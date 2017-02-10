# FakeServer
[![Build Status](https://travis-ci.org/bernardolins/fake_server.svg?branch=master)](https://travis-ci.org/bernardolins/fake_server)
[![Coverage Status](https://coveralls.io/repos/github/bernardolins/fake_server/badge.svg?branch=master)](https://coveralls.io/github/bernardolins/fake_server?branch=master)
[![Inline docs](http://inch-ci.org/github/bernardolins/fake_server.svg?branch=master&style=shields)](http://inch-ci.org/github/bernardolins/fake_server)

FakeServer is a simple Elixir library that helps you to mock web requests.

## Installation

FakeServer is available on [Hex](https://hex.pm/packages/fake_server). To use it on your application, just add it to `mix.exs` as a test dependency.

```elixir
def deps do
  [{:fake_server, "~> 1.0.0", only: :test}]
end
```
## How it works

```elixir
# test/support/response_factories.exs

defmodule MyApp.ResponseFactories do
  use FakeServer
end

# test/my_app/car_api_gateway_test.exs

defmodule CarAPIGatewayTest do
  use ExUnit.Case, async: true
  import FakeServer

  describe "#get" do
    test_with_server "return an array containing all cars" do
      Application.set_env :my_app, :car_api_address, fake_server[:address]
      cars_json = ~s<[{"model": "Camaro", "manufacturer": "Chevrolet"}, {"model": "Mustang", "manufacturer": "Ford"}]>
      route "/cars.json" do
        FakeServer.HTTP.Response.ok(body: cars_json)
      end

      [car1, car2] = MyApp.CarAPIGateway.get
      assert car1[:model] == "Camaro"
      assert car1[:manufacturer] == "Chevrolet"

      assert car2[:model] == "Mustang"
      assert car2[:manufacturer] == "Ford"
    end

    test_with_server "save cache when response is 200" do
      Application.set_env :my_app, :car_api_address, fake_server[:address]
      route "/cars.json" do
        FakeServer.HTTP.Response.ok
      end

      MyApp.CarAPI.Gateway.get
      MyApp.CarAPI.Gateway.get
      MyApp.CarAPI.Gateway.get

      assert fake_server[:hits] == 1
    end

    # cyclic will cause the server to repeat
    test_with_server "dont store cars on cache when response is not 200", [respond_with: FakeServer.HTTP.Response.bad_request] do
      Application.set_env :my_app, :car_api_address, fake_server[:address]

      MyApp.CarAPI.Gateway.get
      MyApp.CarAPI.Gateway.get
      MyApp.CarAPI.Gateway.get

      assert fake_server_hits == 3
    end
  end
end

## Documentation
Detailed documentation is available on [Hexdocs](https://hexdocs.pm/fake_server/api-reference.html)
