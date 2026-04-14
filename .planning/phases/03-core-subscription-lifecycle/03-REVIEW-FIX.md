---
phase: 03-core-subscription-lifecycle
fixed_at: 2026-04-14T20:00:00Z
review_path: .planning/phases/03-core-subscription-lifecycle/03-REVIEW.md
iteration: 1
scope: critical_warning
findings_in_scope: 14
findings_addressed: 12
findings_skipped: 0
findings_deferred: 1
tests_status: 34 properties, 383 tests, 0 failures (baseline 381, +2 new plug tests for WR-07) — 1 pre-existing flaky GenServer race in Accrue.Processor.IdempotencyTest setup (unrelated to any fix)
status: partial
---

# Phase 3: Code Review Fix Report

**Fixed at:** 2026-04-14
**Source review:** `03-REVIEW.md`
**Iteration:** 1
**Scope:** Critical + Warning findings only (14 in scope; 7 Info findings excluded per default scope)

## Summary

| Metric | Count |
|--------|-------|
| Findings in scope | 14 |
| Fixed | 12 |
| Deferred | 1 |
| Skipped | 0 |
| Tests baseline | 381 → 383 passing (2 new tests for WR-07) |
| Credo --strict | clean |

One Critical finding (CR-02) is **deferred: needs-discussion** because it conflicts with an encoded BILL-20 invariant in `charge_3ds_test.exs`. Details below.

## Fixed Issues

| ID | Severity | Files | Commit | Tests |
|----|----------|-------|--------|-------|
| CR-01 | Critical | `accrue/lib/accrue/processor/stripe.ex` | `7fa1a83` | compile + full suite green |
| CR-03 | Critical | `accrue/lib/accrue/webhook/default_handler.ex` | `3406eb6` | webhook tests 28/0 |
| WR-01 | Warning | `accrue/lib/accrue/billing/charge_actions.ex` | `d79c937` | charge tests 10/0 |
| WR-02 | Warning | `accrue/lib/accrue/billing/intent_result.ex`, `accrue/lib/accrue/billing/subscription.ex` | `d79c937` | intent_result + charge tests green |
| WR-03 | Warning | `accrue/lib/accrue/webhook/default_handler.ex`, `accrue/lib/accrue/billing/refund_actions.ex`, `accrue/lib/accrue/jobs/reconcile_refund_fees.ex` | `3406eb6`, `b1a6b35` | refund + reconciler tests 7/0 |
| WR-04 | Warning | `accrue/lib/accrue/billing/refund_actions.ex` | `b1a6b35` | refund tests 5/0 |
| WR-05 | Warning | `accrue/lib/accrue/billing/refund_actions.ex` | `b1a6b35` | refund tests 5/0 |
| WR-06 | Warning | `accrue/lib/accrue/credo/no_raw_status_access.ex` | `b6137b7` | credo --strict clean |
| WR-07 | Warning | `accrue/lib/accrue/plug/put_operation_id.ex`, `accrue/test/accrue/plug/put_operation_id_test.exs` | `dfc2c66` | plug tests 6/0 (+2 new) |
| WR-08 | Warning | `accrue/lib/accrue/billing.ex` | `b6137b7` | billable + events_transaction tests 13/0 |
| WR-09 | Warning | `accrue/lib/accrue/billing/subscription_actions.ex`, `accrue/lib/accrue/billing/invoice_actions.ex`, `accrue/lib/accrue/webhook/default_handler.ex` | `f9d4c2a` | full suite green |
| WR-10 | Warning | `accrue/lib/accrue/webhook/default_handler.ex` | `3406eb6` | webhook tests 28/0 |
| WR-11 | Warning | `accrue/lib/accrue/billing/invoice_projection.ex`, `accrue/lib/accrue/billing/subscription_projection.ex` | `dfc2c66` | invoice projection tests green |

### Detailed actions

#### CR-01: Stripe adapter silently overwrites billing-context idempotency key
**Commit:** `7fa1a83`
**Fix:** `stripe_opts/3` now reads `Keyword.get(opts, :idempotency_key)` first and only falls back to `compute_idempotency_key/3` when the caller didn't supply one. Restores D3-60/D3-61 deterministic retry convergence on the Stripe path — the same `subject_uuid` from `Accrue.Processor.Idempotency` now routes through to Stripe's idempotency cache.

#### CR-03: `default_handler.ex` `reduce_refund` crashes on unknown charge id
**Commit:** `3406eb6`
**Fix:** Replaced `Repo.get_by!` with `Repo.get_by/2` + nil-guard in **four** places (beyond just the refund reducer from the review): `upsert_refund`, `upsert_charge`, `upsert_subscription`, `upsert_invoice`. When the parent customer/charge isn't projected locally yet, returns `{:ok, :deferred}`, emits `[:accrue, :webhooks, :orphan_*]` telemetry, and the enclosing `reduce_row` commits cleanly. Oban no longer retry-loops into DLQ. Matches D3-50 tolerance for out-of-order `charge.refund.updated` before `charge.refunded`. All four reducers (`reduce_refund`, `reduce_charge`, `reduce_subscription`, `reduce_invoice`) updated to short-circuit on `:deferred` without attempting to record an event on a non-existent row.

#### WR-01: `create_payment_intent/2` colliding idempotency key
**Commit:** `d79c937`
**Fix:** Pre-generate `subject_uuid = Idempotency.subject_uuid(:create_payment_intent, op_id)` so two distinct PaymentIntents in the same operation hash to distinct keys. Aligns with `run_charge` and `create_setup_intent`.

#### WR-02: `IntentResult.wrap` can never surface `requires_action` for Invoice/Charge
**Commit:** `d79c937`
**Fix:** Added `def wrap({:ok, %Invoice{data: data}} = ok)` and `def wrap({:ok, %Charge{data: data}} = ok)` clauses that peek into the struct's `data` map for `latest_invoice.payment_intent` / `payment_intent` and surface `{:ok, :requires_action, pi}` when `requires_action?/1`. Also normalized `Subscription.pending_intent/1` to dual-key lookup (atom vs string) and removed the `_ = SubscriptionItem` alias-suppression hack (IN-02 drive-by).

#### WR-03: Money math allows negative `merchant_loss_amount`
**Commits:** `3406eb6` (default_handler), `b1a6b35` (refund_actions + reconcile_refund_fees)
**Fix:** All three sites now clamp via `max(0, fee - fee_refunded)`. A property test covering fee_adjustment > fee can be added in a follow-up; the commit covers the immediate correctness bug. Migration-level CHECK constraint NOT added in this pass (would require a new migration) — noted as a follow-up.

#### WR-04: `String.to_existing_atom` without rescue in RefundActions
**Commit:** `b1a6b35`
**Fix:** Wrapped in `try/rescue ArgumentError -> :pending`, mirroring the DefaultHandler pattern.

#### WR-05: `create_refund/2` crashes on non-Money `:amount`
**Commit:** `b1a6b35`
**Fix:** `case` now covers `nil | %Money{} | other`. Non-Money → `ArgumentError` with explanatory message. `%Money{}` with mismatched currency → `ArgumentError` comparing against `charge_currency_atom/1`, which safely coerces the charge's `:string` currency to atom via `String.to_existing_atom/1` with `String.to_atom/1` fallback.

#### WR-06: `NoRawStatusAccess` has bypasses
**Commit:** `b6137b7`
**Fix:** Added `!=` clauses (two directions) and string-literal `@string_statuses` clauses for `charge.status` (which is `:string`, not enum). Tightened `exempt_file?/1` to no longer match production modules under `lib/accrue/test/...`. **Pattern-match detection (def/defp/case heads) is NOT implemented** — adding it safely requires distinguishing changeset field casts (`status: :active` in a keyword-list attrs) from entitlement checks, which risks a cascade of false positives. `credo --strict` is clean after the fix.

#### WR-07: `PutOperationId` trusts unvalidated attacker header
**Commit:** `dfc2c66`
**Fix:** Added `sanitize_header_id/1` that strips non-`[a-zA-Z0-9_-]` chars, enforces `byte_size in 1..128`, and prefixes with `"untrusted-"` so the value is clearly marked in downstream SHA256 input / Oban pdict / events. Invalid values fall through to the `http-` random fallback. Extended `put_operation_id_test.exs` with two new tests (charset rejection, oversized rejection).

#### WR-08: Customer actions still use `Ecto.Multi`
**Commit:** `b6137b7`
**Fix:** Migrated `create_customer/1` and `update_customer/2` from `Ecto.Multi.new() + Repo.transaction/1` to `Repo.transact(fn -> with ... end)` per D3-18.

#### WR-09: `upsert_items` uses `Repo.insert!/update!` inside `Repo.transact`
**Commit:** `f9d4c2a`
**Fix:** Converted all four upsert_items sites (`subscription_actions.upsert_item`, `invoice_actions.upsert_item`, `default_handler.upsert_subscription_item`, `default_handler.upsert_invoice_items`) from `Enum.each` + bang variants to `Enum.reduce_while` + non-bang variants. Changeset failures now propagate as `{:error, changeset}` into the enclosing `with`-chain rather than raising `Ecto.InvalidChangesetError`.

#### WR-10: Webhook reducer passes stub object without checking id
**Commit:** `3406eb6`
**Fix:** Added a pattern-match guard clause `def handle_event(type, %Accrue.Webhook.Event{object_id: nil}, _ctx)` before the normal clause. Emits `[:accrue, :webhooks, :missing_object_id]` telemetry and short-circuits with `:ok` rather than crashing downstream in `Processor.fetch/2`.

#### WR-11: `InvoiceProjection.decompose/1` stores atom-keyed data
**Commit:** `dfc2c66`
**Fix:** Promoted `SubscriptionProjection.to_string_keys/1` from private to public (`@doc` + `@spec`) and invoked it on `data: stripe_inv` in `InvoiceProjection.decompose/1`. A second decompose/1 on reload now sees the same string-keyed shape regardless of whether the original source was Fake (atom-keyed) or Stripe (string-keyed).

## Deferred Issues

### CR-02: `charge/3` runs Stripe call outside `Repo.transact`
**Status:** deferred: needs-discussion
**File:** `accrue/lib/accrue/billing/charge_actions.ex:118-147`

**Why deferred:** Applied the fix locally (persist Charge row inside `Repo.transact` even on `requires_action`), but this broke `test/accrue/billing/charge_3ds_test.exs:94`:

```elixir
# No local row written: BILL-20 invariant — the SCA branch MUST NOT
# insert a half-baked Charge row while the PaymentIntent still needs
# customer action.
assert Repo.aggregate(Charge, :count) == 0
```

The test explicitly codifies BILL-20 as "no local row during 3DS pending state" and the subsequent `1B` test depends on the webhook reducer taking the `nil`-row insert branch. The review's proposed fix (persist with `status: "requires_action"` inside the transact) contradicts this locked test invariant.

**Analysis:**
- The review itself acknowledges the current design converges on retries *when CR-01 is fixed* (which it now is): same `subject_uuid` → same Stripe idem key → Stripe replays → webhook reducer inserts.
- The residual gap is only non-SCA, non-transient DB failures on the happy path. That's a narrow surface.
- D3-18 and BILL-20 are both locked decisions, and they conflict on this point. Resolving requires a product-level decision: do we persist a `requires_action` Charge row as a first-class state (BILL-20 softens), or do we rely on webhook-path convergence (D3-18 softens for SCA only)?

**Recommendation for next iteration:** Bring to phase owner for locked-decision reconciliation. If BILL-20 is softened, apply the fix from the review + update `charge_3ds_test.exs` test 1A to assert `%Charge{status: "requires_action"}` exists and test 1B to assert the webhook reducer takes the `existing` update branch rather than `nil` insert. If D3-18 is softened for this case, document the exception in CONTEXT.md and add a focused unit test covering the DB-failure-after-Stripe-success non-SCA path.

**Revert:** The partial CR-02 edit was rolled back via `git checkout -- charge_actions.ex` before any commit, so `main` is back to pre-CR-02 state for that file. No commits to back out.

## Notes

### Tests status
- **Baseline:** 34 properties, 381 tests, 0 failures (2 excluded)
- **After fixes:** 34 properties, 383 tests, 0 failures (2 excluded) — +2 new tests for WR-07 charset/length rejection
- **Flakiness:** 1 pre-existing intermittent failure in `Accrue.Processor.IdempotencyTest` (`test compute_idempotency_key/3 emits Logger.warning when no seed available`) — GenServer.call race against `Accrue.Processor.Fake` during test setup, **unrelated to any fix**. The test passes with 80%+ frequency; the failure mode is `** (EXIT) no process`. Flagged for follow-up.
- **Credo --strict:** clean on all runs

### Commits
```
f9d4c2a fix(03-review): WR-09 replace upsert_items bang variants with reduce_while
dfc2c66 fix(03-review): WR-07/WR-11 sanitize x-request-id header + string-normalize invoice data
b6137b7 fix(03-review): WR-06/WR-08 tighten Credo + migrate customer actions to Repo.transact
d79c937 fix(03-review): WR-01/WR-02 deterministic PI idem key + wrap Invoice/Charge
b1a6b35 fix(03-review): WR-03/WR-04/WR-05 clamp merchant_loss, rescue status parse, validate :amount
3406eb6 fix(03-review): CR-03/WR-10/WR-03 tolerate missing parents, nil object_id, clamp merchant_loss
7fa1a83 fix(03-review): CR-01 preserve caller idempotency key in stripe_opts
```

### Follow-ups (not in scope for this pass)
1. CR-02 — needs locked-decision reconciliation between D3-18 and BILL-20.
2. WR-03 migration — add `CHECK (merchant_loss_amount_minor >= 0)` CHECK constraint on `accrue_refunds`.
3. WR-03 property test — generate adversarial `(fee, fee_refunded)` pairs with `fee_refunded > fee` and assert `merchant_loss >= 0`.
4. Flaky `IdempotencyTest` setup race — investigate Fake GenServer lifecycle.
5. Info findings (IN-01..IN-07) — out of scope for critical_warning pass; address in next review cycle.

---

_Fixed: 2026-04-14_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
