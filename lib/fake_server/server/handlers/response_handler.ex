defmodule FakeServer.Handlers.ResponseHandler do
  alias FakeServer.Route
  alias FakeServer.Response
  require Logger

  def init(req, state) do
    with %Route{} = route <- Keyword.get(state, :route, nil),
         %Response{} = response <- execute_response(req, route),
         {:ok, req} <- :cowboy_req.reply(response.code, response.headers, response.body, req)
    do
      {:ok, req, state}
    else
      error ->
        Logger.warn("An error occurred while executing the request: #{inspect error}")
        {:ok, req, state}
    end
  end

  def terminate(_, _, _), do: :ok

  defp execute_response(req, route) do
    case route.response do
      %Response{} = response -> response
      _ -> Response.default()
    end
  end
end

