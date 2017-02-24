defmodule FakeServer do

  alias FakeServer.HTTP.Response
  alias FakeServer.HTTP.Server
  alias FakeServer.Agents.ServerAgent

  @base_address "http://127.0.0.1"

  
  @moduledoc """
  # FakeServer

  This module provides some simple macros to help you to mock HTTP requests on your tests.

  ## Getting Started
 
  A basic setup is shown bellow:
  
  ```elixir
  defmodule DummyTest do
    use ExUnit.Case, async: true
    import FakeServer
    alias FakeServer.HTTP.Response

    Application.ensure_all_started(:fake_server)

    test_with_server "test if fake server really works" do
      route fake_server, "/test", do: [Response.ok, Response.not_found, Response.bad_request]

      response = HTTPoison.get! fake_server_address <> "/test"
      assert response.status_code == 200

      response = HTTPoison.get! fake_server_address <> "/test"
      assert response.status_code == 404

      response = HTTPoison.get! fake_server_address <> "/test"
      assert response.status_code == 400 
    end
  end
  ```
  """

  @doc """
  This macro starts a server on a random or customized port and calls ExUnit's `test` internally. 

  *Note: Despite the server is running, no route is configured, so any request to this server will return 404.*

  You must provide a `test_description` (a message describing the teste) and a `test_block` (the test itself).

  Some `opts` are accepted:
  `port` is used to customize which port the server will run.
  `default_response` to customize the default response. The server will reply this when no response is provided.

  Also, two variables are available inside `test_block`:
  `fake_server` is an id to the server. It should be only used internally.
  `fake_server_address` is an url to hit the server. You can use it to configure you application to call the fake server instead of the real one.

  To configure a `route` to the server, use `route/3` macro.

  ### Example
  `
  test_with_server "with no route will respond always 404" do
    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 404
  end

  test_with_server "test with default port", [port: 5001] do
    assert fake_server_address == "http://127.0.0.1:5001"
    assert response.status_code == 404
  end
  ```
  """
  defmacro test_with_server(test_description, opts \\ [], do: test_block) do
    quote do
      test unquote(test_description) do
        {:ok, server_name, port} = Server.run

        ServerAgent.put_default_response(server_name, unquote(opts[:default_response]))

        var!(fake_server_address) = "#{unquote(@base_address)}:#{port}"
        var!(fake_server) = server_name
        var!(fake_server_map) = ServerAgent.take_server_info(server_name)

        unquote(test_block)

        Server.stop(server_name)
      end
    end
  end

  @doc """
  """
  defmacro route(fake_server_name, route, do: response_block) do
    quote do
      case unquote(response_block) do
        {:controller, module, function_name} ->
          FakeServer.Agents.ServerAgent.put_controller_to_path(unquote(fake_server_name), unquote(route), module, function_name)
          Server.update_router(unquote(fake_server_name))
        list ->
          ServerAgent.put_responses_to_path(unquote(fake_server_name), unquote(route), list)
          Server.update_router(unquote(fake_server_name))
      end
    end
  end
end
