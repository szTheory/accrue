---
phase: 217
slug: canonical-projection-and-compatibility
status: ready
nyquist_compliant: true
wave_0_complete: false
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
| **Full suite command** | `cd accrue && mix test.all` |
| **Estimated runtime** | Measure during Wave 0 |

## Sampling Rate

- **After every task commit:** Run focused ExUnit files plus `mix format --check-formatted`
- **After every plan wave:** Run `cd accrue && mix test test/accrue/entitlements --exclude live_stripe`
- **Before `$gsd-verify-work`:** Run `cd accrue && mix test.all`; the full suite must be green
- **Max feedback latency:** Measure and record during Wave 0

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 217-01-01, 217-02-01 | 217-01, 217-02 | 1-2 | ACCT-01 | T-217-01, T-217-05 | Deterministic union/dedupe/max snapshot without grant loss | unit + property | `cd accrue && mix test test/accrue/entitlements/snapshot_test.exs test/property/entitlement_projection_property_test.exs` | ❌ W0 planned | ⬜ pending |
| 217-01-01, 217-02-02 | 217-01, 217-02 | 1-2 | ACCT-02 | T-217-01, T-217-06 | Source-local retraction and serialized semantic revisions | integration + property | `cd accrue && mix test test/accrue/entitlements/projector_test.exs test/property/entitlement_projection_property_test.exs` | ❌ W0 planned | ⬜ pending |
| 217-05-01, 217-05-02 | 217-05 | 3 | ACCT-03 | T-217-16, T-217-18 | Persisted-rail dispatch prevents cross-provider mutation | unit + integration | `cd accrue && mix test test/accrue/billing/resource_dispatch_test.exs` | ❌ W0 planned | ⬜ pending |
| 217-04-01, 217-04-02 | 217-04 | 2 | ACCT-04 | T-217-12, T-217-15 | Disabled/shadow/enabled cutover preserves legacy parity | integration | `cd accrue && mix test test/accrue/entitlements/compatibility_test.exs` | ❌ W0 planned | ⬜ pending |
| 217-03-01, 217-03-02 | 217-03 | 2 | ACCT-05 | T-217-08, T-217-11 | Revision-bound decisions block stale or equivalent cross-rail purchases | unit + integration | `cd accrue && mix test test/accrue/entitlements/purchase_decision_test.exs` | ❌ W0 planned | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [x] `accrue/test/accrue/entitlements/snapshot_test.exs` and `accrue/test/property/entitlement_projection_property_test.exs` — created before implementation by 217-01-01 and 217-02-01 for ACCT-01/02 semantic invariants
- [x] `accrue/test/accrue/entitlements/projector_test.exs` — created before implementation by 217-01-01 and expanded by 217-02-02 for row-lock, ordering, revision, audit, and concurrency proof
- [x] `accrue/test/accrue/entitlements/compatibility_test.exs` and `accrue/test/accrue/entitlements/purchase_decision_test.exs` — created before implementation by 217-04-01 and 217-03-01 for ACCT-04/05 contracts
- [x] `accrue/test/accrue/billing/resource_dispatch_test.exs` — created before implementation by 217-05-01 for ACCT-03 persisted-processor dispatch and negative Apple isolation

## Manual-Only Verifications

All phase behaviors are expected to have automated verification. Any irreducible host-facing guidance check must be added here by the planner with explicit instructions.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or create their Wave 0 dependency before production code
- [x] Sampling continuity: every task has focused automated verification
- [x] Wave 0 covers all MISSING references through the task IDs above
- [x] No watch-mode flags
- [ ] Feedback latency is measured and acceptable
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planned; runtime/latency fields complete during execution
