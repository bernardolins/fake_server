defmodule FakeServer.Instance do
  defstruct [
    errors: [],
    port: nil,
    max_conn: 100,
    router: nil,
    routes: [],
    server_name: nil,
    server_ref: nil
  ]

  def run(config \\ []) do
    case ensure_server_name(config[:server_name]) do
      {:ok, pid} when is_pid(pid) ->
        GenServer.start(__MODULE__, config)
      {:ok, name} ->
        GenServer.start(__MODULE__, config, name: name)
      error ->
        error
    end
  end

  def init(config) do
    with server           <- struct(__MODULE__, config),
         {:ok, router}    <- FakeServer.Router.create(server.routes),
         server           <- %__MODULE__{server | router: router},
         {:ok, port}      <- FakeServer.Port.ensure(server.port),
         server           <- %__MODULE__{server | port: port},
         {:ok, name}      <- ensure_server_name(server.server_name),
         server           <- %__MODULE__{server | server_name: name},
         {:ok, max_conn}  <- ensure_max_conn(server.max_conn),
         server           <- %__MODULE__{server | max_conn: max_conn},
         {:ok, pid}       <- FakeServer.Cowboy.start_listen(server),
         server           <- %__MODULE__{server | server_ref: pid}
    do
      {:ok, server}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  def stop(server), do: GenServer.stop(server)
  def terminate(_, server), do: FakeServer.Cowboy.stop(server)

  defp ensure_server_name(nil), do: {:ok, self()}
  defp ensure_server_name(name) when is_atom(name), do: {:ok, name}
  defp ensure_server_name(name), do: {:error, {name, "server name must be an atom"}}

  defp ensure_max_conn(max_conn) when not is_integer(max_conn), do: {:error, {max_conn, "max_conn must be a positive integer"}}
  defp ensure_max_conn(max_conn) when max_conn < 1, do: {:error, {max_conn, "max_conn must be greater than 0"}}
  defp ensure_max_conn(max_conn), do: {:ok, max_conn}
end
