defmodule FakeServer.InstanceTest do
  use ExUnit.Case

  alias FakeServer.Instance

  describe "#run" do
    test "returns {:error, reason} when server_name is not an atom" do
      assert {:error, {1, "server name must be an atom"}} == Instance.run(server_name: 1)
      assert {:error, {"invalid", "server name must be an atom"}} == Instance.run(server_name: "invalid")
      assert {:error, {[], "server name must be an atom"}} == Instance.run(server_name: [])
      assert {:error, {%{}, "server name must be an atom"}} == Instance.run(server_name: %{})
    end

    test "returns {:error, reason} when max_conn is smaller than 1" do
      assert {:error, {0, "max_conn must be greater than 0"}} == Instance.run(max_conn: 0)
      assert {:error, {-1, "max_conn must be greater than 0"}} == Instance.run(max_conn: -1)
    end

    test "returns {:error, reason} when max_conn is not a positive integer" do
      assert {:error, {"ten", "max_conn must be a positive integer"}} == Instance.run(max_conn: "ten")
      assert {:error, {10.3, "max_conn must be a positive integer"}} == Instance.run(max_conn: 10.3)
    end

    test "returns {:error, reason} when random port could not be get" do
    end

    test "returns {:error, reason} when access server could not be started"
    test "returns {:error, reason} when cowboy server could not be started"

    test "returns {:ok, pid} when all validation passes" do
      assert {:ok, pid1} = Instance.run()
      assert {:ok, pid2} = Instance.run(server_name: :test)
      assert {:ok, pid3} = Instance.run(max_conn: 200)
      GenServer.stop(pid1)
      GenServer.stop(pid2)
      GenServer.stop(pid3)
    end
  end

  describe "#stop" do
    test "returns :ok and stops the http server" do
      {:ok, pid} = Instance.run(port: 55001)
      assert Instance.run(port: 55001) == {:error, {55001, "port is already in use"}}
      assert Instance.stop(pid) == :ok
      assert {:ok, _} = Instance.run(port: 55001)
    end

    test "can stop the server using the serve name" do
      {:ok, _} = Instance.run(port: 55002, server_name: :test)
      assert Instance.run(port: 55002) == {:error, {55002, "port is already in use"}}
      assert Instance.stop(:test) == :ok
      assert {:ok, _} = Instance.run(port: 55002)
    end
  end

  describe "#access_list" do
    test "returns {:ok, list} with the server access_list" do
      {:ok, pid} = Instance.run()
      assert Instance.access_list(pid) == {:ok, []}
    end
  end

  describe "#port" do
    test "returns the server port" do
      {:ok, pid} = Instance.run(port: 55003)
      assert Instance.port(pid) == 55003
    end
  end
end
