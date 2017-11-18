defmodule ResponseTest do
  use ExUnit.Case
  alias FakeServer.HTTP.Response

  describe "#new" do
    test "accept the response status code as a mandatory parameter" do
      assert Response.new(200) == %Response{code: 200, body: "", headers: %{}}
    end

    test "accept the response body as string" do
      assert Response.new(200, ~s<{"message": "This is a body"}>) == %Response{code: 200, body: ~s<{"message": "This is a body"}>, headers: %{}}
    end

    test "accept the response body as map" do
      assert Response.new(200, %{message: "This is a body", code: 1}) == %Response{code: 200, body: %{message: "This is a body", code: 1}, headers: %{}}
    end

    test "accept the response headers as a map" do
      assert Response.new(200, "", %{"x-my-header" => "fake-server"}) == %Response{code: 200, body: "", headers: %{"x-my-header" => "fake-server"}}
    end
  end

  test "#default" do
    assert Response.default == %Response{code: 200, body: ~s<{"message": "This is a default response from FakeServer"}>, headers: %{}}
  end

  describe "2XX" do
    test "returns the correspondent status code" do
      assert Response.ok == %Response{code: 200, body: "", headers: %{}}
      assert Response.created == %Response{code: 201, body: "", headers: %{}}
      assert Response.accepted == %Response{code: 202, body: "", headers: %{}}
      assert Response.non_authoritative_information == %Response{code: 203, body: "", headers: %{}}
      assert Response.no_content == %Response{code: 204, body: "", headers: %{}}
      assert Response.reset_content == %Response{code: 205, body: "", headers: %{}}
      assert Response.partial_content == %Response{code: 206, body: "", headers: %{}}
      assert Response.multi_status == %Response{code: 207, body: "", headers: %{}}
      assert Response.already_reported == %Response{code: 208, body: "", headers: %{}}
      assert Response.im_used == %Response{code: 226, body: "", headers: %{}}
    end

    test "returns the correspondent status code with a json string as body" do
      assert Response.ok(~s<{"status_kind": "2xx"}>) == %Response{code: 200, body: ~s<{"status_kind": "2xx"}>, headers: %{}}
      assert Response.created(~s<{"status_kind": "2xx"}>) == %Response{code: 201, body: ~s<{"status_kind": "2xx"}>, headers: %{}}
      assert Response.accepted(~s<{"status_kind": "2xx"}>) == %Response{code: 202, body: ~s<{"status_kind": "2xx"}>, headers: %{}}
      assert Response.non_authoritative_information(~s<{"status_kind": "2xx"}>) == %Response{code: 203, body: ~s<{"status_kind": "2xx"}>, headers: %{}}
      assert Response.no_content(~s<{"status_kind": "2xx"}>) == %Response{code: 204, body: ~s<{"status_kind": "2xx"}>, headers: %{}}
      assert Response.reset_content(~s<{"status_kind": "2xx"}>) == %Response{code: 205, body: ~s<{"status_kind": "2xx"}>, headers: %{}}
      assert Response.partial_content(~s<{"status_kind": "2xx"}>) == %Response{code: 206, body: ~s<{"status_kind": "2xx"}>, headers: %{}}
      assert Response.multi_status(~s<{"status_kind": "2xx"}>) == %Response{code: 207, body: ~s<{"status_kind": "2xx"}>, headers: %{}}
      assert Response.already_reported(~s<{"status_kind": "2xx"}>) == %Response{code: 208, body: ~s<{"status_kind": "2xx"}>, headers: %{}}
      assert Response.im_used(~s<{"status_kind": "2xx"}>) == %Response{code: 226, body: ~s<{"status_kind": "2xx"}>, headers: %{}}
    end

    test "returns the correspondent status code with a map as response body" do
      assert Response.ok(%{status_kind: "2xx"}) == %Response{code: 200, body: %{status_kind: "2xx"}, headers: %{}}
      assert Response.created(%{status_kind: "2xx"}) == %Response{code: 201, body: %{status_kind: "2xx"}, headers: %{}}
      assert Response.accepted(%{status_kind: "2xx"}) == %Response{code: 202, body: %{status_kind: "2xx"}, headers: %{}}
      assert Response.non_authoritative_information(%{status_kind: "2xx"}) == %Response{code: 203, body: %{status_kind: "2xx"}, headers: %{}}
      assert Response.no_content(%{status_kind: "2xx"}) == %Response{code: 204, body: %{status_kind: "2xx"}, headers: %{}}
      assert Response.reset_content(%{status_kind: "2xx"}) == %Response{code: 205, body: %{status_kind: "2xx"}, headers: %{}}
      assert Response.partial_content(%{status_kind: "2xx"}) == %Response{code: 206, body: %{status_kind: "2xx"}, headers: %{}}
      assert Response.multi_status(%{status_kind: "2xx"}) == %Response{code: 207, body: %{status_kind: "2xx"}, headers: %{}}
      assert Response.already_reported(%{status_kind: "2xx"}) == %Response{code: 208, body: %{status_kind: "2xx"}, headers: %{}}
      assert Response.im_used(%{status_kind: "2xx"}) == %Response{code: 226, body: %{status_kind: "2xx"}, headers: %{}}
    end
  end

  describe "4XX" do
    test "returns the correspondent status code with a map as response body" do
      assert Response.bad_request(%{status_kind: "4xx"})== %Response{code: 400, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.unauthorized(%{status_kind: "4xx"})== %Response{code: 401, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.payment_required(%{status_kind: "4xx"})== %Response{code: 402, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.forbidden(%{status_kind: "4xx"})== %Response{code: 403, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.not_found(%{status_kind: "4xx"})== %Response{code: 404, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.method_not_allowed(%{status_kind: "4xx"})== %Response{code: 405, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.not_acceptable(%{status_kind: "4xx"})== %Response{code: 406, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.proxy_authentication_required(%{status_kind: "4xx"})== %Response{code: 407, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.request_timeout(%{status_kind: "4xx"})== %Response{code: 408, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.conflict(%{status_kind: "4xx"})== %Response{code: 409, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.gone(%{status_kind: "4xx"})== %Response{code: 410, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.length_required(%{status_kind: "4xx"})== %Response{code: 411, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.precondition_failed(%{status_kind: "4xx"})== %Response{code: 412, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.payload_too_large(%{status_kind: "4xx"})== %Response{code: 413, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.uri_too_long(%{status_kind: "4xx"})== %Response{code: 414, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.unsupported_media_type(%{status_kind: "4xx"})== %Response{code: 415, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.expectation_failed(%{status_kind: "4xx"})== %Response{code: 417, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.im_a_teapot(%{status_kind: "4xx"})== %Response{code: 418, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.misdirected_request(%{status_kind: "4xx"})== %Response{code: 421, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.unprocessable_entity(%{status_kind: "4xx"})== %Response{code: 422, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.locked(%{status_kind: "4xx"})== %Response{code: 423, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.failed_dependency(%{status_kind: "4xx"})== %Response{code: 424, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.upgrade_required(%{status_kind: "4xx"})== %Response{code: 426, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.precondition_required(%{status_kind: "4xx"})== %Response{code: 428, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.too_many_requests(%{status_kind: "4xx"})== %Response{code: 429, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.request_header_fields_too_large(%{status_kind: "4xx"})== %Response{code: 431, body: %{status_kind: "4xx"}, headers: %{}}
      assert Response.unavailable_for_legal_reasons(%{status_kind: "4xx"})==  %Response{code: 451, body: %{status_kind: "4xx"}, headers: %{}}
    end

    test "returns the correspondent status code with a json string as response body" do
      assert Response.bad_request(~s<{"status_kind":"4xx"}>)== %Response{code: 400, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.unauthorized(~s<{"status_kind":"4xx"}>)== %Response{code: 401, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.payment_required(~s<{"status_kind":"4xx"}>)== %Response{code: 402, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.forbidden(~s<{"status_kind":"4xx"}>)== %Response{code: 403, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.not_found(~s<{"status_kind":"4xx"}>)== %Response{code: 404, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.method_not_allowed(~s<{"status_kind":"4xx"}>)== %Response{code: 405, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.not_acceptable(~s<{"status_kind":"4xx"}>)== %Response{code: 406, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.proxy_authentication_required(~s<{"status_kind":"4xx"}>)== %Response{code: 407, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.request_timeout(~s<{"status_kind":"4xx"}>)== %Response{code: 408, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.conflict(~s<{"status_kind":"4xx"}>)== %Response{code: 409, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.gone(~s<{"status_kind":"4xx"}>)== %Response{code: 410, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.length_required(~s<{"status_kind":"4xx"}>)== %Response{code: 411, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.precondition_failed(~s<{"status_kind":"4xx"}>)== %Response{code: 412, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.payload_too_large(~s<{"status_kind":"4xx"}>)== %Response{code: 413, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.uri_too_long(~s<{"status_kind":"4xx"}>)== %Response{code: 414, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.unsupported_media_type(~s<{"status_kind":"4xx"}>)== %Response{code: 415, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.expectation_failed(~s<{"status_kind":"4xx"}>)== %Response{code: 417, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.im_a_teapot(~s<{"status_kind":"4xx"}>)== %Response{code: 418, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.misdirected_request(~s<{"status_kind":"4xx"}>)== %Response{code: 421, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.unprocessable_entity(~s<{"status_kind":"4xx"}>)== %Response{code: 422, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.locked(~s<{"status_kind":"4xx"}>)== %Response{code: 423, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.failed_dependency(~s<{"status_kind":"4xx"}>)== %Response{code: 424, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.upgrade_required(~s<{"status_kind":"4xx"}>)== %Response{code: 426, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.precondition_required(~s<{"status_kind":"4xx"}>)== %Response{code: 428, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.too_many_requests(~s<{"status_kind":"4xx"}>)== %Response{code: 429, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.request_header_fields_too_large(~s<{"status_kind":"4xx"}>)== %Response{code: 431, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
      assert Response.unavailable_for_legal_reasons(~s<{"status_kind":"4xx"}>)==  %Response{code: 451, body: ~s<{"status_kind":"4xx"}>, headers: %{}}
    end
  end

  test "5xx" do
    assert Response.internal_server_error ==  %Response{code: 500, body: "", headers: %{}}
    assert Response.not_implemented ==  %Response{code: 501, body: "", headers: %{}}
    assert Response.bad_gateway ==  %Response{code: 502, body: "", headers: %{}}
    assert Response.service_unavailable ==  %Response{code: 503, body: "", headers: %{}}
    assert Response.gateway_timeout ==  %Response{code: 504, body: "", headers: %{}}
    assert Response.http_version_not_supported ==  %Response{code: 505, body: "", headers: %{}}
    assert Response.variant_also_negotiates ==  %Response{code: 506, body: "", headers: %{}}
    assert Response.insufficient_storage ==  %Response{code: 507, body: "", headers: %{}}
    assert Response.loop_detected ==  %Response{code: 508, body: "", headers: %{}}
    assert Response.not_extended ==  %Response{code: 510, body: "", headers: %{}}
    assert Response.network_authentication_required ==  %Response{code: 511, body: "", headers: %{}}
  end
end
