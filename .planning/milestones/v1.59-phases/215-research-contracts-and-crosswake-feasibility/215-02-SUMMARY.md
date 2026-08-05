---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 02
subsystem: research-governance
tags: [research-authority, amendments, watchlist, shell-verifier, exunit]
requires:
  - phase: 215-01
    provides: Crosswake feasibility evidence and Phase 215 research context
provides:
  - v1.59 authority manifest with explicit precedence and active policy
  - stable amendment/supersession ledger and dated reassessment workflow
  - deterministic authority/watchlist drift gate with malformed-fixture coverage
affects: [216-rail-foundation, 217-projection, 218-apple-repair, 219-offline-contract, 220-release-proof]
tech-stack:
  added: [Bash verifier, ExUnit fixture coverage]
  patterns: [ROOT_DIR-injected documentation gate, stable watchlist tuple identity]
key-files:
  created:
    - .planning/research/v1.59-AUTHORITY.md
    - .planning/research/v1.59-AMENDMENTS.md
    - scripts/ci/verify_v159_authority.sh
    - accrue/test/accrue/docs/v159_authority_docs_test.exs
  modified:
    - .planning/research/RESEARCH-INDEX.md
    - .planning/research/v1.59-WATCHLIST.md
key-decisions:
  - "The adjacent amendment ledger is the authority-level record for routine material claim changes; standalone ADRs/RFCs remain reserved for broad public-contract decisions."
  - "Watchlist equality is the literal monitor/trigger/owner/response tuple; duplicate or incomplete rows fail closed."
requirements-completed: [RSCH-01, RSCH-03]
coverage:
  - id: D1
    description: v1.59 authority manifest and amendment ledger preserve precedence and the no-independent-72-hour policy.
    requirement: RSCH-01
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_v159_authority.sh
        status: pass
    human_judgment: false
  - id: D2
    description: Watchlist ownership, row completeness, duplicate rejection, and dated reassessment behavior fail closed.
    requirement: RSCH-03
    verification:
      - kind: unit
        ref: accrue/test/accrue/docs/v159_authority_docs_test.exs
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-07-31
status: complete
---

# Phase 215 Plan 02: Research Authority and Watchlist Governance Summary

**A single v1.59 authority entry point now locks policy precedence, preserves claim history, and mechanically rejects malformed watchlist governance.**

## Performance

- **Duration:** 12 min
- **Completed:** 2026-07-31
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added the first-entry v1.59 authority manifest with the exact D-02 six-level precedence, accepted policy, effective date, review state, and linked research bundle.
- Recorded stable, effective-dated amendment claims, including the history-preserving supersession of independent 72-hour cutoff formulations.
- Added a ROOT_DIR-injectable, fail-closed authority verifier and fixture-driven ExUnit coverage for authority, ledger, and watchlist drift.
- Replaced ambiguous watchlist ownership with stable row IDs, Phase 215–220 runbooks, complete response tuples, review metadata, and dated reassessment rules.

## Task Commits

1. **Task 1: Establish the authority manifest and amendment ledger** — `6de5b67e` (docs)
2. **Task 2: Enforce authority and watchlist completeness (RED)** — `9d2382eb` (test)
3. **Task 2: Enforce authority and watchlist completeness (GREEN)** — `ef7c9e06` (feat)

## Verification

- `bash scripts/ci/verify_v159_authority.sh` — passed.
- `cd accrue && mix test test/accrue/docs/v159_authority_docs_test.exs` — passed (5 tests).

## Decisions Made

- Routine provider and dependency findings update the stable amendment ledger through a dated reassessment; they are not policy acceptance and do not require standalone ADR/RFC documents.
- The verifier treats null, empty, singleton-incomplete, and duplicate watchlist tuples as invalid, while preserving deterministic source order for unique rows.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Issues Encountered

None.

## Next Phase Readiness

Phases 216–220 can resolve v1.59 policy questions through the authority manifest and must record provider/dependency changes as dated reassessments before changing entitlement behavior.

## Self-Check: PASSED

- Confirmed all six key files exist and all three task commits are present in git history.
