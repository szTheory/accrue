---
phase: 31-advisory-integration-alignment
plan: 01
subsystem: testing
tags: [verify-01, playwright, readme, ci]

requires: []
provides:
  - Mobile VERIFY-01 README/CI parity anchors
  - npm e2e:mobile shortcut matching a11y pattern
  - Filesystem guard for README-listed verify01 specs
affects: []

tech-stack:
  added: []
  patterns:
    - "Tier A require_substring + Tier B grep file-exists loop before sk_live awk gate"

key-files:
  created: []
  modified:
    - scripts/ci/verify_verify01_readme_contract.sh
    - examples/accrue_host/README.md
    - examples/accrue_host/package.json

key-decisions:
  - "Keep sk_live negation awk block unchanged; loop runs before it."

patterns-established:
  - "README verify01 spec paths are extracted with grep -oE and checked under examples/accrue_host/"

requirements-completed: [INV-03, MOB-01, MOB-03, A11Y-03]

duration: 15min
completed: 2026-04-21
---

# Phase 31: Advisory integration alignment — Plan 01 Summary

**VERIFY-01 contract now enforces mobile anchors, validates listed spec files exist, and documents `npm run e2e:mobile` beside the a11y lane.**

## Performance

- **Duration:** ~15 min
- **Tasks:** 4
- **Files modified:** 3

## Accomplishments

- Extended `verify_verify01_readme_contract.sh` with mobile spec path + mobile shell heading checks and a README-driven file-exists loop.
- Added `e2e:mobile` npm script mirroring `e2e:a11y`.
- README VERIFY-01 section documents mobile shortcut, `chromium-mobile`, and POSIX `env -u NO_COLOR` with a Windows escape hatch.

## Task Commits

1. **Task 1: Tier A — script anchors for mobile VERIFY-01** — `dd6df7d` (feat)
2. **Task 2: Tier B — README-listed verify01 spec paths exist** — `ce88047` (feat)
3. **Task 3: package.json — add e2e:mobile** — `99177fc` (feat)
4. **Task 4: README — document e2e:mobile next to e2e:a11y** — `3f36617` (docs)

## Files Created/Modified

- `scripts/ci/verify_verify01_readme_contract.sh` — mobile `require_substring` lines + verify01 spec path existence loop
- `examples/accrue_host/package.json` — `e2e:mobile` script
- `examples/accrue_host/README.md` — VERIFY-01 mobile + NO_COLOR prose

## Deviations

None

## Self-Check: PASSED

- `bash scripts/ci/verify_verify01_readme_contract.sh` — OK
- `node -e` check for `e2e:mobile` script — OK
- `rg` acceptance criteria from plan — OK
