---
phase: 26-hierarchy-and-pattern-alignment
plan: "02"
status: complete
completed: "2026-04-20"
requirements-completed: [UX-02]
---

# Plan 26-02 Summary — UX-02 money detail hierarchy

## Objective

Remove nested `ax-page` chrome from money detail LiveViews; use neutral stack wrappers per `26-UI-SPEC.md` / Phase 20.

## Changes

- `subscription_live.ex`, `invoice_live.ex`, `charge_live.ex` — inner `div.ax-page` / `form.ax-page` replaced with `ax-stack-xl` or `ax-stack-sm`; exactly **one** `class="ax-page"` remains each file (outer `<section>`).
- `app.css` — new `.ax-stack-xl` and `.ax-stack-sm` (grid gaps; not page landmarks).
- Tests: `Regex.scan(~r/class="ax-page"/, html) |> length() == 1` on subscription, customer, invoice, and charge detail mounts.
- `25-INV-03-spec-alignment.md` — **26-02** evidence on detail rollup, C-07, C-09.

## Self-Check: PASSED

- `rg -c 'class="ax-page"'` on each touched `*_live.ex`: **1**
- `mix test` on the four detail test modules: **0 failures**
