# Phase 203: database-schema-contract-adr - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-02
**Phase:** 203-database-schema-contract-adr
**Areas discussed:** Contract Strength, Binding Surfaces, Compatibility Story, Phase 204 Handoff

---

## Contract Strength

| Option | Description | Selected |
|--------|-------------|----------|
| Firm accepted contract with BCP-14-style `MUST`/`MAY` | Clear support boundary and testable behavior, but risks overpromising if future hardening is phrased as already implemented. | |
| Lighter decision note | Low ceremony and easy to read, but weak against docs/test drift and ambiguous for support. | |
| Hybrid ADR: normative current contract plus advisory future hardening | Locks current `billing`/`public` behavior while keeping future checks explicitly queued. | yes |

**User's choice:** Discuss/consider all areas with subagent research and one-shot recommendations; Claude recommendation accepted for downstream context.
**Notes:** Use firm language for current behavior and non-goals only. Keep future checks as follow-up work for Phase 204 ranking.

---

## Binding Surfaces

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal surfaces | Small ADR that records current posture only; leaves drift risk across installer/docs/tests/raw SQL. | |
| All binding surfaces | Strong immediate enforcement; too broad for an ADR phase and risks accidental implementation churn. | |
| Layered authoritative surfaces | Authoritative executable contract in config/schema/migration/installer generation; docs/example/tests mirror it. | yes |

**User's choice:** Discuss/consider all areas with subagent research and one-shot recommendations; Claude recommendation accepted for downstream context.
**Notes:** Name all relevant surfaces but do not implement guards in Phase 203.

---

## Compatibility Story

| Option | Description | Selected |
|--------|-------------|----------|
| Terse compatibility note | Keeps ADR short but under-warns existing installs. | |
| Detailed upgrade warning | Names compile-time config, existing `public`/`billing` pins, and host-owned data movement. | yes |
| Migration recipe | Useful for rare schema moves, but implies Accrue endorses or automates production table relocation. | |

**User's choice:** Discuss/consider all areas with subagent research and one-shot recommendations; Claude recommendation accepted for downstream context.
**Notes:** No schema relocation recipe in this phase. Existing installs must pin intended schema before recompilation.

---

## Phase 204 Handoff

| Option | Description | Selected |
|--------|-------------|----------|
| Short narrative list | ADR-friendly but hard for Phase 204 to rank against CI/adoption work. | |
| Structured table/checklist | Rankable, evidence-backed, and consistent with Phase 202 handoff shape. | yes |
| Issue-ready implementation cards | Actionable but premature before Phase 204 ranks cross-audit work. | |

**User's choice:** Discuss/consider all areas with subagent research and one-shot recommendations; Claude recommendation accepted for downstream context.
**Notes:** Handoff rows should include evidence path, risk, impact, tradeoff, implementation approach, verification, rollback, and non-goals.

---

## Claude's Discretion

- Exact ADR section order, table labels, and wording may be tuned by the planner/researcher as long as the locked decisions in `203-CONTEXT.md` hold.
- The planner/researcher may add concise examples for developer understanding, but must not turn the ADR into a migration runbook or implementation plan.

## Deferred Ideas

- Actual schema-prefix hardening implementation.
- Any default rename from `billing` to `accrue`.
- Any automatic production data movement or schema relocation recipe.
- UI/admin/portal and brandbook pending todos.
