defmodule FakeServer.Agents.ResponseAgent do
  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  def put_response_list(responses) do
    Agent.update(__MODULE__, fn(_) -> List.wrap(responses) end)
  end

  def take_next do
    case Agent.get(__MODULE__, fn(responses) -> responses end) do
      [] ->
        FakeServer.HTTP.Response.default()
      [response|responses] ->
        Agent.update(__MODULE__, fn(_) -> responses end)
        response
    end
  end
end
