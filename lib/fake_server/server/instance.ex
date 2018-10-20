defmodule FakeServer.Instance do
  defstruct [
    access: nil,
    errors: [],
    port: nil,
    max_conn: 100,
    router: nil,
    routes: [],
    server_name: nil,
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
         {:ok, port}      <- FakeServer.Port.ensure(server.port),
         server           <- %__MODULE__{server | port: port},
         {:ok, name}      <- ensure_server_name(server.server_name),
         server           <- %__MODULE__{server | server_name: name},
         {:ok, max_conn}  <- ensure_max_conn(server.max_conn),
         server           <- %__MODULE__{server | max_conn: max_conn},
         {:ok, access}    <- FakeServer.Server.Access.start_link,
         server           <- %__MODULE__{server | access: access},
         {:ok, router}    <- FakeServer.Router.create(server.routes, access),
         server           <- %__MODULE__{server | router: router},
         {:ok, _}         <- FakeServer.Cowboy.start_listen(server)
    do
      {:ok, server}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  def stop(server), do: GenServer.stop(server)
  def terminate(_, server), do: FakeServer.Cowboy.stop(server)

  def access_list(server), do: GenServer.call(server, :access_list)
  def handle_call(:access_list, _, server), do: {:reply, FakeServer.Server.Access.access_list(server.access), server}

  defp ensure_server_name(nil), do: {:ok, self()}
  defp ensure_server_name(name) when is_atom(name), do: {:ok, name}
  defp ensure_server_name(name), do: {:error, {name, "server name must be an atom"}}

  defp ensure_max_conn(max_conn) when not is_integer(max_conn), do: {:error, {max_conn, "max_conn must be a positive integer"}}
  defp ensure_max_conn(max_conn) when max_conn < 1, do: {:error, {max_conn, "max_conn must be greater than 0"}}
  defp ensure_max_conn(max_conn), do: {:ok, max_conn}
end
