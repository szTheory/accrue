---
phase: 51-integrator-golden-path-docs
plan: "03"
subsystem: docs
tags: [troubleshooting, webhooks, dx-codes, accrue-dx]

requires:
  - phase: 51-01
    provides: First Hour + host README spine and VERIFY-01 prose
provides:
  - Troubleshooting anchor convention note (kebab-case ↔ ACCRUE-DX)
  - Webhooks guide deep link to ACCRUE-DX-WEBHOOK-RAW-BODY
  - First Hour + host README bounded failure callouts
affects: [onboarding, support]

tech-stack:
  added: []
  patterns:
    - "Hybrid SSOT: narrative surfaces carry short callouts; troubleshooting.md owns full matrix rows"

key-files:
  created: []
  modified:
    - accrue/guides/troubleshooting.md
    - accrue/guides/webhooks.md
    - accrue/guides/first_hour.md
    - examples/accrue_host/README.md

key-decisions:
  - "Split First Hour troubleshooting links across multiple blockquote lines so `rg -c` acceptance (line-based) matches integrator intent."

patterns-established: []

requirements-completed: [INT-03]

duration: 20min
completed: 2026-04-22
---

# Phase 51 — Plan 03 Summary

**Stable ACCRUE-DX troubleshooting anchors are documented once, linked from webhooks and First Hour, and surfaced lightly in the host demo README without duplicating the matrix.**

## Performance

- **Tasks:** 4
- **Files modified:** 4

## Accomplishments

- Troubleshooting intro documents kebab-case fragment convention aligned with existing `{#accrue-dx-*}` headings.
- Webhooks **Signature failures** links to `troubleshooting.md#accrue-dx-webhook-raw-body` with explicit **`ACCRUE-DX-WEBHOOK-RAW-BODY`**.
- First Hour adds a short **When this fails** block after the router raw-body example with three troubleshooting anchors + installer rerun link.
- Host **First run** step 2 cites **`ACCRUE-DX-WEBHOOK-RAW-BODY`** and **`ACCRUE-DX-WEBHOOK-SECRET-MISSING`** with repo-relative troubleshooting paths; VERIFY-01 authority remains under **#proof-and-verification**.

## Task Commits

1. **Task 1: Troubleshooting — anchor convention** — `ca94902`
2. **Task 2: Webhooks — raw-body deep link** — `20929a3`
3. **Task 3: First Hour — troubleshooting pointers** — `56d2da6`
4. **Task 4: Host README — troubleshooting scent** — `76df86c`

## Deviations from Plan

None.

## Issues Encountered

Plan acceptance used `rg -c` (match line count); consolidated single-line links failed the “≥3 lines” check — fixed by one troubleshooting link per blockquote line.

## Next Phase Readiness

Phase 52+ can build on consistent anchor vocabulary without changing `setup_diagnostic.ex` codes.

## Self-Check: PASSED

- Plan-level `rg` / `head` acceptance checks re-run after edits — PASS
- `bash scripts/ci/verify_verify01_readme_contract.sh` — PASS

---
*Phase: 51-integrator-golden-path-docs · Plan 03*
