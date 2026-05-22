# Stack Research — Entitlements / Plan-Gating (v1.39)

**Domain:** Feature/access gating layer on top of an existing Elixir/Phoenix billing library
**Researched:** 2026-05-22
**Confidence:** HIGH (lattice_stripe verdict and LiveView-free constraint verified against source; versions verified live on Hex)

## TL;DR for the roadmapper

- **No new runtime dependency is required to ship entitlements.** The core gate API, Plug guard, LiveView `on_mount` guard, admin view, and Stripe-webhook consumption are all buildable on Accrue's *existing* dependency matrix.
- **lattice_stripe 1.1.0 does NOT expose Stripe's Entitlements API** (no `Feature` / `ProductFeature` / `ActiveEntitlement` resource modules, no entitlement-typed structs). **Verified by reading the published sibling source** — zero matches for `entitlement` anywhere in `lib/` or `guides/`.
- **But lattice_stripe does NOT block the integration**, because (a) its `%Event{}` is type-agnostic and already delivers the `entitlements.active_entitlement_summary.updated` webhook as a valid event today, and (b) its `LatticeStripe.Request` + `LatticeStripe.Client.request/2` raw-API escape hatch is public and first-class, so any `/v1/entitlements/*` path is callable now.
- **Recommendation: ship entitlements as a LOCAL-first layer derived from subscription→plan state (option c), with optional Stripe sync via the raw-API escape hatch + generic webhook (a thin slice of option b), and defer typed lattice_stripe Entitlements resource modules to a separate upstream contribution (option a) that is NOT on this milestone's critical path.**
- **The LiveView `on_mount` guard requires NO new dependency.** It ships behind the **same `optional: true` + conditional-compilation pattern Accrue already uses for `sigra` and `opentelemetry`** — `phoenix_live_view` stays optional in core (it is already a hard dep only in `accrue_admin`).

## The two must-answer questions, answered

### Q1 — Does lattice_stripe `~> 1.1` expose Stripe's Entitlements API? → **NO.**

**Verdict: NO — verified against source, not inferred.** lattice_stripe's latest Hex release is **1.1.0** (confirmed live on the Hex API; the local sibling at `/Users/jon/projects/lattice_stripe` is also `@version "1.1.0"`).

Evidence (read directly from `/Users/jon/projects/lattice_stripe`):

- `grep -ril "entitlement" lib guides` → **zero matches.**
- `grep -ril "active_entitlement_summary"` across the repo → **zero matches.**
- The `lib/lattice_stripe/billing/` tree contains only `Meter`, `MeterEvent`, `MeterEventAdjustment`, `MeterEventStream`, `BillingPortal` (+ `guards.ex`). No `Feature`, no `ProductFeature`, no `ActiveEntitlement` resource modules exist.
- The top-level resource set covers Customer, Subscription, Invoice, Price, Product, Coupon, PromotionCode, Charge, PaymentIntent, etc. — but there is **no entitlements resource and no `Product.list_features` / customer-entitlement endpoint**.

This matches the PROJECT.md note that lattice_stripe historically lags on newer Billing objects (Meters/MeterEvents only arrived in 1.1; Entitlements have not arrived at all).

**Crucially, "NO typed support" does not mean "blocked." Two existing seams make the integration possible with zero lattice_stripe changes:**

1. **Webhook consumption already works.** `LatticeStripe.Webhook.construct_event/3` calls `LatticeStripe.Event.from_map/1`, which is documented as *"Always succeeds (infallible)"* and keeps `data` as a raw map regardless of `type`. So Stripe's `entitlements.active_entitlement_summary.updated` arrives **today** as a fully valid `%LatticeStripe.Event{type: "entitlements.active_entitlement_summary.updated", data: %{...}}`. Accrue's existing `use Accrue.Webhook.Handler` pattern-matches on the type string — no new struct needed to consume the optional sync webhook.

2. **The raw Stripe API is a public, first-class escape hatch.** `LatticeStripe.Request` is *"part of the public API"* and `LatticeStripe.Client.request/2` (and `request!/2`) dispatch any `%Request{method:, path:, params:}` through the same retry / idempotency / `:telemetry` pipeline that the typed resource modules use. So Accrue can call `GET /v1/entitlements/features`, `GET /v1/products/:id/features`, `POST /v1/products/:id/features`, and `GET /v1/customers/:id/active_entitlements` **right now** without waiting on upstream. The client's default `api_version` is already `2026-03-25.dahlia`, far past Entitlements GA (April 2024).

**Recommendation (a vs b vs c):**

> **Ship LOCAL-first (c) as the always-on core, add a thin Stripe-sync slice via the raw-API + generic webhook (a narrow part of b) as the provider-honest Stripe path, and treat typed upstream resource modules (a) as a nice-to-have follow-up that is explicitly OFF the critical path.**

Rationale:

- **Local-first is mandatory regardless**, because the milestone is provider-honest across **Stripe + Braintree + Fake**. Braintree and Fake have no Stripe Entitlements API at all, so the entitlement model *must* be derivable from local subscription→plan→feature mapping. This is also the JTBD-FRONTIER's stated leverage: *"Subscription state already exists locally — this is a thin, high-leverage layer, not a new domain."* The local layer is the source of truth for `has_active_plan?` / `entitled?` and works identically across all three processors.
- **Raw-API + generic webhook (thin b)** is the right Stripe-native sync path because it needs no upstream release, carries no version-coupling risk, and reuses lattice_stripe's existing retry/telemetry/idempotency. The Stripe path becomes: consume `entitlements.active_entitlement_summary.updated` to invalidate/refresh a cached active-entitlement projection, optionally backed by an on-demand `GET /v1/customers/:id/active_entitlements` call through `Client.request/2`.
- **Typed upstream (a)** — contributing `LatticeStripe.Entitlements.{Feature,ProductFeature,ActiveEntitlement}` resource modules upstream is genuinely valuable for the ecosystem and would let Accrue drop the raw-`%Request{}` calls later, but it is a **separate, larger effort with its own release cadence**. Putting it on the v1.39 critical path would couple Accrue's milestone to a lattice_stripe minor release. Wrap the raw calls behind a private `Accrue.Billing.Stripe.Entitlements` adapter module so that swapping to typed lattice_stripe functions later is an internal refactor, not an API change. Recommend filing it as a deferred upstream contribution (SEED-style note), not a v1.39 dependency.

### Q2 — Are any new deps needed for the Plug guard or the LiveView `on_mount` guard? → **NO.**

**Plug guard (`require_plan` / `require_feature`):** No new dependency. `plug` (latest **1.19.2**) is already present transitively via Phoenix (`phoenix ~> 1.8` pulls `plug ~> 1.16`+). A guard plug is an ordinary module implementing `init/1` + `call/2` that calls the core gate API (`Accrue.entitled?/2` etc.) and halts/redirects on failure. Accrue already ships a Plug (`Accrue.Webhook.Plug`), so the pattern and the transitive `plug` dep are established. **Add nothing.**

**LiveView `on_mount` guard:** No new *required* dependency, and the "keep core LiveView-free" constraint is honored by using the **exact conditional-compilation pattern Accrue already uses for `sigra` and `opentelemetry`**:

- `phoenix_live_view` is declared `optional: true` in `accrue/mix.exs` (it is *already* a hard dep only in `accrue_admin`; core has no LiveView dep today). Latest stable on Hex is **1.1.30**; pin `~> 1.1` to match the constraint `accrue_admin` already uses. Do **not** make it a required dep of core.
- The `Accrue.Entitlements.LiveView` (or `Accrue.Live.EntitlementGuard`) module guards itself at `use`/compile time with `Code.ensure_loaded?(Phoenix.LiveView)` / `Application.compile_env`, identical to the documented `Accrue.Integrations.Sigra` guard. `on_mount/4` is a plain function that returns `{:cont, socket}` / `{:halt, redirect(...)}` — it only references `Phoenix.LiveView`/`Phoenix.Component` symbols inside the conditionally-compiled body, so core compiles cleanly with or without LiveView present.
- Host apps that want the LiveView guard already have `phoenix_live_view` in their own deps (it's a LiveView app); Accrue's optional declaration just lets the helper compile against it without forcing it on headless/API-only hosts.

**Net:** the LiveView guard ships behind an `optional: true` entry for `phoenix_live_view` in core (the *same* mechanism already in the matrix for `sigra`/`opentelemetry`) — not a new dependency, just one optional declaration added to core's `deps/0`.

## Recommended Stack

### Core Technologies (all ALREADY in Accrue's matrix — nothing added)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `:ecto` / `:ecto_sql` / `:postgrex` | `~> 3.13` / `~> 3.13` / `~> 0.22` | Local entitlement model: `plan → feature/quota` mapping table + active-entitlement projection cache | Already the domain-modeling spine. Entitlements is a thin schema + queries over data Accrue already holds. No new persistence tech. |
| `:lattice_stripe` | `~> 1.1` (Hex 1.1.0) | Stripe-native sync via raw-API escape hatch (`Client.request/2`) + generic `%Event{}` webhook consumption | Already required. Its public `Request`/`Client.request/2` and type-agnostic `%Event{}` cover the entire optional Stripe-sync path with **no upstream change required**. |
| `:oban` | `~> 2.21` | Async refresh of the active-entitlement projection on `entitlements.active_entitlement_summary.updated` (and optional reconcile sweep) | Already required; webhook handlers already enqueue Oban jobs. Entitlement sync reuses the existing webhook→Oban path. |
| `:telemetry` | `~> 1.3` | `[:accrue, :entitlements, :check, :start/stop/exception]` spans on every gate call | Already required; PROJECT.md mandates telemetry on all public entry points. Entitlement checks must emit spans like every other facade fn. |
| `:nimble_options` | `~> 1.1` | Validate host-declared plan→feature config schema | Already required and is the established config-validation + docs-generation path (`Accrue.Config`). The plan→feature map is config; validate it here. |
| `:plug` | `~> 1.16` (Hex 1.19.2) | `require_plan` / `require_feature` controller guard | Already transitive via `phoenix ~> 1.8`. A guard plug is `init/1` + `call/2`; mirrors existing `Accrue.Webhook.Plug`. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:phoenix_live_view` | `~> 1.1` (Hex stable 1.1.30) — **declared `optional: true` in core** | `Accrue.Entitlements.LiveView.on_mount/4` route-level guard | Only loaded when the host is a LiveView app; conditionally compiled like `sigra`. Keeps core LiveView-free for headless/API hosts. Already a hard dep in `accrue_admin` (which renders the admin entitlements view). |
| `:sigra` | `~> 0.1` (`optional: true`, already in matrix) | Map a gate check onto host session identity (`Accrue.entitled?(current_user, ...)`) | Adapter-thin only. Per the milestone scope, keep coupling shallow — Accrue never owns the user schema; Sigra/Lockspire stay optional adapters. |

### Development Tools (already in matrix — no change)

| Tool | Purpose | Notes |
|------|---------|-------|
| `:stream_data` `~> 1.3` | Property-test the plan→feature resolution + quota/seat-count edges | Already required for money math; reuse for entitlement-resolution invariants (e.g., "active sub ⇒ entitled to mapped features"). |
| `:mox` `~> 1.2` | Mock the Stripe-sync adapter behaviour in entitlement tests without hitting Stripe | Already the decided test-double approach; the Fake processor lane proves entitlements deterministically. |

## Installation

No new packages. The only `mix.exs` change is adding **one optional declaration** to core `accrue/deps/0` (it is already present in `accrue_admin` as a hard dep):

```elixir
# accrue/mix.exs — deps/0 (NEW entry; everything else unchanged)
{:phoenix_live_view, "~> 1.1", optional: true},

# Already present in accrue/deps/0 — reused, not added:
# {:lattice_stripe, "~> 1.1"}
# {:oban, "~> 2.21"}
# {:ecto_sql, "~> 3.13"}, {:postgrex, "~> 0.22"}
# {:telemetry, "~> 1.3"}, {:nimble_options, "~> 1.1"}
# {:sigra, "~> 0.1", optional: true}
# plug arrives transitively via {:phoenix, "~> 1.8"}
```

Conditional-compilation skeleton (mirrors the documented `Accrue.Integrations.Sigra` pattern in PROJECT.md):

```elixir
defmodule Accrue.Entitlements.LiveView do
  @moduledoc "on_mount/4 entitlement guard. No-op unless Phoenix.LiveView is loaded."
  if Code.ensure_loaded?(Phoenix.LiveView) do
    def on_mount(plan_or_feature, _params, session, socket) do
      # references Phoenix.LiveView / Phoenix.Component only inside this branch
      ...
    end
  else
    def on_mount(_plan_or_feature, _params, _session, socket), do: {:cont, socket}
  end
end
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Raw-API via `LatticeStripe.Client.request/2` for Stripe entitlement reads | Contribute typed `LatticeStripe.Entitlements.*` resource modules upstream (option a) | Worth doing as a *follow-up* ecosystem contribution, OR if a future milestone needs ergonomic typed structs across many entitlement calls. Keep it OFF the v1.39 critical path to avoid coupling the milestone to a lattice_stripe release. Hide raw calls behind a private adapter so the later swap is internal. |
| Local plan→feature mapping as source of truth | Stripe Entitlements as the canonical source everywhere | Only viable for Stripe-only deployments; breaks provider-honesty for Braintree/Fake. Local-first is required for the multi-provider matrix. Use Stripe sync as an *overlay/refresh signal*, not the sole source. |
| `phoenix_live_view` as `optional: true` in core + conditional compilation | Move the LiveView guard entirely into `accrue_admin` | Acceptable fallback, but worse DX: host apps want `on_mount` guards on *their own* LiveViews, not just admin. `accrue_admin` is operator-facing, not host-route-facing. Optional-in-core is the right home for a host-consumable guard. |
| `:telemetry` events on gate checks | Stripe-side metering of entitlement checks | Not applicable — gate checks are local/hot-path; instrument with telemetry, never a network call per check. |

## What NOT to Use / NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Any auth/identity dependency (ueberauth, phx.gen.auth as a dep, a user schema) | Accrue never owns the user/identity model — explicit project constraint and milestone scope ("keep adapter-thin"). | Host owns identity; Accrue gate fns take an opaque billable/owner. Sigra/Lockspire stay `optional: true` adapters. |
| Making `phoenix_live_view` a **required** core dep | Breaks the hard "core `accrue` stays LiveView-free" constraint for headless/API-only hosts. | `optional: true` + `Code.ensure_loaded?/1` conditional compilation (same as `sigra`/`opentelemetry`). |
| A dedicated authorization/policy library (e.g., a Bodyguard/LetMe-style dep) | Over-engineers a billing gate. Entitlement checks are simple boolean/quota lookups against local state; a policy framework adds a dependency and a second mental model for no benefit. | Plain functions on `Accrue` + a Plug + an `on_mount` returning `{:cont, ...}`/`{:halt, ...}`. |
| Pinning to lattice_stripe `1.2`/typed Entitlements as a hard requirement | That version does not exist on Hex; would block the milestone on an unreleased upstream. | `~> 1.1` (1.1.0) + raw-API escape hatch + generic webhook, which work today. |
| A cache dependency (Cachex/Nebulex) for the active-entitlement projection | Premature; the projection can live in Postgres (already present) and be refreshed by the existing webhook→Oban path. Adds an unneeded dep + cache-invalidation surface. | Postgres-backed projection table refreshed on `active_entitlement_summary.updated`; add an ETS/cache layer only if a sourced perf need appears (intake-gated per stop rule S1). |
| `stripity_stripe` for the entitlement calls | 2019-era API pin; the exact gap Accrue replaced lattice_stripe to avoid. | `lattice_stripe` raw-API `Client.request/2`. |

## Stack Patterns by Variant

**If processor == Stripe:**
- Local plan→feature map is the always-on source; optionally overlay Stripe's active-entitlement projection.
- Consume `entitlements.active_entitlement_summary.updated` (generic `%Event{}`) → enqueue Oban refresh → optionally `GET /v1/customers/:id/active_entitlements` via `Client.request/2`.
- All raw calls behind a private `Accrue.Billing.Stripe.Entitlements` adapter.

**If processor == Braintree or Fake:**
- Pure local plan→feature mapping; no external entitlement source exists. This is the deterministic Fake proof lane and the Braintree path. Provider-honest matrix labels: Stripe "native sync available", Braintree/Fake "local mapping".

**If host is headless / API-only (no LiveView):**
- `phoenix_live_view` not loaded; `Accrue.Entitlements.LiveView.on_mount/4` compiles to a no-op/`{:cont}` branch. Core stays LiveView-free. The Plug guard + core gate API still work.

## Version Compatibility

| Package | Version | Notes |
|---------|---------|-------|
| `lattice_stripe` | `~> 1.1` (Hex 1.1.0 = local sibling) | No entitlements resource modules; raw-API + generic `%Event{}` cover the need. Client `api_version` default `2026-03-25.dahlia` ≥ Entitlements GA (Apr 2024). |
| `phoenix_live_view` | `~> 1.1` (Hex stable **1.1.30**; 1.2.0 still RC) | Matches the constraint `accrue_admin` already uses. Declare `optional: true` in core. Avoid 1.2.x until stable. |
| `plug` | `~> 1.16` (transitive; Hex **1.19.2**) | Already pulled by `phoenix ~> 1.8`. Guard plug needs nothing newer. |
| `oban` | `~> 2.21` | Webhook→Oban refresh path reuses existing wiring; no change. |
| `ecto`/`ecto_sql`/`postgrex` | `~> 3.13` / `~> 3.13` / `~> 0.22` | Projection + mapping tables; no new extensions (gen_random_uuid in PG 14 core). |

## Sources

- `/Users/jon/projects/lattice_stripe` source (read directly, HIGH confidence): `mix.exs` `@version "1.1.0"`; `lib/lattice_stripe/billing/` tree (Meter/MeterEvent only); `lib/lattice_stripe/event.ex` (`from_map/1` infallible, type-agnostic `data`); `lib/lattice_stripe/request.ex` + `lib/lattice_stripe/client.ex` (`request/2` public, `api_version: "2026-03-25.dahlia"`); `grep -ri entitlement` and `grep -ri active_entitlement_summary` → zero matches.
- Hex.pm API, live 2026-05-22 (HIGH confidence): `lattice_stripe` latest = **1.1.0**; `phoenix_live_view` latest stable = **1.1.30** (latest = 1.2.0-rc.2); `plug` latest stable = **1.19.2**.
- `.planning/PROJECT.md` (HIGH): conditional-compilation pattern for optional deps (`Accrue.Integrations.Sigra`), "core stays LiveView-free", `phoenix_live_view` hard only in `accrue_admin`, milestone v1.39 scope + "no new external dependency for the core."
- `.planning/research/JTBD-FRONTIER.md` (HIGH): entitlements is the #1 gap; "subscription state already exists locally — thin, high-leverage layer."
- `.planning/seeds/SEED-002-ecosystem-integrations.md` #4 (HIGH): Sigra/Lockspire identity tie-in stays optional/adapter-thin.
- [Stripe Entitlements docs](https://docs.stripe.com/billing/entitlements), [Feature API](https://docs.stripe.com/api/entitlements/feature), [Product Feature API](https://docs.stripe.com/api/product-feature), [Active Entitlement object](https://docs.stripe.com/api/entitlements/active-entitlement/object), [List active entitlements](https://docs.stripe.com/api/entitlements/active-entitlement/list) (MEDIUM-HIGH): `Feature` / `ProductFeature` / `ActiveEntitlement` objects + `entitlements.active_entitlement_summary.updated` webhook confirmed.
- [Stripe Sessions 2024 updates](https://stripe.com/blog/biggest-updates-sessions-2024), [Managing SaaS access control with Stripe Entitlements](https://stripe.dev/blog/managing-saas-access-control-with-stripe-entitlements-api) (MEDIUM): Entitlements API announced Stripe Sessions 2024 (April 2024), GA by late 2024 — well before lattice_stripe's `2026-03-25.dahlia` baseline.

---
*Stack research for: Entitlements / plan-gating (Accrue v1.39)*
*Researched: 2026-05-22*
