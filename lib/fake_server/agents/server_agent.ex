defmodule FakeServer.Agents.ServerAgent do
  alias FakeServer.Specs.ServerSpec

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  def save_spec(%ServerSpec{} = spec) do
    Agent.update(__MODULE__, &Keyword.put(&1, spec.id, spec))
    spec
  end

  def get_spec(server_id) do
    Agent.get(__MODULE__, &Keyword.get(&1, server_id))
  end
end
