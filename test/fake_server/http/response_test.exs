defmodule ResponseTest do
  use ExUnit.Case
  alias FakeServer.HTTP.Response

  test "#new" do
    assert Response.new(200) == %Response{code: 200, body: "", headers: []}
    assert Response.new(200, ~s<{"message": "This is a body"}>) == %Response{code: 200, body: ~s<{"message": "This is a body"}>, headers: []}
    assert Response.new(200, "", %{"x-my-header" => "fake-server"}) == %Response{code: 200, body: "", headers: %{"x-my-header" => "fake-server"}}
  end

  test "#default" do
    assert Response.default == %Response{code: 200, body: ~s<{"message": "This is a default response from FakeServer"}>, headers: []}
  end

  test "2XX" do
    assert Response.ok == %Response{code: 200, body: "", headers: []}
    assert Response.created == %Response{code: 201, body: "", headers: []}
    assert Response.accepted == %Response{code: 202, body: "", headers: []}
    assert Response.non_authoritative_information == %Response{code: 203, body: "", headers: []}
    assert Response.no_content == %Response{code: 204, body: "", headers: []}
    assert Response.reset_content == %Response{code: 205, body: "", headers: []}
    assert Response.partial_content == %Response{code: 206, body: "", headers: []}
    assert Response.multi_status == %Response{code: 207, body: "", headers: []}
    assert Response.already_reported == %Response{code: 208, body: "", headers: []}
    assert Response.im_used == %Response{code: 226, body: "", headers: []}
  end

  test "4xx" do
    assert Response.bad_request == %Response{code: 400, body: "", headers: []}
    assert Response.unauthorized == %Response{code: 401, body: "", headers: []}
    assert Response.payment_required == %Response{code: 402, body: "", headers: []}
    assert Response.forbidden == %Response{code: 403, body: "", headers: []}
    assert Response.not_found == %Response{code: 404, body: "", headers: []}
    assert Response.method_not_allowed == %Response{code: 405, body: "", headers: []}
    assert Response.not_acceptable == %Response{code: 406, body: "", headers: []}
    assert Response.proxy_authentication_required == %Response{code: 407, body: "", headers: []}
    assert Response.request_timeout == %Response{code: 408, body: "", headers: []}
    assert Response.conflict == %Response{code: 409, body: "", headers: []}
    assert Response.gone == %Response{code: 410, body: "", headers: []}
    assert Response.length_required == %Response{code: 411, body: "", headers: []}
    assert Response.precondition_failed == %Response{code: 412, body: "", headers: []}
    assert Response.payload_too_large == %Response{code: 413, body: "", headers: []}
    assert Response.uri_too_long == %Response{code: 414, body: "", headers: []}
    assert Response.unsupported_media_type == %Response{code: 415, body: "", headers: []}
    assert Response.expectation_failed == %Response{code: 417, body: "", headers: []}
    assert Response.im_a_teapot == %Response{code: 418, body: "", headers: []}
    assert Response.misdirected_request == %Response{code: 421, body: "", headers: []}
    assert Response.unprocessable_entity == %Response{code: 422, body: "", headers: []}
    assert Response.locked == %Response{code: 423, body: "", headers: []}
    assert Response.failed_dependency == %Response{code: 424, body: "", headers: []}
    assert Response.upgrade_required == %Response{code: 426, body: "", headers: []}
    assert Response.precondition_required == %Response{code: 428, body: "", headers: []}
    assert Response.too_many_requests == %Response{code: 429, body: "", headers: []}
    assert Response.request_header_fields_too_large == %Response{code: 431, body: "", headers: []}
    assert Response.unavailable_for_legal_reasons ==  %Response{code: 451, body: "", headers: []}
  end

  test "5xx" do
    assert Response.internal_server_error ==  %Response{code: 500, body: "", headers: []}
    assert Response.not_implemented ==  %Response{code: 501, body: "", headers: []}
    assert Response.bad_gateway ==  %Response{code: 502, body: "", headers: []}
    assert Response.service_unavailable ==  %Response{code: 503, body: "", headers: []}
    assert Response.gateway_timeout ==  %Response{code: 504, body: "", headers: []}
    assert Response.http_version_not_supported ==  %Response{code: 505, body: "", headers: []}
    assert Response.variant_also_negotiates ==  %Response{code: 506, body: "", headers: []}
    assert Response.insufficient_storage ==  %Response{code: 507, body: "", headers: []}
    assert Response.loop_detected ==  %Response{code: 508, body: "", headers: []}
    assert Response.not_extended ==  %Response{code: 510, body: "", headers: []}
    assert Response.network_authentication_required ==  %Response{code: 511, body: "", headers: []}
  end
end
