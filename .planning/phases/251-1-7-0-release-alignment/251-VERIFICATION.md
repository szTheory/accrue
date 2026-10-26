---
phase: 251-1-7-0-release-alignment
verified: 2026-10-26T14:05:30Z
status: passed
score: "completed-plan claims verified: 251-01, 251-02, 251-03, 251-04; phase success criteria claimed: 0/3 (phase in progress)"
covered_files:
  - ".github/workflows/ci.yml"
  - ".github/workflows/release-please.yml"
  - ".planning/phases/251-1-7-0-release-alignment/251-01-PLAN.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-01-SUMMARY.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-02-PLAN.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-02-SUMMARY.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-03-PLAN.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-03-SUMMARY.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-04-PLAN.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-04-SUMMARY.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-05-PLAN.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-06-PLAN.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-07-PLAN.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-CHANGELOG-DRAFTS.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-CONTEXT.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-RESEARCH.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-UAT.md"
  - ".planning/phases/251-1-7-0-release-alignment/251-mint-close-artifacts.mjs"
  - "RELEASING.md"
  - "scripts/ci/README.md"
  - "scripts/ci/verify_release_branch_repair_safety.sh"
  - "scripts/ci/verify_release_changelog_curated.sh"
  - "scripts/ci/verify_release_contract.sh"
covered_digest: "v1:sha256:24164063a365fdc56ace671b00c2d3b7cc6aa74c9d1ccf487f02dbe277b10372"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 251: 1.7.0 Release Alignment Verification Report (in progress)

**Scope:** `status: passed` and `behavior_unverified: 0` apply to the completed-plan claims below only. Phase success criteria SC1-SC3 are not yet claimed. No requirement is marked Complete.

## Observable Truths

| # | Claim | Evidence | Status |
|---|-------|----------|--------|
| B1 | Phase 251 owns SL-G, SL-E and executable-UAT from its first commit | `251-01-SUMMARY.md` coverage B1; SL-G, SL-E, exec-UAT `--all-since 229` and `--phase 251` exit 0 | VERIFIED |
| W1 | release-please.yml never force-resets the release branch; the legacy algorithm is shown to empty a release PR | `251-02-SUMMARY.md` coverage W1; `verify_release_branch_repair_safety.sh --self-test` (controls A, B, placement) and `--repo .` exit 0; live pre-fix run failed naming lines 183/184 | VERIFIED |
| W2 | A merged release PR still labelled `autorelease: pending` turns Release Please red via a job no publish job needs | `251-02-SUMMARY.md` coverage W2; `verify_release_contract.sh` (N1-N3 single-violation controls) exit 0 | VERIFIED |
| W3 | RELEASING.md and scripts/ci/README.md give the corrected remedies; legacy reset remedy rejected | `251-02-SUMMARY.md` coverage W3; `verify_release_contract.sh` (N4-N6 single-violation controls) exit 0 | VERIFIED |
| G1 | The SC1 curated-CHANGELOG gate is committed and merge-blocking, and it fails the real uncurated 963ad2cd candidate for all three packages | `251-03-SUMMARY.md` coverage G1; `verify_release_changelog_curated.sh --self-test` (10 fixtures, FAIL and PASS controls) and the live run exit 0 (grandfathered at 1.6.0); 963ad2cd `--version 1.7.0` exits 1 with 18/168/41 raw lines | VERIFIED |
| L1 | Workflow-fix PR #54 exact head F green and squash-merged as S `6e285bff`; push CI at S green vs baseline 40281358498 | `251-04-SUMMARY.md` coverage L1; `250-ci-head-status.mjs` at F (pull_request, `--pr-base origin/main`) and at S (push) exit 0 | VERIFIED |
| L2 | The wedge detector fired live at S: Release Please run 40344886221 has `Release Please=success`, `Release PR wedge check=failure` naming PR 50 | `251-04-SUMMARY.md` coverage L2; `gh run view 40344886221` jobs and `--log-failed` | VERIFIED |
| L3 | #50 stale-label hazard proven (dry run would tag 3 1.7.0 releases at b4310a39) then removed (merged-pending `[]`, would tag 0); dispatch run 40348672308 success at FREEZE_SHA | `251-04-SUMMARY.md` coverage L3; merged-pending query with negative control; github-release dry run before/after | VERIFIED |
| L4 | Fresh release PR #55 has the seven release files at 1.7.0, three 1.7.0 component blocks, raw head parent FREEZE_SHA; no 1.7.0 tag, release or Hex package | `251-04-SUMMARY.md` coverage L4; `verify_release_pr_scope.sh --pr 55 --version 1.7.0` exit 0 | VERIFIED |
| SC1 | Release PR branch carries 1.7.0 README pins, companion notes and curated CHANGELOGs with no raw phase-scoped lines | not yet claimed (in progress); decided by the G1 gate on the release PR head | NOT CLAIMED |
| SC2 | Every required check on the release PR's exact head SHA concludes `success` | not yet claimed (in progress) | NOT CLAIMED |
| SC3 | Hex publication of 1.7.0 happens only after a recorded explicit maintainer yes | not yet claimed (in progress) | NOT CLAIMED |

## Excluded from covered_files

`.planning/STATE.md`, `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` are live trackers. This file is excluded from its own list. `251-RELEASE-LEDGER.md` records PR heads, merge SHAs and run IDs of commits it cannot be part of; covering it would form a digest cycle.

## Publication authorization

On 2026-10-26 the maintainer said, verbatim: "follow ur recs. i authorize release we want to release early and often at any natural stopping point that is release worthy". This is the recorded explicit yes for publishing 1.7.0 (RLS-02) and the standing policy to release at every release-worthy stopping point. It is recorded here and in `.planning/STATE.md` (Decisions). SC3 is claimed only after publication evidence exists.

## Gaps

SC1-SC3 remain open until later Phase 251 plans claim them.
