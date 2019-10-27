defmodule ResponseListTest do
  use ExUnit.Case
  alias FakeServer.ResponseList
  alias FakeServer.Response

  describe "#add_response" do
    test "returns :ok if a valid response is added" do
      {:ok, list_id} = ResponseList.start_link()
      assert :ok = ResponseList.add_response(list_id, Response.ok!())
      ResponseList.stop(list_id)
    end

    test "returns {:error, reason} if an invalid response is added" do
      {:ok, list_id} = ResponseList.start_link()
      assert {:error, {1, "invalid response type"}} = ResponseList.add_response(list_id, 1)

      assert {:error, {600, "invalid status code"}} =
               ResponseList.add_response(list_id, %Response{status: 600})

      ResponseList.stop(list_id)
    end
  end

  describe "#get_next" do
    test "returns response by order if there is a response on the list" do
      {:ok, list_id} = ResponseList.start_link()
      ResponseList.add_response(list_id, Response.ok!())
      ResponseList.add_response(list_id, Response.forbidden!())
      assert Response.ok!() == ResponseList.get_next(list_id)
      assert Response.forbidden!() == ResponseList.get_next(list_id)
      ResponseList.stop(list_id)
    end

    test "returns the default response if the list is empty" do
      {:ok, list_id} = ResponseList.start_link()
      assert Response.default!() == ResponseList.get_next(list_id)
      ResponseList.stop(list_id)
    end
  end
end
