# Phase 216: Additive rail and persistence foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-02
**Phase:** 216-additive-rail-and-persistence-foundation
**Areas discussed:** Rail registration and legacy aliasing, rail-qualified product catalog, durable record identity and uniqueness, observation evidence retention, account-scoped device identity
**Mode:** Project defaults auto-selected all gray areas and auto-resolved additive/reversible choices after research. The user explicitly confirmed the two security/product-sensitive choices in text mode.

---

## Rail Registration and Legacy Aliasing

| Option | Description | Selected |
|--------|-------------|----------|
| Additive rails registry with `processor` alias | Add `rails`/`default_rail`; preserve `processor` as the default controllable gateway alias and legacy behavior when new config is absent. | ✓ |
| Turn `processor` into a map | Reuse the existing key for multiple rails, changing its type and breaking existing host configuration. | |
| Replace processor with rails | Deprecate the existing processor contract and require migration even for single-processor hosts. | |

**User's choice:** Auto-resolved to the additive registry under the standing project configuration.
**Notes:** Phase-215 authority and current public contracts reject turning Apple into a processor or changing the type of `processor`.

---

## Rail-Qualified Product Catalog

| Option | Description | Selected |
|--------|-------------|----------|
| Nested products per logical plan | Keep logical plans outermost; qualify provider IDs by rail and environment, with `price_ids` as default shorthand. | ✓ |
| Globally bare identifiers | Continue treating raw provider IDs as globally unique. | |
| Separate provider catalogs | Configure unrelated Stripe and Apple plan catalogs and reconcile them elsewhere. | |

**User's choice:** Auto-resolved to nested qualified products under the standing project configuration.
**Notes:** The chosen model preserves existing plan-first DX and permits identical raw IDs across rails/environments without collisions.

---

## Durable Record Identity and Uniqueness

| Option | Description | Selected |
|--------|-------------|----------|
| Database-enforced scoped identity | UUID records plus scoped constraints and partial unique indexes, mirrored by changeset validation. | ✓ |
| Application-only validation | Detect duplicates before writes without database uniqueness authority. | |
| Append-only grants without current uniqueness | Preserve every row but leave the current logical grant ambiguous. | |

**User's choice:** Auto-resolved to database-enforced identity under the standing project configuration.
**Notes:** This follows existing Ecto/PostgreSQL patterns and preserves historical observations separately from one current logical grant.

---

## Observation Evidence Retention

| Option | Description | Selected |
|--------|-------------|----------|
| Opaque reference | Store normalized/redacted fields and digest; allow a nullable encrypted payload reference with explicit expiry, never raw evidence in the observation row. | ✓ |
| Encrypted in-row | Retain replayable provider evidence directly in the database with a fixed window. | |
| No replay material | Store only normalized fields/digest and require provider refetch or resubmission for every repair. | |

**User's choice:** Option 1 — Opaque reference.
**Notes:** This minimizes the queryable sensitive-data surface while preserving an explicit later seam for Apple replay when required.

---

## Account-Scoped Device Identity

| Option | Description | Selected |
|--------|-------------|----------|
| Account-scoped registration | Scope installation/key uniqueness to the account; proofs bind both account and recomputed key thumbprint. | ✓ |
| Global key ownership | Permit one key to belong to only one account; switching requires generating a new key. | |
| Single-account installation | Globally tie both installation and key to one account until release. | |

**User's choice:** Option 1 — Account-scoped registration.
**Notes:** Authenticated account switching is allowed without weakening account-and-key proof binding; revocation/history remains durable.

---

## the agent's Discretion

- Exact internal module/schema/constraint names.
- Internal validated representation of rail registrations and qualified products, while preserving the locked public semantics.
- Exact opaque evidence-store behaviour name and storage adapter seam.

## Deferred Ideas

None. Projection/cutover, Apple runtime, offline proof runtime, and adopter operations remain in their assigned later phases.
