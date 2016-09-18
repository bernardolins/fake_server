defmodule FailWhale.HandlerTest do
  use ExUnit.Case
  doctest FailWhale

  import Mock

  @conn {:http_req}
  @valid_opts [behavior: :behavior]
  @invalid_opts [no_behavior: :behavior]
  @inexistent_status_opts [behavior: :invalid_behavior]

  setup_all do
    FailWhale.Status.create(:status_200, %{response_code: 200, response_body: "test"})
    :ok
  end

  test "#init returns connection and options" do
    FailWhale.Behavior.create(:behavior, [:status_200])
    assert FailWhale.Handler.init(:http, @conn, @invalid_opts) == {:ok, @conn, @invalid_opts}
    FailWhale.Behavior.destroy(:behavior)
  end

  test "#handle returns the formated response if no error occurred in reply" do
    FailWhale.Behavior.create(:behavior, [:status_200])
    with_mock :cowboy_req, [reply: fn(_,_,_,_) -> {:ok, :replied}  end] do
      assert FailWhale.Handler.handle(@conn, @valid_opts) == {:ok, @conn, @valid_opts}
    end
    FailWhale.Behavior.destroy(:behavior)
  end
  
  test "#handle returns shutdown command if something went wrong during reply" do
    FailWhale.Behavior.create(:behavior, [:status_200])
    with_mock :cowboy_req, [reply: fn(_,_,_,_) -> {:error, :some_error}  end] do
      assert FailWhale.Handler.handle(@conn, @valid_opts) == {:shutdown, {:http_req}, :some_error}
    end
    FailWhale.Behavior.destroy(:behavior)
  end

  test "#handle returns invalid status list error if behavior does not exist" do
    FailWhale.Behavior.create(:behavior, [:status_200])
    assert FailWhale.Handler.handle(@conn, @invalid_opts) == {:shutdown, {:http_req}, :invalid_status_list}
    FailWhale.Behavior.destroy(:behavior)
  end

  test "#handle does not return error when there are no status remaining" do
    FailWhale.Behavior.create(:behavior, [:status_200])
    with_mock :cowboy_req, [reply: fn(_,_,_,_) -> {:ok, :replied}  end] do
      FailWhale.Handler.handle(@conn, @valid_opts)
      assert FailWhale.Handler.handle(@conn, @valid_opts) == {:ok, @conn, @valid_opts}
    end
    FailWhale.Behavior.destroy(:behavior)
  end

  test "#handle does not return error when next_response returns error" do
    FailWhale.Behavior.create(:behavior, [:status_200])
    with_mocks([{:cowboy_req, [], [reply: fn(_,_,_,_) -> {:ok, :replied} end]},
                {FailWhale.Behavior, [], [next_response: fn(_name) -> {:error, :some_error} end]} ]) do 
      assert FailWhale.Handler.handle(@conn, @valid_opts) == {:ok, @conn, @valid_opts}
    end
    FailWhale.Behavior.destroy(:behavior)
  end

end

