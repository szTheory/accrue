---
phase: 217
slug: canonical-projection-and-compatibility
status: draft
nyquist_compliant: false
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
| TBD | TBD | 0 | ACCT-01 | TBD | Deterministic union/dedupe/max snapshot without grant loss | unit + property | `cd accrue && mix test test/accrue/entitlements/snapshot_test.exs test/property/entitlement_projection_property_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | 0 | ACCT-02 | TBD | Source-local retraction and serialized semantic revisions | integration + property | `cd accrue && mix test test/accrue/entitlements/projector_test.exs test/property/entitlement_projection_property_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | 0 | ACCT-03 | TBD | Persisted-rail dispatch prevents cross-provider mutation | unit + integration | `cd accrue && mix test test/accrue/billing/resource_dispatch_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | 0 | ACCT-04 | TBD | Disabled/shadow/enabled cutover preserves legacy parity | integration | `cd accrue && mix test test/accrue/entitlements/compatibility_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | 0 | ACCT-05 | TBD | Revision-bound decisions block stale or equivalent cross-rail purchases | unit + integration | `cd accrue && mix test test/accrue/entitlements/purchase_decision_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [ ] `accrue/test/accrue/entitlements/snapshot_test.exs` and `accrue/test/property/entitlement_projection_property_test.exs` — ACCT-01/02 semantic invariants
- [ ] `accrue/test/accrue/entitlements/projector_test.exs` — row-lock, ordering, revision, and audit proof
- [ ] `accrue/test/accrue/entitlements/compatibility_test.exs` and `accrue/test/accrue/entitlements/purchase_decision_test.exs` — ACCT-04/05 contracts
- [ ] `accrue/test/accrue/billing/resource_dispatch_test.exs` — ACCT-03 persisted-processor dispatch and negative Apple isolation

## Manual-Only Verifications

All phase behaviors are expected to have automated verification. Any irreducible host-facing guidance check must be added here by the planner with explicit instructions.

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency is measured and acceptable
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
