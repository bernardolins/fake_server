# FakeServer
[![Build Status](https://travis-ci.org/bernardolins/fake_server.svg?branch=master)](https://travis-ci.org/bernardolins/fake_server)
[![Coverage Status](https://coveralls.io/repos/github/bernardolins/fake_server/badge.svg?branch=master)](https://coveralls.io/github/bernardolins/fake_server?branch=master)
[![Inline docs](http://inch-ci.org/github/bernardolins/fake_server.svg?branch=master&style=shields)](http://inch-ci.org/github/bernardolins/fake_server)

FakeServer is a simple Elixir library that helps you to mock web requests.

## Installation

FakeServer is available on [Hex](https://hex.pm/packages/fake_server). To use it on your application, just add it to `mix.exs` as a test dependency.

```elixir
def deps do
  [{:fake_server, "~> 0.4.1", only: :test}]
end
```
## How it works

First, you create some `FakeServer.Status`. Those status are the way the server will respond when a request arrives. In a status you specify the response code and body. You can add some headers to the response as well.

```elixir
iex(1)> FakeServer.Status.create(:status200, %{response_code: 200, response_body: "Hello World"})
:ok
iex(2)> FakeServer.Status.create(:status400, %{response_code: 400, response_body: "bad_request"})
:ok
iex(3)> FakeServer.Status.create(:status500, %{response_code: 500, response_body: "internal_server_error"})
:ok
```
*Multiple servers can use the same status, so you just need to define it once.*

Then, you create a server that uses some of the statuses available:
```elixir
iex(4)> FakeServer.run(:server_name, [:status200, :status500, :status400])
{:ok, "127.0.0.1:8259"}
```
Now you have an HTTP server running; You can access the server using the address returned by `FakeServer.run/2` function. This new server will respond with the status specified in the list you provided. The first request will get the first status as a response, and so on. When the server responds with a status, it is removed from the list and the server will respond with the next status.

```bash
$ curl 127.0.0.1:8259
Hello World
$ curl 127.0.0.1:8259
internal_server_error
$ curl 127.0.0.1:8259
bad_request
```

If the list empties, the request will get a default response:
```bash
$ curl 127.0.0.1:8259
"status": "no more actions"
```

## Using it on your tests

The primary use of FakeServer is on tests. It can simplify some complex to test scenarios, like timeouts, external servers instability, cache usage, and many others. Just be creative :)

Here are some usage examples:

**Important:** From version *0.2.1* to *0.3.0*, `FakeServer.Server` was replaced by `FakeServer`

```elixir
### test/test_helper.exs
ExUnit.start()

# create some status that your external server could respond with
# you just need to do it once for you entire test suite.
FakeServer.Status.create(:status200, %{response_code: 200, response_body: ~s<"username": "mr_user">})
FakeServer.Status.create(:status500, %{response_code: 500, response_body: ~s<"error": "internal server error">})
FakeServer.Status.create(:status403, %{response_code: 403, response_body: ~s<"error": "forbidden">})

# you can also pass `response_header` (optional):
FakeServer.Status.create(:status200, %{response_code: 200, response_body: "OK", resonse_headers: %{"Conent-Length": 5}})


### test/user_test.exs
defmodule UserTest do
  use ExUnit.Case

  setup_all do
    # you can run a single server on a test file
    # start a fake server with an empty status_list
    # you can ignore the third param if you want the server to run on a random port
    # when using a global server, make sure :async option is set to false on ExUnit
    {:ok, address} = FakeServer.run(:external_server, [], %{port: 5000})

    # point your application to the new fake server
    System.put_env(:external_server_url, address)

    # you can use ExUnit callback to stop the server
    on_exit fn ->
      FakeServer.stop(:external_server)
    end
  end

  test "#get returns user if the external server responds 200" do
    # add the status sequence you want the server to respond with
    # the fake server will respond with the first status on the list and remove it from the list
    # this repeats for every request you make
    # if the list empties, the server will respond 200.
    FakeServer.modify_behavior(:external_server, :status200)

    # make the request to the fake server and validate it works
    assert User.get == %{username: "mr_user"}
  end

  test "#get retry up to 3 times when external server responds with 500" do
    FakeServer.modify_behavior(:external_server, [:status500, :status500, :status500, :status200])

    # you can easily test a retry scenario, where one call to the external service makes multiple requests
    assert User.get == %{username: "mr_user"}
  end

  test "#get returns timeout after 3 retries" do
    # another retry example, this time with a timeout scenario
    FakeServer.modify_behavior(:external_server, [:status500, :status500, :status500, :status500])
    assert User.get == %{error: "timeout", code: 408}
  end

  test "#get serves stale when external server is down" do
    FakeServer.modify_behavior(:external_server, [:status200, :status500])

    # our application saves cache on the first successfull response
    # so we make a get request with a 200 response from fake server to save some cache
    User.get

    # the second response from fake server is 500, but there is cache!
    # that's how we know the stale is working
    assert User.get == %{username: "mr_user"}
  end
end
```
## Documentation
Detailed documentation is available on [Hexdocs](https://hexdocs.pm/fake_server/api-reference.html)
