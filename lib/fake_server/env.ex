defmodule FakeServer.Env do
  @moduledoc false
  defstruct [ip: "127.0.0.1", port: nil]

  def new(port) do
    %FakeServer.Env{port: port}
  end
end
