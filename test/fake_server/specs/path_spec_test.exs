defmodule FakeServer.Specs.PathSpecTest do
  use ExUnit.Case

  alias FakeServer.Specs.PathSpec
  alias FakeServer.HTTP.Response

  describe "#new" do
    test "returns an empty PathSpec structure" do
      assert PathSpec.new == %PathSpec{}
    end
  end

  describe "#response" do
    test "returns a response list for a path" do
      spec = PathSpec.new |> PathSpec.configure_response([Response.ok])
      assert PathSpec.response(spec) == [Response.ok]
    end

    test "returns [] if response list not set" do
      spec = PathSpec.new
      assert PathSpec.response(spec) == nil
    end
  end

  describe "#configure_response" do
    test "sets response list for a path" do
      spec = PathSpec.new
      assert PathSpec.response(spec) == nil
      spec = PathSpec.new |> PathSpec.configure_response([Response.ok])
      assert PathSpec.response(spec) == [Response.ok]
    end
  end
end
