defmodule FakeServer.Agents.EnvAgentTest do
  use ExUnit.Case

  alias FakeServer.Agents.EnvAgent
  alias FakeServer.Env

  describe "#start_link" do
    test "start an agent with EnvAgent module name and an empty list" do
      {:ok, _} = EnvAgent.start_link
      assert Agent.get(EnvAgent, fn(responses) -> responses end) == []
      EnvAgent.stop
    end

    test "returns error if the server already exists" do
      {:ok, pid} = EnvAgent.start_link
      assert EnvAgent.start_link == {:error, {:already_started, pid}}
      EnvAgent.stop
    end
  end

  describe "#stop" do
    test "stops the response agent if it's started" do
      {:ok, _} = EnvAgent.start_link
      assert EnvAgent.stop == :ok
    end

    test "throw :noproc error when stopping an agent that was not started" do
      assert catch_exit(EnvAgent.stop) == :noproc
    end
  end

  describe "#save_env" do
    test "saves a new spec" do
      EnvAgent.start_link
      EnvAgent.save_env(:some_server, Env.new(8080))
      assert Agent.get(EnvAgent, &(&1)) == [some_server: %Env{ip: "127.0.0.1", port: 8080}]
      EnvAgent.stop
    end

    test "overwrites existing server spec" do
      EnvAgent.start_link
      EnvAgent.save_env(:some_server, Env.new(9999))
      assert Agent.get(EnvAgent, &(&1)) == [some_server: %Env{ip: "127.0.0.1", port: 9999}]

      EnvAgent.save_env(:some_server, Env.new(8888))
      assert Agent.get(EnvAgent, &(&1)) == [some_server: %Env{ip: "127.0.0.1", port: 8888}]
      EnvAgent.stop
    end
  end

  describe "#get_env" do
    test "returns server spec when one is saved to agent" do
      EnvAgent.start_link
      EnvAgent.save_env(:some_server, Env.new(8888))
      assert EnvAgent.get_env(:some_server) == %Env{ip: "127.0.0.1", port: 8888}
      EnvAgent.stop
    end

    test "returns nil when given server id is not available" do
      EnvAgent.start_link
      assert EnvAgent.get_env(:some_server) == nil
      EnvAgent.stop
    end
  end
end
