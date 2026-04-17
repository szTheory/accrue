---
phase: 19
slug: tax-location-and-rollout-safety
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-17
updated: 2026-04-17
---

# Phase 19 - Security

Per-phase security contract for tax-location validation, rollout failure projection, admin/host recovery surfaces, and rollout-safety documentation.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| tax-location attrs -> `Accrue.Processor.Stripe.update_customer/3` | Customer location data crosses from Accrue into Stripe customer update calls. | Address, shipping, tax validation params, optional IP address |
| raw processor error -> `Accrue.Processor.Stripe.ErrorMapper` | Stripe error payloads cross into Accrue's public error surface. | Provider error code, request id, HTTP status, raw provider payload before mapping |
| public host call -> `Accrue.Billing.update_customer_tax_location/2` | Untrusted host/customer input crosses into the public billing facade. | Address and shipping fields |
| processor result -> local `Customer` row | Provider customer response is reduced into local persisted customer projection. | Customer metadata and non-PII provider fields |
| canonical Stripe/Fake payload -> projection modules | Provider billing state is reduced into local queryable columns. | Automatic-tax status, disabled reason, finalization error code |
| webhook event family -> default handler reducer | Stripe webhook event types trigger local invoice reconciliation. | Event type, invoice identifier, canonical invoice payload |
| local projections -> admin detail UI | Billing state crosses into operator-visible admin surfaces. | Projected reason/code fields and recovery copy |
| host LiveView form -> host billing facade | User-entered address fields cross from host UI into public billing APIs. | Tax-location form values |
| implementation facts -> public guides | Internal behavior is translated into rollout and recovery documentation. | Public error names, recovery order, rollout caveats |
| docs examples -> copied terminal / support notes | Example content can leak unsafe data or imply unsupported behavior. | Placeholder locations, command notes, support-note guidance |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-19-01 | I | `accrue/lib/accrue/processor/stripe/error_mapper.ex` | mitigate | Map `customer_tax_location_invalid` to a stable `%Accrue.APIError{}` with sanitized `processor_error`; do not retain raw address values, raw body text, or Stripe request params. Evidence: `error_mapper.ex:101`, `:111`, `:156`. | closed |
| T-19-02 | T | `accrue/lib/accrue/processor/fake.ex` | mitigate | Keep Fake deterministic and limited to validation-state simulation only; no custom tax rates or jurisdiction logic. Evidence: `fake.ex:2213`, `:2216`, `:2243`. | closed |
| T-19-03 | R | `accrue/test/accrue/processor/stripe_test.exs` | mitigate | Assert stable error codes and narrow metadata fields so tests fail if raw provider payloads leak. Evidence: `stripe_test.exs:73`, `:95`, `:103`. | closed |
| T-19-04 | I | `accrue/lib/accrue/billing.ex` | mitigate | Strip `address`, `shipping`, `phone`, and tax-location PII before persisting `customer.data` or recording event payloads. Evidence: `billing.ex:617`, `:621`, `:732`. | closed |
| T-19-05 | T | `accrue/lib/accrue/billing.ex` | mitigate | Keep `update_customer/2` local-only and add `update_customer_tax_location/2` rather than changing existing semantics. Evidence: `billing.ex:596`, `:599`, `:659`. | closed |
| T-19-06 | R | `accrue/test/accrue/billing/tax_location_test.exs` | mitigate | Assert stable `%Accrue.APIError{code: "customer_tax_location_invalid"}` values and sanitized local customer data. Evidence: `tax_location_test.exs:41`, `:47`, `:76`. | closed |
| T-19-07 | I | `accrue/lib/accrue/billing/invoice_projection.ex` | mitigate | Persist only `automatic_tax_disabled_reason` and `last_finalization_error_code`; do not add raw finalization messages or raw address columns outside existing payload storage. Evidence: `invoice_projection.ex:65`, `:66`, `invoice_projection_test.exs:116`. | closed |
| T-19-08 | D | `accrue/lib/accrue/webhook/default_handler.ex` | mitigate | Reconcile `invoice.updated` and `invoice.finalization_failed` through the explicit invoice reducer list. Evidence: `default_handler.ex:151`, `:152`, `default_handler_test.exs:47`, `:77`. | closed |
| T-19-09 | T | migration/schema pair | mitigate | Keep rollout-safety columns additive and string-only so existing rows remain readable and rollback-safe for non-tax hosts. Evidence: `20260417193000_add_tax_rollout_safety_columns.exs:13`, `:18`, `subscription.ex:62`, `invoice.ex:63`. | closed |
| T-19-10 | I | `accrue_admin/lib/accrue_admin/live/*.ex` | mitigate | Render projected reason/code fields and recovery copy only; do not expose raw Stripe payloads, raw address values, or direct provider fetches. Evidence: `customer_live.ex:103`, `subscription_live.ex:147`, `invoice_live.ex:167`, `:173`, `invoice_live_test.exs:126`, `:127`. | closed |
| T-19-11 | E | `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | mitigate | Keep host flow on `AccrueHost.Billing` wrappers over public Accrue APIs; do not bypass host boundaries with direct Stripe calls. Evidence: `billing.ex:48`, `:50`, `subscription_live.ex:29`, `:55`. | closed |
| T-19-12 | R | UI test files | mitigate | Assert recovery copy and local-field rendering so regressions do not silently remove tax-risk visibility. Evidence: `subscription_live_test.exs:61`, `invoice_live_test.exs:118`, host `subscription_live_test.exs:81`. | closed |
| T-19-13 | I | `accrue/guides/troubleshooting.md` | mitigate | Use placeholder/example language only; do not include real addresses, customer ids, raw processor payloads, or copied logs containing PII. Evidence: `troubleshooting.md:330`, `:343`, `:367`. | closed |
| T-19-14 | T | `guides/testing-live-stripe.md` | mitigate | State the safe test-mode path, Checkout existing-customer `customer_update` caveats, and test credential rules; do not imply production data or dashboard-only recovery. Evidence: `testing-live-stripe.md:51`, `:61`, `:80`. | closed |
| T-19-15 | R | doc tests | mitigate | Assert rollout language about existing subscriptions, invoices, payment links, and Checkout update flags. Evidence: `tax_rollout_docs_test.exs:7`, `:25`, `troubleshooting_guide_test.exs:46`. | closed |

*Status: open - closed*
*Disposition: mitigate (implementation required) - accept (documented risk) - transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Remediation Notes

Initial audit found T-19-10 open because `accrue_admin/lib/accrue_admin/live/invoice_live.ex` rendered the full invoice payload through `JsonViewer`, including `invoice.data`. The mitigation was completed on 2026-04-17 by removing the invoice payload JSON viewer and deleting the helper that included `invoice.data`.

Regression coverage now seeds address-bearing invoice data and asserts the admin invoice HTML does not include `Invoice payload` or `123 Private Lane` while still rendering the projected disabled reason and finalization error code.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-17 | 15 | 14 | 1 | gsd-security-auditor |
| 2026-04-17 | 15 | 15 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-17
