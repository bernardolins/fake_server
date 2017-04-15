defmodule FakeServer do

  alias FakeServer.HTTP.Server

  @fake_server_ip "127.0.0.1"

  @moduledoc """
  Provides macros that help create HTTP servers in tests
  """

  @doc """
  This macro works similarly to `ExUnit.Case.test/3`, with the difference that it starts an HTTP server.

  The address of this server is set in the `fake_server_address` variable. To allow multiple servers to run concurrently, each one of them receives a hash of identification. This hash is available in the `fake_server` variable and should only be used internally by FakeServer.

  If you need an HTTP server on your test, just use `test_with_server` instead of `ExUnit.Case.test/3`. Their arguments are similar: A description (the `test_description` argument) and the implementation of the test case itself (the `list` argument).

  You can also set some configuration parameters for the server before it starts through the keyword list `opts`.

  ## Usage:
  ```elixir
  test_with_server "without configured routes will always return 404" do
    response = HTTPoison.get! fake_server_address <> "/"
    assert response.status_code == 404
    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 404
    response = HTTPoison.get! fake_server_address <> "/test/1"
    assert response.status_code == 404
  end

  test_with_server "server port configuration", [port: 5001] do
    assert fake_server_address == "127.0.0.1:5001"
    response = HTTPoison.get! "127.0.0.1:5001" <> "/"
    assert response.status_code == 404
  end

  test_with_server "adding a route", do
    route fake_server, "/", do: FakeServer.HTTP.Response.bad_request
    response = HTTPoison.get! fake_server_address <> "/"
    assert response.status_code == 400
  end

  test_with_server "setting a default response", [default_response: Response.forbidden] do
    route fake_server, "/test", do: Response.bad_request

    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 400

    response = HTTPoison.get! fake_server_address <> "/test"
    assert response.status_code == 403
  end
  ```
  """
  defmacro test_with_server(test_description, opts \\ [], do: test_block) do
    quote do
      test unquote(test_description) do
        map_opts = Enum.into(unquote(opts), %{})
        {:ok, server_id, port} = Server.run(map_opts)

        var!(fake_server) = server_id
        var!(fake_server_address) = "#{unquote(@fake_server_ip)}:#{port}"

        unquote(test_block)

        Server.stop(server_id)
      end
    end
  end

  @doc """
  Adds a route to a server and the responses that will be given when a request reaches that route.

  Responses can be given in three formats:

  1. A single answer. In this case, this response will be given by the server on the first request. The following requests will be replied with the default_response.

  2. A list of answers. In this case, each request will be replied with the first element of the list, which is then removed. When the list is empty, the requests will receive default_respose in response.

  3. A FakeController. In this case, the responses will be given dynamically, according to request parameters. For more details see FakeController.
  """
  defmacro route(fake_server_id, path, do: response_block) do
    quote do
      case unquote(response_block) do
        [module: module, function: function] ->
          Server.add_controller(unquote(fake_server_id), unquote(path), [module: module, function: function])
        list when is_list(list) ->
          Server.add_route(unquote(fake_server_id), unquote(path), list)
        %FakeServer.HTTP.Response{} = response ->
          Server.add_route(unquote(fake_server_id), unquote(path), response)
      end
    end
  end
end
