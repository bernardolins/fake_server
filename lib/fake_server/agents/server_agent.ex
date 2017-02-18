defmodule FakeServer.Agents.ServerAgent do
  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  def put_server(server_id) do
    Agent.update(__MODULE__, fn(servers) ->
      case servers[server_id] do
        nil ->
          server_info = %FakeServer.ServerInfo{name: server_id}
          Keyword.put(servers, server_id, server_info)
        server_info ->
          servers
      end
    end)
  end

  # :ok or {:error, reason}
  def put_responses_to_path(server_id, path, responses) do
    Agent.update(__MODULE__, fn(servers) ->
      case servers[server_id] do
        nil ->
          server_info = %FakeServer.ServerInfo{name: server_id, route_responses: Map.put(%{}, path, responses)}
          Keyword.put(servers, server_id, server_info)
        server_info ->
          server_info = %FakeServer.ServerInfo{server_info | route_responses: Map.put(server_info.route_responses, path, responses)}
          Keyword.put(servers, server_id, server_info)
      end
    end)
  end

  # :ok or {:error, reason}
  def put_default_response(_server_id, nil), do: nil
  def put_default_response(server_id, %FakeServer.HTTP.Response{} = default_response) do
    Agent.update(__MODULE__, fn(servers) ->
      server_info = servers[server_id]
      updated_server_info = %FakeServer.ServerInfo{server_info | default_response: default_response}
      Keyword.put(servers, server_id, updated_server_info)
    end)
  end

  def take_server_info(server_id) do
    Agent.get(__MODULE__, fn(servers) -> servers[server_id] end)
  end

  # ["/some/path"] or nil
  def take_server_paths(server_id) do
    Agent.get(__MODULE__, fn(servers) ->
      case servers[server_id] do
        nil -> nil
        server_route_list -> Map.keys(server_route_list.route_responses)
      end
    end)
  end

  # %[%Response{}] or nil
  def take_next_response_to_path(server_id, path) do
    case server_response_list_for_path(server_id, path) do
      nil -> nil
      [] -> server_default_response(server_id)
      server_route_list ->
        [next_response|route_responses] = server_route_list
        put_responses_to_path(server_id, path, route_responses)
        next_response
    end
  end

  # nil or %Response{}
  defp server_default_response(server_id) do
    Agent.get(__MODULE__, fn(servers) ->
      case servers[server_id] do
        nil -> nil
        server_info -> server_info.default_response
      end
    end)
  end

  defp server_response_list_for_path(server_id, path) do
    servers = Agent.get(__MODULE__, &(&1))
    case servers[server_id] do
      nil -> nil
      server_info -> server_info.route_responses[path]
    end
  end
end
