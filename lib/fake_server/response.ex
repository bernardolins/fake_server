defmodule FakeServer.Response do
  @moduledoc """
  Response structure

  FakeServer makes use of the FakeServer.Response structure to define the responses that will be given by the server.

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
  FakeServer.Response.new(200, %{name: "Test User", email: "test_user@test.com"}, %{"Content-Type" => "application/json"})
  FakeServer.Response.new(200, ~s<{"name":"Test User","email":"test_user@test.com"}>, %{"Content-Type" => "application/json"})
  FakeServer.Response.new(201, ~s<{"name":"Test User","email":"test_user@test.com"}>)
  FakeServer.Response.new(404)
  ```
  """
  def new(status_code, body \\ "", headers \\ %{}) do
    with response         <- %__MODULE__{code: status_code, body: body, headers: headers},
         :ok              <- validate(response),
         {:ok, response}  <- ensure_body_format(response),
         {:ok, response}  <- ensure_headers_keys(response)
    do
      {:ok, response}
    end
  end

  def new!(status_code, body \\ "", headers \\ %{}) do
    case new(status_code, body, headers) do
      {:ok, response} -> response
      {:error, reason} -> raise FakeServer.Error, reason
    end
  end

  def validate(%__MODULE__{body: body, code: code, headers: headers}) do
    cond do
      not is_map(headers) ->                            {:error, {headers, "response headers must be a map"}}
      not (is_bitstring(body) or is_map(body)) ->       {:error, {body, "body must be a map or a string"}}
      not Enum.member?(allowed_status_codes(), code) -> {:error, {code, "invalid status code"}}
      true ->                                           :ok
    end
  end
  def validate(response), do: {:error, {response, "invalid response type"}}

  @doc """
  Creates a new response with status code 200
  """
  def ok(body \\ "", headers \\ %{}), do: new(200, body, headers)
  def ok!(body \\ "", headers \\ %{}), do: new!(200, body, headers)

  @doc """
  Creates a new response with status code 201
  """
  def created(body \\ "", headers \\ %{}), do: new(201, body, headers)
  def created!(body \\ "", headers \\ %{}), do: new!(201, body, headers)

  @doc """
  Creates a new response with status code 202
  """
  def accepted(body \\ "", headers \\ %{}), do: new(202, body, headers)
  def accepted!(body \\ "", headers \\ %{}), do: new!(202, body, headers)

  @doc """
  Creates a new response with status code 203
  """
  def non_authoritative_information(body \\ "", headers \\ %{}), do: new(203, body, headers)
  def non_authoritative_information!(body \\ "", headers \\ %{}), do: new!(203, body, headers)

  @doc """
  Creates a new response with status code 204
  """
  def no_content(body \\ "", headers \\ %{}), do: new(204, body, headers)
  def no_content!(body \\ "", headers \\ %{}), do: new!(204, body, headers)

  @doc """
  Creates a new response with status code 205
  """
  def reset_content(body \\ "", headers \\ %{}), do: new(205, body, headers)
  def reset_content!(body \\ "", headers \\ %{}), do: new!(205, body, headers)

  @doc """
  Creates a new response with status code 206
  """
  def partial_content(body \\ "", headers \\ %{}), do: new(206, body, headers)
  def partial_content!(body \\ "", headers \\ %{}), do: new!(206, body, headers)

  @doc """
  Returns a list with all 4xx HTTP methods available
  """
  def all_4xx do
    [
      bad_request!(),
      unauthorized!(),
      forbidden!(),
      not_found!(),
      method_not_allowed!(),
      not_acceptable!(),
      proxy_authentication_required!(),
      request_timeout!(),
      conflict!(),
      gone!(),
      length_required!(),
      precondition_failed!(),
      payload_too_large!(),
      uri_too_long!(),
      unsupported_media_type!(),
      expectation_failed!(),
      im_a_teapot!(),
      unprocessable_entity!(),
      locked!(),
      failed_dependency!(),
      upgrade_required!(),
      precondition_required!(),
      too_many_requests!(),
      request_header_fields_too_large!()
    ]
  end

  @doc """
  Creates a new response with status code 400
  """
  def bad_request(body \\ "", headers \\ %{}), do: new(400, body, headers)
  def bad_request!(body \\ "", headers \\ %{}), do: new!(400, body, headers)

  @doc """
  Creates a new response with status code 401
  """
  def unauthorized(body \\ "", headers \\ %{}), do: new(401, body, headers)
  def unauthorized!(body \\ "", headers \\ %{}), do: new!(401, body, headers)

  @doc """
  Creates a new response with status code 403
  """
  def forbidden(body \\ "", headers \\ %{}), do: new(403, body, headers)
  def forbidden!(body \\ "", headers \\ %{}), do: new!(403, body, headers)

  @doc """
  Creates a new response with status code 404
  """
  def not_found(body \\ "", headers \\ %{}), do: new(404, body, headers)
  def not_found!(body \\ "", headers \\ %{}), do: new!(404, body, headers)

  @doc """
  Creates a new response with status code 405
  """
  def method_not_allowed(body \\ "", headers \\ %{}), do: new(405, body, headers)
  def method_not_allowed!(body \\ "", headers \\ %{}), do: new!(405, body, headers)

  @doc """
  Creates a new response with status code 406
  """
  def not_acceptable(body \\ "", headers \\ %{}), do: new(406, body, headers)
  def not_acceptable!(body \\ "", headers \\ %{}), do: new!(406, body, headers)

  @doc """
  Creates a new response with status code 407
  """
  def proxy_authentication_required(body \\ "", headers \\ %{}), do: new(407, body, headers)
  def proxy_authentication_required!(body \\ "", headers \\ %{}), do: new!(407, body, headers)

  @doc """
  Creates a new response with status code 408
  """
  def request_timeout(body \\ "", headers \\ %{}), do: new(408, body, headers)
  def request_timeout!(body \\ "", headers \\ %{}), do: new!(408, body, headers)

  @doc """
  Creates a new response with status code 409
  """
  def conflict(body \\ "", headers \\ %{}), do: new(409, body, headers)
  def conflict!(body \\ "", headers \\ %{}), do: new!(409, body, headers)

  @doc """
  Creates a new response with status code 410
  """
  def gone(body \\ "", headers \\ %{}), do: new(410, body, headers)
  def gone!(body \\ "", headers \\ %{}), do: new!(410, body, headers)

  @doc """
  Creates a new response with status code 411
  """
  def length_required(body \\ "", headers \\ %{}), do: new(411, body, headers)
  def length_required!(body \\ "", headers \\ %{}), do: new!(411, body, headers)

  @doc """
  Creates a new response with status code 412
  """
  def precondition_failed(body \\ "", headers \\ %{}), do: new(412, body, headers)
  def precondition_failed!(body \\ "", headers \\ %{}), do: new!(412, body, headers)

  @doc """
  Creates a new response with status code 413
  """
  def payload_too_large(body \\ "", headers \\ %{}), do: new(413, body, headers)
  def payload_too_large!(body \\ "", headers \\ %{}), do: new!(413, body, headers)

  @doc """
  Creates a new response with status code 414
  """
  def uri_too_long(body \\ "", headers \\ %{}), do: new(414, body, headers)
  def uri_too_long!(body \\ "", headers \\ %{}), do: new!(414, body, headers)

  @doc """
  Creates a new response with status code 415
  """
  def unsupported_media_type(body \\ "", headers \\ %{}), do: new(415, body, headers)
  def unsupported_media_type!(body \\ "", headers \\ %{}), do: new!(415, body, headers)

  @doc """
  Creates a new response with status code 417
  """
  def expectation_failed(body \\ "", headers \\ %{}), do: new(417, body, headers)
  def expectation_failed!(body \\ "", headers \\ %{}), do: new!(417, body, headers)

  @doc """
  Creates a new response with status code 418
  """
  def im_a_teapot(body \\ "", headers \\ %{}), do: new(418, body, headers)
  def im_a_teapot!(body \\ "", headers \\ %{}), do: new!(418, body, headers)

  @doc """
  Creates a new response with status code 422
  """
  def unprocessable_entity(body \\ "", headers \\ %{}), do: new(422, body, headers)
  def unprocessable_entity!(body \\ "", headers \\ %{}), do: new!(422, body, headers)

  @doc """
  Creates a new response with status code 423
  """
  def locked(body \\ "", headers \\ %{}), do: new(423, body, headers)
  def locked!(body \\ "", headers \\ %{}), do: new!(423, body, headers)

  @doc """
  Creates a new response with status code 424
  """
  def failed_dependency(body \\ "", headers \\ %{}), do: new(424, body, headers)
  def failed_dependency!(body \\ "", headers \\ %{}), do: new!(424, body, headers)

  @doc """
  Creates a new response with status code 426
  """
  def upgrade_required(body \\ "", headers \\ %{}), do: new(426, body, headers)
  def upgrade_required!(body \\ "", headers \\ %{}), do: new!(426, body, headers)

  @doc """
  Creates a new response with status code 428
  """
  def precondition_required(body \\ "", headers \\ %{}), do: new(428, body, headers)
  def precondition_required!(body \\ "", headers \\ %{}), do: new!(428, body, headers)

  @doc """
  Creates a new response with status code 429
  """
  def too_many_requests(body \\ "", headers \\ %{}), do: new(429, body, headers)
  def too_many_requests!(body \\ "", headers \\ %{}), do: new!(429, body, headers)

  @doc """
  Creates a new response with status code 431
  """
  def request_header_fields_too_large(body \\ "", headers \\ %{}), do: new(431, body, headers)
  def request_header_fields_too_large!(body \\ "", headers \\ %{}), do: new!(431, body, headers)

  @doc """
  Returns a list with all 5xx HTTP methods available
  """
  def all_5xx do
    [
      internal_server_error!(),
      not_implemented!(),
      bad_gateway!(),
      service_unavailable!(),
      gateway_timeout!(),
      http_version_not_supported!(),
      variant_also_negotiates!(),
      insufficient_storage!(),
      not_extended!(),
      network_authentication_required!()
    ]
  end

  @doc """
  Creates a new response with status code 500
  """
  def internal_server_error(body \\ "", headers \\ %{}), do: new(500, body, headers)
  def internal_server_error!(body \\ "", headers \\ %{}), do: new!(500, body, headers)

  @doc """
  Creates a new response with status code 501
  """
  def not_implemented(body \\ "", headers \\ %{}), do: new(501, body, headers)
  def not_implemented!(body \\ "", headers \\ %{}), do: new!(501, body, headers)

  @doc """
  Creates a new response with status code 502
  """
  def bad_gateway(body \\ "", headers \\ %{}), do: new(502, body, headers)
  def bad_gateway!(body \\ "", headers \\ %{}), do: new!(502, body, headers)

  @doc """
  Creates a new response with status code 503
  """
  def service_unavailable(body \\ "", headers \\ %{}), do: new(503, body, headers)
  def service_unavailable!(body \\ "", headers \\ %{}), do: new!(503, body, headers)

  @doc """
  Creates a new response with status code 504
  """
  def gateway_timeout(body \\ "", headers \\ %{}), do: new(504, body, headers)
  def gateway_timeout!(body \\ "", headers \\ %{}), do: new!(504, body, headers)

  @doc """
  Creates a new response with status code 505
  """
  def http_version_not_supported(body \\ "", headers \\ %{}), do: new(505, body, headers)
  def http_version_not_supported!(body \\ "", headers \\ %{}), do: new!(505, body, headers)

  @doc """
  Creates a new response with status code 506
  """
  def variant_also_negotiates(body \\ "", headers \\ %{}), do: new(506, body, headers)
  def variant_also_negotiates!(body \\ "", headers \\ %{}), do: new!(506, body, headers)

  @doc """
  Creates a new response with status code 507
  """
  def insufficient_storage(body \\ "", headers \\ %{}), do: new(507, body, headers)
  def insufficient_storage!(body \\ "", headers \\ %{}), do: new!(507, body, headers)

  @doc """
  Creates a new response with status code 510
  """
  def not_extended(body \\ "", headers \\ %{}), do: new(510, body, headers)
  def not_extended!(body \\ "", headers \\ %{}), do: new!(510, body, headers)

  @doc """
  Creates a new response with status code 511
  """
  def network_authentication_required(body \\ "", headers \\ %{}), do: new(511, body, headers)
  def network_authentication_required!(body \\ "", headers \\ %{}), do: new!(511, body, headers)

  @doc """
  FakeServer default response. Used when there are no responses left to reply.
  """
  def default, do: new(200, ~s<{"message": "This is a default response from FakeServer"}>)
  def default!, do: new!(200, ~s<{"message": "This is a default response from FakeServer"}>)

  defp allowed_status_codes() do
    [
      100, 101, 102, 103, 200, 201, 202,
      203, 204, 205, 206, 300, 301, 302,
      303, 304, 305, 306, 307, 308, 400,
      401, 403, 404, 405, 406, 407, 408,
      409, 410, 411, 412, 413, 414, 415,
      417, 418, 422, 423, 424, 426, 428,
      429, 431, 500, 501, 502, 503, 504,
      505, 506, 507, 510, 511
    ]
  end

  defp ensure_body_format(%__MODULE__{body: body} = response) when is_bitstring(body), do: {:ok, response}
  defp ensure_body_format(%__MODULE__{body: body} = response) when is_map(body) do
    case Poison.encode(body) do
      {:ok, body} -> {:ok, %__MODULE__{response | body: body}}
      {:error, _} -> {:error, {body, "could not turn body map into json"}}
    end
  end

  defp ensure_headers_keys(%__MODULE__{headers: headers} = response) do
    valid? = headers
    |> Map.keys()
    |> Enum.all?(&(is_bitstring(&1)))

    if valid?, do: {:ok, response}, else: {:error, {headers, "all header keys must be strings"}}
  end
end
