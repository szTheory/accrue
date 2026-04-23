# Phase 67: Proof contracts — Discussion log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`67-CONTEXT.md`**.

**Date:** 2026-04-23  
**Phase:** 67-proof-contracts  
**Mode:** Research synthesis (user-requested one-shot update; parallel subagents on ecosystem + verifier architecture)

**Areas covered:** Enforcement architecture · Needle strategy · Contributor triage · Cross-ecosystem lessons

---

## Research synthesis — Enforcement architecture

| Topic | Notes | Locked in CONTEXT |
|-------|--------|-------------------|
| Bash vs Mix vs ExUnit-only | For this monorepo, bash shift-left gates are established; Mix task migration would split mental model in one phase | **D-01** |
| ExUnit wrapper vs duplicate literals | Subagent + codebase review: **`OrganizationBillingOrg09MatrixTest`** already delegates to bash — optimal to avoid drift | **D-01**, **D-03** |

**User's direction:** Emphasize great DX, least surprise, coherent architecture — interpreted as **single owner for needles + thin ExUnit harness**.

---

## Research synthesis — Needle strategy

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| More `grep -F` needles | Fast CI, clear failures, matches current stack | Diminishing returns if over-applied to prose | **Use for taxonomy/archetype invariants only** (**D-02**) |
| Full-file snapshots | Catches any drift | Brittle, poor editor DX | **Reject for 67** (**D-02**) |
| AST / codegen SSOT | Strong for large taxonomies | Heavy for current slice | **Defer** (**deferred** in CONTEXT) |

---

## Research synthesis — Contributor triage (**PRF-02**)

- Existing **`scripts/ci/README.md`** triage subsection is the right anchor; extend with explicit **co-update** wording and matrix link — **D-04**.

---

## Research synthesis — Ecosystem lessons (abbrev.)

- **Right:** Same checks locally/CI; narrow contracts; single source per invariant; deterministic doc gates.  
- **Wrong:** Same literal in README + tests + code unrelated to SSOT; CI-only undocumented scripts; dual conflicting enforcement.  
- Mapped to **D-01**, **D-05**, **D-06**.

---

## Claude's discretion

- Inventory ordering and exact final needle count after gap analysis — **D-06** in **67-CONTEXT.md**.

## Deferred ideas

- Mix-native verifier, shared needles JSON, HTML row anchors — see **`<deferred>`** in **`67-CONTEXT.md`**.
