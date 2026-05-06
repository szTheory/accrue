---
phase: 107-rendro-release-optional-chromic-path
plan: 02
subsystem: infra
tags: [rendro, hex, release, dependency-proof]
requires:
  - phase: 107-rendro-release-optional-chromic-path
    provides: "A stable invoice renderer contract ready for published Rendro release proof"
provides:
  - "Accrue now resolves Rendro from Hex at `~> 0.1.0` instead of a sibling path dependency"
  - "A checked-in clean-checkout proof lane for Hex-backed Rendro resolution"
  - "A maintainer runbook that records the Rendro publish-handoff order"
affects: [phase-108, release-runbook, dependency-management]
tech-stack:
  added: [rendro-hex-0.1.0]
  patterns: [clean-checkout-dependency-proof, published-dependency-handoff]
key-files:
  created:
    - scripts/ci/verify_rendro_hex_resolution.sh
  modified:
    - accrue/mix.exs
    - accrue/mix.lock
    - RELEASING.md
key-decisions:
  - "Resolve Rendro from Hex with `~> 0.1.0` so consumer semantics match maintainer semantics."
  - "Make the proof lane clone the repo and overlay the current workspace diff, which keeps the check useful before commit while still validating a temp checkout."
patterns-established:
  - "Release-sensitive dependency handoffs should ship with a checked-in clean-checkout proof script, not only a local maintainer note."
requirements-completed: [PDF-07]
duration: 1 run
completed: 2026-05-06
---

# Phase 107 Plan 02 Summary

**Accrue now consumes Rendro the same way external users do: from Hex at `~> 0.1.0`, with a checked-in clean-checkout proof lane and a release runbook that codifies the publish order.**

## Performance

- **Duration:** 1 run
- **Started:** 2026-05-06T16:20:00Z
- **Completed:** 2026-05-06T16:25:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Replaced the temporary `path: "../../rendro"` dependency with `{:rendro, "~> 0.1.0"}` and refreshed `accrue/mix.lock` to a Hex-backed `rendro` entry.
- Added `scripts/ci/verify_rendro_hex_resolution.sh` to prove a temp checkout resolves Rendro from Hex and rejects any lingering `../../rendro` path dependency.
- Updated `RELEASING.md` so the runbook explicitly records the order publish Rendro → confirm Hex availability → cut Accrue over → run the clean-checkout proof.

## Task Commits

No atomic task commits were created in this execution. The dependency cutover and runbook proof were completed directly in the existing dirty workspace and verified in-place.

## Files Created/Modified

- `accrue/mix.exs` - switched Rendro from a local path dependency to `{:rendro, "~> 0.1.0"}`.
- `accrue/mix.lock` - now records Rendro as a Hex package at `0.1.0`.
- `RELEASING.md` - codifies the Rendro publish handoff and proof step.
- `scripts/ci/verify_rendro_hex_resolution.sh` - temp-clone proof lane for Hex-backed Rendro resolution.

## Decisions Made

- Kept the version requirement at `~> 0.1.0` exactly as planned instead of widening or exact-pinning it.
- Preserved a shell-only proof lane so the release verification path stays easy to run in CI and maintainer workspaces.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Because the working tree was already dirty, the proof script had to apply the current workspace diff into the temp clone so the verification lane could validate the actual local state before any future commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 108 can now treat the Rendro Hex dependency as settled and focus on the remaining migration/docs closeout plus the final proof sweep.
- Release closeout has a durable scriptable proof artifact instead of depending on maintainer-local sibling repos.

## Self-Check

PASSED

- `cd accrue && mix deps.get` resolved Rendro from Hex and updated the lockfile to `0.1.0`.
- `bash scripts/ci/verify_rendro_hex_resolution.sh` passed from a temp clone.
- `rg -n '\{:rendro, "~> 0\.1\.0"\}' accrue/mix.exs` matched and `rg -n 'path:\s*"../../rendro"' accrue/mix.exs` returned no matches.
