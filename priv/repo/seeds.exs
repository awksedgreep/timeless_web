alias TimelessWeb.Repo
alias TimelessWeb.Accounts
alias TimelessWeb.Site.Post
alias TimelessWeb.Site.Project

posts = [
  %{
    title: "Why Timeless starts inside your Phoenix app",
    slug: "why-timeless-starts-inside-your-phoenix-app",
    summary:
      "A note on why embedded observability is the right first move for small teams and product engineers.",
    body_md: """
    Timeless starts with a simple bias: **the fastest way to trust observability is to run it in the same app you are already shipping**.

    That gives you a shorter path from "something feels off" to "I can inspect metrics, logs, and traces right now" without standing up a separate platform on day one.

    ## The shape

    - `timeless_phoenix` embeds persistent metrics, logs, and traces in a Phoenix application.
    - `timeless_stack` is the path for central ingestion when you outgrow single-app deployment.
    - This site uses the embedded model on purpose so the public dashboard can double as a living product demo.
    """,
    published_on: ~D[2026-03-28],
    featured: true
  },
  %{
    title: "Public dashboards, private collaboration",
    slug: "public-dashboards-private-collaboration",
    summary:
      "Why the site keeps observability open while reserving chat and moderation features for authenticated users.",
    body_md: """
    The dashboard is part documentation, part proof, and part invitation.

    Anyone should be able to open the page, see the system moving, and understand what the stack does. Chat is a different surface. It needs moderation, user context, and better social tooling than a marketing site needs on day one.

    That is why this first version keeps:

    - dashboards public
    - docs public
    - chat behind authentication
    """,
    published_on: ~D[2026-03-27],
    featured: false
  },
  %{
    title: "SQLite is enough for the website",
    slug: "sqlite-is-enough-for-the-website",
    summary:
      "The product stack is ambitious; the website persistence layer should stay boring and dependable.",
    body_md: """
    The website does not need a heavyweight database. It needs simple content storage, user auth, and a reliable local development story.

    SQLite fits that job well:

    - no separate service to provision
    - easy local setup
    - good enough for posts, projects, and lightweight community features

    We can always revisit it later if the site itself turns into a larger product surface.
    """,
    published_on: ~D[2026-03-26],
    featured: false
  }
]

projects = [
  %{
    name: "timeless_phoenix",
    slug: "timeless-phoenix",
    tagline: "Embed observability directly into Phoenix.",
    summary:
      "One dependency, one child spec, one dashboard route for persistent metrics, logs, and traces.",
    description_md: """
    `timeless_phoenix` is the fastest way to get the Timeless stack running.

    It mounts the dashboard pages inside Phoenix LiveDashboard, exports OpenTelemetry spans to TimelessTraces, and keeps metric history available across restarts.
    """,
    repo_url: "https://github.com/awksedgreep/timeless_phoenix",
    docs_url: "https://hexdocs.pm/timeless_phoenix",
    featured: true,
    sort_order: 10
  },
  %{
    name: "timeless_stack",
    slug: "timeless-stack",
    tagline: "Push metrics to a central server when the topology grows.",
    summary:
      "A central deployment target for teams that want shared observability infrastructure and eventually managed workflows.",
    description_md: """
    `timeless_stack` is the next step when local embedding is no longer enough.

    It is designed to collect and serve telemetry centrally while preserving the same product philosophy: durable data, practical workflows, and a path toward a hosted cloud offering.
    """,
    repo_url: "https://github.com/awksedgreep/timeless_stack",
    featured: true,
    sort_order: 20
  },
  %{
    name: "timeless_metrics",
    slug: "timeless-metrics",
    tagline: "The compressed time-series engine under the hood.",
    summary:
      "Durable metric storage optimized for historical queries, retention, and compact persistence.",
    description_md: """
    `timeless_metrics` is the storage layer that gives Timeless its historical memory.

    It powers the persistent charts in the dashboard and is the base primitive for the embedded observability story.
    """,
    repo_url: "https://github.com/awksedgreep/timeless_metrics",
    docs_url: "https://hexdocs.pm/timeless_metrics",
    featured: false,
    sort_order: 30
  }
]

Enum.each(posts, fn attrs ->
  Repo.insert!(
    Post.changeset(
      Repo.get_by(Post, slug: attrs.slug) || %Post{},
      attrs
    ),
    on_conflict: {:replace_all_except, [:id, :inserted_at]},
    conflict_target: :slug
  )
end)

Enum.each(projects, fn attrs ->
  Repo.insert!(
    Project.changeset(
      Repo.get_by(Project, slug: attrs.slug) || %Project{},
      attrs
    ),
    on_conflict: {:replace_all_except, [:id, :inserted_at]},
    conflict_target: :slug
  )
end)

{:ok, _admin} = Accounts.promote_user_to_admin("mark.cotner@diablodata.com")
