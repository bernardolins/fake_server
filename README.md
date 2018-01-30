# FakeServer
[![Build Status](https://travis-ci.org/bernardolins/fake_server.svg?branch=master)](https://travis-ci.org/bernardolins/fake_server)
[![Coverage Status](https://coveralls.io/repos/github/bernardolins/fake_server/badge.svg?branch=master)](https://coveralls.io/github/bernardolins/fake_server?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/dt/fake_server.svg)](https://hex.pm/packages/fake_server)
[![Inline docs](http://inch-ci.org/github/bernardolins/fake_server.svg?branch=master&style=shields)](http://inch-ci.org/github/bernardolins/fake_server)

With FakeServer you can create individual HTTP servers each test case, allowing external requests to be tested without the need for mocks. It integrates well with ExUnit, keeping the tests clean and readable.

There is an [example application](https://github.com/bernardolins/exfootball) that uses FakeServer and contains several usage examples. The [docs](https://hexdocs.pm/fake_server/api-reference.html) also shows more details of all the features available in the library.

## Installation

FakeServer is available on [Hex](https://hex.pm/packages/fake_server). First, add it to `mix.exs` as a test dependency:

```elixir
def deps do
  [
    {:fake_server, "~> 1.3", only: :test}
  ]
end
```

Then, start `fake_server` application on `test/test_helper.exs`.

```elixir
{:ok, _} = Application.ensure_all_started(:fake_server)
```

## Basic Usage

FakeServer provides the macro `FakeServer.test_with_server`. It works like ExUnit's `test` macro, but before your test starts it will run an HTTP server in a random port (by default). The server will be available until test case is finished.

You can use the `FakeServer.route` macro to add a route and setup it's response. Use `FakeServer.address` to get the address of the server running in the current test.

```elixir
# extracted from https://github.com/bernardolins/exfootball

defmodule Exfootball.External.FootballDataTest do
  use ExUnit.Case
  import FakeServer

  alias Exfootball.External.FootballData

  describe "#list_competitions" do
    test_with_server "returns a map with the same size of the list of competitions replied by football-data api" do
      Application.put_env(:exfootball, :football_data_api_url, "http://#{FakeServer.address}")

      route "/competitions", FakeServer.HTTP.Response.ok([
           %{id: 444, caption: "Campeonato Brasileiro da Série A"},
           %{id: 445, caption: "Premier League 2017/18"},
           %{id: 446, caption: "Championship 2017/18"}
          ],
          %{"content-type" => "application/json"}
        )
      end

      assert Enum.count(FootballData.list_competitions) == 3
    end
  end
end
```

For more examples see the [docs](https://hexdocs.pm/fake_server/api-reference.html) or the [example application](https://github.com/bernardolins/exfootball), which uses [Tesla](https://github.com/teamon/tesla) to request [football-data](https://www.football-data.org/docs/v1/index.html) api.
