defmodule Fakex.BehaviorTest do
  use ExUnit.Case
  doctest Fakex

  test "#begin start a new agent with module name and empty Keyword list" do
    Fakex.Behavior.begin
    assert Agent.get(Fakex.Behavior, fn(list) -> list end) == []
  end

  test "#add return error if name is not atom" do
    assert Fakex.Behavior.add("some_invalid_name", code: 200, body: ~s<"user": "test">) == {:error, :invalid_name}
  end

  test "#add returns error if name not provided" do
    assert Fakex.Behavior.add(code: 200) == {:error, :invalid_name}
  end

  test "#add put a new behavior on the list" do
  end
end
