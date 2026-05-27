---
phase: 143-recovered-revenue-analytics
verified: 2026-05-27T12:25:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
---

# Phase 143: Recovered-Revenue Analytics Verification Report

**Phase Goal (composite of Plans 143-01 + 143-02):**
Snapshot MRR onto dunning lifecycle events, ship the `Accrue.Analytics.Dunning` Ecto context that aggregates recovered-vs-lost MRR from the existing `accrue_events` ledger (no new tables), and expose a `/analytics/recovery` LiveView dashboard in `accrue_admin` under the admin-auth `live_session`.

**Verified:** 2026-05-27T12:25:00Z
**Status:** passed
**Re-verification:** No — initial verification (143-01-SUMMARY.md was reconstructed retroactively from commit `57ce35b4`).

## Goal Achievement

### Observable Truths

| # | Truth (from PLAN must_haves) | Status | Evidence |
|---|------|--------|----------|
| 1 | MRR is snapshotted inside event payloads for recovery and exhaustion (143-01) | VERIFIED | `default_handler.ex:782` (exhaustion path) and `:880` (recovery path) both call `calculate_mrr_cents(canonical)` and inject `mrr_value_cents` + `currency` into `data:` of `Events.record/record_multi`. `calculate_mrr_cents/1` defined at `:1896` handles month/year/week/day intervals and tolerates atom/string keys via the local `get/2` helper (`:1661`). |
| 2 | Ecto context exists to aggregate MRR data without new database tables (143-01) | VERIFIED | `accrue/lib/accrue/analytics/dunning.ex` (72 LOC) defines `recovered_vs_lost_mrr/1`. Uses `from(e in Event, where: e.type in [@recovered_type, @exhausted_type], group_by: e.type, select: {e.type, sum(fragment("(?->>'mrr_value_cents')::integer", e.data))})` — straight Postgres JSONB aggregation against `accrue_events`. No new tables or migrations introduced. |
| 3 | User can access the Recovered Revenue dashboard (143-02) | VERIFIED | Route registered at `accrue_admin/lib/accrue_admin/router.ex:75-77` inside the `live_session :accrue_admin` block (lines 52-86), so admin `on_mount {AccrueAdmin.AuthHook, :ensure_admin}` (line 9) is inherited. LiveView test successfully mounts via `live(conn, "/billing/analytics/recovery")` against the test endpoint with `admin_token: "admin"`. |
| 4 | Dashboard displays accurate "Money Saved" metrics (143-02) | VERIFIED | `RecoveryLive.mount/3` calls `Dunning.recovered_vs_lost_mrr()` (line 12) and assigns `:stats`. `render/1` renders two `KpiCard.kpi_card` components: "Recovered MRR" and "Lost MRR" with `format_minor/1` (cents → "$X.XX"). LiveView test seeded `mrr_value_cents: 5000` recovered + `2000` exhausted and asserted the HTML contains `"$50.00"` and `"$20.00"` — passed. |

**Score:** 4/4 truths verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue/lib/accrue/webhook/default_handler.ex` | Event payload snapshotting | VERIFIED | 1924 LOC; `calculate_mrr_cents/1` defined; both `dunning.exhausted` (`:804-814`) and `dunning.recovered` (`:885-894`) `Events.record/record_multi` calls carry `mrr_value_cents` + `currency`. No debt markers (TBD/FIXME/XXX) introduced. |
| `accrue/lib/accrue/analytics/dunning.ex` | MRR Ecto aggregations | VERIFIED | 72 LOC; `recovered_vs_lost_mrr/1` returns `%{recovered_cents: non_neg_integer(), lost_cents: non_neg_integer()}`. Optional `:since`/`:until` `DateTime` windowing via `maybe_since/maybe_until` private helpers using parameterized `^` binding. `@spec` declared. |
| `accrue/test/accrue/analytics/dunning_test.exs` | Test coverage | VERIFIED | 83 LOC; 2 tests — aggregation correctness and `:since`/`:until` windowing. Both passed (see "Behavioral Spot-Checks"). |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | LiveView for recovery dashboard | VERIFIED | 86 LOC; uses `Phoenix.LiveView`, aliases `Accrue.Analytics.Dunning` + `AccrueAdmin.Components.{AppShell, Breadcrumbs, KpiCard}`. `mount/3` loads stats, `render/1` uses the canonical `<AppShell.app_shell>` shell + `ax-kpi-grid`. |
| `accrue_admin/lib/accrue_admin/router.ex` | Route under /analytics | VERIFIED | 194 LOC; `scope "/analytics", AccrueAdmin.Live.Analytics do live("/recovery", RecoveryLive, :index) end` at `:75-77`, nested inside `live_session :accrue_admin` (`:52`), inheriting `pipe_through :accrue_admin_browser` (`:50`) + `on_mount` admin hook. |
| `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` | LiveView test | VERIFIED | 66 LOC; mounts `/billing/analytics/recovery`, asserts `"Recovered MRR"`, `"$50.00"`, `"Lost MRR"`, `"$20.00"` in rendered HTML — passed. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `default_handler.ex` (exhaustion path) | `accrue_events` (Postgres) | `Events.record/1` with `mrr_value_cents` in `data` | WIRED | `:804-814` writes `%{type: "dunning.exhausted", data: %{to_status: ..., source: ..., mrr_value_cents: mrr_value_cents, currency: currency}}`. |
| `default_handler.ex` (recovery path) | `accrue_events` (Postgres) | `Events.record_multi/3` (atomic with anchor-clear) | WIRED | `:885-894` folds the `dunning.recovered` record into the same `Ecto.Multi` as the `clear_anchor` write — atomic transaction. |
| `analytics/dunning.ex` | `accrue_events` (Postgres) | JSONB `sum(fragment("(?->>'mrr_value_cents')::integer", e.data))` group_by | WIRED | Compiled query (logged during test run): `SELECT a0."type", sum((a0."data"->>'mrr_value_cents')::integer) FROM "accrue_events" AS a0 WHERE (a0."type" IN ('dunning.recovered','dunning.exhausted')) GROUP BY a0."type"`. Confirmed via test logs. |
| `RecoveryLive.mount/3` | `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` | direct call in `mount/3` | WIRED | `recovery_live.ex:12` `stats = Dunning.recovered_vs_lost_mrr()`. |
| `router.ex` | `RecoveryLive` | `live "/recovery", RecoveryLive, :index` | WIRED | `router.ex:76`, scoped under `AccrueAdmin.Live.Analytics`, nested in `live_session :accrue_admin` for admin-auth inheritance. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `RecoveryLive.render/1` | `@stats.recovered_cents` / `@stats.lost_cents` | `Dunning.recovered_vs_lost_mrr/1` (mount) → `Repo.all(query)` on `accrue_events` | Yes — verified by LiveView test seeding events and asserting rendered `$50.00`/`$20.00` | FLOWING |
| `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` | aggregation map | Real Postgres `SELECT … GROUP BY` against `accrue_events` ledger written by `Events.record` from `DefaultHandler` | Yes — confirmed via test SQL traces | FLOWING |
| `DefaultHandler` `data.mrr_value_cents` | `mrr_value_cents` int | `calculate_mrr_cents(canonical)` reducing over `data["items"]["data"]` | Yes — function present, tolerates atom+string keys, handles month/year/week/day intervals; empty items list returns `0` (graceful degradation), confirmed by passing `dunning_exhaustion_test.exs` regression suite | FLOWING (with note below) |

**Note on `mrr_value_cents` test coverage at the DefaultHandler boundary:**
There is no direct assertion in `dunning_exhaustion_test.exs` that `data["mrr_value_cents"]` is present in the recorded event. The existing test (`:308-311`) only asserts `ledger.data["to_status"]` and `ledger.data["source"]`. The new field is added but not explicitly verified at the emission boundary. This is a coverage gap, not a goal-failure: the code path is clear, the `Accrue.Analytics.Dunning` test seeds the exact shape `%{"mrr_value_cents" => N}` and aggregates correctly, and the existing dunning regression tests still pass (no schema break). Flagging as Info — not a blocker.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `Accrue.Analytics.Dunning` aggregates correctly + respects time windows | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | `2 tests, 0 failures` | PASS |
| `RecoveryLive` mounts under admin auth and renders KPI cards with real data | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | `1 test, 0 failures` | PASS |
| Dunning exhaustion/recovery regression — adding `mrr_value_cents` did not break existing event shape | `cd accrue && mix test test/accrue/webhook/dunning_exhaustion_test.exs test/accrue/webhook/dunning_campaign_start_test.exs test/accrue/webhook/dunning_campaign_keying_test.exs test/accrue/jobs/dunning_sweeper_test.exs` | `32 tests, 0 failures` | PASS |
| `DefaultHandler` general regression | `cd accrue && mix test test/accrue/webhook/default_handler_test.exs` | `5 tests, 0 failures` | PASS |
| Recovery route exposed in router | `mix phx.routes` (in `accrue_admin/`) | `UndefinedFunctionError: AccrueAdmin.Router.formatted_routes/1` — expected: `accrue_admin/router.ex` is a macro-only router-builder, not a Phoenix endpoint router. Plan 143-02's `mix phx.routes \| grep ...` verify command does not apply here. Static verification: route definition confirmed at `router.ex:75-77` inside `live_session :accrue_admin`, AND the integration test successfully `live`s the route at `/billing/analytics/recovery`. | PASS (via static + integration) |

### T-143-01 Mitigation (Information Disclosure / SQL Injection)

| Mitigation | Status | Evidence |
|-----------|--------|----------|
| `:since`/`:until` window parameters bound via Ecto `^` | VERIFIED | `dunning.ex:64-72` — `where(query, [e], e.inserted_at >= ^since)` and `e.inserted_at <= ^until`. Compiled SQL (from test logs): `WHERE … AND (a0."inserted_at" >= $1) GROUP BY a0."type" [~U[2025-12-31 00:00:00.000000Z]]` — bound as `$1`, not interpolated. No string formatting into the fragment. |

### T-143-02 Mitigation (Elevation of Privilege)

| Mitigation | Status | Evidence |
|-----------|--------|----------|
| `/analytics/recovery` nested inside admin-auth live_session | VERIFIED | `router.ex:75-77` sits inside `live_session :accrue_admin` block at `:52-86`, which threads `on_mount: on_mount` and the macro defaults `@default_on_mount [{AccrueAdmin.AuthHook, :ensure_admin}]` (`:9`). All sibling admin routes (customers, subscriptions, invoices, etc.) use the same hook — recovery is no weaker. |

### Requirements Coverage

`.planning/REQUIREMENTS.md` is empty (0 lines). The phase plans declare `requirements: [ANA-01]` (143-01) and `requirements: [ANA-02]` (143-02) but the canonical requirement descriptions for ANA-01/ANA-02 are not catalogued in REQUIREMENTS.md. The PLAN-internal must_haves serve as the verification contract here:

| Requirement | Source Plan | Description (inferred from plan must_haves) | Status | Evidence |
|------------|-------------|---------------------------------------------|--------|----------|
| ANA-01 | 143-01 | Snapshot MRR onto dunning events + ship `Accrue.Analytics.Dunning` aggregations | SATISFIED | Truths #1, #2 verified above |
| ANA-02 | 143-02 | `/analytics/recovery` LiveView dashboard exposing recovered-vs-lost MRR via the ANA-01 context | SATISFIED | Truths #3, #4 verified above |

No orphaned requirements (REQUIREMENTS.md is empty so there is no broader map to validate against).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER markers in `analytics/dunning.ex`, `recovery_live.ex`, or the modified `default_handler.ex` block. No stub returns. No hardcoded empty data flowing to render. | — | — |

### Human Verification Required

None. All four observable truths are verified programmatically through static analysis + executed test suites. The dashboard renders real aggregated data, the route is wired into the admin live_session for auth inheritance, and the MRR snapshotting flows through to the analytics query end-to-end.

### Notes / Minor Observations (Info-only)

1. **Test coverage gap at the DefaultHandler emission boundary:** No test asserts `ledger.data["mrr_value_cents"]` is present after a webhook-driven `dunning.exhausted` / `dunning.recovered` emission. The field's presence is established by reading the production code and via the analytics test (which seeds the exact shape and aggregates it). A future hardening test in `dunning_exhaustion_test.exs` could close this — not a phase-143 goal failure.
2. **Plan 143-02's automated verify command `mix phx.routes | grep "/analytics/recovery"` is not directly runnable** because `accrue_admin/lib/accrue_admin/router.ex` is a router-builder macro, not a Phoenix endpoint router. The equivalent verification is satisfied (a) statically by reading the router source, and (b) functionally by the LiveView integration test mounting `/billing/analytics/recovery` against the test endpoint that has called `accrue_admin "/billing"`. Not a code defect — only a noted plan-verify-command mismatch.
3. **143-01-SUMMARY.md was reconstructed retroactively** (commit `f3f921db`) after commit `57ce35b4` shipped the production code without writing the summary. All three claimed `files_modified` exist on disk and match the plan contract.
4. The pivot from the v1.44 assessment's suggested route `/analytics/dunning` to the implemented `/analytics/recovery` is consistent within both plan files (143-02 PLAN, 143-PATTERNS.md, 143-RESEARCH.md all consistently say `/analytics/recovery`).

### Gaps Summary

None. Phase 143 ships a complete, working recovered-revenue analytics path: MRR is captured at event-emission time, aggregated via Ecto JSONB grouping with no new tables, and surfaced through an admin-auth-protected LiveView dashboard. Both threat-model mitigations (T-143-01, T-143-02) verified. All targeted test suites pass with zero failures. No regressions in pre-existing dunning emission tests.

---

_Verified: 2026-05-27T12:25:00Z_
_Verifier: Claude (gsd-verifier)_
