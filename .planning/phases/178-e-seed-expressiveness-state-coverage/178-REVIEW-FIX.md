---
phase: 178-e-seed-expressiveness-state-coverage
fixed_at: 2026-06-04T17:44:00Z
review_path: .planning/phases/178-e-seed-expressiveness-state-coverage/178-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 178-E: Code Review Fix Report

**Fixed at:** 2026-06-04T17:44:00Z
**Source review:** .planning/phases/178-e-seed-expressiveness-state-coverage/178-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope (critical + warning): 2
- Fixed: 2
- Skipped: 0

Additionally, IN-03 was applied as trivial (as permitted by phase instructions); IN-01 and IN-02 were skipped.

## Fixed Issues

### WR-01: E2E Plug Has Duplicate Routes for Only Two of Five Seed Endpoints

**Files modified:** `accrue_admin/test/support/e2e_plug.ex`
**Commit:** aa559b27
**Applied fix:** Added `/__e2e__/reset`, `/__e2e__/seed/dashboard`, and `/__e2e__/seed/operator-flows` route aliases (Option B). All five seed/control routes now consistently expose a `/__e2e__/*` alias, eliminating the latent 404 trap for any future direct `Plug.Test.conn` unit tests. The two existing `/__e2e__` aliases (edge-states, overflow) and the unprefixed routes are untouched.

---

### WR-02: Cleanup Allowlist Contains Dead Entries That Can Never Match in Host DB

**Files modified:** `scripts/ci/accrue_host_seed_e2e.exs`
**Commit:** 610c9c36
**Applied fix:** Removed dead entries from all three allowlists:
- `@fixture_customer_processor_ids`: removed `cus_host_premium_replay` (never inserted by this script)
- `@fixture_subscription_processor_ids`: removed `sub_host_premium_replay` (never inserted), `sub_e2e_dunning_at_risk` and `sub_e2e_canceling` (belong to admin E2E DB `accrue_admin_test`, not host DB `accrue_host_test`)
- `@fixture_subscription_item_processor_ids`: removed `si_host_premium_replay` (never inserted by this script)
Kept: `cus_e2e_edge_1`, `sub_e2e_edge_at_risk`, `sub_e2e_edge_canceling`, `si_host_browser_replay` — all confirmed inserted by host seed scripts.

---

## Info Items

### IN-03: `seed_overflow!` Return Value Silently Ignores Subscription Inserts (applied)

**Files modified:** `accrue_admin/test/support/e2e_fixtures.ex`
**Commit:** e13c37a4
**Applied fix:** Changed `Enum.each` to `_subscriptions = Enum.map(...)` in `seed_overflow!`. Trivial change; signals transformation intent and keeps structs reachable.

---

### IN-01: Invoice Processor ID Naming Convention Inconsistency (skipped)

**File:** `scripts/ci/accrue_host_seed_e2e.exs:444`
**Reason:** Skipped per phase instructions. Info-only; internally consistent `inv_` prefix is deliberate. A comment could be added manually if desired.

---

### IN-02: Trialing Subscription Idempotency Is Soft on Re-run (skipped)

**File:** `examples/accrue_host/priv/repo/seeds/hero_accounts.exs:85-98`
**Reason:** Skipped per phase instructions. Info-only; the risk is low (only occurs if the Fake processor advances trialing to active between seed runs, which doesn't happen in CI).

---

## Test Verification

- `cd accrue_admin && mix test --seed 0`: **262 tests, 0 failures**
- `cd examples/accrue_host && mix test test/accrue_host/hero_accounts_test.exs test/accrue_host/seed_e2e_cleanup_test.exs --seed 0`: **3 tests, 0 failures**

---

_Fixed: 2026-06-04T17:44:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
