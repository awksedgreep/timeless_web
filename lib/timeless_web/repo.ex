defmodule TimelessWeb.Repo do
  use Ecto.Repo,
    otp_app: :timeless_web,
    adapter: Ecto.Adapters.SQLite3
end
