---
phase: 78-billing-portal-on-accrue-billing-telemetry-truth
status: clean
review_depth: quick
reviewed: "2026-04-24"
---

# Phase 78 — code review

## Scope

- `accrue/lib/accrue/billing.ex` — billing portal facade + `NimbleOptions` attrs
- `accrue/test/accrue/billing/billing_portal_session_facade_test.exs` — Fake + telemetry assertions
- `accrue/guides/telemetry.md`, `accrue/guides/operator-runbooks.md`, `accrue/CHANGELOG.md` — BIL-05 docs

## Findings

Facade keeps portal URLs out of `span_billing` metadata (only `billing_metadata/4` fields; tests assert `inspect(metadata)` omits the Fake session URL prefix). Attrs schema mirrors `Session` minus `:customer`. Bang variant matches `Session.create!/1` error branching.

## Residual risk

Telemetry test uses a short-lived `:telemetry.attach` handler id; handlers are detached in `after`. Local function handler emits an info-level performance note from `:telemetry` — acceptable for this test file.
