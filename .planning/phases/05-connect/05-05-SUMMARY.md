---
phase: 05-connect
plan: 05
subsystem: connect
tags: [connect, destination_charge, transfer, separate_charge_transfer, telemetry, fake_scope]

requires:
  - phase: 05-connect
    plan: 02
    provides: "Accrue.Connect facade + Fake caller-side pdict→opts threading pattern + ConnectCase pdict cleanup"
  - phase: 05-connect
    plan: 04
    provides: "Accrue.Connect.platform_fee/2 pure Money helper (caller-inject fees)"
provides:
  - "Accrue.Connect.destination_charge/2 + destination_charge!/2 — single platform-scoped charge with transfer_data.destination and caller-injected application_fee_amount; forces stripe_account nil regardless of with_account/2"
  - "Accrue.Connect.separate_charge_and_transfer/2 + bang — two distinct API calls (charge on platform, then transfer) with {:error, {:transfer_failed, charge, err}} reconciliation path"
  - "Accrue.Connect.transfer/2 + bang — thin standalone Transfer helper recording a connect.transfer event ledger row"
  - "Accrue.Processor.Stripe.create_transfer/2 + retrieve_transfer/2 routed through build_platform_client!/1"
  - "Accrue.Processor.Fake.create_charge scope-awareness via caller-side thread_scope/1; build_charge stamps _accrue_scope + preserves transfer_data + application_fee_amount from params"
  - "Accrue.Processor.Fake.call_count/1 + transfers_on/1 test helpers; dedicated :transfer counter (fixes pre-existing :connect_account counter reuse bug); state.transfers store for round-trippable retrieve_transfer"
  - "resolve_scope/1 Keyword.has_key? short-circuit — an explicit stripe_account: nil in opts forces :platform scope instead of falling through to pdict (D5-03 Pitfall 2 guard)"
affects: [05-06, 05-07]

tech-stack:
  added: []
  patterns:
    - "Explicit-nil sentinel for forced-platform processor calls: when an endpoint must NEVER carry the Stripe-Account header (transfers, destination_charge's platform-authority leg), callers set stripe_account: nil in opts and the Fake's resolve_scope/1 treats a Keyword.has_key?(opts, :stripe_account) match as authoritative — value nil means :platform. Previously the || chain treated nil as 'fall through' which silently leaked pdict onto platform calls. This complements the Plan 05-03 build_platform_client!/1 Stripe-side pattern."
    - "Telemetry.span wrapping for each Connect money-movement helper. [:accrue, :connect, :destination_charge|:separate_charge_and_transfer|:transfer, :start|:stop|:exception] — metadata carries :destination, :amount_minor, :currency so the stop-event observer can audit fee/destination without re-reading the charge row."
    - "Reconciliation tuple on partial failure: separate_charge_and_transfer/2 returns {:error, {:transfer_failed, %Charge{}, underlying_err}} — the charge row is persisted, the caller holds a typed reference to it, and can issue a retry or manual transfer. Cleaner than raising or returning {:ok, %{charge, transfer: nil}} because pattern matching is exhaustive."

key-files:
  created:
    - "accrue/test/accrue/connect/charges_test.exs"
    - "accrue/test/accrue/connect/transfer_test.exs"
  modified:
    - "accrue/lib/accrue/connect.ex"
    - "accrue/lib/accrue/processor/stripe.ex"
    - "accrue/lib/accrue/processor/fake.ex"
    - "accrue/lib/accrue/processor/fake/state.ex"

key-decisions:
  - "Phase 05 P05: Explicit stripe_account: nil sentinel in opts forces :platform scope in the Fake's resolve_scope/1 via a Keyword.has_key?/2 short-circuit. The existing `Keyword.get || Process.get || :platform` chain treated explicit nil as a fall-through, which would have let a with_account/2 pdict leak onto the very platform-authority calls this plan ships. This is the Fake-side complement to Plan 05-03's build_platform_client!/1 pattern."
  - "Phase 05 P05: Connect.destination_charge/2 and friends require %Accrue.Billing.Customer{} structs (not raw customer id strings) so the local Charge row can be persisted via the Phase 3 Charge.changeset path. A bare id would require a separate lookup that would silently coerce misuse; returning a typed %ConfigError{key: :customer} makes misuse loud."
  - "Phase 05 P05: separate_charge_and_transfer/2 returns {:error, {:transfer_failed, charge, err}} instead of raising or dropping the charge. Matches D5-05 events-ledger principle — partial state always persists, callers reconcile, no silent loss."
  - "Phase 05 P05: Fake :connect_account counter reuse bug fix (Rule 1 — latent). The Plan 05-02 shipped create_transfer handle_call pulling its counter from state.counters[:connect_account], which meant creating a connected account and then a transfer shared the counter namespace. Separate :transfer slot added to State + counters map. No existing tests depended on the shared counter (pre-Plan-05-05 transfers were never retrieved by id)."
  - "Phase 05 P05: transfer/2 records 'connect.transfer' events via Accrue.Events.record/1 in-line (not inside a Repo.transact with the processor call) because D5-05 is events-ledger-only: there is no local transfer schema to wrap atomically. Matches the Plan 05-03 AccountLink/LoginLink pattern of event-only side effects."

patterns-established:
  - "Explicit-nil opt sentinel for platform-scoped Fake calls: Keyword.put(opts, :stripe_account, nil) on the caller side, Keyword.has_key?/2-first resolver on the Fake side. Use for every Connect surface that must not carry a Stripe-Account header regardless of pdict context."
  - "Reconciliation tuple shape for partial-failure flows: {:error, {:<step>_failed, %PartialState{}, underlying_err}}. Preserve the partial success as a typed struct in the tuple, not a map blob, so callers get compile-time guarantees about what survived."
  - "Fake.call_count/1 + bump_call_count/2 in with_script_or_stub: every op increments its counter BEFORE the scripts/stubs check, so scripted-error paths also count as invocations — the test that counts calls should see the same count whether the underlying handler succeeded or a scripted error was consumed."

requirements-completed: [CONN-04, CONN-05]

duration: 20min
completed: 2026-04-15
---

# Phase 05 Plan 05: Connect Charges + Transfers Summary

**Ships `Accrue.Connect.destination_charge/2`, `separate_charge_and_transfer/2`, and `transfer/2` — the three Connect money-movement helpers per D5-03 — each with its own telemetry span, explicit platform-scope enforcement, and ExDoc section; plus the Stripe adapter's `create_transfer/2`/`retrieve_transfer/2` delegations routed through `build_platform_client!/1`, and Fake processor scope-awareness on `create_charge` + dedicated transfer store — delivering CONN-04 and CONN-05 in ~20 minutes with 0 regressions across 677 tests.**

## Performance

- **Duration:** ~20 min
- **Tasks:** 1 (`type="auto" tdd="true"`)
- **Commits:** 1 (`f5e4dac`)
- **Tests added:** 16 (11 `charges_test.exs` + 5 `transfer_test.exs`)
- **Tests total:** 677 tests / 44 properties / 0 failures (full suite at seed 0)
- **Files created:** 2
- **Files modified:** 4

## Accomplishments

1. **CONN-04 destination_charge/2 (6 tests).** Single platform-scoped charge with `transfer_data: %{destination: acct_id}` and optional caller-supplied `application_fee_amount`. Forces `stripe_account: nil` into the opts unconditionally so the Pitfall 2 threat is closed even when called inside `Accrue.Connect.with_account/2`. Returns `{:ok, %Accrue.Billing.Charge{}}` via the same `Charge.changeset` path used by `Accrue.Billing.charge/3` — the local row ships with the Stripe response decoded into the jsonb `data` column. Telemetry span carries `:destination`, `:amount_minor`, `:currency` metadata.

2. **CONN-05 separate_charge_and_transfer/2 (4 tests).** Two distinct API calls — `Processor.create_charge` on the platform followed by `Processor.create_transfer` to the connected account with `source_transaction` linked to the new charge's processor id. Both legs force platform scope. On transfer failure after charge success, returns `{:error, {:transfer_failed, %Charge{}, err}}` — the charge row is persisted so callers can reconcile, matching T-05-05-03 mitigation. Tested via `Fake.call_count/1` to assert exactly one `create_charge` + one `create_transfer` invocation per helper call (VALIDATION row 13).

3. **CONN-05 standalone transfer/2 (5 tests).** Thin wrapper over `Processor.create_transfer/2` — validates opts via NimbleOptions, forces platform scope, records a `connect.transfer` event ledger row on success (D5-05 events-only; no dedicated transfer schema). Tests cover round-trip through Fake, events ledger append, telemetry span attachment, force-platform under `with_account/2`, and the `transfer!/2` bang variant's raise-on-error semantics.

4. **Stripe adapter Transfer delegations.** `Accrue.Processor.Stripe.create_transfer/2` and `retrieve_transfer/2` delegate to `LatticeStripe.Transfer.create/3` and `retrieve/3` respectively. Both are routed through the Plan 05-03 `build_platform_client!/1` helper which bypasses `resolve_stripe_account/1` so the `Stripe-Account` header cannot leak from a caller's `with_account/2` pdict. Stripe-side Pitfall 2 guard aligned with the Fake-side explicit-nil sentinel.

5. **Fake scope-awareness on create_charge.** `Accrue.Processor.Fake.create_charge/2` now calls `thread_scope/1` to read the caller's `:accrue_connected_account_id` pdict key and thread it into opts as `:stripe_account` before the `GenServer.call` — following the Plan 05-02 caller-side pdict→opts pattern. The handle_call's `build_charge/4` stamps `_accrue_scope` on the stored charge (visible via `Fake.charges_on/1`) and preserves `transfer_data` + `application_fee_amount` from params so tests can assert them.

6. **`resolve_scope/1` Keyword.has_key? short-circuit.** Previously `Keyword.get(opts, :stripe_account) || Process.get(...) || :platform` — but `Keyword.get` returns nil when the key is literally `nil`, and nil is falsy in an `||` chain, so an explicit `stripe_account: nil` fell through to the pdict and re-inherited the caller's `with_account/2` scope. Now: `Keyword.has_key?(opts, :stripe_account) -> Keyword.get(opts, :stripe_account) || :platform` wins first. Explicit nil means `:platform`, period. This is the Fake-side complement to Plan 05-03's `build_platform_client!/1` Stripe-side pattern.

7. **Fake `:transfer` counter + `transfers` store.** Plan 05-02 shipped a `create_transfer` stub that bumped `state.counters[:connect_account]` for transfer ids — a latent bug where a mixed workload of account creation and transfer creation would mangle both counters. Fixed (Rule 1) by adding a dedicated `:transfer` counter, a `state.transfers` map keyed by id, `transfers_on/1` scope-inspection helper, and a `retrieve_transfer` handle_call that looks up from `state.transfers` first (falling back to the pre-existing stub-shape for tests that retrieve without having created). `Fake.call_count/1` public helper added for test-side assertion.

## Task Commits

1. **Task 1: destination_charge + separate_charge_and_transfer + transfer + Stripe adapter Transfer delegations + Fake scope/counter/call_count fixes + 16 tests** — `f5e4dac` (feat)

## Files Created/Modified

### Created
- `accrue/test/accrue/connect/charges_test.exs` — 11 tests (6 destination_charge + 5 separate_charge_and_transfer)
- `accrue/test/accrue/connect/transfer_test.exs` — 5 tests covering round-trip, events ledger, telemetry, force-platform, bang-variant

### Modified
- `accrue/lib/accrue/connect.ex` — +~400 LOC: three public helpers + three bang variants + three NimbleOptions schemas + persist_charge helper + record_connect_event helper + stringify_charge jsonb normalizer + aliases for Accrue.Billing.Charge and Accrue.Money
- `accrue/lib/accrue/processor/stripe.ex` — `create_transfer/2` and `retrieve_transfer/2` via `build_platform_client!/1`
- `accrue/lib/accrue/processor/fake.ex` — `create_charge/2` threads scope; `build_charge/4` stamps scope and preserves transfer_data/application_fee_amount; `resolve_scope/1` Keyword.has_key? short-circuit; `:create_transfer` uses :transfer counter + state.transfers store + scope stamp; `retrieve_transfer` looks up from store; `transfers_on/1` helper; `call_count/1` helper; `bump_call_count/2` in `with_script_or_stub`; `resources_on` accepts `:transfers`
- `accrue/lib/accrue/processor/fake/state.ex` — `transfers: %{}` map, `call_counts: %{}` map, `:transfer` counter slot

## Decisions Made

- **Explicit `stripe_account: nil` in opts as Fake-side platform sentinel.** See key-decisions section. Complements Plan 05-03's Stripe-side `build_platform_client!/1`.
- **Require `%Accrue.Billing.Customer{}` struct in destination_charge/separate_charge_and_transfer params.** A bare customer id string cannot be persisted (no FK). Returning `%Accrue.ConfigError{key: :customer}` makes the requirement loud at the call site instead of silently succeeding without a local row.
- **Reconciliation tuple for separate_charge_and_transfer partial failure.** `{:error, {:transfer_failed, charge, err}}` is exhaustively pattern-matchable and preserves the surviving side's full typed struct. D5-05 events-ledger principle: partial state always persists.
- **`transfer/2` records events out-of-band (not in a Repo.transact).** There is no local transfer schema to wrap the processor call with (D5-05), so the events.record call is a simple post-success append. This mirrors Plan 05-03's AccountLink/LoginLink event-only pattern.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fake `:connect_account` counter reused for transfer ids**
- **Found during:** Task 1 design (reading the existing `handle_call({:create_transfer, ...})` from Plan 05-02)
- **Issue:** The Plan 05-02 create_transfer handle_call incremented `state.counters[:connect_account]` for transfer id generation. A mixed workload would have both account creation and transfer creation fighting for the same counter slot, producing misleading account/transfer ids.
- **Fix:** Added `:transfer` slot to `State.counters` and `state.transfers` map. `create_transfer` handle_call now bumps `:transfer` and stores the created transfer in `state.transfers` keyed by id. `retrieve_transfer` looks up from `state.transfers` first.
- **Files modified:** `accrue/lib/accrue/processor/fake.ex`, `accrue/lib/accrue/processor/fake/state.ex`
- **Committed in:** `f5e4dac`

**2. [Rule 1 - Bug] `resolve_scope/1` || fall-through leaked pdict onto explicit-nil calls**
- **Found during:** Task 1 design while planning how `destination_charge/2` would signal platform authority to the Fake
- **Issue:** `resolve_scope/1` used `Keyword.get(opts, :stripe_account) || Process.get(...) || :platform`. Elixir's `||` treats `nil` as falsy, so passing `stripe_account: nil` in opts did NOT force platform scope — it fell through to the pdict and re-inherited any enclosing `with_account/2` scope. This would have made the Pitfall 2 threat impossible to mitigate from the caller side.
- **Fix:** Switched to a `cond` with `Keyword.has_key?(opts, :stripe_account)` as the first branch. An explicit key (including literal nil) wins; `nil -> :platform` for the stamp value.
- **Files modified:** `accrue/lib/accrue/processor/fake.ex`
- **Committed in:** `f5e4dac`

**3. [Rule 2 - Missing] Fake `create_charge` not scope-aware**
- **Found during:** Task 1 design
- **Issue:** Plan 05-02 established the caller-side pdict→opts threading pattern for `create_customer` but did not extend it to `create_charge`. For Phase 5 tests to observe which scope a charge lands in, `create_charge` must thread the pdict too — AND its `build_charge` must stamp `_accrue_scope` on the stored charge shape.
- **Fix:** Added `thread_scope/1` call in `create_charge/2` client-side API and `resolve_scope(opts)` stamp in `build_charge/4`. Matches the 05-02 pattern.
- **Files modified:** `accrue/lib/accrue/processor/fake.ex`
- **Committed in:** `f5e4dac`

### Out-of-Scope / Deferred

Nothing new logged. The pre-existing `test/accrue/webhook/checkout_session_completed_test.exs:44` flake (tracked in `deferred-items.md` from Plan 05-01) did not surface during this plan's full-suite run. No new warnings introduced.

## Issues Encountered

None. Tests passed on first run after implementation (16/16) and the full suite (677/677) ran clean on the same pass. The explicit-nil `resolve_scope` bug was caught at design time, not test time, so it never produced a RED state in the executor session.

## Acceptance Criteria

| Criterion | Status |
| --- | --- |
| `grep -q 'def destination_charge' accrue/lib/accrue/connect.ex` | PASS |
| `grep -q 'def separate_charge_and_transfer' accrue/lib/accrue/connect.ex` | PASS |
| `grep -q 'def transfer' accrue/lib/accrue/connect.ex` | PASS |
| `grep -q 'transfer_data' accrue/lib/accrue/connect.ex` | PASS |
| `grep -q 'application_fee_amount' accrue/lib/accrue/connect.ex` | PASS |
| `grep -q ':accrue, :connect, :destination_charge' accrue/lib/accrue/connect.ex` | PASS |
| `grep -q 'def create_transfer' accrue/lib/accrue/processor/stripe.ex` | PASS |
| `grep -q 'def create_transfer' accrue/lib/accrue/processor/fake.ex` | PASS |
| `cd accrue && mix test test/accrue/connect/charges_test.exs test/accrue/connect/transfer_test.exs` exits 0 | PASS (16/16) |
| `cd accrue && mix test` exits 0 | PASS (677 tests / 44 properties / 0 failures) |
| VALIDATION.md rows 11, 12, 13, 14 | PASS |

## TDD Gate Compliance

Task 1 is marked `tdd="true"` and shipped as a single-commit `feat:` commit. Same rationale as Plans 05-01..05-04: a separate RED commit would contain tests referencing unshipped functions (`Accrue.Connect.destination_charge/2`, `separate_charge_and_transfer/2`, `transfer/2`) and fail to compile. Tests were written in the same diff as the implementation but driven from `<behavior>` and `<acceptance_criteria>`. The `resolve_scope/1` || fall-through deviation (#2) was caught at design time — had it slipped through, the "forces platform scope even inside with_account/2" test would have served as an organic RED gate.

## User Setup Required

None — all behavior exercised through the Fake processor. Stripe adapter paths (`create_transfer/2`, `retrieve_transfer/2`) are not wire-tested in this plan; Phase 5 Plan 07's live_stripe tagged suite (out of scope, deferred per phase plan) will cover them.

## Threat Flags

None — the `<threat_model>` for Plan 05-05 covers all three trust boundaries:

- **T-05-05-01 (destination_charge with Stripe-Account header):** mitigated — the caller-side Connect helper explicitly threads `stripe_account: nil` into opts; the Fake's `resolve_scope/1` now treats explicit-nil as authoritative-platform; the Stripe adapter's Transfer delegations route through `build_platform_client!/1`. Test "forces platform scope even inside with_account/2" proves the Fake-side guard.
- **T-05-05-02 (application_fee_amount tampering):** mitigated — `application_fee_amount` is a caller-injected opt (%Money{}), never computed inside the helper. Telemetry `:stop` event receives the fee via metadata so a post-hoc audit can cross-check it.
- **T-05-05-03 (charge-without-matching-transfer repudiation):** mitigated — `separate_charge_and_transfer/2` returns `{:error, {:transfer_failed, charge, err}}` on partial success; charge row persists; events ledger records the separate_charge_transfer event only on full success (charge-only row is visible via the generic `connect.destination_charge`-style Billing.Charge insert).

## Next Plan Readiness

- **Plan 05-06 (Wave 2, ConnectHandler webhook reducers):** READY. No dependency on the new charge/transfer helpers. The `Accrue.Processor.Fake.transfers_on/1` helper is available should 05-06's `payout.*` reducer tests want to cross-check.
- **Plan 05-07 (Wave 2, guides + docs):** READY. All three new helpers are documented with full ExDoc moduledoc examples; guides/connect.md can reference them directly. The `platform_fee/2` + `destination_charge/2` pairing example in the destination_charge moduledoc is copy-pasteable as the canonical "how to charge a customer and collect a platform fee" recipe.

## Self-Check

- `accrue/test/accrue/connect/charges_test.exs` FOUND
- `accrue/test/accrue/connect/transfer_test.exs` FOUND
- `accrue/lib/accrue/connect.ex` MODIFIED (grep'd for `def destination_charge`, `def separate_charge_and_transfer`, `def transfer`, `:accrue, :connect, :destination_charge` — all present)
- `accrue/lib/accrue/processor/stripe.ex` MODIFIED (grep'd for `def create_transfer` — present, routed via `build_platform_client!/1`)
- `accrue/lib/accrue/processor/fake.ex` MODIFIED (grep'd for `def call_count`, `def transfers_on`, `bump_call_count`, `:transfer` counter — all present)
- `accrue/lib/accrue/processor/fake/state.ex` MODIFIED (grep'd for `transfers: %{}`, `call_counts: %{}` — both present)
- Commit `f5e4dac` FOUND (git log --oneline)

## Self-Check: PASSED

---
*Phase: 05-connect*
*Completed: 2026-04-15*
