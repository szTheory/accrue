---
phase: 233-shared-direction-portal-contract
reviewed: 2026-10-07T22:00:00Z
depth: standard
files_reviewed: 48
files_reviewed_list:
  - accrue/priv/accrue/templates/install/billing.ex.eex
  - accrue/priv/static/brand.css
  - accrue_admin/README.md
  - accrue_portal/README.md
  - accrue_portal/lib/accrue_portal/auth_hook.ex
  - accrue_portal/lib/accrue_portal/auth_plug.ex
  - accrue_portal/lib/accrue_portal/authorize.ex
  - accrue_portal/lib/accrue_portal/context.ex
  - accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex
  - accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex
  - accrue_portal/lib/accrue_portal/copy.ex
  - accrue_portal/lib/accrue_portal/customer_session.ex
  - accrue_portal/lib/accrue_portal/layouts.ex
  - accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex
  - accrue_portal/lib/accrue_portal/live/blocked_live.ex
  - accrue_portal/lib/accrue_portal/live/checkout_live.ex
  - accrue_portal/lib/accrue_portal/live/home_live.ex
  - accrue_portal/lib/accrue_portal/live/invoices_live.ex
  - accrue_portal/lib/accrue_portal/live/payment_methods_live.ex
  - accrue_portal/lib/accrue_portal/live/subscription_live.ex
  - accrue_portal/lib/accrue_portal/live/subscriptions_live.ex
  - accrue_portal/lib/accrue_portal/path.ex
  - accrue_portal/lib/accrue_portal/router.ex
  - accrue_portal/priv/static/accrue_portal.css
  - accrue_portal/priv/static/accrue_portal.js
  - accrue_portal/test/accrue_portal/auth_hook_test.exs
  - accrue_portal/test/accrue_portal/checkout_context_test.exs
  - accrue_portal/test/accrue_portal/context_contract_test.exs
  - accrue_portal/test/accrue_portal/context_live_test.exs
  - accrue_portal/test/accrue_portal/context_post_test.exs
  - accrue_portal/test/accrue_portal/live/checkout_live_discount_test.exs
  - accrue_portal/test/accrue_portal/live/checkout_live_test.exs
  - accrue_portal/test/accrue_portal/live/payment_methods_wrong_tenant_test.exs
  - accrue_portal/test/accrue_portal/live/subscription_live_test.exs
  - accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs
  - accrue_portal/test/accrue_portal/readme_contract_test.exs
  - accrue_portal/test/accrue_portal/router_test.exs
  - accrue_portal/test/support/tap_formatter.ex
  - examples/accrue_host/README.md
  - examples/accrue_host/e2e/phase233-baseline.spec.js
  - examples/accrue_host/e2e/phase233-context.spec.js
  - examples/accrue_host/e2e/phase233-semantic.spec.js
  - examples/accrue_host/lib/accrue_host/billing.ex
  - examples/accrue_host/lib/accrue_host/portal_context_adapter.ex
  - examples/accrue_host/lib/accrue_host_web/controllers/organization_scope_controller.ex
  - examples/accrue_host/lib/accrue_host_web/router.ex
  - examples/accrue_host/test/accrue_host_web/admin_mount_test.exs
  - scripts/ci/accrue_host_seed_e2e.exs
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 233: Code Review Report

**Reviewed:** 2026-10-07T22:00:00Z  
**Depth:** standard  
**Files Reviewed:** 48  
**Status:** issues_found

## Summary

Reviewed the Phase 233 portal context, authorization, checkout, host example, styles, documentation, and associated tests. One checkout transport mismatch blocks a supported personal checkout flow: LiveView permits the existing personal Customer's processor, but the rendered form's POST controller rejects that same session.

## Critical Issues

### CR-01: [BLOCKER] Checkout POST rejects supported personal legacy-processor sessions

**File:** `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex:99`  
**Issue:** `checkout_target?/2` unconditionally requires `checkout.processor == Processor.name()`. The paired `CheckoutLive.checkout_action_target?/3` intentionally applies that configured-processor restriction only when a custom context adapter is present (`checkout_live.ex:501-506`), preserving personal billing compatibility with a sole existing Customer whose processor differs from the currently configured processor. The LiveView can therefore render a valid pinned checkout form and issue its client token, but submitting that form to this controller fails the target check and is denied before subscription creation. The current POST coverage exercises custom-adapter checkouts, while the configured-processor mismatch coverage only asserts the custom checkout is disabled.

**Fix:** Make the POST target check use the same adapter-aware processor rule as `CheckoutLive.checkout_action_target?/3`: always require the pinned context processor to equal the LocalSession processor and the exact Customer to match; require `Processor.name()` only when `current_context_adapter` is configured. Add a personal legacy-processor rendered-form POST positive case while retaining the custom-adapter mismatch denial.

---

_Reviewed: 2026-10-07T22:00:00Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
