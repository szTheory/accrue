# Phase 48 — Technical Research

**Question:** What do we need to know to plan **ADM-01** (metering-adjacent admin home signal) well?

**Sources:** `48-CONTEXT.md`, `48-UI-SPEC.md`, `dashboard_live.ex`, `MeterEvent` schema, existing dashboard tests, Phase 44/45 metering docs.

---

## 1. Aggregate choice (CONTEXT D-01..D-04)

- **`accrue_meter_events.stripe_status == "failed"`** is the durable terminal state after first failure (sync) or meter error webhook (Phase 44). Matches `[:accrue, :ops, :meter_reporting_failed]` narrative: **first transition to failed**, not retry volume.
- **`pending` count** is a poor KPI: healthy in-flight `report_usage` traffic also uses `pending` → alert fatigue if surfaced as red.
- **Query shape:** `import Ecto.Query` + `from(m in MeterEvent, where: m.stripe_status == "failed") |> Repo.aggregate(:count, :id)` mirrors existing `dashboard_stats/0` (`Repo.aggregate` on `WebhookEvent`, `Event`, etc.). No `Repo.all` + `length/1`.
- **Org / owner scope:** Current `dashboard_stats/0` has **no** `OwnerScope` filter — global `Repo` counts for the mounted admin DB (same as Customers / webhooks KPIs). New count follows that pattern unless a separate initiative adds tenant isolation to the dashboard (out of scope for 48).

## 2. Deep link honesty (CONTEXT D-05..D-07)

- **`/events`** via `ScopedPath.build(@admin_mount_path, "/events", @current_owner_scope)` is the locked target: event **ledger** surface, not a row-filtered view of meter failures. Copy + `aria_label` must **not** claim the events table row count equals the KPI (UI-SPEC + D-06).
- **`/webhooks`** remains owned by the webhook backlog KPI; linking the meter-failure count there without SQL parity would mislead operators (D-07).

## 3. UI integration points

- **Placement:** First child inside `section.ax-kpi-grid` in `dashboard_live.ex` **before** Customers `KpiCard` (48-UI-SPEC).
- **Component:** `AccrueAdmin.Components.KpiCard` with `label`, `value`, optional `delta` / `delta_tone`, `href`, `aria_label`, `meta` slot — same linked-card pattern as existing four KPIs.
- **Grid CSS:** `.ax-kpi-grid` uses responsive `grid-template-columns` in `accrue_admin/assets/css/app.css` (repeat(2,…) / repeat(3,…) breakpoints). Five cards may need **breakpoint-only** tweaks inside existing `.ax-kpi-grid` rules (UI-SPEC allows; no new layout primitive).

## 4. Copy SSOT

- All new operator strings → **`AccrueAdmin.Copy`** with `dashboard_meter_*` prefix (CONTEXT D-09). No new literals in `dashboard_live.ex` HEEx for this feature.

## 5. Testing posture (CONTEXT D-12..D-14)

- Extend **`AccrueAdmin.DashboardLiveTest`** (`accrue_admin/test/accrue_admin/live/dashboard_live_test.exs`): uses `AccrueAdmin.LiveCase`, `TestRepo`, `Factory.customer`, session `admin_token: "admin"`, `live(conn, "/billing")`.
- Insert at least one **`MeterEvent`** with `stripe_status: "failed"` in `setup` (via `MeterEvent.pending_changeset/1` → `MeterEvent.failed_changeset/2` + `TestRepo`, or equivalent) so the KPI renders **non-zero**; assert primary **label** and **`href="/billing/events"`** (or org-scoped variant) and **`aria-label`** from `Copy` helpers appear in HTML.
- **ExUnit for Copy:** No dedicated `copy_test.exs` today — add **assertions on `Copy.dashboard_meter_*` return values** inside the same LiveView test file **or** introduce `accrue_admin/test/accrue_admin/copy_dashboard_meter_test.exs` if planners prefer isolated unit tests (either satisfies D-12).
- **Playwright / axe:** Deferred to Phase **50** per D-13 unless an existing VERIFY-01 spec breaks; then minimal selector fix only.

## 6. Risks / pitfalls

| Risk | Mitigation |
|------|------------|
| Label implies filtered `/events` view | Meta + aria copy: terminal **meter event** failures; link opens **ledger** for correlation |
| Confusing meter KPI with webhook backlog | Distinct `Copy` keys and wording (“meter reporting” / “meter events”) vs webhook card |
| `identifier` uniqueness in test setup | Use unique `identifier` string per test insert (like other meter tests) |

## Validation Architecture

**Nyquist dimension 8 (feedback sampling) for this LiveView + Copy phase:**

| Dimension | Strategy |
|-----------|----------|
| Primary automated gate | `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs` (or full `mix test` in `accrue_admin` after changes) — exit **0** |
| Copy SSOT | `rg 'dashboard_meter_' accrue_admin/lib/accrue_admin/copy.ex` non-empty; `rg 'Meter reporting|meter event|failed' accrue_admin/lib/accrue_admin/live/dashboard_live.ex` returns **no** new user-facing string literals (only `Copy.*` calls and structural HEEx) |
| SQL presence | `rg 'stripe_status.*failed|MeterEvent' accrue_admin/lib/accrue_admin/live/dashboard_live.ex` shows aggregate uses **`MeterEvent`** + **failed** terminal filter |
| Placement | `rg -n 'ax-kpi-grid' accrue_admin/lib/accrue_admin/live/dashboard_live.ex` — first `KpiCard` after grid opening tag is the new meter card (grep order / read file) |
| Optional CSS | If `app.css` touched: `rg 'ax-kpi-grid' accrue_admin/assets/css/app.css` — only existing selector blocks extended |

Wave 0: **Not required** — ExUnit + LiveViewTest already present in `accrue_admin`.

---

## RESEARCH COMPLETE

Phase 48 planning can proceed with **48-CONTEXT.md** + **48-UI-SPEC.md** as SSOT and this file for anchors and validation strategy.
