defmodule FakeServer.PortTest do
  use ExUnit.Case

  describe "#ensure" do
    test "returns {:error, reason} when port is not in allowed range" do
      message = "port is not in allowed range: 55000..65000"
      assert {:error, {5000, message}} == FakeServer.Port.ensure(5000)
      assert {:error, {65001, message}} == FakeServer.Port.ensure(65001)
      assert {:error, {"55000", message}} == FakeServer.Port.ensure("55000")
      assert {:error, {-1, message}} == FakeServer.Port.ensure(-1)
      assert {:error, {[55000], message}} == FakeServer.Port.ensure([55000])
    end

    test "returns {:error, reason} when port is not available" do
      {:ok, socket} = :ranch_tcp.listen(ip: {0, 0, 0, 0}, port: 55000)
      assert {:error, {55000, "port is already in use"}} == FakeServer.Port.ensure(55000)
      :erlang.port_close(socket)
    end

    test "returns {:error, reason} when a random port could not be allocated" do
    end

    test "returns {:ok, port} with a random port when calling ensure with nil" do
    end

    test "returns {:ok, port} when port is valid and available" do
      assert {:ok, 55000} == FakeServer.Port.ensure(55000)
    end
  end
end
