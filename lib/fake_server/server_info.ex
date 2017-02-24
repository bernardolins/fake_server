defmodule FakeServer.ServerInfo do
  defstruct [name: nil, paths: %{}, controllers: %{}, default_response: FakeServer.HTTP.Response.default]
  @enforce_keys[:name]
end
