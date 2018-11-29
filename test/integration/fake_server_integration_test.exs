defmodule FakeServer.FakeServerIntegrationTest do
  use ExUnit.Case, async: false

  import FakeServer
  alias FakeServer.Response
  alias FakeServer.Route

  test_with_server "with port configured, server will listen on the port provided", [port: 55001] do
    route "/", Response.ok!
    assert FakeServer.address == "127.0.0.1:55001"
    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 200
  end

  test_with_server "save server hits" do
    route "/", Response.ok!
    assert FakeServer.hits == 0
    HTTPoison.get! FakeServer.address <> "/"
    assert FakeServer.hits == 1
    HTTPoison.get! FakeServer.address <> "/"
    assert FakeServer.hits == 2
  end

  test_with_server "save route hits" do
    route "/no/cache", FakeServer.Response.ok!
    route "/cache", FakeServer.Response.ok!
    assert (FakeServer.hits "/no/cache") == 0
    assert (FakeServer.hits "/cache") == 0
    HTTPoison.get! FakeServer.address <> "/no/cache"
    assert (FakeServer.hits "/no/cache") == 1
    HTTPoison.get! FakeServer.address <> "/cache"
    assert (FakeServer.hits "/cache") == 1
    assert FakeServer.hits == 2
  end

  test_with_server "accepts routes on the configuration", routes: [Route.create!(path: "/", response: Response.forbidden!)] do
    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 403
  end

  test_with_server "default response will be replied if server is configured with an empty list" do
    route "/test", []

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
  end

  test_with_server "without any routes configured will always reply 404" do
    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 404
    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 404
    response = HTTPoison.get! FakeServer.address <> "/test/1"
    assert response.status_code == 404
  end

  test_with_server "reply the first element of the list and remove it" do
    route "/test", [Response.ok!, Response.not_found!, Response.bad_request!]

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
    route "/test", [Response.bad_request!]

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200
    assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
  end

  test_with_server "always reply the same response when it is a single element" do
    route "/test", Response.bad_request! "test"

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 400
    assert response.body == "test"
    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 400
    assert response.body == "test"
  end

  test_with_server "reply the expected response on cofigured route and 404 on not configured routes" do
    route "/", [Response.bad_request!]

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 400
    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 404
    response = HTTPoison.get! FakeServer.address <> "/test/1"
    assert response.status_code == 404
  end

  test_with_server "reply the expected response on cofigured route and 404 on not configured routes with a single element" do
    route "/", Response.bad_request!

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.status_code == 400
    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 404
    response = HTTPoison.get! FakeServer.address <> "/test/1"
    assert response.status_code == 404
  end

  test_with_server "accepts response lists and single responses on different routes" do
    route "/list", [Response.ok!, Response.not_found!, Response.bad_request!]
    route "/response", Response.bad_request!

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
    assert response.status_code == 400
  end

  test_with_server "works with response headers as map with string keys" do
    route "/", Response.ok!(~s<{"response": "ok"}>, %{"Content-Type" => "application/json"})

    response = HTTPoison.get! FakeServer.address <> "/"
    assert Enum.any?(response.headers, fn(header) -> header == {"Content-Type", "application/json"} end)
  end

  test_with_server "works when the response is created with a map as response body" do
    route "/", Response.ok!(%{response: "ok"})

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.body == ~s<{"response":"ok"}>
  end

  test_with_server "works when the response is created with a string as response body" do
    route "/", Response.ok!(~s<{"response":"ok"}>)

    response = HTTPoison.get! FakeServer.address <> "/"
    assert response.body == ~s<{"response":"ok"}>
  end

  test_with_server "raise FakeServer.Error when response is invalid on a route" do
    assert_raise FakeServer.Error, fn -> route "/", Response.new!(600) end
    assert_raise FakeServer.Error, fn -> route "/", Response.ok!(1) end
    assert_raise FakeServer.Error, fn -> route "/", Response.ok!("", []) end
  end

  test_with_server "raise FakeServer.Error when path is invalid" do
    assert_raise FakeServer.Error, fn -> route "abc", Response.ok!() end
    assert_raise FakeServer.Error, fn -> route '/abc', Response.ok!() end
    assert_raise FakeServer.Error, fn -> route :abc, Response.ok!() end
    assert_raise FakeServer.Error, fn -> route 123, Response.ok!() end
    assert_raise FakeServer.Error, fn -> route [], Response.ok!() end
  end

  describe "when using ResponseFactory" do
    test_with_server "generates a response wiht custom data" do
      customized_response = %{body: body} = FakeResponseFactory.build(:person)
      person = Poison.decode!(body, keys: :atoms)

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
      customized_response = %{body: body} = FakeResponseFactory.build(:person)
      person = Poison.decode!(body, keys: :atoms)

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
        person = Poison.decode!(person.body, keys: :atoms)
        body = Poison.decode!(response.body)

        assert response.status_code == 200
        assert person[:name] == body["name"]
        assert person[:email] == body["email"]
        assert person[:company][:name] == body["company"]["name"]
        assert person[:company][:country] == body["company"]["country"]
      end)
    end
  end

  describe "when using functions" do
    test_with_server "reply with the function return if it's a valid Response struct" do
      route "/", fn(_) -> Response.ok! end

      response = HTTPoison.get! FakeServer.address <> "/"
      assert response.status_code == 200
    end

    #test_with_server "reply with the function return if it's a valid Response struct from a factory" do
    #  route "/", fn(_) -> FakeResponseFactory.build(:person) end

    #  response1 = HTTPoison.get! FakeServer.address <> "/"
    #  assert response1.status_code == 200
    #  response2 = HTTPoison.get! FakeServer.address <> "/"
    #  assert response2.status_code == 200
    #  assert response1 != response2
    #end

    test_with_server "returns default_response if the function return is not a Response struct or list of responses" do
      route "/", fn(_) -> :ok end

      response = HTTPoison.get! FakeServer.address <> "/"
      assert response.status_code == 200
      assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
    end

    test_with_server "accepts the request object as argument" do
      route "/", fn(req) ->
        if req.query_string["token"]  == "1234" do
          Response.ok!
        else
          Response.forbidden!
        end
      end

      response = HTTPoison.get! FakeServer.address <> "/"
      assert response.status_code == 403

      response = HTTPoison.get! FakeServer.address <> "/?token=1234&abc=def"
      assert response.status_code == 200
    end

    test_with_server "can evaluate the request body" do
      route "/", fn(req) ->
        if req.body  == ~s<{"test": true}> do
          Response.ok! %{test: true}
        else
          Response.ok! %{test: false}
        end
      end

      address = FakeServer.address <> "/"

      response = HTTPoison.post! address, ~s<{"test": true}>
      assert response.status_code == 200
      assert response.body == ~s<{"test":true}>

      response = HTTPoison.post! address, ~s<{}>
      assert response.body == ~s<{"test":false}>
    end

    test_with_server "turn the body into map if the request content-type is application/json" do
      route "/", fn(req) ->
        if req.body  == %{"test" => true} do
          Response.ok! %{test: true}
        else
          Response.ok! %{test: false}
        end
      end

      address = FakeServer.address <> "/"

      response = HTTPoison.post! address, ~s<{"test": true}>, %{"content-type" => "application/json"}
      assert response.status_code == 200
      assert response.body == ~s<{"test":true}>

      response = HTTPoison.post! address, ~s<{"test": true}>
      assert response.body == ~s<{"test":false}>
    end
  end

  test_with_server "can handle all 2xx status codes" do
    response_list = [
      Response.ok!,
      Response.created!,
      Response.accepted!,
      Response.non_authoritative_information!,
      Response.no_content!,
      Response.reset_content!,
      Response.partial_content!
    ]

    route "/", response_list

    Enum.each(response_list, fn(response) ->
      get_response = HTTPoison.get! FakeServer.address <> "/"
      assert get_response.status_code == response.code
    end)
  end

  test_with_server "can handle all 4xx status codes" do
    route "/", Response.all_4xx

    Enum.each(Response.all_4xx, fn(response) ->
      get_response = HTTPoison.get! FakeServer.address <> "/"
      assert get_response.status_code == response.code
    end)
  end

  test_with_server "can handle all 5xx status codes" do
    route "/", Response.all_5xx

    Enum.each(Response.all_5xx, fn(response) ->
      get_response = HTTPoison.get! FakeServer.address <> "/"
      assert get_response.status_code == response.code
    end)
  end
end
