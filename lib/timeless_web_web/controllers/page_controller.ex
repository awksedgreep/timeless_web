defmodule TimelessWebWeb.PageController do
  use TimelessWebWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/timeless")
  end
end
