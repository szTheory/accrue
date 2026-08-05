---
phase: 216
fixed_at: 2026-08-02T00:00:00Z
review_path: /Users/jon/projects/accrue/.planning/phases/216-additive-rail-and-persistence-foundation/216-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 216: Code Review Fix Report

**Fixed at:** 2026-08-02T00:00:00Z
**Source review:** `/Users/jon/projects/accrue/.planning/phases/216-additive-rail-and-persistence-foundation/216-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: Observation metadata permits arbitrary PII and provider payload fragments

**Files modified:** `accrue/lib/accrue/entitlements/observation.ex`, `accrue/priv/repo/migrations/20260802200000_bound_accrue_entitlement_provider_identity.exs`, `accrue/test/accrue/entitlements/persistence_test.exs`
**Commits:** 2041b197, c4340c22
**Applied fix:** Replaced the substring deny-list with the Phase-216 fixed metadata projection contract (empty metadata or exactly one allowlisted `source` key), enforced it with a PostgreSQL JSONB check, and covered neutral-key PII and payload-fragment bypasses.

### CR-02: Device identity fields accept raw personal/device data

**Files modified:** `accrue/lib/accrue/entitlements/device.ex`, `accrue/priv/repo/migrations/20260802200000_bound_accrue_entitlement_provider_identity.exs`, `accrue/test/accrue/entitlements/persistence_test.exs`, `accrue/test/mix/tasks/accrue_install_test.exs`
**Commit:** 1028bf3e
**Applied fix:** Constrained installation and thumbprint values to bounded opaque tokens without introducing the deferred proof-verification format, added matching PostgreSQL checks and direct-write tests, and retained account-scoped uniqueness/history semantics. Re-review confirmed canonical P-256 thumbprint recomputation belongs to the later registration runtime, not this persistence-only phase.

### CR-03: Additive rails crash when the schema's default processor is used

**Files modified:** `accrue/lib/accrue/config.ex`, `accrue/test/accrue/config_entitlements_test.exs`
**Commit:** 3016410e
**Applied fix:** Passed NimbleOptions-normalized configuration to cross-field boot validation and added coverage for a valid host-fake rail with the top-level processor omitted.

## Verification

- Scoped `mix format --check-formatted` and `git diff --check` passed for every Phase 216 fix.
- A fresh `accrue_test` database was dropped, created, and migrated so prior local migration state could not mask the new constraints.
- Focused Phase 216 verification passed: 80 tests, 0 failures.
- Full `mix test --warnings-as-errors` passed: 1,810 tests and 63 properties, 0 failures (11 excluded).
- Standard-depth re-review passed with 15 files reviewed and zero findings.

---

_Fixed: 2026-08-02T00:00:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
