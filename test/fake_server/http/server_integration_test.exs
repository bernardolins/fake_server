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
    test "server can be started on a random" do
      {:ok, port} = FakeServer.HTTP.Server.run
      assert :ranch_tcp.listen(ip: {127,0,0,1}, port: port) == {:error, :eaddrinuse}
      FakeServer.HTTP.Server.stop
    end

    test "server can be started on a given port" do
      {:ok, port} = FakeServer.HTTP.Server.run([port: 51289])
      assert port == 51289
      assert :ranch_tcp.listen(ip: {127,0,0,1}, port: 51289) == {:error, :eaddrinuse}
      FakeServer.HTTP.Server.stop
    end

    test "server can be accessed on a valid route responding default response" do
      RouterAgent.put_route("/test")
      {:ok, port} = FakeServer.HTTP.Server.run
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], []) 
      assert response |> elem(0) |> elem(1) == 200
      FakeServer.HTTP.Server.stop
    end

    test "server can return 404 if an invalid route is accessed" do
      {:ok, port} = FakeServer.HTTP.Server.run
      {:ok, response} = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], []) 
      assert response |> elem(0) |> elem(1) == 404 
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
  end
end
