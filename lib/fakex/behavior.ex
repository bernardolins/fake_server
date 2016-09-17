defmodule FailWhale.Behavior do
  @moduledoc """
  Provides an interface to create behaviors

  ## Examples
  #
  #      iex> FailWhale.Behavior.create(:name, [:some_status1, :some_status2])
  #           :ok
  """

  def create(_name, []), do: {:error, :no_status}
  def create(name, status_list) do
    name
    |> validate_name
    |> validate_pipeline(status_list)
  end 

  def next_response(name) do
    case Agent.get(name, fn(status_list) -> List.first(status_list) end) do
      nil -> {:ok, :no_more_statuss}
      response -> 
        update_pipeline(name)
        {:ok, response}
    end
  end

  defp validate_name name do
    case is_atom name do
      true -> name
      false -> {:error, :invalid_name}
    end
  end

  defp validate_pipeline(name_error = {:error, _reason}, _status_list), do: name_error
  defp validate_pipeline(name, status_list) do
    case validate_statuss(status_list) do
      :ok -> create_pipeline(name, status_list)
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_statuss([]), do: :ok
  defp validate_statuss(status_list) do
    [status|remaining_statuss] = status_list
    case FailWhale.Status.get(status) do
      {:error, _} -> {:error, {:invalid_status, status}}
      {:ok, _} -> validate_statuss(remaining_statuss)
    end
  end

  defp create_pipeline(name, status_list) do
    case Agent.start_link(fn -> status_list end, name: name) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> {:error, :already_exists}
      _ -> {:error, :unknown_error}
    end
  end

  defp update_pipeline(name) do
     Agent.update(name, fn(status_list) ->
      [_|remaining_statuss] = status_list
      remaining_statuss
    end)
  end
end
