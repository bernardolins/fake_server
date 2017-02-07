defmodule FakeServer do
#  @moduledoc """
#  The server itself.
#  """
#
#  @ip {127, 0, 0, 1}
#  @stringified_ip "127.0.0.1"
#  @base_port_number 5000
#  @max_connections 100
#
#  @doc """
#  This function starts a new server. You must provide:
#  - a `name` to the server: This identifies the server, and is used to shut it down.
#  - a `status_list`: This is an array containing the statuses of the server. Each request to the server will receive as response the first status on this list. The status is then removed from the list. If no more statuses are available, the server will respond `HTTP 200`.
#  - some `options`. Currently the only option accepted is `port`.
#
#  ### Return values
#  If the server is started without any error, the return will be `{:ok, address}` tuple. The `address` is the `ip:port` the server listen on.
#  Currently `127.0.0.1` is the single `ip` value. The port is a random number between `5001` and `10000`.
#
#  ### Options
#  You can set some options on a map. Currently, the only option accepted is `port`. Take a look at the examples to learn how it works.
#
#  ### Examples
#  ```elixir
#  ## create some status
#  FakeServer.Status.create(:status200, %{response_code: 200, response_body: ~s<"username": "mr_user">})
#  FakeServer.Status.create(:status500, %{response_code: 500, response_body: ~s<"error": "internal server error">})
#  FakeServer.Status.create(:status403, %{response_code: 403, response_body: ~s<"error": "forbidden">})
#
#  FakeServer.run(:server1, :status200) ## with only one status, [] are not needed
#  {:ok, "127.0.0.1:9925"}
#  FakeServer.run(:server2, [:status200, :status500]) ## with a list of statuses
#  {:ok, "127.0.0.1:8388"}
#  FakeServer.run(:server3, [:status500, :status403], %{port: 5000}) ## with a default port
#  {:ok, "127.0.0.1:5000"}
#  FakeServer.run(:server3, [:status200, :status200]) ## you can repeat same status multiple times
#  {:ok, "127.0.0.1:7293"}
#  ```
#  """
#  def run(name, status_list, opts \\ %{}) do
#    case Application.ensure_all_started(:cowboy) do
#      {:ok, _} ->
#        status_list = List.wrap(status_list)
#        name
#        |> create_behavior(status_list)
#        |> create_routes
#        |> add_to_router
#        |> server_config(opts)
#        |> start_server(name)
#      {:error, _} -> raise FakeServer.ServerError, message: "An error occurred while starting the server"
#    end
#  end
#
#  @doc """
#  Stops a running server. You must provide the server `name`.
#
#  ### Return values
#  If the server is running, it will return `:ok`. Otherwise, it will return `{:error, :not_found}`
#
#  ### Examples
#  ```elixir
#  FakeServer.stop(:running_server)
#  :ok
#  FakeServer.stop(:invalid_server)
#  {:error, :not_found}
#  ```
#  """
#  def stop(name), do: :cowboy.stop_listener(name)
#
#  @doc """
#  Modifies behavior of a running server.
#
#  ### Return values
#  If the server is running, it will return `:ok`. Otherwise, it will return `{:error, :not_found}`.
#  Also, if the status list contains one or more inexistent status an :invalid_status error will be returned.
#
#  ### Examples
#  ```elixir
#  FakeServer.modify_behavior(:running_server, [:new_status1, :new_status2])
#  :ok
#  FakeServer.modify_behavior(:invalid_server, [:new_status])
#  {:error, :server_not_found}
#  FakeServer.modify_behavior(:invalid_server, [:inexistent_status])
#  {:error, {:invalid_status, :inexistent_status}}
#  FakeServer.modify_behavior(:invalid_server, [])
#  {:error, :no_status}
#  ```
#  """
#  def modify_behavior(name, new_status_list) do
#    new_status_list = List.wrap(new_status_list)
#    FakeServer.Behavior.modify(name, new_status_list)
#  end
#
#  defp create_behavior(name, status_list) do
#    case FakeServer.Behavior.create(name, status_list) do
#      {:error, :already_exists} -> raise FakeServer.ServerError, message: "The server '#{name}' already exists"
#      {:error, :invalid_name} -> raise FakeServer.NameError, message: "Server name '#{name}' must be an atom"
#      {:error, {:invalid_status, status_name}} -> raise FakeServer.ServerError, message: "Invalid status: '#{status_name}'"
#      {:error, _} -> raise FakeServer.ServerError
#      {:ok, name} -> [behavior: name]
#    end
#  end
#
#  defp create_routes(hander_opts), do: [{:_, FakeServer.Handler, hander_opts}]
#
#  defp add_to_router(routes), do: :cowboy_router.compile([{:_, routes}])
#
#  defp server_config(routes, %{port: port}) do
#    [port: port,
#     routes: routes,
#     max_connections: 100]
#  end
#  defp server_config(routes, %{}) do
#    [port: choose_port(),
#     routes: routes,
#     max_connections: 100]
#  end
#
#  defp start_server(config, name) do
#    case :cowboy.start_http(name, @max_connections, [port: config[:port]], [env: [dispatch: config[:routes]]]) do
#      {:ok, _} -> {:ok, server_address(config[:port])}
#      {:error, :already_exists} -> raise FakeServer.ServerError, message: "The server '#{name}' already exists"
#      {:error, _} -> raise FakeServer.ServerError
#    end
#  end
#
#  defp choose_port do
#    port = random_port_number()
#    case :ranch_tcp.listen(ip: @ip, port: port) do
#      {:ok, socket} ->
#        :erlang.port_close(socket)
#        port
#      {:error, :eaddrinuse} -> choose_port()
#    end
#  end
#
#  defp random_port_number, do: @base_port_number + :rand.uniform(5000)
#
#  defp server_address(port), do: "#{@stringified_ip}:#{port}"
end
