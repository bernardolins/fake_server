defmodule FakeServer.Integration.TestWithServerTest do
  use ExUnit.Case

  import FakeServer
  alias FakeServer.Request
  alias FakeServer.Response
  alias FakeServer.Route

  def setup_test_with_server(env) do
    assert %FakeServer.Instance{port: _, routes: _, router: _} = env
  end

  describe "test_with_server macro" do
    test_with_server "supports inline port configuration", [port: 63_543] do
      assert FakeServer.port() == 63_543
    end

    test_with_server "supports inline route configuration", [routes: [Route.create!(path: "/test", response: Response.accepted!())]] do
      response = HTTPoison.get!("#{FakeServer.address}/test")
      assert response.status_code == 202
    end

    test_with_server "returns 404 if a request is made to a non-configured route" do
      response = HTTPoison.get!("#{FakeServer.address}/not/exists")
      assert response.status_code == 404
    end

    test_with_server "raises FakeServer.Error if the configured route does not begins with '/'" do
      assert_raise FakeServer.Error, fn ->
        route "invalid", Response.ok!()
      end
    end

    test_with_server "provides the server http address on a macro call" do
      assert FakeServer.http_address() =~ "http://127.0.0.1:"
    end

    test_with_server "provides the server ip:port on a macro call" do
      assert FakeServer.http_address() =~ "127.0.0.1:"
    end

    test_with_server "supports multiple routes returning a %FakeServer.Response{} struct" do
      route "/test1", Response.bad_request!()
      route "/test2", Response.no_content!()

      response = HTTPoison.get!("#{FakeServer.address}/test1")
      assert response.status_code == 400
      response = HTTPoison.get!("#{FakeServer.address}/test2")
      assert response.status_code == 204
    end

    test_with_server "supports multiple routes returning a list" do
      route "/test1", [Response.bad_request!(), Response.no_content!()]
      route "/test2", [Response.no_content!(), Response.bad_request!()]

      response = HTTPoison.get!("#{FakeServer.address}/test1")
      assert response.status_code == 400
      response = HTTPoison.get!("#{FakeServer.address}/test2")
      assert response.status_code == 204
      response = HTTPoison.get!("#{FakeServer.address}/test1")
      assert response.status_code == 204
      response = HTTPoison.get!("#{FakeServer.address}/test2")
      assert response.status_code == 400
      response = HTTPoison.get!("#{FakeServer.address}/test1")
      assert response.status_code == 200
      assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
      response = HTTPoison.get!("#{FakeServer.address}/test2")
      assert response.status_code == 200
      assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
    end

    test_with_server "supports multiple routes returning a function" do
      route "/test1", fn(_) -> Response.bad_request!() end
      route "/test2", fn(_) -> Response.no_content!() end

      response = HTTPoison.get!("#{FakeServer.address}/test1")
      assert response.status_code == 400
      response = HTTPoison.get!("#{FakeServer.address}/test2")
      assert response.status_code == 204
    end

    test_with_server "supports multiple routes returning different kinds of responses" do
      route "/test1", Response.no_content!()
      route "/test2", fn(_) -> Response.bad_request!() end
      route "/test3", [Response.accepted!(), Response.partial_content!()]

      response = HTTPoison.get!("#{FakeServer.address}/test1")
      assert response.status_code == 204
      response = HTTPoison.get!("#{FakeServer.address}/test2")
      assert response.status_code == 400
      response = HTTPoison.get!("#{FakeServer.address}/test3")
      assert response.status_code == 202
      response = HTTPoison.get!("#{FakeServer.address}/test3")
      assert response.status_code == 206
    end

    test_with_server "supports hit count for each route" do
      route "/test1", Response.no_content!()
      route "/test2", fn(_) -> Response.bad_request!() end
      route "/test3", [Response.accepted!(), Response.partial_content!()]

      assert FakeServer.hits() == 0
      assert FakeServer.hits("/test1") == 0
      assert FakeServer.hits("/test2") == 0
      assert FakeServer.hits("/test3") == 0
      HTTPoison.get!("#{FakeServer.address}/test1")
      assert FakeServer.hits() == 1
      assert FakeServer.hits("/test1") == 1
      assert FakeServer.hits("/test2") == 0
      assert FakeServer.hits("/test3") == 0
      HTTPoison.get!("#{FakeServer.address}/test2")
      assert FakeServer.hits() == 2
      assert FakeServer.hits("/test1") == 1
      assert FakeServer.hits("/test2") == 1
      assert FakeServer.hits("/test3") == 0
      HTTPoison.get!("#{FakeServer.address}/test3")
      assert FakeServer.hits() == 3
      assert FakeServer.hits("/test1") == 1
      assert FakeServer.hits("/test2") == 1
      assert FakeServer.hits("/test3") == 1
    end

    test_with_server "supports assertions on received requests" do
      headers = %{"authorization" => "bearer mytoken"}
      route "/test1", Response.no_content!()

      HTTPoison.put!("#{FakeServer.address}/test1", "body", headers)
      assert request_received "/test1", method: "PUT", headers: headers, body: "body", count: 1
      assert request_received "/test1", method: "PUT", headers: headers, body: "body"
      assert request_received "/test1", method: "PUT", headers: headers
      assert request_received "/test1", method: "PUT"
      assert request_received "/test1"
      assert !request_received "/test1", method: "PUT", headers: headers, body: "body", count: 0
      assert !request_received "/test1", method: "PUT", headers: headers, body: "wrong body", count: 1
      assert !request_received "/test1", method: "PUT", headers: %{"authorization" => "wrong"}, body: "body", count: 1
      assert !request_received "/test1", method: "WRONG", headers: headers, body: "body", count: 1

      HTTPoison.get!("#{FakeServer.address}/test1", headers)
      HTTPoison.put!("#{FakeServer.address}/test1", "body", headers)
      assert request_received "/test1", method: "GET", headers: headers, count: 1
      assert request_received "/test1", method: "PUT", headers: headers, body: "body", count: 2

      assert request_received "/test1", method: "POST", headers: headers, count: 0
      assert !request_received "/test1", method: "POST"
    end

    test_with_server "supports route binding" do
      route "/test/:param", fn(%Request{path: path}) ->
        if path == "/test/hello", do: Response.ok!(), else: Response.not_found!()
      end

      response = HTTPoison.get!("#{FakeServer.address}/test/hello")
      assert response.status_code == 200
      response = HTTPoison.get!("#{FakeServer.address}/test/world")
      assert response.status_code == 404
    end

    test_with_server "supports optional segments" do
      route "/test[/not[/mandatory]]", Response.accepted!()

      response = HTTPoison.get!("#{FakeServer.address}/test")
      assert response.status_code == 202
      response = HTTPoison.get!("#{FakeServer.address}/test/not")
      assert response.status_code == 202
      response = HTTPoison.get!("#{FakeServer.address}/test/not/mandatory")
      assert response.status_code == 202
    end

    test_with_server "supports fully optional segments" do
      route "/test/[...]", Response.accepted!()

      response = HTTPoison.get!("#{FakeServer.address}/test")
      assert response.status_code == 202
      response = HTTPoison.get!("#{FakeServer.address}/test/not")
      assert response.status_code == 202
      response = HTTPoison.get!("#{FakeServer.address}/test/not/mandatory")
      assert response.status_code == 202
    end

    test_with_server "paths ending in slash are no different than those ending without slash" do
      route "/test", Response.accepted!()

      response = HTTPoison.get!("#{FakeServer.address}/test")
      assert response.status_code == 202
      response = HTTPoison.get!("#{FakeServer.address}/test/")
      assert response.status_code == 202
    end
  end
end
