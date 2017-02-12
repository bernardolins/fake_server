defmodule FakeServer.Agents.ResponseAgent do
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  def put_response_list(server_name, route, responses) do
    Agent.update(__MODULE__, fn(servers) ->
      case servers[server_name] do
        nil ->
          Map.put(servers, server_name, %{route => List.wrap(responses)})
        routes_for_server ->
          routes_for_server = routes_for_server |> Map.put(route, List.wrap(responses))
          Map.put(servers, server_name, routes_for_server)
      end
    end)
  end

  def take_next(server_name, route) do
    routes = Agent.get(__MODULE__, fn(servers) -> servers[server_name] end)
    case routes[route] do
      [] ->
        FakeServer.HTTP.Response.default()
      nil ->
        FakeServer.HTTP.Response.not_found
      [response|responses] ->
        routes = Map.put(routes, route, responses)
        Agent.update(__MODULE__, fn(servers) -> Map.put(servers, server_name, routes) end)
        response
    end
  end
end
