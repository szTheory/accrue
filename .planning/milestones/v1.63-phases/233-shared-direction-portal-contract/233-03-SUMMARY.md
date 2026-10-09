---
phase: 233-shared-direction-portal-contract
plan: 03
subsystem: auth
tags: [phoenix-liveview, portal, authorization, context-pins]
requires:
  - phase: 233-01
    provides: Optional actor and billable resolution contract with blocked recovery.
  - phase: 233-02
    provides: Signed context pins for Portal forms and payment-method operations.
provides:
  - Fresh authorization for Home, subscription, and invoice LiveViews.
  - Pinned navigation and target-scoped subscription actions across account switches.
affects: [233-05, 233-07, portal-adoption]
actuals:
  tokens: 11890
  tasks: 2
  commits: 4
plan_head_before: 544bddd9167f234d73d30e68c050f1a35a371a30
plan_head_after: 18bbe9ce5c332f977733a11746f4f7fa43ac5557
tech-stack:
  added: []
  patterns: [fresh-context authorization, server-loaded target authorization, signed navigation pins]
key-files:
  created:
    - accrue_portal/test/accrue_portal/context_live_test.exs
    - .planning/phases/233-shared-direction-portal-contract/233-03-T1-RED.json
    - .planning/phases/233-shared-direction-portal-contract/233-03-T2-RED.json
  modified:
    - accrue_portal/lib/accrue_portal/auth_hook.ex
    - accrue_portal/lib/accrue_portal/authorize.ex
    - accrue_portal/lib/accrue_portal/context.ex
    - accrue_portal/lib/accrue_portal/layouts.ex
    - accrue_portal/lib/accrue_portal/path.ex
    - accrue_portal/lib/accrue_portal/live/home_live.ex
    - accrue_portal/lib/accrue_portal/live/subscriptions_live.ex
    - accrue_portal/lib/accrue_portal/live/subscription_live.ex
    - accrue_portal/lib/accrue_portal/live/invoices_live.ex
key-decisions:
  - "Resolve a signed context pin again for each protected LiveView action and authorize the server-loaded target before mutation."
  - "Add a pin to custom-host LiveView navigation on initial selection while leaving personal-only compatibility intact."
patterns-established:
  - "Portal event payloads identify a requested target only; fresh customer-scoped reads and current host policy determine authority."
  - "Run subscription changes with the authenticated human actor in Accrue.Actor scope."
requirements-completed: [POR-08, SAFE-02, SAFE-03]
coverage:
  - id: D1
    description: Home and subscription pages display and navigate within the selected billable context.
    requirement: POR-08
    verification:
      - kind: integration
        ref: accrue_portal/test/accrue_portal/context_live_test.exs#home and subscription routes keep the selected billed identity and signed navigation pin
        status: pass
    human_judgment: false
  - id: D2
    description: Subscription cancel, preview, and change events freshly authorize the server-loaded target and clear stale confirmation or preview state on revocation.
    requirement: SAFE-02
    verification:
      - kind: integration
        ref: accrue_portal/test/accrue_portal/context_live_test.exs#revoked subscription cancellation clears confirmation and performs no provider mutation
        status: pass
      - kind: integration
        ref: accrue_portal/test/accrue_portal/context_live_test.exs#a forged foreign subscription event cannot mutate another customer's subscription
        status: pass
      - kind: integration
        ref: accrue_portal/test/accrue_portal/context_live_test.exs#an authorized subscription cancellation records the signed-in human actor
        status: pass
    human_judgment: false
  - id: D3
    description: Invoice navigation and reconnect retain the selected billable and block safely after policy revocation.
    requirement: SAFE-03
    verification:
      - kind: integration
        ref: accrue_portal/test/accrue_portal/context_live_test.exs#invoices are loaded for the selected organization and a revoked pinned reconnect is blocked
        status: pass
      - kind: integration
        ref: accrue_portal/test/accrue_portal/context_live_test.exs#an invoice route pins its initial selection into the browser URL for reconnect
        status: pass
    human_judgment: false
  - id: D4
    description: Personal Portal context remains compatible while the signed reference is carried through initial custom-host navigation.
    requirement: POR-08
    verification:
      - kind: integration
        ref: accrue_portal/test/accrue_portal/context_contract_test.exs
        status: pass
      - kind: integration
        ref: accrue_portal/test/accrue_portal/live/subscription_live_test.exs
        status: pass
    human_judgment: false
duration: 13min
completed: 2026-10-07
status: complete
---

# Phase 233 Plan 03: Shared Direction & Portal Contract Summary

**Home, subscription, and invoice LiveViews retain a signed billable context and reauthorize each protected read and subscription event.**

## Performance

- **Duration:** 13 minutes
- **Started:** 2026-10-07T20:54:08Z
- **Completed:** 2026-10-07T21:07:25Z
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments

- Added context-aware authorization that re-resolves the signed reference and reads subscription targets through the customer-scoped billing read model before host authorization.
- Kept Home, subscription list/detail, and invoice navigation bound to the displayed billable through initial URL pinning, links, and reconnect.
- Cleared stale cancellation confirmation and plan preview on policy invalidation, announced the blocked outcome, prevented provider calls for denied and forged targets, and attributed successful actions to the signed-in actor.

## Task Commits

1. **Task 1: Bind dashboard and subscription reads, links and actions** - `aa32b0b4` (test), `08f53e27` (feat)
2. **Task 2: Bind invoice navigation and reconnect to the same identity** - `1bc5fcf5` (test), `18bbe9ce` (feat)

**Plan metadata:** `2c11d4b2` (docs: complete plan)

## Files Created/Modified

- `accrue_portal/lib/accrue_portal/auth_hook.ex` - Adds the custom-host context pin to initial protected navigation while preserving old tab references.
- `accrue_portal/lib/accrue_portal/authorize.ex` - Re-resolves and authorizes the current context and customer-scoped subscription target.
- `accrue_portal/lib/accrue_portal/context.ex` - Adds named subscription action authorization and supports pin-based adapter re-resolution.
- `accrue_portal/lib/accrue_portal/layouts.ex` and `path.ex` - Carry the signed context in navigation and present LiveView notices.
- `accrue_portal/lib/accrue_portal/live/` - Applies pinned navigation and fresh authorization to Home, subscriptions, subscription detail, and invoices.
- `accrue_portal/test/accrue_portal/context_live_test.exs` - Exercises rendered routes, revocation, forged targets, reconnect, no-mutation, and actor attribution.
- `accrue_portal/test/accrue_portal/context_contract_test.exs` and subscription LiveView tests - Keeps adapter and existing page expectations aligned with initial pin navigation.
- `.planning/phases/233-shared-direction-portal-contract/233-03-T*-RED.json` - Preserves classified RED evidence for both TDD tasks.

## Decisions Made

- Each protected subscription event re-resolves the signed pin, loads the target from the currently authorized Customer, then checks the named host action.
- Custom adapter contexts receive an initial URL pin before continuing; personal-only behavior remains on its existing path.
- Human actor attribution stays separate from the billed entity and is scoped around subscription mutations.

## TDD Gate Compliance

- **T1 RED:** `233-03-T1-RED.json` records the target revocation assertion failing because cancellation confirmation remained visible without fresh event authorization.
- **T1 GREEN:** Commit `08f53e27`; focused LiveView coverage passed after authorization and state invalidation were implemented.
- **T2 RED:** `233-03-T2-RED.json` records the invoice URL pin assertion failing because the initial URL lacked a context pin.
- **T2 GREEN:** Commit `18bbe9ce`; focused coverage and the full Portal regression passed after pin propagation and reconnect authorization were added.
- **Refactor/verification:** `mix compile --warnings-as-errors`, `mix format --check-formatted`, `node --check priv/static/accrue_portal.js`, and `git diff --check` passed. Full Portal suite: 58 tests, 0 failures.

## Deviations from Plan

None. Navigation helpers, layout notices, and adapter fixture adjustments were necessary to implement and test the listed signed-navigation and accessible invalidation behavior.

## Issues Encountered

The first full warnings-as-errors test run found a test fixture warning caused by placing a helper between clauses of `resolve/2`. The helper was moved below those clauses; the full suite then passed with 58 tests and no failures. The roadmap progress helper could not update the repository's phase row, so the 233-03 checklist and 5/7 count were updated directly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 233-07 can use the same pin and fresh authorization contract for checkout completion. Plan 233-05 can document the tested custom-host and personal compatibility paths.

---
*Phase: 233-shared-direction-portal-contract*
*Completed: 2026-10-07*

## Self-Check: PASSED

- Summary file exists and parses with four fully covered automated deliverables.
- All four task commits are ancestors of the current plan head.
- Measured task commit count is 4 (`544bddd9167f234d73d30e68c050f1a35a371a30..18bbe9ce5c332f977733a11746f4f7fa43ac5557`).
