defmodule FakeServer do

  alias FakeServer.HTTP.Server

  @moduledoc """
  Provides macros that help create HTTP servers in tests
  """

  @doc """
  Runs a test with an HTTP server.

  This macro works similarly to `ExUnit.Case.test/3`, with the difference that it starts an HTTP server. If you need an HTTP server on your test, just use `test_with_server/3` instead of `ExUnit.Case.test/3`. Their arguments are similar: A description (the `test_description` argument) and the implementation of the test case itself (the `list` argument). The server will start just before your test block and will stop just before the test exits. Each `test_with_server/3` has its own server.

  ## Environment
  FakeServer defines an environment for each `test_with_server/3`. This environment is stored insied a FakeServer.Env structure, which has the following fields:

  - `:ip`: the current server IP
  - `:port`: the current the server port

  To access this environment, FakeServer provides the `FakeServer.env/0` macro, which returns the environment for the current test. For convenience, you can also use the `FakeServer.address/0` macro that returns the server address in the "IP: port" format. It also can only be called from `test_with_server/0`

  ## Server options
  You can set some options to the server before it starts using the `opts` params. The following options are accepted:

  `:default_response`: The response that will be given by the server if no route has been configured or no answers are available for a particular route.
  `:port`: The port that the server will respond.

  ## Usage:
  ```elixir
  defmodule FakeServerTest do
    use ExUnit.Case, async: true

    import FakeServer

    alias FakeServer.HTTP.Response

    test_with_server "without configured routes will always return 404" do
      response = HTTPoison.get! FakeServer.address <> "/"
      assert response.status_code == 404
      response = HTTPoison.get! FakeServer.address <> "/test"
      assert response.status_code == 404
      response = HTTPoison.get! FakeServer.address <> "/test/1"
      assert response.status_code == 404
    end

    test_with_server "server port configuration", [port: 5001] do
      assert FakeServer.address == "127.0.0.1:5001"
      response = HTTPoison.get! "127.0.0.1:5001" <> "/"
      assert response.status_code == 404
    end

    test_with_server "adding a route", do
      route "/", do: FakeServer.HTTP.Response.bad_request
      response = HTTPoison.get! FakeServer.address <> "/"
      assert response.status_code == 400
    end

    test_with_server "setting a default response", [default_response: Response.forbidden] do
      route "/test", do: Response.bad_request

      response = HTTPoison.get! FakeServer.address <> "/test"
      assert response.status_code == 400

      response = HTTPoison.get! FakeServer.address <> "/test"
      assert response.status_code == 403
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
        var!(env, FakeServer) = env
        var!(current_id, FakeServer) = server_id
        unquote(test_block)

        Server.stop(server_id)
      end
    end
  end

  @doc """
  Adds a route to a server and the responses that will be given when a request reaches that route.

  Responses can be given in three formats:

  1. A single answer. In this case, this response will be given by the server on the first request. The following requests will be replied with the default_response.

  2. A list of answers. In this case, each request will be replied with the first element of the list, which is then removed. When the list is empty, the requests will receive default_respose in response.

  3. A FakeController. In this case, the responses will be given dynamically, according to request parameters. For more details see FakeController.
  """
  defmacro route(path, do: response_block) when is_list(response_block) do
    quote do
      current_id = var!(current_id, FakeServer)
      Server.add_route(current_id, unquote(path), unquote(response_block))
    end
  end
  defmacro route(path, do: response_block) do
    quote do
      current_id = var!(current_id, FakeServer)
      case unquote(response_block) do
        [module: module, function: function] ->
          Server.add_controller(current_id, unquote(path), [module: module, function: function])
        %FakeServer.HTTP.Response{} = response ->
          Server.add_route(current_id, unquote(path), response)
      end
    end
  end

  @doc """
  Returns the current server environment.

  You can only call FakeServer.env inside `test_with_server/3`.

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
      case var!(env, FakeServer) do
        nil -> raise "You can only call FakeServer.env inside test_with_server"
        env -> env
      end
    end
  end

  @doc """
  Returns the current server address.

  You can only call FakeServer.address inside `test_with_server/3`.

  ## Usage
  ```elixir
    test_with_server "Getting the server address", [port: 5001] do
      assert FakeServer.address == "127.0.0.1:5001"
    end
  ```
  """
  defmacro address do
    quote do
      case var!(env, FakeServer) do
        nil -> raise "You can only call FakeServer.address inside test_with_server"
        env -> "#{env.ip}:#{env.port}"
      end
    end
  end
end
