# Phase 226: ci-baseline-proof-semantics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-10
**Phase:** 226-ci-baseline-proof-semantics
**Areas discussed:** Comparable cohort validity, Proof semantics, Maintainer DX

---

## Comparable Cohort Validity

| Option | Description | Selected |
|---|---|---|
| Strict fail-closed cohort | Exactly three eligible green first-attempt dispatches; reruns stay diagnostic. | ✓ |
| Include reruns | Use reruns as baseline members. | |
| Different policy | User-defined alternative. | |

**User's choice:** Strict fail-closed cohort, then approval to follow the remaining recommendations.
**Notes:** Missing provider facts require explicit field-level omission reasons; root signatures are normalized/privacy-safe; cache evidence remains conservative.

---

## Proof Semantics

| Option | Description | Selected |
|---|---|---|
| Three-fact fail-closed model | Preserve policy, conclusion, and proof state independently. | ✓ |
| Simplified overall status | Collapse semantics into one status. | |
| Different model | User-defined alternative. | |

**User's choice:** Three-fact fail-closed model, then approval to follow the remaining recommendations.
**Notes:** Provider enforcement is a dated API snapshot; explicit policy mapping replaces name heuristics; provider errors cannot become `not-found`.

---

## Maintainer DX

| Option | Description | Selected |
|---|---|---|
| Command-first triage home | Keep one `scripts/ci/README.md` entry point and link to owner scripts. | ✓ |
| Dedicated competing guide/dashboard | Add another maintainer interface. | |
| Different interface | User-defined alternative. | |

**User's choice:** Follow synthesized recommendations automatically.
**Notes:** Preserve ownership matrix, precise proof vocabulary, accessible/copyable documentation, and bounded safe recovery steps. No new product UI or CI dashboard.

---

## the agent's Discretion

- Exact manifest representation, signature normalization, tests, and document layout, subject to the locked fail-closed and privacy constraints.

## Deferred Ideas

- CI topology, matrix, cache, and branch-protection changes remain Phase 227 scope.
