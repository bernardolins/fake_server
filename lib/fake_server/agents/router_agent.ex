defmodule FakeServer.Agents.RouterAgent do
  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def put_route(route) when is_bitstring(route) do
    Agent.update(__MODULE__, fn(routes) -> [route|routes] end)
  end
  
  def take_all do
    Agent.get_and_update(__MODULE__, fn(routes) -> {routes, []} end)
  end
end
