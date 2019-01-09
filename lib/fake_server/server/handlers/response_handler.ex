defmodule FakeServer.Handlers.ResponseHandler do
  @moduledoc false

  alias FakeServer.Route
  alias FakeServer.Response
  alias FakeServer.Server.Access

  require Logger

  def init(req, state) do
    with %Route{} = route         <- Keyword.get(state, :route, nil),
         {:ok, access}            <- extract_access(state),
         :ok                      <- Access.compute_access(access, :cowboy_req.path(req)),
         %Response{} = response   <- execute_response(req, route)
    do
      req = :cowboy_req.reply(response.status, response.headers, response.body, req)
      {:ok, req, state}
    else
      error ->
        Logger.error("An error occurred while executing the request: #{inspect error}")
        {:ok, req, state}
    end
  end

  def terminate(_, _, _), do: :ok

  defp execute_response(req, route) do
    case route.response do
      %Response{} = response -> response
      {:ok, %Response{} = response} -> response
    end
  end

  defp extract_access(state) do
    case Keyword.get(state, :access, nil) do
      nil -> {:error, :no_access}
      access -> {:ok, access}
    end
  end
end

