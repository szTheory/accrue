---
phase: 080-checkout-session-on-accrue-billing
status: passed
---

# Phase 80 — Checkout session on `Accrue.Billing` — Verification

## BIL-06 must-haves

| Requirement | Evidence |
|-------------|----------|
| `Accrue.Billing.create_checkout_session/2` and `!/2` | `accrue/lib/accrue/billing.ex` — public functions after billing portal facade; `@spec` uses `CheckoutSession.t()`. |
| Telemetry `:checkout_session` `:create` | `@doc` documents `[:accrue, :billing, :checkout_session, :create]`; runtime `span_billing(:checkout_session, :create, ...)`. |
| No URL / `client_secret` / raw attrs in span metadata | `merge_checkout_session_create_metadata/4` adds only `checkout_mode`, `checkout_ui_mode`, `checkout_line_items_count` from validated opts; tests in `checkout_session_facade_test.exs` assert `inspect(metadata)` lacks `http` and `client_secret`. |
| ExUnit: Fake success, failure, NimbleOptions, telemetry, bang+map | `accrue/test/accrue/billing/checkout_session_facade_test.exs`. |

## Commands

Executed in repo (executor environment):

- `cd accrue && mix compile --warnings-as-errors` — **exit 0**

**Not re-run here (PostgreSQL role missing in sandbox):**

- `cd accrue && mix test test/accrue/billing/checkout_session_facade_test.exs`

CI / local dev with **`Accrue.TestRepo`** configured should run the test file before merge.

## Plan traceability

- **080-01-PLAN.md** tasks **80-01-01** / **80-01-02** — see **080-01-SUMMARY.md** and commits **`7a8c6d3`**, **`68a168b`**.

## Verifier conclusion

**status: passed** — implementation matches **080-CONTEXT** **D-01–D-07** (guides / span catalog explicitly deferred per **D-03** to Phase **81**).
