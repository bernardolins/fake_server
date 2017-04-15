defmodule FakeServer.HTTP.ResponseTest do
  use ExUnit.Case
  alias FakeServer.HTTP.Response

  test "#ok must respond with a 200 status code and empty body and headers" do
    assert Response.ok == %Response{code: 200, body: "", headers: []}
  end

  test "#created must respond with a 201 status code and empty body and headers" do
    assert Response.created == %Response{code: 201, body: "", headers: []}
  end

  test "#accepted must respond with a 202 status code and empty body and headers" do
    assert Response.accepted == %Response{code: 202, body: "", headers: []}
  end

  test "#no_content must respond with a 204 status code and empty body and headers" do
    assert Response.no_content == %Response{code: 204, body: "", headers: []}
  end

  test "#bad_request must respond with a 400 status code and empty body and headers" do
    assert Response.bad_request == %Response{code: 400, body: "", headers: []}
  end

  test "#unauthorized must respond with a 401 status code and empty body and headers" do
    assert Response.unauthorized == %Response{code: 401, body: "", headers: []}
  end

  test "#forbidden must respond with a 403 status code and empty body and headers" do
    assert Response.forbidden == %Response{code: 403, body: "", headers: []}
  end

  test "#not_found must respond with a 404 status code and empty body and headers" do
    assert Response.not_found == %Response{code: 404, body: "", headers: []}
  end

  test "#default must respond with a 200 status code, a message on the body and empty headers" do
    assert Response.default == %Response{code: 200, body: "This is a default response from FakeServer", headers: []}
  end
end
