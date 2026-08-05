# Phase 215: Research, contracts, and Crosswake feasibility - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-31
**Phase:** 215-Research, contracts, and Crosswake feasibility
**Areas discussed:** Research authority, Decision-table contract, Crosswake proof bar, Source capability contract

---

## Research Authority

| Option | Description | Selected |
|--------|-------------|----------|
| Existing bundle + prose notes | Preserve current files and record supersession informally in prose. Lowest ceremony, but precedence remains distributed. | |
| Per-topic ADR/RFCs | Give each material decision an immutable rationale document. Strong history, but too fragmented and costly for routine provider/watchlist changes. | |
| Authority manifest + amendments | One discovery/precedence manifest with stable claim IDs, confidence, source provenance, dispositions, and explicit supersession. | ✓ |

**User's choice:** Consider all approaches and delegate the recommendation; optimize for a coherent, one-shot result with strong architecture and developer ergonomics.
**Notes:** The recommendation combines a small authority manifest with immutable amendments rather than adopting a heavyweight RFC process. Current project scope always outranks historical prompt/research material.

---

## Decision-Table Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Normative Markdown only | Most readable, but reducers, tests, fixtures, and support text can drift. | |
| YAML/JSON source | Language-neutral and schema-friendly, but introduces a custom DSL/generator that can become a second reducer. | |
| Data-only Elixir contract + derived artifacts | Idiomatic primary authoring for Accrue, exhaustive ExUnit proof, generated Markdown, and exported Crosswake JSON vectors. | ✓ |

**User's choice:** Delegate the choice after broad Elixir/Phoenix and cross-ecosystem research, emphasizing DX and least surprise.
**Notes:** The contract data must not become production runtime logic or a public API. Stable case IDs connect tests, docs, fixtures, and privacy-safe support explanations.

---

## Crosswake Proof Bar

| Option | Description | Selected |
|--------|-------------|----------|
| Checked-in native iOS tracer | Proves StoreKit, device crypto, secure storage, atomic state, lifecycle, and authenticated host transport against a pinned Crosswake shell. | ✓ |
| Generic Crosswake capability pack | Creates a reusable bridge ABI, but requires upstream product/ABI work and risks generic-plugin scope creep. | |
| Protocol vectors only | Safely advances server protocol work but cannot prove mobile runtime feasibility. | Fallback only |

**User's choice:** Delegate a deep, one-shot recommendation using security, mobile, DevOps/SRE, DX, and user-flow lenses.
**Notes:** Deterministic vectors remain merge-blocking. Simulator evidence is advisory. Physical-device proof and complete host transport are required to declare runtime feasibility; otherwise later mobile coupling is blocked while server work may continue.

---

## Source Capability Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Documentation-only matrix | Clear to humans but cannot support safe host branching or source-specific action guidance. | |
| Behaviour + raw nested map | Familiar from processor capabilities, but booleans/maps collapse meaningful ownership states and create brittle public keys. | |
| Behaviour-backed registry + typed values | Separate source ownership with closed capabilities, outcomes, errors, guidance, docs, and conformance gates. | ✓ |

**User's choice:** Delegate the choice from the consumer/JTBD perspective with idiomatic Elixir API design and user-friendly outcomes.
**Notes:** `externally_managed` and `host_owned` are not generic failures. Apple management guidance is an actionable outcome, while unavailable operations return typed errors. UI mirrors the result in plain language and never infers capability from the processor matrix.

---

## the agent's Discretion

- The user explicitly delegated all four decisions after requesting specialist research, coherent recommendations, idiomatic Elixir/Phoenix design, cross-ecosystem lessons, developer ergonomics, least surprise, and applicable UX/accessibility/brand considerations.
- Exact internal filenames, module names, renderer task name, and authority-ledger placement remain planner discretion within the locked contracts.

## Deferred Ideas

None. UI implementation remains in the already-roadmapped later phases.
