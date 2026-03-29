defmodule TimelessWebWeb.AdminControllerTest do
  use TimelessWebWeb.ConnCase, async: true

  import TimelessWeb.AccountsFixtures

  test "redirects guests away from admin", %{conn: conn} do
    conn = get(conn, ~p"/admin")

    assert redirected_to(conn) == ~p"/users/log-in"
  end

  test "redirects non-admin users away from admin", %{conn: conn} do
    user = user_fixture()
    conn = conn |> log_in_user(user) |> get(~p"/admin")

    assert redirected_to(conn) == ~p"/"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "admin"
  end

  test "allows admins into admin pages", %{conn: conn} do
    {:ok, admin} = TimelessWeb.Accounts.promote_user_to_admin(unique_user_email())
    conn = conn |> log_in_user(admin) |> get(~p"/admin")

    assert html_response(conn, 200) =~ "Content and project controls."
  end
end
