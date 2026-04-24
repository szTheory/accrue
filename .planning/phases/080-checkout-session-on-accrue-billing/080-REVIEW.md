---
phase: 080-checkout-session-on-accrue-billing
status: clean
depth: quick
---

# Phase 80 — Code review (orchestrator quick pass)

**Scope:** `accrue/lib/accrue/billing.ex`, `accrue/test/accrue/billing/checkout_session_facade_test.exs`

## Security

- Facade validates attrs before `span_billing`; only allowlisted dimensions merged into telemetry metadata for `:checkout_session` `:create`.
- Bang variant does not leak raw error tuples beyond `inspect/1` in raise message (matches portal pattern).

## Quality

- `CheckoutSession` alias avoids collision with `Accrue.BillingPortal.Session`.
- Tests detach telemetry handler in `try/after`.

## Findings

None blocking.
