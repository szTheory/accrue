# Phase 91: Pre-publish 1.0.0 prep — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-26
**Phase:** 091-pre-publish-prep
**Areas discussed:** PR sequencing vs Phase 92 bump, CHANGELOG `1.0.0 — Stable` shape, RELEASING.md post-1.0 section structure, Companion guide flip scope
**Mode:** advisor-style deep synthesis — user requested cohesive one-shot recommendations across all areas, with parallel research subagents per area, only flagging VERY impactful forks. No high-impact forks were surfaced — all areas auto-applied per `discuss_publish_contracts_research_depth: deep_synthesis_cohesive_defaults_unless_discuss_high_impact_confirm`.

---

## PR sequencing vs Phase 92 `@version` bump

| Option | Description | Selected |
|--------|-------------|----------|
| A1. Separate pre-bump PR | Phase 91 lands docs in its own PR ahead of Phase 92's combined Release Please PR; `@version` stays `0.3.1` end-of-phase; matches v1.27 Phase 84 docs-only precedent. | ✓ |
| A2. Bundled into Release Please PR | Phase 91 doc edits live on a feature branch and get merged into the open Release Please PR before Phase 92 merges that PR; one landing event for everything. | |
| A3. Staged with conditional/future-tense | Phase 91 phrases everything in future-tense ("will be 1.0.0"); Phase 92 flips tense in the bump PR; two coordinated PRs but Phase 91 stays honest at 0.3.1. | |

**Selected:** A1 (separate pre-bump PR) — research recommended A2 but flagged HIGH-impact; the synthesis chose A1 with two qualifiers that mute A2's concerns: (a) CHANGELOG preamble lives in `## Unreleased` (no fake `## 1.0.0` heading on `main`), and (b) prose uses commitment-level voice ("Accrue commits to v1.x API stability…", "the `1.0.x` line treats…") not claim-level voice ("Accrue is now 1.0.x"). A1 honors the literal ROADMAP success criterion #5 (`@version` stays `0.3.1`) and matches v1.27 Phase 84 precedent.

**Notes:** v1.28 Phase 86's `discuss_default_post_publish_pr_coupling: same_pr_as_mix_version_bump_when_human_batchable` is the *post-publish* analog where docs ride with the version bump. Phase 91 is *pre-publish* — the analog is reversed: docs land **ahead of** the bump.

---

## REL-06 — CHANGELOG `1.0.0 — Stable` shape

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Narrative-only | Multi-paragraph stability declaration + facade boundary recap, no auto-rendered changes. | |
| 2. Minimal one-liner | Single short bullet pointing at RELEASING.md / maturity-and-maintenance. | |
| 3. Hybrid: stability preamble + auto-rendered changes | 3-line preamble at top of `## Unreleased`, Release Please carries it into rendered `## [1.0.0]` heading on Phase 92's release PR; categorized `### Features / ### Bug Fixes / …` sections cover the actual 0.3.1 → 1.0.0 diff. | ✓ |

**Selected:** Option 3 (Hybrid) — matches Broadway 1.0, LiveView 1.0, Ecto 3.0 idiom; coexists with Release Please automation (preamble in `## Unreleased` is carried verbatim by RP into the rendered `## [1.0.0]` block); avoids duplicate-heading collision risk on RP regeneration; preserves the Conventional Commits diff adopters need to see at the cut.

**Notes:** Concrete preamble text locked in CONTEXT.md D-05. `accrue` (3 lines: stability commitment, surface list, deprecation policy, cross-link) and `accrue_admin` (2 lines: lockstep release, surface list, cross-link to `accrue` for shared contract) differ — the admin package is downstream and points back to core for the canonical SemVer commitment.

---

## RELEASING.md post-1.0 section structure

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Replace pre-1.0 closure in place | Delete `## Pre-1.0 closure (maintainer intent)` and put `## Post-1.0 cadence (maintainer intent)` in the same position; single voice. | ✓ |
| 2. Keep pre-1.0 closure as historical, add post-1.0 cadence after | Preserve closure block as historical; add new cadence section after; reader sees both. | |
| 3. Replace + promote bootstrap appendix into routine path | Replace closure block with cadence section AND promote `## Appendix: Same-day 1.0.0 bootstrap` into main flow. | |

**Selected:** Option 1 (Replace in place) — Phoenix `RELEASE.md` and Ecto release docs treat the runbook as purely operational (CHANGELOG owns historical narrative). Option 2 ossifies into stale parallel realities. Option 3 conflates Phase 91 (pre-publish docs) with Phase 92 (the actual bootstrap event) — the appendix is genuinely exceptional until Phase 92 cuts the linked publish.

**Notes:** Concrete 10-bullet outline locked in CONTEXT.md D-11. Forward-port window auto-applied at 6 months (matches Elixir core / Oban deprecation rhythm). RELEASING.md top-of-file preamble (lines 3–9) keeps neutral framing in Phase 91 — does NOT flip to "post-1.0" until Phase 92 to keep the file honest while `@version` is still `0.3.1`. Bootstrap appendix (line 164) untouched in Phase 91. Section heading at line 19 (`## Routine pre-1.0 linked releases`) renames to `## Routine linked releases` — completes the voice flip with one extra word edit.

**One coupled decision (research-flagged, auto-resolved):** CLS-02 cross-link from `accrue/guides/upgrade.md` § "Pre-1.0 wrap-up semantics" gets renamed to § "Post-1.0 cadence" in the same Phase 91 PR. Anchor stability for an internal repo cross-link is low-value — rename, don't keep an HTML `<a id="…">` shim.

---

## Companion guide flip scope

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Strict DOC-03 (READMEs only) | Flip only `accrue/README.md` Stability + root README Maintenance posture; leave `maturity-and-maintenance.md`, `upgrade.md`, etc. for later. | |
| 2. Comprehensive flip | Flip every `pre-1.0` / `0.x` / `intake-gated` mention in user-facing docs. | |
| 3. Two-pass scoped | Flip the four user-facing docs the README cross-links explicitly name + REL-07 mandates (READMEs + `maturity-and-maintenance.md` + `upgrade.md`). Skip `release-notes.md` (historical past-tense), `production-readiness.md` line 11 (`~>` install-mechanics, couples to Phase 92), `first_hour.md` line 22 (intake-gated doctrine survives 1.0). | ✓ |

**Selected:** Option 3 (Two-pass scoped) — Strict DOC-03 leaves stale prose one click in (canonical "release fights its own docs" footgun). Comprehensive sweep over-reaches into past-tense historical text. Two-pass scoped matches v1.27 CLS precedent shape and the Phoenix / Ecto 3.0 surgical-pass approach (front door + immediate stability/upgrade story; not every passing past-tense reference).

**Notes:** Concrete edits per file locked in CONTEXT.md D-13 (line numbers, exact prose flips, install-literal exclusions). Verifier risk surface confirmed empty — none of the 6 merge-blocking verifiers pin "pre-1.0" / "0.x" / "intake-gated" / `## Stability` literal prose. Install snippet `{:accrue, "~> 0.3.1"}` is NOT touched in Phase 91 — verifier-pinned to `mix.exs @version`, Phase 92's bump owns it.

**DOC-04 non-goals reaffirmation shape (auto-applied):** new dated `### Reaffirmed at 1.0.0 (2026-04-26)` sub-section under `.planning/PROJECT.md` non-goals (line ~150). Single greppable anchor for falsifiable verification, matches v1.27 CLS-03 dated-pass precedent. Does NOT lift PROC-08 / FIN-03 — they stay non-goals (the whole point of DOC-04).

---

## Claude's Discretion

- Exact preamble wording in CHANGELOG entries (D-05) — planner may tighten by ≤20% if reviewers want shorter; structure (3-line `accrue` + 2-line `accrue_admin`, Unreleased-anchored) is locked.
- Bullet wording in `## Post-1.0 cadence (maintainer intent)` (D-11) — planner may rephrase for grep-friendliness; structure (10 numbered items in the order listed) is locked.
- Exact insertion point for the new `@public_api` list inside `maturity-and-maintenance.md` (D-13) — top-of-file vs under existing header, planner picks based on current doc shape.
- Whether `091-VERIFICATION.md` transcript annex is one combined block or per-requirement subsections (D-18) — keep grep-friendly.

## Deferred Ideas

- `accrue/guides/release-notes.md` line 52 "Minor (pre-1.0)" flip — past-tense describing 0.x history; correct as-is. Will be naturally superseded when Phase 92 / future minors append a 1.0.0+ entry.
- `accrue/guides/production-readiness.md` line 11 "stability boundary for pre-1.0 minors" flip — couples to `~>` install-literal mechanics; Phase 92 PPX-12 owns it.
- `accrue/guides/first_hour.md` line 22 "intake-gated" flip — doctrine, not version-tied. Survives 1.0.
- `RELEASING.md` `## Appendix: Same-day 1.0.0 bootstrap (exceptional)` demotion — Phase 92 territory or v1.31 hygiene pass.
- Forward-port window other than 6 months — auto-applied 6 months (Elixir/Oban precedent); flagged for visibility, user can override at PR review.

## Research subagents spawned

Four parallel `gsd-advisor-researcher` agents (2026-04-26):

1. **PR sequencing** — researched Phoenix LiveView 1.0, stripity_stripe 3.0, release-please for Elixir, semver.org adopter-trust footguns; recommended A2 (HIGH-impact flag); synthesis chose A1 with mitigating prose discipline (commitment-level voice + Unreleased-anchored CHANGELOG).
2. **CHANGELOG shape** — researched Keep a Changelog 1.1.0, Release Please customizing (`BEGIN_COMMIT_OVERRIDE`), Broadway 1.0 / LiveView 1.0 / Ecto 3.0 verbatim 1.0.0 entries; recommended Hybrid (auto-apply); accepted.
3. **RELEASING.md structure** — researched Phoenix `RELEASE.md`, Pay (Rails) CHANGELOG, Elixir core "Compatibility and Deprecations", Oban v2.0 upgrade guide; recommended Replace-in-place + present-progressive (flagged forward-port number + CLS-02 anchor as coupled forks); both auto-resolved.
4. **Companion guide flip scope** — read `verify_*.sh` scripts directly to confirm zero pre-1.0 / 0.x prose pins; recommended Two-pass scoped (auto-apply); accepted.
