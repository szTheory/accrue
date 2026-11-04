---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "18"
subsystem: acceptance-and-ci
tags: [ci, browser-uat, reporter-capture, acceptance-evidence, cache]

requires:
  - phase: 254
    provides: Reviewed subscription fixes, coverage records, CI measurements and curation evidence
provides:
  - Final attempt-1 CI and Browser UAT measurements tied to the final source commit
  - Truthful machine-generated acceptance evidence for the seven Phase 254 requirements
  - A complete per-task verification map with executed green commands
affects: [phase-254-closeout]

requirements-completed: [CIQ-02, CIQ-03, CIQ-04, UXQ-02, UXQ-04, CURATE-01, CURATE-02]

coverage:
  - id: C1
    description: "The required owner runs the deterministic Admin guardrails, including the subscription, isolation, quality-record and fixed-point checks."
    requirement: CIQ-02
    verification:
      - kind: command
        ref: "Phase 252 retained gate passed 21/21; Phase 253 serial aggregate passed all 12 lanes and retained 151 browser cells; Phase 254 quality aggregate passed 5/5; final required Admin owner run 41740924592 succeeded on attempt 1."
        status: pass
    human_judgment: false
  - id: C2
    description: "The required Browser UAT and visual regression gate pass against the committed baseline identity and the reviewed subscription states."
    requirement: CIQ-03
    verification:
      - kind: command
        ref: "Browser UAT run 41740924604 succeeded on attempt 1 at aa8dc46378555f56410a8f27a2e7cffe93266c62; the baseline-set and identity checks and Phase 211 visual gate passed, with all 32 Phase 254 visual cells retained."
        status: pass
    human_judgment: false
  - id: C3
    description: "Recurring quality cost is measured against the frozen allowances on the final source commit, with complete cell identity and timing evidence."
    requirement: CIQ-04
    verification:
      - kind: command
        ref: "phase254_budget.mjs check passed for the final attempt-1 runs; visual added time was 67 s and a11y added time was -175.356 s; all 151 a11y timings were retained (p90 2539 ms)."
        status: pass
    human_judgment: false
  - id: C4
    description: "Accessibility evidence covers the required subscription states and viewport/theme combinations with timing and content checks."
    requirement: UXQ-02
    verification:
      - kind: command
        ref: "Phase 254-11 edge tests and results bundles are bound into the generated acceptance record; the final Admin guardrails owner passed with the latest accessibility evidence and no dropped cells."
        status: pass
    human_judgment: false
  - id: C5
    description: "The reviewed visual corrections preserve the required design rubric, protected facts and baseline identity."
    requirement: UXQ-04
    verification:
      - kind: command
        ref: "The confirmed design review covers all seven rubric dimensions; native prohibition proof and the final visual identity gate passed; visual p90 was 1168 ms across 32 retained cells."
        status: pass
    human_judgment: false
  - id: C6
    description: "The curation and selection records remain current, deterministic and consistent with the committed subscription story manifest."
    requirement: CURATE-01
    verification:
      - kind: command
        ref: "Subscription manifest fixed-point and regenerated guide comparison passed; the curation verifier, selection projection check and Phase 254 quality aggregate passed on the final source commit."
        status: pass
    human_judgment: false
  - id: C7
    description: "The next-job and adopter guidance is grounded in recorded gaps, with synthetic demand kept distinct from measured evidence."
    requirement: CURATE-02
    verification:
      - kind: command
        ref: "Phase 254-16 and 254-17 evidence, the curation transparency checks and the acceptance generator all passed; all task rows are present in the 51-row Per-Task Verification Map."
        status: pass
    human_judgment: false

human_judgment: false
completed: 2026-11-03
status: complete
duration: final measurement and acceptance closeout
---

# Phase 254 Plan 18: final measurement and executable acceptance

**The final required CI and Browser UAT owners passed on the measured source head, and all seven Phase 254 requirements now have executed acceptance evidence.**

## Accomplishments

- Fixed reporter capture and ExUnit startup behavior, repaired the acceptance generator's pre-summary escalation handling, and corrected validation-map handling for directory paths with a trailing slash. The latter now normalizes directory paths while retaining traversal rejection.
- Reused the existing release-gate third-party build cache in Browser UAT, pruned first-party build outputs before compilation, and added a contract tying the reader to the exact runtime, configuration and lock identity. The final run restored the shared cache in 2 s and compiled in 152 s. The uncached comparison was 156 s; cached samples ranged from 135–155 s, so the measured reduction is small and variable rather than a stable 19 s gain. The cache remains a low-cost reuse of existing work and did not change test coverage or gates.
- Recorded final attempt-1 runs on `aa8dc46378555f56410a8f27a2e7cffe93266c62`: CI run `41740924592` and Browser UAT run `41740924604`. Both required owner jobs succeeded and reported `phase_owned_ok: true`.
- The Browser job took 1211 s, 67 s above its 1144 s baseline and within the 180 s allowance. All 32 visual cells passed; p90 was 1168 ms, below the frozen 1195 ms reference. The required Admin owner added 801.644 s against a 977 s baseline p90, or -175.356 s added; all 151 accessibility timings were retained, with p90 2539 ms below the frozen warning threshold.
- Classified the two unrelated CI reds: SL-G remains the recorded environmental known red `KR-254-06` because the main-run baseline also reports zero discovered artifacts; the parked ratchet failure is pre-existing on main run `40387584954`. No owner escalation was required, so checkpoint `254-18-02` is recorded as not required. All budget deviations are closed as resolved or accepted.
- Filled the Per-Task Verification Map for all 51 tasks. The acceptance generator confirms all seven requirements, task evidence, edge evidence, amendments and checkpoint answers; only the summary was pending before this file was created.

## Verification

- `node --test --test-reporter=tap scripts/ci/generate_phase254_acceptance.test.mjs` passed 27/27 tests, including pending-state and directory-path cases.
- `node scripts/ci/generate_phase254_acceptance.mjs --latest --expect-pending 254-18` passed before summary creation and reported exactly `254-18-SUMMARY.md` pending.
- `node scripts/ci/verify_ci_efficiency_contract.mjs --repo .` passed for the Browser cache contract.
- The Phase 252 gate passed 21/21; the Phase 253 aggregate passed its 12 serial lanes with 151 browser cells; the Phase 254 quality aggregate passed all five records. The digest fixed-point checks passed without changing tracked digest artifacts.
- `node scripts/ci/verify_phase230_archive_invariants.mjs --repo .` passed, scanning 178 files and 68 path literals.
- `writeValidationMap` now reports 51/51 green tasks, no pending task rows, and `nyquist_compliant: true` / `wave_0_complete: true`.

## Remaining CI evidence

- The two non-owner reds remain visible and classified as above; no rerun was made. The required CI and Browser UAT owner jobs are green on the final measured source commit.
- The generated `254-UAT.md`, executable UAT contract check and independent phase verification are completed in the post-summary and phase-close steps.
