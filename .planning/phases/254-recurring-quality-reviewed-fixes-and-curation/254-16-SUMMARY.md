---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "16"
subsystem: curation
tags: [caller-map, synthetic-adopters, maintenance-cost, candidate-ranking]

requires:
  - phase: 254
    provides: Frozen Phase 254 budget, route inventory, and curation ledger
provides:
  - Route-seeded Admin and Portal caller map with a stable digest
  - Five distinct synthetic adopter briefs with frozen-input maintenance estimates
  - Hard-filtered, cost-aware next-job candidates recorded as recommendation input
affects: [254-17, 254-18]

actuals:
  tokens: 40000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Seed caller-map gaps from live router declarations while curated coverage rows retain precedence"
    - "Recompute adopter and candidate maintenance costs from caller-map jobs and the frozen composition p90/budget"
    - "Apply entry-trigger gates before ordinal ranking; use shared-owner reuse and rolling horizon only for ties"

key-files:
  created:
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-16-SUMMARY.md
  modified:
    - accrue_admin/storybook/_support/subscription_manifest.ex
    - accrue_admin/storybook/subscription-curation.json
    - accrue_admin/storybook/phase254-selection.json
    - accrue_admin/storybook/phase254-budget.json
    - scripts/ci/verify_phase254_curation.mjs
    - scripts/ci/verify_phase254_curation.test.mjs
    - guides/subscription-story-coverage.md
    - storybook/phase252-manifest.json

key-decisions:
  - "All five adopter profiles remain synthetic design assumptions; the team profile is marked implemented and self_hosted has no seeds or stories."
  - "Maintenance cost uses only frozen.composition_cell.per_cell_p90_s (1.794 s) and frozen.value (959 s); the guide documents the cost and ordinal level thresholds."
  - "Admin customer investigation is the recommendation input. Recovery remains gated on retry/campaign-history integrity, and Portal subscription work remains gated on contract verification plus a dev/test harness."
  - "No milestone or roadmap item was opened; phase254-visual-cases.json remained byte-identical at SHA-256 d78090e75003d0e04e32839258a76acb23f6dbccf03beaa2c80a13d8b56a91ed."

requirements-completed: []
requirements-advanced: [CURATE-02]

coverage:
  - id: D1
    description: "Every live route from the Admin and Portal routers maps to a caller row, and an added-route fixture proves new routes appear as uncovered."
    requirement: CURATE-02
    verification:
      - kind: unit
        ref: "SubscriptionManifest tests: real-router reconciliation, positive extra-route fixture, and 22/22 task-01 lab tests"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exactly five distinct synthetic adopter profiles link jobs, uncovered states and review triggers to the gap map; cost fields are recomputed from the frozen budget."
    requirement: CURATE-02
    verification:
      - kind: unit
        ref: "Node curation verifier: six brief rejection fixtures; full task-02 run 45/45 tests and 24/24 lab tests"
        status: pass
      - kind: other
        ref: "Generated ledger and guide fixed point; curation, selection, and budget digest checks"
        status: pass
    human_judgment: false
  - id: D3
    description: "Existing UI jobs are hard-filtered by their entry triggers, then ranked ordinally against maintenance cost with deterministic shared-owner and horizon tie-breaks."
    requirement: CURATE-02
    verification:
      - kind: unit
        ref: "Node curation verifier: two gatedCannotWin violation fixtures and one clean fixture; full task-03 run 48/48 tests and 27/27 lab tests"
        status: pass
      - kind: other
        ref: "Roadmap-count check with seeded Phase 999 positive control; unchanged committed and working phase/milestone counts"
        status: pass
    human_judgment: false

duration: about 20 minutes
completed: 2026-11-03
status: complete
commits: 3
plan_head_before: f166e3f8ed7960ff632a0450f022fccc85f772dd
plan_head_after: 0c2ccee230a047ff87624116cce93a9d90c835c7
---

# Phase 254 Plan 16: route-seeded curation and next-job recommendation

**The gap map now follows every live Admin and Portal route, the five adopter profiles carry traceable maintenance estimates, and the next-job ranking recommends Admin customer investigation while preserving the recovery and Portal gates.**

## Accomplishments

- Added 34 unique route/surface entries to the current 53-row caller map. Curated subscription evidence keeps precedence; newly observed routes default to uncovered, and an extra-route fixture proves the route parser cannot silently omit a new route.
- Added five profiles in the order `launch`, `team`, `learner`, `operations`, `self_hosted`. Each is marked synthetic and has a distinct equivalence class, caller-map jobs, linked gap states and review triggers, and the exact limit from the profile table. `team` is marked implemented; `self_hosted` is explicitly a deployment profile with no seeds or stories.
- Added the pure maintenance-cost calculation: each distinct uncovered `{surface, job, state}` adds four browser cells; the browser cost uses the frozen 1.794-second composition-cell p90, and budget share uses the frozen 959-second CIQ-04 value. Both brief and candidate costs use this function.
- Added six candidate families and a deterministic ordinal score. Entry gates run before ranking, high/medium/low cost penalties affect rank, shared-owner reuse breaks rank ties before rolling-horizon order, and story counts do not enter the score. The generated `next_job` is labelled `recommendation-input`, not a milestone.
- Added Node verifier fixtures for all six brief rejection cases and for both gated-candidate violations plus the clean Portal-below-eligible case. The guide now renders the full caller map, brief costs and candidate table.
- Regenerated the manifest, guide, curation ledger, selection projection and budget digest through their owners. The Phase 252 visual-case projection stayed byte-identical.

## Task Commits

1. **254-16-01 — Route-seeded gap map:** `52d3b815e921d45103b3da9b50472a03117637fc`.
2. **254-16-02 — Five synthetic adopter briefs:** `858e8d8c4cc97eb85a3aecd7a55a1c8c077da2b6`.
3. **254-16-03 — Hard-filtered candidate ranking:** `0c2ccee230a047ff87624116cce93a9d90c835c7`.

## Verification

- Task 01 disposable Admin lab suite: 22 tests, zero failures. Generated manifest/guide, curation verifier, selection projection and budget digest checks passed.
- Task 02 Node verifier suite: 45 tests, zero failures; disposable Admin lab suite: 24 tests, zero failures. All five briefs and all cost fields passed the ledger verifier and generated-guide fixed point.
- Task 03 Node verifier suite: 48 tests, zero failures; disposable Admin lab suite: 27 tests, zero failures. Candidate hard filters, recovery reopening, ranking determinism, shared-owner/horizon tie-breaks, story-count invariance, and recommendation status passed.
- Curation verifier passed; selection projection matched all 151 cases, 14 always-run cases, 8 sentinels, 32 visual cases and 16 design capture keys; budget restamp matched the committed manifest. The seeded roadmap heading increased the scratch count by one while the working roadmap remained equal to `HEAD`.
- Budget digest restamps were recorded as DEV-254-22/23 for task 01, DEV-254-24 for task 02, and DEV-254-25 for task 03. Task 01 required a second owner regeneration/restamp after final formatting and route-identity validation; both records are resolved and the final digest checks pass.

Plan 16 is complete. Plan 17 is next; Plan 18 still owns the retained SL-G acceptance-artifact closure and its blocking human gate.
