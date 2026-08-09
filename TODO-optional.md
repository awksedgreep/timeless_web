# Optional feature ideas

Things an earlier version of this app had that the current one does not. These
are **ideas to build fresh**, not code to restore — the old implementations
targeted a v0.8.0 codebase from February with different dependency versions and
the pre-libSQL storage engines, so none of it would port cleanly.

Listed roughly by apparent value. Several probably should not be built here at
all; the notes say where something likely belongs elsewhere or already exists.

| Idea | Notes |
|---|---|
| **Interactive Explorer** | Ad-hoc query and browse UI over the stores. The strongest candidate: nothing in the current stack covers exploratory querying. |
| **Backup UI** | Trigger and monitor backups from the web UI. Today this is the manual volume-tarball procedure in `deploy/DEPLOYMENT.md`, which is easy to skip — worth automating regardless of whether it gets a UI. |
| **Schema browser** | Browse metric names, label keys and values, and series cardinality. No current equivalent, and cardinality visibility would have helped diagnose the per-series distribution questions. |
| **Annotations** | Mark deploys and incidents on charts. No current equivalent. |
| Alerts | Check `timeless_metrics` first — it already has alerting. Likely duplication rather than a gap. |
| Health view | Overlaps the existing doctor and preflight checks. Probably better as an addition to those than a separate page. |
| Metrics view | Superseded by `timeless_metrics_dashboard`. |
| Dashboard | Superseded by the LiveDashboard pages. |
| Store watcher | Watched the on-disk store for changes. Predates libSQL and would need a completely different design now. |

## Background

The repository previously carried two unrelated lineages: a `main` that stopped
at v0.8.0 in February, and `master`, a later rewrite that is what production
runs. Keeping both invited pulling or deploying the wrong one, which happened
more than once. On 2026-08-09 the stale lineage was deleted and `master` was
renamed to `main`, leaving one branch.

The old code is gone deliberately. It targeted different dependency versions
and the pre-libSQL storage engines, so it was never a realistic base to merge
from — and a branch nobody will merge is just something else to trip over. What
was worth keeping is the list above.
