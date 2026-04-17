---
phase: 20-organization-billing-with-sigra
plan: 02
subsystem: auth
tags: [sigra, liveview, organization-billing, scope-hydration, testing]
requires:
  - phase: 20-organization-billing-with-sigra
    provides: Sigra-backed host organizations, memberships, and migrations from plan 20-01
provides:
  - Sigra-hydrated `current_scope` for the host billing page
  - Scope-derived organization billing facade helpers that ignore client org ids
  - Locked host billing copy and denial behavior for no-active-org and member viewers
affects: [phase-20-plan-03, phase-20-plan-04, org-billing, accrue-host]
tech-stack:
  added: []
  patterns: [hydrate host auth scope through Sigra, derive billing owner from current_scope only]
key-files:
  created: []
  modified:
    - examples/accrue_host/lib/accrue_host/billing.ex
    - examples/accrue_host/lib/accrue_host_web/user_auth.ex
    - examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex
    - examples/accrue_host/test/accrue_host_web/org_billing_live_test.exs
    - examples/accrue_host/test/support/conn_case.ex
key-decisions:
  - "The host billing page now resolves the active organization through Sigra.Scope.Hydration and clears stale active-org pointers fail-closed."
  - "All organization billing mutations route through scope-derived facade helpers, so browser-supplied organization ids are rendered inert."
patterns-established:
  - "Use current_scope.active_organization plus membership role to authorize host billing actions."
  - "Carry active_organization_id in the host test session when proving Sigra-hydrated LiveView behavior."
requirements-completed: [ORG-02]
duration: 4 min
completed: 2026-04-17
---

# Phase 20 Plan 02: Organization Billing Scope Summary

**The host `/app/billing` flow now hydrates Sigra active-organization scope server-side and bills only the resolved organization with locked denial copy for non-admin viewers**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-17T19:59:44Z
- **Completed:** 2026-04-17T20:04:15Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added the ORG-02 LiveView contract for active-org happy path, no-active-org denial, member denial, and forged organization id attempts.
- Hydrated `current_scope` through `Sigra.Scope.Hydration.hydrate/3` so stale active-organization pointers fail closed before billing code runs.
- Routed host billing mutations through scope-derived helpers and updated the billing page copy to match the Phase 20 UI contract.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add ORG-02 host LiveView proof for Sigra-hydrated active-organization billing** - `aa1b24c` (test)
2. **Task 2: Hydrate current scope with Sigra and route ORG-02 billing through scope-derived host wrappers** - `1fe4716` (feat)

## Files Created/Modified
- `examples/accrue_host/lib/accrue_host/billing.ex` - adds scope-derived organization lookup, billing-state, subscribe, tax-location, and cancel helpers.
- `examples/accrue_host/lib/accrue_host_web/user_auth.ex` - hydrates the host scope through Sigra and clears stale active-org session pointers.
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` - switches `/app/billing` to active-organization copy, denial states, and scope-only billing mutations.
- `examples/accrue_host/test/accrue_host_web/org_billing_live_test.exs` - proves owner/admin happy path plus no-org, member-only, and forged-id denial behavior.
- `examples/accrue_host/test/support/conn_case.ex` - allows tests to seed `active_organization_id` into the host session.

## Decisions Made
- Used the real Sigra hydrator in host auth instead of reimplementing org lookup logic inside the billing LiveView.
- Left organization selection outside the billing page and treated every client-supplied organization id as untrusted noise.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Extended the host conn test helper with `active_organization_id` session support**
- **Found during:** Task 2 (Hydrate current scope with Sigra and route ORG-02 billing through scope-derived host wrappers)
- **Issue:** The new LiveView proof needed a way to seed the active organization into the host session so Sigra hydration could run in controller and LiveView tests.
- **Fix:** Updated `ConnCase.log_in_user/3` to accept `active_organization_id` and store it in the test session.
- **Files modified:** `examples/accrue_host/test/support/conn_case.ex`
- **Verification:** `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host/billing_facade_test.exs test/accrue_host_web/org_billing_live_test.exs`
- **Committed in:** `1fe4716`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required to exercise the planned Sigra-hydrated host flow in integration tests. No architectural scope change.

## Issues Encountered
- The first LiveView pass missed an assign for the locked start-subscription copy, which surfaced immediately under `--warnings-as-errors` and was corrected before the task commit.
- The org LiveView suite needed direct event submits and fake-row cleanup to keep forged-id and denial assertions stable when run alongside the billing facade tests.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The host auth layer now exposes a hydrated `current_scope` with active organization and membership data for downstream admin proof work.
- Follow-on Phase 20 plans can reuse the scope-derived organization helpers instead of threading organization ids through params or LiveView payloads.

## Self-Check: PASSED

---
*Phase: 20-organization-billing-with-sigra*
*Completed: 2026-04-17*
