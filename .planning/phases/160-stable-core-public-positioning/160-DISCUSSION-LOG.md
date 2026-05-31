# Phase 160: Stable-Core Public Positioning - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 160-Stable-Core Public Positioning
**Areas discussed:** Stable-core claim strength, Adopter-facing doc spine, Support-boundary mirrors, Verifier / release-note contract

---

## Stable-Core Claim Strength

| Option | Description | Selected |
|--------|-------------|----------|
| Quiet maintenance posture | Implied through changelogs and sparse README hints. Low churn, but easy to miss and weak for POS-01/POS-03. | |
| Explicit stable-core / done-enough statement | Publicly state Accrue is stable-core for declared scope, with demand-driven reopen triggers. | yes |
| Strong feature-freeze language | Very clear against scope creep, but risks signaling abandonment and conflicts with demand-driven expansion. | |
| Release-notes-only framing | Keeps top-level docs product-focused, but most evaluators miss it and it fails first-time discoverability. | |

**User's choice:** Asked to discuss all areas with subagent research and produce one cohesive recommendation.
**Notes:** Selected recommendation is explicit stable-core / done-enough statement with reopen triggers. Avoid "feature freeze", "maintenance only", and "no new features ever".

---

## Adopter-Facing Doc Spine

| Option | Description | Selected |
|--------|-------------|----------|
| Root README as canonical spine | Best GitHub first impression, but becomes long and duplicated quickly. | |
| `accrue/README.md` as single source of truth | Strong Hex package landing, but weak monorepo/package-map handoff. | |
| Jobs to Be Done as canonical narrative | Best complete-loop clarity, but not enough for install/setup alone. | |
| Maturity guide as canonical SSOT | Strong posture signal, but too policy-heavy as first success path. | |
| Layered hub-and-spoke | Root orientation, package landing, First Hour setup, JTBD capability loop, maturity posture, production checklist. | yes |

**User's choice:** Asked for a one-shot perfect set of coherent recommendations.
**Notes:** Selected recommendation is a layered doc architecture where each surface owns one job and mirrors stay thin.

---

## Support-Boundary Mirrors

| Option | Description | Selected |
|--------|-------------|----------|
| Processor support matrix SSOT + thin mirrors | One canonical capability truth with short public/package mirrors. | yes |
| Package README-specific boundaries | Strong package-local DX but high drift risk across packages. | |
| Central public guide SSOT + matrix as maintainer artifact | Better public discoverability, but creates dual-SSOT risk unless generated. | |
| Release-note-driven boundary summary | Good for deltas, poor as static support reference. | |
| Broad duplication with drift gates | Local context everywhere, but brittle and contradiction-prone. | |

**User's choice:** Asked to consider ecosystem examples and avoid footguns.
**Notes:** Selected recommendation keeps canonical capability truth centralized and allows only short mirrors. Do not duplicate row-by-row capability tables or invent support-label synonyms.

---

## Verifier / Release-Note Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Prose-only manual review | Flexible but depends on reviewer memory and weakens POS-03. | |
| Extend `verify_package_docs.sh` only | Minimal moving parts, but turns the script into a mixed-concern mega-gate. | |
| New dedicated `verify_stable_core_posture.sh` | Focused POS-03 contract with clear failure prefix and triage. | |
| Tie release notes fully to posture copy | Catches release drift but awkwardly couples posture to version headings. | |
| ExUnit docs contract tests | Useful if thin shell-out, risky if duplicating bash needles. | |
| Combined bundle with dedicated verifier + light release-note cross-check | Dedicated posture verifier, CI wiring, triage docs, minimal release-note token/pointer, optional shell-out test. | yes |

**User's choice:** Asked for recommendations that emphasize great engineering, least surprise, and DX.
**Notes:** Selected recommendation is a new dedicated posture verifier wired into `docs-contracts-shift-left`, with narrow bash needles and a light `verify_release_notes_contract.sh` extension.

---

## the agent's Discretion

- Exact copy is left to downstream implementation, but must preserve explicit stable-core / demand-driven posture without abandonment language.
- Exact verifier needles are left to downstream implementation, but must be narrow, intentional, grep-friendly, and documented in `scripts/ci/README.md`.
- A public support-boundary guide or generated excerpt is allowed only if it does not create a second hand-maintained capability SSOT.

## Deferred Ideas

None — discussion stayed within Phase 160 stable-core public positioning scope.
