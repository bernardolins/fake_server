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
      body: body(cowboy_req),
      cookies: cookies(cowboy_req),
      headers: headers(cowboy_req),
      method: method(cowboy_req),
      path: path(cowboy_req),
      query_string: query_string(cowboy_req),
    }
  end

  defp body(cowboy_req) do
    if :cowboy_req.has_body(cowboy_req) do
      read_body(cowboy_req)
      |> try_decode_body(cowboy_req)
    end
  end

  defp read_body(req, body \\ "") do
    case :cowboy_req.read_body(req) do
      {:ok, data, _} -> body <> data
      {:more, data, req2} -> read_body(req2, body <> data)
    end
  end

  defp cookies(cowboy_req), do: Enum.into(:cowboy_req.parse_cookies(cowboy_req), %{})
  defp headers(cowboy_req), do: :cowboy_req.headers(cowboy_req)
  defp method(cowboy_req), do: :cowboy_req.method(cowboy_req)
  defp path(cowboy_req), do: :cowboy_req.path(cowboy_req)
  defp query_string(cowboy_req), do: Enum.into(:cowboy_req.parse_qs(cowboy_req), %{})

  defp try_decode_body(body, cowboy_req) do
    if content_type_json?(cowboy_req) do
      decode(body)
    else
      body
    end
  end

  defp content_type_json?(cowboy_req) do
    case headers(cowboy_req) do
      %{"content-type" => content_type} -> content_type =~ "application/json"
      _ -> false
    end
  end

  defp decode(body) do
    case Poison.decode(body) do
      {:ok, map} -> map
      _ -> body
    end
  end
end
