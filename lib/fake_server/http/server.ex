defmodule FakeServer.HTTP.Server do
  @moduledoc false

  alias FakeServer.Specs.ServerSpec
  alias FakeServer.Agents.ServerAgent
  alias FakeServer.HTTP.Response

  def run(opts \\ %{}) do
    server_spec = ServerSpec.new(opts)
    router = set_router(server_spec, [id: server_spec.id])

    :cowboy.start_http(server_spec.id, 100, [port: server_spec.port], [env: [dispatch: router]])
    ServerAgent.save_spec(server_spec)
    {:ok, server_spec.id, server_spec.port}
  end

  def add_route(server_id, path, response_list \\ []) do
    ServerAgent.get_spec(server_id)
    |> ServerSpec.configure_response_list_for(path, response_list)
    |> update_router
    |> ServerAgent.save_spec
  end

  def add_controller(server_id, path, [module: _, function: _] = controller) do
    ServerAgent.get_spec(server_id)
    |> ServerSpec.configure_controller_for(path, controller)
    |> update_router
    |> ServerAgent.save_spec
  end

  def set_default_response(server_id, %Response{} = default_response) do
    ServerAgent.get_spec(server_id)
    |> ServerSpec.configure_default_response(default_response)
    |> ServerAgent.save_spec
  end

  def stop(id), do: :cowboy.stop_listener(id)

  defp update_router(spec) do
    :cowboy.set_env(spec.id, :dispatch, (set_router(spec)))
    spec
  end

  defp set_router(server_spec, opts \\ []) do
    routes = ServerSpec.path_list_for(server_spec)
    |> Enum.map(&({&1, FakeServer.HTTP.Handler, opts ++ [id: server_spec.id]}))
    :cowboy_router.compile([{:_, routes}])
  end
end
