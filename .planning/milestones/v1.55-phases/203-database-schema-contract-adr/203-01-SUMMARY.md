---
phase: 203-database-schema-contract-adr
plan: 01
subsystem: database
tags: [postgres, ecto, schema-prefix, adr, upgrade]

requires:
  - phase: 201-software-quality-evaluation
    provides: software-quality schema-prefix risk framing
  - phase: 202-ci-cd-performance-and-determinism-audit
    provides: Phase 204 handoff precedent and audit-only boundary pattern
provides:
  - Accepted database schema contract ADR for DB-01 through DB-04
  - Phase 204 DB schema-prefix hardening handoff rows
  - Explicit no-code-change boundary proof for Phase 203
affects: [204-ranked-hardening-roadmap, database, upgrade, installer, docs]

tech-stack:
  added: []
  patterns:
    - Hybrid accepted ADR: normative current contract plus advisory future hardening.
    - Layered schema contract surfaces: executable sources of truth separated from docs/test mirrors.
    - Phase 204 handoff rows carry evidence, impact, tradeoff, verification, rollback, and non-goals.

key-files:
  created:
    - .planning/phases/203-database-schema-contract-adr/203-01-SUMMARY.md
  modified:
    - .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md

key-decisions:
  - "Keep `billing` as the default Accrue-owned Postgres schema for v1.55 and v1.x."
  - "Keep explicit `public` as a supported opt-out, not a deprecated path."
  - "Reject default `accrue` for v1.55 because `billing.accrue_*` is clearer and avoids default-rename upgrade risk."
  - "Treat Phase 204 schema-prefix checks as advisory implementation work, not Phase 203 shipped behavior."

patterns-established:
  - "ADR support contracts should name executable authority separately from mirror surfaces."
  - "Database hardening handoffs should state rollback and non-goals alongside implementation approach."

requirements-completed: [DB-01, DB-02, DB-03, DB-04]

duration: 6m 12s
completed: 2026-07-02
status: complete
---

# Phase 203 Plan 01: Database Schema Contract ADR Summary

**Accepted ADR locking `billing` as the default Accrue-owned Postgres schema, preserving explicit `public`, rejecting a default `accrue` rename, and handing rankable schema-prefix hardening checks to Phase 204.**

## Performance

- **Duration:** 6m 12s
- **Started:** 2026-07-02T22:37:29Z
- **Completed:** 2026-07-02T22:43:41Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Expanded `203-DB-SCHEMA-CONTRACT-ADR.md` into an accepted hybrid ADR with current contract, authoritative surfaces, compatibility warning, consequences, non-goals, verification, requirement coverage, and phase boundary sections.
- Replaced vague future work with a Phase 204 handoff table for default constant centralization, prefix-agreement assertions, compatibility lanes, raw SQL qualification, installer/docs coverage, and host-owned data migration boundaries.
- Preserved Phase 203 as ADR-only work: no source, migrations, installer, public docs mirror, CI, package metadata, runtime schema, example host, or product files changed.

## Task Commits

Each task was committed atomically:

1. **Task 1: Lock Current Schema Contract In The ADR** - `a51f5b06` (docs)
2. **Task 2: Replace Future Work Prose With Phase 204 Handoff** - `0f54e37d` (docs)
3. **Task 3: Close Compatibility, Non-Goals, And Verification** - `ecf3f129` (docs)

## Files Created/Modified

- `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` - Accepted database schema contract ADR.
- `.planning/phases/203-database-schema-contract-adr/203-01-SUMMARY.md` - Execution summary and verification record.

## Verification

- Task 1 gate passed for `billing`, `public`, compile-time config, `Accrue.Config`, `Accrue.Schema`, `Accrue.Migration`, code evidence paths, `config/config.exs`, `config/runtime.exs`, and required MUST/MAY/MUST NOT contract language.
- Task 2 gate passed for the Phase 204 handoff table columns and rows, including prefix-agreement, schema-prefix, raw SQL, `--billing-schema public`, First Hour, Upgrade, example-host, qualified table usage, and local DB-schema-contract ranking language.
- Task 3 gate passed for DB-01 through DB-04 coverage rows, pin-before-recompile language, explicit `public` and `billing` config examples, host-owned migration boundary, non-goals, implementation milestone language, and schema-push exclusion.
- Overall phase gate passed for all plan-level ADR terms and `test -z "$(git diff --name-only -- accrue accrue_admin accrue_portal examples .github scripts)"`.

## Boundary Evidence

The working tree began with unrelated dirty planning files. Those files were not staged or committed by this plan. Plan-owned commits touched only `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md`; the summary commit adds only this summary file.

## Decisions Made

- `billing` remains the default because it names the Phoenix billing domain and already avoids accidental `public` pollution.
- Explicit `public` remains supported for hosts that intentionally want Accrue tables in the default schema.
- `accrue` is not the default because `accrue.accrue_*` is redundant and a default rename creates upgrade-sensitive lookup risk.
- Phase 204 owns final cross-audit ordering for schema hardening; Phase 203 supplies only local DB-schema-contract inputs.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

No plan issues. One supplemental acceptance grep was rerun after shell quoting misparsed backticked terms; the required task gate had already passed and no artifact changes were needed.

## Known Stubs

None.

## Authentication Gates

None.

## Threat Flags

None - the plan created an ADR artifact only and introduced no new network endpoints, auth paths, file access patterns, schema changes, workflow changes, release automation changes, or trust-boundary code.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 204 can consume the final ADR and rank DB schema-prefix hardening against Phase 201 software-quality and Phase 202 CI/CD findings.

## Self-Check: PASSED

- ADR artifact exists: `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md`
- Summary artifact exists: `.planning/phases/203-database-schema-contract-adr/203-01-SUMMARY.md`
- Task commits exist: `a51f5b06`, `0f54e37d`, `ecf3f129`
- Product/runtime diff boundary preserved: no changes under `accrue`, `accrue_admin`, `accrue_portal`, `examples`, `.github`, or `scripts`

---
*Phase: 203-database-schema-contract-adr*
*Completed: 2026-07-02*
