# FakeServer
[![Build Status](https://travis-ci.org/bernardolins/fake_server.svg?branch=master)](https://travis-ci.org/bernardolins/fake_server)
[![Coverage Status](https://coveralls.io/repos/github/bernardolins/fake_server/badge.svg?branch=master)](https://coveralls.io/github/bernardolins/fake_server?branch=master)

FakeServer is a simple HTTP server used to simulate external services instability on your tests. When you create the server, you provides a list of status, and the requests will be responded with those status, in order of arrival. If there are no more status, the server will respond always 200.

## Documentation
Detailed documentation is available on [Hexdocs](https://hexdocs.pm/fake_server/0.3.0)

## Basic Usage

**Important:** From version *0.2.1* to *0.3.0*, `FakeServer.Server` was replaced by `FakeServer`

```elixir
defmodule UserTest do
  use ExUnit.Case

  setup_all do
    # create some status that your external server could respond with
    # you just need to do it once for you entire test suite.
    FakeServer.Status.create(:status200, %{response_code: 200, response_body: ~s<"username": "mr_user">})
    FakeServer.Status.create(:status500, %{response_code: 500, response_body: ~s<"error": "internal server error">})
    FakeServer.Status.create(:status403, %{response_code: 403, response_body: ~s<"error": "forbidden">})
    :ok
  end
  
  test "#get returns user if the external server responds 200" do
    # start a fake server with a list of status
    {:ok, address} = FakeServer.run(:external_server, :status200)
    # tell your application to access the server
    System.put_env(:external_server_url, address)
    assert User.get == %{username: "mr_user"}
    # stop the server
    FakeServer.stop(:external_server)
  end
  
  test "#get retry up to 3 times when external server responds with 500" do
    {:ok, address} = FakeServer.run(:external_server, [:status500, :status500, :status500, :status200])
    System.put_env(:external_server_url, address)
    # user will be get after 3 retrys
    assert User.get == %{username: "mr_user"}
    FakeServer.stop(:external_server)
  end
  
  test "#get returns timeout after 3 retrys" do
    {:ok, address} = FakeServer.run(:external_server, [:status500, :status500, :status500, :status500])
    System.put_env(:external_server_url, address)
    assert User.get == %{error: "timeout", code: 408}
    FakeServer.stop(:external_server)
  end

  test "#get reads cache when requisition failed" do
    # you can tell the server to use a default port instead of a random one
    {:ok, address} = FakeServer.run(:external_server, [:status200, :status500], %{port: 5000})
    System.put_env(:external_server_url, address)
    # first get ensures there is some cache available...
    User.get
    # this request got a 500 as response, but there is cache!
    assert User.get == %{username: "mr_user"}
    FakeServer.stop(:external_server)
  end
end
```

## Installation

FakeServer is available on [Hex](https://hex.pm/packages/fake_server/0.3.0). To use it on your application, just add it to `mix.exs` as a test dependency.

```elixir
def deps do
  [{:fake_server, "~> 0.3.0", only: :test}]
end
```
