defmodule FakeServer.CowboyTest do
  use ExUnit.Case, async: true

  alias FakeServer.Cowboy
  alias FakeServer.Instance

  describe "#start_listen" do
    test "starts an http server on the port provided by the Instance configuration" do
      instance = %Instance{port: 55000}
      assert {:ok, pid} = Cowboy.start_listen(instance)
      assert {:error, :eaddrinuse} = :ranch_tcp.listen(ip: {0, 0, 0, 0}, port: 55000)
      :cowboy.stop_listener(instance.server_name)
    end

    test "starts an http server with the given server_name" do
      instance = %Instance{port: 55000, server_name: :test_server}
      assert {:ok, pid} = Cowboy.start_listen(instance)
      assert :ok == :cowboy.stop_listener(:test_server)
    end
  end

  describe "#stop" do
    test "stops a given started instance" do
      instance = %Instance{port: 55000, server_name: :test_server}
      assert {:ok, pid} = Cowboy.start_listen(instance)
      assert {:error, :eaddrinuse} = :ranch_tcp.listen(ip: {0, 0, 0, 0}, port: 55000)
      assert :ok = Cowboy.stop(instance)
      assert {:ok, socket} = :ranch_tcp.listen(ip: {0, 0, 0, 0}, port: 55000)
      :erlang.port_close(socket)
    end
  end
end
