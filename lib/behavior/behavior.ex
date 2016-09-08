defmodule Fakex.Behavior do
  def begin do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def add(name, behavior = [code: _code, body: _body]) do
    case is_atom name do
      true -> Agent.update(__MODULE__, fn(behavior_list) -> Keyword.put(behavior_list, name, behavior) end)
      false -> {:error, :invalid_name}
    end
  end
  def add(_behavior) do
    {:error, :invalid_name}
  end
end
