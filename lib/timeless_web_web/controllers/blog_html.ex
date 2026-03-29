defmodule TimelessWebWeb.BlogHTML do
  use TimelessWebWeb, :html

  def markdown(text), do: Phoenix.HTML.raw(Earmark.as_html!(text))

  embed_templates "blog_html/*"
end
