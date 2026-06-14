# Phase 187: Audit & Baseline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 187-audit-baseline
**Areas discussed:** Rubric schema, Audit matrix boundary, Live interaction probes, Baseline artifact format

---

## Rubric Schema

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve v1.51 10 dimensions; add interaction-integrity and microcopy; model layer/z-index as overlay tags | Keeps v1.51 comparability, gives screenshots-miss defects and copy their own scoring lanes, avoids over-weighting one foundation mechanism. Requires explicit overlay examples to prevent inconsistent tagging. | yes |
| Promote interaction-integrity, layer/z-index, and microcopy to first-class dimensions | Simple flat scorecard and makes layer defects visible. Noisier comparison, double-counts modal/dropdown failures, and turns a token/foundation mechanism into its own quality dimension. | |

**User's choice:** User selected all gray areas and requested subagent-backed, recommendation-first synthesis so routine choices could be locked without more back-and-forth.
**Notes:** Advisor recommendation accepted as the coherent package: keep the original 10 dimensions, add `11 interaction-integrity` and `12 microcopy`, and require layer/z-index overlay tags instead of a 13th dimension.

---

## Audit Matrix Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Manifest-driven representative matrix | Every audited surface has applicable state scenarios across canonical viewport/theme modes, plus targeted breakpoint and interaction probes. Idempotent and comparable without combinatorial explosion. | yes |
| Literal Cartesian product | Maximum theoretical coverage and easy to explain, but creates impossible cells, brittle screenshots, duplicated findings, and Phase 187 scope creep. | |

**User's choice:** User requested all areas be researched and synthesized into one set of recommendations.
**Notes:** Advisor recommendation accepted: define "full matrix" as a replayable manifest with `covered`, `gap`, and `n/a` cells. Use existing desktop/mobile Playwright projects and light/dark themes, with targeted 320/375/768/1024/1440 probes only where layout risk exists.

---

## Live Interaction Probes

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid ledger-first exploratory probes plus targeted repeatable Playwright assertions | Fits Phase 187 audit scope, catches defects screenshots and axe miss, produces reproducible ledger entries, and avoids encoding broken behavior as permanent tests. | yes |
| Full automation-first interaction matrix now | More repeatable from day one, but too much build work for an audit phase and likely duplicates Phase 191 remediation/regression work. | |

**User's choice:** User requested a deep expert lens across UI/UX, DX, Phoenix/LiveView, accessibility, and software engineering.
**Notes:** Advisor recommendation accepted: run the full exploratory interaction probe set now, automate stable baseline contracts when feasible, and leave exhaustive corrected-behavior regression tests to Phase 191.

---

## Baseline Artifact Format

| Option | Description | Selected |
|--------|-------------|----------|
| Markdown-only ledger/scorecard | Easy to read and matches some v1.51 precedent, but brittle for Phase 192 comparison and hard to parse safely. | |
| Hybrid committed baseline: markdown summary plus schema-checked JSON/NDJSON plus artifact manifest | Human-readable and machine-comparable, reuses existing NDJSON scoring precedent, supports Phase 192 no-regression comparison, and avoids committing bulky generated screenshots/traces. | yes |

**User's choice:** User requested one-shot recommendations that are cohesive with project goals and strong DX.
**Notes:** Advisor recommendation accepted: commit `187-RUBRIC.md`, `187-BASELINE.md`, `baseline.cells.json`, `defects.ndjson`, `artifacts.manifest.json`, and schemas if cheap. Structured data is canonical when it disagrees with markdown.

---

## the agent's Discretion

- Exact JSON schema details and helper script names.
- Exact Playwright spec/probe grouping.
- Exact severity labels, provided they remain rankable and documented.
- Whether to harden known Phase 179 harness issues before the audit run if they would compromise evidence quality.

## Deferred Ideas

- Full per-defect regression tests after fixes - Phase 191.
- CI no-regression guardrails - Phase 192.
- SARIF/GitHub code-scanning export for UI defects - optional later.
- PhoenixStorybook dependency - still deferred.
