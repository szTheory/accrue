---
phase: 129-customer-operator-surfaces-observability
plan: 01
subsystem: observability
tags: [telemetry, event-ledger, dunning, oban, ecto-multi, drift-gate]

# Dependency graph
requires:
  - phase: 128-campaign-engine-foundation
    provides: "dunning campaign engine — first-transition elector (D-09), DunningStep worker (D-10/D-11/D-16), cancel-on-recovery finalize (D-12), pre-marked scope fences for the Phase-129 emit sites"
provides:
  - "dunning.campaign_started ledger event + [:accrue, :ops, :dunning_campaign_started] telemetry on the first nil→past_due edge"
  - "dunning.step_sent ledger event + [:accrue, :ops, :dunning_step_sent] telemetry per delivered step"
  - "dunning.recovered ledger event + [:accrue, :ops, :dunning_recovered] telemetry on recovery (folded into the anchor-clear multi)"
  - "dunning.exhausted ledger event + [:accrue, :ops, :dunning_exhausted] telemetry — the SOLE canonical recovered-vs-lost loss signal"
  - "all four registered across the enforced drift-gate triad (inventory + metrics + guide catalog/runbook)"
affects: [129-02-recovered-vs-lost-counter, dunning-observability, operator-surfaces]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Lifecycle observability = paired dotted accrue_events ledger entry + [:accrue, :ops, :*] telemetry at one site"
    - "In-transaction ledger via Events.record_multi/3 folded into the same Ecto.Multi as the state write (recovery); post-write Events.record/1 for standalone update_all paths (campaign_started, step_sent)"
    - "Drift-gate triad lockstep: any new ops event lands in inventory + metrics counter (tags matching metadata) + guide catalog & runbook in one change"

key-files:
  created: []
  modified:
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/lib/accrue/workers/dunning_step.ex
    - accrue/test/support/telemetry_ops_inventory.ex
    - accrue/lib/accrue/telemetry/metrics.ex
    - accrue/guides/telemetry.md
    - accrue/test/accrue/webhook/dunning_campaign_start_test.exs
    - accrue/test/accrue/webhook/dunning_campaign_keying_test.exs
    - accrue/test/accrue/webhook/dunning_exhaustion_test.exs
    - accrue/test/accrue/workers/dunning_step_test.exs

key-decisions:
  - "D-01 honored: emit under the shipped+enforced [:accrue, :ops, :dunning_*] idiom (NOT DUN-08's literal [:accrue, :dunning, *]) so the events go through the drift gate rather than forking the contract."
  - "Recovery ledger write folded into the SAME multi as the anchor-clear (converted the bare Repo.update to Repo.transaction(Ecto.Multi)) so dunning.recovered is atomic with the status write."
  - "dunning.exhausted ledger+telemetry emitted beside the existing dunning_exhaustion telemetry inside the enclosing Repo.transact; the sweeper's request-time dunning.terminal_action_requested is left untouched (T-129-04 — loss can never be double-counted)."
  - "campaign_started carries NO :source key and declares NO metrics tags; step_sent declares NO tags (never tag high-cardinality subscription_id) — T-129-02 cardinality guard."

patterns-established:
  - "Paired ledger+telemetry lifecycle emit at the Phase-128 scope-fence sites"
  - "Recovery edge vs terminal edge split: dunning.recovered only when Subscription.active?/1; dunning.exhausted only when dunning_exhausted_status/1 is non-nil"

requirements-completed: [DUN-08]

# Metrics
duration: 8min
completed: 2026-05-25
---

# Phase 129 Plan 01: Dunning Lifecycle Observability Summary

**Four dunning lifecycle events (campaign_started / step_sent / recovered / exhausted) now emit as paired `accrue_events` ledger entries AND `[:accrue, :ops, :dunning_*]` telemetry, registered across the enforced inventory+metrics+guide drift-gate triad.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-25T06:08:05Z
- **Completed:** 2026-05-25T06:16:00Z
- **Tasks:** 2 (Task 1 was TDD: RED → GREEN)
- **Files modified:** 9

## Accomplishments
- Four lifecycle events emit BOTH a dotted ledger entry and an `[:accrue, :ops, :dunning_*]` telemetry event from `lib/` (DUN-08 SC#3, with the conscious `:ops`-namespace deviation per D-01).
- `dunning.recovered` folded into the recovery anchor-clear via `Ecto.Multi`/`Events.record_multi/3` — atomic with the status write.
- `dunning.exhausted` established as the sole canonical loss signal beside the existing `dunning_exhaustion` telemetry; the sweeper's request-time `dunning.terminal_action_requested` is untouched (Plan 02's recovered-vs-lost fold can't double-count).
- All four registered in lockstep across the drift-gate triad — inventory list, metrics counters (tags matching metadata), and guide catalog + operator-runbook rows.

## Task Commits

1. **Task 1 (RED): failing tests for four lifecycle events** - `ae81d2bf` (test)
2. **Task 1 (GREEN): emit four dunning lifecycle events** - `683e862e` (feat)
3. **Task 2: register four events across the drift-gate triad** - `ddadb334` (feat)

_Note: Task 1 was TDD — RED commit (`ae81d2bf`) then GREEN commit (`683e862e`); no separate refactor was needed._

## Files Created/Modified
- `accrue/lib/accrue/webhook/default_handler.ex` - emit `dunning.campaign_started` (post-write, in `enqueue_day_zero_step`), `dunning.recovered` (in-multi anchor-clear), `dunning.exhausted` (in-transaction beside the exhaustion telemetry)
- `accrue/lib/accrue/workers/dunning_step.ex` - emit `dunning.step_sent` after `Mailer.deliver/2` returns in `deliver_step/4`; updated scope-fence moduledoc
- `accrue/test/support/telemetry_ops_inventory.ex` - appended all four to `expected_ops_events/0`
- `accrue/lib/accrue/telemetry/metrics.ex` - four counters (source-tagged for recovered/exhausted, untagged for campaign_started/step_sent)
- `accrue/guides/telemetry.md` - catalog + operator-runbook rows for all four
- `accrue/test/accrue/webhook/dunning_campaign_start_test.exs` - `dunning.campaign_started` ledger+telemetry assertions (+ no-second-start)
- `accrue/test/accrue/webhook/dunning_campaign_keying_test.exs` - `dunning.recovered` ledger+telemetry assertions (+ no-emit-without-anchor)
- `accrue/test/accrue/webhook/dunning_exhaustion_test.exs` - `dunning.exhausted` ledger+telemetry assertions (+ no-emit on non-dunning transition)
- `accrue/test/accrue/workers/dunning_step_test.exs` - `dunning.step_sent` ledger+telemetry assertions (step_index 0 and 1)

## Decisions Made
- **D-01 namespace honored:** events emit under `[:accrue, :ops, :dunning_*]` (the shipped+enforced idiom), not DUN-08's literal `[:accrue, :dunning, *]` — keeps the events inside the drift gate.
- **Recovery atomicity:** converted the recovery anchor-clear from a bare `Repo.update/2` to `Repo.transaction(Ecto.Multi)` so the `dunning.recovered` ledger record commits atomically with the anchor-clear/status write. The bare-update behavior (post-commit cancel stash, error propagation) is preserved.
- **Exhausted = sole loss signal:** emitted at the confirmed `:past_due`→`:unpaid`/`:canceled` transition (`maybe_emit_dunning_exhaustion/2`) covering all loss sources; the sweeper's request-time event is left alone.

## Deviations from Plan

None - plan executed exactly as written. The plan offered "record_multi/3 or record/1 if no multi is threaded" latitude at the exhausted site; chose `Events.record/1` (no multi is threaded at that exact site, and it runs inside the enclosing `Repo.transact`, so it is already atomic with the status write).

## Issues Encountered
None. RED produced the expected 6 failures; GREEN passed all 35 tests in the four files; the drift-gate triad and full `accrue` suite (1563 tests, 0 failures, `--seed 0`) are green. Credo `--strict` clean on the modified lib files. The benign `telemetry:attach` "local function handler" info logs in tests mirror the pre-existing `dunning_exhaustion` test pattern.

## Threat Surface
- **T-129-01 (Info Disclosure):** verified — ledger data + telemetry metadata carry only IDs + bounded enums (`subscription_id`, `step_key`, `step_index`, `step_count`, `to_status`, `source`). No email, card data, or amounts.
- **T-129-02 (DoS / cardinality):** `campaign_started`/`step_sent` declare NO metrics tags; `recovered`/`exhausted` tag only the 3-value `:source` enum.
- **T-129-03 (Tampering):** all ledger writes go through `Events.record/1` / `record_multi/3` (the append-only path), never `Repo.insert(%Event{})`.
- **T-129-04 (double-count):** sweeper's `dunning.terminal_action_requested` left untouched (grep-confirmed unchanged at 2 occurrences); `dunning.exhausted` is the only loss signal.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Plan 02 (recovered-vs-lost counter) can now fold over the `dunning.recovered` and `dunning.exhausted` ledger entries as its substrate.
- DUN-06 (portal banner) and DUN-07 (admin dunning state) remain for later Phase-129 plans.

---
*Phase: 129-customer-operator-surfaces-observability*
*Completed: 2026-05-25*

## Self-Check: PASSED

All modified files exist on disk; all three task commits (`ae81d2bf`, `683e862e`, `ddadb334`) exist in git history.
