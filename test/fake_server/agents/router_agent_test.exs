defmodule FakeServer.Agents.RoutergentTest do
  use ExUnit.Case

  alias FakeServer.Agents.RouterAgent

  describe "#start_link" do
    test "start an agent with RouterAgent module name and an empty map" do
      {:ok, _} = RouterAgent.start_link
      assert Agent.get(RouterAgent, fn(routes) -> routes end) == %{}
      RouterAgent.stop
    end

    test "returns error if the server already exists" do
      {:ok, pid} = RouterAgent.start_link
      assert RouterAgent.start_link == {:error, {:already_started, pid}}
      RouterAgent.stop
    end
  end

  describe "#stop" do
    test "stops the route agent if it's started" do
      {:ok, _} = RouterAgent.start_link
      assert RouterAgent.stop == :ok
    end

    test "throw :noproc error when stopping an agent no started" do
      assert catch_exit(RouterAgent.stop) == :noproc
    end
  end

  describe "#put_route" do
    test "saves a route" do
      {:ok, _} = RouterAgent.start_link

      server_name = :server
      route1 = "/test1"
      route2 = "/test2"
      RouterAgent.put_route(server_name, route1)
      RouterAgent.put_route(server_name, route2)

      assert Agent.get(RouterAgent, fn(routes) -> routes end) == %{server: [route2, route1]}
    end

    test "raises function_clause error if a route is not a bitstring" do
      {:ok, _} = RouterAgent.start_link

      server_name = :server
      assert catch_error(RouterAgent.put_route(server_name, 1)) == :function_clause
      assert catch_error(RouterAgent.put_route(server_name, [])) == :function_clause
      assert catch_error(RouterAgent.put_route(server_name, %{})) == :function_clause
    end
  end

  describe "#take_all" do
    test "takes all routes and keep routes for the given server on routes agent" do
      {:ok, _} = RouterAgent.start_link

      server_name = :server
      route1 = "/test1"
      route2 = "/test2"
      RouterAgent.put_route(server_name, route1)
      RouterAgent.put_route(server_name, route2)

      assert RouterAgent.take_all(server_name) == [route2, route1]
      assert RouterAgent.take_all(server_name) == [route2, route1]
    end
  end
end
