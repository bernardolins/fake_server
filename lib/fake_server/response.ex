defmodule FakeServer.Response do
  @moduledoc """
  Response structure and helpers.

  FakeServer makes use of the `%FakeServer.Response{}` structure to define the responses that will be given by the server.

  ## Structure Fields

    - `:status`: The status code of the response. It must be an integer.
    - `:body`: Optional. The response body. Can be a string or a map. If the body is a map, it will be encoded so the map must be equivalent to a valid JSON.
    - `:headers`: Optional. The response headers. Must be a map with the string keys.

  You can use the `new/3` function to create a response. Since this function performs several validations, you should avoid to create the structure directly.
  """

  @enforce_keys [:status]
  defstruct status: nil, body: "", headers: %{}

  @doc """
  Creates a new Response structure. Returns `{:ok, response}` on success or `{:error, reason}` when validation fails

  ## Example
  ```elixir
  iex> FakeServer.Response.new(200, %{name: "Test User", email: "test_user@test.com"}, %{"Content-Type" => "application/json"})
  iex> FakeServer.Response.new(200, ~s<{"name":"Test User","email":"test_user@test.com"}>, %{"Content-Type" => "application/json"})
  iex> FakeServer.Response.new(201, ~s<{"name":"Test User","email":"test_user@test.com"}>)
  iex> FakeServer.Response.new(404)
  ```
  """
  def new(status_code, body \\ "", headers \\ %{}) do
    with response <- %__MODULE__{status: status_code, body: body, headers: headers},
         :ok <- validate(response),
         {:ok, response} <- ensure_body_format(response),
         {:ok, response} <- ensure_headers_keys(response) do
      {:ok, response}
    end
  end

  @doc """
  Similar to `new/3`, but raises `FakeServer.Error` when validation fails.
  """
  def new!(status_code, body \\ "", headers \\ %{}) do
    case new(status_code, body, headers) do
      {:ok, response} -> response
      {:error, reason} -> raise FakeServer.Error, reason
    end
  end

  @doc false
  def validate({:ok, %__MODULE__{} = response}), do: validate(response)

  def validate(%__MODULE__{body: body, status: status, headers: headers}) do
    cond do
      not is_map(headers) ->
        {:error, {headers, "response headers must be a map"}}

      not (is_bitstring(body) or is_map(body)) ->
        {:error, {body, "body must be a map or a string"}}

      not Enum.member?(allowed_status_codes(), status) ->
        {:error, {status, "invalid status code"}}

      true ->
        :ok
    end
  end

  def validate(response), do: {:error, {response, "invalid response type"}}

  @doc """
  Creates a new response with status 200

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def ok(body \\ "", headers \\ %{}), do: new(200, body, headers)

  @doc """
  Creates a new response with status 200 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def ok!(body \\ "", headers \\ %{}), do: new!(200, body, headers)

  @doc """
  Creates a new response with status 201

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def created(body \\ "", headers \\ %{}), do: new(201, body, headers)

  @doc """
  Creates a new response with status 201 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def created!(body \\ "", headers \\ %{}), do: new!(201, body, headers)

  @doc """
  Creates a new response with status 202

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def accepted(body \\ "", headers \\ %{}), do: new(202, body, headers)

  @doc """
  Creates a new response with status 202 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def accepted!(body \\ "", headers \\ %{}), do: new!(202, body, headers)

  @doc """
  Creates a new response with status 203.

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def non_authoritative_information(body \\ "", headers \\ %{}), do: new(203, body, headers)

  @doc """
  Creates a new response with status 203 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def non_authoritative_information!(body \\ "", headers \\ %{}), do: new!(203, body, headers)

  @doc """
  Creates a new response with status 204

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def no_content(body \\ "", headers \\ %{}), do: new(204, body, headers)

  @doc """
  Creates a new response with status 204 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def no_content!(body \\ "", headers \\ %{}), do: new!(204, body, headers)

  @doc """
  Creates a new response with status 205

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def reset_content(body \\ "", headers \\ %{}), do: new(205, body, headers)

  @doc """
  Creates a new response with status 205 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def reset_content!(body \\ "", headers \\ %{}), do: new!(205, body, headers)

  @doc """
  Creates a new response with status 206

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def partial_content(body \\ "", headers \\ %{}), do: new(206, body, headers)

  @doc """
    Creates a new response with status 206 and returns it.

    Raises `FakeServer.Error` if the validation fails.
  """
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
  Similar to `all_4xx/0`, but excludes the status codes in parameter.
  """
  def all_4xx(except: except) do
    all_4xx() |> Enum.reject(&Enum.member?(except, &1.status))
  end

  @doc """
  Creates a new response with status 400

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def bad_request(body \\ "", headers \\ %{}), do: new(400, body, headers)

  @doc """
  Creates a new response with status 400 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def bad_request!(body \\ "", headers \\ %{}), do: new!(400, body, headers)

  @doc """
  Creates a new response with status 401

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def unauthorized(body \\ "", headers \\ %{}), do: new(401, body, headers)

  @doc """
  Creates a new response with status 401 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def unauthorized!(body \\ "", headers \\ %{}), do: new!(401, body, headers)

  @doc """
  Creates a new response with status 403

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def forbidden(body \\ "", headers \\ %{}), do: new(403, body, headers)

  @doc """
  Creates a new response with status 403 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def forbidden!(body \\ "", headers \\ %{}), do: new!(403, body, headers)

  @doc """
  Creates a new response with status 404

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def not_found(body \\ "", headers \\ %{}), do: new(404, body, headers)

  @doc """
  Creates a new response with status 404 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def not_found!(body \\ "", headers \\ %{}), do: new!(404, body, headers)

  @doc """
  Creates a new response with status 405

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def method_not_allowed(body \\ "", headers \\ %{}), do: new(405, body, headers)

  @doc """
  Creates a new response with status 405 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def method_not_allowed!(body \\ "", headers \\ %{}), do: new!(405, body, headers)

  @doc """
  Creates a new response with status 406

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def not_acceptable(body \\ "", headers \\ %{}), do: new(406, body, headers)

  @doc """
  Creates a new response with status 406 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def not_acceptable!(body \\ "", headers \\ %{}), do: new!(406, body, headers)

  @doc """
  Creates a new response with status 407

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def proxy_authentication_required(body \\ "", headers \\ %{}), do: new(407, body, headers)

  @doc """
  Creates a new response with status 407 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def proxy_authentication_required!(body \\ "", headers \\ %{}), do: new!(407, body, headers)

  @doc """
  Creates a new response with status 408

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.

  """
  def request_timeout(body \\ "", headers \\ %{}), do: new(408, body, headers)

  @doc """
  Creates a new response with status 408 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def request_timeout!(body \\ "", headers \\ %{}), do: new!(408, body, headers)

  @doc """
  Creates a new response with status 409

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def conflict(body \\ "", headers \\ %{}), do: new(409, body, headers)

  @doc """
  Creates a new response with status 409 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def conflict!(body \\ "", headers \\ %{}), do: new!(409, body, headers)

  @doc """
  Creates a new response with status 410

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def gone(body \\ "", headers \\ %{}), do: new(410, body, headers)

  @doc """
  Creates a new response with status 410 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def gone!(body \\ "", headers \\ %{}), do: new!(410, body, headers)

  @doc """
  Creates a new response with status 411

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def length_required(body \\ "", headers \\ %{}), do: new(411, body, headers)

  @doc """
  Creates a new response with status 411 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def length_required!(body \\ "", headers \\ %{}), do: new!(411, body, headers)

  @doc """
  Creates a new response with status 412

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def precondition_failed(body \\ "", headers \\ %{}), do: new(412, body, headers)

  @doc """
  Creates a new response with status 412 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def precondition_failed!(body \\ "", headers \\ %{}), do: new!(412, body, headers)

  @doc """
  Creates a new response with status 413

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def payload_too_large(body \\ "", headers \\ %{}), do: new(413, body, headers)

  @doc """
  Creates a new response with status 413 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def payload_too_large!(body \\ "", headers \\ %{}), do: new!(413, body, headers)

  @doc """
  Creates a new response with status 414

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def uri_too_long(body \\ "", headers \\ %{}), do: new(414, body, headers)

  @doc """
  Creates a new response with status 414 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def uri_too_long!(body \\ "", headers \\ %{}), do: new!(414, body, headers)

  @doc """
  Creates a new response with status 415

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def unsupported_media_type(body \\ "", headers \\ %{}), do: new(415, body, headers)

  @doc """
  Creates a new response with status 415 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def unsupported_media_type!(body \\ "", headers \\ %{}), do: new!(415, body, headers)

  @doc """
  Creates a new response with status 417

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def expectation_failed(body \\ "", headers \\ %{}), do: new(417, body, headers)

  @doc """
  Creates a new response with status 417 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def expectation_failed!(body \\ "", headers \\ %{}), do: new!(417, body, headers)

  @doc """
  Creates a new response with status 418

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def im_a_teapot(body \\ "", headers \\ %{}), do: new(418, body, headers)

  @doc """
  Creates a new response with status 418 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def im_a_teapot!(body \\ "", headers \\ %{}), do: new!(418, body, headers)

  @doc """
  Creates a new response with status 422

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def unprocessable_entity(body \\ "", headers \\ %{}), do: new(422, body, headers)

  @doc """
  Creates a new response with status 422 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def unprocessable_entity!(body \\ "", headers \\ %{}), do: new!(422, body, headers)

  @doc """
  Creates a new response with status 423

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def locked(body \\ "", headers \\ %{}), do: new(423, body, headers)

  @doc """
  Creates a new response with status 423 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def locked!(body \\ "", headers \\ %{}), do: new!(423, body, headers)

  @doc """
  Creates a new response with status 424

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def failed_dependency(body \\ "", headers \\ %{}), do: new(424, body, headers)

  @doc """
  Creates a new response with status 424 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def failed_dependency!(body \\ "", headers \\ %{}), do: new!(424, body, headers)

  @doc """
  Creates a new response with status 426

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def upgrade_required(body \\ "", headers \\ %{}), do: new(426, body, headers)

  @doc """
  Creates a new response with status 426 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def upgrade_required!(body \\ "", headers \\ %{}), do: new!(426, body, headers)

  @doc """
  Creates a new response with status 428

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def precondition_required(body \\ "", headers \\ %{}), do: new(428, body, headers)

  @doc """
  Creates a new response with status 428 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def precondition_required!(body \\ "", headers \\ %{}), do: new!(428, body, headers)

  @doc """
  Creates a new response with status 429

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def too_many_requests(body \\ "", headers \\ %{}), do: new(429, body, headers)

  @doc """
  Creates a new response with status 429 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def too_many_requests!(body \\ "", headers \\ %{}), do: new!(429, body, headers)

  @doc """
  Creates a new response with status 431

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def request_header_fields_too_large(body \\ "", headers \\ %{}), do: new(431, body, headers)

  @doc """
  Creates a new response with status 431 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def request_header_fields_too_large!(body \\ "", headers \\ %{}), do: new!(431, body, headers)

  @doc """
  Returns a list with all 5xx HTTP methods available.
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
  Similar to `all_5xx/0`, but excludes the status codes in parameter.
  """
  def all_5xx(except: except) do
    all_5xx() |> Enum.reject(&Enum.member?(except, &1.status))
  end

  @doc """
  Creates a new response with status 500

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def internal_server_error(body \\ "", headers \\ %{}), do: new(500, body, headers)

  @doc """
  Creates a new response with status 500 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def internal_server_error!(body \\ "", headers \\ %{}), do: new!(500, body, headers)

  @doc """
  Creates a new response with status 501

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def not_implemented(body \\ "", headers \\ %{}), do: new(501, body, headers)

  @doc """
  Creates a new response with status 501 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def not_implemented!(body \\ "", headers \\ %{}), do: new!(501, body, headers)

  @doc """
  Creates a new response with status 502

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def bad_gateway(body \\ "", headers \\ %{}), do: new(502, body, headers)

  @doc """
  Creates a new response with status 502 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def bad_gateway!(body \\ "", headers \\ %{}), do: new!(502, body, headers)

  @doc """
  Creates a new response with status 503

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def service_unavailable(body \\ "", headers \\ %{}), do: new(503, body, headers)

  @doc """
  Creates a new response with status 503 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def service_unavailable!(body \\ "", headers \\ %{}), do: new!(503, body, headers)

  @doc """
  Creates a new response with status 504

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def gateway_timeout(body \\ "", headers \\ %{}), do: new(504, body, headers)

  @doc """
  Creates a new response with status 504 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def gateway_timeout!(body \\ "", headers \\ %{}), do: new!(504, body, headers)

  @doc """
  Creates a new response with status 505

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def http_version_not_supported(body \\ "", headers \\ %{}), do: new(505, body, headers)

  @doc """
  Creates a new response with status 505 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def http_version_not_supported!(body \\ "", headers \\ %{}), do: new!(505, body, headers)

  @doc """
  Creates a new response with status 506

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def variant_also_negotiates(body \\ "", headers \\ %{}), do: new(506, body, headers)

  @doc """
  Creates a new response with status 506 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def variant_also_negotiates!(body \\ "", headers \\ %{}), do: new!(506, body, headers)

  @doc """
  Creates a new response with status 507

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def insufficient_storage(body \\ "", headers \\ %{}), do: new(507, body, headers)

  @doc """
  Creates a new response with status 507 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def insufficient_storage!(body \\ "", headers \\ %{}), do: new!(507, body, headers)

  @doc """
  Creates a new response with status 510

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def not_extended(body \\ "", headers \\ %{}), do: new(510, body, headers)

  @doc """
  Creates a new response with status 510 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def not_extended!(body \\ "", headers \\ %{}), do: new!(510, body, headers)

  @doc """
  Creates a new response with status 511

  Returns `{:ok, response}` tuple on succes and `{:error, reason}` when validation fails.
  """
  def network_authentication_required(body \\ "", headers \\ %{}), do: new(511, body, headers)

  @doc """
  Creates a new response with status 511 and returns it.

  Raises `FakeServer.Error` if the validation fails.
  """
  def network_authentication_required!(body \\ "", headers \\ %{}), do: new!(511, body, headers)

  @doc """
  FakeServer default response. Used when there are no responses left to reply.

  ```
  iex> FakeServer.Response.default()
  {:ok,
    %FakeServer.Response{
      body: "{\"message\": \"This is a default response from FakeServer\"}",
      headers: %{},
      status: 200
    }
  }
  ```
  """
  def default, do: new(200, ~s<{"message": "This is a default response from FakeServer"}>)

  @doc """
  Similar to `default/0`.
  """
  def default!, do: new!(200, ~s<{"message": "This is a default response from FakeServer"}>)

  defp allowed_status_codes() do
    [
      100,
      101,
      102,
      103,
      200,
      201,
      202,
      203,
      204,
      205,
      206,
      300,
      301,
      302,
      303,
      304,
      305,
      306,
      307,
      308,
      400,
      401,
      403,
      404,
      405,
      406,
      407,
      408,
      409,
      410,
      411,
      412,
      413,
      414,
      415,
      417,
      418,
      422,
      423,
      424,
      426,
      428,
      429,
      431,
      500,
      501,
      502,
      503,
      504,
      505,
      506,
      507,
      510,
      511
    ]
  end

  defp ensure_body_format(%__MODULE__{body: body} = response) when is_bitstring(body),
    do: {:ok, response}

  defp ensure_body_format(%__MODULE__{body: body} = response) when is_map(body) do
    case Poison.encode(body) do
      {:ok, body} -> {:ok, %__MODULE__{response | body: body}}
      {:error, _} -> {:error, {body, "could not turn body map into json"}}
    end
  end

  defp ensure_headers_keys(%__MODULE__{headers: headers} = response) do
    valid? =
      headers
      |> Map.keys()
      |> Enum.all?(&is_bitstring(&1))

    if valid?, do: {:ok, response}, else: {:error, {headers, "all header keys must be strings"}}
  end
end
