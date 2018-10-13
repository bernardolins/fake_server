defmodule FakeServer.Port do
  @default_port_range 55_000..65_000
  @default_port_allocation_attempts 5

  def ensure(nil) do
    if port = choose_random_port() do
      {:ok, port}
    else
      {:error, "could not allocate a random port"}
    end
  end

  def ensure(port) do
    cond do
      not valid?(port)      -> {:error, {port, "port is not in allowed range: #{inspect @default_port_range}"}}
      not available?(port)  -> {:error, {port, "port is already in use"}}
      true                  -> {:ok, port}
    end
  end

  defp choose_random_port() do
    port_range()
    |> Enum.take_random(@default_port_allocation_attempts)
    |> test_ports()
  end

  defp test_ports([]), do: nil
  defp test_ports([port|port_list]) do
    if available?(port), do: port, else: test_ports(port_list)
  end

  defp valid?(port), do: Enum.member?(port_range(), port)

  defp available?(port) do
    case :ranch_tcp.listen(ip: {0, 0, 0, 0}, port: port) do
      {:ok, socket} ->
        :erlang.port_close(socket)
        true
      {:error, _} ->
        false
    end
  end

  defp port_range() do
    Application.get_env(:fake_server, :port_range, @default_port_range)
  end
end
