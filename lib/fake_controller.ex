defmodule FakeController do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      def use_controller(controller_name) do
        function_name = "#{to_string(controller_name)}_controller" |> String.to_atom
        [module: __MODULE__, function: function_name]
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def use_controller(controller_name) do
        raise "Invalid controller #{controller_name}"
      end
    end
  end
end
