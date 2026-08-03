---
phase: 217
slug: canonical-projection-and-compatibility
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-02
---

# Phase 217 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (existing project) |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/entitlements --exclude live_stripe` |
| **Full suite command** | `cd accrue && mix test --warnings-as-errors` |
| **Estimated runtime** | ~29s full suite; focused phase gate under 2s |

## Sampling Rate

- **After every task commit:** Run focused ExUnit files plus `mix format --check-formatted`
- **After every plan wave:** Run `cd accrue && mix test test/accrue/entitlements --exclude live_stripe`
- **Before phase verification:** Run `cd accrue && mix test --warnings-as-errors`; the full suite must be green
- **Max feedback latency:** Measure and record during Wave 0

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 217-01-01, 217-02-01 | 217-01, 217-02 | 1-2 | ACCT-01 | T-217-01, T-217-05 | Deterministic union/dedupe/max snapshot without grant loss | unit + property | `cd accrue && mix test test/accrue/entitlements/snapshot_test.exs test/property/entitlement_projection_property_test.exs` | ✅ | ✅ green |
| 217-01-01, 217-02-02 | 217-01, 217-02 | 1-2 | ACCT-02 | T-217-01, T-217-06 | Source-local retraction and serialized semantic revisions | integration + property | `cd accrue && mix test test/accrue/entitlements/projector_test.exs test/property/entitlement_projection_property_test.exs` | ✅ | ✅ green |
| 217-05-01, 217-05-02 | 217-05 | 3 | ACCT-03 | T-217-16, T-217-18 | Persisted-rail dispatch prevents cross-provider mutation | unit + integration | `cd accrue && mix test test/accrue/billing/resource_dispatch_test.exs` | ✅ | ✅ green |
| 217-04-01, 217-04-02 | 217-04 | 2 | ACCT-04 | T-217-12, T-217-15 | Disabled/shadow/enabled cutover preserves legacy parity | integration | `cd accrue && mix test test/accrue/entitlements/compatibility_test.exs` | ✅ | ✅ green |
| 217-03-01, 217-03-02 | 217-03 | 2 | ACCT-05 | T-217-08, T-217-11 | Revision-bound decisions block stale or equivalent cross-rail purchases | unit + integration | `cd accrue && mix test test/accrue/entitlements/purchase_decision_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [x] `accrue/test/accrue/entitlements/snapshot_test.exs` and `accrue/test/property/entitlement_projection_property_test.exs` — created before implementation by 217-01-01 and 217-02-01 for ACCT-01/02 semantic invariants
- [x] `accrue/test/accrue/entitlements/projector_test.exs` — created before implementation by 217-01-01 and expanded by 217-02-02 for row-lock, ordering, revision, audit, and concurrency proof
- [x] `accrue/test/accrue/entitlements/compatibility_test.exs` and `accrue/test/accrue/entitlements/purchase_decision_test.exs` — created before implementation by 217-04-01 and 217-03-01 for ACCT-04/05 contracts
- [x] `accrue/test/accrue/billing/resource_dispatch_test.exs` — created before implementation by 217-05-01 for ACCT-03 persisted-processor dispatch and negative Apple isolation

## Human Verification

None. The zero-human policy requires `type="auto"` tasks and an `<automated>` verify block. The reusable `Accrue.BackendAutomationContractTest` rejects tracer tasks, human-verify tasks, and missing automated verification blocks. No manual verification, UAT, or auto-approval is used.

## Plan 217-01 Measured Evidence

| Command | Result | Runtime |
|---------|--------|---------|
| `cd accrue && mix test test/accrue/entitlements/snapshot_test.exs test/accrue/entitlements/projector_test.exs test/accrue/backend_automation_contract_test.exs` | 10 tests, 0 failures | 0.2s |
| `cd accrue && mix test test/accrue/entitlements --exclude live_stripe` | 159 tests, 0 failures | 1.5s |
| `cd accrue && mix format --check-formatted lib/accrue/entitlements/snapshot.ex lib/accrue/entitlements/projector.ex lib/accrue/entitlements.ex test/accrue/entitlements/snapshot_test.exs test/accrue/entitlements/projector_test.exs test/accrue/backend_automation_contract_test.exs` | exit 0 | under 1s |
| `cd accrue && mix compile --warnings-as-errors` | exit 0 | under 1s |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or create their Wave 0 dependency before production code
- [x] Sampling continuity: every task has focused automated verification
- [x] Wave 0 covers all MISSING references through the task IDs above
- [x] No watch-mode flags
- [x] Feedback latency is measured and acceptable (focused 0.2s; wave 1.5s)
- [x] `nyquist_compliant: true` set in frontmatter
- [x] Two consecutive randomized full suites passed: 67 properties, 1882 tests, 0 failures at seeds 567304 and 596642
- [x] Independent deep code review is clean with 0 residual findings

**Approval:** not applicable — Phase 217 has executable zero-human verification.

The recurring repository CI already runs formatting, the warnings-as-errors full suite, and Credo strict. No phase-specific workflow was added because the existing gate exercises this behavior on every change.
