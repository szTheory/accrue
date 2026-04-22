---
phase: 46-release-train-hex-publish
plan: "02"
subsystem: testing
tags: [ci, bash, jq, rel-02, release-please]

requires: []
provides:
  - Deterministic manifest ↔ mix.exs @version verifier script
  - Merge-blocking CI job release-manifest-ssot wired before annotation-sweep
affects: [ci, release-please]

tech-stack:
  added: []
  patterns:
    - "REL-02 preflight as a fast ubuntu job using jq + sed only (no secrets)"

key-files:
  created:
    - "scripts/ci/verify_release_manifest_alignment.sh"
  modified:
    - ".github/workflows/ci.yml"

key-decisions:
  - "Fail when manifest accrue/accrue_admin versions differ or either mismatches mix.exs."

patterns-established:
  - "annotation_sweep.sh receives release-manifest-ssot so warning annotations on that job fail the sweep."

requirements-completed: [REL-02]

duration: 15min
completed: 2026-04-22
---

# Phase 46 — Plan 02 summary

**REL-02 SSOT is enforced by a tracked bash+jq script and a new merge-blocking `release-manifest-ssot` job ahead of the annotation sweep.**

## Performance

- **Tasks:** 2
- **Files modified:** 2 (1 create)

## Accomplishments

- Added `verify_release_manifest_alignment.sh` (executable in git) comparing `.release-please-manifest.json` to both packages’ `@version` lines with lockstep enforcement.
- Inserted early CI job and extended `annotation-sweep` `needs` + sweep CLI args; documented job id in `ci.yml` header contract.

## Task commits

1. **Task 1: Add verify_release_manifest_alignment.sh** — `8519445` (feat)
2. **Task 2: Wire release-manifest-ssot job into CI** — `9a80931` (ci)

## Deviations from plan

None.

## Issues encountered

None.

## Self-Check: PASSED

- `bash scripts/ci/verify_release_manifest_alignment.sh` → OK
- `rg -n 'release-manifest-ssot' .github/workflows/ci.yml` → present in job key, needs, and sweep invocation
