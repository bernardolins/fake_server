defmodule FakeServer.Specs.PathSpec do
  @moduledoc false

  defstruct [controller: nil, response_list: [], hits: 0, response: nil]

  alias FakeServer.Specs.PathSpec

  def new do
    %PathSpec{}
  end

  def response_list(%PathSpec{} = spec) do
    spec.response_list
  end

  def response(%PathSpec{} = spec) do
    spec.response
  end

  def configure_response(%PathSpec{} = spec, new_response) do
    %PathSpec{spec | response: new_response}
  end

  def configure_response_list(%PathSpec{} = spec, new_response_list) do
    %PathSpec{spec | response_list: new_response_list}
  end

  def controller(%PathSpec{} = spec) do
    spec.controller
  end

  def configure_controller(%PathSpec{} = spec, new_controller) do
    %PathSpec{spec | controller: new_controller}
  end
end
