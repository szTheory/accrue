---
status: passed
phase: 26
verified: "2026-04-20"
---

# Phase 26 — Verification

## Must-haves (from plans)

| ID | Evidence |
|----|----------|
| UX-01 | Four money indexes use `ax-chip ax-label`; tests assert chips and no `ax-text-12` in touched paths; `.ax-chip` shell in `app.css`. |
| UX-02 | `subscription_live`, `invoice_live`, `charge_live` have exactly one `class="ax-page"`; customer detail already single shell; regression tests count `ax-page` in HTML. |
| UX-03 | `webhooks_live` wraps table cells with `ax-body`; `webhook_live` removes nested `ax-page`; tests assert `ax-body` / `ax-kpi-grid` / single `ax-page`. |
| UX-04 | `theme.css` UX-04 comment; `26-theme-exceptions.md` row for `default_brand/0`; `admin_ui.md` links; `REQUIREMENTS.md` UX-01..04 complete. |

## Automated

- `cd accrue_admin && mix test` — **passed** (full suite, 2026-04-20).
- Targeted tests during execution: money index, money detail, webhook index/detail modules.

## Human verification

_None required for this phase (markup/CSS + docs alignment)._

## Schema drift

- `gsd-sdk query verify.schema-drift 26` — `valid: true`.
