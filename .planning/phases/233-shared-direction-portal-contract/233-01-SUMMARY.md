---
phase: 233-shared-direction-portal-contract
plan: 01
subsystem: auth
tags: [phoenix-liveview, portal, billing, authorization, ecto]
requires:
  - phase: 233-04
    provides: Shared design direction and the existing Portal presentation baseline
provides:
  - Optional host adapter for resolving and authorizing a distinct Portal billable context
  - Exact custom Customer resolution by owner type, lossless owner ID, and configured processor
  - Generic authenticated blocked recovery route separated from unauthenticated login
affects: [233-02, 233-03, 233-05, 233-06, 233-07, 234, 235, 236]
actuals:
  tokens: 10608
  tasks: 2
  commits: 5
commits: 5
plan_head_before: b0d94fa1682bcc9115fac6cf9f31b65b669a6649
plan_head_after: d84faaf727a146742417c7dae51109a3bf9573c2
tech-stack:
  added: []
  patterns:
    - Host adapters resolve a server-side billable and authorize named actions before Customer provisioning
    - Personal Customer selection preserves one existing processor row and fails closed on ambiguity
key-files:
  created:
    - accrue_portal/lib/accrue_portal/context.ex
    - accrue_portal/lib/accrue_portal/live/blocked_live.ex
    - accrue_portal/test/accrue_portal/context_contract_test.exs
    - accrue_portal/test/support/tap_formatter.ex
  modified:
    - accrue_portal/lib/accrue_portal/auth_hook.ex
    - accrue_portal/lib/accrue_portal/auth_plug.ex
    - accrue_portal/lib/accrue_portal/customer_session.ex
    - accrue_portal/lib/accrue_portal/layouts.ex
    - accrue_portal/lib/accrue_portal/router.ex
    - accrue_portal/test/accrue_portal/auth_hook_test.exs
    - accrue_portal/test/accrue_portal/router_test.exs
key-decisions:
  - "The host adapter resolves the actor separately from the billed entity and authorizes :read before any custom Customer lookup or creation."
  - "Custom Customer identity uses owner type, lossless owner ID, and the configured processor; personal installs retain one existing owner Customer and block when that identity is ambiguous."
  - "Authenticated resolution failures go to an auth-only blocked page; only missing authentication goes to the configured local login path."
patterns-established:
  - "A LiveView mount resolves and authorizes context on each mount instead of treating previous assigns as authority."
  - "A blocked recovery route renders generic copy and does not expose the failed selection."
requirements-completed: [POR-08, SAFE-02]
coverage:
  - id: D1
    description: "A selected host billable reaches real HomeLive data through the exact owner type, owner ID, and configured processor Customer while the actor remains distinct."
    requirement: POR-08
    verification:
      - kind: integration
        ref: "accrue_portal/test/accrue_portal/context_contract_test.exs#selected host billable renders HomeLive data for its exact Customer"
        status: pass
      - kind: integration
        ref: "accrue_portal/test/accrue_portal/context_contract_test.exs#a different processor Customer with matching owner does not supply HomeLive data"
        status: pass
    human_judgment: false
  - id: D2
    description: "Authenticated denied, unavailable, and unselected custom contexts reach generic recovery without provisioning, while unauthenticated visitors retain the local login path."
    requirement: SAFE-02
    verification:
      - kind: integration
        ref: "accrue_portal/test/accrue_portal/context_contract_test.exs#authenticated unavailable selection renders a generic blocked page without provisioning"
        status: pass
      - kind: integration
        ref: "accrue_portal/test/accrue_portal/context_contract_test.exs#authenticated unavailable HTTP action blocks before provisioning"
        status: pass
      - kind: unit
        ref: "accrue_portal/test/accrue_portal/auth_hook_test.exs#authenticated denied context goes to the non-login blocked destination"
        status: pass
      - kind: unit
        ref: "accrue_portal/test/accrue_portal/auth_hook_test.exs#a repeated mount re-resolves and reauthorizes a previously allowed context"
        status: pass
    human_judgment: false
metrics:
  duration: 26min
  completed: 2026-10-07
status: complete
---

# Phase 233 Plan 01: Shared Direction & Portal Contract Summary

**Optional host policy now resolves a distinct billed entity through Portal, binds its Customer to the exact owner and processor identity, and gives authenticated denials a safe blocked recovery page.**

## Performance

- **Duration:** 26 min
- **Started:** 2026-10-07T19:12:39Z
- **Completed:** 2026-10-07T19:38:32Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added `Accrue.Portal.Context` and the optional `:context_adapter` contract for server-side billable resolution and closed named-action authorization.
- Routed custom contexts through exact Customer lookup and authorized provisioning, while preserving personal-only installs and disambiguating existing processor rows.
- Added a dedicated authenticated blocked route, escaped billable identity in the Portal shell, safe local login validation, and HTTP/LiveView denial coverage.

## Task Commits

1. **Task 1 RED:** `4fc801ff` (`test(233-01): add failing coverage for selected billable context`)
2. **Task 1 GREEN:** `329d63e5` (`feat(233-01): resolve selected billable Portal context`)
3. **Task 2 RED:** `7f21bf9f` (`test(233-01): add failing denial recovery assertions`)
4. **Task 2 GREEN:** `d07ffc0c` (`feat(233-01): block denied billable contexts safely`)
5. **Task 2 remount coverage:** `d84faaf7` (`test(233-01): cover mount reauthorization on reconnect`)

## Files Created/Modified

- `accrue_portal/lib/accrue_portal/context.ex` - Context envelope, adapter callbacks, owner identity, and safe local switch-path checks.
- `accrue_portal/lib/accrue_portal/customer_session.ex` - Authorization-before-provisioning and exact custom Customer lookup; unambiguous legacy personal resolution.
- `accrue_portal/lib/accrue_portal/auth_hook.ex` and `auth_plug.ex` - Separate login from denied/unavailable outcomes across LiveView and HTTP actions.
- `accrue_portal/lib/accrue_portal/router.ex` and `live/blocked_live.ex` - Adapter handoff and authenticated blocked recovery route.
- `accrue_portal/lib/accrue_portal/layouts.ex` - Display the selected host billable separately from Portal branding.
- `accrue_portal/test/accrue_portal/context_contract_test.exs`, `auth_hook_test.exs`, and `router_test.exs` - Integration and guard coverage.
- `accrue_portal/test/support/tap_formatter.ex` - ExUnit event formatter used to preserve executable TDD RED evidence.

## Verification

- `cd accrue_portal && mix test test/accrue_portal/context_contract_test.exs` - passed for Task 1.
- `cd accrue_portal && mix test test/accrue_portal/auth_hook_test.exs test/accrue_portal/context_contract_test.exs` - 10 tests, 0 failures.
- `cd accrue_portal && mix test test/accrue_portal/auth_hook_test.exs test/accrue_portal/context_contract_test.exs test/accrue_portal/router_test.exs test/accrue_portal/live/subscription_live_test.exs` - 25 tests, 0 failures, including fresh authorization after a simulated remount.
- `cd accrue_portal && mix test --warnings-as-errors` - 45 tests, 0 failures.
- TDD RED evidence passed `check tdd-red-evidence` for Task 1 and the authenticated-denial Task 2 assertion. The persisted reports are `233-01-T1-RED.json` and `233-01-T2-RED.json`.
- `git diff --check` passed before the implementation commit.

## Decisions Made

- Custom contexts must be resolved by the host adapter and authorized before Portal checks or creates a Customer. Selection values do not grant access.
- Custom Customer identity is the owner type, lossless owner ID, and configured processor triple. Personal installs without an adapter retain a single existing processor Customer; multiple matching processor rows are treated as ambiguous rather than choosing one.
- The blocked page is outside the customer-required LiveView session, requires an authenticated actor, uses generic copy, and returns to the host application root.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved existing personal Customers across supported processors**
- **Found during:** Task 2 verification.
- **Issue:** Binding the no-adapter personal path to the current default processor hid existing Braintree Customers and broke Portal subscription detail tests.
- **Fix:** Resolve a unique existing personal Customer by owner type and ID and carry that row's processor into the personal Context. If multiple processor rows match, fail closed rather than selecting the first.
- **Files modified:** `accrue_portal/lib/accrue_portal/context.ex`, `accrue_portal/lib/accrue_portal/customer_session.ex`.
- **Verification:** The focused suite including `subscription_live_test.exs` passed (23 tests); the full package suite passed (44 tests).
- **Committed in:** `d07ffc0c`.

**Total deviations:** 1 auto-fixed (1 bug).
**Impact on plan:** Preserved the promised legacy personal path while keeping custom host contexts bound to the configured processor. No schema or dependency changes were introduced.

## Issues Encountered

- The local Hex cache lacked dependencies pinned in the existing lockfile. `HEX_HOME=/tmp/accrue-233-hex mix deps.get` restored those locked dependencies; dependency manifests and lockfiles remained unchanged.
- The router test's expected LiveView route count was updated to include the new blocked route.
- `roadmap.update-plan-progress 233` could not update the pre-existing `0/TBD` phase row because the roadmap has no writable Phase 233 plan-detail section. The progress row was updated to `2/7 In Progress`; the phase remains active.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The optional host context contract and generic denial path are ready for later Portal action authorization and selection persistence work.
- No account discovery, pin parsing, or action expansion was added; later plans can build on the Context contract without assuming a host company model.

---
*Phase: 233-shared-direction-portal-contract*
*Completed: 2026-10-07*

## Self-Check: PASSED

- Summary file exists at the required phase path.
- All five task commits (`4fc801ff`, `329d63e5`, `7f21bf9f`, `d07ffc0c`, `d84faaf7`) are ancestors of the recorded plan head.
- The plan ledger measures five commits from `b0d94fa1682bcc9115fac6cf9f31b65b669a6649` through `d84faaf727a146742417c7dae51109a3bf9573c2`.
- Stub scan found no empty-value UI placeholders, TODOs, FIXMEs, or placeholder copy in plan-owned source and tests.
