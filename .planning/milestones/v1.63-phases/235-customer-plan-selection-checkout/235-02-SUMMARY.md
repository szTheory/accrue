---
phase: 235-customer-plan-selection-checkout
plan: 02
subsystem: payments
tags: [phoenix, liveview, checkout, braintree, playwright, ecto]
requires:
  - phase: 235-01
    provides: visible Braintree checkout form, safe retry behavior, and browser fixtures
provides:
  - Exact pricing selection bound to validated sign-in return and persisted checkout operation
  - Trusted complete terms rendered from the persisted local session with fail-closed recovery
  - Served browser proof of pricing, sign-in, selected checkout, and unknown-plan recovery
affects: [235-03, 235-04]
actuals:
  tokens: 8089
  tasks: 3
  commits: 4
plan_head_before: 0e171488cb7f5b8bf1f8410e214530912494ba0d
plan_head_after: 32a7b9f4311ff8326a4e52fc85c0080bca4dfd4a
tech-stack:
  added: []
  patterns:
    - Selection UUID scopes checkout idempotency to one pricing return
    - Persisted session metadata is the sole source for displayed checkout terms
key-files:
  created: []
  modified:
    - accrue/lib/accrue/checkout/local_session.ex
    - accrue/test/accrue/checkout/local_session_test.exs
    - accrue_portal/lib/accrue_portal/live/checkout_live.ex
    - accrue_portal/test/accrue_portal/live/checkout_live_test.exs
    - examples/accrue_host/config/runtime.exs
    - examples/accrue_host/e2e/phase233-braintree-checkout.spec.js
    - examples/accrue_host/lib/accrue_host_web/controllers/page_controller.ex
    - examples/accrue_host/lib/accrue_host_web/controllers/user_session_controller.ex
    - examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex
    - examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs
    - scripts/ci/accrue_host_seed_e2e.exs
key-decisions:
  - "Bind each selected checkout to a UUID in the validated login return so duplicate resumes reuse one persisted session while a new pricing visit gets a fresh operation."
  - "Use the organization shared-billing route after fresh host context authorization so actor, billable, and portal context remain aligned."
  - "Reject incomplete or mismatched persisted terms before enabling payment; explicitly trusted zero remains displayable."
requirements-completed: [CKO-04, CKO-03]
coverage:
  - id: D1
    description: Exact plan selection survives the pricing sign-in return and creates a stable persisted checkout session for duplicate resumes.
    requirement: CKO-04
    verification:
      - kind: integration
        ref: examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs#pricing selection stores only a validated exact-plan login return
        status: pass
      - kind: unit
        ref: accrue/test/accrue/checkout/local_session_test.exs#concurrent create_or_reuse calls with the same operation return the same session
        status: pass
    human_judgment: false
  - id: D2
    description: Checkout displays only complete persisted host-trusted plan terms, distinguishes explicit zero from missing terms, and blocks invalid amounts or line-item mismatches.
    requirement: CKO-03
    verification:
      - kind: automated_ui
        ref: accrue_portal/test/accrue_portal/live/checkout_live_test.exs#checkout offer summary and payment eligibility cases
        status: pass
    human_judgment: false
  - id: D3
    description: The served browser journey carries the selected Launch plan through sign-in and renders persisted trusted terms; unknown plans recover without a default selection.
    requirement: CKO-04
    verification:
      - kind: e2e
        ref: examples/accrue_host/e2e/phase233-braintree-checkout.spec.js#pricing selection survives login and renders persisted trusted terms
        status: pass
      - kind: e2e
        ref: examples/accrue_host/e2e/phase233-braintree-checkout.spec.js#unknown pricing selection recovers without selecting a default
        status: pass
    human_judgment: false
  - id: D4
    description: Existing Braintree browser integration remains covered for successful mock disposition, retry, setup failure, abandonment, and duplicate-action behavior.
    requirement: CKO-04
    verification:
      - kind: e2e
        ref: cd examples/accrue_host && npm run e2e:braintree-checkout (11 passed, deterministic local fixtures and mocked SDK)
        status: pass
    human_judgment: false
decisions:
  - "Per-pricing-return UUID creates a fresh idempotency namespace while concurrent resumes of that return converge on one local session."
  - "The Portal receives the freshly authorized organization shared-billing path for organization checkout."
metrics:
  duration: 12min
  completed: 2026-10-08
status: complete
---

# Phase 235 Plan 02: Customer Plan Selection & Checkout Summary

**A selected host offer now stays bound to its authenticated return and persisted checkout session, whose complete trusted terms are shown before payment.**

## Performance

- **Duration:** About 12 minutes
- **Started:** 2026-10-08T11:48:00Z
- **Completed:** 2026-10-08T12:00:24Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- The pricing CTA records a validated exact plan plus a unique selection UUID; login resumes that selection without a default plan or changed billable context.
- Duplicate/concurrent resumes reuse the session tied to that selection, while a new pricing selection receives a separate idempotency key.
- Checkout terms render from trusted persisted metadata and matching line items. Missing or invalid material terms prevent payment and present recovery; explicit trusted zero is retained.
- The served browser suite proves the selected-plan journey and maintains the existing deterministic Braintree retry and failure coverage.

## Task Commits

1. **Task 1: Persist the exact host selection and retain it across sign-in** — `2398917a`, `f4c2c135` (feature and correctness follow-up)
2. **Task 2: Render trusted complete terms and fail closed** — `049a859f`
3. **Task 3: Prove the served browser journey** — `32a7b9f4`

**Plan metadata:** state and roadmap updates are committed separately from the four measured task commits.

## Files Created/Modified

- `examples/accrue_host/lib/accrue_host_web/controllers/page_controller.ex` and `user_session_controller.ex` — validate and preserve the exact plan selection through login.
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` — persist plan terms, bind the session to the organization and selection, and route to authorized shared billing.
- `accrue/lib/accrue/checkout/local_session.ex` — recover a concurrent insert race by returning the already persisted session for the same operation.
- `accrue_portal/lib/accrue_portal/live/checkout_live.ex` — display trusted complete terms and expose invalid terms as an alert.
- Host, core, and Portal tests; E2E spec; E2E session seeding; local test portal origin configuration.

## Decisions Made

- A UUID in the return path scopes idempotency to one pricing action: retries converge, while a later pricing click can start a new selection.
- The Portal shared-billing route is used only for a local persisted session, so the host's organization authorization and cookie context are retained.
- No charge maximum was inferred. This flow passes the selected processor price ID and exact integer minor-unit metadata; the inspected contract did not establish a maximum bound.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Configure the local Portal origin for Braintree return URLs**
- **Found during:** Task 1 / Task 3 browser verification
- **Issue:** Test runtime had no `portal_base_url`, so local checkout could not build its return URL.
- **Fix:** Configure a test-only origin using the configured host port.
- **Files modified:** `examples/accrue_host/config/runtime.exs`
- **Verification:** `npm run e2e:braintree-checkout` passed.
- **Committed in:** `f4c2c135`

**2. [Rule 2 - Missing Critical] Keep organization checkout inside the freshly authorized shared-billing context**
- **Found during:** Task 1 / Task 3 browser verification
- **Issue:** The personal `/billing` mount did not match the organization payer context and the generated absolute URL lost the host session context.
- **Fix:** Route local organization sessions to `/shared-billing` with a relative Portal path and include the billable name in trusted session metadata.
- **Files modified:** `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`
- **Verification:** Host integration and served browser journey passed.
- **Committed in:** `f4c2c135`

**3. [Rule 1 - Bug] Converge concurrent local-session creation on the existing selection**
- **Found during:** Task 1 concurrency review
- **Issue:** Two first-time `create_or_reuse` calls could race at the unique operation ID and one caller would receive a changeset error.
- **Fix:** On operation ID uniqueness conflict, re-read and return the persisted session; test 12 concurrent calls for one identical session.
- **Files modified:** `accrue/lib/accrue/checkout/local_session.ex`, `accrue/test/accrue/checkout/local_session_test.exs`, and host selection handling.
- **Verification:** Core local-session tests passed.
- **Committed in:** `f4c2c135`

**4. [Rule 2 - Missing Critical] Seed complete trusted metadata for browser checkout fixtures**
- **Found during:** Task 3
- **Issue:** Existing seeded checkout sessions lacked the metadata/line item equality required by the new terms contract.
- **Fix:** Seed plan name, amount, currency, interval, billable context, and matching priced line item.
- **Files modified:** `scripts/ci/accrue_host_seed_e2e.exs`
- **Verification:** Exact Playwright suite passed (11 tests).
- **Committed in:** `32a7b9f4`

**5. [Rule 1 - Bug] Make incomplete-summary recovery status unambiguous to assistive and browser assertions**
- **Found during:** Task 3
- **Issue:** Using `role=status` collided with a pre-existing status assertion on the checkout page.
- **Fix:** Expose the invalid-terms message as an alert.
- **Files modified:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex`
- **Verification:** Portal checkout LiveView and Playwright suites passed.
- **Committed in:** `32a7b9f4`

**Total deviations:** 5 auto-fixed (two Rule 1, two Rule 2, one Rule 3). All addressed direct blockers or correctness requirements for this plan.

## Verification

- `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs` — **6 tests, 0 failures**.
- `cd accrue && mix test test/accrue/checkout/local_session_test.exs` — **5 tests, 0 failures**.
- `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs` — **8 tests, 0 failures**.
- `cd examples/accrue_host && npm run e2e:braintree-checkout` — **11 browser tests passed** using deterministic local fixtures and a mocked SDK. This does not assert live-provider fidelity.

## Issues Encountered

- Chromium could not start inside the default sandbox due to macOS bootstrap restrictions. The same plan command passed when run with the approved browser execution context.
- The host-focused test initially used the old plan-only URL after the selection UUID became required; updating the test to exercise the validated selection path restored the intended assertion.

## User Setup Required

None. Browser coverage uses local deterministic fixtures and a mocked Braintree SDK.

## Next Phase Readiness

Plan 235-03 can build on the selected-plan persistence and trusted summary contract. The real browser path and organization context are now exercised. No live provider behavior is claimed.

## Self-Check: PASSED

- Task source, test, runtime, fixture, and E2E files exist.
- Task commits `2398917a`, `049a859f`, `f4c2c135`, and `32a7b9f4` are present in the current history.
- Four commits are measured from plan base `0e171488cb7f5b8bf1f8410e214530912494ba0d` through `32a7b9f4311ff8326a4e52fc85c0080bca4dfd4a`.

---
*Phase: 235-customer-plan-selection-checkout*
*Completed: 2026-10-08*
