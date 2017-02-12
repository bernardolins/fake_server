defmodule FakeServer.Agents.RouterAgent do
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  def put_route(server_name, route) when is_bitstring(route) do
    servers = Agent.get(__MODULE__, fn(servers) -> servers end)
    case servers[server_name] do
      nil ->
        Agent.update(__MODULE__, fn(servers) -> Map.put(servers, server_name, [route]) end)
      routes ->
        Agent.update(__MODULE__, fn(servers) -> Map.put(servers, server_name, [route|routes]) end)
    end
  end

  def take_all(server_name) do
    case Agent.get(__MODULE__, fn(servers) -> servers[server_name] end) do
      nil -> []
      server ->  server |> Enum.uniq
    end
  end
end
