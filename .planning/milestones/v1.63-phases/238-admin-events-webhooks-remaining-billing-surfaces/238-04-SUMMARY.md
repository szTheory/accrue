---
phase: 238-admin-events-webhooks-remaining-billing-surfaces
plan: 04
subsystem: billing
tags: [connect, stripe, phoenix-liveview, exunit]
requires:
  - phase: 238-admin-events-webhooks-remaining-billing-surfaces
    provides: existing owner-scoped Connect projections and local fee override flow
provides:
  - Connect list labels and renders Stripe-observed capability facts separately from local fee overrides
  - Connect detail identifies missing provider snapshot facts as unknown and preserves the provider snapshot on local override save
affects: [238-05, connect-admin]
actuals:
  tokens: 3834
  tasks: 2
  commits: 4
plan_head_before: 37ade835063349bb8fc714c0faaaf2b7444d5a44
plan_head_after: f554ff12e02ad30c5c0903a7b4bdb429fa13ffe5
tech-stack:
  added: []
  patterns:
    - Read the raw Connect provider snapshot as the source for displayed Stripe observations.
    - Re-resolve list facts by exact account ID under the active owner scope.
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
    - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
    - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
key-decisions:
  - "Treat the raw provider fields in Account.data as observed evidence; false database defaults alone do not establish a Stripe observation."
  - "Keep the platform fee override a local account setting and preserve provider snapshot fields during its save."
requirements-completed: [ADM-08]
coverage:
  - id: D1
    description: Connect account lists distinguish Stripe-observed capabilities, unavailable observations, local override state, owner-scoped links, and stable equal-timestamp order.
    requirement: ADM-08
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Connect account details separate provider readiness from the local fee override and preserve provider facts through same-value local saves.
    requirement: ADM-08
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 8min
  completed: 2026-10-09
  commits: 4
  plan_head_before: 37ade835063349bb8fc714c0faaaf2b7444d5a44
  plan_head_after: f554ff12e02ad30c5c0903a7b4bdb429fa13ffe5
status: complete
---

# Phase 238 Plan 04: Connect Facts Summary

**Connect list and detail views now label Stripe-observed account capabilities separately from the local platform fee override, with missing raw observations shown as unknown or unavailable.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-10-09T03:49:00Z
- **Completed:** 2026-10-09T03:57:02Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- The Connect account list explicitly labels provider readiness and local fee override as separate columns and card fields.
- Missing raw Stripe capability fields render as unavailable/unknown instead of deriving readiness from false database defaults.
- Detail saves retain the exact owner-scoped account lookup, fresh StepUp, local persistence, and audit; same-value save coverage verifies provider snapshot fields remain intact.
- Added deterministic coverage for owner-scoped detail links, stable ID tie-breaking, and rejected StepUp leaving local state unchanged.

## Task Commits

1. **Task 1: Separate observed Stripe readiness from local fee policy in account inspection** - `8f81edf1` (test), `d0d46406` (feat)
2. **Task 2: Keep fee-override save local and current under refresh or repeated submission** - `54a03d9d` (test), `f554ff12` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex` - Renders owner-scoped provider observations and the independent local override.
- `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` - Labels provider readiness and local policy separately; maps absent snapshot facts to unknown.
- `accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs` - Covers unavailable observations, local override copy, exact scoped links, and stable ordering.
- `accrue_admin/test/accrue_admin/live/connect_account_live_test.exs` - Covers fact preservation, same-value local save, and rejected StepUp.

## Decisions Made

- The raw provider snapshot in `Account.data` is the evidence source for displayed Stripe facts. The database's false defaults do not establish that Stripe reported a disabled capability.
- The local override remains in `Account.data["platform_fee_override"]`, independent of the provider snapshot fields.

## Phase 238 Closeout Scope Disposition (2026-10-09)

The current Connect projection has no provider-observation timestamp and no provider refresh operation or failed-refresh marker. Its UI identifies values as the "Last stored Stripe snapshot" and explicitly says that freshness is not tracked. Closeout verification found that the original plan's stale/failed-refresh truth asked for information the phase neither stores nor fetches.

The phase contract is aligned to the existing bounded capability: missing provider facts remain unknown/unavailable; present facts remain clearly labeled as last stored with freshness disclosed as untracked; the local platform-fee override remains independent. No schema, Stripe API call, refresh action, or current-freshness claim is introduced. Freshness timestamps and refresh-failure states are deferred to a separately scoped future change. The existing ExUnit assertion for the exact freshness disclosure and the Phase 238 served browser assertions remain the automated evidence.

## Issues Encountered

- The account projection has no provider-observation timestamp or refresh-failure marker. Missing raw capability evidence is now unavailable/unknown, but the current model cannot independently identify a present snapshot as stale or record a failed refresh. This implementation does not add schema or query-layer scope beyond Plan 238-04.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/connect_accounts_live_test.exs` - passed (9 tests, 0 failures).
- `cd accrue_admin && mix test test/accrue_admin/live/connect_account_live_test.exs` - passed (7 tests, 0 failures).

## Next Phase Readiness

Connect list/detail semantics and regression coverage are ready for Plan 238-05 browser coverage. Browser verification remains in that plan.

---
*Phase: 238-admin-events-webhooks-remaining-billing-surfaces*
*Completed: 2026-10-09*

## Self-Check: PASSED

- Summary file exists.
- All four task commits are ancestors of the current HEAD.
- The measured plan task commit count is 4.
