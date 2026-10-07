---
phase: 233-shared-direction-portal-contract
plan: 02
subsystem: payments
tags: [phoenix, liveview, signed-context, braintree, authorization]
requires:
  - phase: 233-01
    provides: Host context resolution and fresh action-policy contract
provides:
  - Short-lived signed payment-flow pins bound to billable, processor, and Customer identity
  - Fresh authorization for create, default, and delete payment-method operations
  - Rendered payment forms that retain their original context across tab changes
affects: [portal, checkout, payment-methods, host-context-adapters]
actuals:
  tokens: 14871
  tasks: 2
  commits: 5
commits: 5
plan_head_before: a948e193245c73ffc773c30002494fe1cfb80b7d
plan_head_after: 12f33a475ea9dde7f4bed47a2f34d17997867075
tech-stack:
  added: []
  patterns: [Phoenix.Token signed locator with fresh server-side resolution, named per-operation authorization]
key-files:
  created:
    - accrue_portal/test/accrue_portal/context_post_test.exs
  modified:
    - accrue_portal/lib/accrue_portal/context.ex
    - accrue_portal/lib/accrue_portal/customer_session.ex
    - accrue_portal/lib/accrue_portal/auth_plug.ex
    - accrue_portal/lib/accrue_portal/auth_hook.ex
    - accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex
    - accrue_portal/lib/accrue_portal/live/payment_methods_live.ex
    - accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex
    - accrue_portal/priv/static/accrue_portal.js
    - accrue_portal/test/accrue_portal/live/payment_methods_wrong_tenant_test.exs
    - accrue_portal/lib/accrue_portal/copy.ex
decisions:
  - Signed pins are locators only; every POST re-resolves the actor, host policy, and exact Customer before authorization.
  - Personal mode keeps its supported cross-processor Customer compatibility while custom billables require the configured processor.
  - Payment-method writes run with the actual signed-in human actor attribution.
metrics:
  duration: 26min
  completed: 2026-10-07
status: complete
requirements-completed: [POR-08, SAFE-02, SAFE-03]
coverage:
  - id: D1
    description: Rendered default, delete, and add-card forms submit signed pins and remain bound to their original billing identity.
    requirement: POR-08
    verification:
      - kind: integration
        ref: accrue_portal/test/accrue_portal/context_post_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Invalid, expired, revoked, mismatched, and foreign-target payment requests are denied without writes; create denial issues no Braintree client token.
    requirement: SAFE-02
    verification:
      - kind: integration
        ref: accrue_portal/test/accrue_portal/context_post_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Hosted Fields clears pending secure state on invalidation and submits a nonce through the pinned create form.
    requirement: SAFE-03
    verification:
      - kind: other
        ref: node --check accrue_portal/priv/static/accrue_portal.js
        status: pass
    human_judgment: false
---

# Phase 233 Plan 02: Payment Form Context Pins Summary

**Default, delete, and create payment flows now submit short-lived signed context locators, then re-resolve current host policy and exact billing identity before any operation.**

## Performance

- **Duration:** 26 minutes
- **Started:** 2026-10-07T16:19:26-04:00
- **Completed:** 2026-10-07T16:45:00-04:00
- **Tasks:** 2
- **Files modified or created:** 17

## Accomplishments

- Added 20-minute Phoenix.Token pins covering owner type/id, processor, and Customer ID. Pins locate context but never grant authority.
- Bound all three rendered payment-method POSTs to their original context and added fresh named authorization before mutation.
- Gated Braintree client-token issuance on create authorization and cleared Hosted Fields pending state when the flow is invalidated.
- Added real rendered-form-to-router integration coverage for positive mutations, tab switching, revocation, forged/expired pins, wrong targets, and zero-token/zero-write denials.

## Task Commits

1. **Task 1, RED:** `07b626df` — failing rendered default/delete pin and denial tests.
2. **Task 1, GREEN:** `1132b6c7` — pin default/delete flows and freshly authorize targets.
3. **Task 2, RED:** `22f89c33` and `1315bc15` — failing create-authorization and rendered create form tests.
4. **Task 2, GREEN:** `12f33a47` — authorize add-card before token issuance and connect pinned create submission.

## TDD Gate Compliance

- RED evidence: `.planning/phases/233-shared-direction-portal-contract/233-02-T1-RED.tap`, `233-02-T2-RED.tap`, and `233-02-T2-create-RED.tap`; each was classified `RED_EVIDENCE_OK` before implementation.
- GREEN evidence: final integration suite passed with 52 tests and 0 failures. The T1 producer/POST suite passed after `1132b6c7`; the full three-action suite passed after `12f33a47`.
- Plan-wide checks also passed: `mix compile --warnings-as-errors`, `mix test --warnings-as-errors`, `node --check accrue_portal/priv/static/accrue_portal.js`, and `git diff --check`.

## Decisions Made

- Each payment form carries a signed locator in `context_pin`; POST handlers still reload the current actor, host membership/policy, Customer, and target.
- For old tabs, an authorized original context remains usable after host selection changes; revoked or invalid pins safely block without falling back to the new selection.
- Preserve personal single-Customer cross-processor compatibility from plan 233-01, while enforcing the configured processor for custom billables.

## Deviations from Plan

None. No dependencies or schema changes were introduced.

## Issues Encountered

An initial transient full-suite failure in an existing custom-endpoint context contract test passed on isolated, combined, and final Portal suite reruns; no unresolved issue remains.

## User Setup Required

None.

## Next Phase Readiness

The shared payment-method pin and named-action contract is ready for the remaining Phase 233 routes and checkout integrations.

## Self-Check: PASSED

The summary file exists, all five task commits are ancestors of the recorded plan head, and the implementation plus final Portal suite are verified.

---
*Phase: 233-shared-direction-portal-contract*
*Completed: 2026-10-07*
