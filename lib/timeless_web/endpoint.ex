defmodule TimelessWeb.Endpoint do
  defdelegate broadcast(topic, event, payload), to: TimelessWebWeb.Endpoint
  defdelegate config(key), to: TimelessWebWeb.Endpoint
end
