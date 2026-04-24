---
phase: 78-billing-portal-on-accrue-billing-telemetry-truth
plan: 01
subsystem: accrue
tags: [BIL-04, billing_portal, telemetry, facade, fake]

requires: []
provides:
  - Accrue.Billing.create_billing_portal_session/2 and !/2 delegating to BillingPortal.Session
  - Fake-backed tests including telemetry metadata URL leak guard

tech-stack:
  added: []
  patterns:
    - "NimbleOptions.validate! on facade attrs mirroring Session @create_schema minus :customer"

key-files:
  created:
    - accrue/test/accrue/billing/billing_portal_session_facade_test.exs
  modified:
    - accrue/lib/accrue/billing.ex

key-decisions:
  - "Bang errors mirror Session.create!/1 (exception re-raise vs RuntimeError with inspect(other))."

patterns-established: []

requirements-completed: [BIL-04]

duration: 10 min
completed: 2026-04-24
---

# Phase 78 — Plan 01 summary

**Billing context exposes portal session creation** with `span_billing(:billing_portal, :create, ...)`, validated attrs, and tests proving Fake happy/error paths plus telemetry metadata excludes the Fake portal URL prefix.

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- `rg -n "def create_billing_portal_session" accrue/lib/accrue/billing.ex` — match.
- `rg -n ":billing_portal, :create" accrue/lib/accrue/billing.ex` — match.
- `rg -n "BillingPortal.Session.create" accrue/lib/accrue/billing.ex` — match.
- `cd accrue && PGUSER="${PGUSER:-$USER}" mix test test/accrue/billing/billing_portal_session_facade_test.exs test/accrue/telemetry/billing_span_coverage_test.exs` — exit 0.
- `mix compile --warnings-as-errors` — exit 0.

## Task commits

1. **Task 1: Billing facade functions + @doc** — `2f3272c` (feat)
2. **Task 2: ExUnit — happy path, failure, telemetry metadata** — `f676b97` (test)
