defmodule FakeServer.HTTP.Server do
  @base_port_number 5000
  @base_ip {127, 0, 0, 1}

  def run(config \\ []) do
    server_name = config[:name] || random_server_name()
    port = config[:port] || choose_port()

    FakeServer.Agents.ServerAgent.put_server(server_name)
    router = set_router(server_name, [name: server_name])

    :cowboy.start_http(server_name, 100, [port: port], [env: [dispatch: router]])
    {:ok, server_name, port}
  end

  def stop(server_name), do: :cowboy.stop_listener(__MODULE__)

  def update_router(server_name) do
    :cowboy.set_env(server_name, :dispatch, (set_router(server_name)))
  end

  defp set_router(server_name, opts \\ []) do
    routes = FakeServer.Agents.ServerAgent.take_server_paths(server_name)
    |> Enum.map(&({&1, FakeServer.HTTP.Handler, [name: server_name]}))

    :cowboy_router.compile([{:_, routes}])
  end

  defp choose_port do
    port = random_port_number()
    case :ranch_tcp.listen(ip: @base_ip, port: port) do
      {:ok, socket} ->
        :erlang.port_close(socket)
        port
      {:error, :eaddrinuse} -> choose_port()
    end
  end

  defp random_port_number, do: @base_port_number + :rand.uniform(5000)

  # thanks http://stackoverflow.com/a/32002566 :)
  defp random_server_name(length \\ 16) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64
    |> binary_part(0, length)
    |> String.to_atom
  end
end
