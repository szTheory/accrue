---
phase: 218-apple-observation-and-repair
plan: "02"
subsystem: payments
tags: [apple, entitlements, dependency-security, verifier]
requires:
  - phase: 218-01
    provides: Apple observation intake behind a private verification seam
provides:
  - Explicit rejection of `app_store_server_library` for Accrue
  - Locked Accrue-owned Apple verifier fallback for Plan 218-03
affects: [218-03, apple-verifier, dependency-policy]
tech-stack:
  added: []
  patterns:
    - Human package-legitimacy decisions select the private implementation path without weakening verifier gates
key-files:
  created:
    - .planning/phases/218-apple-observation-and-repair/218-02-SUMMARY.md
  modified: []
key-decisions:
  - "Rejected app_store_server_library 2.2.0; do not install or evaluate it further."
  - "Plan 218-03 must implement Accrue.Entitlements.Apple.Verifier privately using host-owned Finch and configured trust inputs, with no separate verifier dependency."
requirements-completed: []
coverage:
  - id: D1
    description: Explicit blocking legitimacy decision selects the private Apple verifier path.
    verification:
      - kind: manual_procedural
        ref: "User checkpoint response: rejected"
        status: pass
      - kind: other
        ref: "git diff --quiet -- mix.exs mix.lock"
        status: pass
    human_judgment: false
duration: 3min
completed: 2026-08-03
status: complete
---

# Phase 218 Plan 02: Verify the candidate Apple server package identity Summary

**The candidate `app_store_server_library` was rejected, locking Plan 218-03 to an Accrue-owned private verifier with no additional verifier dependency.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-08-03T14:15:00Z
- **Completed:** 2026-08-03T14:18:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Recorded the explicit human response: `rejected`.
- Locked the fallback for Plan 218-03: private `Accrue.Entitlements.Apple.Verifier`; Accrue owns implementation, while host applications retain Finch and trust/config inputs.
- Preserved the full D-05/D-06 verification contract: no verifier dependency, package evaluation, or reduced hostile-chain, API, supervision, privacy, or dependency gates.
- Confirmed `mix.exs` and `mix.lock` remain unchanged.

## Task Commits

The checkpoint produced no application-code or dependency changes. This summary is committed as the plan metadata record.

1. **Task 1: Verify the candidate Apple server package identity** - no task commit (blocking human decision recorded in this summary)

## Files Created/Modified

- `.planning/phases/218-apple-observation-and-repair/218-02-SUMMARY.md` - durable package-decision record and fallback contract for Plan 218-03.

## Decisions Made

- The user rejected `app_store_server_library` under Accrue's dependency-minimization philosophy.
- Plan 218-03 must not install or evaluate the rejected package. It must implement the locked private fallback behind `Accrue.Entitlements.Apple.Verifier`, with no separate package or verifier dependency.
- The fallback does not relax Apple verification requirements: strict independent JWS verification and all existing D-05/D-06 security, privacy, supervision, and admission requirements remain binding.

## Deviations from Plan

None - the plan explicitly permits a rejection and defines the existing-dependency fallback.

## Issues Encountered

None.

## User Setup Required

None - this plan adds no external configuration.

## Next Phase Readiness

Plan 218-03 can proceed directly with the locked Accrue-owned fallback. It must leave `mix.exs` and `mix.lock` unchanged, keep the verifier private, and continue to require host-owned Finch plus trust/configuration inputs.

## Self-Check: PASSED

- Summary exists at the required phase path.
- `mix.exs` and `mix.lock` have no diff, so no candidate package was installed.

---
*Phase: 218-apple-observation-and-repair*
*Plan: 02*
*Completed: 2026-08-03*
