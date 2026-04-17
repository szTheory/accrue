---
phase: 19
slug: tax-location-and-rollout-safety
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-17
---

# Phase 19 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `examples/accrue_host/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/processor/stripe_test.exs test/accrue/processor/fake_test.exs test/accrue/billing/tax_location_test.exs test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/webhook/default_handler_test.exs test/accrue/docs/troubleshooting_guide_test.exs test/accrue/docs/tax_rollout_docs_test.exs` |
| **Full suite command** | `cd accrue && mix test && cd ../accrue_admin && mix test && cd ../examples/accrue_host && mix test` |
| **Estimated runtime** | ~120-300 seconds |

---

## Sampling Rate

- **After every task commit:** Run the plan-local `<automated>` command from the active PLAN file in its package context.
- **After every plan wave:** Run package-local full suites for the packages touched in that wave.
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 300 seconds

---

## Plan Verification Map

| Plan | Wave | Requirements | Files / Commands | Secure Behavior | Status |
|------|------|--------------|------------------|-----------------|--------|
| 19-01 | 1 | TAX-02 | `accrue/lib/accrue/processor/stripe.ex`, `accrue/lib/accrue/processor/stripe/error_mapper.ex`, `accrue/lib/accrue/processor/fake.ex`, `accrue/test/accrue/processor/stripe_test.exs`, `accrue/test/accrue/processor/fake_test.exs`.<br>`cd accrue && mix test test/accrue/processor/stripe_test.exs`<br>`cd accrue && mix test test/accrue/processor/fake_test.exs` | Address PII is sanitized before invalid tax-location errors cross the public API boundary, and Fake reproduces deterministic invalid-location states. | pending |
| 19-02 | 2 | TAX-02 | `accrue/lib/accrue/billing.ex`, `accrue/test/accrue/billing/tax_location_test.exs`.<br>`cd accrue && mix test test/accrue/billing/tax_location_test.exs` | Public customer tax-location updates go through the processor with immediate validation while local customer persistence strips raw address/shipping/phone data. | pending |
| 19-03 | 1 | TAX-03 | `accrue/priv/repo/migrations/20260417193000_add_tax_rollout_safety_columns.exs`, `accrue/lib/accrue/billing/subscription.ex`, `accrue/lib/accrue/billing/invoice.ex`, `accrue/lib/accrue/billing/subscription_projection.ex`, `accrue/lib/accrue/billing/invoice_projection.ex`, `accrue/lib/accrue/webhook/default_handler.ex`, `accrue/test/accrue/billing/subscription_projection_tax_test.exs`, `accrue/test/accrue/billing/invoice_projection_test.exs`, `accrue/test/accrue/webhook/default_handler_test.exs`.<br>`cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/webhook/default_handler_test.exs` | Invalid-location rollback and finalization failures are projected into narrow local fields and reconciled through explicit webhook handlers without exposing raw provider error payloads. | pending |
| 19-04 | 3 | TAX-02, TAX-03 | `accrue_admin/lib/accrue_admin/live/customer_live.ex`, `accrue_admin/lib/accrue_admin/live/subscription_live.ex`, `accrue_admin/lib/accrue_admin/live/invoice_live.ex`, `accrue_admin/test/accrue_admin/live/customer_live_test.exs`, `accrue_admin/test/accrue_admin/live/subscription_live_test.exs`, `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`.<br>`cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/invoice_live_test.exs`<br><br>`examples/accrue_host/lib/accrue_host/billing.ex`, `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`, `examples/accrue_host/test/accrue_host/billing_facade_test.exs`, `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs`.<br>`cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs test/accrue_host_web/live/subscription_live_test.exs` | Admin and host package scopes are verified independently; admin uses local projections only, and the host repair flow stays on public Accrue APIs without direct Stripe reads or writes. | pending |
| 19-05 | 3 | TAX-04 | `accrue/guides/troubleshooting.md`, `guides/testing-live-stripe.md`, `accrue/test/accrue/docs/troubleshooting_guide_test.exs`, `accrue/test/accrue/docs/tax_rollout_docs_test.exs`.<br>`cd accrue && mix test test/accrue/docs/troubleshooting_guide_test.exs test/accrue/docs/tax_rollout_docs_test.exs` | Docs must include the stable repair contract plus literal Checkout caveats `customer_update[address]=auto` and `customer_update[shipping]=auto` for existing customers. | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Contract

- Phase 19 has no standalone pre-execution Wave 0 plan. Every planned verification artifact is created or extended within the owning plan.
- 19-01 owns processor verification in existing files `accrue/test/accrue/processor/stripe_test.exs` and `accrue/test/accrue/processor/fake_test.exs`.
- 19-02 creates `accrue/test/accrue/billing/tax_location_test.exs`.
- 19-03 extends `accrue/test/accrue/billing/subscription_projection_tax_test.exs`, `accrue/test/accrue/billing/invoice_projection_test.exs`, and `accrue/test/accrue/webhook/default_handler_test.exs`.
- 19-04 extends existing `accrue_admin` and `examples/accrue_host` LiveView/facade tests named in the plan.
- 19-05 extends `accrue/test/accrue/docs/troubleshooting_guide_test.exs` and adds `accrue/test/accrue/docs/tax_rollout_docs_test.exs`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live Stripe customer location validation | TAX-02 | Requires Stripe test-mode credentials and API-version-sensitive customer validation behavior | Follow `guides/testing-live-stripe.md` with a valid and invalid customer address; confirm `customer_tax_location_invalid` maps to the documented Accrue error. |
| Existing production subscription rollout | TAX-04 | Migration risk depends on the host app's real existing Stripe objects | Read the rollout guide against a representative host app and confirm it tells operators to update existing subscriptions/payment links explicitly before enabling automatic collection, and to set `customer_update[address]=auto` or `customer_update[shipping]=auto` for existing Checkout customers whose collected addresses should overwrite the Stripe Customer. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 contract matches the actual plan-owned test/doc files
- [x] No watch-mode flags
- [x] Feedback latency < 300s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
