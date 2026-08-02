---
phase: 216-additive-rail-and-persistence-foundation
reviewed: 2026-08-02T18:31:46Z
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
  - accrue/priv/repo/migrations/20260802200000_bound_accrue_entitlement_provider_identity.exs
  - accrue/test/accrue/config_entitlements_test.exs
  - accrue/test/accrue/docs/entitlements_guide_test.exs
  - accrue/test/accrue/entitlements/fake_fixture_test.exs
  - accrue/test/accrue/entitlements/persistence_test.exs
  - accrue/test/mix/tasks/accrue_install_test.exs
  - accrue/test/support/entitlements/fixtures.ex
findings:
  critical: 3
  warning: 0
  info: 0
  total: 3
status: issues_found
---

# Phase 216: Code Review Report

**Reviewed:** 2026-08-02T18:31:46Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The additive-rail configuration and durable-record boundaries were reviewed, including migrations, runtime validation, and persistence tests. The stated privacy boundary is not actually enforced for observation metadata or device identity fields. In addition, relying on the documented schema default for `:processor` makes an otherwise valid additive-rail configuration crash during boot validation.

## Critical Issues

### CR-01: Observation metadata permits arbitrary PII and provider payload fragments

**File:** `/Users/jon/projects/accrue/accrue/lib/accrue/entitlements/observation.ex:211`
**Issue:** The privacy boundary claims metadata must not retain PII or provider bodies, but validation only rejects a small substring deny-list. For example, `%{"source" => "customer@example.com"}` is accepted (verified directly), as are phone numbers, addresses, and arbitrary provider JSON fragments with neutral key names. These values are then persisted in the queryable `metadata` column. This defeats the documented durable-record privacy guarantee.
**Fix:** Replace the deny-list with an allow-list of the few normalized metadata keys and constrained enum/scalar values needed by projection. If free-form metadata is not required, remove it from `@ingest_fields`; also add an equivalent database constraint or store only a fixed typed projection.

### CR-02: Device identity fields accept raw personal/device data

**File:** `/Users/jon/projects/accrue/accrue/lib/accrue/entitlements/device.ex:27`
**Issue:** `installation_id` and `key_thumbprint` are merely required. A value such as `"Jane Doe iPhone"` or `"customer@example.com"` is accepted (verified directly) and persisted, despite the guide's explicit prohibition on physical-device data and PII. `key_thumbprint` is particularly unsafe because no digest/thumbprint format is enforced.
**Fix:** Define bounded identifier formats for `installation_id` and a fixed cryptographic-thumbprint encoding/length for `key_thumbprint`, validate them in the changeset, and add matching database checks. If installation IDs can contain host-controlled text, store a one-way digest instead of the raw value.

### CR-03: Additive rails crash when the schema's default processor is used

**File:** `/Users/jon/projects/accrue/accrue/lib/accrue/config.ex:1256`
**Issue:** `validate_at_boot!/0` validates the configuration but discards NimbleOptions' normalized result. When a host relies on the declared default `processor: Accrue.Processor.Fake` and configures a `:rails` entry, `validate_rails!/1` calls `Keyword.fetch!(opts, :processor)` on the unnormalized raw env and raises `KeyError`. This was reproduced with a valid test `:host_fake` rail and no explicit `:processor` setting. The feature fails to boot instead of honoring its schema default.
**Fix:** Pass the normalized result from `NimbleOptions.validate!/2` into `maybe_validate_boot_setup!/1`, or use `Keyword.get(opts, :processor, Accrue.Processor.Fake)` in `validate_rails!/1` (and audit other cross-field validation for the same raw-default assumption).

---

_Reviewed: 2026-08-02T18:31:46Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
