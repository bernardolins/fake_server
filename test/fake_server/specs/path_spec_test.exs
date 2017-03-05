defmodule FakeServer.Specs.PathSpecTest do
  use ExUnit.Case

  alias FakeServer.Specs.PathSpec
  alias FakeServer.HTTP.Response

  describe "#new" do
    test "returns an empty PathSpec structure" do
      assert PathSpec.new == %PathSpec{}
    end
  end

  describe "#response_list" do
    test "returns a response list for a path" do
      spec = PathSpec.new |> PathSpec.configure_response_list([Response.ok])
      assert PathSpec.response_list(spec) == [Response.ok]
    end

    test "returns [] if response list not set" do
      spec = PathSpec.new
      assert PathSpec.response_list(spec) == []
    end
  end

  describe "#configure_response_list" do
    test "sets response list for a path" do
      spec = PathSpec.new
      assert PathSpec.response_list(spec) == []
      spec = PathSpec.new |> PathSpec.configure_response_list([Response.ok])
      assert PathSpec.response_list(spec) == [Response.ok]
    end
  end

  describe "#controller" do
    test "returns a controller for a path" do
      spec = PathSpec.new |> PathSpec.configure_controller([module: SomeModule, function: :some_function])
      assert PathSpec.controller(spec) == [module: SomeModule, function: :some_function]
    end

    test "returns [] if response list not set" do
      spec = PathSpec.new
      assert PathSpec.controller(spec) == nil
    end
  end
end
