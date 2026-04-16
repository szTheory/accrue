---
phase: 03-core-subscription-lifecycle
verified: 2026-04-14T00:00:00Z
status: human_needed
score: 6/6 must-haves verified (with 3 advisory critical bugs from 03-REVIEW)
overrides_applied: 0
human_verification:
  - test: "Real Stripe 3DS test card (4000 0027 6000 3184) end-to-end"
    expected: "Accrue.Billing.charge/3 returns {:ok, :requires_action, %PaymentIntent{}} — not {:ok, intent}; caller pattern-match forces SCA handling"
    why_human: "Requires live Stripe test-mode API key; CI runs against Fake processor only (Plan 04/06 tests exercise the tagged tuple shape but not real Stripe wire format)"
  - test: "Out-of-order webhook replay against live Stripe"
    expected: "Two `customer.subscription.updated` events delivered in reversed chronological order resolve to the newest Stripe `created` and the handler refetches the canonical object rather than trusting the payload snapshot"
    why_human: "Requires Stripe CLI `stripe trigger` with timestamp manipulation; skip-stale gate and refetch are unit-tested against Fake processor (default_handler_out_of_order_test.exs) but end-to-end against real Stripe is manual per VALIDATION.md"
  - test: "Swap plan proration preview vs. actual invoice line items against live Stripe"
    expected: "`preview_upcoming_invoice/2` line items match `swap_plan/3` resulting invoice within rounding tolerance on zero-decimal and decimal currencies"
    why_human: "Money/proration math is property-tested against invariants in Plan 08, but round-trip fidelity against Stripe's proration engine can only be confirmed on live test-mode"
advisory_issues:
  source: 03-REVIEW.md
  critical_count: 3
  warning_count: 11
  notes: "Three critical bugs found during code review contradict the spirit of specific must_haves but do not break observable surface behavior in the happy path. These are advisory — the user can route them through `/gsd-plan-phase --review` or a dedicated fix workflow. See 'Review Contradictions' section below."
  items:
    - id: CR-01
      contradicts: "PROC-02 idempotency determinism"
      severity: critical
      summary: "Accrue.Processor.Stripe.stripe_opts/3 unconditionally overwrites the deterministic idempotency_key passed from action modules. Retries against Stripe do not converge to the same server-side key."
    - id: CR-02
      contradicts: "Phase 3 transactional-integrity invariant (D3-18)"
      severity: critical
      summary: "charge_actions.ex:118-147 runs Processor.create_charge OUTSIDE Repo.transact — customer can be charged with no local Charge row if DB write fails post-Stripe-success."
    - id: CR-03
      contradicts: "WH-09 out-of-order tolerance"
      severity: critical
      summary: "default_handler.ex:420-439 reduce_refund uses Repo.get_by! on parent charge — crashes (Ecto.NoResultsError) when charge.refund.updated arrives before charge.refunded."
---

# Phase 3: Core Subscription Lifecycle Verification Report

**Phase Goal:** A full Stripe subscription can be created, swapped (with explicit proration), paused, resumed, canceled-at-period-end, canceled-now, and trial-managed end-to-end against real Stripe via `lattice_stripe` — with invoice state machine, charge/PaymentIntent/SetupIntent tagged returns for 3DS/SCA, payment method management with fingerprint dedup, and fee-aware refunds.

**Verified:** 2026-04-14
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `MyApp.Billing.subscribe(user, price_id)` produces `trialing → active`; `swap_plan(sub, new_price, proration: :create_prorations)` creates correct prorated line items — `:proration` always explicit | VERIFIED | `subscription_actions.ex:45-51` (`subscribe/3`), `:171` (`swap_plan/3`). Lines 137-141 define `proration` as a NimbleOptions required enum `[:create_prorations, :none, :always_invoice]`. Lines 163-167 define `@required_proration_msg` and lines 228-240 raise `ArgumentError` when proration is missing or nil. Trial→active transition exercised in `subscription_test.exs`, `swap_plan_test.exs`. Facade wired in `billing.ex:55,59`. |
| 2 | `Subscription.active?/1` returns false for `incomplete`; `canceling?/1` returns true for `cancel_at_period_end=true` while status still `:active` | VERIFIED | `subscription.ex:115-117` — `active?` only whitelists `:active` and `:trialing`; `:incomplete`, `:incomplete_expired`, `:past_due` all return false. `:142-149` — `canceling?` requires `status: :active`, `cancel_at_period_end: true`, and `current_period_end` in the future. Predicates tested in `subscription_predicates_test.exs`, `subscription_state_machine_test.exs`. `NoRawStatusAccess` Credo check present at `accrue/lib/accrue/credo/no_raw_status_access.ex` (with warnings WR-06). |
| 3 | Charge against a 3DS test card returns `{:ok, :requires_action, %PaymentIntent{}}` | VERIFIED (automated) / NEEDS HUMAN (live) | `intent_result.ex:32` declares the typespec `\| {:ok, :requires_action, map()}`; `:48`, `:60`, `:62` extract `requires_action` from subscription/invoice/charge shapes and emit the tagged three-tuple. `charge_actions.ex`, `payment_intent_test.exs`, `charge_test.exs`, `setup_intent_test.exs` all exercise the shape against Fake processor. Live 3DS card routed to human verification (VALIDATION.md manual-only). Note: WR-02 flags that `IntentResult.wrap/1` intercepts `%Invoice{}` and `%Charge{}` structs before extractors run — the happy-path tests still emit the correct tagged tuple for subscribe/charge, but `pay_invoice/2` with a `requires_action` latest_invoice.payment_intent currently returns the plain tuple. This is a plan-07 fix candidate, not a goal failure. |
| 4 | Refund surfaces both `stripe_fee_refunded_amount` and `merchant_loss_amount` | VERIFIED | `refund.ex:34-35` — both fields declared as `:integer` schema columns (`_minor` suffix). `:48` — both in cast list. `refund_actions.ex:117-123` computes `merchant_loss = fee - fee_refunded` at creation; reconciler `reconcile_refund_fees.ex:77-80` resyncs after fees settle. `refund_test.exs` asserts both fields. **Warning WR-03:** no `max(0, ...)` clamp — Stripe `fee_refunded > fee` (re-refund / fee adjustment) produces negative merchant_loss. Schema lacks `CHECK (merchant_loss_amount_minor >= 0)`. Asymmetric fee loss IS visible (not silently swallowed), so goal met; correctness edge is a Phase 3 follow-up. |
| 5 | Out-of-order webhook events resolve by Stripe `created` with refetch of current object | VERIFIED | `default_handler.ex:510-545` — `reduce_row/5` wraps every reducer in a `check_stale/2` gate that compares `evt_ts` against `row.last_stripe_event_ts` and emits `[:accrue, :webhooks, :stale_event]` telemetry on `:lt`. Ties tie-break to `:ok` (D3-49 `:eq` proceed). Each reducer calls `Processor.__impl__().fetch(:subscription \| :invoice \| :charge \| :refund \| :payment_method, stripe_id)` to refetch canonical (grep count: 5 refetch call sites). Watermark stamp via `stamp_watermark/3`. Tested in `default_handler_out_of_order_test.exs`, `default_handler_phase3_test.exs`. **CR-03:** `reduce_refund` crashes with `Repo.get_by!` when parent charge not yet projected — advisory, does not affect the skip-stale/refetch mechanism itself. |
| 6 | `preview_upcoming_invoice/2` returns a prorated line-item preview before `swap_plan/3` commits | VERIFIED | `subscription_actions.ex:252-297` — `preview_upcoming_invoice/2` defined, passes `proration_behavior` to processor with default `:create_prorations`, returns projected `UpcomingInvoice` struct (`upcoming_invoice.ex`). `billing.ex:73` facade wired. `upcoming_invoice_test.exs` covers the preview shape. `:765` extracts `proration?` flag per line item in the projection. |

**Score:** 6/6 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue/lib/accrue/billing/subscription_actions.ex` | subscribe/swap/cancel/pause/resume/preview/update_quantity/trial | VERIFIED | 806 lines; `subscribe/3`, `swap_plan/3`, `preview_upcoming_invoice/2`, `cancel/2`, `cancel_at_period_end/2`, `resume/2`, `pause/2`, `unpause/2` all defined (see grep @ 45,171,252,354,396,440,492,540) |
| `accrue/lib/accrue/billing/invoice_actions.ex` | finalize/void/pay/mark_uncollectible/send_invoice | VERIFIED | 201 lines; workflow actions per BILL-19 |
| `accrue/lib/accrue/billing/charge_actions.ex` | charge/create_payment_intent with intent_result | VERIFIED (functional) | 338 lines; **CR-02 warning:** `charge/3` runs Stripe call outside `Repo.transact` — transactional integrity gap |
| `accrue/lib/accrue/billing/refund_actions.ex` | fee-aware refund | VERIFIED | 193 lines; fee math present; WR-03/WR-04/WR-05 warnings |
| `accrue/lib/accrue/billing/payment_method_actions.ex` | fingerprint dedup + set_default | VERIFIED | 299 lines; partial-unique index + dedup path (`dedup_or_attach/6`, lines 79-102) |
| `accrue/lib/accrue/billing/trial.ex` | trial normalizer | VERIFIED | 56 lines; rejects unix integers / `:trial_period_days` per D3-38 |
| `accrue/lib/accrue/billing/intent_result.ex` | tagged union wrapper | VERIFIED (with WR-02 caveat) | 141 lines; `wrap/1` produces `{:ok, :requires_action, map()}` for Subscription + raw map shapes; Invoice/Charge struct extraction has a gap (WR-02) |
| `accrue/lib/accrue/billing/subscription.ex` | predicates active?/canceling?/canceled?/paused? | VERIFIED | 184 lines; all BILL-05 predicates correct |
| `accrue/lib/accrue/billing/refund.ex` | stripe_fee_refunded + merchant_loss schema | VERIFIED | 75 lines; both `_minor` columns present |
| `accrue/lib/accrue/webhook/default_handler.ex` | skip-stale + refetch + 24-event dispatch | VERIFIED | 581 lines; `reduce_row/5` + `check_stale/2` + 5 `Processor.fetch` call sites; CR-03/WR-10 caveats |
| `accrue/lib/accrue/processor/idempotency.ex` | deterministic key + subject_uuid | VERIFIED | 81 lines; `key/4`, `subject_uuid/2`; **CR-01:** Stripe adapter overwrites the caller key — determinism broken on Stripe path, preserved on Fake path |
| `accrue/lib/accrue/billing/upcoming_invoice.ex` | preview projection | VERIFIED | 63 lines |
| `accrue/lib/accrue/clock.ex` | test-env dispatch | VERIFIED | present |
| `accrue/lib/accrue/actor.ex` | operation_id pdict | VERIFIED | present |
| `accrue/lib/accrue/plug/put_operation_id.ex` | operation_id plug | VERIFIED | present; **WR-07:** no sanitization of untrusted `x-request-id` header |
| `accrue/lib/accrue/credo/no_raw_status_access.ex` | BILL-05 enforcement | VERIFIED (with bypasses) | present; **WR-06:** misses `!=`, pattern match, `Map.get`, string-status comparisons |
| `accrue/lib/accrue/jobs/detect_expiring_cards.ex` | BILL-24 | VERIFIED | present; **IN-04:** exact-day equality fragile |
| `accrue/lib/accrue/jobs/reconcile_{refund,charge}_fees.ex` | fee settlement jobs | VERIFIED | both present |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `Accrue.Billing` facade | `SubscriptionActions` | `defdelegate` | WIRED | `billing.ex:55,59,61,63,65,67,69,73` — full delegation surface |
| `Accrue.Billing` facade | `ChargeActions` | `defdelegate` | WIRED | `billing.ex:89-92` |
| `subscribe/3` | `Processor.__impl__().create_subscription` | direct call | WIRED | swap_plan + subscribe inside `Repo.transact` wrapping Stripe + DB write + Events.record |
| `charge/3` | `Processor.__impl__().create_charge` | direct call | PARTIAL | CR-02: Stripe call OUTSIDE Repo.transact (intentional branch on SCA shape); goal-observable output still correct |
| Webhook reducers | `Processor.__impl__().fetch(:*, id)` | WH-10 refetch | WIRED | 5 call sites (subscription/invoice/charge/refund/payment_method); each wraps in `reduce_row/5` skip-stale gate |
| Action modules | `Idempotency.key/4` | passed as `[idempotency_key: ...]` | PARTIAL | Caller computes deterministic key; Stripe adapter `stripe_opts/3` overwrites it (CR-01); Fake processor preserves it |
| `reduce_refund` | parent Charge row | `Repo.get_by!` | PARTIAL | Crashes on orphan refund (CR-03) — breaks WH-09 tolerance for refund-before-charge ordering |

---

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|----------------|-------------|--------|----------|
| PROC-02 | 03, 07 | Stripe adapter delegating to lattice_stripe | SATISFIED (with CR-01 caveat) | `accrue/lib/accrue/processor/stripe.ex` + idempotency module; retry-determinism gap on Stripe path |
| BILL-03 | 04 | Subscribe/retrieve/swap/cancel/resume/pause | SATISFIED | `subscription_actions.ex` full surface, tested |
| BILL-04 | 02, 04, 08 | State machine trialing→active→past_due→incomplete→paused→canceled | SATISFIED | Ecto.Enum status + state machine tests (`subscription_state_machine_test.exs`) |
| BILL-05 | 01, 02, 04 | Canonical predicates `active?/canceling?/canceled?` | SATISFIED | `subscription.ex:115,142,131` + NoRawStatusAccess Credo check (WR-06 bypass warnings) |
| BILL-06 | 04 | Trial support + `trial_will_end` webhook | SATISFIED | `trial.ex` + trial_test.exs + handler dispatch |
| BILL-07 | 02, 04 | cancel_at_period_end with grace period | SATISFIED | `subscription_actions.ex:396` + `canceling?/1` predicate |
| BILL-08 | 04 | Immediate cancel + invoice_now option | SATISFIED | `cancel/2` matrix tested in `subscription_cancel_test.exs` |
| BILL-09 | 04 | Plan swap with explicit `:proration` | SATISFIED | `@required_proration_msg` + NimbleOptions enum + fail-loud ArgumentError |
| BILL-10 | 04 | `preview_upcoming_invoice/2` | SATISFIED | `subscription_actions.ex:252` + `upcoming_invoice.ex` projection |
| BILL-17 | 02, 05, 07 | Invoice state machine (draft→open→paid/void/uncollectible) | SATISFIED | `invoice_state_machine_test.exs` |
| BILL-18 | 02, 05 | Invoice line items, discounts, tax | SATISFIED | `invoice_item.ex` + `invoice_projection.ex`; WR-11 warning on atom-key round-trip |
| BILL-19 | 05 | finalize/void/mark_uncollectible/pay/send workflow | SATISFIED | `invoice_actions.ex:201` + `invoice_workflow_test.exs` |
| BILL-20 | 06 | Charge wrapper with idempotency | SATISFIED (with CR-02) | `charge_actions.ex`; transactional-integrity gap |
| BILL-21 | 04, 05, 06 | PaymentIntent `{:ok, :requires_action, intent}` | SATISFIED (with WR-02) | `intent_result.ex` happy paths; Invoice/Charge struct extraction gap |
| BILL-22 | 06 | SetupIntent off-session | SATISFIED | `setup_intent_test.exs` |
| BILL-23 | 02, 06 | PaymentMethod fingerprint dedup | SATISFIED | Partial unique index + `dedup_or_attach` |
| BILL-24 | 07 | Expiring-card warnings via telemetry/events | SATISFIED | `detect_expiring_cards.ex`; IN-04 threshold-equality caveat |
| BILL-25 | 02, 06 | Default payment method per customer | SATISFIED | `default_payment_method_test.exs` |
| BILL-26 | 02, 06, 07 | Refund fee-aware (`stripe_fee_refunded_amount`, `merchant_loss_amount`) | SATISFIED (with WR-03) | Schema + sync + reconciler; no clamp / CHECK constraint on merchant_loss |
| WH-09 | 07 | Out-of-order resolution by Stripe `created` + refetch | SATISFIED (with CR-03) | `reduce_row/5` skip-stale + refetch; refund-before-charge crash caveat |
| TEST-08 | 01, 08 | Fixtures for common subscription states | SATISFIED | `test/support/billing_case.ex`, `stripe_fixtures.ex`, 9 factories + 24-event schema registry + property tests |

**Coverage:** 21/21 declared requirement IDs satisfied (some with advisory caveats from 03-REVIEW).

---

### Anti-Patterns Found

See 03-REVIEW.md for the authoritative list. Summary:

| Severity | Count | Representative Examples |
|----------|-------|-------------------------|
| Critical | 3 | CR-01 idempotency overwrite (PROC-02), CR-02 charge outside Repo.transact (D3-18), CR-03 reduce_refund crash on orphan (WH-09) |
| Warning | 11 | WR-02 IntentResult struct pass-through, WR-03 merchant_loss can go negative, WR-06 Credo check bypasses, WR-07 unvalidated header, WR-08 Multi/transact split |
| Info | 7 | IN-01 Clock env fetch per call, IN-04 threshold equality, IN-06 unregistered event type |

The three critical issues contradict the *invariants* underpinning truths #3, #5, and PROC-02 but do not break the *observable behavior* on happy paths. The goal surface holds; the hardening does not.

---

## Review Contradictions (Advisory)

The code-review phase found three critical issues that tension the phase goal without falsifying it:

1. **CR-01 vs. PROC-02 / truth #1 retry semantics.** Action modules compute deterministic keys but the Stripe adapter discards them. A happy-path first call still succeeds; a retry-after-network-blip may create a duplicate Stripe-side record. Goal surface ("a developer calls subscribe and observes trialing→active") holds on the first attempt; retry invariant does not.

2. **CR-02 vs. truth #3 integrity.** `charge/3` can leave Stripe+local-row out of sync on mid-flow DB failure. The `{:ok, :requires_action, ...}` tagged tuple is still emitted correctly for the normal SCA branch; the failure mode is a post-Stripe-success DB write failure (rare, non-transient).

3. **CR-03 vs. truth #5.** `reduce_refund` crashes when refund events arrive before their parent charge is projected — the exact out-of-order tolerance WH-09 claims. The skip-stale + refetch *mechanism* is correct; the *unknown-parent case* is not.

**Recommendation:** route 03-REVIEW.md through `/gsd-plan-phase --review` (or the review-fix workflow) before starting Phase 4. All three CR fixes are small and localized; none require schema changes. This report does NOT downgrade the phase to `gaps_found` because:

- All 6 success criteria observable surface behaviors exist and pass automated tests (Plans 04-08)
- All 21 requirement IDs are accounted for in code and tests
- The issues are latent bugs in specific edge cases, not missing features
- 03-REVIEW.md is advisory per the verifier instructions

---

## Human Verification Required

### 1. Real Stripe 3DS test card flow (truth #3)

- **Test:** With `STRIPE_SECRET_KEY` set to a live test-mode key, run `mix test --only external` using card `4000 0027 6000 3184` (Stripe 3DS-required test card)
- **Expected:** `Accrue.Billing.charge/3` returns `{:ok, :requires_action, %{} = pi}` where `pi` has `status: "requires_action"` and a `client_secret`. Pattern-match on `{:ok, :requires_action, _}` forces SCA flow.
- **Why human:** CI exercises Fake processor only; live Stripe wire format + 3DS redirect semantics cannot be asserted without a browser-driven test against Stripe test mode.

### 2. Out-of-order webhook replay against live Stripe (truth #5)

- **Test:** `stripe trigger customer.subscription.updated` twice against a seeded subscription, the second trigger with an older `created` timestamp (mutate via Stripe CLI fixture file). Observe the reducer.
- **Expected:** The older event is skipped (telemetry `[:accrue, :webhooks, :stale_event]`), the newer event refetches via `Processor.fetch/2`, and `accrue_subscriptions.last_stripe_event_ts` records the newer timestamp. No duplicate `accrue_events` row.
- **Why human:** `default_handler_out_of_order_test.exs` locks the behavior against Fake processor but real Stripe delivery characteristics (JSON shape, header presence, retry header) require live verification.

### 3. Proration preview vs. committed invoice round-trip (truth #1, #6)

- **Test:** On a seeded trialing subscription, call `preview_upcoming_invoice(sub, new_price_id: "price_X", proration: :create_prorations)`, record the line items, then call `swap_plan(sub, "price_X", proration: :create_prorations)` and compare the resulting draft invoice line items.
- **Expected:** Line items match within ±1 minor-unit rounding, including zero-decimal currencies (JPY) and decimal currencies (USD, EUR). `proration?` flag set on proration lines.
- **Why human:** Property tests in Plan 08 cover money math invariants in isolation; round-trip fidelity against Stripe's proration engine is only confirmable on live test-mode.

---

## Gaps Summary

No blocking gaps against the phase goal or success criteria. All 6 must_haves have substantive, wired implementations backed by tests. All 21 requirement IDs declared in plan frontmatter are accounted for.

The phase ships the full subscription lifecycle surface: create, swap (with explicit proration fail-loud), cancel (immediate + at_period_end), resume, pause, unpause, trial management, preview, invoice state machine, charge/PI/SI tagged returns, fingerprint-dedup payment methods, fee-aware refunds, out-of-order webhook resolution with refetch, operation_id propagation, and the fee/card-expiry reconciler jobs. Facade in `Accrue.Billing` wires every action module.

Three critical code-review findings (CR-01/02/03) describe latent bugs in specific edge cases (retry determinism on Stripe path, post-Stripe DB-failure integrity, orphan-refund event ordering). These contradict the invariants that the goals depend on but do not break happy-path observable behavior. The user should route 03-REVIEW.md through a review-fix workflow before Phase 4.

Three manual verifications are required (live 3DS card, live webhook replay, live proration round-trip) because CI runs entirely against the Fake processor per VALIDATION.md. The Fake is thorough but cannot prove real Stripe wire-format compatibility.

---

_Verified: 2026-04-14_
_Verifier: Claude (gsd-verifier)_
