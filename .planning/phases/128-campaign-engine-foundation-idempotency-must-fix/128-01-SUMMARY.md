---
phase: 128-campaign-engine-foundation-idempotency-must-fix
plan: 01
subsystem: config
tags: [dunning, campaign, nimble_options, config, boot-validation, oban-precursor]

# Dependency graph
requires:
  - phase: 123-config-core-gate-api-foundation
    provides: "NimbleOptions @schema + validate_at_boot!/0 + maybe_validate_boot_setup!/1 + Accrue.ConfigError cross-field boot-raise precedent (validate_entitlements_price_ids!/1)"
provides:
  - "Accrue.Config.dunning_campaign/0, dunning_campaign_enabled?/0, dunning_campaign_steps/0 accessors (consumed by the campaign worker, pure resolver, and webhook REPLACE gate in Plans 03/05/06)"
  - "Nested :dunning.campaign schema entry with {:custom} intra-list validator + cross-field boot grace raise"
  - "@default_dunning_steps default journey (offsets [0,5,12], keys :reminder/:action_required/:final_notice, on by default)"
affects: [dunning-campaign-worker, dunning-pure-resolver, webhook-default-handler-replace-gate, plan-128-03, plan-128-05, plan-128-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-layer config validation: per-field {:custom} intra-list validator + sibling cross-field boot raise (cloned from validate_entitlements_price_ids! precedent)"
    - "Module attrs (@step_schema, @default_dunning_steps) declared BEFORE @schema so the schema default can reference them"
    - "Namespaced raw-read-own-default accessors (dunning_campaign*) cloning the dunning/0 + past_due_grace/0 shape"

key-files:
  created:
    - accrue/test/accrue/config_dunning_campaign_test.exs
  modified:
    - accrue/lib/accrue/config.ex

key-decisions:
  - "campaign: false normalizes to [enabled: false, steps: []] at three read sites (the {:custom} validator AND the raw-read accessor AND the boot grace validator), because validate_at_boot!/0 passes UN-normalized opts to maybe_validate_boot_setup!/1"
  - "template typed as :atom (not {:in, ...}) since module names ARE atoms and the value is host-trusted compile-time config (threat T-128-02 = accept)"
  - "Property generator builds strictly-increasing offsets by cumulative-summing positive deltas so the invariant holds by construction; the negative property reverses a >=2-step list to guarantee a real ordering violation"

patterns-established:
  - "Cross-field config invariants that NimbleOptions {:custom} cannot express (sibling-key reads) live as a *!/1 boot raise wired into maybe_validate_boot_setup!/1, never as a {:custom} validator"
  - "Opt-out shorthand (campaign: false) is normalized defensively at every read site that may see raw env, not just the validated copy"

requirements-completed: [DUN-01]

# Metrics
duration: 3min
completed: 2026-05-24
---

# Phase 128 Plan 01: Campaign Config Foundation Summary

**Config-driven, NimbleOptions-validated multi-step dunning cadence under `:dunning.campaign`, shipped ON by default (offsets [0,5,12]) with two-layer validation (intra-list `{:custom}` + cross-field boot raise) and three namespaced accessors for downstream consumers.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-24T17:40:43Z
- **Completed:** 2026-05-24T17:43:41Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments
- Added `@step_schema` (per-step NimbleOptions schema) and `@default_dunning_steps` (the D-01 `[0,5,12]` journey with `:reminder`/`:action_required`/`:final_notice` keys and the three email-module templates), declared before `@schema`.
- Extended the existing `:dunning` schema entry with an explicit `:keys` list (typing `mode`/`grace_days`/`terminal_action`/`telemetry_prefix`) plus a nested `campaign:` `{:custom}` sub-key defaulting to `[enabled: true, steps: @default_dunning_steps]` — opt-out, not opt-in.
- Implemented the public intra-list validator `validate_dunning_campaign/1`: normalizes `campaign: false` → `[enabled: false, steps: []]`, validates each step against `@step_schema`, enforces strictly-increasing + unique `after_days`, unique `key`, and a LOUD error on `steps: []` while enabled.
- Implemented the private cross-field boot validator `validate_dunning_campaign_grace!/1` (raises `Accrue.ConfigError` when `last_step.after_days > grace_days`), wired into `maybe_validate_boot_setup!/1` immediately after `validate_entitlements_price_ids!/1`.
- Added the three downstream accessors `dunning_campaign/0`, `dunning_campaign_enabled?/0`, `dunning_campaign_steps/0`.
- Added a dedicated test file (18 tests + 2 stream_data properties) proving every DUN-01 behavior, all green at `--seed 0`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add campaign schema, attrs, validators, and accessors to Accrue.Config** — `3a7fb82` (feat)
2. **Task 2: Wave-0 config validation tests (DUN-01)** — `35361d8` (test, includes a Rule 1 fix to `config.ex`)

_Plan metadata commit follows this SUMMARY._

## Files Created/Modified
- `accrue/lib/accrue/config.ex` — Added `@step_schema` + `@default_dunning_steps` module attrs; extended `:dunning` schema with `:keys` + nested `campaign:` `{:custom}` entry; added `validate_dunning_campaign/1` (+ private step helpers + `strictly_increasing?/1`); added `validate_dunning_campaign_grace!/1` + boot wiring; added `dunning_campaign/0` + `dunning_campaign_enabled?/0` + `dunning_campaign_steps/0`.
- `accrue/test/accrue/config_dunning_campaign_test.exs` — New `async: false` test (env save/restore for `:dunning`) covering the intra-list validator, default-journey accessors, cross-field boot raise, and strictly-increasing/unique property invariants.

## Decisions Made
- **`campaign: false` normalized at three read sites.** `validate_at_boot!/0` discards the NimbleOptions-normalized output and passes the *raw* opts to `maybe_validate_boot_setup!/1`, so the boot grace validator (and the raw-read accessor) must treat the `false` opt-out shorthand themselves — they cannot rely on the `{:custom}` validator's normalization.
- **`template` is `:atom`, not `{:in, [...]}`.** Module names are atoms; the value is host-supplied trusted config, so there's no atom-table exhaustion surface (threat T-128-02 disposition = accept). Plan's `<interfaces>` and PATTERNS.md both prescribe `:atom`.
- **Property generators construct invariants by design.** The valid generator cumulative-sums positive deltas (always strictly increasing + unique); the negative property reverses a `>=2`-step strictly-increasing list, guaranteeing a genuine ordering violation rather than a flaky equal-pair.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `campaign: false` opt-out crashed `validate_dunning_campaign_grace!/1` and `dunning_campaign/0`**
- **Found during:** Task 2 (running the new test suite — the "grace guard does not fire when the campaign is disabled" test failed with `FunctionClauseError` in `Keyword.get/3`).
- **Issue:** `validate_at_boot!/0` passes UN-normalized opts to `maybe_validate_boot_setup!/1`, so the boot grace validator received the literal `campaign: false` and called `Keyword.get(false, :enabled, false)`, which raises. The `dunning_campaign/0` accessor had the same latent crash for a host that sets `campaign: false`.
- **Fix:** `validate_dunning_campaign_grace!/1` now coerces a raw `false` campaign to `[enabled: false, steps: []]` before reading keys (with an explanatory comment on why boot sees the raw shape). `dunning_campaign/0` now matches `false` and returns the normalized keyword shape so the predicate/steps accessors always operate on a keyword list.
- **Files modified:** `accrue/lib/accrue/config.ex`
- **Verification:** Full test file green (18 tests + 2 properties, 0 failures) at `--seed 0`; `config_test.exs` + `config_entitlements_test.exs` still green (65 tests, 0 failures); `mix compile --warnings-as-errors` exits 0.
- **Committed in:** `35361d8` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The fix is required for correctness — it makes the documented `campaign: false` opt-out actually work at boot and via the accessors. No scope creep; the normalization mirrors exactly what the `{:custom}` validator already does.

## Issues Encountered
None beyond the Rule 1 fix above. The email-module atoms referenced in `@default_dunning_steps` (`Accrue.Emails.DunningActionRequired`, `Accrue.Emails.DunningFinalNotice`, created in later Plan 128 tasks) do not trigger undefined-function warnings because they are bare atoms in a module attribute, never invoked here — `--warnings-as-errors` is clean without any `@compile {:no_warn_undefined}` guard.

## Known Stubs
None — the two as-yet-uncreated email modules appear only as atom values in the default journey (resolved by later Plan 128 tasks per the phase plan); they are not stub data flowing to a UI and do not block DUN-01's goal (config validation + accessors).

## Scope Fence
No ledger events, no telemetry, and no `Accrue.Dunning.Engine` behaviour introduced (Phases 129/131 — explicitly out of scope per the plan and config.json `discuss_default_dunning_phase_boundary`).

## Next Phase Readiness
- `Accrue.Config.dunning_campaign_steps/0` and `dunning_campaign_enabled?/0` are available for the Plan 03 pure resolver, the Plan 05 campaign worker, and the Plan 06 webhook REPLACE gate.
- The default journey validates clean at boot (12 <= 14), and an invalid cadence raises loud at boot — the boot-safety foundation (T-128-01) is in place.
- No blockers.

## Self-Check: PASSED

- FOUND: `accrue/test/accrue/config_dunning_campaign_test.exs`
- FOUND: `.planning/phases/128-campaign-engine-foundation-idempotency-must-fix/128-01-SUMMARY.md`
- FOUND commit: `3a7fb82` (Task 1)
- FOUND commit: `35361d8` (Task 2)

---
*Phase: 128-campaign-engine-foundation-idempotency-must-fix*
*Completed: 2026-05-24*
