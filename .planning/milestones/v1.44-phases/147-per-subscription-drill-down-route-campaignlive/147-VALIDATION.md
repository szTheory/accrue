---
phase: 147
slug: per-subscription-drill-down-route-campaignlive
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 147 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest |
| **Config file** | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` |
| **Full suite command** | `cd accrue && mix test && cd ../accrue_admin && mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue && mix test test/accrue/analytics/dunning_test.exs`
- **After every plan wave:** Run `cd accrue && mix test && cd ../accrue_admin && mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| campaign_timeline/2 implementation | 01 | 1 | DAN-05 | T-147-03 (SQL injection) | Ecto parameterized query; no raw SQL | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ✅ (add cases) | ⬜ pending |
| campaign_timeline_grouped/2 implementation | 01 | 1 | DAN-05 | — | N/A — pure function, no DB | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ✅ (add cases) | ⬜ pending |
| invoices_for_campaign/2 implementation | 01 | 1 | DAN-12 | T-147-02 (IDOR), T-147-03 | Ecto parameterized query; admin-only route | integration | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ✅ (add cases) | ⬜ pending |
| CampaignLive + router | 02 | 2 | DAN-12 | T-147-01 (unauthorized access) | live_session :accrue_admin blocks non-admin | LiveView | `cd accrue_admin && mix test test/accrue_admin/live/analytics/campaign_live_test.exs` | ❌ Wave 0 | ⬜ pending |
| CampaignTimeline component | 02 | 2 | DAN-12 | — | N/A — pure render component | LiveView | `cd accrue_admin && mix test test/accrue_admin/live/analytics/campaign_live_test.exs` | ❌ Wave 0 | ⬜ pending |
| Cross-package boundary | 02 | 2 | DAN-12, D-04 | T-147-05 | CampaignLive has no Ecto.Query/Repo/Billing.* | static grep | `cd accrue_admin && mix test test/accrue_admin/live/analytics/campaign_live_test.exs` | ❌ Wave 0 | ⬜ pending |
| RecoveryLive row-click link | 03 | 2 | DAN-12 | — | N/A | LiveView | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | ✅ (add assertion) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs` — new test file covering DAN-12 LiveView cases + boundary assertion
- [ ] Add `describe "campaign_timeline/2"`, `describe "campaign_timeline_grouped/2"`, `describe "invoices_for_campaign/2"` blocks to `accrue/test/accrue/analytics/dunning_test.exs`
- [ ] Add at-risk table row-link assertion to `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs`

*No new test framework install needed — ExUnit + Phoenix.LiveViewTest already in place.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser nav: click at-risk row → lands on `/billing/analytics/recovery/subscriptions/:id` | DAN-12 | End-to-end browser navigation | Start `accrue_admin` dev server; navigate to `/billing/analytics/recovery`; click a row in AtRiskTable; confirm URL changes and timeline renders |

---

## Threat Map (Security)

| Threat ID | Pattern | STRIDE | Mitigation | Testable? |
|-----------|---------|--------|------------|-----------|
| T-147-01 | Unauthorized drill-down access | Elevation of Privilege | `live_session :accrue_admin` with `ensure_admin` on_mount hook — no new bypass surface | Via LiveView test confirming redirect for unauthenticated user |
| T-147-02 | IDOR via subscription_id | Information Disclosure | Admin-only route; authorized operators have full access by design | N/A — no owner-scoping required for admin-only route |
| T-147-03 | SQL injection via subscription_id | Tampering | Ecto parameterized queries — `^subscription_id` bound safely; malformed UUID → empty result, no crash | Unit test with malformed subscription_id confirming empty map return |
| T-147-04 | PII in event data logged | Information Disclosure | `dunning.*` event data has only `invoice_id` (Stripe ID) and `campaign_anchor` (ISO timestamp) — no PII per data model | Static audit — `dunning.ex` never logs event data fields |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
