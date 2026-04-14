---
phase: 3
slug: core-subscription-lifecycle
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-14
revised: 2026-04-14
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Populated from 03-RESEARCH.md "Validation Architecture" section.

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

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Wave 0 | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|--------|--------|
| 01-T1 | 01 | 1 | BILL-05, TEST-08 | T-03-01-01, T-03-01-02 | Clock test-env dispatch + Actor operation_id pdict + Phase 3 Error types | unit | `mix test test/accrue/clock_test.exs` | W0 ✅ | ⬜ pending |
| 01-T2 | 01 | 1 | BILL-05 | T-03-01-03 | Custom Credo check flags raw `.status` access | unit | `mix test test/accrue/credo/no_raw_status_access_test.exs && mix credo --strict` | W0 ✅ | ⬜ pending |
| 01-T3 | 01 | 1 | TEST-08 | — | BillingCase sandbox + StripeFixtures compile clean | compile | `MIX_ENV=test mix compile --warnings-as-errors` | W0 ✅ | ⬜ pending |
| 01-T4 | 01 | 1 | — | — | Accrue.Billing facade defdelegate scaffold (prevents Wave 2 fan-in) | compile | `MIX_ENV=test mix compile --warnings-as-errors` | W0 ✅ | ⬜ pending |
| 02-T1 | 02 | 1 | BILL-04, BILL-17, BILL-23, BILL-25, BILL-26 | T-03-02-05, T-03-02-06 | Migration: partial unique index on PM fingerprint + FK on_delete SET NULL + Ecto.Enum status columns | migration | `MIX_ENV=test mix ecto.migrate` | — | ⬜ pending |
| 02-T2 | 02 | 1 | BILL-04, BILL-05, BILL-17, BILL-18 | T-03-02-01, T-03-02-03 | Subscription/Invoice schemas with Ecto.Enum status + predicates + force_status bypass | unit | `mix test test/accrue/billing/subscription_predicates_test.exs test/accrue/billing/invoice_state_machine_test.exs` | W0 ✅ | ⬜ pending |
| 02-T3 | 02 | 1 | BILL-05 | T-03-02-01 | Composable Ecto query fragments (Query.active/1 etc.) | unit | `mix test test/accrue/billing/query_test.exs` | W0 ✅ | ⬜ pending |
| 03-T1 | 03 | 1 | PROC-02 | T-03-03-02 | Deterministic idempotency key derivation | unit + property | `mix test test/accrue/processor/idempotency_test.exs test/accrue/billing/properties/idempotency_key_test.exs` | W0 ✅ | ⬜ pending |
| 03-T2 | 03 | 1 | PROC-02, BILL-06, TEST-08 | T-03-03-03, T-03-03-05 | Fake processor behaviour compliance + scripted_response + transition + advance | unit | `mix test test/accrue/processor/fake_test.exs` | W0 ✅ | ⬜ pending |
| 03-T3 | 03 | 1 | PROC-02 | T-03-03-01, T-03-03-04 | Stripe adapter delegates to lattice_stripe at sole boundary | compile (+ live gated) | `mix compile --warnings-as-errors` (contract) + `mix test --only stripe_live` (optional) | — | ⬜ pending |
| 04-T1 | 04 | 2 | BILL-06, BILL-21 | T-03-04-03, T-03-04-02 | Trial.normalize_trial_end + IntentResult wrapper + SubscriptionProjection | unit | `mix test test/accrue/billing/trial_test.exs` | W0 ✅ | ⬜ pending |
| 04-T2 | 04 | 2 | BILL-03, BILL-09, BILL-10, BILL-21 | T-03-04-01, T-03-04-02 | subscribe/swap_plan/preview/update_quantity + proration required fail-loud + auto-preload | unit | `mix test test/accrue/billing/subscription_test.exs test/accrue/billing/swap_plan_test.exs test/accrue/billing/upcoming_invoice_test.exs` | W0 ✅ | ⬜ pending |
| 04-T3 | 04 | 2 | BILL-04, BILL-07, BILL-08 | T-03-04-04, T-03-04-05 | cancel matrix (immediate/at_period_end/invoice_now) + strict resume vs unpause split | unit | `mix test test/accrue/billing/subscription_cancel_test.exs test/accrue/billing/subscription_state_machine_test.exs` | W0 ✅ | ⬜ pending |
| 05-T1 | 05 | 2 | BILL-17, BILL-18 | — | InvoiceProjection.decompose deterministic rollup + child items | unit | `mix test test/accrue/billing/invoice_projection_test.exs` | W0 ✅ | ⬜ pending |
| 05-T2 | 05 | 2 | BILL-17, BILL-18, BILL-19, BILL-21 | T-03-05-01, T-03-05-02 | Invoice workflow actions via user-path changeset + upsert idempotent | unit | `mix test test/accrue/billing/invoice_workflow_test.exs test/accrue/billing/invoice_items_test.exs` | W0 ✅ | ⬜ pending |
| 06-T1 | 06 | 2 | BILL-20, BILL-21, BILL-22 | T-03-06-04, T-03-06-07 | charge/PI/SI tagged returns + charge/3 nil-PM returns error tuple / charge!/3 raises | unit | `mix test test/accrue/billing/charge_test.exs test/accrue/billing/payment_intent_test.exs test/accrue/billing/setup_intent_test.exs` | W0 ✅ | ⬜ pending |
| 06-T2 | 06 | 2 | BILL-23, BILL-25 | T-03-06-01, T-03-06-02, T-03-06-06 | PaymentMethod fingerprint dedup + partial unique index race catch + set_default NotAttached guard | unit + async concurrency | `mix test test/accrue/billing/payment_method_dedup_test.exs test/accrue/billing/default_payment_method_test.exs` | W0 ✅ | ⬜ pending |
| 06-T3 | 06 | 2 | BILL-26 | T-03-06-05 | Refund fee math sync best-effort + fees_settled_at marker | unit | `mix test test/accrue/billing/refund_test.exs` | W0 ✅ | ⬜ pending |
| 07-T1 | 07 | 3 | WH-09, BILL-17, BILL-26 | T-03-07-01, T-03-07-02, T-03-07-03, T-03-07-07 | DefaultHandler skip-stale + always-refetch + 24-event taxonomy dispatch | unit | `mix test test/accrue/webhook/default_handler_phase3_test.exs test/accrue/webhook/default_handler_out_of_order_test.exs` | W0 ✅ | ⬜ pending |
| 07-T2 | 07 | 3 | PROC-02 | T-03-07-05 | operation_id propagation via Plug.PutOperationId + Oban.Middleware.put/1 (LiveView deferred) | unit | `mix test test/accrue/plug/put_operation_id_test.exs` | W0 ✅ | ⬜ pending |
| 07-T3 | 07 | 3 | BILL-24, BILL-26 | T-03-07-04, T-03-07-06 | Reconcilers (refund + charge fees) + DetectExpiringCards with events-based dedup | unit | `mix test test/accrue/jobs/reconcile_refund_fees_test.exs test/accrue/jobs/reconcile_charge_fees_test.exs test/accrue/jobs/detect_expiring_cards_test.exs` | W0 ✅ | ⬜ pending |
| 08-T1 | 08 | 3 | TEST-08 | — | Nine subscription-state factories routed through Fake + 100-concurrent async-safety regression | unit | `mix test test/accrue/test/factory_test.exs` | W0 ✅ | ⬜ pending |
| 08-T2 | 08 | 3 | — | — | Canonical event schemas (24 entries) + Accrue.Events.Upcaster behaviour | unit | `mix test test/accrue/events/schemas_test.exs` | W0 ✅ | ⬜ pending |
| 08-T3 | 08 | 3 | BILL-04, PROC-02 | — | Property tests: proration money math + idempotency key determinism | property | `mix test test/accrue/billing/properties/` | W0 ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Total rows:** 24 (one per task across Plans 01-08).

---

## Wave 0 Requirements

*Wave 0 = test scaffolding that must exist before implementation tasks run.*

- [x] `accrue/test/support/fake_processor.ex` — extend from Phase 2 with subscription/invoice/refund fakes (Plan 03 Task 2)
- [x] `accrue/test/support/stripe_fixtures.ex` — canned Stripe payloads (Plan 01 Task 3)
- [x] `accrue/test/support/billing_case.ex` — test case template with Repo sandbox + fake processor (Plan 01 Task 3)
- [ ] Property test module for money/proration math (`accrue/test/accrue/billing/properties/proration_test.exs`) (Plan 08 Task 3 — requires Plan 04 Money API landed first)

Three of four Wave 0 items land in Plan 01 (Wave 1). The fourth (property tests) lands in Plan 08 (Wave 3) because it depends on Plan 04's `Accrue.Money` arithmetic surface and `Accrue.Processor.Idempotency.key/3,4`. Plan 08 ordering is correct — property tests logically belong at the end of the phase as the "lock in the invariants" pass.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real Stripe 3DS test card flow surfaces `{:ok, :requires_action, ...}` against live Stripe test mode | BILL-06 | Requires real Stripe API key + test card; CI runs against fakes only | Set `STRIPE_SECRET_KEY` to test key, run `mix test --only external` with card `4000 0027 6000 3184` |
| Webhook out-of-order replay against live Stripe | WH-09 | Requires Stripe CLI `stripe trigger` replay | `stripe trigger customer.subscription.updated` twice with altered timestamps |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (3/4 land in Plan 01 Wave 1; 4th is Plan 08 by design)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** populated during `/gsd-plan-phase` revision 2026-04-14 (checker BLOCKER 3 closure). Plan 08 Task 3 now verifies the flag post-execution; it does not re-populate the map.
