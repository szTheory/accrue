---
phase: 216-additive-rail-and-persistence-foundation
reviewed: 2026-08-02T18:42:53Z
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
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 216: Code Review Report

**Reviewed:** 2026-08-02T18:42:53Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** clean

## Summary

This re-review checked fixes `2041b197`, `1028bf3e`, `3016410e`, and `c4340c22` against the prior blockers. CR-01 is closed: observation metadata now has an exact application allow-list and a matching PostgreSQL check. CR-02 is closed within the locked Phase 216 scope: D-14 and Task 3 make device identity a bounded, account-scoped storage key only, explicitly deferring semantic P-256 validation and canonical thumbprint recomputation to the later registration/proof runtime. CR-03 is closed: boot validation now passes NimbleOptions' normalized options into cross-field validation.

The device token grammar cannot prove a token was not derived from PII, but enforcing a cryptographic digest or proof format here would introduce the deferred Phase 219 contract. The current Ecto and PostgreSQL bounds reject obvious raw human/device forms while preserving the required opaque, deterministic fixture boundary. No in-scope Phase 216 defect remains.

---

_Reviewed: 2026-08-02T18:42:53Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
