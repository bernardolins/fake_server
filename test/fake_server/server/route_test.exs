defmodule FakeServer.RouteTest do
  use ExUnit.Case

  alias FakeServer.Route
  alias FakeServer.Response

  describe "#create" do
    test "returns {:error, reason} if path is not a string" do
      assert {:error, {1, "path must be a string"}} == Route.create(path: 1)
      assert {:error, {'/', "path must be a string"}} == Route.create(path: '/')
      assert {:error, {nil, "path must be a string"}} == Route.create(path: nil)
      assert {:error, {[], "path must be a string"}} == Route.create(path: [])
      assert {:error, {['/', 'test'], "path must be a string"}} == Route.create(path: ['/', 'test'])
      assert {:error, {%{}, "path must be a string"}} == Route.create(path: %{})
    end

    test "returns {:error, reason} if path does not begins with '/'" do
      assert {:error, {"abc", "path must start with '/'"}} == Route.create(path: "abc")
    end

    test "returns {:error, reason} if route response is not valid" do
      message = "response must be a function, a Response struct, or a list of Response structs"
      assert {:error, {1, message}} == Route.create(response: 1)
      assert {:error, {nil, message}} == Route.create(response: nil)
      assert {:error, {"abc", message}} == Route.create(response: "abc")
      assert {:error, {%{}, message}} == Route.create(response: %{})
    end

    test "returns {:error, reason} if function arity is not 1" do
      assert {:error, {_, "response function arity must be 1"}} = Route.create(response: fn -> :ok end)
    end

    test "returns {:ok, route} if all validation passes and response is a function" do
      assert {:ok, _} = Route.create(response: fn(_) -> :ok end)
    end

    test "returns {:ok, route} if all validation passes and response is an empty list" do
      assert {:ok, _} = Route.create(response: [])
    end

    test "returns {:ok, route} if all validation passes and response is a list of Response structs" do
      assert {:ok, _} = Route.create(response: [Response.ok!, Response.not_found!])
    end

    test "returns {:ok, route} if all validation passes and response is a Response struct" do
      assert {:ok, _} = Route.create(response: Response.not_found!)
    end
  end

  describe "#create!" do
    test "raises FakeSever.Error if path is not a string" do
      assert_raise FakeServer.Error, fn -> Route.create!(path: 1) end
      assert_raise FakeServer.Error, fn -> Route.create!(path: '/') end
      assert_raise FakeServer.Error, fn -> Route.create!(path: nil) end
      assert_raise FakeServer.Error, fn -> Route.create!(path: []) end
      assert_raise FakeServer.Error, fn -> Route.create!(path: ['/', 'test']) end
      assert_raise FakeServer.Error, fn -> Route.create!(path: %{}) end
    end

    test "raises FakeSever.Error if path does not begins with '/'" do
      assert_raise FakeServer.Error, fn -> Route.create!(path: "abc") end
    end

    test "raises FakeSever.Error if route response is not valid" do
      assert_raise FakeServer.Error, fn -> Route.create!(response: 1) end
      assert_raise FakeServer.Error, fn -> Route.create!(response: nil) end
      assert_raise FakeServer.Error, fn -> Route.create!(response: "abc") end
      assert_raise FakeServer.Error, fn -> Route.create!(response: %{}) end
    end

    test "raise FakeServer.Error if function arity is not 1" do
      assert_raise FakeServer.Error, fn -> Route.create!(response: fn -> :ok end) end
    end

    test "returns a Route struct if all validation passes and response is a function" do
      assert %Route{} = Route.create!(response: fn(_) -> :ok end)
    end

    test "returns a Route struct if all validation passes and response is an empty list" do
      assert %Route{} = Route.create!(response: [])
    end

    test "returns a Route struct if all validation passes and response is a list of Response structs" do
      assert %Route{} = Route.create!(response: [Response.ok!, Response.not_found!])
    end

    test "returns a Route struct if all validation passes and response is a Response struct" do
      assert %Route{} = Route.create!(response: Response.not_found!)
    end
  end

  describe "#path" do
    test "returns a valid route path" do
      assert "/" == Route.path(Route.create!)
      assert "/abc" == Route.path(Route.create!(path: "/abc"))
    end
  end

  describe "#handler" do
    test "returns the route handler" do
      assert FakeServer.Handlers.FunctionHandler == Route.handler(Route.create!(response: fn(_) -> :ok end))
      assert Handler == Route.handler(Route.create!(response: []))
      assert Handler == Route.handler(Route.create!(response: [Response.ok!, Response.not_found!]))
      assert FakeServer.Handlers.ResponseHandler == Route.handler(Route.create!(response: Response.ok!))
    end
  end

  describe "#valid?" do
    test "returns false if path is not a string" do
      assert false == Route.valid?(%Route{path: 1})
      assert false == Route.valid?(%Route{path: '/'})
      assert false == Route.valid?(%Route{path: nil})
      assert false == Route.valid?(%Route{path: []})
      assert false == Route.valid?(%Route{path: ['/', 'test']})
      assert false == Route.valid?(%Route{path: %{}})
    end
    test "returns false if path does not starts with a '/'" do
      assert false == Route.valid?(%Route{path: "abc"})
      assert false == Route.valid?(%Route{path: "abc/cde"})
    end

    test "returns false if response is invalid" do
      assert false == Route.valid?(%Route{response: 1})
      assert false == Route.valid?(%Route{response: nil})
      assert false == Route.valid?(%Route{response: "abc"})
      assert false == Route.valid?(%Route{response: %{}})
    end

    test "returns true if all validation passes" do
      assert true == Route.valid?(%Route{})
      assert true == Route.valid?(Route.create!(path: "/abc/cde"))
      assert true == Route.valid?(Route.create!(response: fn(_) -> :ok end))
      assert true == Route.valid?(Route.create!(response: []))
      assert true == Route.valid?(Route.create!(response: [Response.ok!, Response.not_found!]))
      assert true == Route.valid?(Route.create!(response: Response.ok!))
    end
  end
end
