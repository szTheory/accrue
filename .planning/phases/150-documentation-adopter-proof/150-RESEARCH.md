# Phase 150: Documentation & Adopter Proof - Research

**Researched:** 2026-05-28
**Domain:** Phoenix 1.8 LiveView layout wiring + ExDoc guide authoring + Fake-processor seeds + adoption-proof-matrix drift gate (Elixir/Phoenix monorepo)
**Confidence:** HIGH (all claims grounded in the live codebase, not training data)

## Summary

Phase 150 is a **documentation + adopter-proof** phase. Phase 149 already shipped both building blocks: `Accrue.Dunning.requires_attention?/1` (core boolean, in `accrue`) and `AccrueAdmin.Components.DunningBanner.dunning_banner/1` (function component, in `accrue_admin`). This phase does NOT touch those modules. It (1) adds a `## In-App Banners` section to `accrue/guides/dunning.md`, (2) wires `<.dunning_banner>` into `examples/accrue_host`'s `Layouts.app`, (3) seeds a dedicated past-due demo account, and (4) adds an adoption-proof-matrix row + verifier needle.

The single most important codebase fact: **`in_active_dunning_campaign/1` is literally `where: not is_nil(s.dunning_campaign_started_at)`** (`accrue/lib/accrue/billing/query.ex:149-151`). The banner shows whenever a customer has any subscription with a non-nil `dunning_campaign_started_at`. The seed therefore only needs to set that one column on a subscription — no webhook replay, no clock advance required for the *seed* (those are needed only in the wiring tests, which already exist from Phase 130).

The second most important fact: **`Layouts.app` is a stateless function component** (`examples/accrue_host/lib/accrue_host_web/components/layouts.ex:36`) that receives only `flash` and `current_scope`. It cannot use `on_mount`. The cleanest D-10-compliant approach is to resolve the customer with the **already-existing** `AccrueHost.Billing.customer_for_scope/1` helper, called either from inside `Layouts.app` or (preferred) hoisted into a tiny layout-local helper, and pass the resolved `%Customer{}` (or `nil`) to the banner. **Do NOT pass a raw billable to the banner** — `Accrue.Billing.customer/1` is a get-or-create that would create a customer row as a side effect (see Pitfall 1).

**Primary recommendation:** Resolve `{:ok, customer}` via `AccrueHost.Billing.customer_for_scope(@current_scope)` inside `Layouts.app`, fall back to `nil` on `{:error, :no_active_organization}`, render `<AccrueAdmin.Components.DunningBanner.dunning_banner customer={customer} />` at the top of `<main>`. Seed a `past-due@example.com` user + org + Fake-backed subscription with `dunning_campaign_started_at` set. Add the guide section after "Over-email warning" with a cross-link. Add one matrix row + one verifier needle.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Demo dunning scenario (BAN-04):**
- **D-01:** Produce the in-dunning state via a **seeded scenario** in `examples/accrue_host/priv/repo/seeds.exs` — always-on, reproducible (`mix ecto.setup` + log in = banner visible). No dev-only trigger buttons. Matches the Phase 132 adopter-proof demo pattern.
- **D-02:** Seed a **dedicated past-due demo account** (e.g. `past-due@example.com`) — a user whose active organization has a past-due subscription and an active dunning campaign — **alongside the existing healthy primary account**. Reviewer can log in as either to see banner-on vs banner-off. The default/healthy user is NOT permanently nagged.
- **D-03:** Drive the past-due/dunning state through the **Fake processor** (no live Stripe/Braintree dependency in the example seed).

**Banner placement & style (BAN-04):**
- **D-04:** Mount the banner at the **top of `<main>` in `Layouts.app`** (`examples/accrue_host/lib/accrue_host_web/components/layouts.ex`) so it appears **globally on every authenticated page**.
- **D-05:** The example uses the component's **zero-config default styling/message** (no custom `inner_block` in the demo). The customized/CTA variant is shown in the guide (D-08), not the example.

**Guide depth & structure (BAN-03):**
- **D-06:** Add a new top-level **`## In-App Banners`** section to `accrue/guides/dunning.md`, placed **immediately after the "Over-email warning" section**. Add a **cross-link from the over-email warning into the new section**.
- **D-07:** Document **both integration paths**: the `accrue_admin` `<.dunning_banner>` component path, AND a **core-only DIY path** using just `Accrue.Dunning.requires_attention?/1`. Be explicit about the dependency boundary: the ready-made component requires `accrue_admin`; the helper is core.
- **D-08:** For the component path, document **both the default (zero-config) usage AND `inner_block` customization** (e.g. a styled "Update your card" message with a CTA link to the host's payment/subscription route).

**Customer resolution (BAN-04, and the pattern the guide shows):**
- **D-09:** Resolve the current scope's **active organization → its Accrue customer**, and pass that as the banner's `:customer`. Matches the example's **org-level billing model**. User-level resolution was rejected.
- **D-10:** Put the org→customer lookup in a **small helper** (e.g. in `AccrueHost.Billing` or as a layout assign) so `Layouts.app` stays clean. **Reuse the existing org→customer resolution pattern already in `subscription_live.ex` / `AccrueHost.Billing`** rather than inventing a new one.

### Claude's Discretion
- Exact prose/wording of the guide section, code-snippet formatting, and the seeded account's display name/email.
- Whether the org→customer helper lives in `AccrueHost.Billing` vs a layout `on_mount`/assign — pick whichever matches the existing `subscription_live.ex` pattern.
- Exact form of the BAN-04 adopter-proof matrix row (follow the existing matrix convention in the adoption-proof matrix / prior adopter-proof rows).

### Deferred Ideas (OUT OF SCOPE)
- **Multi-channel (SMS/push) dunning via Chimeway** — explicit standing non-goal (compliance risk).
- **Real-time PubSub-driven banner refresh** — out of scope; banner reflects state on page load/navigation.
- **A polished customer-facing payment-update flow in the example** — the banner's CTA can link to the existing subscription page; a dedicated dunning resolution UI is not this phase.
- **Promoting the banner component into core `accrue`** — would re-open Phase 149's placement decision; out of scope. The core-only DIY doc path (D-07) is the v1.45 answer.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BAN-03 | `guides/dunning.md` updated with an "In-App Banners" section; examples showing how to mount the component or use the helper. | Guide structure mapped below; current sections + the "Over-email warning" insertion point identified. Exact component signature (`dunning_banner/1`, `:customer` attr, `inner_block` slot) and core helper (`Accrue.Dunning.requires_attention?/1`) confirmed from source for accurate copy/paste snippets. |
| BAN-04 | `examples/accrue_host` demonstrates the banner in its UI when the test user is in dunning; adopter-proof matrix row. | Layout mount point, `customer_for_scope/1` resolution helper, seed pattern (`AccountsFixtures`-equivalent + Fake subscribe + `dunning_campaign_started_at`), and the adoption-proof-matrix + verifier convention all mapped below. |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dunning state check (`requires_attention?/1`) | API / Backend (core `accrue`) | Database (reads `accrue_subscriptions.dunning_campaign_started_at`) | Core domain query; no LiveView runtime. Already shipped Phase 149. |
| Banner rendering (`dunning_banner/1`) | Frontend Server (SSR / `Phoenix.Component` in `accrue_admin`) | — | A function component; renders during HEEx eval. Lives in `accrue_admin` (LiveView-runtime-hard-dep package), not core. Already shipped Phase 149. |
| Org → customer resolution | API / Backend (host `AccrueHost.Billing`) | Database | Host policy boundary; must reuse `customer_for_scope/1`. UI must not do raw lookups. |
| Banner mount point | Frontend Server (`Layouts.app` function component) | — | Stateless layout; computes the customer assign inline. No `on_mount` available. |
| Demo state production | Database (seed) via Fake processor | API / Backend (`Accrue.Billing.subscribe/3` + `force_status_changeset/2`) | Seed creates user/org/customer/subscription rows + sets the dunning anchor column. |
| Guide / matrix docs | Docs (ExDoc guide + planning/host docs) | — | No runtime; auto-discovered by ExDoc `guides/*.md` wildcard. |

## Standard Stack

No new dependencies. This phase uses only what is already wired.

### Core (already present — confirmed from source)
| Module / Asset | Where | Purpose |
|----------------|-------|---------|
| `Accrue.Dunning.requires_attention?/1` | `accrue/lib/accrue/dunning.ex:20-33` | Core boolean; the DIY path (D-07) and the component's internal check. Accepts a `%Customer{}` or a billable. |
| `Accrue.Billing.Query.in_active_dunning_campaign/1` | `accrue/lib/accrue/billing/query.ex:149-151` | The query `requires_attention?` delegates to: `where: not is_nil(s.dunning_campaign_started_at)`. **This is the entire predicate.** |
| `AccrueAdmin.Components.DunningBanner.dunning_banner/1` | `accrue_admin/lib/accrue_admin/components/dunning_banner.ex:18-37` | The headless function component. `attr :customer, :any, required: true`; `slot :inner_block, required: false`. Default message renders when no inner block. Returns `~H""` (empty) when not in dunning. |
| `AccrueHost.Billing.customer_for_scope/1` | `examples/accrue_host/lib/accrue_host/billing.ex:93-97` | Returns `{:ok, %Customer{}}` or `{:error, :no_active_organization}`. **The exact org→customer reuse for D-09/D-10.** |
| `AccrueHost.Billing.billing_state_for_scope/1` | `examples/accrue_host/lib/accrue_host/billing.ex:99-103` | Returns `{:ok, %{customer: customer, subscription: subscription}}` — what `subscription_live.ex:580` uses. Either this or `customer_for_scope/1` is acceptable; `customer_for_scope/1` is the leaner fit for the banner. |
| `Accrue.Billing.subscribe/3` | `accrue/lib/accrue/billing.ex:56` | Used in seeds/tests to create the customer + subscription via the configured (Fake) processor: `Billing.subscribe(organization, "price_basic")`. |
| `Accrue.Billing.Subscription.force_status_changeset/2` | `accrue/lib/accrue/billing/subscription.ex:109` | Webhook-path changeset; the only changeset that casts `dunning_campaign_started_at` and `past_due_since` (and `status`). Cast fields at `subscription.ex:88-99`. Use this to set the dunning anchor + `past_due` status in the seed. |

### Host account/org creation (already present — confirmed from source)
| Function | Where | Purpose |
|----------|-------|---------|
| `AccrueHost.Accounts.register_user/1` | `examples/accrue_host/lib/accrue_host/accounts.ex:77` | Creates a user. |
| `AccrueHost.Accounts.update_user_password/2` | `examples/accrue_host/lib/accrue_host/accounts.ex:160` | Sets a password (needed so the seeded demo account can log in via the password form at `POST /users/log-in`). |
| `AccrueHost.Organizations.create_organization/2` | `examples/accrue_host/lib/accrue_host/organizations.ex` | Creates an org; takes `Scope.for_user(owner)` + attrs. (Mirrors `AccountsFixtures.organization_fixture/1`.) |
| `AccrueHost.Accounts.OrganizationMembership` | `examples/accrue_host/lib/accrue_host/accounts/organization_membership.ex` | Membership row (role `:owner`/`:admin`/`:member`). |
| `AccrueHost.Accounts.Organization` | `examples/accrue_host/lib/accrue_host/accounts/organization.ex:3` | `use Accrue.Billable, billable_type: "Organization"` — confirms the org is the billable. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `customer_for_scope/1` resolution inside `Layouts.app` | A layout `on_mount` assign | `Layouts.app` is a function component (stateless) — `on_mount` is a LiveView lifecycle hook, not available to a plain component. The live views (`subscription_live.ex`) render `<Layouts.app current_scope={@current_scope}>` so the scope is in hand; resolving the customer from the scope inside the component matches the existing call shape (`active_organization_name(@current_scope)` at `subscription_live.ex:253`). Prefer the in-layout resolution. |
| Seeding via webhook replay (Phase 130 style) | Direct `force_status_changeset/2` write in the seed | The seed needs a *static, always-on* state (D-01), not a journey. The webhook path is for the wiring **tests** (already covered by `dunning_wiring_test.exs` / `dunning_full_journey_test.exs`). A direct write of `dunning_campaign_started_at` is the simplest reproducible seed. |
| Passing the raw `Organization` billable to the banner | Passing the resolved `%Customer{}` | `Accrue.Billing.customer/1` is **get-or-create** (`accrue/lib/accrue/billing.ex:780-800`) and hits the processor — passing a billable risks a side-effecting customer creation on every page render. Resolve to `%Customer{}` first. See Pitfall 1. |

**Installation:** None. `examples/accrue_host/mix.exs:65-66` already declares both `accrue` (path `../../accrue`) and `accrue_admin` (path `../../accrue_admin`) as deps — the component is available. **VERIFIED: `examples/accrue_host/mix.exs`.**

## Package Legitimacy Audit

Not applicable — this phase installs **no external packages**. All modules used (`Accrue.*`, `AccrueAdmin.*`, `AccrueHost.*`) are first-party, already present in the monorepo, and confirmed by reading source files this session.

## Architecture Patterns

### System Data Flow (banner render path)

```
HTTP request (authenticated /app/*)
      │
      ▼
LiveView mount (subscription_live.ex or any /app live view)
  on_mount {UserAuth, :require_authenticated}  ──► assigns @current_scope
      │                                              (user + active_organization + membership)
      ▼
render/1 renders  <Layouts.app current_scope={@current_scope}>
      │
      ▼
Layouts.app(assigns)                       [examples/.../components/layouts.ex]
      │  resolve customer:
      │  AccrueHost.Billing.customer_for_scope(@current_scope)
      │     ├─ {:ok, %Customer{}}  ──► customer
      │     └─ {:error, :no_active_organization} ──► nil
      ▼
<main>
  <AccrueAdmin.Components.DunningBanner.dunning_banner customer={customer} />
      │
      ▼
  dunning_banner/1                          [accrue_admin/.../dunning_banner.ex]
      │  Accrue.Dunning.requires_attention?(customer)
      │     └─ Subscription |> where(customer_id: customer.id)
      │              |> in_active_dunning_campaign()   (not is_nil dunning_campaign_started_at)
      │              |> Repo.exists?()
      ├─ true  ──► render default banner (or inner_block if provided)
      └─ false ──► render ~H"" (nothing)
```

Healthy account: `customer.id` has no subscription with a dunning anchor → `exists?` false → empty render. Past-due demo account: seeded subscription has `dunning_campaign_started_at` set → `exists?` true → banner renders. This is the side-by-side proof (D-02).

### Project Structure (files touched)

```
accrue/
  guides/dunning.md                          # BAN-03: add "## In-App Banners" after "Over-email warning"
examples/accrue_host/
  lib/accrue_host_web/components/layouts.ex   # BAN-04 (D-04): banner at top of <main> in Layouts.app
  priv/repo/seeds.exs                         # BAN-04 (D-01..D-03): seed past-due@example.com + healthy account
  docs/adoption-proof-matrix.md               # BAN-04: new banner row (Blocking: Fake-backed host table)
  test/accrue_host_web/...                    # BAN-04: LiveView test (banner-on vs banner-off)
scripts/ci/verify_adoption_proof_matrix.sh    # BAN-04: add require_substring needle for the new row
```

### Pattern 1: Resolve customer in the stateless layout, pass `%Customer{}` to the banner
**What:** Compute the customer assign from `@current_scope` inside `Layouts.app`; never pass a raw billable.
**When to use:** D-04 banner mount.
**Example:**
```elixir
# examples/accrue_host/lib/accrue_host_web/components/layouts.ex
# inside def app(assigns) — resolve before the ~H, or via a small private helper.
# Source-grounded: AccrueHost.Billing.customer_for_scope/1 (billing.ex:93-97)

defp dunning_customer(%AccrueHost.Accounts.Scope{} = scope) do
  case AccrueHost.Billing.customer_for_scope(scope) do
    {:ok, customer} -> customer
    {:error, _} -> nil
  end
end
defp dunning_customer(_), do: nil

# in the ~H, at the top of <main>:
#   <AccrueAdmin.Components.DunningBanner.dunning_banner customer={dunning_customer(@current_scope)} />
```
Note: `requires_attention?/1` safely returns `false` for a `%Customer{}` with no dunning subscription, and for the billable fallback it returns `false` on `{:error, ...}` (`dunning.ex:28-33`). Passing `nil` is acceptable only if you confirm the `nil` path: `requires_attention?(nil)` hits the `billable` clause → `Accrue.Billing.customer(nil)`. **Safer: guard the banner so it only renders when `customer` is a `%Customer{}`** (e.g. `:if={match?(%Accrue.Billing.Customer{}, customer)}`), avoiding the get-or-create call shape entirely.

### Pattern 2: Seed a past-due + dunning subscription (Fake processor, then anchor write)
**What:** Create user → set password → create org → membership → `Billing.subscribe(org, price)` (Fake) → update the subscription with `force_status_changeset(%{status: :past_due, past_due_since: ..., dunning_campaign_started_at: ...})`.
**When to use:** D-01..D-03 seed.
**Example (shape, grounded in `subscription_live_test.exs:35` + `dunning_wiring_test.exs` + `billing.ex` cast fields):**
```elixir
# examples/accrue_host/priv/repo/seeds.exs  (additive — keep existing dunning-events seeds)
# Ensure Fake processor is the configured processor in the seed env.

{:ok, user} = AccrueHost.Accounts.register_user(%{email: "past-due@example.com"})
user = AccrueHost.Accounts.update_user_password(user, %{password: "<demo password>"}) |> elem(1) |> elem(0)
{:ok, org} = AccrueHost.Organizations.create_organization(AccrueHost.Accounts.Scope.for_user(user), %{name: "Past Due Co", slug: "past-due-co"})
# membership (owner) — see AccountsFixtures.organization_membership_fixture for the changeset shape
{:ok, _sub} = AccrueHost.Billing.subscribe(org, "price_basic")   # creates Customer + Subscription via Fake

# Flip to past-due + active dunning campaign — the one column that drives requires_attention?/1:
sub = AccrueHost.Billing.billing_state_for(org) |> elem(1) |> Map.fetch!(:subscription)
sub
|> Accrue.Billing.Subscription.force_status_changeset(%{
     status: :past_due,
     past_due_since: DateTime.utc_now(),
     dunning_campaign_started_at: DateTime.utc_now()
   })
|> AccrueHost.Repo.update!()
```
**Idempotency:** seeds run on every `mix ecto.setup`/`ecto.reset`; guard with a `Repo.get_by`/`unless exists?` so re-runs don't crash on unique-email/slug constraints (the existing dunning-events seed is already deterministic-but-additive; match its tolerance). Confirm the exact `register_user` + `update_user_password` return tuples against `accounts.ex` when planning — the example above is the shape, not verbatim.

### Pattern 3: Guide section with both paths (D-07/D-08)
**What:** `## In-App Banners` placed after `## Over-email warning`, with a cross-link added into the over-email section. Two subsections: (a) component path (`accrue_admin`, default + `inner_block` CTA), (b) core-only DIY path (`Accrue.Dunning.requires_attention?/1`).
**Heading/snippet conventions (from `accrue/guides/dunning.md`):** top-level sections are `## Title`; sub-sections `### Title`; fenced ```elixir blocks; `>` blockquote for warnings (see the existing `## Over-email warning` at lines 237-253). Config snippets use `# config/runtime.exs` comments. Match these exactly.

### Anti-Patterns to Avoid
- **Passing a raw billable (`Organization`) to `dunning_banner`** — triggers `Accrue.Billing.customer/1` get-or-create on every render. Resolve to `%Customer{}` first.
- **Re-implementing org→customer resolution** — `customer_for_scope/1` already exists. D-10 explicitly forbids inventing a new lookup.
- **Adding a dev-only trigger button or manual steps** — D-01 mandates a seeded, always-on scenario.
- **Using a custom `inner_block` in the example host** — D-05 mandates the zero-config default in the example; the CTA variant goes in the guide only.
- **Re-deriving lifecycle/`past_due` truth in the guide** — `dunning.md` cross-references `lifecycle_semantics.md#past_due` (see guide lines 3-7, 256-260). Keep that discipline.
- **Re-specifying campaign config / engine in the new section** — the new section is about *display*, not the campaign mechanism.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| "Is this customer in dunning?" | A custom query / `status == :past_due` check | `Accrue.Dunning.requires_attention?/1` | Phase 149 shipped it; it uses the ledger-anchored `dunning_campaign_started_at` (not status) to avoid projection-lag false positives (the whole point of BAN-01). |
| Banner markup + conditional render | New HEEx component | `AccrueAdmin.Components.DunningBanner.dunning_banner/1` | Phase 149 shipped it with default styling + `inner_block`. |
| Org → Accrue customer lookup | New layout query | `AccrueHost.Billing.customer_for_scope/1` | Already the host's policy boundary (D-10). |
| Creating customer + subscription rows in the seed | Manual `Repo.insert` of `Customer`/`Subscription` | `Accrue.Billing.subscribe(org, price)` (Fake) | Goes through the real facade + Fake processor (D-03); only the dunning-anchor flip needs `force_status_changeset`. |
| User/org/membership creation in the seed | Raw inserts | `Accounts.register_user/1`, `Organizations.create_organization/2`, membership changeset (mirror `AccountsFixtures`) | The host context owns validation + slug/email uniqueness. |

**Key insight:** Every primitive this phase needs already exists in the monorepo. The phase is *assembly + documentation*, not construction.

## Runtime State Inventory

Not a rename/refactor/migration phase. Section omitted intentionally — there is no stored-data renaming, live-service reconfiguration, OS-registered state, secret renaming, or build-artifact churn in scope. (New seed rows are additive demo data, not a migration of existing records.)

## Common Pitfalls

### Pitfall 1: Banner triggers a side-effecting customer creation
**What goes wrong:** Passing the `Organization` (or any billable) to `dunning_banner customer={...}` makes `requires_attention?/1` call `Accrue.Billing.customer/1`, which **creates a customer row if none exists** (get-or-create, `billing.ex:780-800`) — on every page render, for every authenticated user.
**Why it happens:** The `:customer` attr is `:any` and `requires_attention?/1` accepts a billable fallback.
**How to avoid:** Resolve `{:ok, %Customer{}}` via `customer_for_scope/1` in the layout and pass the `%Customer{}` (or `nil`). Guard the banner to render only for `%Customer{}` (`:if={match?(%Accrue.Billing.Customer{}, customer)}`).
**Warning signs:** New `accrue_customers` rows appearing for users who never subscribed; Fake processor `create_customer` calls in logs on plain GETs.

### Pitfall 2: Seed not idempotent → `mix ecto.reset` crashes
**What goes wrong:** Re-running seeds inserts a duplicate `past-due@example.com` / `past-due-co` slug → unique constraint error → `ecto.setup` fails → adopter can't even boot the demo.
**How to avoid:** Guard with `Repo.get_by(User, email: ...)` / `unless` before insert, or rescue the unique-constraint path. The existing seed uses `Ecto.UUID.generate()` for event subjects (always fresh); the account seed needs an explicit existence guard.
**Warning signs:** `mix ecto.reset` green once, red on the second run.

### Pitfall 3: Layout customer resolution runs a DB query on every render
**What goes wrong:** `customer_for_scope/1` + `requires_attention?/1` each hit the DB; `Layouts.app` renders on every authenticated page and on every LiveView re-render/patch.
**Why it happens:** Stateless component recomputes assigns each render.
**How to avoid:** Acceptable for the demo (two indexed lookups; `dunning_campaign_started_at` is covered by `accrue_subscriptions_past_due_since_idx`-class indexing and customer_id FK). Document the trade-off in the guide DIY path (suggest resolving once in `mount` and passing down as an assign for production hosts). Do NOT over-engineer the example — D-04/D-05 want the simplest drop-in.
**Warning signs:** N+1 concern only matters at scale; not a demo blocker.

### Pitfall 4: Forgetting the verifier needle when editing the matrix
**What goes wrong:** Adding a row to `adoption-proof-matrix.md` without a matching `require_substring` in `scripts/ci/verify_adoption_proof_matrix.sh` means the row is undefended (drift gate doesn't pin it); conversely, the verifier already pins ~50 substrings — editing surrounding text can break an existing needle.
**Why it happens:** The matrix and its verifier are a co-update pair (the established support-contract SSOT discipline — see Phase 130 D-05).
**How to avoid:** Add the new row to the **"Blocking: Fake-backed host + browser"** table (`adoption-proof-matrix.md:14-31`) AND add a `require_substring "<token>" "<label>"` line to the verifier in the same change set. Run the verifier locally: `bash scripts/ci/verify_adoption_proof_matrix.sh`. Do not disturb existing needles.
**Warning signs:** `docs-contracts-shift-left` CI job fails with "matrix missing ..." or the row passes silently with no gate.

### Pitfall 5: Demo account can't log in (no password)
**What goes wrong:** `register_user/1` creates an unconfirmed, password-less user (the host uses magic-link by default; `AccountsFixtures.user_fixture` logs in via magic link). A seeded account with no password and no confirmation can't log in through the demo UI's password form.
**How to avoid:** Set a password via `Accounts.update_user_password/2` (and confirm the user if confirmation is required for login — check the auth flow when planning). Document the demo credentials in the host README / seed comment so a reviewer knows how to log in as `past-due@example.com`.
**Warning signs:** Reviewer follows "log in as past-due@example.com" and gets bounced to magic-link.

## Code Examples

### Banner component signature (verbatim from source — for accurate guide snippets)
```elixir
# Source: accrue_admin/lib/accrue_admin/components/dunning_banner.ex:15-37
attr(:customer, :any, required: true, doc: "The customer or billable struct")
slot(:inner_block, required: false)

def dunning_banner(assigns) do
  if Accrue.Dunning.requires_attention?(assigns.customer) do
    # renders @inner_block if present, else the default red banner
  else
    ~H""   # renders nothing
  end
end
```
Default message text (for the guide): *"Action Required: We were unable to process your recent payment. Please update your payment method to avoid service interruption."*

### Core DIY path (verbatim from source — D-07)
```elixir
# Source: accrue/lib/accrue/dunning.ex:20-33
# In a host that does NOT pull accrue_admin, roll your own markup:
<%= if Accrue.Dunning.requires_attention?(@customer) do %>
  <div class="my-dunning-banner">
    Update your card — <a href={~p"/app/billing"}>fix payment</a>
  </div>
<% end %>
```

### The query that drives everything (verbatim — explains the seed)
```elixir
# Source: accrue/lib/accrue/billing/query.ex:149-151
def in_active_dunning_campaign(query \\ Subscription) do
  from(s in query, where: not is_nil(s.dunning_campaign_started_at))
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Banner component proposed as `Accrue.Components.DunningBanner` in core (REQUIREMENTS BAN-02) | Shipped as `AccrueAdmin.Components.DunningBanner` in `accrue_admin` | Phase 149 | The guide MUST reference `AccrueAdmin.Components.DunningBanner` and be explicit that the ready-made component needs `accrue_admin` (D-07). Core stays LiveView-runtime-free. |
| Adoption proof at `.planning/processor-support-matrix.md` (initial CONTEXT note `additional_context #5`) | Adoption-proof matrix lives at `examples/accrue_host/docs/adoption-proof-matrix.md`, gated by `scripts/ci/verify_adoption_proof_matrix.sh` | Established (Phase 130/132) | The BAN-04 row goes in the **host** adoption-proof matrix, not the planning processor-support matrix. The processor-support matrix is a *capability* matrix (per-provider labels), not a per-feature adopter-proof matrix. [VERIFIED: read both files this session.] |

**Deprecated/outdated:** The CONTEXT.md `<canonical_refs>` and `additional_context` point at `.planning/processor-support-matrix.md` for the BAN-04 row — but the established adopter-proof convention (Phases 130/132) uses `examples/accrue_host/docs/adoption-proof-matrix.md`. Phase 132's locked decision explicitly names `examples/accrue_host/docs/adoption-proof-matrix.md` + `scripts/ci/verify_adoption_proof_matrix.sh`. **Recommendation:** put the banner row in the host adoption-proof matrix (matches precedent). Flag this divergence to the planner/user — see Open Questions.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The BAN-04 adopter-proof row belongs in `examples/accrue_host/docs/adoption-proof-matrix.md` (not `.planning/processor-support-matrix.md` as CONTEXT literally says). | State of the Art / Open Questions | If wrong, the row lands in the wrong file. Low risk — Phase 132 precedent is explicit; flagged for confirmation. |
| A2 | The seeded demo user logs in via the password form, so it needs a password set (and possibly confirmation). | Pitfall 5 | If the demo relies on magic-link only, the password step is unnecessary; if login requires confirmation, missing it blocks login. Verify the host auth flow during planning. |
| A3 | A static `force_status_changeset` write of `dunning_campaign_started_at` is sufficient for the seed (no webhook/clock needed). | Pattern 2 | Very low risk — `in_active_dunning_campaign/1` checks only that column; verified from source. |
| A4 | `subscribe(org, "price_basic")` works in the seed env with the Fake processor configured (as in `subscription_live_test.exs`). | Pattern 2 | If the seed env's processor/price config differs from test, the subscribe call could fail. Verify `examples/accrue_host/config/{config,dev,runtime}.exs` processor + the seeded price id during planning. |
| A5 | Guarding the banner with `match?(%Accrue.Billing.Customer{}, customer)` avoids the get-or-create side effect. | Pattern 1 / Pitfall 1 | Low risk — confirmed `requires_attention?/1` clause structure. |

## Open Questions

1. **Which matrix file gets the BAN-04 row?**
   - What we know: CONTEXT.md says `.planning/processor-support-matrix.md`; the established adopter-proof convention (Phases 130/132, and the `verify_adoption_proof_matrix.sh` gate) uses `examples/accrue_host/docs/adoption-proof-matrix.md`.
   - What's unclear: whether the user wants to follow CONTEXT literally or follow precedent.
   - Recommendation: Use `examples/accrue_host/docs/adoption-proof-matrix.md` (the **Blocking: Fake-backed host + browser** table) + a `require_substring` needle in `scripts/ci/verify_adoption_proof_matrix.sh`. This matches the dunning-wiring row already in that table (matrix line 27) and the entitlement-gating row (line 29). discuss-phase should confirm before locking.

2. **Does the seeded demo user need email confirmation to log in?**
   - What we know: `register_user/1` creates an unconfirmed user; `AccountsFixtures.user_fixture` confirms via magic-link login.
   - What's unclear: whether the password login path requires a confirmed user.
   - Recommendation: Set a password and, if needed, confirm the user in the seed. Verify the exact `accounts.ex` login guard when planning; document the demo credentials in the seed comment + host README.

3. **Where exactly does the customer resolution live — inside `Layouts.app` or hoisted?**
   - What we know: `Layouts.app` is a stateless function component; D-10 wants the lookup in a "small helper."
   - Recommendation (discretion per D-10): a private `defp dunning_customer(scope)` in `Layouts` calling `AccrueHost.Billing.customer_for_scope/1`. This keeps the `~H` clean and reuses the existing helper. Either this or computing it in each live view's `mount` and passing as an assign is acceptable; the in-layout helper is the lowest-friction global mount (D-04 wants it on *every* authenticated page, so per-view assigns would require touching every live view).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `accrue` (path dep) | banner core helper | ✓ | path `../../accrue` | — |
| `accrue_admin` (path dep) | `DunningBanner` component | ✓ | path `../../accrue_admin` | — (component is in this package) |
| PostgreSQL | seeds + tests | ✓ (assumed per existing host) | 14+ | — |
| Fake processor | seed dunning state (D-03) | ✓ (`Accrue.Processor.Fake`, used in host tests) | in-repo | — |
| Chrome/Stripe network | — | not needed | — | n/a (Fake lane only) |

No missing dependencies. **VERIFIED: `examples/accrue_host/mix.exs:65-66`** declares both packages.

## Validation Architecture

> Nyquist validation is enabled (no `workflow.nyquist_validation: false` found). Section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) + `Phoenix.LiveViewTest` for LiveView assertions |
| Config file | `examples/accrue_host/config/test.exs`; `examples/accrue_host/test/test_helper.exs` |
| Quick run command | `cd examples/accrue_host && mix test test/accrue_host_web/<banner_test>.exs` |
| Full suite command | `cd examples/accrue_host && mix test` (or `mix verify` bounded / `mix verify.full`) |
| Doc-presence gate | `bash scripts/ci/verify_adoption_proof_matrix.sh` (from repo root) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BAN-04 | Past-due account renders the banner | LiveView | `mix test test/accrue_host_web/dunning_banner_live_test.exs` | ❌ Wave 0 (new) |
| BAN-04 | Healthy account does NOT render the banner | LiveView | (same file, second test) | ❌ Wave 0 (new) |
| BAN-04 | Seed produces an in-dunning subscription | unit/integration | assert `Repo.exists?(in_active_dunning_campaign for the demo customer)` (can live in the same LiveView test setup or a seeds smoke) | ❌ Wave 0 (new) |
| BAN-04 | Adoption-proof matrix row present + pinned | doc-presence | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✓ verifier exists; needs new needle |
| BAN-03 | Guide contains the "In-App Banners" section | doc-presence | optional `grep -q "## In-App Banners" accrue/guides/dunning.md` (no dedicated guide verifier exists for this section today) | ⚠️ no existing guide-section gate — consider a lightweight grep assertion or rely on review |

### LiveView test approach (grounded in `subscription_live_test.exs`)
The proven pattern (from `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs:14-50`):
```elixir
use AccrueHostWeb.ConnCase, async: false
import Phoenix.LiveViewTest

setup do
  Accrue.Processor.Fake.start_link([]); Accrue.Processor.Fake.reset()
  cleanup_fake_billing_rows!()
  user = AccountsFixtures.user_fixture()
  org  = AccountsFixtures.organization_fixture(%{owner: user})
  %{user: user, organization: org}
end

# Banner-ON test:
test "past-due org renders the dunning banner", %{conn: conn, user: user, organization: org} do
  {:ok, _sub} = Billing.subscribe(org, "price_basic")
  # flip to dunning via force_status_changeset (set dunning_campaign_started_at)
  {:ok, view, html} =
    conn |> log_in_user(user, active_organization_id: org.id) |> live(~p"/app/billing")
  assert html =~ "Action Required"        # default banner copy
  # or: assert has_element?(view, ".accrue-default-dunning-banner")
end

# Banner-OFF test: healthy org (subscribe, no dunning anchor) → refute the banner.
```
`log_in_user(conn, user, active_organization_id: org.id)` is the existing ConnCase helper (`conn_case.ex:65,85`). Use `has_element?`/`html =~` against the banner wrapper class `accrue-default-dunning-banner` or the default copy string. This validates **both** success criteria: SC#2 (banner shows for past-due) directly, and the side-by-side healthy/past-due contrast (D-02).

### Sampling Rate
- **Per task commit:** `cd examples/accrue_host && mix test test/accrue_host_web/<banner_test>.exs` + `bash scripts/ci/verify_adoption_proof_matrix.sh`
- **Per wave merge:** `cd examples/accrue_host && mix test` (bounded `mix verify`)
- **Phase gate:** host `mix verify` green + the adoption-proof verifier green + `accrue` package `mix test` unaffected, before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `examples/accrue_host/test/accrue_host_web/dunning_banner_live_test.exs` — new LiveView test (banner-on + banner-off), covers BAN-04 SC#2.
- [ ] Seed idempotency guard in `examples/accrue_host/priv/repo/seeds.exs` — so `ecto.reset` re-runs cleanly.
- [ ] New `require_substring` needle in `scripts/ci/verify_adoption_proof_matrix.sh` matching the BAN-04 row token.
- [ ] (Optional, recommended) a grep-style presence check for `## In-App Banners` in `accrue/guides/dunning.md` — there is no existing guide-section drift gate; decide whether to add one or rely on review. The `verify_package_docs.sh` gate exists but verify whether it would need a new needle (see MEMORY: verify_package_docs ↔ test coupling).

*Existing infra reused:* `Accrue.Processor.Fake`, `AccountsFixtures`, `ConnCase.log_in_user/3`, `Phoenix.LiveViewTest`, `force_status_changeset/2`.

## Security Domain

> `security_enforcement` not found as `false` in config — included, scoped to actual surface.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No new auth surface — reuses existing `UserAuth`/scope; seed sets a demo password only. |
| V3 Session Management | no | Reuses existing session/scope plumbing. |
| V4 Access Control | yes (light) | Banner reads the *current scope's* org→customer only (`customer_for_scope/1` is scope-bound). It must not leak another org's dunning state. The existing helper already scopes to `active_organization`. |
| V5 Input Validation | no | No user input introduced; seed data is static. |
| V6 Cryptography | no | None. |
| V7 Error Handling / Logging | yes (light) | Do not log customer/subscription PII when resolving the banner customer; the layout resolution is a read. Sensitive Stripe fields rule (CLAUDE.md) — banner shows generic copy, no payment details. |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant dunning-state leak (banner shows another org's state) | Information Disclosure | Resolve customer strictly from `@current_scope` via `customer_for_scope/1` (scope-bound). Never accept a customer id from params. |
| Side-effecting customer creation on render (Pitfall 1) | Tampering / availability | Pass resolved `%Customer{}`/`nil`, guard with `match?(%Customer{}, customer)`. |
| Hard-coded demo password in seeds committed to repo | (demo-only) | Acceptable for an example host seed; document it as a demo credential, not a production secret. Do not reuse the pattern for real hosts in the guide. |

## Sources

### Primary (HIGH confidence) — read this session
- `accrue/lib/accrue/dunning.ex` (Phase 149 core helper)
- `accrue/lib/accrue/billing/query.ex` (`in_active_dunning_campaign/1`)
- `accrue/lib/accrue/billing/subscription.ex` (`force_status_changeset/2`, cast fields, `dunning_campaign_active?/1`)
- `accrue/lib/accrue/billing.ex` (`subscribe/3`, `customer/1` get-or-create)
- `accrue_admin/lib/accrue_admin/components/dunning_banner.ex` (Phase 149 component)
- `examples/accrue_host/lib/accrue_host/billing.ex` (`customer_for_scope/1`, `billing_state_for_scope/1`, `find_customer/1`)
- `examples/accrue_host/lib/accrue_host_web/components/layouts.ex` (`Layouts.app`, `<main>`)
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` (existing scope/customer call shapes)
- `examples/accrue_host/priv/repo/seeds.exs` (existing seed)
- `examples/accrue_host/mix.exs` (deps: accrue + accrue_admin)
- `examples/accrue_host/test/support/fixtures/accounts_fixtures.ex` (user/org/membership creation)
- `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` (LiveView test pattern + `log_in_user`)
- `examples/accrue_host/test/accrue_host/dunning_wiring_test.exs` (Fake-backed subscription seeding pattern)
- `examples/accrue_host/test/support/conn_case.ex` (`log_in_user/3`)
- `examples/accrue_host/docs/adoption-proof-matrix.md` + `scripts/ci/verify_adoption_proof_matrix.sh` (matrix + drift gate)
- `accrue/guides/dunning.md` (guide structure, "Over-email warning" insertion point)
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `150-CONTEXT.md`, Phase 130/132 CONTEXT.md

### Secondary / Tertiary
- None — no web sources needed; this is an internal-codebase phase.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every module/function read from source this session.
- Architecture / mount point: HIGH — `Layouts.app` and the resolution helper confirmed; the stateless-component constraint is verified.
- Seed pattern: HIGH (mechanism) / MEDIUM (exact return-tuple shapes of `register_user`/`update_user_password` and the seed-env processor/price config — flagged A4/A2 for planning verification).
- Matrix location: HIGH that the adopter-proof convention is the host matrix; MEDIUM on whether the user wants to override CONTEXT's literal `.planning/` pointer (Open Question 1).
- Pitfalls: HIGH — Pitfall 1 (get-or-create) and the seed-idempotency/login pitfalls are grounded in source.

**Research date:** 2026-05-28
**Valid until:** 2026-06-27 (stable internal codebase; re-verify if Phase 149 artifacts or the host auth flow change)
