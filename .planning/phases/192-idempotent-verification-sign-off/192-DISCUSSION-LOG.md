# Phase 192: Idempotent verification & sign-off - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-19
**Phase:** 192-idempotent-verification-sign-off
**Areas discussed:** Final scorecard shape, Adversarial judge loop, CI guardrail boundary, Screenshot sign-off package, Regression repair policy

---

## Final Scorecard Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Machine-readable delta only | Best for CI and artifact comparison, but weak maintainer readability and screenshot/UAT story. | |
| Markdown report only | Easiest to read, but violates the Phase 187 structured-artifact rule and can hide cell regressions. | |
| Hybrid artifacts plus markdown | Machine-readable deltas and readable report; structured data remains canonical. | ✓ |
| Aggregate score summary | Useful only as a summary; not acceptable as the pass/fail gate. | |

**User's choice:** Discuss and consider all; use subagent research; one-shot a cohesive recommendation.
**Notes:** Advisor research converged on a strict hybrid package:
`192-SCORECARD.md`, `final.cells.json`, `scorecard.delta.json`,
`regressions.ndjson`, `artifacts.manifest.json`, and `192-SIGN-OFF.md`.
Every comparable cell must be greater than or equal to the Phase 187 baseline.

---

## Adversarial Judge Loop

| Option | Description | Selected |
|--------|-------------|----------|
| Separate evidence passes per lens | Auditable and maps to existing Playwright/axe/trace/brand artifacts. | ✓ |
| One synthesized scoring run | Simple command surface, but opaque if it owns raw evidence and scoring together. | |
| Human/agent review table | Useful for subjective brand and screenshot acceptance when tied to evidence. | ✓ |
| LLM-only visual scoring | Useful advisory smell check, but nondeterministic and insufficient for a11y/interaction proof. | |

**User's choice:** Research using expert lenses and recommend the cohesive approach.
**Notes:** Locked as a layered evidence system. Raw lens outputs stay separate;
synthesis is a pure reducer over canonical cell IDs; LLM visual scoring is
advisory, not the gate.

---

## CI Guardrail Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Deterministic bounded CI gates | Contributor-reproducible checks without secrets or subjective review. | ✓ |
| Full `npm run e2e` on every PR | Too broad; includes baseline, visuals, traces, and older UAT specs. | |
| Baseline capture/artifacts on every PR | Produces final evidence, but expensive and not a simple pass/fail UI gate. | |
| `score-visuals` as required check | External secret/model and false-green risk when no key/screenshots. | |
| Screenshots/traces as CI artifacts | Good supporting evidence and debugging surface; not merge-blocking by itself. | ✓ |

**User's choice:** Research tradeoffs deeply and pick the best DX/SRE boundary.
**Notes:** Merge-blocking set: BEAM/package CI, `baseline:parse`,
`verify_phase191_ax187_coverage.mjs`, `e2e:group-contracts`, `e2e:phase191`,
`e2e:a11y`, targeted `reduced-motion.spec.js`, and component-lab structural
coverage. Full baseline regeneration, screenshots, traces, and visual scoring
remain final/manual evidence.

---

## Screenshot Sign-Off Package

| Option | Description | Selected |
|--------|-------------|----------|
| Phase-boundary screenshots only | Lightweight but chronology-focused and repeats v1.51 still-image weakness. | |
| Final curated gallery | Human-friendly and JTBD-focused, but must be tied to scorecard evidence. | ✓ |
| Scorecard plus screenshots | Connects full matrix proof to a finite human review surface. | ✓ |
| Generated Playwright artifact links | Useful drill-down evidence, too raw for the primary review surface. | ✓ |
| Human checklist | Necessary final acceptance layer when tied to evidence. | ✓ |

**User's choice:** Consider UI/UX, brand, JTBD, user psychology, accessibility,
dark/light/system, affordances, and microcopy.
**Notes:** Locked as scorecard plus curated gallery plus human checklist in
`192-SIGN-OFF.md`. The gallery is JTBD-first and uses operator nouns/verbs
rather than backend implementation details.

---

## Regression Repair Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Inline all fixes in Phase 192 | Fast but risks turning verification into broad implementation churn. | |
| Inline harness/parser/evidence fixes only | Keeps final verification trustworthy without reopening prior phase scope. | ✓ |
| Blocking subplans for true regressions | Preserves zero-regression requirement and rerun discipline. | ✓ |
| Defer non-regression improvements | Acceptable only for out-of-scope or newly discovered improvements. | ✓ |

**User's choice:** One-shot recommendation that moves toward the project goals and avoids overbuilding.
**Notes:** True UI/a11y/interaction/copy regressions block VER-02..04 and must
be repaired in narrowly scoped Phase 192 plans before rerunning the scorecard.
Only non-regression improvements can be deferred with explicit maintainer note.

---

## Claude's Discretion

- Exact script names, reducer implementation shape, schema field names, CI job
  topology, and curated gallery size are left to researcher/planner discretion
  within the locked decisions in `192-CONTEXT.md`.

## Deferred Ideas

- `White-label billing portal design system` was reviewed but not folded. It is
  future portal/design-system scope, not Phase 192 admin verification scope.
