defmodule FakeServer.ResponseList do
  @moduledoc false

  def start_link(), do: Agent.start_link(fn -> [] end)
  def stop(list_id), do: Agent.stop(list_id)

  def add_response(list_id, response) do
    case FakeServer.Response.validate(response) do
      :ok ->
        Agent.update(list_id, &(&1 ++ [response]))
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_next(list_id) do
    Agent.get_and_update(list_id, fn
      [response | responses] -> {response, responses}
      [] -> {FakeServer.Response.default!(), []}
    end)
  end
end
