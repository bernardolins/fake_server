defmodule FakeServer.Server.AccessTest do
  use ExUnit.Case
  alias FakeServer.Server.Access

  test "compute access for a route" do
    {:ok, server} = Access.start_link
    assert Access.compute_access(server, %FakeServer.Request{path: "/test", method: "PUT", headers: %{}, body: ""})
    assert Access.access_list(server) == [%FakeServer.Request{path: "/test", method: "PUT", headers: %{}, body: ""}]
    Access.stop(server)
  end
end
