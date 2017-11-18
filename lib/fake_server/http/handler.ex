defmodule FakeServer.HTTP.Handler do
  @moduledoc false

  alias FakeServer.Specs.ServerSpec
  alias FakeServer.Agents.ServerAgent
  alias FakeServer.Agents.EnvAgent

  def init(_type, conn, opts), do: {:ok, conn, opts}

  def handle(conn, opts) do
    case ServerAgent.get_spec(opts[:id]) do
      nil -> :cowboy_req.reply(500, [], "Server spec not found", conn)
      spec ->
        update_hits(spec.id)
        path = elem(:cowboy_req.path(conn), 0)
        spec
        |> check_controller(path, conn)
        |> reply(path, conn)
    end

    {:ok, conn, opts}
  end

  def terminate(_reason, _req, _state), do: :ok

  defp check_controller(spec, path, conn) do
    case ServerSpec.controller_for(spec, path) do
      nil -> spec
      controller ->
        controller_response_list = apply(controller[:module], controller[:function], [conn])
        spec
        |> ServerSpec.configure_response_list_for(path, controller_response_list)
        |> ServerAgent.save_spec
    end
  end

  defp reply(spec, path, conn) do
    response = case ServerSpec.response_list_for(spec, path) do
      [] -> spec.default_response
      [response|remaining_responses] ->
        spec
        |> ServerSpec.configure_response_list_for(path, remaining_responses)
        |> ServerAgent.save_spec
        response
    end

    try do
      headers = validate_headers(response.headers)
      body = validate_body(response.body)
      :cowboy_req.reply(response.code, headers, body, conn)
    rescue e in ArgumentError -> :cowboy_req.reply(500, [], ~s<{"message":#{inspect e.message}}>, conn)
    end
  end

  defp update_hits(server_id) do
    case EnvAgent.get_env(server_id) do
      nil -> nil
      env ->  EnvAgent.save_env(server_id, %FakeServer.Env{env | hits: env.hits + 1})
    end
  end

  defp validate_headers(headers) when is_list(headers) do
    headers
    |> check_headers_and_value_types
  end
  defp validate_headers(headers) when is_map(headers) do
    headers
    |> check_headers_and_value_types
    |> Enum.into([])
  end
  defp validate_headers(headers), do: raise ArgumentError, "Invalid headers: #{inspect headers}: Must be a keyword list or a map"

  defp validate_body(body) when is_bitstring(body), do: body
  defp validate_body(body) do
    case Poison.encode(body) do
      {:ok, encoded_body} -> encoded_body
      {:error, _} -> raise ArgumentError, "Could not encode body: #{inspect body}"
    end
  end

  defp check_headers_and_value_types(headers) do
    headers
    |> Enum.each(fn({header, value}) ->
      if !is_binary(header) and !is_list(header), do: raise ArgumentError, "Invalid header #{inspect header}: Must be a binary"
      if !is_binary(value) and !is_list(value), do: raise ArgumentError, "Invalid header value #{inspect value}: Must be a binary or a list"
    end)
    headers
  end
end
