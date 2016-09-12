defmodule Fakex.ActionTest do
  use ExUnit.Case
  doctest Fakex

  @valid_behavior %{response_body: "\"user\": \"test\"", response_code: 200}
  test "#destroy_all return error if agent not started" do
    assert Fakex.Action.destroy_all == {:error, :no_action_to_destroy}
  end

  test "#destroy_all return :ok if agent is correctly destroy_alled" do
    Fakex.Action.create(:test, @valid_behavior)
    assert Fakex.Action.destroy_all == :ok
  end

  test "#create return error if name is not atom" do
    assert Fakex.Action.create("some_invalid_name", @valid_behavior) == {:error, :invalid_name}
  end

  test "#create returns error if name not provided" do
    assert Fakex.Action.create(@valid_behavior) == {:error, :name_not_provided}
  end

  test "#create returns error if response_body not provided" do
    assert Fakex.Action.create(:test, %{response_code: 200}) == {:error, :response_body_not_provided}
  end

  test "#create returns error if response_code not provided" do
    assert Fakex.Action.create(:test, %{response_body: ~s<"user": "test">}) == {:error, :response_code_not_provided}
  end

  test "#create put a new behavior on the list" do
    assert Fakex.Action.create(:test, @valid_behavior) == :ok
    assert Agent.get(Fakex.Action, fn(list) -> list end) == [test: @valid_behavior]
    Fakex.Action.destroy_all
  end

  test "#get returns all behaviors" do
    Fakex.Action.create(:test, @valid_behavior)
    assert Fakex.Action.get == {:ok, [test: @valid_behavior]}
    Fakex.Action.destroy_all
  end

  test "#get(name) returns behaviors by name" do
    Fakex.Action.create(:test, @valid_behavior)
    assert Fakex.Action.get(:test) == {:ok, @valid_behavior}
    Fakex.Action.destroy_all
  end

  test "#get(name) returns not found error if there are no behaviors with that name" do
    Fakex.Action.create(:test, @valid_behavior)
    assert Fakex.Action.get(:test2) == {:error, :not_found}
    Fakex.Action.destroy_all
  end
end
