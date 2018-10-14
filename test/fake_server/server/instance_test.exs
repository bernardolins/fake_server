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

    test "returns {:ok, pid} when all validation passes" do
      assert {:ok, _} = Instance.run()
      assert {:ok, _} = Instance.run(server_name: :test)
      assert {:ok, _} = Instance.run(max_conn: 200)
    end
  end
end
