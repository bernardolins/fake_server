defmodule FakeServer.Router do
  @moduledoc false

  alias FakeServer.Route

  def create(route_list, access_control) do
    cowboy_routes =
      for %Route{} = route <- route_list, Route.valid?(route) do
        {Route.path(route), Route.handler(route), [route: route, access: access_control]}
      end
    {:ok, :cowboy_router.compile([{:_, cowboy_routes}])}
  end

  def reset() do
    {:ok, :cowboy_router.compile([{:_, []}])}
  end
end

