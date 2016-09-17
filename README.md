# Fakex
[![Build Status](https://travis-ci.org/bernardolins/fail-whale.svg?branch=master)](https://travis-ci.org/bernardolins/fail-whale)
[![Coverage Status](https://coveralls.io/repos/github/bernardolins/fakex/badge.svg?branch=master)](https://coveralls.io/github/bernardolins/fakex?branch=master)

```elixir
setup do
  Fakex.Action.create(:st200, %{response_code: 200, response_body: ~s<"username": "mr_user">})
  Fakex.Action.create(:st400, %{response_code: 400, response_body: ~s<"error": "bad request">})
  Fakex.Action.create(:st403, %{response_code: 403, response_body: ~s<"error": "forbidden">})
  
  Fakex.Behavior.create(:bh1, [:st403, :st403, :st403])
  Fakex.Behavior.create(:bh2, [:st403, :st200])
  Fakex.Behavior.create(:bh3, [:st200])
end

test "get user when 200" do
  Fakex.Server.run(:bh3)
  assert User.get == %{username: "mr_user"}
end

test "retry when forbidden" do
  Fakex.Server.run(:bh2)
  assert User.get == %{username: "mr_user"}
end

test "retry 3 times and timeout" do
  Fakex.Server.run(:bh1)
  assert User.get == %{error: "timeout", code: 408}
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add fakex to your list of dependencies in `mix.exs`:

        def deps do
          [{:fakex, "~> 0.0.1"}]
        end

  2. Ensure fakex is started before your application:

        def application do
          [applications: [:fakex]]
        end

