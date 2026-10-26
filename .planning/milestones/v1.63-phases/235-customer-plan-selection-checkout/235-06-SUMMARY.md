---
phase: 235-customer-plan-selection-checkout
plan: 06
subsystem: payments
tags: [checkout, braintree, stripe, phoenix-liveview, playwright, exunit]

# Dependency graph
requires:
  - phase: 235-04
    provides: Mounted Braintree checkout and served browser test lane.
  - phase: 235-05
    provides: Trusted checkout terms, safe recovery behavior, and the Braintree browser fixture setup.
provides:
  - Braintree host returns resolve a completed LocalSession through the current authorized organization and exact processor Customer.
  - Pending, missing, mismatched, forged, and foreign returns cannot claim checkout completion.
  - Served browser coverage follows pricing handoff to mounted checkout and verifies the fixture-backed host return.
affects: [customer-plan-selection-checkout, portal-checkout, payment-verification]

# Actuals (#2632): chars/4 over the realized plan diff.
actuals:
  tokens: 7826
  tasks: 2
  commits: 3
plan_head_before: 095b0761f9c343af89471e82f6cab028a9b17c89
plan_head_after: 11787fe95270c2a899ed1b5adf0b86604a0e1370

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Resolve provider-specific checkout evidence through the current authorized billable and processor Customer."
    - "Use a deterministic injected browser SDK and explicitly labeled LocalSession fixtures; do not claim live-provider success."

key-files:
  created:
    - examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs
  modified:
    - accrue/lib/accrue/checkout/local_session.ex
    - examples/accrue_host/lib/accrue_host/billing.ex
    - examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex
    - examples/accrue_host/e2e/phase233-braintree-checkout.spec.js
    - scripts/ci/accrue_host_seed_e2e.exs

key-decisions:
  - "Braintree uses the selected plan and selection UUID only as an operation locator; completion requires the matching persisted LocalSession and fresh billing authorization."
  - "Stripe keeps its cs_ locator and fetched paid-session reconciliation unchanged."
  - "The browser success case uses an explicitly fixture-backed completed LocalSession because this lane has no deterministic server-side Braintree subscription gateway."

patterns-established:
  - "Provider return branches use only their provider's evidence source: Stripe fetch/reconcile or scoped Braintree LocalSession."
  - "Browser fixtures label seeded completion as non-live evidence, while the Portal controller test proves the nonce POST completion with a deterministic gateway stub."

requirements-completed: [CKO-01, CKO-02, CKO-03, CKO-04]

coverage:
  - id: D1
    description: "Only the current authorized Braintree Customer's exact completed LocalSession can show host completion; other states stay pending or unavailable."
    requirement: CKO-02
    verification:
      - kind: unit
        ref: "ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 mix test test/accrue_host_web/live/subscription_live_braintree_test.exs (8 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Stripe hosted returns retain cs_ validation and fetched paid-session evidence."
    requirement: CKO-02
    verification:
      - kind: integration
        ref: "mix test test/accrue_host_web/live/subscription_live_test.exs (8 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The served checkout sends one mocked nonce POST, and completed, pending, and forged Braintree host returns render only their persisted-state outcomes."
    requirement: CKO-01
    verification:
      - kind: e2e
        ref: "npm run e2e:braintree-checkout (14 tests; deterministic injected SDK and fixture-backed return)"
        status: pass
      - kind: integration
        ref: "cd accrue_portal && mix test test/accrue_portal/checkout_context_test.exs --name-pattern 'rendered checkout form posts its pin and nonce'"
        status: pass
    human_judgment: false
  - id: D4
    description: "Repeated Braintree return reads do not create another LocalSession or replay a payment operation."
    requirement: CKO-03
    verification:
      - kind: unit
        ref: "subscription_live_braintree_test.exs: completed scoped return is read twice with unchanged LocalSession count"
        status: pass
      - kind: e2e
        ref: "npm run e2e:braintree-checkout: fixture-backed completed return reload renders the same completed state"
        status: pass
    human_judgment: false

duration: 60min
completed: 2026-10-08
status: complete
---

# Phase 235 Plan 06: Customer Plan Selection & Checkout Summary

**Braintree host returns now require a fresh scoped LocalSession match, with Stripe fetched payment evidence preserved and deterministic served-browser coverage.**

## Performance

- **Duration:** 60 minutes
- **Started:** 2026-10-08T13:52:34Z
- **Completed:** 2026-10-08T14:52:33Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added a Customer-scoped LocalSession lookup and a host Billing facade that re-resolves the active organization and current checkout permission before reading a Braintree return.
- Braintree returns validate the persisted processor, customer, billable, operation identity, plan, selection, terms, and line item. Only `completed` produces the host completion message; uncertain and other non-complete outcomes remain pending or unavailable without replay.
- Kept Stripe's `cs_` locator and fetched paid-session reconciliation on its existing branch.
- Extended the served browser path from pricing selection to the mounted Braintree form, verifying one nonce-bearing mocked POST. Added explicitly fixture-backed completed, pending, repeated, and forged host return checks.
- Preserved the actual Portal POST completion proof: the deterministic controller test verifies the LocalSession becomes completed after a nonce-bearing POST.

## Task Commits

1. **Task 1 RED:** `4832a0fe` — add failing Braintree return proof.
2. **Task 1 GREEN:** `19b0dac6` — resolve scoped Braintree checkout returns.
3. **Task 2:** `11787fe9` — prove scoped Braintree host returns in the browser.

## Files Created/Modified

- `accrue/lib/accrue/checkout/local_session.ex` — exact Customer, Braintree processor, and operation lookup.
- `examples/accrue_host/lib/accrue_host/billing.ex` — fresh organization permission and processor Customer resolution.
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` — distinct Braintree LocalSession and Stripe fetched-session return paths.
- `examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs` — completed, pending, foreign, forged, permission, and repeated-read assertions.
- `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js` — pricing handoff, visible submit, and fixture-backed host return coverage.
- `scripts/ci/accrue_host_seed_e2e.exs` — scoped completed/open LocalSession fixtures with explicit evidence labeling and cleanup.

## Decisions Made

- The Braintree URL carries only the existing plan and selection values to locate the persisted operation; the URL itself never establishes payment.
- The served browser's completed return is fixture-backed because the test server has no deterministic Braintree subscription gateway configured. The injected SDK is mock evidence, and no live-provider transaction is claimed.
- Stripe's existing provider fetch remains authoritative and unchanged.

## TDD Gate Compliance

- **RED:** Commit `4832a0fe` added the named completed-return assertion. The target executed and failed because the host rendered its generic unverifiable-return message instead of recognizing the completed scoped LocalSession. The GSD classifier returned `RED_EVIDENCE_OK`; semantic review confirmed the planned behavior assertion failed after valid setup. A temporary ExUnit-to-JUnit formatter was used because ExUnit's native console report is not a supported classifier format; the formatter and report were removed after validation.
- **GREEN:** Commit `19b0dac6` added the narrow Customer operation lookup, fresh host authorization, Braintree evidence checks, and passing Braintree/Stripe regression tests.
- **REFACTOR:** None required.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test correction] Compare repeated-read session count to the test baseline**
- **Found during:** Task 1
- **Issue:** The assertion expected exactly one LocalSession, but the test database already contained other sessions in the test transaction.
- **Fix:** Capture the count after inserting the target session and assert repeated returns leave that count unchanged.
- **Files modified:** `examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs`
- **Verification:** The focused Braintree suite passed 8 tests.
- **Committed in:** `19b0dac6`

**2. [Execution sequencing] Finish the full read-first pass before production edits**
- **Found during:** Task 1 RED setup
- **Issue:** The new test file was created before the final two declared `read_first` files had been opened.
- **Fix:** Read both files before any production-source edits, then continued against the plan's existing scope.
- **Files modified:** None beyond planned test/source files.
- **Verification:** Completed the required reads; focused regression suites passed.
- **Committed in:** The existing Task 1 commits; no extra files or scope were added.

**Total deviations:** 2 (one Rule 1 correction and one execution-sequencing correction). **Impact:** No scope expansion; the assertion now checks the intended read-only invariant.

## Issues Encountered

- The initial sandboxed Playwright invocation could not launch Chromium because macOS denied Chromium's Mach bootstrap registration. The same plan command passed after the approved local browser escalation: 14 tests, 0 failures.
- The first targeted Mix invocation used unsupported `--grep`; the equivalent `--name-pattern` command ran the intended controller test successfully.

## User Setup Required

None.

## Next Phase Readiness

Plan 235-06's Braintree return gap is closed with automated unit, integration, and served-browser evidence. The execution summary does not mark Phase 235 complete; phase-level verification and post-execution gates remain with the orchestrator.

---
*Phase: 235-customer-plan-selection-checkout*
*Plan: 06*
*Completed: 2026-10-08*

## Self-Check: PASSED

- The Summary file exists.
- Task commits `4832a0fe`, `19b0dac6`, and `11787fe9` are ancestors of HEAD.
- The persisted plan ledger measures 3 task commits from `095b0761` through `11787fe9`.
