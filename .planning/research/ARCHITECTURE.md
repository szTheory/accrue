# Architecture Research

**Domain:** Elixir/Phoenix payments & billing library (Accrue)
**Researched:** 2026-04-11
**Confidence:** HIGH (grounded in PROJECT.md locked decisions, direct survey of lattice_stripe and sigra source)

## Scope

This document translates the locked decisions in `PROJECT.md` into a concrete architectural blueprint for the Accrue monorepo:

- Module tree for `accrue/` core and `accrue_admin/` companion
- Layering and context boundaries (public API vs internal)
- Four canonical data flows (subscribe, webhook, PDF, email)
- Supervision tree and application boot behavior
- Exact integration seams with `lattice_stripe` and `sigra`
- Topological build order — what must exist before what
- Before/after shape of a Phoenix host app across `mix accrue.install`

A developer should be able to read this file and know where every source file goes, what its neighbors are, and why.

---

## 1. System Overview

Accrue is a **headless billing kernel** (`accrue`) plus a **companion LiveView admin UI** (`accrue_admin`), both living in a single monorepo but published as two Hex packages. The host Phoenix app is the integration point — Accrue never owns user schemas, never starts a supervision tree the host doesn't explicitly mount, and never hard-links LiveView into the core.

```
┌──────────────────────────────────────────────────────────────────────┐
│                      HOST PHOENIX APP (MyApp)                        │
│                                                                      │
│  ┌────────────────────┐   ┌──────────────────┐  ┌────────────────┐   │
│  │  MyAppWeb (router, │   │   MyApp.Billing  │  │  MyApp.Accounts│   │
│  │  controllers, LVs) │──▶│  (GENERATED      │  │   (host-owned  │   │
│  │                    │   │   context facade)│  │   User/Org)    │   │
│  └──────────┬─────────┘   └────────┬─────────┘  └────────┬───────┘   │
│             │                      │                     │          │
│             │                      │  use Accrue.Billable│          │
│             ▼                      ▼                     ▼          │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │            Accrue.Webhook.Plug   (mounted in Endpoint)       │   │
│  └────────────────────────┬─────────────────────────────────────┘   │
└───────────────────────────┼──────────────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────────────┐
│                         ACCRUE CORE (accrue/)                        │
│                                                                      │
│  ┌───────────────────── PUBLIC API SURFACE ─────────────────────┐   │
│  │  Accrue  (top-level sugar)      Accrue.Billable (macro)      │   │
│  │  Accrue.Billing.{Customers,                                   │   │
│  │    Subscriptions, Invoices,    Accrue.Events (query API)     │   │
│  │    Charges, PaymentMethods,    Accrue.Telemetry (names)      │   │
│  │    Refunds, Coupons, Checkout} Accrue.Error (hierarchy)      │   │
│  └──────────────────────┬────────────────────────────────────────┘   │
│                         │                                            │
│  ┌──────────────────────▼────────────────────────────────────────┐   │
│  │                    BEHAVIOURS (extension points)              │   │
│  │  Accrue.Processor   Accrue.Auth   Accrue.Mailer   Accrue.PDF  │   │
│  └────┬────────────┬───────────┬───────────┬────────────┬────────┘   │
│       │            │           │           │            │            │
│  ┌────▼────┐  ┌────▼───┐  ┌────▼────┐ ┌────▼────┐  ┌────▼─────┐      │
│  │Processor│  │ Auth   │  │ Mailer  │ │  PDF    │  │ Integra- │      │
│  │.Stripe  │  │.Default│  │.Swoosh  │ │.Chromic │  │  tions   │      │
│  │.Fake    │  │.Sigra* │  │.Test    │ │.Test    │  │.Sigra*   │      │
│  └────┬────┘  └────┬───┘  └─────────┘ └─────────┘  └────┬─────┘      │
│       │            │                                    │            │
│  ┌────▼────────────▼──── INTERNAL ENGINES ──────────────▼─────────┐  │
│  │  Webhook (Plug, Verifier, Dispatcher, Worker, Idempotency)     │  │
│  │  Events  (Ledger, Recorder, Upcaster, Query, Bridge)           │  │
│  │  Billing.Schemas (Customer/Subscription/Invoice/...)           │  │
│  │  Config (NimbleOptions) · Application (supervisor)             │  │
│  └────┬────────────────────────────────────────────────────┬──────┘  │
└───────┼────────────────────────────────────────────────────┼─────────┘
        │                                                    │
        ▼                                                    ▼
┌──────────────────┐                              ┌───────────────────┐
│   lattice_stripe │                              │    Host Repo      │
│   (Stripe HTTP)  │                              │   (PostgreSQL 14+)│
└──────────────────┘                              └───────────────────┘

                    *conditionally compiled — only if dep present
```

Parallel to this, `accrue_admin/` ships a LiveView dashboard that reads Accrue's schemas directly (same Repo, same Ecto context) and uses `Accrue.Auth` for access control. It depends on `accrue` but not vice versa.

---

## 2. Monorepo Layout

```
accrue/                                       # git root
├── .github/workflows/                        # shared CI (matrix across both apps)
├── guides/                                   # shared ExDoc guides
│   ├── quickstart.md
│   ├── configuration.md
│   ├── testing.md
│   ├── sigra-integration.md
│   ├── custom-processors.md
│   ├── custom-pdf-adapter.md
│   ├── brand-customization.md
│   └── admin-ui.md
├── LICENSE                                   # single root MIT
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── SECURITY.md
├── README.md
├── mix.exs                                   # umbrella-style root (no children), or minimal
│
├── accrue/                                   # CORE PACKAGE (published to Hex)
│   ├── mix.exs                               # name: :accrue
│   ├── CHANGELOG.md
│   ├── lib/
│   │   ├── accrue.ex                         # top-level sugar + @moduledoc landing
│   │   ├── accrue/
│   │   │   ├── application.ex                # OTP app, lightweight supervisor
│   │   │   ├── config.ex                     # NimbleOptions schema + fetch helpers
│   │   │   ├── error.ex                      # exception hierarchy root
│   │   │   ├── telemetry.ex                  # event names + span helpers
│   │   │   ├── billable.ex                   # `use Accrue.Billable` macro
│   │   │   │
│   │   │   ├── billing/                      # DOMAIN KERNEL (pure + Ecto)
│   │   │   │   ├── customers.ex              # public context fns (list/get/upsert)
│   │   │   │   ├── customer.ex               # schema (polymorphic owner)
│   │   │   │   ├── subscriptions.ex          # public context fns (lifecycle)
│   │   │   │   ├── subscription.ex           # schema + state machine
│   │   │   │   ├── subscription_item.ex
│   │   │   │   ├── subscription_schedule.ex
│   │   │   │   ├── invoices.ex
│   │   │   │   ├── invoice.ex                # schema + state machine
│   │   │   │   ├── invoice_line_item.ex
│   │   │   │   ├── charges.ex
│   │   │   │   ├── charge.ex
│   │   │   │   ├── payment_intents.ex
│   │   │   │   ├── payment_intent.ex
│   │   │   │   ├── setup_intents.ex
│   │   │   │   ├── setup_intent.ex
│   │   │   │   ├── payment_methods.ex
│   │   │   │   ├── payment_method.ex
│   │   │   │   ├── refunds.ex
│   │   │   │   ├── refund.ex
│   │   │   │   ├── coupons.ex
│   │   │   │   ├── coupon.ex
│   │   │   │   ├── promotion_code.ex
│   │   │   │   ├── price.ex
│   │   │   │   ├── product.ex
│   │   │   │   ├── money.ex                  # zero-decimal-safe money helpers
│   │   │   │   └── state_machine.ex          # shared state transition helpers
│   │   │   │
│   │   │   ├── processor.ex                  # @behaviour (create_customer, etc.)
│   │   │   ├── processor/
│   │   │   │   ├── stripe.ex                 # first-party adapter (lattice_stripe)
│   │   │   │   ├── stripe/
│   │   │   │   │   ├── customer.ex           # per-resource translation layer
│   │   │   │   │   ├── subscription.ex
│   │   │   │   │   ├── invoice.ex
│   │   │   │   │   ├── charge.ex
│   │   │   │   │   ├── refund.ex
│   │   │   │   │   ├── payment_method.ex
│   │   │   │   │   ├── checkout.ex
│   │   │   │   │   ├── connect.ex            # Stripe-Account header threading
│   │   │   │   │   ├── idempotency.ex        # deterministic key derivation
│   │   │   │   │   └── error.ex              # LatticeStripe.Error -> Accrue.Error
│   │   │   │   └── fake.ex                   # in-memory processor + test clock
│   │   │   │
│   │   │   ├── auth.ex                       # @behaviour
│   │   │   ├── auth/
│   │   │   │   ├── default.ex                # no-op / assigns-based fallback
│   │   │   │   └── plug.ex                   # `plug :require_admin` helper
│   │   │   │
│   │   │   ├── mailer.ex                     # @behaviour
│   │   │   ├── mailer/
│   │   │   │   ├── swoosh.ex                 # real adapter
│   │   │   │   ├── test.ex                   # Swoosh.Adapters.Test wrapper
│   │   │   │   └── templates/                # HEEx templates shipped in lib
│   │   │   │       ├── layout.html.heex
│   │   │   │       ├── layout.text.eex
│   │   │   │       ├── receipt.html.heex
│   │   │   │       ├── payment_failed.html.heex
│   │   │   │       ├── trial_ending.html.heex
│   │   │   │       ├── invoice_finalized.html.heex
│   │   │   │       └── ... (full set from PROJECT.md)
│   │   │   ├── emails.ex                     # public: Accrue.Emails.send_receipt/1
│   │   │   │
│   │   │   ├── pdf.ex                        # @behaviour
│   │   │   ├── pdf/
│   │   │   │   ├── chromic.ex                # default adapter
│   │   │   │   ├── test.ex                   # assertion-based test adapter
│   │   │   │   └── templates/
│   │   │   │       └── invoice.html.heex     # shared with email invoice template
│   │   │   │
│   │   │   ├── webhook/                      # INGEST PIPELINE
│   │   │   │   ├── plug.ex                   # raw-body + signature verify + persist
│   │   │   │   ├── cache_body_reader.ex      # Plug.Parsers body_reader
│   │   │   │   ├── verifier.ex               # HMAC check (delegates to lattice_stripe)
│   │   │   │   ├── event.ex                  # `accrue_webhook_events` schema
│   │   │   │   ├── idempotency.ex            # insert-or-skip on processor_event_id
│   │   │   │   ├── dispatcher.ex             # enqueue Oban job
│   │   │   │   ├── worker.ex                 # Oban.Worker — dispatches to handler
│   │   │   │   ├── handler.ex                # @behaviour user implements
│   │   │   │   ├── default_handler.ex        # built-in state reconciliation
│   │   │   │   └── replay.ex                 # requeue / dead-letter tooling
│   │   │   │
│   │   │   ├── events/                       # APPEND-ONLY LEDGER
│   │   │   │   ├── event.ex                  # `accrue_events` schema
│   │   │   │   ├── recorder.ex               # Ecto.Multi-friendly insert
│   │   │   │   ├── upcaster.ex               # schema_version evolution
│   │   │   │   ├── query.ex                  # timeline / replay-as-of / analytics
│   │   │   │   └── sigra_bridge.ex           # conditional Sigra.Audit passthrough
│   │   │   │
│   │   │   ├── integrations/
│   │   │   │   └── sigra.ex                  # conditional `if Code.ensure_loaded?`
│   │   │   │
│   │   │   └── test/                         # public test helpers (not test support)
│   │   │       ├── helpers.ex                # assert_email_sent/assert_pdf_rendered
│   │   │       └── factories.ex              # ExMachina-style
│   │   │
│   │   └── mix/tasks/
│   │       ├── accrue.install.ex             # generator: migrations + MyApp.Billing
│   │       ├── accrue.gen.migration.ex       # regenerate a migration slice
│   │       └── accrue.gen.handler.ex         # scaffold a webhook handler
│   │
│   ├── priv/
│   │   ├── templates/                        # source files copied by installer
│   │   │   ├── migrations/
│   │   │   │   ├── 01_create_accrue_customers.ex.eex
│   │   │   │   ├── 02_create_accrue_subscriptions.ex.eex
│   │   │   │   ├── 03_create_accrue_invoices.ex.eex
│   │   │   │   ├── 04_create_accrue_webhook_events.ex.eex
│   │   │   │   ├── 05_create_accrue_events.ex.eex
│   │   │   │   └── 06_accrue_events_role_grants.ex.eex
│   │   │   ├── billing_context.ex.eex        # the MyApp.Billing facade
│   │   │   ├── billing_handler.ex.eex        # default webhook handler
│   │   │   └── config_snippet.exs.eex
│   │   └── repo/                             # seeds? not yet
│   │
│   └── test/
│       ├── accrue/...                        # mirror of lib tree
│       └── test_helper.exs
│
└── accrue_admin/                             # COMPANION PACKAGE (published separately)
    ├── mix.exs                               # name: :accrue_admin, dep: {:accrue, in_umbrella: true}
    ├── CHANGELOG.md
    └── lib/
        ├── accrue_admin.ex
        ├── accrue_admin/
        │   ├── router.ex                     # `accrue_admin "/billing"` macro
        │   ├── live/                         # LiveViews
        │   │   ├── dashboard_live.ex
        │   │   ├── customers_live.ex
        │   │   ├── customer_show_live.ex
        │   │   ├── subscriptions_live.ex
        │   │   ├── invoices_live.ex
        │   │   ├── invoice_show_live.ex
        │   │   ├── charges_live.ex
        │   │   ├── coupons_live.ex
        │   │   ├── webhook_events_live.ex
        │   │   └── webhook_event_show_live.ex
        │   ├── components/
        │   │   ├── layout.ex                 # app shell, nav, theme toggle
        │   │   ├── core_components.ex
        │   │   ├── state_badge.ex            # idiomatic pill for subscription/invoice states
        │   │   ├── money.ex                  # formatted money component
        │   │   ├── timeline.ex               # for accrue_events activity feed
        │   │   └── webhook_inspector.ex
        │   ├── theme.ex                      # Ink/Slate/Fog/Paper/Moss/Cobalt/Amber
        │   └── telemetry.ex                  # admin-specific emits
        └── priv/static/                      # compiled CSS, logo, fonts
```

### 2.1 Layout Rationale

- **Sibling mix projects, not umbrella children.** PROJECT.md says "sibling mix projects" with independent Hex releases. The root `mix.exs` is a thin no-op; `accrue/` and `accrue_admin/` each have their own `mix.exs` and `CHANGELOG.md`. CI runs both matrices.
- **`billing/` holds schemas AND context modules inside the library.** These are the low-level building blocks. The host-owned `MyApp.Billing` generated context is a *facade* over these, not a replacement — it exists so host code has a stable named module to call and so Accrue's internals can evolve without breaking imports.
- **`processor/stripe/` split by resource** mirrors `lattice_stripe/lib/lattice_stripe/` which is also split by resource (customer.ex, payment_intent.ex, refund.ex). This keeps translation layers narrow and unit-testable.
- **`webhook/` and `events/` are sibling internal engines**, both one level under `accrue/`. Neither depends on the other at the module level; the webhook worker *calls* the events recorder as a client, not via macros.
- **`priv/templates/`** holds installer payloads. These are `.eex` files the installer renders and writes into the host app. The installer code itself lives in `lib/mix/tasks/`.
- **`test/helpers.ex` is NOT in `test/support/`.** Public test helpers ship in `lib/` so host apps can depend on them. This is the same pattern Swoosh (`Swoosh.TestAssertions`) and Oban (`Oban.Testing`) use.

---

## 3. Layering Rules

Layers from outermost (host) to innermost (storage). A module MAY depend on anything in a lower layer; it MUST NOT depend on anything in a higher layer.

```
Layer 7 : Host MyAppWeb (controllers, LiveViews, router)
Layer 6 : MyApp.Billing (GENERATED host context — facade)
Layer 5 : Accrue public API (Accrue.Billing.*, Accrue.Events, Accrue.Emails)
Layer 4 : Accrue behaviours (Processor, Auth, Mailer, PDF)
Layer 3 : Accrue adapter implementations (Processor.Stripe, Mailer.Swoosh, ...)
Layer 2 : Accrue internal engines (Webhook, Events.Recorder, schemas)
Layer 1 : External deps (lattice_stripe, Oban, Swoosh, ChromicPDF, Ecto, Postgrex)
Layer 0 : PostgreSQL
```

### Hard rules

1. **Schemas (Layer 2) do not call processors.** Ever. They are pure Ecto schemas with changesets and nothing else. Processor calls are orchestrated by the context modules at Layer 5.
2. **Processor adapters (Layer 3) never touch Ecto.** `Accrue.Processor.Stripe.create_customer/2` takes primitive maps/structs and returns primitive maps/structs. It does NOT insert rows. The Layer 5 context function calls it, then persists the result via `Ecto.Multi` alongside an event ledger insert.
3. **`MyApp.Billing` (Layer 6) is the only host-visible entry point for business operations.** Host code calling `Accrue.Billing.Subscriptions.create/1` directly is legal but discouraged; the generated facade gives users a stable project-local seam to add auth checks, logging, and custom policy without forking internals.
4. **`accrue_admin` reads schemas but uses context functions for writes.** LiveViews query `Accrue.Billing.Subscription` directly (Ecto preloads, pagination) but mutate via `Accrue.Billing.Subscriptions.cancel/2` so webhook handlers and admin actions converge on one write path.
5. **No module under `accrue/billing/` may import `accrue/processor/stripe/`.** The inverse is fine (Stripe adapter knows about Accrue schemas for return types). This is a one-way arrow enforced by code review (and dialyzer specs).
6. **No module in core `accrue/` may reference `Phoenix.LiveView`, `Phoenix.Component`, or `Phoenix.Router`.** The admin package is the only place these appear. `Phoenix.HTML` and `Phoenix.Template` are allowed in core for email/PDF rendering because they work without LiveView.

### Public vs internal

Public modules (documented in ExDoc, covered by deprecation policy):

- `Accrue` (top-level sugar)
- `Accrue.Billable` (macro)
- `Accrue.Billing.*` — every `*.ex` file that isn't a bare schema
- `Accrue.Billing.{Customer, Subscription, ...}` schemas (public as types but not as free-form data)
- `Accrue.Processor` (behaviour)
- `Accrue.Auth` (behaviour)
- `Accrue.Mailer` (behaviour)
- `Accrue.PDF` (behaviour)
- `Accrue.Events` (query API)
- `Accrue.Webhook.Handler` (behaviour)
- `Accrue.Error` and all subclasses
- `Accrue.Telemetry` (event name module)
- `Accrue.Test.*` (test helpers)
- `Mix.Tasks.Accrue.*`

Internal (marked `@moduledoc false`, no stability guarantees):

- `Accrue.Webhook.Plug`, `.Verifier`, `.Dispatcher`, `.Worker`, `.Idempotency`
- `Accrue.Events.{Recorder, Upcaster, SigraBridge}`
- `Accrue.Processor.Stripe.*` submodules (only `Accrue.Processor.Stripe` itself is stable)
- `Accrue.Billing.StateMachine`
- `Accrue.Config`

---

## 4. Behaviour Contracts

### 4.1 `Accrue.Processor`

The load-bearing extension point. Roughly:

```elixir
defmodule Accrue.Processor do
  @type client :: term()
  @type ref :: String.t()  # processor's resource id (e.g. "cus_123")
  @type error :: Accrue.Error.t()

  @callback client(opts :: keyword()) :: {:ok, client()} | {:error, error()}

  @callback create_customer(client, attrs :: map()) :: {:ok, map()} | {:error, error()}
  @callback update_customer(client, ref, attrs :: map()) :: {:ok, map()} | {:error, error()}
  @callback retrieve_customer(client, ref) :: {:ok, map()} | {:error, error()}

  @callback create_subscription(client, attrs :: map()) :: {:ok, map()} | {:error, error()}
  @callback update_subscription(client, ref, attrs :: map()) :: {:ok, map()} | {:error, error()}
  @callback cancel_subscription(client, ref, opts :: keyword()) :: {:ok, map()} | {:error, error()}

  @callback attach_payment_method(client, ref, pm_ref :: String.t()) :: {:ok, map()} | {:error, error()}
  @callback detach_payment_method(client, pm_ref :: String.t()) :: {:ok, map()} | {:error, error()}

  @callback create_invoice(client, attrs :: map()) :: {:ok, map()} | {:error, error()}
  @callback finalize_invoice(client, ref) :: {:ok, map()} | {:error, error()}
  @callback pay_invoice(client, ref, opts :: keyword()) :: {:ok, map()} | {:error, error()}
  @callback void_invoice(client, ref) :: {:ok, map()} | {:error, error()}

  @callback create_refund(client, charge_ref :: String.t(), attrs :: map()) :: {:ok, map()} | {:error, error()}

  @callback create_checkout_session(client, attrs :: map()) :: {:ok, map()} | {:error, error()}
  @callback create_portal_session(client, attrs :: map()) :: {:ok, map()} | {:error, error()}

  @callback verify_webhook(payload :: binary(), signature :: String.t(), secret :: String.t()) ::
              {:ok, map()} | {:error, error()}
end
```

Key design notes:

- **`client` is opaque.** For Stripe it's `%LatticeStripe.Client{}`. For Fake it's a pid or an ETS table reference. The processor returns it from `client/1` and accepts it as the first arg on every call.
- **Returns are raw maps, not structs.** The Layer 5 context function receives the map and writes it into its Ecto changeset (alongside storing the full blob in `data` jsonb per the dj-stripe-inspired decision).
- **`verify_webhook/3` is static (no client).** It only needs the secret and signature; the plug calls it before any persistence happens.
- **Connect threads through `opts`.** `create_customer(client, attrs, stripe_account: "acct_...")`. For Stripe this becomes a per-request header; for Fake it's recorded for assertions.
- **Idempotency keys threaded through `opts`** and derived *by Accrue* deterministically from the business entity id + operation — not generated by the host. See §6.2.

### 4.2 `Accrue.Auth`

```elixir
defmodule Accrue.Auth do
  @callback current_user(Plug.Conn.t()) :: map() | nil
  @callback user_schema() :: module()
  @callback actor_id(user :: map()) :: term()
  @callback require_admin(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  @callback log_audit(event :: map()) :: :ok
end
```

Default adapter (`Accrue.Auth.Default`) returns `conn.assigns[:current_user]`, accepts any `user_schema` configured via `Accrue.Config`, and `require_admin/2` uses a host-provided `is_admin?/1` callback. It does *nothing* for `log_audit/1` (it's an Accrue.Events write already).

### 4.3 `Accrue.Mailer`

```elixir
defmodule Accrue.Mailer do
  @callback deliver(email :: Swoosh.Email.t(), opts :: keyword()) :: {:ok, term()} | {:error, term()}
end
```

Thin. Wraps Swoosh to prevent Swoosh from leaking into user code paths. `Accrue.Emails.send_receipt/1` builds a `Swoosh.Email` and passes it to the configured mailer adapter.

### 4.4 `Accrue.PDF`

```elixir
defmodule Accrue.PDF do
  @callback render(html :: iodata(), opts :: keyword()) :: {:ok, binary()} | {:error, term()}
end
```

Even thinner. Takes rendered HEEx output (iodata), returns PDF bytes. `ChromicPDF` adapter calls `ChromicPDF.print_to_pdf/2`; `Test` adapter returns `<<"PDF:", html::binary>>` and records the call for assertions.

### 4.5 `Accrue.Webhook.Handler`

```elixir
defmodule Accrue.Webhook.Handler do
  @callback handle_event(event :: Accrue.Webhook.Event.t()) ::
              :ok | {:ok, term()} | :error | {:error, term()}
end
```

Matches the shape of `LatticeStripe.Webhook.Handler` exactly (see `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/webhook/handler.ex`). The difference is that Accrue's default handler already implements state reconciliation, so users can pattern-match on events they care about and `super` or fall through to the default.

---

## 5. Supervision Tree

Accrue itself starts **nothing** by default — like sigra, it is a library whose primitives run inline in host call stacks. The `Accrue.Application` module exists for boot-time diagnostics only:

```elixir
defmodule Accrue.Application do
  use Application

  def start(_type, _args) do
    Accrue.Config.validate_runtime!()
    Accrue.Telemetry.attach_default_handlers()

    maybe_warn_missing_raw_body_plug()
    maybe_warn_oban_not_configured()

    Supervisor.start_link([], strategy: :one_for_one, name: Accrue.Supervisor)
  end
end
```

This directly parallels `Sigra.Application` (`/Users/jon/projects/sigra/lib/sigra/application.ex`) which also starts an empty supervisor and performs boot-time config warnings.

### Why Accrue does not start its own Finch/Oban

- **Oban** is already running in the host app (required dep per PROJECT.md Constraints). Accrue queues into it via `Oban.insert/1`; it does not own a separate instance. The installer adds the `accrue_webhooks` and `accrue_emails` queues to the host's `config :my_app, Oban, queues: [...]`.
- **Finch** is required by `lattice_stripe` but Accrue does not own it. The installer adds `{Finch, name: MyApp.Finch}` to the host supervision tree (or detects an existing one) and uses that name in the Stripe client config.
- **PubSub** is optional; only needed if admin LiveViews want real-time updates. `accrue_admin` subscribes to a topic that `Accrue.Webhook.Worker` broadcasts to *if* `Phoenix.PubSub` is configured in `Accrue.Config`. No hard dep.
- **No GenServers in core.** Stateless-by-default. The Fake Processor is the only "process" — and it's optional, only started in test environments by `Accrue.Test.start_fake/1`.

### Host supervision tree after install

```
MyApp.Supervisor
├── MyApp.Repo
├── Phoenix.PubSub
├── Finch (name: MyApp.Finch)                  # added by installer if missing
├── {Oban, Application.fetch_env!(:my_app, Oban)}
│     queues: [default: 10, accrue_webhooks: 20, accrue_emails: 5]
├── MyAppWeb.Endpoint
└── # Accrue.Application starts automatically as an OTP app (diagnostics only)
```

---

## 6. Data Flows

### 6.1 Subscribe Flow

```
MyAppWeb.BillingController.create/2
        │
        ▼
MyApp.Billing.subscribe(user, plan_id, payment_method_id)       # Layer 6
        │   (generated facade — thin wrapper with host authz)
        ▼
Accrue.Billing.Subscriptions.create/1                           # Layer 5
        │
        │   Ecto.Multi.new()
        │   |> Multi.run(:customer, fn -> ensure_customer(user) end)
        │   |> Multi.run(:stripe_sub, fn _ ->
        │        Accrue.Processor.create_subscription(client, attrs)
        │      end)
        │   |> Multi.insert(:subscription, &build_subscription_changeset/1)
        │   |> Accrue.Events.Recorder.record_multi(:event, "subscription.created", ...)
        │   |> Repo.transaction()
        │
        ▼
Accrue.Processor.Stripe.create_subscription/2                   # Layer 3
        │
        ▼
Accrue.Processor.Stripe.Idempotency.key(:subscription, :create, uuid)
        │  -> "accrue:sub:create:d41d8cd9..."
        ▼
LatticeStripe.Subscription.create(client, attrs, idempotency_key: key)
        │
        ▼
        [HTTPS → api.stripe.com → response]
        │
        ▼  {:ok, stripe_sub_map}
Accrue.Processor.Stripe.Error.normalize/1                       # error pass-through
        │
        ▼  {:ok, map}
[back to Multi — insert row, insert event]
        │
        ▼
:telemetry.execute([:accrue, :billing, :subscription, :create, :stop], ...)
        │
        ▼
{:ok, %Accrue.Billing.Subscription{}}
```

**Direction is strictly outbound then inbound**: controller → host context → Accrue context → processor adapter → external; response unwinds the same stack. The event ledger insert is inside the same `Ecto.Multi` as the row insert, guaranteeing atomicity (if Stripe succeeded but the DB insert failed, the event is not written — and the webhook will later reconcile state on retry).

### 6.2 Webhook Flow

```
Stripe → POST /webhooks/stripe
        │   (headers: Stripe-Signature, body: raw JSON)
        ▼
MyAppWeb.Endpoint
        │   # `plug Plug.Parsers, body_reader: {Accrue.Webhook.CacheBodyReader, :read_body, []}`
        ▼
MyAppWeb.Router
        │
        ▼
Accrue.Webhook.Plug.call/2                                      # Layer 2 internal
        │
        │   1. Read raw body (preserved by CacheBodyReader)
        │   2. Read Stripe-Signature header
        │   3. Accrue.Webhook.Verifier.verify!(body, sig, secret)
        │        └─ delegates to Accrue.Processor.verify_webhook/3
        │              └─ Accrue.Processor.Stripe uses LatticeStripe.Webhook
        │   4. Decode JSON, extract processor_event_id
        │   5. Accrue.Webhook.Idempotency.insert_or_skip/1
        │        └─ INSERT INTO accrue_webhook_events (id, processor_event_id, status, payload)
        │           ON CONFLICT (processor_event_id) DO NOTHING
        │        └─ if already seen: return :already_processed, respond 200
        │   6. Accrue.Webhook.Dispatcher.enqueue/1
        │        └─ Oban.insert(%Accrue.Webhook.Worker{args: %{event_id: id}})
        │   7. send_resp(conn, 200, "")   # <100ms p99 budget
        │
        ▼
  [HTTP 200 returned to Stripe — under 100ms]

[ASYNC — Oban picks up the job]
        │
        ▼
Accrue.Webhook.Worker.perform/1                                 # Layer 2 internal
        │
        │   1. Load %Accrue.Webhook.Event{} from DB
        │   2. Mark status: :processing
        │   3. Resolve handler module (user's handler or default)
        │   4. Accrue.Telemetry.span([:accrue, :webhook, :handle], ...)
        │
        ▼
user's MyApp.Billing.WebhookHandler.handle_event/1
        │   (or falls through to Accrue.Webhook.DefaultHandler)
        │
        ▼
Accrue.Billing.Subscriptions.reconcile_from_webhook/1           # Layer 5
        │
        │   Ecto.Multi
        │   |> Multi.update(:subscription, ...)
        │   |> Accrue.Events.Recorder.record_multi(:event, "subscription.updated", ...)
        │   |> Repo.transaction()
        │
        ▼
Worker marks accrue_webhook_events.status = :completed
        │
        ▼
[optional] Phoenix.PubSub.broadcast(:accrue, "webhook:events", {:processed, event})
        │
        ▼  (accrue_admin.WebhookEventsLive re-renders if subscribed)
```

**On handler failure**: Worker marks `status: :failed`, increments `attempts`, Oban re-schedules with exponential backoff. After `max_attempts` the row goes to `status: :dead_letter` and surfaces in the admin UI's DLQ view for replay via `Accrue.Webhook.Replay.requeue/1`.

This flow is structurally identical to `lattice_stripe/lib/lattice_stripe/webhook/plug.ex` except Accrue inserts the DB idempotency row and enqueues Oban *before* dispatch, where lattice_stripe dispatches synchronously. Accrue owns the async pipeline because webhook reliability is "the #1 value-add" per PROJECT.md.

### 6.3 PDF Flow

```
MyApp.Billing.invoice_pdf(invoice_id)
        │
        ▼
Accrue.Billing.Invoices.to_pdf/1
        │
        │   1. Load invoice + line_items + customer (preloaded)
        │   2. Build assigns map (branding from Accrue.Config)
        │
        ▼
Accrue.PDF.render_template/2
        │
        │   Phoenix.Template.render(:invoice, "html", assigns)
        │   └─ uses lib/accrue/pdf/templates/invoice.html.heex
        │   → iodata (HTML)
        │
        ▼
Accrue.PDF.adapter().render(html, opts)                         # behaviour dispatch
        │
        ├─ Accrue.PDF.Chromic.render/2
        │    └─ ChromicPDF.print_to_pdf({:html, html}, opts)
        │        → {:ok, <<PDF bytes>>}
        │
        └─ Accrue.PDF.Test.render/2
             └─ record call in process dict; return {:ok, "PDF:" <> html}
             └─ (test assertions via Accrue.Test.assert_pdf_rendered/1)
        │
        ▼
{:ok, binary} or {:error, Accrue.Error.PDFError.t()}
```

The same HEEx template is used for the invoice email body (HTML) and the invoice PDF. Single source of truth.

### 6.4 Email Flow

```
Accrue.Webhook.DefaultHandler for "invoice.payment_succeeded"
        │
        ▼
Accrue.Emails.send_receipt(invoice)
        │
        │   1. Load preloads (customer, subscription, line_items)
        │   2. Phoenix.Template.render(:receipt, "html", assigns)
        │      + render(:receipt, "text", assigns)
        │   3. Build %Swoosh.Email{}
        │
        ▼
Accrue.Mailer.adapter().deliver(email, opts)                    # behaviour dispatch
        │
        ├─ Accrue.Mailer.Swoosh
        │    └─ Option A (sync): MyApp.Mailer.deliver(email)
        │    └─ Option B (async): Oban.insert(%Accrue.Mailer.Worker{email: ...})
        │         (configurable via Accrue.Config :async_email)
        │
        └─ Accrue.Mailer.Test
             └─ delegates to Swoosh.Adapters.Test
             └─ assertable via Swoosh.TestAssertions.assert_email_sent/1
                or Accrue.Test.assert_email_sent/1 wrapper
        │
        ▼
{:ok, metadata} | {:error, Accrue.Error.MailerError.t()}
```

The host-configured Swoosh mailer (`MyApp.Mailer`) is the actual send target; `Accrue.Mailer.Swoosh` is a thin shim that picks up whatever `Accrue.Config[:mailer]` points to. Async dispatch via Oban reuses the same queue infrastructure the webhook pipeline uses.

---

## 7. Integration with `lattice_stripe`

Survey of `/Users/jon/projects/lattice_stripe/lib/` shows exactly what Accrue can lean on today and where it must extend:

```
lib/lattice_stripe/
├── client.ex                       # struct, no GenServer — passed explicitly
├── customer.ex                     # CRUD + search + stream
├── payment_intent.ex               # CRUD, confirm, capture
├── payment_method.ex               # attach/detach/list
├── setup_intent.ex
├── refund.ex
├── checkout/session.ex
├── webhook.ex + webhook/plug.ex    # verify + dispatch (we will NOT reuse the plug)
├── event.ex                        # %LatticeStripe.Event{}
├── error.ex                        # typed errors
├── telemetry.ex
└── testing.ex
```

**What Accrue reuses as-is:**
- `LatticeStripe.Client` — passed through `Accrue.Config[:stripe_client]` at runtime. One client per app; for Connect, Accrue constructs a per-request sub-client with `stripe_account:` set (see `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/client.ex:24-29`).
- `LatticeStripe.Customer.{create, retrieve, update, list, delete}` — Accrue calls these directly from `Accrue.Processor.Stripe.Customer`.
- `LatticeStripe.PaymentIntent`, `.PaymentMethod`, `.SetupIntent`, `.Refund`, `.Checkout.Session` — same.
- `LatticeStripe.Webhook.verify/3` — Accrue's `Webhook.Verifier` delegates here. Accrue does NOT use `LatticeStripe.Webhook.Plug` because Accrue's plug persists an idempotency row and enqueues Oban before responding, whereas lattice_stripe dispatches synchronously.
- `LatticeStripe.Error` — Accrue's error normalization layer maps `%LatticeStripe.Error{type: :card_error}` → `%Accrue.CardError{}`, preserving the `type` atom for pattern matching.

**What Accrue must extend (or upstream to lattice_stripe):**

Per PROJECT.md Context section, lattice_stripe has "no Billing (Subscription/Product/Price/Invoice/Meter) coverage yet". Accrue cannot ship without these. Options:

1. **Upstream into lattice_stripe** (preferred, per "Accrue will need lattice_stripe to add these, or build them upstream as lattice_stripe contributions"). The `LatticeStripe.Subscription`, `.Invoice`, `.Price`, `.Product`, `.SubscriptionSchedule` modules get added as a milestone inside `lattice_stripe/` before Accrue needs them. This is the critical dependency edge in the roadmap.
2. **Fallback**: build raw `%LatticeStripe.Request{}` structs in `Accrue.Processor.Stripe.Subscription` and send them via `LatticeStripe.Client.request/2`. Works but duplicates resource-mapping boilerplate.

**Decision recommended for roadmap**: treat "lattice_stripe billing coverage" as a Phase 0 prerequisite. Accrue Phase 2 (Subscriptions) is blocked on this.

**Idempotency key derivation** — `LatticeStripe.Request` accepts `idempotency_key:` in `opts` (see `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/client.ex:34-44`). Accrue generates these deterministically:

```elixir
defmodule Accrue.Processor.Stripe.Idempotency do
  @spec key(resource :: atom(), action :: atom(), entity_id :: String.t()) :: String.t()
  def key(resource, action, entity_id) do
    "accrue:#{resource}:#{action}:#{entity_id}"
  end
end
```

The `entity_id` is the Accrue-side UUID for the subscription/invoice/etc, generated *before* the processor call, so retries of the same logical operation produce the same key. For idempotent operations with per-attempt variation (e.g., an invoice charge retry after a failed card), the key incorporates an attempt counter from the accrue_events history.

**Connect header threading** — Every `Accrue.Processor.*` function accepts `stripe_account:` in opts. The Stripe adapter constructs a per-call client via `%{client | stripe_account: opts[:stripe_account]}` (struct is plain data, no GenServer, so this is safe). Connect flows surface this from `MyApp.Billing.subscribe/3` which in turn reads it from the billable's `connected_account_id` field.

---

## 8. Integration with `sigra`

Survey of `/Users/jon/projects/sigra/lib/` shows:

- `sigra/auth.ex` — 1809 lines, exposes `register`, `authenticate`, session management. Accrue's `Accrue.Integrations.Sigra` does NOT wrap these — authentication is host-owned.
- `sigra/audit.ex` — 405 lines, exposes `log/2` and `log_multi/3` (`Ecto.Multi`-friendly). This is what Accrue bridges into for the event ledger passthrough.
- `sigra/plug/require_authenticated.ex`, `sigra/plug/require_scopes.ex` — the plugs Accrue's admin UI mounts behind when Sigra is present.

### `Accrue.Integrations.Sigra` shape

```elixir
if Code.ensure_loaded?(Sigra) do
  defmodule Accrue.Integrations.Sigra do
    @moduledoc """
    First-party Sigra adapter. Conditionally compiled — this module only
    exists if :sigra is in the host app's dep tree at compile time.

    Wires Accrue.Auth and Accrue.Events to Sigra.Auth and Sigra.Audit.
    """
    @behaviour Accrue.Auth

    @impl true
    def current_user(conn), do: Sigra.Plug.current_user(conn)

    @impl true
    def user_schema, do: Application.fetch_env!(:sigra, :user_schema)

    @impl true
    def actor_id(user), do: user.id

    @impl true
    def require_admin(conn, opts) do
      conn
      |> Sigra.Plug.RequireAuthenticated.call([])
      |> Sigra.Plug.RequireScopes.call(scopes: ["billing.admin"])
    end

    @impl true
    def log_audit(event) do
      Sigra.Audit.log("billing.#{event.type}",
        repo: Accrue.Config.repo(),
        audit_schema: Application.fetch_env!(:sigra, :audit_schema),
        actor_id: event.actor_id,
        metadata: event.data
      )
      :ok
    end

    @doc "Used by Accrue.Events.SigraBridge to bridge into Sigra.Audit via Ecto.Multi"
    def audit_multi(multi, action, opts) do
      Sigra.Audit.log_multi(multi, action, opts)
    end
  end
end
```

The top-level `if Code.ensure_loaded?(Sigra) do` guard is the same pattern lattice_stripe uses for its Plug module:

```elixir
# /Users/jon/projects/lattice_stripe/lib/lattice_stripe/webhook/plug.ex:1
if Code.ensure_loaded?(Plug) do
  defmodule LatticeStripe.Webhook.Plug do
    ...
```

**Verified idiomatic**: this is the established Elixir pattern for optional-dep modules. Both lattice_stripe and Oban use it. The module simply doesn't exist when the dep is missing, so `Code.ensure_loaded?(Accrue.Integrations.Sigra)` in the installer becomes the detection call.

### Installer-time sigra detection

The installer runs in mix context, so it can read `Mix.Project.config()[:deps]` *of the host app*:

```elixir
defp sigra_present? do
  Mix.Project.deps_tree()
  |> Enum.any?(fn {name, _} -> name == :sigra end)
rescue
  _ -> false
end
```

When true:
- The generated `MyApp.Billing` context sets `use Accrue, auth: Accrue.Integrations.Sigra`.
- The generated admin router mount uses `pipe_through [:browser, :require_authenticated]` (Sigra's pipeline) instead of the default noop.
- The generated `config/config.exs` snippet sets `config :accrue, auth: Accrue.Integrations.Sigra`.

When false, the installer prints a guide link and generates `Accrue.Auth.Default` wiring instead.

### Sigra audit bridge

`Accrue.Events.SigraBridge` is invoked from `Accrue.Events.Recorder` inside the same `Ecto.Multi`:

```elixir
def record_multi(multi, name, attrs) do
  multi
  |> Multi.insert(:accrue_event, Event.changeset(%Event{}, attrs))
  |> maybe_bridge_sigra(name, attrs)
end

defp maybe_bridge_sigra(multi, name, attrs) do
  if Accrue.Config.sigra_audit_bridge?() and Code.ensure_loaded?(Accrue.Integrations.Sigra) do
    Accrue.Integrations.Sigra.audit_multi(multi, "billing.#{name}", ...)
  else
    multi
  end
end
```

Two-layer check: compile-time `Code.ensure_loaded?` guards against the module not existing; runtime `Accrue.Config` flag gives ops the ability to disable the bridge without recompiling.

---

## 9. Build Order (Topological)

Components must be built in dependency order. This informs roadmap phase structure. Arrows mean "must exist before".

```
                  ┌──────────────────────────────────┐
                  │ 0. lattice_stripe billing support │ (upstream prerequisite)
                  └──────────────┬───────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 1. Accrue.Config + Accrue.Error + Accrue.Telemetry              │  foundation
└──────────────────────────┬──────────────────────────────────────┘
                           │
        ┌──────────────────┼────────────────────────┐
        ▼                  ▼                        ▼
┌───────────────┐  ┌──────────────────┐  ┌──────────────────────┐
│ 2. Processor  │  │ 3. Events.Event  │  │ 4. Billing schemas   │
│    behaviour  │  │    schema +      │  │    (Customer,        │
│    + Fake     │  │    Recorder      │  │    Subscription,     │
│    adapter    │  │    (Ecto.Multi)  │  │    Invoice, etc.)    │
└──────┬────────┘  └────────┬─────────┘  └──────────┬───────────┘
       │                    │                      │
       │   (2 is THE foundation for testing 4+5)   │
       │                    │                      │
       └────────────┬───────┴──────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. Accrue.Processor.Stripe (resource-by-resource)               │
│    Customers → PaymentMethods → Subscriptions → Invoices →      │
│    Charges → Refunds → Coupons → Checkout → Connect             │
└──────────────────────────┬──────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────────┐
        ▼                  ▼                      ▼
┌───────────────┐  ┌──────────────────┐  ┌──────────────────────┐
│ 6. Webhook    │  │ 7. Billing       │  │ 8. Auth behaviour    │
│    pipeline   │  │    context fns   │  │    + Default + Sigra │
│    (Plug,     │  │    (lifecycle    │  │    adapter           │
│    Verifier,  │  │    orchestration │  │                      │
│    Worker,    │  │    via Multi)    │  │                      │
│    Idempotency│  │                  │  │                      │
└───────┬───────┘  └────────┬─────────┘  └──────────┬───────────┘
        │                   │                       │
        └──────────┬────────┴───────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│ 9. Mailer behaviour + Emails module + templates                 │
│10. PDF behaviour + ChromicPDF adapter + invoice template        │  (can be parallel)
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│11. Accrue.Test helpers (assert_email_sent, assert_pdf_rendered, │
│    start_fake, advance_time)                                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│12. Mix.Tasks.Accrue.Install (needs all templates to exist)      │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│13. accrue_admin package (LiveViews depend on all Billing        │
│    context fns + Accrue.Auth + Accrue.Events.Query)             │
└─────────────────────────────────────────────────────────────────┘
```

### Why this order

- **(1) Config + Error + Telemetry first** because every subsequent module uses them. Errors especially — every adapter needs `Accrue.Error.normalize/1` to exist.
- **(2) Processor behaviour + Fake adapter before anything else** because "Fake Processor is the primary test surface, not an afterthought" (PROJECT.md). Every downstream test that needs a processor uses Fake. If we build real Stripe first, every earlier test becomes slow/flaky.
- **(3) Events schema + Recorder before Billing context functions** because every Billing context function writes events atomically alongside state. Build the ledger first so the atomic pattern is established and exercised in every test.
- **(4) Billing schemas can be built in parallel with (2) and (3)** — they're pure Ecto, no behaviour dependency. But they cannot be *used* until (2) and (3) exist.
- **(5) Stripe adapter is resource-by-resource** because each resource has its own lattice_stripe dependency and error cases. Customers → PaymentMethods first (the building blocks for everything else), then Subscriptions, then the billing-side resources.
- **(6) Webhook pipeline is unblocked once (2) exists** — it only needs the Processor behaviour for verification and the Event schema for idempotency rows. It does not need (5) to be complete; a webhook handler for `customer.created` can land before the Stripe Connect adapter does.
- **(7) Billing context functions** are the last core-domain work. Each one is an `Ecto.Multi` that calls Processor + writes schema + records event — so it needs (2), (3), (4), (5), and (6) all in place.
- **(8) Auth behaviour can be built in parallel with (6/7)** — it's orthogonal. Default adapter first, Sigra adapter once sigra's own API is stable.
- **(9, 10) Emails and PDF can be built in parallel** once (4) exists — they only need the schemas to render templates.
- **(11) Test helpers must come after (9) and (10)** because `assert_email_sent` needs the Mailer behaviour, `assert_pdf_rendered` needs the PDF behaviour.
- **(12) Installer last among core work** — it generates templates that reference every module the host will touch. If modules don't exist, the installer either fails or generates references to ghost code.
- **(13) accrue_admin is a strict consumer** — LiveViews read schemas, call context functions, query `Accrue.Events`. It cannot start until everything else is at least skeleton-stable. Built late but in parallel with installer polish and documentation.

---

## 10. Brownfield Host App: Before and After Install

### Before `mix accrue.install`

```
my_app/
├── mix.exs                    # has {:accrue, "~> 1.0"} + {:oban, ...}
├── config/
│   ├── config.exs
│   ├── dev.exs
│   └── runtime.exs
└── lib/
    ├── my_app/
    │   ├── application.ex
    │   ├── repo.ex
    │   └── accounts/
    │       └── user.ex        # host's own User schema
    └── my_app_web/
        ├── endpoint.ex
        ├── router.ex
        └── ...
```

### After `mix accrue.install --billable MyApp.Accounts.User`

```
my_app/
├── mix.exs
├── priv/repo/migrations/
│   ├── 20260411100000_create_accrue_customers.exs         # NEW
│   ├── 20260411100001_create_accrue_payment_methods.exs   # NEW
│   ├── 20260411100002_create_accrue_subscriptions.exs     # NEW
│   ├── 20260411100003_create_accrue_invoices.exs          # NEW
│   ├── 20260411100004_create_accrue_charges.exs           # NEW
│   ├── 20260411100005_create_accrue_refunds.exs           # NEW
│   ├── 20260411100006_create_accrue_coupons.exs           # NEW
│   ├── 20260411100007_create_accrue_webhook_events.exs    # NEW
│   ├── 20260411100008_create_accrue_events.exs            # NEW
│   └── 20260411100009_accrue_events_immutability.exs      # NEW (PG role grants + trigger)
├── config/
│   ├── config.exs                                         # MODIFIED: :accrue + Oban queues
│   └── runtime.exs                                        # MODIFIED: Stripe keys, webhook secret
└── lib/
    ├── my_app/
    │   ├── application.ex                                 # MODIFIED: Finch + Oban + Accrue children
    │   ├── accounts/
    │   │   └── user.ex                                    # MODIFIED: `use Accrue.Billable`
    │   └── billing.ex                                     # NEW: MyApp.Billing context facade
    │   └── billing/
    │       └── webhook_handler.ex                         # NEW: MyApp.Billing.WebhookHandler
    └── my_app_web/
        ├── endpoint.ex                                    # MODIFIED: CacheBodyReader body_reader
        └── router.ex                                      # MODIFIED: webhook plug + admin mount (if admin installed)
```

The installer uses string-based source injection (same pattern as Sigra's `Sigra.Install.Injector` in `/Users/jon/projects/sigra/lib/sigra/install/injector.ex`) for the modify-in-place files.

---

## 11. Architectural Patterns

### Pattern 1: Context Facade with Behaviour-Based Extension

**What:** Public context modules (`Accrue.Billing.Subscriptions`) orchestrate; behaviours (`Accrue.Processor`) abstract variation; adapters (`Accrue.Processor.Stripe`) are swap-in implementations. The generated `MyApp.Billing` is a second facade layer — host-owned — that gives users a stable module to add project-local concerns to.

**When to use:** Every Billing domain operation.
**Trade-offs:** Two facade layers feels redundant when Accrue is the only consumer, but the generated layer is crucial for the upgrade story — users put their custom logic there instead of forking Accrue internals.

### Pattern 2: Ecto.Multi as the Atomicity Unit

**What:** Every state-mutating operation is an `Ecto.Multi` that composes a processor call, a schema write, and an event ledger insert in one transaction. If any step fails, none commit, and the webhook later reconciles the drift.

**Example:**
```elixir
def create(attrs) do
  Multi.new()
  |> Multi.run(:stripe, fn _, _ -> Accrue.Processor.create_subscription(client(), attrs) end)
  |> Multi.insert(:subscription, &build_changeset(&1.stripe))
  |> Accrue.Events.Recorder.record_multi(:event, "subscription.created", & &1.subscription)
  |> Repo.transact()
end
```

**Trade-offs:** Requires every downstream to speak `Multi`. This is idiomatic Ecto and explicitly called out in PROJECT.md philosophy.

### Pattern 3: Conditional Compilation for Optional Integrations

**What:** Optional-dep modules wrapped in `if Code.ensure_loaded?(Dep) do ... end` at the top level. Verified idiomatic via lattice_stripe and Oban.

**When to use:** Sigra adapter, ChromicPDF adapter, any future community integration.
**Trade-offs:** Slightly unusual for newcomers; requires runtime guards in callers too. Worth it for dep hygiene.

### Pattern 4: Hybrid Library + Generator

**What:** Security/logic in the lib (updated via `mix deps.update`), schemas/routes/context facades generated into the host (owned by user). Directly mirrors sigra's pattern.

**When to use:** Anything the host app needs to customize per project (schemas, routes, auth gates) vs anything Accrue needs to upgrade atomically (signature verification, Stripe translation, state machines).

### Pattern 5: Append-Only Event Ledger with DB-Enforced Immutability

**What:** `accrue_events` is append-only at the Postgres level (role-based GRANT, no UPDATE/DELETE privilege for the app role, enforced by a trigger for defense-in-depth). Records include `schema_version` in the `data` jsonb blob for upcaster-based evolution. Every state mutation pairs with an event insert inside `Ecto.Multi`.

**Trade-offs:** No CQRS machinery (saving ~450 LOC vs Commanded). Atomicity via Postgres transactions, not event sourcing. Loses the "replay to rebuild state" property but the webhook pipeline handles reconciliation anyway.

---

## 12. Anti-Patterns

### Anti-Pattern 1: Letting the Stripe adapter own DB writes

**What people do:** Push Ecto inserts down into `Accrue.Processor.Stripe.create_subscription/2`.
**Why it's wrong:** Destroys adapter substitutability. Breaks the Fake processor story (Fake would need its own DB path). Mixes Layer 2 with Layer 3. Tight-couples "called Stripe" with "wrote a row," preventing retries where you want one but not the other.
**Do instead:** Adapters return plain maps. Context functions (Layer 5) own the `Ecto.Multi` and insert.

### Anti-Pattern 2: Synchronous webhook dispatch

**What people do:** Call the user's handler inline inside `Accrue.Webhook.Plug.call/2` and return when it finishes.
**Why it's wrong:** Stripe's webhook timeout is seconds, a handler doing real work (sending emails, refunds, reconciliation) easily blows past it. You lose retry-on-deploy semantics. You can't replay after fix. Webhooks disable themselves.
**Do instead:** Plug persists idempotency row + enqueues Oban job + returns 200 in <100ms. Worker dispatches async with retry.

### Anti-Pattern 3: False multi-processor parity

**What people do:** Design `Accrue.Processor` callbacks to cover everything every processor supports, papering over capability gaps with feature flags.
**Why it's wrong:** Laravel's explicit regret (PROJECT.md Context). Stripe and Paddle disagree on tax, dunning, and proration semantics; pretending otherwise means the highest-level API is the union of misunderstandings.
**Do instead:** Ship Stripe-only for v1. Processor behaviour is scoped to Stripe's model with clear documentation that future adapters will need supplementary behaviours (e.g. `Accrue.Processor.Tax`) rather than forcing Stripe-specific callbacks onto them.

### Anti-Pattern 4: Accrue starting its own Oban / Repo / Finch

**What people do:** Accrue has an `Accrue.Repo`, starts its own Oban instance, bundles a Finch pool.
**Why it's wrong:** Host app already has all three. Library-level state is the fastest path to Phoenix-unfriendly DX. Multi-instance Oban is a known footgun.
**Do instead:** Accrue uses the host's Repo, the host's Oban instance (queues added by installer), and the host's Finch pool (or adds one if missing). Accrue's supervision tree is empty. See sigra's `application.ex` (verified).

### Anti-Pattern 5: LiveView in core Accrue

**What people do:** Ship a few "just a few" LiveView helpers in `accrue/` for convenience.
**Why it's wrong:** Turns LiveView into a hard dep, killing headless use cases (API-only apps, background workers, channels-only apps).
**Do instead:** LiveView stays in `accrue_admin/`. Core `accrue/` may use `Phoenix.HTML` and `Phoenix.Template` for email/PDF rendering since those don't pull in the LiveView runtime.

---

## 13. Integration Points Summary

### External Services

| Service | Integration Pattern | Notes |
|---|---|---|
| Stripe API | Via `lattice_stripe` directly in `Accrue.Processor.Stripe.*`; deterministic idempotency keys; Connect via `stripe_account:` opt threading | Billing endpoints (Subscription, Invoice) must be added to lattice_stripe first — Phase 0 blocker |
| Stripe webhooks | `Accrue.Webhook.Plug` (NOT `LatticeStripe.Webhook.Plug`) — persists first, dispatches async | Raw-body preservation via `Accrue.Webhook.CacheBodyReader` mounted in `Plug.Parsers` |
| SMTP / transactional email | Swoosh under `Accrue.Mailer` behaviour; host's own `MyApp.Mailer` is the ultimate adapter | Async option via Oban `accrue_emails` queue |
| Chrome / headless rendering | `ChromicPDF` under `Accrue.PDF` behaviour; `Test` adapter for test env | Optional dep; host can swap for Gotenberg adapter |
| OpenTelemetry | `Accrue.Telemetry.span/3` wraps every public entry point; standard `[:accrue, :domain, :action, :start/:stop/:exception]` naming | No OTel SDK dep — just `:telemetry` emits; host attaches handlers |

### Internal Boundaries

| Boundary | Communication | Notes |
|---|---|---|
| MyApp.Billing → Accrue.Billing.* | Direct function calls (generated facade delegates) | Facade is host-owned; Accrue can evolve under it |
| Accrue.Billing.* → Accrue.Processor | `Accrue.Processor.__adapter__.call(...)` indirection via `Accrue.Config` | Dispatch at runtime lets Fake/Stripe swap per env |
| Accrue.Processor.Stripe → lattice_stripe | Direct calls — `LatticeStripe.Customer.create/2` etc. | No wrapping GenServer; `%LatticeStripe.Client{}` is plain struct |
| Accrue.Webhook.Plug → Accrue.Webhook.Worker | `Oban.insert/1` — crosses process boundary | Idempotency row inserted before enqueue; survives restart |
| Accrue.Webhook.Worker → user handler | Direct function call (module resolved from config) | User's handler returns `:ok`/`:error`; worker translates to Oban retry semantics |
| Accrue.Events.Recorder → Accrue.Integrations.Sigra | Via `maybe_bridge_sigra/2` inside the same `Ecto.Multi` | Compile-time `Code.ensure_loaded?` + runtime config flag |
| accrue_admin LiveView → Accrue.Billing.* (reads) | Direct Ecto queries on schemas | Schemas are public enough for reads |
| accrue_admin LiveView → Accrue.Billing.* (writes) | Via context functions (never direct schema writes) | One write path; webhook + admin converge |

---

## 14. Scaling Considerations

| Scale | Architecture Adjustments |
|---|---|
| 0-1k customers | Single Repo, single Oban queue, inline email, inline PDF. Works as-is. |
| 1k-100k customers | Move `accrue_emails` queue to dedicated pool; move PDF rendering to Oban worker (don't block web); add DB indexes on `accrue_events(inserted_at, subject_type, subject_id)`. |
| 100k-1M customers | Partition `accrue_events` by month (PG 14 declarative partitioning); consider read replica for `accrue_admin` dashboards; raise Oban `accrue_webhooks` concurrency; consider PubSub sharding for admin real-time updates. |
| 1M+ customers | Revenue-side concerns dominate architecture concerns. Accrue is not the bottleneck by this point — Stripe Connect sharding, dunning campaign orchestration, and SRE observability are the next load-bearing pieces. Out of scope for v1.0. |

### Scaling Priorities

1. **First bottleneck: webhook handler latency blows the <100ms budget** once the default handler does real work inline. Fix: ensure the plug *never* calls handler code — only persist + enqueue + 200. This is already the design.
2. **Second bottleneck: `accrue_events` table growth.** At 10 events/customer-day × 100k customers = 1M events/day. Partition by month, index `(subject_type, subject_id, inserted_at DESC)`, archive cold partitions.
3. **Third bottleneck: admin dashboard queries.** LiveView will happily query `SELECT COUNT(*) FROM accrue_subscriptions WHERE status = 'active'` on every mount. Materialize via periodic aggregation into a small stats table updated by an Oban cron worker.

---

## 15. Outstanding Questions for the Roadmap

1. **Does lattice_stripe billing support land in a separate milestone inside `lattice_stripe/` before Accrue Phase 2, or is it built as part of Accrue Phase 2 and upstreamed?** This is a cross-project dependency the roadmap must make explicit.
2. **Does `accrue_admin` ship with its own NPM/esbuild pipeline or inherit the host app's `assets/`?** LiveView UI with Ink/Slate/Fog/Paper theming suggests Accrue wants to ship pre-compiled CSS/JS via `priv/static/`, like `phoenix_live_dashboard` does. Lean toward pre-compiled + shipped.
3. **Where does the default webhook handler live — in `accrue/` (`Accrue.Webhook.DefaultHandler`) or generated into `MyApp.Billing.WebhookHandler`?** Recommend: both. Accrue ships `Accrue.Webhook.DefaultHandler` which users can call from their generated `MyApp.Billing.WebhookHandler` as `super` or fall-through. This preserves both upgrade safety (logic in lib) and extensibility (seam in host).
4. **Schema of `accrue_events.subject` — polymorphic `(subject_type, subject_id)` like the billable, or typed foreign keys per entity?** Recommend polymorphic for uniformity with the billable pattern; query performance via composite index `(subject_type, subject_id, inserted_at DESC)`.
5. **Does `Accrue.Config` use NimbleOptions schema declared at compile time (validated once) or runtime validation on every read?** Recommend compile-time schema + `validate_runtime!/0` on app start (mirrors sigra's pattern where `Sigra.Config` holds the NimbleOptions schema).

---

## 16. Sources

- `/Users/jon/projects/accrue/.planning/PROJECT.md` — locked decisions, constraints, philosophy
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe.ex` — API version, module inventory
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/client.ex` — client struct, Connect header pattern, idempotency_key opt
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/customer.ex` — resource module shape (CRUD + search + stream + PII-safe Inspect)
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/webhook/plug.ex` — raw-body mount strategies; verified `if Code.ensure_loaded?(Plug) do` optional-dep pattern
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/webhook/handler.ex` — `@callback handle_event/1` contract shape
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/webhook/cache_body_reader.ex` — same conditional compile pattern
- `/Users/jon/projects/sigra/lib/sigra.ex` — hybrid lib+generator positioning language
- `/Users/jon/projects/sigra/lib/sigra/application.ex` — empty-supervisor-with-diagnostics pattern (HIGH confidence reference for Accrue.Application design)
- `/Users/jon/projects/sigra/lib/sigra/auth.ex` — confirms Sigra.Auth is the module Accrue.Integrations.Sigra wraps
- `/Users/jon/projects/sigra/lib/sigra/audit.ex` — `log/2` and `log_multi/3` APIs, Ecto.Multi-friendly
- `/Users/jon/projects/sigra/lib/sigra/install/injector.ex` — string injection pattern for modifying host files
- `/Users/jon/projects/sigra/lib/sigra/plug/` — auth pipeline plugs Accrue.Integrations.Sigra delegates to

Confidence: HIGH. Every architectural claim is either (a) a direct locked decision in PROJECT.md, (b) a pattern verified in the sibling libraries' source, or (c) a logical derivation from the two. No WebSearch was needed for this document because the authoritative sources are all local.

---
*Architecture research for: Accrue (Elixir/Phoenix payments library)*
*Researched: 2026-04-11*
