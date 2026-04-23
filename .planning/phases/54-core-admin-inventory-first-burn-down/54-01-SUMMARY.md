---
phase: 54-core-admin-inventory-first-burn-down
plan: "01"
subsystem: ui
tags: [exdoc, adm-07, documentation, accrue_admin]

requires: []
provides:
  - Canonical ADM-07 parity matrix at accrue_admin/guides/core-admin-parity.md
  - Hexdocs extras entry and README/admin_ui discoverability links
affects: [54-02]

tech-stack:
  added: []
  patterns:
    - "Router-derived 11-row matrix as single SSOT for Copy/token/VERIFY posture"

key-files:
  created:
    - accrue_admin/guides/core-admin-parity.md
  modified:
    - accrue_admin/mix.exs
    - accrue_admin/guides/admin_ui.md
    - accrue_admin/README.md

key-decisions:
  - "Invoice rows document P0 gaps pre-ADM-08 burn-down; 54-02 updates them to clean."

patterns-established:
  - "ADM-07 matrix lives only in guides/core-admin-parity.md (D-01)."

requirements-completed: [ADM-07]

duration: 25min
completed: 2026-04-22
---

# Phase 54 plan 01 summary

**Shipped the versioned ADM-07 parity matrix as `guides/core-admin-parity.md`, wired it into ExDoc extras, and linked it from `admin_ui.md` and `README.md` for Hex consumers.**

## Performance

- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Authoritative **11-row** core surface table with **Copy posture**, **`ax-*` / token**, **VERIFY-01 lane**, and **D-18** exclusions.
- **ExDoc** `extras` + **Guides** group registration in `accrue_admin/mix.exs`.
- Discoverability via **`admin_ui.md`** checklist section and **README** Tier A bullet.

## Task commits

1. **Task 1: Author core-admin-parity.md** — `3776816` (docs)
2. **Task 2: Register guide in mix.exs ExDoc extras** — `f049731` (docs)
3. **Task 3: Discoverability links (admin_ui + README)** — `515500c` (docs)

## Files created/modified

- `accrue_admin/guides/core-admin-parity.md` — ADM-07 SSOT matrix.
- `accrue_admin/mix.exs` — ExDoc extras + groups.
- `accrue_admin/guides/admin_ui.md` — Core parity checklist link.
- `accrue_admin/README.md` — v1.14 inventory pointer.

## Decisions made

None beyond the locked Phase 54 CONTEXT (router-faithful rows, honest VERIFY lane).

## Deviations from plan

None — plan executed as written.

## Issues encountered

None.

## Next phase readiness

**54-02** can close ADM-08 on invoices and refresh the `/invoices` matrix rows.

---
*Phase: 54-core-admin-inventory-first-burn-down*
*Completed: 2026-04-22*
