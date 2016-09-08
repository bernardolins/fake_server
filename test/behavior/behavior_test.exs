defmodule Fakex.BehaviorTest do
  use ExUnit.Case
  doctest Fakex

  test "#begin start a new agent with module name and empty Keyword list" do
    Fakex.Behavior.begin
    assert Agent.get(Fakex.Behavior, fn(list) -> list end) == []
  end
end
