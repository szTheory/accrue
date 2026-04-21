# Pitfalls Research

**Domain:** Adding non-Sigra org billing recipes to Accrue documentation + host proofs
**Researched:** 2026-04-21
**Confidence:** HIGH (billing tenancy is a known high-risk area)

## Cross-tenant leakage

| Pitfall | Prevention |
|---------|------------|
| Admin LiveView defaulting to “first org” or global queries | Recipes must show explicit scope from `current_user` / membership; align with **ORG-03** language from v1.3. |
| Webhook replay using wrong actor or billable | Document that replay/admin tooling must use same auth adapter contract as online requests. |
| `assoc` / preload without org filter | Call out `Repo.get` vs scoped queries; recommend host facade functions that **always** take billable or org id. |

## Doc / proof drift

| Pitfall | Prevention |
|---------|------------|
| Matrix claims “covered” without a runner | Any new archetype row needs owning script or test path named in `scripts/ci/README.md` pattern from v1.7. |
| Duplicated contradictory Sigra vs non-Sigra steps | Single spine doc + “if Sigra → … else → …” table reduces forked narratives. |

## False expectations

| Pitfall | Prevention |
|---------|------------|
| Readers assume Accrue ships Pow/phx.gen.auth | State clearly: **host-owned** adapters; Accrue ships behaviour contract + Sigra optional integration. |
| Org billing == multi-party Stripe Connect | Out of scope; recipes focus on **which Ecto row** is the Stripe customer owner, not Connect marketplace patterns. |

## Phase placement

- **Pitfalls content** belongs in Phase **37** (foundation doc) and **38** (Pow/custom edge cases); Phase **39** encodes proof so regressions surface in CI/docs checks.
