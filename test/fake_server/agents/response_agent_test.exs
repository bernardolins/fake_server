defmodule FakeServer.Agents.ResponseAgentTest do
  use ExUnit.Case

  alias FakeServer.HTTP.Response
  alias FakeServer.Agents.ResponseAgent

  describe "#start_link" do
    test "start an agent with ResponseAgent module name and an empty list" do
      {:ok, _} = ResponseAgent.start_link
      assert Agent.get(ResponseAgent, fn(responses) -> responses end) == %{}
      ResponseAgent.stop
    end

    test "returns error if the server already exists" do
      {:ok, pid} = ResponseAgent.start_link
      assert ResponseAgent.start_link == {:error, {:already_started, pid}}
      ResponseAgent.stop
    end
  end

  describe "#stop" do
    test "stops the response agent if it's started" do
      {:ok, _} = ResponseAgent.start_link
      assert ResponseAgent.stop == :ok
    end

    test "throw :noproc error when stopping an agent no started" do
      assert catch_exit(ResponseAgent.stop) == :noproc
    end
  end

  describe "#put_response_list" do
    test "saves a list of responses for a server and route" do
      {:ok, _} = ResponseAgent.start_link
      response_list = [Response.ok, Response.forbidden]
      server_name = :server
      route = "/test"
      ResponseAgent.put_response_list(server_name, route, response_list)
      assert Agent.get(ResponseAgent, fn(responses) -> responses end) == %{server: %{"/test" => response_list}}
    end

    test "saves a single response as a list of responses" do
      {:ok, _} = ResponseAgent.start_link
      response = Response.ok
      server_name = :server
      route = "/test"
      ResponseAgent.put_response_list(server_name, route, response)
      assert Agent.get(ResponseAgent, fn(responses) -> responses end) == %{server: %{"/test" => [response]}}
    end
  end

  describe "#take_next" do
    test "takes the head of the status list" do
      {:ok, _} = ResponseAgent.start_link
      response_list = [Response.ok, Response.forbidden]
      server_name = :server
      route = "/test"
      ResponseAgent.put_response_list(server_name, route, response_list)
      assert ResponseAgent.take_next(server_name, route) == Response.ok
      assert ResponseAgent.take_next(server_name, route) == Response.forbidden
    end

    test "takes default response if the list empties" do
      {:ok, _} = ResponseAgent.start_link
      server_name = :server
      route = "/test"
      ResponseAgent.put_response_list(server_name, route, [])
      assert ResponseAgent.take_next(server_name, route) == Response.default
    end

    test "takes 404 response if the route does not exist" do
      {:ok, _} = ResponseAgent.start_link
      server_name = :server
      route = "/test"
      ResponseAgent.put_response_list(server_name, route, [])
      assert ResponseAgent.take_next(server_name, "/anoter/route") == Response.not_found
    end
  end
end
