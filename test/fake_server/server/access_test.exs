defmodule FakeServer.Server.AccessTest do
  use ExUnit.Case
  alias FakeServer.Server.Access

  test "compute access for a route" do
    {:ok, server} = Access.start_link
    assert Access.compute_access(server, "/test")
    assert Access.access_list(server) == ["/test"]
    Access.stop(server)
  end
end
