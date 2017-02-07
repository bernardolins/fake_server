defmodule FakeServer.HTTP.Server do
  @base_port_number 5000
  @base_ip {127, 0, 0, 1}

  def run(config \\ []) do 
    :cowboy.start_http(__MODULE__, 
                       100, 
                       [port: config[:port] || choose_port()], 
                       [env: [dispatch: set_router()]])
  end

  def stop, do: :cowboy.stop_listener(__MODULE__)

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
