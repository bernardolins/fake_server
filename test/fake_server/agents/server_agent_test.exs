defmodule FakeServer.Agents.ServerAgentTest do
  use ExUnit.Case

  alias FakeServer.Agents.ServerAgent
  alias FakeServer.Specs.ServerSpec

  describe "#start_link" do
    test "start an agent with ServerAgent module name and an empty list" do
      {:ok, _} = ServerAgent.start_link
      assert Agent.get(ServerAgent, fn(responses) -> responses end) == []
      ServerAgent.stop
    end

    test "returns error if the server already exists" do
      {:ok, pid} = ServerAgent.start_link
      assert ServerAgent.start_link == {:error, {:already_started, pid}}
      ServerAgent.stop
    end
  end

  describe "#stop" do
    test "stops the response agent if it's started" do
      {:ok, _} = ServerAgent.start_link
      assert ServerAgent.stop == :ok
    end

    test "throw :noproc error when stopping an agent that was not started" do
      throw_value = case catch_exit(ServerAgent.stop) do
        value when is_tuple(value) -> elem(value, 0)
        value -> value
      end
      assert throw_value == :noproc
    end
  end

  describe "#save_spec" do
    test "saves a new spec" do
      ServerAgent.start_link
      ServerSpec.new(%{id: :some_server, port: 8080}) |> ServerAgent.save_spec
      assert Agent.get(ServerAgent, &(&1)) == [some_server: %ServerSpec{id: :some_server, port: 8080}]
      ServerAgent.stop
    end

    test "overwrites existing server spec" do
      ServerAgent.start_link
      ServerSpec.new(%{id: :some_server, port: 9999}) |> ServerAgent.save_spec
      assert Agent.get(ServerAgent, &(&1)) == [some_server: %ServerSpec{id: :some_server, port: 9999}]

      ServerSpec.new(%{id: :some_server, port: 8888}) |> ServerAgent.save_spec
      assert Agent.get(ServerAgent, &(&1)) == [some_server: %ServerSpec{id: :some_server, port: 8888}]
      ServerAgent.stop
    end
  end

  describe "#get_spec" do
    test "returns server spec when one is saved to agent" do
      ServerAgent.start_link
      ServerSpec.new(%{id: :some_server, port: 9999}) |> ServerAgent.save_spec
      assert ServerAgent.get_spec(:some_server) == %ServerSpec{id: :some_server, port: 9999}
      ServerAgent.stop
    end

    test "returns nil when given server id is not available" do
      ServerAgent.start_link
      assert ServerAgent.get_spec(:some_server) == nil
      ServerAgent.stop
    end
  end
end
