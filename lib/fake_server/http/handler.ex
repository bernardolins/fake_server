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

    :cowboy_req.reply(response.code, response.headers, response.body, conn)
  end

  defp update_hits(server_id) do
    case EnvAgent.get_env(server_id) do
      nil -> nil
      env ->  EnvAgent.save_env(server_id, %FakeServer.Env{env | hits: env.hits + 1})
    end
  end
end
