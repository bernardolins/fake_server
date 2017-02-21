defmodule FakeServer.Agents.ServerAgentTest do
  use ExUnit.Case

  alias FakeServer.Agents.ServerAgent
  alias FakeServer.ServerInfo
  alias FakeServer.HTTP.Response

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
      assert catch_exit(ServerAgent.stop) == :noproc
    end
  end

  describe "#put_server" do
    test "puts an item with server name as key and a %ServerInfo as value on ServerAgent" do
      {:ok, _} = ServerAgent.start_link
      assert Agent.get(ServerAgent, &(&1)) == []
      ServerAgent.put_server(:some_server)
      assert Agent.get(ServerAgent, &(&1)) == [some_server: %ServerInfo{name: :some_server}]
      ServerAgent.stop
    end

    test "does no overwrite an existent item" do
      {:ok, _} = ServerAgent.start_link
      server_info = %ServerInfo{name: :some_server, default_response: Response.bad_request}
      Agent.update(ServerAgent, fn(_) -> [some_server: server_info] end)
      new_server = Agent.get(ServerAgent, fn(servers) -> servers[:some_server]  end)
      ServerAgent.put_server(:some_server)
      assert new_server.default_response == Response.bad_request
      assert Agent.get(ServerAgent, &(&1)) == [some_server: server_info]
      ServerAgent.stop
    end
  end

  describe "#put_responses_to_path" do
    test "puts a list of responses on server_info object of an existent entry" do
      {:ok, _} = ServerAgent.start_link
      server_info = %ServerInfo{name: :some_server, route_responses: %{"/" => [Response.ok]}}
      ServerAgent.put_server(:some_server)
      ServerAgent.put_responses_to_path(:some_server, "/", [Response.ok])
      assert Agent.get(ServerAgent, &(&1)) == [some_server: server_info]
      ServerAgent.stop
    end

    test "puts a single response as a list on server_info object of an existent entry" do
      {:ok, _} = ServerAgent.start_link
      server_info = %ServerInfo{name: :some_server, route_responses: %{"/" => [Response.ok]}}
      ServerAgent.put_server(:some_server)
      ServerAgent.put_responses_to_path(:some_server, "/", Response.ok)
      assert Agent.get(ServerAgent, &(&1)) == [some_server: server_info]
      ServerAgent.stop
    end

    test "does not overwrite existing server info" do
      {:ok, _} = ServerAgent.start_link
      server_info = %ServerInfo{name: :some_server, route_responses: %{"/" => [Response.ok]}, default_response: Response.bad_request}
      ServerAgent.put_server(:some_server)
      ServerAgent.put_default_response(:some_server, Response.bad_request)
      ServerAgent.put_responses_to_path(:some_server, "/", [Response.ok])
      assert Agent.get(ServerAgent, &(&1)) == [some_server: server_info]
      ServerAgent.stop
    end

    test "creates an entry if one does not exist" do
      {:ok, _} = ServerAgent.start_link
      server_info = %ServerInfo{name: :some_server, route_responses: %{"/" => [Response.ok]}}
      ServerAgent.put_responses_to_path(:some_server, "/", [Response.ok])
      assert Agent.get(ServerAgent, &(&1)) == [some_server: server_info]
      ServerAgent.stop
    end
  end

  describe "#put_default_response" do
    test "configures the default response on server_info object of an existent entry" do
      {:ok, _} = ServerAgent.start_link
      server_info = %ServerInfo{name: :some_server, default_response: Response.bad_request}
      ServerAgent.put_server(:some_server)
      ServerAgent.put_default_response(:some_server, Response.bad_request)
      assert Agent.get(ServerAgent, &(&1)) == [some_server: server_info]
      ServerAgent.stop
    end

    test "does nothing if receives nil as default response" do
      {:ok, _} = ServerAgent.start_link
      ServerAgent.put_server(:some_server)
      ServerAgent.put_default_response(:some_server,nil)
      assert Agent.get(ServerAgent, &(&1)) == [some_server: %ServerInfo{name: :some_server}]
      ServerAgent.stop
    end
  end

  describe "#put_controller_to_path" do
    test "saves a module and controller name to a given path" do
      {:ok, _} = ServerAgent.start_link
      server_info = %ServerInfo{name: :some_server, controllers: %{"/" => {SomeModule, :some_controller}}}
      ServerAgent.put_server(:some_server)
      ServerAgent.put_controller_to_path(:some_server, "/", SomeModule, :some_controller)
      assert Agent.get(ServerAgent, &(&1)) == [some_server: server_info]
      ServerAgent.stop
    end

    test "does not overwrite existing server info" do
      {:ok, _} = ServerAgent.start_link
      server_info = %ServerInfo{name: :some_server, controllers: %{"/" => {SomeModule, :some_controller}}, default_response: FakeServer.HTTP.Response.bad_request}
      ServerAgent.put_server(:some_server)
      ServerAgent.put_default_response(:some_server, Response.bad_request)
      ServerAgent.put_controller_to_path(:some_server, "/", SomeModule, :some_controller)
      assert Agent.get(ServerAgent, &(&1)) == [some_server: server_info]
      ServerAgent.stop
    end

    test "creates an entry if one does not exist" do
      {:ok, _} = ServerAgent.start_link
      server_info = %ServerInfo{name: :some_server, controllers: %{"/" => {SomeModule, :some_controller}}}
      ServerAgent.put_controller_to_path(:some_server, "/", SomeModule, :some_controller)
      assert Agent.get(ServerAgent, &(&1)) == [some_server: server_info]
      ServerAgent.stop
    end
  end

  describe "#take_server_info" do
    test "gets info of a given server" do
      {:ok, _} = ServerAgent.start_link
      server_info = %ServerInfo{name: :some_server, default_response: Response.bad_request}
      ServerAgent.put_server(:some_server)
      ServerAgent.put_default_response(:some_server, Response.bad_request)
      assert ServerAgent.take_server_info(:some_server) == server_info
      ServerAgent.stop
    end

    test "returns nil if server does not exist" do
      {:ok, _} = ServerAgent.start_link
      assert ServerAgent.take_server_info(:some_server) == nil
      ServerAgent.stop
    end
  end

  describe "#take_server_paths" do
    test "returns an array containing all server paths" do
      {:ok, _} = ServerAgent.start_link
      ServerAgent.put_responses_to_path(:some_server, "/", [])
      ServerAgent.put_responses_to_path(:some_server, "/test", [])
      ServerAgent.put_responses_to_path(:some_server, "/test/1", [])
      assert ServerAgent.take_server_paths(:some_server) == ["/", "/test", "/test/1"]
      ServerAgent.stop
    end

    test "returns an empty array if there are no paths to server" do
      {:ok, _} = ServerAgent.start_link
      ServerAgent.put_server(:some_server)
      assert ServerAgent.take_server_paths(:some_server) == []
      ServerAgent.stop
    end

    test "returns nil if server does not exists" do
      {:ok, _} = ServerAgent.start_link
      assert ServerAgent.take_server_paths(:some_server) == nil
      ServerAgent.stop
    end
  end

  describe "#take_next_response_to_path" do
    test "gets info of a given server" do
      {:ok, _} = ServerAgent.start_link
      ServerAgent.put_responses_to_path(:some_server, "/", [Response.ok, Response.bad_request])
      assert ServerAgent.take_next_response_to_path(:some_server, "/") == Response.ok
      assert ServerAgent.take_next_response_to_path(:some_server, "/") == Response.bad_request
      ServerAgent.stop
    end

    test "returns default response if response list is empty" do
      {:ok, _} = ServerAgent.start_link
      ServerAgent.put_responses_to_path(:some_server, "/", [])
      assert ServerAgent.take_next_response_to_path(:some_server, "/") == Response.default
      ServerAgent.stop
    end

    test "returns nil if route does not exists" do
      {:ok, _} = ServerAgent.start_link
      ServerAgent.put_server(:some_server)
      assert ServerAgent.take_next_response_to_path(:some_server, "/") == nil
      ServerAgent.stop
    end

    test "returns nil if server does not exists" do
      {:ok, _} = ServerAgent.start_link
      assert ServerAgent.take_next_response_to_path(:some_server, "/") == nil
      ServerAgent.stop
    end
  end

  describe "#delete_controller" do
    test "deletes an existing controller for a given path" do
      {:ok, _} = ServerAgent.start_link
      server_info = %ServerInfo{name: :some_server, controllers: %{}}
      ServerAgent.put_server(:some_server)
      ServerAgent.put_controller_to_path(:some_server, "/", SomeModule, :some_controller)
      ServerAgent.delete_controller(:some_server, "/")
      assert Agent.get(ServerAgent, &(&1)) == [some_server: server_info]
      ServerAgent.stop
    end

    test "returns ok and does nothing when server does not exist" do
      {:ok, _} = ServerAgent.start_link
      assert ServerAgent.delete_controller(:some_server, "/") == :ok
      ServerAgent.stop
    end

    test "returns ok and does nothing when server exist but route doesn't" do
      {:ok, _} = ServerAgent.start_link
      ServerAgent.put_server(:some_server)
      assert ServerAgent.delete_controller(:some_server, "/") == :ok
      ServerAgent.stop
    end
  end
end
