# Phase 48 — Pattern Map

Analogs for executor `read_first` routing.

| Planned touch | Role | Closest analog | Excerpt / note |
|---------------|------|----------------|----------------|
| Dashboard KPI query | Read-heavy aggregate | `dashboard_stats/0` in `dashboard_live.ex` — `Repo.aggregate(WebhookEvent, ...)` | Same module, same `import Ecto.Query` style |
| Linked KPI card | HEEx + `KpiCard` | Existing webhook backlog block (`dashboard_kpi_webhook_backlog_*`) | `href` + `aria_label` + `ScopedPath.build/3` |
| Copy | SSOT strings | `Copy.dashboard_kpi_*` functions in `copy.ex` | Section comment `Operator dashboard (DashboardLive)` |
| LiveView test | Mount + HTML assert | `AccrueAdmin.DashboardLiveTest` | `live(conn, "/billing")`, `Copy.*` in assertions |
| Failed meter row | Fixture | `accrue/test/accrue/webhook/dispatch_worker_test.exs` — `MeterEvent.pending_changeset` → `failed_changeset` | Use `TestRepo` in admin test |

---

## PATTERN MAPPING COMPLETE
