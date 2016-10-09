defmodule FakeServer.StatusTest do
  use ExUnit.Case
  doctest FakeServer

  @valid_behavior %{response_body: "\"user\": \"test\"", response_code: 200, response_headers:  %{ "Content-Length" => 5 }}
  test "#destroy_all return error if agent not started" do
    assert FakeServer.Status.destroy_all == {:error, :no_status_to_destroy}
  end

  test "#destroy_all return :ok if agent is correctly destroy_alled" do
    FakeServer.Status.create(:test, @valid_behavior)
    assert FakeServer.Status.destroy_all == :ok
  end

  test "#create return error if name is not atom" do
    assert FakeServer.Status.create("some_invalid_name", @valid_behavior) == {:error, {:invalid_status_name, "some_invalid_name"}}
  end

  test "#create returns error if name not provided" do
    assert FakeServer.Status.create(@valid_behavior) == {:error, :name_not_provided}
  end

  test "#create returns error if response_body not provided" do
    assert FakeServer.Status.create(:test, %{response_code: 200}) == {:error, :response_body_not_provided}
  end

  test "#create returns error if response_code not provided" do
    assert FakeServer.Status.create(:test, %{response_body: ~s<"user": "test">}) == {:error, :response_code_not_provided}
  end

  test "#create put a new behavior on the list" do
    assert FakeServer.Status.create(:test, @valid_behavior) == :ok
    assert Agent.get(FakeServer.Status, fn(list) -> list end) == [test: @valid_behavior]
    FakeServer.Status.destroy_all
  end

  test "#get returns all behaviors" do
    FakeServer.Status.create(:test, @valid_behavior)
    assert FakeServer.Status.get == {:ok, [test: @valid_behavior]}
    FakeServer.Status.destroy_all
  end

  test "#get(name) returns behaviors by name" do
    FakeServer.Status.create(:test, @valid_behavior)
    assert FakeServer.Status.get(:test) == {:ok, @valid_behavior}
    FakeServer.Status.destroy_all
  end

  test "#get(name) returns behaviors by name and includes response headers" do
    FakeServer.Status.create(:test, @valid_behavior)
    {:ok, valid_behavior} = FakeServer.Status.get(:test)
    assert valid_behavior.response_headers == %{ "Content-Length"=> 5 }
    FakeServer.Status.destroy_all
  end

  test "#get(name) returns not found error if there are no behaviors with that name" do
    FakeServer.Status.create(:test, @valid_behavior)
    assert FakeServer.Status.get(:test2) == {:error, :not_found}
    FakeServer.Status.destroy_all
  end
end
