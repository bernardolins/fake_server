defmodule FakeServer do

  alias FakeServer.HTTP.Response
  alias FakeServer.HTTP.Server
  alias FakeServer.Agents.RouterAgent
  alias FakeServer.Agents.ResponseAgent

  @base_address "http://127.0.0.1"

  defmacro test_with_server(test_description, opts \\ [], do: test_block) do
    quote do
      test unquote(test_description) do
        {:ok, port} = Server.run
        var!(fake_server_address) = "#{unquote(@base_address)}:#{port}"
        unquote(test_block)
        Server.stop
      end
    end
  end

  defmacro route(route, do: response_block) do
    quote do
      RouterAgent.put_route(unquote(route))
      ResponseAgent.put_response_list(unquote(response_block))
      Server.update_router
    end
  end
end
