defmodule FakeServer.ResponseFactory do
  @moduledoc """
  Create reusable and customizable answers for your servers.

  With response factories it is possible to create a default format of a given response and identify it with a name so that it can be shared across several test cases.

  They are inspired by the [ExMachina's factories](https://github.com/thoughtbot/ex_machina), and were created to suit the use case where it is necessary to modify both the body or headers of a given response while testing different scenarios.

  ## What is a factory?
  A factory is just a function with no arguments inside a module that `use FakeServer.ResponseFactory`.

  The function name must end in `_response` and it must return a `FakeServer.Response` structure. The factory name is everything before `_response`.

  ```elixir
  # test/support/my_response_factory.ex
  defmodule MyResponseFactory do
    use FakeServer.ResponseFactory

    def person_response do
      ok(%{
        name: Faker.Name.name,
        email: Faker.Internet.free_email,
        company: %{name: Faker.Company.name, county: Faker.Address.country}
      }, %{"Content-Type" => "application/json"})
    end
  end
  ```

  ## Using a factory
  To use a factory, just call `ResponseFactory.build(:factory_name)`. This macro accepts two optinal arguments:

    - `body_opts`: This is a list with keys whose values should be overwritten in the body of factory's response. If any of the keys is set to `nil`, it will be deleted from the original body. If a key that does not exist on the original body is set here, **it will be ignored**.

    - `header_opts`: This is a map with the headers whose values should be overwritten. If any of the headers is set to `nil`, it will be deleted from the original header list. If a key that does not exist on the original header list is set here, **it will be included on the headers list**.


  You can also create a list of responses with `MyResponseFactory.build_list(list_size, :factory_name)`.

  ## Example

  ```elixir
  # test/my_app/some_test.exs
  defmodule MyApp.SomeTest do
    use ExUnit.Case, async: false
    import FakeServer

    test_with_server "basic factory usage" do
      customized_response = %{body: person} = MyResponseFactory.build(:person)

      route "/person", do: customized_response

      response = HTTPoison.get! FakeServer.address <> "/person"
      body = Poison.decode!(response.body)

      assert response.status_code == 200
      assert person[:name] == body["name"]
      assert person[:email] == body["email"]
      assert person[:company][:name] == body["company"]["name"]
      assert person[:company][:country] == body["company"]["country"]
    end

    test_with_server "setting custom attributes" do
      route "/person", do: MyResponseFactory.build(:person, name: "John", email: "john@myawesomemail.com")

      response = HTTPoison.get! FakeServer.address <> "/person"
      body = Poison.decode!(response.body)

      assert response.status_code == 200
      assert body["name"] == "John"
      assert body["email"] == "john@myawesomemail.com"
    end

    test_with_server "deleting an attribute" do
      route "/person", do: MyResponseFactory.build(:person, name: nil)

      response = HTTPoison.get! FakeServer.address <> "/person"
      body = Poison.decode!(response.body)

      assert response.status_code == 200
      assert body["name"] == nil
    end

    test_with_server "overriding a header" do
      route "/person", do: MyResponseFactory.build(:person, %{"Content-Type" => "application/x-www-form-urlencoded"})

      response = HTTPoison.get! FakeServer.address <> "/person"

      assert response.status_code == 200
      assert Enum.any?(response.headers, fn(header) -> header == {"Content-Type", "application/x-www-form-urlencoded"} end)
    end

    test_with_server "deleting a header" do
      route "/person", do: MyResponseFactory.build(:person, %{"Content-Type" => nil})

      response = HTTPoison.get! FakeServer.address <> "/person"

      assert response.status_code == 200
      refute Enum.any?(response.headers, fn(header) -> header == {"Content-Type", _} end)
    end

    test_with_server "create a list of responses" do
      person_list = MyResponseFactory.build_list(3, :person)

      route "/person", do: person_list

      Enum.each(person_list, fn(person) ->
        response = HTTPoison.get! FakeServer.address <> "/person"
        body = Poison.decode!(response.body)

        assert response.status_code == 200
        assert person.body[:name] == body["name"]
        assert person.body[:email] == body["email"]
        assert person.body[:company][:name] == body["company"]["name"]
        assert person.body[:company][:country] == body["company"]["country"]
      end)
    end
  end
  ```
  """

  defmacro __using__(_) do
    quote do
      import FakeServer.Response

      def build(name, header_opts) when is_map(header_opts) do
        response = get_response(name)
        headers = override_headers(response.headers, header_opts)
        new(response.code, response.body, headers)
      end
      def build(name, body_opts \\ [], header_opts \\ %{}) when is_list(body_opts) do
        response = get_response(name)
        body = override_body_keys(response.body, body_opts)
        headers = override_headers(response.headers, header_opts)
        new(response.code, body, headers)
      end

      def build_list(list_size, name) when is_integer(list_size) do
        Enum.map(1..list_size, fn(_) -> __MODULE__.build(name) end)
      end

      def build_list(names_list) do
        Enum.map(names_list, fn(name) -> __MODULE__.build(name) end)
      end

      defp get_response(name) do
        function_name = "#{to_string(name)}_response" |> String.to_atom
        apply(__MODULE__, function_name, [])
      end

      defp override_body_keys(original_body, keys) do
        keys
        |> Enum.reduce(original_body, fn({key, value}, body) ->
          override_body_key(body, key, value)
        end)
      end

      defp override_body_key(body, key, value) when is_nil(value), do: Map.delete(body, key)
      defp override_body_key(body, key, value) do
        if Map.has_key?(body, key), do: Map.put(body, key, value),
        else: body
      end

      defp override_headers(original_headers, new_headers) do
        new_headers
        |> Enum.reduce(original_headers, fn({header, header_value}, result_headers) ->
          if is_nil(header_value) do
            Map.delete(result_headers, header)
          else
            Map.put(result_headers, header, header_value)
          end
        end)
      end
    end
  end
end
