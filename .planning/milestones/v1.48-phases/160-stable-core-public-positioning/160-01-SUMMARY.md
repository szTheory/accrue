---
phase: 160-stable-core-public-positioning
plan: "01"
subsystem: docs
tags: [positioning, stable-core, guides, readme]
requires: []
provides: [POS-01, POS-02]
affects: [README.md, accrue/README.md, accrue/guides/first_hour.md, accrue/guides/jobs_to_be_done.md, accrue/guides/maturity-and-maintenance.md]
tech_stack: [markdown, rg, bash]
key_files:
  - README.md
  - accrue/README.md
  - accrue/guides/first_hour.md
  - accrue/guides/jobs_to_be_done.md
  - accrue/guides/maturity-and-maintenance.md
decisions:
  - Public posture standardized to "stable-core / demand-driven expansion" with explicit reopen triggers.
  - First Hour remains a thin setup mirror, while doctrine lives in Maturity and scope narrative lives in JTBD.
metrics:
  completed_at: 2026-05-31T21:30:14Z
---

# Phase 160 Plan 01: Stable-Core Public Positioning Summary

**Stable-core posture language and reopen-trigger doctrine shipped across root/core landing pages plus the First Hour, JTBD scope, and Maturity guide spine.**

## Performance

- Duration: ~20 minutes
- Completed: 2026-05-31T21:30:14Z
- Tasks: 2/2
- Files modified: 5

## Accomplishments

- Repositioned [README.md](/Users/jon/projects/accrue/README.md) and [accrue/README.md](/Users/jon/projects/accrue/accrue/README.md) to state stable-core posture, documented-facade boundary, and evidence-based reopen triggers.
- Tightened guide ownership across [first_hour.md](/Users/jon/projects/accrue/accrue/guides/first_hour.md), [jobs_to_be_done.md](/Users/jon/projects/accrue/accrue/guides/jobs_to_be_done.md), and [maturity-and-maintenance.md](/Users/jon/projects/accrue/accrue/guides/maturity-and-maintenance.md).
- Preserved cross-link spine between root, core README, setup guide, scope narrative, and maturity doctrine.

## Verification Evidence

- `bash scripts/ci/verify_package_docs.sh` (passed after Task 1, Task 2, and final run)
- `rg -n 'stable-core / demand-driven expansion|canonical SaaS billing loop|concrete adopter failure mode|correctness/security/data-loss risk|repeated support issue|operational failure|explicit strategy change' README.md accrue/README.md accrue/guides/first_hour.md accrue/guides/jobs_to_be_done.md accrue/guides/maturity-and-maintenance.md` (passed)

## Commits

- `ee3cd540` — `docs(160-01): reposition root and core docs for stable-core posture`
- `4c9afd98` — `docs(160-01): tighten canonical guide spine for stable-core posture`

## Deviations from Plan

None - plan executed as written.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/160-stable-core-public-positioning/160-01-SUMMARY.md`
- Referenced commits found in git history: `ee3cd540`, `4c9afd98`
