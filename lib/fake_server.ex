defmodule FakeServer do
  @moduledoc """
  The server itself. 
  """

  @ip {127, 0, 0, 1}
  @stringified_ip "127.0.0.1"
  @base_port_number 5000
  @max_connections 100

  @doc """
  This function starts a new server. You must provide:
  - a `name` to the server: This identifies the server, and is used to shut it down. 
  - a `status_list`: This is an array containing the statuses of the server. Each request to the server will receive as response the first status on this list. The status is then removed from the list. If no more statuses are available, the server will respond `HTTP 200`.
  - some `options`. Currently the only option accepted is `port`.

  ### Return values
  If the server is started without any error, the return will be `{:ok, address}` tuple. The `address` is the `ip:port` the server listen on.
  Currently `127.0.0.1` is the single `ip` value. The port is a random number between `5001` and `10000`.

  ### Options
  You can set some options on a map. Currently, the only option accepted is `port`. Take a look at the examples to learn how it works.

  ### Examples
  ```elixir
  ## create some status
  FakeServer.Status.create(:status200, %{response_code: 200, response_body: ~s<"username": "mr_user">})
  FakeServer.Status.create(:status500, %{response_code: 500, response_body: ~s<"error": "internal server error">})
  FakeServer.Status.create(:status403, %{response_code: 403, response_body: ~s<"error": "forbidden">})

  FakeServer.run(:server1, :status200) ## with only one status, [] are not needed
  {:ok, "127.0.0.1:9925"}
  FakeServer.run(:server2, [:status200, :status500]) ## with a list of statuses
  {:ok, "127.0.0.1:8388"}
  FakeServer.run(:server3, [:status500, :status403], %{port: 5000}) ## with a default port
  {:ok, "127.0.0.1:5000"}
  FakeServer.run(:server3, [:status200, :status200]) ## you can repeat same status multiple times
  {:ok, "127.0.0.1:7293"}
  ```
  """
  def run(_name, [], _opts), do: {:error, :no_status}
  def run(name, status_list, opts) do
    status_list = List.wrap(status_list)
    name
    |> create_behavior(status_list)
    |> create_routes
    |> add_to_router
    |> server_config(opts)
    |> start_server(name)
  end 

  @doc """ 
  Just an alias to run/3 with empty options.
  """
  def run(name, status_list), do: run(name, status_list, %{})

  @doc """
  Stops a running server. You must provide the server `name`.

  ### Return values
  If the server is running, it will return `:ok`. Otherwise, it will return `{:error, :not_found}`

  ### Examples
  ```elixir
  FakeServer.stop(:running_server)
  :ok
  FakeServer.stop(:invalid_server)
  {:error, :not_found}
  ```
  """
  def stop(name), do: :cowboy.stop_listener(name)

  defp create_behavior(name, status_list) do
    case FakeServer.Behavior.create(name, status_list) do
      {:error, reason} -> {:error, reason}
      {:ok, name} -> [behavior: name]
    end
  end

  defp create_routes({:error, reason}), do: {:error, reason}
  defp create_routes(hander_opts), do: [{:_, FakeServer.Handler, hander_opts}]

  defp add_to_router({:error, reason}), do: {:error, reason}
  defp add_to_router(routes), do: :cowboy_router.compile([{:_, routes}])  

  defp server_config({:error, reason}, _opts), do: {:error, reason}
  defp server_config(routes, %{port: port}) do
    [port: port,
     routes: routes,
     max_connections: 100]
  end
  defp server_config(routes, %{}) do
    [port: choose_port,
     routes: routes,
     max_connections: 100]
  end

  defp start_server({:error, reason}, _name), do: {:error, reason}
  defp start_server(config, name) do
    case :cowboy.start_http(name, @max_connections, [port: config[:port]], [env: [dispatch: config[:routes]]]) do
      {:ok, _} -> {:ok, server_address(config[:port])}
      {:error, :already_started} -> {:error, :already_started}
      {:error, _} -> {:error, :unknown_error}
    end
  end

  defp choose_port do
    case :ranch_tcp.listen(ip: @ip, port: random_port_number) do
      {:ok, socket} ->
        :erlang.port_close(socket)
        random_port_number
      {:error, :eaddrinuse} -> choose_port
    end
  end

  defp random_port_number, do: @base_port_number + :rand.uniform(5000)

  defp server_address(port), do: "#{@stringified_ip}:#{port}"
end
