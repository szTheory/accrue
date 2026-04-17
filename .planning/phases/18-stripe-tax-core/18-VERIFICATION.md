---
phase: 18-stripe-tax-core
verified: 2026-04-17T17:19:01Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
---

# Phase 18: Stripe Tax Core Verification Report

**Phase Goal:** Developers can enable Stripe Tax on new recurring and checkout flows through Accrue's public API, with Fake-backed behavior and local projections that make automatic tax state observable.
**Verified:** 2026-04-17T17:19:01Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Developers can enable or disable automatic tax when calling `Accrue.Billing.subscribe/3`, and omitted tax options stay backward-compatible. | ✓ VERIFIED | `SubscriptionActions` normalizes `:automatic_tax` into processor params and strips the public option from downstream opts before calling the processor (`accrue/lib/accrue/billing/subscription_actions.ex:75-95`, `:715-741`). Subscription tests cover enabled, disabled, and omitted cases (`accrue/test/accrue/billing/subscription_test.exs:42-60`). |
| 2 | Developers can enable or disable automatic tax when creating checkout sessions through the public API. | ✓ VERIFIED | `Accrue.Checkout.Session.create/1` validates `automatic_tax: [type: :boolean, default: false]` and always emits `"automatic_tax" => %{"enabled" => opts[:automatic_tax]}` in request params before calling the processor (`accrue/lib/accrue/checkout/session.ex:51-81`, `:141-169`). Checkout tests cover enabled and disabled flows (`accrue/test/accrue/checkout_test.exs:88-117`). |
| 3 | The Stripe processor passes automatic-tax intent through to Stripe-backed calls without introducing alternate request shaping. | ✓ VERIFIED | `Accrue.Processor.Stripe.create_subscription/2` and `checkout_session_create/2` both pass `stringify_keys(params)` directly into `LatticeStripe` calls (`accrue/lib/accrue/processor/stripe.ex:125-132`, `:688-694`). Adapter tests lock that behavior (`accrue/test/accrue/processor/stripe_test.exs:150-167`). |
| 4 | The Fake processor deterministically represents enabled and disabled automatic-tax states for subscription, invoice, and checkout flows. | ✓ VERIFIED | Fake checkout, subscription, and invoice builders synthesize `automatic_tax`, `tax`, and `total_details.amount_tax` from normalized params (`accrue/lib/accrue/processor/fake.ex:1498-1533`, `:1996-2137`). Tests assert enabled and disabled parity for all three shapes (`accrue/test/accrue/processor/fake_test.exs:108-197`). |
| 5 | Local subscription rows expose whether automatic tax was enabled and what status Stripe/Fake reported. | ✓ VERIFIED | Schema fields and casts exist on `Subscription` (`accrue/lib/accrue/billing/subscription.ex:50-89`), the migration adds columns (`accrue/priv/repo/migrations/20260417180000_add_automatic_tax_columns_to_billing_tables.exs:11-20`), and `SubscriptionProjection.decompose/1` projects `automatic_tax` and `automatic_tax_status` (`accrue/lib/accrue/billing/subscription_projection.ex:14-35`, `:68-78`). Projection tests cover string-keyed, atom-keyed, and omitted payloads (`accrue/test/accrue/billing/subscription_projection_tax_test.exs:7-42`). |
| 6 | Local invoice rows preserve automatic-tax state and tax amount without requiring 1:1 Stripe column parity. | ✓ VERIFIED | Invoice schema fields and casts include `tax_minor`, `automatic_tax`, and `automatic_tax_status` (`accrue/lib/accrue/billing/invoice.ex:57-95`), the migration adds the tax-state columns (`accrue/priv/repo/migrations/20260417180000_add_automatic_tax_columns_to_billing_tables.exs:17-20`), and `InvoiceProjection.decompose/1` derives `tax_minor` from `tax` then `total_details.amount_tax`, defaulting to `0` only when automatic tax is enabled without an amount (`accrue/lib/accrue/billing/invoice_projection.ex:30-64`, `:155-170`). Projection tests cover string-keyed and atom-keyed payloads plus fallback behavior (`accrue/test/accrue/billing/invoice_projection_test.exs:77-102`, `:154-172`). |
| 7 | Returned checkout session structs expose automatic-tax state and tax amount for local observation. | ✓ VERIFIED | `Accrue.Checkout.Session` struct includes `:automatic_tax` and `:amount_tax`, and `from_stripe/1` projects both from processor payload fields (`accrue/lib/accrue/checkout/session.ex:27-46`, `:117-197`). Checkout tests assert `session.automatic_tax` and `session.amount_tax` for enabled and disabled flows (`accrue/test/accrue/checkout_test.exs:88-117`). |
| 8 | Focused unit and integration tests prove tax-enabled and tax-disabled flows remain backward-compatible for existing non-tax users. | ✓ VERIFIED | Targeted verification passed: `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/billing/subscription_test.exs test/accrue/checkout_test.exs test/accrue/processor/fake_test.exs test/accrue/processor/stripe_test.exs` finished with `74 tests, 0 failures`. The suite includes explicit no-tax subscription behavior (`accrue/test/accrue/billing/subscription_test.exs:56-60`). |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/lib/accrue/billing/subscription_actions.ex` | Public subscription tax option normalization | ✓ VERIFIED | Exists, contains normalization and opt sanitization, and is wired into `Processor.__impl__().create_subscription/2`. |
| `accrue/lib/accrue/checkout/session.ex` | Public checkout tax option and returned session projection | ✓ VERIFIED | Exists, substantive, and wired into `checkout_session_create/2` plus `from_stripe/1` projection. |
| `accrue/lib/accrue/processor/stripe.ex` | Stripe passthrough for automatic-tax params | ✓ VERIFIED | Exists and forwards `stringify_keys(params)` to Stripe subscription and checkout calls. |
| `accrue/lib/accrue/processor/fake.ex` | Deterministic Fake automatic-tax payloads | ✓ VERIFIED | Exists and builds deterministic subscription, invoice, and checkout tax payloads. |
| `accrue/lib/accrue/billing/subscription.ex` | Local subscription tax observability fields | ✓ VERIFIED | Exists with persistent `automatic_tax` and `automatic_tax_status` fields. |
| `accrue/lib/accrue/billing/invoice.ex` | Local invoice tax observability fields | ✓ VERIFIED | Exists with `tax_minor`, `automatic_tax`, and `automatic_tax_status` fields. |
| `accrue/lib/accrue/billing/subscription_projection.ex` | Subscription automatic-tax projection | ✓ VERIFIED | Exists and maps processor payloads into local row attrs. |
| `accrue/lib/accrue/billing/invoice_projection.ex` | Invoice automatic-tax and tax-amount projection | ✓ VERIFIED | Exists and maps processor payloads into local row attrs. |
| `accrue/priv/repo/migrations/20260417180000_add_automatic_tax_columns_to_billing_tables.exs` | Schema support for automatic-tax observability | ✓ VERIFIED | Exists and adds additive automatic-tax columns to subscriptions and invoices. |
| Phase 18 tests under `accrue/test/accrue/**` | Proof of tax-enabled, tax-disabled, and backward-compatible flows | ✓ VERIFIED | Exists and passed in the targeted verification suite. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `subscription_actions.ex` | `Processor.__impl__().create_subscription/2` | normalized `stripe_params` | ✓ WIRED | `stripe_params` gains `automatic_tax`, then the processor call receives those params (`accrue/lib/accrue/billing/subscription_actions.ex:75-95`). |
| `subscription_actions.ex` | `SubscriptionProjection.decompose/1` | returned processor payload | ✓ WIRED | Created subscription payload is immediately decomposed into local attrs before insert (`accrue/lib/accrue/billing/subscription_actions.ex:90-97`). |
| `checkout/session.ex` | `Processor.__impl__().checkout_session_create/2` | `build_stripe_params/1` | ✓ WIRED | `create/1` validates input, builds tax-shaped params, and calls the processor (`accrue/lib/accrue/checkout/session.ex:77-82`, `:141-169`). |
| `checkout/session.ex` | `%Accrue.Checkout.Session{}` | `from_stripe/1` | ✓ WIRED | Returned processor payload is projected into `automatic_tax` and `amount_tax` fields (`accrue/lib/accrue/checkout/session.ex:117-197`). |
| `subscription_projection.ex` | `subscription.ex` | `decompose/1 attrs map` | ✓ WIRED | Projected `automatic_tax` and `automatic_tax_status` keys match schema cast fields (`accrue/lib/accrue/billing/subscription_projection.ex:18-35`; `accrue/lib/accrue/billing/subscription.ex:80-89`). |
| `invoice_projection.ex` | `invoice.ex` | `invoice_attrs` | ✓ WIRED | Projected `tax_minor`, `automatic_tax`, and `automatic_tax_status` keys match schema cast fields (`accrue/lib/accrue/billing/invoice_projection.ex:58-64`; `accrue/lib/accrue/billing/invoice.ex:87-95`). |
| `invoice_actions.ex` | `InvoiceProjection.decompose/1` | invoice action flow | ✓ WIRED | User-path invoice actions run processor results through `InvoiceProjection.decompose/1` before row updates (`accrue/lib/accrue/billing/invoice_actions.ex:127-133`). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `accrue/lib/accrue/billing/subscription_actions.ex` | `attrs.automatic_tax` / `attrs.automatic_tax_status` on inserted subscriptions | Public `opts[:automatic_tax]` -> normalized `stripe_params.automatic_tax` -> processor payload -> `SubscriptionProjection.decompose/1` -> DB insert | Yes | ✓ FLOWING |
| `accrue/lib/accrue/checkout/session.ex` | `%Session{automatic_tax, amount_tax}` | Public `opts[:automatic_tax]` -> `build_stripe_params/1` -> processor `checkout_session_create/2` -> `from_stripe/1` | Yes | ✓ FLOWING |
| `accrue/lib/accrue/billing/subscription_projection.ex` | `automatic_tax`, `automatic_tax_status` | Processor payload `automatic_tax` map from Fake or Stripe | Yes | ✓ FLOWING |
| `accrue/lib/accrue/billing/invoice_projection.ex` | `tax_minor`, `automatic_tax`, `automatic_tax_status` | Processor payload `tax` / `total_details.amount_tax` and `automatic_tax` map | Yes | ✓ FLOWING |
| `accrue/lib/accrue/processor/fake.ex` | `automatic_tax`, `tax`, `total_details.amount_tax` | Normalized request params for subscriptions, invoices, and checkout sessions | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 18 targeted tax behaviors | `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/billing/subscription_test.exs test/accrue/checkout_test.exs test/accrue/processor/fake_test.exs test/accrue/processor/stripe_test.exs` | `74 tests, 0 failures` | ✓ PASS |
| Full project regression context | `cd accrue && mix test` | `46 properties, 1126 tests, 7 failures (11 excluded)` | ? OUTSIDE PHASE |

The seven full-suite failures are outside the Phase 18 goal surface:
- 3 failures in `test/accrue/docs/expansion_discovery_test.exs` due to missing Phase 16 recommendation artifact paths.
- 3 failures in `test/accrue/docs/trust_review_test.exs` due to missing Phase 15 trust-review artifact paths.
- 1 failure in `test/accrue/application_test.exs` due to an auth error-message expectation mismatch.

None of those failures exercise the Phase 18 tax entry points, processor tax behavior, checkout/session projection, billing projections, or Phase 18-changed files.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| TAX-01 | 18-01, 18-02, 18-03, 18-04 | Developer can enable Stripe Tax for new subscription and checkout flows through Accrue's public billing API. | ✓ SATISFIED | Subscription public API and tests (`accrue/lib/accrue/billing/subscription_actions.ex:75-95`, `accrue/test/accrue/billing/subscription_test.exs:42-60`), checkout public API and tests (`accrue/lib/accrue/checkout/session.ex:51-81`, `:117-169`, `accrue/test/accrue/checkout_test.exs:88-117`), Stripe/Fake adapter parity (`accrue/lib/accrue/processor/stripe.ex:125-132`, `:688-694`, `accrue/lib/accrue/processor/fake.ex:1498-1533`, `:1996-2137`), and local projection observability (`accrue/lib/accrue/billing/subscription_projection.ex:14-35`, `accrue/lib/accrue/billing/invoice_projection.ex:58-64`, `:155-170`). |

No orphaned Phase 18 requirements found in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

No blocker or warning-level anti-patterns found in the Phase 18 implementation files. Targeted scans found no TODO/FIXME/placeholder implementations in the Phase 18 source and test files.

### Gaps Summary

No Phase 18 gaps found. The implementation matches the roadmap contract: public subscription and checkout tax enablement is present, provider behavior is observable under Fake and forwarded under Stripe, local subscription and invoice projections persist the narrow automatic-tax state, and the focused regression suite passes.

---

_Verified: 2026-04-17T17:19:01Z_
_Verifier: Claude (gsd-verifier)_
