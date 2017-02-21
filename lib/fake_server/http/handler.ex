defmodule FakeServer.HTTP.Handler do
  def init(_type, conn, opts), do: {:ok, conn, opts}

  def handle(conn, opts) do
    route = :cowboy_req.path(conn) |> elem(0)

    case FakeServer.Agents.ServerAgent.take_path_controller(opts[:name], route) do
      nil ->
        reply(opts[:name], route, conn)
      controller ->
        controller_response = apply(elem(controller, 0), elem(controller, 1), [conn])
        FakeServer.Agents.ServerAgent.put_responses_to_path(opts[:name], route, controller_response)
        FakeServer.Agents.ServerAgent.delete_controller(opts[:name], route)
        reply(opts[:name], route, conn)
    end


    {:ok, conn, opts}
  end

  def terminate(_reason, _req, _state), do: :ok

  defp reply(name, route, conn) do
    response = FakeServer.Agents.ServerAgent.take_next_response_to_path(name, route)
    :cowboy_req.reply(response.code, response.headers, response.body, conn)
  end
end
