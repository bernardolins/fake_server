defmodule Fakex.PipelineTest do
  use ExUnit.Case
  doctest Fakex

  @valid_behavior_list [:status_200, :status_400, :timeout]
  @invalid_behavior_list [:status_200, :status_400, :invalid]

  setup_all do
    Fakex.Behavior.begin
    Fakex.Behavior.create(:status_200, %{response_code: 200, response_body: ~s<"user": "Test", "age": 25>})
    Fakex.Behavior.create(:status_400, %{response_code: 400, response_body: ~s<"error": "bad request">})
    Fakex.Behavior.create(:timeout, %{response_code: 408, response_body: ~s<"error": "request timeout">})
    :ok
  end

  test "#create creates a new pipeline with given behaviors and current number of calls" do
    assert Fakex.Pipeline.create(:test_pipeline, @valid_behavior_list) == :ok
    assert Agent.get(:test_pipeline, fn(list) -> list end) == @valid_behavior_list
    Agent.stop(:test_pipeline)
  end

  test "#create returns error if no behaviors are provided" do
    assert Fakex.Pipeline.create(:test_pipeline, []) == {:error, :no_behavior}
  end

  test "#create returns error on the first invalid behavior" do
    assert Fakex.Pipeline.create(:test_pipeline, @invalid_behavior_list) == {:error, {:invalid_behavior, :invalid}}
  end

  test "#create returns error when name already exists" do
    Fakex.Pipeline.create(:test_pipeline, @valid_behavior_list)
    assert Fakex.Pipeline.create(:test_pipeline, @valid_behavior_list) == {:error, :already_exists}
  end

  test "#create returns error when name is not an atom" do
    assert Fakex.Pipeline.create("test_pipeline", @invalid_behavior_list) == {:error, :invalid_name}
  end

  test "#next_response returns the next response if there is one available" do
    Fakex.Pipeline.create(:test_pipeline, @valid_behavior_list)
    assert Fakex.Pipeline.next_response(:test_pipeline) == {:ok, :status_200}
    assert Fakex.Pipeline.next_response(:test_pipeline) == {:ok, :status_400}
    assert Fakex.Pipeline.next_response(:test_pipeline) == {:ok, :timeout}
  end

  test "#next_response returns pipeline_empty if there is no more behaviors on pipeline list" do
    Fakex.Pipeline.create(:test_pipeline, @valid_behavior_list)
    Fakex.Pipeline.next_response(:test_pipeline)
    Fakex.Pipeline.next_response(:test_pipeline)
    Fakex.Pipeline.next_response(:test_pipeline)
    assert Fakex.Pipeline.next_response(:test_pipeline) == {:ok, :pipeline_empty}
  end
end
