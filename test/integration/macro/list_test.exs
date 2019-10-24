defmodule FakeServer.Integration.ListTest do
  use ExUnit.Case, async: false

  import FakeServer
  alias FakeServer.Response

  describe "when using lists as response" do
    test_with_server "returns the first element of the list and removes it" do
      route("/test", [Response.ok!(), Response.no_content!()])
      response = HTTPoison.get!("#{FakeServer.address()}/test")
      assert response.status_code == 200
      response = HTTPoison.get!("#{FakeServer.address()}/test")
      assert response.status_code == 204
    end

    test_with_server "returns the default_response when the list is empty" do
      route("/test", [])
      response = HTTPoison.get!("#{FakeServer.address()}/test")
      assert response.status_code == 200
      assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
    end

    test_with_server "raise FakeServer.Error if some element of the list is not a FakeServer.Response object" do
      assert_raise FakeServer.Error, fn ->
        route("/test", [Response.no_content!(), 22, Response.bad_request!()])
      end
    end

    test_with_server "computes hits for the corresponding route" do
      route("/test", [Response.bad_request!(), Response.no_content!()])
      assert hits() == 0
      assert hits("/test") == 0
      HTTPoison.get!("#{FakeServer.address()}/test")
      assert hits() == 1
      assert hits("/test") == 1
      HTTPoison.get!("#{FakeServer.address()}/test")
      assert hits() == 2
      assert hits("/test") == 2
    end

    test_with_server "computes hits even if the list is empty" do
      route("/test", [])
      assert hits() == 0
      assert hits("/test") == 0
      HTTPoison.get!("#{FakeServer.address()}/test")
      assert hits() == 1
      assert hits("/test") == 1
    end

    test_with_server "returns the corresponding response if some element of the list is a {:ok, FakeServer.Response} tuple" do
      route("/test", [Response.bad_request(), Response.no_content()])
      response = HTTPoison.get!("#{FakeServer.address()}/test")
      assert response.status_code == 400
      response = HTTPoison.get!("#{FakeServer.address()}/test")
      assert response.status_code == 204
    end
  end
end
