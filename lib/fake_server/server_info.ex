defmodule FakeServer.ServerInfo do
  defstruct [name: nil, route_responses: %{}, default_response: FakeServer.HTTP.Response.default]
  @enforce_keys[:name]
end
