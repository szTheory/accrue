---
phase: 249-local-gate-parity-planning-truth
plan: "11"
subsystem: ci-local-replay
status: complete
completed: 2026-10-24
requirements-completed: [GREEN-01, GREEN-03]
tags: [replay, docs-contracts-shift-left, pending-close]
key-files:
  created:
    - .planning/phases/249-local-gate-parity-planning-truth/249-LOCAL-REPLAY.md
key-decisions:
  - "SL-E real run now fails with 'marked Complete but no *-VERIFICATION.md' rather than the plan's 'zero Complete requirements' text, because earlier plans marked GREEN-01..05/TRUTH-01/02 Complete; recorded as a PENDING-CLOSE deviation, resolved by 249-17"
commits: 1
plan_head_before: 0f802db0e13fe0dcd9fc53b27335a6e5bb3d6737
plan_head_after: a749c77b
actuals:
  tokens: 15000
  tasks: 2
  commits: 1
coverage:
  - id: C1
    description: docs-contracts-shift-left replays green (41 PASS, 0 red) with only SL-F, tokens mutators and close gates skipped
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "python3 249-replay-ci-job.py --job docs-contracts-shift-left --run --skip SL-F --skip tokens steps --skip close gates (PASS=41 SKIP=7)"
        status: pass
    human_judgment: false
  - id: C2
    description: node --test, --fixtures, --self-test and --all-opted-in halves of the three close gates exit 0
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "verify_completion_evidence / verify_artifact_fixed_point / verify_executable_uat_contract halves (6 commands, all rc 0)"
        status: pass
    human_judgment: false
  - id: C3
    description: release-manifest-ssot, phase18-tax-gate and ios-offline-client replay green
    requirement: GREEN-03
    verification:
      - kind: command
        ref: "249-replay-ci-job.py --job release-manifest-ssot|phase18-tax-gate (--skip Install Hex)|ios-offline-client --run"
        status: pass
    human_judgment: false
  - id: C4
    description: SL-G and exec-UAT real runs fail only with their permitted PENDING-CLOSE text; SL-E fails close-only with a deviating text (documented)
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "node scripts/ci/verify_artifact_fixed_point.mjs --repo . ... ; node scripts/ci/verify_executable_uat_contract.mjs --all-since 229"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 11: Docs-contracts and small-job replay Summary

Replayed docs-contracts-shift-left (41 PASS, 0 red) plus release-manifest-ssot, phase18-tax-gate and ios-offline-client (all green) at HEAD 0f802db0, and created the 249-LOCAL-REPLAY.md ledger.

## Deviations from Plan

**1. [Plan assumption stale] SL-E PENDING-CLOSE text differs.**
- Plan permitted `zero Complete requirements parsed from the traceability table`. Observed: `GREEN-01 is marked Complete but no *-VERIFICATION.md exists in .../249-local-gate-parity-planning-truth`.
- Cause: earlier plans (249-01/03/06) ran `requirements mark-complete`, so the table now has Complete rows; the gate advanced to its next check. No source defect, gate not weakened; it clears when 249-17 writes VERIFICATION.md.
- Consequence: the plan's single-chain automated verify would fail on the SL-E clause; every other clause was run and passed. Recorded in the ledger. Not reverted (reverting the Complete marks would undo prior plans' state updates).

SL-F (PR body currency) skipped, routed to Phase 250. Tokens install/regenerate/determinism skipped, run in scratch clone in 249-14.

## Self-Check: PASSED

Ledger exists and is committed (a749c77b).
