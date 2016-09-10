defmodule Fakex.Behavior do
  def create(_name, []), do: {:error, :no_action}
  def create(name, action_list) do
    name
    |> validate_name
    |> validate_pipeline(action_list)
  end 

  def next_response(name) do
    case Agent.get(name, fn(action_list) -> List.first(action_list) end) do
      nil -> {:ok, :no_more_actions}
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

  defp validate_pipeline(name_error = {:error, _reason}, _action_list), do: name_error
  defp validate_pipeline(name, action_list) do
    case validate_actions(action_list) do
      :ok -> create_pipeline(name, action_list)
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_actions([]), do: :ok
  defp validate_actions(action_list) do
    [action|remaining_actions] = action_list
    case Fakex.Action.get(action) do
      {:error, _} -> {:error, {:invalid_action, action}}
      {:ok, _} -> validate_actions(remaining_actions)
    end
  end

  defp create_pipeline(name, action_list) do
    case Agent.start_link(fn -> action_list end, name: name) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> {:error, :already_exists}
      _ -> {:error, :unknown_error}
    end
  end

  defp update_pipeline(name) do
     Agent.update(name, fn(action_list) ->
      [_|remaining_actions] = action_list
      remaining_actions
    end)
  end
end
