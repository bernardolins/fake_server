defmodule FakeServer.HandlerTest do
  use ExUnit.Case
  doctest FakeServer

  import Mock

  @conn {:http_req}
  @valid_opts [behavior: :behavior]
  @invalid_opts [no_behavior: :behavior]
  @inexistent_status_opts [behavior: :invalid_behavior]

  setup_all do
    FakeServer.Status.create(:status_200, %{response_code: 200, response_body: "test", response_headers:  %{ "Content-Length" => 5 }})
    :ok
  end

  test "#init returns connection and options" do
    FakeServer.Behavior.create(:behavior, [:status_200])
    assert FakeServer.Handler.init(:http, @conn, @invalid_opts) == {:ok, @conn, @invalid_opts}
    FakeServer.Behavior.destroy(:behavior)
  end

  test "#handle returns the formated response if no error occurred in reply" do
    FakeServer.Behavior.create(:behavior, [:status_200])
    with_mock :cowboy_req, [reply: fn(_,_,_,_) -> {:ok, :replied}  end] do
      assert FakeServer.Handler.handle(@conn, @valid_opts) == {:ok, @conn, @valid_opts}
    end
    FakeServer.Behavior.destroy(:behavior)
  end
  
  test "#handle returns shutdown command if something went wrong during reply" do
    FakeServer.Behavior.create(:behavior, [:status_200])
    with_mock :cowboy_req, [reply: fn(_,_,_,_) -> {:error, :some_error}  end] do
      assert FakeServer.Handler.handle(@conn, @valid_opts) == {:shutdown, {:http_req}, :some_error}
    end
    FakeServer.Behavior.destroy(:behavior)
  end

  test "#handle returns invalid status list error if behavior does not exist" do
    FakeServer.Behavior.create(:behavior, [:status_200])
    assert FakeServer.Handler.handle(@conn, @invalid_opts) == {:shutdown, {:http_req}, :invalid_status_list}
    FakeServer.Behavior.destroy(:behavior)
  end

  test "#handle does not return error when there are no status remaining" do
    FakeServer.Behavior.create(:behavior, [:status_200])
    with_mock :cowboy_req, [reply: fn(_,_,_,_) -> {:ok, :replied}  end] do
      FakeServer.Handler.handle(@conn, @valid_opts)
      assert FakeServer.Handler.handle(@conn, @valid_opts) == {:ok, @conn, @valid_opts}
    end
    FakeServer.Behavior.destroy(:behavior)
  end

  test "#handle does not return error when next_response returns error" do
    FakeServer.Behavior.create(:behavior, [:status_200])
    with_mocks([{:cowboy_req, [], [reply: fn(_,_,_,_) -> {:ok, :replied} end]},
                {FakeServer.Behavior, [], [next_response: fn(_name) -> {:error, :some_error} end]} ]) do 
      assert FakeServer.Handler.handle(@conn, @valid_opts) == {:ok, @conn, @valid_opts}
    end
    FakeServer.Behavior.destroy(:behavior)
  end

end

