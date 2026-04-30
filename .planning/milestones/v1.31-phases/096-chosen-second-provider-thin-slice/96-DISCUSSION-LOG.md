# Phase 96 Discussion Log

**Date:** 2026-04-29
**Phase:** 96 — chosen second-provider thin slice

This log captures the discussion flow and the recommendation-driven decisions used to produce `96-CONTEXT.md`.

## Discussion Entry

- User selected **all** surfaced gray areas for Phase 96.
- User requested one-shot, research-backed recommendations using subagents, with emphasis on:
  - pros/cons/tradeoffs
  - idiomatic Elixir/Phoenix/Ecto/Plug design
  - lessons from successful adjacent libraries/frameworks
  - least surprise
  - coherent software architecture
  - great developer ergonomics
  - truthful user/adopter experience
  - shifting low-impact decisions left in future GSD flows

## Areas Discussed

### 1. Payment-method handoff

**Alternatives considered**

| Option | Notes |
|---|---|
| Host-owned Braintree acquisition with explicit handoff ref into `subscribe/3` | Keeps browser/provider JS in host, narrow server contract |
| New narrow `Accrue.Billing` helper for vault-acquisition init | Possible future DX improvement, but expands API now |
| Hide acquisition inside `subscribe/3` / implicit PM CRUD | Rejected as least honest and too provider-shaped |

**Locked direction**

- Keep Braintree acquisition host-owned.
- Prefer one narrow handoff reference over raw provider-specific argument sprawl.
- Keep payment-method inventory/CRUD out of the public Phase 96 story unless minimally required internally.

### 2. Proof surface

**Alternatives considered**

| Option | Notes |
|---|---|
| Canonical host as the real Braintree proof surface; installer stays thin | Recommended |
| Installer-generated host as the primary real proof | Too template-heavy and less realistic |
| Both canonical host and installer as full Braintree lanes | Too much maintenance drag and drift risk |
| Package-level provider smoke only | Too abstract for this phase's “real slice” goal |

**Locked direction**

- Use `examples/accrue_host` as the only real Braintree proof surface.
- Keep installer proof limited to boundary integrity, compile/install smoke, and docs/verifier needles.
- Keep provider-backed Braintree proof narrow and advisory.

### 3. `subscribe/3` contract shape

**Alternatives considered**

| Option | Notes |
|---|---|
| Keep `subscribe/3` unchanged and let host magic happen entirely off-screen | Too under-specified |
| Add explicit preparatory helper, keep `subscribe/3` semantic | Strong option if needed |
| Widen `subscribe/3` with Braintree-specific opts | Rejected as provider-keyword sprawl |
| Add provider-specific alternate API | Rejected as facade-boundary drift |

**Locked direction**

- Keep `Accrue.Billing.subscribe/3` as the primary public subscription seam.
- Avoid provider-specific `subscribe/3` option growth.
- If an additional API is needed, prefer one narrow preparatory helper over alternate provider-specific subscription APIs.

### 4. Public positioning

**Alternatives considered**

| Option | Notes |
|---|---|
| Matrix-led, docs-mirrored support truth | Recommended |
| README-led announcement with matrix as detail | Too much overclaim drift risk |
| Provider-guide split | Too much surface for this phase |

**Locked direction**

- Keep `.planning/processor-support-matrix.md` as canonical SSOT.
- Mirror concise support language in package docs and host docs.
- Always name the supported slice explicitly: **gateway subscription core**.
- Keep Stripe default-path language and Stripe-only labels visible.

### 5. Shift-left preference

**Locked direction**

- Future GSD processor-track passes should auto-synthesize low-impact decisions into coherent recommendations instead of escalating them interactively.
- Only reopen choices that materially affect product boundary, public support promise, proof-lane philosophy, or long-term API surface.

## Research Inputs

Parallel advisor research was requested and used for synthesis across:

- payment-method handoff
- proof surface
- `subscribe/3` contract shape
- public positioning

The recommendations consistently favored:

- host-owned UI/browser seams
- bounded first-party promises
- canonical host proof over template bloat
- matrix-led support truth
- explicit slice naming
- avoidance of provider-keyword leakage into generic public APIs

## Result

The recommendations converged without unresolved conflict, so the decisions were written directly into `96-CONTEXT.md` as Phase 96 defaults.
