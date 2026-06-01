---
phase: 159-linked-release-readiness-publish-proof
plan: "01"
subsystem: release
tags: [release-please, hex, github-actions, verification-ledger]
requires:
  - phase: 158-oban-cron-wiring-adopter-proof
    provides: prior linked-line release baseline and host proof contracts
provides:
  - three-package manifest alignment verifier including accrue_portal
  - phase 159 release verification ledger with deterministic gate evidence
  - release runbook instructions for PR/TARGET/RUN ledger recording
affects: [release-process, ci-gates, linked-publish-proof]
tech-stack:
  added: []
  patterns: [append-only verification ledger, three-package lockstep release proof]
key-files:
  created:
    - .planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md
  modified:
    - scripts/ci/verify_release_manifest_alignment.sh
    - scripts/ci/capture_linked_release_proof.sh
    - scripts/ci/README.md
    - RELEASING.md
key-decisions:
  - "Do not fabricate REL-03 completion: record blocker because no post-1.3.0 Release Please PR exists."
  - "Run deterministic bundle locally and map evidence rows to canonical CI job ids in the ledger."
patterns-established:
  - "Release proof uses one append-only phase ledger keyed by PR_NUMBER/TARGET_VERSION/RUN_ID."
  - "Manifest/version lockstep checks must always include accrue, accrue_admin, and accrue_portal."
requirements-completed: [REL-02]
duration: 43m
completed: 2026-05-31
---

# Phase 159 Plan 01: Linked Release Readiness + Publish Proof Summary

**Three-package release proof scaffolding was hardened and deterministic gates were captured, while real publish proof remained blocked by missing post-1.3.0 Release Please intent.**

## Performance

- **Duration:** 43m
- **Started:** 2026-05-31T17:33:00Z
- **Completed:** 2026-05-31T18:16:54Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Expanded `verify_release_manifest_alignment.sh` to enforce lockstep across `accrue`, `accrue_admin`, and `accrue_portal`.
- Created `159-VERIFICATION.md` with fixed schema and appended deterministic gate evidence rows mapped to release CI job ids.
- Updated release documentation and CI gate map to use the Phase 159 ledger and explicit proof chain.
- Attempted publish-phase proof commands and recorded real blockers instead of claiming release completion.

## Task Commits

1. **Task 1: Harden the three-package proof surfaces and seed the Phase 159 ledger** - `113d3918` (feat)
2. **Task 2: Audit release intent and run deterministic gate bundle** - `dbf42fe7` (fix)
3. **Task 3: Ordered publish + post-publish truth capture** - `05223da3` (fix, blocker evidence only)

## Files Created/Modified
- `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` - Canonical release ledger with gate evidence and blocker recovery path.
- `scripts/ci/verify_release_manifest_alignment.sh` - Three-package manifest/mix lockstep enforcement.
- `scripts/ci/capture_linked_release_proof.sh` - Added release file snapshot and HexDocs availability capture.
- `scripts/ci/README.md` - REL-01/02/03 mapping and Phase 159 proof-chain ownership.
- `RELEASING.md` - Explicit ledger-recording steps and fallback-only publish workflow guidance.

## Decisions Made
- No open Release Please PR exists for a version after `1.3.0`; REL-01 and REL-03 cannot be truthfully completed yet.
- Deterministic gate bundle was executed and recorded with command/job mapping to preserve release-proof continuity.

## Deviations from Plan

### Auto-fixed Issues

None.

### External Blockers

1. Missing release intent:
- **Found during:** Task 2
- **Issue:** `gh pr list --state open` returned no Release Please PR; manifest target stayed `1.3.0`, already published.
- **Impact:** Could not set real `PR_NUMBER`, `TARGET_VERSION` (> `1.3.0`), or run publish proof for the next linked line.
- **Recorded in:** `159-VERIFICATION.md` pre-merge audit + recovery state.

2. Host Hex smoke failure in current local host route state:
- **Found during:** Task 3
- **Issue:** `bash scripts/ci/accrue_host_hex_smoke.sh` failed with `attempting to redefine live_session :accrue_admin`.
- **Impact:** Host Hex smoke proof for the pending next release line remains unresolved locally.
- **Recorded in:** `159-VERIFICATION.md` under `Host Hex smoke`.

## Authentication Gates

None.

## Issues Encountered

- `scripts/ci/accrue_host_uat.sh` and `scripts/ci/accrue_host_hex_smoke.sh` produce generated/example-host workspace drift in this checkout. These changes were intentionally not staged.

## Known Stubs

None.

## Threat Flags

None.

## Next Phase Readiness

- REL-02 deterministic proof scaffolding is ready.
- To complete REL-01 and REL-03, maintainers need:
1. A new combined Release Please PR targeting a version after `1.3.0`.
2. Successful Release Please publish run id for that target.
3. Clean host route state for `accrue_host_hex_smoke.sh`.

## Self-Check: PASSED
