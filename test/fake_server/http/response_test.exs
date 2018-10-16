defmodule ResponseTest do
  use ExUnit.Case
  alias FakeServer.HTTP.Response

  describe "#new" do
    test "accept the response status code as a mandatory parameter" do
      assert {:ok, %Response{code: 200}} = Response.new(200)
    end

    test "accept the response body as string" do
      assert {:ok, %Response{body: ~s<{"message": "This is a body"}>}} = Response.new(200, ~s<{"message": "This is a body"}>)
    end

    test "encode the body if it is a valid json map" do
      assert {:ok, %Response{body: ~s<{"message":"This is a body","code":1}>}} = Response.new(200, %{message: "This is a body", code: 1})
    end

    test "accept the response headers as a map" do
      assert {:ok, %Response{headers: %{"x-my-header" => "fake-server"}}} = Response.new(200, "", %{"x-my-header" => "fake-server"})
    end
  end

  describe "#validate" do
    test "returns {:error, reason} when status code is invalid" do
      assert {:error, {600, "invalid status code"}} == %Response{code: 600} |> Response.validate
      assert {:error, {"200", "invalid status code"}} == %Response{code: "200"} |> Response.validate
      assert {:error, {[], "invalid status code"}} == %Response{code: []} |> Response.validate
      assert {:error, {%{}, "invalid status code"}} == %Response{code: %{}} |> Response.validate
    end

    test "returns {:error, reason} when header list is not a map" do
      assert {:error, {1, "response headers must be a map"}} == %Response{code: 200, headers: 1} |> Response.validate
      assert {:error, {[], "response headers must be a map"}} == %Response{code: 200, headers: []} |> Response.validate
      assert {:error, {[{"a", "b"}], "response headers must be a map"}} == %Response{code: 200, headers:  [{"a", "b"}]} |> Response.validate
    end

    test "returns {:error, reason} when body is not a map or string" do
      assert {:error, {1, "body must be a map or a string"}} == %Response{code: 200, body: 1} |> Response.validate
      assert {:error, {[], "body must be a map or a string"}} == %Response{code: 200, body: []} |> Response.validate
      assert {:error, {{:a, 1}, "body must be a map or a string"}} == %Response{code: 200, body: {:a, 1}} |> Response.validate
    end

    test "returns :ok when response is valid" do
      assert :ok == %Response{code: 200} |> Response.validate
      assert :ok == %Response{code: 200, headers: %{}} |> Response.validate
      assert :ok == %Response{code: 200, body: ""} |> Response.validate
      assert :ok == %Response{code: 200, body: %{}, headers: %{}} |> Response.validate
    end
  end

  test "#default" do
    assert {:ok, %Response{code: 200, body: ~s<{"message": "This is a default response from FakeServer"}>, headers: %{}}} == Response.default
  end

  test "#default!" do
    assert %Response{code: 200, body: ~s<{"message": "This is a default response from FakeServer"}>, headers: %{}} == Response.default!
  end

  describe "2XX" do
    test "normal version returns {:ok, response} with the correspondent status code" do
      assert {:ok, %Response{code: 200, body: "", headers: %{}}} == Response.ok
      assert {:ok, %Response{code: 201, body: "", headers: %{}}} == Response.created
      assert {:ok, %Response{code: 202, body: "", headers: %{}}} == Response.accepted
      assert {:ok, %Response{code: 203, body: "", headers: %{}}} == Response.non_authoritative_information
      assert {:ok, %Response{code: 204, body: "", headers: %{}}} == Response.no_content
      assert {:ok, %Response{code: 205, body: "", headers: %{}}} == Response.reset_content
      assert {:ok, %Response{code: 206, body: "", headers: %{}}} == Response.partial_content
    end

    test "! version returns the response with correspondent status code" do
      assert %Response{code: 200, body: "", headers: %{}} == Response.ok!
      assert %Response{code: 201, body: "", headers: %{}} == Response.created!
      assert %Response{code: 202, body: "", headers: %{}} == Response.accepted!
      assert %Response{code: 203, body: "", headers: %{}} == Response.non_authoritative_information!
      assert %Response{code: 204, body: "", headers: %{}} == Response.no_content!
      assert %Response{code: 205, body: "", headers: %{}} == Response.reset_content!
      assert %Response{code: 206, body: "", headers: %{}} == Response.partial_content!
    end
  end

  describe "4XX" do
    test "all_4xx responds a list with all 4xx status code" do
      assert length(Response.all_4xx) == 24
      Enum.each(Response.all_4xx, fn(response) ->
        assert response.code >= 400 && response.code <= 431
      end)
    end

    test "normal version returns {:ok, response} with the correspondent status code" do
      assert {:ok, %Response{code: 400}} = Response.bad_request
      assert {:ok, %Response{code: 401}} = Response.unauthorized
      assert {:ok, %Response{code: 403}} = Response.forbidden
      assert {:ok, %Response{code: 404}} = Response.not_found
      assert {:ok, %Response{code: 405}} = Response.method_not_allowed
      assert {:ok, %Response{code: 406}} = Response.not_acceptable
      assert {:ok, %Response{code: 407}} = Response.proxy_authentication_required
      assert {:ok, %Response{code: 408}} = Response.request_timeout
      assert {:ok, %Response{code: 409}} = Response.conflict
      assert {:ok, %Response{code: 410}} = Response.gone
      assert {:ok, %Response{code: 411}} = Response.length_required
      assert {:ok, %Response{code: 412}} = Response.precondition_failed
      assert {:ok, %Response{code: 413}} = Response.payload_too_large
      assert {:ok, %Response{code: 414}} = Response.uri_too_long
      assert {:ok, %Response{code: 415}} = Response.unsupported_media_type
      assert {:ok, %Response{code: 417}} = Response.expectation_failed
      assert {:ok, %Response{code: 418}} = Response.im_a_teapot
      assert {:ok, %Response{code: 422}} = Response.unprocessable_entity
      assert {:ok, %Response{code: 423}} = Response.locked
      assert {:ok, %Response{code: 424}} = Response.failed_dependency
      assert {:ok, %Response{code: 426}} = Response.upgrade_required
      assert {:ok, %Response{code: 428}} = Response.precondition_required
      assert {:ok, %Response{code: 429}} = Response.too_many_requests
      assert {:ok, %Response{code: 431}} = Response.request_header_fields_too_large
    end

    test "! version returns the response with correspondent status code" do
      assert %Response{code: 400} = Response.bad_request!
      assert %Response{code: 401} = Response.unauthorized!
      assert %Response{code: 403} = Response.forbidden!
      assert %Response{code: 404} = Response.not_found!
      assert %Response{code: 405} = Response.method_not_allowed!
      assert %Response{code: 406} = Response.not_acceptable!
      assert %Response{code: 407} = Response.proxy_authentication_required!
      assert %Response{code: 408} = Response.request_timeout!
      assert %Response{code: 409} = Response.conflict!
      assert %Response{code: 410} = Response.gone!
      assert %Response{code: 411} = Response.length_required!
      assert %Response{code: 412} = Response.precondition_failed!
      assert %Response{code: 413} = Response.payload_too_large!
      assert %Response{code: 414} = Response.uri_too_long!
      assert %Response{code: 415} = Response.unsupported_media_type!
      assert %Response{code: 417} = Response.expectation_failed!
      assert %Response{code: 418} = Response.im_a_teapot!
      assert %Response{code: 422} = Response.unprocessable_entity!
      assert %Response{code: 423} = Response.locked!
      assert %Response{code: 424} = Response.failed_dependency!
      assert %Response{code: 426} = Response.upgrade_required!
      assert %Response{code: 428} = Response.precondition_required!
      assert %Response{code: 429} = Response.too_many_requests!
      assert %Response{code: 431} = Response.request_header_fields_too_large!
    end
  end

  describe "5xx" do
    test "all_5xx responds a list with all 5xx status code" do
      assert length(Response.all_5xx) == 10
      Enum.each(Response.all_5xx, fn(response) ->
        assert response.code >= 500 && response.code <= 511
      end)
    end

    test "normal version returns {:ok, response} with the correspondent status code" do
      assert {:ok, %Response{code: 500, body: "", headers: %{}}} ==  Response.internal_server_error
      assert {:ok, %Response{code: 501, body: "", headers: %{}}} ==  Response.not_implemented
      assert {:ok, %Response{code: 502, body: "", headers: %{}}} ==  Response.bad_gateway
      assert {:ok, %Response{code: 503, body: "", headers: %{}}} ==  Response.service_unavailable
      assert {:ok, %Response{code: 504, body: "", headers: %{}}} ==  Response.gateway_timeout
      assert {:ok, %Response{code: 505, body: "", headers: %{}}} ==  Response.http_version_not_supported
      assert {:ok, %Response{code: 506, body: "", headers: %{}}} ==  Response.variant_also_negotiates
      assert {:ok, %Response{code: 507, body: "", headers: %{}}} ==  Response.insufficient_storage
      assert {:ok, %Response{code: 510, body: "", headers: %{}}} ==  Response.not_extended
      assert {:ok, %Response{code: 511, body: "", headers: %{}}} ==  Response.network_authentication_required
    end

    test "! version returns the response with correspondent status code" do
      assert %Response{code: 500, body: "", headers: %{}} ==  Response.internal_server_error!
      assert %Response{code: 501, body: "", headers: %{}} ==  Response.not_implemented!
      assert %Response{code: 502, body: "", headers: %{}} ==  Response.bad_gateway!
      assert %Response{code: 503, body: "", headers: %{}} ==  Response.service_unavailable!
      assert %Response{code: 504, body: "", headers: %{}} ==  Response.gateway_timeout!
      assert %Response{code: 505, body: "", headers: %{}} ==  Response.http_version_not_supported!
      assert %Response{code: 506, body: "", headers: %{}} ==  Response.variant_also_negotiates!
      assert %Response{code: 507, body: "", headers: %{}} ==  Response.insufficient_storage!
      assert %Response{code: 510, body: "", headers: %{}} ==  Response.not_extended!
      assert %Response{code: 511, body: "", headers: %{}} ==  Response.network_authentication_required!
    end
  end
end
