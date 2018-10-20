defmodule FakeServer.Handlers.FunctionHandler do
  alias FakeServer.Route
  alias FakeServer.Response
  alias FakeServer.Request
  alias FakeServer.Server.Access

  require Logger

  def init(req, state) do
    with %Route{} = route         <- Keyword.get(state, :route, nil),
         {:ok, access}            <- extract_access(state),
         %Request{} = request     <- Request.from_cowboy_req(req),
         :ok                      <- Access.compute_access(access, :cowboy_req.path(req)),
         %Response{} = response   <- execute_response(request, route)
    do
      req = :cowboy_req.reply(response.code, response.headers, response.body, req)
      {:ok, req, state}
    else
      error ->
        Logger.error("An error occurred while executing the request: #{inspect error}")
        {:ok, req, state}
    end
  end

  def terminate(_, _, _), do: :ok

  defp execute_response(request, route) do
    case route.response.(request) do
      %Response{} = response -> response
      _ -> Response.default!()
    end
  end

  defp extract_access(state) do
    case Keyword.get(state, :access, nil) do
      nil -> {:error, :no_access}
      access -> {:ok, access}
    end
  end
end

