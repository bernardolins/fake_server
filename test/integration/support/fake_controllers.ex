defmodule FakeServer.Integration.FakeControllers do
  use FakeController

  def single_response_controller(_conn) do
    FakeServer.HTTP.Response.ok(~s<{"pet_name": "Rufus", "kind": "dog"}>)
  end

  def query_string_controller(req) do
    if req.query["token"] == "1234" do
      FakeServer.HTTP.Response.ok
    else
      FakeServer.HTTP.Response.unauthorized
    end
  end
end
