defmodule FakeServer do

  alias FakeServer.HTTP.Server
  alias FakeServer.Agents.EnvAgent

  @moduledoc """
  Manage HTTP servers on your tests
  """

  @doc """
  Runs a test with an HTTP server.

  If you need an HTTP server on your test, just write it using `test_with_server/3` instead of `ExUnit.Case.test/3`. Their arguments are similar: A description (the `test_description` argument), the implementation of the test case itself (the `list` argument) and an optional list of parameters (the `opts` argument).

  The server will start just before your test block and will stop just before the test exits. Each `test_with_server/3` has its own server. By default, all servers will start in a random unused port, which allows you to run your tests with `ExUnit.Case async: true` option enabled.

  ## Environment
  FakeServer defines an environment for each `test_with_server/3`. This environment is stored inside a `FakeServer.Env` structure, which has the following fields:

  - `:ip`: the current server IP
  - `:port`: the current server port
  - `:routes`: the list of server routes
  - `:hits`: the number of requests made to the server

  To access this environment, you can use `FakeServer.env/0`, which returns the environment for the current test. For convenience, you can also use `FakeServer.address/0`, `FakeServer.http_address/0` or `FakeServer.hits/0`.

  ## Server options
  You can set some options to the server before it starts using the `opts` params. The following options are accepted:

  `:default_response`: The response that will be given by the server if a route has no responses configured.
  `:port`: The port that the server will listen.

  ## Usage:
  ```elixir
  defmodule SomeTest do
    use ExUnit.Case, async: true
    import FakeServer
    alias FakeServer.Response

    test_with_server "each test runs its own http server" do
      IO.inspect FakeServer.env
      # prints something like %FakeServer.Env{hits: 0, ip: "127.0.0.1", port: 5156, routes: []}
    end

    test_with_server "it is possible to configure the server to run on a specific port", [port: 5001] do
      assert FakeServer.env.port == 5001
      assert FakeServer.address == "127.0.0.1:5001"
    end

    test_with_server "it is possible to count how many requests the server received" do
      route "/", fn(_) -> Response.ok end
      assert FakeServer.hits == 0

      HTTPoison.get! FakeServer.address <> "/"
      assert FakeServer.hits == 1

      HTTPoison.get! FakeServer.address <> "/"
      assert FakeServer.hits == 2
    end

    test_with_server "adding body and headers to the response" do
      route "/", do: Response.ok(~s<{"response": "ok"}>, [{'x-my-header', 'fake-server'}])

      response = HTTPoison.get! FakeServer.address <> "/"
      assert Enum.any?(response.headers, fn(header) -> header == {"x-my-header", "fake-server"} end)
    end
  end
  ```
  """
  defmacro test_with_server(test_description, opts \\ [], do: test_block) do
    quote do
      test unquote(test_description) do
        case FakeServer.Instance.run(unquote(opts)) do
          {:ok, server} ->
            var!(current_server, FakeServer) = server
            unquote(test_block)
            FakeServer.Instance.stop(server)

          {:error, reason} ->
            raise FakeServer.Error, reason
        end
      end
    end
  end

  @doc """
  Adds a route to a server and the response that will be given when a request reaches that route.


  When the macro route is used, you are telling the server what to respond when a request is made for this route. If you run a `test_with_server/3` with no route configured, the server will always reply `404`.

  ```elixir
  test_with_server "if you do not add any route, the server will reply 404 to all requests" do
    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 404
    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 404
    response = HTTPoison.get! FakeServer.address <> "/test/1"
    assert response.status_code == 404
    assert FakeServer.env.hits == 0
  end
  ```

  ## Adding routes
  When you add a route, you have to say what will be answered by it when it receives a request. For each request, the server will use the appropriate `FakeServer.Response` based on the way the route was configured.

  ### Routes with a single response
  When the test expects the route to receive only one request, it is appropriate to configure this route with a single response.

  ```elixir
  test_with_server "raises UserNotFound error when the user is not found on server" do
    route "/user/" <> @user_id, Response.not_found

    assert_raise, MyApp.Errors.UserNotFound, fn ->
      MyApp.External.User.get(@user_id)
    end
  end
  ```

  ### Routes with lists

  When the route is configured with a list of `FakeServer.Response`s, the server will respond with the first element in the list and then remove it. This will be repeated for each request made for this route. If the list is empty, the server will respond with its `default_response`.

  ```
  test_with_server "the server will always reply the first element and then remove it" do
    route "/", [Response.ok, Response.not_found, Response.bad_request]
    assert FakeServer.hits == 0

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 200
    assert FakeServer.hits == 1

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 404
    assert FakeServer.hits == 2

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 400
    assert FakeServer.hits == 3
  end

  test_with_server "default response can be configured and will be replied when the response list is empty", [default_response: Response.bad_request] do
    route "/", []
    assert FakeServer.hits == 0

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 400
    assert FakeServer.hits == 1

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 400
    assert FakeServer.hits == 2
  end
  ```

  ### Configuring a route with a function

  You can configure a route to execute a function every time a request arrives. This function must accept a single argument, which is an `FakeServer.Request` object that holds request information. The `FakeServer.Request` structure holds several information about the request, such as method, headers and query strings.

  Configure a route with a function is useful when you need to simulate timeouts, validate the presence of headers or some mandatory parameters.

  The function will be called every time a request arrives at that route. If the return value of the function is a `FakeServer.Response`, this response will be replied. However, if the return is not a `FakeServer.Response`, the server `default_response` is returned.

  ```elixir
  test_with_server "the server will return the default_response if the function return is not a Response struct", [default_response: Response.not_found("Ops!")] do
    route "/", fn(_) -> :ok end

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 404
    assert response.body == "Ops!"
  end

  test_with_server "you can evaluate the request object to choose what to reply" do
    route "/", fn(%{query: query} = _req) ->
      case Map.get(query, "access_token") do
        "1234" -> Response.ok("Welcome!")
        nil -> Response.bad_request("You must provide and access_token!")
        _ -> Response.forbidden("Invalid access token!")
      end
    end

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 400
    assert response.body == "You must provide and access_token!"

    response = HTTPoison.get! FakeServer.address <> "/?access_token=4321"
    assert response.status_code == 403
    assert response.body == "Invalid access token!"

    response = HTTPoison.get! FakeServer.address <> "/?access_token=1234"
    assert response.status_code == 200
    assert response.body == "Welcome!"
  end
  ```

  ### Responses
  The server will always use a struct to set the response. You can define the headers and body of this struct using `FakeServer.Response` helpers like `FakeServer.Response.ok/2` or `FakeServer.Response.not_found/2`. There are helpers like these for most of the HTTP status codes.

  You can also use `FakeServer.Response.new/3` or even create the struct yourself. For more details see `FakeServer.Response` docs.

  ```elixir
  test_with_server "adding body and headers to the response" do
    route "/", do: Response.ok(~s<{"response": "ok"}>, %{"x-my-header" => 'fake-server'})

    response = HTTPoison.get! FakeServer.address <> "/"
    assert Enum.any?(response.headers, fn(header) -> header == {"x-my-header", "fake-server"} end)
  end
  ```
  """
  defmacro route(path, response_block) do
    quote do
      server = var!(current_server, FakeServer)
      case FakeServer.Instance.add_route(server, unquote(path), unquote(response_block)) do
        :ok -> :ok
        {:error, reason} -> raise FakeServer.Error, reason
      end
    end
  end

  @doc """
  Returns the current server address.

  You can only call `FakeServer.address/0` inside `test_with_server/3`.

  ## Usage
  ```elixir
    test_with_server "Getting the server address", [port: 55001] do
      assert FakeServer.address == "127.0.0.1:55001"
    end
  ```
  """
  defmacro address do
    quote do
      server = var!(current_server, FakeServer)
      "127.0.0.1:#{FakeServer.Instance.port(server)}"
    end
  end

  @doc """
  Returns the current server HTTP address.

  You can only call `FakeServer.http_address/0` inside `test_with_server/3`.

  ## Usage
  ```elixir
    test_with_server "Getting the server address", [port: 55001] do
      assert FakeServer.address == "http://127.0.0.1:55001"
    end
  ```
  """
  defmacro http_address do
    quote do
      server = var!(current_server, FakeServer)
      "http://127.0.0.1:#{FakeServer.Instance.port(server)}"
    end
  end

  @doc """
  Returns the number of requests made to the server.

  You can only call `FakeServer.hits/0` inside `test_with_server/3`.

  ## Usage
  ```elixir
  test_with_server "counting server hits" do
    route "/", do: Response.ok
    assert FakeServer.hits == 0
    HTTPoison.get! FakeServer.address <> "/"
    assert FakeServer.hits == 1
    HTTPoison.get! FakeServer.address <> "/"
    assert FakeServer.hits == 2
  end
  ```
  """
  defmacro hits do
    quote do
      server = var!(current_server, FakeServer)
      case FakeServer.Instance.access_list(server) do
        {:ok, access_list} -> length(access_list)
        {:error, reason} -> raise FakeServer.Error, reason
      end
    end
  end

  @doc """
  Returns the number of requests made to a route in the server.

  You can only call `FakeServer.hits/1` inside `test_with_server/3`.

  ## Usage
  ```elixir
  test_with_server "count route hits" do
    route "/no/cache", FakeServer.Response.ok
    route "/cache", FakeServer.Response.ok
    assert (FakeServer.hits "/no/cache") == 0
    assert (FakeServer.hits "/cache") == 0
    HTTPoison.get! FakeServer.address <> "/no/cache"
    assert (FakeServer.hits "/no/cache") == 1
    HTTPoison.get! FakeServer.address <> "/cache"
    assert (FakeServer.hits "/cache") == 1
    assert FakeServer.hits == 2
  end
  ```
  """
  defmacro hits(path) do
    quote do
      server = var!(current_server, FakeServer)
      case FakeServer.Instance.access_list(server) do
        {:ok, access_list} ->
          access_list_path =
            access_list
            |> Enum.filter(&(&1 == unquote(path)))
          length(access_list_path)
        {:error, reason} -> raise FakeServer.Error, reason
      end
    end
  end
end
