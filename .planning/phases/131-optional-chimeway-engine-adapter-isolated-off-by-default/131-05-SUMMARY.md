---
phase: 131-optional-chimeway-engine-adapter-isolated-off-by-default
plan: 05
subsystem: infra
tags: [ci, shell, isolation-gate, dunning, chimeway]

# Dependency graph
requires:
  - phase: 131-03
    provides: Accrue.Dunning.Engine behaviour + cond-compiled Chimeway adapter
  - phase: 131-04
    provides: Chimeway adapter docs, guides, and config schema
provides:
  - scripts/ci/verify_dunning_chimeway_isolation.sh — merge-blocking static isolation gate (DUN-03 D-04)
  - CI wiring: "Dunning core stays Chimeway-free (DUN-03 D-04)" step in docs-contracts-shift-left job
affects:
  - Any future PR touching billing/dunning.ex, workers/dunning_step.ex, or dunning/campaign.ex

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shift-left isolation gate pattern: grep with ^[^#]* anchor on a specific file list exits 1 on real code couplings, passes on comment-only mentions"
    - "Three always-on dunning files scanned by path, not whole-lib glob, so the cond-compiled adapter is structurally excluded"

key-files:
  created:
    - scripts/ci/verify_dunning_chimeway_isolation.sh
  modified:
    - .github/workflows/ci.yml

key-decisions:
  - "Use ^[^#]* anchor in grep pattern (not post-grep -v filter) to strip comment lines — matches the existing verify_core_liveview_runtime_free.sh and verify_entitlement_sync_isolation.sh precedents"
  - "Scan only the three always-on file paths (not the whole lib tree) so the conditionally-compiled lib/accrue/integrations/chimeway.ex adapter is excluded by scope, not by an allowlist filter"
  - "Wire as step in docs-contracts-shift-left job immediately after the entitlement sync isolation gate — same merge-blocking job, consistent placement"

patterns-established:
  - "Isolation gate precedent: shift-left merge gate for off-by-default optional integrations (Chimeway) mirrors the ENT-10 D-04 advisory-cache isolation gate"

requirements-completed: [DUN-03]

# Metrics
duration: 2min
completed: 2026-05-25
---

# Phase 131 Plan 05: Dunning Chimeway Isolation Gate Summary

**Shift-left merge gate `verify_dunning_chimeway_isolation.sh` that fails the build if any always-on dunning file references Chimeway, wired into CI as a named merge-blocking step (DUN-03 D-04)**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-25T16:30:43Z
- **Completed:** 2026-05-25T16:33:09Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments
- Created `scripts/ci/verify_dunning_chimeway_isolation.sh` (executable, 69 lines): shift-left gate that greps the three always-on dunning files for `Accrue.Integrations.Chimeway|Chimeway\.` with a `^[^#]*` anchor to strip comment lines, exits 1 on any real coupling, exits 0 when clean
- Verified all acceptance criteria: gate passes against HEAD, comment-only ref does not trip gate, real `Accrue.Integrations.Chimeway.run(state)` ref correctly trips gate (exit 1)
- Wired the gate into `.github/workflows/ci.yml` as `"Dunning core stays Chimeway-free (DUN-03 D-04)"` step in the `docs-contracts-shift-left` job, immediately after the entitlement sync isolation gate

## Task Commits

Each task was committed atomically:

1. **Task 1: Create verify_dunning_chimeway_isolation.sh + wire into CI** - `f811a719` (feat)

**Plan metadata:** (committed with SUMMARY.md)

## Files Created/Modified
- `scripts/ci/verify_dunning_chimeway_isolation.sh` - Shift-left isolation gate: greps billing/dunning.ex, workers/dunning_step.ex, dunning/campaign.ex for Chimeway refs; exits 1 on real coupling, 0 when clean
- `.github/workflows/ci.yml` - Added "Dunning core stays Chimeway-free (DUN-03 D-04)" step after line 53 in docs-contracts-shift-left job

## Decisions Made

- **grep anchor vs post-filter:** Used `^[^#]*` embedded in the grep pattern (not a separate `grep -v '^[[:space:]]*#'` pipe) because the grep output has `filename:linenum:` prefixes that would prevent the naïve post-filter from stripping comment lines. The `^[^#]*` anchor matches only when the symbol appears before any `#` in the raw file line — identical to the existing `verify_core_liveview_runtime_free.sh` and `verify_entitlement_sync_isolation.sh` precedents.

- **Target scope (file list, not whole-lib glob):** The gate scans exactly three named paths instead of `${lib} --include='*.ex'` so the cond-compiled `lib/accrue/integrations/chimeway.ex` adapter is excluded by construction (it is never included in the scan targets), not by a fragile `grep -v` allowlist on the output.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed incorrect comment-stripping approach during acceptance-criterion testing**
- **Found during:** Task 1 (negative-check acceptance criteria verification)
- **Issue:** Initial implementation used `| grep -v '^[[:space:]]*#'` as a post-filter, but the grep output includes `filename:linenum:` prefixes, so lines whose *source* starts with `#` do not start with `#` in the output — the filter silently failed to strip comment lines
- **Fix:** Replaced with `^[^#]*` anchor embedded in the primary grep pattern, matching the existing `verify_core_liveview_runtime_free.sh` and `verify_entitlement_sync_isolation.sh` precedent
- **Files modified:** scripts/ci/verify_dunning_chimeway_isolation.sh
- **Verification:** Acceptance-criterion check passed: comment-only `# Chimeway.trigger` line in campaign.ex did NOT trip gate; real `Accrue.Integrations.Chimeway.run(state)` line DID trip gate (exit 1)
- **Committed in:** f811a719 (Task 1 commit — fix applied before commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug in grep pipeline logic)
**Impact on plan:** Critical correctness fix — without it the gate would silently pass on comment-only Chimeway mentions while failing to provide the documented allowlist behavior. Fixed and verified before task commit.

## Issues Encountered
- macOS BSD `head` does not support `head -n -1` (Linux-only flag) — used `python3` to trim test lines from campaign.ex during acceptance-criterion testing. No impact on shipped artifact.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- DUN-03 requirement is fully satisfied: the `Accrue.Dunning.Engine` behaviour, off-by-default cond-compiled Chimeway adapter (Plans 01-04), and the isolation merge gate (Plan 05) are all in place
- Phase 131 is complete; Phase 132 (entitlements adopter-proof demo, PROOF-03) can proceed

---
*Phase: 131-optional-chimeway-engine-adapter-isolated-off-by-default*
*Completed: 2026-05-25*
