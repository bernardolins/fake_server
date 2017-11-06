defmodule FakeServer.FakeServerIntegrationTest do
  use ExUnit.Case, async: false

  import FakeServer
  import FakeServer.Integration.FakeControllers

  alias FakeServer.HTTP.Response

  setup_all do
    # This should be be done at test/test_helper.exs
    Application.ensure_all_started(:fake_server)
    Application.ensure_all_started(:httpoison)
    on_exit fn ->
      Application.stop(:fake_server)
    end
  end

  test_with_server "with port configured, server will listen on the port provided", [port: 5001] do
    assert FakeServer.address == "127.0.0.1:5001"
  end

  test_with_server "with port configured, will setup a server env", [port: 5001] do
    env = FakeServer.env
    assert env.ip == "127.0.0.1"
    assert env.port == 5001
  end

  test_with_server "stores the routes in test env" do
    assert FakeServer.env.routes == []
    route "/", do: []
    assert FakeServer.env.routes == ["/"]

    route "/route1", do: Response.bad_request
    assert FakeServer.env.routes == ["/route1", "/"]

    route "/route2", do: use_controller :query_string
    assert FakeServer.env.routes == ["/route2", "/route1", "/"]
  end

  test_with_server "save server hits in the environment" do
    route "/", do: Response.ok
    assert FakeServer.hits == 0
    HTTPoison.get! FakeServer.address <> "/"
    assert FakeServer.hits == 1
    HTTPoison.get! FakeServer.address <> "/"
    assert FakeServer.hits == 2
  end

  test_with_server "default response can be configured and will be replied response list is empty", [port: 5001, default_response: Response.bad_request] do
    route "/", do: []
    assert FakeServer.hits == 0
    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 400
    assert FakeServer.hits == 1
  end

  test_with_server "default response can be configured and will be replied with a single response", [default_response: Response.forbidden] do
    route "/test", do: Response.bad_request

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 403
  end

  test_with_server "default response will be replied if server is configured with an empty list", [default_response: Response.forbidden] do
    route "/test", do: []

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 403

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 403
  end

  test_with_server "with any routes configured will always reply 404" do
    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 404
    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 404
    response = HTTPoison.get! FakeServer.address <> "/test/1"
    assert response.status_code == 404
  end

  test_with_server "reply the first element of the list and remove it" do
    route "/test", do: [Response.ok, Response.not_found, Response.bad_request]

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 404

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
  end

  test_with_server "always reply the default_response when the list empties" do
    route "/test", do: [Response.bad_request]

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
  end

  test_with_server "accepts a single element instead of a list" do
    route "/test", do: Response.bad_request

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
  end

  test_with_server "reply the expected response on cofigured route and 404 on not configured routes" do
    route "/", do: [Response.bad_request]
    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 404

    response = HTTPoison.get! FakeServer.address <> "/test/1"
    assert response.status_code == 404
  end

  test_with_server "reply the expected response on cofigured route and 404 on not configured routes with a single element" do
    route "/", do: Response.bad_request
    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 404

    response = HTTPoison.get! FakeServer.address <> "/test/1"
    assert response.status_code == 404
  end

  test_with_server "with a simple controller always reply 200" do
    route "/dog", do: use_controller :single_response

    response = HTTPoison.get! FakeServer.address <> "/dog"
    assert response.status_code == 200
    assert response.body == ~s<{"pet_name": "Rufus", "kind": "dog"}>
  end

  test_with_server "evaluates FakeController and reply accordingly" do
    route "/", do: use_controller :query_string
    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 401

    response = HTTPoison.get! FakeServer.address <> "/?token=1234"
    assert response.status_code == 200
  end

  test_with_server "accepts controllers, response lists and single responses on different routes" do
    route "/controller", do: use_controller :query_string
    route "/list", do: [Response.ok, Response.not_found, Response.bad_request]
    route "/response", do: Response.bad_request

    response = HTTPoison.get! FakeServer.address <> "/controller"
    assert response.status_code == 401
    response = HTTPoison.get! FakeServer.address <> "/controller?token=1234"
    assert response.status_code == 200

    response = HTTPoison.get! FakeServer.address <> "/list"
    assert response.status_code == 200
    response = HTTPoison.get! FakeServer.address <> "/list"
    assert response.status_code == 404
    response = HTTPoison.get! FakeServer.address <> "/list"
    assert response.status_code == 400
    response = HTTPoison.get! FakeServer.address <> "/list"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>

    response = HTTPoison.get! FakeServer.address <> "/response"
    assert response.status_code == 400
    response = HTTPoison.get! FakeServer.address <> "/response"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
  end

  test_with_server "works with response headers" do
    route "/", do: Response.ok(~s<{"response": "ok"}>, [{'x-my-header', 'fake-server'}])

    response = HTTPoison.get! FakeServer.address <> "/"
    assert Enum.any?(response.headers, fn(header) -> header == {"x-my-header", "fake-server"} end)
  end

  test_with_server "works when the response is created with a map as response body" do
    route "/", do: Response.ok(%{response: "ok"})

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.body == ~s<{"response":"ok"}>
  end
end
