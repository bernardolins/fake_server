defmodule FakeServer.BehaviorTest do
  use ExUnit.Case
  doctest FakeServer

  @valid_status_list [:status_200, :status_400, :timeout]
  @invalid_status_list [:status_200, :status_400, :invalid]

  setup_all do
    FakeServer.Status.create(:status_200, %{response_code: 200, response_body: ~s<"user": "Test", "age": 25>})
    FakeServer.Status.create(:status_400, %{response_code: 400, response_body: ~s<"error": "bad request">})
    FakeServer.Status.create(:timeout, %{response_code: 408, response_body: ~s<"error": "request timeout">})
    :ok
  end

  test "#create creates a new behavior with given status and current number of calls" do
    assert FakeServer.Behavior.create(:test_behavior, @valid_status_list) == {:ok, :test_behavior}
    assert Agent.get(:test_behavior, fn(list) -> list end) == @valid_status_list
    Agent.stop(:test_behavior)
  end

  test "#create does not returns error if no status are provided" do
    assert FakeServer.Behavior.create(:test_behavior, []) == {:ok, :test_behavior}
  end

  test "#create returns error on the first invalid status" do
    assert FakeServer.Behavior.create(:test_behavior, @invalid_status_list) == {:error, {:invalid_status, :invalid}}
  end

  test "#create returns error when name already exists" do
    FakeServer.Behavior.create(:test_behavior, @valid_status_list)
    assert FakeServer.Behavior.create(:test_behavior, @valid_status_list) == {:error, :already_exists}
  end

  test "#create returns error when name is not an atom" do
    assert_raise FakeServer.NameError, "Name 'test_behavior' must be an atom", fn -> 
      FakeServer.Behavior.create("test_behavior", @invalid_status_list)
    end
  end

  test "#destroy destroys a behavior if the behavior exists" do
    FakeServer.Behavior.create(:test_behavior, @valid_status_list)
    assert FakeServer.Behavior.destroy(:test_behavior) == :ok
  end

  test "#destroy returns error if behavior does not exists" do
    assert FakeServer.Behavior.destroy(:test_behavior) == {:error, :no_behavior_to_destroy}
  end

  test "#next_response returns the next response if there is one available" do
    FakeServer.Behavior.create(:test_behavior, @valid_status_list)
    assert FakeServer.Behavior.next_response(:test_behavior) == {:ok, :status_200}
    assert FakeServer.Behavior.next_response(:test_behavior) == {:ok, :status_400}
    assert FakeServer.Behavior.next_response(:test_behavior) == {:ok, :timeout}
  end

  test "#next_response returns no_more_status if there is no more status on behavior list" do
    FakeServer.Behavior.create(:test_behavior, @valid_status_list)
    FakeServer.Behavior.next_response(:test_behavior)
    FakeServer.Behavior.next_response(:test_behavior)
    FakeServer.Behavior.next_response(:test_behavior)
    assert FakeServer.Behavior.next_response(:test_behavior) == {:ok, :no_more_status}
  end

  test "#modify returns ok if behavior exists" do
    FakeServer.Behavior.create(:test_behavior, [])
    assert FakeServer.Behavior.modify(:test_behavior, [:status_200]) == :ok
  end

  test "#modify returns server not found if server name does not exist" do
    assert FakeServer.Behavior.modify(:test_behavior, [:status_200]) == {:error, :server_not_found}
  end

  test "#modify returns error if status list is invalid" do
    FakeServer.Behavior.create(:test_behavior, [])
    assert FakeServer.Behavior.modify(:test_behavior, [:status_invalid]) == {:error, {:invalid_status, :status_invalid}}
  end

  test "#modify does not returns error if status list is empty" do
    FakeServer.Behavior.create(:test_behavior, [])
    assert FakeServer.Behavior.modify(:test_behavior, []) == :ok
  end
end
