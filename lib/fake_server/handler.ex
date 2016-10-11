defmodule FakeServer.Handler do
  @moduledoc false

  def init(_type, conn, opts), do: {:ok, conn, opts}

  def handle(conn, opts) do
    opts[:behavior]
    |> check_behavior
    |> respond_accordingly(conn)
    |> format_response(conn, opts)
  end

  def terminate(_reason, _req, _state), do: :ok

  defp check_behavior(nil), do: {:error, :invalid_status_list}
  defp check_behavior(behavior) do
    case FakeServer.Behavior.next_response(behavior) do
      {:error, _} -> default_response
      {:ok, :no_more_status} -> default_response
      {:ok, response} -> get_response(response)
    end
  end

  defp default_response, do: %{response_code: 200, response_body: ~s<"status": "no more actions">}

  defp get_response(response) do
    case FakeServer.Status.get(response) do
      {:ok, response} -> response
      {:error, reason} -> {:error, reason}
    end
  end

  defp respond_accordingly({:error, reason}, _conn), do: {:error, reason}
  defp respond_accordingly(response, conn) do
    case :cowboy_req.reply(response[:response_code], response[:response_headers], response[:response_body], conn) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp format_response(:ok, conn, opts), do: {:ok, conn, opts}
  defp format_response({:error, reason}, conn, _opts), do: {:shutdown, conn, reason}
end
