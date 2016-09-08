defmodule Fakex.BehaviorTest do
  use ExUnit.Case
  doctest Fakex

  @valid_behavior %{response_body: "\"user\": \"test\"", response_code: 200}

  test "#begin start a new agent with module name and empty Keyword list" do
    Fakex.Behavior.begin
    assert Agent.get(Fakex.Behavior, fn(list) -> list end) == []
    Agent.stop(Fakex.Behavior)
  end

  test "#create return error if name is not atom" do
    assert Fakex.Behavior.create("some_invalid_name", @valid_behavior) == {:error, :invalid_name}
  end

  test "#create returns error if name not provided" do
    assert Fakex.Behavior.create(@valid_behavior) == {:error, :name_not_provided}
  end

  test "#create returns error if response_body not provided" do
    assert Fakex.Behavior.create(:test, %{response_code: 200}) == {:error, :response_body_not_provided}
  end

  test "#create returns error if response_code not provided" do
    assert Fakex.Behavior.create(:test, %{response_body: ~s<"user": "test">}) == {:error, :response_code_not_provided}
  end

  test "#create put a new behavior on the list" do
    Fakex.Behavior.begin
    assert Agent.get(Fakex.Behavior, fn(list) -> list end) == []
    assert Fakex.Behavior.create(:test, @valid_behavior) == :ok
    assert Agent.get(Fakex.Behavior, fn(list) -> list end) == [test: @valid_behavior]
    Agent.stop(Fakex.Behavior)
  end

  test "#get returns all behaviors" do
    Fakex.Behavior.begin
    Fakex.Behavior.create(:test, @valid_behavior)
    assert Fakex.Behavior.get == {:ok, [test: @valid_behavior]}
    Agent.stop(Fakex.Behavior)
  end

  test "#get returns an empty list if there are no behaviors" do
    Fakex.Behavior.begin
    assert Fakex.Behavior.get == {:ok, []}
    Agent.stop(Fakex.Behavior)
  end

  test "#get(name) returns behaviors by name" do
    Fakex.Behavior.begin
    Fakex.Behavior.create(:test, @valid_behavior)
    assert Fakex.Behavior.get(:test) == {:ok, @valid_behavior}
    Agent.stop(Fakex.Behavior)
  end

  test "#get(name) returns not found error if there are no behaviors with that name" do
    Fakex.Behavior.begin
    Fakex.Behavior.create(:test, @valid_behavior)
    assert Fakex.Behavior.get(:test2) == {:error, :not_found}
    Agent.stop(Fakex.Behavior)
  end

  test "#get(name) returns not found error if there are no behaviors at all" do
    Fakex.Behavior.begin
    assert Fakex.Behavior.get(:test) == {:error, :not_found}
    Agent.stop(Fakex.Behavior)
  end
end
