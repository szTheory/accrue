# Phase 201: software-quality-evaluation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-02
**Phase:** 201-software-quality-evaluation
**Areas discussed:** Audit stance and bluntness, Evidence boundary, Scope split with Phases 202 and 203, Treatment of folded todos

---

## Audit Stance And Bluntness

| Option | Description | Selected |
|--------|-------------|----------|
| Blunt scored audit | Forces priority, exposes weakest dimensions, useful for Phase 204, but can read like a public report card and imply false precision. | |
| Balanced readiness report with scored triage | Keeps blunt ranking while framing findings as release-readiness triage; safer for Accrue's stable-core OSS posture. | x |
| Narrative quality review | Most readable and good for context, but weakens traceability and prioritization if used alone. | |

**User's choice:** Discuss all and produce one coherent recommendation set with research and subagents.
**Notes:** Advisor research recommended a balanced readiness report with a blunt scored core. The audit should remain maintainer-facing, evidence-backed, and brand-voice-aligned.

---

## Evidence Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Static repo evidence only | Fully repeatable and low burden, but cannot prove dynamic CI/runtime claims. | |
| Limited command verification | Keeps repo evidence primary while allowing cheap deterministic checks for drift and confidence. | x |
| Live/external metrics | Best for CI runtime, flake, and public trust signals, but dynamic, auth-dependent, and largely Phase 202 scope. | |

**User's choice:** Discuss all and recommend the least-surprise path.
**Notes:** Advisor research recommended static repo evidence as primary plus limited cheap verification. Full CI, Docker, live Stripe, GitHub run history, and external scorecards should be labeled as follow-up metrics, not Phase 201 requirements.

---

## Scope Split With Phases 202 And 203

| Option | Description | Selected |
|--------|-------------|----------|
| Shallow mention only | Clean boundary, but Phase 201 under-explains major quality risks. | |
| Integrated summary with explicit handoff | Keeps Phase 201 broad and useful while preserving 202/203 ownership of specialist detail. | x |
| Full deep dive inside Phase 201 | Self-contained, but duplicates specialist artifacts and risks conflicting recommendations. | |

**User's choice:** Discuss all and make recommendations cohesive across phases.
**Notes:** Advisor research recommended integrated summaries. Phase 201 should rank CI/CD and schema-prefix safety as cross-quality risks; Phase 202 owns detailed CI measurement/topology; Phase 203 owns the accepted DB schema ADR.

---

## Treatment Of Folded Todos

| Option | Description | Selected |
|--------|-------------|----------|
| Named weaknesses | Useful when the todo is a current adoption/support risk, but can over-expand phase scope. | |
| Supporting evidence | Lets a todo inform an existing weakness without becoming implementation scope. | x |
| Deferred polish | Right for real but low-risk visual/public-trust cleanup. | x |
| Resolved/no-op | Right when repo evidence shows the pending todo is already implemented. | x |

**User's choice:** Fold all matched todos, but consider them through the audit lens.
**Notes:** White-label portal design-system becomes supporting evidence for portal parity/customer portal UX. PageHeader is resolved/positive evidence. Brandbook favicon is deferred polish.

---

## Claude's Discretion

- Exact audit table structure, score wording, and appendix layout.
- Exact cheap supporting commands to run, if any, during planning/execution.
- Exact brand-voice wording, as long as risks stay concrete and evidence-backed.

## Deferred Ideas

- Future portal readiness/design-system and white-label implementation pass.
- Brandbook favicon HTML polish.
- Todo hygiene for the resolved PageHeader artifact.
- Phase 202 GitHub run-history/CI baseline metrics.
- Future schema-prefix hardening implementation.
