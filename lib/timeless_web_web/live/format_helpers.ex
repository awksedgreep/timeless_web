defmodule TimelessWebWeb.FormatHelpers do
  @moduledoc """
  Shared formatting helpers for Timeless LiveView pages.
  """

  def format_number(n) when is_integer(n) and n >= 1_000_000 do
    "#{Float.round(n / 1_000_000, 1)}M"
  end

  def format_number(n) when is_integer(n) and n >= 1_000 do
    "#{Float.round(n / 1_000, 1)}K"
  end

  def format_number(n), do: to_string(n)

  def format_bytes(bytes) when bytes >= 1_073_741_824 do
    "#{Float.round(bytes / 1_073_741_824, 1)} GB"
  end

  def format_bytes(bytes) when bytes >= 1_048_576 do
    "#{Float.round(bytes / 1_048_576, 1)} MB"
  end

  def format_bytes(bytes) when bytes >= 1024 do
    "#{Float.round(bytes / 1024, 1)} KB"
  end

  def format_bytes(bytes), do: "#{bytes} B"

  def format_duration(:forever), do: "forever"
  def format_duration(:infinity), do: "forever"
  def format_duration(seconds) when seconds >= 86400, do: pluralize(div(seconds, 86400), "day")
  def format_duration(seconds) when seconds >= 3600, do: pluralize(div(seconds, 3600), "hour")
  def format_duration(seconds) when seconds >= 60, do: pluralize(div(seconds, 60), "minute")
  def format_duration(seconds), do: pluralize(seconds, "second")

  def format_duration_ms(ms), do: format_duration(div(ms, 1000))

  defp pluralize(1, unit), do: "1 #{unit}"
  defp pluralize(n, unit), do: "#{n} #{unit}s"

  def format_value(nil), do: "—"
  def format_value(v) when is_float(v), do: Float.round(v, 2) |> to_string()
  def format_value(v), do: to_string(v)

  def format_timestamp(nil), do: "—"

  def format_timestamp(ts) when is_integer(ts) do
    ts
    |> DateTime.from_unix!()
    |> Calendar.strftime("%Y-%m-%d %H:%M")
  end
end
