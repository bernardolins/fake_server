defmodule FakeServer.HTTP.Response do
  defstruct [code: nil, body: "", headers: []]
  @enforce_keys[:code]

  def ok(body \\ "", headers \\ []) do
    %FakeServer.HTTP.Response{code: 200, body: body, headers: headers}
  end

  def created(body \\ "", headers \\ []) do
    %FakeServer.HTTP.Response{code: 201, body: body, headers: headers}
  end

  def bad_request(body \\ "", headers \\ []) do
    %FakeServer.HTTP.Response{code: 400, body: body, headers: headers}
  end

  def unauthorized(body \\ "", headers \\ []) do
    %FakeServer.HTTP.Response{code: 401, body: body, headers: headers}
  end

  def forbidden(body \\ "", headers \\ []) do
    %FakeServer.HTTP.Response{code: 403, body: body, headers: headers}
  end

  def not_found(body \\ "", headers \\ []) do
    %FakeServer.HTTP.Response{code: 404, body: body, headers: headers}
  end

  def default do
    %FakeServer.HTTP.Response{code: 200, body: "This is a default response from FakeServer"}
  end
end
