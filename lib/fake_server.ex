defmodule FakeServer do

  alias FakeServer.HTTP.Server

  @fake_server_ip "127.0.0.1"

  @moduledoc """
  This module provides some simple macros to help you to mock HTTP requests on your tests.

  ### Basic Usage
  ```elixir
  # test/test_helper.exs
  Application.ensure_all_started(:fake_server)
  ExUnit.start()

  # test/my_app/dummy_test.exs
  defmodule DummyTest do
    use ExUnit.Case, async: true
    import FakeServer
    alias FakeServer.HTTP.Response

    test_with_server "test if fake_server really works" do
      route fake_server, "/test", do: [Response.ok, Response.not_found, Response.bad_request]

      response = HTTPoison.get! fake_server_address <> "/test"
      assert response.status_code == 200

      response = HTTPoison.get! fake_server_address <> "/test"
      assert response.status_code == 404

      response = HTTPoison.get! fake_server_address <> "/test"
      assert response.status_code == 400

      response = HTTPoison.get! fake_server_address <> "/test"
      assert response.status_code == 200
      assert respone.body == "This is a default response from FakeServer"
    end
  end
  ```
  """

  @doc """
  This macro starts a server on a random or customized port and calls `ExUnit.Case.test/3` internally.

  Note that calling this macro will give you a running server without any routes configured. Therefore, all requests to this server will return 404. To set up a route to the server, use `route/3` macro.

  ### Arguments
  `test_description`: A string describing the test. This argument will become `message` argument of `ExUnit.Case.test/3`.

  `opts`: A map containing options to configure the server before it starts. This map accepts:
    1. `:id` customizes the server id, used as the unique identifier. If you don't provide this option, FakeServer will create one for you.
    2. `:port` set up which port the server will run. Again, if you don't provide one, FakeServer will generate a random port between 5000-10000
    3. `:default_response` customizes the server reply when response list is empty.

  `test_block`: The test itself. Run inside `ExUnit.Case.test/3`.

  Some variables are available to use inside `test_block`:

    1. `fake_server` identifies the server. Should only be used internally.
    3. `fake_server_ip` returns the IP to reach fake_server. Defaults to "127.0.0.1"
    3. `fake_server_port` returns the port fake_server is listening.
    2. `fake_server_address` is server `IP:port`. You can replace your application config to use this address instead of the real one.

  ### Examples
  ```
  test_with_server "with no route configured will always reply 404" do
    response = HTTPoison.get! fake_server_address <> "/"
    assert response.status_code == 404
    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 404
    response = HTTPoison.get! fake_server_address <> "/test/1"
    assert response.status_code == 404
  end

  test_with_server "with port configured, server will listen on the port provided", [port: 5001] do
    assert fake_server_port == 5001
    assert fake_server_address == "127.0.0.1:5001"
    response = HTTPoison.get! "127.0.0.1:5001" <> "/"
    assert response.status_code == 404
  end

  test_with_server "default response can be configured and will be replied response list is empty", [port: 5001, default_response: FakeServer.HTTP.Response.bad_request] do
    route fake_server, "/", do: []
    response = HTTPoison.get! fake_server_address <> "/"
    assert response.status_code == 400
  end
  ```
  """
  defmacro test_with_server(test_description, opts \\ [], do: test_block) do
    quote do
      test unquote(test_description) do
        map_opts = Enum.into(unquote(opts), %{})
        {:ok, server_id, port} = Server.run(map_opts)

        var!(fake_server) = server_id
        var!(fake_server_ip) = unquote(@fake_server_ip)
        var!(fake_server_port) = port
        var!(fake_server_address) = "#{unquote(@fake_server_ip)}:#{port}"

        unquote(test_block)

        Server.stop(server_id)
      end
    end
  end

  @doc """
  This macro configures a route into a running server. You should only use it inside `test_with_server/3`.

  ### Arguments

  `fake_server_id`: FakeServer uses this id to find out where to add the route. You can use `fake_server` variable, available inside `test_with_server/3` macro.

  `path`: This is the URL path. Must be in "/some/path" format.

  `response_block`: This block must return a `FakeServer.HTTP.Response`, a list of responses or a `FakeController`.

  ### Examples
  ```
  # test/support/fake_controllers.exs
  defmodule MyApp.FakeControllers
    use FakeController

    def query_string_example_controller(conn) do
      if :cowboy_req.qs_val("token", conn) |> elem(0) == "1234" do
        FakeServer.HTTP.Response.ok
      else
        FakeServer.HTTP.Response.unauthorized
      end
    end
  end

  # test/my_app/dummy_test.exs
  defmodule MyApp.DummyTest do
    use ExUnit.Case, async: true
    import FakeServer
    import MyApp.FakeControllers

    Application.ensure_all_started(:fake_server)

    test_with_server "reply 403 on / and 404 on other paths" do
      route fake_server, "/", do: FakeServer.HTTP.Response.forbidden
      response = HTTPoison.get! fake_server_address <> "/"
      assert response.status_code == 403

      response = HTTPoison.get! fake_server_address <> "/test"
      assert response.status_code == 404
    end

    test_with_server "reply the first element of the list on / and 404 on other paths" do
      route fake_server, "/", do: [FakeServer.HTTP.Response.forbidden, FakeServer.HTTP.Response.bad_request]
      response = HTTPoison.get! fake_server_address <> "/"
      assert response.status_code == 403

      response = HTTPoison.get! fake_server_address <> "/"
      assert response.status_code == 400

      response = HTTPoison.get! fake_server_address <> "/test"
      assert response.status_code == 404
    end

    test_with_server "evaluates FakeController and reply accordingly" do
      route fake_server, "/", do: use_controller :query_string_example
      response = HTTPoison.get! fake_server_address <> "/"
      assert response.status_code == 401

      response = HTTPoison.get! fake_server_address <> "/?token=4321"
      assert response.status_code == 401

      response = HTTPoison.get! fake_server_address <> "/?token=1234"
      assert response.status_code == 200
    end
  end
  ```
  """
  defmacro route(fake_server_id, path, do: response_block) do
    quote do
      case unquote(response_block) do
        {:controller, module, function} ->
          Server.add_controller(unquote(fake_server_id), unquote(path), [module: module, function: function])
        list ->
          Server.add_route(unquote(fake_server_id), unquote(path), list)
      end
    end
  end
end
