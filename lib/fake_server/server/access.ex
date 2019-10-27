defmodule FakeServer.Server.Access do
  @moduledoc false

  def start_link(), do: Agent.start_link(fn -> [] end)
  def stop(server), do: Agent.stop(server)

  def compute_access(server, request) do
    Agent.update(server, fn requests ->
      [request | requests]
    end)
  end

  def access_list(server) do
    Agent.get(server, fn requests ->
      Enum.reverse(requests)
    end)
  end
end
