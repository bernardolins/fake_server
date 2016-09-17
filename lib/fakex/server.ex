defmodule FailWhale.Server do
  @moduledoc ""

  @doc ""
  def run(behavior) do
    [behavior: behavior]
    |> create_routes
    |> add_to_router
    |> server_config(behavior)
    |> start_server
  end

  @doc ""
  def stop(behavior), do: :cowboy.stop_listener(behavior)

  defp create_routes(hander_opts), do: [{:_, FailWhale.Handler, hander_opts}]

  defp add_to_router(routes), do: :cowboy_router.compile([{:_, routes}])  

  defp server_config(routes, server_behavior) do
    [behavior: server_behavior,
     port: 5000,
     routes: routes,
     max_connections: 100]
  end

  defp start_server(config) do
    case :cowboy.start_http(config[:behavior], config[:max_connections], [port: config[:port]], [env: [dispatch: config[:routes]]]) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
