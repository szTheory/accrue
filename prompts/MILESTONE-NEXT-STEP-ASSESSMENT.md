# Milestone Next-Step Assessment (re-runnable ritual)

> Saved 2026-05-24 so this no longer has to be re-pasted at each milestone.
> Run it from the root of ONE GSD-managed Elixir/Phoenix OSS lib at a new-milestone
> step. It produces a practical adopter-facing "how done is this lib / what's the
> single highest-leverage next milestone" assessment, retains learnings into the
> proper GSD places, then **STOPS before building or kicking off the milestone**.
> Invoke with: "run prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md".

## Context / role

I'm in the root of ONE of my Elixir/Phoenix OSS library projects (GSD-managed, has a
`.planning/` dir and usually a `prompts/` research subdir). I build these with GSD on a
lot of autopilot, so a lib often grows strong before I've internalized what's already
built, how complete the real adopter story is, and what the highest-leverage next
milestone is. I'm running this AT A NEW MILESTONE STEP to (a) re-check how close this lib
is to "done", (b) pick the single highest-leverage next milestone, and (c) retain new/
updated lessons + investigations in the proper place so future milestones start informed.

This is NOT a generic code review or repo-health audit. I want a practical product/
adopter-facing assessment from the perspective of a Phoenix SaaS developer who'd actually
use this lib in a real app.

## Core question

How close is this library to being "done enough" for its stated scope before additional
work hits diminishing returns — and if it's not done, what is the single most impactful
next milestone / wedge, and what are the next few after it?

**What "done" means:** does this lib have the core user flows / JTBD / features / docs /
install path / examples / operator-admin-diagnostic surfaces / support-truth / proof
posture that a serious Phoenix SaaS developer expects from a library in this category?
Optimize for realistic adopter value, NOT perfectionism, and NOT phase/milestone counting.

## Framing principles

- Repo-local truth first. Inspect the ACTUAL repo (lib/ source, tests, examples) instead
  of trusting milestone names or one doc. Separate "already built but under-documented"
  from "not actually built".
- Separate "important missing core wedge" from "adjacent maybe-nice-to-have".
- If the stated scope is intentionally narrow, don't punish it for not becoming a platform.
- If planning docs drift or disagree, call it out and LOWER confidence rather than fake
  certainty. Prefer concrete shipped/open evidence over aspirational docs.
- Be honest if the lib is stronger than I think, or if I'm at risk of overbuilding.
- Use subagents / parallel exploration for context-window efficiency wherever it helps.

## What to do

1. **Understand what this lib actually is** — read `.planning/{PROJECT,ROADMAP,REQUIREMENTS,STATE,MILESTONES}.md`
   and archived `.planning/milestones/*`; any JTBD / gap-map doc; recent
   `.planning/phases/NN-*/NN-LEARNINGS.md` and `.planning/threads/*` (don't re-derive these);
   **all planted seeds `.planning/seeds/SEED-*.md` and candidate-milestone research `.planning/research/*.md`
   (these carry queued future-milestone options — e.g. SEED-004 admin-UI blueprint redesign — that the
   ROADMAP "Deferred Seeds and Ideas" table only points at; read them so a candidate is never missed);**
   README + key guides; the `prompts/` research subdir (`*-deep-research.md`, `*-oss-dna.md`,
   `*_context.md`, brand/UX docs, `*_journey_blueprint.md`); enough lib/ source + tests + examples
   to sanity-check REAL vs described.
2. **Explain the current adopter story briefly** — the one job; which flows are clearly
   real today; which Phoenix SaaS adopters it serves well; where the story is still rough.
3. **Estimate how "done" it is** — rough done-% justified by this rubric (NOT by counting
   phases): core JTBD coverage · breadth vs category expectations · docs/onboarding/examples/
   install · operator/admin/diagnostic/support-truth · proof/CI/verification honesty ·
   whether the remaining delta is FOUNDATIONAL / IMPORTANT-BUT-NARROW / LONG-TAIL POLISH.
   Bands: 90-95% near-done · 80-89% strong, meaningful wedges remain · 70-79% credible+useful,
   important gaps · <70% missing foundational expectations. If effectively done, say so.
4. **Research candidate next milestones** (subagents in parallel, one per serious candidate).
   For each: pros/cons/tradeoffs grounded in a concrete example; what's idiomatic for
   Elixir/Plug/Ecto/Phoenix; lessons from successful libs in the space (incl. other
   ecosystems) — steal the rights, avoid the footguns; DX, least-surprise, UI/UX where
   relevant; grounded in the prompts corpus + `.planning` truth so candidates stay coherent
   with the project's vision (not a grab-bag).
5. **Pick THE next milestone** — rank top 3-5 wedges; name the single highest-leverage one
   and what "done enough" looks like; call out tempting diminishing-returns/adjacent/
   overbuilding items; suggest ordering for the few after it.
6. **Verdict** — keep pushing / finish the last wedges / probably stop soon — plus a blunt
   maintainer takeaway: if you were me, what would you build next? If the honest answer is
   "nothing major, this is basically done for its scope," say that directly.

## Bookkeeping (do this, then STOP — don't build)

- Append genuinely new lessons/decisions/surprises to the relevant
  `.planning/phases/NN-*/NN-LEARNINGS.md` (or note they belong in the next phase's learnings);
  flag cross-phase "graduation" candidates.
- Record/refresh open INVESTIGATIONS + cross-session context as `.planning/threads/*` entries.
- Update `.planning/STATE.md` (current position, decisions, blockers) and PROJECT.md
  decisions/out-of-scope if this assessment changes them.
- Don't duplicate what the repo already records; don't invent files GSD doesn't use.
- Then STOP — produce the assessment + recommendation + bookkeeping and hand back. Do NOT
  write implementation/feature code and do NOT auto-run `/gsd:new-milestone` this pass.

## Shift-left into GSD

Where this expresses a RECURRING preference (subagent research, idiomatic-Elixir lens,
DX/UX-first, lessons/investigations retention, adopter-first "done" lens): auto-apply
low-risk routine prefs to `~/.gsd/defaults.json` (global) or `.planning/config.json`
(project) and say exactly what changed. For VERY impactful changes (model profile;
disabling research/plan-check/verifier/nyquist or any quality gate; anything that changes
WHAT gets built or skips verification): surface and ASK FIRST.

## Constraints

- Focus on THIS lib only.
- Prefer repo-local inspection over the internet; browse only when truly needed for a
  current-expectation or market-comparison claim.
- Report + bookkeeping/shift-left ONLY — no feature code, no starting the build.
- Label assumptions; when docs conflict, prefer concrete shipped/open evidence and note the
  inconsistency + lower confidence.

## Output shape

1. Framing — what the lib is, what "done" means here, confidence caveats if docs drift.
2. Current state — one-line job, rough done-% + band, short paragraph on what's clearly real.
3. Adopter coverage map — well-served / partially-served / still-rough flows.
4. Next-work recommendation — top 3-5 wedges, why each matters, "done enough" for each,
   the single pick, suggested ordering.
5. Diminishing-returns judgment — high-leverage vs polish/adjacent/overbuilding.
6. Blunt maintainer takeaway.
7. Bookkeeping written — exactly which LEARNINGS/threads/STATE/PROJECT entries added/updated;
   graduation candidates surfaced.
8. Shift-left applied — config/default changes auto-applied + any high-impact asks.

Style: no fluff, strong product judgment, high signal density, staff+ engineer who
understands Phoenix/Elixir OSS product strategy. Before finalizing, sanity-check that every
conclusion comes from ACTUAL repo inspection — not milestone names or a single doc.
