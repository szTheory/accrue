# Phase 5: Connect - Context

**Gathered:** 2026-04-15
**Status:** Ready for research & planning

<domain>
## Phase Boundary

Phase 5 delivers first-class Stripe Connect support for marketplace platforms on top of the Phase 4 webhook-hardening infra and the single `Accrue.Processor.Stripe` facade:

- **Account lifecycle** (CONN-01/02/03/08/09): Standard/Express/Custom connected accounts via `Accrue.Connect.create_account/2`, Account Links for onboarding/update flows (`create_account_link/2`), capability management via nested-map `update/4`, webhook-driven sync of `charges_enabled` / `details_submitted` / `payouts_enabled` / `capabilities` / payout schedule.
- **Stripe-Account threading** (PROC-05, CONN-11): every processor call routes `Stripe-Account` through `lattice_stripe` without leaking platform-scoped secrets; platform-scoped and connected-account-scoped calls are both reachable via the same API with explicit context.
- **Money movement** (CONN-04/05/06): destination charges and separate-charges-plus-transfers both ship as first-class functions with their own typed opts, telemetry spans, and ExDoc sections; platform fee computation via a pure Money helper.
- **Express dashboard** (CONN-07): `Accrue.Connect.create_login_link/2` returns a short-lived credential struct for one-click dashboard redirection.
- **Per-endpoint webhook routing** (CONN-10, already half-shipped by Phase 4 WH-13): the Connect-variant endpoint in `config :accrue, :webhook_endpoints, [connect: [secret: ..., mode: :connect]]` gets a dedicated handler module with reducers for `account.*` / `capability.*` / `person.*` / `account.application.*`.

**Out of scope:** Admin LV Connect pages (Phase 7 ADMIN-19/20), email/PDF (Phase 6), install generator updates for Connect config (Phase 8), OSS release wiring (Phase 9). Phase 5 lives entirely in the `accrue/` package — no `accrue_admin/` code.

</domain>

<decisions>
## Implementation Decisions

### D5-01: Stripe-Account threading — hybrid pdict + per-call opts override

**Three-level precedence chain, mirroring the existing `api_version` resolver shape.**

- **Per-call opts win:** `Accrue.Billing.subscribe(user, plan, stripe_account: "acct_...")` flows through every context fn's existing `opts` keyword into `Accrue.Processor.Stripe.build_client!/1`, passed to `LatticeStripe.Client.new!/1` as `stripe_account:`. Works across Task/Oban boundaries because opts are copied into job args.
- **Pdict default via scoped block:** `Accrue.Connect.with_account("acct_...", fn -> Accrue.Billing.subscribe(user, plan) end)` stores in process dict under a namespaced key (e.g. `{:accrue, :connected_account_id}`). Read via a new `Accrue.Connect.current_account_id/0` helper matching `Accrue.Actor.current_operation_id/0` (`accrue/lib/accrue/actor.ex:74-98`).
- **Plug for LiveView/Controller flows:** `Accrue.Plug.PutConnectedAccount, from: {MyApp.Tenancy, :current_account_id, []}` — sibling of `Accrue.Plug.PutOperationId`, sets pdict for the request cycle. Zero call-site churn for marketplace dashboards.
- **Config-level fallback:** `config :accrue, :connect, default_stripe_account: nil` (almost always `nil`; useful for single-tenant platforms that want a lexical default).
- **Resolver:** new `resolve_stripe_account/1` sibling of `resolve_api_version/1` in `accrue/lib/accrue/processor/stripe.ex` (around lines 820-825), runs `opts[:stripe_account] || Accrue.Connect.current_account_id() || Accrue.Config.get(:default_stripe_account)`.
- **Oban middleware:** Accrue already ships `Accrue.Oban.Middleware` threading `operation_id`. Extend it to carry `stripe_account` into job args, so webhook dispatch + ReconcilerJob + DunningSweeper preserve Connect context across process boundaries. Pattern is identical to operation_id; ~10 LOC.
- **Build-client integration:** `build_client!/1` currently calls `LatticeStripe.Client.new!(api_key: key, api_version: api_version)`. After D5-01, it calls `LatticeStripe.Client.new!(api_key: key, api_version: api_version, stripe_account: resolved_account)` — lattice_stripe's per-client semantics then apply platform-scoped when resolved is `nil` and connected-account-scoped when bound. Per-request opts still win over per-client per lattice_stripe's own documented precedence (see `lattice_stripe/lib/lattice_stripe/account.ex:12-30`).
- **Fake processor:** `Accrue.Processor.Fake` reads the same resolved value via an identical helper and scopes its ETS keyspace on `{stripe_account, resource_type}`. One shape, one Fake, one mental model. Test helpers `Fake.accounts_for/1`, `Fake.charges_on/1` accept either a connected account id or `:platform`.
- **Why not per-call opts only?** Churn at every marketplace call site; silent platform-mode fallback if a site forgets the opt. Doesn't compose with LiveView `on_mount` tenancy.
- **Why not pdict only?** Doesn't cross Task/Oban boundaries without the middleware, and the middleware needs opts as the wire format anyway — so opts must exist.
- **Why not a `Connect.Billing.*` sub-facade?** Doubles every Billing context fn with a Connect twin. Violates "one shape, one mental model." Cashier's static `Cashier::stripe($account)` wrapper is subsumed by `with_account/2`.
- **Coherence:** D-07 stays intact — only `Accrue.Processor.Stripe` sees `LatticeStripe`. D-05 dual bang/tuple unaffected. Pattern is symmetric with api_version so ExDoc essentially writes itself.

### D5-02: Connected account persistence — hybrid projection (extends Phase 3 D3-13/14/15)

**New schema `accrue_connect_accounts`, webhook-driven denormalization via `force_status_changeset`.**

- **Schema shape** (Ecto + migration — exact column set to be finalized in planning):
  ```elixir
  create table(:accrue_connect_accounts, primary_key: false) do
    add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
    add :stripe_account_id, :string, null: false
    add :owner_type, :string
    add :owner_id, :binary_id
    add :type, :string, null: false         # "standard" | "express" | "custom"
    add :country, :string
    add :email, :string
    add :charges_enabled, :boolean, null: false, default: false
    add :details_submitted, :boolean, null: false, default: false
    add :payouts_enabled, :boolean, null: false, default: false
    add :capabilities, :map, default: %{}   # jsonb — per-capability status from Stripe
    add :requirements, :map, default: %{}   # currently_due / eventually_due / past_due etc.
    add :data, :map, default: %{}           # full Stripe Account object as received
    add :deauthorized_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end

  create unique_index(:accrue_connect_accounts, [:stripe_account_id])
  create index(:accrue_connect_accounts, [:owner_type, :owner_id])
  create index(:accrue_connect_accounts, [:charges_enabled]) where: "charges_enabled = false"
  ```
- **Predicates** (per D3-04 — never expose raw booleans directly in the downstream Admin LV):
  ```elixir
  def charges_enabled?(%ConnectAccount{charges_enabled: true}), do: true
  def charges_enabled?(%ConnectAccount{}), do: false
  def payouts_enabled?/1
  def fully_onboarded?/1  # charges_enabled AND details_submitted AND payouts_enabled
  def deauthorized?/1     # deauthorized_at IS NOT NULL
  ```
- **Webhook updates go through `force_status_changeset/2`** — mirrors D3-17 user-path vs webhook-path split. User-path `Accrue.Connect.create_account/2` inserts the row with whatever Stripe returns; webhook `account.updated` uses `force_status_changeset` to bypass validation and always reflect Stripe (D2-29 canonicality).
- **`Accrue.Connect.Account` struct** is the first-class value passed to charge helpers (D5-03) and returned from `create_account/2` / `retrieve_account/2`.
- **Why not pure passthrough?** Admin LV Phase 7 needs list + filter + status badges with <100ms page budget and sane rate-limit behavior on platforms with non-trivial account counts. Live Stripe fetches per row fail this.
- **Why not minimal projection (id + acct_id + data jsonb only)?** Filter/sort on `charges_enabled` via jsonb expression index is ergonomically worse than typed columns and inconsistent with Phase 3 precedent. Pay's lighter `pay_merchants` shape works for Pay because Pay doesn't ship an Admin LV with filter/sort.
- **Coherence:** Extends Phase 3 D3-13/14/15 hybrid projection pattern verbatim. Reuses `force_status_changeset` from D3-17. CONN-03 success criterion has a local witness for assertion-based tests.

### D5-03: Charge API — two distinct functions

**`Accrue.Connect.destination_charge/2` and `Accrue.Connect.separate_charge_and_transfer/2` as sibling public functions, each with typed opts and its own telemetry span.**

- **Signatures:**
  ```elixir
  @spec destination_charge(params :: map(), opts :: keyword()) ::
          {:ok, %Accrue.Billing.Charge{}} | {:error, Accrue.Error.t()}
  @spec destination_charge!(params, opts) :: %Accrue.Billing.Charge{}

  @spec separate_charge_and_transfer(params :: map(), opts :: keyword()) ::
          {:ok, %{charge: %Accrue.Billing.Charge{}, transfer: map()}}
          | {:error, Accrue.Error.t()}
  @spec separate_charge_and_transfer!(params, opts) :: map()
  ```
- **`destination_charge/2`:** one `charges.create` call on PLATFORM with `transfer_data: %{destination: acct_id}` + `application_fee_amount` computed by the caller via `platform_fee/2` (D5-04). Platform sees the full charge; Stripe auto-transfers net. Uses `stripe_account: nil` at the request level — this is a platform-scoped call.
- **`separate_charge_and_transfer/2`:** either (a) charge on connected account via `stripe_account: acct` then no transfer needed (application fee routes via `application_fee_amount` on the charge), or (b) charge platform-side then explicit `transfers.create` to destination. Phase 5 ships pattern (b) — the explicit transfer model — because it's the one that needs a new `transfer/2` helper and matches "separate charges + transfers" naming.
- **Accept either `%Accrue.Connect.Account{}` or `"acct_..."` string** as `destination:` opt; internal `resolve_account/1` normalizes.
- **Return value bundles the resolved Account struct** so Admin LV can link directly to the account detail page without a second lookup.
- **`Accrue.Connect.transfer/2`:** separate public helper for the explicit Transfer API (CONN-05). Thin wrapper around `LatticeStripe.Transfer.create/3`. Used internally by `separate_charge_and_transfer/2` and directly by hosts who need bare transfers.
- **Telemetry events:**
  ```
  [:accrue, :connect, :destination_charge, :start|:stop|:exception]
  [:accrue, :connect, :separate_charge_and_transfer, :start|:stop|:exception]
  [:accrue, :connect, :transfer, :start|:stop|:exception]
  ```
- **Why not single `charge/3` with `mode:` option?** Saves one function name but loses typed opts per mode, loses distinct telemetry events, loses distinct ExDoc sections, and hides two structurally-different Stripe call shapes behind one branch. CONN-04 and CONN-05 are listed as separate success criteria precisely because they're two distinct integration patterns with different failure modes and different webhook shapes (`charge.succeeded` on platform vs on connected account).
- **Why not building-blocks only?** Fails "batteries-included" — CONN-04/05 are first-class requirements in a ship-complete v1.0.
- **Coherence:** Each function maps 1:1 onto Stripe's own docs structure. Uses D5-01 threading under the hood for the Stripe-Account header. Returns follow existing Phase 3 `Charge` projection shape. Fake processor records charges keyed on account scope so test assertions can distinguish platform from connected.

### D5-04: Platform fee helper — pure Money math, config-driven, caller-inject

**`Accrue.Connect.platform_fee/2` is a pure function over `Accrue.Money` with NimbleOptions-backed config defaults. Callers explicitly pass the result into charge helpers as `application_fee_amount:` — no auto-injection.**

- **Signature:**
  ```elixir
  @spec platform_fee(gross :: Accrue.Money.t(), opts :: keyword()) ::
          {:ok, Accrue.Money.t()} | {:error, Accrue.Error.t()}

  # opts:
  #   :rate_override - [percent: Decimal.t(), fixed: Accrue.Money.t()]
  #                    overrides config default for this call (promo rates)
  #   :min           - Accrue.Money.t()  (default from config)
  #   :max           - Accrue.Money.t()  (default from config)
  ```
- **Config schema** (extend `Accrue.Config` with NimbleOptions entry):
  ```elixir
  config :accrue, :connect,
    platform_fee: [
      percent: Decimal.new("2.9"),
      fixed: %Accrue.Money{currency: :USD, minor: 30},
      min: nil,
      max: nil
    ]
  ```
- **Computation order (Stripe-documented rounding):** round percent component first (using banker's rounding via `Accrue.Money` primitives), then add fixed, then apply min/max clamps. Property-tested across JPY (0-decimal), USD (2-decimal), KWD (3-decimal).
- **FND-01 compliance:** `%Money{}` in, `%Money{}` out. No bare integers at the helper boundary. Internally converts to minor units for the computation but returns `%Money{}`.
- **Explicit caller-inject:**
  ```elixir
  {:ok, fee} = Accrue.Connect.platform_fee(gross)
  Accrue.Connect.destination_charge(
    %{amount: gross, destination: account, customer: cust},
    application_fee_amount: fee
  )
  ```
  Money movement is auditable — the fee amount appears verbatim at the charge call site and in the resulting `:stop` telemetry event.
- **Per-account overrides are host-owned:** documented as a 5-line pattern in `guides/connect.md` — host looks up their own policy table (or reads a `fee_override` jsonb on the connected account row) and passes `rate_override:` to `platform_fee/2`. Ship-complete for the 80% flat-rate case; 20% tiered-seller case is a documented guide recipe, not a schema.
- **Why not auto-inject into charge helpers?** Silently injecting fees into money movement violates auditability — a host debugging "why is this fee 2.9% not 1.5%" should see the number at the call site, not inside framework code. Deviates from Pay precedent (Pay has no fee helper; hosts compute explicitly).
- **Why not Ecto-backed policy table?** Forces migration + CRUD on every host even if they only need `2.9%+30¢`. Pay ships nothing like this. Stripe's own Connect guidance is "compute in your app, pass `application_fee_amount` explicitly." Revisit post-v1.0 if user feedback demands built-in per-account policy (additive, zero breaking change).
- **StreamData property tests (non-negotiable):**
  - For all `(currency, gross, percent, fixed)` tuples: `fee ≤ gross`
  - Round-percent-then-add-fixed matches Stripe's documented rounding rule
  - Zero gross yields zero fee
  - Min/max clamps are idempotent: `clamp(clamp(x))` == `clamp(x)`
  - Three-decimal currencies (KWD) preserve minor-unit precision end-to-end
- **Coherence:** FND-01 Money value type; NimbleOptions schema extends existing `Accrue.Config` pattern for free ExDoc; no persistence layer, no admin CRUD needed; helper is trivially property-testable; matches Pay precedent; respects "ship complete without forcing infra."

### D5-05: Connect webhook handler — dedicated `Accrue.Webhook.ConnectHandler` module

**New handler module conditionally dispatched when webhook ctx `endpoint == :connect`. Sibling of the existing `Accrue.Webhook.DefaultHandler`. Phase 4 WH-13 already plumbed endpoint atom through the plug + event row; Phase 5 wires the dispatcher to route by it.**

- **Event coverage** (webhook → Connect projection reducers):
  - `account.updated` → upsert `accrue_connect_accounts` row via `force_status_changeset/2` with latest `charges_enabled` / `details_submitted` / `payouts_enabled` / `capabilities` / `requirements`.
  - `account.application.authorized` → new row (if missing) + stamp `authorized_at`.
  - `account.application.deauthorized` → stamp `deauthorized_at`; do NOT hard-delete (audit trail). Emit `[:accrue, :ops, :connect_account_deauthorized]` ops telemetry (OBS-03 extension).
  - `capability.updated` → partial update on `capabilities` jsonb key, refetch account if capability key is new.
  - `person.created` / `person.updated` → out of scope for Phase 5 persistence (Custom accounts only; passthrough the webhook, ack, no local mutation). Revisit if Phase 7 needs it.
  - `payout.created` / `payout.paid` / `payout.failed` on connected account endpoint → record in `accrue_events` ledger; no dedicated payout schema (out of scope for v1.0).
- **Dispatcher wiring** (`accrue/lib/accrue/webhook/dispatch_worker.ex` or equivalent):
  ```elixir
  handler =
    case ctx.endpoint do
      :connect -> Accrue.Webhook.ConnectHandler
      _        -> Accrue.Webhook.DefaultHandler
    end

  handler.handle_event(event.type, event, ctx)
  ```
  Ctx already flows from the Phase 4 plug through the event row into the dispatch worker; just needs to be read by the dispatcher.
- **ConnectHandler shape** mirrors DefaultHandler's flat `handle_event/3` clause-per-type structure (`accrue/lib/accrue/webhook/default_handler.ex:69-80`). Each reducer: load-or-fetch → force_status_changeset → Repo.transact with `Events.record_multi/2` → emit span.
- **Idempotency** piggybacks on the existing unique index on `accrue_webhook_events.processor_event_id` — same short-circuit as DefaultHandler. Connect-specific semantics (e.g., `account.application.deauthorized` needing tombstone behavior) live inside the ConnectHandler reducer, not the shared infra.
- **Why not extend DefaultHandler?** DefaultHandler already has ~10+ event-type clauses; adding another 6-8 for Connect mixes platform-customer events and connected-account events in one module. Pay's per-area handler classes (`Pay::Webhooks::Stripe::AccountUpdated` as a sibling of `Pay::Webhooks::Stripe::CustomerUpdated`) validate splitting on endpoint boundary even in a framework with a shared dispatch table.
- **Why not user-implemented behaviour?** Violates ship-complete — D2-29 says Stripe is canonical and account webhooks drive local state, which implies built-in reconciliation. Host-override hook already exists via the Phase 2 user-handler pattern; Connect-aware hosts can subscribe to `[:accrue, :connect, :*]` telemetry for custom logic without re-implementing sync.
- **Coherence:** Extends Phase 4 WH-13 endpoint-atom infra. Reuses D3-17 force_status_changeset pattern. Respects D2-29. Leaves room for Connect-specific idempotency without polluting DefaultHandler.

### D5-06: AccountLink / LoginLink return shape — structs with Inspect-masked `:url`

**`%Accrue.Connect.AccountLink{url, expires_at, created, object}` and `%Accrue.Connect.LoginLink{url, created}` — both with `defimpl Inspect` masking `:url` as `<redacted>`, mirroring Phase 4 `Accrue.BillingPortal.Session` verbatim.**

- **Module layout** (direct copy of `accrue/lib/accrue/billing_portal/session.ex:149-178` Inspect masking pattern):
  ```elixir
  defmodule Accrue.Connect.AccountLink do
    @enforce_keys [:url, :expires_at, :created, :object]
    defstruct [:url, :expires_at, :created, :object]

    @type t :: %__MODULE__{
            url: String.t(),
            expires_at: DateTime.t(),
            created: DateTime.t(),
            object: String.t()  # "account_link"
          }

    @spec from_stripe(map()) :: t()
    def from_stripe(%{"url" => url, "expires_at" => exp, "created" => c, "object" => o}), do: ...

    defimpl Inspect do
      def inspect(%{url: _, expires_at: exp, created: c}, _opts) do
        concat(["#Accrue.Connect.AccountLink<url: <redacted>, expires_at: ", inspect(exp), ">"])
      end
    end
  end

  defmodule Accrue.Connect.LoginLink do
    @enforce_keys [:url, :created]
    defstruct [:url, :created]
    # identical Inspect masking
  end
  ```
- **Public API** (dual bang/tuple per D-05):
  ```elixir
  @spec create_account_link(account :: Accrue.Connect.Account.t() | String.t(), opts :: keyword()) ::
          {:ok, Accrue.Connect.AccountLink.t()} | {:error, Accrue.Error.t()}
  @spec create_account_link!(account, opts) :: Accrue.Connect.AccountLink.t()

  @spec create_login_link(account, opts) ::
          {:ok, Accrue.Connect.LoginLink.t()} | {:error, Accrue.Error.t()}
  @spec create_login_link!(account, opts) :: Accrue.Connect.LoginLink.t()
  ```
- **`opts` for `create_account_link/2`:**
  - `:return_url` (required — host's post-onboarding landing page)
  - `:refresh_url` (required — host's "link expired, generate a new one" page)
  - `:type` (`"account_onboarding" | "account_update"`, default `"account_onboarding"`)
  - `:collect` (`"eventually_due" | "currently_due"`, default `"currently_due"`)
- **Do NOT ship framework-owned `return_url` / `refresh_url` helpers.** Host owns its Phoenix router and controllers for onboarding resume. Baking URL generation into Accrue would force a Phoenix hard-dep into core (Phase 4 explicitly kept it out — `phoenix_live_view` is hard-dep only in `accrue_admin`). Document the pattern in `guides/connect.md`: "your Phoenix controller for `/connect/onboarding/resume` calls `Accrue.Connect.create_account_link/2` and redirects to the returned url."
- **Why not bare URL string?** Breaks Phase 4 CHKT-04 precedent, loses `expires_at` (onboarding UX needs expiry countdown), no Inspect masking hook — URL leaks into Logger/telemetry handlers. Would force a breaking v1.x change when expiry is demanded.
- **Why not three-tuple `{:ok, url, expires_at}`?** Unconventional in Elixir, breaks `with`/`else` chains, still no Inspect masking for the URL.
- **Credential hygiene rationale:** AccountLink URL is a bearer onboarding credential valid until `expires_at` (usually ~1 hour); LoginLink URL is a 5-minute Express dashboard bearer token. Both must never appear in logs, crash dumps, or telemetry metadata. `defimpl Inspect` is the blessed Elixir mechanism.
- **Coherence:** Matches Phase 4 CHKT-04 `BillingPortal.Session` shape verbatim — a host dev who learned the portal session struct in Phase 4 finds AccountLink / LoginLink identically shaped in Phase 5. Principle of least surprise.

### Claude's Discretion

Downstream researcher and planner pick defaults for the following — not blocked on the user:

- **Account type handling at onboarding (CONN-01).** Default: `Accrue.Connect.create_account/2` takes `type: :standard | :express | :custom` as required opt (no default — force host to pick). Each type has different capability requirements; ExDoc shows all three patterns side-by-side.
- **Capability request idiom.** Default: follow lattice_stripe's documented pattern (see `lattice_stripe/lib/lattice_stripe/account.ex` moduledoc) — use nested-map `update/4` with `capabilities: %{"card_payments" => %{requested: true}}`. Do NOT ship a `request_capability/3` helper per lattice_stripe Phase 17 D-04b ("fake ergonomics — the capability name set is an open growing string enum"). Document the pattern in `guides/connect.md`.
- **`Accrue.Connect.Account.Requirements` nested struct.** Default: store Stripe's `requirements` jsonb verbatim; no typed nested struct mirror. Accrue doesn't lint currently_due/past_due/eventually_due at the library layer — host decides how to surface in their UI.
- **Payout schedule config (CONN-08).** Default: passthrough via `Accrue.Connect.update_account/3` with `settings: %{payouts: %{schedule: ...}}` nested map. No dedicated `Accrue.Connect.set_payout_schedule/3` helper — same reasoning as capability request idiom.
- **Express dashboard LoginLink vs Account retrieve dashboard URL.** Default: ship only LoginLink (the Stripe-blessed Express-account shortcut). Standard-type accounts own their own dashboard login; Custom-type has no dashboard. Document in the Connect guide.
- **Ops telemetry events for Connect** (OBS-03 extension from Phase 4 D4):
  - `[:accrue, :ops, :connect_account_deauthorized]`
  - `[:accrue, :ops, :connect_capability_lost]` — when a previously-active capability flips to inactive
  - `[:accrue, :ops, :connect_payout_failed]`
- **Test fixtures:** add `Accrue.Test.Factory.connect_account/1` with presets for Standard/Express/Custom, fully_onboarded and partially_onboarded.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 5 scope + requirements
- `.planning/ROADMAP.md` §"Phase 5: Connect" — goal, requirements (PROC-05, CONN-01..11), success criteria
- `.planning/REQUIREMENTS.md` — PROC-05, CONN-01 through CONN-11
- `.planning/PROJECT.md` — vision, constraints, core value, release model
- `/Users/jon/projects/accrue/CLAUDE.md` — tech stack pins (`lattice_stripe ~> 1.1` post-Phase 4 D4-01)

### Prior phase decisions that constrain Phase 5
- `.planning/phases/01-foundations/01-CONTEXT.md` — FND-01 Accrue.Money (D5-04 depends on this), Fake processor strategy, dual bang/tuple API (D-05), `Accrue.Error` shape
- `.planning/phases/02-schemas-webhook-plumbing/02-CONTEXT.md` — D2-09 (transact+events atomicity), D2-29 (Stripe canonical — D5-02 projection depends on this), D2-33 (webhook event status enum), D2-37 (Oban-as-retry engine)
- `.planning/phases/03-core-subscription-lifecycle/03-CONTEXT.md` — D3-04 (predicates, never raw status — applies to D5-02 connect account predicates), D3-13/14/15 (hybrid projection pattern — D5-02 extends verbatim), D3-17 (force_status_changeset on webhook path — D5-05 uses), operation_id pdict (D5-01 template)
- `.planning/phases/04-advanced-billing-webhook-hardening/04-CONTEXT.md` — D4-01 (lattice_stripe 1.1 consumption), D4-04 (multi-endpoint webhook plug, WH-13 — D5-05 wires the handler side), CHKT-04 (BillingPortal.Session struct with Inspect masking — D5-06 mirrors verbatim), Oban queues conventions

### Accrue codebase touchpoints for Phase 5 integration
- `/Users/jon/projects/accrue/accrue/lib/accrue/processor/stripe.ex` — lines 60-80 (create_customer pattern to mirror for create_account), lines 820-854 (resolve_api_version + build_client! — D5-01 integration point; must add `resolve_stripe_account/1` sibling and pass `stripe_account:` into `LatticeStripe.Client.new!/1`)
- `/Users/jon/projects/accrue/accrue/lib/accrue/processor.ex` — behaviour callback surface; Phase 5 adds Connect callbacks: `create_account/2`, `retrieve_account/2`, `update_account/3`, `delete_account/2`, `reject_account/3`, `list_accounts/2`, `create_account_link/2`, `create_login_link/2`, `create_transfer/2`, `retrieve_transfer/2`
- `/Users/jon/projects/accrue/accrue/lib/accrue/actor.ex` lines 74-98 — `current_operation_id/0` + `put_operation_id/1` pattern to mirror for `Accrue.Connect.current_account_id/0` + `Accrue.Connect.with_account/2`
- `/Users/jon/projects/accrue/accrue/lib/accrue/stripe.ex` — `Accrue.Stripe.with_api_version/2` template to mirror for `Accrue.Connect.with_account/2`
- `/Users/jon/projects/accrue/accrue/lib/accrue/plug/` — `PutOperationId` template to mirror for `Accrue.Plug.PutConnectedAccount`
- `/Users/jon/projects/accrue/accrue/lib/accrue/oban/` — middleware threading operation_id; extend to carry `stripe_account`
- `/Users/jon/projects/accrue/accrue/lib/accrue/billing_portal/session.ex` lines 149-178 — `defimpl Inspect` masking pattern; D5-06 copies verbatim for AccountLink + LoginLink
- `/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex` lines 14-42 + 69-80 — dispatch shape and reducer pattern for D5-05 ConnectHandler to mirror
- `/Users/jon/projects/accrue/accrue/lib/accrue/webhook/plug.ex` lines 71-95 — endpoint atom routing (Phase 4 WH-13); D5-05 reads `ctx.endpoint` to select handler
- `/Users/jon/projects/accrue/accrue/lib/accrue/config.ex` — NimbleOptions schema extension pattern for D5-04 `:connect, :platform_fee` config + `:connect, :default_stripe_account` fallback

### lattice_stripe (sibling repo — read before implementing any Connect surface)
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/account.ex` — `LatticeStripe.Account.{create,retrieve,update,delete,reject,list,stream!}` — full Phase 17 Connect lifecycle. Moduledoc lines 12-30 document per-client vs per-request `stripe_account:` precedence (D5-01 threading contract)
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/account/capability.ex` — capability shape
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/account/requirements.ex` — reused at both `account.requirements` and `account.future_requirements`
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/account_link.ex` — AccountLink API shape for D5-06
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/login_link.ex` — Express dashboard LoginLink API shape for D5-06
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/client.ex` — `Client.new!/1` with `stripe_account:` opt — D5-01 integration
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/transfer.ex` — Transfer API for D5-03 `separate_charge_and_transfer/2` (if it exists; if not, Phase 5 dev may need to add it to lattice_stripe first — verify in research phase)
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/charge.ex` — existing charge create; D5-03 destination_charge uses with `transfer_data:` opt

### Stripe official documentation
- https://docs.stripe.com/connect — Connect overview, account types comparison
- https://docs.stripe.com/connect/destination-charges — CONN-04 destination charge pattern (primary reference for D5-03)
- https://docs.stripe.com/connect/separate-charges-and-transfers — CONN-05 separate-charges + transfers pattern
- https://docs.stripe.com/connect/platform-pricing-tools/pricing-schemes — CONN-06 fee computation guidance (D5-04 rounding rules)
- https://docs.stripe.com/connect/marketplace/tasks/app-fees — application_fee_amount semantics
- https://docs.stripe.com/api/accounts — Account object reference (fields for D5-02 projection)
- https://docs.stripe.com/api/account_links — AccountLink shape (D5-06)
- https://docs.stripe.com/api/account/login_link — LoginLink shape (D5-06)
- https://docs.stripe.com/api/capabilities — capability object shape
- https://docs.stripe.com/connect/webhooks — Connect webhook event catalog (D5-05 event coverage)
- https://docs.stripe.com/api/transfers — Transfer API for D5-03

### Prior-art libs (inspiration, not copy-paste)
- https://github.com/pay-rails/pay — Pay-Rails Connect support: `Pay::Stripe::Merchant` model (typed columns for `onboarding_complete` etc — minimal-projection precedent that Accrue intentionally extends to hybrid), per-webhook-type handler classes (`Pay::Webhooks::Stripe::AccountUpdated` — D5-05 splitting precedent). **Pay ships NO platform fee calculator — validates D5-04 "keep it simple" decision.**
- https://github.com/pay-rails/pay/blob/main/docs/marketplaces/stripe_connect.md — Pay Connect docs (caller-inject fee pattern)
- https://laravel.com/docs/12.x/billing — Cashier does NOT natively ship Connect; documented via Stripe PHP SDK direct. Cashier's static `Cashier::stripe($account)` wrapper shape is subsumed by D5-01's `with_account/2`.

### Architectural precedent (Elixir ecosystem)
- `Logger.metadata/1` — pdict-based scoped metadata, same mental model as D5-01 `with_account/2`
- `Ecto.Repo` dynamic repo model — precedent for "per-operation context via opts OR pdict"

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (from Phases 1-4)
- **`Accrue.Processor.Stripe.build_client!/1`** — Phase 5 extends to pass `stripe_account: resolved` into `LatticeStripe.Client.new!/1`. One-line change; the resolver helper is the real work.
- **`Accrue.Processor.Stripe.resolve_api_version/1`** (lines 820-825) — template for the new `resolve_stripe_account/1` sibling.
- **`Accrue.Actor.current_operation_id/0`** (lines 74-98) — pdict access pattern mirrored for `Accrue.Connect.current_account_id/0`.
- **`Accrue.Plug.PutOperationId`** — template for `Accrue.Plug.PutConnectedAccount`.
- **`Accrue.Oban.Middleware`** — already threads operation_id; extend to carry `stripe_account` into job args.
- **`Accrue.Webhook.Plug`** (lines 71-95) — Phase 4 WH-13 endpoint-atom routing; D5-05 reads `ctx.endpoint` to select handler.
- **`Accrue.Webhook.DefaultHandler`** — `handle_event/3` flat clause shape mirrored in new `Accrue.Webhook.ConnectHandler`. Reducer pattern (load-or-fetch → force_status_changeset → Repo.transact + Events.record_multi → emit span) copied verbatim.
- **`Accrue.BillingPortal.Session`** (lines 149-178) — `@enforce_keys` struct + `from_stripe/1` + `defimpl Inspect` url-masking pattern copied verbatim for D5-06 AccountLink / LoginLink.
- **`Accrue.Billing.Query`** — add `Query.connect_accounts_needing_sync/0` and `Query.connect_accounts_fully_onboarded/0` predicates.
- **`Accrue.Events.record_multi/2`** — all Phase 5 mutations slot through this via `Repo.transact/2`.
- **`Accrue.Config`** — extends with `:connect` key containing `:platform_fee` schema + `:default_stripe_account` fallback.
- **`Accrue.Processor.Fake`** — extends with: connect account lifecycle (create/retrieve/update/reject/list), `stripe_account`-scoped ETS keyspace, `create_transfer/2`, `create_account_link/2`, `create_login_link/2`, test-helper `Fake.accounts_for/1`.

### Established Patterns
- **Commit-then-call-Stripe** (D2-09 / D3-18) — D5-02 `create_account/2` commits local row first, then Stripe call, then webhook-driven sync (same as subscription create path).
- **Dual bang/tuple API** (D-05) — every new Connect public fn ships `/1` + `!/1`.
- **`force_status_changeset/2` on webhook path** (D3-17) — D5-05 reducers use this for Connect account state.
- **Hybrid projection** (D3-13/14/15) — D5-02 extends verbatim.
- **Inspect masking for credentials** (Phase 4 CHKT-04) — D5-06 copies verbatim.
- **NimbleOptions schema in Accrue.Config** — D5-04 platform_fee entry gets free ExDoc via NimbleOptions.docs/1.
- **Three-level precedence chain** (opts > pdict > config) — D5-01 mirrors `resolve_api_version/1`.
- **StreamData property tests for money math** — D5-04 non-negotiable.
- **Oban queues:** existing `accrue_webhooks`, `accrue_mailers`, `accrue_maintenance`, `accrue_dunning`, `accrue_meters`. Phase 5 adds NO new queue — Connect events flow through `accrue_webhooks` unchanged.

### Integration Points
- **`lattice_stripe ~> 1.1`** sibling repo — `LatticeStripe.Account`, `AccountLink`, `LoginLink` already shipped. Verify `LatticeStripe.Transfer` exists; if not, bump lattice_stripe first.
- **Host app's Phoenix router** — owns `return_url` / `refresh_url` for onboarding resume. Accrue documents the controller pattern in `guides/connect.md`; does NOT generate URLs.
- **Host app's `Oban` config** — no new queue. Oban middleware extension carries `stripe_account` across job boundaries.
- **Phase 7 `accrue_admin`** — consumes `Accrue.Connect.list_accounts/1`, subscribes to `[:accrue, :ops, :connect_*]` telemetry. Zero Phase 7 logic in Phase 5.
- **Phase 6 Email + PDF** — no direct Phase 5 coupling; `receipt` emails on Connect destination charges render platform branding by default, per-account branding overrides in Phase 6.

</code_context>

<specifics>
## Specific Ideas

- **"Cashier-for-Elixir" parity means subsuming Cashier's static `Cashier::stripe($account)` wrapper** — D5-01's hybrid threading gives Cashier-style users `with_account/2` AND Pay-style users per-call opts, without a sub-facade.
- **"One shape, one Fake, one mental model"** — the single most important principle for D5-01. Sub-facade (`Accrue.Connect.Billing.*`) is the anti-pattern to avoid.
- **Principle of least surprise means symmetry with what shipped in earlier phases.** D5-06 structs match Phase 4 CHKT-04 `BillingPortal.Session` verbatim. D5-01 mirrors `resolve_api_version/1`. D5-02 extends D3-13/14/15. D5-05 mirrors `DefaultHandler`. Nothing in Phase 5 invents a new pattern.
- **Credential hygiene is non-negotiable.** AccountLink URLs, LoginLink URLs, and portal session URLs are all short-lived bearer credentials. All three go through `defimpl Inspect` masking. A host who logs a `%Accrue.Connect.AccountLink{}` to Logger or Sentry must see `<redacted>`, not the actual URL.
- **Ship-complete for the 80% marketplace case, document the 20% as host-app patterns.** D5-04 platform_fee config handles the flat-rate case; tiered-seller per-account overrides are a 5-line guide recipe, not a schema. D5-06 onboarding URLs are host-owned; Accrue ships the link, not the routing.
- **Money movement must be auditable at the call site.** D5-04 explicit caller-inject of `application_fee_amount` beats auto-injection — a debugging host needs to see the fee amount in the code and in telemetry metadata, not dig through framework internals.

</specifics>

<deferred>
## Deferred Ideas

- **Ecto-backed per-account fee policy table** — deferred to v1.x (additive, zero breaking change). Hosts who need tiered fees today wire a 5-line lookup + `rate_override:` opt per the guide. (Raised under D5-04.)
- **Framework-owned `return_url` / `refresh_url` route helpers** — rejected; host owns its Phoenix router. Would force a Phoenix hard-dep into core, violates Phase 4 Phoenix-optional-in-core boundary. (Raised under D5-06.)
- **`Accrue.Connect.request_capability/3` helper** — rejected (per lattice_stripe Phase 17 D-04b). Capability names are an open, growing string enum; ergonomics are fake. Document nested-map `update/4` idiom instead. (Raised under Claude's Discretion.)
- **Dedicated payout schema** (`accrue_connect_payouts`) — deferred to v1.x. Phase 5 records `payout.*` events to `accrue_events` ledger only; no typed projection. (Raised under D5-05.)
- **Custom-type account `person.*` webhook persistence** — deferred to v1.x. Phase 5 passthrough ack, no local mutation. Revisit if Phase 7 admin UI needs to surface people. (Raised under D5-05.)
- **Standard-type dashboard redirect helper** — rejected. Standard accounts own their own dashboard login; only Express has a Stripe-blessed shortcut (LoginLink). (Raised under Claude's Discretion.)
- **`Accrue.Connect.Account.Requirements` typed nested struct** — rejected. Store Stripe's `requirements` as jsonb verbatim; host decides how to surface currently_due / past_due in UI. (Raised under Claude's Discretion.)
- **`Accrue.Connect.Billing.*` sub-facade** — rejected (D5-01 Option 4). Doubles API surface, violates "one shape, one mental model." Subsumed by `with_account/2`.
- **OAuth-based Connect onboarding (legacy Stripe pattern)** — out of scope. Phase 5 uses Account Links only, matching modern Stripe guidance.

</deferred>

---

*Phase: 05-connect*
*Context gathered: 2026-04-15*
