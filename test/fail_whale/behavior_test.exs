  defmodule FailWhale.BehaviorTest do
    use ExUnit.Case
    doctest FailWhale

    @valid_status_list [:status_200, :status_400, :timeout]
    @invalid_status_list [:status_200, :status_400, :invalid]

    setup_all do
      FailWhale.Status.create(:status_200, %{response_code: 200, response_body: ~s<"user": "Test", "age": 25>})
      FailWhale.Status.create(:status_400, %{response_code: 400, response_body: ~s<"error": "bad request">})
      FailWhale.Status.create(:timeout, %{response_code: 408, response_body: ~s<"error": "request timeout">})
    :ok
  end

  test "#create creates a new behavior with given status and current number of calls" do
    assert FailWhale.Behavior.create(:test_behavior, @valid_status_list) == {:ok, :test_behavior}
    assert Agent.get(:test_behavior, fn(list) -> list end) == @valid_status_list
    Agent.stop(:test_behavior)
  end

  test "#create returns error if no status are provided" do
    assert FailWhale.Behavior.create(:test_behavior, []) == {:error, :no_status}
  end

  test "#create returns error on the first invalid status" do
    assert FailWhale.Behavior.create(:test_behavior, @invalid_status_list) == {:error, {:invalid_status, :invalid}} 
  end

  test "#create returns error when name already exists" do
    FailWhale.Behavior.create(:test_behavior, @valid_status_list)
    assert FailWhale.Behavior.create(:test_behavior, @valid_status_list) == {:error, :already_exists}
  end

  test "#create returns error when name is not an atom" do
    assert FailWhale.Behavior.create("test_behavior", @invalid_status_list) == {:error, :invalid_name}
  end

  test "#next_response returns the next response if there is one available" do
    FailWhale.Behavior.create(:test_behavior, @valid_status_list)
    assert FailWhale.Behavior.next_response(:test_behavior) == {:ok, :status_200}
    assert FailWhale.Behavior.next_response(:test_behavior) == {:ok, :status_400}
    assert FailWhale.Behavior.next_response(:test_behavior) == {:ok, :timeout}
  end

  test "#next_response returns behavior_empty if there is no more status on behavior list" do
    FailWhale.Behavior.create(:test_behavior, @valid_status_list)
    FailWhale.Behavior.next_response(:test_behavior)
    FailWhale.Behavior.next_response(:test_behavior)
    FailWhale.Behavior.next_response(:test_behavior)
    assert FailWhale.Behavior.next_response(:test_behavior) == {:ok, :no_more_status}
  end
end
