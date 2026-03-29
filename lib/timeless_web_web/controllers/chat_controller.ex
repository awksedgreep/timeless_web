defmodule TimelessWeb.ChatController do
  use TimelessWeb, :controller

  def show(conn, _params) do
    Phoenix.LiveView.Controller.live_render(conn, TimelessWebWeb.ChatLive,
      session: %{"user_token" => get_session(conn, :user_token)}
    )
  end
end
