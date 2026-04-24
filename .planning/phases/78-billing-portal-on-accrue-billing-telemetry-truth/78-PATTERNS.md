# Phase 78 — Pattern map

## Billing facade + telemetry

**Analog:** `accrue/lib/accrue/billing.ex` — `attach_payment_method/3` wraps `PaymentMethodActions` in `span_billing(:payment_method, :attach, customer, opts, fn -> ... end)`.

**Apply:** New `create_billing_portal_session/2` and `create_billing_portal_session!/2` use `span_billing(:billing_portal, :create, customer, opts, fn -> ... end)` then build map `%{customer: customer}` merged with validated second-arg attrs; call `Accrue.BillingPortal.Session.create/1`.

## Session + processor

**Analog:** `accrue/lib/accrue/billing_portal/session.ex` `create/1` + `accrue/test/accrue/billing_portal_test.exs` setup with `Accrue.BillingCase` and Fake `processor_id`.

**Apply:** Reuse same test setup patterns; assert on `%Accrue.BillingPortal.Session{}` and Inspect redaction via existing Session behavior (no need to re-test Session in depth).

## Span coverage enforcement

**Analog:** `accrue/test/accrue/telemetry/billing_span_coverage_test.exs` — public `__info__(:functions)` minus exceptions must appear in `billing.ex` source alongside `Accrue.Telemetry.span`.

**Apply:** Any new public `Accrue.Billing` function must use `span_billing` (or direct `Accrue.Telemetry.span`) in the same module.

## PATTERN MAPPING COMPLETE
