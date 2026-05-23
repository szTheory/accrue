---
phase: 124-enforcement-surfaces-plug-liveview-guards
plan: 05
subsystem: docs
tags: [liveview, phoenix_component, entitlements, doc-reconciliation, runtime-liveview-free, oban]

# Dependency graph
requires:
  - phase: 124-01
    provides: ":entitlements guard config + :surface OTel allowlist (the entitlements surface this doc reconcile describes)"
provides:
  - "CLAUDE.md, ROADMAP.md SC#3, PITFALLS.md Pitfall #8, oban/middleware.ex moduledoc, and the mix.exs dep comment all reconciled from the factually-false 'core is LiveView-FREE / no LiveView present / phoenix_live_view absent-or-optional' claim to the accurate 'core stays LiveView-runtime-free' posture (D-06 lockstep)"
  - "ROADMAP SC#3 re-framed to the static merge-gate invariant (no always-compiled core module references the LiveView socket runtime), not the infeasible 'compiles with no LiveView present'"
affects: [124-06, 125, 126]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Doc/wording reconciliation in lockstep with the code PR (mirrors Phase 123 D-16 plural-telemetry reconcile, and v1.39's same-PR doc-honesty discipline)"

key-files:
  created:
    - .planning/phases/124-enforcement-surfaces-plug-liveview-guards/124-05-SUMMARY.md
  modified:
    - CLAUDE.md
    - .planning/ROADMAP.md
    - .planning/research/PITFALLS.md
    - accrue/lib/accrue/oban/middleware.ex
    - accrue/mix.exs

key-decisions:
  - "REQUIREMENTS.md ENT-07 left untouched — it already reads 'runtime-LiveView-free' (verified before editing, per plan notes); no edit needed."
  - "mix.exs dep line {:phoenix_live_view, \"~> 1.1\"} kept NON-optional (D-02); only the surrounding comment was extended."
  - "oban/middleware.ex change kept as a doc comment (moduledoc) so it stays allowlisted by the Plan 06 static merge gate (gate-clean verified)."

patterns-established:
  - "Invariant framing: 'no always-compiled core module references the LiveView socket runtime (Phoenix.LiveView / on_mount / Socket)' — replaces 'core compiles with no LiveView present' everywhere it appeared."

requirements-completed: [ENT-07]

# Metrics
duration: 3min
completed: 2026-05-23
---

# Phase 124 Plan 05: D-06 LiveView-runtime-free Doc Reconciliation Summary

**Every project artifact that claimed core `accrue` is 'LiveView-FREE / compiles with no LiveView present / phoenix_live_view absent-or-optional in core' is now reconciled to the accurate 'core stays LiveView-runtime-free' posture, with ROADMAP SC#3 pointing at the static merge-gate invariant instead of the infeasible compile-cell.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-23T12:20:52Z
- **Completed:** 2026-05-23T12:23:22Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- **CLAUDE.md** — the optional-deps line and the `phoenix_live_view` stack-table row now state it is a **required** (non-optional) core dep providing `Phoenix.Component`/`~H` for the email + invoice render spine and the cond-compiled `on_mount` guard, while core stays runtime-LiveView-free (no socket runtime, never in `extra_applications`).
- **ROADMAP.md** — SC#3 re-framed from "compiles and loads with no LiveView present" to "a merge-blocking CI check proves no always-compiled core module references the LiveView socket runtime (Phoenix.LiveView / on_mount / Socket)"; the line-133 "LiveView-free constraint" note re-framed to the runtime-free posture and the now-resolved "verify the live mix.exs at planning time" clause closed out (verified non-optional).
- **PITFALLS.md Pitfall #8** — corrected from "guard belongs in `accrue_admin`/opt-in, LV absent from core" to "guard lives in cond-compiled CORE `lib/accrue/live/entitlements.ex` via the Sigra 4-pattern; phoenix_live_view is already a required core dep; the real invariant is no-socket-runtime-in-always-compiled-core, enforced by a static merge gate." Fixed the warning-sign bullet, the Phase-to-address line, and the tech-debt / integration-gotcha / "Looks Done But Isn't" / recovery / pitfall-to-phase-mapping rows; also corrected the stale source-summary line (376). The genuine pitfalls (ordering-vs-auth, redirect loop, gate-after-expensive-mount, resolve-once, fail-closed-on-missing-current_user) and the controller-Plug-guidance were left intact.
- **oban/middleware.ex** — the `## LiveView integration` moduledoc rewritten from "LiveView is a hard dependency of `accrue_admin` only, never `accrue`." to "LiveView's socket runtime is never coupled in core; phoenix_live_view is a required core dep for Phoenix.Component (...); core stays runtime-LiveView-free." Stays a doc comment, gate-clean.
- **mix.exs** — the comment above `{:phoenix_live_view, "~> 1.1"}` now states it is a REQUIRED (non-optional) core dep for the email + invoice spine AND the cond-compiled guard, with no LiveView socket runtime in always-compiled code and never in `extra_applications`. The dep line itself is unchanged and still non-optional (D-02).

## Task Commits

Each task was committed atomically:

1. **Task 1: Reconcile CLAUDE.md + ROADMAP.md + mix.exs comment to LiveView-runtime-free** - `7c951ed` (docs)
2. **Task 2: Reconcile PITFALLS.md Pitfall #8 + oban/middleware.ex moduledoc** - `d002251` (docs)

_Task 2's commit was amended to fold in the residual stale-claim fix at PITFALLS.md:376 (same file, same D-06 logical change)._

## Files Created/Modified

- `CLAUDE.md` - optional-deps line + phoenix_live_view stack-table row reconciled to runtime-LiveView-free
- `.planning/ROADMAP.md` - SC#3 + line-133 LiveView-free note re-framed to the static socket-runtime merge gate
- `.planning/research/PITFALLS.md` - Pitfall #8 (and its summary-table/recovery/mapping rows + the source-summary line) corrected to cond-compile-in-core
- `accrue/lib/accrue/oban/middleware.ex` - `## LiveView integration` moduledoc corrected; remains a gate-clean doc comment
- `accrue/mix.exs` - comment above the (still non-optional) phoenix_live_view dep clarified

## Decisions Made

- REQUIREMENTS.md ENT-07 already read "runtime-LiveView-free"; diffed before touching, made no edit (matches the plan's pre-verified note).
- Kept the mix.exs dep line non-optional (D-02) — only the comment changed.
- Kept the oban edit a doc comment so the Plan 06 static gate continues to allowlist it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Reconciled one extra stale source-summary line in PITFALLS.md**
- **Found during:** Task 2 (post-edit residual stale-claim sweep)
- **Issue:** PITFALLS.md line 376 (the Sources section's PROJECT.md summary) still paraphrased the false "core stays LiveView-free" claim — outside the line numbers the plan enumerated, but squarely within the D-06 reconciliation intent ("every artifact that claimed ... is reconciled").
- **Fix:** Re-worded to "core stays runtime-LiveView-free — phoenix_live_view required for Phoenix.Component, no socket-runtime coupling."
- **Files modified:** .planning/research/PITFALLS.md
- **Verification:** `grep 'LiveView-free' ... | grep -v 'runtime-LiveView-free'` returns nothing across all five reconciled files.
- **Committed in:** d002251 (folded into Task 2 commit via amend)

---

**Total deviations:** 1 auto-fixed (1 missing-critical completeness fix)
**Impact on plan:** Necessary for the plan's own success criterion ("every artifact ... reconciled"). No scope creep — same file, same change family.

## Issues Encountered

- The Task 1 acceptance criteria required the literal phrase "socket runtime" in the mix.exs comment; my first draft used "LiveView socket runtime" split across "...runtime-free" and a separate "Socket" token. Adjusted the comment to contain the contiguous phrase "LiveView socket runtime" before committing — `grep -c 'socket runtime' accrue/mix.exs` then returned 1.

## Verification

- `grep -c 'no LiveView present' .planning/ROADMAP.md` → 0 ✓
- `grep -c 'stays LiveView-free' CLAUDE.md` → 0 ✓
- CLAUDE.md contains "runtime-free" (2 occurrences) ✓
- ROADMAP SC#3 + line-133 note contain "socket runtime" (2) ✓
- mix.exs comment contains "socket runtime" (1) and "extra_applications" (2); dep line still `{:phoenix_live_view, "~> 1.1"}` non-optional ✓
- oban/middleware.ex: no "never accrue" (0); contains "socket runtime"/"required core dep" (2) ✓
- Gate regex over oban/middleware.ex → GATE-CLEAN (still a doc comment) ✓
- `cd accrue && mix compile --warnings-as-errors` → exit 0 (both tasks) ✓
- No genuinely-stale "LiveView-free" string remains across all five files (all are "runtime-LiveView-free") ✓

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 06 (the merge-blocking static LiveView-runtime-free CI gate) can now point readers at honest docs: SC#3 and the ROADMAP note already describe the exact invariant the gate enforces, and the oban/middleware.ex doc comment is confirmed gate-clean.
- No blockers.

---
*Phase: 124-enforcement-surfaces-plug-liveview-guards*
*Completed: 2026-05-23*

## Self-Check: PASSED

- All 5 reconciled files + the SUMMARY exist on disk.
- Both task commits (`7c951ed`, `d002251`) exist in git history.
