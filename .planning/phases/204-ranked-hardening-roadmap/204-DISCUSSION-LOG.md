# Phase 204: ranked-hardening-roadmap - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-02
**Phase:** 204-ranked-hardening-roadmap
**Areas discussed:** Ranking Rules, Milestone Slicing, Ranked Versus Deferred Boundary, Roadmap Artifact Shape

---

## User Direction

The user selected all gray areas and requested a one-shot researched recommendation set using subagents. The requested lens included:

- Pros, cons, tradeoffs, and concrete examples for each approach.
- Idiomatic Elixir, Plug, Ecto, Phoenix, Hex, DevOps, SRE, and OSS-library expectations.
- Lessons from successful billing libraries in other ecosystems, especially what to copy and what footguns to avoid.
- Strong DX, least surprise, consumer-focused API/docs design, JTBD, user-friendly surfaces, and great UI/UX where applicable.
- Local `prompts/` research and current brandbook guidance, with the newer brandbook superseding older prompt-era brand language.

---

## Ranking Rules

| Option | Description | Selected |
|--------|-------------|----------|
| First-public-push trust | Prioritize what a stranger sees first: version truth, evaluator path, provider semantics, package metadata. | |
| Next-release safety | Prioritize release recovery, provider proof, schema safety, and toolchain truth before the next Hex release. | |
| Maintainer runtime / CI efficiency | Prioritize the weakest audit dimension: CI timing, host setup, gate splitting, and test classification. | |
| Low-effort risk reduction | Prioritize small changes with good risk payoff. | |
| Adopter-proof release-readiness blend | Rank trust breakage first, then data/release safety, measurement prerequisites, runtime efficiency, and low effort only as tie-breaker. | yes |

**User's choice:** "Discuss/consider all" and let researched subagent recommendations drive a cohesive one-shot answer.
**Notes:** The selected rule set ranks public truth, evaluator clarity, provider proof semantics, release recovery, and schema-prefix safety above pure runtime speed. CI remains critical, but topology cleanup waits for baseline measurement.

---

## Milestone Slicing

| Option | Description | Selected |
|--------|-------------|----------|
| Keep draft A-E | Preserve the current five slices: CI baseline, public truth/evaluator, CI cleanup, schema, portal. | |
| Compress to three milestones | Reduce coordination overhead but mix unrelated work. | |
| Measure-first sequence | Baseline proof/CI state before CI cleanup; public/release truth before broad polish. | yes |
| Release-safety-first | Put recovery/provider/toolchain release issues before CI measurement. | |
| Adopter-front-door-first | Maximize first-public-push docs and package trust before internal cleanup. | |

**User's choice:** One coherent researched recommendation.
**Notes:** The final recommendation is a five-slice sequence: Public Truth and Proof-State Baseline; Evaluator Path and Release Safety; CI Critical Path Cleanup; Schema Prefix Contract Hardening; Portal Parity Readiness. The sequence preserves "measure before CI cleanup" while still ranking public/release trust highly.

---

## Ranked Versus Deferred Boundary

| Candidate | Description | Selected |
|-----------|-------------|----------|
| Public truth | Fix toolchain/version/package truth drift. | yes |
| Evaluator proof path | Provide one clone-to-confidence path for a Phoenix evaluator. | yes |
| Provider proof semantics | Make Fake, Stripe, Braintree, proved, skipped, and advisory states explicit. | yes |
| Release recovery preflight | Add machine checks before manual linked-package recovery publish. | yes |
| Schema hardening | Add future guards around `billing`, explicit `public`, prefix agreement, and raw SQL qualification. | yes |
| CI baseline and cleanup | Add baseline summaries first; split gates only after evidence. | yes |
| Package metadata | Fix Hex/GitHub trust signals and descriptions/links. | yes |
| Narrow portal readiness | Treat portal parity as a concrete package-story risk, not broad UI polish. | yes |
| Support triage index | Useful later if support-routing pain appears. | deferred |
| Test value classification | Useful later after CI timing/failure baseline exists. | deferred |
| Broad portal design-system/white-label pass | Valid todo evidence, but too broad without concrete portal adoption failure. | deferred |

**User's choice:** Include all evidence-backed high-leverage items, but avoid overbuilding and polish-only work.
**Notes:** The top 10 keeps narrow portal readiness and defers support triage/test classification. Broad portal white-label work remains deferred unless future evidence upgrades it.

---

## Roadmap Artifact Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Compact top-10 table only | Fast scan, but weak evidence and planner handoff. | |
| Rich implementation rows/cards only | Strong handoff, but rank is buried. | |
| Two-layer artifact | Compact top-10 first, then detailed evidence-backed cards grouped into slices. | yes |
| Milestone-first roadmap | Strong slice planning, but can obscure cross-audit priority. | |
| JTBD-routed playbook | Good reader UX, but not enough by itself for RD-01. | |

**User's choice:** One researched recommendation.
**Notes:** Selected two-layer shape. Required sections: How to read this roadmap, Ranking method, Ranked Top 10, Implementation Cards, Suggested Follow-Up Milestones, Explicit Deferrals, Requirement Coverage, Phase Handoff and Boundary.

---

## Claude's Discretion

- Exact prose and table/card layout may be adjusted during planning, but the ranking rule, recommended top 10, milestone sequence, and two-layer artifact shape are locked unless new repo evidence contradicts them.
- Low effort may break ties only within the same risk class.
- Future planner may combine release/public-truth items when implementation dependencies make that cleaner.

## Deferred Ideas

- Test value classification until CI baseline evidence exists.
- Broad portal white-label/design-system/UI polish.
- Support triage index until repeated support-routing evidence exists.
- Pixel-diff visual regression tooling.
- Default schema rename to `accrue`.
- CI gate demotion/deletion before measurement.
