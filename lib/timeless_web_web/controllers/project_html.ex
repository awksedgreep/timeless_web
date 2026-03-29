defmodule TimelessWebWeb.ProjectHTML do
  use TimelessWebWeb, :html

  def markdown(text), do: Phoenix.HTML.raw(Earmark.as_html!(text))

  def project_tone("timeless-phoenix"), do: "project-pill-azure"
  def project_tone("timeless-stack"), do: "project-pill-violet"
  def project_tone("timeless-metrics"), do: "project-pill-teal"
  def project_tone("timeless-logs"), do: "project-pill-coral"
  def project_tone("timeless-traces"), do: "project-pill-violet"
  def project_tone(_slug), do: "project-pill-neutral"

  embed_templates "project_html/*"
end
