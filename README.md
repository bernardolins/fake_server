# FakeServer
[![Build Status](https://travis-ci.org/bernardolins/fake_server.svg?branch=master)](https://travis-ci.org/bernardolins/fake_server)
[![Coverage Status](https://coveralls.io/repos/github/bernardolins/fake_server/badge.svg?branch=master)](https://coveralls.io/github/bernardolins/fake_server?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/dt/fake_server.svg)](https://hex.pm/packages/fake_server)

FakeServer is an HTTP server that simulates responses. It can be used in test and development environments, helping to validate the behavior of your application if there are errors or unexpected responses from some external HTTP service.

It provides the `test_with_server` macro to be used together with [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html), making it easier to write tests that need to request external services. Instead of creating a mock when you need make a request, you can use a real HTTP server that will reply a deterministic response. This way you can validate if your application can handle it.

`FakeServer` can also be used through functions, when ExUnit is not available (in the console, for example).

## Installation

**Important**: From the version 2.0, FakeServer only supports cowboy 2.x. If you have cowboy 1.x as dependency, use FakeServer version 1.5.

FakeServer is available on [Hex](https://hex.pm/packages/fake_server). First, add it to `mix.exs` as a test dependency:

```elixir
def deps do
  [
    {:fake_server, "~> 2.0", only: :test}
  ]
end
```

Then, start `fake_server` application on `test/test_helper.exs`.

```elixir
{:ok, _} = Application.ensure_all_started(:fake_server)
```

## Basic Usage

For more examples you can see the [docs](https://hexdocs.pm/fake_server/api-reference.html).

### ExUnit

FakeServer provides the macro `FakeServer.test_with_server`. It works like ExUnit's `test` macro, but before your test starts it will run an HTTP server in a random port (by default). The server will be available until test case is finished.

You can use the `FakeServer.route` macro to add a route and setup it's response. Use `FakeServer.http_address` to get the address of the server running in the current test. Each test will start its own HTTP server.

```elixir
defmodule MyTest do
  use ExUnit.Case
  import FakeServer

  test_with_server "returns 404 if a request is made to a non-configured route" do
    response = HTTPoison.get!("#{FakeServer.address}/not/configured")
    assert response.status_code == 404
  end

  test_with_server "when the response is a structure it returns the given response" do
    route "/test", Response.no_content!()
    response = HTTPoison.get!("#{FakeServer.address}/test")
    assert response.status_code == 204
  end

  test_with_server "when the response is a list it returns the first element of the list and removes it" do
    route "/test", [Response.ok!(), Response.no_content!()]
    response = HTTPoison.get!("#{FakeServer.address}/test")
    assert response.status_code == 200
    response = HTTPoison.get!("#{FakeServer.address}/test")
    assert response.status_code == 204
  end

  test_with_server "when the response is a function it runs the function" do
    route "/say/hi", fn(_) -> IO.puts "HI!" end
    response = HTTPoison.get! "#{FakeServer.address}/say/hi"
  end

  test_with_server "computes hits for the corresponding route" do
    route "/test", Response.no_content!()
    assert hits() == 0
    assert hits("/test") == 0
    HTTPoison.get!("#{FakeServer.address}/test")
    assert hits() == 1
    assert hits("/test") == 1
  end

  test_with_server "supports inline port configuration", [port: 55_000] do
    assert FakeServer.port() == 55_000
  end
end
```
#### Setup Server

If you need to do some setup before every `test_with_server` tests, you can define a `setup_test_with_server/1` function in your module. This function will receive a %FakeServer.Instance{} struct as a parameter.


### Standalone Server

You can use a fake server without ExUnit with `FakeServer.start` and other helper functions available. Functions work similar to macros, but can be used outside the tests.

```elixir
iex> {:ok, pid} = FakeServer.start(:my_server)
{:ok, #PID<0.302.0>}

iex> :ok = FakeServer.put_route(pid, "/say/hi", fn(_) -> IO.puts "HI!" end)
:ok

iex> {:ok, port} = FakeServer.port(:my_server)
{:ok, 62698}
```
For more examples you can see the [docs](https://hexdocs.pm/fake_server/api-reference.html).
