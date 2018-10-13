defmodule FakeServer.Router do
  alias FakeServer.Route

  def create(route_list) do
    cowboy_routes =
      for %Route{} = route <- route_list, Route.valid?(route) do
        {Route.path(route), Route.handler(route), [route: route]}
      end
    {:ok, :cowboy_router.compile([{:_, cowboy_routes}])}
  end

  def reset() do
    {:ok, :cowboy_router.compile([{:_, []}])}
  end
end

