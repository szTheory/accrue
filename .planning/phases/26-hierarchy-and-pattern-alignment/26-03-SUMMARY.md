---
phase: 26-hierarchy-and-pattern-alignment
plan: "03"
status: complete
completed: "2026-04-20"
---

# Plan 26-03 Summary — UX-03 webhooks typography

## Objective

Align webhook index and detail with money-list typographic rhythm (`ax-body`, no nested page chrome).

## Changes

- `webhooks_live.ex` — `status_summary/1`, `endpoint_summary/1`, `received_summary/1`, and `safe_link/2` emit `<span class="ax-body">` around cell content.
- `webhook_live.ex` — replay confirmation and forensic blocks use `ax-stack-xl` instead of nested `ax-page` (single outer `ax-page` preserved).
- Tests: `webhooks_live_test.exs` asserts `ax-body` and refutes `ax-text-12`; `webhook_live_test.exs` asserts one `ax-page` and `ax-kpi-grid`.
- `25-INV-03-spec-alignment.md` — **26-03** markers on Webhooks surface rollup and C-04/C-05.

## Self-Check: PASSED

- `mix test test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/webhook_live_test.exs` — **0 failures**
