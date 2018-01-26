defmodule FakeServer.RequestTest do
  use ExUnit.Case

  @cowboy_req {
    :http_req, :some_port, :ranch_tcp, :keepalive, :some_pid, "POST",
    :"HTTP/1.1", {{127, 0, 0, 1}, 52683}, "127.0.0.1", :undefined, 6455,
    "/", :undefined, "a=b", :undefined, [],
    [{"host", "127.0.0.1:6455"}, {"user-agent", "hackney/1.10.1"}, {"content-type", "application/octet-stream"}, {"content-length", "14"}],
    [], :undefined, [], :waiting, "{\"test\": true}",
    :undefined, false, :waiting, [], "", :undefined
  }

  describe "#from_cowboy_req" do
    test "creates a struct with the http method of cowboy_req object" do
      request = FakeServer.Request.from_cowboy_req(@cowboy_req)
      assert request.method == "POST"
    end

    test "creates a struct with the http body of cowboy_req object" do
      request = FakeServer.Request.from_cowboy_req(@cowboy_req)
      assert request.body == "{\"test\": true}"
    end

    test "creates a struct with the http headers of cowboy_req object" do
      request = FakeServer.Request.from_cowboy_req(@cowboy_req)
      assert request.headers == %{"user-agent" => "hackney/1.10.1", "host" => "127.0.0.1:6455", "content-length" => "14", "content-type" => "application/octet-stream"}
    end

    test "creates a struct with the http query_string of cowboy_req object" do
      request = FakeServer.Request.from_cowboy_req(@cowboy_req)
      assert request.query_string == "a=b"
    end

    test "creates a struct with the http query of cowboy_req object" do
      request = FakeServer.Request.from_cowboy_req(@cowboy_req)
      assert request.query == %{"a" => "b"}
    end
  end
end
