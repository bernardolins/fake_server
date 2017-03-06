# FakeServer
[![Build Status](https://travis-ci.org/bernardolins/fake_server.svg?branch=master)](https://travis-ci.org/bernardolins/fake_server)
[![Coverage Status](https://coveralls.io/repos/github/bernardolins/fake_server/badge.svg?branch=master)](https://coveralls.io/github/bernardolins/fake_server?branch=master)
[![Inline docs](http://inch-ci.org/github/bernardolins/fake_server.svg?branch=master&style=shields)](http://inch-ci.org/github/bernardolins/fake_server)

FakeServer provides some helpers to easily mock HTTP servers on your tests. You can configure a server, some routes and choose what each route will reply based on your needs.

FakeServer integrates with [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) but can be used as a standalone server either.

## Installation

FakeServer is available on [Hex](https://hex.pm/packages/fake_server). All you have to do is to add it to `mix.exs` as a test dependency. 

This version is not released to hex yet. You can use it by adding a `github` option to your `mix.exs`.

```elixir
def deps do
  [{:fake_server, github: "bernardolins/fake_server", ref: "master", only: :test}]
end
```

Start `fake_server` application on `test/test_helper.exs`
```elixir
{:ok, _} = Application.ensure_all_started(:fake_server)
```

## Documentation
Detailed documentation is available on [Hexdocs](https://hexdocs.pm/fake_server/api-reference.html)

## Using with ExUnit

Please, refer to [docs](https://hexdocs.pm/fake_server/api-reference.html) for more details. Also, there are some usage examples at `test/integration` directory.

Even if the examples here are using `GET` requests, you should be able to use any HTTP method.

### With a single response

```elixir
# test/support/fake_controllers.ex
test_with_server "accepts a single element" do
  route fake_server, "/test", do: Response.bad_request

  response = HTTPoison.get! fake_server_address <> "/test"
  assert response.status_code == 400

  response = HTTPoison.get! fake_server_address <> "/test"
  assert response.status_code == 200
  assert response.body == "This is a default response from FakeServer"
end

test_with_server "default response can be configured and will be replied when there are no more responses", [default_response: Response.forbidden] do
  route fake_server, "/test", do: Response.bad_request

  response = HTTPoison.get! fake_server_address <> "/test"
  assert response.status_code == 400

  response = HTTPoison.get! fake_server_address <> "/test"
  assert response.status_code == 403
end
```

### With a list of responses

```elixir
# test/support/fake_controllers.ex
test_with_server "reply the first element of the list and remove it" do
  route fake_server, "/test", do: [Response.ok, Response.not_found, Response.bad_request]

  response = HTTPoison.get! fake_server_address <> "/test"
  assert response.status_code == 200

  response = HTTPoison.get! fake_server_address <> "/test"
  assert response.status_code == 404

  response = HTTPoison.get! fake_server_address <> "/test"
  assert response.status_code == 400

  # reply the default_response when the list empties
  response = HTTPoison.get! fake_server_address <> "/test"
  assert response.status_code == 200
  assert response.body == "This is a default response from FakeServer"
end

test_with_server "default response will be replied if server is configured with an empty list", [default_response: Response.forbidden] do
  route fake_server, "/test", do: []

  response = HTTPoison.get! fake_server_address <> "/test"
  assert response.status_code == 403

  response = HTTPoison.get! fake_server_address <> "/test"
  assert response.status_code == 403
end
```

### FakeControllers

```elixir
# test/support/fake_controllers.ex
defmodule FakeServer.Integration.FakeControllers do
  use FakeController

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
  route fake_server, "/", do: use_controller :query_string
  response = HTTPoison.get! fake_server_address <> "/"
  assert response.status_code == 401

  response = HTTPoison.get! fake_server_address <> "/?token=1234"
  assert response.status_code == 200
end
```

### Server configuration

```elixir
# test/my_app/some_test.exs
test_with_server "with port configured, server will listen on the port provided", [port: 5001] do
  assert fake_server_address == "127.0.0.1:5001"
  response = HTTPoison.get! "127.0.0.1:5001" <> "/"
  assert response.status_code == 404
end

test_with_server "default response can be configured and will be replied if response list is empty", [port: 5001, default_response: Response.bad_request] do
  route fake_server, "/", do: []
  response = HTTPoison.get! fake_server_address <> "/"
  assert response.status_code == 400
end
```
