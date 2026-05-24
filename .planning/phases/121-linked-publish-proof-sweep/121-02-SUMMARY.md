---
phase: 121-linked-publish-proof-sweep
plan: 02
subsystem: release
tags: [release, publish, recovery, blocker]

# Dependency graph
requires:
  - phase: 121-linked-publish-proof-sweep
    provides: exact `PR_NUMBER` and `TARGET_VERSION` markers from Plan 01
provides:
  - Exact merge-bound workflow run identifier for the linked release attempt
  - Honest blocker record for the failed portal publish
affects: [phase-121, release recovery path, post-publish proof]

# Tech tracking
tech-stack:
  added: []
  patterns: [run-id-bound-ledger, partial-release-failure-record]

key-files:
  created:
    - .planning/phases/121-linked-publish-proof-sweep/121-02-SUMMARY.md
  modified:
    - .planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md

key-decisions:
  - "Bind Plan 02 to the merge-triggered Release Please run on the exact merge commit instead of using a 'latest run' shortcut."
  - "Treat the failed `accrue_portal` dry run as a real release blocker, not a warning to paper over."
  - "Stop before public-proof capture and docs cleanup because the linked trio did not actually finish publishing."

requirements-completed: []

# Metrics
duration: ~20m
completed: 2026-05-08
---

# Phase 121 Plan 02: Merge path blocked on portal publish

**Plan 02 did not complete. PR `#21` merged and produced tags plus GitHub releases for `1.1.0`, but the merge-triggered Release Please run `25533304999` failed before `accrue_portal` could publish to Hex.**

## Evidence
- Revalidated the merged PR with `bash scripts/ci/verify_release_pr_scope.sh --pr 21 --version 1.1.0`.
- Bound the publish attempt to merge commit `5cd030760bc5930d565b82d9a912dff860eafb14` and workflow run `25533304999`.
- Confirmed ordered job outcomes:
  - `publish-accrue` -> success
  - `publish-accrue-admin` -> success
  - `publish-accrue-portal` -> failure
- Captured the failing dry-run error from the portal job log: `Missing files: LICENSE*`.
- Confirmed the public state is partial:
  - `accrue` on Hex: `1.1.0`
  - `accrue_admin` on Hex: `1.1.0`
  - `accrue_portal` on Hex: `404`

## Blocking outcome
- `REL-11` remains incomplete.
- `121-VERIFICATION.md` now records `RUN_ID: 25533304999` and the exact failure mode.
- Phase 121 cannot continue to public-proof capture or post-publish mirror cleanup until the portal publish is recovered or replaced by a new linked release line.

## Self-Check: FAILED

---
*Phase: 121-linked-publish-proof-sweep*
*Completed: 2026-05-08*
