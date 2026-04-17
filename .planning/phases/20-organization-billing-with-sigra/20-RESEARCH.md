# Phase 20: Organization Billing With Sigra - Research

**Researched:** 2026-04-17
**Revised:** 2026-04-17
**Domain:** Organization-owned billing with Sigra-backed host scope on top of Accrue's polymorphic billable contract
**Confidence:** HIGH

<user_constraints>
## User Constraints

No `*-CONTEXT.md` exists for Phase 20, so roadmap, requirements, state, and the approved UI-SPEC are the authoritative planning inputs. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/accrue/.planning/REQUIREMENTS.md] [VERIFIED: /Users/jon/projects/accrue/.planning/STATE.md] [VERIFIED: /Users/jon/projects/accrue/.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md]

### Locked Decisions

- Goal: "A Sigra-backed Phoenix host can bill the active organization, while Accrue's generic billable model remains the public ownership contract for non-Sigra hosts." [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]
- Requirements: `ORG-01`, `ORG-02`, `ORG-03`. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/accrue/.planning/REQUIREMENTS.md]
- Public, admin, webhook replay, and finance boundaries must stay on row-scoped `owner_type` / `owner_id` instead of trusting client-selected organization IDs. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]
- Sigra-first means the canonical host proof must use Sigra organization scope, memberships, active-organization session hydration, and admin boundaries. [VERIFIED: /Users/jon/projects/accrue/.planning/STATE.md]
- Locked denial copy comes from `20-UI-SPEC.md`, including the exact cross-org denial flash and ambiguous webhook replay block copy. [VERIFIED: /Users/jon/projects/accrue/.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md]

### Claude's Discretion

- How to split Phase 20 across host foundation, host scope, admin scope, query gating, admin presentation, and replay proof.
- Whether `accrue_admin` uses a thin internal owner-scope adapter around Sigra admin semantics or direct Sigra structs, as long as the routing and denial behavior matches the verified contracts.

### Deferred Ideas (OUT OF SCOPE)

- `ORG-04`: broader non-Sigra tenancy recipes after the Sigra-first proof. [VERIFIED: /Users/jon/projects/accrue/.planning/REQUIREMENTS.md]
- Finance products or app-owned exports. [VERIFIED: /Users/jon/projects/accrue/.planning/REQUIREMENTS.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ORG-01 | Host app can make an organization billable using Accrue's existing `Accrue.Billable` ownership model. | `Accrue.Billable` only requires a billable schema and `Accrue.Billing.customer/1` persists `owner_type` and `owner_id`, so organizations fit the existing contract without changing Accrue billing tables. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billable.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing.ex] |
| ORG-02 | Sigra-backed host flow can bill the active organization while preserving membership and admin scope boundaries. | The local Sigra source is available at `/Users/jon/projects/sigra`. Its concrete contracts include `Sigra.Organizations`, `Sigra.Scope.Hydration.hydrate/3`, `Sigra.Plug.PutActiveOrganization.call/3`, `Sigra.Plug.LoadActiveOrganization`, `Sigra.Plug.RequireMembership`, `Sigra.LiveView.OrganizationScope`, and host scope fields `user`, `active_organization`, `membership`, `impersonating_from`. [VERIFIED: /Users/jon/projects/sigra/lib/sigra/organizations.ex] [VERIFIED: /Users/jon/projects/sigra/lib/sigra/scope/hydration.ex] [VERIFIED: /Users/jon/projects/sigra/lib/sigra/plug/put_active_organization.ex] |
| ORG-03 | Org admins cannot access or mutate another organization's billing state through public, admin, webhook replay, or export paths. | `accrue_admin` is global today, but Sigra's admin scope primitives and Accrue's customer ownership rows give the right enforcement seam. Webhook rows do not carry owner columns, so replay must prove ownership through linked local billing rows or deny as ambiguous. [VERIFIED: /Users/jon/projects/sigra/lib/sigra/admin/scope.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/webhooks.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs] |
</phase_requirements>

## Summary

Sigra is now a resolved dependency target. It is local source code at `/Users/jon/projects/sigra`, not a Hex package yet, so the example host should depend on it by path when not in Hex-release mode. The Phase 20 host should therefore target the real API and wrapper pattern from the Sigra example app directly. [VERIFIED: /Users/jon/projects/sigra/test/example/lib/example/organizations.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/mix.exs]

The concrete host wrapper shape is:

```elixir
use Sigra.Organizations,
  repo: AccrueHost.Repo,
  schemas: [
    organization: AccrueHost.Accounts.Organization,
    membership: AccrueHost.Accounts.OrganizationMembership,
    invitation: AccrueHost.Accounts.OrganizationInvitation,
    user_session: AccrueHost.Accounts.UserSession,
    organization_slug_alias: AccrueHost.Accounts.OrganizationSlugAlias,
    user: AccrueHost.Accounts.User,
    scope: AccrueHost.Accounts.Scope
  ]
```

This means Phase 20 should add `AccrueHost.Organizations` directly, not an invented host abstraction. [VERIFIED: /Users/jon/projects/sigra/test/example/lib/example/organizations.ex]

The host scope contract is also resolved. Required fields are `user`, `active_organization`, `membership`, and `impersonating_from`, and the scope module must implement `put_active_organization(scope, organization, membership)`. `Sigra.Scope.Hydration.hydrate/3` hydrates `scope.active_organization` and `scope.membership` from `session.active_organization_id`, returning `{:ok, scope}` or `{:error, :not_a_member | :org_not_found}`. That lets Phase 20 use the actual Sigra hydration path in `AccrueHostWeb.UserAuth`. [VERIFIED: /Users/jon/projects/sigra/test/example/lib/example/accounts/scope.ex] [VERIFIED: /Users/jon/projects/sigra/lib/sigra/scope/hydration.ex]

The authoritative active-organization write path is also concrete: `Sigra.Plug.PutActiveOrganization.call(conn, org, organizations: ..., session_store: Sigra.SessionStores.Ecto, session_store_opts: [repo: AccrueHost.Repo, session_schema: AccrueHost.Accounts.UserSession], scope_module: AccrueHost.Accounts.Scope)`. It verifies membership before writing session state. `Sigra.Plug.LoadActiveOrganization` reads `conn.assigns[:current_scope]` and `conn.private[:sigra_session]`, hydrates scope without halting, and stale pointers fail closed. `Sigra.Plug.RequireMembership` halts unless an active organization exists and the membership role is allowed. For billing mutations, owner/admin should be the allowed roles; `:member` is read-only. [VERIFIED: /Users/jon/projects/sigra/lib/sigra/plug/put_active_organization.ex] [VERIFIED: /Users/jon/projects/sigra/lib/sigra/plug/load_active_organization.ex] [VERIFIED: /Users/jon/projects/sigra/lib/sigra/plug/require_membership.ex]

Sigra's LiveView and admin route contracts are concrete too. `Sigra.LiveView.OrganizationScope` gives organization-scoped LiveView parity, while `Sigra.LiveView.AdminScope` and `Sigra.Admin.Scope.resolve/3` distinguish global versus organization admin routes and return `:not_found` for out-of-scope organization routes. Phase 20 does not need to guess the denial behavior at the router level anymore; it needs to adapt `accrue_admin` so package surfaces comply with the approved UI redirect+flash contract even if lower-level Sigra route denial semantics are 404-like. [VERIFIED: /Users/jon/projects/sigra/lib/sigra/live_view/organization_scope.ex] [VERIFIED: /Users/jon/projects/sigra/lib/sigra/live_view/admin_scope.ex] [VERIFIED: /Users/jon/projects/sigra/lib/sigra/admin/scope.ex]

The organization schema requirements are concrete: Sigra-generated organizations include `name`, `slug`, `deleted_at`, `personal`, and `owner_user_id`, and membership roles are `[:owner, :admin, :member]`. Phase 20 should add `use Accrue.Billable, billable_type: "Organization"` on the host organization schema so the org remains compatible with Accrue's generic owner contract. [VERIFIED: /Users/jon/projects/sigra/test/example/lib/example/accounts/organization.ex] [VERIFIED: /Users/jon/projects/sigra/test/example/lib/example/accounts/organization_membership.ex]

Canonical denial behavior is also resolved. Host billing mutation without an active org or without owner/admin membership must render the locked UI-SPEC copy and perform no mutation. Admin cross-org detail URLs must redirect to the scoped index with the exact flash `You don't have access to billing for this organization.` and render no row metadata. Sigra's route-level org denial may be 404/not_found semantics, but `accrue_admin` package surfaces in Phase 20 must honor the redirect+flash UI contract. Ambiguous webhook replay must render `Ownership couldn't be verified for this webhook. Replay is unavailable until the linked billing owner is resolved.` and disable replay. [VERIFIED: /Users/jon/projects/accrue/.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Organization billable ownership (`owner_type` / `owner_id`) | API / Backend | Database / Storage | The owner contract is created in `Accrue.Billing.customer/1` and persisted in `accrue_customers`; clients never write those columns directly. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing.ex] |
| Active organization selection and hydration | Frontend Server (SSR) | API / Backend | `current_scope` and session hydration live in host auth and Sigra plugs/on_mount paths. [VERIFIED: /Users/jon/projects/sigra/lib/sigra/scope/hydration.ex] [VERIFIED: /Users/jon/projects/sigra/test/example/lib/example_web/user_auth.ex] |
| Public org billing facade | API / Backend | Frontend Server (SSR) | The host billing wrapper remains the mutation boundary; LiveViews should call the facade, not query Accrue tables directly. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex] |
| Admin owner scope resolution | Frontend Server (SSR) | API / Backend | `accrue_admin` mounts and loaders are the package seam for scoping detail and replay routes. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex] |
| Webhook replay authorization | API / Backend | Frontend Server (SSR) | Replay requires server-side proof from local billing rows or event causality because webhook rows are not owner-scoped. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/webhooks.ex] |

## Standard Stack

| Library | Version/Source | Purpose | Why Standard |
|---------|----------------|---------|--------------|
| `Accrue.Billable` | repo-local | Public ownership contract for any host billable schema | ORG-01 is already shaped around this contract; changing it would violate milestone decisions. |
| `Accrue.Billing` | repo-local | Canonical customer and subscription ownership path | Preserves `owner_type` and `owner_id` today. |
| `Sigra` | local source at `/Users/jon/projects/sigra` | Organization CRUD, membership, active-org session hydration, admin scope | Phase 20 now has a verified concrete API target. |
| `examples/accrue_host` | repo-local | Canonical host proof surface | Roadmap and prior summaries already treat it as the canonical host proof. |
| `accrue_admin` | repo-local | Admin LiveView and query package | ORG-03 requires package-level scoping and replay denial. |

## Installation

```bash
cd examples/accrue_host
mix deps.get
# In local development, Sigra should resolve from:
# {:sigra, path: "../../../sigra"}
```

For Hex release mode, keep explicit branching in `examples/accrue_host/mix.exs` so local verification and future packaged release behavior remain distinct and testable. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/mix.exs]

## Architecture Patterns

### Pattern 1: Reuse the Existing Billable Contract for Organizations

Make the host organization schema `use Accrue.Billable, billable_type: "Organization"` and pass the organization struct directly into `Accrue.Billing.customer/1`. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billable.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing.ex]

### Pattern 2: Hydrate Scope With Sigra, Then Resolve Billing From `current_scope`

Use `Sigra.Scope.Hydration.hydrate/3` in host auth or the Sigra load-active-org plug to populate `current_scope.active_organization` and `current_scope.membership`. Host billing mutations must then resolve the organization from `current_scope`, not from params. [VERIFIED: /Users/jon/projects/sigra/lib/sigra/scope/hydration.ex] [VERIFIED: /Users/jon/projects/sigra/test/example/lib/example_web/user_auth.ex]

### Pattern 3: Use Sigra Role Semantics For Billing Mutation Denial

Use roles `[:owner, :admin]` for billing mutations and treat `:member` as read-only. `Sigra.Plug.RequireMembership` already encodes the role check semantics, and host/admin code should mirror that policy. [VERIFIED: /Users/jon/projects/sigra/lib/sigra/plug/require_membership.ex]

### Pattern 4: Prove Admin Ownership Through Customer Rows And Webhook/Event Causality

Customer, subscription, and invoice loaders should join back to `Customer.owner_type` / `owner_id`. Webhook loaders should resolve ownership from linked local billing rows or event causality, and return ambiguity when proof is insufficient. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/subscriptions.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/invoices.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/webhooks.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sigra host seam | Generic compatibility wrapper | Real `AccrueHost.Organizations` using `Sigra.Organizations` | The local Sigra source is available and verified. |
| Active organization writes | Direct session or DB writes | `Sigra.Plug.PutActiveOrganization.call/3` | It verifies membership before writing the session row. |
| Billing org choice | Client-submitted `organization_id` | Sigra-hydrated `current_scope.active_organization` | This is the locked tenant boundary. |
| Admin route authorization | LiveView-only filtering | owner-aware query loaders plus redirect/flash denial | Loader-first enforcement prevents row leakage. |

## Database / Schema Implications

- `accrue_customers` already stores `owner_type` and `owner_id` and does not need a core migration for organizations. [VERIFIED: /Users/jon/projects/accrue/accrue/priv/repo/migrations/20260412100001_create_accrue_customers.exs]
- The example host does need organization and membership tables because they do not exist today. The schema should follow Sigra's required organization and membership fields. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/priv/repo/migrations/20260416163132_create_users_auth_tables.exs] [VERIFIED: /Users/jon/projects/sigra/test/example/lib/example/accounts/organization.ex]
- `accrue_webhook_events` remains owner-agnostic, so replay authorization must stay derived rather than denormalized in Phase 20. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs]

## Common Pitfalls

### Pitfall 1: Treating Sigra As Unresolved

The local source is present. Planning or implementation that avoids the concrete Sigra API does not satisfy the phase goal. [VERIFIED: /Users/jon/projects/sigra]

### Pitfall 2: Trusting Client-Selected Organization IDs

Any `organization_id` coming from params, hidden inputs, or event payloads creates an IDOR path and violates Phase 20 success criteria. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]

### Pitfall 3: Letting Admin Detail Or Replay Views Load Global Rows First

If the loader returns a global row and the LiveView decides afterward, cross-org row metadata is already exposed to server rendering and audit paths. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/webhooks.ex]

### Pitfall 4: Assuming Webhook Rows Themselves Prove Ownership

`WebhookEvent` rows do not carry `owner_type` / `owner_id`, so replay authorization must derive from linked billing rows or deny as ambiguous. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `examples/accrue_host` can depend on local Sigra by path during Phase 20 execution, with explicit Hex-release branching retained for packaged verification. | Summary; Installation | Low - the local source path and current mix structure are already verified. |
| A2 | `accrue_admin` can adopt a thin owner-scope helper around Sigra admin semantics without changing Accrue's public billable contract. | Summary; Architectural Responsibility Map | Medium - if false, a broader admin package contract change would be needed, but the public owner contract still stands. |
| A3 | The example host should create Sigra-shaped organization and membership tables locally because those tables do not exist yet. | Database / Schema Implications | Low - the repo currently lacks them and Sigra's required schema fields are verified. |
| A4 | Webhook ambiguity can be represented in loaders and surfaced in UI without adding owner columns to webhook rows. | Summary; Architecture Patterns | Medium - if proof links are insufficient in code, the phase may need a follow-up denormalization phase, but Phase 20 still must fail closed. |

## Open Questions (RESOLVED)

1. **What exact Sigra source and API surface should Phase 20 target?**
   - Answer: the local source at `/Users/jon/projects/sigra`, using `Sigra.Organizations`, `Sigra.Scope.Hydration`, `Sigra.Plug.PutActiveOrganization`, `Sigra.Plug.LoadActiveOrganization`, `Sigra.Plug.RequireMembership`, `Sigra.LiveView.OrganizationScope`, `Sigra.LiveView.AdminScope`, and `Sigra.Admin.Scope`. The example host should depend on Sigra by path when not in Hex release mode. [VERIFIED: /Users/jon/projects/sigra/lib/sigra/organizations.ex] [VERIFIED: /Users/jon/projects/sigra/lib/sigra/scope/hydration.ex]

2. **What Phase 20 admin scope contract should the plan assume?**
   - Answer: use Sigra-style global versus organization admin semantics. `Sigra.Admin.Scope.resolve/3` decides whether the route is global or organization-scoped and returns `:not_found` for out-of-scope organization routes. `accrue_admin` should adapt that into owner-aware loaders and the approved redirect+flash UI contract. [VERIFIED: /Users/jon/projects/sigra/lib/sigra/admin/scope.ex] [VERIFIED: /Users/jon/projects/accrue/.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md]

3. **What is the canonical denial behavior for host billing and webhook replay?**
   - Answer: host billing mutation without an active org or without owner/admin membership renders the locked UI-SPEC copy and performs no mutation. Cross-org admin detail URLs redirect to scoped index with `You don't have access to billing for this organization.` and render no row metadata. Ambiguous webhook replay shows `Ownership couldn't be verified for this webhook. Replay is unavailable until the linked billing owner is resolved.` and disables replay. [VERIFIED: /Users/jon/projects/accrue/.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md]
