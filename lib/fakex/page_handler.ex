defmodule Fakex.PageHandler do
  def init(_type, req, opts) do
    headers = [{"content-type", "text/plain"}]
    body = "Hello world from tsuru"

    IO.inspect opts
    {:ok, resp} = :cowboy_req.reply(200, headers, body, req)
    {:ok, resp, opts}
  end

  def handle(req, state) do
    {:ok, req, state}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end
end
