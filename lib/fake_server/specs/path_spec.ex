defmodule FakeServer.Specs.PathSpec do
  @moduledoc false

  defstruct [hits: 0, response: nil]

  alias FakeServer.Specs.PathSpec

  def new do
    %PathSpec{}
  end

  def response(%PathSpec{} = spec) do
    spec.response
  end

  def configure_response(%PathSpec{} = spec, new_response) do
    %PathSpec{spec | response: new_response}
  end
end
