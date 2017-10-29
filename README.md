# FakeServer
[![Build Status](https://travis-ci.org/bernardolins/fake_server.svg?branch=master)](https://travis-ci.org/bernardolins/fake_server)
[![Coverage Status](https://coveralls.io/repos/github/bernardolins/fake_server/badge.svg?branch=master)](https://coveralls.io/github/bernardolins/fake_server?branch=master)
[![Inline docs](http://inch-ci.org/github/bernardolins/fake_server.svg?branch=master&style=shields)](http://inch-ci.org/github/bernardolins/fake_server)

FakeServer makes it easy to create mocks for HTTP servers in your tests. It integrates very well with ExUnit, but can also be used as a standalone server.

Following this README you will see some basic examples of usage. More details can be found in the documentation available on [Hexdocs](https://hexdocs.pm/fake_server/api-reference.html).

**Important:** This README follows the master branch, that may not have been published yet. Therefore, information contained herein may not be present in the docs.

## Installation

FakeServer is available on [Hex](https://hex.pm/packages/fake_server). All you have to do is to add it to `mix.exs` as a test dependency.

```elixir
def deps do
  [{:fake_server, "~> 1.0", only: :test}]
end
```

Start `fake_server` application on `test/test_helper.exs`

```elixir
{:ok, _} = Application.ensure_all_started(:fake_server)
```

## ExUnit integration

To use FakeServer together with ExUnit, simply write your tests using the `test_with_server` macro.

### Running a test with a server
`test_with_server`, starts an HTTP server, initially without any route configured (that is, any request will be replied with 404).

```elixir
test_with_server "server will always reply 404 without any route configured", do
  response = HTTPoison.get! FakeServer.address <> "/"
  assert response.status_code == 404

  response = HTTPoison.get! FakeServer.address <> "/any/route"
  assert response.status_code == 404

  response = HTTPoison.get! FakeServer.address <> "/another/route"
  assert response.status_code == 404
end
```

### Adding routes

You can add routes to your server through the `route` macro.

A route can reply a request in 3 ways:
  1. directly returning the response;
  2. iterating a list;
  3. querying a FakeController.

#### With a single response

```elixir
# test/my_app/some_module_test.exs

describe "with a single response element" do
  test_with_server "reply with this element once and then uses a default response" do
    route "/test", do: Response.bad_request

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200
    assert response.body == "This is a default response from FakeServer"
  end

  test_with_server "this default response can be configured", [default_response: Response.forbidden] do
    route "/test", do: Response.bad_request

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 403
  end
end
```

#### With a list of responses

```elixir
# test/my_app/some_module_test.exs

describe "with a list of responses" do
  test_with_server "responds with the first element until the list empties, and then uses a default response" do
    route "/test", do: [Response.ok, Response.not_found, Response.bad_request]

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 404

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 400

    # reply the default_response when the list empties
    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 200
    assert response.body == "This is a default response from FakeServer"
  end

  test_with_server "this default response can be configured", [default_response: Response.forbidden] do
    route "/test", do: []

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 403

    response = HTTPoison.get! FakeServer.address <> "/test"
    assert response.status_code == 403
  end
end
```

#### With FakeControllers
With FakeControllers you can analyze the content of the request and choose the type of response dynamically.

A controller is a special function that is executed every time a route configured with it receives a request.

```elixir
# test/support/fake_controllers.ex

# Create a module with your controllers and use the
# FakeController.__using__ macro on this module
defmodule FakeServer.Integration.FakeControllers do
  use FakeController

  # Controller names must end in _controller
  # Also, they receive a single argument
  # They must return an %FakeServer.HTTP.Response struct
  def query_string_controller(conn) do
    if :cowboy_req.qs_val("token", conn) |> elem(0) == "1234" do
      FakeServer.HTTP.Response.ok
    else
      FakeServer.HTTP.Response.unauthorized
    end
  end
end

# test/my_app/some_test.exs

test_with_server "evaluates FakeController and reply accordingly" do
  # Every time a request arrives at root path, the controller
  # will be executed to determine which response should be given
  # Note that _controller is not needed on the controller name this time!
  route "/", do: use_controller :query_string

  response = HTTPoison.get! FakeServer.address <> "/"
  assert response.status_code == 401

  response = HTTPoison.get! FakeServer.address <> "/?token=1234"
  assert response.status_code == 200
end
```

### Server configuration

The `test_with_server` macro accepts a keyword list with arguments to the server that will be created.

```elixir
# test/my_app/some_test.exs
test_with_server "accepts the port argument to configure a custom port for the server", [port: 5001] do
  assert FakeServer.address == "127.0.0.1:5001"

  route "/", do: Response.bad_request

  response = HTTPoison.get! "127.0.0.1:5001" <> "/"
  assert response.status_code == 400
end

test_with_server "accepts the default_response argument to configure the server default response", [default_response: Response.bad_request] do
  route "/", do: []
  response = HTTPoison.get! FakeServer.address <> "/"
  assert response.status_code == 400
end
```
