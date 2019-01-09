defmodule FakeServer do
  @moduledoc """
  Manage HTTP servers on your tests
  """

  @doc """
  Runs a test with an HTTP server.

  If you need an HTTP server on your test, just write it using `test_with_server/3` instead of `ExUnit.Case.test/3`. Their arguments are similar: A description (the `test_description` argument), the implementation of the test case itself (the `list` argument) and an optional list of parameters (the `opts` argument).

  The server will start just before your test block and will stop just before the test exits. Each `test_with_server/3` has its own server. By default, all servers will start in a random unused port, which allows you to run your tests with `ExUnit.Case async: true` option enabled.

  ## Server options
  You can set some options to the server before it starts using the `opts` params. The following options are accepted:

  - `:routes`: A list of routes to add to the server. If you set a route here, you don't need to configure a route using `route/2`.
  - `:port`: The port that the server will listen. The port value must be between 55_000 and 65_000

  ## Usage:
  ```elixir
  defmodule SomeTest do
    use ExUnit.Case

    import FakeServer

    alias FakeServer.Response
    alias FakeServer.Route

    test_with_server "supports inline port configuration", [port: 63_543] do
      assert FakeServer.port() == 63_543
    end

    test_with_server "supports inline route configuration", [routes: [Route.create!(path: "/test", response: Response.accepted!())]] do
      response = HTTPoison.get!(FakeServer.address <> "/test")
      assert response.status_code == 202
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
  Adds a route to a server and sets its response.

  If you run a `test_with_server/3` with no route configured, the server will always reply `404`.

  ## Route path

  The route path must be a string starting with "/". Route binding and optional segments are accepted:

  ```elixir
  test_with_server "supports route binding" do
    route "/test/:param", fn(%Request{path: path}) ->
      if path == "/test/hello", do: Response.ok!(), else: Response.not_found!()
    end

    response = HTTPoison.get!(FakeServer.address <> "/test/hello")
    assert response.status_code == 200
    response = HTTPoison.get!(FakeServer.address <> "/test/world")
    assert response.status_code == 404
  end

  test_with_server "supports optional segments" do
    route "/test[/not[/mandatory]]", Response.accepted!()

    response = HTTPoison.get!(FakeServer.address <> "/test")
    assert response.status_code == 202
    response = HTTPoison.get!(FakeServer.address <> "/test/not")
    assert response.status_code == 202
    response = HTTPoison.get!(FakeServer.address <> "/test/not/mandatory")
    assert response.status_code == 202
  end

  test_with_server "supports fully optional segments" do
    route "/test/[...]", Response.accepted!()

    response = HTTPoison.get!(FakeServer.address <> "/test")
    assert response.status_code == 202
    response = HTTPoison.get!(FakeServer.address <> "/test/not")
    assert response.status_code == 202
    response = HTTPoison.get!(FakeServer.address <> "/test/not/mandatory")
    assert response.status_code == 202
  end

  test_with_server "paths ending in slash are no different than those ending without slash" do
    route "/test", Response.accepted!()

    response = HTTPoison.get!(FakeServer.address <> "/test")
    assert response.status_code == 202
    response = HTTPoison.get!(FakeServer.address <> "/test/")
    assert response.status_code == 202
  end
  ```

  ## Adding routes

  Besides the path, you need to tell the server what to reply when that path is requested. FakeServer accepts three types of response:

  - a single `FakeServer.Response` structure
  - a list of `FakeServer.Response` structures
  - a function with arity 1

  ### Routes with a single FakeServer.Response structure
  When a route is expected to be called once or to always reply the same thing, simply configure it with a `FakeServer.Response` structure as response.
  Every request to this path will always receive the same response.

  ```elixir
  test_with_server "Updating a user always returns 204" do
    route "/user/:id", Response.no_content!()

    response = HTTPoison.put!(FakeServer.address <> "/user/1234")
    assert response.status_code == 204

    response = HTTPoison.put!(FakeServer.address <> "/user/5678")
    assert response.status_code == 204
  end
  ```

  ### Routes with a list of FakeServer.Response structure
  When the route is configured with a `FakeServer.Response` structure list, the server will reply every request with the first element in the list and then remove it.
  If the list is empty, the server will reply `FakeServer.Response.default/0`.

  ```elixir
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
  ```

  ### Configuring a route with a function
  You can configure a route to execute a function every time a request arrives.
  This function must accept a single argument, which is an `FakeServer.Request` object.
  The `FakeServer.Request` structure holds several information about the request, such as method, headers and query strings.

  Configure a route with a function is useful when you need to simulate timeouts, validate the presence of headers or some mandatory parameters.
  It also can be useful when used together with route path binding.

  The function will be called every time the route is requested.
  If the return value of the function is a `FakeServer.Response`, this response will be replied.
  However, if the function return value is not a `FakeServer.Response`, it will reply `FakeServer.Response.default/0`.

  ```elixir
  test_with_server "the server will return the default response if the function return is not a Response struct" do
    route "/", fn(_) -> :ok end

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
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
  Returns the current server TCP port.

  You can only call `FakeServer.port/0` inside `test_with_server/3`.

  ## Usage
  ```elixir
    test_with_server "Getting the server port", [port: 55001] do
      assert FakeServer.port == 55001
    end
  ```
  """
  defmacro port do
    quote do
      server = var!(current_server, FakeServer)
      FakeServer.Instance.port(server)
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
