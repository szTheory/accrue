---
phase: 152-close-v1-46-closure-gaps-since-warnings-verification-hex-pub
plan: "01"
subsystem: documentation
tags: [exdoc, elixir, compiler-warnings, annotations]

# Dependency graph
requires: []
provides:
  - "7 malformed @since annotations in dunning.ex converted to canonical @doc since: \"1.3.0\""
  - "1 malformed @since annotation in funnel_chart.ex converted to canonical @doc since: \"1.3.0\""
  - "Compiler warning elimination: module attribute @since was set but never used (dunning.ex:343)"
  - "verify_package_docs.sh exits 0 — no regressions"
affects:
  - "152-02: Three Zeros gate (mix compile --warnings-as-errors now passes in accrue)"
  - "152-03: Hex publish — all ExDoc badges are canonical for 1.3.0"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ExDoc @since badge: canonical form is @doc since: \"1.3.0\" as separate attribute after closing \"\"\" before @spec"

key-files:
  created: []
  modified:
    - "accrue/lib/accrue/analytics/dunning.ex"
    - "accrue_admin/lib/accrue_admin/components/funnel_chart.ex"

key-decisions:
  - "Fixed to version 1.3.0 per D-01 (not 1.4.0 which was in all stray annotations)"
  - "Prose :since option docs (e.g., * :since — %DateTime{} lower bound) left untouched — these are string content, not module attributes"
  - "Pre-existing accrue_admin warnings (Meeseeks.Error, MailglassInbound, StatusBadge) are out of scope for this plan; the @since warning is the only one introduced/tracked"

patterns-established:
  - "ExDoc since badge pattern: remove @since from inside heredoc body; add @doc since: \"version\" on its own line after closing triple-quote, before @spec"

requirements-completed: []

# Metrics
duration: 2min
completed: "2026-05-29"
---

# Phase 152 Plan 01: Fix @since Annotations Summary

**All 8 malformed `@since` annotations across two packages fixed to canonical `@doc since: "1.3.0"` form, eliminating the compiler warning in dunning.ex and ExDoc junk text from rendered output**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-29T21:31:43Z
- **Completed:** 2026-05-29T21:33:49Z
- **Tasks:** 3 (2 code edits + 1 verification)
- **Files modified:** 2

## Accomplishments

- Fixed 4 bare `@since "1.4.0"` lines embedded inside `@doc """ ... """` heredoc bodies in dunning.ex (lines 50, 98, 159, 224) — each removed from heredoc body and replaced with canonical `@doc since: "1.3.0"` after closing `"""`
- Fixed 2 free-floating `@since "1.4.0"` module attributes outside heredocs in dunning.ex (lines 333, 343) — replaced with `@doc since: "1.3.0"` in canonical placement; line 343 was the compiler warning source
- Fixed 1 already-canonical `@doc since: "1.4.0"` in dunning.ex (line 371) — version corrected from 1.4.0 to 1.3.0
- Fixed 1 bare `@since "1.4.0"` line inside `@doc """ ... """` heredoc in funnel_chart.ex (line 27) — removed from heredoc body, `@doc since: "1.3.0"` added after closing `"""`
- `mix compile --warnings-as-errors` exits 0 in accrue (no `@since` warning or other new warnings)
- `bash scripts/ci/verify_package_docs.sh` exits 0 — no regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix dunning.ex — 7 @since corrections** - `88d16460` (fix)
2. **Task 2: Fix funnel_chart.ex — 1 @since correction** - `5af7b87e` (fix)
3. **Task 3: Verify docs gate** - (verification only — no files modified, no commit)

## Files Created/Modified

- `accrue/lib/accrue/analytics/dunning.ex` — 7 `@since` fixes: 4 heredoc-embedded removals + 2 free-floating replacements + 1 version correction; all now `@doc since: "1.3.0"` in canonical ExDoc placement
- `accrue_admin/lib/accrue_admin/components/funnel_chart.ex` — 1 `@since` fix: heredoc-embedded removal + `@doc since: "1.3.0"` added after closing `"""`

## Decisions Made

- Targeted version `1.3.0` per locked decision D-01 (not `1.4.0` which was in all stray annotations)
- Prose `:since` option docs (e.g., `* :since — %DateTime{} lower bound`) left untouched — these are string content inside heredoc descriptions, not module attributes
- Pre-existing accrue_admin warnings (`Meeseeks.Error`, `MailglassInbound`, `StatusBadge`) confirmed as out of scope for this plan; `mix compile` without `--warnings-as-errors` exits 0 in accrue_admin with no new `@since` warnings

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None. `accrue_admin` `mix compile --warnings-as-errors` has pre-existing warnings unrelated to this plan's scope (Meeseeks.Error, MailglassInbound, StatusBadge). These are documented as pre-existing and do not affect this plan's success criteria. The plan's stated gate (`mix compile --warnings-as-errors` exits 0 in accrue, not accrue_admin) passes cleanly.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 01 complete: all 8 `@since` annotations corrected; D-02 fully satisfied
- `mix compile --warnings-as-errors` clean in accrue — prerequisite for Three Zeros gate (Plan 02)
- `verify_package_docs.sh` exits 0 — no regressions from annotation edits
- ExDoc will render `(since 1.3.0)` badges for all 8 functions/components (was rendering literal `@since "1.4.0"` junk text in ExDoc output for 7 of them)
- Plan 02 (Three Zeros gate) can proceed immediately

## Threat Flags

None — docstring metadata edits only, no new attack surface introduced.

---
*Phase: 152-close-v1-46-closure-gaps-since-warnings-verification-hex-pub*
*Completed: 2026-05-29*
