# Organization billing

This guide is the **non-Sigra** mainline for **organization-shaped** Stripe billing on Phoenix: you establish identity with `phx.gen.auth` (or equivalent), resolve an **active organization** from the session with **membership checks**, attach **`use Accrue.Billable`** to the org row, and route subscribe/cancel flows through a small host billing facade that accepts **`Organization`** as the billable. It complements the adapter contract in [Auth adapters](auth_adapters.md)—that file stays the `Accrue.Auth` SSOT; here we focus on **session → organization → billable** and **ORG-03** obligations.

## Who this guide is for

Teams shipping **B2B or multi-tenant SaaS** where the Stripe Customer should follow the **organization**, not only the signed-in user. You already run (or plan) `phx.gen.auth`, you own org/membership tables, and you want a single linear checklist instead of piecing together fragments from several guides.

## Session → organization → billable

1. **Session identity** — Keep `fetch_current_user` / `MyAppWeb.UserAuth` (or equivalent) as the source of truth for **who** is signed in.
2. **Active organization** — Add `fetch_current_organization` as a plug or `on_mount` hook that loads the org id from the session **and verifies membership** before assigning `current_organization`. Never trust a raw `org_id` query param without a membership join.
3. **Billable row** — For org-shaped billing, add `use Accrue.Billable` to **`MyApp.Accounts.Organization`** (not only `User`) so Accrue’s customer/subscription rows anchor on the org.
4. **Host facade** — Implement `MyApp.Billing.subscribe/2`, `customer_for/1`, and related hooks so org flows pass **`Organization`** into `Accrue.Billing` helpers; keep policy (who may subscribe, cancel, update tax location) in the host module.
5. **Auth adapter** — Configure `config :accrue, :auth_adapter, MyApp.Auth.PhxGenAuth` (or your adapter). Copy the **module body** for `MyApp.Auth.PhxGenAuth` from [Auth adapters](auth_adapters.md); do not duplicate it here.

For **which row** owns finance exports and revenue reporting, see [Finance handoff](finance-handoff.md).

## ORG-03 boundaries at a glance

Accrue stores billing state, but **cross-tenant isolation** is host-owned. Every host surface falls into one of four path classes: **public**, **admin**, **webhook replay**, and **export**. The full ORG-03 requirement text lives in the repo milestone [v1.3-REQUIREMENTS.md](https://github.com/szTheory/accrue/blob/main/.planning/milestones/v1.3-REQUIREMENTS.md) (ORG-03); Phase 38 (**ORG-07**, **ORG-08**) adds deeper anti-patterns for Pow, custom org resolution, and replay matrices.

| Path class | Threat one-liner | Host obligation | Enforce at | Further reading |
|------------|------------------|------------------|------------|-------------------|
| public | IDOR via guessable org URLs | Scope every query by membership; never “first org in DB” defaults | Router plugs, context functions | ORG-03 |
| admin | Privilege escalation into another tenant’s billing | Require admin role **and** org membership before Accrue Admin or destructive billing UI | `require_admin_plug`, LiveView mounts | [Auth adapters](auth_adapters.md) |
| webhook replay | Cross-org mutation from replayed or mis-scoped events | Resolve billable from event metadata; no global `Repo.all` in handlers | Webhook handler, Oban workers | [Webhooks](webhooks.md) |
| export | Data spill into wrong tenant file or inbox | Filter exports by org scope; same Stripe account as configured customer | Export jobs, Sigma/RR joins | [Finance handoff](finance-handoff.md) |

## Minimal host model (Organization + Membership)

Model at least **`Organization`**, **`OrganizationMembership`** (user ↔ org + role), and optionally **`OrganizationInvitation`**. On **user registration**, bootstrap a **personal organization** plus membership so solo developers get a working org-shaped path without a second “create your workspace” tutorial. Keep slugs and soft-delete rules explicit so `current_organization` never points at a row the user should not see.

## phx.gen.auth checklist

1. Keep **`fetch_current_user`** as the identity source of truth (existing `phx.gen.auth` pipeline).
2. Add **`fetch_current_organization`** as a plug or LiveView `on_mount` that **verifies membership** before assigning `current_organization` (session stores an org id; membership table is the gate).
3. Add **`use Accrue.Billable`** on **`MyApp.Accounts.Organization`** with the correct `billable_type` for your app.
4. Ensure host **`MyApp.Billing`** functions used for org-shaped subscribe/customer flows take **`Organization`** (or a scope that resolves to one) as the billable argument passed into Accrue.
5. Set **`config :accrue, :auth_adapter, MyApp.Auth.PhxGenAuth`** — copy the adapter module body from [`guides/auth_adapters.md`](auth_adapters.md); it lists every `Accrue.Auth` callback.

## Pow-oriented checklist (ORG-07)

Pow answers **who is signed in**; it does **not** infer which **organization** is active. Treat `Pow.Plug.current_user/1` as the identity boundary, then run the same **membership-gated** `fetch_current_organization` pattern as the `phx.gen.auth` mainline—never promote a raw session org hint to `current_organization` without a membership join.

### Identity with Pow

Read the signed-in user with **`Pow.Plug.current_user/1`** on the `%Plug.Conn{}` (and LiveView assigns fed by the same pipeline). That value is the **identity** input to your plugs and `on_mount` hooks; every org decision still flows through explicit session + membership checks.

### Active organization and membership

Add **`fetch_current_organization`** as a plug or LiveView `on_mount` that loads an org id from the session **and verifies membership** before assigning `current_organization`. Pow does not infer active org tenancy—if you stash an org id in session, re-validate against your membership table on each request, matching steps 2–4 in **Session → organization → billable** above.

### Billable row and host facade

Attach **`use Accrue.Billable`** to **`MyApp.Accounts.Organization`** for org-shaped billing. Shape **`MyApp.Billing`** so subscribe/cancel/customer helpers accept **`Organization`** (or a scope that resolves to one) when calling `Accrue.Billing`, keeping policy (who may subscribe, cancel, update tax location) in the host module.

### Accrue.Auth configuration

Configure:

```elixir
config :accrue, :auth_adapter, MyApp.Auth.Pow
```

Copy the **`MyApp.Auth.Pow`** module body from [`auth_adapters.md`](auth_adapters.md)—that section is the SSOT for `Accrue.Auth` callbacks (`current_user/1`, `require_admin_plug/0`, audit hooks, optional step-up). Accrue Admin and audit paths still call `Accrue.Auth`; Pow is only how **`current_user/1`** is implemented.

### Maintenance and upgrades

Pow is **community-maintained**. Pin `pow` (and extensions) deliberately, read upstream changelog on every bump, and **re-verify** Plug ordering and session fetch after upgrades—Pow integrates at the connection layer and regressions often surface as missing assigns rather than compile errors.

## User-as-billable (bounded aside)

**User-as-billable** (Cashier-style: `use Accrue.Billable` on **`User`**) is a valid stepping stone for single-tenant or solo apps. Accrue still expects consistent **`owner_type`** / **`owner_id`** on persisted billing rows. If you later move Stripe Customer ownership to an **Organization**, plan a **migration** of customer/subscription ownership—Stripe IDs cannot silently “move” without host data work. **Pow** is covered in **ORG-07** above; **custom organization models** (alternate session keys, subdomains, replay/export matrices) are covered in **ORG-08** below.

## Reference wiring (examples/accrue_host)

The demo host is generator-agnostic proof, not a second tutorial:

| Module | Role |
|--------|------|
| `AccrueHost.Accounts.Organization` | Org schema with `use Accrue.Billable, billable_type: "Organization"` |
| `AccrueHost.Accounts.User` | User schema (also billable in the demo—illustrates the bounded aside) |
| `AccrueHost.Billing` | Host facade: `subscribe_active_organization/2`, `customer_for_scope/1`, policy hooks |

Cross-check the latest files under `examples/accrue_host/lib/accrue_host/` after upgrades.

## Footguns to avoid

- **Stale `active_organization_id`** after membership revoke — always re-check membership when loading org from session.
- **IDOR** on `/orgs/:id` without membership — param is untrusted; session + membership is trusted.
- **“First org in the database”** fallbacks in dev — they become production incidents.
- **Webhook handlers** that query billables without org/processor scope — replays and multi-tenant leaks.
- Assuming **`Accrue.Auth.Default`** is production-safe for non-Sigra apps — it is not; configure a real adapter.

## Related guides

- [Auth adapters](auth_adapters.md) — `Accrue.Auth` contract and `MyApp.Auth.PhxGenAuth` source.
- [Finance handoff](finance-handoff.md) — Stripe RR, Sigma, and **which host row** backs reporting.
- [Sigra integration](sigra_integration.md) — optional first-party adapter when Sigra is already a dependency.
