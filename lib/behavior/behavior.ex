defmodule Fakex.Behavior do
  def begin do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end
end
