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
    |> validate_status_list(status_list)
  end 

  def next_response(name) do
    case Agent.get(name, fn(status_list) -> List.first(status_list) end) do
      nil -> {:ok, :no_more_status}
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

  defp validate_status_list(name_error = {:error, _reason}, _status_list), do: name_error
  defp validate_status_list(name, status_list) do
    case validate_status(status_list) do
      :ok -> create_behavior(name, status_list)
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_status([]), do: :ok
  defp validate_status(status_list) do
    [status|remaining_status] = status_list

    case check_current_status(status) do
      :ok -> validate_status(remaining_status)
      {:error, reason} -> {:error, reason}
    end
  end

  defp check_current_status(status) do
    status  
    |> check_status_name
    |> check_status_existence
  end

  defp check_status_name(status) do
    FailWhale.Status.validate_name(status)
  end
  
  defp check_status_existence({:error, reason}), do: {:error, reason}
  defp check_status_existence(status) do
    case FailWhale.Status.get(status) do
      {:error, _} -> {:error, {:invalid_status, status}}
      {:ok, _} -> :ok
    end
  end

  defp create_behavior(name, status_list) do
    case Agent.start_link(fn -> status_list end, name: name) do
      {:ok, _} -> {:ok, name}
      {:error, {:already_started, _}} -> {:error, :already_exists}
      _ -> {:error, :unknown_error}
    end
  end

  defp update_pipeline(name) do
     Agent.update(name, fn(status_list) ->
      [_|remaining_status] = status_list
      remaining_status
    end)
  end
end
