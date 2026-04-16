---
phase: 04
slug: advanced-billing-webhook-hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-14
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Populated by the planner from 04-RESEARCH.md "Validation Architecture" section.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+, OTP 27+) |
| **Config file** | `accrue/test/test_helper.exs`, `accrue/test/support/*.ex` |
| **Quick run command** | `cd accrue && mix test --stale` |
| **Full suite command** | `cd accrue && mix test` |
| **Property tests** | `cd accrue && mix test --only property` (StreamData) |
| **Estimated runtime** | Quick: ~10s · Full: ~45s · +property: ~90s |

---

## Sampling Rate

- **After every task commit:** `mix test --stale`
- **After every plan wave:** `mix test` (full suite)
- **Before `/gsd-verify-work`:** Full suite green + `mix credo --strict` + `mix dialyzer`
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

*Populated by the planner from 04-RESEARCH.md test pillars. Each pillar maps to one or more plan tasks with automated test commands.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _TBD_ | — | — | — | — | — | — | — | — | ⬜ pending |

---

## Wave 0 Requirements

*Populated by the planner from 04-RESEARCH.md Wave 0 gap list. Examples based on research findings:*

- [ ] `accrue/test/accrue/billing/meter_events_test.exs` — BILL-13 outbox + reconciler test stubs
- [ ] `accrue/test/accrue/billing/dunning_test.exs` — BILL-15 sweeper + grace policy stubs
- [ ] `accrue/test/accrue/webhooks/dlq_test.exs` — WH-08 requeue/requeue_where stubs
- [ ] `accrue/test/accrue/checkout/session_test.exs` — CHKT-01/02/03 stubs
- [ ] `accrue/test/accrue/billing_portal/session_test.exs` — CHKT-04/05/06 stubs
- [ ] `accrue/test/accrue/events/upcaster_registry_test.exs` — EVT-05 chain composition
- [ ] `accrue/test/accrue/events/query_test.exs` — EVT-06/10 timeline_for/state_as_of/bucket_by
- [ ] `accrue/test/support/processor/fake.ex` — extend with `report_meter_event/1`, `checkout_session_create/2`, `portal_session_create/2`, `subscription_schedule_*`, `coupon_create/2`, `promotion_code_create/2`
- [ ] `accrue/test/support/stripe_fixtures.ex` — canned payloads for ~10 new webhook event types (`customer.subscription.paused`, `customer.subscription.resumed`, `subscription_schedule.*`, `checkout.session.completed`, `billing_portal.session.created`, `invoice.payment_action_required`, etc.)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Stripe Dashboard Smart Retries config | BILL-15 | Dashboard-only setting, not API-writable | Install guide documents: enable Smart Retries, set attempts, confirm webhook `invoice.payment_failed` still fires |
| Customer Portal Configuration (CHKT-05) | CHKT-05 | `BillingPortal.Configuration` API deferred to lattice_stripe 1.2 | Install guide checklist: create portal config in Dashboard with "Cancel immediately" disabled, capture `bpc_...` ID for `Accrue.BillingPortal.Session.create(configuration: ...)` |
| Checkout hosted-mode round-trip | CHKT-01/02 | Requires real browser to complete Stripe-hosted form | Manual test script: create session, redirect, submit test card, verify success_url + webhook delivery |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references from 04-RESEARCH.md
- [ ] Property tests declared for money math (discount composition BILL-27/28, grace-period arithmetic BILL-15)
- [ ] Fake processor extensions (`report_meter_event`, `checkout_session_create`, `portal_session_create`, `subscription_schedule_*`) in place
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
