defmodule FakeServer.HTTP.ServerTest do
  use ExUnit.Case

  alias FakeServer.Agents.ServerAgent
  alias FakeServer.HTTP.Response

  def integration_tests_controller(_conn) do
    [Response.bad_request, Response.unauthorized]
  end

  def with_conn_controller(conn) do
    case :cowboy_req.qs_val("respond_with", conn) |> elem(0) do
      "404" -> Response.not_found
      "401" -> Response.unauthorized
      "400" -> Response.bad_request
    end
  end

  setup_all do
    ServerAgent.start_link
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
      ServerAgent.put_responses_to_path(server_name, "/test", [])
      FakeServer.HTTP.Server.update_router(server_name)

      assert port == 51289
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/another/route', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 404
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server will respond the default response if a route is provided and the response list is empty" do
      {:ok, server_name, port} = FakeServer.HTTP.Server.run
      ServerAgent.put_responses_to_path(server_name, "/test", [])
      FakeServer.HTTP.Server.update_router(server_name)

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server can respond with multiple response codes on a valid route" do
      {:ok, server_name, port} = FakeServer.HTTP.Server.run
      ServerAgent.put_responses_to_path(server_name, "/test", [Response.forbidden, Response.bad_request])
      FakeServer.HTTP.Server.update_router(server_name)

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 403

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "the server routes can be updated without server restart" do
      {:ok, server_name, port} = FakeServer.HTTP.Server.run
      ServerAgent.put_responses_to_path(server_name, "/test", [Response.ok])
      FakeServer.HTTP.Server.update_router(server_name)

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200

      ServerAgent.put_responses_to_path(server_name, "/test/new", [Response.forbidden])
      FakeServer.HTTP.Server.update_router(server_name)
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test/new', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 403
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "the response can be given by a controller" do
      {:ok, server_name, port} = FakeServer.HTTP.Server.run
      ServerAgent.put_controller_to_path(server_name, "/test", __MODULE__, :integration_tests_controller)
      FakeServer.HTTP.Server.update_router(server_name)

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 401
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "can evaluate conn to find out how to reply" do
      {:ok, server_name, port} = FakeServer.HTTP.Server.run

      ServerAgent.put_controller_to_path(server_name, "/test", __MODULE__, :with_conn_controller)
      FakeServer.HTTP.Server.update_router(server_name)
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test?respond_with=404', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 404

      ServerAgent.put_controller_to_path(server_name, "/test", __MODULE__, :with_conn_controller)
      FakeServer.HTTP.Server.update_router(server_name)
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test?respond_with=401', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 401

      ServerAgent.put_controller_to_path(server_name, "/test", __MODULE__, :with_conn_controller)
      FakeServer.HTTP.Server.update_router(server_name)
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test?respond_with=400', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "deletes the controller after the request" do
      {:ok, server_name, port} = FakeServer.HTTP.Server.run

      ServerAgent.put_controller_to_path(server_name, "/test", __MODULE__, :with_conn_controller)
      FakeServer.HTTP.Server.update_router(server_name)
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test?respond_with=404', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 404

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test?respond_with=401', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200

      FakeServer.HTTP.Server.stop(server_name)
    end
  end
end
