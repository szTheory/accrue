# Phase 1: Foundations - Research

**Researched:** 2026-04-11
**Domain:** Elixir library primitives — value types, behaviours, Postgres immutability, email/PDF adapter shapes, conditional compilation
**Confidence:** HIGH (stack versions, SQLSTATE, Ecto/ChromicPDF APIs verified); MEDIUM (mjml_eex ↔ phoenix_swoosh glue — idiomatic pattern is not the one currently sketched in CONTEXT.md D-22)

## Summary

Phase 1 is the first code commit of a greenfield Elixir library. The technical decisions are nearly all locked in CONTEXT.md (D-01..D-45) and CLAUDE.md; research value is concentrated in **verifying the HOW** for five high-risk areas:

1. `Accrue.Money` wraps `:ex_money` but uses its OWN two-column Ecto representation (`amount_minor :bigint` + `currency :string`) — **not** ex_money_sql's `Money.Ecto.Composite.Type` or the `money_with_currency` Postgres composite type. The wrapper owns conversion.
2. Append-only ledger uses `BEFORE UPDATE OR DELETE` trigger with SQLSTATE `45A01` — confirmed as a valid user-defined class, mappable back through `Postgrex.Error`.
3. The idiomatic `mjml_eex` integration is **NOT** `use Phoenix.Swoosh, formats: %{"mjml" => :html_body}`. `mjml_eex` does not register as a Phoenix template engine for render_body; the real pattern is one module per email using `use MjmlEEx, mjml_template: "x.mjml.eex"` then passing `render(assigns)` to `Swoosh.Email.html_body/2` directly.
4. `Ecto.Repo.transaction/2` is deprecated in favor of `Repo.transact/2` in Ecto 3.13+ — use `transact` throughout.
5. ChromicPDF's `Template.source_and_options/1` uses option names `header` / `footer` (not `header_html` / `footer_html`). The `Accrue.PDF` public API can keep the `_html`-suffixed names but the adapter must translate.

**Primary recommendation:** Organize Phase 1 as ~7 parallel workstreams (Money, Error+Config+Telemetry, EventLedger migration+schema+API, Processor behaviour+Fake+Stripe-stub, Mailer+PDF+Auth behaviours, Application+Monorepo+License+Brand, CI with_sigra/without_sigra matrix + validation fixtures). The only hard serial edge is "ledger migration must land before `Events.record/1` can be tested."

## User Constraints (from CONTEXT.md)

### Locked Decisions

All 45 decisions D-01 through D-45 from `01-CONTEXT.md` are locked. Reproduced here by category for planner reference; full rationale in CONTEXT.md.

**Money (D-01..D-04):**
- D-01: `Accrue.Money` is a thin wrapper over `:ex_money`; Accrue owns API shape, inherits CLDR currency correctness.
- D-02: Ecto representation is **two columns** `amount_minor :bigint` + `currency :string` (ISO 4217) via a custom `Accrue.Ecto.Money` Ecto type. Not ex_money_sql's composite type.
- D-03: Primary constructor `Accrue.Money.new(minor_units :: integer, currency :: atom)`. `Decimal` / `float` raise `ArgumentError` on `new/2`; use `Accrue.Money.from_decimal/2` for explicit conversion.
- D-04: Mixed-currency arithmetic raises `Accrue.Money.MismatchedCurrencyError`.

**Error hierarchy (D-05..D-08):**
- D-05: Dual API — `create_subscription/2` returns tuple; `create_subscription!/2` raises. Mirrors Ecto.
- D-06: Rich error structs: `Accrue.CardError`, `RateLimitError`, `SignatureError`, `APIError`, `IdempotencyError`, `DecodeError`, `ConfigError`. Each implements `Exception` and is pattern-matchable.
- D-07: Stripe error → Accrue.Error mapping lives **only** in `Accrue.Processor.Stripe`.
- D-08: `SignatureError` always raises (never returns a tuple).

**Event ledger (D-09..D-12):**
- D-09: Both BEFORE UPDATE/DELETE trigger AND REVOKE grants (defense in depth).
- D-10: Role management host-owned; `mix accrue.install` generates REVOKE stub migration. Boot-time `has_table_privilege` check warns in dev, raises in prod when `enforce_immutability: true`.
- D-11: Trigger raises SQLSTATE `45A01`. Repo wrapper pattern-matches `%Postgrex.Error{postgres: %{code: :accrue_event_immutable}}` and re-raises `Accrue.EventLedgerImmutableError`. No message-string parsing.
- D-12: `Accrue.Events.Event` schema exists for reads; no update/delete helpers exposed.

**Events API (D-13..D-16):**
- D-13: Both `Events.record/1` (for `Repo.transact/2` blocks) and `Events.record_multi/3` (for `Ecto.Multi` pipelines).
- D-14: `idempotency_key` is caller-provided, nullable unique index. Webhook passes Stripe event ID → `on_conflict: :nothing` dedup. No auto-generated keys.
- D-15: Actor context via process dictionary (`Accrue.Actor.put_current/1`) + explicit `actor:` keyword override. Actor enum: `user | system | webhook | oban | admin`.
- D-16: OTel trace_id auto-captured via `Accrue.Telemetry.current_trace_id/0` — reads span context when `:opentelemetry` loaded, no-op otherwise.

**Telemetry (D-17..D-18):**
- D-17: 4-level event names `[:accrue, :domain, :resource, :action, :phase]` where phase ∈ `:start|:stop|:exception`. Domain ∈ `:billing|:events|:webhooks|:mail|:pdf|:processor`.
- D-18: `Accrue.Telemetry.Metrics` optional helper module returning `Telemetry.Metrics` definitions.

**Processor.Fake (D-19..D-20):**
- D-19: Explicit test clock; `Accrue.Processor.Fake.advance(server, duration)`. No wall-clock.
- D-20: Deterministic IDs `cus_fake_00001`, `sub_fake_00001`, `in_fake_00001`, `pi_fake_00001`, `pm_fake_00001`. Reset via `Accrue.Processor.Fake.reset/0`.

**Mailer (D-21..D-31):**
- D-21: Single `c:deliver(type :: atom, assigns :: map)` callback — semantic args, NOT `%Swoosh.Email{}`.
- D-22: Default pipeline: `Accrue.Mailer.deliver(:payment_succeeded, %{customer_id: id, invoice_id: id})` → `Accrue.Emails.PaymentSucceeded` template module → delivered via `Accrue.Mailer.Swoosh` → enqueued on `:accrue_mailers` Oban queue. **See Pitfall #3 below — the "formats: %{"mjml" => :html_body}" shape in CONTEXT.md does not match how mjml_eex actually works.**
- D-23: Pay-style 4-rung graduated override ladder: kill switch → MFA conditional → template module override → full pipeline replace.
- D-24: Rich global brand config in `Accrue.Config` read by every default template.
- D-25: Per-email toggle `config :accrue, emails: [type: boolean | {M, f, a}]`.
- D-26: `Accrue.Mailer.Swoosh` is `use Swoosh.Mailer, otp_app: :accrue`. Host can point at existing `adapter:`.
- D-27: Oban payload is `{type :: atom, %{entity_id_only_map}}`. Worker rehydrates from DB at delivery time. PDFs NEVER in Oban args.
- D-28: Emits `[:accrue, :mailer, :deliver, :start|:stop|:exception]` with `%{email_type, customer_id}`.
- D-29: Ship both `Swoosh.TestAssertions.assert_email_sent/1` compatibility AND `Accrue.Test.Mailer.assert_email_sent(:payment_succeeded, customer: c)` semantic helper.
- D-30: MJML default via `mjml_eex`; automatic text-body fallback; plain HEEx HTML as Rustler-failure fallback.
- D-31: `mix accrue.gen.emails` copies templates to host's `priv/accrue/templates/` for direct editing.

**PDF (D-32..D-39):**
- D-32: `c:render(html :: binary(), opts :: keyword())` — Shape B.
- D-33: `Accrue.PDF.ChromicPDF` default. Calls `ChromicPDF.Template.source_and_options(...) |> ChromicPDF.print_to_pdf()`. ChromicPDF is started by the **host supervision tree**, never by Accrue.
- D-34: `Accrue.PDF.Test` sends `{:pdf_rendered, html, opts}` to `self()` and returns `{:ok, "%PDF-TEST"}`.
- D-35: `opts`: `:size (:a4|:letter)`, `:header_html`, `:footer_html`, `:header_height`, `:footer_height`, `:archival` (true → `print_to_pdfa/2`, requires Ghostscript).
- D-36: Core stays LiveView-free. Callers flatten Phoenix.Component themselves via `Phoenix.HTML.Safe.to_iodata |> IO.iodata_to_binary` before `Accrue.PDF.render/2`. Shape-A convenience ships in `accrue_admin`.
- D-37: Gotenberg adapter is documented custom-adapter path, not first-party.
- D-38: Stripe-hosted PDF passthrough is Phase 2 concern.
- D-39: Auto-attach invoice PDF to receipt email — **Phase 2 behavior**, but Phase 1 behaviours must be shaped to support it (deliver callback rehydrates; Mailer worker can call PDF adapter).

**Auth (D-40..D-41):**
- D-40: `Accrue.Auth.Default` dev-permissive (`%{id: "dev", email: "dev@localhost", role: :admin}`), prod raises `Accrue.ConfigError` during `Accrue.Application.start/2`.
- D-41: Sigra auto-detection via compile-time conditional compile per CLAUDE.md pattern.

**Monorepo & Release (D-42..D-44):**
- D-42: Sibling mix projects `accrue/` + `accrue_admin/`, non-umbrella. Root holds README, LICENSE, `.github/workflows/`, `release-please-config.json`, `guides/`, `scripts/`.
- D-43: Lockstep major versions, independent minor/patch. `accrue_admin` pins `{:accrue, "~> 1.0"}`. Per-package Release Please entries with `release-type: "elixir"` and `bump-minor-pre-major: true`.
- D-44: `mix accrue.install` is the generator task (Phase 8 scope for full behavior; Phase 1 may ship skeleton).

**Conditional compile (D-45):**
- D-45: Follow CLAUDE.md 4-pattern exactly: `optional: true` dep, `@compile {:no_warn_undefined, Sigra.X}`, guard at `use` time, runtime dispatch via config. Must pass `--warnings-as-errors` in both `with_sigra` and `without_sigra`.

### Claude's Discretion

These are the planner's/executor's call per CONTEXT.md:

- Module file layout inside `lib/accrue/` (one `Money.ex` vs split into `Money/Currency/Ecto`)
- `Accrue.Config` NimbleOptions schema field-by-field layout
- Test organization (`test/accrue/`, property test placement, fixture strategy)
- Migration filenames and order (only constraint: `accrue_events` table + trigger + REVOKE stub must exist)
- `Accrue.Application.start/2` body specifics (empty supervisor is locked; child list for Fake-processor registries is planner's call)
- Internal naming of workers, middlewares, plugs
- Whether `Accrue.Mailer.Default` lives in own file or inline
- Exact `Accrue.Emails.*` count for Phase 1 (only `PaymentSucceeded` reference template is required; others land in Phase 6)
- Shape of `Accrue.Test.Mailer` / `Accrue.Test.PDF` helper modules

### Deferred Ideas (OUT OF SCOPE)

Do not plan or research these for Phase 1:
- `Accrue.Billing.invoice_pdf(invoice, source:)` — Phase 2
- Auto-attach invoice PDF to receipt email (runtime behavior) — Phase 2
- Full ~15-template email catalog (14 beyond `PaymentSucceeded`) — Phase 6
- `Accrue.Integrations.Sigra` concrete callback bodies — later (scaffold only in Phase 1)
- Customer Portal / Checkout Session helpers — Phase 4
- Stripe Connect — Phase 5

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FND-01 | `Accrue.Money` with zero/three-decimal safety | `:ex_money 5.24.2` wrapping; custom `Accrue.Ecto.Money` two-column type; StreamData property tests for round-trip + mismatched-currency raise |
| FND-02 | `Accrue.Error` exception hierarchy | Pattern: one file `lib/accrue/errors.ex` with all 7 structs each `defexception`; map from `lattice_stripe` error shapes only inside `Accrue.Processor.Stripe` |
| FND-03 | `Accrue.Config` via NimbleOptions with auto-docs | `NimbleOptions 1.1.1`; schema module + `@moduledoc NimbleOptions.docs(@schema)` for generated docs |
| FND-04 | `Accrue.Telemetry` event naming conventions | 4-level `[:accrue, :domain, :resource, :action, :phase]` documented in module docstring; `:telemetry.span/3` used by every public entry |
| FND-05 | `Accrue.Application` empty-supervisor | Precedent: `Ecto.Repo` apps, `Oban`, Phoenix use host-supervised pattern. `Accrue.Application.start/2` returns `Supervisor.start_link([], strategy: :one_for_one, name: Accrue.Supervisor)`. Possibly one child: Registry for Fake processor instances. |
| FND-06 | Monorepo layout | Root + `accrue/` + `accrue_admin/`; `lattice_stripe` is the internal precedent (same author uses this layout already) |
| FND-07 | Brand palette CSS variables | Static file `accrue/priv/static/brand.css` (or `lib/accrue/brand.css`) with `:root` selector defining `--accrue-ink`, `--accrue-slate`, `--accrue-fog`, `--accrue-paper`, `--accrue-moss`, `--accrue-cobalt`, `--accrue-amber`. No CSS tooling — plain file. |
| PROC-01 | `Accrue.Processor` behaviour | Define `@callback create_customer/2`, `retrieve_customer/2`, `update_customer/3`, etc. Phase 1 scope: only callbacks needed to prove the Fake's shape; Phase 3 grows it. |
| PROC-03 | `Accrue.Processor.Fake` in-memory ETS | GenServer holding ETS tables + test clock + deterministic ID counters. `advance/2`, `reset/0`, `stub/3` (scriptable responses) |
| PROC-07 | Stripe error → Accrue.Error mapping | Isolated inside `Accrue.Processor.Stripe`; tested with Mox-mocked `lattice_stripe` responses |
| EVT-01 | `accrue_events` append-only w/ trigger + REVOKE | SQLSTATE `45A01`, `BEFORE UPDATE OR DELETE FOR EACH ROW` trigger, REVOKE stub in separate migration |
| EVT-02 | Schema columns | `id bigserial PK`, `type varchar NOT NULL`, `schema_version integer NOT NULL DEFAULT 1`, `actor_type varchar NOT NULL` (enum check), `actor_id varchar`, `subject_type varchar`, `subject_id varchar`, `data jsonb NOT NULL DEFAULT '{}'`, `trace_id varchar`, `idempotency_key varchar`, `inserted_at timestamptz NOT NULL DEFAULT now()`. Indexes: `(subject_type, subject_id, inserted_at)`, `UNIQUE (idempotency_key) WHERE idempotency_key IS NOT NULL`. |
| EVT-03 | `Events.record/1` + `record_multi/3` | Both go through one validated changeset; `Repo.transact` inner / `Ecto.Multi.insert` outer |
| EVT-07 | Trace_id correlation | `Accrue.Telemetry.current_trace_id/0` written into `trace_id` column at insert time |
| EVT-08 | Actor enum enforcement | PG CHECK constraint `actor_type IN ('user','system','webhook','oban','admin')` + Ecto changeset validation |
| AUTH-01 | `Accrue.Auth` behaviour | Callbacks: `current_user/1`, `require_admin_plug/0`, `user_schema/0`, `log_audit/2`, `actor_id/1` |
| AUTH-02 | `Accrue.Auth.Default` dev-only | Env check via `Application.get_env(:accrue, :env)` or injected; raise `Accrue.ConfigError` at `Application.start/2` in prod |
| MAIL-01 | `Accrue.Mailer` behaviour wrapping Swoosh | Semantic `deliver(type, assigns)`; default adapter dispatches to template modules; Oban worker for async |
| PDF-01 | `Accrue.PDF` behaviour | `@callback render(html :: binary, opts :: keyword) :: {:ok, binary} \| {:error, term}` |
| OBS-01 | `:telemetry` start/stop/exception on public entries | `:telemetry.span/3` wrapping every public function. `Accrue.Telemetry` helper macro to reduce boilerplate. |
| OBS-06 | Stripe error mapping with metadata preserved | Covered by PROC-07; keep raw processor error in `:processor_error` field |
| OSS-11 | MIT LICENSE file at monorepo root | Plain text MIT; per-package symlink or copy |
| TEST-01 | Fake Processor as primary test surface | Fake is primary; Mox mock for the behaviour covers pure-interface tests; Stripe adapter tested separately with lattice_stripe stubs |

## Standard Stack

### Core (already locked in CLAUDE.md, versions re-verified)

| Library | Version | Purpose | Why Standard | Provenance |
|---------|---------|---------|--------------|-----------|
| `:elixir` | `~> 1.17` (dev machine has 1.19.5/OTP28) | Language | Locked in CLAUDE.md | [VERIFIED: `elixir --version`] |
| `:ecto` | `~> 3.13` | Domain modeling | CLAUDE.md lock; `Repo.transact/2` stable here | [CITED: CLAUDE.md] |
| `:ecto_sql` | `~> 3.13` | Repo + migrations | Pinned to ecto minor | [CITED: CLAUDE.md] |
| `:postgrex` | `~> 0.22` | PG driver | Supports custom SQLSTATE parsing via `%Postgrex.Error{postgres: %{code: atom}}` | [CITED: CLAUDE.md] |
| `:ex_money` | `~> 5.24` | Currency/money primitive | 5.24.2 on 2026-01-29; ISO 4217 + ISO 24165, 180+ currencies with CLDR | [VERIFIED: hex.pm API 2026-04-11] |
| `:ex_money_sql` | `~> 1.12` (maybe NOT needed) | Ecto integration for ex_money | **1.12.0** on 2026-01-15. **Evaluate carefully**: CONTEXT.md D-02 locks a two-column representation, so ex_money_sql's `Money.Ecto.Composite.Type` / `money_with_currency` composite type is NOT used. Accrue writes its own `Accrue.Ecto.Money` type. `ex_money_sql` may still be useful for currency-table helpers; if not, omit entirely to shed dep. | [VERIFIED: hex.pm API 2026-04-11] |
| `:lattice_stripe` | `~> 0.2` | Stripe HTTP | Sibling library; processor.Stripe dispatches here | [CITED: CLAUDE.md] |
| `:oban` | `~> 2.21` | Async jobs | Community edition; `:accrue_mailers` queue for email async | [CITED: CLAUDE.md] |
| `:swoosh` | `~> 1.25` | Email delivery | Default phoenix mailer | [CITED: CLAUDE.md] |
| `:phoenix_swoosh` | `~> 1.2` | HEEx rendering helper for email | `render_body/3`; note: NOT used for mjml templates in idiomatic pattern — see Pitfall #3 | [CITED: CLAUDE.md] |
| `:mjml_eex` | `~> 0.13` | MJML → HTML compilation | One module per email, `render(assigns)` returns HTML | [CITED: CLAUDE.md] |
| `:chromic_pdf` | `~> 1.17` | PDF rendering | Not started by Accrue; host supervision tree starts it; in tests use Accrue.PDF.Test | [CITED: CLAUDE.md] |
| `:nimble_options` | `~> 1.1` | Config schema + docs | `Accrue.Config` module | [CITED: CLAUDE.md] |
| `:telemetry` | `~> 1.3` | Instrumentation | `:telemetry.span/3` for every public entry | [CITED: CLAUDE.md] |
| `:jason` | `~> 1.4` | JSON | `data` jsonb columns | [CITED: CLAUDE.md] |
| `:decimal` | `~> 2.0` | Decimal math | Pin explicitly; transitive through ecto and ex_money | [CITED: CLAUDE.md] |

### Supporting (dev/test)

| Library | Version | Purpose |
|---------|---------|---------|
| `:mox` | `~> 1.2` | Behaviour-backed mocks for Processor/Mailer/PDF/Auth |
| `:stream_data` | `~> 1.3` | Property tests for `Money` math (zero/three-decimal round-trip, mismatched-currency raise) |
| `:ex_doc` | `~> 0.40` | Docs |
| `:credo` | `~> 1.7` | Lint |
| `:dialyxir` | `~> 1.4` | Dialyzer |

### Optional

| Library | Marker | Integration |
|---------|--------|-------------|
| `:sigra` | `optional: true` | `Accrue.Integrations.Sigra` conditionally compiled |
| `:opentelemetry` | `optional: true` | `Accrue.Telemetry.current_trace_id/0` no-ops when absent |
| `:telemetry_metrics` | `optional: true` | `Accrue.Telemetry.Metrics` module only |

### Alternatives Considered

| Instead of | Could Use | Why rejected |
|------------|-----------|-------|
| `Accrue.Ecto.Money` (custom two-column) | `Money.Ecto.Composite.Type` + `money_with_currency` PG composite | CONTEXT.md D-02 chose two columns for indexability/analytics; composite type requires `mix money.gen.postgres.money_with_currency` migration that hosts must run. Two-column is simpler and locked. |
| Direct `ChromicPDF.print_to_pdf/1` call | `ChromicPDF.Template.source_and_options/1 \|> print_to_pdf/1` | Template helper is the idiomatic path per ChromicPDF hexdocs; handles size/margins/header/footer uniformly. |
| `use Phoenix.Swoosh, formats: %{"mjml" => :html_body}` | Per-module `use MjmlEEx, mjml_template:` + `render/1` + `html_body/2` | mjml_eex does NOT register as a Phoenix template engine; the engine module in mjml_eex is an **EEx engine** for `render_static_component`, not a Phoenix template engine. See Pitfall #3. |

**Installation:**
```elixir
# accrue/mix.exs deps/0
{:ecto, "~> 3.13"},
{:ecto_sql, "~> 3.13"},
{:postgrex, "~> 0.22"},
{:ex_money, "~> 5.24"},
{:lattice_stripe, "~> 0.2"},
{:oban, "~> 2.21"},
{:swoosh, "~> 1.25"},
{:phoenix_swoosh, "~> 1.2"},
{:mjml_eex, "~> 0.13"},
{:chromic_pdf, "~> 1.17"},
{:nimble_options, "~> 1.1"},
{:telemetry, "~> 1.3"},
{:jason, "~> 1.4"},
{:decimal, "~> 2.0"},
{:sigra, "~> 0.1", optional: true},
{:opentelemetry, "~> 1.7", optional: true},
{:telemetry_metrics, "~> 1.1", optional: true},
# dev/test
{:mox, "~> 1.2", only: :test},
{:stream_data, "~> 1.3", only: [:dev, :test]},
{:ex_doc, "~> 0.40", only: :dev, runtime: false},
{:credo, "~> 1.7", only: [:dev, :test], runtime: false},
{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
```

**Version verification (2026-04-11):**
- `ex_money` 5.24.2 (2026-01-29) [VERIFIED: hex.pm /api/packages/ex_money]
- `ex_money_sql` 1.12.0 (2026-01-15) [VERIFIED: hex.pm /api/packages/ex_money_sql]
- All other versions [CITED: CLAUDE.md Tech Stack section, researched 2026-04-11]

## Architecture Patterns

### Recommended Project Structure

```
accrue/                                      # monorepo root
├── LICENSE                                  # MIT
├── README.md                                # 30-second quickstart (stub OK for Phase 1)
├── .github/workflows/ci.yml                 # matrix: with_sigra/without_sigra
├── release-please-config.json
├── .release-please-manifest.json
├── guides/                                  # shared ExDoc guides
├── accrue/
│   ├── mix.exs
│   ├── lib/
│   │   ├── accrue.ex                        # top-level moduledoc
│   │   ├── accrue/
│   │   │   ├── application.ex               # empty supervisor
│   │   │   ├── config.ex                    # NimbleOptions schema
│   │   │   ├── telemetry.ex                 # event naming + span helpers + trace_id
│   │   │   ├── telemetry/metrics.ex         # optional Telemetry.Metrics defs
│   │   │   ├── actor.ex                     # process-dict actor context
│   │   │   ├── errors.ex                    # all 7 defexception structs
│   │   │   ├── money.ex                     # public API
│   │   │   ├── money/mismatched_currency_error.ex
│   │   │   ├── ecto/money.ex                # custom Ecto type (amount_minor + currency)
│   │   │   ├── events.ex                    # record/1, record_multi/3
│   │   │   ├── events/event.ex              # Ecto schema, read-only
│   │   │   ├── events/ledger_immutable_error.ex
│   │   │   ├── processor.ex                 # behaviour
│   │   │   ├── processor/fake.ex            # ETS-backed GenServer
│   │   │   ├── processor/stripe.ex          # adapter; maps lattice_stripe errors
│   │   │   ├── mailer.ex                    # behaviour + delegate
│   │   │   ├── mailer/default.ex            # default adapter
│   │   │   ├── mailer/swoosh.ex             # use Swoosh.Mailer
│   │   │   ├── workers/mailer.ex            # Oban worker
│   │   │   ├── emails/payment_succeeded.ex  # reference template module
│   │   │   ├── pdf.ex                       # behaviour
│   │   │   ├── pdf/chromic_pdf.ex           # default adapter
│   │   │   ├── pdf/test.ex                  # test adapter
│   │   │   ├── auth.ex                      # behaviour
│   │   │   ├── auth/default.ex              # dev-permissive / prod-raise
│   │   │   ├── integrations/sigra.ex        # conditionally compiled
│   │   │   └── brand.ex                     # color constants (CSS lives in priv)
│   │   └── accrue/emails/templates/         # .mjml.eex + .text.eex (not in priv to allow compile-time)
│   ├── priv/
│   │   ├── static/brand.css                 # brand palette CSS variables
│   │   └── repo/migrations/                 # (empty — host owns migrations; see D-10)
│   ├── test/
│   │   ├── test_helper.exs                  # Mox.defmock + Application.put_env
│   │   ├── support/                         # shared test helpers
│   │   └── accrue/                          # per-module tests
│   └── CHANGELOG.md
└── accrue_admin/
    ├── mix.exs                              # {:accrue, path: "../accrue"} in dev; "~> 1.0" published
    └── lib/                                 # (Phase 7)
```

### Pattern 1: Behaviour + Default + Adapter Swap (for Processor/Mailer/PDF/Auth)

**What:** A public API facade delegates to a configurable implementation resolved at runtime via `Application.get_env`.
**When to use:** Every Phase 1 behaviour. This is the Mox-verified pattern from `:mox` docs.

```elixir
# lib/accrue/processor.ex
defmodule Accrue.Processor do
  @callback create_customer(params :: map(), opts :: keyword()) ::
              {:ok, map()} | {:error, Accrue.Error.t()}
  # ... more callbacks

  def create_customer(params, opts \\ []), do: impl().create_customer(params, opts)

  defp impl, do: Application.get_env(:accrue, :processor, Accrue.Processor.Fake)
end

# test/test_helper.exs
Mox.defmock(Accrue.Processor.Mock, for: Accrue.Processor)
Application.put_env(:accrue, :processor, Accrue.Processor.Mock)

# in a test
test "..." do
  expect(Accrue.Processor.Mock, :create_customer, fn _params, _opts ->
    {:ok, %{id: "cus_xyz"}}
  end)
  # ...
end
```

Source: [CITED: https://hexdocs.pm/mox/Mox.html]. Pattern verified against CLAUDE.md "Test Library Decision: Mox, Decisively."

### Pattern 2: `Ecto.Repo.transact/2` for Atomic Event+State

**What:** Use `Repo.transact/2` (not deprecated `transaction/2`).
**When to use:** Every `Events.record/1` call site and every Billing write that must couple state + event.

```elixir
Accrue.Repo.transact(fn ->
  with {:ok, sub} <- insert_subscription(changeset),
       {:ok, _evt} <- Accrue.Events.record(%{
         type: "subscription.created",
         subject_type: "Subscription",
         subject_id: sub.id,
         data: %{...}
       }) do
    {:ok, sub}
  end
end)
```

Source: [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]. `transaction/2` is deprecated in favor of `transact/2`.

### Pattern 3: Append-Only Ledger via Trigger + REVOKE (Belt + Suspenders)

**What:** Postgres trigger raises SQLSTATE `45A01` on `BEFORE UPDATE OR DELETE`; REVOKE migration strips UPDATE/DELETE/TRUNCATE grants from the app role.

```elixir
# priv/accrue/templates/migrations/create_accrue_events.exs (generated by mix accrue.install)
defmodule Accrue.Repo.Migrations.CreateAccrueEvents do
  use Ecto.Migration

  def up do
    create table(:accrue_events, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :type, :string, null: false
      add :schema_version, :integer, null: false, default: 1
      add :actor_type, :string, null: false
      add :actor_id, :string
      add :subject_type, :string
      add :subject_id, :string
      add :data, :map, null: false, default: %{}
      add :trace_id, :string
      add :idempotency_key, :string
      add :inserted_at, :utc_datetime_usec, null: false, default: fragment("now()")
    end

    create index(:accrue_events, [:subject_type, :subject_id, :inserted_at])
    create unique_index(:accrue_events, [:idempotency_key],
             where: "idempotency_key IS NOT NULL")

    execute """
    ALTER TABLE accrue_events
      ADD CONSTRAINT accrue_events_actor_type_check
      CHECK (actor_type IN ('user','system','webhook','oban','admin'))
    """

    execute """
    CREATE OR REPLACE FUNCTION accrue_events_immutable()
    RETURNS trigger
    LANGUAGE plpgsql AS $$
    BEGIN
      RAISE SQLSTATE '45A01'
        USING MESSAGE = 'accrue_events is append-only; UPDATE and DELETE are forbidden';
    END;
    $$;
    """

    execute """
    CREATE TRIGGER accrue_events_immutable_trigger
      BEFORE UPDATE OR DELETE ON accrue_events
      FOR EACH ROW EXECUTE FUNCTION accrue_events_immutable();
    """
  end

  def down do
    execute "DROP TRIGGER IF EXISTS accrue_events_immutable_trigger ON accrue_events"
    execute "DROP FUNCTION IF EXISTS accrue_events_immutable()"
    drop table(:accrue_events)
  end
end

# priv/accrue/templates/migrations/revoke_accrue_events_writes.exs (stub; user edits role name)
defmodule Accrue.Repo.Migrations.RevokeAccrueEventsWrites do
  use Ecto.Migration

  def up do
    execute "REVOKE UPDATE, DELETE, TRUNCATE ON accrue_events FROM accrue_app"
  end

  def down do
    execute "GRANT UPDATE, DELETE, TRUNCATE ON accrue_events TO accrue_app"
  end
end
```

Source: [CITED: https://www.postgresql.org/docs/current/plpgsql-errors-and-messages.html — SQLSTATE `45A01` is in the user-defined class range; all 5-char codes of digits + uppercase ASCII letters are valid except `00000` and codes ending in `000`]. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html — `execute/1` for raw SQL].

### Pattern 4: Postgrex Error Pattern-Matching (No String Parsing)

```elixir
# lib/accrue/events.ex
def record(attrs) do
  attrs
  |> Event.changeset()
  |> Accrue.Repo.insert()
rescue
  err in Postgrex.Error ->
    case err do
      %Postgrex.Error{postgres: %{code: :accrue_event_immutable}} ->
        reraise Accrue.EventLedgerImmutableError, [message: err.postgres.message], __STACKTRACE__
      _ ->
        reraise err, __STACKTRACE__
    end
end
```

Postgrex maps the SQLSTATE through its internal table; `45A01` will surface as raw code string `"45A01"`. We register a custom atom label via a helper, OR match on the literal `code: "45A01"`. **Note for planner:** verify at plan time whether Postgrex 0.22 exposes unknown SQLSTATE codes as string or atom — if string, match `postgres: %{code: "45A01"}` directly. [ASSUMED] — confirm via a quick ExUnit test in Task 1.

### Pattern 5: Empty-Supervisor Library Application

**What:** `Accrue.Application.start/2` returns a Supervisor that owns only internal registries (if any). Host owns Repo, Oban, Finch, ChromicPDF lifecycle.
**Precedent:** Oban core, Ecto, `:telemetry` all follow this — the library is a collection of modules, not a runtime. `mix.exs` declares `mod: {Accrue.Application, []}` only if the Fake processor registry needs OTP supervision.

```elixir
defmodule Accrue.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    Accrue.Config.validate_at_boot!()
    Accrue.Auth.Default.boot_check!()

    children = [
      # Registry for Fake processor instances (test helper; kept for prod parity)
      {Registry, keys: :unique, name: Accrue.Processor.Fake.Registry}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Accrue.Supervisor)
  end
end
```

### Pattern 6: Conditional Compile for Sigra (CLAUDE.md 4-Step)

```elixir
# mix.exs deps/0
{:sigra, "~> 0.1", optional: true}

# lib/accrue/integrations/sigra.ex
if Code.ensure_loaded?(Sigra) do
  defmodule Accrue.Integrations.Sigra do
    @compile {:no_warn_undefined, [Sigra.Audit, Sigra.Auth]}
    @behaviour Accrue.Auth

    @impl true
    def current_user(conn), do: Sigra.Auth.current_user(conn)
    # ... etc
  end
end
```

Must compile clean under `--warnings-as-errors` in BOTH `with_sigra` (dep included) and `without_sigra` (dep absent) CI matrix entries. [CITED: CLAUDE.md "Conditional Compilation for Optional Deps" section 4-step pattern].

### Anti-Patterns to Avoid

- **Hand-rolled money type.** Use `:ex_money` for the currency table + CLDR. `Accrue.Money` is a thin wrapper, not a reimplementation.
- **Storing `%Swoosh.Email{}` in Oban args.** Breaks JSON round-trip. Store `{type :: atom, entity_id_map}` and rehydrate in worker.
- **Starting ChromicPDF in `Accrue.Application`.** Host owns the supervision tree; Accrue only calls into it.
- **Mocking `:lattice_stripe` directly.** Mock the `Accrue.Processor` behaviour instead; `Accrue.Processor.Stripe` is the only place that sees raw Stripe responses.
- **Message-string pattern matching on Postgrex errors.** Use `postgres: %{code: ...}` match instead (D-11).
- **Using `Ecto.Repo.transaction/2`.** Deprecated; use `transact/2`.
- **Exposing `Accrue.Events.Event` update/delete helpers.** Write-once only (D-12).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Currency conversion / zero-decimal detection | Custom integer-handling logic | `:ex_money` | 180+ currencies, ISO 4217 + CLDR, edge cases handled (JPY=0 decimal, KWD/BHD=3 decimals, IQD, UYI) |
| JSON in Postgres | Custom encoder | `:jason` via Ecto `:map` column type | Already transitive through Phoenix/Ecto |
| HTTP to Stripe | Custom Finch/Req wrapper | `:lattice_stripe` | Sibling library, tracks Stripe 2026-03-25 dahlia API |
| Email delivery | Custom SMTP/API | `:swoosh` | Standard Phoenix default; host wires adapter |
| MJML → HTML | Custom Rust bindings / subprocess | `:mjml_eex` | Rustler NIF backend, Node fallback |
| PDF rendering | wkhtmltopdf / pdf_generator / Prawn-port | `:chromic_pdf` | wkhtmltopdf archived with CVEs |
| Config validation | Custom `with` chains | `:nimble_options` | Auto-generated docs via `NimbleOptions.docs/1` |
| Behaviour mocks | `:meck` / `:mock` (global) | `:mox` | Async-safe, contract-verified |
| Property tests | Hand-rolled random | `:stream_data` | Standard Elixir property-testing lib |
| Postgres trigger message parsing | Regex on error message | `%Postgrex.Error{postgres: %{code: ...}}` pattern match | Robust, locale-independent |
| Transactions | Manual `BEGIN/COMMIT` SQL | `Repo.transact/2` | Handles savepoints, rollback-on-error, returns function result |

**Key insight:** Phase 1 is about building the thin layer that ties locked choices together. Every line of code should be plumbing a dep, not re-implementing one.

## Common Pitfalls

### Pitfall 1: ex_money_sql Composite Type Trap

**What goes wrong:** A developer reads the ex_money README, sees `field :amount, Money.Ecto.Composite.Type` and `add :amount, :money_with_currency`, and ships Phase 1 with this — then realizes `mix money.gen.postgres.money_with_currency` is a user-facing generator the host must run, and the composite type is harder to index for analytics than two columns.
**Why it happens:** The ex_money_sql README is the obvious path and the CONTEXT.md decision to go two-column is subtle.
**How to avoid:** Phase 1 plans must NOT import `Money.Ecto.Composite.Type`. Build `Accrue.Ecto.Money` as a custom `Ecto.Type` implementing `cast/1`, `load/1`, `dump/1`, reading two separate columns (`{field_name}_amount_minor :: integer` and `{field_name}_currency :: string`) via a `embeds_one`-like macro or by convention. Alternative: use `embeds_one` on a `Accrue.Money` embedded schema with `{:embeds_one, ...}` — but CONTEXT.md says two flat columns. Simplest: a helper macro `money_field :amount` that expands to two `field :amount_minor` + `field :currency` + a virtual `Accrue.Money` getter.
**Warning signs:** Any code referencing `Money.Ecto.Composite.Type` or `add :x, :money_with_currency` — those are the wrong path.
**Confidence:** HIGH. [VERIFIED: hexdocs.pm/ex_money_sql/readme.html contradicts the two-column decision; D-02 is explicit about the choice].

### Pitfall 2: Postgrex SQLSTATE Mapping

**What goes wrong:** Postgrex maps known SQLSTATE codes to atoms (e.g., `:unique_violation` for `23505`). Custom codes like `45A01` are NOT in Postgrex's built-in table. A pattern-match on `postgres: %{code: :accrue_event_immutable}` fails silently — the actual value is the string `"45A01"` (or a symbol Postgrex invented, depending on version).
**Why it happens:** Assuming Postgrex exposes a custom atom for your custom class.
**How to avoid:** Write a targeted ExUnit test in Phase 1 that inserts into `accrue_events`, attempts `Repo.update_all`, and inspects the full `%Postgrex.Error{}` struct. Use the literal `code` value that comes back (likely `"45A01"` as a binary). Alternatively, inspect `err.postgres.message` for the trigger's `USING MESSAGE` prefix — but message parsing is brittle (CONTEXT.md D-11 forbids it). Prefer matching on the literal code string.
**Warning signs:** Tests pass in one Postgrex version but fail when upgrading.
**Confidence:** MEDIUM. [ASSUMED — Postgrex 0.22 behavior not verified in this research session; planner must verify via a smoke test early in Phase 1.]

### Pitfall 3: mjml_eex Does NOT Hook Into Phoenix.Swoosh's `formats:` Map

**What goes wrong:** CONTEXT.md D-22 describes each template module as `use Phoenix.Swoosh` with `formats: %{"mjml" => :html_body, "text" => :text_body}` — this implies Phoenix.Swoosh will look for a `.mjml` file, pass it through mjml_eex as a template engine, and populate `html_body`. That integration does not exist in mjml_eex as of v0.13. mjml_eex provides `MjmlEEx.Engines.Mjml` which is an **EEx engine** for mjml_eex's own component directives (`render_static_component` / `render_dynamic_component`), NOT a `Phoenix.Template.Engine` that can be registered for the `.mjml` extension with Phoenix.
**Why it happens:** Wishful thinking from reading `formats:` docs + seeing that mjml_eex exposes an "engine" module.
**How to avoid:** Use the idiomatic mjml_eex pattern instead:
```elixir
defmodule Accrue.Emails.PaymentSucceeded do
  use MjmlEEx, mjml_template: "payment_succeeded.mjml.eex"
  # MjmlEEx defines a `render/1` function that compiles the template at build time
end

defmodule Accrue.Mailer.Default do
  import Swoosh.Email
  alias Accrue.Emails

  @impl Accrue.Mailer
  def deliver(:payment_succeeded, assigns) do
    assigns = enrich(assigns)  # rehydrate customer + invoice from DB

    new()
    |> to({assigns.customer.name, assigns.customer.email})
    |> from({Accrue.Config.get!(:from_name), Accrue.Config.get!(:from_email)})
    |> subject("Receipt for payment")
    |> html_body(Emails.PaymentSucceeded.render(assigns))
    |> text_body(Emails.PaymentSucceeded.render_text(assigns))  # separate .text.eex via phoenix_swoosh OR inline EEx
    |> Accrue.Mailer.Swoosh.deliver()
  end
end
```

The text body can come from a sibling `.text.eex` file rendered via plain EEx or `Phoenix.Swoosh.render_body/3` for the text format only. Phoenix.Swoosh's `formats:` option CAN still be used for the text format; the MJML html body is just built directly via `MjmlEEx.render/1`.

**The planner should update the implementation plan to match this pattern and document it as the project's idiomatic email pipeline for all 14+ emails in Phase 6.**

**Warning signs:** Any Phase 1 attempt to register `.mjml` in `config :phoenix, :template_engines` — this fails because mjml_eex doesn't ship a `Phoenix.Template.Engine`.
**Confidence:** HIGH. [VERIFIED: github.com/akoutmos/mjml_eex README + `lib/engines/mjml.ex` — the engine is an `@behaviour EEx.Engine`, not `Phoenix.Template.Engine`].

### Pitfall 4: Starting ChromicPDF in Accrue's Supervision Tree

**What goes wrong:** Plan naïvely adds `{ChromicPDF, on_demand: true}` to `Accrue.Application`'s children list to "make tests work." Now every host app boots ChromicPDF twice, or worse, two ChromicPDF pools compete for the same Chrome processes.
**Why it happens:** Assuming the library owns its own dependencies' lifecycles.
**How to avoid:** `Accrue.Application` has ZERO ChromicPDF children. The install guide tells host apps to add ChromicPDF to their own supervision tree. In Accrue's own test suite, use `Accrue.PDF.Test` adapter (Chrome-free) so Phase 1 tests never need ChromicPDF running. [CITED: CONTEXT.md D-33; ChromicPDF hexdocs confirm on-demand vs. pool setup as caller's choice.]

### Pitfall 5: Oban Worker Args with Structs

**What goes wrong:** Enqueue a mailer job with `%{email: %Swoosh.Email{...}}` or `%{customer: %Customer{}}`. Oban JSON-encodes args; Ecto schemas round-trip lossily (associations, `__meta__`), and `%Swoosh.Email{}` with function refs doesn't round-trip at all.
**Why it happens:** Convenience.
**How to avoid:** Args are always `{type :: atom, %{only_primitive_ids_map}}`. Worker rehydrates from DB. D-27 locks this. PDFs NEVER in args (D-39).

### Pitfall 6: Compile-Time vs Runtime Config Leak

**What goes wrong:** Reading `:stripe_secret_key` via `Application.compile_env!/2` bakes the dev secret into the release beam file.
**How to avoid:** Per CLAUDE.md "Config Boundaries" table:
- **Compile-time OK:** `:auth_adapter`, `:pdf_adapter`, `:mailer_adapter`, `:processor` — read via `Application.compile_env!/2` so misconfig fails at `mix compile`.
- **Runtime REQUIRED:** `:stripe_secret_key`, `:webhook_signing_secret`, `:default_currency`, `:from_email`, brand config, feature flags — read via `Application.get_env/3` in `config/runtime.exs`.

## Runtime State Inventory

**Not applicable** — Phase 1 is a greenfield initial commit. No existing stored data, live service config, OS-registered state, secrets, or build artifacts to inventory. Step 2.5 skipped.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | build | yes | 1.19.5 | — |
| Erlang/OTP | build | yes | 28 | — |
| mix | build | yes | at `/opt/homebrew/bin/mix` | — |
| Chromium | Ghostscript-free PDF rendering (NOT needed in Phase 1) | yes | at `/opt/homebrew/bin/chromium` | `Accrue.PDF.Test` adapter |
| Ghostscript | PDF/A archival mode (NOT needed in Phase 1) | unknown | — | `archival: true` opt-in only |
| PostgreSQL | Event ledger integration tests | unknown | — | Use `Ecto.Adapters.SQL.Sandbox` in tests; host provides PG at runtime |
| Rust toolchain | mjml_eex Rustler NIF build (only needed if no prebuilt binary for Darwin aarch64) | unknown | — | mjml_eex's Rustler NIF typically ships precompiled binaries for macOS/Linux; only needed if precompiled is missing. Document Node.js fallback. |

**Notes for planner:**
- Dev machine has Elixir 1.19.5 + OTP 28, which is ABOVE the declared floor of 1.17/OTP 27. CI matrix must still include 1.17/27 as the floor (CLAUDE.md). 1.19 is not in CLAUDE.md's current matrix — consider adding 1.18 smoke tests but keep 1.17 as minimum.
- Chromium is available on the dev machine but Phase 1 does NOT need it — use `Accrue.PDF.Test` adapter throughout Phase 1 testing.
- PostgreSQL availability is a Phase 1 plan prerequisite for the ledger integration test. If not available locally, plan must either install it or stub the test with a recorded Postgrex error fixture (less good).

**Missing dependencies with no fallback:** none identified.

**Missing dependencies with fallback:** PostgreSQL (tests can use sandbox adapter, but a real PG instance is needed for trigger tests — planner must confirm availability in the first task of Wave 0).

## Code Examples

### Accrue.Money public API (reference)

```elixir
# lib/accrue/money.ex
defmodule Accrue.Money do
  @moduledoc """
  Money value type. Thin wrapper over `Money` (from `:ex_money`) that enforces:

    * integer minor units on construction (no floats, no decimals)
    * zero-decimal (JPY) and three-decimal (KWD) currencies round-trip correctly
    * mixed-currency arithmetic raises `#{__MODULE__}.MismatchedCurrencyError`
  """

  alias Accrue.Money.MismatchedCurrencyError

  @type t :: %__MODULE__{amount_minor: integer(), currency: atom()}
  defstruct [:amount_minor, :currency]

  @spec new(integer(), atom()) :: t()
  def new(amount_minor, currency) when is_integer(amount_minor) and is_atom(currency) do
    # Delegate to ex_money for validation/currency table check
    _ = Money.new!(currency, Decimal.new(amount_minor, "1e-#{Money.Currency.exponent(currency)}"))
    %__MODULE__{amount_minor: amount_minor, currency: currency}
  end

  def new(_, _), do: raise ArgumentError, "Accrue.Money.new/2 requires (integer, atom); use from_decimal/2 for Decimal conversions"

  @spec add(t(), t()) :: t()
  def add(%__MODULE__{currency: c, amount_minor: a}, %__MODULE__{currency: c, amount_minor: b}),
    do: %__MODULE__{currency: c, amount_minor: a + b}
  def add(%__MODULE__{currency: c1}, %__MODULE__{currency: c2}),
    do: raise(MismatchedCurrencyError, left: c1, right: c2)
end
```

Source: Pattern synthesized from ex_money docs. [CITED: hex.pm/ex_money 5.24.2, hexdocs.pm/ex_money]

### Mox test_helper.exs

```elixir
# test/test_helper.exs
Mox.defmock(Accrue.Processor.Mock, for: Accrue.Processor)
Mox.defmock(Accrue.Mailer.Mock,    for: Accrue.Mailer)
Mox.defmock(Accrue.PDF.Mock,       for: Accrue.PDF)
Mox.defmock(Accrue.Auth.Mock,      for: Accrue.Auth)

Application.put_env(:accrue, :processor, Accrue.Processor.Fake)  # Fake is PRIMARY surface
Application.put_env(:accrue, :mailer,    Accrue.Mailer.Default)
Application.put_env(:accrue, :pdf,       Accrue.PDF.Test)
Application.put_env(:accrue, :auth,      Accrue.Auth.Default)

ExUnit.start()
```

Note: Mox is available for pure-behaviour tests where deterministic scripted responses are needed; the Fake is the default runtime test surface.

Source: [CITED: hexdocs.pm/mox/Mox.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Ecto.Repo.transaction/2` | `Ecto.Repo.transact/2` | Ecto 3.12+ | `transaction/2` deprecated; use `transact` everywhere |
| `:stripity_stripe` | `:lattice_stripe` | Accrue project inception | Stripity pins 2019 API; Lattice tracks current |
| wkhtmltopdf / `:pdf_generator` | `:chromic_pdf` | ~2022 | wkhtmltopdf archived with unpatched CVEs |
| `:bamboo` | `:swoosh` | Phoenix 1.6+ | Swoosh is Phoenix default |
| `:poison` | `:jason` | Phoenix 1.4+ | Faster, community standard |
| `:exq` / `:verk` / `:rihanna` | `:oban` | ~2020 | Oban is the standard; others abandoned or niche |

**Deprecated / do NOT use:** wkhtmltopdf, `:stripity_stripe`, `:poison`, `:bamboo`, `:mock`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Postgrex 0.22 surfaces unknown SQLSTATE `45A01` as string `"45A01"` (not a computed atom) | Pitfall #2, Pattern #4 | Pattern-matching on the wrong shape will make immutability enforcement tests silently fail. **Mitigation:** first Phase 1 task writes a smoke test to inspect the real `%Postgrex.Error{}` struct. |
| A2 | mjml_eex's Rustler NIF ships precompiled binaries for macOS aarch64 + common Linux targets; Rust toolchain is not required on every dev machine | Environment Availability | If false, CI matrix needs Rust installed; docs must mention Node fallback. **Mitigation:** check mjml_eex v0.13 release notes / CI badges before Phase 1 Plan finalization. |
| A3 | `Accrue.Application.start/2` should start a `Registry` for Fake processor instances | Pattern #5 | If unnecessary, the library runs a redundant registry. If omitted and needed, Fake processor tests will fail to isolate state. **Mitigation:** plan Task can decide based on whether Fake is per-test or global GenServer. |
| A4 | `ex_money_sql` is NOT needed as a dep because Accrue writes its own Ecto type | Standard Stack | If `ex_money_sql` has useful currency-table helpers Accrue duplicates, that's wasted effort. **Mitigation:** planner reviews `Money.Currency` helpers during design; may still depend on ex_money_sql for non-Ecto-type helpers. |
| A5 | `:accrue_mailers` Oban queue should default to concurrency 20 per CLAUDE.md hint | Decisions summary | If 20 is too aggressive for common SMTP providers, mail sending gets throttled. **Mitigation:** document as a Config-overridable default; host owns Oban config per D-27. |

## Open Questions (RESOLVED)

1. **Where does `Accrue.Repo` come from?**
   - What we know: CONTEXT.md D-10 says "host owns Repo"; Accrue reads `config :accrue, :repo, MyApp.Repo`.
   - What's unclear: Every code example in this research uses `Accrue.Repo.transact/2` but Accrue doesn't define `Accrue.Repo` — it's whatever the host configured.
   - **RESOLVED:** Plan 03 Task 2 ships `lib/accrue/repo.ex` as a runtime-resolved facade: `defp repo, do: Application.get_env(:accrue, :repo) || raise Accrue.ConfigError`. Tests inject `Accrue.TestRepo` via `config/test.exs` (pre-wired by Plan 01). `Accrue.Repo.transact/1`, `insert/2` delegate through.

2. **Does Phase 1 ship a `Accrue.Emails.PaymentSucceeded` reference template, or stub the template-module pattern entirely?**
   - What we know: D-22 says "the behaviour and one reference template" is Phase 1; CONTEXT.md "Claude's Discretion" explicitly calls out that only `PaymentSucceeded` is required in Phase 1.
   - What's unclear: The email requires a Customer + Invoice, which don't exist until Phase 2.
   - **RESOLVED:** Plan 05 Task 1 ships `Accrue.Emails.PaymentSucceeded` using the CORRECTED mjml_eex pattern (`use MjmlEEx, mjml_template: "..."`) with a `render/1` that compiles at build time. The template file (`priv/accrue/templates/emails/payment_succeeded.mjml.eex`) accepts Phase 1 fixture assigns (customer_name, amount, invoice_number, receipt_url) without DB rehydration. Phase 2+ wires real Customer/Invoice rehydration inside `Accrue.Workers.Mailer.perform/1`.

3. **`mix accrue.install` — how much of it in Phase 1?**
   - What we know: D-44 and REQUIREMENTS INST-01..10 place the full installer in Phase 8; D-10 says Phase 1 needs the REVOKE migration stub generated somehow.
   - What's unclear: Does Phase 1 write a real Mix task, or just put the migration stubs under `priv/accrue/templates/migrations/` and document "copy these"?
   - **RESOLVED:** Plan 03 Task 1 ships only the raw migration template files in `priv/accrue/templates/migrations/` (including the REVOKE stub). No Mix task is authored in Phase 1. Phase 8 builds the actual generator. Phase 1 tests run the templates directly via the normal `mix ecto.migrate` flow against `Accrue.TestRepo`.

4. **CI matrix — add Elixir 1.18 or 1.19?**
   - What we know: CLAUDE.md matrix is 1.17/27, 1.18/27, 1.18/28. Dev machine runs 1.19.5/OTP 28.
   - What's unclear: Whether 1.19 entered release after CLAUDE.md was written.
   - **RESOLVED:** Plan 06 Task 2 ships the CI workflow with CLAUDE.md's canonical matrix (1.17/27 floor, 1.18/27 primary, 1.18/28 forward-compat) plus a one-cell `with_sigra` variant on 1.18/27. 1.19 is NOT added to the floor for Phase 1 — it can be bolted on in Phase 9 as a forward smoke test without changing CLAUDE.md's locked floor.

5. **`Accrue.Ecto.Money` type shape — one column or two?**
   - What we know: D-02 says two columns (`amount_minor :bigint` + `currency :string`).
   - What's unclear: How Ecto `Ecto.Type` callbacks handle a TYPE that spans two columns — Ecto types are designed for single-column mapping. Two approaches: (a) helper macro `money_field :price` that expands to two fields and a virtual getter; (b) `embeds_one :price, Accrue.Money.Embedded` (single jsonb column) which contradicts D-02.
   - **RESOLVED:** Plan 02 Task 1 ships BOTH the custom `Accrue.Ecto.Money` Ecto.Type (single-column jsonb form, used inside `accrue_events.data` where money is one property of a blob) AND the `money_field/1` macro (two-column canonical form per D-02). Downstream phases use `money_field/1` in schemas: `schema "subscriptions" do money_field :price end` expands to `price_amount_minor :bigint + price_currency :string + virtual :price`. Property tests in Plan 02 cover USD/JPY/KWD round-trip through the macro.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib), with `ex_unit_notifier` optional |
| Config file | `accrue/test/test_helper.exs` (to be created in Wave 0) |
| Quick run command | `cd accrue && mix test --stale` |
| Full suite command | `cd accrue && mix test` |

Extended toolchain per OSS-02: `mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix credo --strict && mix dialyzer && mix docs --warnings-as-errors && mix hex.audit`.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FND-01 | `Money.new/2` rejects non-integer; zero-decimal (JPY) round-trip; three-decimal (KWD) round-trip | unit + property | `mix test test/accrue/money_test.exs` | Wave 0 |
| FND-01 | Mixed-currency `Money.add/2` raises `MismatchedCurrencyError` | unit | `mix test test/accrue/money_test.exs -t mismatch` | Wave 0 |
| FND-02 | Each error struct is `Exception`-compatible and pattern-matchable | unit | `mix test test/accrue/errors_test.exs` | Wave 0 |
| FND-03 | `Accrue.Config` NimbleOptions schema validates at boot and generates `@moduledoc` docs | unit | `mix test test/accrue/config_test.exs` | Wave 0 |
| FND-04 | Telemetry emits start/stop/exception with correct event names | unit w/ `:telemetry_test` attach | `mix test test/accrue/telemetry_test.exs` | Wave 0 |
| FND-05 | `Accrue.Application.start/2` boots without requiring host Repo | unit | `mix test test/accrue/application_test.exs` | Wave 0 |
| FND-06 | Monorepo layout; `accrue_admin` depends on `accrue` at path in dev | smoke | `cd accrue_admin && mix deps.get && mix compile` | Wave 0 |
| FND-07 | `brand.css` exists with all 7 palette variables in `:root` | file assertion | `mix test test/accrue/brand_test.exs` | Wave 0 |
| PROC-01 | Every `@callback` in `Accrue.Processor` has a corresponding `@impl` in `Fake` and `Stripe` | compile-time (dialyzer) + unit | `mix dialyzer && mix test test/accrue/processor_test.exs` | Wave 0 |
| PROC-03 | Fake processor: deterministic IDs, test-clock advance, scriptable stubs | unit | `mix test test/accrue/processor/fake_test.exs` | Wave 0 |
| PROC-07 | Stripe error → Accrue.Error mapping, metadata preserved | unit w/ Mox-mocked `lattice_stripe` | `mix test test/accrue/processor/stripe_test.exs` | Wave 0 |
| EVT-01 | `Repo.update_all` on `accrue_events` raises `Accrue.EventLedgerImmutableError` | integration (requires PG) | `mix test test/accrue/events/immutability_test.exs` | Wave 0 |
| EVT-01 | REVOKE migration strips UPDATE/DELETE/TRUNCATE from a test role | integration (requires PG + two roles) | `mix test test/accrue/events/revoke_test.exs --only integration` | Wave 0 |
| EVT-02 | Schema has all required columns with correct types + constraints | migration + insert test | `mix test test/accrue/events/event_test.exs` | Wave 0 |
| EVT-03 | `record/1` inside `Repo.transact` and `record_multi/3` inside `Ecto.Multi` both go through same changeset | unit | `mix test test/accrue/events_test.exs` | Wave 0 |
| EVT-03 | Idempotency: duplicate insert with same `idempotency_key` returns `{:ok, existing}` via `on_conflict: :nothing` | unit (requires PG) | `mix test test/accrue/events/idempotency_test.exs` | Wave 0 |
| EVT-07 | When `:opentelemetry` loaded, `trace_id` column populated from current span | unit | `mix test test/accrue/events/trace_id_test.exs --only with_otel` | Wave 0 |
| EVT-08 | Actor enum CHECK constraint rejects `actor_type: "bogus"` | unit (requires PG) | `mix test test/accrue/events/actor_test.exs` | Wave 0 |
| AUTH-01 | `Accrue.Auth` behaviour callbacks exist with correct specs | compile + dialyzer | `mix dialyzer` | Wave 0 |
| AUTH-02 | `Accrue.Auth.Default` returns dev user in `:dev`; raises in `:prod` at boot | unit w/ env var swap | `mix test test/accrue/auth/default_test.exs` | Wave 0 |
| MAIL-01 | `Accrue.Mailer.deliver/2` routes to default adapter, which assembles email via MjmlEEx template + delegates to Swoosh | unit | `mix test test/accrue/mailer_test.exs` | Wave 0 |
| MAIL-01 | Oban worker serialization: args contain only primitives (no structs) | unit | `mix test test/accrue/workers/mailer_test.exs` | Wave 0 |
| PDF-01 | `Accrue.PDF.Test` adapter receives `{:pdf_rendered, html, opts}` and returns fake bytes | unit | `mix test test/accrue/pdf_test.exs` | Wave 0 |
| OBS-01 | Every public function wrapped in `:telemetry.span/3` | coverage audit (integration test attaching a catch-all handler) | `mix test test/accrue/observability_test.exs` | Wave 0 |
| OBS-06 | Stripe `card_declined` response → `%Accrue.CardError{decline_code: "generic_decline"}` | unit w/ Mox | (same as PROC-07) | Wave 0 |
| OSS-11 | `LICENSE` file at monorepo root matches MIT template | file assertion | `mix test test/accrue/license_test.exs` | Wave 0 |
| TEST-01 | Fake Processor is reachable via `Accrue.Processor` facade when configured | unit | `mix test test/accrue/processor/fake_integration_test.exs` | Wave 0 |
| D-45 | `mix compile --warnings-as-errors` passes with and without `:sigra` | CI matrix | `mix compile --warnings-as-errors` in both matrix entries | Wave 0 |

### Sampling Rate

- **Per task commit:** `mix format --check-formatted && mix test --stale`
- **Per wave merge:** `mix test && mix credo --strict`
- **Phase gate:** Full OSS-02 toolchain green (`format + compile --warnings-as-errors + test --warnings-as-errors + credo --strict + dialyzer + docs --warnings-as-errors + hex.audit`) across CI matrix `{1.17/27, 1.18/27, 1.18/28}` × `{with_sigra, without_sigra}`

### Wave 0 Gaps

- [ ] `accrue/mix.exs` — project file with deps + version — no source tree exists yet
- [ ] `accrue/test/test_helper.exs` — ExUnit start + Mox defmocks + Application.put_env
- [ ] `accrue/test/support/repo_case.ex` — shared Postgres sandbox setup for integration tests
- [ ] `accrue/test/support/fake_processor_case.ex` — resets Fake processor between tests
- [ ] `accrue/config/test.exs` — test env config pointing to Fake processor + Test PDF adapter
- [ ] PostgreSQL dev instance for ledger integration tests (`postgres://accrue_test@localhost/accrue_test`) — must exist before EVT-01/02/03/08 tests can run
- [ ] CI workflow matrix YAML (`.github/workflows/ci.yml`) with `with_sigra` / `without_sigra` job variants
- [ ] Dialyzer PLT cache config per CLAUDE.md recipe
- [ ] `accrue/test/accrue/events/fixtures/` — minimal Ecto Repo for trigger tests (may just use a dedicated `Accrue.TestRepo` in dev/test only)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (scaffold only) | `Accrue.Auth` behaviour + `Accrue.Auth.Default` fail-closed in prod. Phase 1 does NOT ship real auth — it ships the boundary. |
| V3 Session Management | no | Host app owns sessions; Accrue reads `conn` via the Auth adapter. |
| V4 Access Control | yes (foundation) | `Accrue.Auth.require_admin_plug/0` is defined in Phase 1 but only enforced by host app. Actor enum enforces attribution. |
| V5 Input Validation | yes | NimbleOptions validates config at boot; `Accrue.Money.new/2` rejects non-integers; Event changeset validates actor_type against enum. |
| V6 Cryptography | indirect | Webhook signature verification (Phase 2 plug) must be constant-time — but Phase 1 only defines `Accrue.SignatureError`, not verification logic. No crypto in Phase 1. |
| V7 Error Handling / Logging | yes | Error structs carry `processor_error` but MUST NOT include secret keys; `Accrue.Processor.Stripe` error mapping must scrub Stripe secret from any logged context. |
| V8 Data Protection | yes | `accrue_events.data jsonb` is write-once; append-only property is cryptographically weaker than Merkle hashing (deferred) but meets audit baseline. No payment-method PII in Phase 1 schemas (only references to Stripe processor IDs). |
| V9 Communication | no (Phase 2+) | Phase 2 webhook TLS is host-owned. |
| V10 Malicious Code | yes | Conditional compile must not execute untrusted code paths; `:sigra` detection via `Code.ensure_loaded?` is safe. |
| V14 Configuration | yes | Compile-time vs runtime config boundary strictly enforced (CLAUDE.md); secrets NEVER compile-time. |

### Known Threat Patterns for Elixir/Phoenix Billing

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret leak via compile-time config | Information Disclosure | `Application.compile_env!/2` only for non-secrets; secrets via `config/runtime.exs` only |
| Ledger tampering via direct SQL | Tampering | Defense in depth: trigger + REVOKE grants (D-09) |
| Impersonated actor in event | Repudiation | `actor_type` CHECK constraint + actor context enforced by `Plug.PutActor` / Oban middleware (D-15) |
| Money arithmetic bug (mixed currencies, float rounding) | Tampering | `Accrue.Money.new/2` rejects floats; cross-currency raises; StreamData property tests cover round-trips |
| Unrecoverable signature-error silently returning error tuple | Elevation (attacker slips bogus webhook past) | D-08: `SignatureError` always raises; webhook plug translates to HTTP 400 |
| Oban job arg leaking PII | Information Disclosure | D-27: only primitive IDs in args, worker rehydrates |
| ChromicPDF Chrome process compromise | Elevation | Host-controlled Chromium instance, not Accrue-spawned; PDF.Test adapter in Accrue's own CI means Accrue's own tests never run Chrome |
| Trigger-disabling superuser | Tampering | REVOKE grants layer (D-09) — superuser can still bypass both, but this is documented residual risk; install guide warns |

### Phase 1 Security Controls Checklist

- [ ] No secrets in compile-time config — verify by `grep -r "compile_env" lib/accrue/` returns only non-secret keys
- [ ] `Accrue.SignatureError` raises (does not return tuple) — covered by unit test
- [ ] `accrue_events` trigger active AND REVOKE stub documented — integration test
- [ ] `Accrue.Money.new/2` refuses float/Decimal/string — property test
- [ ] `Accrue.Auth.Default` raises in `:prod` at boot — unit test with env swap
- [ ] Error structs do not include stripe_secret_key in `:processor_error` — mapping test asserts redaction

## Project Constraints (from CLAUDE.md)

Extracted from `/Users/jon/projects/accrue/CLAUDE.md`. The planner must treat these with the same authority as CONTEXT.md locked decisions.

1. **Tech stack floor:** Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, PostgreSQL 14+. No legacy support.
2. **Release model:** ship complete. First public release is v1.0. Internal phases are build milestones, not public releases.
3. **Security non-negotiables:**
   - Webhook signature verification mandatory and non-bypassable
   - Raw-body plug must run before `Plug.Parsers`
   - Sensitive Stripe fields never logged
   - Payment method details stored as Stripe references, never as PII
4. **Performance:** webhook path <100ms p99 (Phase 2 concern, not Phase 1). Observability: all public entry points emit `:telemetry` start/stop/exception.
5. **Monorepo:** sibling `accrue/` + `accrue_admin/`, non-umbrella. Shared workflows/, per-package `mix.exs` and `CHANGELOG.md`.
6. **License:** MIT both packages.
7. **Test library:** Mox, decisively. No `:mock`, `:meck`, `:mimic`, `:hammox`.
8. **Don't use list (non-exhaustive):** `:stripity_stripe`, `:bamboo`, `:poison`, `:exq`, `:httpoison`/`:tesla` for Stripe, `:commanded`, `:pdf_generator`, `:absinthe` for Accrue API, `:ueberauth`, `:mock`, `pg_uuidv7`.
9. **Conditional compile 4-step pattern** applied to all optional deps (`:sigra`, `:opentelemetry`, `:telemetry_metrics`).
10. **Config boundaries:** adapters compile-time via `Application.compile_env!/2`; secrets + brand config + feature flags runtime-only via `config/runtime.exs`.
11. **`Accrue.Config`** surfaced via `NimbleOptions.docs/1` in the `Accrue` module docs.
12. **Accrue does NOT start** its own Oban, its own Repo, or its own ChromicPDF. Host owns all runtime lifecycles.
13. **Monorepo precedent:** `lattice_stripe` sibling repo (same author) is the template.
14. **Release Please v4** per-package entries with `release-type: "elixir"`, `bump-minor-pre-major: true`.
15. **Dialyzer PLT cache** keyed on OTP × Elixir × mix.lock hash, using `actions/cache/restore@v4` + `save@v4` split (not combined).
16. **GSD workflow enforcement:** All file changes route through a GSD command. No direct edits outside workflow.

## Sources

### Primary (HIGH confidence)
- [VERIFIED] `https://hex.pm/api/packages/ex_money` — ex_money 5.24.2 (2026-01-29), last 3 versions confirmed
- [VERIFIED] `https://hex.pm/api/packages/ex_money_sql` — ex_money_sql 1.12.0 (2026-01-15)
- [CITED] `https://hexdocs.pm/ex_money_sql/readme.html` — composite type vs map type Ecto integration
- [CITED] `https://hexdocs.pm/chromic_pdf/ChromicPDF.Template.html` — `source_and_options/1` signature and options (`content`, `header`, `footer`, `size`, `header_height`, etc.)
- [CITED] `https://hexdocs.pm/ecto/Ecto.Repo.html` — `Repo.transact/2` is the successor to deprecated `transaction/2`
- [CITED] `https://www.postgresql.org/docs/current/plpgsql-errors-and-messages.html` — custom SQLSTATE `45A01` is valid; 5-char digits + uppercase ASCII except `00000` and codes ending `000`
- [CITED] `https://hexdocs.pm/mox/Mox.html` — idiomatic behaviour + `defmock` + `Application.put_env` pattern
- [CITED] `https://hexdocs.pm/ecto_sql/Ecto.Migration.html` — `execute/1` for raw SQL (trigger, REVOKE)
- [CITED] `https://github.com/akoutmos/mjml_eex` — `use MjmlEEx, mjml_template:` is the idiomatic usage pattern
- [CITED] `https://github.com/akoutmos/mjml_eex/blob/master/lib/engines/mjml.ex` — `MjmlEEx.Engines.Mjml` is an `EEx.Engine`, NOT a `Phoenix.Template.Engine`
- [CITED] `https://hexdocs.pm/phoenix_swoosh/Phoenix.Swoosh.html` — `formats:` map + `render_body/3`
- [CITED] `/Users/jon/projects/accrue/CLAUDE.md` — tech stack pins, conditional compile 4-step, config boundaries, test library decision
- [CITED] `/Users/jon/projects/accrue/.planning/phases/01-foundations/01-CONTEXT.md` — all 45 locked decisions D-01..D-45
- [CITED] `/Users/jon/projects/accrue/.planning/REQUIREMENTS.md` — phase 1 requirement IDs

### Secondary (MEDIUM confidence)
- [VERIFIED] `elixir --version` on dev machine — 1.19.5 / OTP 28
- [CITED] `https://akoutmos.com/post/mjml-template-compliation/` — blog post on MJML compilation patterns in Elixir
- [CITED] `https://medium.com/swlh/using-mjml-in-elixir-phoenix-ca27050ff26f` — MJML in Phoenix overview (older but supports the direct-render pattern)

### Tertiary (LOW confidence — marked for validation)
- [ASSUMED A1] Postgrex 0.22 surfaces custom SQLSTATE `45A01` as literal string — not verified in this session; first Phase 1 task must confirm
- [ASSUMED A2] mjml_eex precompiled binaries available for macOS aarch64 — not verified
- [ASSUMED A3] `Accrue.Application` needs a `Registry` child for Fake processor — planner decision
- [ASSUMED A4] `ex_money_sql` may not be needed at all — depends on whether non-Ecto currency helpers are reused
- [ASSUMED A5] `:accrue_mailers` concurrency default of 20 is appropriate — host should override if needed

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions verified via hex.pm API or CLAUDE.md (recent research)
- Architecture patterns: HIGH — idiomatic Elixir library patterns (empty supervisor, behaviour + adapter, Mox) are well-established
- Postgres trigger + REVOKE: HIGH — PostgreSQL docs verified
- SQLSTATE mapping: MEDIUM — Postgrex surface form not verified, smoke test required
- mjml_eex integration: HIGH (pattern corrected) — verified via github source that CONTEXT.md D-22's `formats:` approach is wrong
- Phase 1 scope / requirement mapping: HIGH — CONTEXT.md is fully locked

**Research date:** 2026-04-11
**Valid until:** 2026-05-11 (30 days — Elixir ecosystem is stable; no fast-moving deps)
