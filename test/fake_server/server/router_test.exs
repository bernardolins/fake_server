defmodule FakeServerRouterTest do
  use ExUnit.Case, async: true

  describe "#create" do
    test "returns {:ok, router} with an empty route list" do
      assert {:ok, [{_, _, route_list}]} = FakeServer.Router.create([])
      assert length(route_list) == 0
    end

    test "returns {:ok, router} including only valid routes" do
      routes = [1, FakeServer.Route.create!, %FakeServer.Route{path: "invalid"}]
      assert {:ok, [{_, _, route_list}]} = FakeServer.Router.create(routes)
      assert length(route_list) == 1
    end
  end

  describe "#reset" do
    test "returns {:ok, empty_router}" do
      routes = [FakeServer.Route.create!]
      assert {:ok, [{_, _, route_list}]} = FakeServer.Router.create(routes)
      assert length(route_list) == 1
      assert {:ok, [{_, _, route_list}]} = FakeServer.Router.reset()
      assert length(route_list) == 0
    end
  end
end
