# Phase 220: First-adopter proof and release gates - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-04
**Phase:** 220-first-adopter-proof-and-release-gates
**Areas discussed:** Reference-host proof shape, deterministic scenario contract, operator and repair proof, public release contract

---

## Reference-host proof shape and deterministic scenario contract

| Option | Description | Selected |
|--------|-------------|----------|
| Versioned data-only corpus | Shared synthetic scenario IDs and outcomes consumed by Elixir, Swift, docs, and CI. | ✓ |
| Focused host suites only | Per-test Elixir setup without a shared cross-language corpus. | |
| Browser-first proof | Playwright walkthrough as the principal oracle. | |

**User's choice:** Approved the cohesive recommendation.
**Notes:** Deterministic, credential-free evidence is merge-blocking; runtime-capability claims remain blocked until their specific Crosswake evidence exists.

---

## Operator and repair proof

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded diagnostic projection plus safe repairs | Typed, privacy-bounded account diagnosis with separately authorized repair actions. | ✓ |
| Direct Ecto/Oban inspection | Admin or runbooks expose storage schemas and job internals directly. | |
| External observability as primary diagnosis | Logs/APM dashboards replace a durable account-level diagnosis contract. | |

**User's choice:** Approved the cohesive recommendation.
**Notes:** UI/API stays job-and-next-action focused; raw provider material, PII, proof bytes, and worker internals remain hidden.

---

## Public release contract

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical fixture plus generated matrix and hand-authored guides | Machine-checked exact limits with readable guidance/runbooks/release material. | ✓ |
| Guide-only bundle | Human-authored docs without a contract fixture. | |
| Fully runtime-generated documentation | Generate public docs directly from runtime modules. | |

**User's choice:** Approved the cohesive recommendation.
**Notes:** Generated facts prevent support-matrix drift; human prose retains App Review, incident, privacy, and explanatory nuance.

---

## the agent's Discretion

The user delegated exact implementation, architecture, tooling, UI/API presentation, documentation structure, and test composition to recommendations that preserve the locked boundaries and support a coherent first-adopter release contract.

## Deferred Ideas

None.
