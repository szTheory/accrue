# Phase 214: Docs & truth reconciliation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-30
**Phase:** 214-docs-truth-reconciliation
**Areas discussed:** Canonical sync wording, Release-note allocation, Public API
versioning, Historical truth policy, Drift prevention

---

## Canonical sync wording

| Option | Description | Selected |
|--------|-------------|----------|
| Local gate + advisory cache | Local plan→feature mapping is the canonical Accrue grant gate; optional Stripe sync supplies diagnostic evidence only. | ✓ |
| Processor-authoritative projection | Stripe is authoritative and Accrue reconciles a local projection; idiomatic for money objects but ambiguous for authorization. | |
| Stripe Entitlements as source of truth | Stripe-native entitlements directly define access. Contradicts the shipped provider-honest gate and isolation proof. | |
| Dual-source drift framing | Present local and Stripe state as two comparable sources. Useful secondary operator language but misleading as the headline. | |

**User's choice:** Research all options and choose the strongest coherent recommendation.

**Notes:** Specialist research compared Stripe, Pay, Cashier, Phoenix contexts, Ecto
contracts, and Accrue's shipped verification. The selected wording preserves one
authorization authority and uses drift language only to explain the advisory cache.

---

## Release-note allocation

| Option | Description | Selected |
|--------|-------------|----------|
| Core detail + sibling coordination | Core records the full dependency/API story; admin/portal record linked-version compatibility without claiming feature ownership. | ✓ |
| Duplicate full notes everywhere | Maximum visibility, but falsely implies three-package ownership and triples drift risk. | |
| Core only | Clean ownership, but leaves linked admin/portal changelog consumers without an explanation. | |
| Plain-language mirror only | Avoids changelog prose, but fails package-local history and DOCS-03. | |

**User's choice:** Research all options and choose the strongest coherent recommendation.

**Notes:** The recommendation follows the linked Release Please model while preserving
package-local ownership. It adds portal changelog discoverability and keeps generated
ExDoc output out of manual edits.

---

## Public API versioning

| Option | Description | Selected |
|--------|-------------|----------|
| Annotate every public `def` | Treat technical callability as a public contract; overexposes adapter and reconciliation plumbing. | |
| Annotate supported adopter contracts | Badge the public refresh, processor facade/callback, and Fake test helper; keep plumbing hidden. | ✓ |
| Annotate refresh only | Minimal public story, but under-documents custom processor and deterministic test contracts. | |
| No `since` metadata | Avoid version prediction, but violates Elixir guidance and DOCS-03. | |

**User's choice:** Research all options and choose the strongest coherent recommendation.

**Notes:** Initial repository assumptions used `1.4.0`; adversarial tag/commit review
proved this wrong. Phase 213 landed after `accrue-v1.4.0`, so all supported additions
must consistently use the normal next feature version, `1.5.0`.

---

## Historical truth policy

| Option | Description | Selected |
|--------|-------------|----------|
| Update current truth; preserve dated evidence | Correct adopter/current planning surfaces while leaving historical phases, archives, seeds, and evidence truthful to their dates. | ✓ |
| Rewrite every old match | Makes unscoped grep cleaner but fabricates history and damages auditability. | |
| Preserve everything; add one summary | Protects history but leaves current public docs contradictory. | |

**User's choice:** Research all options and choose the strongest coherent recommendation.

**Notes:** The acceptance grep becomes path-aware. A dated statement that the sync was
deferred is evidence; the same statement in the current JTBD capability row is drift.

---

## Drift prevention

| Option | Description | Selected |
|--------|-------------|----------|
| One-time manual grep | Low effort but provides no future protection. | |
| Extend existing contracts | Add semantic positives/negatives and failure fixtures to the package-doc and release-note verifiers already in CI. | ✓ |
| Add a dedicated verifier | Clear name, but duplicates ownership and adds another CI/triage surface for a bounded truth family. | |

**User's choice:** Research all options and choose the strongest coherent recommendation.

**Notes:** Checks protect semantics rather than exact paragraphs. Negative fixtures prove
that stale versions, deferred-current status, and grant-authority inversion fail without
freezing audience-specific prose.

---

## the agent's Discretion

- Audience-specific shortening of the canonical wording without dropping its four facts.
- Exact Unreleased/next-release heading and bullet ordering.
- Internal organization of helpers inside the existing verifier families.
- Exact negative fixture sentences.

## Deferred Ideas

None.
