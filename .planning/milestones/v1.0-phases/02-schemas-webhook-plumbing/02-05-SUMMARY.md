---
phase: 02-schemas-webhook-plumbing
plan: 05
subsystem: payments
tags: [idempotency, api-version, billing-context, transactional-events, ecto-multi]

# Dependency graph
requires:
  - plan: 02-01
    provides: Customer schema, Processor behaviour, Events module
  - plan: 02-02
    provides: Billable macro, Billing context with create_customer
  - plan: 02-04
    provides: Webhook ingest pipeline, handler dispatch
provides:
  - Deterministic idempotency keys for outbound Stripe calls (PROC-04)
  - Per-request API version override with three-level precedence (PROC-06)
  - Billing context update_customer with transactional event recording
  - put_data/2 and patch_data/2 for data column operations (D2-08)
  - EVT-04 rollback invariant proven by test
affects: [phase-03, phase-04, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SHA-256 deterministic idempotency key with accr_ prefix"
    - "Process dictionary seed resolution chain for idempotency"
    - "Three-level API version precedence (opts > pdict > config)"
    - "Ecto.Multi atomic update + event recording"
    - "Optimistic lock on data column operations"

key-files:
  created:
    - accrue/lib/accrue/stripe.ex
    - accrue/test/accrue/processor/idempotency_test.exs
    - accrue/test/accrue/billing/events_transaction_test.exs
  modified:
    - accrue/lib/accrue/processor/stripe.ex
    - accrue/lib/accrue/processor/fake.ex
    - accrue/lib/accrue/processor/fake/state.ex
    - accrue/lib/accrue/actor.ex
    - accrue/lib/accrue/config.ex
    - accrue/lib/accrue/billing.ex

key-decisions:
  - "compute_idempotency_key and resolve_api_version are public on Processor.Stripe for testability"
  - "Fake processor idempotency cache stored in GenServer state, reset on reset/0"
  - "Rollback test uses baseline count comparison for robustness against pre-existing data"

patterns-established:
  - "Idempotency key: accr_ + 22-char base64url of SHA-256(op|subject_id|seed)"
  - "API version override: Accrue.Stripe.with_api_version/2 push/pop helper"
  - "Actor.current_operation_id/0 for cross-cutting seed propagation"

requirements-completed: [PROC-04, PROC-06, EVT-04]

# Metrics
duration: 9min
completed: 2026-04-12
---

# Phase 02 Plan 05: Processor Extensions + Billing Transactional Events Summary

**Deterministic idempotency keys via SHA-256 with accr_ prefix and seed resolution chain, three-level API version precedence, Billing context update_customer/put_data/patch_data with atomic event recording, EVT-04 rollback invariant proven by test -- 19 passing tests**

## What Was Built

### Deterministic Idempotency Keys (D2-11, D2-12, PROC-04)

`Accrue.Processor.Stripe.compute_idempotency_key/3` computes `"accr_" + 22-char base64url` from SHA-256 of `"#{op}|#{subject_id}|#{seed}"`. The seed resolution chain follows D2-12:

1. `opts[:operation_id]` (explicit per-call)
2. `Accrue.Actor.current_operation_id/0` (process dict, set by Oban middleware / webhook plug)
3. Random UUID fallback with `Logger.warning` (observable non-determinism)

All Stripe adapter callbacks (`create_customer/2`, `retrieve_customer/2`, `update_customer/3`) now pass `:idempotency_key` and `:stripe_version` to lattice_stripe calls.

### Per-Request API Version Override (D2-14, D2-15, PROC-06)

`Accrue.Processor.Stripe.resolve_api_version/1` implements three-level precedence:

1. `opts[:api_version]` (explicit per-call)
2. `Process.get(:accrue_stripe_api_version)` (scoped via helper)
3. `Accrue.Config.stripe_api_version/0` (application config)

`Accrue.Stripe.with_api_version/2` provides a push/pop helper for traffic-split rollouts, restoring the previous pdict value even on exception.

### Actor Operation ID (D2-12)

`Accrue.Actor.current_operation_id/0` and `put_operation_id/1` extend the Actor module with process-dict-backed operation ID storage. Oban middleware and webhook plug can set this so downstream processor calls produce deterministic idempotency keys.

### Fake Processor Idempotency Tracking

The Fake processor now maintains an `idempotency_cache` in its GenServer state. When the same idempotency key is used twice, it returns the cached result (matching Stripe's behavior). Cache is cleared on `reset/0`.

### Billing Context Extensions (D2-07, D2-08, D2-09, EVT-04)

- **`update_customer/2`** -- Updates customer with metadata validation (D2-07) and records a `"customer.updated"` event atomically via `Ecto.Multi` (EVT-04).
- **`put_data/2`** -- Full replacement of the `data` jsonb column with optimistic locking (D2-08).
- **`patch_data/2`** -- Shallow merge into existing `data` with optimistic locking (D2-08).

### EVT-04 Rollback Proof

The rollback test creates a customer inside a wrapping transaction, verifies both customer and event rows exist, then rolls back. After rollback, both rows return to baseline counts -- proving the same-transaction invariant.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unused @default_api_version module attribute**
- **Found during:** Task 1, compilation
- **Issue:** After moving API version resolution to `Accrue.Config.stripe_api_version/0`, the `@default_api_version` attribute became unused, failing `--warnings-as-errors`.
- **Fix:** Commented out the attribute with documentation reference.
- **Files modified:** accrue/lib/accrue/processor/stripe.ex
- **Commit:** ad247c5

**2. [Rule 1 - Bug] Default arg on private build_client!/1**
- **Found during:** Task 1, compilation
- **Issue:** `defp build_client!(opts \\ [])` generated a warning since all call sites pass opts explicitly.
- **Fix:** Removed default argument.
- **Files modified:** accrue/lib/accrue/processor/stripe.ex
- **Commit:** ad247c5

**3. [Rule 1 - Bug] Rollback test fragile against pre-existing data**
- **Found during:** Task 2, GREEN phase
- **Issue:** `assert count == 0` after rollback failed because a residual event row existed in the test DB from a previous run (immutability trigger prevents DELETE cleanup).
- **Fix:** Changed to baseline count comparison (`count_after == count_before`) for robustness.
- **Files modified:** accrue/test/accrue/billing/events_transaction_test.exs
- **Commit:** 868cc40

## Verification

- `mix compile --warnings-as-errors` exits 0
- `mix test test/accrue/processor/idempotency_test.exs` -- 12 tests, 0 failures
- `mix test test/accrue/billing/events_transaction_test.exs` -- 7 tests, 0 failures
- Idempotency key is deterministic for same inputs, unique for different inputs
- API version three-level precedence verified
- Rollback test proves both customer and event disappear together

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 RED | e097239 | Failing tests for idempotency keys + API version override |
| 1 GREEN | ad247c5 | Deterministic idempotency keys, API version override, Fake tracking |
| 2 RED | 4c8982d | Failing tests for billing transactional events + EVT-04 rollback |
| 2 GREEN | 868cc40 | Billing context update_customer, put_data, patch_data, rollback proof |

## Self-Check: PASSED

- All 9 source/test files: FOUND
- All 4 commits (e097239, ad247c5, 4c8982d, 868cc40): FOUND
