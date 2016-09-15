defmodule Fakex.Action do
  @moduledoc """
  Provides an interface to create and destroy Actions

  ## Examples
  #
  #      iex> Fakex.Action.create(:action_name, %{response_code: 200, response_body: ~s<\"username\": \"some_guy\"})
  #           :ok
  #
  #      iex> Fakex.Action.destroy_all
  #           :ok
  #
  """

  def destroy_all do
    case Process.whereis(__MODULE__) do
      nil -> {:error, :no_action_to_destroy}
      _ ->
        Agent.stop(__MODULE__)
        :ok
    end
  end

  def create(name, action = %{response_code: _code, response_body: _body}) do
    case start_server do
      {:ok, :up} -> add_action(name, action)
      {:error, reason} -> {:error, reason}
    end

  end
  def create(_name, %{response_body: _body}) do
    {:error, :response_code_not_provided}
  end
  def create(_name, %{response_code: _code}) do
    {:error, :response_body_not_provided}
  end
  def create(_action) do
    {:error, :name_not_provided}
  end

  def get do
    {:ok, Agent.get(__MODULE__, fn(action_list) -> action_list end)}
  end

  def get(name) do
    action = Agent.get(__MODULE__, fn(action_list) -> Keyword.get(action_list, name) end)
    case action do
      nil -> {:error, :not_found}
      _ -> {:ok, action}
    end
  end

  def start_server do
    case Agent.start_link(fn -> [] end, name: __MODULE__) do
      {:ok, _} -> {:ok, :up} 
      {:error, {:already_started, _}} -> {:ok, :up}
      {:error, reason} -> {:error, reason}
    end
  end

  defp add_action(name, action) do
    case is_atom name do
      true ->
        Agent.update(__MODULE__, fn(action_list) -> Keyword.put(action_list, name, action) end)
        :ok
      false -> {:error, :invalid_name}
    end
  end
end
