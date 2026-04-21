# Architecture Research

**Domain:** ORG-04 integration with existing Accrue architecture
**Researched:** 2026-04-21
**Confidence:** HIGH

## Existing architecture (do not redesign)

| Layer | Responsibility |
|-------|----------------|
| **Host app** | Chooses billable schema(s) (`User`, `Organization`, …), implements org resolution from session, wires `MyApp.Billing` facade. |
| **`Accrue.Billable`** | Host schema concern — `owner_type` / `owner_id` on `Accrue.Billing.Customer` (and related) stays the polymorphic join. |
| **`Accrue.Auth` behaviour** | Admin + actor id for audit; Sigra adapter is one implementation; phx.gen.auth / Pow adapters are **host-owned** modules implementing the same contract. |
| **`accrue_admin`** | Queries scoped by configured auth adapter + host conventions; org isolation is **host + adapter** obligation. |

## Integration flow (conceptual)

1. Request arrives (LiveView / controller).
2. Host identifies **actor** (user) and optional **active organization** (membership, role).
3. Host resolves **billable** Ecto struct the subscription is attached to (user-as-customer vs org-as-customer).
4. Host calls `MyApp.Billing.*` (public facade) with that struct; Accrue persists Stripe customer linkage on `Accrue.Billing.Customer` for that billable.
5. Admin and webhooks use same ownership columns — recipes must show where accidental cross-tenant reads creep in (preload scope, default_scopes).

## Suggested build order (for roadmap phases)

1. **Doc spine + phx.gen.auth** — lowest ambiguity, largest adopter overlap with Phoenix defaults.
2. **Pow + custom org** — higher variance; document boundaries and “bring your own” scope helpers.
3. **Proof/matrix** — encode archetype so CI/docs drift is caught.

## New vs modified components

| New / modified | What |
|----------------|------|
| **Guides + host README cross-links** | Primary delivery vehicle. |
| **Optional** verifier / matrix scripts | If new anchors are promised merge-blocking. |
| **No** new Accrue core tables for ORG-04 | Unless a gap is discovered during implementation — treat as scope change, not default. |
