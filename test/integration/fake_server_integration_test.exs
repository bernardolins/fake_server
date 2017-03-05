defmodule FakeServer.FakeServerIntegrationTest do
  use ExUnit.Case, async: true

  import FakeServer
  import FakeServer.Integration.FakeControllers

  alias FakeServer.HTTP.Response

  setup_all do
    # This should be be done at test/test_helper.exs
    Application.ensure_all_started(:fake_server)
    on_exit fn ->
      Application.stop(:fake_server)
    end
  end

  test_with_server "with port configured, server will listen on the port provided", [port: 5001] do
    assert fake_server_address == "127.0.0.1:5001"
    response = HTTPoison.get! "127.0.0.1:5001" <> "/"
    assert response.status_code == 404
  end

  test_with_server "default response can be configured and will be replied response list is empty", [port: 5001, default_response: Response.bad_request] do
    route fake_server, "/", do: []
    response = HTTPoison.get! fake_server_address <> "/"
    assert response.status_code == 400
  end

  test_with_server "with any routes configured will always reply 404" do
    response = HTTPoison.get! fake_server_address <> "/"
    assert response.status_code == 404
    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 404
    response = HTTPoison.get! fake_server_address <> "/test/1"
    assert response.status_code == 404
  end

  test_with_server "reply the first element of the list and remove it" do
    route fake_server, "/test", do: [Response.ok, Response.not_found, Response.bad_request]

    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 200

    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 404

    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 200
    assert response.body == "This is a default response from FakeServer"
  end

  test_with_server "always reply the default_response when the list empties" do
    route fake_server, "/test", do: [Response.bad_request]

    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 200
    assert response.body == "This is a default response from FakeServer"

    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 200
    assert response.body == "This is a default response from FakeServer"
  end

  test_with_server "accepts a single element instead of a list" do
    route fake_server, "/test", do: Response.bad_request

    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 200
    assert response.body == "This is a default response from FakeServer"
  end

  test_with_server "reply the expected response on cofigured route and 404 on not configured routes" do
    route fake_server, "/", do: [Response.bad_request]
    response = HTTPoison.get! fake_server_address <> "/"
    assert response.status_code == 400

    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 404

    response = HTTPoison.get! fake_server_address <> "/test/1"
    assert response.status_code == 404
  end

  test_with_server "reply the expected response on cofigured route and 404 on not configured routes with a single element" do
    route fake_server, "/", do: Response.bad_request
    response = HTTPoison.get! fake_server_address <> "/"
    assert response.status_code == 400

    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 404

    response = HTTPoison.get! fake_server_address <> "/test/1"
    assert response.status_code == 404
  end

  test_with_server "with a simple controller always reply 200" do
    route fake_server, "/dog", do: use_controller :single_response

    response = HTTPoison.get! fake_server_address <> "/dog"
    assert response.status_code == 200
    assert response.body == ~s<{"pet_name": "Rufus", "kind": "dog"}>
  end

  test_with_server "evaluates FakeController and reply accordingly" do
    route fake_server, "/", do: use_controller :query_string
    response = HTTPoison.get! fake_server_address <> "/"
    assert response.status_code == 401

    response = HTTPoison.get! fake_server_address <> "/?token=1234"
    assert response.status_code == 200
  end

  test_with_server "accepts controllers, response lists and single responses on different routes" do
    route fake_server, "/controller", do: use_controller :query_string
    route fake_server, "/list", do: [Response.ok, Response.not_found, Response.bad_request]
    route fake_server, "/response", do: Response.bad_request

    response = HTTPoison.get! fake_server_address <> "/controller"
    assert response.status_code == 401
    response = HTTPoison.get! fake_server_address <> "/controller?token=1234"
    assert response.status_code == 200

    response = HTTPoison.get! fake_server_address <> "/list"
    assert response.status_code == 200
    response = HTTPoison.get! fake_server_address <> "/list"
    assert response.status_code == 404
    response = HTTPoison.get! fake_server_address <> "/list"
    assert response.status_code == 400
    response = HTTPoison.get! fake_server_address <> "/list"
    assert response.status_code == 200
    assert response.body == "This is a default response from FakeServer"

    response = HTTPoison.get! fake_server_address <> "/response"
    assert response.status_code == 400
    response = HTTPoison.get! fake_server_address <> "/response"
    assert response.status_code == 200
    assert response.body == "This is a default response from FakeServer"
  end
end
