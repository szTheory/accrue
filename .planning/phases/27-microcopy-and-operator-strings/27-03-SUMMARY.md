---
phase: 27-microcopy-and-operator-strings
plan: 03
subsystem: ui
tags: [liveview, copy, webhooks, admin]

requires:
  - phase: 27-02
    provides: Copy.Locked scaffold + money detail migration
provides:
  - Webhook replay / bulk / denial strings in Copy.Locked (verbatim parity)
  - Webhooks index Tier A empty copy via AccrueAdmin.Copy
  - Contributor docs for copy tiers + CHANGELOG host-visible subsection
affects: []

tech-stack:
  added: []
  patterns:
    - "Webhook E2E/ExUnit literals trace to Copy.Locked; index empty states use Tier A Copy.*"

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/copy/locked.ex
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
    - accrue_admin/README.md
    - accrue_admin/CHANGELOG.md
    - .planning/phases/25-admin-ux-inventory/25-INV-03-spec-alignment.md

key-decisions:
  - "Preserved byte-for-byte replay and bulk confirmation strings; webhooks index headline removes DLQ jargon per Tier A."

patterns-established:
  - "README documents Tier A/B/C; CHANGELOG flags host-visible copy changes."

requirements-completed: [COPY-01, COPY-02, COPY-03]

duration: 35min
completed: 2026-04-20
---

# Phase 27: Microcopy — Plan 03 summary

**Webhook operator strings and webhooks index empty chrome now route through `AccrueAdmin.Copy` / `AccrueAdmin.Copy.Locked` without breaking existing tests; README and CHANGELOG document host-visible copy policy.**

## Task commits

1. **Tasks 1–3** — `88c5c3d` feat(27-03): centralize webhook operator copy in Copy / Locked
2. **Tasks 5–6** — (next commit) docs: README tiers + CHANGELOG host-visible copy
3. **Task 7** — (same commit) INV-03 webhook evidence + this SUMMARY

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhooks_live_test.exs` — PASS
- Playwright `phase13-canonical-demo.spec.js` not re-run (deps not verified in executor); optional per plan.

## Self-Check: PASSED
