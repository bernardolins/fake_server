defmodule FakeServer.API.ServerSpec do
  defstruct [id: nil, paths: %{}, controllers: %{}, default_response: FakeServer.HTTP.Response.default]
  @enforce_keys[:name]

  @id_length 16

  alias FakeServer.API.ServerSpec
  alias FakeServer.API.PathSpec

  require IEx

  def new do
    %ServerSpec{id: random_server_id()}
  end

  def id(%ServerSpec{} = spec) do
    spec.id
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
end
