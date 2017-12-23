defmodule FakeServer.Specs.ServerSpec do
  @moduledoc false

  defstruct [id: nil, paths: %{}, default_response: FakeServer.HTTP.Response.default, port: nil]
  @enforce_keys[:name]

  @id_length 16
  @base_ip {127, 0, 0, 1}
  @base_port_number 5000

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

  def response_for(%ServerSpec{} = spec, path) do
    case spec.paths[path] do
      nil -> nil
      path_spec -> PathSpec.response(path_spec)
    end
  end

  def configure_response_for(%ServerSpec{} = spec, path, new_response) do
    path_spec = (spec.paths[path] || PathSpec.new) |> PathSpec.configure_response(new_response)
    new_path_list = Map.put(spec.paths, path, path_spec)
    %ServerSpec{spec | paths: new_path_list}
  end

  def default_response(%ServerSpec{} = spec) do
    spec.default_response
  end

  def configure_default_response(%ServerSpec{} = spec, new_default_response) do
    spec = configure_response_for(spec, :_, [])
    %ServerSpec{spec | default_response: new_default_response}
  end

  # thanks http://stackoverflow.com/a/32002566 :)
  defp random_server_id do
    random = :crypto.strong_rand_bytes(@id_length)
    random
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
        choose_port(port + 1)
    end
  end

  defp random_port_number, do: @base_port_number + :rand.uniform(5000)
end
