defmodule FakeServer.Status do
  @moduledoc """
  Provides an interface to create and destroy Statuss

  ## Examples
  #
  #      iex> FakeServer.Status.create(:status_name, %{response_code: 200, response_body: ~s<\"username\": \"some_guy\"})
  #           :ok
  #
  #      iex> FakeServer.Status.destroy_all
  #           :ok
  #
  """

  def destroy_all do
    case Process.whereis(__MODULE__) do
      nil -> {:error, :no_status_to_destroy}
      _ ->
        Agent.stop(__MODULE__)
        :ok
    end
  end

  def create(name, status = %{response_code: _code, response_body: _body}) do
    name
    |> validate_name
    |> check_server_and_add(status)
  end
  def create(_name, %{response_body: _body}) do
    {:error, :response_code_not_provided}
  end
  def create(_name, %{response_code: _code}) do
    {:error, :response_body_not_provided}
  end
  def create(_status) do
    {:error, :name_not_provided}
  end

  def get do
    {:ok, Agent.get(__MODULE__, fn(status_list) -> status_list end)}
  end

  def get(name) do
    status = Agent.get(__MODULE__, fn(status_list) -> Keyword.get(status_list, name) end)
    case status do
      nil -> {:error, :not_found}
      _ -> {:ok, status}
    end
  end

  def validate_name(name) do
    case is_atom(name) do
      true -> name
      false -> {:error, {:invalid_status_name, name}}
    end
  end
  
  defp check_server_and_add({:error, {:invalid_status_name, name}}, _status), do: {:error, {:invalid_status_name, name}}
  defp check_server_and_add(name, status) do
    case start_server do
      {:ok, :up} -> add_status(name, status)
      {:error, reason} -> {:error, reason}
    end
  end

  defp start_server do
    case Agent.start_link(fn -> [] end, name: __MODULE__) do
      {:ok, _} -> {:ok, :up} 
      {:error, {:already_started, _}} -> {:ok, :up}
      {:error, reason} -> {:error, reason}
    end
  end

  defp add_status(name, status) do
    case is_atom name do
      true ->
        Agent.update(__MODULE__, fn(status_list) -> Keyword.put(status_list, name, status) end)
        :ok
      false -> {:error, :invalid_name}
    end
  end
end
