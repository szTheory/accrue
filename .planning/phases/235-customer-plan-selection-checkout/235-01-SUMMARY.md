---
phase: 235-customer-plan-selection-checkout
plan: 01
subsystem: payments
tags: [braintree, hosted-fields, checkout, playwright]

requires: []
provides:
  - Visible mounted checkout sends one tokenized nonce through the existing same-origin checkout endpoint.
  - Checkout setup, validation, abandonment, duplicate action, and uncertain transport states fail safely and announce status.
affects: [235-02, 235-03, CKO-01, CKO-02]

actuals:
  tokens: 5429
  tasks: 2
  commits: 2
  plan_head_before: 7a964bdc0942f8d3ea0d59f999e73da097c0fc7d
  plan_head_after: 19d63bf642902d2ceb8d98436070a2119d855541

tech-stack:
  added: []
  patterns:
    - Same-origin POST via fetch retains the existing CSRF, context pin, and nonce fields.
    - Mock SDK evidence is labeled separately from live Braintree/provider proof.

key-files:
  created:
    - .planning/phases/235-customer-plan-selection-checkout/deferred-items.md
  modified:
    - accrue_portal/priv/static/accrue_portal.js
    - examples/accrue_host/e2e/phase233-braintree-checkout.spec.js

key-decisions:
  - "Preserve the existing checkout POST contract and use fetch so an uncertain response can remain visible without replay."
  - "Treat a nonce and browser navigation as non-authoritative; the deterministic server case asserts the server's context denial."

patterns-established:
  - "A checkout operation becomes non-replayable as soon as its single-use nonce is dispatched."
  - "A late tokenization callback after hook teardown is ignored and cannot submit an abandoned form."

requirements-completed: [CKO-01, CKO-02]
coverage:
  - id: D1
    description: "Visible mounted checkout tokenizes once, posts the nonce and context pin, then renders an authoritative server denial."
    requirement: CKO-02
    verification:
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase233-braintree-checkout.spec.js#mock SDK visible submit sends one nonce and renders the server disposition"
        status: pass
    human_judgment: true
    rationale: "The injected SDK proves the browser path and safe server denial, but it does not prove live Braintree iframe behavior or provider acceptance."
  - id: D2
    description: "SDK errors, invalid card input, retries, duplicate actions, abandonment, teardown, and uncertain transport preserve at most one dispatch."
    requirement: CKO-01
    verification:
      - kind: e2e
        ref: "npm run e2e:braintree-checkout"
        status: pass
    human_judgment: false

duration: 19min
completed: 2026-10-08
status: complete
---

# Phase 235 Plan 01: Customer Plan Selection & Checkout Summary

**The mounted Braintree form sends one nonce through the existing checkout POST and keeps recovery safe after failures or abandonment.**

## Performance

- **Duration:** 19 min
- **Started:** 2026-10-08T04:28:35Z
- **Completed:** 2026-10-08T04:48:04Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced initialization-only browser evidence with a visible submit, one deterministic nonce, one same-origin POST carrying CSRF and context pin, and the rendered server denial. The mock SDK is explicitly labeled as mock evidence.
- Added accessible pending and error messages for secure SDK setup, invalid-card input, tokenization failure, server submission, and uncertain responses. Uncertain responses clear the nonce, disable replay, and direct customers to billing status or support.
- Covered repeated submits, fresh retries, SDK setup failure, leaving during tokenization, teardown, and blocked organization context in the Braintree browser suite.

## Task Commits

1. **Task 1: Submit one visible Braintree checkout to an evidenced server outcome** — `6ac9e5e0` (`feat`)
2. **Task 2: Keep the visible form safe across SDK failure, abandonment, and repeated actions** — `19d63bf6` (`fix`)

Plan metadata is committed separately with the sequential state and roadmap updates.

## Files Created/Modified

- `accrue_portal/priv/static/accrue_portal.js` — Secure Hosted Fields lifecycle, nonce POST, status announcements, replay guard, and late-callback teardown guard.
- `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js` — Deterministic mock-SDK evidence for the visible submit and recovery lifecycle.
- `.planning/phases/235-customer-plan-selection-checkout/deferred-items.md` — Existing unrelated compiler and exchange-rate warnings.

## Decisions Made

- Kept the existing checkout endpoint, CSRF token, signed context pin, and nonce field. The fetch response navigates to the server-resolved destination; a network failure remains on the form as an uncertain outcome and is never replayed automatically.
- The test's valid-context attempt reached the configured Braintree gateway and returned HTTP 500 in this environment. The deterministic proof instead submits a nonce with a deliberately stale context pin and asserts the server's 302 denial. This proves the real browser POST and an authoritative no-payment result without claiming a charge or live-provider success.
- Requirement IDs remain pending in REQUIREMENTS.md because sibling plans also declare them; `requirements.ready-ids` returned 0/2 ready.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Keep uncertain submission outcomes visible and non-replayable**
- **Found during:** Task 2
- **Issue:** Native form navigation could leave an uncertain server response without customer-facing status or recovery guidance.
- **Fix:** Send the same form fields to the existing same-origin POST with `fetch`; on transport failure, clear the nonce, keep submission disabled, and announce the billing-status/support guidance.
- **Files modified:** `accrue_portal/priv/static/accrue_portal.js`
- **Verification:** `npm run e2e:braintree-checkout` passed, including interrupted transport and no-replay assertions.
- **Committed in:** `6ac9e5e0`

**2. [Rule 1 - Bug] Ignore tokenization callbacks after checkout abandonment**
- **Found during:** Task 2
- **Issue:** A tokenization callback arriving after Hosted Fields teardown could submit an abandoned form.
- **Fix:** Mark the hook destroyed, clear its nonce, and return before processing any late callback.
- **Files modified:** `accrue_portal/priv/static/accrue_portal.js`, `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js`
- **Verification:** Browser test leaves during a delayed tokenization and asserts teardown with zero checkout POSTs.
- **Committed in:** `19d63bf6`

**3. [Rule 1 - Regression] Keep the offer CTA label while secure SDK setup is unavailable**
- **Found during:** Task 1 verification
- **Issue:** Replacing the offer CTA label with a processing label during SDK setup broke the existing promo-preview locator and obscured the selected offer.
- **Fix:** Disable payment while retaining the original CTA label, wait briefly for a late SDK load, and announce setup failures in the status region.
- **Files modified:** `accrue_portal/priv/static/accrue_portal.js`
- **Verification:** Both existing promo browser tests and all checkout browser tests passed.
- **Committed in:** `6ac9e5e0`

**4. [Rule 3 - Verification constraint] Use deterministic server denial instead of provider acceptance evidence**
- **Found during:** Task 1 verification
- **Issue:** With valid context, the Braintree-configured server attempted an external gateway call and returned HTTP 500 in this test environment.
- **Fix:** Keep the visible click and nonce-bearing POST, but deliberately invalidate the context pin so the real server returns its authoritative no-payment denial before the provider call.
- **Files modified:** `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js`
- **Verification:** The test asserts the nonce and pin in the POST, the 302 response, and the rendered denial; it does not claim provider acceptance.
- **Committed in:** `6ac9e5e0`

**Total deviations:** 4 (2 Rule 1, 1 Rule 2, 1 Rule 3). **Impact:** The planned visible form, server transport, and recovery states are covered; live Braintree provider acceptance remains outside this deterministic evidence.

## Issues Encountered

- Chromium could not start in the workspace sandbox because macOS denied its bootstrap service; the same planned command passed when run with elevated process permission.
- Existing unrelated compiler and `ex_money` warnings are recorded in `deferred-items.md` and were not changed.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

Plan 235-02 can proceed. The mounted checkout tracer and safe-recovery assertions are in place; the next plan owns host-selected offer continuity and trusted pricing terms.

---
*Phase: 235-customer-plan-selection-checkout*
*Completed: 2026-10-08*

## Self-Check: PASSED

- Summary file exists and coverage schema validation passed.
- Task commits `6ac9e5e0` and `19d63bf6` are ancestors of HEAD.
