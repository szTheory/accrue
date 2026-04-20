---
phase: 28-accessibility-hardening
plan: 02
subsystem: ui
tags: [accessibility, data_table, caption]

requires: []
provides:
  - Optional `table_caption` assign on DataTable desktop grid
  - Visually hidden caption strings from Copy for customers and webhooks indexes
affects: []

tech-stack:
  added: []
  patterns:
    - "ax-visually-hidden utility for off-screen but screen-reader-visible captions"

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/components/data_table.ex
    - accrue_admin/lib/accrue_admin/live/customers_live.ex
    - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/test/accrue_admin/components/data_table_test.exs
    - accrue_admin/test/accrue_admin/live/customers_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs

key-decisions:
  - "Captions only on desktop table branch, not mobile cards"

patterns-established:
  - "Page title strings centralized in Copy next to empty-state copy"

requirements-completed: [A11Y-02]

duration: 0min
completed: 2026-04-20
---

# Phase 28 — Plan 02 summary

**Customers and webhooks desktop grids expose programmatic names via native captions aligned with page headings.**

## Accomplishments

- `Copy.customers_index_table_caption/0` and `Copy.webhooks_index_table_caption/0` match `h2.ax-display` text.
- `DataTable` renders `<caption class="ax-visually-hidden">` when assign is set.
- Component and LiveView tests assert caption markup.

## Task commits

Integrated in commit **feat(a11y): complete phase 28 accessibility hardening** (search git log for that subject).

## Deviations from plan

None — followed plan as specified.

## Issues encountered

None.
