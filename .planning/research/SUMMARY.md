# Research Summary: Accrue Track 4 (Elixir/Phoenix/Ecto/Plug Idiomatic Architecture)

**Domain:** Elixir/Phoenix billing library + mounted admin/portal packages  
**Researched:** 2026-05-31  
**Overall confidence:** HIGH

## Executive Summary

Accrue is already aligned with core Phoenix idioms in the places that matter most for library DX: context-first public API (`Accrue.Billing`), host-owned web/auth/runtime concerns, and package-mounted UI surfaces (`accrue_admin`, `accrue_portal`) implemented as router macros over `forward`/`live_session`. This reduces adopter surprise and keeps ownership lines explicit.

The architecture should now stabilize around a strict “public facade + host wiring contract” boundary, not feature-breadth expansion. In practical terms: keep adding capability only where the processor support matrix already promises first-party behavior; resist widening unsupported parity rows (especially Braintree subscription-item/preview semantics) that would dilute correctness and support honesty.

Data ownership is mostly well-shaped for Ecto: host owns Repo lifecycle and migration execution; Accrue owns generated migration content and schema constraints. The remaining release risk is not missing features but drift across docs/contracts/verifiers versus behavior. Accrue already has unusually strong verifier posture; the next milestone should consolidate this into explicit release-readiness gates and reduce optional-path ambiguity (LiveView optionality, portal/admin auth/session assumptions, Oban queue wiring).

For next-step recommendations: prioritize contract stabilization, stricter compatibility boundaries, and operability proofs over new domain scope. The highest leverage work is “less surprise at integration + fewer implicit assumptions,” not additional billing primitives.

## Key Findings

**Stack:** Keep Elixir 1.17 + Phoenix 1.8 + LiveView 1.1 + Ecto/ecto_sql 3.13+ + Oban 2.21+; this is idiomatic and current for the ecosystem.  
**Architecture:** Preserve host-owned runtime (Repo/Oban/auth/telemetry handlers) with Accrue as a context + plug/router/component library, not an owning app.  
**Critical pitfall:** Expanding unsupported cross-processor semantics faster than support-contract/verifier updates creates “looks supported” drift and support debt.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Contract Boundary Hardening** - make API and ownership lines explicit and machine-verified
   - Addresses: public API boundaries, migrations/schema ownership, router integration docs
   - Avoids: accidental surface expansion and host-integration surprises

2. **Release Gates Consolidation** - codify minimum release-readiness checks as one auditable gate set
   - Addresses: docs/tests/verifiers, Oban/telemetry/operator readiness
   - Avoids: drift between package docs, support matrix, and runtime behavior

3. **Mounted UI Integration Polish** - narrow, UX-centered hardening of admin/portal auth/session/tenant flow
   - Addresses: LiveView package split ergonomics, least-surprise mount behavior
   - Avoids: widening into net-new product scope

**Phase ordering rationale:**
- Boundary clarity first, because all downstream UX and gates depend on what is officially supported.
- Gates second, so every future change is automatically constrained by the codified contract.
- UX polish third, once invariants are locked and testable.

**Research flags for phases:**
- Phase 1: Likely needs deeper research on version-compat policy for optional deps (especially LiveView in core).
- Phase 2: Standard patterns, low research risk (mostly packaging/verification engineering).
- Phase 3: Moderate research risk around LiveView auth/session threat-model edge cases.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified against current HexDocs for Phoenix/Ecto/Plug/Oban/Telemetry. |
| Features | HIGH | Repo-local matrix + guides are explicit and current. |
| Architecture | HIGH | Code and docs agree on host-owned runtime and mounted package boundaries. |
| Pitfalls | MEDIUM | Pitfall ranking is evidence-backed but forward-looking (depends on future scope choices). |

## Gaps to Address

- Clarify and enforce an explicit compatibility matrix for optional dependencies in core (`phoenix_live_view`, `opentelemetry`, `telemetry_metrics`), including tested version ranges.
- Decide whether `accrue_portal` should stay thin-README by design or adopt a fuller package guide parity with `accrue_admin`.
- Add a single “release gate rubric” doc mapping each verifier script to a risk class (contract drift, security posture, runtime boot safety, UI parity).
