defmodule ResponseTest do
  use ExUnit.Case
  alias FakeServer.Response

  describe "#new" do
    test "accept the response status code as a mandatory parameter" do
      assert {:ok, %Response{status: 200}} = Response.new(200)
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

    test "returns {:error, {headers, reason}} if headers are not a map" do
      assert {:error, {[], "response headers must be a map"}} == Response.new(200, "", [])
      assert {:error, {"", "response headers must be a map"}} == Response.new(200, "", "")
      assert {:error, {12, "response headers must be a map"}} == Response.new(200, "", 12)
    end

    test "returns {:error, {headers, reason}} if headers keys are not strings" do
      assert {:error, {%{content_type: "application/json"}, "all header keys must be strings"}} == Response.new(200, "", %{content_type: "application/json"})
    end

    test "returns {:error, {body, reason}} if body is not a map or string" do
      assert {:error, {'hello', "body must be a map or a string"}} == Response.new(200, 'hello')
      assert {:error, {1234567, "body must be a map or a string"}} == Response.new(200, 1234567)
    end

    test "returns {:error, {body, reason}} if body could not be encoded" do
      assert {:error, {%{test: {:a, 1}}, "could not turn body map into json"}} == Response.new(200, %{test: {:a, 1}})
    end

    test "returns {:error, {status, reason}} if status is not a valid integer" do
      assert {:error, {600, "invalid status code"}} == Response.new(600)
      assert {:error, {-200, "invalid status code"}} == Response.new(-200)
      assert {:error, {"200", "invalid status code"}} == Response.new("200")
    end
  end

  describe "#new!" do
    test "accept the response status code as a mandatory parameter" do
      assert %Response{status: 200} = Response.new!(200)
    end

    test "accept the response body as string" do
      assert %Response{body: ~s<{"message": "This is a body"}>} = Response.new!(200, ~s<{"message": "This is a body"}>)
    end

    test "encode the body if it is a valid json map" do
      assert %Response{body: ~s<{"message":"This is a body","code":1}>} = Response.new!(200, %{message: "This is a body", code: 1})
    end

    test "accept the response headers as a map" do
      assert %Response{headers: %{"x-my-header" => "fake-server"}} = Response.new!(200, "", %{"x-my-header" => "fake-server"})
    end

    test "raise FakeServer.Error if headers are not a map" do
      assert_raise FakeServer.Error, ~s<[]: response headers must be a map>, fn -> Response.new!(200, "", []) end
      assert_raise FakeServer.Error, ~s<"": response headers must be a map>, fn -> Response.new!(200, "", "") end
      assert_raise FakeServer.Error, ~s<12: response headers must be a map>, fn -> Response.new!(200, "", 12) end
    end

    test "returns {:error, {headers, reason}} if headers keys are not strings" do
      assert_raise FakeServer.Error, ~s<%{content_type: "application/json"}: all header keys must be strings>, fn ->
        Response.new!(200, "", %{content_type: "application/json"})
      end
    end

    test "returns {:error, {body, reason}} if body is not a map or string" do
      assert_raise FakeServer.Error, ~s<'hello': body must be a map or a string>, fn -> Response.new!(200, 'hello') end
      assert_raise FakeServer.Error, ~s<1234567: body must be a map or a string>, fn -> Response.new!(200, 1234567) end
    end

    test "returns {:error, {body, reason}} if body could not be encoded" do
      assert_raise FakeServer.Error, ~s<%{test: {:a, 1}}: could not turn body map into json>, fn -> Response.new!(200, %{test: {:a, 1}}) end
    end

    test "returns {:error, {status, reason}} if status is not a valid integer" do
      assert_raise FakeServer.Error, ~s<600: invalid status code>, fn -> Response.new!(600) end
      assert_raise FakeServer.Error, ~s<-200: invalid status code>, fn -> Response.new!(-200) end
      assert_raise FakeServer.Error, ~s<"200": invalid status code>, fn -> Response.new!("200") end
    end
  end

  describe "#validate" do
    test "returns {:error, reason} when status code is invalid" do
      assert {:error, {600, "invalid status code"}} == %Response{status: 600} |> Response.validate
      assert {:error, {"200", "invalid status code"}} == %Response{status: "200"} |> Response.validate
      assert {:error, {[], "invalid status code"}} == %Response{status: []} |> Response.validate
      assert {:error, {%{}, "invalid status code"}} == %Response{status: %{}} |> Response.validate
    end

    test "returns {:error, reason} when header list is not a map" do
      assert {:error, {1, "response headers must be a map"}} == %Response{status: 200, headers: 1} |> Response.validate
      assert {:error, {[], "response headers must be a map"}} == %Response{status: 200, headers: []} |> Response.validate
      assert {:error, {[{"a", "b"}], "response headers must be a map"}} == %Response{status: 200, headers:  [{"a", "b"}]} |> Response.validate
    end

    test "returns {:error, reason} when body is not a map or string" do
      assert {:error, {1, "body must be a map or a string"}} == %Response{status: 200, body: 1} |> Response.validate
      assert {:error, {[], "body must be a map or a string"}} == %Response{status: 200, body: []} |> Response.validate
      assert {:error, {{:a, 1}, "body must be a map or a string"}} == %Response{status: 200, body: {:a, 1}} |> Response.validate
    end

    test "returns :ok when response is valid" do
      assert :ok == %Response{status: 200} |> Response.validate
      assert :ok == %Response{status: 200, headers: %{}} |> Response.validate
      assert :ok == %Response{status: 200, body: ""} |> Response.validate
      assert :ok == %Response{status: 200, body: %{}, headers: %{}} |> Response.validate
    end
  end

  test "#default" do
    assert {:ok, %Response{status: 200, body: ~s<{"message": "This is a default response from FakeServer"}>, headers: %{}}} == Response.default
  end

  test "#default!" do
    assert %Response{status: 200, body: ~s<{"message": "This is a default response from FakeServer"}>, headers: %{}} == Response.default!
  end

  describe "2XX" do
    test "normal version returns {:ok, response} with the correspondent status code" do
      assert {:ok, %Response{status: 200, body: "", headers: %{}}} == Response.ok
      assert {:ok, %Response{status: 201, body: "", headers: %{}}} == Response.created
      assert {:ok, %Response{status: 202, body: "", headers: %{}}} == Response.accepted
      assert {:ok, %Response{status: 203, body: "", headers: %{}}} == Response.non_authoritative_information
      assert {:ok, %Response{status: 204, body: "", headers: %{}}} == Response.no_content
      assert {:ok, %Response{status: 205, body: "", headers: %{}}} == Response.reset_content
      assert {:ok, %Response{status: 206, body: "", headers: %{}}} == Response.partial_content
    end

    test "! version returns the response with correspondent status code" do
      assert %Response{status: 200, body: "", headers: %{}} == Response.ok!
      assert %Response{status: 201, body: "", headers: %{}} == Response.created!
      assert %Response{status: 202, body: "", headers: %{}} == Response.accepted!
      assert %Response{status: 203, body: "", headers: %{}} == Response.non_authoritative_information!
      assert %Response{status: 204, body: "", headers: %{}} == Response.no_content!
      assert %Response{status: 205, body: "", headers: %{}} == Response.reset_content!
      assert %Response{status: 206, body: "", headers: %{}} == Response.partial_content!
    end
  end

  describe "4XX" do
    test "all_4xx responds a list with all 4xx status code" do
      assert length(Response.all_4xx) == 24
      Enum.each(Response.all_4xx, fn(response) ->
        assert response.status >= 400 && response.status <= 431
      end)
    end

    test "normal version returns {:ok, response} with the correspondent status code" do
      assert {:ok, %Response{status: 400}} = Response.bad_request
      assert {:ok, %Response{status: 401}} = Response.unauthorized
      assert {:ok, %Response{status: 403}} = Response.forbidden
      assert {:ok, %Response{status: 404}} = Response.not_found
      assert {:ok, %Response{status: 405}} = Response.method_not_allowed
      assert {:ok, %Response{status: 406}} = Response.not_acceptable
      assert {:ok, %Response{status: 407}} = Response.proxy_authentication_required
      assert {:ok, %Response{status: 408}} = Response.request_timeout
      assert {:ok, %Response{status: 409}} = Response.conflict
      assert {:ok, %Response{status: 410}} = Response.gone
      assert {:ok, %Response{status: 411}} = Response.length_required
      assert {:ok, %Response{status: 412}} = Response.precondition_failed
      assert {:ok, %Response{status: 413}} = Response.payload_too_large
      assert {:ok, %Response{status: 414}} = Response.uri_too_long
      assert {:ok, %Response{status: 415}} = Response.unsupported_media_type
      assert {:ok, %Response{status: 417}} = Response.expectation_failed
      assert {:ok, %Response{status: 418}} = Response.im_a_teapot
      assert {:ok, %Response{status: 422}} = Response.unprocessable_entity
      assert {:ok, %Response{status: 423}} = Response.locked
      assert {:ok, %Response{status: 424}} = Response.failed_dependency
      assert {:ok, %Response{status: 426}} = Response.upgrade_required
      assert {:ok, %Response{status: 428}} = Response.precondition_required
      assert {:ok, %Response{status: 429}} = Response.too_many_requests
      assert {:ok, %Response{status: 431}} = Response.request_header_fields_too_large
    end

    test "! version returns the response with correspondent status code" do
      assert %Response{status: 400} = Response.bad_request!
      assert %Response{status: 401} = Response.unauthorized!
      assert %Response{status: 403} = Response.forbidden!
      assert %Response{status: 404} = Response.not_found!
      assert %Response{status: 405} = Response.method_not_allowed!
      assert %Response{status: 406} = Response.not_acceptable!
      assert %Response{status: 407} = Response.proxy_authentication_required!
      assert %Response{status: 408} = Response.request_timeout!
      assert %Response{status: 409} = Response.conflict!
      assert %Response{status: 410} = Response.gone!
      assert %Response{status: 411} = Response.length_required!
      assert %Response{status: 412} = Response.precondition_failed!
      assert %Response{status: 413} = Response.payload_too_large!
      assert %Response{status: 414} = Response.uri_too_long!
      assert %Response{status: 415} = Response.unsupported_media_type!
      assert %Response{status: 417} = Response.expectation_failed!
      assert %Response{status: 418} = Response.im_a_teapot!
      assert %Response{status: 422} = Response.unprocessable_entity!
      assert %Response{status: 423} = Response.locked!
      assert %Response{status: 424} = Response.failed_dependency!
      assert %Response{status: 426} = Response.upgrade_required!
      assert %Response{status: 428} = Response.precondition_required!
      assert %Response{status: 429} = Response.too_many_requests!
      assert %Response{status: 431} = Response.request_header_fields_too_large!
    end
  end

  describe "5xx" do
    test "all_5xx responds a list with all 5xx status code" do
      assert length(Response.all_5xx) == 10
      Enum.each(Response.all_5xx, fn(response) ->
        assert response.status >= 500 && response.status <= 511
      end)
    end

    test "normal version returns {:ok, response} with the correspondent status code" do
      assert {:ok, %Response{status: 500, body: "", headers: %{}}} ==  Response.internal_server_error
      assert {:ok, %Response{status: 501, body: "", headers: %{}}} ==  Response.not_implemented
      assert {:ok, %Response{status: 502, body: "", headers: %{}}} ==  Response.bad_gateway
      assert {:ok, %Response{status: 503, body: "", headers: %{}}} ==  Response.service_unavailable
      assert {:ok, %Response{status: 504, body: "", headers: %{}}} ==  Response.gateway_timeout
      assert {:ok, %Response{status: 505, body: "", headers: %{}}} ==  Response.http_version_not_supported
      assert {:ok, %Response{status: 506, body: "", headers: %{}}} ==  Response.variant_also_negotiates
      assert {:ok, %Response{status: 507, body: "", headers: %{}}} ==  Response.insufficient_storage
      assert {:ok, %Response{status: 510, body: "", headers: %{}}} ==  Response.not_extended
      assert {:ok, %Response{status: 511, body: "", headers: %{}}} ==  Response.network_authentication_required
    end

    test "! version returns the response with correspondent status code" do
      assert %Response{status: 500, body: "", headers: %{}} ==  Response.internal_server_error!
      assert %Response{status: 501, body: "", headers: %{}} ==  Response.not_implemented!
      assert %Response{status: 502, body: "", headers: %{}} ==  Response.bad_gateway!
      assert %Response{status: 503, body: "", headers: %{}} ==  Response.service_unavailable!
      assert %Response{status: 504, body: "", headers: %{}} ==  Response.gateway_timeout!
      assert %Response{status: 505, body: "", headers: %{}} ==  Response.http_version_not_supported!
      assert %Response{status: 506, body: "", headers: %{}} ==  Response.variant_also_negotiates!
      assert %Response{status: 507, body: "", headers: %{}} ==  Response.insufficient_storage!
      assert %Response{status: 510, body: "", headers: %{}} ==  Response.not_extended!
      assert %Response{status: 511, body: "", headers: %{}} ==  Response.network_authentication_required!
    end
  end
end
