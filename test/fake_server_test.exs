defmodule FakeServerTest do
  use ExUnit.Case

  describe "#start" do
    test "returns {:ok, pid} if the server started correctly" do
      assert {:ok, _pid} = FakeServer.start(:test_ok_start)
      FakeServer.stop(:test_ok_start)
    end

    test "returns {:error, reason} if a server with the same name is already started" do
      FakeServer.start(:test_error_start)
      assert {:error, {:already_started, _pid}} = FakeServer.start(:test_error_start)
      FakeServer.stop(:test_error_start)
    end

    test "returns {:error, reason} if the server name is invalid" do
      assert {:error, {"test", "server name must be an atom"}} = FakeServer.start("test")
    end
  end

  describe "#start!" do
    test "returns the server pid if the test is started" do
      pid = FakeServer.start!(:test_ok_start!)
      assert is_pid(pid)
      FakeServer.stop(:test_ok_start!)
    end

    test "raise FakeServer.Error if a server with the same name is already started" do
      FakeServer.start(:test_error_start!)
      assert_raise FakeServer.Error, fn -> FakeServer.start!(:test_error_start!) end
      FakeServer.stop(:test_error_start!)
    end

    test "raise FakeServer.Error if the server name is invalid" do
      assert_raise FakeServer.Error, ~s<"test": "server name must be an atom">, fn ->
        FakeServer.start!("test")
      end
    end
  end

  describe "#port" do
    test "returns {:ok, port} if the given name or pid is from a started server" do
      FakeServer.start(:test_ok_port, 55_000)
      assert {:ok, 55_000} == FakeServer.port(:test_ok_port)
      FakeServer.stop(:test_ok_port)
    end

    test "returns {:error, reason} if the given name or pid is not from a started server" do
      assert {:error, {:not_started, "this server is not running"}} ==
               FakeServer.port(:not_started)
    end
  end

  describe "#port!" do
    test "returns the server port if the given name or pid is from a started server" do
      FakeServer.start(:test_ok_port!, 56_000)
      assert 56_000 == FakeServer.port!(:test_ok_port!)
      FakeServer.stop(:test_ok_port!)
    end

    test "raises FakeServer.Error if the given name or pid is not from a started server" do
      assert_raise FakeServer.Error, ~s<:not_started: "this server is not running">, fn ->
        FakeServer.port!(:not_started)
      end
    end
  end

  describe "#put_route" do
    test "returns :ok if the route is added to a started server" do
      FakeServer.start(:test_ok_put_route)
      assert :ok == FakeServer.put_route(:test_ok_put_route, "/", FakeServer.Response.ok())
      FakeServer.stop(:test_ok_put_route)
    end

    test "returns {:error, reason} if the given name or pid is not from a started server" do
      assert {:error, {:not_started, "this server is not running"}} ==
               FakeServer.put_route(:not_started, "/", FakeServer.Response.ok())
    end
  end

  describe "#put_route!" do
    test "returns :ok if the route is added to a started server" do
      FakeServer.start(:test_ok_put_route!)
      assert :ok == FakeServer.put_route!(:test_ok_put_route!, "/", FakeServer.Response.ok())
      FakeServer.stop(:test_ok_put_route!)
    end

    test "raises FakeServer.Error if the given name or pid is not from a started server" do
      assert_raise FakeServer.Error, ~s<:not_started: "this server is not running">, fn ->
        FakeServer.put_route!(:not_started, "/", FakeServer.Response.ok())
      end
    end
  end
end
