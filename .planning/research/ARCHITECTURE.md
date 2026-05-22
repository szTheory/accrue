# Architecture Research — Entitlements / Plan-Gating (v1.39)

**Domain:** First-party feature/plan gating layered onto an existing Elixir/Phoenix billing library (Accrue)
**Researched:** 2026-05-22
**Confidence:** HIGH (codebase-verified integration points; MEDIUM on Stripe-sync timing since the dep does not yet support it)

> Scope note: This is an **integration design** against Accrue's already-feature-complete
> billing core, not a redesign of that core. Every recommendation below either reuses an
> existing seam (telemetry `span_billing`, `Events.record`, `Processor.Capabilities`,
> conditional-compile, `nimble_options` config, `AccrueAdmin.AuthHook`) or adds a thin new
> module that mirrors one. New-vs-modified is called out per component. The verified
> central insight: **entitlements resolve entirely from local subscription state Accrue
> already holds** — `billable → Customer → active Subscriptions → SubscriptionItems →
> price_id → (plan→feature map)` — so the gate read path needs zero processor API calls.

---

## Decisions at a glance

| # | Question | Decision | Confidence |
|---|----------|----------|------------|
| 1 | Where the model lives | **Hybrid: host-declared static map (nimble_options) is the source of truth; an optional synced cache table layers on for Stripe** | HIGH |
| 2 | Query/gate core | **New `Accrue.Entitlements` context** + thin convenience delegates on `Accrue`; telemetry-instrumented; ledger records grant/revoke, **not** checks | HIGH |
| 3 | Plug + LiveView guards | **Plug guard in core (`Accrue.Plug.RequireEntitlement`); LiveView `on_mount` in a thin conditionally-compiled core module (`Accrue.Live.Entitlements`)** guarded by `Code.ensure_loaded?(Phoenix.LiveView)` | HIGH |
| 4 | Provider-honest dispatch | **Resolver behaviour + capability rows**: Fake/Braintree = local plan→feature map; Stripe = local map by default, native Entitlements as an opt-in source once the dep supports it | HIGH |
| 5 | Stripe sync | **In-scope-but-OPTIONAL and behind a flag; ship the cache table + webhook plumbing now, defer live Stripe API reads** (lattice_stripe 1.1.0 has no Entitlements module — verified) | MEDIUM |
| 6 | Admin surface | **New "Entitlements" tab on the existing `CustomerLive`** in `accrue_admin` | HIGH |
| 7 | Caching vs live-check | **Always read from local state (subscription projection + optional cache table); never call a processor API on the gate path** | HIGH |

---

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│  HOST APP (Phoenix)                                                        │
│  ┌────────────────────┐   ┌──────────────────────┐   ┌─────────────────┐  │
│  │ Controller         │   │ LiveView route        │   │ HEEx / business │  │
│  │ plug RequireEntitl │   │ on_mount {Entitl, …}  │   │ if entitled?    │  │
│  └─────────┬──────────┘   └──────────┬───────────┘   └────────┬────────┘  │
└────────────┼─────────────────────────┼────────────────────────┼───────────┘
             │  (NEW core)              │ (NEW core, cond-compiled)│ (public API)
┌────────────▼─────────────────────────▼────────────────────────▼───────────┐
│  accrue (core, LiveView-runtime-free)                                      │
│                                                                            │
│  Accrue.Plug.RequireEntitlement     Accrue.Live.Entitlements              │
│        │  (NEW)                            │  (NEW, if Code.ensure_loaded? │
│        │                                   │       Phoenix.LiveView)       │
│        └───────────────┬───────────────────┘                              │
│                        ▼                                                    │
│            ┌───────────────────────────┐    thin delegates  ┌───────────┐ │
│            │  Accrue.Entitlements (NEW) │◄───────────────────┤  Accrue   │ │
│            │  entitled?/active_plan?/   │                    │ (delegate)│ │
│            │  features_for/list/        │                    └───────────┘ │
│            │  grant/revoke (telemetry + │                                   │
│            │  span_entitlement)         │                                   │
│            └───┬──────────────┬─────────┘                                   │
│   resolve plan │              │ record grant/revoke                         │
│   ▼            │              ▼                                             │
│ ┌────────────────────────┐  ┌──────────────────────┐  ┌─────────────────┐ │
│ │ Entitlements.Resolver  │  │ Accrue.Events (EXIST)│  │ Accrue.Telemetry│ │
│ │ behaviour (NEW)        │  │ tamper-evident ledger│  │ span (EXIST)    │ │
│ │  • LocalMap (default)  │  └──────────────────────┘  └─────────────────┘ │
│ │  • StripeNative (opt)  │                                                 │
│ └───┬────────────┬───────┘                                                 │
│     │            │ reads                                                    │
│     ▼            ▼                                                          │
│ ┌────────────┐  ┌──────────────────────────────────────────────────────┐ │
│ │ Config     │  │ EXISTING local state (NO processor API on read path)  │ │
│ │ :plans map │  │  Customer ─< Subscription ─< SubscriptionItem.price_id│ │
│ │ (nimble)   │  │  Query.active/1 · Subscription.active?/1               │ │
│ │ (NEW key)  │  │  + OPTIONAL accrue_entitlement_grants cache (NEW tbl) │ │
│ └────────────┘  └──────────────────────────────────────────────────────┘ │
│                                                                            │
│  Stripe-sync (OPTIONAL): Webhook.DefaultHandler clause (MODIFY) →          │
│     entitlements.active_entitlement_summary.updated → upsert cache table   │
└────────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | New / Modified |
|-----------|----------------|----------------|
| `Accrue.Entitlements` | Public context: `entitled?/2`, `has_active_plan?/2`, `features_for/1`, `list_entitlements/1`, `grant/3`, `revoke/3`. Wraps each entry in `span_entitlement`. | **NEW** |
| `Accrue.Entitlements.Resolver` | Behaviour: `resolve(billable, opts) :: {:ok, %{plan: ..., features: MapSet}} \| {:error, _}`. | **NEW** |
| `Accrue.Entitlements.LocalMap` | Default resolver — folds active subscriptions' `price_id`s through the host `:plans` config map. | **NEW** |
| `Accrue.Entitlements.StripeNative` | Opt-in resolver — reads the cache table (and, once the dep supports it, the Stripe Active Entitlements API). | **NEW (cache-only at v1.39)** |
| `Accrue.Entitlements.Grant` (schema) | Optional cache row: `customer_id`, `feature` (lookup_key), `source` (`:local` / `:stripe`), `active`, `data`, `lock_version`. | **NEW (optional)** |
| `Accrue.Plug.RequireEntitlement` | Controller-level gate. `plug Accrue.Plug.RequireEntitlement, feature: "api_access"` (or `plan:`). Halts 403 / redirects on deny. | **NEW** |
| `Accrue.Live.Entitlements` | LiveView `on_mount` gate. Conditionally compiled. `on_mount {Accrue.Live.Entitlements, {:require_feature, "api_access"}}`. | **NEW (cond-compiled)** |
| `Accrue` | Thin convenience delegates (`Accrue.entitled?/2`, `Accrue.has_active_plan?/2`). | **MODIFIED** (currently moduledoc-only) |
| `Accrue.Config` | New `:plans` (plan→feature map) + `:entitlements` (resolver/source/sync flags) schema keys + accessors. | **MODIFIED** |
| `Accrue.Processor.Capabilities` | New `entitlements:` rows in `@support_labels` + `@provider_support_labels`. | **MODIFIED** |
| `Accrue.Webhook.DefaultHandler` | New clause for `entitlements.active_entitlement_summary.updated` → cache upsert. | **MODIFIED (optional path)** |
| `AccrueAdmin … CustomerLive` | New "Entitlements" tab listing resolved features for a customer. | **MODIFIED** |
| `Accrue.Events` | Reused unchanged — records `entitlement.granted` / `entitlement.revoked`. | **REUSED** |

---

## Recommended Project Structure

```
accrue/lib/accrue/
├── entitlements.ex                 # NEW  public context + span_entitlement helper
├── entitlements/
│   ├── resolver.ex                 # NEW  @behaviour (resolve/2, capabilities optional)
│   ├── local_map.ex                # NEW  default resolver (config :plans fold)
│   ├── stripe_native.ex            # NEW  cache-table resolver (+ future Stripe API)
│   ├── grant.ex                    # NEW  optional Ecto schema (cache row)
│   └── plan.ex                     # NEW  small struct: %{plan_id, features :: MapSet}
├── plug/
│   └── require_entitlement.ex      # NEW  core Plug guard (lives next to existing plugs)
├── live/
│   └── entitlements.ex             # NEW  on_mount guard, Code.ensure_loaded? guarded
├── config.ex                       # MODIFY  add :plans + :entitlements schema keys
├── processor/capabilities.ex       # MODIFY  add entitlements rows
└── webhook/default_handler.ex      # MODIFY  add summary.updated clause (optional)

accrue/priv/repo/migrations/
└── XXXXXX_create_accrue_entitlement_grants.exs   # NEW (optional cache; gated install)

accrue_admin/lib/accrue_admin/live/
└── customer_live.ex                # MODIFY  add Entitlements tab

accrue/guides/
└── entitlements.md                 # NEW  guide + JTBD ⛔→✅ flip
```

### Structure Rationale

- **`entitlements/` as a sibling of `billing/`, not inside it.** Entitlements is a *read-over-billing* concern with its own context boundary (mirrors how `Accrue.Connect`, `Accrue.Checkout`, `Accrue.BillingPortal` are top-level contexts, not `Billing.*` submodules). It depends on `Billing.Subscription` / `Billing.Query` but billing must never depend on it.
- **`plug/require_entitlement.ex` next to `put_operation_id.ex` / `put_connected_account.ex`.** The Plug guard belongs in core because `plug` is a hard dep (`~> 1.16`) and Plug guards work with plain controllers — no Phoenix or LiveView required.
- **`live/entitlements.ex` as a single conditionally-compiled file.** See the LiveView-free reconciliation below — this is the one piece that touches the LiveView socket lifecycle, so it is wrapped exactly like `Accrue.Integrations.Sigra`.
- **`grant.ex` optional + migration gated.** Hosts on pure local-mapping never need the table. Only Stripe-sync adopters run the migration, matching how Accrue gates other optional install steps.

---

## Architectural Patterns

### Pattern 1: Hybrid model — static config is source of truth, cache table is an overlay

**What:** The plan→feature mapping is host-declared **static config** validated by `nimble_options`,
exactly like the existing `:plan_resolver` / `:branding` keys. An optional `accrue_entitlement_grants`
table caches Stripe-derived entitlement summaries for the Stripe-native source only.

**When to use:** Always declare the static map. Add the cache only if the host turns on Stripe sync.

**Trade-offs:** Static config means zero DB hit and zero staleness for the common case; the cost
is that plan→feature changes require a deploy (acceptable — these are product-shaped, low-churn).
The cache adds a staleness window for Stripe-managed features but enables Stripe-Dashboard-driven
catalogs without redeploy.

**Why config and not a first-class table for the mapping itself:** This matches the PROJECT.md
config-vs-runtime boundary. Plan→feature mapping is *adapter/catalog-shaped* (stable per-deploy),
which the PROJECT.md table places at compile-time-OK / `config/config.exs`. Putting the *mapping*
in a table would (a) invent a CRUD surface Accrue has deliberately avoided for catalog data, and
(b) duplicate what `lattice_stripe` Product/Price + Stripe's own feature catalog already own.
Subscription→plan linkage is the **runtime** half and already lives in the DB (`SubscriptionItem.price_id`).

**Example (host config — new `:plans` key):**
```elixir
# config/config.exs  (compile-time-OK; product-shaped, low churn)
config :accrue, :plans, %{
  "price_pro_monthly"   => %{plan: "pro",  features: ["api_access", "seats", "exports"]},
  "price_pro_yearly"    => %{plan: "pro",  features: ["api_access", "seats", "exports"]},
  "price_basic_monthly" => %{plan: "basic", features: ["api_access"]}
}

# config/runtime.exs  (toggleable)
config :accrue, :entitlements,
  resolver: Accrue.Entitlements.LocalMap,   # or .StripeNative
  stripe_sync: false                         # opt-in cache from webhook
```

### Pattern 2: Resolver behaviour mirrors the Processor capability/support-matrix pattern

**What:** A new `Accrue.Entitlements.Resolver` behaviour with one required callback
`resolve/2`, dispatched at runtime via config — identical in shape to how `Accrue.Processor`,
`Accrue.Auth`, and `Accrue.PlanResolver` resolve their impl via `Application.get_env/3` at call time.
Provider honesty is expressed through new rows in `Accrue.Processor.Capabilities` rather than
a parallel matrix.

**When to use:** This is the seam that keeps the gate provider-agnostic. `LocalMap` works for
every processor (Fake, Braintree, Stripe); `StripeNative` is opt-in for Stripe shops who want
Stripe to own the feature catalog.

**Trade-offs:** One more behaviour to document, but it buys the exact provider-honest story the
rest of Accrue ships: "Stripe native where available; local mapping for Braintree/Fake."

**Example (capability rows — added to `Accrue.Processor.Capabilities`):**
```elixir
# @support_labels
entitlements: %{
  local_mapping:    "all first-party",
  stripe_native:    "official Stripe-native source",
  webhook_sync:     "official Stripe-native source"
}

# @provider_support_labels
entitlements: %{
  resolve: %{
    fake:      "testing/local-only",
    stripe:    "local mapping (native source optional)",
    braintree: "local mapping"
  },
  webhook_sync: %{
    fake:      "n/a",
    stripe:    "native (entitlements.active_entitlement_summary.updated)",
    braintree: "unsupported"
  }
}
```

### Pattern 3: Gate read path folds existing local state — never a processor call

**What:** `entitled?/2` and `has_active_plan?/2` resolve from the subscription projection Accrue
already maintains via webhook ingest. The resolver loads the customer's **active** subscriptions
(`Accrue.Billing.Query.active/1`, which already encodes the `:active`+`:trialing` semantics and is
documented as "active for entitlement purposes"), reads each `SubscriptionItem.price_id`, and folds
those through the `:plans` map into a `MapSet` of features.

**When to use:** Every gate check. This is the single most important performance decision —
gate checks happen per-request and per-LiveView-mount, so they must be a local query (or cheaper).

**Trade-offs:** A naive implementation does one subquery per check (customer's active subs + items).
Mitigations below in Scaling. The benefit is correctness-by-reuse: the same `active?` edge cases
(`cancel_at_period_end` still active, `incomplete_expired` terminated, trialing entitled) that
`Subscription`/`Query` already handle apply automatically — no second source of truth for "active."

**Example (resolver core, LocalMap):**
```elixir
def resolve(billable, _opts) do
  with {:ok, customer} <- Accrue.Billing.customer(billable) do
    plans = Accrue.Config.plans()                       # %{price_id => %{plan, features}}
    features =
      Subscription
      |> Query.active()
      |> where([s], s.customer_id == ^customer.id)
      |> join(:inner, [s], i in SubscriptionItem, on: i.subscription_id == s.id)
      |> select([_s, i], i.price_id)
      |> Repo.all()
      |> Enum.flat_map(fn pid -> get_in(plans, [pid, :features]) || [] end)
      |> MapSet.new()
    {:ok, %{features: features, plans: ...}}
  end
end
```

---

## Reconciling the LiveView-free constraint (the load-bearing question)

**Constraint:** PROJECT.md / CLAUDE.md state core `accrue` is "LiveView-FREE" and `accrue_admin`
owns LiveView. Yet `accrue/mix.exs` line 80 already declares `{:phoenix_live_view, "~> 1.1"}` as a
**non-optional** dep — used only for `Phoenix.Component` + the `~H` sigil in the shared invoice
component library, **not** for the LiveView socket runtime / `on_mount` lifecycle. `:phoenix` itself
is `optional: true`.

**Reading of the real constraint:** "LiveView-free" means *core must not require a host to run
LiveView, and must not couple its public APIs to the LiveView socket lifecycle.* It does **not** mean
"`phoenix_live_view` must be absent from `mix.lock`." So the precise rule for the `on_mount` guard:
it must compile and load fine in a host that has no LiveView, and must not be referenced by any
always-compiled core code path.

**Recommendation — ship BOTH guards from core, with the `on_mount` guard conditionally compiled:**

1. **Plug guard → unconditional core module** (`Accrue.Plug.RequireEntitlement`). `plug ~> 1.16`
   is a hard dep; controllers don't need Phoenix or LiveView. No conditional compile needed.

2. **LiveView guard → conditionally compiled core module** (`Accrue.Live.Entitlements`), wrapped
   exactly like `Accrue.Integrations.Sigra`:
   ```elixir
   if Code.ensure_loaded?(Phoenix.LiveView) do
     defmodule Accrue.Live.Entitlements do
       import Phoenix.LiveView, only: [redirect: 2]
       import Phoenix.Component, only: [assign: 3]

       def on_mount({:require_feature, feature}, _params, _session, socket) do
         billable = socket.assigns[:current_user] || socket.assigns[:current_scope]
         if Accrue.Entitlements.entitled?(billable, feature),
           do: {:cont, socket},
           else: {:halt, redirect(socket, to: deny_path())}
       end
       # {:require_plan, plan} clause analogous
     end
   end
   ```
   Because the whole `defmodule` is elided when LiveView is absent, a host that does not run
   LiveView never compiles a reference to `Phoenix.LiveView` from this path. The
   `@compile {:no_warn_undefined, [Phoenix.LiveView]}` guard (per the existing 4-pattern) silences
   warnings. This is the *same* pattern the codebase already uses for `:sigra` and `:opentelemetry`.

**Why not put the `on_mount` guard in `accrue_admin`?** Because the guard is for **host** LiveViews
(the SaaS app's own gated pages), not admin pages. Putting it in `accrue_admin` would force every
host that wants route-gating to depend on the admin package — wrong layering. The conditional-compile
keeps it in core, available to any host that runs LiveView, without imposing LiveView on hosts that
don't.

**Host consumption:**
- Plug guard: in the host's controller/router pipeline —
  `plug Accrue.Plug.RequireEntitlement, feature: "api_access"`.
- `on_mount` guard: in the host's `live_session` —
  `live_session :app, on_mount: [{Accrue.Live.Entitlements, {:require_feature, "api_access"}}]`.

---

## Data Flow

### Gate-check flow (the hot path — no processor API)

```
Controller plug / LiveView on_mount / HEEx `if`
        ↓
Accrue.entitled?(billable, "api_access")           (delegate)
        ↓
Accrue.Entitlements.entitled?/2  → span_entitlement [:accrue, :entitlements, :check, :evaluate]
        ↓
Resolver.resolve(billable, opts)   (LocalMap default)
        ↓
Accrue.Billing.customer/1 (cached row)
        ↓
Query.active/1 + join SubscriptionItem  → [price_id, …]   (LOCAL DB read)
        ↓
fold through Config.plans() map → MapSet(features)
        ↓
MapSet.member?(features, "api_access")  → boolean
```
No event recorded on a check (checks are high-frequency and read-only; recording them would flood
the tamper-evident ledger and defeat its signal). Telemetry `start/stop` is emitted for observability.

### Grant / revoke flow (low-frequency, ledger-recorded)

```
Accrue.Entitlements.grant(billable, "beta_feature", opts)   # comp / manual override
        ↓ span_entitlement [:accrue, :entitlements, :grant, :create]
Repo.transact:
   upsert accrue_entitlement_grants row  (source: :local)
   Events.record(%{type: "entitlement.granted", subject_type: "Customer", …})
```
`grant`/`revoke` exist for manual/comp overrides and (when sync is on) for reflecting Stripe state.
These DO record to the ledger — they are deliberate state changes, mirroring how every other
`Accrue.Billing` write records an event in the same `Repo.transact`.

### Optional Stripe-sync flow (webhook-driven cache, behind a flag)

```
Stripe → POST /webhooks/stripe  (existing raw-body plug, signature verify, persist, enqueue 200)
        ↓ existing Webhook.Ingest → DispatchWorker → DefaultHandler
DefaultHandler.handle_event("entitlements.active_entitlement_summary.updated", event, ctx)  (NEW clause)
        ↓
extract customer + entitlements[] (≤10 inline; URL for full paginated list)
        ↓
upsert accrue_entitlement_grants rows (source: :stripe, active: true/false)
        ↓
Events.record("entitlement.synced")
```
**Staleness handling:** Stripe caps the inline `entitlements` array at 10 and provides a pagination
URL for the rest (verified). For v1.39, persist the inline set and mark the cache row with the
summary timestamp; if a host has >10 features per customer, the full-list fetch is a documented
follow-up (requires the Stripe API surface the dep lacks today). The `StripeNative` resolver reads
the cache, never a live API call on the gate path.

---

## Build Order (dependency-respecting)

The ordering below is what the roadmapper should phase. Each step is shippable and unblocks the next.

1. **Config + model foundation** (no behavior yet)
   `Accrue.Config` `:plans` + `:entitlements` schema keys & accessors; `Entitlements.Plan` struct;
   `Resolver` behaviour. *Unblocks everything; pure additive config.*

2. **`Accrue.Entitlements` context + `LocalMap` resolver + `Accrue` delegates**
   `entitled?/2`, `has_active_plan?/2`, `features_for/1`, `list_entitlements/1`, wrapped in
   `span_entitlement`. Fold over `Query.active/1` + `SubscriptionItem.price_id`. Fake-backed tests.
   *This is the high-value core — gating works end-to-end with zero new infra.*

3. **Plug guard** (`Accrue.Plug.RequireEntitlement`)
   Depends on step 2. Core module next to existing plugs. Halts/redirects; telemetry. Host docs.

4. **LiveView `on_mount` guard** (`Accrue.Live.Entitlements`, conditionally compiled)
   Depends on step 2. The `Code.ensure_loaded?(Phoenix.LiveView)` wrapper + a `without_live_view`-style
   CI matrix cell proving it compiles absent LiveView. *This is the constraint-sensitive step — give it
   its own phase so the "core stays LiveView-free" gate is explicit and verifiable.*

5. **Provider-honest matrix wiring** (`Capabilities` rows + support-matrix doc + drift gate)
   Depends on step 2. Adds `entitlements:` rows to `@support_labels` / `@provider_support_labels`,
   updates `processor-support-matrix.md`, extends the existing merge-blocking drift verifier.
   *Mirrors how SCM-06 / PROC-24 closed prior provider-honest contracts.*

6. **`grant`/`revoke` + optional `accrue_entitlement_grants` cache + ledger events**
   Depends on steps 2 & 5. Adds the optional schema/migration, `StripeNative` resolver (cache-read
   only), and ledger recording. Gated install step.

7. **Optional Stripe webhook sync** (`DefaultHandler` clause)
   Depends on step 6 (needs the cache table). Behind `stripe_sync: true`. Consume
   `entitlements.active_entitlement_summary.updated` via the existing ingest pipeline.
   *Keep IN-SCOPE-BUT-OPTIONAL; document the >10-entitlements pagination limitation as a follow-up.*

8. **Admin surface** — Entitlements tab on `CustomerLive` in `accrue_admin`
   Depends on step 2 (read API) and benefits from step 6 (cache rows to show source). Token/Copy
   discipline + VERIFY-01 per the established admin pattern.

9. **Docs spine** — `guides/entitlements.md`, JTBD ⛔→✅ flip in `jobs_to_be_done.md` +
   `JTBD-FRONTIER.md` update log, First Hour / README needles, package-doc verifier.

**Critical-path note:** Steps 1→2→(3,4 in parallel)→5 deliver the headline JTBD ("gate a feature
on a paid subscription") with no new tables and no Stripe dependency. Steps 6–7 are the optional
Stripe-native depth; they should not block the milestone's core value.

---

## Scaling Considerations

| Scale | Gate read-path adjustments |
|-------|----------------------------|
| 0–1k customers | LocalMap straight query (`active subs join items`) per check is fine; sub-millisecond on indexed `customer_id`. |
| 1k–100k | Add a per-request memoization key (process dict, like `Accrue.Actor`) so multiple `entitled?` calls in one request/mount fold the customer's features once. Ensure `accrue_subscriptions(customer_id, status)` and `accrue_subscription_items(subscription_id)` indexes exist (verify in migrations). |
| 100k+ | For Stripe-sync shops, read the denormalized `accrue_entitlement_grants` cache (single indexed lookup by `customer_id, feature`) instead of the join. For local-map shops, an ETS feature cache keyed by `customer_id` invalidated on subscription webhook is the next lever — but only if profiling shows the join is hot. |

### Scaling Priorities

1. **First bottleneck:** repeated `entitled?` calls within one request/mount each re-querying.
   *Fix:* per-process memoization of the resolved feature set (cheap, no infra).
2. **Second bottleneck:** the active-subs+items join under high RPS.
   *Fix:* the optional cache table (already built for Stripe-sync) doubles as the denormalized
   read model; or ETS with webhook-driven invalidation. **Do not build either preemptively** —
   the join is correct and fast for the overwhelming majority of Accrue hosts.

---

## Anti-Patterns

### Anti-Pattern 1: Calling the processor API on the gate path

**What people do:** Resolve entitlements by hitting Stripe's List Active Entitlements API on each
`entitled?` check.
**Why it's wrong:** Per-request external HTTP = latency, rate-limit risk, and an outage in Stripe
takes down feature access. Stripe itself recommends persisting entitlements locally (verified).
**Do this instead:** Resolve from local subscription projection (default) or the synced cache table.
The processor only ever writes to local state asynchronously via webhooks.

### Anti-Pattern 2: A second source of truth for "is the subscription active?"

**What people do:** Re-implement active/trialing/canceled logic inside the entitlements layer.
**Why it's wrong:** `Subscription.active?/1` and `Query.active/1` already encode the tricky edges
(`cancel_at_period_end` still active, `incomplete_expired` terminated, trialing entitled) and are
documented as the entitlement-purposes definition. Forking it guarantees drift.
**Do this instead:** Always go through `Accrue.Billing.Query.active/1` / `Subscription.active?/1`.

### Anti-Pattern 3: Recording every gate check in the audit ledger

**What people do:** `Events.record("entitlement.checked")` on each `entitled?` call.
**Why it's wrong:** Checks are extremely high-frequency; this floods the tamper-evident ledger and
destroys its signal-to-noise (the ledger is for deliberate state changes).
**Do this instead:** Emit telemetry `start/stop` for checks (observability), record to the ledger
only for `grant`/`revoke`/`sync` (state changes), exactly as every other `Accrue.Billing` write does.

### Anti-Pattern 4: Making core depend on `phoenix_live_view` runtime for the `on_mount` guard

**What people do:** Add an unconditional `Accrue.Live.Entitlements` referencing `Phoenix.LiveView`,
or push the guard into `accrue_admin`.
**Why it's wrong:** Breaks the "host can run Accrue without LiveView" promise, or forces host route
gating to depend on the admin package.
**Do this instead:** Conditionally compile the guard in core with
`Code.ensure_loaded?(Phoenix.LiveView)` + `@compile {:no_warn_undefined, …}`, identical to the
`Accrue.Integrations.Sigra` pattern, and add a `without_live_view`-style CI matrix cell.

---

## Integration Points

### Reused (no change)

| Seam | How entitlements uses it | Notes |
|------|--------------------------|-------|
| `Accrue.Telemetry.span/3` | New `span_entitlement/4` wrapper emits `[:accrue, :entitlements, resource, action, :start/stop/exception]` | Follows the 4-level naming + OTel no-op bridge already in place |
| `Accrue.Events.record/1` | `entitlement.granted` / `.revoked` / `.synced` events in the same `Repo.transact` | Reuses idempotency + actor/trace auto-capture |
| `Accrue.Billing.Query.active/1`, `Subscription.active?/1` | Single definition of "active for entitlement purposes" | Already documented for this exact use |
| `Accrue.Billing.customer/1` | billable → Customer resolution | Lazy fetch-or-create cached row |
| Conditional-compile pattern (`Code.ensure_loaded?` + `@compile {:no_warn_undefined}`) | LiveView guard | Cloned from `Integrations.Sigra` |
| `nimble_options` `@schema` in `Accrue.Config` | `:plans` + `:entitlements` keys, docs auto-generated | Cloned from `:plan_resolver` / `:branding` |
| `Application.get_env/3` runtime dispatch | Resolver impl resolution | Same as `Processor.__impl__/0`, `Auth.impl/0` |
| Webhook ingest → `DefaultHandler` | Optional Stripe-sync clause | Existing verify→persist→enqueue→200 path untouched |

### External services

| Service | Integration pattern | Gotchas |
|---------|--------------------|---------|
| Stripe Entitlements API (List/Retrieve Active Entitlements) | **Deferred** — `lattice_stripe` 1.1.0 has **no** Entitlements module (verified: `lib/lattice_stripe/billing/` = meter/meter_event only). Live reads can't be wired until the dep adds the surface. | Until then, "Stripe-native" = consume the webhook summary into the cache; live API reads are a post-v1.39 follow-up dependent on `lattice_stripe` ≥ 1.2. |
| Stripe webhook `entitlements.active_entitlement_summary.updated` | Existing webhook plug + new `DefaultHandler` clause | Inline `entitlements` array capped at 10; pagination URL for the rest — handle the common (≤10) case now, document the overflow follow-up. |

### Internal boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `Accrue.Entitlements` → `Accrue.Billing` | Direct function calls (read-only) | One-way: billing must NOT import entitlements |
| `Accrue.Plug.RequireEntitlement` → `Accrue.Entitlements` | Direct call | Plug halts/redirects on deny |
| `Accrue.Live.Entitlements` → `Accrue.Entitlements` | Direct call (cond-compiled) | `{:cont, socket}` / `{:halt, redirect}` |
| `accrue_admin CustomerLive` → `Accrue.Entitlements.list_entitlements/1` | Public read API | Admin never bypasses the context |
| Host `:plans` config → `Accrue.Config.plans/0` | Read accessor | Compile-time-OK; product-shaped |

---

## Sources

- Accrue codebase (HIGH — read directly 2026-05-22): `accrue/lib/accrue/billing.ex` (`span_billing` pattern, `Repo.transact` + `Events.record` write pattern), `accrue/lib/accrue/processor.ex` + `processor/capabilities.ex` (behaviour + support-matrix + `@provider_support_labels`), `accrue/lib/accrue/integrations/sigra.ex` (4-pattern conditional compile), `accrue/lib/accrue/events.ex` + `telemetry.ex` (ledger + span/OTel no-op), `accrue/lib/accrue/auth.ex` + `plan_resolver.ex` + `config.ex` (runtime dispatch + nimble_options schema), `accrue/lib/accrue/billing/subscription.ex` + `query.ex` + `subscription_item.ex` (active-for-entitlement predicates + `price_id` data path), `accrue/lib/accrue/plug/*` + `router.ex` + `webhook/handler.ex` + `default_handler.ex`, `accrue_admin/lib/accrue_admin/auth_hook.ex` (existing `on_mount`), `accrue/mix.exs` (phoenix optional, phoenix_live_view present for components), `accrue/deps/lattice_stripe/lib/lattice_stripe/billing/` (no Entitlements module — verified absence).
- `.planning/PROJECT.md` (HIGH): v1.39 goal/scope, config-vs-runtime boundary table, conditional-compilation section, monorepo layout, "ship complete" posture, PROC-08 provider-honest strategy.
- `.planning/research/JTBD-FRONTIER.md` (HIGH): entitlements as #1 gap, canonical SaaS loop, "gates on subscription state already held locally," SEED-002 #4 adapter-thin identity tie-in.
- Stripe Entitlements docs + webhook semantics (MEDIUM — official docs, May 2026): Active Entitlement object, `entitlements.active_entitlement_summary.updated` fires on customer entitlement change, ≤10 inline entitlements + pagination URL, Stripe recommends persisting locally. https://docs.stripe.com/billing/entitlements · https://docs.stripe.com/api/entitlements/active-entitlement · https://docs.stripe.com/api/events/types

---
*Architecture research for: Entitlements / Plan-Gating integration into Accrue (v1.39)*
*Researched: 2026-05-22*
