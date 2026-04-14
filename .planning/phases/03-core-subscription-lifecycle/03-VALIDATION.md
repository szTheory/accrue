---
phase: 3
slug: core-subscription-lifecycle
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-14
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Populated from 03-RESEARCH.md "Validation Architecture" section. Planner fills per-task rows.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + StreamData (property) + Mox (behaviour contracts) + Oban.Testing |
| **Config file** | `accrue/test/test_helper.exs` (exists from Phase 1) |
| **Quick run command** | `mix test --stale` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30s quick / ~120s full |

---

## Sampling Rate

- **After every task commit:** Run `mix test --stale`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green + `mix credo --strict` + `mix dialyzer`
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

*Planner populates this table during Step 8. One row per plan task.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| — | — | — | — | — | — | — | — | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Wave 0 = test scaffolding that must exist before implementation tasks run. Planner finalizes.*

- [ ] `accrue/test/support/fake_processor.ex` — extend from Phase 2 with subscription/invoice/refund fakes
- [ ] `accrue/test/support/stripe_fixtures.ex` — canned Stripe payloads (subscription.created, invoice.paid, charge.refunded, payment_intent.requires_action, etc.)
- [ ] `accrue/test/support/billing_case.ex` — test case template with Repo sandbox + fake processor
- [ ] Property test module for money/proration math (`accrue/test/accrue/money_test.exs`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real Stripe 3DS test card flow surfaces `{:ok, :requires_action, ...}` against live Stripe test mode | BILL-06 | Requires real Stripe API key + test card; CI runs against fakes only | Set `STRIPE_SECRET_KEY` to test key, run `mix test --only external` with card `4000 0027 6000 3184` |
| Webhook out-of-order replay against live Stripe | WH-09 | Requires Stripe CLI `stripe trigger` replay | `stripe trigger customer.subscription.updated` twice with altered timestamps |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
