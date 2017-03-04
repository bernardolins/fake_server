defmodule FakeController do
  @moduledoc """
  FakeControllers provide a way to respond dynamically, based on each request arrived.
  All you have to do is to create a function with arity 1 and name ending in `_controller`. Just make sure this function returns a `FakeServer.HTTP.Response`.

  This function receives a `conn` object as an argument. This object contains information about the request, like the headers, query string parameters and many other.
  You can use this information to choose what to reply.

  Once you create a controller, you may create a route on a server that uses it. You can do this by calling `use_controller/1` function on `FakeServer.route/3`.

  ### Examples
  ```
  # test/support/fake_controllers.exs
  defmodule MyApp.FakeControllers do
    use FakeController

    def basic_controller(_conn) do
      FakeServer.HTTP.ok(body: ~s<{"pet_name": "Rufus", "kind": "dog"}>)
    end

    def query_string_example_controller(conn) do
      if :cowboy_req.qs_val("token", conn) |> elem(0) == "1234" do
        FakeServer.HTTP.Response.ok
      else
        FakeServer.HTTP.Response.unauthorized
      end
    end
  end

  # test/my_app/dummy_controller_test.exs
  defmodule MyApp.DummyControllerTest do
    Application.ensure_all_started(:fake_server)
    use ExUnit.Case, async: true

    import FakeServer
    import FakeControllers

    test_with_server "always reply 200" do
      route fake_server, "/dog", do: use_controller :example

      response = HTTPoison.get! fake_server_address <> "/dog"
      assert response.status_code == 200
      assert response.body == ~s<{"pet_name": "Rufus", "kind": "dog"}>
    end

    test_with_server "evaluates FakeController and reply accordingly" do
      route fake_server, "/", do: use_controller :example
      response = HTTPoison.get! fake_server_address <> "/"
      assert response.status_code == 401

      response = HTTPoison.get! fake_server_address <> "/?token=1234"
      assert response.status_code == 200
    end
  end
  ```
  """
  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      def use_controller(controller_name) do
        function_name = "#{to_string(controller_name)}_controller" |> String.to_atom
        {:controller, __MODULE__, function_name}
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def use_controller(controller_name) do
        raise "Invalid controller #{controller_name}"
      end
    end
  end
end
