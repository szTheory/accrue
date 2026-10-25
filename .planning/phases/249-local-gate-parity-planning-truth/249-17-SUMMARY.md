---
phase: 249-local-gate-parity-planning-truth
plan: "17"
subsystem: phase-close-evidence
status: complete
completed: 2026-10-25
requirements-completed: [GREEN-01, GREEN-02, GREEN-03, GREEN-04, GREEN-05, TRUTH-01, TRUTH-02]
tags: [phase-close, covered-digest, executable-uat, sl-e, sl-g]
key-files:
  created:
    - .planning/phases/249-local-gate-parity-planning-truth/249-mint-close-artifacts.mjs
    - .planning/phases/249-local-gate-parity-planning-truth/249-VERIFICATION.md
    - .planning/phases/249-local-gate-parity-planning-truth/249-UAT.md
  modified:
    - .planning/STATE.md
    - .planning/REQUIREMENTS.md
commits: COMMITS_PLACEHOLDER
plan_head_before: 6898c27f4e5c151a66939b713c5531a66bd5a9d3
plan_head_after: HEAD_AFTER_PLACEHOLDER
actuals:
  tasks: 2
  commits: COMMITS_PLACEHOLDER
coverage:
  - id: R1
    description: GREEN-01 every planning-doc contract step of docs-contracts-shift-left passes locally with its ci.yml command
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "node scripts/ci/verify_completion_evidence.mjs --repo . --require-completion-evidence --require-table-agreement"
        status: pass
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --job docs-contracts-shift-left --run --skip SL-F --skip tokens-steps (final replay recorded in the Final replay section)"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_artifact_fixed_point.mjs --repo . --require-acyclic --require-fixed-point --require-digest-match"
        status: pass
    human_judgment: false
  - id: R2
    description: GREEN-02 accrue_admin compiles with warnings as errors and the admin guardrail jobs reach their real assertions
    requirement: GREEN-02
    verification:
      - kind: command
        ref: "cd accrue_admin && MIX_ENV=test mix compile --force --warnings-as-errors (249-01 and 249-13 ledgers)"
        status: pass
    human_judgment: false
  - id: R3
    description: GREEN-03 DSY-01 breakpoint annotations and D-32 module-boundary guards pass
    requirement: GREEN-03
    verification:
      - kind: command
        ref: "node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor"
        status: pass
    human_judgment: false
  - id: R4
    description: GREEN-04 Phase 190 automation contract and Phase 190/192 probes pass with every probe classified
    requirement: GREEN-04
    verification:
      - kind: command
        ref: "bash scripts/ci/verify_phase190_automation_contract.sh"
        status: pass
      - kind: command
        ref: "grep -c -E '\\| (stale-contract|regression) \\|' .planning/phases/249-local-gate-parity-planning-truth/249-PROBE-CLASSIFICATION.md"
        status: pass
    human_judgment: false
  - id: R5
    description: GREEN-05 package suites and host mix phases proven locally; host dev-boot/browser and Playwright E2E routed to Phase 250 per the reworded requirement
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "grep -qF -e 'Routed to Phase 250 (custody: no local preview DB; maintainer decision 2026-10-25)' .planning/phases/249-local-gate-parity-planning-truth/249-REPLAY-HOST.md"
        status: pass
      - kind: command
        ref: "grep -qF -e 'Routed to Phase 250 (custody: no local preview DB; maintainer decision 2026-10-25)' .planning/phases/249-local-gate-parity-planning-truth/249-REPLAY-E2E.md"
        status: pass
      - kind: command
        ref: "node --test --test-reporter=tap scripts/ci/test_accrue_host_preview_custody.mjs (28 pass, 0 fail, recorded in 249-18)"
        status: pass
    human_judgment: false
  - id: R6
    description: TRUTH-01 stale HANDOFF.json removed, STATE.md reflects v1.67, resolved debug sessions filed
    requirement: TRUTH-01
    verification:
      - kind: command
        ref: "test ! -e .planning/HANDOFF.json && test -f .planning/debug/resolved/phase245-browser-capture-stall.md && grep -c -e '^current_phase: 249$' .planning/STATE.md"
        status: pass
    human_judgment: false
  - id: R7
    description: TRUTH-02 out-of-band owner-feedback commits recorded in MILESTONES.md and STATE.md with note receipts and no backdated verification
    requirement: TRUTH-02
    verification:
      - kind: command
        ref: "grep -c -e '3d7d949d..b4a7eeac' .planning/MILESTONES.md .planning/STATE.md"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 17: Phase Close Summary

Phase 249 closes with a re-runnable mint helper that derives `covered_files`, computes `covered_digest` only through `computeDigest`, and generates `249-UAT.md` only through `generateAutomatedUat`. GREEN-01..05 and TRUTH-01..02 are marked Complete after `249-VERIFICATION.md` reached `status: passed` with `behavior_unverified: 0`.

## What was built

- `249-mint-close-artifacts.mjs`: idempotent ESM helper (repo root from `git rev-parse --show-toplevel`, no home-path literals). Running it twice leaves the tree unchanged.
- `249-VERIFICATION.md`, `249-UAT.md`: tracked, digest-bound, `human_judgment: false` throughout.
- STATE.md: `current_phase: 249` re-asserted plus the Phase 250 hand-off note. REQUIREMENTS.md: seven rows Complete (LAND-* and RLS-* stay Pending).

## Routed to Phase 250

Phase 250 must prove remotely, on the exact integration head SHA, everything the local environment cannot honestly run:

| Lane | Reason |
|------|--------|
| host-integration dev-boot smoke | custody decision 2026-10-25 (no local preview DB), runs under CI absent-mode from 249-18 |
| host-integration browser lane | same custody decision |
| host-integration assert-preserved | same custody decision |
| host Hex smoke (published-tag leg) | tags do not point at this checkout locally |
| playwright-e2e shards 1-3 | custody decision 2026-10-25 (81 tests listed non-vacuously in 249-15, not executed) |
| host-docker-smoke | Docker is off-limits locally |
| Linux visual-regression baselines (accrue_admin_browser.yml) | baselines are Linux-only; CI diff first, re-mint by workflow_dispatch only for an intentional change |

## Phase 250 hand-off

SL-G and executable-UAT always read the current phase. When Phase 250 starts it must flip `current_phase: 250` and mint its own tracked VERIFICATION (with `covered_files` and `covered_digest`) and its generated UAT in the same step or commit sequence, then re-run SL-G and executable-UAT before it pushes. Flipping the phase without the artifacts turns those gates red again.

## Deviations from Plan

- The plan's verify requires `git status --porcelain` to be empty, but the maintainer-instructed untracked `.planning/milestone.lock` must stay. Cleanliness is checked with `--untracked-files=no`; the lock is the only untracked path.
- NEGATIVE_CONTROLS_PLACEHOLDER

## Self-Check: PENDING
