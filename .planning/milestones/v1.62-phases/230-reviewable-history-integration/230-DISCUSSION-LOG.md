# Phase 230: Reviewable History Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-15
**Phase:** 230-reviewable-history-integration
**Areas discussed:** Candidate shape & ancestry, Excluded-commit dispositions, Verification depth & evidence format, Ref creation & rollback point
**Mode:** advisor (calibration tier `minimal_decisive`), four parallel research agents

---

## Method note

The user selected all four gray areas and requested deep parallel subagent research with a
single cohesive recommendation package. Four `gsd-advisor-researcher` agents ran concurrently.

**Three of the four agents independently reported that facts in their briefs were stale**, because
the local `origin/main` ref had not been fetched in ~27 days. Every correction was re-verified
directly in this session before being accepted:

| Briefed fact | Measured truth | Verified by |
|---|---|---|
| `origin/main` = `8f3135f7`, 17 commits, at 1.5.0 | `d30fc25d`, 24 commits, at **1.5.1** | `git ls-remote`, manifest read |
| 5 files touched on both sides | **6** — `accrue/lib/accrue/config.ex` joined | `comm -12` over both diffs |
| Merge tree `e8206af5` | `e1990d37`, still zero conflicts | `git merge-tree --write-tree` |
| PR #44 = 4 cherry-picked commits (per `STATE.md`) | Head is local `main` + 4; `main` **is** an ancestor | `git merge-base --is-ancestor` |
| — (unreported by anyone) | `origin/main` migrated to **Decimal 3 / ex_money 6 / Ecto 3.14** | `git diff` on `accrue/mix.exs` |
| — (unreported by anyone) | 229 capsule leaves **139 commits unpreserved** | `git bundle list-heads` + reachability |

One agent's claim that closure commit `8a95be8` was unresolvable was its own transcription typo;
`8a95fbe8` resolves fine. One agent ran `git fetch` during research, advancing local `origin/*`
refs mid-session, and created then deleted a temporary ref and tag (net-zero on ref set).

---

## Candidate shape & ancestry

| Option | Description | Selected |
|--------|-------------|----------|
| Merge `origin/main` into a branch cut from milestone HEAD, plus a code-only review sibling | Nothing rewritten; `v1.61` stays an ancestor; single merge commit ⇒ `git revert -m 1` is exact undo; reviewer reads 72 source files instead of 283 | ✓ |
| Squash/collapse onto a branch off `origin/main` | Minimal diff, but breaks `v1.61` ancestry, orphans F-01..F-04, destroys ~153 changelog-bearing commits and kills REL-05 | |
| Rebase milestone onto `origin/main` | Disqualified outright — `v1.61` points *into* the branch, so rebasing orphans the tag | |

**User's choice:** Accepted the recommended package (no fork raised — the alternatives were
disqualified on requirement grounds rather than preference).
**Notes:** Recorded as D-01..D-06.

---

## Excluded-commit dispositions

| Option | Description | Selected |
|--------|-------------|----------|
| Evidence-backed wholesale exclusion of the 80 abandoned commits + machine-checked ledger + archive preservation | Unique non-planning surface is 4 superseded files; supersession proven at tree and requirement level, not by patch-id | ✓ |
| Salvage-by-patch-equivalence (cherry-pick the "unique" deltas) | Rejected as actively harmful — would land a rejected 463-line verifier as a live CI gate alongside its replacement | |
| Wholesale merge of the abandoned line | Disqualified — resurrects rejected gates, restores superseded requirement IDs, duplicates archived phase dirs | |

**Fork raised — PR #44 disposition (public, outward-facing):**

| Option | Description | Selected |
|--------|-------------|----------|
| Close unmerged, cite superseding SHAs | Its 4 useful commits are already on the candidate as exact patch-id matches; merging would publish all 80 abandoned commits onto `main` | ✓ |
| Rebase #44 onto the candidate | Preserves the PR thread but is a remote write leaving two overlapping paths to `main` | |
| Leave alone, record only | Takes no public action but leaves a live PR that would publish the abandoned line if merged | |

**User's choice:** Close unmerged, citing superseding SHAs.
**Notes:** Recorded as D-07..D-13. `STATE.md`'s account of PR #44 is factually wrong and D-10
corrects it. A key methodological finding: `git cherry`'s 3 `-` marks here are patch-id false
positives on repeated boilerplate, so `git cherry` is a lead and never proof.

---

## Verification depth & evidence format

| Option | Description | Selected |
|--------|-------------|----------|
| Integration Disposition Ledger — a fourth `collect → render → verify` triad with the hazard universe recomputed from SHAs | Detects the classes `git` cannot see; refuses to run on a stale binding; exact-set completeness assertions | ✓ |
| Narrative disposition in prose + lean on Phase 231's gates | Violates the post-218 executable-acceptance policy; cannot assert completeness; `human_judgment: false` could not be honestly claimed | |

**Fork raised — dependency-migration scope:**

| Option | Description | Selected |
|--------|-------------|----------|
| Compile + money/property tests must pass; fix what breaks | A candidate nobody can compile is not a candidate; re-resolve the three skewed sibling lockfiles | ✓ |
| Prove it, record honestly, fix nothing | Tightly scoped but knowingly ships a candidate in a failed state | |
| Lockfiles only; defer behavioral proof to 231 | Risks discovering money-math breakage late | |

**User's choice:** Compile and money/property suites must pass; fixing Decimal 3 breakage is in scope.
**Notes:** Recorded as D-14..D-24. The dependency migration was found by reading the diff, not by
any tool — it is invisible to `git merge` and was named in none of the planning documents.

---

## Ref creation & rollback point

| Option | Description | Selected |
|--------|-------------|----------|
| Typed ref continuity in the verifier + bounded declared-additions ledger + fresh capsule minted last | 5 of 7 current divergences were caused by Release Please and `git fetch`, not by this work; fix belongs in verifier semantics | ✓ |
| Pure fail-forward with an exception ledger, verifier untouched | Ledger grows one row per bot release; normalizes a permanently red gate that 231/232 inherit and learn to ignore | |

**User's choice:** Accepted the recommended package.
**Notes:** Recorded as D-25..D-35. Surfaced an urgent safety gap unrelated to the question asked:
the 229 capsule does not preserve current `HEAD`, leaving 139 commits recoverable only from reflog,
which Phase 229's own D-06 rejects. Closing that is now the phase's first task.

---

## Claude's Discretion

- Exact JSON schema field names, artifact filenames, script decomposition, and renderer layout.
- How to decompose the verifier changes across tasks; preservation-ref naming within 229's hex encoding.
- Whether the excluded-commit and integration-disposition ledgers are one artifact or two.

## Deferred Ideas

- PR authoring, risk summary, rollback instructions, Release Please readiness — Phase 232.
- Fresh clean-checkout gates, exact-SHA GitHub proof, ship-window resolution — Phase 231.
- Any deletion or classification of refs, branches, worktrees, untracked files — Phase 232 (HYG-01).
- Pinning release-please `commit-search-depth` (~492 commits against a default of 500) — Phase 232.
- CHANGELOG editorial curation for ~153 mostly-internal commits — Phase 232, per `RELEASING.md`.
- Renaming the two adopter-named refs — fail-forward stands; free only at a new capsule mint.
- `.planning/v1.61-v1.61-MILESTONE-AUDIT.md` double-prefix duplicate — record now, fix in 232.
- Package publication — outside v1.62.
