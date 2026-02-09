defmodule TimelessWebWeb.BackupController do
  use TimelessWebWeb, :controller

  def download(conn, %{"name" => name}) do
    base_dir = backup_base_dir()
    backup_path = Path.join(base_dir, name)

    cond do
      not Regex.match?(~r/\A[\w\-]+\z/, name) ->
        conn |> put_status(:bad_request) |> text("Invalid backup name")

      not File.dir?(backup_path) ->
        conn |> put_status(:not_found) |> text("Backup not found")

      true ->
        send_tar(conn, name, backup_path)
    end
  end

  defp send_tar(conn, name, backup_path) do
    tar_filename = "timeless_backup_#{name}.tar.gz"
    {:ok, files} = File.ls(backup_path)

    tar_entries =
      Enum.map(files, fn file ->
        full_path = Path.join(backup_path, file)
        {String.to_charlist(file), File.read!(full_path)}
      end)

    tmp_path = Path.join(System.tmp_dir!(), tar_filename)

    try do
      :ok = :erl_tar.create(String.to_charlist(tmp_path), tar_entries, [:compressed])
      tar_binary = File.read!(tmp_path)

      conn
      |> put_resp_content_type("application/gzip")
      |> put_resp_header("content-disposition", ~s(attachment; filename="#{tar_filename}"))
      |> send_resp(200, tar_binary)
    after
      File.rm(tmp_path)
    end
  end

  defp backup_base_dir do
    data_dir = Application.get_env(:timeless_web, :timeless_data_dir, "/tmp/timeless_dev")
    Path.join(data_dir, "backups")
  end
end
