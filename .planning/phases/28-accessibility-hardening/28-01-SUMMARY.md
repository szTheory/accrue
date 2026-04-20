---
phase: 28-accessibility-hardening
plan: 01
subsystem: ui
tags: [phoenix_live_view, accessibility, step-up, focus]

requires: []
provides:
  - Step-up modal focus restore via JS.push_focus / pop_focus
  - Escape and Cancel dismissal without continuation or audit row
  - Copy-backed submit label "Verify identity"
affects: [29-mobile-parity-and-ci]

tech-stack:
  added: []
  patterns:
    - "Window Escape handler on money detail LiveViews when step-up pending"
    - "dismiss_challenge/1 mirrors clear_pending without audit"

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/step_up.ex
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex
    - accrue_admin/lib/accrue_admin/live/charge_live.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/test/accrue_admin/live/charge_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - accrue_admin/test/accrue_admin/live/step_up_test.exs

key-decisions:
  - "Fully qualified Phoenix.LiveView.JS in HEEx kept to avoid import churn"

patterns-established:
  - "phx-window-keydown + phx-key escape for cancellable step-up only when pending"

requirements-completed: [A11Y-01]

duration: 0min
completed: 2026-04-20
---

# Phase 28 — Plan 01 summary

**Step-up admin surface uses LiveView JS focus stack, Escape/Cancel dismissal without auditing, and a Copy-backed Verify identity label.**

## Performance

- **Tasks:** 4 (integrated before SUMMARY)
- **Files modified:** 10

## Accomplishments

- `StepUp.dismiss_challenge/1` clears pending state without continuation or `Events.record/1`.
- Modal uses stable dialog id, `phx-mounted` focus into subtree, `phx-remove` pop_focus, Cancel + labeled submit.
- Charge, invoice, and subscription LiveViews handle `step_up_escape` and `step_up_dismiss`.
- LiveView tests cover dismiss and updated submit copy.

## Task commits

Tasks were delivered as an integrated change set in commit **feat(a11y): complete phase 28 accessibility hardening** (search git log for that subject).

## Deviations from plan

None — followed plan as specified.

## Issues encountered

None.
