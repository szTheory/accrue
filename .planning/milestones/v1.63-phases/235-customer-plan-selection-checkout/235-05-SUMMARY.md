---
phase: 235-customer-plan-selection-checkout
plan: 05
subsystem: payments
tags: [checkout, payments, phoenix-liveview, braintree-mock, playwright, exunit]

# Dependency graph
requires:
  - phase: 235-03
    provides: Persisted checkout sessions with pinned customer context and authorization.
  - phase: 235-04
    provides: Portal checkout UI and the served Braintree browser lane.
provides:
  - Trusted explicit zero-priced checkout completes through the actual POST exactly once.
  - Expired checkout displays a validated route back to billing and makes no payment request.
affects: [portal-checkout, customer-plan-selection-checkout, payment-verification]

# Actuals (#2632)
actuals:
  tokens: 2912
  tasks: 2
  commits: 4
plan_head_before: fb5acfe01066b83852c84b7831be7bfbdca9fb91
plan_head_after: a219f5a598bbc87b766275714262bca8f3343acc

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Assert checkout behavior through the actual controller route and provider-operation counts."
    - "Verify recovery navigation in the served browser with the deterministic mock SDK."

key-files:
  created: []
  modified:
    - accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex
    - accrue_portal/lib/accrue_portal/live/checkout_live.ex
    - accrue_portal/test/accrue_portal/checkout_context_test.exs
    - accrue_portal/test/accrue_portal/live/checkout_live_test.exs
    - examples/accrue_host/e2e/phase233-braintree-checkout.spec.js
    - scripts/ci/accrue_host_seed_e2e.exs

key-decisions:
  - "Accept persisted amount_minor zero when all existing customer, processor, offer, line-item, and authorization checks match."
  - "Use only safe_recovery_url/2 output for expired-session navigation; unsafe cancel URLs retain the existing safe fallback."
  - "Treat the Braintree Playwright lane as deterministic mock-SDK evidence, not live-provider evidence."

requirements-completed: [CKO-01, CKO-03, CKO-04]

coverage:
  - id: D1
    description: "A trusted zero-priced checkout succeeds through POST exactly once."
    requirement: CKO-01
    verification:
      - kind: integration
        ref: "cd accrue_portal && mix test test/accrue_portal/checkout_context_test.exs test/accrue_portal/live/checkout_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Expired checkout links return to the validated host billing destination without a payment action."
    requirement: CKO-03
    verification:
      - kind: unit
        ref: "accrue_portal/test/accrue_portal/live/checkout_live_test.exs: expired and missing checkout sessions fail closed in the LiveView surface"
        status: pass
      - kind: e2e
        ref: "cd examples/accrue_host && npm run e2e:braintree-checkout (deterministic mock SDK)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Missing, negative, and mismatched charge terms remain ineligible and produce no provider call."
    requirement: CKO-04
    verification:
      - kind: integration
        ref: "cd accrue_portal && mix test test/accrue_portal/checkout_context_test.exs test/accrue_portal/live/checkout_live_test.exs"
        status: pass
    human_judgment: false

duration: 13min
completed: 2026-10-08
status: complete
---

# Phase 235 Plan 05: Customer Plan Selection & Checkout Summary

**Trusted zero-priced offers complete through POST exactly once, while expired checkouts return to billing through a validated and browser-tested link.**

## Performance

- **Duration:** 13 minutes
- **Started:** 2026-10-08T13:34:39Z
- **Completed:** 2026-10-08T13:47:37Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Aligned the actual checkout POST with the visible checkout eligibility rule for an explicitly trusted zero amount. The real POST test verifies the success redirect, persisted completed status, one billing operation, and replay protection.
- Preserved rejection for absent, negative, and mismatched amounts; those cases make no provider call.
- Added a safe Return to billing action to the expired-session guidance, checked the hostile javascript cancel URL falls back to /billing, and verified there is no checkout form or payment activity.
- Seeded an expired session for the host fixture and followed its recovery link in the served browser.

## Task Commits

1. **Task 1 RED:** `9d0ac3d5` — failing test for trusted zero-priced POST.
2. **Task 1 GREEN:** `275feb6a` — allow explicit trusted zero-priced checkout terms.
3. **Task 2 RED:** `34aa3636` — LiveView and served-browser coverage for expired checkout recovery.
4. **Task 2 GREEN:** `a219f5a5` — render the validated expired checkout recovery action.

## Files Created/Modified

- `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` — accepts zero minor units while preserving the remaining trusted-term checks.
- `accrue_portal/lib/accrue_portal/live/checkout_live.ex` — renders the safe billing recovery action in the expired state.
- `accrue_portal/test/accrue_portal/checkout_context_test.exs` — actual POST, provider count, persisted result, replay, and invalid-amount assertions.
- `accrue_portal/test/accrue_portal/live/checkout_live_test.exs` — expired-state safe link and no-payment assertions.
- `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js` — served-browser recovery route and no-payment assertion.
- `scripts/ci/accrue_host_seed_e2e.exs` — deterministic expired-session browser fixture.

## Decisions Made

- Persisted amount zero is eligible only when the existing actor, processor, offer, line-item, terms, and authorization checks still match.
- Expired-session navigation uses the already validated recovery URL; the test confirms an unsafe javascript URL resolves to the safe /billing fallback.
- Browser evidence uses the deterministic mock SDK. No live Braintree success is claimed.

## TDD Execution

- **Task 1 RED:** The named test, “explicit trusted zero-priced checkout POST completes exactly once,” reached the actual POST and failed at the saved-success-URL redirect assertion because zero was rejected by the positive-only check. The TAP evidence passed the GSD RED classifier and semantic review confirmed this was the intended behavior assertion, not a setup or fixture failure.
- **Task 1 GREEN:** Changed the trusted amount predicate to accept nonnegative minor units while retaining the other validation gates. The focused Portal suite passed 25 tests with 0 failures.
- **Task 2 RED:** The expired and missing session LiveView test mounted the expired fixture, confirmed the unsafe URL resolved to /billing, then failed at the intended Return to billing link assertion. Its TAP evidence passed the GSD RED classifier. The served-browser test also failed only because that recovery link was not yet present; the other 12 browser tests passed.
- **Task 2 GREEN:** Added the safe link to the expiry guidance and restricted the generic leave action to its ready-session case. The focused Portal suite passed 25 tests with 0 failures, and the served Braintree lane passed all 13 tests.
- **REFACTOR:** None required. Each task has a separate RED test commit before its GREEN implementation commit.

## Deviations from Plan

None. The planned controller, LiveView, regression tests, fixture, and served-browser checks were implemented.

## Issues Encountered

The first browser run in the default sandbox could not launch Chromium because of an OS MachPortRendezvous permission denial. The same planned command ran successfully with the approved local browser permission and passed all 13 tests. No planned verification remains unrun.

## User Setup Required

None.

## Next Phase Readiness

The zero-price POST and expired-session recovery gaps are covered by automated integration and served-browser checks. No manual UAT is needed for these deterministic outcomes. The browser lane uses a mock SDK and does not establish live-provider success.

---
*Phase: 235-customer-plan-selection-checkout*
*Plan: 05*
*Completed: 2026-10-08*

## Self-Check: PASSED

- The Summary file exists.
- All four task commits are ancestors of the current HEAD.
- The coverage classifier reports all three deliverables as automatically covered by passing checks.
