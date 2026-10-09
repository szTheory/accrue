---
phase: 233-shared-direction-portal-contract
plan: 07
subsystem: payments
tags: [phoenix, liveview, braintree, checkout, authorization, context-pin]
requires:
  - phase: 233-02
    provides: Signed context-pin verification and fresh host context resolution.
provides:
  - Checkout token issuance and LiveView completion require fresh authority for the pinned LocalSession and Customer.
  - Rendered Hosted Fields checkout posts its signed context pin, CSRF token, and tokenized nonce through the existing completion route.
  - Checkout POST denies missing, forged, expired, revoked, mismatched, completed, or replayed targets before provider mutation.
affects: [233-05, 235, checkout, portal-authorization]
actuals:
  tokens: 14335
  tasks: 2
  commits: 4
plan_head_before: e054860c957c00118d1dcd2228b40584f8a778c6
plan_head_after: a2affdb2b05df94bb1be3b29989cfa3b16e6061b
tech-stack:
  added: []
  patterns: [server-revalidated-checkout-pin, authorized-token-issuance, nonce-only-native-checkout-post]
key-files:
  created:
    - accrue_portal/test/accrue_portal/checkout_context_test.exs
    - .planning/phases/233-shared-direction-portal-contract/233-07-T1-RED.json
    - .planning/phases/233-shared-direction-portal-contract/233-07-T1-RED.tap
    - .planning/phases/233-shared-direction-portal-contract/233-07-T2-RED.json
    - .planning/phases/233-shared-direction-portal-contract/233-07-T2-RED.tap
  modified:
    - accrue_portal/lib/accrue_portal/context.ex
    - accrue_portal/lib/accrue_portal/copy.ex
    - accrue_portal/lib/accrue_portal/auth_plug.ex
    - accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex
    - accrue_portal/lib/accrue_portal/live/checkout_live.ex
    - accrue_portal/priv/static/accrue_portal.js
    - accrue_portal/test/accrue_portal/live/checkout_live_test.exs
    - accrue_portal/test/accrue_portal/live/checkout_live_discount_test.exs
key-decisions:
  - "Keep checkout completion and promo validation as separate host actions; only checkout_complete permits token issuance or subscription mutation."
  - "Use the rendered form pin for both transports; the Hosted Fields hook sends a nonce-only native POST for the rendered POST form, while the LiveView event remains independently pin-checked."
  - "Normalize the authenticated human into Accrue.Actor's explicit user actor shape before billing writes."
patterns-established:
  - "Checkout POSTs resolve the signed pin at the auth boundary and independently re-resolve it in the controller before target checks and mutation."
  - "Provider capability is issued only after the exact server-loaded checkout target passes freshness and completion policy checks."
requirements-completed: [POR-08, SAFE-02, SAFE-03]
coverage:
  - id: D1
    description: "Checkout reads that lack completion authority receive no client token or Hosted Fields; an authorized rendered pin completes only its displayed LocalSession with the human actor recorded."
    requirement: SAFE-02
    verification:
      - kind: integration
        ref: "accrue_portal/test/accrue_portal/checkout_context_test.exs#read-only checkout mount and rendered checkout LiveView event"
        status: pass
    human_judgment: false
  - id: D2
    description: "The rendered checkout form submits its context pin, CSRF token, and nonce through the real completion POST route; missing, forged, expired, revoked, switched, foreign, completed, and replayed contexts do not make unauthorized provider calls."
    requirement: SAFE-03
    verification:
      - kind: integration
        ref: "accrue_portal/test/accrue_portal/checkout_context_test.exs#rendered checkout form POST, old-tab, revocation, foreign target, expiry, and replay cases"
        status: pass
      - kind: unit
        ref: "cd accrue_portal && HEX_HOME=/tmp/accrue-233-hex mix test --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D3
    description: "Portal personal and organization checkout retain a common pinned flow without introducing host-specific billing UI or a new dependency."
    requirement: POR-08
    verification:
      - kind: integration
        ref: "accrue_portal/test/accrue_portal/checkout_context_test.exs#personal-compatible and organization checkout context coverage"
        status: pass
    human_judgment: false
duration: 17min
completed: 2026-10-07
status: complete
---

# Phase 233 Plan 07: Pinned Checkout Completion Summary

**Hosted Fields checkout now carries its rendered context pin through LiveView and HTTP completion, with fresh authorization before token issuance or provider mutation.**

## Performance

- **Duration:** 17 minutes
- **Started:** 2026-10-07T21:10:17Z
- **Completed:** 2026-10-07T21:27:41Z
- **Tasks:** 2 / 2
- **Files changed:** 13, including source, regression tests, and RED evidence

## Accomplishments

- Kept checkout read, promo validation, and checkout completion as separate named actions. A read-authorized organization with no completion grant received zero Braintree tokens and no Hosted Fields form.
- Revalidated the pinned context and exact server-loaded LocalSession, Customer, configured processor, selected subscription item, expiry, and open status before checkout completion. Subscription writes run under the normalized human actor.
- Added a POST-compatible rendered checkout form with CSRF, context pin, and nonce fields. The official Hosted Fields SDK remains in place; it submits the tokenized nonce through the protected POST route and clears it on teardown. The LiveView event path independently consumes the rendered pin.
- Added positive and zero-write regressions for successful POST, missing/forged/expired pins, read-only authority, switched selection, revoked access, foreign target, and replay.

## Task Commits

1. **Task 1 RED: checkout context authorization tests** — `60cce572` (`test`).
2. **Task 1 GREEN: pin-authorized checkout LiveView** — `17c22370` (`feat`).
3. **Task 2 RED: rendered checkout POST tests** — `12a06672` (`test`).
4. **Task 2 GREEN: pin-authorized checkout POST** — `a2affdb2` (`feat`).

The plan contains four task commits, measured from `plan_head_before` through `plan_head_after`.

## Files Created/Modified

- `accrue_portal/test/accrue_portal/checkout_context_test.exs` — rendered-pin LiveView and real HTTP completion integration coverage, including positive and denied controls.
- `accrue_portal/lib/accrue_portal/live/checkout_live.ex` — fresh target/action checks, pinned form fields, and client-token gating.
- `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` — fresh pin, target, action, expiry, and idempotency checks before subscription.
- `accrue_portal/lib/accrue_portal/auth_plug.ex` — requires and resolves the rendered pin for checkout POSTs.
- `accrue_portal/priv/static/accrue_portal.js` — posts the Hosted Fields nonce with the rendered pin; preserves the alternate tokenized event payload path.
- `accrue_portal/lib/accrue_portal/context.ex`, `copy.ex` — distinct completion and promo actions and denied-checkout copy.
- `accrue_portal/test/accrue_portal/live/checkout_live_test.exs`, `checkout_live_discount_test.exs` — compatibility fixtures use actual rendered pins.
- `233-07-T1-RED.json`, `233-07-T1-RED.tap`, `233-07-T2-RED.json`, `233-07-T2-RED.tap` — validated fail-first evidence for both TDD tasks.

## TDD Gate Compliance

- **Task 1 RED:** `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` for the zero-token authorization regression; the target failed before implementation. Task 1 GREEN passed 10 focused checkout tests.
- **Task 2 RED:** `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` for the missing rendered POST contract; 3 other focused tests passed. Task 2 GREEN passed 23 checkout and context POST tests.
- **Overall verification:** Portal test suite passed 66 tests with 0 failures. Compile with warnings as errors, format check, JavaScript syntax check, and `git diff --check` passed.

## Decisions Made

- Only `:checkout_complete` permits token issuance and subscription mutation; `:checkout_validate_promo` remains separate.
- The rendered pin is the authority locator for both completion transports, and is resolved against current host policy before action.
- Billing event attribution uses the authenticated human's explicit `:user` actor identity.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Security] Resolve checkout POST pins in the authentication boundary**
- **Found during:** Task 2
- **Issue:** The existing AuthPlug used mutable session selection for checkout POSTs before the controller ran.
- **Fix:** Require and resolve `context_pin` for checkout completion POSTs, then provide the configured context session keys for the controller's independent fresh resolution.
- **Files modified:** `accrue_portal/lib/accrue_portal/auth_plug.ex`
- **Verification:** Missing, forged, expired, switched, and revoked pin integration cases pass with zero provider calls.
- **Committed in:** `a2affdb2`

**2. [Rule 1 - Compatibility] Normalize the authenticated user for event attribution**
- **Found during:** Task 2
- **Issue:** The host's authenticated user struct is not itself the `Accrue.Actor` map required by the event ledger.
- **Fix:** Convert its actor ID into the same explicit `:user` actor form used by the existing LiveView and payment-method controller paths.
- **Files modified:** `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex`
- **Verification:** The real POST positive control creates a subscription and observes the human user actor in the gateway event.
- **Committed in:** `a2affdb2`

**Total deviations:** 2 auto-fixed correctness/security adjustments. Both directly support the plan's pin and human-actor requirements.

## Issues Encountered

- The first POST positive-control run found that Phoenix requires absolute success URLs to use `redirect(external: ...)`; the controller now permits safe HTTPS destinations and valid local paths, with an app-local fallback for invalid destinations.
- The existing checkout hook source regression expected the tokenized LiveView event payload. The hook retains that payload path for non-POST forms while the rendered checkout form submits its nonce through the POST route.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The checkout flow now uses the shared context contract and supports both pinned completion transports. No new dependency or schema change is needed for downstream checkout work.

---
*Phase: 233-shared-direction-portal-contract*
*Completed: 2026-10-07*

## Self-Check: PASSED

- Plan task commits `60cce572`, `17c22370`, `12a06672`, and `a2affdb2` are ancestors of the recorded plan head.
- The T1 and T2 RED evidence records both classify as `RED_EVIDENCE_OK`.
- Full Portal tests, compile, formatter, JavaScript syntax, and diff checks passed.
