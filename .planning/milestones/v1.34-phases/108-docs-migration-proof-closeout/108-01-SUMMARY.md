---
phase: 108-docs-migration-proof-closeout
plan: 01
subsystem: docs
tags: [rendro, chromicpdf, pdf, migration, docs]
requires:
  - phase: 106-invoice-renderer-seam-rendro-default
    provides: invoice renderer seam and Rendro-first default behavior
  - phase: 107-rendro-release-optional-chromic-path
    provides: explicit Chromic fallback contract and Hex-backed Rendro handoff
provides:
  - Rendro-first front-door package docs
  - Canonical three-state invoice PDF migration guidance
  - Upgrade pointer into the PDF migration contract
affects: [README, first-hour, production-readiness, configuration, pdf-guide, upgrade-guide]
tech-stack:
  added: []
  patterns: [layered pointer docs, canonical migration section in deep guide]
key-files:
  created:
    - .planning/milestones/v1.34-phases/108-docs-migration-proof-closeout/108-01-SUMMARY.md
  modified:
    - accrue/README.md
    - accrue/guides/first_hour.md
    - accrue/guides/production-readiness.md
    - accrue/guides/configuration.md
    - accrue/guides/pdf.md
    - accrue/guides/upgrade.md
key-decisions:
  - "Kept README, First Hour, and Production Readiness as short Rendro-first pointers while leaving migration detail in guides/pdf.md."
  - "Documented the three locked host migration states in guides/pdf.md and explicitly rejected invoice-renderer inference from :pdf_adapter."
patterns-established:
  - "Front-door docs point to the canonical PDF guide instead of duplicating renderer setup."
  - "Migration guidance lives in one deep guide section, with upgrade docs acting only as a pointer."
requirements-completed: [PDF-08, PDF-09]
duration: 7min
completed: 2026-05-06
---

# Phase 108 Plan 01: Docs Migration Proof Closeout Summary

**Rendro-first package docs plus a canonical three-state invoice PDF migration section for legacy `:pdf_adapter` and ChromicPDF hosts**

## Performance

- **Duration:** 7 min
- **Started:** 2026-05-06T16:52:30Z
- **Completed:** 2026-05-06T16:59:32Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added Rendro-first, no-Chrome-needed guidance to the package README and First Hour flow, with pointers into the canonical PDF guide.
- Reframed production and configuration docs around `:invoice_pdf_adapter` ownership while preserving `:pdf_adapter` as the lower-level HTML seam.
- Added the dedicated Migration section in `accrue/guides/pdf.md` and linked the upgrade guide to it instead of duplicating the contract.

## Task Commits

Each task was committed atomically:

1. **Task 1: Surface the Rendro-first default in the package front door and operational pointers** - `328afa8` (docs)
2. **Task 2: Add the canonical migration section and short upgrade pointer** - `bcfe230` (docs)

## Files Created/Modified

- `accrue/README.md` - Added the front-door Rendro-first invoice PDF statement and PDF guide pointer.
- `accrue/guides/first_hour.md` - Added first-user expectation-setting that the default invoice path does not require Chrome.
- `accrue/guides/production-readiness.md` - Updated checklist wording to name `:invoice_pdf_adapter`, explicit Chromic setup, and invoice asset/font validation.
- `accrue/guides/configuration.md` - Kept config ownership concise and added the default `Accrue.InvoiceRenderer.Rendro` example.
- `accrue/guides/pdf.md` - Added the canonical three-state migration section and explicit non-inference wording.
- `accrue/guides/upgrade.md` - Added a short pointer into the PDF migration section.

## Decisions Made

- Kept the docs layered: README, First Hour, and Production Readiness stay short and link to `guides/pdf.md` for renderer and migration depth.
- Put all legacy host migration rules in `guides/pdf.md` so `upgrade.md` does not become a second source of truth.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `bash scripts/ci/verify_package_docs.sh` failed on an unrelated `.planning/PROJECT.md` contract (`gateway subscription core` missing). Per plan scope and file-ownership constraints, this was left untouched and not folded into the docs-only plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The front-door and canonical PDF docs now tell one Rendro-first story for `PDF-08` and `PDF-09`.
- Remaining verification work for Phase 108 can focus on the broader proof artifact and any advanced-guide cleanup planned in later work.

## Verification

- Task 1 acceptance checks: passed via `rg -n "Rendro|guides/pdf.md|Chrome|ChromicPDF|invoice_pdf_adapter|Accrue.InvoiceRenderer.Rendro|pdf_adapter" ...`
- Task 2 acceptance checks: passed via `rg -n "Migration|no action needed|invoice_pdf_adapter|pdf_adapter|Accrue.InvoiceRenderer.ChromicPDF|infer" ...`
- Plan-level docs verifier: `bash scripts/ci/verify_package_docs.sh` failed for out-of-scope `.planning/PROJECT.md`, not for the six plan-owned docs.

## Self-Check: PASSED

---
*Phase: 108-docs-migration-proof-closeout*
*Completed: 2026-05-06*
