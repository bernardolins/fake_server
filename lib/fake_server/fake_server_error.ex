defmodule FakeServer.Error do
  @message_template "FakeServer Error"

  defexception message: @message_template

  def exception({param, reason}) do
    message = "#{inspect param}: #{reason}"
    %__MODULE__{message: message}
  end

  def exception(reason) when is_bitstring(reason) do
    %__MODULE__{message: reason}
  end

  def exception(_) do
    %__MODULE__{}
  end
end
