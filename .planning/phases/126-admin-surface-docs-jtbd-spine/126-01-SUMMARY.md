---
phase: 126-admin-surface-docs-jtbd-spine
plan: 01
subsystem: payments
tags: [entitlements, admin, resolver, local_map, ecto, tdd]

# Dependency graph
requires:
  - phase: 123-config-core-gate-api-foundation
    provides: ":entitlements config + Accrue.Entitlements.Resolver.LocalMap fold (fold_active/1, catalog/0, active_items/1)"
  - phase: 125-provider-honesty-lifecycle-truth
    provides: "Query.entitling/1 + past-due grace overlay (grace_plans / expired_grace_plans) the seam surfaces"
provides:
  - "Accrue.Entitlements.Admin.resolve_for_customer/1 returning {resolved_map, unmapped_price_ids}"
  - "Two @doc false LocalMap delegations: fold_for_customer/1 (SSOT fold reuse) and unmapped_entitling_price_ids/1 (drift surface)"
  - "Wave 0 unit-test contract (admin_test.exs) the Plan 02 entitlements LiveView relies on"
affects: [126-02-admin-entitlements-live, 126-admin-surface-docs-jtbd-spine]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Internal read-only diagnostic seam (separate module + @doc false delegations) — additive, never widening the public gate API"
    - "Read-through-the-SSOT-fold: admin reuses fold_active/1, never re-implements resolution (PITFALLS #2)"
    - "Independent drift re-derivation: surface the price_ids the resolver structurally discards under :deny"

key-files:
  created:
    - accrue/lib/accrue/entitlements/admin.ex
    - accrue/test/accrue/entitlements/admin_test.exs
  modified:
    - accrue/lib/accrue/entitlements/resolver/local_map.ex

key-decisions:
  - "resolve_for_customer/1 returns a {resolved, unmapped} pair (never a boolean) so the admin tab gets the resolved entitlement state AND the unmapped drift the resolved map can never show — keeps the seam off the deferred fetch_entitled/2 gate-API trap (D-04 / D-07)."
  - "fold_for_customer/1 literally calls fold_active/1 — a single fold, zero copy — so the admin view can never drift from the gate's grant/deny truth (T-126-02 / PITFALLS #2)."
  - "Admin hard-codes the LocalMap resolver; custom resolvers are out of scope for the read-only diagnostic (A2 limitation, documented in the moduledoc)."

patterns-established:
  - "Diagnostic read seam: new Accrue.Entitlements.Admin module + two @doc false delegations on the resolver, never a new Accrue.* public function."
  - "Independent unmapped-drift surfacing via catalog()/active_items() reuse + Enum.reject(Map.has_key?)."

requirements-completed: [ENT-11]

# Metrics
duration: 2min
completed: 2026-05-23
---

# Phase 126 Plan 01: Admin Entitlements Read Seam Summary

**`Accrue.Entitlements.Admin.resolve_for_customer/1` — an internal read-only diagnostic seam that returns `{resolved_map, unmapped_price_ids}` by reusing the resolver's SSOT fold and independently surfacing the entitling price_ids the resolver structurally discards under `:deny`.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-23T20:29:53Z
- **Completed:** 2026-05-23T20:31:14Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Shipped the ONE load-bearing technical artifact for ENT-11: `Accrue.Entitlements.Admin.resolve_for_customer/1`, the seam the Plan 02 admin entitlements tab calls.
- Added two `@doc false` delegations on `LocalMap` — `fold_for_customer/1` (reuses the SSOT `fold_active/1`, zero fold copy) and `unmapped_entitling_price_ids/1` (reuses `catalog()`/`active_items()` to surface `:deny`-dropped price_ids).
- Locked the Wave 0 unit-test contract (`admin_test.exs`): mapped, unmapped-drift (Pitfall 1 `price_basic`), empty, and grace (in-window grant + out-of-window expired) cases — all GREEN.
- Held all D-04 hard constraints: no new public `Accrue.*` gate API (`entitlements.ex` unchanged, still 4 public defs), one-way dependency (no reverse reference to `Admin` from billing/resolver), and `fetch_entitled/2` (D-07) stays deferred.

## Task Commits

Each task was committed atomically (TDD RED → GREEN):

1. **Task 1: Wave 0 failing unit test** - `d23bde1` (test) — RED: `Accrue.Entitlements.Admin` undefined
2. **Task 2: Two @doc false LocalMap delegations** - `a3f9f0d` (feat) — `fold_for_customer/1` + `unmapped_entitling_price_ids/1`
3. **Task 3: Implement resolve_for_customer/1** - `8ae57ea` (feat) — GREEN (6 tests, 0 failures)

**Plan metadata:** see final docs commit.

## Files Created/Modified

- `accrue/lib/accrue/entitlements/admin.ex` (created) - Internal read-only diagnostic seam; `resolve_for_customer/1` returns `{resolved, unmapped_price_ids}` by delegating to the two LocalMap seam helpers. Moduledoc pins the not-a-gate-API / one-way-dependency / LocalMap-hardcode posture.
- `accrue/lib/accrue/entitlements/resolver/local_map.ex` (modified) - Added `fold_for_customer/1` (delegates to `fold_active/1`) and `unmapped_entitling_price_ids/1` (reuses `catalog()`/`active_items()`), both `@doc false`.
- `accrue/test/accrue/entitlements/admin_test.exs` (created) - Wave 0 unit test; `async: false` with `:entitlements` app-env mutation + `on_exit` restore; covers mapped/unmapped/empty/grace.

## Decisions Made

- **`{resolved, unmapped}` pair, never a boolean** — the resolved map can never show drift (`handle_unmapped/3 :deny` silently discards), so the seam re-derives the unmapped list independently. This keeps the seam clear of the deferred `fetch_entitled/2` gate-API trap (D-04 / D-07).
- **Single fold, zero copy** — `fold_for_customer/1` literally calls the private `fold_active/1`, so the admin diagnostic and the gate share one resolution path and cannot drift (T-126-02 / PITFALLS #2).
- **LocalMap hard-coded** — documented A2 limitation; custom resolvers are out of scope for this read-only diagnostic.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. (One transient observation: the plan's `cd accrue && …` verify commands must be run from the repo root since the executor's working directory is `/Users/jon/projects/accrue`; the first RED check appeared to mis-fire only because of a missing `cd` into the `accrue` mix project, not a test problem. Re-running from the correct directory confirmed the expected RED state.)

## TDD Gate Compliance

Each task carried `tdd="true"`. Gate sequence verified in git log:

1. RED — `test(126-01)` commit `d23bde1`: test fails on missing `Accrue.Entitlements.Admin` module (confirmed via the plan's RED verify grep).
2. GREEN — `feat(126-01)` commits `a3f9f0d` (delegations) → `8ae57ea` (admin module): `admin_test.exs` reaches 6 tests, 0 failures.
3. REFACTOR — none needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The `{resolved, unmapped}` contract is GREEN and is the exact shape Plan 02's `accrue_admin` entitlements LiveView consumes (renders `resolved` + an unmapped-drift badge from `unmapped`).
- One-way dependency and no-public-gate-API posture are machine-verified, so the seam can be safely consumed by the admin LiveView without inviting a fail-open gate.

## Self-Check: PASSED

- Files: `admin.ex`, `local_map.ex`, `admin_test.exs`, `126-01-SUMMARY.md` all present.
- Commits: `d23bde1` (test), `a3f9f0d` (feat), `8ae57ea` (feat) all in git history.

---
*Phase: 126-admin-surface-docs-jtbd-spine*
*Completed: 2026-05-23*
