---
phase: 207-orchestration-digest-one-command-round-fix-loop
plan: 01
subsystem: testing
tags: [ui-ratchet, node, ndjson, convergence, deterministic-gate, forward-only]

# Dependency graph
requires:
  - phase: 206-adversarial-verifier-finding-ledger-deterministic-gate
    provides: "phase-ratchet-ledger.mjs deterministic reducer (fold/runReducer/computeRegressions/GUARD_HOME_SPECS/checkGuardRef/isSafeSpecPath), findings.ledger.ndjson, ledger.baseline.json"
provides:
  - "--next-round CLI mode: computes next round integer from rounds.ndjson, writes .round-next marker (D-47)"
  - "--seal-round CLI mode: D-48 4-clause dry conjunction + D-49 K=2/6-cap convergence classification, appends rounds.ndjson row, writes .round-status marker"
  - "committed empty append-only rounds.ndjson (ratchet-round-seal/1 schema)"
  - "exported GUARD_HOME_SPECS/checkGuardRef/isSafeSpecPath guard-token grammar (for 207-03 reuse) + computeNextRound"
affects: [207-04-digest, 207-05-ui-round-mix-task, 207-03-guard-mint, 208-convergence-slice]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Round-state event log: committed, append-only, absent/empty reads as [] (twins findings.ledger.ndjson convention)"
    - "Ephemeral scalar handoff markers (.round-next/.round-status) under gitignored test-results/, deliberately absent from DEFAULT_PATHS"
    - "Pure parameterized clause helpers + orchestrator split (computeClause*/sealRound), mirroring existing computeRegressions/runReducer split"
    - "Self-test fixtures on fs.mkdtempSync scratch roots — zero real-file mutation, save/restore process.exitCode + env for orchestrator-level fixture"

key-files:
  created:
    - accrue_admin/e2e/ratchet/rounds.ndjson
  modified:
    - accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs

key-decisions:
  - "Round markers live under test-results/ (gitignored), NOT DEFAULT_PATHS — they are ephemeral scalar handoffs to the later Elixir orchestrator, not gate-relevant committed artifacts"
  - "--seal-round ALWAYS exits 0 on the success path; the non-zero escalation contract belongs to the later Elixir ui.round task (207-05). Only a missing/non-numeric RATCHET_ROUND exits 1 (T-207-07) and appends nothing"
  - "consecutiveDry filters to the current epoch FIRST, then counts the trailing dry run — a streak never leaks across an epoch boundary (D-49)"
  - "Clause 3 & standing-regressions emptiness uses readNdjsonRows(path).length === 0, folding absent/0-byte/whitespace into one absence-safe predicate"

patterns-established:
  - "Round convergence reasoning lives entirely in the self-tested node reducer, never in Elixir (D-51)"
  - "Guard-token grammar is exported once and reused, never re-derived (Don't Hand-Roll — the failure mode Phase 206 flagged)"

requirements-completed: [ORCH-06]

coverage:
  - id: D1
    description: "--next-round computes next round integer (max+1, order-independent) and marker-writes it without touching any gate artifact"
    requirement: "ORCH-06"
    verification:
      - kind: unit
        ref: "node e2e/ratchet/phase-ratchet-ledger.mjs --self-test (fixture 0: computeNextRound empty->1, {1,3,2}->4)"
        status: pass
      - kind: integration
        ref: "node e2e/ratchet/phase-ratchet-ledger.mjs --next-round (real empty rounds.ndjson -> writes 1 to .round-next; git status shows ledger/baseline/regressions untouched)"
        status: pass
    human_judgment: false
  - id: D2
    description: "--seal-round computes the D-48 4-clause dry conjunction (new-opens, zero-open, regressions-empty, coverage-floor) and appends a ratchet-round-seal/1 row"
    requirement: "ORCH-06"
    verification:
      - kind: unit
        ref: "node e2e/ratchet/phase-ratchet-ledger.mjs --self-test (fixtures 6, 7a-7d: all-true->dry:true, each clause false->dry:false)"
        status: pass
      - kind: integration
        ref: "RATCHET_ROUND=1 node e2e/ratchet/phase-ratchet-ledger.mjs --seal-round (real empty ledger -> appends 1 row, status=continue, exit 0)"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-49 K=2/6-cap convergence classification with epoch-scoped streak counting; missing/non-numeric RATCHET_ROUND exits nonzero and appends nothing (T-207-07)"
    requirement: "ORCH-06"
    verification:
      - kind: unit
        ref: "node e2e/ratchet/phase-ratchet-ledger.mjs --self-test (fixtures 8-11: 2-consecutive->converged, older-epoch excluded, round6->cap-reached, missing-env->exit1/no-append)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Guard-token grammar helpers (GUARD_HOME_SPECS/checkGuardRef/isSafeSpecPath) + computeNextRound exported for later-plan reuse"
    requirement: "ORCH-06"
    verification:
      - kind: unit
        ref: "node -e import('./e2e/ratchet/phase-ratchet-ledger.mjs') -> typeof checkGuardRef === 'function'"
        status: pass
    human_judgment: false

# Metrics
duration: 5min
completed: 2026-07-05
status: complete
---

# Phase 207 Plan 01: Round-state machinery (--next-round / --seal-round) Summary

**Extended the Phase-206 deterministic ratchet reducer with a `--next-round` counter handoff and a `--seal-round` D-48 4-clause dry conjunction + D-49 K=2/6-cap convergence classifier, backed by a committed append-only `rounds.ndjson` and 22 zero-mutation self-test assertions.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-05T00:11:14Z
- **Completed:** 2026-07-05T00:15:49Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 extended)

## Accomplishments
- `--next-round` CLI mode: pure `computeNextRound` (max round + 1, order-independent) marker-writes the next round integer to `.round-next` and touches zero gate artifacts.
- `--seal-round` CLI mode: computes the D-48 4-clause dry conjunction (zero new opens this round, zero open remaining, both regression files empty, coverage floor met), appends one `ratchet-round-seal/1` row to `rounds.ndjson`, classifies D-49 convergence (K=2 consecutive dry → `converged`; 6-round cap → `cap-reached`; else `continue`), and writes the `.round-status` marker — always exiting 0 on success, exiting 1 only on a missing/non-numeric `RATCHET_ROUND`.
- New committed, empty, append-only `rounds.ndjson` — the single source of truth for "has the ratchet converged yet."
- Exported `GUARD_HOME_SPECS`/`checkGuardRef`/`isSafeSpecPath` (guard-token grammar) plus `computeNextRound`, so 207-03's guard-mint reuses the grammar instead of re-deriving it.

## Task Commits

Each task was committed atomically:

1. **Task 1: `--next-round` + committed `rounds.ndjson` + guard-grammar exports** - `0c63e76b` (feat)
2. **Task 2: `--seal-round` 4-clause dry conjunction + K=2/6-cap convergence** - `12df7c06` (feat)

_Both tasks are `tdd="true"`; verification is the in-file `--self-test` fixture harness. Each commit added its fixtures + implementation together and was proven green by `--self-test` before commit (the reducer's test spine is the self-test, not a separate test file)._

## Files Created/Modified
- `accrue_admin/e2e/ratchet/rounds.ndjson` - New committed, empty, append-only round-state event log (`ratchet-round-seal/1` rows).
- `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` - Extended with `computeNextRound`, the 7 pure round/clause helpers, `readCellsCensus`/`bundleSha256`, the `sealRound` orchestrator, `--next-round`/`--seal-round` CLI branches, round-state path constants, a static `SURFACES` import, guard-grammar + `computeNextRound` exports, and 7 new self-test fixtures (fixture 0 + fixtures 6–11).

## Decisions Made
- Round markers (`.round-next`/`.round-status`) live under the already-gitignored repo-root `test-results/` tree and are deliberately excluded from `DEFAULT_PATHS` — they are ephemeral scalar handoffs to the later Elixir orchestrator, not gate-relevant committed artifacts (no new `.gitignore` entry needed).
- `--seal-round` never aborts mid-pipeline: it always exits 0 on the success path so the digest (207-04) can render before the Elixir `ui.round` task (207-05) reads the status marker and decides escalation. The only non-zero exit is the `RATCHET_ROUND` validation guard (T-207-07), which appends nothing.
- `computeConsecutiveDry` filters rows to the current epoch *before* counting the trailing dry run, so a dry streak can never leak across an epoch boundary (D-49).
- Emptiness checks (Clause 3 + standing regressions) reuse `readNdjsonRows(path).length === 0`, collapsing absent / 0-byte / whitespace-only into one absence-safe predicate consistent with the rest of the file.

## Deviations from Plan

None - plan executed exactly as written. Both tasks implemented per the `<action>` specs; all acceptance criteria and the full `<verification>` (self-test green + real `--next-round`/`--seal-round` round-trip, repo restored clean) passed.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The `rounds.ndjson` schema (`ratchet-round-seal/1`) and the two marker files (`.round-next`, `.round-status`) are the load-bearing contract 207-04 (digest) and 207-05 (`ui.round` mix task) read — both are now established and self-test-proven.
- `GUARD_HOME_SPECS`/`checkGuardRef`/`isSafeSpecPath` are importable, unblocking 207-03's guard-mint.
- No blockers. The real ledger currently classifies `continue` (coverage-floor clause fails on the Phase-200 census's `gap` cells), which is the expected pre-convergence state.

## Self-Check: PASSED

---
*Phase: 207-orchestration-digest-one-command-round-fix-loop*
*Completed: 2026-07-05*
