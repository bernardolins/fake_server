defmodule FakeServer.Server.Access do
  @moduledoc false

  def start_link(), do: Agent.start_link(fn -> [] end)
  def stop(server), do: Agent.stop(server)

  def compute_access(server, route) do
    Agent.update(server, fn(routes) ->
      [route|routes]
    end)
  end

  def access_list(server) do
    Agent.get(server, fn(routes) ->
      Enum.reverse(routes)
    end)
  end
end
