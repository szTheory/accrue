---
phase: 78-billing-portal-on-accrue-billing-telemetry-truth
verified: "2026-04-24"
status: passed
---

# Phase 78 — Billing portal on `Accrue.Billing` + telemetry truth

Closure record for **v1.24** requirements **BIL-04** (billing context portal session facade + Fake tests + span) and **BIL-05** (telemetry guide, operator runbook cross-link, changelog). No live credentials in this file.

## Automated verification

- **Compile:** `cd accrue && mix compile --warnings-as-errors` — **exit 0**.
- **ExUnit (facade + span inventory):** `cd accrue && PGUSER="${PGUSER:-$USER}" mix test test/accrue/billing/billing_portal_session_facade_test.exs test/accrue/telemetry/billing_span_coverage_test.exs` — **5 tests, 0 failures**.

## BIL-04 (facade + telemetry)

- **API:** `accrue/lib/accrue/billing.ex` — `create_billing_portal_session/2`, `create_billing_portal_session!/2`; `span_billing(:billing_portal, :create, ...)` → `Accrue.BillingPortal.Session.create/1`; `NimbleOptions` schema for attrs (no `:customer` in second arg).
- **Tests:** `accrue/test/accrue/billing/billing_portal_session_facade_test.exs` — happy path, bang + map attrs, `Fake.scripted_response(:portal_session_create, {:error, %Accrue.APIError{}})`, telemetry start metadata asserts `operation == "billing_portal.create"` and `inspect(metadata)` excludes Fake portal URL prefix `https://billing.stripe.test/p/session/`.

## BIL-05 (docs + changelog)

- **`guides/telemetry.md`** — OTel / tuple bullets for `accrue.billing.billing_portal.create` and `payment_method.{attach,detach,set_default}` with exact `[:accrue, :billing, …]` tuples; **Last reconciled (billing span examples)** footnote **2026-04-24 — Phase 78 BIL-05**.
- **`guides/operator-runbooks.md`** — Accrue-layer triage sentence with relative link to `telemetry.md` and `:billing_portal` tuple; warns against pasting `%Accrue.BillingPortal.Session{}` inspect into tickets.
- **`CHANGELOG.md`** — **Unreleased → Billing** bullet for `create_billing_portal_session/2` and `!/2`.

## Closure checklist

- [x] **BIL-04** satisfied — facade + span + Fake/telemetry tests green.
- [x] **BIL-05** satisfied — telemetry + runbook + changelog updated; optional First Hour pointer skipped (no integrator gap found).

## Traceability

- **Roadmap:** `.planning/ROADMAP.md` — Phase **78** row under **v1.24**.
- **Requirements:** `.planning/REQUIREMENTS.md` — **BIL-04**, **BIL-05** marked complete.
