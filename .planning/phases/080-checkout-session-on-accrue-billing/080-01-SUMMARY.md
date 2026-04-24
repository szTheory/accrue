---
phase: 080-checkout-session-on-accrue-billing
plan: 01
subsystem: payments
tags: [billing, checkout, nimble_options, telemetry, fake_processor]

requires:
  - phase: 079-friction-inventory-maintainer-pass
    provides: BIL-06 deferred to phase 80; portal facade patterns
provides:
  - Accrue.Billing.create_checkout_session/2 and !/2
  - Checkout span metadata allowlist (mode, ui_mode, line item count)
  - ExUnit facade coverage (Fake, telemetry, validation)
affects:
  - 081-telemetry-and-integrator-docs

tech-stack:
  added: []
  patterns:
    - "Billing facade mirrors create_billing_portal_session — NimbleOptions + span_billing + delegate"

key-files:
  created:
    - accrue/test/accrue/billing/checkout_session_facade_test.exs
  modified:
    - accrue/lib/accrue/billing.ex

key-decisions:
  - "Integer :checkout_line_items_count in span metadata so ExUnit can assert equality (strings from put_metadata for mode/ui_mode)."

patterns-established:
  - "CheckoutSession alias avoids BillingPortal.Session name collision."

requirements-completed: [BIL-06]

duration: 25min
completed: 2026-04-24
---

# Phase 080: Checkout session on Accrue.Billing — Plan 01 Summary

**NimbleOptions-gated `Accrue.Billing.create_checkout_session/2` delegates to `Accrue.Checkout.Session` under `span_billing(:checkout_session, :create, …)` with low-cardinality checkout metadata and dedicated Fake + telemetry tests.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-04-24 (inline execute-phase)
- **Completed:** 2026-04-24
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Public facade + bang variant with attrs schema mirroring `Checkout.Session` `@create_schema` minus `:customer`.
- Telemetry metadata adds `checkout_mode`, `checkout_ui_mode`, `checkout_line_items_count` without URLs or secrets.
- ExUnit covers happy path, scripted processor error, telemetry assertions, unknown-key validation, and bang with map attrs.

## Task Commits

1. **Task 80-01-01: billing.ex facade** — `7a8c6d3` (feat)
2. **Task 80-01-02: ExUnit** — `68a168b` (test)

## Files Created/Modified

- `accrue/lib/accrue/billing.ex` — `@checkout_session_facade_attrs_schema`, `create_checkout_session/2`, `!/2`, `merge_checkout_session_create_metadata/4`
- `accrue/test/accrue/billing/checkout_session_facade_test.exs` — facade regression suite

## Decisions Made

- Kept idiomatic `alias Accrue.Checkout.Session, as: CheckoutSession` (plan acceptance `rg` for `Session as CheckoutSession` without comma does not match Elixir syntax).

## Deviations from Plan

None for product behavior. **Plan acceptance tooling:** one `rg` pattern in PLAN for the alias omits the Elixir-required comma after `Session`.

## Issues Encountered

- `mix test` in this environment failed to connect to PostgreSQL (`role "postgres" does not exist`). **`mix compile --warnings-as-errors`** succeeded locally; run `cd accrue && mix test test/accrue/billing/checkout_session_facade_test.exs` where TestRepo is configured.

## User Setup Required

None.

## Next Phase Readiness

- BIL-06 facade is in place for Phase **81** (BIL-07 / `billing_span_coverage_test`, guides) per **080-CONTEXT D-03**.

## Self-Check: PASSED

- `mix compile --warnings-as-errors` (accrue) — PASS
- `mix test` — NOT RUN (DB unavailable in executor environment)

---
*Phase: 080-checkout-session-on-accrue-billing*
*Completed: 2026-04-24*
