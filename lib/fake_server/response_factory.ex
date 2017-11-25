defmodule FakeServer.ResponseFactory do
  defmacro __using__(_) do
    quote do
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
