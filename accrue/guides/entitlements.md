# Entitlements — gate features on what they paid for

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
dependency.

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

- [Lifecycle Semantics](lifecycle_semantics.md) — the SSOT for which lifecycle
  states grant entitlement (the truth `entitling?/1` encodes).
- [Telemetry](telemetry.md) — the `[:accrue, ...]` span catalog and OTel wiring
  for the `:check` event above.
- [Auth adapters](auth_adapters.md) — how `Accrue.Auth` resolves the host
  identity that the guards turn into a billable.
- **Admin entitlements view** — in `accrue_admin`, a customer's resolved active
  plans, granted features, quantities, grace state, and unmapped-plan drift are
  visible at `/customers/:id?tab=entitlements`.
