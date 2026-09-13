---
phase: 226-ci-baseline-proof-semantics
plan: "18"
subsystem: ci
tags: [github-actions, ci-baseline, provenance, playwright]
requires:
  - phase: 226-ci-baseline-proof-semantics
    provides: "Revision-bound exact-identity collector and complete-prerequisite admission controls"
provides:
  - "Fresh, privacy-safe 90-day canonical CI baseline with 20 complete staged paths"
  - "Byte-reproducible Markdown report and final validation ledger"
affects: [BASE-01, BASE-02, OWN-01]
tech-stack:
  added: []
  patterns: [declared-edge timing admission, read-only GitHub Actions collection, dual-render byte proof]
key-files:
  created: [.planning/phases/226-ci-baseline-proof-semantics/226-18-SUMMARY.md]
  modified:
    - scripts/ci/collect_ci_baseline.mjs
    - scripts/ci/verify_ci_baseline.mjs
    - .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson
    - .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md
    - .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md
decisions:
  - "Exclude Playwright timing only when its declared host-integration prerequisite is absent, skipped, or unsuccessful."
  - "Keep complete release → host-integration → Playwright paths eligible and retain exact matrix identity resolution."
metrics:
  duration: "~6 minutes"
  completed: "2026-08-12"
  tasks_completed: 1
status: complete
---

# Phase 226 Plan 18: Final CI Baseline Proof Summary

Fresh 90-day Actions evidence is now revision-bound, exact-identity admitted, privacy-safe, and byte-reproducible, with 20 complete release → host integration → Playwright paths (p50 2083s; p95 2602s).

## Accomplishments

- Added a failing-first regression proving Playwright timing is omitted when its declared `host-integration` prerequisite is absent, skipped, or unsuccessful; complete staged paths remain eligible.
- Recollected canonical NDJSON through authenticated, read-only Actions access and validated its critical path.
- Rendered the same records twice, byte-compared the renders, atomically replaced the canonical pair, and revalidated it.
- Updated the validation ledger with executed Plan 17 and Plan 18 rows; all 27 rows are green with zero behavior-unverified rows.

## Verification

- `gh auth status`
- Full Node schema/fixture, canonical critical-path, provider-proof, ExUnit formatter, setup-diagnostics, and inherited required-lane suite: PASS.
- Canonical report: 20 complete first-attempt staged paths; expected 33–36 minute path confirmed (p50 2083s; p95 2602s).

## Commits

- `52137bfe` `test(226-18): cover live Playwright matrix identity`
- `c7462418` `fix(226-18): resolve declared Playwright template identity`
- `efddf8f8` `test(226-18): exclude skipped live workflow nodes`
- `b1d21eec` `fix(226-18): omit skipped live CI nodes`
- `3ec6aff9` `perf(226-18): batch read-only Actions collection`
- `9f3d4433` `test(226-18): exclude incomplete annotation aggregate`
- `c39d735f` `fix(226-18): fail closed incomplete annotation timing`
- `1c17e0e6` `test(226-18): exclude incomplete host timing`
- `d6f04228` `fix(226-18): fail closed incomplete host timing`
- `c7cfd498` `test(226-18): exclude incomplete Playwright timing`
- `3fe565ee` `fix(226-18): require complete host before Playwright timing`

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 2 - Missing critical functionality] Added declared host-edge completeness for Playwright timing.
   - Found during: Task 1 live admission repair.
   - Fix: Exclude only `playwright-e2e` timing nodes whose declared `host-integration` prerequisite is absent, skipped, or unsuccessful; preserve complete staged paths and exact identity rejection.
   - Files modified: `scripts/ci/collect_ci_baseline.mjs`, `scripts/ci/verify_ci_baseline.mjs`.
   - Commits: `c7cfd498`, `3fe565ee`.

## Known Stubs

None.

## Self-Check: PASSED

- Canonical NDJSON, Markdown, validation ledger, and this summary exist.
- All task commits listed above exist in git history.
