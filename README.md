# FakeServer
[![Build Status](https://travis-ci.org/bernardolins/fake_server.svg?branch=master)](https://travis-ci.org/bernardolins/fake_server)
[![Coverage Status](https://coveralls.io/repos/github/bernardolins/fake_server/badge.svg?branch=master)](https://coveralls.io/github/bernardolins/fake_server?branch=master)

FakeServer is a simple HTTP server used to mock external services responses on your tests. With it, you can simulate services instability, check if the external request was made or if the cache was used, and many other complex scenarios that can be very difficult to simulate on a test. When you create the server, you provide a list of status, and the requests will be responded with the first status on that list, in order of arrival. If there are no more status, the server will respond always 200.

## Documentation
Detailed documentation is available on [Hexdocs](https://hexdocs.pm/fake_server/0.3.0)


**Important:** From version *0.2.1* to *0.3.0*, `FakeServer.Server` was replaced by `FakeServer`

## Basic Usage

FakeServer is foccused on common scenarios that are difficult to simulate on a test, like:

1. Test how your application behaves when an external service responds with multiple error codes;
2. Validate if your application access cache, or serves stale when the external server is down
3. Test retries
4. Verify timeouts
5. Multiple servers responses

Just be creative, almost any scenario can be simulated with FakeServer, all with a simple and easy interface.

```elixir
### test/test_helper.exs
ExUnit.start()

# create some status that your external server could respond with
# you just need to do it once for you entire test suite.
FakeServer.Status.create(:status200, %{response_code: 200, response_body: ~s<"username": "mr_user">})
FakeServer.Status.create(:status500, %{response_code: 500, response_body: ~s<"error": "internal server error">})
FakeServer.Status.create(:status403, %{response_code: 403, response_body: ~s<"error": "forbidden">})


### test/user_test.exs
defmodule UserTest do
  use ExUnit.Case
  
  test "#get returns user if the external server responds 200" do
    # start a fake server with a list of status you just created
    # the fake server will respond with the first status on the list
    # after that, the status will be removed
    # this repeats for every request you make
    # if the list empties, the server will respond 200.
    {:ok, address} = FakeServer.run(:external_server, :status200)

    # point your application to the new fake server
    System.put_env(:external_server_url, address)

    # make the request to the fake server and validate it works
    assert User.get == %{username: "mr_user"}

    # stop the server, so you can use it again in the following tests
    FakeServer.stop(:external_server)
  end
  
  test "#get retry up to 3 times when external server responds with 500" do
    # you can run the server on a default port instead of a random one
    {:ok, address} = FakeServer.run(:external_server, [:status500, :status500, :status500, :status200], %{port: 5000})
    System.put_env(:external_server_url, address)

    # you can easily test a retry scenario, where one call to the external service makes multiple requests
    assert User.get == %{username: "mr_user"}
    FakeServer.stop(:external_server)
  end
  
  test "#get returns timeout after 3 retries" do
    {:ok, address} = FakeServer.run(:external_server, [:status500, :status500, :status500, :status500])
    System.put_env(:external_server_url, address)

    assert User.get == %{error: "timeout", code: 408}
    FakeServer.stop(:external_server)
  end

  test "#get serves stale when external server is down" do
    {:ok, address} = FakeServer.run(:external_server, [:status200, :status500])
    System.put_env(:external_server_url, address)

    # our application saves cache on the first successfull response
    # so we make a get request with a 200 response from fake server
    User.get

    # the second response from fake server is 500, but there is cache!
    # that's how we know the stale is working
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
