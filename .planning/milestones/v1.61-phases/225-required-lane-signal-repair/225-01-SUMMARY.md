---
phase: 225-required-lane-signal-repair
plan: 01
subsystem: ci-testing
tags: [ci, exunit, ecto, oban, playwright, incident-triage]
requires: []
provides:
  - "Privacy-safe normalized incident index for the release webhook and Admin page-flow signatures"
  - "Event-owned webhook ingest assertions with same-identity replay coverage"
  - "External-API coverage declaration for first-party CI proof surfaces"
affects: [225-02, 225-03, release-gate, admin-hardening-guardrails]
tech-stack:
  added: []
  patterns:
    - "CI incident records lead with classification, one narrow command, and immutable evidence"
    - "Webhook tests scope persistence assertions by the created event identity"
key-files:
  created:
    - .planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md
    - .planning/phases/225-required-lane-signal-repair/COVERAGE.md
  modified:
    - scripts/ci/README.md
    - accrue/test/accrue/webhook/ingest_test.exs
key-decisions:
  - "Treat identical release-matrix webhook failures as one test-isolation incident with required and advisory cells visibly separated."
  - "Use persisted event identity for webhook, dispatch-job, and ledger assertions instead of suite-global cardinality."
  - "Rename the success-only co-presence test rather than claim unproven rollback behavior."
patterns-established:
  - "Tests that inspect shared persistence tables must predicate every assertion on the owned entity identity."
requirements-completed: [REL-01, REL-03]
coverage:
  - id: D1
    description: "Normalized, privacy-safe incident records and command-first maintainer triage for the two active signatures."
    requirement: REL-01
    verification:
      - kind: other
        ref: "225-01 incident-index static verification command"
        status: pass
    human_judgment: false
  - id: D2
    description: "Webhook ingest facts and same-identity replay are isolated by the persisted event identity."
    requirement: REL-03
    verification:
      - kind: integration
        ref: "cd accrue && mix test test/accrue/webhook/ingest_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D3
    description: "Phase-local declaration excludes first-party CI proof surfaces from external-API integration coverage."
    verification:
      - kind: other
        ref: "COVERAGE.md static verification command"
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-09
status: complete
---

# Phase 225 Plan 01: Required-Lane Signal Repair Summary

**Two privacy-safe CI incident records now route maintainers to exact repro commands, while webhook ingest tests prove only event-owned persistence facts.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-08-09T03:21:59Z
- **Completed:** 2026-08-09T03:29:59Z
- **Tasks:** 3/3
- **Files modified:** 4

## Accomplishments

- Created one causal record per active normalized signature, visibly separating three required release cells from advisory Sigra and preserving Actions artifacts as the raw-evidence home.
- Added a command-first triage section that names the canonical source file for both release webhook and Admin page-flow incidents.
- Replaced whole-table webhook observations with event, dispatch-job, and ledger predicates; same-identity replay stays deterministic and the success-only test no longer claims rollback proof.
- Declared that Phase 225 changes first-party ExUnit, Playwright, GitHub Actions, and maintainer-evidence contracts rather than an external API integration.

## Task Commits

1. **Task 1: Trace both active signatures from failure to one command and one causal record** — `731a76cf` (docs)
2. **Task 2: Replace webhook global observations with event-owned positive and duplicate-negative contracts** — `1c46755f` (test, RED), `8706e743` (fix, GREEN)
3. **Task 3: Create the external-API coverage declaration** — `cde2bfd7` (docs)

## Files Created/Modified

- `.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md` — normalized incident index with immutable Actions links and pending-proof statuses.
- `.planning/phases/225-required-lane-signal-repair/COVERAGE.md` — no-external-API integration decision.
- `scripts/ci/README.md` — narrow commands and canonical repair surfaces for Phase 225 incidents.
- `accrue/test/accrue/webhook/ingest_test.exs` — identity-scoped webhook, Oban, and ledger assertions.

## Decisions Made

- The release-matrix signature remains one test-isolation incident; Floor, Primary dev target, and OpenTelemetry are `[required]`, while Sigra remains `[advisory]`.
- Admin page-flow evidence records the 210-cycle / 60-second capacity diagnosis but leaves corrective browser work for Plan 225-02.
- The TDD red step introduced an unrelated webhook event and confirmed the previous suite-global assertion failed before the identity-scoped GREEN change.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The RED test failed as intended: adding an unrelated event made the former whole-table `WebhookEvent` cardinality assertion observe two rows.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 225-02 can partition the Admin Phase 191 traversal and repair its generated-evidence truth while retaining this incident record as the causal source.
- Fresh repair-commit Actions proof remains pending and is intentionally not represented as passed.

## Self-Check: PASSED

- Confirmed all four task artifacts exist and all four task commits are present in git history.
- Re-ran the incident-index static verification and `cd accrue && mix test test/accrue/webhook/ingest_test.exs --warnings-as-errors` (5 tests, 0 failures).
