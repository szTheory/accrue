---
phase: 146
slug: at-risk-query-at-risk-table-last-failure-enrichment
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 146 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs` |
| **Quick run (accrue)** | `cd accrue && mix test test/accrue/analytics/dunning_test.exs test/accrue/billing/query_test.exs test/accrue/webhook/dunning_campaign_start_test.exs` |
| **Quick run (admin)** | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| **Full suite command** | `cd accrue && mix test` (then `cd accrue_admin && mix test`) |
| **Estimated runtime** | ~30 seconds (quick), ~90 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue && mix test test/accrue/analytics/dunning_test.exs test/accrue/billing/query_test.exs`
- **After every plan wave:** Run full suite for the modified package
- **Before `/gsd:verify-work`:** Both `accrue` and `accrue_admin` full suites must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| emit_campaign_started /2 refactor | — | 1 | DAN-04 | unit | `cd accrue && mix test test/accrue/webhook/dunning_campaign_start_test.exs` | ⬜ pending |
| in_active_dunning_campaign/1 | — | 1 | DAN-03 | unit | `cd accrue && mix test test/accrue/billing/query_test.exs` | ⬜ pending |
| at_risk_subscriptions/1 core query | — | 2 | DAN-03 | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ⬜ pending |
| projection-lag race test | — | 2 | DAN-03 SC2 | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ⬜ pending |
| ETA nil fallback | — | 2 | DAN-03 | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ⬜ pending |
| pre-v1.44 honest default | — | 2 | DAN-04 | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ⬜ pending |
| RecoveryLive at-risk table render | — | 3 | DAN-11 SC1 | integration | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | ⬜ pending |
| Window change refreshes at-risk | — | 3 | DAN-11 | integration | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | ⬜ pending |
| Cross-package boundary assertion | — | 3 | DAN-11 SC4 | static | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/analytics/at_risk_subscriptions_test.exs` or extend `dunning_test.exs` with `use Accrue.BillingCase, async: false` + `use Oban.Testing, repo: Accrue.TestRepo` (needed for Oban job insertion in ETA tests)
- [ ] Verify `accrue/test/accrue/webhook/dunning_campaign_start_test.exs` exists and can be extended with `invoice_id` assertion

*Note: Existing `dunning_test.exs` uses `Accrue.RepoCase` which does NOT include Oban setup. The `at_risk_subscriptions/1` tests that need Oban job insertion may need to be in a separate file or the module must be changed to `BillingCase`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| At-risk table visible in browser below funnel | DAN-11 SC1 | Visual layout check | Visit `/billing/analytics/recovery` in dev server; confirm table appears below FunnelChart |
| Column order: customer link, days, step, ETA, failure reason | DAN-11 SC1 | Visual inspection | Verify column labels match spec |
| Customer link navigates to customer detail | DAN-11 SC1 | Browser navigation | Click a customer link, verify route |
| "—" shown for nil ETA and nil failure_reason | DAN-03, DAN-04 | Visual check | Inspect table row with no pending Oban job |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
