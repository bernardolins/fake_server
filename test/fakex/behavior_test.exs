defmodule Fakex.BehaviorTest do
  use ExUnit.Case
  doctest Fakex

  @valid_action_list [:status_200, :status_400, :timeout]
  @invalid_action_list [:status_200, :status_400, :invalid]

  setup_all do
    Fakex.Action.create(:status_200, %{response_code: 200, response_body: ~s<"user": "Test", "age": 25>})
    Fakex.Action.create(:status_400, %{response_code: 400, response_body: ~s<"error": "bad request">})
    Fakex.Action.create(:timeout, %{response_code: 408, response_body: ~s<"error": "request timeout">})
    :ok
  end

  test "#create creates a new behavior with given actions and current number of calls" do
    assert Fakex.Behavior.create(:test_behavior, @valid_action_list) == :ok
    assert Agent.get(:test_behavior, fn(list) -> list end) == @valid_action_list
    Agent.stop(:test_behavior)
  end

  test "#create returns error if no actions are provided" do
    assert Fakex.Behavior.create(:test_behavior, []) == {:error, :no_action}
  end

  test "#create returns error on the first invalid action" do
    assert Fakex.Behavior.create(:test_behavior, @invalid_action_list) == {:error, {:invalid_action, :invalid}}
  end

  test "#create returns error when name already exists" do
    Fakex.Behavior.create(:test_behavior, @valid_action_list)
    assert Fakex.Behavior.create(:test_behavior, @valid_action_list) == {:error, :already_exists}
  end

  test "#create returns error when name is not an atom" do
    assert Fakex.Behavior.create("test_behavior", @invalid_action_list) == {:error, :invalid_name}
  end

  test "#next_response returns the next response if there is one available" do
    Fakex.Behavior.create(:test_behavior, @valid_action_list)
    assert Fakex.Behavior.next_response(:test_behavior) == {:ok, :status_200}
    assert Fakex.Behavior.next_response(:test_behavior) == {:ok, :status_400}
    assert Fakex.Behavior.next_response(:test_behavior) == {:ok, :timeout}
  end

  test "#next_response returns behavior_empty if there is no more actions on behavior list" do
    Fakex.Behavior.create(:test_behavior, @valid_action_list)
    Fakex.Behavior.next_response(:test_behavior)
    Fakex.Behavior.next_response(:test_behavior)
    Fakex.Behavior.next_response(:test_behavior)
    assert Fakex.Behavior.next_response(:test_behavior) == {:ok, :no_more_actions}
  end
end
