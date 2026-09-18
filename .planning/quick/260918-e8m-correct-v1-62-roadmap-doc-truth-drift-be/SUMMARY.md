---
id: 260918-e8m
slug: correct-v1-62-roadmap-doc-truth-drift-be
date: 2026-09-18
status: complete
human_judgment: false
commits:
  - 62c5c6a0
---

# Summary: Correct v1.62 ROADMAP doc-truth drift before archive

**One-liner:** Reworded two false Phase 231 success criteria and one stale plan
count in `.planning/ROADMAP.md` so the v1.62 archive records the candidate's real
state instead of a green claim it never earned.

## What changed

`.planning/ROADMAP.md`, three lines, nothing else:

| Line | Before | After |
|---|---|---|
| 54 | `**Plans**: 16/20 plans executed` | `20/20` — 20 PLAN.md + 20 SUMMARY.md exist |
| 102 | criterion 1 "completes the repository's local CI-equivalent gates" | honest per-lane proof, recorded argv + exit codes, closed lexicon, no aggregate boolean |
| 103 | criterion 2 "inspect **green** required GitHub Actions checks" | honest per-lane status with recorded evidence; a green Actions conclusion alone is not provider proof |

## Why it mattered

`/gsd-complete-milestone` archives ROADMAP.md verbatim to
`milestones/v1.62-ROADMAP.md`. Both criteria were demonstrably false at the
candidate SHA `c1397fe9` — `docs-contracts-shift-left` fails both locally and on
GitHub, and `release-gate` fails all three required matrix cells plus
`phase18-tax-gate`. Archiving unchanged would have frozen a false green claim
about a release candidate into the permanent record.

## Root cause

Quick-task `260916-gda` (`06a7c863`) reworded GATE-01/GATE-02 in REQUIREMENTS.md
from outcome-wording to honest per-lane process-wording, per Phase 231's locked
decision D-29 forbidding an aggregate green boolean. The correction landed in
REQUIREMENTS.md only. ROADMAP.md kept the old outcome-wording, so the milestone's
two planning surfaces contradicted each other for two days.

**Lesson:** a requirement rewording has at least two homes. REQUIREMENTS.md holds
the requirement; ROADMAP.md holds the success criterion derived from it. Changing
one without the other splits the milestone's own truth.

## Verification

- `bash scripts/ci/verify_roadmap_hygiene.sh` → `OK`
- `bash scripts/ci/verify_v1_17_friction_research_contract.sh` → `OK`
- Checked before editing that neither contract asserts against the three target
  lines (hygiene guards only the Planning Doctrine block, lines 20-26).
- `git diff --stat` → `1 file changed, 3 insertions(+), 3 deletions(-)`; no phase
  status, checkbox, or unrelated line touched.

These two scripts are the only files under `scripts/ci/` that read ROADMAP.md.
