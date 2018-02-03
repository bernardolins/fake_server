defmodule FakeServer.Request do
  @moduledoc """
  Stores some information about a request when it arrives the server.

  ## Structure Fields:

    - `method`: a string with the HTTP request method.
    - `body`: a string with the body of the request.
    - `headers`: a map with the request headers.
    - `path`: a string with the request path.
    - `cookies`: a map with the request cookies.
    - `query_string`: a string with the query_string.
    - `query`: a map with each one of the parameters from the query string.
  """
  defstruct [
    method: "",
    body: "",
    headers: %{},
    path: "",
    cookies: %{},
    query_string: "",
    query: %{}
  ]

  @doc false
  def from_cowboy_req(cowboy_req) do
    %__MODULE__{
      method: method(cowboy_req),
      body: body(cowboy_req),
      headers: headers(cowboy_req),
      path: path(cowboy_req),
      query_string: query_string(cowboy_req),
      query: query(cowboy_req)
    }
  end

  defp method(cowboy_req) do
    cowboy_req
    |> :cowboy_req.method
    |> elem(0)
  end

  defp body(cowboy_req) do
    cowboy_req
    |> :cowboy_req.body
    |> elem(1)
  end

  defp headers(cowboy_req) do
    cowboy_req
    |> :cowboy_req.headers
    |> elem(0)
    |> Enum.into(%{})
  end

  defp path(cowboy_req) do
    cowboy_req
    |> :cowboy_req.path
    |> elem(0)
  end

  defp query_string(cowboy_req) do
    cowboy_req
    |> :cowboy_req.qs
    |> elem(0)
  end

  defp query(cowboy_req) do
    qs = query_string(cowboy_req)

    qs
    |> String.split("&")
    |> create_query_map
  end

  defp create_query_map([""]), do: %{}
  defp create_query_map(query_list) do
    query_list
    |> Enum.map(fn(query) -> List.to_tuple(String.split(query, "=")) end)
    |> Enum.into(%{})
  end
end
