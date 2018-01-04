defmodule FakeServer.HTTP.ServerTest do
  use ExUnit.Case

  alias FakeServer.Agents.ServerAgent
  alias FakeServer.Agents.EnvAgent
  alias FakeServer.HTTP.Response
  alias FakeServer.HTTP.Server

  def integration_tests_controller(_conn) do
    Response.bad_request
  end

  def with_request_controller(req) do
    case req.query["respond_with"] do
      "404" -> Response.not_found
      "401" -> Response.unauthorized
      "400" -> Response.bad_request
    end
  end

  setup_all do
    ServerAgent.start_link
    EnvAgent.start_link
    Application.ensure_all_started(:cowboy)
    :ok
  end

  describe "When server is running but spec is not found" do
    test "server will always reply 500 with a message on the body" do
      {:ok, server_name, port} = Server.run
      Server.add_response(server_name, "/test", nil)
      Agent.update(ServerAgent, fn(_) -> [] end)
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 500
      FakeServer.HTTP.Server.stop(server_name)
    end
  end

  describe "When server is running and spec is found" do
    test "server will always reply 404 when a request is made to an inexistent path" do
      {:ok, server_name, port} = Server.run
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 404
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server will reply default response if response list is empty" do
      {:ok, server_name, port} = Server.run
      Server.add_response(server_name, "/test", [])
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server will reply first response on response list" do
      {:ok, server_name, port} = Server.run
      Server.add_response(server_name, "/test", [Response.bad_request, Response.forbidden])
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 403
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "default response can be configured and will be returned to every path with response list empty" do
      {:ok, server_name, port} = Server.run

      Server.add_response(server_name, "/test", nil)
      Server.add_response(server_name, "/test/1", nil)

      Server.set_default_response(server_name, Response.forbidden)
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 403

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test/1', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 403
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server will run controller function to check what to reply" do
      {:ok, server_name, port} = Server.run

      Server.add_response(server_name, "/test", [module: __MODULE__, function: :integration_tests_controller])

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400

      FakeServer.HTTP.Server.stop(server_name)
    end

    test "server will check conn variable on controller function to check what to reply" do
      {:ok, server_name, port} = Server.run

      Server.add_response(server_name, "/test", [module: __MODULE__, function: :with_request_controller])

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test?respond_with=404', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 404

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test?respond_with=401', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 401

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test?respond_with=400', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400
      FakeServer.HTTP.Server.stop(server_name)
    end

    test "accept a controller on a route and a response list on another" do
      {:ok, server_name, port} = Server.run

      Server.add_response(server_name, "/test", [module: __MODULE__, function: :integration_tests_controller])
      Server.add_response(server_name, "/test/1", Response.forbidden)

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 400

      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test/1', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 403

      FakeServer.HTTP.Server.stop(server_name)
    end

    test "accept a response with a string as body" do
      {:ok, server_name, port} = Server.run

      Server.add_response(server_name, "/test", Response.ok(~s<{"test":"ok"}>))


      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200
      assert response |> elem(2) == '{"test":"ok"}'

      FakeServer.HTTP.Server.stop(server_name)
    end

    test "accept a response with a map as body" do
      {:ok, server_name, port} = Server.run

      Server.add_response(server_name, "/test", Response.ok(%{test: "ok"}))


      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200
      assert response |> elem(2) == '{"test":"ok"}'

      FakeServer.HTTP.Server.stop(server_name)
    end

    test "accept a response with a header as a map with string as keys" do
      {:ok, server_name, port} = Server.run

      Server.add_response(server_name, "/test", Response.ok(%{test: "ok"}, %{"Content-Type" => "application/json"}))


      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200
      assert response |> elem(1) |> List.last == {'content-type', 'application/json'}
      assert response |> elem(2) == '{"test":"ok"}'

      FakeServer.HTTP.Server.stop(server_name)
    end

    test "accept a response with a header as a map" do
      {:ok, server_name, port} = Server.run

      Server.add_response(server_name, "/test", Response.ok(%{test: "ok"}, %{'Content-Type' => 'application/json'}))


      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200
      assert response |> elem(1) |> List.last == {'content-type', 'application/json'}
      assert response |> elem(2) == '{"test":"ok"}'

      FakeServer.HTTP.Server.stop(server_name)
    end

    test "returns 500 with a message if the headers are invalid" do
      {:ok, server_name, port} = Server.run

      Server.add_response(server_name, "/test", Response.ok(%{test: "ok"}, %{content_type: 'application/json'}))


      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 500
      assert response |> elem(2) == '{"message":"Invalid header :content_type: Must be a binary"}'

      FakeServer.HTTP.Server.stop(server_name)
    end

    test "returns 500 with a message if the headers are not either a map or a list" do
      {:ok, server_name, port} = Server.run

      Server.add_response(server_name, "/test", Response.ok(%{test: "ok"}, 1))


      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 500
      assert response |> elem(2) == '{"message":"Invalid headers: 1: Must be a keyword list or a map"}'

      FakeServer.HTTP.Server.stop(server_name)
    end

    test "returns 500 with a message if the body is invalid" do
      {:ok, server_name, port} = Server.run

      Server.add_response(server_name, "/test", Response.ok([a: 1]))


      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 500
      assert response |> elem(2) == '{"message":"Could not encode body: [a: 1]"}'

      FakeServer.HTTP.Server.stop(server_name)
    end

    test "accept a response with a header as a list" do
      {:ok, server_name, port} = Server.run

      Server.add_response(server_name, "/test", Response.ok(%{test: "ok"}, [{'Content-Type', 'application/json'}]))


      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], [])
      assert response |> elem(0) |> elem(1) == 200
      assert response |> elem(1) |> List.last == {'content-type', 'application/json'}
      assert response |> elem(2) == '{"test":"ok"}'

      FakeServer.HTTP.Server.stop(server_name)
    end
  end
end
