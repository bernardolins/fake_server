defmodule Fakex.Server do
  def run name, port do
    routes = [ {:_, Fakex.PageHandler,[behavior: name]} ]
    dispatch = :cowboy_router.compile([{:_, routes}])
    opts = [port: port] 
    env = [dispatch: dispatch]

    {:ok, _pid} = :cowboy.start_http(name, 100, opts, [env: env])
  end
end
