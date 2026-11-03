---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "17"
subsystem: quality-records
tags: [required-owner, transparency, fail-first, consumed-roots]

requires:
  - phase: 254
    provides: Current selection projection, curation guide, accessibility results and confirmed design review
provides:
  - Serial Phase 254 quality aggregate in the required Admin guardrail owner
  - Required-owner path contracts for every new Phase 254 record input
  - Bounded transparency checks with current, clean and independent violation subjects
  - Native GSD fail-first evidence for all three Phase 254 transparency prohibitions
affects: [254-18]

actuals:
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Run record validators serially behind one unconditional required-owner step and name the first failed record"
    - "Test generated selection, a11y, design-review and curation surfaces against independent content violations"
    - "Promote prohibition descriptors only after native current, clean and violation-subject proof"

key-files:
  created:
    - scripts/ci/verify_phase254_quality.mjs
    - scripts/ci/verify_phase254_transparency.test.mjs
    - scripts/ci/fixtures/phase254-transparency/clean.json
    - scripts/ci/fixtures/phase254-transparency/selection-violation.json
    - scripts/ci/fixtures/phase254-transparency/a11y-claim-violation.json
    - scripts/ci/fixtures/phase254-transparency/brief-violation.json
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-NATIVE-PROHIBITION-PROOF.json
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-17-SUMMARY.md
  modified:
    - scripts/ci/verify_phase200_admin_guardrails.sh
    - scripts/ci/verify_phase200_guardrail_contract.sh
    - scripts/ci/phase252_paths.mjs
    - scripts/ci/verify_phase252_ci_contract.test.mjs
    - scripts/ci/verify_phase254_quality.mjs
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-07-PLAN.md
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-11-PLAN.md
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-16-PLAN.md

key-decisions:
  - "The quality step follows the existing Phase 254 budget check and runs selection freshness, curation, latest a11y results, confirmed design review and Storybook CSS recomposition serially."
  - "The storybook JSON roots remain exact; accrue_admin/storybook/unrelated.json stays unclassified. Screenshot and fixture removal controls explicitly remove overlapping broader rules for their classifier-negative checks."
  - "The candidate table's ordinal curation score is not treated as an accessibility or aesthetic quality score; the generated design review explicitly records that it has no aesthetic score."
  - "The final aggregate CLI runs only the five record checks; its injected-executor unit tests register only under node --test."

requirements-completed: []
requirements-advanced: [CIQ-02, UXQ-02, UXQ-04, CURATE-02]

coverage:
  - id: D1
    description: "The required Admin guardrail owner admits every new Phase 254 record source and runs all five record checks after the budget check."
    requirement: CIQ-02
    verification:
      - kind: unit
        ref: "Node owner-contract mutations cover removed, gated, renamed and reordered aggregate steps; positive/removal path controls cover every new root."
        status: pass
      - kind: command
        ref: "bash scripts/ci/verify_phase200_guardrail_contract.sh; node --test scripts/ci/verify_phase252_ci_contract.test.mjs scripts/ci/verify_phase254_quality.mjs (37/37); strict verify_ci_script_contract cohort (PASS)."
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_phase254_quality.mjs: all five checks passed serially."
        status: pass
    human_judgment: false
  - id: D2
    description: "Generated selection, accessibility, design-review and curation surfaces remain bounded and truthful; each independent content violation is rejected."
    requirement: UXQ-02
    verification:
      - kind: unit
        ref: "scripts/ci/verify_phase254_transparency.test.mjs (11/11): current generated surfaces and clean fixture pass; selection, a11y/design and brief violations each fail their own assertion."
        status: pass
    human_judgment: false
  - id: D3
    description: "The three retained plan prohibitions are native-proven against current, clean and independent violation subjects before and after descriptor promotion."
    requirement: UXQ-04
    verification:
      - kind: command
        ref: "gsd_run check prohibition-enforcement pre/post outputs; the proof records three resolved green results with passed=true, failFirst=true and failFirstProof=violation-fixture."
        status: pass
      - kind: command
        ref: "Exact Plan 17 task-03 verifier validates one proof row per assigned violation fixture and all three plan targets."
        status: pass
    human_judgment: false
  - id: D4
    description: "Synthetic adopter briefs and the next-job recommendation remain distinct from real demand, research or an opened milestone."
    requirement: CURATE-02
    verification:
      - kind: unit
        ref: "The brief-violation fixture is rejected while the current generated guide and clean fixture pass."
        status: pass
    human_judgment: false

duration: about 20 minutes
completed: 2026-11-03
status: complete
commits: 4
plan_head_before: c969f0509d57b42d09ba644ca3f398d21eaf10ef
plan_head_after: fd96f861edcfe9410f198f35b34f855ba80f8235
---

# Phase 254 Plan 17: required quality records and transparency proof

**All Phase 254 record checks now run through one required-owner step, new inputs are explicitly admitted, and the three transparency prohibitions have current, clean and fail-first violation evidence.**

## Accomplishments

- Added `verify_phase254_quality.mjs` as a serial aggregate for selection projection freshness, curation ledger, current a11y results, confirmed design review and Storybook CSS recomposition. The Phase 200 guardrail owner invokes it unconditionally after the budget check; shell and Node contracts reject a missing, gated, renamed or misordered invocation.
- Added required roots and removal controls for Phase 254 generators, CSS recomposition, the a11y validator, desktop baselines, visual cases, the coverage guide and Phase 254 fixtures. Exact Storybook JSON roots remain narrow, so an unrelated Storybook JSON path stays unclassified.
- Added real-surface transparency checks for generated selection summaries, the current design review, current a11y output and the generated curation guide. The clean subject passes; each of the three independent violation fixtures is rejected for its own content.
- Used the installed GSD projection and prohibition-enforcement procedure for the selection, accessibility/design and synthetic-brief prohibitions. All three pre-promotion runs showed a passing current test, a passing clean subject and a fail-first result for their assigned violation. The scoped plan entries were then promoted and re-enforced; the final proof is in `254-NATIVE-PROHIBITION-PROOF.json`.
- The three pre-promotion result files have SHA-256 `ae475ba391ef00eee18cedcf74aa8d07f2970f0b8009afd4e9d02ae8220343c3` each. The GSD result payload is identical across them because the entries were deliberately unresolved at that stage; their requests carry distinct prohibition statements and violation fixtures.

## Task Commits

1. **254-17-01 — Required-owner aggregate and consumed roots:** `9ce98b837`.
   - Follow-up: **Keep CLI aggregate output clean while registering unit tests under `node --test`:** `fd96f861e`.
2. **254-17-02 — Generated-surface transparency checks:** `e4cfb8a7a`.
3. **254-17-03 — Native prohibition proof and scoped promotion:** recorded with this summary and proof artifact.

## Verification

- `bash scripts/ci/verify_phase200_guardrail_contract.sh` passed.
- `node --test --test-reporter=tap scripts/ci/verify_phase252_ci_contract.test.mjs scripts/ci/verify_phase254_quality.mjs` passed 37/37 tests; runner-step removal, gating, renaming and order mutations all failed as required.
- `node --test --test-reporter=tap scripts/ci/verify_phase254_transparency.test.mjs` passed 11/11 tests on the current generated surfaces, clean fixture and three independent violations.
- `node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor` passed against the final tracked CI-script cohort.
- `node scripts/ci/verify_phase254_quality.mjs` passed all five record checks in the required order.
- Native GSD enforcement passed for all three promoted descriptors. Each final result is unflagged `green`, and its evidence records `passed: true`, `failFirst: true`, `failFirstProof: "violation-fixture"`.

Plan 17 is complete. Plan 18 remains the final acceptance plan; preserve KR-254-06 red and stop at its named blocking-human checkpoint without auto-answering it.
