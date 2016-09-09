defmodule Fakex.Pipeline do
  def create(_name, []), do: {:error, :no_behavior}
  def create(name, behavior_list) do
    name
    |> validate_name
    |> validate_pipeline(behavior_list)
  end 

  defp validate_name name do
    case is_atom name do
      true -> name
      false -> {:error, :invalid_name}
    end
  end

  defp validate_pipeline(name_error = {:error, _reason}, _behavior_list), do: name_error
  defp validate_pipeline(name, behavior_list) do
    case validate_behaviors(behavior_list) do
      :ok -> create_pipeline(name, behavior_list)
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_behaviors([]), do: :ok
  defp validate_behaviors(behavior_list) do
    [behavior|remaining_behaviors] = behavior_list
    case Fakex.Behavior.get(behavior) do
      {:error, _} -> {:error, {:invalid_behavior, behavior}}
      {:ok, _} -> validate_behaviors(remaining_behaviors)
    end
  end

  defp create_pipeline(name, behavior_list) do
    case Agent.start_link(fn -> {0, behavior_list} end, name: name) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> {:error, :already_exists}
      _ -> {:error, :unknown_error}
    end
  end
end
