---
phase: 236-portal-billing-self-service
plan: 02
subsystem: payments
tags: [portal, payment-methods, braintree-hosted-fields, phoenix-liveview, exunit]

# Dependency graph
requires: [236-01]
provides:
  - Customer-scoped card reads, supported owner-authorized actions, and truthful POST outcomes.
  - Direct authorized Hosted Fields entry with nonce clearing across failure, patch, and teardown.
affects: [portal-billing-self-service, payment-method-access, hosted-fields]

actuals:
  tokens: 10614
  tasks: 2
  commits: 2
plan_head_before: f9ef76518be5dab2cdcc13c906157c653fb5e9d9
plan_head_after: b628c711aa684c7bdfde232864eff34a55f239a2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Render card actions only when the configured provider supports them and the selected owner grants them."
    - "Use explicit empty, unavailable, and unsupported outcomes for card reads."
    - "Clear single-use Hosted Fields nonce state on LiveView update and teardown."

key-files:
  created: []
  modified:
    - accrue/lib/accrue/processor/fake.ex
    - accrue/lib/accrue/processor/stripe.ex
    - accrue_portal/lib/accrue_portal/billing_read_model.ex
    - accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex
    - accrue_portal/lib/accrue_portal/copy.ex
    - accrue_portal/lib/accrue_portal/live/payment_methods_live.ex
    - accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex
    - accrue_portal/priv/static/accrue_portal.js
    - accrue_portal/test/accrue_portal/context_post_test.exs
    - accrue_portal/test/accrue_portal/live/payment_methods_live_test.exs
    - accrue_portal/test/accrue_portal/live/add_payment_method_live_test.exs

key-decisions:
  - "Match displayed actions and POST authorization to both the selected owner and the configured provider capability."
  - "Require changing the account default before deleting a default card when another saved card exists."
  - "Use Braintree Hosted Fields only for Braintree and deterministic Fake contexts; Stripe direct add-card remains unavailable until its own secure entry flow exists."
  - "Keep card reads distinct as successful, unavailable, or unsupported so operational failures never render as an empty list."

requirements-completed: [POR-01, POR-02, POR-04, POR-05]

coverage:
  - id: D1
    description: "The payment-method page identifies the billed entity and renders zero, one, or several cards only for the authorized Customer."
    requirement: POR-01
    verification:
      - kind: integration
        ref: "test/accrue_portal/live/payment_methods_live_test.exs#payment methods page renders only the current customer's cards and actions"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/payment_methods_live_test.exs#successful empty card reads show the empty state"
        status: pass
    human_judgment: false
  - id: D2
    description: "Failed and unsupported card reads are distinct from successful empty results, and actions appear only for provider-supported owner grants."
    requirement: POR-02
    verification:
      - kind: integration
        ref: "test/accrue_portal/live/payment_methods_live_test.exs#failed payment method reads render unavailable instead of an empty list"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/context_post_test.exs#payment method actions appear only when the selected owner grants them"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/payment_methods_live_test.exs#add card is hidden when the selected processor differs from the configured provider"
        status: pass
    human_judgment: false
  - id: D3
    description: "Default/delete actions disclose the billed identity, card, and consequence; exact-owner POST checks remain authoritative."
    requirement: POR-02
    verification:
      - kind: integration
        ref: "test/accrue_portal/context_post_test.exs#payment method actions appear only when the selected owner grants them"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/context_post_test.exs#rendered default and delete forms carry a context pin accepted by their POSTs"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/context_post_test.exs#missing and forged pins block payment method writes"
        status: pass
    human_judgment: false
  - id: D4
    description: "Direct add-card navigation renders only supported Hosted Fields, keeps raw card entry outside app inputs, and reports actual controller results."
    requirement: POR-04
    verification:
      - kind: integration
        ref: "test/accrue_portal/live/add_payment_method_live_test.exs#add payment method page renders the hosted-fields form for the signed-in customer"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/add_payment_method_live_test.exs#direct add-card navigation explains when Hosted Fields do not support the processor"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/context_post_test.exs#failed card saves announce the processor result and create no card"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-10-08
status: complete
---

# Phase 236 Plan 02: Payment Method Self-Service Summary

**Customers see only supported, authorized card actions, understand their consequences, and can enter cards through an authorized secure-field route.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-10-08T16:38:56Z
- **Completed:** 2026-10-08T16:53:55Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added explicit successful, unavailable, and unsupported card-list outcomes; database read failures now produce an announced unavailable state instead of an empty list.
- Displayed the billed identity and card identity in action confirmations. Owner grants and configured provider capabilities gate each action, and deleting a default card with another saved card first requires selecting the replacement.
- Rejected provider-mismatched payment actions at POST time. Fake and Stripe capability declarations now match their already-implemented payment-method operations.
- Restricted the Braintree Hosted Fields route to Braintree/Fake contexts, disabled submit until secure fields initialize, disclosed the billed identity, and cleared the nonce on LiveView updates and teardown.
- Added deterministic empty/failure/unsupported, owner-grant, exact-target, direct-route, and result-announcement coverage.

## Task Commits

1. **Task 1: Confirm and execute supported card actions** - `ae9e26c1` (`feat`)
2. **Task 2: Open direct add-card route with secure fields** - `b628c711` (`fix`)

## Deviations from Plan

### Auto-fixed Issues

**1. Capability declarations omitted existing Fake and Stripe payment-method operations**
- **Found during:** Task 1 (Confirm and execute supported card actions)
- **Issue:** The action gate would hide operations already implemented by Fake and Stripe because their capability maps only declared vault acquisition and listing.
- **Fix:** Declared the existing create, update, delete, and set-default operations in both provider maps, matching the processor support matrix.
- **Files modified:** `accrue/lib/accrue/processor/fake.ex`, `accrue/lib/accrue/processor/stripe.ex`
- **Verification:** The payment-method LiveView test checks the declared capabilities, and the focused package tests passed.

**2. Default-card deletion can require replacement first**
- **Found during:** Task 1 (Confirm and execute supported card actions)
- **Issue:** The existing billing mutation rejects removal of a default card while another saved card exists.
- **Fix:** Hide that delete action and explain that the customer can set another card as default first.
- **Files modified:** `accrue_portal/lib/accrue_portal/live/payment_methods_live.ex`, `accrue_portal/lib/accrue_portal/copy.ex`
- **Verification:** Owner-action integration coverage asserts the default card has no delete form until the default changes.

## Issues Encountered

The GSD roadmap progress writer has the previously recorded active-section scoping issue documented in 236-01; no roadmap edit was attempted here.

## User Setup Required

None. Deterministic Fake fixtures cover recurring acceptance; live provider credentials are not required.

## Automated Evidence

- `cd accrue_portal && mix test test/accrue_portal/live/payment_methods_live_test.exs test/accrue_portal/live/add_payment_method_live_test.exs test/accrue_portal/context_post_test.exs` - 18 tests, 0 failures.
- `node --check accrue_portal/priv/static/accrue_portal.js` - passed.
- `mix format` on the changed Elixir files and `git diff --check` - passed.
- No manual UAT is needed for these deterministic claims. Served-browser proof for the hooked JS lifecycle remains in Plan 236-05.

## Next Plan Readiness

Plan 236-04 (checkout outcomes and safe returns) is ready. Plan 236-03 remains dependent on 236-02. Wave 2's package gate runs after both 236-02 and 236-04.

---
*Phase: 236-portal-billing-self-service*
*Completed: 2026-10-08*

## Self-Check: PASSED

- GSD summary validation passed.
- All four deliverables classify as automatically covered.
- Task commits `ae9e26c1` and `b628c711` are ancestors of the recorded plan head.
