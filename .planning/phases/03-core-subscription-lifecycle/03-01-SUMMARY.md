---
phase: 03-core-subscription-lifecycle
plan: 01
subsystem: core-subscription-lifecycle
tags: [scaffolding, clock, credo, facade, errors, test-support]
dependency_graph:
  requires:
    - "Phase 2: Accrue.Actor, Accrue.Config, Accrue.Errors, Accrue.Processor.Fake"
  provides:
    - "Accrue.Clock canonical time source"
    - "Accrue.Actor.current_operation_id!/0"
    - "Accrue.Config :expiring_card_thresholds / :idempotency_mode / :succeeded_refund_retention_days"
    - "Accrue.Error.{MultiItemSubscription,InvalidState,NotAttached,NoDefaultPaymentMethod}"
    - "Accrue.ActionRequiredError"
    - "Accrue.Credo.NoRawStatusAccess BILL-05 enforcement"
    - "Accrue.BillingCase ExUnit template"
    - "Accrue.Test.StripeFixtures"
    - "Accrue.Billing facade with 44 Phase 3 defdelegates"
    - "Accrue.Billing.{Subscription,Invoice,Charge,PaymentMethod,Refund}Actions stubs"
  affects:
    - "Every Phase 3 Wave 2 plan (04/05/06) now targets action modules, not billing.ex"
    - "All Phase 3 tests use Accrue.Clock instead of DateTime.utc_now/0"
tech_stack:
  added: []
  patterns:
    - "Action-module facade: defdelegate block in Accrue.Billing → per-surface *_actions.ex modules, eliminating Wave 2 fan-in collision"
    - "Runtime env branch in Accrue.Clock: test env reads Fake.now/0, prod reads DateTime.utc_now/0"
    - "Stub-and-raise pattern for forward-declared action modules (defdelegate in modern Elixir is compile-checked)"
    - "Credo AST walker with defmodule-stack tracking + filename exemption for lint-time domain rules"
key_files:
  created:
    - accrue/lib/accrue/clock.ex
    - accrue/lib/accrue/credo/no_raw_status_access.ex
    - accrue/lib/accrue/billing/subscription_actions.ex
    - accrue/lib/accrue/billing/invoice_actions.ex
    - accrue/lib/accrue/billing/charge_actions.ex
    - accrue/lib/accrue/billing/payment_method_actions.ex
    - accrue/lib/accrue/billing/refund_actions.ex
    - accrue/test/accrue/clock_test.exs
    - accrue/test/accrue/credo/no_raw_status_access_test.exs
    - accrue/test/support/billing_case.ex
    - accrue/test/support/stripe_fixtures.ex
    - accrue/.credo.exs
  modified:
    - accrue/lib/accrue/actor.ex
    - accrue/lib/accrue/config.ex
    - accrue/lib/accrue/errors.ex
    - accrue/lib/accrue/processor/fake.ex
    - accrue/lib/accrue/billing.ex
    - accrue/test/test_helper.exs
decisions:
  - "defdelegate IS compile-checked in modern Elixir — action modules must expose declarative stub heads, not be empty. Resolved by raising a per-module NotImplementedError."
  - "Credo check scope is Subscription-shaped code only. Plain '.status == X' is too broad and false-positives on WebhookEvent.status / Ecto query fragments. Narrowed the pattern to '.status == <stripe_status_atom>' and 'in [<stripe_status_atoms>]' to eliminate false positives."
  - "Test files under test/ are exempt from NoRawStatusAccess — tests assert directly on Stripe payloads and predicates don't apply."
  - "Credo.Test.Case requires Credo.Service.SourceFileAST to be alive, which comes from the :credo application. test_helper.exs now starts it explicitly."
  - "Accrue.Processor.Fake.now/0 added as a thin wrapper over current_time/0 — gives Accrue.Clock a grep-stable delegation target while keeping the existing current_time/1 API for explicit-server tests."
metrics:
  duration: "~9 minutes"
  completed: "2026-04-14"
  tasks_completed: 4
  files_created: 12
  files_modified: 6
  test_count: "204 tests, 20 properties, 0 failures"
requirements: [TEST-08, BILL-05]
---

# Phase 3 Plan 01: Wave 1 scaffolding (Clock, Credo, facade, errors, test support) Summary

Phase 3 Wave 1 groundwork: canonical Accrue.Clock module with Fake.now/0 dispatch in test env, Accrue.Actor.current_operation_id!/0 for idempotency-key derivation, three new Config keys (expiring_card_thresholds / idempotency_mode / succeeded_refund_retention_days), five new Phase 3 error types (MultiItemSubscription, InvalidState, NotAttached, NoDefaultPaymentMethod, ActionRequiredError), Accrue.Credo.NoRawStatusAccess custom lint-time check enforcing BILL-05, BillingCase ExUnit template + StripeFixtures canned Stripe payloads, and the Accrue.Billing facade with 44 defdelegates routing to 5 stub action modules that Wave 2 plans (04/05/06) will fill in without touching billing.ex.

## Work Completed

### Task 1 — Clock, Actor.current_operation_id!, Config, Errors (TDD)

**Commit:** `6114fa8` (RED `9ee0ed9`)

- `Accrue.Clock.utc_now/0` dispatches to `Accrue.Processor.Fake.now/0` when
  `Application.get_env(:accrue, :env) == :test`, else `DateTime.utc_now/0`.
  This is the canonical time source for every Phase 3 module — trial
  windows, dunning, expiring-card notices, refund retention windows all
  read through Clock, which makes them deterministically testable via
  `Fake.advance/2`.
- Added `Accrue.Processor.Fake.now/0` as a zero-arg wrapper over
  `current_time(__MODULE__)` so Accrue.Clock has a grep-stable callee.
- Added `Accrue.Actor.current_operation_id!/0` — raises
  `Accrue.ConfigError` in `:strict` idempotency mode; warns + generates
  a throwaway `Ecto.UUID` in `:warn` mode. The existing
  `current_operation_id/0` (non-raising) and `put_operation_id/1` were
  already in place from Phase 2.
- Extended `Accrue.Config` NimbleOptions schema with three Phase 3
  keys:
  - `:expiring_card_thresholds` — strictly-descending list of pos-ints,
    default `[30, 7, 1]`, validated by a custom
    `validate_descending/1` function that enforces both positivity and
    monotonic descent.
  - `:idempotency_mode` — `:warn | :strict`, default `:warn`.
  - `:succeeded_refund_retention_days` — pos-int, default `90`.
- Added five new exceptions in `accrue/lib/accrue/errors.ex`:
  - `Accrue.Error.MultiItemSubscription` — single-item Phase 3 invariant
    guard, points at Plan 04 multi-item APIs.
  - `Accrue.Error.InvalidState` — illegal state-machine transitions
    (e.g., `pay_invoice` on a `:void` invoice).
  - `Accrue.Error.NotAttached` — payment method not attached to the
    referenced customer.
  - `Accrue.Error.NoDefaultPaymentMethod` — customer has no default PM.
  - `Accrue.ActionRequiredError` — Stripe requires SCA/3DS customer
    action; carries the full PaymentIntent payload for client-side
    confirmation.
- TDD: RED test committed first (3 Clock tests failed with
  `UndefinedFunctionError`), then GREEN with the Clock module + Fake.now
  + Actor operation_id + Config + Errors.

### Task 2 — Accrue.Credo.NoRawStatusAccess (BILL-05 enforcement)

**Commit:** `9bdadcc`

- Custom Credo check that flags raw `subscription.status` comparisons at
  lint time. Walks the AST with `Macro.traverse/4` tracking the current
  `defmodule` stack to exempt `Accrue.Billing.Subscription` and its
  descendants. Exempts files under `test/` so tests can assert on
  Stripe-shaped payloads directly.
- Flags these patterns:
  - `sub.status == :active` (or any `@stripe_statuses` atom)
  - `:active == sub.status` (reversed form)
  - `sub.status in [:active, :trialing, ...]` — only if at least one
    list element is a Stripe status atom, to avoid false-positives on
    `WebhookEvent.status in [:succeeded, :dead]` Ecto queries.
- 4 test cases: positive (`==`), positive (`in`), negative (predicate
  call), exempt (`Accrue.Billing.Subscription` module body).
- Registered in new `accrue/.credo.exs` with `strict: true` and the
  custom check in the `enabled:` list.
- `test_helper.exs` now starts the `:credo` application so
  `Credo.Test.Case` has access to `Credo.Service.SourceFileAST`.
- Self-lint clean: `mix credo --strict --only Accrue.Credo.NoRawStatusAccess`
  reports zero issues across 94 source files.

### Task 3 — BillingCase + StripeFixtures

**Commit:** `0dc8675`

- `Accrue.BillingCase` ExUnit template:
  - Checks out `Accrue.TestRepo` sandbox (shared mode unless
    `async: true`), stops on exit.
  - Starts + resets `Accrue.Processor.Fake`.
  - Forces `:accrue, :env` to `:test` (so Clock reads Fake), restores
    prior value on exit.
  - Seeds a unique `test-<UUID>` operation ID per test so idempotency
    keys don't collide across parallel tests.
- `Accrue.Test.StripeFixtures`: canned Stripe API response payloads as
  plain string-key maps with deep-merge override semantics. Covers
  `subscription_created/updated`, `invoice`, `payment_intent_requires_action/
  succeeded`, `setup_intent_requires_action`, `charge`, `refund`,
  `payment_method_card`, `webhook_event/3`.

### Task 4 — Accrue.Billing facade + 5 action-module stubs

**Commit:** `19590b8`

- `Accrue.Billing` gains a defdelegate block covering 44 Phase 3
  functions, routed to per-surface action modules:
  - Subscription surface (Plan 04): 20 functions
  - Invoice surface (Plan 05): 10 functions
  - Charge/PaymentIntent/SetupIntent surface (Plan 06): 6 functions
  - PaymentMethod surface (Plan 06): 6 functions
  - Refund surface (Plan 06): 2 functions
- Created 5 stub action modules under `accrue/lib/accrue/billing/`. Each
  exposes the full function heads so `defdelegate` compiles under
  `--warnings-as-errors`. Every stub raises a per-module
  `NotImplementedError` so any accidental pre-Wave-2 call fails loudly
  at runtime with a pointer at the owning plan number.
- This resolves the Wave 2 fan-in blocker from the phase plan: three
  parallel plans would otherwise all need to write to `billing.ex`,
  forcing serial execution. With the facade front-loaded, Wave 2 plans
  target disjoint files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `Accrue.Processor.Fake.now/0`**
- **Found during:** Task 1
- **Issue:** Plan assumes `Fake.now/0` exists as the canonical test-clock accessor, but Phase 1 only shipped `current_time/1` (with an explicit server arg). Clock's delegation target was missing.
- **Fix:** Added a zero-arg `Fake.now/0` wrapper over `current_time(__MODULE__)`. Keeps the grep pattern `Fake.now` stable across Phase 3 code, and leaves the existing explicit-server API in place for tests that need it.
- **Files modified:** `accrue/lib/accrue/processor/fake.ex`
- **Commit:** `6114fa8`

**2. [Rule 3 - Blocking] `defdelegate` is compile-checked, not runtime-checked**
- **Found during:** Task 4
- **Issue:** Plan explicitly states "`defdelegate` is NOT compile-checked against target function existence in Elixir". That was true in older Elixir; modern Elixir (1.17+, matching our pinned floor) emits `warning: Accrue.Billing.FooActions.bar/2 is undefined or private` for every missing target, which `--warnings-as-errors` promotes to a build break. Empty `@moduledoc false` stubs would not compile.
- **Fix:** Each action module now declares the full set of forward-declared function heads with raise-on-call bodies (per-module `NotImplementedError`). Wave 2 plans overwrite those bodies with real logic. The facade shape is unchanged, and the stub-and-raise pattern preserves the "calling it before Wave 2 blows up loudly" runtime contract.
- **Files modified:** All 5 `*_actions.ex` modules
- **Commit:** `19590b8`

**3. [Rule 2 - Missing critical functionality] Credo test infrastructure**
- **Found during:** Task 2
- **Issue:** `Credo.Test.Case` calls `Credo.Service.SourceFileAST.put/2` during `to_source_file/1`, which is a `GenServer.call` against a process started by the `:credo` application. That application isn't started by default in test runs, so every test crashed with `no process: the process is not alive or there's no process currently associated with the given name`.
- **Fix:** Added `{:ok, _} = Application.ensure_all_started(:credo)` at the top of `test/test_helper.exs`. Credo's supervision tree now comes up before ExUnit starts.
- **Files modified:** `accrue/test/test_helper.exs`
- **Commit:** `9bdadcc`

**4. [Rule 1 - Bug] Credo check false-positive on Ecto query fragments**
- **Found during:** Task 2 full-tree lint
- **Issue:** Initial AST pattern `{:==, _, [{{:., _, [_, :status]}, _, _}, _rhs]}` matched `w.status == :succeeded` inside `from` queries (`Accrue.Webhook.Pruner`) — false positive, because `WebhookEvent.status` is not `Subscription.status`.
- **Fix:** Narrowed the AST patterns to only match when the comparand is a `@stripe_statuses` atom (`trialing | active | past_due | canceled | unpaid | incomplete | incomplete_expired | paused`). Similar narrowing on the `in` clause: only flag if the list contains at least one Stripe status atom. Non-Subscription `.status` comparisons are now correctly ignored.
- **Files modified:** `accrue/lib/accrue/credo/no_raw_status_access.ex`
- **Commit:** `9bdadcc`

**5. [Rule 2 - Missing critical functionality] Test file exemption**
- **Found during:** Task 2 full-tree lint
- **Issue:** Plan specifies "files under `accrue/test/`" should be exempt. Initial implementation only exempted by module name (`Accrue.Billing.Subscription`), not by filename, which tripped on `accrue/test/accrue/webhook/ingest_test.exs`.
- **Fix:** Added `exempt_file?/1` guard on `run/2` that short-circuits when `source_file.filename` contains `"/test/"` or starts with `"test/"`. Tests assert on Stripe payloads directly and predicates don't apply there.
- **Files modified:** `accrue/lib/accrue/credo/no_raw_status_access.ex`
- **Commit:** `9bdadcc`

## Verification Results

- `mix compile --warnings-as-errors` — clean (0 warnings)
- `mix test` — 204 tests, 20 properties, 0 failures
- `mix credo --strict --only Accrue.Credo.NoRawStatusAccess` — 0 issues across 94 source files
- `mix test test/accrue/clock_test.exs` — 3/3 pass (Fake delegation, clock advancement, prod-env fallback)
- `mix test test/accrue/credo/no_raw_status_access_test.exs` — 4/4 pass (positive ==, positive in, negative predicate, exempt module)

## Success Criteria

- [x] `Accrue.Clock.utc_now/0` returns `Accrue.Processor.Fake.now/0` in test env (proven by test)
- [x] `Accrue.Actor.current_operation_id!/0` raises in `:strict` mode, warns + generates in `:warn` mode
- [x] Credo check flags raw `.status == :active` and `.status in [:active, :trialing]`, exempts `Accrue.Billing.Subscription` module and test files
- [x] Phase 3 Error hierarchy (5 new types) in place and compilable
- [x] `Accrue.BillingCase` + `Accrue.Test.StripeFixtures` importable from test modules
- [x] `Accrue.Billing` facade declares all 44 Phase 3 functions via `defdelegate` to 5 disjoint action modules — Wave 2 plans can run parallel without touching billing.ex

## Acceptance Criteria Checklist

All acceptance criteria from each task's `<acceptance_criteria>` block pass:

- [x] `grep -q "defmodule Accrue.Clock"` — present
- [x] `grep -q "def utc_now"` — present
- [x] `grep -q "Accrue.Processor.Fake.now"` in Clock — present
- [x] `grep -q "def put_operation_id"` in Actor — present
- [x] `grep -q "def current_operation_id!"` in Actor — present
- [x] `:expiring_card_thresholds` / `:idempotency_mode` in Config — present
- [x] All 5 new Error modules — present
- [x] `defmodule Accrue.Credo.NoRawStatusAccess` + `use Credo.Check` — present
- [x] Registered in `accrue/.credo.exs` — present
- [x] 4 Credo test cases pass, 0 self-lint issues
- [x] `Accrue.BillingCase` + `Accrue.Test.StripeFixtures` — present, compile clean
- [x] `defdelegate subscribe/swap_plan/finalize_invoice/pay_invoice/charge/attach_payment_method/create_refund` all present in `billing.ex`
- [x] All 5 action-module stubs present and compilable

## Self-Check: PASSED

All created files exist, all commits are in the log:
- `accrue/lib/accrue/clock.ex` — FOUND
- `accrue/lib/accrue/credo/no_raw_status_access.ex` — FOUND
- `accrue/lib/accrue/billing/{subscription,invoice,charge,payment_method,refund}_actions.ex` — all FOUND
- `accrue/test/accrue/clock_test.exs` — FOUND
- `accrue/test/accrue/credo/no_raw_status_access_test.exs` — FOUND
- `accrue/test/support/{billing_case,stripe_fixtures}.ex` — all FOUND
- `accrue/.credo.exs` — FOUND
- Commit `9ee0ed9` (RED) — FOUND
- Commit `6114fa8` (Task 1 GREEN) — FOUND
- Commit `9bdadcc` (Task 2) — FOUND
- Commit `0dc8675` (Task 3) — FOUND
- Commit `19590b8` (Task 4) — FOUND
