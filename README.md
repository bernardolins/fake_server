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
  [{:fake_server, github: "bernardolins/fake_server", ref: "master", only: :test}]
end
```

Start `fake_server` application on `test/test_helper.exs`
```elixir
{:ok, _} = Application.ensure_all_started(:fake_server)
```

## Responses
For FakeServer, a response is a struct `% FakeServer.HTTP.Response {}`.

This struct accepts three fields:

1. The `body` string
2. The positive integer `code` (required)
3. The `headers` array

```elixir
Iex (1)>% FakeServer.HTTP.Response {code: 403}
%FakeServer.HTTP.Response {body: "", code: 403, headers: []}
Iex (2)>% FakeServer.HTTP.Response {body: ~ s <{"message": "Hello world!"}}}
** (ArgumentError) the following keys must also be given when building struct FakeServer.HTTP.Response: [: code]
     (Fake_server) expanding struct: FakeServer.HTTP.Response .__ struct __ / 1
                   Iex: 2: (file)>}
iex(3)> FakeServer.HTTP.Response.default
%FakeServer.HTTP.Response{body: "This is a default response from FakeServer",
 code: 200, headers: []}
```

## Using with ExUnit
FakeServer integrates with ExUnit through the `test_with_server` macro.

Within the execution block of the macro is available an HTTP server, which can be accessed at the address (in the 127.0.0.1:port format) saved in the `fake_server_address` variable.

Also, this server is uniquely identified through a hash, which is available in the `fake_server` variable. FakeServer needs this hash to know on which server the operations should be performed. This allows the tests to run asynchronously without problems.

The server is created without any route, that is, any access will be replied with 404. To add a route, just use the `route` macro.

Let's see some examples:

### With a single response

The most basic way of using it is to add a path that replies to a single response. In the default configuration of a route in FakeServer, this reply will be given only for the first request. The following requests will be answered with a configurable `default_response`.

If you always want to respond with the same answer, consider using a `FakeController`.

```elixir
# test/my_app/some_module_test.exs

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

You can also configure a route to respond with elements in a list. Each request will be replied with the first item in the list, which is then removed. This continues until the list empties. When the list is empty, any request will be replied with `default_response`.

```elixir
# test/my_app/some_module_test.exs

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
With FakeControllers you can analyze the content of the request and choose the type of response dynamically.

FakeControllers are functions with the name ending in `_controller`, arity 1, and that return a struct`% FakeServer.HTTP.Response {} `, defined inside some module that uses` FakeController`.

These functions are executed every time a request arrives at a route configured with a controller.

Its argument is a `conn` tuple, which contains various request information, such as query strings and headers.

To use a controller, simply call the `use_controller` macro in the route configuration, passing the controller name without` _controller` as an argument.

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
