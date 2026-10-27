---
phase: 252-production-backed-subscription-stories
plan: "09"
subsystem: testing
tags: [node, tap, storybook, transparency, attribution]
requires:
  - phase: 252-08
    provides:
      - Generated Phase 252 story manifest and production-backed subscription story surfaces
provides:
  - Bounded lab presentation checks over the guide, story moduledoc, and every manifest attribution
  - Synthetic held-out attribution checks across source, ordinary adapter, browser label, and guide
affects: [252-10, 252-VERIFICATION]
actuals:
  tokens: 10889.5
  tasks: 2
  commits: 4
plan_head_before: b1a6a9c7b98aa4b3af0757c47bbebe10e0707a8a
plan_head_after: 3ab07226bc8658623bd428091aefd0b152a4ed2b
commits: 4
tech-stack:
  added: []
  patterns:
    - Versioned JSON subjects feed identical current-source and injected-content assertions
    - Self-tests use shell-free bounded Node TAP children and require named GREEN/RED records
key-files:
  created:
    - scripts/ci/verify_phase252_transparency.mjs
    - scripts/ci/verify_phase252_lab_presentation.test.mjs
    - scripts/ci/verify_phase252_heldout_attribution.test.mjs
    - scripts/ci/fixtures/phase252-transparency/lab-clean.json
    - scripts/ci/fixtures/phase252-transparency/lab-violation.json
    - scripts/ci/fixtures/phase252-transparency/heldout-clean.json
    - scripts/ci/fixtures/phase252-transparency/heldout-violation.json
    - .planning/phases/252-production-backed-subscription-stories/252-09-01-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-09-02-red-evidence.json
  modified:
    - guides/ui-story-lab.md
key-decisions:
  - "Keep claims finite and lexical over enumerated public surfaces; do not represent the checker as universal semantic or customer research validation."
  - "Use the same assertion functions for current repository subjects and injected fixtures; injection changes content only."
  - "Keep the browser-generated held-out clone distinct from CadenceSubscriptionFacts.held_out!/1 and manifest fixtures."
requirements-completed: [SBK-02, SBK-03, SCEN-04, LAB-01]
coverage:
  - id: D1
    description: "The lab guide, SubscriptionDetail moduledoc, and all manifest entry attributions state bounded static, non-production evidence."
    requirement: LAB-01
    verification:
      - kind: unit
        ref: "scripts/ci/verify_phase252_lab_presentation.test.mjs#lab presentation states disposable static limits"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_phase252_transparency.mjs --self-test --only lab"
        status: pass
    human_judgment: false
  - id: D2
    description: "Held-out facts, ordinary-lane refusal, and browser-clone label remain separately attributed as synthetic stress evidence."
    requirement: SBK-02
    verification:
      - kind: unit
        ref: "scripts/ci/verify_phase252_heldout_attribution.test.mjs#held-out attribution identifies synthetic stress evidence"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_phase252_transparency.mjs --self-test --only heldout"
        status: pass
    human_judgment: false
  - id: D3
    description: "Representative-customer and real-adopter affirmative claims fail with required disclaimers retained."
    requirement: SBK-03
    verification:
      - kind: unit
        ref: "scripts/ci/verify_phase252_heldout_attribution.test.mjs#held-out attribution rejects representative and real-adopter claims beside disclaimers"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_phase252_transparency.mjs --self-test"
        status: pass
    human_judgment: false
  - id: D4
    description: "Missing and relabelled evidence fields fail closed, while clean injected content passes the same checks."
    requirement: SCEN-04
    verification:
      - kind: unit
        ref: "scripts/ci/verify_phase252_heldout_attribution.test.mjs#held-out attribution refuses missing disclaimers and relabelled source evidence"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_phase252_transparency.mjs --self-test"
        status: pass
    human_judgment: false
duration: 17min
completed: 2026-10-27
status: complete
human_judgment: false
---

# Phase 252 Plan 09: Lab and Held-Out Attribution Checks Summary

**Bounded source-backed assertions now prove truthful static-lab and synthetic held-out attribution for current, clean, and deliberately violating subjects.**

## Performance

- **Duration:** 17 minutes
- **Started:** 2026-10-27T09:44:49-04:00
- **Completed:** 2026-10-27T10:01:58-04:00
- **Tasks:** 2
- **Files created or modified:** 10

## Accomplishments

- Added a versioned subject collector and named assertion for the guide, SubscriptionDetail moduledoc, and every manifest entry's actor, job, input source, production renderer, and proof lane.
- Extended the same collector to the held-out source lane, ordinary-only adapter refusal, and the actual browser helper's held-out label. The guide separates this synthetic browser clone from both manifest fixtures and `CadenceSubscriptionFacts.held_out!/1`.
- Added clean and violating JSON controls for each target. Bounded self-tests require named TAP records for current and clean GREEN plus content-caused violation RED.

## Task Commits

1. **Task 1: Prove truthful lab presentation through current and injected subjects** — RED `8477d17b`, GREEN `6082f9a9`.
2. **Task 2: Prove synthetic held-out attribution without claiming customer evidence** — RED `4d3b67c3`, GREEN `3ab07226`.

## Files Created or Modified

- `scripts/ci/verify_phase252_transparency.mjs` — bounded source collection, shared assertions, and lab/held-out self-test controls.
- `scripts/ci/verify_phase252_lab_presentation.test.mjs` and `scripts/ci/verify_phase252_heldout_attribution.test.mjs` — named tests and mutation controls.
- Four `scripts/ci/fixtures/phase252-transparency/{lab,heldout}-{clean,violation}.json` subjects — schema-valid controls.
- `guides/ui-story-lab.md` — explicit static, non-production, and synthetic-evidence attribution while preserving existing gate and budget wording.
- Two `.planning/phases/252-production-backed-subscription-stories/252-09-0*-red-evidence.json` records — classifier-verified RED evidence for each TDD task.

## Decisions Made

- Keep checks finite and lexical over enumerated public surfaces. They do not claim universal semantic coverage or validate customer representativeness.
- Use the same assertions for current repository content and injected subjects; the environment override supplies content only.
- Keep the browser-generated long-text clone distinct from the held-out source constructor and manifest fixtures.

## Deviations from Plan

None — both tasks followed the plan and preserved the original prohibition metadata and `252-VERIFICATION.md`.

## Verification

- Both RED records passed `gsd-tools check tdd-red-evidence` with `RED_EVIDENCE_OK`; each identified the intended named assertion failing once (1 test, 1 failure).
- Combined named test targets: **6 passed, 0 failed, 0 skipped**.
- Lab-only controls: current/clean/violation each ran **3** named tests and passed the required GREEN/GREEN/RED contract.
- Held-out-only controls: current/clean/violation each ran **3** named tests and passed the required GREEN/GREEN/RED contract.
- Default combined controls: current/clean/violation each ran **6** named tests and passed the required GREEN/GREEN/RED contract.
- Existing Phase 252 acceptance-generator tests: **20 passed, 0 failed, 0 skipped**.
- Plan evaluation scope found the four task commits on this branch. `git diff --check` passed.

The checker covers only the guide, story moduledoc, manifest attribution fields, held-out source block, ordinary validation/refusal block, and named browser helper label. Its finite patterns do not establish that arbitrary prose is truthful or that synthetic scenarios represent real adopters.

## Issues Encountered

The repository path hook rejected an initial RED evidence command that included a home-directory path. The target and checker were copied byte-for-byte to private temporary paths; hash-verified records then passed the RED classifier. No product scope changed.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

Plan 09's checks and fixtures are ready for plan 252-10 to wire into the prohibition/admission flow. The phase verification remains pending and was not modified here.

---
*Phase: 252-production-backed-subscription-stories*
*Completed: 2026-10-27*

## Self-Check: PASSED

- Summary file exists.
- All four task commits are ancestors of current HEAD.
- Plan evaluation scope resolves four commits on this branch.
- Stub scan found no placeholder or unimplemented content; the two `TODO` matches are TAP metadata fields used to reject skipped tests.
- `252-VERIFICATION.md` remains unchanged.
