# Phase 25: Admin UX inventory - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `25-CONTEXT.md`.

**Date:** 2026-04-20  
**Phase:** 25 — Admin UX inventory  
**Areas discussed:** Artifact layout; INV-01 vs baseline audit; INV-02 blocking policy; INV-03 table shape (user selected **all**; research via parallel subagents; principal agent synthesized into one coherent policy set)

---

## Artifact layout

| Option | Description | Selected |
|--------|-------------|----------|
| A — Single consolidated doc | One file with INV-01..03 sections | |
| B — Split INV files + README | `25-INV-0*.md` + index + CONTEXT as router | ✓ |
| C — Hybrid + machine artifacts | Markdown + optional CSV/json in `artifacts/` | Partially (optional defer only) |

**User's choice:** Discuss **all** areas; research recommended split deliverables; synthesis **locked D-01** as Option B with optional artifacts deferred.

**Notes:** Subagent compared Elixir OSS (`guides/` vs `.planning/`), Rails/Laravel route doc patterns, and footguns (merge conflicts, duplicate SoT with ROADMAP). Final policy aligns with existing `21-*` / `23-*` multi-file phase conventions.

---

## INV-01 vs ADMIN-UX-BASELINE-AUDIT

| Option | Description | Selected |
|--------|-------------|----------|
| A — Promote audit §1 as canonical | Fast; no mechanical link to router | |
| B — Router + phx.routes / snapshot | Code SoT; drift visible | ✓ (core) |
| C — Hybrid | Audit = narrative; INV-01 = procedure + export | ✓ (framing) |
| D — Tests-only matrix | Route contract tests | (not primary) |

**User's choice:** Research + synthesis **locked D-02**: router + compiled routes canonical; audit §1 prior art; `mix phx.routes` idiomatic; `allow_live_reload` two-class; same-PR refresh discipline.

**Notes:** Subagent cited Phoenix `Mix.Tasks.Phx.Routes`, mount prefix, dev-route footguns.

---

## INV-02 component coverage

| Option | Description | Selected |
|--------|-------------|----------|
| A — Strict (all prod primitives in kitchen) | Maximum catalog | |
| B — Scoped to 21-UI-SPEC surfaces | Money + webhooks + step-up + normative dashboard | ✓ |
| C — Phased backlog + promotion | Non-blocking list + promotion on touch | ✓ (combined with B) |

**User's choice:** **Locked D-03**: scoped blocking + promotion rule; kitchen **or** real-route evidence with shared fixtures; reject strict global kitchen completeness.

**Notes:** Subagent drew lessons from Storybook, Lookbook, Phoenix Storybook (staleness, false coverage); aligned with Phase 26 owning pattern alignment.

---

## INV-03 spec alignment shape

| Option | Description | Selected |
|--------|-------------|----------|
| A — Surface-primary rows | Release checklist style | Secondary rollup only |
| B — Rule-ID-primary rows | Full audit trace | Primary model |
| C — Hybrid two-level | Clauses + surface rollup | ✓ |

**User's choice:** **Locked D-04**: clause-level rows with evidence/owner/Partial discipline + small surface rollup; governance at phase boundaries.

**Notes:** Subagent referenced WCAG-style obligation×evidence, Pay/Cashier informal traceability, footgun of vague “Partial” without target phase.

---

## Claude's Discretion

- Optional `mix` task naming for route export.
- INV-01 inclusion or explicit exclusion of non-LiveView `get` routes under admin scope—document either way in INV-01 header.

## Deferred Ideas

- Empty `artifacts/` or CI snapshot without a generator (deferred).
- Formal spec rule IDs in UI-SPECs (defer; use anchors until then).
