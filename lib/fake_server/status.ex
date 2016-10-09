defmodule FakeServer.Status do
  @moduledoc """
  Provides an interface to create and destroy status.

  The status must have:
  * a `name`
  * some `config`. Currently `response_code` and `response_body` are mandatory parameters on the config.
  """

  @doc """
  This function destroys all Status. Since status are reusable entities, there makes no sense to destroy only one of them.
  You should use this function when you want to perform a cleanup.

  ### Examples
  ```elixir
  FakeServer.Status.destroy_all
  :ok
  ```

  If there are no status, this function will return an error:

  ```elixir
  FakeServer.Status.destroy_all
  {:error, :no_status_to_destroy}
  ```
  """
  def destroy_all do
    case Process.whereis(__MODULE__) do
      nil -> {:error, :no_status_to_destroy}
      _ ->
        Agent.stop(__MODULE__)
        :ok
    end
  end


  @doc """
  This function creates a new status.

  ### Parameters
  - `name`: The name must be an atom. This name identifies the status on `FakeServer.run/2` or `FakeServer.run/3`.
  - `status`: The atributes of the status. This represents the response of the fake server when a request arrives. Currently, the following options are accepted:
    - `response_code`: This parameter is **mandatory**. This is the code the fake server will respond with. Must be a valid http response code, like 200, 400 or 500.
    - `response_body`: This parameter is **mandatory**. This is the body of the response of the fake server. Can be any valid http body, like a plain text or a JSON.


  ### Return values
  If everything is ok, this function will return `:ok`. Otherwise, it will return an error and the reason.

  ### Examples
  ```elixir
  FakeServer.Status.create(:status200,
                           %{response_code: 200, response_body: ~s<"username": "mr_user">})
  :ok
  FakeServer.Status.create(:status500,
                           %{response_code: 500, response_body: ~s<"error": "internal server error">})
  :ok
  FakeServer.Status.create(:status403,
                           %{response_code: 403, response_body: ~s<"error": "forbidden">})
  :ok
  FakeServer.Status.create(:status200,
                           %{response_code: 200, response_body: ~s<"username": "mr_user">, response_headers: %{"Content-Length": 5}})
  :ok
  ```
  """
  def create(name, status = %{response_code: _code, response_body: _body, response_headers: _headers}) do
    status = Map.update!(status, :response_headers, &(Map.to_list/1))
    name
    |> validate_name
    |> check_server_and_add(status)
  end
  def create(name, _status = %{response_code: code, response_body: body}) do
    create(name, %{response_code: code, response_body: body, response_headers: %{}})
  end
  def create(_name, %{response_body: _body}) do
    {:error, :response_code_not_provided}
  end
  def create(_name, %{response_code: _code}) do
    {:error, :response_body_not_provided}
  end
  @doc false
  def create(_status) do
    {:error, :name_not_provided}
  end

  @doc false
  def get do
    {:ok, Agent.get(__MODULE__, fn(status_list) -> status_list end)}
  end

  @doc false
  def get(name) do
    status = Agent.get(__MODULE__, fn(status_list) -> Keyword.get(status_list, name) end)
    case status do
      nil -> {:error, :not_found}
      _ -> {:ok, status}
    end
  end

  @doc false
  def validate_name(name) do
    case is_atom(name) do
      true -> name
      false -> {:error, {:invalid_status_name, name}}
    end
  end

  defp check_server_and_add({:error, {:invalid_status_name, name}}, _status), do: {:error, {:invalid_status_name, name}}
  defp check_server_and_add(name, status) do
    case start_server do
      {:ok, :up} -> add_status(name, status)
      {:error, reason} -> {:error, reason}
    end
  end

  defp start_server do
    case Agent.start_link(fn -> [] end, name: __MODULE__) do
      {:ok, _} -> {:ok, :up}
      {:error, {:already_started, _}} -> {:ok, :up}
      {:error, reason} -> {:error, reason}
    end
  end

  defp add_status(name, status) do
    case is_atom name do
      true ->
        Agent.update(__MODULE__, fn(status_list) -> Keyword.put(status_list, name, status) end)
        :ok
      false -> {:error, :invalid_name}
    end
  end
end
