---
phase: 235-customer-plan-selection-checkout
reviewed: 2026-10-08T12:46:13Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - accrue/lib/accrue/checkout.ex
  - accrue/lib/accrue/checkout/local_session.ex
  - accrue/test/accrue/checkout/local_session_test.exs
  - accrue/test/accrue/checkout_test.exs
  - accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex
  - accrue_portal/lib/accrue_portal/live/checkout_live.ex
  - accrue_portal/priv/static/accrue_portal.css
  - accrue_portal/priv/static/accrue_portal.js
  - accrue_portal/test/accrue_portal/checkout_context_test.exs
  - accrue_portal/test/accrue_portal/live/checkout_live_discount_test.exs
  - accrue_portal/test/accrue_portal/live/checkout_live_test.exs
  - examples/accrue_host/config/runtime.exs
  - examples/accrue_host/e2e/phase233-braintree-checkout.spec.js
  - examples/accrue_host/lib/accrue_host_web/components/layouts/root.html.heex
  - examples/accrue_host/lib/accrue_host_web/controllers/page_controller.ex
  - examples/accrue_host/lib/accrue_host_web/controllers/user_session_controller.ex
  - examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex
  - examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs
  - scripts/ci/accrue_host_seed_e2e.exs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 235: Code Review Report

**Reviewed:** 2026-10-08T12:46:13Z  
**Depth:** standard  
**Files Reviewed:** 19  
**Status:** issues_found

## Summary

Reviewed the checkout facade, local Braintree checkout, portal submission path, and host plan-selection return flow. One offered plan cannot complete checkout, and successful Braintree checkouts cannot be confirmed by the host return handler.

## Critical Issues

### CR-01: Zero-priced plan submissions are rejected

**Severity:** BLOCKER  
**File:** `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex:144-146`  
**Issue:** The host offers the `metered` plan with `unit_amount_minor: 0` and creates a checkout session with that amount (`examples/accrue_host/lib/accrue_host/billing/plans.ex:56-60`, `examples/accrue_host/lib/accrue_host/live/subscription_live.ex:297-305`). The portal LiveView accepts zero as valid (`accrue_portal/lib/accrue_portal/live/checkout_live.ex:666-670`), but the actual hosted form submits to `CheckoutController.complete/2`, whose `checkout_terms_match?/2` requires `amount_minor > 0`. Therefore this plan always fails `checkout_target?/2` and is denied before `Billing.subscribe/3` runs.
**Fix:** Accept zero consistently for plans that support zero-priced subscriptions, or route zero-priced plans through an explicit no-payment subscription flow. Keep the amount validation consistent between the LiveView and controller.

## Warnings

### WR-01: Braintree completion returns an unverifiable Stripe placeholder

**Severity:** WARNING  
**File:** `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:336-339`  
**Issue:** The success URL always includes Stripe's `{CHECKOUT_SESSION_ID}` placeholder. For Braintree, `checkout_session_create/2` persists a `LocalSession` and returns a portal URL (`accrue/lib/accrue/processor/braintree.ex:382-387, 1039-1059`); the portal completion handler redirects to the stored success URL verbatim (`accrue_portal/lib/accrue_portal/live/checkout_live.ex:128-132`). Braintree never substitutes the Stripe placeholder. The host then accepts only `cs_...` session IDs and reconciles only sessions with status `complete` (`examples/accrue_host/lib/accrue_host/live/subscription_live.ex:355`, `accrue/lib/accrue/checkout.ex:58-60`). The Braintree local session has a UUID ID and status `completed`, so the successful payment always lands in the unverifiable-return state even though the subscription was created.
**Fix:** Build a Braintree success URL with a local session identifier and teach the host to verify the local session's `completed`/`paid` state, or have the portal construct a processor-specific success return that does not use Stripe's placeholder.

---

_Reviewed: 2026-10-08T12:46:13Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
