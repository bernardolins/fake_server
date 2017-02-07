defmodule FakeServer.HTTP.Handler do
  def init(_type, conn, opts), do: {:ok, conn, opts}  

  def handle(conn, opts) do 
    response = FakeServer.Agents.ResponseAgent.take_next 
    :cowboy_req.reply(response.code, response.headers, response.body, conn)

    {:ok, conn, opts}
  end

  def terminate(_reason, _req, _state), do: :ok
end
