---
phase: 236-portal-billing-self-service
plan: 03
subsystem: payments
tags: [portal, subscriptions, phoenix-liveview, lifecycle, exunit]

# Dependency graph
requires: [236-02]
provides:
  - List and detail cancellation actions use matching processor-specific consequences and explicit confirmation.
  - Subscription reads distinguish successful empty results from unavailable data and render observed lifecycle states truthfully.
  - Subscription mutations reauthorize the exact current target and announce the actual result.
affects: [portal-billing-self-service, subscription-self-service, provider-capabilities]

actuals:
  tokens: 9500
  tasks: 2
  commits: 1
plan_head_before: 42b6407aa55d284b3fac4536a96ef3206be5f011
plan_head_after: 73d6ad0ac2f0f6883c7799e118259a53b62f2358

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Represent subscription list and lookup reads with explicit success or unavailable outcomes."
    - "Resolve and authorize the exact subscription again when a confirmed LiveView mutation arrives."
    - "Gate cancellation and plan changes by current lifecycle state and provider capabilities."
    - "Use shared lifecycle and consequence copy without claiming host application access outcomes."

key-files:
  created: []
  modified:
    - accrue/lib/accrue/processor/braintree.ex
    - accrue/lib/accrue/processor/fake.ex
    - accrue/lib/accrue/processor/stripe.ex
    - accrue_portal/lib/accrue_portal/billing_read_model.ex
    - accrue_portal/lib/accrue_portal/copy.ex
    - accrue_portal/lib/accrue_portal/live/subscription_live.ex
    - accrue_portal/lib/accrue_portal/live/subscriptions_live.ex
    - accrue_portal/test/accrue_portal/context_live_test.exs
    - accrue_portal/test/accrue_portal/live/subscription_live_test.exs
    - accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs

key-decisions:
  - "Show cancel and plan-change controls only when both the observed subscription state and current provider capability support the action."
  - "Reauthorize the exact confirmed subscription at event time; stale or switched targets do not reach the provider mutation."
  - "Keep lifecycle copy limited to billing observations and do not promise host-application access or retained documents."
  - "Treat read failures as unavailable, never as a successful empty subscription collection."

requirements-completed: [POR-01, POR-02, POR-04, POR-06]

coverage:
  - id: D1
    description: "List and detail explain the same provider-specific cancellation consequence and require explicit confirmation before mutation."
    requirement: POR-02
    verification:
      - kind: integration
        ref: "test/accrue_portal/live/subscriptions_live_test.exs"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/subscription_live_test.exs"
        status: pass
      - kind: integration
        ref: "cd accrue_portal && mix test.ci (108 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Stale, foreign, denied, and switched-billable events are checked against current owner context and the exact target before mutation."
    requirement: POR-02
    verification:
      - kind: integration
        ref: "test/accrue_portal/context_live_test.exs"
        status: pass
      - kind: integration
        ref: "cd accrue_portal && mix test.ci (108 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Known lifecycle labels render from observed state; unknown or missing state stays unknown, and an unavailable read remains distinct from an empty result."
    requirement: POR-06
    verification:
      - kind: integration
        ref: "test/accrue_portal/live/subscriptions_live_test.exs"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/subscription_live_test.exs"
        status: pass
      - kind: integration
        ref: "cd accrue_portal && mix test.ci (108 tests, 0 failures)"
        status: pass
    human_judgment: false

duration: 18min
completed: 2026-10-08
status: complete
---

# Phase 236 Plan 03: Subscription Actions and Lifecycle Summary

**Subscription list and detail actions now use matching provider-specific consequences, exact-target authorization, and lifecycle wording limited to observed billing state.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-10-08T17:09:13Z
- **Completed:** 2026-10-08T17:27:07Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added explicit cancellation confirmation in the list and detail views. The confirmation names the billed entity and subscription, and explains immediate Braintree cancellation versus period-end cancellation for other supported processors.
- Re-resolved and reauthorized the exact subscription at confirmation time, then rechecked current lifecycle state and provider support before mutations. Tests cover stale and switched targets without provider calls.
- Rendered distinct successful-empty and unavailable subscription reads, with shared lifecycle labels for trialing, incomplete, unpaid, past-due, active, canceled, and unknown states.
- Removed unsupported promises about host application access and made missing billing observations explicit rather than treating them as healthy or zero.
- Added deterministic coverage for the list/detail consequence parity, unavailable reads, unsupported actions, lifecycle matrix, and mutation feedback.

## Task Commit

- **Subscription actions and observed lifecycle:** `73d6ad0a` (`feat`)

## Deviations from Plan

### Auto-fixed Issues

**1. Provider capability maps omitted already-supported plan changes and invoice previews**
- **Found during:** Task 1 (Match list and detail subscription consequences)
- **Issue:** Conservative action gating hid Fake and Stripe plan changes because their capability maps did not declare existing `swap_plan` and upcoming-invoice preview support.
- **Fix:** Declared those existing operations for Fake and Stripe; Braintree remains explicitly unsupported for plan swaps.
- **Files modified:** `accrue/lib/accrue/processor/fake.ex`, `accrue/lib/accrue/processor/stripe.ex`, `accrue/lib/accrue/processor/braintree.ex`
- **Verification:** The subscription LiveView tests and full Portal CI package gate pass.

**2. Repeatable unavailable-read states needed deterministic test seams**
- **Found during:** Task 2 (Render observed lifecycle and partial state)
- **Issue:** Database failure is not a stable test fixture for the distinction between empty and unavailable reads.
- **Fix:** Added injectable read seams to the read model and exercised explicit unavailable outcomes in LiveView tests.
- **Verification:** The unavailable list and detail tests pass within the full package gate.

## Automated Evidence

- `cd accrue_portal && mix test.ci` - **108 tests, 0 failures**; formatter and retired-package checks passed.
- `mix format` in both `accrue` and `accrue_portal` - passed.
- `git diff --check` - passed.
- No human UAT is needed for these deterministic claims. The remaining served-browser proof for Phase 236 is in Plan 236-05.

## Next Plan Readiness

Plan 236-05 is ready. Plans 236-02, 236-03, and 236-04 are complete, satisfying its declared dependencies.

---
*Phase: 236-portal-billing-self-service*
*Completed: 2026-10-08*

## Self-Check: PASSED

- GSD summary validation passed.
- All three coverage items classify as automatically covered.
- Implementation commit `73d6ad0a` exists at the recorded plan head.
