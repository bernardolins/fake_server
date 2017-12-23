defmodule FakeServer.Specs.ServerSpecTest do
  use ExUnit.Case

  alias FakeServer.Specs.ServerSpec

  import Mock

  describe "#new" do
    test "returns a ServerSpec structure with a given server_id and random port" do
      spec = ServerSpec.new(%{id: :some_id})
      assert spec == %ServerSpec{id: :some_id, port: spec.port}
    end

    test "returns a ServerSpec with a random server_id and port number if neither id nor port are provided " do
      with_mock Base, [url_encode64: fn(_) -> "abcdefghijklmnop" end] do
        spec = ServerSpec.new
        assert spec == %ServerSpec{id: :abcdefghijklmnop, port: spec.port}
      end
    end

    test "returns a ServerSpec structure with a given port" do
      spec = ServerSpec.new(%{port: 8080})
      assert spec == %ServerSpec{id: spec.id, port: 8080}
    end

    test "returns a ServerSpec structure with a given default_response" do
      spec = ServerSpec.new(%{default_response: FakeServer.HTTP.Response.bad_request})
      assert spec == %ServerSpec{id: spec.id, port: spec.port, default_response: FakeServer.HTTP.Response.bad_request}
    end

    @tag :skip
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
      server = ServerSpec.new(%{id: :some_id})
      assert ServerSpec.id(server) == :some_id
    end
  end

  describe "#response_for" do
    test "returns nil when path does not exists on spec" do
      assert ServerSpec.new
      |> ServerSpec.response_for("/path") == nil
    end

    test "returns [] when path exists but list is empty" do
      spec = ServerSpec.new |> ServerSpec.configure_response_for("/path", [])
      assert ServerSpec.response_for(spec, "/path") == []
    end

    test "returns a list when path exists and list is not empty" do
      spec = ServerSpec.new |> ServerSpec.configure_response_for("/path", [FakeServer.HTTP.Response.ok])
      assert ServerSpec.response_for(spec, "/path") == [FakeServer.HTTP.Response.ok]
    end
  end

  describe "#configure_response_list" do
    test "saves an empty list to path on a server" do
      spec = ServerSpec.new
      assert ServerSpec.response_for(spec, "/path") == nil
      spec = ServerSpec.configure_response_for(spec, "/path", [])
      assert ServerSpec.response_for(spec, "/path") == []
    end

    test "saves a list to path on a server" do
      spec = ServerSpec.new
      assert ServerSpec.response_for(spec, "/path") == nil
      spec = ServerSpec.configure_response_for(spec, "/path", [FakeServer.HTTP.Response.ok])
      assert ServerSpec.response_for(spec, "/path") == [FakeServer.HTTP.Response.ok]
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
