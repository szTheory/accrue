---
id: 260918-e8m
slug: correct-v1-62-roadmap-doc-truth-drift-be
date: 2026-09-18
mode: quick
---

# Quick Task: Correct v1.62 ROADMAP doc-truth drift before archive

## Why

`/gsd-complete-milestone 1.62` archives `.planning/ROADMAP.md` verbatim to
`milestones/v1.62-ROADMAP.md` as the permanent historical record. Three lines in
it are false. Archiving as-is freezes a false claim about a release candidate.

Surfaced as tech-debt item 1 in `.planning/v1.62-MILESTONE-AUDIT.md`.

Root cause for (1) and (2): quick-task `260916-gda` (commit `06a7c863`) reworded
GATE-01/GATE-02 in `REQUIREMENTS.md` from outcome-wording to honest per-lane
process-wording, per Phase 231's locked decision D-29 (which forbids an aggregate
green boolean). That correction was never carried into `ROADMAP.md`, so the
milestone's own planning surface now contradicts itself.

## Tasks

1. **ROADMAP.md:103** — Phase 231 success criterion 2 asserts "A maintainer can
   inspect **green** required GitHub Actions checks for that exact SHA". False at
   the candidate SHA (`docs-contracts-shift-left`, `release-gate` ×3 cells, and
   `phase18-tax-gate` all fail). Reword to mirror the corrected REQUIREMENTS.md
   GATE-02 text: honest per-lane status with recorded evidence, lanes retaining
   explicit `proved`/`failed`/`skipped`/`advisory`/`non_run` semantics, a green
   Actions conclusion alone not accepted as provider proof.

2. **ROADMAP.md:102** — criterion 1 says the fresh clean checkout "completes the
   repository's local CI-equivalent gates". Also outcome-flavored and not literally
   true (`docs-contracts-shift-left` fails locally too). Reword to mirror the
   corrected GATE-01 text: produces honest, re-verifiable, per-lane proof with
   recorded argv and exit codes under the closed lexicon, no aggregate
   green/passing boolean.

3. **ROADMAP.md:54** — reads `**Plans**: 16/20 plans executed` for Phase 229;
   20 PLAN.md and 20 SUMMARY.md exist. Correct to 20/20.

## Constraints

- Change no other line.
- Do not touch `REQUIREMENTS.md` — already correct.
- Do not alter any phase completion status or checkbox.
- `scripts/ci/verify_roadmap_hygiene.sh` asserts only against the Planning Doctrine
  block (lines 20-26); none of the three target lines are covered by it. Verified
  before editing.
