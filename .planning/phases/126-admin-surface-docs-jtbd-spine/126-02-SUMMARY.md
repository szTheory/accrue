---
phase: 126-admin-surface-docs-jtbd-spine
plan: 02
subsystem: admin
tags: [entitlements, admin, liveview, copy, verify-01, ent-11]

# Dependency graph
requires:
  - phase: 126-admin-surface-docs-jtbd-spine
    provides: "Accrue.Entitlements.Admin.resolve_for_customer/1 returning {resolved, unmapped_price_ids} (Plan 01 read seam)"
provides:
  - "Read-only entitlements tab on AccrueAdmin.Live.CustomerLive (/customers/:id?tab=entitlements) rendering resolved plans/features/quantities/grace + unmapped-plan drift"
  - "AccrueAdmin.Copy.Entitlements submodule (13 operator strings) + defdelegates + export allowlist (VERIFY-01 three-part contract)"
  - "Wave 0 LiveView test covering the three ENT-11 render states"
affects: [126-admin-surface-docs-jtbd-spine]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Read-only admin diagnostic tab: clone the richest sibling tab clause (payment_methods), call the core read seam once via a private helper, render-only (one-way admin -> core dependency)"
    - "VERIFY-01 three-part copy contract: Copy submodule @doc false 0-arity fns -> Copy defdelegates -> export-task allowlist; zero hardcoded operator strings in the template"
    - "JsonViewer MapSet-safety: convert resolved MapSets to sorted plain lists in a display-map helper before rendering (dodges %{\"__struct__\" => \"MapSet\"} mangling)"

key-files:
  created:
    - accrue_admin/lib/accrue_admin/copy/entitlements.ex
    - accrue_admin/test/accrue_admin/live/entitlements_live_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/mix.lock

key-decisions:
  - "Resolved-first then drift render order (D-02): active plans -> granted features -> seats & limits -> grace (conditional) in the first card, then a separate 'Plan mapping' card badging unmapped price_ids amber with a self-explaining hint. The empty state collapses to the first card; the drift card always renders ('all clear' note when unmapped == [])."
  - "tab_counts/1 omits an :entitlements key (D-01) so no count badge renders; tabs/4's Map.get returns nil and the count badge is :if-gated. The :entitlements atom already exists (config key) so String.to_existing_atom/1 in normalize_tab/tabs cannot raise."
  - "entitlements_display_map/1 converts every resolved MapSet to a sorted list before JsonViewer renders the raw map (Pitfall 2); quantities (a plain map) and :plan pass through unchanged."

patterns-established:
  - "Admin entitlements tab reuses only existing components (StatusBadge moss/amber/slate tones, KpiCard, JsonViewer) and structural classes (ax-card/ax-heading/ax-label/ax-list-row/ax-body/ax-muted/ax-stack-sm/ax-kpi-grid) — zero new component, CSS, route, or auth surface."
  - "HEEx-escaping-robust copy assertions: when a Copy string contains an apostrophe, assert on an apostrophe-free fragment (HEEx renders ' as &#39;)."

requirements-completed: [ENT-11]

# Metrics
duration: 11min
completed: 2026-05-23
---

# Phase 126 Plan 02: Admin Entitlements Tab Summary

**A read-only `entitlements` tab on `AccrueAdmin.Live.CustomerLive` (`/customers/:id?tab=entitlements`) that renders a customer's resolved active plans, granted features, seats & limits, and grace state, then badges any active subscription whose `price_id` is unmapped with a self-explaining "⚠ Unmapped plan" drift signal — calling the Plan 01 read seam once and routing every operator string through the VERIFY-01 three-part Copy contract.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-05-23T20:45:01Z
- **Completed:** 2026-05-23T20:55:22Z
- **Tasks:** 3
- **Files modified:** 6 (2 created, 4 modified)

## Accomplishments

- Shipped the ENT-11 SC#1 operator surface: an operator opens `?tab=entitlements` and sees resolved active plans, granted features, seats & limits, and (when present) grace state — drift-by-eye on unmapped plans.
- Added `AccrueAdmin.Copy.Entitlements` (13 `@doc false` 0-arity fns, verbatim UI-SPEC copy incl. the fail-closed error string stating no access is granted on error), 13 `Copy.entitlements_*` defdelegates, and 13 export-allowlist entries — VERIFY-01 three-part contract intact; `mix accrue_admin.export_copy_strings` now emits 54 strings.
- Wired the tab into `CustomerLive`: `@tabs` gains `entitlements`, `StatusBadge` aliased, `entitlements_view/1` calls `Accrue.Entitlements.Admin.resolve_for_customer/1` exactly once (one-way admin -> core), `entitlements_display_map/1` dodges the JsonViewer MapSet trap, `tab_counts/1` deliberately omits the count.
- Locked the Wave 0 LiveView test (three ENT-11 states, all GREEN): resolved features render on a mapped price, the ⚠ Unmapped plan badge appears for a `price_basic` sub, and the Copy-backed empty state renders without crashing for a no-sub customer.
- Reused only existing components/classes — zero new component, CSS, route, or auth surface; the tab inherits CustomerLive's `AuthHook`/`owner_scope` mount (T-126-04 mitigated).

## Task Commits

1. **Task 1: Copy.Entitlements submodule + defdelegates + export allowlist** - `4fa9094` (feat)
2. **Task 2: CustomerLive entitlements tab (case clause + @tabs + StatusBadge + seam call)** - `474505d` (feat)
3. **Task 3: Wave 0 LiveView test (three render states)** - `6108565` (test, GREEN)

**Plan metadata:** see final docs commit.

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/copy/entitlements.ex` (created) — `AccrueAdmin.Copy.Entitlements`; one `@doc false` 0-arity fn per UI-SPEC Copywriting Contract row (section/drift titles, plan/feature/quantity/grace labels, unmapped badge + hint, empty title/copy, no-drift note, raw-map label, fail-closed error copy).
- `accrue_admin/lib/accrue_admin/copy.ex` (modified) — `alias AccrueAdmin.Copy.Entitlements` + 13 `defdelegate entitlements_*(), to: Entitlements, as: :<shortname>`.
- `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` (modified) — 13 `entitlements_*` names added to the `~w(...)a` `@allowlist`.
- `accrue_admin/lib/accrue_admin/live/customer_live.ex` (modified) — `@tabs` + `entitlements`, `StatusBadge` alias, `case @tab` `"entitlements"` clause (resolved-first card + Plan-mapping drift card + JsonViewer), `entitlements_view/1` + `entitlements_display_map/1` private helpers; `tab_counts/1` unchanged (no `:entitlements` key).
- `accrue_admin/test/accrue_admin/live/entitlements_live_test.exs` (created) — `use AccrueAdmin.LiveCase, async: false`; setup mutates `:auth_adapter` + `:entitlements` with `on_exit` restore; three tests against `Copy.entitlements_*` strings.
- `accrue_admin/mix.lock` (modified) — Rule 3 blocking-fix: synced to reconcile `rendro ~> 0.3.0` (the `accrue` path-dep requirement) so `accrue_admin` compiles.

## Decisions Made

- **Resolved-first, then drift (D-02)** — the first `ax-card` shows resolved truth (plans/features/quantities/grace); a separate "Plan mapping" card shows the unmapped drift (amber badge + apostrophe-bearing self-explaining hint), so an operator reads grant truth before drift. Drift card always renders, with a Copy-backed "all clear" note when nothing is unmapped.
- **No count badge (D-01)** — `tab_counts/1` omits `:entitlements`; `tabs/4`'s `Map.get` returns `nil`, and the count badge is `:if`-gated, so no badge appears. `:entitlements` already exists as a config atom, so `String.to_existing_atom/1` is safe.
- **MapSet display-map (Pitfall 2)** — `entitlements_display_map/1` converts each resolved MapSet to a sorted list before JsonViewer, so the raw-map disclosure shows clean lists, never `%{"__struct__" => "MapSet"}`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Synced accrue_admin/mix.lock to reconcile rendro ~> 0.3.0**
- **Found during:** Task 1 (first `mix compile`)
- **Issue:** `accrue_admin` would not compile — `accrue/mix.exs` requires `rendro ~> 0.3.0` (and `accrue/mix.lock` pins 0.3.0) but `accrue_admin/mix.lock` pinned the stale 0.1.0, which was the installed version. Pre-existing lockfile drift, not caused by this plan's edits.
- **Fix:** `mix deps.get` in `accrue_admin`, reconciling the lock (13 lines: rendro + transitive harfbuzz_ex/unicode_data and a few patch bumps). NOT a package-manager *install* of a new/renamed package (rendro is an existing pinned sibling-path transitive dep), so the package-legitimacy checkpoint exclusion does not apply.
- **Files modified:** `accrue_admin/mix.lock`
- **Commit:** `4fa9094`

**2. [Rule 1 - Bug] HEEx-escaping-robust assertion for the unmapped hint**
- **Found during:** Task 3 (first test run — 1 failure)
- **Issue:** the test asserted `html =~ Copy.entitlements_unmapped_hint()`, but the hint contains an apostrophe (`subscription's`) which HEEx escapes to `subscription&#39;s` in rendered HTML, so the raw `=~` failed (the badge + price_id + drift title all rendered correctly).
- **Fix:** assert on the apostrophe-free tail `"config, so the resolver drops it."` — still pins the self-explaining hint, escaping-robustly.
- **Files modified:** `accrue_admin/test/accrue_admin/live/entitlements_live_test.exs`
- **Commit:** `6108565`

## Issues Encountered

- The plan's `cd accrue_admin && mix ...` verify commands run from the repo root (executor cwd is `/Users/jon/projects/accrue`); ran them with the explicit `cd` into `accrue_admin`. No functional issue.
- SQL `[debug]` log volume drowned the first failing-assertion output; re-ran with log filtering to read the failure cleanly.

## TDD Gate Compliance

Task 3 carried `tdd="true"`. Per the plan's own `<action>` ("it should be GREEN once both [Plan 01 seam + Task 2 tab] land"), the implementation was already in place from Tasks 1-2, so the test functions as the GREEN-confirming gate rather than a from-scratch RED. First run surfaced one genuine assertion bug (HEEx apostrophe escaping), which was fixed; the file then reached 3 tests, 0 failures. The `test(126-02)` commit is the gate artifact.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/entitlements_live_test.exs` → 3 tests, 0 failures (the three render states).
- `cd accrue_admin && mix compile --warnings-as-errors` → clean.
- `mix accrue_admin.export_copy_strings --out ...` → wrote 54 copy strings incl. all 13 `entitlements_*` (VERIFY-01).
- Regression: `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs` → 10 tests, 0 failures (no existing-tab breakage).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- ENT-11 SC#1 (admin entitlements viewer) is shipped and GREEN. The remaining Phase 126 work is docs/verifier (entitlements.md, JTBD ⛔→✅ flip, README/quickstart spine, green doc verifiers) — already covered by Plan 03 (126-03-SUMMARY exists) and Plan 04.
- The tab consumes the Plan 01 seam read-only and one-directionally; no public gate API was widened.

## Self-Check: PASSED

- Files: `accrue_admin/lib/accrue_admin/copy/entitlements.ex`, `accrue_admin/lib/accrue_admin/live/customer_live.ex`, `accrue_admin/test/accrue_admin/live/entitlements_live_test.exs`, `126-02-SUMMARY.md` all present.
- Commits: `4fa9094` (feat), `474505d` (feat), `6108565` (test) all in git history.

---
*Phase: 126-admin-surface-docs-jtbd-spine*
*Completed: 2026-05-23*
