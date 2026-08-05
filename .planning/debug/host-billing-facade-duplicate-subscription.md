---
status: resolved
trigger: "Diagnose AccrueHost.BillingFacadeTest at examples/accrue_host/test/accrue_host/billing_facade_test.exs:160 duplicating a fake subscription and violating accrue_subscriptions_processor_processor_id_index. Determine root cause, whether pre-existing, and the minimal correct test-only or production fix consistent with billing uniqueness/idempotency semantics."
created: 2026-08-04T20:49:35Z
updated: 2026-08-05T20:42:00Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

reasoning_checkpoint:
  hypothesis: "BillingFacadeTest's second identical create is a retry because both calls use AccrueCase's one operation ID; Fake returns the first provider subscription by idempotency key, and the local projection's second insert conflicts with the legitimate global `(processor, processor_id)` constraint."
  confirming_evidence:
    - "The isolated test deterministically raises its unique-index error on the second call at line 167."
    - "Fake's handler returns the cached result for `{:create_subscription, key}`, and 4c221aad's focused core test explicitly asserts one provider subscription per key."
  falsification_test: "Give only the second call a different operation ID; if it still attempts to reuse the first provider ID or fails the unique index, the idempotency-key explanation is false."
  fix_rationale: "The test claims to model two independent creations, so it must give them different operation identities. This preserves the provider-ID uniqueness invariant and leaves retry idempotency unchanged."
  blind_spots: "SubscriptionActions itself still raises if a caller directly repeats a completed same-key subscribe; this host test should not be changed into a retry assertion without a separate production idempotency decision."
  candidate_causes:
    - "code: outdated host test supplies two logically distinct creates with one idempotency identity"
    - "data: both calls have the same customer, price, quantity, and trial shape, making their derived provider key identical"
    - "environment: no evidence of sandbox leakage or cross-test state; isolated reproduction fails"
  and_gate: "no — the test's one reused operation ID fully explains the attempted duplicate; the identical request data is expected retry identity, not an independent contributing defect."
hypothesis: Confirmed — two create operations are intended, but the test uses one effective operation identity. Give its second call a fresh explicit operation ID.
test: Exact one-line test-only counterfactual was run and restored.
expecting: N/A — diagnosis complete.
next_action: Closed by the test-only fresh operation ID on the second logical create.
bug_class: bohrbug

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: The host facade test creates two subscriptions for one user and reports the latest subscription.
actual: The second fake subscription insert violates accrue_subscriptions_processor_processor_id_index.
errors: "accrue_subscriptions_processor_processor_id_index"
reproduction: Run examples/accrue_host/test/accrue_host/billing_facade_test.exs, specifically the test beginning at line 160.
started: Unknown; observed in current full credential-free host-suite run.

## Eliminated
<!-- APPEND only - prevents re-investigating -->

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-08-04T20:49:35Z
  checked: Existing debug session for the credential-free host suite
  found: The complete suite separately reported this unique-index failure after identifying the Braintree missing-credential failure.
  implication: This is an independent deterministic data-isolation/idempotency investigation.
- timestamp: 2026-08-04T20:52:44Z
  checked: Reported test in isolation
  found: The test deterministically fails on its second `Billing.subscribe/3` at line 167 with `Ecto.ConstraintError` for `accrue_subscriptions_processor_processor_id_index`; the stack reaches `SubscriptionActions.insert_subscription/2` at line 1176.
  implication: The failure is a direct duplicate local projection, not cross-test database leakage or concurrency.
- timestamp: 2026-08-04T20:53:16Z
  checked: AccrueCase setup, SubscriptionActions request assembly, Fake subscription handler, and the database migration
  found: AccrueCase sets one `Accrue.Actor` operation ID per test. SubscriptionActions derives its idempotency key from customer ID, that operation ID, and price/quantity. Fake caches `{:create_subscription, key}` and returns the first result on a repeat; the database enforces global uniqueness of `(processor, processor_id)`.
  implication: Two identical calls in this test are an idempotent retry, not two independent subscription-create operations.
- timestamp: 2026-08-04T20:54:27Z
  checked: Git history and current core idempotency coverage
  found: The host assertion requiring distinct subscription IDs was introduced in b62db4a on 2026-04-16. Fake idempotent subscription creation was introduced by 4c221aad on 2026-08-02, whose core test explicitly asserts two calls with one idempotency key return one provider subscription.
  implication: The host test is pre-existing but became incompatible with intentionally strengthened Fake idempotency semantics in 4c221aad; it is unrelated to current Phase 220 work.
- timestamp: 2026-08-04T20:52:36Z
  checked: Test-only counterfactual using a fresh second-call operation ID
  found: `mix test test/accrue_host/billing_facade_test.exs:160 --trace` passed and the complete `billing_facade_test.exs` module passed 18 tests. The focused Phase 217 Fake idempotency test also passed.
  implication: A second operation identity is sufficient and directly validates the proposed test-only patch; the source experiment was restored.

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: `BillingFacadeTest` predates Fake's 4c221aad idempotency caching. `AccrueCase` installs one operation ID per test, so two identical `Billing.subscribe/3` calls derive the same provider idempotency key. Fake correctly returns its first subscription; `SubscriptionActions` then attempts a second local insert for that provider ID, which the required `(processor, processor_id)` unique index rejects. The test is asking for two distinct subscriptions without declaring two distinct operations.
fix: Test-only: pass a fresh explicit `operation_id` to the second `Billing.subscribe/3` call in `billing_state_for/1 returns the fake-backed customer and latest subscription`. Do not weaken the unique index, disable Fake idempotency, or change production creation behavior for this proof.
verification: `MIX_ENV=test mix test test/accrue_host/billing_facade_test.exs test/accrue_host/braintree_subscribe_test.exs --warnings-as-errors` passed (20 tests).
files_changed: [examples/accrue_host/test/accrue_host/billing_facade_test.exs]
