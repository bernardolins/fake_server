defmodule FakeServer.Instance do
  @moduledoc false

  defstruct access: nil,
            errors: [],
            port: nil,
            max_conn: 100,
            router: nil,
            routes: [],
            server_name: nil

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
    with server <- struct(__MODULE__, config),
         {:ok, port} <- FakeServer.Port.ensure(server.port),
         server <- %__MODULE__{server | port: port},
         {:ok, name} <- ensure_server_name(server.server_name),
         server <- %__MODULE__{server | server_name: name},
         {:ok, max_conn} <- ensure_max_conn(server.max_conn),
         server <- %__MODULE__{server | max_conn: max_conn},
         {:ok, access} <- FakeServer.Server.Access.start_link(),
         server <- %__MODULE__{server | access: access},
         {:ok, router} <- FakeServer.Router.create(server.routes, access),
         server <- %__MODULE__{server | router: router},
         {:ok, _} <- FakeServer.Cowboy.start_listen(server) do
      {:ok, server}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  def stop(server), do: GenServer.stop(server)
  def terminate(_, server), do: FakeServer.Cowboy.stop(server)

  def add_route(server, path, response), do: GenServer.call(server, {:add_route, path, response})
  def access_list(server), do: GenServer.call(server, :access_list)
  def port(server), do: GenServer.call(server, :port)
  def state(server), do: GenServer.call(server, :state)

  def handle_call({:add_route, path, response}, _, server) do
    case update_router(path, response, server) do
      {:ok, new_server} -> {:reply, :ok, new_server}
      {:error, _} = error -> {:reply, error, server}
    end
  end

  def handle_call(:access_list, _, server) do
    case get_access_list(server) do
      {:ok, _} = reply -> {:reply, reply, server}
      {:error, _} = error -> {:reply, error, server}
    end
  end

  def handle_call(:port, _, server) do
    {:reply, server.port, server}
  end

  def handle_call(:state, _, server) do
    {:reply, server, server}
  end

  defp ensure_server_name(nil), do: {:ok, self()}
  defp ensure_server_name(name) when is_atom(name), do: {:ok, name}
  defp ensure_server_name(name), do: {:error, {name, "server name must be an atom"}}

  defp ensure_max_conn(max_conn) when not is_integer(max_conn),
    do: {:error, {max_conn, "max_conn must be a positive integer"}}

  defp ensure_max_conn(max_conn) when max_conn < 1,
    do: {:error, {max_conn, "max_conn must be greater than 0"}}

  defp ensure_max_conn(max_conn), do: {:ok, max_conn}

  defp get_access_list(server) do
    case FakeServer.Server.Access.access_list(server.access) do
      access_list when is_list(access_list) -> {:ok, access_list}
      _ -> {:error, {:access_list, "could not get access list"}}
    end
  end

  defp update_router(path, response, server) do
    with {:ok, route} <- FakeServer.Route.create(path: path, response: response),
         routes <- [route | server.routes],
         {:ok, router} <- FakeServer.Router.create(routes, server.access) do
      :cowboy.set_env(server.server_name, :dispatch, router)
      {:ok, %__MODULE__{server | routes: routes, router: router}}
    else
      error -> error
    end
  end
end
