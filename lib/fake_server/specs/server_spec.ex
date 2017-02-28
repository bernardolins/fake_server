defmodule FakeServer.Specs.ServerSpec do
  defstruct [id: nil, paths: %{}, controllers: %{}, default_response: FakeServer.HTTP.Response.default, port: nil]
  @enforce_keys[:name]

  @id_length 16
  @base_ip {127, 0, 0, 1}
  @base_port_number 5000
  @accepted_options [:id, :default_response, :port]

  alias FakeServer.Specs.ServerSpec
  alias FakeServer.Specs.PathSpec

  def new(opts \\ %{}) do
    default_options = %{id: random_server_id(), port: choose_port()}
    opts = Map.merge(default_options, opts)
    struct(ServerSpec, opts)
  end

  def id(%ServerSpec{} = spec) do
    spec.id
  end

  def path_list_for(%ServerSpec{} = spec) do
    Map.keys(spec.paths)
  end

  def response_list_for(%ServerSpec{} = spec, path) do
    case spec.paths[path] do
      nil -> nil
      path_spec -> PathSpec.response_list(path_spec)
    end
  end

  def configure_response_list_for(%ServerSpec{} = spec, path, new_response_list) do
    new_response_list = List.wrap(new_response_list)
    path_spec = (spec.paths[path] || PathSpec.new) |> PathSpec.configure_response_list(new_response_list)
    new_path_list = Map.put(spec.paths, path, path_spec)
    %ServerSpec{spec | paths: new_path_list}
  end

  def controller_for(%ServerSpec{} = spec, path) do
    case spec.paths[path] do
      nil -> nil
      path_spec -> PathSpec.controller(path_spec)
    end
  end

  def configure_controller_for(%ServerSpec{} = spec, path, [module: _, function: _] = new_controller) do
    path_spec = (spec.paths[path] || PathSpec.new) |> PathSpec.configure_controller(new_controller)
    new_path_list = Map.put(spec.paths, path, path_spec)
    %ServerSpec{spec | paths: new_path_list}
  end

  def default_response(%ServerSpec{} = spec) do
    spec.default_response
  end

  def configure_default_response(%ServerSpec{} = spec, new_default_response, options \\ %{}) do
    spec = configure_response_list_for(spec, :_, [])
    %ServerSpec{spec | default_response: new_default_response}
  end

  # thanks http://stackoverflow.com/a/32002566 :)
  defp random_server_id do
    :crypto.strong_rand_bytes(@id_length)
    |> Base.url_encode64
    |> binary_part(0, @id_length)
    |> String.to_atom
  end

  defp choose_port(port \\ nil) do
    port = port || random_port_number()
    case :ranch_tcp.listen(ip: @base_ip, port: port) do
      {:ok, socket} ->
        :erlang.port_close(socket)
        port
      {:error, :eaddrinuse} ->
        choose_port(port+1)
    end
  end

  defp random_port_number, do: @base_port_number + :rand.uniform(5000)
end
