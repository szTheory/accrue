# Phase 5: Connect - Research

**Researched:** 2026-04-15
**Domain:** Stripe Connect (marketplace payments) for Elixir/Phoenix billing library
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D5-01: Stripe-Account threading — hybrid pdict + per-call opts override.**
Three-level precedence: per-call opts > `Accrue.Connect.with_account/2` pdict > `Accrue.Config.get(:default_stripe_account)`. Mirrors existing `resolve_api_version/1` (`accrue/lib/accrue/processor/stripe.ex:820-825`). New `Accrue.Connect.current_account_id/0` mirrors `Accrue.Actor.current_operation_id/0`. New `Accrue.Plug.PutConnectedAccount` mirrors `Accrue.Plug.PutOperationId`. New `resolve_stripe_account/1` sibling of `resolve_api_version/1`. `build_client!/1` extended to pass `stripe_account:` into `LatticeStripe.Client.new!/1`. Oban middleware extended to thread `stripe_account` into job args. Fake processor scopes its ETS keyspace on `{stripe_account, resource_type}`. Sub-facade `Accrue.Connect.Billing.*` REJECTED.

**D5-02: Connected account persistence — hybrid projection.**
New `accrue_connect_accounts` table with typed columns (`stripe_account_id`, `owner_type`, `owner_id`, `type`, `country`, `email`, `charges_enabled`, `details_submitted`, `payouts_enabled`, `capabilities` jsonb, `requirements` jsonb, `data` jsonb, `deauthorized_at`). Webhook updates use `force_status_changeset/2` (D3-17). Predicates per D3-04: `charges_enabled?/1`, `payouts_enabled?/1`, `fully_onboarded?/1`, `deauthorized?/1` — never expose raw booleans through query layer. New `%Accrue.Connect.Account{}` struct is the first-class value passed to charge helpers.

**D5-03: Charge API — two distinct functions.**
`Accrue.Connect.destination_charge/2` (PLATFORM-scoped charges.create with `transfer_data: %{destination: acct}` + `application_fee_amount`) and `Accrue.Connect.separate_charge_and_transfer/2` (platform-side charge + explicit `transfers.create`). Both accept `%Account{}` or `"acct_..."` string via `resolve_account/1`. `Accrue.Connect.transfer/2` ships as separate public helper. Telemetry: `[:accrue, :connect, :destination_charge|:separate_charge_and_transfer|:transfer, :start|:stop|:exception]`. Single-function-with-mode REJECTED.

**D5-04: Platform fee helper — pure Money math.**
`Accrue.Connect.platform_fee(gross, opts) :: {:ok, Money.t()} | {:error, Error.t()}`. NimbleOptions config under `:accrue, :connect, :platform_fee` (percent + fixed + min + max). Caller explicitly injects result into charge opts as `application_fee_amount:`. Computation: round percent first (banker's rounding), add fixed, clamp min/max. StreamData property tests across JPY/USD/KWD non-negotiable. Auto-injection REJECTED. Ecto-backed per-account fee policy REJECTED (deferred to v1.x).

**D5-05: Connect webhook handler — dedicated `Accrue.Webhook.ConnectHandler`.**
New module sibling to `DefaultHandler`. Dispatcher routes via `ctx.endpoint == :connect`. Reducers for `account.updated`, `account.application.authorized`, `account.application.deauthorized` (tombstone, no hard delete), `capability.updated`, `payout.*` (events ledger only). `person.*` is passthrough ack with no local mutation. Each reducer follows DefaultHandler shape: load-or-fetch → force_status_changeset → Repo.transact + Events.record_multi → emit span. Extending DefaultHandler REJECTED.

**D5-06: AccountLink / LoginLink return shape — structs with Inspect-masked `:url`.**
`%Accrue.Connect.AccountLink{url, expires_at, created, object}` and `%Accrue.Connect.LoginLink{url, created}`. Both with `defimpl Inspect` masking `:url` as `<redacted>`. Mirrors `Accrue.BillingPortal.Session` (`accrue/lib/accrue/billing_portal/session.ex:149-178`) verbatim. Dual bang/tuple per D-05. `create_account_link/2` opts: `:return_url` (required), `:refresh_url` (required), `:type`, `:collect`. Framework-owned `return_url`/`refresh_url` route helpers REJECTED.

### Claude's Discretion

- Account type handling at onboarding (CONN-01): `type:` is a required opt with no default — host explicitly picks `:standard | :express | :custom`.
- Capability request idiom: nested-map `update/4` per lattice_stripe Phase 17 D-04b. No `request_capability/3` helper.
- `Accrue.Connect.Account.Requirements` nested struct: store jsonb verbatim, no typed mirror.
- Payout schedule config (CONN-08): passthrough nested-map `update/4`, no helper.
- LoginLink vs Account retrieve dashboard URL: ship LoginLink only (Express-only).
- Ops telemetry: `[:accrue, :ops, :connect_account_deauthorized | :connect_capability_lost | :connect_payout_failed]`.
- Test fixtures: `Accrue.Test.Factory.connect_account/1` with Standard/Express/Custom + fully_onboarded/partially_onboarded presets.

### Deferred Ideas (OUT OF SCOPE)

- Ecto-backed per-account fee policy table (v1.x).
- Framework-owned `return_url`/`refresh_url` route helpers (rejected — host owns Phoenix router).
- `Accrue.Connect.request_capability/3` helper (rejected — capability names are an open enum).
- Dedicated `accrue_connect_payouts` schema (v1.x — events ledger only in v1.0).
- Custom-type `person.*` webhook persistence (v1.x — passthrough ack only in v1.0).
- Standard-type dashboard redirect helper (rejected — no Stripe-blessed shortcut).
- `Accrue.Connect.Account.Requirements` typed nested struct (rejected — jsonb verbatim).
- `Accrue.Connect.Billing.*` sub-facade (rejected — doubles API surface).
- OAuth-based Connect onboarding (rejected — Account Links only, modern Stripe guidance).

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROC-05 | Stripe Connect context (Stripe-Account header) threaded through every processor call | D5-01 hybrid threading; resolver added to `Processor.Stripe.build_client!/1`; lattice_stripe 1.1 per-client/per-request `stripe_account:` semantics verified in `lattice_stripe/lib/lattice_stripe/account.ex:11-30` |
| CONN-01 | Connected account onboarding (Standard/Express/Custom) | `LatticeStripe.Account.create/3` exists. `type:` is required opt; ExDoc shows three patterns |
| CONN-02 | Account Link generation for onboarding/update flows | `LatticeStripe.AccountLink` exists. D5-06 ships struct with Inspect masking |
| CONN-03 | Account status sync (capabilities, charges_enabled, details_submitted, payouts_enabled) | D5-02 hybrid projection + D5-05 ConnectHandler `account.updated` reducer with `force_status_changeset` |
| CONN-04 | Destination charges | `Accrue.Connect.destination_charge/2` — `LatticeStripe.Charge` + `transfer_data: %{destination: acct}` |
| CONN-05 | Separate charges + transfers flow | `Accrue.Connect.separate_charge_and_transfer/2` + `Accrue.Connect.transfer/2`; `LatticeStripe.Transfer` exists at `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/transfer.ex` (verified) |
| CONN-06 | Platform fee computation helper | `Accrue.Connect.platform_fee/2` pure Money math; NimbleOptions config; StreamData property tests |
| CONN-07 | Express dashboard login link | `LatticeStripe.LoginLink` exists. D5-06 LoginLink struct with Inspect masking |
| CONN-08 | Payout schedule configuration | Passthrough via `Accrue.Connect.update_account/3` with `settings: %{payouts: %{schedule: ...}}` |
| CONN-09 | Capability management | Passthrough nested-map `update/4` per lattice_stripe idiom |
| CONN-10 | Per-account webhook secret routing | Phase 4 WH-13 plug already configured; **GAP**: dispatcher → handler routing not yet wired (see Critical Findings) |
| CONN-11 | Platform-scoped and connected-account-scoped API calls | Same surface, explicit context via D5-01 threading |

</phase_requirements>

## Summary

Phase 5 layers Stripe Connect on top of fully-shipped Phases 1–4. The technical surface is well-defined: every locked decision in CONTEXT.md mirrors a pattern that already exists in the codebase (`resolve_api_version/1` for D5-01, `force_status_changeset/2` for D5-02/05, `BillingPortal.Session` Inspect masking for D5-06, `DefaultHandler` shape for D5-05, NimbleOptions config schema for D5-04). lattice_stripe 1.1 ships the full Connect surface (`Account`, `AccountLink`, `LoginLink`, `Transfer`) — verified by direct inspection of the sibling repo. Per-client AND per-request `stripe_account:` precedence is documented in `LatticeStripe.Account` moduledoc (lines 11-30).

Two non-trivial findings require planner attention. **First, Phase 4 WH-13 plumbed the `endpoint` atom only into the webhook plug telemetry — it is NOT persisted on `accrue_webhook_events`, NOT threaded into the dispatch worker, and NOT in the WebhookEvent Ecto schema.** D5-05's dispatcher needs `ctx.endpoint`, so Phase 5 must add an `endpoint` column via migration AND thread the value through ingest → dispatch_worker → handler call site. This is a real ~1-task addition the CONTEXT.md describes as "already plumbed" but is only half-plumbed in the actual code. **Second, the existing test fixtures (`BillingCase`, `StripeFixtures`, `WebhookFixtures`) are Phase 3-scoped; Connect tests need parallel fixtures (`ConnectCase` or extension of `BillingCase`) for the `stripe_account`-scoped Fake processor.**

**Primary recommendation:** Plan Phase 5 as 6 plans following the locked decision boundaries. Wave 0 must include the webhook endpoint column migration before Wave 1 ConnectHandler work begins. lattice_stripe 1.1 is already pinned; no upstream bumps required.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stripe-Account header threading | Processor adapter (`Accrue.Processor.Stripe`) | Process dict (Actor-style) | Header is a per-request HTTP concern owned by the lattice_stripe client builder; pdict is a context-propagation mechanism, not a billing concern |
| Connect account persistence | Ecto schema + migration | Webhook reducers | Local projection of Stripe state per D2-29; webhooks are the canonical update path |
| Connect account public API | Domain context (`Accrue.Connect`) | Processor behaviour | Same shape as `Accrue.Billing` — context module orchestrates, processor delegates to lattice_stripe |
| Charge helpers (destination/separate) | Domain context (`Accrue.Connect`) | Existing `Accrue.Billing.Charge` projection | Connect charges return a `%Charge{}` row; only the request shape differs from non-Connect charges |
| Platform fee computation | Pure value module (`Accrue.Connect`) | NimbleOptions Config | No persistence; pure Money math; config-driven defaults |
| AccountLink/LoginLink credential structs | Value module (`Accrue.Connect.AccountLink|LoginLink`) | Inspect protocol | Bearer credentials — never persisted, mask in inspect |
| Webhook routing by endpoint | Webhook plug + dispatch worker | New `endpoint` column | Plug knows the endpoint atom; must propagate to row + worker |
| Connect-specific webhook reducers | New `Accrue.Webhook.ConnectHandler` | DefaultHandler dispatch shape | Sibling module to keep DefaultHandler legible as event types grow |
| Oban context propagation | `Accrue.Oban.Middleware` | Job args | `stripe_account` follows the same wire format as `operation_id` |
| LiveView/Controller binding | `Accrue.Plug.PutConnectedAccount` | Pdict | Phoenix-optional in core — plug is a thin, no-import-cost helper |

## Standard Stack

### Core (already pinned in mix.exs)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:lattice_stripe` | `~> 1.1` | Stripe Connect API wrapper | [VERIFIED: mix.exs] sibling lib, ships `Account`, `AccountLink`, `LoginLink`, `Transfer`, `Charge` with `transfer_data:`, per-client AND per-request `stripe_account:` precedence |
| `:ecto_sql` | `~> 3.13` | Migration + projection | [VERIFIED: prior phases] Used for `accrue_connect_accounts` table |
| `:postgrex` | `~> 0.22` | jsonb storage | [VERIFIED: prior phases] `capabilities`/`requirements`/`data` jsonb columns |
| `:nimble_options` | `~> 1.1` | Config schema for platform_fee defaults | [VERIFIED: mix.exs] Established pattern in `Accrue.Config` |
| `:oban` | `~> 2.21` | Async webhook handling | [VERIFIED: prior phases] No new queue — Connect events flow through `accrue_webhooks` |
| `:telemetry` | `~> 1.3` | Connect telemetry events | [VERIFIED: prior phases] `[:accrue, :connect, :*]` and `[:accrue, :ops, :connect_*]` |

### Test (already pinned in mix.exs)

| Library | Version | Purpose |
|---------|---------|---------|
| `:mox` | `~> 1.2` | Fake processor + boundary mocks |
| `:stream_data` | `~> 1.3` | **Mandatory** for `platform_fee/2` property tests across JPY (0-decimal), USD (2-decimal), KWD (3-decimal) |
| `ExUnit` | stdlib | Test runner |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hybrid pdict + opts threading (D5-01) | Per-call opts only | Forces churn at every marketplace call site; no LiveView `on_mount` ergonomics |
| Hybrid projection (D5-02) | Pure passthrough live-fetch | Phase 7 Admin LV needs <100ms list page with filter/sort — fails under rate limits |
| Two charge functions (D5-03) | Single `charge/3` with `mode:` | Loses typed opts, distinct telemetry, distinct ExDoc; CONN-04/05 are listed as separate criteria for a reason |
| Pure Money helper (D5-04) | Auto-inject in charge fns | Hides money math at framework call site — fails auditability |
| Dedicated ConnectHandler (D5-05) | Extend DefaultHandler | DefaultHandler already has 10+ clauses; adds 6-8 more; mixing concerns |
| Inspect-masked structs (D5-06) | Bare URL string | Loses `expires_at`; breaks Phase 4 CHKT-04 symmetry; no credential masking |

**No installation needed** — all deps already in `accrue/mix.exs`. Verified `lattice_stripe ~> 1.1`, `nimble_options ~> 1.1`, `mox ~> 1.2`, `stream_data ~> 1.3` present.

## Architecture Patterns

### System Architecture Diagram

```
                ┌─────────────────────────────────────────────────────────────┐
                │              Host Phoenix App (marketplace)                  │
                │                                                              │
                │  Plug: Accrue.Plug.PutConnectedAccount, from: {…, …, []}    │
                │              │                                               │
                │              │ sets pdict {:accrue, :connected_account_id}  │
                │              ▼                                               │
                │  Controller / LiveView                                       │
                │  ─────────────────────                                       │
                │  Accrue.Connect.with_account("acct_…", fn ->                │
                │    Accrue.Connect.destination_charge(%{…},                  │
                │      application_fee_amount: fee)                           │
                │  end)                                                        │
                └────────────────────────┬────────────────────────────────────┘
                                         │
                                         ▼
   ┌─────────────────────────────────────────────────────────────────────────┐
   │                    Accrue.Connect (domain context)                       │
   │                                                                          │
   │   ┌─────────────────┐  ┌──────────────────┐  ┌────────────────────┐   │
   │   │ Account Mgmt    │  │ Charge Helpers   │  │ Credential Structs │   │
   │   │ create/2        │  │ destination_     │  │ AccountLink        │   │
   │   │ retrieve/2      │  │   charge/2       │  │ LoginLink          │   │
   │   │ update/3        │  │ separate_charge_ │  │ (Inspect masked)   │   │
   │   │ reject/3        │  │   and_transfer/2 │  │                    │   │
   │   │ list/1          │  │ transfer/2       │  │ create_account_    │   │
   │   │                 │  │                  │  │   link/2           │   │
   │   │ + predicates    │  │ + platform_fee/2 │  │ create_login_      │   │
   │   │ (fully_         │  │   (pure Money)   │  │   link/2           │   │
   │   │  onboarded?…)   │  │                  │  │                    │   │
   │   └────────┬────────┘  └────────┬─────────┘  └─────────┬──────────┘   │
   │            │                    │                       │              │
   │            ▼                    ▼                       ▼              │
   │   ┌─────────────────────────────────────────────────────────────┐    │
   │   │  resolve_account/1 + dual bang/tuple wrappers              │    │
   │   └─────────────────────────────┬──────────────────────────────┘    │
   └─────────────────────────────────┼─────────────────────────────────────┘
                                     │
                                     ▼
   ┌─────────────────────────────────────────────────────────────────────────┐
   │              Accrue.Processor.Stripe (adapter)                           │
   │                                                                          │
   │   resolve_stripe_account/1   ◀── new sibling of resolve_api_version/1   │
   │      opts > pdict > config                                               │
   │                       │                                                  │
   │                       ▼                                                  │
   │   build_client!/1 → LatticeStripe.Client.new!(                          │
   │                       api_key: …, api_version: …,                       │
   │                       stripe_account: resolved)                         │
   │                       │                                                  │
   │                       ▼                                                  │
   │   LatticeStripe.{Account|AccountLink|LoginLink|Charge|Transfer}         │
   └─────────────────────────────────┬───────────────────────────────────────┘
                                     │
                                     ▼ HTTPS w/ Stripe-Account header
                              ┌─────────────┐
                              │   Stripe    │
                              └──────┬──────┘
                                     │  (event delivery)
                                     ▼
   ┌─────────────────────────────────────────────────────────────────────────┐
   │   Accrue.Webhook.Plug                                                    │
   │   ──────────────────                                                     │
   │   forward "/webhooks/stripe/connect", to: Accrue.Webhook.Plug,          │
   │     init_opts: [endpoint: :connect, processor: :stripe]                 │
   │                                                                          │
   │   resolve_secrets!(:connect, _)  → reads webhook_endpoints[:connect]    │
   │   verify signature ──▶ persist accrue_webhook_events row                │
   │                          + endpoint column (NEW MIGRATION)              │
   │                          ──▶ enqueue Oban DispatchWorker                │
   └─────────────────────────────────┬───────────────────────────────────────┘
                                     │
                                     ▼
   ┌─────────────────────────────────────────────────────────────────────────┐
   │   Accrue.Webhook.DispatchWorker                                          │
   │                                                                          │
   │   ctx = build_ctx(event_row)  ◀── must read endpoint from row            │
   │                                                                          │
   │   handler =                                                              │
   │     case ctx.endpoint do                                                 │
   │       :connect -> Accrue.Webhook.ConnectHandler                         │
   │       _        -> Accrue.Webhook.DefaultHandler                         │
   │     end                                                                  │
   │                                                                          │
   │   handler.handle_event(event.type, event, ctx)                          │
   └─────────────────────────────────┬───────────────────────────────────────┘
                                     │
                                     ▼
   ┌─────────────────────────────────────────────────────────────────────────┐
   │   Accrue.Webhook.ConnectHandler                                          │
   │                                                                          │
   │   account.updated              → load_or_fetch → force_status_changeset │
   │   account.application.authorized → upsert + authorized_at               │
   │   account.application.deauthorized → tombstone + ops telemetry          │
   │   capability.updated           → partial update + refetch on new key    │
   │   payout.{created,paid,failed} → events ledger only                     │
   │   person.{created,updated}     → ack, no local mutation                 │
   │                                                                          │
   │   Each reducer: Repo.transact + Events.record_multi + emit span         │
   └──────────────────────────────────────────────────────────────────────────┘
```

### Recommended Module Layout

```
accrue/lib/accrue/
├── connect.ex                       # Public domain facade (with_account/2,
│                                    #   current_account_id/0, create_account/2,
│                                    #   destination_charge/2, separate_charge_…,
│                                    #   transfer/2, platform_fee/2,
│                                    #   create_account_link/2, create_login_link/2)
├── connect/
│   ├── account.ex                   # %Accrue.Connect.Account{} schema + predicates
│   ├── account_link.ex              # AccountLink struct + Inspect masking
│   ├── login_link.ex                # LoginLink struct + Inspect masking
│   └── projection.ex                # Stripe Account → row mapper (mirrors
│                                    #   Accrue.Billing.SubscriptionProjection)
├── plug/
│   └── put_connected_account.ex     # Mirror of put_operation_id.ex
├── webhook/
│   └── connect_handler.ex           # New sibling of default_handler.ex
└── processor/
    └── stripe.ex                    # Add resolve_stripe_account/1 + extend
                                     #   build_client!/1 (one-line addition)

accrue/priv/repo/migrations/
├── 20260415xxxxxx_create_accrue_connect_accounts.exs
└── 20260415xxxxxx_add_endpoint_to_accrue_webhook_events.exs   ◀── REQUIRED

accrue/test/support/
└── connect_case.ex                  # OR extend billing_case.ex with Connect helpers
```

### Pattern 1: Three-Level Precedence Resolver (D5-01)

**What:** Mirror of existing `resolve_api_version/1`. Source: `accrue/lib/accrue/processor/stripe.ex:820-825`.

```elixir
# accrue/lib/accrue/processor/stripe.ex (NEW sibling)
@doc """
Resolves the Stripe-Account header value using three-level precedence:

  1. `opts[:stripe_account]` (explicit per-call override)
  2. `Accrue.Connect.current_account_id/0` (scoped via `Accrue.Connect.with_account/2`)
  3. `Accrue.Config.get(:default_stripe_account)` (config fallback, usually nil)
"""
@spec resolve_stripe_account(keyword()) :: String.t() | nil
def resolve_stripe_account(opts \\ []) when is_list(opts) do
  Keyword.get(opts, :stripe_account) ||
    Accrue.Connect.current_account_id() ||
    Accrue.Config.get(:default_stripe_account)
end

# extend build_client!/1 — one-line change:
defp build_client!(opts) do
  # …existing key + api_version code…
  stripe_account = resolve_stripe_account(opts)
  LatticeStripe.Client.new!(
    api_key: key,
    api_version: api_version,
    stripe_account: stripe_account
  )
end
```

**Source:** lattice_stripe per-client/per-request semantics documented at `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/account.ex:11-30` [VERIFIED].

### Pattern 2: Pdict Scoped Block (D5-01)

```elixir
# accrue/lib/accrue/connect.ex
@pdict_key {:accrue, :connected_account_id}

@spec with_account(String.t() | %Accrue.Connect.Account{}, (-> result)) :: result when result: var
def with_account(account, fun) when is_function(fun, 0) do
  acct_id = resolve_account_id(account)
  prev = Process.get(@pdict_key)
  Process.put(@pdict_key, acct_id)

  try do
    fun.()
  after
    if prev, do: Process.put(@pdict_key, prev), else: Process.delete(@pdict_key)
  end
end

@spec current_account_id() :: String.t() | nil
def current_account_id, do: Process.get(@pdict_key)
```

**Source:** Mirrors `Accrue.Actor.current_operation_id/0` at `accrue/lib/accrue/actor.ex:74-98` [VERIFIED via direct read].

### Pattern 3: Inspect-Masked Credential Struct (D5-06)

**Source:** `accrue/lib/accrue/billing_portal/session.ex:149-178` [VERIFIED via CONTEXT.md canonical refs].

```elixir
defmodule Accrue.Connect.AccountLink do
  @enforce_keys [:url, :expires_at, :created, :object]
  defstruct [:url, :expires_at, :created, :object]

  @type t :: %__MODULE__{
          url: String.t(),
          expires_at: DateTime.t(),
          created: DateTime.t(),
          object: String.t()
        }

  @spec from_stripe(map()) :: t()
  def from_stripe(%{"url" => url, "expires_at" => exp, "created" => c, "object" => o}) do
    %__MODULE__{
      url: url,
      expires_at: DateTime.from_unix!(exp),
      created: DateTime.from_unix!(c),
      object: o
    }
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{expires_at: exp, created: c}, _opts) do
      concat([
        "#Accrue.Connect.AccountLink<url: <redacted>, expires_at: ",
        Kernel.inspect(exp),
        ", created: ",
        Kernel.inspect(c),
        ">"
      ])
    end
  end
end
```

### Pattern 4: Hybrid Projection + force_status_changeset (D5-02 + D5-05)

```elixir
defmodule Accrue.Connect.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_connect_accounts" do
    field :stripe_account_id, :string
    field :owner_type, :string
    field :owner_id, :binary_id
    field :type, :string
    field :country, :string
    field :email, :string
    field :charges_enabled, :boolean, default: false
    field :details_submitted, :boolean, default: false
    field :payouts_enabled, :boolean, default: false
    field :capabilities, :map, default: %{}
    field :requirements, :map, default: %{}
    field :data, :map, default: %{}
    field :deauthorized_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end

  # User-path: validates required fields
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:stripe_account_id, :type, :owner_type, :owner_id, :country,
                    :email, :data, :capabilities, :requirements,
                    :charges_enabled, :details_submitted, :payouts_enabled])
    |> validate_required([:stripe_account_id, :type])
    |> validate_inclusion(:type, ["standard", "express", "custom"])
    |> unique_constraint(:stripe_account_id)
  end

  # Webhook-path: bypasses validation per D3-17 / D2-29
  def force_status_changeset(account, stripe_payload) do
    account
    |> cast(stripe_payload, [:charges_enabled, :details_submitted, :payouts_enabled,
                             :capabilities, :requirements, :data, :deauthorized_at])
  end

  # Predicates per D3-04 — no raw boolean access in callers
  def charges_enabled?(%__MODULE__{charges_enabled: c}), do: c
  def payouts_enabled?(%__MODULE__{payouts_enabled: p}), do: p
  def fully_onboarded?(%__MODULE__{} = a),
    do: a.charges_enabled and a.details_submitted and a.payouts_enabled
  def deauthorized?(%__MODULE__{deauthorized_at: nil}), do: false
  def deauthorized?(%__MODULE__{}), do: true
end
```

### Pattern 5: ConnectHandler Reducer Shape (D5-05)

```elixir
defmodule Accrue.Webhook.ConnectHandler do
  @moduledoc "Webhook handler for Connect-endpoint events."

  alias Accrue.{Connect, Events, Repo}
  alias Accrue.Connect.Account

  def handle_event("account.updated", event, ctx) do
    payload = event["data"]["object"]
    acct_id = payload["id"]

    Repo.transact(fn ->
      account =
        case Repo.get_by(Account, stripe_account_id: acct_id) do
          nil ->
            # Out-of-order: account.updated arrived before our local create.
            # Fetch from Stripe via Connect.retrieve_account/2 to seed.
            {:ok, fresh} = Connect.retrieve_account(acct_id)
            fresh
          existing -> existing
        end

      account
      |> Account.force_status_changeset(payload)
      |> Repo.update!()
      |> tap(fn updated ->
        Events.record_multi(:connect_account_updated, %{
          subject_type: "connect_account",
          subject_id: updated.id,
          data: payload
        })
      end)
    end)
  end

  def handle_event("account.application.deauthorized", event, _ctx) do
    # Tombstone, do not delete (audit trail).
    # Emit ops telemetry: [:accrue, :ops, :connect_account_deauthorized]
    # …
  end

  # capability.updated, payout.*, person.* clauses follow same shape
end
```

### Anti-Patterns to Avoid

- **Sub-facade `Accrue.Connect.Billing.*`** — doubles every Billing context fn with a Connect twin. Subsumed by `with_account/2`.
- **Auto-injecting `application_fee_amount`** inside charge helpers — hides money math from the call site, fails auditability.
- **Hard-deleting on `account.application.deauthorized`** — destroys audit trail. Tombstone via `deauthorized_at` only.
- **Returning bare URL strings** from `create_account_link/2` — leaks to logger/Sentry, breaks Phase 4 CHKT-04 symmetry.
- **Storing `requirements` as a typed nested struct** — Stripe's currently_due/eventually_due/past_due is an evolving schema; jsonb verbatim is more durable.
- **Shipping a `request_capability/3` helper** — capability names are an open enum (`card_payments`, `transfers`, `link_payments`, `tax_reporting_us_1099_misc`, …); fake ergonomics.
- **Live-fetching connected accounts on Phase 7 list pages** — fails <100ms budget under rate limits; D5-02 hybrid projection is the answer.
- **Re-implementing pdict propagation per call site** — extend `Accrue.Oban.Middleware` once, get it everywhere.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| `Stripe-Account` HTTP header injection | Custom HTTP client wrapper | `LatticeStripe.Client.new!(stripe_account: …)` | Already implemented, per-request precedence handled |
| AccountLink/LoginLink API serialization | Hand-rolled HTTP POST | `LatticeStripe.AccountLink.create/3`, `LatticeStripe.LoginLink.create/3` | Phase 17 ships these |
| Connect Account create/update/retrieve | Hand-rolled wrappers | `LatticeStripe.Account.{create,retrieve,update,delete,reject,list}` | Full lifecycle exists |
| Transfer API | Hand-rolled `transfers.create` | `LatticeStripe.Transfer.create/3` | [VERIFIED: file exists at `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/transfer.ex`] |
| Process dict propagation | New mechanism | Mirror `Accrue.Actor`/`Accrue.Stripe.with_api_version/2` pattern | Tested, established, three-level precedence already proven |
| Oban context propagation | New middleware | Extend `Accrue.Oban.Middleware` (already threads `operation_id`) | ~10 LOC addition; same wire format |
| Money math for platform fee | Bare integer arithmetic | `Accrue.Money` primitives + StreamData property tests | FND-01 compliance; zero/three-decimal currency safety |
| URL credential masking | Custom Logger filter | `defimpl Inspect` on the struct | Phase 4 CHKT-04 precedent; covers Logger AND inspect anywhere |
| Webhook handler dispatch routing | Conditional inside DefaultHandler | New ConnectHandler module + dispatcher case | DefaultHandler legibility; Pay precedent |
| Capability metadata typing | Typed nested struct | jsonb verbatim | Stripe's capability set grows; jsonb is forward-compatible |
| Per-account fee policy | Schema + CRUD UI | NimbleOptions config + `rate_override:` opt | 80% case is flat-rate; 5-line guide for tiered |

**Key insight:** Phase 5 invents nothing structurally new. Every D5-* decision mirrors a pattern that already exists in the codebase. The Phase 5 work is largely (a) wiring lattice_stripe Connect surface into Accrue's behaviour + adapter, (b) one new schema + projection, (c) one new webhook handler, and (d) one new pdict pattern that copies the operation_id pattern verbatim.

## Runtime State Inventory

> Phase 5 is greenfield (new functionality). No rename/refactor. SKIPPED.

## Common Pitfalls

### Pitfall 1: Forgetting endpoint persistence on the webhook event row

**What goes wrong:** Phase 4 WH-13 plumbed `endpoint: :connect` into the webhook plug telemetry but **did not persist** the endpoint atom on the `accrue_webhook_events` row, and **did not thread** it through the dispatch worker. D5-05's dispatcher needs `ctx.endpoint` to route to ConnectHandler.

**Why it happens:** CONTEXT.md says "WH-13 already plumbed endpoint atom through the plug + event row" — but inspection of `accrue/lib/accrue/webhook/webhook_event.ex:38-50` shows no `endpoint` field, and `grep -n endpoint accrue/lib/accrue/webhook/{ingest,dispatch_worker}.ex` returns nothing. The CONTEXT statement is half-true: only the plug telemetry sees `endpoint`; the persisted row does not.

**How to avoid:** Phase 5 plan MUST include a Wave 0 task: (a) migration adding `endpoint :string` (or `Ecto.Enum`) column to `accrue_webhook_events`, (b) update `WebhookEvent` schema, (c) update `Accrue.Webhook.Ingest` (or `do_call/3` in plug.ex) to pass endpoint into the changeset, (d) update `DispatchWorker` to read endpoint from row and build `ctx.endpoint`. Without this, D5-05 ConnectHandler is unreachable.

**Warning signs:** Connect webhook tests fail with all events going to DefaultHandler. ConnectHandler reducers never run.

### Pitfall 2: Stripe-Account header on platform-only calls

**What goes wrong:** A test seeds `with_account("acct_…")` then calls `Accrue.Connect.destination_charge/2`. Destination charges are PLATFORM-scoped — `transfer_data: %{destination: acct}` goes in the charge body, NOT the header. If the request also sends `Stripe-Account: acct_…`, Stripe creates the charge ON the connected account (separate-charges pattern) instead of on the platform.

**Why it happens:** D5-01 threading is automatic via `with_account/2`. Marketplace devs intuitively wrap the entire call in a connected-account scope.

**How to avoid:** `destination_charge/2` MUST internally call with `stripe_account: nil` (override the resolver) OR with `Accrue.Connect.with_account(nil, fn -> … end)`. Document loud-and-clear: "destination charges are platform-scoped; the destination account is in the body, not the header."

**Warning signs:** Test sees the charge created on the connected account instead of the platform. Stripe dashboard shows the charge under "Connected accounts → acct_… → Payments" instead of platform Payments.

### Pitfall 3: Out-of-order `account.updated` before local row exists

**What goes wrong:** A test creates a Standard account via `Accrue.Connect.create_account/2`. Stripe's webhook delivery race causes `account.updated` to arrive before `create_account/2` returns and inserts the local row. ConnectHandler's `Repo.get_by` returns nil and a naive reducer crashes or no-ops.

**How to avoid:** ConnectHandler `account.updated` reducer must call `Connect.retrieve_account(acct_id)` to fetch + seed if local row is missing — same pattern as Phase 3 D3-17 webhook reducers (load-or-fetch). Code example in Pattern 5 above shows the shape.

**Warning signs:** New account shows `charges_enabled: false` until a manual sync, even after Stripe says it's ready.

### Pitfall 4: Property test currency coverage (D5-04)

**What goes wrong:** `platform_fee/2` ships with property tests for USD only. A KWD (3-decimal) host computes `2.9% × ﷼1.000` and gets a rounding error in the third decimal place. JPY (0-decimal) host gets a fractional-yen rounding ambiguity.

**How to avoid:** StreamData generators MUST cover all three currency precisions. Use `Accrue.Money` primitives end-to-end (no Decimal-then-multiply-then-trunc shortcut). Property assertions: `fee ≤ gross`, `fee.currency == gross.currency`, `clamp(clamp(x)) == clamp(x)`, `platform_fee(zero, _) == zero`, round-percent-then-add-fixed matches Stripe's documented formula.

**Warning signs:** CI flake on KWD/JPY tests. Manual reconciliation against Stripe Dashboard shows ±1 minor unit drift.

### Pitfall 5: Connect-variant secret confused with platform secret

**What goes wrong:** Host configures `:webhook_endpoints, [connect: [secret: "whsec_PLATFORM"]]` by mistake (copy-pastes the platform secret into the Connect endpoint config). All Connect events fail signature verification.

**How to avoid:** Document loudly in `guides/connect.md` that Stripe issues a SEPARATE signing secret per Connect endpoint in the Stripe Dashboard — and that mixing them yields silent verification failures. Add a runtime warning on app boot if both `:platform` and `:connect` endpoint secrets are byte-identical.

**Warning signs:** All Connect events 400 with `Accrue.SignatureError`. DLQ fills with Connect events.

### Pitfall 6: ETS keyspace collision in Fake processor

**What goes wrong:** Phase 3 Fake processor stores resources keyed by resource type only (`{:subscription, "sub_…"}`). Phase 5 needs platform AND multiple connected accounts to coexist. A naive extension overwrites Customer X on platform when an identically-IDed Customer X is created on a connected account.

**How to avoid:** D5-01 says "Fake processor scopes ETS keyspace on `{stripe_account, resource_type}`" — implement this as a key-prefix migration. `:platform` is the sentinel for nil. Test helpers `Fake.accounts_for/1`, `Fake.charges_on/1` accept either an acct id or `:platform`.

**Warning signs:** Cross-account test bleed. A test that creates a charge on `acct_A` sees it via `Fake.charges_on(:platform)`.

## Code Examples

### Example 1: Onboarding a Standard account

```elixir
# Source: derived from CONTEXT.md D5-01 + D5-06 + Stripe Connect docs
{:ok, account} =
  Accrue.Connect.create_account(%{
    type: "standard",
    country: "US",
    email: "merchant@example.com",
    capabilities: %{
      "card_payments" => %{requested: true},
      "transfers" => %{requested: true}
    }
  })

{:ok, %Accrue.Connect.AccountLink{} = link} =
  Accrue.Connect.create_account_link(account,
    return_url: "https://platform.example.com/connect/return?acct=#{account.stripe_account_id}",
    refresh_url: "https://platform.example.com/connect/refresh?acct=#{account.stripe_account_id}",
    type: "account_onboarding",
    collect: "currently_due"
  )

# Inspect output redacts the URL:
#  #Accrue.Connect.AccountLink<url: <redacted>, expires_at: ~U[2026-04-15 14:30:00Z], …>

# Host's controller redirects:
redirect(conn, external: link.url)
```

### Example 2: Destination charge with platform fee

```elixir
# Source: D5-03 + D5-04 explicit caller-inject pattern
gross = Accrue.Money.new(10_000, :usd)              # $100.00
{:ok, fee} = Accrue.Connect.platform_fee(gross)     # %Money{minor: 320, currency: :USD}

{:ok, %Accrue.Billing.Charge{} = charge} =
  Accrue.Connect.destination_charge(
    %{
      amount: gross,
      currency: :usd,
      customer: customer,
      destination: account,                          # %Connect.Account{} OR "acct_…"
      description: "Order #1234"
    },
    application_fee_amount: fee
  )
```

### Example 3: Separate charge + transfer

```elixir
# Source: D5-03 separate-charges pattern
{:ok, %{charge: charge, transfer: transfer}} =
  Accrue.Connect.separate_charge_and_transfer(
    %{
      amount: Accrue.Money.new(10_000, :usd),
      currency: :usd,
      customer: customer
    },
    destination: account,
    transfer_amount: Accrue.Money.new(8_000, :usd)   # $80 to seller, $20 platform
  )
```

### Example 4: Scoped operation across multiple billing calls

```elixir
# Source: D5-01 with_account/2 pdict scope
Accrue.Connect.with_account("acct_marketplace_seller_42", fn ->
  # All three calls inside this block carry Stripe-Account header automatically
  {:ok, customer} = Accrue.Billing.fetch_or_create_customer(buyer_user)
  {:ok, sub}      = Accrue.Billing.subscribe(customer, "price_pro_monthly")
  {:ok, invoice}  = Accrue.Billing.preview_upcoming_invoice(sub)
  {:ok, sub, invoice}
end)
```

### Example 5: Express dashboard login link

```elixir
# Source: D5-06 LoginLink struct
{:ok, %Accrue.Connect.LoginLink{} = link} =
  Accrue.Connect.create_login_link(account)

# Host's admin UI:
redirect(conn, external: link.url)   # 5-min Express dashboard bearer
```

### Example 6: NimbleOptions config schema for platform_fee

```elixir
# Source: D5-04 — extends Accrue.Config with new :connect key
@connect_schema [
  default_stripe_account: [
    type: {:or, [:string, nil]},
    default: nil,
    doc: "Default `Stripe-Account` header value (rare; useful for single-tenant platforms)."
  ],
  platform_fee: [
    type: :keyword_list,
    default: [],
    keys: [
      percent: [type: :any, default: Decimal.new("0"), doc: "Percent of gross as Decimal."],
      fixed: [type: :any, default: nil, doc: "Fixed component as %Accrue.Money{}."],
      min: [type: :any, default: nil, doc: "Optional minimum fee as %Accrue.Money{}."],
      max: [type: :any, default: nil, doc: "Optional maximum fee as %Accrue.Money{}."]
    ]
  ]
]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| OAuth-based Connect onboarding | Account Links (`AccountLink.create`) | Stripe deprecated OAuth flow circa 2023 | Phase 5 uses Account Links only; OAuth out of scope |
| `Stripe-Account` set globally on the client | Per-request override AT the client level | lattice_stripe Phase 17 (sibling repo) | D5-01 hybrid threading wins both per-call and scoped patterns |
| `Charge.create` direct on platform | `PaymentIntent.create` (non-Connect) + `Charge.create` (Connect direct) | Stripe `2026-03-25.dahlia` removed direct Charge.create for new integrations | Phase 3 already routes platform charges through PaymentIntent; Phase 5 destination_charge can use `Charges.create` because Connect destination charges remain a Charge endpoint per Stripe docs |
| Platform fee policy table per app | NimbleOptions config + caller-inject | Pay-Rails community consensus 2024 | D5-04 — no schema, no CRUD; tiered fees are a guide recipe |
| `pay_merchants` minimal projection (Pay-Rails) | Hybrid projection with typed columns | D5-02 Phase 5 decision | Admin LV needs filter/sort under <100ms |
| Single webhook endpoint with shared secret | Multi-endpoint with per-endpoint secrets | Stripe Connect best practice (forever) | Phase 4 WH-13 plug + Phase 5 dispatcher routing |

**Deprecated/outdated:**

- **OAuth Connect onboarding** — replaced by Account Links. Do not implement.
- **`Stripite_Stripe`** (Elixir lib) — pinned to Stripe API 2019; lacks 2026 Connect features; replaced by `lattice_stripe ~> 1.1`.
- **Pay-Rails `pay_merchants` minimal-projection precedent** — Accrue intentionally extends to hybrid (D5-02) because of Phase 7 Admin LV demands.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `LatticeStripe.AccountLink.create/3` returns a map with `"url"`, `"expires_at"`, `"created"`, `"object"` keys | Pattern 3 (`from_stripe/1`) | Constructor crashes; planner needs to read `lattice_stripe/lib/lattice_stripe/account_link.ex` to confirm exact return shape |
| A2 | `LatticeStripe.LoginLink.create/3` returns a map with `"url"` and `"created"` keys | D5-06 LoginLink struct | Same as A1 — read `lattice_stripe/lib/lattice_stripe/login_link.ex` to confirm |
| A3 | `LatticeStripe.Transfer.create/3` accepts `%{amount, currency, destination}` | Pattern: `transfer/2` helper | Verified file exists; planner should read it to confirm exact signature before writing the wrapper |
| A4 | Stripe's documented platform fee rounding is "round percent to nearest minor unit, then add fixed, then clamp" | Pitfall 4 + D5-04 | If Stripe's documented order differs, property tests will diverge from Stripe's own computation. Verify against https://docs.stripe.com/connect/platform-pricing-tools/pricing-schemes before locking the algorithm |
| A5 | Connect destination charges remain a `charges.create` endpoint (not `payment_intents.create`) under `2026-03-25.dahlia` | Example 2 + D5-03 | If dahlia removed Charge.create for destination charges, `destination_charge/2` must route through PaymentIntent with `transfer_data:`. Verify in lattice_stripe Charge module + Stripe API changelog |
| A6 | `LatticeStripe.Charge.create/3` accepts `transfer_data: %{destination: …}` opt | D5-03 destination_charge | Verify directly from `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/charge.ex` |
| A7 | Phase 4 endpoint plumbing is half-shipped (plug only) | Pitfall 1 + Critical Findings | HIGH CONFIDENCE — direct grep confirmed no `endpoint` field in `WebhookEvent` schema and no references in ingest/dispatch_worker. Risk is low; this finding is the strongest signal in the research |
| A8 | `Accrue.Oban.Middleware` exists and currently threads operation_id | Pattern: extend middleware | `accrue/lib/accrue/oban/` directory exists per `ls`; planner should verify the middleware module name and shape before extending |

## Open Questions

1. **Exact `LatticeStripe.AccountLink.create/3` return shape**
   - What we know: Module exists at `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/account_link.ex`
   - What's unclear: Whether it returns `{:ok, %LatticeStripe.AccountLink{}}` struct or `{:ok, raw_map}` from Stripe
   - Recommendation: Plan task should `Read` the module and adapt `Accrue.Connect.AccountLink.from_stripe/1` accordingly

2. **`LatticeStripe.Transfer.create/3` signature + return shape**
   - What we know: File exists; sibling of `Charge`
   - What's unclear: Exact opts shape (keyword vs map), return wrapping
   - Recommendation: Same — Wave 0 / Wave 1 task reads the module before wrapping

3. **Stripe `2026-03-25.dahlia` Charge.create status for destination charges**
   - What we know: Phase 3 had to route platform charges through PaymentIntent because Charge.create was removed for new integrations
   - What's unclear: Whether destination charges (`Charge.create` with `transfer_data: %{destination:}`) is similarly removed, or whether destination charges have a special carve-out
   - Recommendation: Verify against current Stripe API reference for `2026-03-25.dahlia`. If removed, `destination_charge/2` routes through `LatticeStripe.PaymentIntent.create/3` with `transfer_data:` instead of `LatticeStripe.Charge.create/3`. Same external behavior; different internal call.

4. **Should Wave 0 be added explicitly to the plan layout?**
   - What we know: CONTEXT.md does not enumerate plans; the webhook endpoint persistence gap is real and blocks D5-05
   - Recommendation: Plan layout should be 6-7 plans, with Plan 01 = Wave 0 (`endpoint` migration + WebhookEvent schema update + ingest/dispatch threading) BEFORE any ConnectHandler work

## Environment Availability

> Phase 5 has no new external dependencies. All required tools and libraries are already pinned in `accrue/mix.exs` and verified by Phase 4 completion.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Build | ✓ | ~> 1.17 | — |
| Erlang/OTP | Runtime | ✓ | 27+ | — |
| PostgreSQL | accrue_connect_accounts table | ✓ | 14+ | — |
| `:lattice_stripe` | Connect API | ✓ | ~> 1.1 (in mix.exs) | — |
| `:nimble_options` | platform_fee config | ✓ | ~> 1.1 | — |
| `:mox` | Fake processor tests | ✓ | ~> 1.2 | — |
| `:stream_data` | Property tests for platform_fee | ✓ | ~> 1.3 | — |
| Stripe test mode account | Live Stripe integration tests (live_stripe/ dir) | Assumed (Phase 3 already uses) | — | Fake processor for unit tests |

**No missing dependencies.** Phase 5 is purely additive Elixir code + one migration.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (stdlib) + Mox 1.2 + StreamData 1.3 |
| Config file | `accrue/test/test_helper.exs`; per-suite cases in `accrue/test/support/` |
| Quick run command | `cd accrue && mix test test/accrue/connect/` |
| Full suite command | `cd accrue && mix test --warnings-as-errors` |
| Live Stripe suite | `cd accrue && mix test --only live_stripe` (existing pattern from Phase 3, in `accrue/test/live_stripe/`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROC-05 | `resolve_stripe_account/1` precedence: opts > pdict > config | unit | `mix test test/accrue/processor/stripe_test.exs:resolve_stripe_account` | ❌ Wave 0 |
| PROC-05 | `build_client!/1` passes resolved value to `LatticeStripe.Client.new!` | unit (Mox boundary) | `mix test test/accrue/processor/stripe_test.exs:build_client_stripe_account` | ❌ Wave 0 |
| PROC-05 | `Accrue.Oban.Middleware` carries `stripe_account` across job boundary | integration | `mix test test/accrue/oban/middleware_test.exs` | ❌ Wave 0 |
| CONN-01 | `Accrue.Connect.create_account/2` for each of `:standard | :express | :custom` round-trips through Fake | unit | `mix test test/accrue/connect/account_test.exs` | ❌ Wave 0 |
| CONN-01 | Required `type:` opt rejected when missing | unit | `mix test test/accrue/connect/account_test.exs:type_required` | ❌ Wave 0 |
| CONN-02 | `create_account_link/2` returns `%AccountLink{}` with `expires_at` populated | unit | `mix test test/accrue/connect/account_link_test.exs` | ❌ Wave 0 |
| CONN-02 | `Inspect.inspect(%AccountLink{})` masks `:url` as `<redacted>` | unit | `mix test test/accrue/connect/account_link_test.exs:inspect_redacts_url` | ❌ Wave 0 |
| CONN-03 | `account.updated` webhook updates `charges_enabled`/`payouts_enabled`/`details_submitted`/`capabilities` via `force_status_changeset` | integration | `mix test test/accrue/webhook/connect_handler_test.exs:account_updated` | ❌ Wave 0 |
| CONN-03 | Out-of-order `account.updated` (no local row) fetches and seeds via `Connect.retrieve_account/2` | integration | `mix test test/accrue/webhook/connect_handler_test.exs:out_of_order_seeds_local_row` | ❌ Wave 0 |
| CONN-03 | Predicates `fully_onboarded?/1`, `charges_enabled?/1` reflect post-webhook state | unit | `mix test test/accrue/connect/account_test.exs:predicates` | ❌ Wave 0 |
| CONN-04 | `destination_charge/2` includes `transfer_data: %{destination: …}` and `application_fee_amount` in request body, NOT in `Stripe-Account` header | unit (Mox) | `mix test test/accrue/connect/charges_test.exs:destination_charge_request_shape` | ❌ Wave 0 |
| CONN-04 | Returns `%Accrue.Billing.Charge{}` projection | integration | `mix test test/accrue/connect/charges_test.exs:destination_charge_returns_charge` | ❌ Wave 0 |
| CONN-05 | `separate_charge_and_transfer/2` issues two distinct calls (charge + transfer) | unit (Mox) | `mix test test/accrue/connect/charges_test.exs:separate_charge_two_calls` | ❌ Wave 0 |
| CONN-05 | `transfer/2` standalone helper round-trips through Fake | unit | `mix test test/accrue/connect/transfer_test.exs` | ❌ Wave 0 |
| CONN-06 | `platform_fee/2` USD: `$100 * 2.9% + $0.30 = $3.20` | unit | `mix test test/accrue/connect/platform_fee_test.exs:usd_basic` | ❌ Wave 0 |
| CONN-06 | `platform_fee/2` JPY (0-decimal) preserves minor-unit precision | unit | `mix test test/accrue/connect/platform_fee_test.exs:jpy_zero_decimal` | ❌ Wave 0 |
| CONN-06 | `platform_fee/2` KWD (3-decimal) preserves minor-unit precision | unit | `mix test test/accrue/connect/platform_fee_test.exs:kwd_three_decimal` | ❌ Wave 0 |
| CONN-06 | StreamData property: `fee ≤ gross` for all currencies | property | `mix test test/property/connect_platform_fee_property_test.exs` | ❌ Wave 0 |
| CONN-06 | StreamData property: clamp idempotent `clamp(clamp(x)) == clamp(x)` | property | `mix test test/property/connect_platform_fee_property_test.exs:clamp_idempotent` | ❌ Wave 0 |
| CONN-06 | StreamData property: `platform_fee(zero, _) == zero` | property | `mix test test/property/connect_platform_fee_property_test.exs:zero_zero` | ❌ Wave 0 |
| CONN-07 | `create_login_link/2` returns `%LoginLink{}` for Express account; rejects Standard/Custom | unit | `mix test test/accrue/connect/login_link_test.exs` | ❌ Wave 0 |
| CONN-07 | `Inspect.inspect(%LoginLink{})` masks `:url` | unit | `mix test test/accrue/connect/login_link_test.exs:inspect_redacts` | ❌ Wave 0 |
| CONN-08 | `update_account/3` with `settings: %{payouts: %{schedule: …}}` round-trips through Fake | unit | `mix test test/accrue/connect/account_test.exs:payout_schedule_passthrough` | ❌ Wave 0 |
| CONN-09 | `update_account/3` with `capabilities: %{"card_payments" => %{requested: true}}` round-trips | unit | `mix test test/accrue/connect/account_test.exs:capability_passthrough` | ❌ Wave 0 |
| CONN-10 | Webhook plug verifies `:connect` endpoint event against `:connect` secret, not platform secret | integration | `mix test test/accrue/webhook/plug_test.exs:connect_endpoint_uses_connect_secret` | ❌ Wave 0 |
| CONN-10 | Tampered Connect-event signature returns 400 | integration | `mix test test/accrue/webhook/plug_test.exs:connect_signature_failure` | ❌ Wave 0 |
| CONN-10 | DispatchWorker routes `endpoint == :connect` event to ConnectHandler, others to DefaultHandler | integration | `mix test test/accrue/webhook/dispatch_worker_test.exs:routes_by_endpoint` | ❌ Wave 0 |
| CONN-11 | Same `Accrue.Billing.subscribe/3` call works platform-scoped (no acct) AND connected-account-scoped (via `with_account/2` or opts) | integration | `mix test test/accrue/connect/dual_scope_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `cd accrue && mix test test/accrue/connect/ test/accrue/webhook/connect_handler_test.exs --warnings-as-errors`
- **Per wave merge:** `cd accrue && mix test --warnings-as-errors`
- **Phase gate:** `cd accrue && mix test --warnings-as-errors && mix credo --strict && mix dialyzer && mix test --only live_stripe` — full suite green, including the live_stripe tag for end-to-end Stripe test-mode round-trip (existing Phase 3 pattern).

### Wave 0 Gaps

- [ ] **Migration:** `priv/repo/migrations/20260415xxxxxx_create_accrue_connect_accounts.exs` (D5-02 schema)
- [ ] **Migration:** `priv/repo/migrations/20260415xxxxxx_add_endpoint_to_accrue_webhook_events.exs` (Critical Finding — see Pitfall 1)
- [ ] **Schema update:** `accrue/lib/accrue/webhook/webhook_event.ex` — add `field :endpoint, :string` (or `Ecto.Enum`) + thread through ingest/changeset
- [ ] **Worker update:** `accrue/lib/accrue/webhook/dispatch_worker.ex` — read `endpoint` from row, build `ctx.endpoint`, branch on `:connect` vs default
- [ ] **Test support:** `accrue/test/support/connect_case.ex` (or extension to `billing_case.ex`) — Connect-aware setup, `Accrue.Test.Factory.connect_account/1` presets for Standard/Express/Custom × fully_onboarded/partially_onboarded
- [ ] **Test support:** `accrue/test/support/stripe_fixtures.ex` — extend with Connect event fixtures (`account.updated`, `account.application.deauthorized`, `capability.updated`, `payout.{created,paid,failed}`)
- [ ] **Test files** (all 27 new files listed in the test map above)
- [ ] **Property test file:** `accrue/test/property/connect_platform_fee_property_test.exs` — StreamData generators for `(currency, gross, percent, fixed)` tuples covering JPY/USD/KWD
- [ ] **Live Stripe test file:** `accrue/test/live_stripe/connect_test.exs` — end-to-end Stripe test-mode round-trip for all 11 CONN-* requirements

## Project Constraints (from CLAUDE.md)

The following CLAUDE.md directives constrain Phase 5 implementation. Planner MUST honor them:

1. **Tech stack pins** — Elixir `~> 1.17`, OTP 27+, Phoenix `~> 1.8` (optional in core), Ecto `~> 3.13`, Postgrex `~> 0.22`, PostgreSQL 14+. No legacy.
2. **`lattice_stripe ~> 1.1`** — only path to Stripe. Phase 5 must NOT introduce direct HTTP calls or alternative Stripe wrappers.
3. **`oban ~> 2.21` community edition** — sufficient. No Oban Pro features. Phase 5 adds NO new queue (uses existing `accrue_webhooks`).
4. **`nimble_options ~> 1.1`** — D5-04 platform_fee config schema lives in `Accrue.Config` per established pattern; `NimbleOptions.docs/1` surfaces in ExDoc for free.
5. **No `:phoenix_live_view` in core `accrue` package** — D5-06 forbids framework-owned `return_url`/`refresh_url` route helpers because they would force a Phoenix hard-dep into core. Host owns the router.
6. **Webhook signature verification mandatory and non-bypassable** — Phase 5 ConnectHandler must NOT add any code path that skips signature verification.
7. **Sensitive Stripe fields never logged** — D5-06 Inspect masking on AccountLink/LoginLink URLs is the canonical mechanism. Phase 5 must NOT log raw URLs in any telemetry handler.
8. **Webhook request path <100ms p99** — ConnectHandler reducers must run async via Oban; the plug only verifies + persists + enqueues.
9. **All public entry points emit `:telemetry` start/stop/exception** — D5-03 telemetry events listed: `[:accrue, :connect, :{destination_charge, separate_charge_and_transfer, transfer}, :start|:stop|:exception]`. Plus ops: `[:accrue, :ops, :connect_account_deauthorized | :connect_capability_lost | :connect_payout_failed]`.
10. **Monorepo:** Phase 5 lives ENTIRELY in `accrue/` package. Zero `accrue_admin/` code. (Phase 7 owns ADMIN-19/20 Connect pages.)
11. **MIT license** — no third-party Connect helper libs that would taint the dep tree.
12. **Use `Accrue.Money` value type** — D5-04 platform_fee/2 is `Money` in, `Money` out. No bare integers at the helper boundary.
13. **GSD workflow enforcement** — All Phase 5 file changes must go through `/gsd-execute-phase`, not direct Edit/Write.
14. **Property tests for money math** — Non-negotiable per CLAUDE.md "billing library" framing. D5-04 ships StreamData property tests across JPY/USD/KWD.
15. **Fake Processor as primary test surface (TEST-01)** — Phase 5 Connect tests run against the Fake processor by default; live_stripe tag is for end-to-end smoke only.

## Sources

### Primary (HIGH confidence)

- **`/Users/jon/projects/accrue/.planning/phases/05-connect/05-CONTEXT.md`** [VERIFIED via Read] — locked decisions D5-01..D5-06 + canonical refs
- **`/Users/jon/projects/accrue/.planning/REQUIREMENTS.md`** [VERIFIED via Read] — PROC-05, CONN-01..11 verbatim
- **`/Users/jon/projects/accrue/.planning/ROADMAP.md`** [VERIFIED via Read] — Phase 5 goal + 5 success criteria
- **`/Users/jon/projects/accrue/.planning/STATE.md`** [VERIFIED via Read] — Phase 4 complete, prior decision history
- **`/Users/jon/projects/accrue/CLAUDE.md`** [VERIFIED via system reminder] — tech stack pins, constraints
- **`/Users/jon/projects/accrue/accrue/lib/accrue/processor/stripe.ex:810-854`** [VERIFIED via Read] — `resolve_api_version/1` template at lines 820-825 + `build_client!/1` at 831-854
- **`/Users/jon/projects/accrue/accrue/lib/accrue/webhook/webhook_event.ex:1-60`** [VERIFIED via Read] — confirms NO `endpoint` field exists; basis for Critical Finding / Pitfall 1
- **`/Users/jon/projects/accrue/accrue/lib/accrue/webhook/plug.ex`** [VERIFIED via Grep] — endpoint atom only in plug telemetry, not propagated downstream
- **`/Users/jon/projects/lattice_stripe/lib/lattice_stripe/account.ex:1-60`** [VERIFIED via Read] — Phase 17 ships full Account lifecycle; per-client AND per-request `stripe_account:` precedence documented
- **`/Users/jon/projects/lattice_stripe/lib/lattice_stripe/transfer.ex`** [VERIFIED via find] — Transfer module exists; D5-03 separate_charge_and_transfer is unblocked
- **`/Users/jon/projects/lattice_stripe/lib/lattice_stripe/account_link.ex`** [VERIFIED via ls] — exists
- **`/Users/jon/projects/lattice_stripe/lib/lattice_stripe/login_link.ex`** [VERIFIED via ls] — exists
- **`/Users/jon/projects/accrue/accrue/mix.exs`** [VERIFIED via Grep] — `lattice_stripe ~> 1.1`, `nimble_options ~> 1.1`, `mox ~> 1.2`, `stream_data ~> 1.3` confirmed pinned

### Secondary (MEDIUM confidence)

- **Stripe Connect official docs** [CITED via CONTEXT.md canonical_refs section]:
  - https://docs.stripe.com/connect — overview + account types
  - https://docs.stripe.com/connect/destination-charges — CONN-04 pattern
  - https://docs.stripe.com/connect/separate-charges-and-transfers — CONN-05 pattern
  - https://docs.stripe.com/connect/platform-pricing-tools/pricing-schemes — CONN-06 fee rounding
  - https://docs.stripe.com/api/accounts — Account object reference
  - https://docs.stripe.com/api/account_links — AccountLink shape
  - https://docs.stripe.com/api/account/login_link — LoginLink shape
  - https://docs.stripe.com/connect/webhooks — Connect webhook event catalog
- **Pay-Rails source** (https://github.com/pay-rails/pay) [CITED via CONTEXT.md] — `Pay::Stripe::Merchant` projection, per-handler webhook classes, NO platform fee calculator (validates D5-04)
- **Laravel Cashier docs** [CITED via CONTEXT.md] — `Cashier::stripe($account)` static wrapper, no native Connect support (validates D5-01 hybrid threading subsuming the wrapper)

### Tertiary (LOW confidence — flagged for verification during planning)

- **A4 platform fee rounding order** — assumed "round percent first, then add fixed, then clamp" per CONTEXT.md D5-04. Verify against Stripe pricing-schemes doc before locking property tests.
- **A5 `2026-03-25.dahlia` destination charge endpoint** — assumed `Charge.create` still works for destination charges. Verify against Stripe API changelog and `lattice_stripe/lib/lattice_stripe/charge.ex` before implementing `destination_charge/2`.

## Metadata

**Confidence breakdown:**

- **Standard stack:** HIGH — every dep is pinned in `accrue/mix.exs` and verified by direct read; lattice_stripe Connect surface verified by direct file-system inspection
- **Architecture patterns:** HIGH — every D5-* decision mirrors a pattern already shipped in Phases 1-4 (verified via line-precise canonical refs in CONTEXT.md and direct code inspection of `processor/stripe.ex:820-825`, `webhook/webhook_event.ex:1-60`, `webhook/plug.ex`)
- **Pitfalls:** HIGH for Pitfalls 1, 2, 3, 6 (codebase-grounded); MEDIUM for Pitfalls 4, 5 (depend on Stripe API behavior + host configuration discipline)
- **Test architecture:** HIGH — ExUnit + Mox + StreamData stack already in use across Phases 2-4; test support directory layout known
- **Critical finding (webhook endpoint persistence gap):** HIGH — confirmed by negative grep across `webhook_event.ex`, `ingest.ex`, `dispatch_worker.ex`

**Research date:** 2026-04-15
**Valid until:** 2026-05-15 (30 days — stable Stripe API + locked-down sibling dep tree; revisit if `lattice_stripe` 1.2 ships a breaking Connect change before Phase 5 execution begins)
