defmodule FakeServer.HTTP.ServerTest do
  use ExUnit.Case

  alias FakeServer.Agents.ServerAgent
  alias FakeServer.HTTP.Response
  alias FakeServer.HTTP.Server

  def integration_tests_controller(_conn) do
    Response.bad_request
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

  describe "When server is running but spec is not found" do
    test "server will always reply 500 with a message on the body" do
      {:ok, server_name, port} = Server.run
      Server.add_route(server_name, "/test")
      Agent.update(ServerAgent, fn(_) -> [] end)
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 500
      FakeServer.HTTP.Server.stop(server_name)
    end
  end

  describe "When server is running and spec is found" do
    test "server will always reply 404 when a request is made to an inexsistent path" do
      {:ok, server_name, port} = Server.run
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 404
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server will reply default response if response list is empty" do
      {:ok, server_name, port} = Server.run
      Server.add_route(server_name, "/test", [])
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server will reply first response on response list" do
      {:ok, server_name, port} = Server.run
      Server.add_route(server_name, "/test", [Response.bad_request, Response.forbidden])
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 403
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "default response can be configured and will be returned to every path with response list empty" do
      {:ok, server_name, port} = Server.run

      Server.add_route(server_name, "/test")
      Server.add_route(server_name, "/test/1")

      Server.set_default_response(server_name, Response.forbidden)
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 403

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test/1', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 403
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server will run controller function to check what to reply" do
      {:ok, server_name, port} = Server.run

      Server.add_controller(server_name, "/test", [module: __MODULE__, function: :integration_tests_controller])

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400

      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server will check conn variable on controller function to check what to reply" do
      {:ok, server_name, port} = Server.run

      Server.add_controller(server_name, "/test", [module: __MODULE__, function: :with_conn_controller])

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test?respond_with=404', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 404

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test?respond_with=401', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 401

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test?respond_with=400', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server will overwrite response list if controller is set to the same path" do
      {:ok, server_name, port} = Server.run

      Server.add_controller(server_name, "/test", [module: __MODULE__, function: :integration_tests_controller])
      Server.add_route(server_name, "/test", Response.forbidden)

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400

      FakeServer.HTTP.Server.stop(server_name)
    end

    test "accept a controller on a route and a response list on another" do
      {:ok, server_name, port} = Server.run

      Server.add_controller(server_name, "/test", [module: __MODULE__, function: :integration_tests_controller])
      Server.add_route(server_name, "/test/1", Response.forbidden)

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test/1', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 403

      FakeServer.HTTP.Server.stop(server_name)
    end
  end
end
