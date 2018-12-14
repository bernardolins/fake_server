defmodule FakeServer.Error do
  @message_template "FakeServer Error"

  defexception message: @message_template

  def exception({param, reason}) do
    message = "#{inspect param}: #{reason}"
    %__MODULE__{message: message}
  end
end
