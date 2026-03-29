defmodule TimelessWebWeb.AdminProjectHTML do
  use TimelessWebWeb, :html

  def project_tone("timeless-phoenix"), do: "project-pill-azure"
  def project_tone("timeless-stack"), do: "project-pill-violet"
  def project_tone("timeless-metrics"), do: "project-pill-teal"
  def project_tone("timeless-logs"), do: "project-pill-coral"
  def project_tone("timeless-traces"), do: "project-pill-violet"
  def project_tone(_slug), do: "project-pill-neutral"

  embed_templates "admin_project_html/*"
end
