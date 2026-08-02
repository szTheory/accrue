---
phase: 216-additive-rail-and-persistence-foundation
reviewed: 2026-08-02T17:47:01Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - accrue/guides/entitlements.md
  - accrue/lib/accrue/config.ex
  - accrue/lib/accrue/entitlements/account.ex
  - accrue/lib/accrue/entitlements/device.ex
  - accrue/lib/accrue/entitlements/grant.ex
  - accrue/lib/accrue/entitlements/observation.ex
  - accrue/priv/accrue/templates/install/runtime_config.exs.eex
  - accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs
  - accrue/priv/repo/migrations/20260802180000_harden_accrue_entitlement_persistence.exs
  - accrue/test/accrue/config_entitlements_test.exs
  - accrue/test/accrue/docs/entitlements_guide_test.exs
  - accrue/test/accrue/entitlements/fake_fixture_test.exs
  - accrue/test/accrue/entitlements/persistence_test.exs
  - accrue/test/mix/tasks/accrue_install_test.exs
  - accrue/test/support/entitlements/fixtures.ex
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 216: Code Review Report

**Reviewed:** 2026-08-02T17:47:01Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The reviewed persistence boundary has a cross-account observation identity flaw: a collision is treated as a successful idempotent ingest and returns another account's record. Provider-controlled identity fields are also unbounded despite being persisted indefinitely. The focused test suite passed (72 tests), but it does not exercise either boundary.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Cross-account identity collisions return another account's observation

**File:** `/Users/jon/projects/accrue/accrue/lib/accrue/entitlements/observation.ex:115-120,219-242`; `/Users/jon/projects/accrue/accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs:53-69`

**Issue:** Both unique identities exclude `account_id`, while `insert_idempotently/2` turns every conflict into `{:ok, fetch_by_identity!(...)}`. Therefore, if account B submits the same rail/environment/event ID (or transaction ID + kind) as account A, PostgreSQL discards B's insert and this function returns A's durable observation as a successful result. This crosses the durable account boundary and makes a malformed or misrouted provider event silently appear accepted for the wrong owner; callers can also read the other account's normalized provenance through the returned struct.

**Fix:** Decide whether provider identities are globally unique or account-scoped, then make the API enforce that decision. If they are account-scoped, include `account_id` in both partial unique indexes, `conflict_target/1`, and `fetch_by_identity!/2`. If globally unique, retain the indexes but make the fetch query verify `observation.account_id == ^account_id` and return an explicit collision/error when it differs. Add integration tests for both event and transaction fallback collisions across two accounts.

## Warnings

### WR-01: Provider identity fields have no size bounds

**File:** `/Users/jon/projects/accrue/accrue/lib/accrue/entitlements/observation.ex:52-76`; `/Users/jon/projects/accrue/accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs:32-48`

**Issue:** Ingest accepts unbounded `provider_event_id`, `provider_transaction_id`, `kind`, `provider_lineage_id`, and `provider_product_id`; PostgreSQL `:string` maps to unconstrained text here. These values are provider-originated and retained in rows and indexes, so an oversized event can exhaust storage/index resources even though metadata and evidence references are explicitly bounded.

**Fix:** Define realistic maximum byte lengths for each normalized identifier, enforce them with `validate_length/3`, and add matching database `octet_length(...) <= N` checks so alternate writers cannot bypass the boundary. Add over-limit changeset and database tests.

---

_Reviewed: 2026-08-02T17:47:01Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
