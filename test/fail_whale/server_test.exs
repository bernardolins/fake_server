defmodule FailWhale.ServerTest do
  use ExUnit.Case
  doctest FailWhale

  setup do
    FailWhale.Status.create(:status_200, %{response_code: 200, response_body: ~s<"username": "mr_user", "age": 25>})
    FailWhale.Status.create(:status_400, %{response_code: 400, response_body: ~s<"error": "bad_request">})
    :ok
  end

  test "#run return ok and server address when start a new server went well" do
    server = FailWhale.Server.run(:external, :status_200)
    assert elem(server, 0) == :ok
    assert String.contains?(elem(server, 1), "127.0.0.1:")
    FailWhale.Server.stop(:external)
  end

  test "#run does not return error if argument is not a list and just one status is passed as argument" do
    server = FailWhale.Server.run(:external, :status_200)
    refute elem(server, 1) == :error
    FailWhale.Server.stop(:external)
  end

  test "#run return error when server already exists" do
    FailWhale.Server.run(:external, [:status_200])
    assert FailWhale.Server.run(:external, [:status_200]) == {:error, :already_exists}
    FailWhale.Server.stop(:external)
  end
  
  test "#run return error when no status is passed to server" do
    assert FailWhale.Server.run(:external, []) == {:error, :no_status}
    FailWhale.Server.stop(:external)
  end
  
  test "#run return error when one or more invalid status are passed as argument" do
    assert FailWhale.Server.run(:external, [:status_200, :some_status]) == {:error, {:invalid_status, :some_status}}
    FailWhale.Server.stop(:external)
  end
  
  test "#run return error when one or more status name are not atoms" do
    assert FailWhale.Server.run(:external, ["some_status"]) == {:error, {:invalid_status_name, "some_status"}}
    FailWhale.Server.stop(:external)
  end

  test "#stop stops a server if the server name is valid" do
    FailWhale.Server.run(:external, [:status_200])
    assert FailWhale.Server.stop(:external) == :ok
  end

  test "#stop returns error if the server passed as argument does not exists" do
    assert FailWhale.Server.stop(:external) == {:error, :not_found}
  end
end
