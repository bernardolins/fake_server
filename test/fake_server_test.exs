defmodule FakeServerTest do
#  use ExUnit.Case
#  doctest FakeServer
#
#  import Mock
#
#  setup do
#    FakeServer.Status.create(:status_200, %{response_code: 200, response_body: ~s<"username": "mr_user", "age": 25>})
#    FakeServer.Status.create(:status_400, %{response_code: 400, response_body: ~s<"error": "bad_request">})
#    :ok
#  end
#
#  test "#run return ok and server address when start a new server went well" do
#    server = FakeServer.run(:external, :status_200)
#    assert elem(server, 0) == :ok
#    assert String.contains?(elem(server, 1), "127.0.0.1:")
#    FakeServer.stop(:external)
#  end
#
#  test "#run does not return error if argument is not a list and just one status is passed as argument" do
#    server = FakeServer.run(:external, :status_200)
#    refute elem(server, 1) == :error
#    FakeServer.stop(:external)
#  end
#
#  test "#run does not return error when no status is passed to server" do
#    server = FakeServer.run(:external, [])
#    assert elem(server, 0) == :ok
#    assert String.contains?(elem(server, 1), "127.0.0.1:")
#    FakeServer.stop(:external)
#  end
#
#  test "#run raise error when server already exists" do
#    FakeServer.run(:external, [:status_200])
#    assert_raise FakeServer.ServerError, "The server 'external' already exists", fn ->
#      assert FakeServer.run(:external, [:status_200]) == {:error, :already_exists}
#    end
#    FakeServer.stop(:external)
#  end
#
#  test "#run raise error when server name is not an atom" do
#    assert_raise FakeServer.NameError, "Server name 'invalid_name' must be an atom", fn ->
#      FakeServer.run("invalid_name", [:status_200])
#    end
#    FakeServer.stop(:external)
#  end
#
#  test "#run raise error when one or more invalid status are passed as argument" do
#    assert_raise FakeServer.ServerError, "Invalid status: 'some_status'", fn ->
#      FakeServer.run(:external, [:status_200, :some_status])
#    end
#    FakeServer.stop(:external)
#  end
#
#  test "#run raise error when an unknown error happens on the server" do
#    with_mock FakeServer.Behavior, [create: fn(_, _) -> {:error, :any_error} end] do
#      assert_raise FakeServer.ServerError, "An error happened on the server", fn ->
#        FakeServer.run(:external, [])
#      end
#    end
#  end
#
#  test "#run raise error when cowboy server already exists" do
#    with_mock :cowboy, [start_http: fn(_, _, _, _) -> {:error, :already_exists} end] do
#      assert_raise FakeServer.ServerError, "The server 'external' already exists", fn ->
#        FakeServer.run(:external, [])
#      end
#    end
#  end
#
#  test "#run raise error when cowboy server returns an unknown error" do
#    with_mock :cowboy, [start_http: fn(_, _, _, _) -> {:error, :any_error} end] do
#      assert_raise FakeServer.ServerError, "An error happened on the server", fn ->
#        FakeServer.run(:external, [])
#      end
#    end
#  end
#  
#  test "#run return error when one or more status names are not atoms" do
#    assert_raise FakeServer.NameError, "Status name 'some_status' must be an atom", fn ->
#      FakeServer.run(:external, ["some_status"])
#    end
#    
#    FakeServer.stop(:external)
#  end
#
#  test "#run with default port creates a server on the given port" do
#    {:ok, address} = FakeServer.run(:external, :status_200, %{port: 5445})
#    assert address == "127.0.0.1:5445"
#    FakeServer.stop(:external)
#  end
#
#  test "#run returns error when coyboy application failed to start" do
#    with_mock Application, [ensure_all_started: fn(:cowboy) -> {:error, :any_error} end] do
#      assert_raise FakeServer.ServerError, "An error occurred while starting the server", fn ->
#        FakeServer.run(:external, ["some_status"])
#      end
#    end
#  end
#
#  test "#stop stops a server if the server name is valid" do
#    FakeServer.run(:external, [:status_200])
#    assert FakeServer.stop(:external) == :ok
#  end
#
#  test "#stop returns error if the server passed as argument does not exists" do
#    assert FakeServer.stop(:external) == {:error, :not_found}
#  end
#
#  test "#modify_behavior updates server status list if the server and status_list are valid" do
#    FakeServer.run(:external, [])
#    assert FakeServer.modify_behavior(:external, [:status_200]) == :ok
#    FakeServer.stop(:external)
#  end
#
#  test "#modify_behavior does not return error if argument is not a list and just one status is passed as argument" do
#    FakeServer.run(:external, [])
#    assert FakeServer.modify_behavior(:external, :status_200) == :ok
#    FakeServer.stop(:external)
#  end
#
#  test "#modify_behavior returns server not found if ther server name does not exist" do
#    assert FakeServer.modify_behavior(:external_invalid, :status_200) == {:error, :server_not_found}
#  end
#
#  test "#modify_behavior returns invalid_status_name if one or more status name are invalid" do
#    FakeServer.run(:external, [])
#    assert_raise FakeServer.NameError, "Status name 'some_status' must be an atom", fn ->
#      FakeServer.modify_behavior(:external, "some_status")
#    end
#    FakeServer.stop(:external)
#  end
#
#  test "#modify_behavior returns invalid_status if one or more status on the status list does not exist" do
#    FakeServer.run(:external, [])
#    assert FakeServer.modify_behavior(:external, :status_invalid) == {:error, {:invalid_status, :status_invalid}}
#    FakeServer.stop(:external)
#  end
end
