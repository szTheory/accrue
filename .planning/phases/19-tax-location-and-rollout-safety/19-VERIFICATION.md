---
phase: 19-tax-location-and-rollout-safety
verified: 2026-04-17T18:48:15Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
---

# Phase 19: Tax Location and Rollout Safety Verification Report

**Phase Goal:** Tax-enabled recurring billing cannot fail silently: customer location capture, immediate validation, invalid-location recovery, and legacy recurring-item migration guidance are explicit.
**Verified:** 2026-04-17T18:48:15Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Developers can set/update customer address or tax-location details through a public Accrue path before creating tax-enabled subscriptions. | ✓ VERIFIED | [`accrue/lib/accrue/billing.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex#L599) exposes `update_customer_tax_location/2` and forces `tax.validate_location = "immediately"` while persisting sanitized customer data; [`accrue/test/accrue/billing/tax_location_test.exs`](/Users/jon/projects/accrue/accrue/test/accrue/billing/tax_location_test.exs#L13) proves the public path works and strips raw address/tax fields. |
| 2 | Customer location validation failures produce actionable Accrue errors and documentation rather than hidden Stripe API failures. | ✓ VERIFIED | [`accrue/lib/accrue/processor/stripe/error_mapper.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/processor/stripe/error_mapper.ex#L101) maps `customer_tax_location_invalid` to stable repair copy with sanitized metadata only; [`accrue/lib/accrue/billing/subscription_actions.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex#L722) preflights automatic-tax subscription creation and returns the same stable error; tests in [`accrue/test/accrue/processor/stripe_test.exs`](/Users/jon/projects/accrue/accrue/test/accrue/processor/stripe_test.exs#L73) and [`accrue/test/accrue/billing/tax_location_test.exs`](/Users/jon/projects/accrue/accrue/test/accrue/billing/tax_location_test.exs#L67) lock the contract. |
| 3 | Invoice finalization failure or automatic-tax invalid-location states are visible in local projections, admin surfaces, or troubleshooting docs. | ✓ VERIFIED | [`accrue/lib/accrue/billing/subscription_projection.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_projection.ex#L17) and [`accrue/lib/accrue/billing/invoice_projection.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/billing/invoice_projection.ex#L56) persist `automatic_tax_disabled_reason` and `last_finalization_error_code`; [`accrue/lib/accrue/webhook/default_handler.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex#L113) reconciles `invoice.updated` and `invoice.finalization_failed`; admin and host views surface the state in [`accrue_admin/lib/accrue_admin/live/customer_live.ex`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex#L104), [`accrue_admin/lib/accrue_admin/live/subscription_live.ex`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex#L140), [`accrue_admin/lib/accrue_admin/live/invoice_live.ex`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/invoice_live.ex#L161), and [`examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex#L24). |
| 4 | Existing subscription rollout docs explain that enabling Stripe Tax/configuring automatic collection does not update existing subscriptions, invoices, or payment links automatically. | ✓ VERIFIED | [`guides/testing-live-stripe.md`](/Users/jon/projects/accrue/guides/testing-live-stripe.md#L75) explicitly says rollout is not retroactive for subscriptions, invoices, payment links, and existing customers without Checkout `customer_update[...]` flags; [`accrue/guides/troubleshooting.md`](/Users/jon/projects/accrue/accrue/guides/troubleshooting.md#L327) documents recovery order and recurring invalid-location states; doc tests in [`accrue/test/accrue/docs/tax_rollout_docs_test.exs`](/Users/jon/projects/accrue/accrue/test/accrue/docs/tax_rollout_docs_test.exs#L4) and [`accrue/test/accrue/docs/troubleshooting_guide_test.exs`](/Users/jon/projects/accrue/accrue/test/accrue/docs/troubleshooting_guide_test.exs#L42) lock the wording. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/lib/accrue/billing.ex` | Public tax-location update path | ✓ VERIFIED | Processor-backed update path exists and strips `address`, `shipping`, `phone`, and `tax` before local persistence. |
| `accrue/lib/accrue/processor/stripe/error_mapper.ex` | Stable sanitized invalid-location error mapping | ✓ VERIFIED | Keeps only `request_id`, `status`, `type`, and `code` in `processor_error`. |
| `accrue/lib/accrue/billing/subscription_actions.ex` | Immediate validation guard for automatic-tax subscribe | ✓ VERIFIED | Preflight validation and post-create invalid-state guard both present. |
| `accrue/priv/repo/migrations/20260417193000_add_tax_rollout_safety_columns.exs` | Queryable rollout-safety columns | ✓ VERIFIED | Adds `automatic_tax_disabled_reason` and `last_finalization_error_code`. |
| `accrue/lib/accrue/billing/subscription_projection.ex` | Subscription disabled-reason projection | ✓ VERIFIED | Projects `automatic_tax.disabled_reason` for string- and atom-keyed payloads. |
| `accrue/lib/accrue/billing/invoice_projection.ex` | Invoice disabled-reason and finalization-code projection | ✓ VERIFIED | Projects both fields into local attrs. |
| `accrue/lib/accrue/webhook/default_handler.ex` | Invoice rollback/finalization webhook reconciliation | ✓ VERIFIED | Handles `invoice.updated` and `invoice.finalization_failed`. |
| `accrue_admin` LiveViews + `examples/accrue_host` LiveView | Operator/user-facing invalid-location visibility and repair path | ✓ VERIFIED | Admin panels render local tax-risk state; host form routes through `AccrueHost.Billing.update_customer_tax_location/2`. |
| `accrue/guides/troubleshooting.md` and `guides/testing-live-stripe.md` | Rollout safety and recovery guidance | ✓ VERIFIED | Recovery order, recurring state names, and non-retroactive rollout caveats are explicit. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Accrue.Billing.update_customer_tax_location/2` | `Processor.update_customer/3` | Immediate tax-location validation | ✓ WIRED | [`accrue/lib/accrue/billing.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex#L603) passes nested tax attrs with `validate_location: "immediately"`. |
| `SubscriptionActions.subscribe/3` | Stable invalid-location Accrue error | Preflight + post-create guard | ✓ WIRED | [`accrue/lib/accrue/billing/subscription_actions.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex#L90) calls `ensure_customer_tax_location/2`; [`accrue/lib/accrue/billing/subscription_actions.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex#L737) maps invalid tax state to `%Accrue.APIError{code: "customer_tax_location_invalid"}`. |
| Webhook reducer | Local invoice projection | Canonical refetch + projection | ✓ WIRED | [`accrue/lib/accrue/webhook/default_handler.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex#L113) dispatches new invoice events; focused tests prove local invoice rows update. |
| Local invoice/subscription fields | Admin and host UI | LiveView render logic | ✓ WIRED | Admin reads local rows only; host renders `automatic_tax_disabled_reason` guidance and routes repair through the host facade. |
| Rollout docs | Guarding tests | String assertions | ✓ WIRED | Doc tests assert required Phase 19 wording stays present. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `accrue/lib/accrue/billing.ex` | Sanitized `customer.data` / `customer.tax_location_updated` event | `Processor.update_customer/3` result | Yes | ✓ FLOWING |
| `accrue/lib/accrue/billing/subscription_projection.ex` | `automatic_tax_disabled_reason` | Processor/Fake subscription payload | Yes | ✓ FLOWING |
| `accrue/lib/accrue/billing/invoice_projection.ex` | `automatic_tax_disabled_reason`, `last_finalization_error_code` | Canonical invoice payload | Yes | ✓ FLOWING |
| `accrue_admin` and host LiveViews | Tax-risk copy and repair messaging | Local `Subscription` / `Invoice` rows and host facade | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core tax-location, projection, webhook, docs, and subscription coverage | `cd accrue && mix test test/accrue/processor/stripe_test.exs test/accrue/processor/fake_test.exs test/accrue/billing/tax_location_test.exs test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/webhook/default_handler_test.exs test/accrue/docs/troubleshooting_guide_test.exs test/accrue/docs/tax_rollout_docs_test.exs test/accrue/billing/subscription_test.exs` | `77 tests, 0 failures` | ✓ PASS |
| Admin tax-risk visibility | `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/invoice_live_test.exs` | `5 tests, 0 failures` | ✓ PASS |
| Host repair flow and public-facade proof | `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs test/accrue_host_web/live/subscription_live_test.exs test/accrue_host_web/subscription_flow_test.exs` | `12 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| TAX-02 | 19-01, 19-02, 19-04 | Developer can collect and validate customer tax location before creating tax-enabled recurring payments. | ✓ SATISFIED | Public API in [`accrue/lib/accrue/billing.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex#L599); stable processor mapping in [`accrue/lib/accrue/processor/stripe/error_mapper.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/processor/stripe/error_mapper.ex#L101); host wrapper in [`examples/accrue_host/lib/accrue_host/billing.ex`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex#L48); focused tests in core and host packages. |
| TAX-03 | 19-03, 19-04 | User or admin can identify and recover from missing or invalid tax location states without silent tax rollout failure. | ✓ SATISFIED | Local fields and projections in [`accrue/lib/accrue/billing/subscription.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription.ex#L62), [`accrue/lib/accrue/billing/invoice.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/billing/invoice.ex#L62), webhook reconciliation in [`accrue/lib/accrue/webhook/default_handler.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex#L113), admin/host rendering and tests. |
| TAX-04 | 19-05 | Existing recurring subscriptions have explicit migration guidance before automatic tax rollout. | ✓ SATISFIED | Rollout caveats and Checkout flags are explicit in [`guides/testing-live-stripe.md`](/Users/jon/projects/accrue/guides/testing-live-stripe.md#L75) and locked by docs tests. |

### Anti-Patterns Found

No blocker or warning anti-patterns found in Phase 19 implementation scope. I did not find placeholder UI copy, unwired helpers, empty handlers, or static stub returns in the verified files.

### Residual Risk

Phase 19 itself verifies cleanly, but the repo still has unrelated full-suite failures outside this phase scope:

- `accrue`: residual failures tied to archived Phase 15/16 planning docs and a stale auth-adapter error-copy assertion.
- `examples/accrue_host`: unrelated Accounts test failures caused by `update_all` affecting multiple users/tokens.
- `accrue_admin`: full suite passes.

These do not block Phase 19 goal achievement because the Phase 19-focused suites above passed and the failing areas do not intersect the tax-location, projection, admin tax-risk, host repair, or rollout-doc paths verified here.

### Gaps Summary

No Phase 19 gaps found. The codebase contains a public customer tax-location update path, stable invalid-location error mapping, local and UI-visible recurring tax-risk state, and explicit rollout guidance for legacy recurring objects.

---

_Verified: 2026-04-17T18:48:15Z_
_Verifier: Claude (gsd-verifier)_
