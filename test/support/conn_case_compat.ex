defmodule TimelessWeb.ConnCase do
  defmacro __using__(opts) do
    quote do
      use TimelessWebWeb.ConnCase, unquote(opts)
    end
  end
end
