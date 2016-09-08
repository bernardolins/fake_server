defmodule Fakex.Behavior do
  def begin do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def create(name, behavior = %{response_code: _code, response_body: _body}) do
    case is_atom name do
      true -> Agent.update(__MODULE__, fn(behavior_list) -> Keyword.put(behavior_list, name, behavior) end)
      false -> {:error, :invalid_name}
    end
  end
  def create(name, %{response_body: _body}) do
    {:error, :response_code_not_provided}
  end
  def create(name, %{response_code: _code}) do
    {:error, :response_body_not_provided}
  end
  def create(_behavior) do
    {:error, :name_not_provided}
  end
end
