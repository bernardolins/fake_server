defmodule FakeServer.Cowboy do
  alias FakeServer.Instance

  def start_listen(%Instance{} = server) do
    :cowboy.start_clear(
      server.server_name,
      [port: server.port],
      %{env: %{dispatch: server.router}}
    )
  end

  def stop(%Instance{} = server) do
    :cowboy.stop_listener(server.server_name)
  end
end
