defmodule FakeServer.HTTP.Response do
  @moduledoc """
  Response structure

  FakeServer makes use of the FakeServer.HTTP.Response structure to define the responses that will be given by the server.

  The structure has the following fields:

    - `:code`: The status code of the response. It must be an integer.
    - `:body`: Optional. The response body. Can be a string or a map.
    - `:headers`: Optional. The response headers. Must be a map with the string keys.

  You can use the `new/3` function to create a new struct.
  """

  @enforce_keys [:code]
  defstruct [code: nil, body: "", headers: %{}]

  @doc """
  Creates a new Response structure.

  ## Example
  ```elixir
  FakeServer.HTTP.Response.new(200, %{name: "Test User", email: "test_user@test.com"}, %{"Content-Type" => "application/json"})
  FakeServer.HTTP.Response.new(200, ~s<{"name":"Test User","email":"test_user@test.com"}>, %{"Content-Type" => "application/json"})
  FakeServer.HTTP.Response.new(201, ~s<{"name":"Test User","email":"test_user@test.com"}>)
  FakeServer.HTTP.Response.new(404)
  ```
  """
  def new(status_code, body \\ "", headers \\ %{}), do: %__MODULE__{code: status_code, body: body, headers: headers}

  @doc """
  Creates a new response with status code 200
  """
  def ok(body \\ "", headers \\ %{}), do: new(200, body, headers)

  @doc """
  Creates a new response with status code 201
  """
  def created(body \\ "", headers \\ %{}), do: new(201, body, headers)

  @doc """
  Creates a new response with status code 202
  """
  def accepted(body \\ "", headers \\ %{}), do: new(202, body, headers)

  @doc """
  Creates a new response with status code 203
  """
  def non_authoritative_information(body \\ "", headers \\ %{}), do: new(203, body, headers)

  @doc """
  Creates a new response with status code 204
  """
  def no_content(body \\ "", headers \\ %{}), do: new(204, body, headers)

  @doc """
  Creates a new response with status code 205
  """
  def reset_content(body \\ "", headers \\ %{}), do: new(205, body, headers)

  @doc """
  Creates a new response with status code 206
  """
  def partial_content(body \\ "", headers \\ %{}), do: new(206, body, headers)

  @doc """
  Returns a list with all 4xx HTTP methods available
  """
  def all_4xx do
    [
      bad_request(),
      unauthorized(),
      forbidden(),
      not_found(),
      method_not_allowed(),
      not_acceptable(),
      proxy_authentication_required(),
      request_timeout(),
      conflict(),
      gone(),
      length_required(),
      precondition_failed(),
      payload_too_large(),
      uri_too_long(),
      unsupported_media_type(),
      expectation_failed(),
      im_a_teapot(),
      unprocessable_entity(),
      locked(),
      failed_dependency(),
      upgrade_required(),
      precondition_required(),
      too_many_requests(),
      request_header_fields_too_large()
    ]
  end

  @doc """
  Creates a new response with status code 400
  """
  def bad_request(body \\ "", headers \\ %{}), do: new(400, body, headers)

  @doc """
  Creates a new response with status code 401
  """
  def unauthorized(body \\ "", headers \\ %{}), do: new(401, body, headers)

  @doc """
  Creates a new response with status code 403
  """
  def forbidden(body \\ "", headers \\ %{}), do: new(403, body, headers)

  @doc """
  Creates a new response with status code 404
  """
  def not_found(body \\ "", headers \\ %{}), do: new(404, body, headers)

  @doc """
  Creates a new response with status code 405
  """
  def method_not_allowed(body \\ "", headers \\ %{}), do: new(405, body, headers)

  @doc """
  Creates a new response with status code 406
  """
  def not_acceptable(body \\ "", headers \\ %{}), do: new(406, body, headers)

  @doc """
  Creates a new response with status code 407
  """
  def proxy_authentication_required(body \\ "", headers \\ %{}), do: new(407, body, headers)

  @doc """
  Creates a new response with status code 408
  """
  def request_timeout(body \\ "", headers \\ %{}), do: new(408, body, headers)

  @doc """
  Creates a new response with status code 409
  """
  def conflict(body \\ "", headers \\ %{}), do: new(409, body, headers)

  @doc """
  Creates a new response with status code 410
  """
  def gone(body \\ "", headers \\ %{}), do: new(410, body, headers)

  @doc """
  Creates a new response with status code 411
  """
  def length_required(body \\ "", headers \\ %{}), do: new(411, body, headers)

  @doc """
  Creates a new response with status code 412
  """
  def precondition_failed(body \\ "", headers \\ %{}), do: new(412, body, headers)

  @doc """
  Creates a new response with status code 413
  """
  def payload_too_large(body \\ "", headers \\ %{}), do: new(413, body, headers)

  @doc """
  Creates a new response with status code 414
  """
  def uri_too_long(body \\ "", headers \\ %{}), do: new(414, body, headers)

  @doc """
  Creates a new response with status code 415
  """
  def unsupported_media_type(body \\ "", headers \\ %{}), do: new(415, body, headers)

  @doc """
  Creates a new response with status code 417
  """
  def expectation_failed(body \\ "", headers \\ %{}), do: new(417, body, headers)

  @doc """
  Creates a new response with status code 418
  """
  def im_a_teapot(body \\ "", headers \\ %{}), do: new(418, body, headers)

  @doc """
  Creates a new response with status code 422
  """
  def unprocessable_entity(body \\ "", headers \\ %{}), do: new(422, body, headers)

  @doc """
  Creates a new response with status code 423
  """
  def locked(body \\ "", headers \\ %{}), do: new(423, body, headers)

  @doc """
  Creates a new response with status code 424
  """
  def failed_dependency(body \\ "", headers \\ %{}), do: new(424, body, headers)

  @doc """
  Creates a new response with status code 426
  """
  def upgrade_required(body \\ "", headers \\ %{}), do: new(426, body, headers)

  @doc """
  Creates a new response with status code 428
  """
  def precondition_required(body \\ "", headers \\ %{}), do: new(428, body, headers)

  @doc """
  Creates a new response with status code 429
  """
  def too_many_requests(body \\ "", headers \\ %{}), do: new(429, body, headers)

  @doc """
  Creates a new response with status code 431
  """
  def request_header_fields_too_large(body \\ "", headers \\ %{}), do: new(431, body, headers)

  @doc """
  Returns a list with all 5xx HTTP methods available
  """
  def all_5xx do
    [
      internal_server_error(),
      not_implemented(),
      bad_gateway(),
      service_unavailable(),
      gateway_timeout(),
      http_version_not_supported(),
      variant_also_negotiates(),
      insufficient_storage(),
      not_extended(),
      network_authentication_required()
    ]
  end

  @doc """
  Creates a new response with status code 500
  """
  def internal_server_error(body \\ "", headers \\ %{}), do: new(500, body, headers)

  @doc """
  Creates a new response with status code 501
  """
  def not_implemented(body \\ "", headers \\ %{}), do: new(501, body, headers)

  @doc """
  Creates a new response with status code 502
  """
  def bad_gateway(body \\ "", headers \\ %{}), do: new(502, body, headers)

  @doc """
  Creates a new response with status code 503
  """
  def service_unavailable(body \\ "", headers \\ %{}), do: new(503, body, headers)

  @doc """
  Creates a new response with status code 504
  """
  def gateway_timeout(body \\ "", headers \\ %{}), do: new(504, body, headers)

  @doc """
  Creates a new response with status code 505
  """
  def http_version_not_supported(body \\ "", headers \\ %{}), do: new(505, body, headers)

  @doc """
  Creates a new response with status code 506
  """
  def variant_also_negotiates(body \\ "", headers \\ %{}), do: new(506, body, headers)

  @doc """
  Creates a new response with status code 507
  """
  def insufficient_storage(body \\ "", headers \\ %{}), do: new(507, body, headers)

  @doc """
  Creates a new response with status code 510
  """
  def not_extended(body \\ "", headers \\ %{}), do: new(510, body, headers)

  @doc """
  Creates a new response with status code 511
  """
  def network_authentication_required(body \\ "", headers \\ %{}), do: new(511, body, headers)

  @doc """
  FakeServer default response. Used when there are no responses left to reply.
  """
  def default, do: new(200, ~s<{"message": "This is a default response from FakeServer"}>)
end


