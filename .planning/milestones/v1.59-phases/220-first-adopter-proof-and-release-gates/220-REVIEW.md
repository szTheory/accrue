---
phase: 220-first-adopter-proof-and-release-gates
reviewed: 2026-08-05T02:59:39Z
depth: standard
files_reviewed: 51
files_reviewed_list:
  - .github/workflows/ci.yml
  - accrue/guides/entitlements.md
  - accrue/guides/multi-rail-offline-release.md
  - accrue/guides/operator-runbooks.md
  - accrue/guides/release-notes.md
  - accrue/lib/accrue/entitlements.ex
  - accrue/lib/accrue/entitlements/admin.ex
  - accrue/lib/accrue/entitlements/offline.ex
  - accrue/lib/accrue/entitlements/offline/registration.ex
  - accrue/lib/accrue/entitlements/reference_scenarios.ex
  - accrue/lib/accrue/entitlements/reference_scenarios/markdown.ex
  - accrue/lib/accrue/entitlements/repair.ex
  - accrue/lib/accrue/entitlements/snapshot.ex
  - accrue/lib/mix/tasks/accrue.entitlements.reference_scenarios.ex
  - accrue/mix.exs
  - accrue/priv/entitlements/v1.59-public-contract.json
  - accrue/priv/entitlements/v1.59-reference-scenarios.json
  - accrue/test/accrue/docs/v159_release_contract_test.exs
  - accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs
  - accrue/test/accrue/entitlements/reference_scenario_device_keys_test.exs
  - accrue/test/accrue/entitlements/reference_scenario_lifecycle_test.exs
  - accrue/test/accrue/entitlements/reference_scenario_offline_policy_test.exs
  - accrue/test/accrue/entitlements/reference_scenario_ordering_test.exs
  - accrue/test/accrue/entitlements/reference_scenario_read_test.exs
  - accrue/test/accrue/entitlements/reference_scenario_reconnect_test.exs
  - accrue/test/accrue/entitlements/reference_scenario_resume_test.exs
  - accrue/test/accrue/entitlements/reference_scenarios_test.exs
  - accrue/test/accrue/entitlements/repair_drills_test.exs
  - accrue/test/support/entitlements/reference_scenario_executor.ex
  - accrue/test/support/entitlements/reference_scenario_executor/device_keys.ex
  - accrue/test/support/entitlements/reference_scenario_executor/lifecycle.ex
  - accrue/test/support/entitlements/reference_scenario_executor/offline_policy.ex
  - accrue/test/support/entitlements/reference_scenario_executor/ordering.ex
  - accrue/test/support/entitlements/reference_scenario_executor/read.ex
  - accrue/test/support/entitlements/reference_scenario_executor/reconnect_cache.ex
  - accrue/test/support/entitlements/reference_scenario_executor/resume.ex
  - examples/accrue_host/docs/adoption-proof-matrix.md
  - examples/accrue_host/docs/capability-limits-matrix.md
  - examples/accrue_host/e2e/entitlement-diagnostics.spec.js
  - examples/accrue_host/lib/accrue_host_web/live/entitlement_diagnostics_live.ex
  - examples/accrue_host/lib/accrue_host_web/router.ex
  - examples/accrue_host/mix.lock
  - examples/accrue_host/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs
  - examples/accrue_host/test/accrue_host/reference_scenario_conformance_test.exs
  - examples/accrue_host/test/accrue_host_web/live/entitlement_diagnostics_live_test.exs
  - examples/crosswake_tracer/README.md
  - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/ReferenceScenarioTests.swift
  - scripts/ci/README.md
  - scripts/ci/verify_adoption_proof_matrix.sh
  - scripts/ci/verify_reference_scenario_contract.sh
  - scripts/ci/verify_release_contract.sh
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 220: Code Review Report

**Reviewed:** 2026-08-05T02:59:39Z
**Depth:** standard
**Files Reviewed:** 51
**Status:** issues_found

## Summary

The Phase 220 release gate runs and its focused aggregate test passes, but its central fixture oracle is materially unenforced: a known fixture/collector disagreement is accepted. This leaves PROOF-02 falsely green in CI. The operator diagnostic also mixes inactive-device evidence into its current-device status, and the claimed modal repair flow is not keyboard-safe.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Aggregate conformance does not enforce the versioned transition oracle

**File:** `accrue/test/support/entitlements/reference_scenario_executor.ex:160-171`

**Issue:** `assert_transition/2` receives `expected_transition`, but most family matchers either discard it (`lifecycle_match?/3` at lines 183-187) or construct hard-coded kind-only checks. The aggregate test therefore accepts a real contract disagreement: `refund_revocation` declares `cache.disposition: "preserve"` in `accrue/priv/entitlements/v1.59-reference-scenarios.json:563-578`, while `Lifecycle` always collects `"replace"` for refunds at `lifecycle.ex:116-119`. `reference_scenario_conformance_test.exs:63-64` still asserts `:ok`, so the merge-blocking proof can pass while its frozen expected result, durable facts, or cache contract is wrong.

**Fix:** Make each family matcher compare every declared `expected_transition.result`, `.durable`, and `.cache` field with independently collected facts; do not replace fixture values with hard-coded values. Correct the refund fixture or collector so those values agree, then add a mutation test that alters each declared expected field and proves aggregate conformance fails.

## Warnings

### WR-01: Revoked or superseded devices can be reported as a recent proof horizon

**File:** `accrue/lib/accrue/entitlements/admin.ex:293-306`

**Issue:** The diagnostic counts active devices to choose `:available` versus `:needs_attention`, but calculates `proof_horizon` from every device. A recently seen revoked or superseded device can therefore yield `state: :needs_attention` and `proof_horizon: :recent`, misleading the operator about whether an active proof is recent.

**Fix:** Filter to active devices before computing both the count and horizon, returning `:unknown` when the filtered list is empty. Add diagnostic coverage for recent revoked and superseded devices.

### WR-02: The repair confirmation dialog is not keyboard-safe despite declaring itself modal

**File:** `examples/accrue_host/lib/accrue_host_web/live/entitlement_diagnostics_live.ex:112-158`

**Issue:** Opening the `aria-modal` dialog does not move focus into it or trap focus, leaving keyboard focus on the triggering control and allowing Tab navigation through the background. The status element at lines 120-123 is focusable but never focused after completion. This contradicts the phase's focus-safe repair-control claim; the browser test does not exercise opening, tabbing, cancelling, or completing the dialog.

**Fix:** Wrap the dialog with Phoenix focus management (for example, `<.focus_wrap id="repair-dialog">`), set initial focus inside it, and restore focus to the trigger on cancel or move it to `#repair-status` after completion. Add browser coverage for those focus transitions.

---

_Reviewed: 2026-08-05T02:59:39Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
