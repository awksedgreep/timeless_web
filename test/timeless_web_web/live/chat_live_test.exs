defmodule TimelessWebWeb.ChatLiveTest do
  use TimelessWebWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import TimelessWeb.AccountsFixtures

  test "authenticated users can post messages", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    {:ok, view, html} = live(conn, ~p"/chat")

    assert html =~ "Community chat."
    assert html =~ user.email

    view
    |> form("#chat-message-form", message: %{body: "ship it"})
    |> render_submit()

    rendered = render(view)
    assert rendered =~ "ship it"
    assert rendered =~ user.email
  end
end
