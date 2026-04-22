---
phase: 38-org-billing-recipes-pow-custom-org-boundaries
plan: 02
subsystem: docs
tags: [org-03, custom-tenancy, liveview, webhooks, audit]

requires:
  - plan: "38-01"
    provides: "Pow ORG-07 section placement before User-as-billable aside"
provides:
  - ORG-08 custom organization model with ORG-03 path-class anti-pattern table
  - Subsections for LiveView admin, context functions, webhook replay, actor_id alignment
  - Contract needles for ORG-08 literals
affects: []

tech-stack:
  added: []
  patterns:
    - "Anti-pattern rows keyed to ORG-03 path classes public/admin/webhook replay/export"

key-files:
  created: []
  modified:
    - accrue/guides/organization_billing.md
    - accrue/test/accrue/docs/organization_billing_guide_test.exs

key-decisions:
  - "User-as-billable aside points to ORG-08 above once the section is inserted before it."

patterns-established:
  - "Custom tenancy prose always returns to membership-verified Organization."

requirements-completed: [ORG-08]

duration: 20min
completed: 2026-04-21
---

# Phase 38 plan 02 summary

**ORG-08 documents custom org resolution with an ORG-03-aligned anti-pattern table and explicit obligations across public, admin, webhook replay, and export paths.**

## Task commits

1. **Task 1: ORG-08 narrative** — `475ef31` (docs)
2. **Task 2: guide test needles** — `b1f33ae` (test)

## Self-Check: PASSED

- `cd accrue && mix test test/accrue/docs/organization_billing_guide_test.exs`
- `cd accrue && MIX_ENV=test mix docs`
