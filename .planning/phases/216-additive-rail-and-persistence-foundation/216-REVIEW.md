---
phase: 216-additive-rail-and-persistence-foundation
reviewed: 2026-08-02T16:17:27Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - accrue/guides/entitlements.md
  - accrue/lib/accrue/config.ex
  - accrue/lib/accrue/entitlements/account.ex
  - accrue/lib/accrue/entitlements/device.ex
  - accrue/lib/accrue/entitlements/grant.ex
  - accrue/lib/accrue/entitlements/observation.ex
  - accrue/priv/accrue/templates/install/runtime_config.exs.eex
  - accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs
  - accrue/test/accrue/config_entitlements_test.exs
  - accrue/test/accrue/docs/entitlements_guide_test.exs
  - accrue/test/accrue/entitlements/fake_fixture_test.exs
  - accrue/test/accrue/entitlements/persistence_test.exs
  - accrue/test/mix/tasks/accrue_install_test.exs
  - accrue/test/support/entitlements/fixtures.ex
findings:
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 216: Code Review Report

**Reviewed:** 2026-08-02T16:17:27Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

The additive rail configuration is boot-validated and the focused suite passes (68 tests), but the new durable evidence boundary still permits raw sensitive material, has an input shape that crashes its idempotent-ingest API, and permits provenance to cross account/rail boundaries. The migration also relies on changesets for invariants that PostgreSQL must enforce for a durable projection.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Blank event IDs select an inapplicable conflict target and crash ingestion

**Classification:** BLOCKER
**File:** `accrue/lib/accrue/entitlements/observation.ex:104-112,155-188`
**Issue:** `validate_identity/1` treats a blank `provider_event_id` as absent, but it never normalizes or rejects that value. With `provider_event_id: ""` and a valid transaction ID, `conflict_target/1` selects the partial transaction index and `fetch_by_identity!/2` searches only rows where `provider_event_id IS NULL`; the row that was inserted has `provider_event_id = ''`, so `repo.one!/1` raises. Such rows also fall outside both partial unique indexes and can be duplicated indefinitely.
**Fix:** Normalize blank optional identity fields to `nil` before `cast/3` (or reject any non-nil blank field) and add coverage for a blank event ID plus a transaction ID. The conflict target and lookup must use the exact persisted normalization.

### CR-02: Evidence reference accepts unbounded raw provider material

**Classification:** BLOCKER
**File:** `accrue/lib/accrue/entitlements/observation.ex:71-73,144-152`
**Issue:** The privacy contract says evidence is an optional bounded reference and raw receipts/JWS/provider bodies must not enter these records, but `evidence_ref` only has a nil-pair check. A caller can persist an arbitrarily large raw receipt, signed JWS, or notification body as `evidence_ref` by providing any expiry. This defeats the explicitly privacy-bounded persistence boundary.
**Fix:** Validate `evidence_ref` as a bounded opaque locator (for example, maximum length plus an allowed scheme/format) and reject raw-evidence signatures such as JWT/JWS payloads. Add tests that raw or oversized values are invalid even when `evidence_expires_at` is present.

### CR-03: A grant can claim an observation from another account or rail

**Classification:** BLOCKER
**File:** `accrue/lib/accrue/entitlements/grant.ex:45-48`
**Issue:** `source_observation_id` has only an independent foreign key. Nothing requires the referenced observation to have the grant's `account_id`, `rail`, or `environment`. A projector or repair job can therefore link verified evidence for one account/rail to a grant for another, breaking the provenance boundary and enabling cross-account entitlement attribution.
**Fix:** Enforce the relationship atomically. A robust database solution is a unique key on observation `(id, account_id, rail, environment)` plus a composite foreign key from the same grant fields; alternatively, validate the observation inside the transaction that writes the grant and reject mismatches. Cover account, rail, and environment mismatch cases.

## Warnings

### WR-01: Persistence invariants disappear when changesets are bypassed

**Classification:** WARNING
**File:** `accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs:32-48,110-121,160-167`
**Issue:** The migration declares no checks for allowed rail/environment/state values, non-negative ordering/revisions/retry counts, or positive grant quantity. Those rules exist only in changesets, so `insert_all`, SQL maintenance jobs, or future import/projector code can persist invalid rows. Invalid enum strings can then make Ecto loading fail, while negative quantity/order corrupts projection semantics.
**Fix:** Add named PostgreSQL `CHECK` constraints for the domain enums and numeric bounds, map them with `check_constraint/3` in the corresponding changesets, and add migration-level persistence tests that verify invalid direct inserts are rejected.

---

_Reviewed: 2026-08-02T16:17:27Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
