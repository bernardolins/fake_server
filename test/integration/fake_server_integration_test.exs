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
    route "/", []
    assert FakeServer.env.routes == ["/"]

    route "/route1", Response.bad_request
    assert FakeServer.env.routes == ["/route1", "/"]

    route "/route2", use_controller :query_string
    assert FakeServer.env.routes == ["/route2", "/route1", "/"]
  end

  test_with_server "save server hits in the environment" do
    route "/", Response.ok
    assert FakeServer.hits == 0
    HTTPoison.get! FakeServer.address <> "/"
    assert FakeServer.hits == 1
    HTTPoison.get! FakeServer.address <> "/"
    assert FakeServer.hits == 2
  end

  test_with_server "default response can be configured and will be replied response list is empty", [port: 5001, default_response: Response.bad_request] do
    route "/", []
    assert FakeServer.hits == 0
    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 400
    assert FakeServer.hits == 1
  end

  test_with_server "default response can be configured and will be replied with a single response", [default_response: Response.forbidden] do
    route "/test", Response.bad_request

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 403
  end

  test_with_server "default response will be replied if server is configured with an empty list", [default_response: Response.forbidden] do
    route "/test", []

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
    route "/test", [Response.ok, Response.not_found, Response.bad_request]

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
    route "/test", [Response.bad_request]

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
  end

  test_with_server "returns default_response if no response is configured to the given route" do
    route "/"

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
  end

  test_with_server "accepts a single element instead of a list" do
    route "/test", Response.bad_request

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
  end

  test_with_server "reply the expected response on cofigured route and 404 on not configured routes" do
    route "/", [Response.bad_request]
    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 404

    response = HTTPoison.get! FakeServer.address <> "/test/1"
    assert response.status_code == 404
  end

  test_with_server "reply the expected response on cofigured route and 404 on not configured routes with a single element" do
    route "/", Response.bad_request
    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 404

    response = HTTPoison.get! FakeServer.address <> "/test/1"
    assert response.status_code == 404
  end

  test_with_server "with a simple controller always reply 200" do
    route "/dog", use_controller :single_response

    response = HTTPoison.get! FakeServer.address <> "/dog"
    assert response.status_code == 200
    assert response.body == ~s<{"pet_name": "Rufus", "kind": "dog"}>
  end

  test_with_server "evaluates FakeController and reply accordingly" do
    route "/", use_controller :query_string
    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 401

    response = HTTPoison.get! FakeServer.address <> "/?token=1234"
    assert response.status_code == 200
  end

  test_with_server "accepts controllers, response lists and single responses on different routes" do
    route "/controller", use_controller :query_string
    route "/list", [Response.ok, Response.not_found, Response.bad_request]
    route "/response", Response.bad_request

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

  test_with_server "works with response headers as a keyword list" do
    route "/", Response.ok(~s<{"response": "ok"}>, [{'Content-Type', 'application/json'}])

    response = HTTPoison.get! FakeServer.address <> "/"
    assert Enum.any?(response.headers, fn(header) -> header == {"Content-Type", "application/json"} end)
  end

  test_with_server "works with response headers as map" do
    route "/", Response.ok(~s<{"response": "ok"}>, %{'Content-Type' => 'application/json'})

    response = HTTPoison.get! FakeServer.address <> "/"
    assert Enum.any?(response.headers, fn(header) -> header == {"Content-Type", "application/json"} end)
  end

  test_with_server "works with response headers as map with string keys" do
    route "/", Response.ok(~s<{"response": "ok"}>, %{"Content-Type" => "application/json"})

    response = HTTPoison.get! FakeServer.address <> "/"
    assert Enum.any?(response.headers, fn(header) -> header == {"Content-Type", "application/json"} end)
  end

  test_with_server "works when the response is created with a map as response body" do
    route "/", Response.ok(%{response: "ok"})

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.body == ~s<{"response":"ok"}>
  end

  test_with_server "works when the response is created with a string as response body" do
    route "/", Response.ok(~s<{"response":"ok"}>)

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.body == ~s<{"response":"ok"}>
  end

  # see test/integration/support/response_factory.ex
  describe "when using ResponseFactory" do
    test_with_server "generates a response wiht custom data" do
      customized_response = %{body: person} = FakeResponseFactory.build(:person)

      route "/person", customized_response

      response = HTTPoison.get! FakeServer.address <> "/person"
      body = Poison.decode!(response.body)

      assert response.status_code == 200
      assert person[:name] == body["name"]
      assert person[:email] == body["email"]
      assert person[:company][:name] == body["company"]["name"]
      assert person[:company][:country] == body["company"]["country"]
    end

    test_with_server "can build multiple custom response types" do
      customized_response = %{body: person} = FakeResponseFactory.build(:person)

      route "/person", customized_response
      route "/not_found", FakeResponseFactory.build(:customized_404)

      response = HTTPoison.get! FakeServer.address <> "/person"
      body = Poison.decode!(response.body)

      assert response.status_code == 200
      assert person[:name] == body["name"]
      assert person[:email] == body["email"]
      assert person[:company][:name] == body["company"]["name"]
      assert person[:company][:country] == body["company"]["country"]
      assert Enum.any?(response.headers, fn(header) -> header == {"Content-Type", "application/json"} end)

      response = HTTPoison.get! FakeServer.address <> "/not_found"
      assert response.status_code == 404
      assert response.body == ~s<{"message":"This item was not found!"}>
    end

    test_with_server "can set some attributes for the built response body" do
      route "/person", FakeResponseFactory.build(:person, name: "John", email: "john@myawesomemail.com")

      response = HTTPoison.get! FakeServer.address <> "/person"
      body = Poison.decode!(response.body)

      assert response.status_code == 200
      assert body["name"] == "John"
      assert body["email"] == "john@myawesomemail.com"
    end

    test_with_server "delete attributes if the value is set to nil" do
      route "/person", FakeResponseFactory.build(:person, email: nil)

      response = HTTPoison.get! FakeServer.address <> "/person"
      body = Poison.decode!(response.body)

      assert response.status_code == 200
      refute Map.has_key?(body, "email")
    end

    test_with_server "can set and delete attributes at the same built call" do
      route "/person", FakeResponseFactory.build(:person, name: "John", email: nil)

      response = HTTPoison.get! FakeServer.address <> "/person"
      body = Poison.decode!(response.body)

      assert response.status_code == 200
      assert body["name"] == "John"
      refute Map.has_key?(body, "email")
    end

    test_with_server "can set attributes as map" do
      route "/person", FakeResponseFactory.build(:person, company: %{name: "MyCompany Inc.", country: "Brazil"})

      response = HTTPoison.get! FakeServer.address <> "/person"
      body = Poison.decode!(response.body)

      assert response.status_code == 200
      assert body["company"]["name"] == "MyCompany Inc."
      assert body["company"]["country"] == "Brazil"
    end

    test_with_server "can delete map attributes" do
      route "/person", FakeResponseFactory.build(:person, company: nil)

      response = HTTPoison.get! FakeServer.address <> "/person"
      body = Poison.decode!(response.body)

      assert response.status_code == 200
      refute Map.has_key?(body, "company")
    end

    test_with_server "do not add an attribute if it does not exist at default response" do
      route "/person", FakeResponseFactory.build(:person, pet: "Rufus")

      response = HTTPoison.get! FakeServer.address <> "/person"
      body = Poison.decode!(response.body)

      assert response.status_code == 200
      refute Map.has_key?(body, "pet")
    end

    test_with_server "can set custom response headers" do
      route "/person", FakeResponseFactory.build(:person, %{"Content-Type" => "application/x-www-form-urlencoded"})

      response = HTTPoison.get! FakeServer.address <> "/person"

      assert response.status_code == 200
      assert Enum.any?(response.headers, fn(header) -> header == {"Content-Type", "application/x-www-form-urlencoded"} end)
    end

    test_with_server "can set body and headers at the same time" do
      custom_response = FakeResponseFactory.build(:person, [name: "John"], %{"Content-Type" => "application/x-www-form-urlencoded"})
      route "/person", custom_response

      response = HTTPoison.get! FakeServer.address <> "/person"
      body = Poison.decode!(response.body)

      assert response.status_code == 200
      assert body["name"] == "John"
      assert Enum.any?(response.headers, fn(header) -> header == {"Content-Type", "application/x-www-form-urlencoded"} end)
    end

    test_with_server "add a new header even if it does not exist on custom response" do
      custom_response = FakeResponseFactory.build(:person, %{"X-MY-HEADER" => "Hi!"})
      route "/person", custom_response

      response = HTTPoison.get! FakeServer.address <> "/person"

      assert response.status_code == 200
      assert Enum.any?(response.headers, fn(header) -> header == {"Content-Type", "application/json"} end)
      assert Enum.any?(response.headers, fn(header) -> header == {"X-MY-HEADER", "Hi!"} end)
    end

    test_with_server "delete a header if it's value is nil" do
      custom_response = FakeResponseFactory.build(:person, %{"Content-Type" => nil})
      route "/person", custom_response

      response = HTTPoison.get! FakeServer.address <> "/person"

      assert response.status_code == 200
      refute Enum.any?(response.headers, fn(header) -> header == {"Content-Type", "application/x-www-form-urlencoded"} end)
    end

    test_with_server "create a list of responses" do
      person_list = FakeResponseFactory.build_list(3, :person)

      route "/person", person_list

      Enum.each(person_list, fn(person) ->
        response = HTTPoison.get! FakeServer.address <> "/person"
        body = Poison.decode!(response.body)

        assert response.status_code == 200
        assert person.body[:name] == body["name"]
        assert person.body[:email] == body["email"]
        assert person.body[:company][:name] == body["company"]["name"]
        assert person.body[:company][:country] == body["company"]["country"]
      end)
    end
  end

  describe "when using functions" do
    test_with_server "reply with the function return if it's a valid Response struct" do
      route "/", fn(_) -> Response.ok end

      response = HTTPoison.get! FakeServer.address <> "/"
      assert response.status_code == 200
    end

    test_with_server "reply with the function return if it's a valid Response struct list" do
      route "/", fn(_) -> [Response.ok, Response.not_found] end

      response = HTTPoison.get! FakeServer.address <> "/"
      assert response.status_code == 200
      response = HTTPoison.get! FakeServer.address <> "/"
      assert response.status_code == 404
    end

    test_with_server "reply with the function return if it's a valid Response struct from a factory" do
      route "/", fn(_) -> FakeResponseFactory.build(:person) end

      response1 = HTTPoison.get! FakeServer.address <> "/"
      assert response1.status_code == 200
      response2 = HTTPoison.get! FakeServer.address <> "/"
      assert response2.status_code == 200
      assert response1 != response2
    end

    test_with_server "returns default_response if the function return is not a Response struct, a list of responses or a controller" do
      route "/", fn(_) -> :ok end

      response = HTTPoison.get! FakeServer.address <> "/"
      assert response.status_code == 200
      assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
    end

    test_with_server "accepts the request object as argument" do
      route "/", fn(req) ->
        if req.query["token"]  == "1234" do
          Response.ok
        else
          Response.forbidden
        end
      end

      response = HTTPoison.get! FakeServer.address <> "/"
      assert response.status_code == 403

      response = HTTPoison.get! FakeServer.address <> "/?token=1234&abc=def"
      assert response.status_code == 200
    end
  end
end

