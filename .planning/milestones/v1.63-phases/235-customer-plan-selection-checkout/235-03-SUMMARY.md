---
phase: 235-customer-plan-selection-checkout
plan: 03
subsystem: payments
tags: [phoenix, liveview, checkout, braintree, postgres, ecto]
requires:
  - phase: 235-02
    provides: Persisted selected offer, trusted terms, and sign-in return context
provides:
  - Atomic open-session claim and strict shared expiry eligibility for checkout submissions
  - Evidence-specific POST and LiveView outcomes, including uncertain provider/local persistence states
  - Promotion mapping revalidation on both browser submission paths
affects: [235-04, accrue_portal]
actuals:
  tokens: 10568
  tasks: 2
  commits: 3
plan_head_before: 6102a655e511e91763658a899f46056d960b0a7b
plan_head_after: 62f44afe010a6247630da3188b6abeed071aa9dc
tech-stack:
  added: []
  patterns:
    - Conditional database update claims each open session once before provider work
    - Unknown provider outcomes persist as uncertain and never reopen for replay
    - Promotion codes cross the form boundary as untrusted input and are checked against current mappings
key-files:
  created: []
  modified:
    - accrue/lib/accrue/checkout/local_session.ex
    - accrue/test/accrue/checkout/local_session_test.exs
    - accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex
    - accrue_portal/test/accrue_portal/checkout_context_test.exs
    - accrue_portal/lib/accrue_portal/live/checkout_live.ex
    - accrue_portal/test/accrue_portal/live/checkout_live_test.exs
    - accrue_portal/test/accrue_portal/live/checkout_live_discount_test.exs
key-decisions:
  - "Persist an atomic processing claim before either transport invokes Billing.subscribe; release it only for known rejection and retain uncertain outcomes as non-replayable."
  - "Use one LocalSession.actionable?/2 predicate for open-state and strict expires_at boundary checks, with the database claim repeating the expiry condition atomically."
  - "Carry the LiveView promotion selection in the real POST form and resolve it again immediately before the operation claim."
patterns-established:
  - "Provider errors without authoritative rejection evidence lead to status/support recovery, never a false no-payment claim or automatic retry."
  - "Fresh transport actions reload the persisted session and reauthorize the pinned host context before claiming work."
requirements-completed: [CKO-01, CKO-03, CKO-04]
coverage:
  - id: D1
    description: "Session claims permit one provider attempt, reject duplicate/concurrent claims, and are actionable only strictly before expiry."
    requirement: CKO-03
    verification:
      - kind: unit
        ref: accrue/test/accrue/checkout/local_session_test.exs#claim boundary and parallel claims
        status: pass
    human_judgment: false
  - id: D2
    description: "POST reloads and revalidates the persisted target and promotion, rejects stale context before provider work, and blocks replay after completion."
    requirement: CKO-03
    verification:
      - kind: integration
        ref: accrue_portal/test/accrue_portal/checkout_context_test.exs#POST stale promotion, replay, and accepted-but-unconfirmed cases
        status: pass
    human_judgment: false
  - id: D3
    description: "LiveView uses the same session claim and expiry rule, prevents a second view from submitting completed work, and keeps accepted-but-unconfirmed work in recovery."
    requirement: CKO-01
    verification:
      - kind: automated_ui
        ref: accrue_portal/test/accrue_portal/live/checkout_live_test.exs#two LiveViews and completion persistence uncertainty
        status: pass
    human_judgment: false
  - id: D4
    description: "The selected offer stays visible while the browser announces submission, and stale discount changes are handled before provider submission."
    requirement: CKO-04
    verification:
      - kind: automated_ui
        ref: accrue_portal/test/accrue_portal/live/checkout_live_discount_test.exs#submit-time drift revalidation
        status: pass
      - kind: automated_ui
        ref: accrue_portal/test/accrue_portal/live/checkout_live_test.exs#checkout hook loading and offer summary assertions
        status: pass
    human_judgment: false
metrics:
  duration: 10min
  completed: 2026-10-08
status: complete
---

# Phase 235 Plan 03: Safe Checkout Submission Summary

**Both checkout transports now claim one persisted operation, recheck current offer and host authorization, and preserve uncertainty after a provider side effect.**

## Performance

- **Duration:** About 10 minutes
- **Started:** 2026-10-08T12:04:00Z
- **Completed:** 2026-10-08T12:14:20Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added an atomic `open` → `processing` claim guarded by persisted status and strict expiry; only one sequential or concurrent request can begin provider work for a session.
- Bound POST to the persisted Customer, processor, offer, and trusted charge terms, freshly authorized the host action, and revalidated submitted promotion codes before claiming the session.
- Made both paths distinguish completed, expired, rejected, and uncertain outcomes. Generic provider errors and local completion persistence failures keep the session blocked and direct the customer to status/support without replay.
- Carried the LiveView promotion choice through the actual POST form and kept selected-offer context visible while the browser announces payment submission.
- Added deterministic tests for exact expiry boundaries, concurrent claims, duplicate LiveViews, stale promotion rejection, and accepted provider results followed by local completion failure. Provider behavior is represented by local stubs; no live-provider behavior is claimed.

## Task Commits

1. **Task 1: Make POST submission reentrant-safe and evidence-specific** — `c280b014`, `d92fc6be` (feature plus shared expiry/promotion correctness follow-up)
2. **Task 2: Apply equivalent state and outcome rules to LiveView submission** — `62f44afe`

**Measured plan commits:** 3 (`6102a655` through `62f44afe`).

## Files Created/Modified

- `accrue/lib/accrue/checkout/local_session.ex` — shared strict eligibility check, atomic session claim, and status transitions.
- `accrue/test/accrue/checkout/local_session_test.exs` — expiry boundary and parallel claim coverage.
- `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` — exact POST target/term validation, promotion revalidation, and evidence-specific responses.
- `accrue_portal/test/accrue_portal/checkout_context_test.exs` — trusted-term fixtures, POST replay, stale promotion, and accepted-but-unconfirmed cases.
- `accrue_portal/lib/accrue_portal/live/checkout_live.ex` — claimed provider submissions and distinct completed/uncertain recovery states.
- `accrue_portal/test/accrue_portal/live/checkout_live_test.exs` and `checkout_live_discount_test.exs` — duplicate-view, uncertainty, loading-context, and stale-promotion coverage.

## Decisions Made

- A successful provider response is not shown as success until the local session completion update succeeds; failure remains uncertain and non-replayable.
- Only a typed card rejection or explicit promotion validation failure releases the claim. Generic Braintree errors remain uncertain because their broad HTTP 400 mapping does not prove rejection.
- Fake/Braintree test doubles provide deterministic local evidence. The implementation does not claim live-provider reconciliation behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Complete checkout context fixtures with trusted terms**
- **Found during:** Task 1 focused controller tests
- **Issue:** Existing context fixtures no longer met the trusted offer-term contract established in Plan 235-02, so the checkout form could not mount and the focused POST tests failed before reaching the behavior under test.
- **Fix:** Updated the named Portal context fixtures with complete matching amount, currency, interval, processor, and billable metadata.
- **Files modified:** `accrue_portal/test/accrue_portal/checkout_context_test.exs`
- **Verification:** Focused context suite passed (13 tests).
- **Committed in:** `c280b014`

**2. [Rule 2 - Missing Critical] Revalidate the promotion on the actual POST path**
- **Found during:** Task 2 transport review
- **Issue:** The visible LiveView promotion preview was not included in the browser's actual POST form, so POST could submit different terms from the displayed total and could not detect stale mappings.
- **Fix:** Included the selected code as an untrusted form field and resolved it against the current mapping before claiming or calling the provider.
- **Files modified:** `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex`, `accrue_portal/lib/accrue_portal/live/checkout_live.ex`, and the corresponding context/discount tests.
- **Verification:** Stale promotion test confirms the session remains open and provider call count stays zero; all focused Portal suites passed.
- **Committed in:** `d92fc6be`, `62f44afe`

**3. [Rule 1 - Bug] Remove unsupported certainty from generic checkout errors**
- **Found during:** Task 2 outcome review
- **Issue:** The previous generic LiveView error claimed a card had been charged even when no authoritative result was available, and replay/uncertainty paths could imply nothing had been submitted.
- **Fix:** Rendered distinct completed, unavailable, and uncertain outcomes; uncertain guidance blocks another payment action and directs the customer to status/support.
- **Files modified:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex`
- **Verification:** Accepted-but-unconfirmed persistence tests passed through both POST and LiveView.
- **Committed in:** `62f44afe`

**Total deviations:** 3 auto-fixed (one Rule 1, one Rule 2, one Rule 3). All corrections support the planned payment-state contract.

## Verification

- `cd accrue && mix test test/accrue/checkout/local_session_test.exs` — **8 tests, 0 failures**.
- `cd accrue_portal && mix test test/accrue_portal/checkout_context_test.exs` — **13 tests, 0 failures**.
- `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs test/accrue_portal/live/checkout_live_discount_test.exs test/accrue_portal/checkout_context_test.exs` — **26 tests, 0 failures**.
- `git diff --check` — passed.

## Known Stubs

None. The provider stubs are deterministic test fixtures, not production runtime paths.

## Issues Encountered

- Git metadata writes were denied by the workspace sandbox on the first commit attempt. The supplied-root and branch checks passed; the authorized commit succeeded through the escalation path. No source or user-owned planning files were discarded.
- `roadmap.update-plan-progress 235` returned `missing_phase_details` without modifying ROADMAP.md. The phase section and progress row exist, but the handler only considers content after the last archived `<details>` block, while the active phase appears before those blocks. I left ROADMAP.md unchanged rather than bypass the registered writer. The shared-ID readiness check returned 0/3 because Plan 235-04 also declares these requirements, so their global checkboxes remain pending.

## User Setup Required

None. All verification uses the repository's local ExUnit and provider test doubles.

## Next Phase Readiness

Plan 235-04 can build on the shared persisted-session and outcome contract. Checkout submission remains blocked after an uncertain provider result until an authoritative status/support resolution is available.

## Self-Check: PASSED

- All seven plan-owned implementation and test files exist.
- Task commits `c280b014`, `d92fc6be`, and `62f44afe` are ancestors of the current HEAD.
- The measured plan ledger records base `6102a655e511e91763658a899f46056d960b0a7b`, three commits, and head `62f44afe010a6247630da3188b6abeed071aa9dc`.

---
*Phase: 235-customer-plan-selection-checkout*
*Completed: 2026-10-08*
