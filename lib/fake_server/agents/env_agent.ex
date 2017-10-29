defmodule FakeServer.Agents.EnvAgent do
  @moduledoc false

  alias FakeServer.Env

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  def save_env(server_id, %Env{} = env) do
    Agent.update(__MODULE__, &Keyword.put(&1, server_id, env))
    env
  end

  def get_env(server_id) do
    Agent.get(__MODULE__, &Keyword.get(&1, server_id))
  end

  def delete_env(server_id) do
    Agent.get(__MODULE__, &Keyword.delete(&1, server_id))
  end
end
