defmodule FakeServer.HTTP.ServerTest do 
  use ExUnit.Case

  alias FakeServer.Agents.RouterAgent
  alias FakeServer.Agents.ResponseAgent

  import Mock

  setup do
    RouterAgent.start_link
    ResponseAgent.start_link
    Application.ensure_all_started(:cowboy)
    :ok
  end

  describe "#run" do
    test "starts a http server on a random port" do
      {:ok, port} = FakeServer.HTTP.Server.run
      assert :ranch_tcp.listen(ip: {127,0,0,1}, port: port) == {:error, :eaddrinuse}
      FakeServer.HTTP.Server.stop
    end

    test "starts a http server on a given port" do
      {:ok, port} = FakeServer.HTTP.Server.run([port: 51289])
      assert port == 51289
      assert :ranch_tcp.listen(ip: {127,0,0,1}, port: 51289) == {:error, :eaddrinuse}
      FakeServer.HTTP.Server.stop
    end

    test "starts a server with a given route" do
      RouterAgent.put_route("/test")
      {:ok, port} = FakeServer.HTTP.Server.run
      response = :httpc.request(:get, {'http://127.0.0.1:#{port}/test', [{'connection', 'close'}]}, [], []) 
      assert response |> elem(0) == :ok
      FakeServer.HTTP.Server.stop
    end
  end
end
