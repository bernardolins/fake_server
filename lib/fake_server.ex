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

  To access this environment, you can use `FakeServer.env/0`, which returns the environment for the current test. For convenience, you can also use the `FakeServer.address/0` or `FakeServer.hits/0`.

  ## Server options
  You can set some options to the server before it starts using the `opts` params. The following options are accepted:

  `:default_response`: The response that will be given by the server if a route has no responses configured.
  `:port`: The port that the server will listen.

  ## Usage:
  ```elixir
  defmodule SomeTest do
    use ExUnit.Case, async: true
    import FakeServer
    alias FakeServer.HTTP.Response

    test_with_server "without configured routes will always return 404 and hits will not be updated" do
      response = HTTPoison.get! FakeServer.address <> "/"
      assert response.status_code == 404
      response = HTTPoison.get! FakeServer.address <> "/test"
      assert response.status_code == 404
      response = HTTPoison.get! FakeServer.address <> "/test/1"
      assert response.status_code == 404
      assert FakeServer.env.hits == 0
    end

    test_with_server "server port configuration", [port: 5001] do
      assert FakeServer.env.port == 5001
      assert FakeServer.address == "127.0.0.1:5001"
    end

    test_with_server "setting a default response", [default_response: Response.forbidden] do
      route "/test", do: Response.bad_request

      response = HTTPoison.get! FakeServer.address <> "/test"
      assert response.status_code == 400

      response = HTTPoison.get! FakeServer.address <> "/test"
      assert response.status_code == 403
    end

    test_with_server "adding a route" do
      route "/", do: FakeServer.HTTP.Response.bad_request

      response = HTTPoison.get! FakeServer.address <> "/"
      assert response.status_code == 400
    end

    test_with_server "save server hits in the environment" do
      route "/", do: Response.ok
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
        map_opts = Enum.into(unquote(opts), %{})
        {:ok, server_id, port} = Server.run(map_opts)
        env = FakeServer.Env.new(port)

        EnvAgent.save_env(server_id, env)

        var!(current_id, FakeServer) = server_id
        unquote(test_block)

        Server.stop(server_id)
        EnvAgent.delete_env(server_id)
      end
    end
  end

  @doc """
  Adds a route to a server and the responses that will be given when a request reaches that route.

  Responses can be given in three formats:

  1. A single `FakeServer.HTTP.Response`. In this case, this response will be given by the server on the first request. The following requests will be replied with the default_response.

  2. A list of `FakeServer.HTTP.Response`. In this case, each request will be replied with the first element of the list, which is then removed. When the list is empty, the requests will be replied with `default_respose`.

  3. A `FakeController`. In this case, the responses will be given dynamically, according to request parameters. For more details see `FakeController`.
  """

  # DEPRECATED: Keep Backward compatibility
  defmacro route(path, response_block \\ nil)
  defmacro route(path, do: response_block) do
    quote do
      current_id = var!(current_id, FakeServer)
      env = EnvAgent.get_env(current_id)
      EnvAgent.save_env(current_id, %FakeServer.Env{env | routes: [unquote(path)|env.routes]})
      Server.add_response(current_id, unquote(path), unquote(response_block))
    end
  end

  defmacro route(path, response_block) do
    quote do
      current_id = var!(current_id, FakeServer)
      env = EnvAgent.get_env(current_id)
      EnvAgent.save_env(current_id, %FakeServer.Env{env | routes: [unquote(path)|env.routes]})
      Server.add_response(current_id, unquote(path), unquote(response_block))
    end
  end

  @doc """
  Returns the current server environment.

  You can only call `FakeServer.env/0` inside `test_with_server/3`.

  ## Usage
  ```elixir
    test_with_server "Getting the server env", [port: 5001] do
      assert FakeServer.env.ip == "127.0.0.1"
      assert FakeServer.env.port == 5001
    end
  ```
  """
  defmacro env do
    quote do
      case var!(current_id, FakeServer) do
        nil -> raise "You can call this macro inside test_with_server only"
        current_id -> EnvAgent.get_env(current_id)
      end
    end
  end

  @doc """
  Returns the current server address.

  You can only call `FakeServer.address/0` inside `test_with_server/3`.

  ## Usage
  ```elixir
    test_with_server "Getting the server address", [port: 5001] do
      assert FakeServer.address == "127.0.0.1:5001"
    end
  ```
  """
  defmacro address do
    quote do
      case var!(current_id, FakeServer) do
        nil -> raise "You can only call FakeServer.address inside test_with_server"
        current_id ->
          env = EnvAgent.get_env(current_id)
          "#{env.ip}:#{env.port}"
      end
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
      case var!(current_id, FakeServer) do
        nil -> raise "You can only call FakeServer.hits inside test_with_server"
        current_id ->
          EnvAgent.get_env(current_id).hits
      end
    end
  end
end
