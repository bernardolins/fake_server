defmodule FakeServer do

  alias FakeServer.HTTP.Response
  alias FakeServer.HTTP.Server
  alias FakeServer.Agents.RouterAgent
  alias FakeServer.Agents.ResponseAgent

  @base_address "http://127.0.0.1"

  defmacro test_with_server(test_description, opts \\ [], do: test_block) do
    quote do
      test unquote(test_description) do
        {:ok, server_name, port} = Server.run

        var!(fake_server_address) = "#{unquote(@base_address)}:#{port}"
        var!(fake_server) = server_name

        unquote(test_block)

        Server.stop(server_name)
      end
    end
  end

  defmacro route(fake_server_name, route, do: response_block) do
    quote do
      RouterAgent.put_route(unquote(fake_server_name), unquote(route))
      ResponseAgent.put_response_list(unquote(fake_server_name), unquote(route), unquote(response_block))
      Server.update_router(unquote(fake_server_name))
    end
  end
end
