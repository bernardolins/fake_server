# FailWhale
[![Build Status](https://travis-ci.org/bernardolins/fail-whale.svg?branch=master)](https://travis-ci.org/bernardolins/fail-whale)
[![Coverage Status](https://coveralls.io/repos/github/bernardolins/fail-whale/badge.svg?branch=master)](https://coveralls.io/github/bernardolins/fail-whale?branch=master)

```elixir
setup do
  FailWhale.Action.create(:st200, %{response_code: 200, response_body: ~s<"username": "mr_user">})
  FailWhale.Action.create(:st400, %{response_code: 400, response_body: ~s<"error": "bad request">})
  FailWhale.Action.create(:st403, %{response_code: 403, response_body: ~s<"error": "forbidden">})
  
  FailWhale.Behavior.create(:bh1, [:st403, :st403, :st403])
  FailWhale.Behavior.create(:bh2, [:st403, :st200])
  FailWhale.Behavior.create(:bh3, [:st200])
end

test "get user when 200" do
  FailWhale.Server.run(:bh3)
  assert User.get == %{username: "mr_user"}
end

test "retry when forbidden" do
  FailWhale.Server.run(:bh2)
  assert User.get == %{username: "mr_user"}
end

test "retry 3 times and timeout" do
  FailWhale.Server.run(:bh1)
  assert User.get == %{error: "timeout", code: 408}
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add fail_whale to your list of dependencies in `mix.exs`:

        def deps do
          [{:fail_whale, "~> 0.0.1"}]
        end

  2. Ensure fail_whale is started before your application:

        def application do
          [applications: [:fail_whale]]
        end

