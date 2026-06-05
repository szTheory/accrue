---
phase: 178-e-seed-expressiveness-state-coverage
plan: "02"
subsystem: test-support
tags:
  - e2e-fixtures
  - seed
  - test-support
  - dunning
  - pagination
dependency_graph:
  requires:
    - 178-01
  provides:
    - seed_edge_states!/0
    - seed_overflow!/0
    - POST /__e2e__/seed/edge-states
    - POST /__e2e__/seed/overflow
  affects:
    - accrue_admin/test/support/e2e_fixtures.ex
    - accrue_admin/test/support/e2e_plug.ex
tech_stack:
  added: []
  patterns:
    - "force_status_changeset/2 pipe form for bypassing transition guards"
    - "Enum.map(1..N) bulk insert loop for overflow fixtures"
    - "Dual route form: stripped path (Phoenix forward) + full path (direct Plug.call)"
key_files:
  created: []
  modified:
    - accrue_admin/test/support/e2e_fixtures.ex
    - accrue_admin/test/support/e2e_plug.ex
decisions:
  - "Added dual routes (stripped + full path) in e2e_plug.ex to satisfy both Phoenix router forward and direct Plug.Test.conn call patterns"
  - "force_status_changeset/2 pipe form used for :past_due subscription to bypass transition guards"
  - "canceling subscription uses standard changeset/2 (status :active is a valid insert state)"
metrics:
  duration: "~12 minutes"
  completed: "2026-06-04"
  tasks_completed: 2
  files_modified: 2
---

# Phase 178 Plan 02: Seed Expressiveness & State Coverage — E2E Fixtures GREEN Summary

## One-liner

seed_edge_states!/0 (dunning/at-risk, canceling, JPY, long-name, coupon, connect-account) and seed_overflow!/0 (26 customers + 26 subs) implemented; 8 RED tests turned GREEN; dual-path e2e plug routes wired.

## What Was Built

**Task 1 — e2e_fixtures.ex:**
- `seed_edge_states!/0`: Inserts a `:past_due` subscription via `%Subscription{} |> Subscription.force_status_changeset(attrs) |> TestRepo.insert!()` with `dunning_campaign_started_at` set 5 days ago; a canceling subscription (`status: :active, cancel_at_period_end: true, current_period_end` 7 days in future); a JPY invoice (`currency: "jpy", total_minor: 55_000`); a JPY charge; a long-name customer (111-char name); a coupon + promo_code; a connect account. Returns a 9-key ID map.
- `seed_overflow!/0`: Inserts 26 customers (`cus_e2e_overflow_1..26`) and 26 subscriptions (`sub_e2e_overflow_cus_e2e_overflow_1..26`), exceeding `DataTable @default_limit=25`. Returns `%{first_customer_id: ...}`.
- New private helpers: `insert_coupon/1`, `insert_promo_code/2`, `insert_connect_account/2` — all follow the established `Map.merge(defaults, attrs) |> changeset |> TestRepo.insert!()` pattern.
- Aliases added: `Coupon`, `PromotionCode`, `Accrue.Connect.Account`.

**Task 2 — e2e_plug.ex:**
- Added `post "/seed/edge-states"` and `post "/__e2e__/seed/edge-states"` routes (before catch-all).
- Added `post "/seed/overflow"` and `post "/__e2e__/seed/overflow"` routes (before catch-all).
- Existing `seed/dashboard` and `seed/operator-flows` routes unchanged.

## Test Results

- Before: `8 tests, 8 failures` (all RED from Plan 178-01 scaffold)
- After: `8 tests, 0 failures`
- Full suite: `262 tests, 0 failures` (0 regressions from prior 254)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Dual route form required in e2e_plug.ex**
- **Found during:** Task 2 — POST route tests returned 404
- **Issue:** The plan specified `post "/seed/edge-states"` (stripped path), but the test calls `AccrueAdmin.E2E.Plug.call([])` directly with `Plug.Test.conn(:post, "/__e2e__/seed/edge-states")`. Plug.Router matches against `path_info`, which for a direct `Plug.Test.conn` call is `["__e2e__", "seed", "edge-states"]` — not `["seed", "edge-states"]`. The stripped-path route only works when called through Phoenix router's `forward("/__e2e__", ...)` which strips the prefix.
- **Fix:** Added both forms: `post "/seed/edge-states"` (for Phoenix router forward, used by Playwright in Phase 179) and `post "/__e2e__/seed/edge-states"` (for direct `Plug.call` in unit tests). Same dual pattern applied to `/seed/overflow`.
- **Files modified:** `accrue_admin/test/support/e2e_plug.ex`
- **Commits:** cd4cfe14

## Commits

| Task | Commit | Message |
|------|--------|---------|
| Task 1 | 556abf1d | feat(178-02): implement seed_edge_states!/0 and seed_overflow!/0 fixtures |
| Task 2 | cd4cfe14 | feat(178-02): wire POST /seed/edge-states and POST /seed/overflow routes in e2e_plug.ex |

## Threat Flags

None. Changes are confined to `test/support/` — compiled only in `:test` env. No new network endpoints in production code.

## Self-Check: PASSED

- [x] `accrue_admin/test/support/e2e_fixtures.ex` — exists, modified (161 insertions)
- [x] `accrue_admin/test/support/e2e_plug.ex` — exists, modified (16 insertions)
- [x] Commit 556abf1d — exists in git log
- [x] Commit cd4cfe14 — exists in git log
- [x] `grep force_status_changeset` confirms `%Subscription{} |> Subscription.force_status_changeset` pipe form
- [x] `grep "seed/edge-states"` confirms routes present in e2e_plug.ex
- [x] 262 tests, 0 failures
