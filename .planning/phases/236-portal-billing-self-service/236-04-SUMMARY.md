---
phase: 236-portal-billing-self-service
plan: 04
subsystem: payments
tags: [checkout, braintree, phoenix-liveview, redirect-validation, exunit]

# Dependency graph
requires: [236-01]
provides:
  - Checkout completion, decline, and uncertainty messages follow the actual server/provider result.
  - Checkout success and recovery navigation allow local paths or the configured HTTPS origin only.
affects: [portal-billing-self-service, checkout, return-navigation]

# Actuals (#2632)
actuals:
  tokens: 6716
  tasks: 2
  commits: 2
plan_head_before: f9ef76518be5dab2cdcc13c906157c653fb5e9d9
plan_head_after: e6679acebe927b912d71313c9a71b2084f46b886

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Accept external checkout navigation only when HTTPS origin matches configured portal_base_url; retain validated local paths and Portal fallback."
    - "Carry the success announcement through LiveView redirects after persisted completion."
    - "Translate explicit Braintree processor-decline responses into CardError; keep other provider errors uncertain."

key-files:
  created: []
  modified:
    - accrue/lib/accrue/processor/braintree.ex
    - accrue/test/accrue/processor/braintree_test.exs
    - accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex
    - accrue_portal/lib/accrue_portal/live/checkout_live.ex
    - accrue_portal/test/accrue_portal/checkout_context_test.exs
    - accrue_portal/test/accrue_portal/live/checkout_live_test.exs

key-decisions:
  - "Classify only explicit Braintree decline responses as card declines; preserve uncertain handling for other failures."
  - "Match HTTPS return host and effective port against configured portal_base_url, and use the local Portal home for blank or unsafe destinations."
  - "Apply the same external-origin policy to the recovery link so success redirects and recovery navigation share one trust boundary."

requirements-completed: [POR-01, POR-04, POR-07]

coverage:
  - id: D1
    description: "Checkout completion remains tied to server/provider evidence: query markers alone do not complete or cancel, declines state no subscription was created, and uncertain outcomes prohibit replay."
    requirement: POR-04
    verification:
      - kind: integration
        ref: "test/accrue_portal/live/checkout_live_test.exs#query-only success markers do not complete or cancel the checkout"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/checkout_live_test.exs#a declined card announces that no subscription was created"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/checkout_live_test.exs#accepted provider result with failed completion persistence shows uncertainty"
        status: pass
      - kind: unit
        ref: "test/accrue/processor/braintree_test.exs#create_subscription/2 translates a processor decline into a card error"
        status: pass
    human_judgment: false
  - id: D2
    description: "POST and LiveView accept validated local or configured HTTPS destinations, reject malformed or unapproved destinations, and retain the success announcement across redirects."
    requirement: POR-07
    verification:
      - kind: integration
        ref: "test/accrue_portal/checkout_context_test.exs#POST return destinations accept only local paths and the configured HTTPS origin"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/checkout_live_test.exs#submitting a nonce completes checkout without exposing card fields in the LiveView"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/checkout_live_test.exs#unapproved HTTPS success host falls back to the portal home"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/checkout_live_test.exs#missing success URL returns home with a success announcement"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/checkout_live_test.exs#expired checkout with unapproved HTTPS recovery only links to the portal"
        status: pass
    human_judgment: false

# Metrics
duration: 9 min
completed: 2026-10-08
status: complete
---

# Phase 236 Plan 04: Checkout outcomes and returns Summary

**Checkout declines and uncertainty now match authoritative provider results, and return URLs are restricted to validated local or configured HTTPS destinations.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-10-08T16:56:43Z
- **Completed:** 2026-10-08T17:05:51Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Braintree processor-decline responses now reach checkout as card declines, while other provider failures remain uncertain and are never replayed automatically.
- POST and LiveView destinations accept safe local paths or the exact HTTPS origin configured by `portal_base_url`; malformed, blank, and unapproved destinations use the Portal home.
- LiveView success flashes survive redirects, and checkout recovery links use the same external-origin policy.
- Added deterministic tests for query-only status markers, decline and uncertainty copy, and the full return destination matrix.

## Task Commits

Each task was committed atomically:

1. **Task 1: Keep checkout outcome tied to server evidence** - `44f4346f` (fix)
2. **Task 2: Return only to validated destinations** - `e6679ace` (fix)

## Files Created/Modified

- `accrue/lib/accrue/processor/braintree.ex` - Classifies explicit Braintree subscription declines as card errors.
- `accrue/test/accrue/processor/braintree_test.exs` - Covers decline translation.
- `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` - Validates POST return URLs against local-path and configured-origin rules.
- `accrue_portal/lib/accrue_portal/live/checkout_live.ex` - Applies the same policy to LiveView redirects and recovery links and preserves success flashes.
- `accrue_portal/test/accrue_portal/checkout_context_test.exs` - Covers the POST return destination matrix.
- `accrue_portal/test/accrue_portal/live/checkout_live_test.exs` - Covers query-only status, decline, uncertainty, LiveView redirects, and recovery.

## Decisions Made

- Treat an explicit Braintree “Processor Declined” response as a definitive card decline; keep generic provider errors in the uncertain state.
- Require configured HTTPS host and port equality for external navigation, while keeping safe local paths available.
- Apply the same host rule to the recovery link as to success redirects because both navigate using persisted checkout return data.

## Deviations from Plan

### Auto-fixed Issues

**1. Braintree subscription declines were surfaced as generic API errors**
- **Found during:** Task 1 (Keep checkout outcome tied to server evidence)
- **Issue:** The provider adapter converted a definite “Processor Declined” response to a generic API error, so the checkout showed uncertainty instead of a confirmed decline.
- **Fix:** Reused the existing Braintree decline translator for subscription creation errors and added adapter plus LiveView regression coverage.
- **Files modified:** `accrue/lib/accrue/processor/braintree.ex`, `accrue/test/accrue/processor/braintree_test.exs`, `accrue_portal/test/accrue_portal/live/checkout_live_test.exs`
- **Verification:** Braintree suite (19 tests) and focused Portal suite (30 tests) passed.
- **Committed in:** `44f4346f`

**Total deviations:** 1 auto-fixed (provider outcome classification)
**Impact on plan:** Necessary to make the planned decline state observable from the real Braintree adapter; no dependency or public API changes.

## Issues Encountered

- The existing LiveView accepted an absent success URL in place, while the plan requires the safe local fallback. Updated this branch to redirect to Portal home with the persisted success announcement.
- Applied the configured-origin rule to the existing recovery link as well, preventing it from exposing an unapproved external destination.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Wave 2 is ready for the `accrue_portal` package CI gate.
- Deterministic checkout outcome and redirect behavior is covered without human UAT; the phase's served-host proof remains in Plan 236-05.

---
*Phase: 236-portal-billing-self-service*
*Completed: 2026-10-08*
