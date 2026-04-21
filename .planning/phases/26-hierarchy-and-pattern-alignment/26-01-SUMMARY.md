---
phase: 26-hierarchy-and-pattern-alignment
plan: "01"
status: complete
completed: "2026-04-20"
requirements-completed: [UX-01]
---

# Plan 26-01 Summary — UX-01 money index list signals

## Objective

Normalize money index billing signal chips to **14px semibold (label)** scale per `26-UI-SPEC.md`, replacing `ax-text-12` on touched chips.

## Key files

- `accrue_admin/lib/accrue_admin/live/customers_live.ex`, `subscriptions_live.ex`, `invoices_live.ex`, `charges_live.ex` — `billing_signals_cell/1` now emits `class="ax-chip ax-label"` for both spans.
- `accrue_admin/assets/css/app.css` — new `.ax-chip` shell (padding, border, background) composing with existing `.ax-label` typography.
- Tests extended on all four `*_live_test.exs` for `ax-chip ax-label` and absence of `ax-text-12` where applicable.
- `.planning/phases/25-admin-ux-inventory/25-INV-03-spec-alignment.md` — C-01 row evidence updated with Phase **26-01** paths and date.

## Commits

- `feat(admin): UX-01 label-scale chips on customers index`
- `feat(admin): UX-01 subscription index billing signal chips`
- `feat(admin): UX-01 invoices and charges index signal chips`
- `docs(planning): INV-03 evidence for Phase 26-01 money indexes`

## Deviations

- Plan `files_modified` listed only LiveViews, tests, and INV-03; **`accrue_admin/assets/css/app.css`** was added so list chips have a defined shell (`.ax-chip` was previously unused in CSS).

## Self-Check: PASSED

- `mix test` on the four money index test files: **0 failures**
- `rg "ax-text-12"` on the four `*_live.ex` files: **no matches**
