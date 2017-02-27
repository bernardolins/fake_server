defmodule FakeServer.Specs.ServerSpecTest do
  use ExUnit.Case

  alias FakeServer.Specs.ServerSpec

  import Mock

  describe "#new" do
    test "returns a ServerSpec structure with a given server_id and random port" do
      spec = ServerSpec.new(:some_id)
      assert spec == %ServerSpec{id: :some_id, port: spec.port}
    end

    test "returns a ServerSpec with a random server_id and port number if neither id nor port are provided " do
      with_mock Base, [url_encode64: fn(_) -> "abcdefghijklmnop" end] do
        spec = ServerSpec.new
        assert spec == %ServerSpec{id: :abcdefghijklmnop, port: spec.port}
      end
    end

    test "returns a ServerSpec structure with a given port" do
      assert ServerSpec.new(:some_id, 8080) == %ServerSpec{id: :some_id, port: 8080}
    end

    test "use next available port if the chosen one is taken" do
      with_mock :rand, [:unstick], [uniform: fn(_) -> 1 end] do
        {:ok, socket} = :ranch_tcp.listen(ip: {127,0,0,1}, port: 5001)
        spec = ServerSpec.new
        assert spec.port == 5002
        :erlang.port_close(socket)
      end
    end
  end

  describe "#id" do
    test "returns server spec when id is random" do
      server = ServerSpec.new
      assert ServerSpec.id(server) == server.id
    end

    test "returns server spec when id is provided" do
      server = ServerSpec.new(:some_id)
      assert ServerSpec.id(server) == :some_id
    end
  end

  describe "#response_list_for" do
    test "returns nil when path does not exists on spec" do
      assert ServerSpec.new
      |> ServerSpec.response_list_for("/path") == nil
    end

    test "returns [] when path exists but list is empty" do
      spec = ServerSpec.new |> ServerSpec.configure_response_list_for("/path", [])
      assert ServerSpec.response_list_for(spec, "/path") == []
    end

    test "returns a list when path exists and list is not empty" do
      spec = ServerSpec.new |> ServerSpec.configure_response_list_for("/path", [FakeServer.HTTP.Response.ok])
      assert ServerSpec.response_list_for(spec, "/path") == [FakeServer.HTTP.Response.ok]
    end
  end

  describe "#configure_response_list" do
    test "saves an empty list to path on a server" do
      spec = ServerSpec.new
      assert ServerSpec.response_list_for(spec, "/path") == nil
      spec = ServerSpec.configure_response_list_for(spec, "/path", [])
      assert ServerSpec.response_list_for(spec, "/path") == []
    end

    test "saves a list to path on a server" do
      spec = ServerSpec.new
      assert ServerSpec.response_list_for(spec, "/path") == nil
      spec = ServerSpec.configure_response_list_for(spec, "/path", [FakeServer.HTTP.Response.ok])
      assert ServerSpec.response_list_for(spec, "/path") == [FakeServer.HTTP.Response.ok]
    end

    test "saves a single element as a list to path on a server" do
      spec = ServerSpec.new
      assert ServerSpec.response_list_for(spec, "/path") == nil
      spec = ServerSpec.configure_response_list_for(spec, "/path", FakeServer.HTTP.Response.ok)
      assert ServerSpec.response_list_for(spec, "/path") == [FakeServer.HTTP.Response.ok]
    end
  end

  describe "#controller_for" do
    test "returns nil when path does not exists on spec" do
      assert ServerSpec.new
      |> ServerSpec.controller_for("/path") == nil
    end

    test "returns nil if path is configured without a controller" do
      spec = ServerSpec.new |> ServerSpec.configure_response_list_for("/path", FakeServer.HTTP.Response.ok)
      assert ServerSpec.controller_for(spec, "/path") == nil
    end

    test "returns a list when path exists and list is not empty" do
      spec = ServerSpec.new |> ServerSpec.configure_controller_for("/path", [module: SomeController, function: :some_function])
      assert ServerSpec.controller_for(spec, "/path") == [module: SomeController, function: :some_function]
    end
  end

  describe "#configure_controller_for" do
    test "saves a controller to path" do
      spec = ServerSpec.new
      assert ServerSpec.controller_for(spec, "/path") == nil
      spec = ServerSpec.configure_controller_for(spec, "/path", [module: SomeController, function: :some_function])
      assert ServerSpec.controller_for(spec, "/path") == [module: SomeController, function: :some_function]
    end

    test "overwrites a controller if one already exist" do
      spec = ServerSpec.new
      spec = ServerSpec.configure_controller_for(spec, "/path", [module: SomeController, function: :some_function])
      assert ServerSpec.controller_for(spec, "/path") == [module: SomeController, function: :some_function]

      spec = ServerSpec.configure_controller_for(spec, "/path", [module: AnotherController, function: :another_function])
      assert ServerSpec.controller_for(spec, "/path") == [module: AnotherController, function: :another_function]
    end
  end

  describe "#default_response" do
    test "returns default response for server" do
      assert ServerSpec.default_response(ServerSpec.new) == FakeServer.HTTP.Response.default
    end
  end

  describe "#configure_default_response" do
    test "saves a default response for the server" do
      spec = ServerSpec.new
      assert ServerSpec.default_response(spec) == FakeServer.HTTP.Response.default
      spec = ServerSpec.configure_default_response(spec, FakeServer.HTTP.Response.not_found)
      assert ServerSpec.default_response(spec) == FakeServer.HTTP.Response.not_found
    end
  end
end
