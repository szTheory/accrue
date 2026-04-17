# Phase 20: Organization Billing With Sigra - Research

**Researched:** 2026-04-17
**Domain:** Organization-owned billing with Sigra-backed host scope on top of Accrue's polymorphic billable contract
**Confidence:** MEDIUM

<user_constraints>
## User Constraints

No `*-CONTEXT.md` exists for Phase 20, so roadmap, requirements, and state are the authoritative planning inputs for this phase. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/accrue/.planning/REQUIREMENTS.md] [VERIFIED: /Users/jon/projects/accrue/.planning/STATE.md]

### Locked Decisions

- Goal: "A Sigra-backed Phoenix host can bill the active organization, while Accrue's generic billable model remains the public ownership contract for non-Sigra hosts." [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]
- Depends on Phase 19. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]
- Requirements: `ORG-01`, `ORG-02`, `ORG-03`. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/accrue/.planning/REQUIREMENTS.md]
- Success criteria require preserving `owner_type` and `owner_id`, using Sigra organization scope/membership/active-organization context, denying cross-org access server-side, and keeping public billing, admin UI, webhook replay, and finance boundaries on the row-scoped owner contract instead of client-selected org IDs. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]
- Recent project decisions say Accrue keeps generic host-owned billables as the public model, Sigra-first means the canonical host proof should use Sigra org scope and membership boundaries, and `cross-tenant billing leakage` remains an explicit milestone risk. [VERIFIED: /Users/jon/projects/accrue/.planning/STATE.md]

### Claude's Discretion

- How to add organization and membership primitives to `examples/accrue_host`, which currently has only user scope. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts/scope.ex] [VERIFIED: codebase grep]
- Whether admin scoping lands as an additive `accrue_admin` seam, host-only query wrappers, or both; the current package has admin auth/session seams but no organization-scope contract. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/auth_hook.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/auth.ex]
- Whether the example host proves org billing inside the existing `/app/billing` LiveView or through a new org-specific host surface. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/router.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex]

### Deferred Ideas (OUT OF SCOPE)

- `ORG-04`: broader non-Sigra tenancy recipes after the Sigra-first proof. [VERIFIED: /Users/jon/projects/accrue/.planning/REQUIREMENTS.md]
- Finance products, accounting semantics, and broad app-owned exports remain out of scope for Phase 20. [VERIFIED: /Users/jon/projects/accrue/.planning/REQUIREMENTS.md] [VERIFIED: /Users/jon/projects/accrue/.planning/STATE.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ORG-01 | Host app can make an organization billable using Accrue's existing `Accrue.Billable` ownership model. | `Accrue.Billable` only requires an Ecto schema with an `id`, and `Accrue.Billing.customer/1` resolves ownership from `mod.__accrue__(:billable_type)` plus `to_string(id)`, so organization billing fits the existing owner contract without a core schema redesign. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billable.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/test/accrue/billable_test.exs] |
| ORG-02 | Sigra-backed host flow can bill the active organization while preserving membership and admin scope boundaries. | The example host currently has only `current_scope.user`, user-only billing facade calls, and no organization or membership schema, so the proof must add host-side org primitives and derive the billable from active scope server-side instead of from params. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts/scope.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex] [VERIFIED: codebase grep] |
| ORG-03 | Org admins cannot access or mutate another organization's billing state through public, admin, webhook replay, or export paths. | Current admin queries and detail pages load rows globally by billing IDs or webhook IDs, and webhook replay acts on raw webhook rows with no owner filter, so Phase 20 needs owner-aware query guards and denial tests around those surfaces. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/customers.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/subscriptions.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/invoices.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/webhooks.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs] |
</phase_requirements>

## Summary

Accrue's core ownership model is already shaped correctly for organization billing. `Accrue.Billable` is polymorphic, `Accrue.Billing.customer/1` persists `owner_type` and `owner_id` as strings, and `accrue_customers` already has the composite uniqueness and row shape needed to represent users, organizations, or teams without new Accrue billing tables. `build_processor_params/1` also only opportunistically copies `name` and `email`, so an organization schema can be billable even if it only contributes an `id`; name/email enrichment is optional rather than structural. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billable.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing/customer.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/priv/repo/migrations/20260412100001_create_accrue_customers.exs]

The planning risk is almost entirely in the host and admin layers. The canonical host example is still user-only: `Scope` carries only `user`, `/app/billing` operates on `current_scope.user`, the generated `AccrueHost.Billing` facade assumes a single `billable`, and all current proof tests assert `"User"` ownership. The admin package is also global today: its router threads auth/session data, but its query modules and detail pages fetch customers, subscriptions, invoices, events, and webhooks without any organization scope contract. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts/scope.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/test/accrue_host/billing_facade_test.exs] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/customers.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/webhooks.ex]

The critical unknown is Sigra itself. This repo ships only a thin, user-centric `Accrue.Integrations.Sigra` auth adapter scaffold; it does not contain organization or membership integrations, `:sigra` is not declared in local deps or lockfiles, and the official Hex package/doc URLs checked in this session returned `404` on 2026-04-17. That makes the canonical Sigra proof dependent on a host-supplied Sigra source or on user confirmation of the exact Sigra API surface before planning can lock execution details. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/integrations/sigra.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/mix.exs] [VERIFIED: codebase grep] [CITED: https://hex.pm/api/packages/sigra] [CITED: https://hexdocs.pm/sigra/]

**Primary recommendation:** keep `Accrue.Billable` and `Accrue.Billing.customer/1` unchanged, add organization/membership/active-organization primitives in the example host, derive the billable organization exclusively from active Sigra scope on the server, and add an additive owner-scope seam to admin/webhook query paths so every org-sensitive surface proves ownership through joined local rows rather than through client-provided organization IDs. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billable.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/customers.ex] [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Organization billable ownership (`owner_type` / `owner_id`) | API / Backend | Database / Storage | The owner contract is created in `Accrue.Billing.customer/1` / `create_customer/1` and persisted in `accrue_customers`; clients never write those columns directly. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing/customer.ex] |
| Active organization selection and membership checks | Frontend Server (SSR) | API / Backend | The host session and LiveView mount own `current_scope`; today that scope is user-only, so Sigra-backed active-org resolution belongs in host auth/scope code before billing calls are made. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/user_auth.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts/scope.ex] [ASSUMED] |
| Public org billing facade (`subscribe`, `customer_for`, tax location, future org actions) | API / Backend | Frontend Server (SSR) | The generated host facade is the established policy hook layer; UI code should call that layer and never query Accrue tables directly. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/test/accrue_host/billing_facade_test.exs] |
| Admin list/detail scoping for customers, subscriptions, invoices, and events | Frontend Server (SSR) | API / Backend | `accrue_admin` LiveViews and query modules own the admin data fetch path today, so org filters have to be enforced in those server-rendered queries or in a new query-scope hook they call. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/customers.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex] [ASSUMED] |
| Webhook replay / event feed access control | API / Backend | Frontend Server (SSR) | Replay and event feed actions run server-side against `WebhookEvent`, `Event`, and `DLQ` primitives; there is no client-safe shortcut because webhook rows themselves do not store owner fields. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhooks_live.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/webhooks.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs] |
| Future finance handoff authorization boundary | API / Backend | Database / Storage | No finance export surface exists in the codebase yet, but the roadmap already says future finance handoff must honor the same row-scoped owner contract. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [VERIFIED: codebase grep] |

## Project Constraints (from CLAUDE.md)

- Keep the implementation on Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, and PostgreSQL 14+ conventions. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- Keep `lattice_stripe` as the Stripe boundary and do not bypass the current processor abstraction. Phase 20 should not introduce organization-specific processor codepaths. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- Webhook signature verification remains mandatory and replay should continue through the existing shared ingest/DLQ path. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- Sensitive Stripe data and PII must not be logged; organization-boundary proofs must use local projections and safe metadata, not copied raw payloads. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- All public entry points should stay on the existing telemetry/OTel surfaces. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- The repo is a monorepo with `accrue/` and `accrue_admin/` plus a canonical Phoenix host example under `examples/`; Phase 20 should respect that ownership split. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md] [VERIFIED: codebase grep]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Accrue.Billable` | repo-local | Public ownership contract for any host billable schema. [VERIFIED: codebase grep] | The macro already injects `__accrue__(:billable_type)` and a scoped `has_one :accrue_customer`; Phase 20 should extend this to organizations instead of creating parallel org-specific billing tables. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billable.ex] |
| `Accrue.Billing` | repo-local | Canonical fetch/create path for local customers and downstream billing records. [VERIFIED: codebase grep] | `customer/1` and `create_customer/1` already preserve `owner_type` and `owner_id`; that is the narrow contract ORG-01 is asking to prove. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing.ex] |
| `examples/accrue_host` | repo-local Phoenix 1.8 / LiveView `~> 1.1.0` host proof app. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/mix.exs] | The roadmap and Phase 19 summaries make the example host the canonical proof surface for host-owned facades, billing UI, and cross-surface verification. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/accrue/.planning/phases/19-tax-location-and-rollout-safety/19-04-SUMMARY.md] |
| `accrue_admin` | repo-local | Admin LiveView UI and query layer. [VERIFIED: codebase grep] | Admin scoping gaps are in package code today, so the org-boundary proof has to account for this package directly. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/customers.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Accrue.Auth` + `AccrueAdmin.Router` session/on-mount seams | repo-local | Existing host-auth and admin-session extension points. [VERIFIED: codebase grep] | Use these for additive admin scoping context before changing the public billing contract. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/auth.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex] |
| `Sigra` | unresolved host dependency; no local dep and no Hex package/doc resolved on 2026-04-17. [VERIFIED: codebase grep] [CITED: https://hex.pm/api/packages/sigra] [CITED: https://hexdocs.pm/sigra/] | Intended source of organization scope, memberships, and active-organization context for the canonical proof. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [ASSUMED] |
| `Accrue.Events` + `WebhookEvent` / `DLQ` | repo-local | Server-side audit trail and replay path. [VERIFIED: codebase grep] | Use for cross-org denial tests around webhook replay and event feed access. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/events_live.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing polymorphic `owner_type` / `owner_id` contract | New org-specific billing tables | New tables would duplicate the current owner contract and break the stated roadmap decision to keep generic billables as the public model. [VERIFIED: /Users/jon/projects/accrue/.planning/STATE.md] [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing/customer.ex] |
| Server-derived active organization | Client-submitted `organization_id` in params | Client-selected org IDs create an IDOR/cross-tenant leakage path and directly contradict the phase success criteria. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] |
| Additive admin query scope seam | Leaving admin global until Phase 21 | Phase 20 success criteria already include admin UI and replay boundaries, so deferring all admin scoping would leave ORG-03 unproven. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] |

**Installation:**
```bash
cd accrue && mix deps.get
cd accrue_admin && mix deps.get
cd examples/accrue_host && mix deps.get
# Add a host-supplied Sigra source only after its package/repo location is confirmed.
```

**Version verification:** `examples/accrue_host` currently pins `:phoenix_live_view` to `~> 1.1.0`; `accrue` and `accrue_admin` are repo-local sibling packages; `:sigra` is not present in local `mix.exs` files or lockfiles, and `https://hex.pm/api/packages/sigra` plus `https://hexdocs.pm/sigra/` both returned `404` on 2026-04-17. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/mix.exs] [VERIFIED: /Users/jon/projects/accrue/accrue/mix.exs] [VERIFIED: codebase grep] [CITED: https://hex.pm/api/packages/sigra] [CITED: https://hexdocs.pm/sigra/]

## Architecture Patterns

### System Architecture Diagram

```text
Sigra session / host auth
    |
    v
Host scope resolution
(`current_scope.user` today -> active organization + membership check in Phase 20)
    |
    +--> public host billing facade (`AccrueHost.Billing`)
    |         |
    |         v
    |    derive billable from active org on the server
    |         |
    |         v
    |    `Accrue.Billing.customer/1` / subscription actions
    |         |
    |         v
    |    `accrue_customers` row keeps `owner_type` / `owner_id`
    |
    +--> admin mount/session
              |
              v
      owner-aware query/detail loads
      (customers, subscriptions, invoices, events, webhooks)
              |
              +--> allow only rows linked to active org ownership
              |
              +--> deny cross-org billing IDs and replay attempts server-side
```

### Recommended Project Structure
```text
examples/accrue_host/lib/accrue_host/
├── accounts/organization.ex            # billable organization schema
├── accounts/organization_membership.ex # org membership/admin role shape
├── accounts/scope.ex                   # extend scope with active organization
└── billing.ex                          # active-org billing facade wrappers

examples/accrue_host/lib/accrue_host_web/
├── user_auth.ex                        # hydrate current scope from Sigra/session
└── live/subscription_live.ex           # org-aware host proof or a sibling org LiveView

accrue_admin/lib/accrue_admin/
├── auth_hook.ex                        # preserve current admin + new scope assigns if added
├── queries/*.ex                        # owner-aware list filters
└── live/*_live.ex                      # detail-page owner proof and denial handling
```

### Pattern 1: Reuse the Existing Billable Contract for Organizations
**What:** Make the host organization schema `use Accrue.Billable` with a pinned `billable_type`, then pass that organization struct directly into `Accrue.Billing.customer/1` and the existing billing actions. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billable.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing.ex]
**When to use:** ORG-01 and every downstream org-owned billing action. [VERIFIED: /Users/jon/projects/accrue/.planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: adapted from /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts/user.ex
defmodule AccrueHost.Accounts.Organization do
  use Ecto.Schema
  use Accrue.Billable, billable_type: "Organization"

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "organizations" do
    field :name, :string
    field :email, :string
  end
end
```
[ASSUMED]

### Pattern 2: Resolve the Billable From Active Scope, Never From Params
**What:** Keep the host UI/API surface thin and have `AccrueHost.Billing` resolve the active organization from server-side scope before delegating into `Accrue.Billing`. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex]
**When to use:** ORG-02 public host proof, cancellation, tax location repair, and any future org-owned invoice/portal action. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]
**Example:**
```elixir
# Source: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex
def customer_for(billable) do
  Billing.customer(billable)
end

def subscribe(billable, price_id, opts \\ []) do
  Billing.subscribe(billable, price_id, opts)
end
```

### Pattern 3: Prove Ownership in Admin Queries by Joining Back to Customer Ownership
**What:** Scope list/detail/replay surfaces by proving that the row belongs to the active organization through `customer.owner_type` / `customer.owner_id`, not by trusting URL IDs alone. Current admin list queries already join `Customer` for subscriptions and invoices, which is the right seam to extend. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/subscriptions.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/invoices.ex]
**When to use:** ORG-03 admin customer/subscription/invoice/event/webhook paths. [VERIFIED: /Users/jon/projects/accrue/.planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: adapted from /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/subscriptions.ex
Subscription
|> join(:inner, [subscription], customer in Customer, on: customer.id == subscription.customer_id)
|> where([_subscription, customer],
     customer.owner_type == "Organization" and customer.owner_id == ^active_org_id
   )
```
[ASSUMED]

### Anti-Patterns to Avoid
- **Client-selected org IDs:** the roadmap explicitly rejects trusting client-selected organization IDs for public, admin, replay, and finance boundaries. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]
- **Changing `Accrue.Billing.customer/1` to be Sigra-specific:** the state file locks the generic billable contract as the public model for non-Sigra hosts. [VERIFIED: /Users/jon/projects/accrue/.planning/STATE.md]
- **Admin detail loads by raw billing ID only:** `Repo.get(Customer, id)` and `Webhooks.detail(id)` are global today and need an owner proof before use in org-scoped flows. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/webhooks.ex]
- **Assuming the current auth adapter already carries organization scope:** `Accrue.Auth` exposes user/admin/actor hooks, not organization/membership callbacks. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/auth.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Organization ownership storage | Separate org-customer tables or duplicated billing schemas | Existing `owner_type` / `owner_id` contract on `accrue_customers` and downstream rows via `customer_id` | The schema is already polymorphic and tested for multiple billable types. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing/customer.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/test/accrue/billable_test.exs] |
| Org selection | Hidden form field or query-param `organization_id` | Active organization derived from Sigra/host scope on the server | Cross-org denial is a server-side requirement, not a UI courtesy. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] |
| Admin authorization | Frontend-only redirects or filtered links | Server-side query/detail scoping plus denial tests | Current admin pages fetch rows directly; filtering links alone would still leak through direct URLs. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex] |
| Replay ownership inference | New client-facing replay selector | Existing `WebhookEvent`, `Event`, `DLQ`, and local billing projections | Replay already has one canonical path; Phase 20 should add ownership proof to that path, not a parallel replay system. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/guides/webhook_gotchas.md] |

**Key insight:** Phase 20 is not a billing-engine rewrite. It is a scope-and-proof phase: keep storage generic, derive the correct organization billable server-side, and make every admin/replay read or mutation prove that ownership chain before proceeding. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing.ex] [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [ASSUMED]

## Database / Schema Implications

- `accrue_customers` already stores `owner_type` and `owner_id` as strings with a unique composite index by processor, so ORG-01 does not require a core Accrue migration just to represent an organization owner. [VERIFIED: /Users/jon/projects/accrue/accrue/priv/repo/migrations/20260412100001_create_accrue_customers.exs] [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing/customer.ex]
- `accrue_subscriptions`, `accrue_invoices`, `accrue_charges`, and payment methods link ownership transitively through `customer_id`, so owner scoping can be proven by joining back to `Customer`. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/priv/repo/migrations/20260412100002_create_accrue_billing_schemas.exs] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/subscriptions.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/invoices.ex]
- `accrue_webhook_events` has no `owner_type` or `owner_id` columns, so org scoping for replay/detail cannot be done from the webhook row alone; it has to be derived from linked local rows or denied when ownership cannot be proven. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/webhooks.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex]
- The example host currently has no organization or membership tables, so a schema push is very likely required in `examples/accrue_host` for canonical proof data, even if core Accrue tables stay unchanged. [VERIFIED: codebase grep] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/priv/repo/migrations/20260416163132_create_users_auth_tables.exs] [ASSUMED]

## Common Pitfalls

### Pitfall 1: Assuming ORG-01 needs new Accrue billing tables
**What goes wrong:** The plan spends time designing org-specific customer/subscription storage even though the current schema already supports polymorphic ownership. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing/customer.ex]
**Why it happens:** The existing proof app only exercises `"User"` ownership, which can make the generic contract look narrower than it is. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/test/accrue_host/billing_facade_test.exs]
**How to avoid:** Add org billable tests against `Accrue.Billable` and `Accrue.Billing.customer/1` first, before touching schema design. [VERIFIED: /Users/jon/projects/accrue/accrue/test/accrue/billable_test.exs] [ASSUMED]
**Warning signs:** New migrations or schemas appear under `accrue/priv/repo/migrations` for org-owned customers. [VERIFIED: codebase grep]

### Pitfall 2: Treating active organization as a UI parameter
**What goes wrong:** A user can switch query params or form payloads to act on another org's billing state. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]
**Why it happens:** The current host proof pulls `current_scope.user` directly in LiveView handlers and has no org layer yet. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts/scope.ex]
**How to avoid:** Resolve the org billable in the host facade from active server-side scope, then ignore any client-selected org identifier. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex] [ASSUMED]
**Warning signs:** Controller/LiveView params include `organization_id` and flow directly into `Billing.customer/1`, `Billing.subscribe/3`, or admin paths. [ASSUMED]

### Pitfall 3: Forgetting that admin pages are globally scoped today
**What goes wrong:** Direct links to `/billing/customers/:id`, `/billing/subscriptions/:id`, or `/billing/webhooks/:id` bypass intended org boundaries. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex]
**Why it happens:** The admin package has auth/session hooks but no organization-scope hook or owner-filter contract. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/auth_hook.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/auth.ex]
**How to avoid:** Add scope-aware list/detail loaders and explicit denial tests for cross-org URLs. [ASSUMED]
**Warning signs:** Tests only cover happy-path admin rendering for the active org and never try another org's IDs. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs] [ASSUMED]

### Pitfall 4: Assuming webhook rows themselves carry owner data
**What goes wrong:** The plan tries to filter replay/detail by `WebhookEvent` columns that do not exist. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs]
**Why it happens:** Replay feels org-local conceptually, but the persisted webhook row is processor-centric, not owner-centric. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/webhooks.ex]
**How to avoid:** Prove replay authorization through linked local billing rows and event causality, or deny when that chain is ambiguous. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/events_live.ex] [ASSUMED]
**Warning signs:** New code checks only `webhook.id` or `processor_event_id` without a lookup through local billing ownership. [ASSUMED]

## Code Examples

Verified patterns from the current codebase:

### Generic billable ownership resolution
```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/billing.ex
def customer(%{__struct__: mod, id: id} = billable) do
  billable_type = mod.__accrue__(:billable_type)
  owner_id = to_string(id)
  ...
end
```

### Generated host facade stays thin
```elixir
# Source: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex
def customer_for(billable) do
  Billing.customer(billable)
end

def billing_state_for(billable) do
  customer = find_customer(billable)
  subscription = current_subscription(customer)
  {:ok, %{customer: customer, subscription: subscription}}
end
```

### Current admin list queries already join through customer rows
```elixir
# Source: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/subscriptions.ex
Subscription
|> join(:inner, [subscription], customer in Customer,
  on: customer.id == subscription.customer_id
)
|> filter_query(filter)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Canonical host proof bills `current_scope.user` only. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex] | Phase 20 should derive the billable from active organization scope while leaving `Accrue.Billable` generic. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [ASSUMED] | Planned in Phase 20. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] | Host scope and facade code become the main implementation surface, not core billing schema redesign. [ASSUMED] |
| Admin package authenticates admins globally and fetches rows by raw billing IDs. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/auth_hook.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex] | Org-aware admin should prove row ownership through customer joins and scoped detail loaders. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [ASSUMED] | Planned in Phase 20. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] | ORG-03 is impossible to prove without additive admin scoping work. [ASSUMED] |
| Repo only contains a user-centric Sigra auth adapter scaffold. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/integrations/sigra.ex] | Canonical Sigra org proof requires a concrete host-provided organization/membership API surface. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [ASSUMED] | Not yet present in repo as of 2026-04-17. [VERIFIED: codebase grep] | Planning must treat Sigra API details as unresolved until the user or dependency source confirms them. [ASSUMED] |

**Deprecated/outdated:**
- A user-only `current_scope` is outdated for this phase because it cannot express active-organization ownership or cross-org denial. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts/scope.ex] [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]
- Global admin detail loading is outdated for ORG-03 because it proves admin auth but not tenant ownership. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Sigra exposes organization, membership, and active-organization primitives that the example host can call directly once the dependency source is available. | Summary; Architecture Patterns | High - the host proof shape and test fixtures may need to be redesigned around a different Sigra API. |
| A2 | `accrue_admin` can gain org scoping additively through session/on-mount context plus query/detail helpers without changing Accrue's public billable contract. | Summary; Architectural Responsibility Map; Common Pitfalls | Medium - if false, Phase 20 may need a broader admin package contract change. |
| A3 | The example host will need organization/membership migrations or Sigra-installed tables because no such tables exist in the repo today. | Database / Schema Implications | Medium - if Sigra stores this state elsewhere, the host schema work changes substantially. |
| A4 | Owner-aware webhook replay can be proven through linked local billing rows and event causality without adding owner columns to `accrue_webhook_events`. | Common Pitfalls | Medium - if linkage is insufficient in real Sigra flows, an additive denormalized owner column may become necessary. |

## Open Questions

1. **What exact Sigra source and API surface should Phase 20 target?**
   - What we know: local Accrue code only includes a user-centric conditional adapter scaffold, and no local or Hex package source for `sigra` was resolved today. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/integrations/sigra.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/mix.exs] [CITED: https://hex.pm/api/packages/sigra]
   - What's unclear: the concrete modules/functions for organization scope, memberships, active organization, and org-admin checks. [ASSUMED]
   - Recommendation: get the actual Sigra dependency source or confirm its API before locking plan tasks that reference module names. [ASSUMED]

2. **Should admin scoping land in Phase 20 package code or be delayed to the Phase 21 UX proof?**
   - What we know: Phase 20 success criteria already call out admin UI and replay boundaries, and current admin code is globally scoped. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex]
   - What's unclear: whether the planner should treat all admin scoping as required in Phase 20 or only the minimal seam plus tests, with richer UX in Phase 21. [ASSUMED]
   - Recommendation: plan at least the server-side scoping hooks and denial tests in Phase 20, then leave presentation polish and browser coverage breadth to Phase 21. [ASSUMED]

3. **What should the canonical denial behavior be for cross-org access?**
   - What we know: current admin mounts redirect non-admin users to `/`, while host billing flows use flashes and normal LiveView reloads. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_mount_test.exs] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex]
   - What's unclear: whether cross-org access should be `404`, redirect, forbidden flash, or explicit error tuple in each surface. [ASSUMED]
   - Recommendation: choose one server-side denial pattern per surface early and test it directly; do not leave it implicit in query misses. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `accrue`, `accrue_admin`, `examples/accrue_host` builds/tests | ✓ | `1.19.5` [VERIFIED: local command] | — |
| Mix | package/test commands | ✓ | `1.19.5` [VERIFIED: local command] | — |
| PostgreSQL client | Ecto migrations and test setup | ✓ | `14.17` [VERIFIED: local command] | — |
| PostgreSQL server on localhost | running focused/local tests immediately | ✗ | no response on `localhost:5432` [VERIFIED: local command] | Use the project's configured test DB service before execution. [ASSUMED] |
| Sigra package/docs | canonical Sigra-backed host proof | ✗ | no local dep; Hex/docs URLs returned `404` on 2026-04-17 [VERIFIED: codebase grep] [CITED: https://hex.pm/api/packages/sigra] [CITED: https://hexdocs.pm/sigra/] | No verified fallback for a true Sigra proof. |

**Missing dependencies with no fallback:**
- Concrete Sigra dependency source / API documentation for organization scope and membership behavior. [VERIFIED: codebase grep] [CITED: https://hex.pm/api/packages/sigra]

**Missing dependencies with fallback:**
- Running local PostgreSQL service; planning can proceed without it, but execution/testing cannot. [VERIFIED: local command] [ASSUMED]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest across all three apps. [VERIFIED: codebase grep] |
| Config file | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `examples/accrue_host/test/test_helper.exs` [VERIFIED: codebase grep] |
| Quick run command | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host/billing_facade_test.exs test/accrue_host_web/admin_mount_test.exs test/accrue_host_web/admin_webhook_replay_test.exs` [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/mix.exs] [ASSUMED] |
| Full suite command | `cd accrue && mix test.all && cd ../accrue_admin && mix test && cd ../examples/accrue_host && mix verify` [VERIFIED: /Users/jon/projects/accrue/accrue/mix.exs] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/mix.exs] [ASSUMED] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ORG-01 | Organization schema can `use Accrue.Billable` and round-trip `owner_type` / `owner_id` through `Accrue.Billing.customer/1`. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] | unit/integration | `cd accrue && mix test test/accrue/billable_test.exs -x` [VERIFIED: /Users/jon/projects/accrue/accrue/test/accrue/billable_test.exs] | ✅ |
| ORG-02 | Active organization scope and membership drive canonical host billing flows. [VERIFIED: /Users/jon/projects/accrue/.planning/REQUIREMENTS.md] | integration/LiveView | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host/billing_facade_test.exs test/accrue_host_web/org_billing_live_test.exs` [ASSUMED] | ❌ Wave 0 |
| ORG-03 | Cross-org access fails server-side for host, admin, replay, and future export boundaries. [VERIFIED: /Users/jon/projects/accrue/.planning/REQUIREMENTS.md] | integration/LiveView | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host_web/org_billing_access_test.exs test/accrue_host_web/admin_webhook_replay_test.exs` [ASSUMED] | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** run the smallest focused ExUnit command covering the touched surface. [VERIFIED: /Users/jon/projects/accrue/accrue/mix.exs] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/mix.exs]
- **Per wave merge:** run package-focused suites for `accrue`, `accrue_admin`, and `examples/accrue_host` touched by the wave. [VERIFIED: /Users/jon/projects/accrue/accrue/mix.exs] [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/mix.exs] [ASSUMED]
- **Phase gate:** all relevant package suites green, including host proof denial tests and admin replay checks. [ASSUMED]

### Wave 0 Gaps
- [ ] `examples/accrue_host/test/accrue_host_web/org_billing_live_test.exs` — host active-org happy-path proof for ORG-02. [ASSUMED]
- [ ] `examples/accrue_host/test/accrue_host_web/org_billing_access_test.exs` — cross-org denial coverage for host/admin entry points under ORG-03. [ASSUMED]
- [ ] `accrue_admin` owner-scope tests for customer/subscription/invoice/webhook detail loaders — current admin tests are global happy-path only. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/test/accrue_admin/live/webhook_replay_test.exs] [ASSUMED]
- [ ] Sigra-backed host fixtures or a minimal Sigra test double — no such fixture layer exists in the repo today. [VERIFIED: codebase grep] [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Host-owned auth via `Accrue.Auth` adapter and host session plumbing; Sigra is intended to be a host auth source, not an Accrue-owned auth system. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/auth.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/guides/sigra_integration.md] |
| V3 Session Management | yes | Active org must be derived from trusted host session/scope data, not from request params. [VERIFIED: /Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/user_auth.ex] [ASSUMED] |
| V4 Access Control | yes | Owner-aware query filters and detail loaders over `owner_type` / `owner_id`; deny cross-org billing IDs and replay actions server-side. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/customers.ex] [ASSUMED] |
| V5 Input Validation | yes | Ecto/NimbleOptions and host facade normalization; reject or ignore client-selected org identifiers. [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/billing.ex] [VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/checkout/session.ex] [ASSUMED] |
| V6 Cryptography | no | Phase 20 does not introduce new cryptographic primitives; existing webhook signature verification remains in force. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-org IDOR on billing detail routes | Elevation of Privilege | Scope detail queries by joined customer ownership, not by raw row ID alone. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex] [ASSUMED] |
| Forged org selection in host UI | Spoofing / Tampering | Ignore client org identifiers and derive the organization from trusted host scope/session data. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [ASSUMED] |
| Confused-deputy webhook replay | Tampering / Elevation of Privilege | Require owner proof before `DLQ.requeue/1` or bulk replay under org-scoped admin flows. [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhooks_live.ex] [ASSUMED] |
| Wrong-audience finance/event feed leakage | Information Disclosure | Keep event/webhook/export filters on owner-scoped local rows and explicit host authorization, not on free-text filters alone. [VERIFIED: /Users/jon/projects/accrue/.planning/STATE.md] [VERIFIED: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/events_live.ex] [ASSUMED] |

## Sources

### Primary (HIGH confidence)
- `/Users/jon/projects/accrue/.planning/ROADMAP.md` - Phase 20 goal, dependencies, success criteria.
- `/Users/jon/projects/accrue/.planning/REQUIREMENTS.md` - `ORG-01`, `ORG-02`, `ORG-03`, and out-of-scope items.
- `/Users/jon/projects/accrue/.planning/STATE.md` - current milestone decisions and risks.
- `/Users/jon/projects/accrue/accrue/lib/accrue/billable.ex` - generic billable contract.
- `/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex` - `customer/1`, `create_customer/1`, processor param behavior.
- `/Users/jon/projects/accrue/accrue/lib/accrue/billing/customer.ex` - persisted ownership schema.
- `/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts/scope.ex` - current user-only scope shape.
- `/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex` - host facade seam.
- `/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` - current host billing proof path.
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex` - admin session/on-mount extension seam.
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/auth_hook.ex` - current admin auth mount.
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/customers.ex` - owner fields exposed in customer queries.
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/subscriptions.ex` - customer join seam for subscription scoping.
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/invoices.ex` - customer join seam for invoice scoping.
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/webhooks.ex` - current global webhook lookup.
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex` - global customer detail loading.
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex` - replay action path.
- `/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` - current admin replay proof.
- `https://hex.pm/api/packages/sigra` - checked 2026-04-17, returned `404`.
- `https://hexdocs.pm/sigra/` - checked 2026-04-17, returned `404`.

### Secondary (MEDIUM confidence)
- `/Users/jon/projects/accrue/.planning/phases/18-stripe-tax-core/18-RESEARCH.md` - prior billing/tax projection patterns that Phase 20 should preserve.
- `/Users/jon/projects/accrue/.planning/phases/19-tax-location-and-rollout-safety/19-RESEARCH.md` - established host facade and admin-local projection boundary.
- `/Users/jon/projects/accrue/.planning/phases/19-tax-location-and-rollout-safety/19-04-SUMMARY.md` - example host migration parity and facade-proof lessons.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - most of the phase uses verified repo-local modules and schemas; the only weak spot is external Sigra source resolution. [VERIFIED: codebase grep] [CITED: https://hex.pm/api/packages/sigra]
- Architecture: MEDIUM - the owner contract and current gaps are verified, but the exact Sigra API shape and the final admin scoping seam are still assumptions. [VERIFIED: codebase grep] [ASSUMED]
- Pitfalls: HIGH - the current user-only scope, global admin detail loading, and owner-less webhook rows are all directly visible in the codebase. [VERIFIED: codebase grep]

**Research date:** 2026-04-17
**Valid until:** 2026-04-24
