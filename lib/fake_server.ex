defmodule FakeServer do
  @moduledoc """
  FakeServer
  """

  @ip {127, 0, 0, 1}
  @stringified_ip "127.0.0.1"
  @base_port_number 5000
  @max_connections 100

  @doc ""
  def run(_name, []), do: {:error, :no_status}
  def run(name, status_list) do
    status_list = List.wrap(status_list)
    name
    |> create_behavior(status_list)
    |> create_routes
    |> add_to_router
    |> server_config
    |> start_server(name)
  end 

  def run(name, status_list, opts = %{}) do
    status_list = List.wrap(status_list)
    name
    |> create_behavior(status_list)
    |> create_routes
    |> add_to_router
    |> server_config(opts)
    |> start_server(name)
  end

  @doc ""
  def stop(name), do: :cowboy.stop_listener(name)

  defp create_behavior(name, status_list) do
    case FakeServer.Behavior.create(name, status_list) do
      {:error, reason} -> {:error, reason}
      {:ok, name} -> [behavior: name]
    end
  end

  defp create_routes({:error, reason}), do: {:error, reason}
  defp create_routes(hander_opts), do: [{:_, FakeServer.Handler, hander_opts}]

  defp add_to_router({:error, reason}), do: {:error, reason}
  defp add_to_router(routes), do: :cowboy_router.compile([{:_, routes}])  

  defp server_config({:error, reason}), do: {:error, reason}
  defp server_config(routes) do
    [port: choose_port,
     routes: routes,
     max_connections: 100]
  end

  defp server_config({:error, reason}, _opts), do: {:error, reason}
  defp server_config(routes, %{port: port}) do
    [port: port,
     routes: routes,
     max_connections: 100]
  end

  defp start_server({:error, reason}, _name), do: {:error, reason}
  defp start_server(config, name) do
    case :cowboy.start_http(name, @max_connections, [port: config[:port]], [env: [dispatch: config[:routes]]]) do
      {:ok, _} -> {:ok, server_address(config[:port])}
      {:error, :already_started} -> {:error, :already_started}
      {:error, _} -> {:error, :unknown_error}
    end
  end

  defp choose_port do
    case :ranch_tcp.listen(ip: @ip, port: random_port_number) do
      {:ok, socket} ->
        :erlang.port_close(socket)
        random_port_number
      {:error, :eaddrinuse} -> choose_port
    end
  end

  defp random_port_number, do: @base_port_number + :rand.uniform(5000)

  defp server_address(port), do: "#{@stringified_ip}:#{port}"
end
