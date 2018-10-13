defmodule FakeServer.Route do
  defstruct [
    handler: Handler,
    path: "/",
    response: FakeServer.HTTP.Response.default(),
  ]

  def create(opts \\ []) do
    with route <- struct(__MODULE__, opts),
         {:ok, route} <- ensure_path(route),
         {:ok, route} <- ensure_response(route),
         {:ok, route} <- ensure_handler(route)
    do
      {:ok, route}
    end
  end

  def create!(opts \\ []) do
    case create(opts) do
      {:ok, route} -> route
      {:error, reason} -> raise FakeServer.Error, reason
    end
  end

  def path(%__MODULE__{path: path}), do: path
  def handler(%__MODULE__{handler: handler}), do: handler

  def valid?(%__MODULE__{} = route) do
    with {:ok, _} <- ensure_path(route),
         {:ok, _} <- ensure_response(route)
    do
      true
    else
      _ -> false
    end
  end

  defp ensure_path(%__MODULE__{path: path} = route) do
    cond do
      not is_bitstring(path) -> {:error, {path, "path must be a string"}}
      not String.starts_with?(path, "/") -> {:error, {path, "path must start with '/'"}}
      true -> {:ok, route}
    end
  end

  defp ensure_response(%__MODULE__{response: response} = route) do
    case valid_response?(response) do
      :ok -> {:ok, route}
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_handler(%__MODULE__{response: response} = route) do
    cond do
      is_function(response)                               -> {:ok, %__MODULE__{route | handler: Handler}}
      is_list(response)                                   -> {:ok, %__MODULE__{route | handler: Handler}}
      FakeServer.HTTP.Response.validate(response) == :ok  -> {:ok, %__MODULE__{route | handler: Handler}}
      true -> {:error, {response, "response must be a function, a Response struct, or a list of Response structs"}}
    end
  end

  defp valid_response?(response) when is_function(response), do: :ok

  defp valid_response?([]), do: :ok
  defp valid_response?([response|responses]) do
    case valid_response?(response) do
      :ok -> valid_response?(responses)
      {:error, reason} -> {:error, reason}
    end
  end

  defp valid_response?(%FakeServer.HTTP.Response{} = response), do: FakeServer.HTTP.Response.validate(response)
  defp valid_response?(response), do: {:error, {response, "response must be a function, a Response struct, or a list of Response structs"}}
end
