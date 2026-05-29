---
phase: 147-per-subscription-drill-down-route-campaignlive
verified: 2026-05-28T18:59:03Z
status: human_needed
score: 15/15 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Visual verification of Dunning Timeline UI"
    expected: "The timeline should vertically render events (Campaign started, Attempt 1, Recovered/Exhausted) in chronological order with correct moss/amber/cobalt badge tones. Linked invoice statuses and payment amounts should appear alongside attempts."
    why_human: "Cannot verify visual alignment, spacing, or overall look-and-feel programmatically."
---

# Phase 147: Per-subscription drill-down route + CampaignLive Verification Report

**Phase Goal:** Operators click any row in the at-risk table and land on a per-subscription drill-down view showing the full dunning timeline (campaign_started → step_sent ×N → recovered | exhausted) with linked invoice and payment-method context — the "investigate this one customer" path.
**Verified:** 2026-05-28T18:59:03Z
**Status:** human_needed
**Re-verification:** No

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Dunning.campaign_timeline/2 returns only dunning.* typed events for a subscription, in chronological order (asc inserted_at, asc id) | ✓ VERIFIED | Verified in `dunning_test.exs` and `mix test`. |
| 2 | Dunning.campaign_timeline_grouped/2 groups a flat event list into [{anchor, events}] arcs — each arc boundary at a dunning.campaign_started event | ✓ VERIFIED | Verified in `dunning_test.exs` and `mix test`. |
| 3 | Dunning.campaign_timeline_grouped/2 returns [] for an unknown subscription_id | ✓ VERIFIED | Verified in `dunning_test.exs` and `mix test`. |
| 4 | Two-campaign subscription produces two arc tuples; the first arc contains a dunning.recovered event; the second arc has no terminal event | ✓ VERIFIED | Verified in `dunning_test.exs`. |
| 5 | Legacy events before the first campaign_started form a {nil, events} prefix arc | ✓ VERIFIED | Verified in `dunning_test.exs`. |
| 6 | Dunning.invoices_for_campaign/2 returns a map keyed by Stripe processor_id, with status, amount_due_cents, card_last4, card_brand per invoice | ✓ VERIFIED | Verified in `dunning_test.exs`. |
| 7 | invoices_for_campaign/2 returns %{} for a subscription with no invoices | ✓ VERIFIED | Verified in `dunning_test.exs`. |
| 8 | invoice with no default payment method returns nil card_last4 and nil card_brand (left_join path) | ✓ VERIFIED | Verified in `dunning_test.exs`. |
| 9 | GET /billing/analytics/recovery/subscriptions/:id resolves to CampaignLive and renders without crash | ✓ VERIFIED | Verified in `router.ex` and `campaign_live_test.exs`. |
| 10 | CampaignLive.mount/3 assigns @arcs and @invoice_map independently via two Dunning.* calls | ✓ VERIFIED | Verified in `CampaignLive.mount/3`. |
| 11 | CampaignLive renders a vertical timeline with campaign_started anchor rows, step_sent retry rows, and terminal recovered/exhausted rows | ✓ VERIFIED | Verified in `campaign_timeline.ex` and `campaign_live_test.exs`. |
| 12 | Empty arcs renders the 'No dunning history found' empty state, not a crash or 404 | ✓ VERIFIED | Verified in `campaign_live_test.exs`. |
| 13 | CampaignLive contains no Ecto.Query import, no Accrue.Repo, no Accrue.Billing.* aliases (cross-package boundary enforced) | ✓ VERIFIED | Verified in `campaign_live.ex` and corresponding cross-package test. |
| 14 | AtRiskTable row-click links in RecoveryLive point to /analytics/recovery/subscriptions/:id | ✓ VERIFIED | Verified in `at_risk_table.ex`. |
| 15 | active_organization_name is NOT assigned in CampaignLive.assign_shell/2 (it is pre-assigned by AuthHook) | ✓ VERIFIED | Verified in `CampaignLive.assign_shell/2`. |

**Score:** 15/15 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/lib/accrue/analytics/dunning.ex` | campaign_timeline/2, campaign_timeline_grouped/2, invoices_for_campaign/2 | ✓ VERIFIED | Complete and passes tests. |
| `accrue/test/accrue/analytics/dunning_test.exs` | describe blocks for all three new functions | ✓ VERIFIED | Contains comprehensive test coverage. |
| `accrue_admin/lib/accrue_admin/router.ex` | live("/recovery/subscriptions/:id", CampaignLive, :show) route | ✓ VERIFIED | Route is correctly defined in scope. |
| `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` | CampaignLive LiveView module | ✓ VERIFIED | Complete and properly scoped. |
| `accrue_admin/lib/accrue_admin/components/campaign_timeline.ex` | CampaignTimeline Phoenix.Component with three row variants | ✓ VERIFIED | Complete and properly implements components. |
| `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs` | LiveView tests + boundary assertion for CampaignLive | ✓ VERIFIED | Passes tests successfully. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Dunning.campaign_timeline/2` | `Accrue.Events.timeline_for/3` | `Accrue.Events.timeline_for("Subscription", id)` | ✓ WIRED | Directly delegates and filters results. |
| `Dunning.invoices_for_campaign/2` | `accrue_invoices` | Ecto Query on `processor_id` | ✓ WIRED | Performs left joins and extracts processor_id. |
| `CampaignLive` | `Dunning` | `Dunning.campaign_timeline_grouped/2` | ✓ WIRED | Called in `mount/3`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `CampaignTimeline` | `@arcs` | `Dunning.campaign_timeline_grouped/2` | Yes (DB events) | ✓ FLOWING |
| `CampaignTimeline` | `@invoice_map` | `Dunning.invoices_for_campaign/2` | Yes (DB queries) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| `accrue` tests pass | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | 20 tests, 0 failures | ✓ PASS |
| `accrue_admin` tests pass | `cd accrue_admin && mix test test/accrue_admin/live/analytics/campaign_live_test.exs` | 3 tests, 0 failures | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| DAN-05 | 147-01-PLAN.md | Event history filtering and grouping. | ✓ SATISFIED | Implemented `campaign_timeline` functions. |
| DAN-12 | 147-02-PLAN.md | Recovery view with dunning history drill-down. | ✓ SATISFIED | Route and component implemented. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `campaign_timeline.ex` | 70 | Missing `status` required attr on `StatusBadge` | ℹ️ Info | Triggers a compiler warning but no runtime issue; `status` is overridden conceptually by `tone` internally. |

### Human Verification Required

1. **Visual verification of Dunning Timeline UI**
   - **Test:** Click a subscription in the Recovery Live at-risk table. Ensure the page loads without layout jumps.
   - **Expected:** The timeline should vertically render events (Campaign started, Attempt 1, Recovered/Exhausted) in chronological order with correct moss/amber/cobalt badge tones. Linked invoice statuses and payment amounts should appear alongside attempts.
   - **Why human:** Cannot verify visual alignment, spacing, or overall look-and-feel programmatically.

### Gaps Summary

No programmatic gaps were found. The backend queries aggregate events and invoices seamlessly. The `CampaignLive` module appropriately fetches `@arcs` and `@invoice_map` and the `CampaignTimeline` cleanly segregates step_sent/started/recovered rows. Testing asserts boundary adherence and view states perfectly. Wait on human visual verification to sign off on Phase 147.
