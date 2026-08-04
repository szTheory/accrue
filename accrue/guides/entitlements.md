# Entitlements — gate features on what they paid for

## Inspect an entitlement source

Use `Accrue.Entitlements.Source.Registry`, never `Accrue.Processor`, to inspect a rail's entitlement-source capability. The fixed order is `observation`, `control`, `restore`, `reconciliation`, `management`, and `offline`; the closed states are `supported`, `externally_managed`, `host_owned`, `deferred`, `unavailable`, and `feasibility_blocked`.

Apple subscription management is externally managed. Present the returned plain-language guidance and **Manage subscription** action, which links to `https://apps.apple.com/account/subscriptions`. Do not translate an Apple outcome into a Stripe cancellation, dunning, retry, swap, proration, invoice, or payment-method action. The separate [processor support matrix](../../.planning/processor-support-matrix.md) remains the gateway-control authority.

For the canonical meaning of `active`, `trialing`, `paused`, `past_due`, and
ended states — and for *which* lifecycle states grant access — see
[Lifecycle Semantics](lifecycle_semantics.md). Use that guide for the truth of
"who is entitled"; use **this** guide for how to *ask* the question and how to
*enforce* the answer in a controller, a LiveView, and your config.

Accrue's entitlement layer (`Accrue.Entitlements`, surfaced on the `Accrue`
facade) answers one question — *"what has this billable paid for?"* — from
**local subscription state only**. It makes zero processor calls on the gate
path: it reads the same local rows your webhooks already keep in sync, so a gate
check is a database read at LiveView speed, never a blocking Stripe round-trip.

> **Tagline:** one config map, one `entitled?/2` call, two thin guards. The
> truth of *who* is entitled lives in `lifecycle_semantics.md`; this guide owns
> the *how*.

---

## Additive rails and durable entitlement records

The existing `:processor` configuration is the supported legacy alias for the
single controllable billing rail. Hosts that need concurrent sources may opt in
to `:rails` and choose a controllable `:default_rail`; keep using `price_ids`
for the default rail/environment or use `products` for the explicit
rail/environment/product tuple. A product identifier is equal only with its
full qualified tuple — matching the same raw identifier on another rail or
environment is not a collision.

Apple is an entitlement source/observer. Apple does not implement `Accrue.Processor`; Stripe remains the controllable processor example. Phase 216 does not verify Apple signed material, and Phase 216 does not mutate the Apple subscription lifecycle. Hosts must retain Apple verification and lifecycle management at their own provider boundary.

### Schedule Apple reconciliation

Accrue does not start an Oban instance, a Cron plugin, or a timer. A host that
enables Apple reconciliation must add the queue and periodic worker to its
existing Oban configuration, alongside the configured Apple client and strict
admission settings:

```elixir
config :my_app, Oban,
  queues: [accrue_entitlements: 10],
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [{"*/15 * * * *", Accrue.Entitlements.Apple.ReconciliationSweeper}]}
  ]

config :accrue, :apple_reconciliation,
  client: MyApp.AppleClient.new(...),
  admission: [
    verifier: MyApp.AppleVerifier,
    verifier_config: [...],
    product_map: %{"apple_product_id" => :pro},
    verifier_version: "v1",
    config_version: "v1"
  ]
```

The Cron worker finds persisted idle checkpoints whose `next_due_at` is due,
locks each row, inserts a privacy-safe reconciliation job (lineage UUID,
environment, and bounded reason only), and marks the checkpoint running in the
same transaction. Apple status/history remains the authority; a scheduler tick
never grants access by itself. Oban uniqueness is not the execution lock.

To disable scheduled repair safely, first remove the Cron entry, then drain
queued `Accrue.Entitlements.Apple.ReconcileWorker` jobs or atomically release
any scheduler-reserved running checkpoints back to `idle`. Do not delete the
checkpoint rows or add an Accrue supervision child.

The durable projection boundary has four Accrue-owned tables:
`accrue_entitlement_accounts`, `accrue_entitlement_observations`,
`accrue_entitlement_grants`, and `accrue_entitlement_devices`. They retain
opaque account links, normalized observations, current and superseded grant
history, and revoked device history. Evidence is limited to a digest plus an
optional bounded reference and expiry; do not persist raw receipts, signed
material, provider notification bodies, adopter identity, or PII in these
records.

This foundation deliberately excludes a projector, backfill, cutover, Apple
verification, offline issuance, Google Play, Family Sharing, and provider
lifecycle mutation. Those later-phase concerns must not be inferred from the
registration or persistence schema.

---

## Getting Started — the fail-closed easy path

The whole API collapses to one boolean. Ask whether the billable has a feature,
render accordingly:

```elixir
if Accrue.entitled?(user, :pro), do: render_pro(), else: upsell()
```

That is the contract you should internalize before anything else: **the only
path to `true` is an affirmative, resolved match.** Every ambiguity fails
closed. `nil`, a non-billable, a billable with no customer, no active
subscription, an *unmapped* active plan, and even a resolver that *raises* all
collapse to `false`. A billing or availability hiccup never hands out a paid
feature for free — there is no fail-open branch anywhere in the gate path.

The scalar variants follow the same rule:

```elixir
Accrue.has_active_plan?(user, :pro)         # holds the :pro plan? (atom or price_id string)
Accrue.features_for(user)                   # => [:pro, :reports, :api]  (sorted, deduped, UNION across all active subs)
Accrue.entitlement_quantity(user, :seats)   # => 5   (0 when unmapped/absent)
```

`has_active_plan?/2` and `features_for/1` answer over the **UNION of every
active subscription** the billable holds — a customer on two active plans
answers `true` for both, and their feature sets merge. There is no
"representative plan" footgun.

---

## Configure the catalog

Entitlements are **host-declared**: you map each logical plan to the features
and quotas it grants, and to the `price_id`s that count as "holding" it. This
lives under `:entitlements` in `config/runtime.exs` and is boot-validated — a
malformed catalog (or the same `price_id` mapped to two plans) raises
`Accrue.ConfigError` at boot, never silently at request time.

```elixir
config :accrue,
  entitlements: [
    plans: [
      pro: [
        features: [:reports, :api],
        limits: [seats: 5],
        price_ids: ["price_pro_monthly", "price_pro_yearly"]
      ],
      team: [
        features: [:reports, :api, :sso],
        limits: [seats: 25],
        price_ids: ["price_team_monthly"]
      ]
    ],
    unmapped_action: :deny,
    past_due_grace: :none
  ]
```

Two knobs decide the fail-closed posture:

- **`unmapped_action:`** (default `:deny`) — what happens when a billable holds
  an *active* `price_id` that is not in any plan's `price_ids`. `:deny` fails
  closed (the unmapped plan grants nothing); `:raise` surfaces the drift loudly
  at check time. It never silently allows.
- **`past_due_grace:`** (default `:none`) — whether a `:past_due` subscription
  keeps access during dunning. `:none` fails closed immediately; `:dunning`
  reuses the dunning grace window; a positive integer `N` grants an
  entitlement-specific N-day window measured from `past_due_since` against
  `Accrue.Clock`. A grace grant is an affirmative, *configured* decision — see
  [Lifecycle Semantics](lifecycle_semantics.md#lifecycle--entitlement-truth-table)
  for the full grace-window nuance, which is the SSOT.

By default the resolver is `Accrue.Entitlements.Resolver.LocalMap`; swap it via
`resolver:` if you implement the `Accrue.Entitlements.Resolver` behaviour.

---

## Gate a controller route

For controller-level gating Accrue ships a pure Plug,
`Accrue.Plug.RequireEntitlement`, plus two router macros that are single-arg
sugar over it. Add the macros to a pipeline (or pipe-through) so a whole scope
is gated:

```elixir
# lib/my_app_web/router.ex
import Accrue.Router   # brings require_feature/1 and require_plan/1 into scope

pipeline :require_reports do
  plug :fetch_current_user            # YOUR auth runs first — it resolves the billable
  require_feature :reports            # plug Accrue.Plug.RequireEntitlement, feature: :reports
end

pipeline :require_pro do
  plug :fetch_current_user
  require_plan :pro                   # plug Accrue.Plug.RequireEntitlement, plan: :pro
end

scope "/app", MyAppWeb do
  pipe_through [:browser, :require_reports]
  live "/reports", ReportsLive
end
```

The macros expand to the explicit plug; reach for the plug form directly when
you need to override the deny behavior or the billable resolver:

```elixir
plug Accrue.Plug.RequireEntitlement,
  feature: :reports,
  on_deny: {:redirect, "/pricing"},
  billable: &MyApp.billable_for/1
```

**Deny is opaque by default.** A denied request gets a content-negotiated `403
Forbidden` whose body leaks nothing — no feature name, no plan, no subscription
state. That is deliberate: a gate should not advertise what the caller is
missing. Override per-guard via `on_deny:` (`:forbidden | {:redirect, path} |
{status, body} | fun/2 | {m, f, a}`), or globally via the `:on_deny` config key;
the precedence is per-guard opt → config global → built-in opaque 403. The
billable is resolved once per request (your `billable:` fn, else the global
`:billable` config, else a `current_scope.user → current_user → nil` probe) and
the resolver **never raises** — a miss resolves to `nil`, which fails closed.

---

## Gate a LiveView

For route-level gating of host LiveViews, the `on_mount` guard
`Accrue.Live.Entitlements` mounts the same decision engine. It is
**conditionally compiled** — it only exists when `Phoenix.LiveView` is loaded,
so core stays runtime-LiveView-free. Add it to a `live_session`, **after** your
own auth `on_mount` hook (which resolves the billable):

```elixir
# lib/my_app_web/router.ex
live_session :paid,
  on_mount: [
    MyAppWeb.UserAuth,                                   # YOUR auth FIRST
    {Accrue.Live.Entitlements, {:require_feature, :reports}}
  ] do
  live "/reports", ReportsLive
end

# Or gate on holding a whole plan:
live_session :pro,
  on_mount: [
    MyAppWeb.UserAuth,
    {Accrue.Live.Entitlements, {:require_plan, :pro}}
  ] do
  live "/admin", AdminLive
end
```

A denied mount is content-negotiated the LiveView way: a `{:redirect, path}`
deny redirects there; an opaque `:forbidden` (or non-redirectable status/body)
degrades to a flash plus a redirect to the configured `deny_path` (default
`"/"`). The billable is resolved once per mount and stashed via `assign_new`, so
nested live navigations don't re-probe. As with the plug, the only path to a
granted mount is an affirmative resolved match.

For organization-scoped gates, make your host auth/scope loader populate the
organization billable before `Accrue.Live.Entitlements` runs. If the resolver
returns `%Ecto.Association.NotLoaded{}` or another unloaded billable, Accrue
normalizes it to a fail-closed deny instead of raising; preload the organization
in your auth hook when the route should be grantable.

---

## Lifecycle truth

Entitlement is derived from `Accrue.Billing.Subscription.entitling?/1`, which
composes the lifecycle predicates (`active?/1`, `paused?/1`, `canceled?/1`) —
never raw `.status`. The reader-critical rows:

| Status / modifier | Entitled? | Basis |
|---|:---:|---|
| `:trialing` | ✅ | `active?` includes trialing |
| `:active` | ✅ | normal paid-active |
| `:active` + `cancel_at_period_end` (period future) | ✅ | paid-through |
| `:active` + `pause_collection` non-nil | ✗ | `paused?` overrides status |
| `:past_due` | ✗ default / ✅ in-grace | knob (`past_due_grace`) |
| `:canceled` / `:incomplete_expired` / any `ended_at` | ✗ | `canceled?` terminal |

This is a *summary*. The grace footnote nuance (`past_due_since`,
`Accrue.Clock`, the `:past_due_grace`/`:past_due_expired` reasons, and why
`:unpaid` never receives grace) lives in the SSOT, not here.

Canonical source:
[`lifecycle_semantics.md#lifecycle--entitlement-truth-table`](lifecycle_semantics.md#lifecycle--entitlement-truth-table)
— `entitling?/1` is the single source of truth, and every surface (this guide,
the resolver, the admin view) derives from it rather than re-deriving from
`.status`.

---

## Provider honesty

Entitlement resolution is **local-identical across Stripe, Braintree, and
Fake** — it reads local subscription state, never the processor. There is no
"Stripe-only" or "bounded on Braintree" caveat here: because the gate derives
from the local mirror your webhooks already maintain, the exact same
`Accrue.entitled?/2` call returns the byte-identical answer on every provider,
and the deterministic Fake lane is a first-class merge-blocking proof of that
convergence — not a degraded stand-in.

For the machine-readable capability surface, see `Accrue.Processor.Capabilities`
(the `entitlements:` capability group is labeled "all first-party" — the
matrix's one *convergence* lane). The optional Stripe-native entitlement sync is
a separate, off-by-default overlay; the core gate described here needs no Stripe
dependency. That overlay is the `entitlements.stripe_native_sync` capability row
(labeled **"Stripe-native advisory (observational)"**, with Stripe `native
(advisory)`, Fake out-of-slice, and Braintree unsupported) — distinct from the
`entitlements.local_mapping` convergence row above.

---

## Optional Stripe-native sync (advisory)

Everything above is **local-first and Stripe-free**. Accrue also ships an
**optional, off-by-default** path that ingests Stripe's native entitlement
summaries into a local *advisory cache*. It is **observational only** — turning
it on never changes a gate decision. This section is the operator's guide to
what it does, how to enable it, and the consistency caveats you inherit when you
do.

### What `:advisory` means — observational, not gate-influencing

> **The disclaimer, plainly: `:advisory` does NOT change `entitled?` /
> `has_active_plan?`.** When sync is enabled, Accrue records each
> `entitlements.active_entitlement_summary.updated` webhook into an advisory
> cache for **audit, telemetry, and the admin read-seam** — and nothing else.
> Local plan→feature mapping stays **canonical** in v1.x; the gate path never
> reads the cache. `entitled?` behaves byte-for-byte the same with sync ON, OFF,
> or as it did after Phase 126. The sole path to `true` is still an affirmative,
> resolved **local** match.

This is deliberate. An eventual-consistency Stripe cache that silently fed gate
decisions would be an authorization surface: a stale or partial snapshot could
hand out — or withhold — a paid feature. Keeping the overlay observational means
a cache that is stale, partial, or missing entirely **can never produce a wrong
gate answer**. (Gate-influencing semantics are reserved as a future,
non-breaking opt-in enum value — see *Deferred* below — but they are not v1.x.)

The advisory cache is exposed read-only via a core seam — the
`Accrue.Entitlements.StripeSync` module's `summary_for_customer/1` function
(one-way, internal `@doc false`) — so the recorded summary is programmatically
inspectable without ever touching the gate.

### Why there is no `fetch_entitled/2`

`fetch_entitled/2` is closed and will-not-build. A Stripe-backed predicate would
make authorization depend on a network call that can fail open under partition,
which contradicts Accrue's fail-closed local gate. The non-gate diagnostic value
is already served by `Accrue.Entitlements.StripeSync.summary_for_customer/1` and
`Accrue.Entitlements.Admin.resolve_for_customer/1`.

### How to enable it

Enabling is a **two-step opt-in** — both are required:

1. **Set the config flag.** Under `:entitlements`, set `stripe_native_sync:
   :advisory` (the default is `:disabled`, which makes the entire path inert —
   the webhook reducer early-returns before any database read):

   ```elixir
   config :accrue,
     entitlements: [
       plans: [ # ... your catalog, as above ... ],
       unmapped_action: :deny,
       past_due_grace: :none,
       stripe_native_sync: :advisory   # default :disabled
     ]
   ```

   The key is a boot-validated enum (`:disabled | :advisory`), not a boolean, so
   future modes can be appended without a breaking config change.

2. **Enable the Stripe event on your Dashboard.** This is **host-owned** — Accrue
   cannot do it for you. On your Stripe webhook endpoint (the same one Accrue
   already verifies under your `:webhook_signing_secrets`), enable the
   `entitlements.active_entitlement_summary.updated` event. Until that event is
   enabled in Stripe, no summaries arrive and the cache stays empty.

With both in place, each summary webhook is reduced into the advisory cache with
the same **monotonic skip-stale** discipline the rest of Accrue uses (older
out-of-order or replayed summaries are skipped, never clobbering newer state),
and a `entitlements.summary.synced` ledger row is recorded on each *material*
change. See [Telemetry](telemetry.md) for the full event catalog.

### The eventual-consistency window

Stripe webhooks carry **no delivery-order guarantee and no documented
propagation-lag SLA** — a summary can lag the underlying change, arrive
out-of-order, or fail delivery and retry. The advisory cache is therefore
**eventually consistent**: it can briefly trail Stripe's actual state.

This is harmless *because the cache is observational*. Local-first canonical
resolution means a stale advisory cache **never produces a wrong gate
decision** — the local subscription projection (kept in sync by
`customer.subscription.*` webhooks on the same monotonic discipline) is the
truth the gate reads. The monotonic guard guarantees the cache, once it catches
up, reflects the highest-timestamp summary regardless of delivery order. For
missed webhooks or startup reconciliation, use the client-backed refresh path
described below.

### The 10-entitlement inline cap

The summary webhook inlines **at most 10** entitlements in
`entitlements.data`, with `has_more: true` and a `url` pagination handle when a
customer holds more. Accrue records exactly what the webhook delivers and is
**honest about partiality**:

- The `has_more` flag is persisted to a typed, indexed `truncated` column, so a
  known-incomplete cache row is queryable and operator-visible.
- When `has_more: true`, Accrue fires the ops signal
  `[:accrue, :ops, :entitlement_summary_truncated]` (see
  [Telemetry](telemetry.md)) so operators can find partial caches without
  scanning.
- Because the cache is observational, a truncated (partial) summary can **never**
  cause a wrong gate decision — it is surfaced for transparency, not consulted
  for access.

### Client-backed refresh for missed webhooks and reconciliation

Accrue now ships the full client-backed read through
`Accrue.Entitlements.StripeSync.refresh/2`. When
`stripe_native_sync: :advisory` is enabled, the refresh asks the configured
processor for Stripe active entitlements and writes the same advisory cache row
as the webhook reducer. When the flag is disabled, it returns
`{:ok, :disabled}` before processor or repository I/O.

Use this path after missed webhook delivery, on operational startup
reconciliation, or when an operator wants to compare Stripe's current native
entitlement view with Accrue's local grant model:

```elixir
customer = Accrue.Repo.get!(Accrue.Billing.Customer, customer_id)
Accrue.Entitlements.StripeSync.refresh(customer)
```

Hosts that use Oban can enqueue the provided host-owned worker on the existing
webhook queue:

```elixir
%{"customer_id" => customer.id}
|> Accrue.Entitlements.StripeSync.RefreshWorker.new()
|> Oban.insert()
```

Refresh errors return through the processor result and Oban retry semantics; a
successful refresh still writes diagnostics only. The local plan→feature map
remains the only Accrue grant authority, and refreshed advisory rows never
change `entitled?/2`, `has_active_plan?/2`, controller plugs, or LiveView
guards.

---

## Telemetry

Every check emits `[:accrue, :entitlements, :check]` start/stop/exception
spans via `Accrue.Telemetry.span/3`, with metadata:

```elixir
%{feature: ..., result: true | false, resolver: ..., reason: ...,
  surface: :plug | :live | nil, subject_type: ..., subject_id: ...}
```

A few rules worth pinning:

- **`subject_id` is internal-only** — the customer/billable id, *never* an
  email, name, or any PII.
- **`reason`** carries the *why* of a deny (e.g. `:no_active_subscription`,
  `:not_entitled`, `:past_due_grace`, `:past_due_expired`) so "denied" and
  "couldn't check" are distinguishable in telemetry without leaking through the
  opaque 403.
- **`surface`** is `:plug` or `:live` when the check came from a guard, `nil`
  for a direct `Accrue.entitled?/2` call.
- **Per-check decisions are telemetry-only** — this path *never* writes to the
  `accrue_events` audit ledger. (Grant/revoke/sync lifecycle events are ledgered
  elsewhere; a per-request gate decision is not.)

---

## Related guides

## v1.59 multi-rail and offline adoption path

Use this path when a host needs the additive Stripe, Apple, and offline-study
contract. It is deliberately short: the generated matrix owns exact support
cells; this guide explains how to evaluate and operate the contract.

1. Start with the anonymized reference-host recipe in
   [`examples/accrue_host/docs/adoption-proof-matrix.md`](https://github.com/szTheory/accrue/blob/main/examples/accrue_host/docs/adoption-proof-matrix.md)
   and run its local `mix verify` proof.
2. From the repository root, run the deterministic contract check:

   ```sh
   cd accrue && mix accrue.entitlements.reference_scenarios --check
   ```

3. Read the generated
   [`capability and limits matrix`](https://github.com/szTheory/accrue/blob/main/examples/accrue_host/docs/capability-limits-matrix.md)
   for the exact supported, unsupported, privacy, and merge-authority cells.
4. If a scenario does not converge, record its stable scenario ID and follow the
   matching procedure in [Operator runbooks](operator-runbooks.md#v159-multi-rail-and-offline-runbooks).

### Evidence is deliberately split

`deterministic_conformance` is the merge-blocking semantic lane. It proves the
same account projection for Apple-to-web and Stripe-to-iOS scenarios without
claiming a mobile runtime. `runtime_capability` is a separate, non-blocking
lane; the checked-in Crosswake tracer is `feasibility_blocked` until it has the
required bridge compile/unit and physical-device evidence. Fake, browser,
simulator, and Swift-vector results do not change that status.

`advisory_parity` is non-blocking provider comparison evidence. Browser and
Playwright coverage is a complementary rendered-host check for accessible copy
and flows, not the semantic oracle for StoreKit, signed proof, offline cache
replacement, ordering, or key rotation.

### Compatibility and privacy boundary

This is additive: legacy hosts remain compatible. Apple subscriptions stay
externally managed, and Accrue does not transfer, merge, migrate, refund, or
prorate lifecycle state across rails. When an offline lease is stale, a learner
may continue downloaded study and local progress only; new value waits for a
reconnect.

Keep raw transaction data, signed proof material, tokens, PII, provider
payloads, and credential values out of diagnostics, telemetry, guides, and
support tickets. Use the bounded diagnostic's state, reason, next action, age,
and safe correlation instead.

- [Lifecycle Semantics](lifecycle_semantics.md) — the SSOT for which lifecycle
  states grant entitlement (the truth `entitling?/1` encodes).
- [Telemetry](telemetry.md) — the `[:accrue, ...]` span catalog and OTel wiring
  for the `:check` event above.
- [Auth adapters](auth_adapters.md) — how `Accrue.Auth` resolves the host
  identity that the guards turn into a billable.
- **Admin entitlements view** — in `accrue_admin`, a customer's resolved active
  plans, granted features, quantities, grace state, and unmapped-plan drift are
  visible at `/customers/:id?tab=entitlements`.
