defmodule FakeServer.Integration.ResponseTest do
  use ExUnit.Case, async: false

  import FakeServer
  alias FakeServer.Response

  describe "when using FakeServer.Response{} structs as response" do
    test_with_server "returns the given response" do
      route("/test", Response.no_content!())
      response = HTTPoison.get!("#{FakeServer.address()}/test")
      assert response.status_code == 204
      response = HTTPoison.get!("#{FakeServer.address()}/test")
      assert response.status_code == 204
    end

    test_with_server "raise FakeServer.Error if the response is not a FakeServer.Response object" do
      assert_raise FakeServer.Error, fn ->
        route("/test", 22)
      end
    end

    test_with_server "computes hits for the corresponding route" do
      route("/test", Response.no_content!())
      assert hits() == 0
      assert hits("/test") == 0
      HTTPoison.get!("#{FakeServer.address()}/test")
      assert hits() == 1
      assert hits("/test") == 1
    end

    test_with_server "returns the corresponding response if some element of the list is a {:ok, FakeServer.Response} tuple" do
      route("/test", Response.no_content())
      response = HTTPoison.get!("#{FakeServer.address()}/test")
      assert response.status_code == 204
      response = HTTPoison.get!("#{FakeServer.address()}/test")
      assert response.status_code == 204
    end
  end
end
