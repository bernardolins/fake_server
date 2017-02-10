defmodule FakeServer.HTTP.Server do
  @base_port_number 5000
  @base_ip {127, 0, 0, 1}

  def run(config \\ []) do
    port = config[:port] || choose_port()
    :cowboy.start_http(__MODULE__,
                       100,
                       [port: port],
                       [env: [dispatch: set_router()]])
    {:ok, port}
  end

  def stop, do: :cowboy.stop_listener(__MODULE__)

  def update_router do
    :cowboy.set_env(__MODULE__, :dispatch, set_router)
  end

  defp set_router do
    routes = FakeServer.Agents.RouterAgent.take_all
    |> Enum.map(&({&1, FakeServer.HTTP.Handler, []}))

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
end
