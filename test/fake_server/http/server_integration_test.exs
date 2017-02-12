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
      {:ok, server_name, port} = FakeServer.HTTP.Server.run
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 404
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server will return 404 on any route if the access is on a inexistent route" do
      {:ok, server_name, port} = FakeServer.HTTP.Server.run([port: 51289])
      RouterAgent.put_route(server_name, "/test")
      ResponseAgent.put_response_list(server_name, "/test", [])
      FakeServer.HTTP.Server.update_router(server_name)

      assert port == 51289
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/another/route', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 404
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server will respond the default response if a route is provided and the response list is empty" do
      {:ok, server_name, port} = FakeServer.HTTP.Server.run
      RouterAgent.put_route(server_name, "/test")
      ResponseAgent.put_response_list(server_name, "/test", [])
      FakeServer.HTTP.Server.update_router(server_name)

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server can respond with multiple response codes on a valid route" do
      {:ok, server_name, port} = FakeServer.HTTP.Server.run
      RouterAgent.put_route(server_name, "/test")
      ResponseAgent.put_response_list(server_name, "/test", [Response.forbidden, Response.bad_request])
      FakeServer.HTTP.Server.update_router(server_name)

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 403

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "the server routes can be updated without server restart" do
      {:ok, server_name, port} = FakeServer.HTTP.Server.run
      RouterAgent.put_route(server_name, "/test")
      ResponseAgent.put_response_list(server_name, "/test", [Response.ok])
      FakeServer.HTTP.Server.update_router(server_name)

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200

      RouterAgent.put_route(server_name, "/test/new")
      ResponseAgent.put_response_list(server_name, "/test/new", [Response.forbidden])
      FakeServer.HTTP.Server.update_router(server_name)
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test/new', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 403
      FakeServer.HTTP.Server.stop(server_name)
    end
  end
end
