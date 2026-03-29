defmodule TimelessWeb.ChatTest do
  use TimelessWeb.DataCase, async: false

  alias TimelessWeb.Chat

  import TimelessWeb.AccountsFixtures

  test "creates a message and trims body" do
    user = user_fixture()

    assert {:ok, message} = Chat.create_message(user, %{body: "  hello builders  "})
    assert message.body == "hello builders"
    assert message.user.id == user.id
  end

  test "rejects blank messages" do
    user = user_fixture()

    assert {:error, changeset} = Chat.create_message(user, %{body: "   "})
    assert "can't be blank" in errors_on(changeset).body
  end
end
