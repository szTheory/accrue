# Phase 156: Entitlements Gating Adopter Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 156-Entitlements Gating Adopter Proof
**Areas discussed:** NotLoaded guard placement, Fail-closed user path, Proof shape, Router comment contract

---

## NotLoaded guard placement

| Option | Description | Selected |
|--------|-------------|----------|
| Host-only guard | Handle unloaded association defensively only in the `examples/accrue_host` billable resolver. | |
| Core-only guard | Normalize unloaded association in core `Accrue.Entitlements.Guard` / LiveView guard path. | |
| Both | Normalize in core and keep the example resolver/comment explicit for adopters. | x |

**User's choice:** Approved the synthesized recommendation after requesting subagent-backed research across all options.
**Notes:** Advisor research favored "both" because core safe defaults protect all adopters, while example-level guidance keeps the copy/paste path understandable. Primary decision logic should live in `Accrue.Entitlements.Guard`, not in `Accrue.Live.Entitlements`.

---

## Fail-closed user path

| Option | Description | Selected |
|--------|-------------|----------|
| Generic denial only | Keep current fail-closed entitlement denial for missing/unloaded billable state. | |
| Distinct org-selection UX | Add a pre-entitlement host hook/message for missing active organization. | |
| Hybrid | Keep generic core denial and document/demonstrate ordering plus `NotLoaded` fail-closed behavior. | x |

**User's choice:** Approved the synthesized recommendation.
**Notes:** The chosen path preserves Phase 156 scope. A distinct "select organization first" UX may be useful later, but it is a new host UX behavior and not required by PRF-01.

---

## Proof shape

| Option | Description | Selected |
|--------|-------------|----------|
| Existing tests only | Keep only the current positive/negative host route tests. | |
| Host `NotLoaded` regression | Add one explicit host-level `NotLoaded` regression while preserving existing tests. | x |
| Host plus core regression | Add both host-level and core unit coverage for `NotLoaded`. | |

**User's choice:** Approved the synthesized recommendation.
**Notes:** The host route is the adopter-facing proof. Add supplemental core coverage only if needed to keep implementation simple and localized.

---

## Router comment contract

| Option | Description | Selected |
|--------|-------------|----------|
| Terse inline note | Keep router comment minimal and rely on docs for details. | |
| Full inline recipe | Put the full auth/scope/entitlement recipe in the router comment. | |
| Hybrid | Put a concise contract inline and keep the full recipe in canonical docs. | x |

**User's choice:** Approved the synthesized recommendation.
**Notes:** Router should state auth/scope hook first, entitlement hook second, deny target outside the gated session, and fail-closed behavior for missing/unloaded billable state. Longer variants belong in `accrue/guides/entitlements.md` or the adoption matrix.

---

## the agent's Discretion

- The user explicitly asked for subagent-backed research and a one-shot cohesive recommendation rather than selecting each option manually.
- The agent synthesized advisor results into one locked recommendation set.

## Deferred Ideas

- Distinct "select/load organization first" UX before entitlement denial.
- Broader multi-tenant organization-scope guidance beyond the focused entitlement guard ordering recipe.
