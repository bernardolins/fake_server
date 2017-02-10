defmodule FakeServer.HTTP.ServerTest do
  use ExUnit.Case

  alias FakeServer.Agents.RouterAgent
  alias FakeServer.Agents.ResponseAgent
  alias FakeServer.HTTP.Response

  import Mock

  setup do
    RouterAgent.start_link
    ResponseAgent.start_link
    Application.ensure_all_started(:cowboy)
    :ok
  end

  describe "On integration tests" do
    test "server will return 404 on any route if started on a random port without routes" do
      {:ok, port} = FakeServer.HTTP.Server.run
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 404
      FakeServer.HTTP.Server.stop
    end

    test "server will return 404 on any route if started on a given port without routes" do
      {:ok, port} = FakeServer.HTTP.Server.run([port: 51289])
      assert port == 51289
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 404
      FakeServer.HTTP.Server.stop
    end

    test "server will respond the default response if a route is provided" do
      RouterAgent.put_route("/test")
      {:ok, port} = FakeServer.HTTP.Server.run
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200
      FakeServer.HTTP.Server.stop
    end

    test "server can respond with multiple response codes on a valid route" do
      RouterAgent.put_route("/test")
      ResponseAgent.put_response_list([Response.forbidden, Response.bad_request])
      {:ok, port} = FakeServer.HTTP.Server.run

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 403

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400
      FakeServer.HTTP.Server.stop
    end

    test "the server routes can be updated without server restart" do
      RouterAgent.put_route("/test")
      {:ok, port} = FakeServer.HTTP.Server.run

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200

      RouterAgent.put_route("/test/new")
      FakeServer.HTTP.Server.update_router
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 404
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test/new', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200
      FakeServer.HTTP.Server.stop
    end
  end
end
