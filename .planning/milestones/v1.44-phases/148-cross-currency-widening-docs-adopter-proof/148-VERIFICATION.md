---
phase: 148-cross-currency-widening-docs-adopter-proof
verified: 2024-05-28T00:00:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
gaps: []
---

# Phase 148: Cross-currency widening + recovery-rate API + public docs + adopter-proof Verification Report

**Phase Goal:** The v1.44 public API surface (`Accrue.Analytics.Dunning.{recovered_vs_lost_mrr, funnel, at_risk_subscriptions, campaign_timeline, recovery_rate}/1`) freezes for the next Hex publish — currency-correct, documented, adopter-provable end-to-end against deterministic-clock seed data in `examples/accrue_host`.
**Verified:** 2024-05-28T00:00:00Z
**Status:** passed
**Re-verification:** No

## Goal Achievement

### Observable Truths

| #   | Truth   | Status     | Evidence       |
| --- | ------- | ---------- | -------------- |
| 1   | recovered_vs_lost_mrr/1 returns lists of currency amounts instead of flattened totals | ✓ VERIFIED | Implementation in `accrue/lib/accrue/analytics/dunning.ex` |
| 2   | recovery_rate/1 returns the arithmetic rate of recovered/(recovered+exhausted) | ✓ VERIFIED | Implementation in `accrue/lib/accrue/analytics/dunning.ex` |
| 3   | RecoveryLive renders KPI cards per currency and 'Showing data since...' | ✓ VERIFIED | Multi-currency loops over `kpi_pairs` implemented |
| 4   | Analytics guide is available in ExDoc, module docs updated, `verify_package_docs.sh` checks | ✓ VERIFIED | `guides/analytics.md` exists and verified by script |
| 5   | examples/accrue_host mounts a fully populated Recovery dashboard using seeded data | ✓ VERIFIED | Seed script updated, `recovery_analytics_test.exs` proves it |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected    | Status | Details |
| -------- | ----------- | ------ | ------- |
| `accrue/lib/accrue/analytics/dunning.ex` | Widened API shapes and recovery rate calculation | ✓ VERIFIED | Contains widened APIs |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | Multi-currency KPI Cards | ✓ VERIFIED | Contains `kpi_pairs` logic |
| `accrue/guides/analytics.md` | Public documentation | ✓ VERIFIED | Exists with expected sections |
| `examples/accrue_host/priv/repo/seeds.exs` | Deterministic dunning events | ✓ VERIFIED | Utilizes `Accrue.Clock` |
| `examples/accrue_host/test/.../recovery_analytics_test.exs` | UI rendering proof | ✓ VERIFIED | Passes UI assert tests |

### Key Link Verification

| From | To  | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `Accrue.Analytics.Dunning.recovery_rate/1` | `funnel/1` | delegation | ✓ VERIFIED | Delegate via `stats = funnel(opts)` |
| `RecoveryLive` | `Accrue.Analytics.Dunning` | stats access | ✓ VERIFIED | `stats.recovered`, `stats.lost` used |
| `verify_package_docs.sh` | `guides/analytics.md` | grep verification | ✓ VERIFIED | Script runs and passes `100k events` regex |
| `adoption-proof-matrix.md` | `priv/repo/seeds.exs` | doc link | ✓ VERIFIED | Link to seeds present |

### Requirements Coverage

All goals mapped to tasks in plans are present and properly documented.

### Gaps Summary

No gaps found. All automated checks and artifact verifications passed.