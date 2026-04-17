---
phase: 18-stripe-tax-core
slug: stripe-tax-core
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-17
updated: 2026-04-17
auditor: gsd-security-auditor
---

# Phase 18 — Security

Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| host billing call -> `Accrue.Billing.subscribe/3` | Untrusted caller input crosses into Accrue's public subscription API | Flat `automatic_tax` option and other subscription request opts |
| `SubscriptionActions` -> processor adapter | Normalized tax intent crosses into a provider-specific adapter | `automatic_tax: %{enabled: boolean}` processor params |
| normalized Accrue params -> Stripe adapter | Provider-specific tax payload leaves Accrue's public boundary | Stripe-shaped subscription and checkout params |
| normalized Accrue params -> Fake adapter | Test double materializes tax state for local verification | Fake subscription, invoice, and checkout payload maps |
| processor payload -> projection modules | Canonical Stripe/Fake billing payloads are converted into local DB attrs | `automatic_tax`, `tax`, and `total_details.amount_tax` values |
| projection attrs -> database rows | Narrow derived observability fields are persisted for application queries | `automatic_tax`, `automatic_tax_status`, and `tax_minor` |
| host checkout call -> `Accrue.Checkout.Session.create/1` | Untrusted caller input enters checkout creation | Flat `automatic_tax` checkout option and line item/session params |
| checkout projection -> returned `%Accrue.Checkout.Session{}` | Processor payload becomes host-visible observable state | `automatic_tax` boolean, `amount_tax`, and retained provider `data` |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-18-01 | Tampering | `accrue/lib/accrue/billing/subscription_actions.ex` | mitigate | Accept only flat boolean `:automatic_tax`; implementation reads `Keyword.get(opts, :automatic_tax, false)` and strips the public option before request opts continue downstream. Evidence: `subscription_actions.ex:715`, `subscription_actions.ex:740`. | closed |
| T-18-02 | Information Disclosure | `accrue/test/accrue/billing/subscription_test.exs` | mitigate | Tests assert local/raw automatic-tax payload fields without logging full processor payloads or sensitive Stripe objects. Evidence: `subscription_test.exs:42`. | closed |
| T-18-03 | Spoofing | `accrue/lib/accrue/billing/subscription_actions.ex` | mitigate | Subscription flow forwards only enablement intent, not caller-supplied tax totals or statuses, into `Processor.__impl__().create_subscription/2`. Evidence: `subscription_actions.ex:75`, `subscription_actions.ex:91`. | closed |
| T-18-04 | Tampering | `accrue/lib/accrue/processor/stripe.ex` | mitigate | Stripe adapter preserves normalized params through `stringify_keys(params)` for subscription and checkout calls without deriving tax totals. Evidence: `stripe.ex:125`, `stripe.ex:688`. | closed |
| T-18-05 | Information Disclosure | `accrue/lib/accrue/processor/stripe.ex` | mitigate | Tax payload handling remains inside existing adapter call flow with no new logging path for Stripe payload maps or tax details. Evidence: `stripe.ex:25`, `stripe.ex:970`. | closed |
| T-18-06 | Repudiation | `accrue/lib/accrue/processor/fake.ex` | mitigate | Fake emits observable automatic-tax fields for subscription, invoice, and checkout paths, with tests catching parity drift. Evidence: `fake.ex:1508`, `fake.ex:2001`, `fake_test.exs:108`. | closed |
| T-18-07 | Tampering | `accrue/lib/accrue/billing/invoice_projection.ex` | mitigate | `tax_minor` derives only from processor payload fields `tax` and `total_details.amount_tax`, with no caller-provided total path. Evidence: `invoice_projection.ex:155`. | closed |
| T-18-08 | Information Disclosure | `accrue/lib/accrue/billing/subscription_projection.ex` | mitigate | Subscription projection persists only `automatic_tax`, `automatic_tax_status`, and retained raw `data`, avoiding expanded sensitive tax detail columns or logging. Evidence: `subscription_projection.ex:16`. | closed |
| T-18-09 | Denial of Service | migration/schema pair | mitigate | Additive schema change uses narrow nullable/defaulted fields so existing non-tax rows remain readable. Evidence: `20260417180000_add_automatic_tax_columns_to_billing_tables.exs:11`, `subscription.ex:60`, `invoice.ex:60`. | closed |
| T-18-10 | Tampering | `accrue/lib/accrue/checkout/session.ex` | mitigate | Checkout accepts only flat boolean `automatic_tax` and constructs the nested Stripe-shaped map inside `build_stripe_params/1`. Evidence: `session.ex:51`, `session.ex:141`. | closed |
| T-18-11 | Information Disclosure | `accrue/lib/accrue/checkout/session.ex` | mitigate | Checkout projection exposes only boolean state and numeric tax amount while retaining full provider payload under `data`. Evidence: `session.ex:117`. | closed |
| T-18-12 | Repudiation | `accrue/test/accrue/checkout_test.exs` | mitigate | Checkout tests assert enabled and disabled automatic-tax behavior so missing or invalid tax state is observable in deterministic tests. Evidence: `checkout_test.exs:88`, `checkout_test.exs:104`. | closed |

Status: all Phase 18 threats are closed.

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-17 | 12 | 12 | 0 | gsd-security-auditor |

## Auditor Result

`## SECURED`

The security auditor verified all 12 Phase 18 threats as closed. No `## Threat Flags` sections were present in the Phase 18 summary files, and no unregistered flags were found.

## Supporting Verification

- Phase verification passed with `8/8` must-haves verified in `18-VERIFICATION.md`.
- Code review completed with `status: clean` in `18-REVIEW.md`.
- Targeted Phase 18 suite passed: `74 tests, 0 failures`.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

Approval: verified 2026-04-17
