# Phase 10: Host App Dogfood Harness - Research

**Researched:** 2026-04-16
**Domain:** Phoenix host-app integration, session auth, mounted LiveView admin, Fake-backed billing, signed webhook ingest
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Harness Location and Shape

- **D-01:** Create the dogfood app as a normal Phoenix app under `examples/accrue_host`, using a conventional host namespace such as `AccrueHost`. This keeps it visible to users and lets Phase 13 reuse the same path for adoption assets without turning Phase 10 into tutorial work.
- **D-02:** The host app must be rebuilt from a clean checkout using documented commands, with no hidden local database, private machine state, or manual setup outside the documented path.
- **D-03:** Default dogfood mode uses local path dependencies for `accrue` and `accrue_admin` so the harness validates the current repo. Leave Hex-style dependency validation for Phase 12 unless it is trivial to support without weakening the path-dependency proof.
- **D-04:** Treat generated installer output as part of the proof. The app should be created or refreshed through `mix accrue.install` and should not hand-wire private Accrue internals to make the harness pass.

### Host-Owned Domain and Auth Boundary

- **D-05:** Use a minimal host-owned `Accounts.User` billable schema with `use Accrue.Billable`; Accrue must not own the user schema.
- **D-06:** Prefer a simple Phoenix-auth-shaped host session boundary over Sigra for this harness. That tests the generic public adapter path instead of relying on another Jon-owned library.
- **D-07:** Mount `accrue_admin` at `/billing` through `AccrueAdmin.Router.accrue_admin/2`, threading only the host session keys needed to identify the current admin.
- **D-08:** Protect the admin mount through a realistic host-owned auth/session check. A test-only bypass is acceptable only if it is explicit, documented, and not the default browser path.

### Fake-Backed User Billing Flow

- **D-09:** The primary user-facing flow should be a small SaaS-style subscription path: signed-in user views a plan, starts a subscription through the generated `MyApp.Billing` facade, sees persisted billing state, and can perform at least one update action such as plan swap or cancel.
- **D-10:** The flow must run against `Accrue.Processor.Fake` with no network access and no live Stripe dependency.
- **D-11:** The host app may use deterministic fake price IDs such as `price_basic` and `price_pro`; the important proof is that calls go through public checkout/subscription APIs and persist normal Accrue state.
- **D-12:** Avoid a fake UI that only inserts rows. The host flow should exercise Accrue APIs and reducer paths so failures expose real first-user integration friction.

### Webhook Proof

- **D-13:** Mount a scoped webhook endpoint using the installer-generated route and the public `Accrue.Webhook.Plug` path, including raw-body handling and signature verification.
- **D-14:** The dogfood test should post a signed Fake/Stripe-shaped payload through the host endpoint rather than bypassing the Plug with direct reducer calls.
- **D-15:** The webhook flow should prove idempotent ingest, persisted `accrue_webhook_events`, dispatch through the normal handler path, and resulting billing/event-ledger state.

### Admin Flow and Audited Action

- **D-16:** The admin UAT path should inspect state created by the user-facing flow, including customer/subscription/webhook/event history visible through `accrue_admin`.
- **D-17:** The required audited admin action should be a low-risk webhook/admin operation such as replaying or requeueing a failed webhook event, because that uses existing admin semantics and avoids inventing refund/cancellation product policy in the dogfood app.
- **D-18:** The admin action proof must verify that an audit/event record is produced, not just that the UI flashes a success message.

### Local Verification

- **D-19:** Phase 10 should add local verification commands for setup, migrations, tests, and booting the host app. CI integration and required GitHub Actions gating are Phase 11.
- **D-20:** Include at least one browser-facing or browser-equivalent UAT path for the host app plus mounted admin UI. A local Playwright path is acceptable if it follows existing repo patterns; otherwise LiveView/Conn tests may cover the same end-to-end behavior until Phase 11 formalizes browser artifacts.
- **D-21:** The verification path must fail on private shortcuts: direct inserts that avoid public APIs, missing raw-body webhook handling, unauthenticated admin mount, hidden env requirements, or generated artifact drift.

### Claude's Discretion

- Exact Phoenix app generator command and whether to commit generated static assets, as long as clean checkout rebuild remains documented and deterministic.
- Exact host auth implementation details, as long as it is host-owned, session-backed, and protects `accrue_admin` realistically.
- Exact route names and page copy inside the dogfood app.
- Whether the local browser UAT uses Playwright immediately or starts with Phoenix-level browser-equivalent tests, provided Phase 11 can promote it to CI without redesign.
- Exact admin action selected from existing `accrue_admin` capabilities, provided it is audited and visible in persisted state.

### Deferred Ideas (OUT OF SCOPE)

- Mandatory GitHub Actions gate for the host app — Phase 11.
- Hex-style dependency validation and first-hour troubleshooting polish — Phase 12 unless trivial to include safely.
- Public tutorial/demo packaging, screenshots, and README positioning — Phase 13.
- Security, performance, accessibility, responsive, and compatibility hardening — Phase 14.
- Hosted public demo environment — future requirement `HOST-09`, not Phase 10.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HOST-01 | A minimal Phoenix host app exists in the repository as the canonical dogfood app for `accrue` and `accrue_admin`. | Use a normal Phoenix 1.8 app at `examples/accrue_host` created generator-first, then adapt it with path deps and installer output. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html][VERIFIED: repo grep] |
| HOST-02 | The host app uses the public installer and package APIs rather than private shortcuts or hand-wired internals. | Keep integration at `mix accrue.install`, `use Accrue.Billable`, generated `MyApp.Billing`, `Accrue.Router.accrue_webhook`, and `AccrueAdmin.Router.accrue_admin/2`. [VERIFIED: repo grep] |
| HOST-03 | The host app has at least one realistic billable schema and generated `MyApp.Billing` facade. | Reuse `mix phx.gen.auth` user schema plus `use Accrue.Billable`; keep generated billing facade as host-owned policy layer. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][VERIFIED: repo grep] |
| HOST-04 | The host app mounts the scoped webhook endpoint and verifies signed Fake/Stripe-shaped webhook payloads end to end. | Use installer router snippet with route-scoped raw-body parser and verify through `Accrue.Webhook.Plug` and `Accrue.Webhook.Ingest`. [VERIFIED: repo grep] |
| HOST-05 | The host app mounts `accrue_admin` behind a realistic auth/session boundary. | Use Phoenix session auth from `phx.gen.auth` and mount `accrue_admin "/billing"` with explicit session key threading. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][VERIFIED: repo grep] |
| HOST-06 | A user-facing checkout/subscription flow works through the host app against the Fake processor without network access. | Route UI actions through `MyApp.Billing.subscribe/swap_plan/cancel` over `Accrue.Billing` with `Accrue.Processor.Fake`; seed realistic state with `Accrue.Test.Factory` only for setup, not proof-path bypasses. [VERIFIED: repo grep] |
| HOST-07 | An admin-facing flow can inspect billing state, view webhook/event history, and perform at least one audited admin action. | Reuse existing admin replay semantics and `admin.step_up.*` audit trail instead of inventing new policy-heavy actions. [VERIFIED: repo grep] |
| HOST-08 | The host app can be rebuilt from a clean checkout with documented commands and no hidden local state. | Depend on documented generator/setup/migration commands only, and plan around the currently missing local PostgreSQL server as an execution prerequisite. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html][VERIFIED: local environment probe] |
</phase_requirements>

## Summary

Phase 10 should be planned as a generator-first Phoenix integration proof, not as a hand-built fixture. Phoenix 1.8.5 still ships the standard `mix phx.new` scaffold and `mix phx.gen.auth` session-auth path, while Accrue already exposes the public integration surface this phase is supposed to dogfood: `use Accrue.Billable`, generated `MyApp.Billing`, `accrue_webhook`, and `accrue_admin`. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html][CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][VERIFIED: repo grep][VERIFIED: hex.pm registry]

The clean plan is: scaffold `examples/accrue_host`, align its dependency floor to the repo's supported stack, add local path deps to `accrue` and `accrue_admin`, run `mix accrue.install`, keep the user flow on public billing facade calls, and prove webhook/admin behavior through the normal router and LiveView paths. The strongest audited admin action is webhook replay or bulk requeue because the admin package already implements that path and already records audit-capable event history. [VERIFIED: repo grep][CITED: https://playwright.dev/docs/test-webserver]

The main planning risks are not conceptual; they are integration drift risks: Phoenix generator defaults do not exactly match the repo's locked floor, the webhook path fails unless the raw-body parser is scoped correctly, and local execution currently lacks a running PostgreSQL server on `localhost:5432`. Build the plan so those are explicit Wave 0 checks, not surprises discovered midway through implementation. [VERIFIED: local Phoenix scaffold probe][VERIFIED: repo grep][VERIFIED: local environment probe]

**Primary recommendation:** Build the harness as a normal Phoenix 1.8 app with generated session auth, local path deps, installer-owned Accrue wiring, route-scoped webhook ingest, and one replay-based admin proof path. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html][CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][VERIFIED: repo grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Host auth/session boundary for browser pages and `/billing` | Frontend Server | Browser / Client | Phoenix owns session cookies, plugs, and LiveView session mounting; the browser only carries the cookie and follows redirects. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][VERIFIED: repo grep] |
| User-facing subscribe / swap / cancel flow | API / Backend | Frontend Server (SSR) | Billing writes and event persistence belong to `Accrue.Billing`; Phoenix pages/forms trigger those APIs and render results. [VERIFIED: repo grep] |
| Signed webhook receipt and idempotent ingest | API / Backend | Database / Storage | Signature verification, ingest, and dispatch live in `Accrue.Webhook.*`; durable dedup and ledger state live in Postgres. [VERIFIED: repo grep] |
| Mounted `accrue_admin` UI | Frontend Server | Browser / Client | Router macro, LiveSession, auth hook, and session threading are server-owned; browser just renders LiveView and submits actions. [VERIFIED: repo grep] |
| Billing, webhook, and audit history persistence | Database / Storage | API / Backend | `accrue_*` tables and `accrue_events` are the durable proof surface; app/API code only mutates them through public actions. [VERIFIED: repo grep] |
| Local browser UAT harness | Browser / Client | Frontend Server | Playwright drives real pages, while the host app boot command and reset/seed wiring live server-side. [VERIFIED: repo grep][CITED: https://playwright.dev/docs/test-webserver] |

## Project Constraints (from CLAUDE.md)

- Work through GSD workflow entry points before repo edits; for planning artifacts, stay inside the current planning workflow. [VERIFIED: CLAUDE.md]
- Supported floors remain Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, PostgreSQL 14+. Do not recommend lower targets. [VERIFIED: CLAUDE.md]
- `accrue` and `accrue_admin` are sibling Mix projects in one monorepo; Phase 10 should preserve that shape and use local path deps for dogfooding. [VERIFIED: CLAUDE.md]
- Webhook signature verification is mandatory and non-bypassable; raw-body handling must run before `Plug.Parsers`, and sensitive Stripe fields must never be logged. [VERIFIED: CLAUDE.md]
- Accrue must not own host auth; host apps provide auth/session integration through the public adapter boundary. [VERIFIED: repo grep][VERIFIED: 10-CONTEXT.md]
- Oban, Repo, and other runtime services are host-owned; Accrue should be integrated into the host supervision/config surface rather than booting its own hidden services. [VERIFIED: CLAUDE.md][VERIFIED: repo grep]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | 1.8.5, published 2026-03-05 [VERIFIED: hex.pm registry] | Host app framework and router/session foundation | `mix phx.new` and Phoenix 1.8 docs are the canonical new-user path this phase is trying to prove. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] |
| Phoenix LiveView | 1.1.28, published 2026-03-27 [VERIFIED: hex.pm registry] | Generated auth screens and mounted `accrue_admin` | `phx.gen.auth` and `accrue_admin` both assume current LiveView patterns. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][VERIFIED: repo grep] |
| Phoenix Ecto | 4.7.0, published 2025-11-07 [VERIFIED: hex.pm registry] | Standard Phoenix Repo integration | `phx.new` still scaffolds Ecto-backed Phoenix apps and this phase needs real migrations and Repo setup. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] |
| Ecto SQL | 3.13.5, published 2026-03-03 [VERIFIED: hex.pm registry] | Migrations and SQL integration | Matches the repo's locked Accrue floor and current Phoenix generator defaults for Ecto apps. [VERIFIED: CLAUDE.md][VERIFIED: local Phoenix scaffold probe] |
| Postgrex | 0.22.0, published 2026-01-10 [VERIFIED: hex.pm registry] | PostgreSQL adapter | Aligns with the repo's locked Postgres-backed billing persistence model. [VERIFIED: CLAUDE.md] |
| Bandit | 1.10.4, published 2026-03-26 [VERIFIED: hex.pm registry] | Default Phoenix HTTP adapter | `mix phx.new` defaults to Bandit in Phoenix 1.8.5, so sticking with it keeps the dogfood path close to the new-user default. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html][VERIFIED: local Phoenix scaffold probe] |
| Oban | 2.21.1, published 2026-03-26 [VERIFIED: hex.pm registry] | Webhook dispatch and async billing jobs | Accrue's ingest path and host-owned queue wiring already assume Oban. [VERIFIED: repo grep] |
| `accrue` | 0.1.2, published 2026-04-16 [VERIFIED: hex.pm registry] | Public billing, webhook, and test APIs | Phase 10 must dogfood the released public surface, but via local `path:` deps. [VERIFIED: 10-CONTEXT.md][VERIFIED: repo grep] |
| `accrue_admin` | 0.1.2, published 2026-04-16 [VERIFIED: hex.pm registry] | Mounted admin UI | Phase 10 explicitly requires a realistic mounted admin boundary. [VERIFIED: 10-CONTEXT.md][VERIFIED: repo grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix HTML | 4.3.0, published 2025-09-28 [VERIFIED: hex.pm registry] | HEEx helpers for generated host UI | Keep it when using normal Phoenix HTML/LiveView pages in the example app. [VERIFIED: local Phoenix scaffold probe] |
| `bcrypt_elixir` | 3.3.2, published 2025-05-19 [VERIFIED: hex.pm registry] | Password hashing for `phx.gen.auth` | Use the generator default unless you have a locked reason to swap hashers later. [VERIFIED: local Phoenix scaffold probe][CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] |
| Swoosh | 1.25.0, published 2026-04-02 [VERIFIED: hex.pm registry] | Mailbox preview for generated auth flows | Keep it if the host app uses generated registration/login flows and local confirmation mail previews. [VERIFIED: local Phoenix scaffold probe] |
| `@playwright/test` | 1.59.1, published 2026-04-01 [VERIFIED: npm registry] | Local browser UAT, if Phase 10 includes Playwright | Reuse the repo's existing `webServer`, trace, and screenshot pattern when browser proof is included. [VERIFIED: repo grep][CITED: https://playwright.dev/docs/test-webserver] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `mix phx.gen.auth` | Custom minimal session controller/plugs | Faster to sketch, but it weakens the "new Phoenix user" proof and reintroduces auth edge cases Phoenix already generates. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] |
| Bandit | `plug_cowboy` 2.8.0 [VERIFIED: hex.pm registry] | Cowboy is fine for internal test endpoints, but Bandit matches the default `phx.new` user path in Phoenix 1.8. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] |
| Playwright local UAT | Phoenix ConnTest + LiveViewTest only | Phoenix tests are faster and good enough for browser-equivalent proof, but they miss the real mounted browser path and future CI artifacts. [VERIFIED: repo grep][CITED: https://playwright.dev/docs/test-webserver] |

**Installation:**
```bash
mix phx.new examples/accrue_host \
  --app accrue_host \
  --module AccrueHost \
  --database postgres \
  --binary-id \
  --no-dashboard \
  --no-agents-md

cd examples/accrue_host
mix phx.gen.auth Accounts User users --live --binary-id
# add local path deps to ../../accrue and ../../accrue_admin
mix deps.get
mix accrue.install \
  --yes \
  --billable AccrueHost.Accounts.User \
  --billing-context AccrueHost.Billing \
  --admin-mount /billing \
  --webhook-path /webhooks/stripe
```
[CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html][CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][VERIFIED: repo grep]

## Architecture Patterns

### System Architecture Diagram

```text
Browser
  -> Phoenix pages / LiveView auth flow
  -> Host route handlers / LiveView events
  -> Generated AccrueHost.Billing facade
  -> Accrue.Billing public APIs
  -> Repo + Accrue tables + accrue_events ledger

Fake / Stripe-shaped webhook POST
  -> /webhooks/stripe
  -> route-scoped raw-body parser
  -> Accrue.Webhook.Plug
  -> Accrue.Webhook.Ingest
  -> accrue_webhook_events + Oban job + accrue_events
  -> normal webhook dispatch / reducer path
  -> updated billing projections

Authenticated admin browser
  -> /billing mounted by AccrueAdmin.Router.accrue_admin/2
  -> AccrueAdmin.AuthHook + host session keys
  -> admin LiveViews
  -> query existing billing/webhook/event state
  -> replay/requeue action
  -> admin.step_up.* / admin audit events
```
[VERIFIED: repo grep]

### Recommended Project Structure
```text
examples/accrue_host/
├── lib/accrue_host/                  # Host domain, Repo, generated Billing facade
│   ├── accounts/                     # phx.gen.auth user + scope
│   ├── billing.ex                    # mix accrue.install output
│   └── billing_handler.ex            # mix accrue.install output
├── lib/accrue_host_web/
│   ├── controllers/                  # Session + page controllers
│   ├── live/                         # User-facing billing pages if LiveView-backed
│   ├── user_auth.ex                  # phx.gen.auth auth boundary
│   └── router.ex                     # browser, webhook, and accrue_admin mounts
├── config/                           # runtime secrets, Oban wiring, Accrue config
├── priv/repo/migrations/             # host auth tables + accrue migrations
├── test/                             # DataCase, ConnCase, LiveView tests, webhook tests
└── e2e/                              # optional local Playwright UAT
```
[CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html][VERIFIED: repo grep]

### Pattern 1: Generator-First Host App
**What:** Start from `mix phx.new` and `mix phx.gen.auth`, then adapt the generated app to use local path deps and Accrue installer output. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html][CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html]
**When to use:** Always for this phase; the whole point is to model the first-user path, not a custom internal fixture. [VERIFIED: 10-CONTEXT.md]
**Example:**
```elixir
# Source: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html
scope "/", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :require_authenticated_user,
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}] do
    live "/users/settings", UserLive.Settings, :edit
  end
end
```

### Pattern 2: Public-Boundary Billing Integration
**What:** Keep the host app at `use Accrue.Billable` plus generated `AccrueHost.Billing` wrappers, and let `Accrue.Billing` own processor normalization and persistence. [VERIFIED: repo grep]
**When to use:** For every user-facing billing action in the example app. [VERIFIED: 10-CONTEXT.md]
**Example:**
```elixir
# Source: /Users/jon/projects/accrue/accrue/priv/accrue/templates/install/billing.ex.eex
defmodule AccrueHost.Billing do
  alias Accrue.Billing

  def subscribe(billable, price_id, opts \\ []), do: Billing.subscribe(billable, price_id, opts)
  def swap_plan(subscription, price_id, opts), do: Billing.swap_plan(subscription, price_id, opts)
  def cancel(subscription, opts \\ []), do: Billing.cancel(subscription, opts)
end
```

### Pattern 3: Route-Scoped Webhook Ingest
**What:** Mount the webhook through the router macro inside a dedicated raw-body pipeline. [VERIFIED: repo grep]
**When to use:** For the one real webhook endpoint the host app exposes in Phase 10. [VERIFIED: 10-CONTEXT.md]
**Example:**
```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/install/patches.ex
import Accrue.Router

pipeline :accrue_webhook_raw_body do
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
    length: 1_000_000
end

scope "/webhooks" do
  pipe_through :accrue_webhook_raw_body
  accrue_webhook "/stripe", :stripe
end
```

### Pattern 4: Mounted Admin Behind Host Auth
**What:** Let Phoenix own the auth boundary and `AccrueAdmin.Router.accrue_admin/2` own the mounted admin routes and assets. [VERIFIED: repo grep]
**When to use:** For `/billing` and any realistic admin-only verification path. [VERIFIED: 10-CONTEXT.md]
**Example:**
```elixir
# Source: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex
import AccrueAdmin.Router

accrue_admin "/billing", session_keys: [:user_token]
```

### Anti-Patterns to Avoid
- **Hand-writing admin routes/assets:** Use `AccrueAdmin.Router.accrue_admin/2`; do not copy package internals into the host router. [VERIFIED: repo grep]
- **Direct row inserts as the proof path:** Setup fixtures can seed state, but the user and admin proofs must go through public APIs and mounted routes. [VERIFIED: 10-CONTEXT.md]
- **Global raw-body parser changes:** Keep webhook raw-body handling route-scoped so the host app does not accidentally change unrelated request parsing. [VERIFIED: repo grep]
- **Auth-by-URL hiding:** `/billing` must fail closed through host session/admin checks, not just by being undocumented. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][VERIFIED: repo grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Session auth for the host app | Custom session plugs/controllers from scratch | `mix phx.gen.auth` | It already generates current-scope plumbing, tests, mailer hooks, and session flows the planner would otherwise have to re-specify. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] |
| Billable integration layer | Private calls into Accrue internals | `use Accrue.Billable` + generated `AccrueHost.Billing` | This is the supported host boundary and the explicit proof surface for HOST-02/HOST-03. [VERIFIED: repo grep] |
| Webhook raw-body verification | Ad hoc body caching or direct reducer calls | Installer router snippet + `Accrue.Webhook.Plug` | Signature verification and idempotent ingest already exist and are security-sensitive. [VERIFIED: repo grep] |
| Admin route tree and auth hook | Copy-pasted LiveView routes | `AccrueAdmin.Router.accrue_admin/2` | The package already owns assets, LiveSession, auth hook, and mount semantics. [VERIFIED: repo grep] |
| Fake billing lifecycle fixtures | Manual DB row graphs | `Accrue.Test.Factory` and `Accrue.Test.Webhooks` | These helpers already create realistic Fake-backed state through supported paths. [VERIFIED: repo grep] |
| Browser server orchestration | Custom shell scripts for server boot/waiting | Playwright `webServer` config | The repo already uses this pattern, and it produces repeatable startup plus retained traces/screenshots on failure. [VERIFIED: repo grep][CITED: https://playwright.dev/docs/test-webserver] |

**Key insight:** the shortest safe Phase 10 path is to reuse Phoenix's generator surfaces and Accrue's public host surfaces exactly where they already exist, because this phase is measuring first-user friction rather than library feature coverage. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html][VERIFIED: repo grep]

## Common Pitfalls

### Pitfall 1: Phoenix Generator Drift
**What goes wrong:** The generated app compiles, but its floors and defaults do not exactly match the repo's supported stack or desired repo hygiene. [VERIFIED: local Phoenix scaffold probe][VERIFIED: CLAUDE.md]
**Why it happens:** `mix phx.new` 1.8.5 still emits broad version constraints like Elixir `~> 1.15`, `phoenix_ecto ~> 4.5`, `bandit ~> 1.5`, and generates `AGENTS.md` unless told otherwise. [VERIFIED: local Phoenix scaffold probe][CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html]
**How to avoid:** Normalize the generated app immediately: bump floors to match repo constraints, add path deps, and decide up front whether to pass `--no-agents-md`. [VERIFIED: CLAUDE.md][CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html]
**Warning signs:** Mixed dependency ranges, unexpected nested `AGENTS.md`, and generator output that diverges from the repo's Elixir floor. [VERIFIED: local Phoenix scaffold probe]

### Pitfall 2: Proof Path Bypass
**What goes wrong:** Tests pass because rows were inserted directly, but the host app never actually proves the public installer and API path. [VERIFIED: 10-CONTEXT.md]
**Why it happens:** It is faster to seed tables than to drive `MyApp.Billing`, router mounts, and webhook POSTs. [VERIFIED: 10-CONTEXT.md]
**How to avoid:** Restrict direct inserts to setup-only fixtures and keep the assertion path on user clicks/forms, webhook POSTs, and admin actions. [VERIFIED: 10-CONTEXT.md][VERIFIED: repo grep]
**Warning signs:** No calls to generated billing facade, no signed webhook POST in tests, or no mounted `/billing` auth path in coverage. [VERIFIED: repo grep]

### Pitfall 3: Raw-Body Parser Missing or Too Broad
**What goes wrong:** Signed webhook tests fail, or the host app mutates global request parsing just to make webhooks work. [VERIFIED: repo grep]
**Why it happens:** `Accrue.Webhook.Plug` expects `conn.assigns[:raw_body]`, which only exists if `Plug.Parsers` uses `Accrue.Webhook.CachingBodyReader` first. [VERIFIED: repo grep]
**How to avoid:** Apply the installer router snippet exactly and keep it route-scoped under `/webhooks`. [VERIFIED: repo grep]
**Warning signs:** 400 signature failures, empty raw bodies, or host router changes that add a global custom body reader. [VERIFIED: repo grep]

### Pitfall 4: Admin Boundary That Looks Real but Isn't
**What goes wrong:** `accrue_admin` is mounted, but any browser session can reach it or destructive actions are not attributable to a real admin actor. [VERIFIED: repo grep][VERIFIED: 10-CONTEXT.md]
**Why it happens:** Teams mount the macro but skip host auth/session wiring or skip the `current_admin` path. [VERIFIED: repo grep]
**How to avoid:** Use `phx.gen.auth` sessions for host login, forward only required session keys, and assert redirect/fail-closed behavior for anonymous users. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][VERIFIED: repo grep]
**Warning signs:** `/billing` works without login, missing session keys in the LiveSession, or admin actions without `admin.step_up.*` / audit evidence. [VERIFIED: repo grep]

### Pitfall 5: Hidden Runtime State
**What goes wrong:** A fresh checkout does not boot because Postgres, secrets, or Oban wiring were assumed rather than documented. [VERIFIED: local environment probe][VERIFIED: repo grep]
**Why it happens:** Local machines often already have databases and env vars set from earlier work. [VERIFIED: 10-CONTEXT.md]
**How to avoid:** Put setup, `mix ecto.create`, `mix ecto.migrate`, required env vars, and Oban queues into documented commands and test them from a clean app directory. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html][VERIFIED: repo grep]
**Warning signs:** Boot instructions reference unstated env vars, or `pg_isready` fails on the target machine. [VERIFIED: local environment probe]

## Code Examples

Verified patterns from official sources and the current codebase:

### Host Billable Schema
```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/billable.ex
schema "users" do
  field :email, :string
  use Accrue.Billable
  timestamps()
end
```
[VERIFIED: repo grep]

### Mounted Admin + Webhook Router
```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/router.ex
# Source: /Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex
import Accrue.Router
import AccrueAdmin.Router

scope "/webhooks" do
  pipe_through :accrue_webhook_raw_body
  accrue_webhook "/stripe", :stripe
end

accrue_admin "/billing", session_keys: [:user_token]
```
[VERIFIED: repo grep]

### Playwright Server-Orchestration Shape
```javascript
// Source: https://playwright.dev/docs/test-webserver
webServer: {
  command: "MIX_ENV=test mix host_app.e2e.server",
  url: "http://127.0.0.1:4018/health",
  reuseExistingServer: !process.env.CI,
  timeout: 120_000
}
```
[CITED: https://playwright.dev/docs/test-webserver]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phoenix app booted with Cowboy by default | Phoenix 1.8 `mix phx.new` defaults to Bandit | Current in Phoenix installer 1.8.5 [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] | The host harness should stay on Bandit unless there is a concrete incompatibility. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] |
| Auth examples centered on controller-only plugs | `mix phx.gen.auth` now generates current-scope plumbing and LiveView session hooks by default | Current in Phoenix auth docs for 1.8 [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] | The host app can use a realistic minimal auth boundary without inventing its own session model. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] |
| Browser UAT often wired with custom shell scripts | Playwright `webServer` config is the standard orchestration pattern | Current in Playwright docs and already used in `accrue_admin` [CITED: https://playwright.dev/docs/test-webserver][VERIFIED: repo grep] | Phase 10 can inherit repeatable startup, traces, and screenshots from an existing repo pattern. [VERIFIED: repo grep] |

**Deprecated/outdated:**
- Hand-wiring private Accrue routes or internals is outdated for this phase because installer patches, billing templates, router macros, and test helpers already exist as the supported integration path. [VERIFIED: repo grep]
- Treating Cowboy as the default new-app server assumption is outdated for Phoenix 1.8 planning. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None | — | — |

All claims in this research were verified or cited in this session — no user confirmation needed. [VERIFIED: research artifact review]

## Open Questions

1. **Where should optional Playwright live for the host app?**
   - What we know: The repo already has a working Playwright pattern in [`accrue_admin/playwright.config.js`](/Users/jon/projects/accrue/accrue_admin/playwright.config.js) and [`accrue_admin/e2e/phase7-uat.spec.js`](/Users/jon/projects/accrue/accrue_admin/e2e/phase7-uat.spec.js). [VERIFIED: repo grep]
   - What's unclear: Whether Phase 10 wants browser UAT colocated under `examples/accrue_host` or temporarily reused from the existing admin workspace. [VERIFIED: 10-CONTEXT.md]
   - Recommendation: Prefer host-app-local Playwright files if browser UAT is added in Phase 10, because the capability belongs to the host app and Phase 11 can promote it directly into CI. [VERIFIED: repo grep]

2. **Should generated Phoenix assets be committed or regenerated in docs?**
   - What we know: The phase allows discretion here, and `phx.new` produces assets plus related toolchain files by default. [VERIFIED: 10-CONTEXT.md][VERIFIED: local Phoenix scaffold probe]
   - What's unclear: Whether the repo wants the example app to be fully committed and immediately runnable without first regenerating assets locally. [VERIFIED: 10-CONTEXT.md]
   - Recommendation: Commit the generated app and its current assets for determinism, but document the exact generator/setup commands so rebuild-from-clean is still provable. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Phoenix host app, Mix tasks | ✓ [VERIFIED: local environment probe] | 1.19.5 / OTP 28 [VERIFIED: local environment probe] | — |
| Mix | `mix phx.new`, `mix phx.gen.auth`, `mix accrue.install`, tests | ✓ [VERIFIED: local environment probe] | 1.19.5 [VERIFIED: local environment probe] | — |
| Phoenix installer (`mix phx.new`) | Scaffolding `examples/accrue_host` | ✓ [VERIFIED: local environment probe] | 1.8.5 [VERIFIED: local environment probe] | — |
| Node / npm / npx | Assets and optional Playwright | ✓ [VERIFIED: local environment probe] | Node 22.14.0, npm 11.1.0 [VERIFIED: local environment probe] | — |
| Playwright package + browser cache | Optional browser UAT | ✓ [VERIFIED: local environment probe] | `@playwright/test` package present; browser cache present [VERIFIED: local environment probe] | Use Phoenix Conn/LiveView tests first if Phase 10 does not add host-app-local Playwright immediately. [VERIFIED: 10-CONTEXT.md] |
| PostgreSQL binaries | `mix ecto.create`, `mix ecto.migrate`, app boot | Partial [VERIFIED: local environment probe] | `psql` and `postgres` binaries found; no server responding on `localhost:5432` [VERIFIED: local environment probe] | Start a local Postgres instance or point the host app at another documented local database. |

**Missing dependencies with no fallback:**
- A running PostgreSQL server is required to execute the eventual host app setup and integration suite; the binaries exist, but no reachable server was detected on the default port. [VERIFIED: local environment probe]

**Missing dependencies with fallback:**
- None for planning; browser UAT can start as Phoenix-level end-to-end tests if Playwright is deferred within the phase. [VERIFIED: 10-CONTEXT.md]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.ConnTest + Phoenix.LiveViewTest, with optional Playwright local UAT modeled on existing repo patterns. [VERIFIED: repo grep][CITED: https://playwright.dev/docs/test-webserver] |
| Config file | Mix aliases in host `mix.exs`; Playwright config does not exist yet and should be added in Wave 0 only if browser UAT is chosen. [VERIFIED: local Phoenix scaffold probe][VERIFIED: repo grep] |
| Quick run command | `cd examples/accrue_host && mix test` [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] |
| Full suite command | `cd examples/accrue_host && mix test && npm exec playwright test` if Playwright is added; otherwise `mix test` remains the phase gate. [CITED: https://playwright.dev/docs/test-webserver][VERIFIED: 10-CONTEXT.md] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HOST-01 | Example app compiles and boots as a normal Phoenix app under `examples/accrue_host` | integration | `cd examples/accrue_host && mix test` | ❌ Wave 0 |
| HOST-02 | Installer/public APIs are used, not private shortcuts | integration | `cd examples/accrue_host && mix test test/install_boundary_test.exs` | ❌ Wave 0 |
| HOST-03 | Host `Accounts.User` billable schema + generated billing facade work | integration | `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs` | ❌ Wave 0 |
| HOST-04 | Signed webhook POST flows through mounted endpoint and normal ingest path | integration | `cd examples/accrue_host && mix test test/accrue_host_web/webhook_ingest_test.exs` | ❌ Wave 0 |
| HOST-05 | `/billing` is behind realistic auth/session checks | live/integration | `cd examples/accrue_host && mix test test/accrue_host_web/admin_mount_test.exs` | ❌ Wave 0 |
| HOST-06 | Signed-in user can subscribe and update/cancel via public billing facade against Fake | live/integration | `cd examples/accrue_host && mix test test/accrue_host_web/subscription_flow_test.exs` | ❌ Wave 0 |
| HOST-07 | Admin can inspect state and replay/requeue one webhook with audit evidence | live/integration | `cd examples/accrue_host && mix test test/accrue_host_web/admin_webhook_replay_test.exs` | ❌ Wave 0 |
| HOST-08 | Clean-checkout setup path is documented and reproducible | smoke/manual + scripted | `cd examples/accrue_host && mix ecto.create && mix ecto.migrate && mix test` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `cd examples/accrue_host && mix test`
- **Per wave merge:** `cd examples/accrue_host && mix test`
- **Phase gate:** `mix test` green for the host app, plus one browser-facing or browser-equivalent UAT path per D-20. [VERIFIED: 10-CONTEXT.md]

### Wave 0 Gaps
- [ ] `examples/accrue_host` scaffold and `mix.exs` with local path deps — covers HOST-01, HOST-08.
- [ ] Host `DataCase` / `ConnCase` / auth test support — covers HOST-03 through HOST-07.
- [ ] Webhook integration test file for signed POST + ingest assertions — covers HOST-04.
- [ ] Admin mount/auth test file — covers HOST-05, HOST-07.
- [ ] Optional `package.json` + `playwright.config.js` under `examples/accrue_host` if browser UAT is chosen in Phase 10 — covers HOST-07, HOST-08.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] | Use generated Phoenix session auth for the host app. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] |
| V3 Session Management | yes [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] | Keep `/billing` behind host session cookies and current-scope plumbing, not query params or custom tokens. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][VERIFIED: repo grep] |
| V4 Access Control | yes [VERIFIED: repo grep] | Gate admin access through host auth plus `AccrueAdmin.AuthHook`; assert anonymous redirect/fail-closed behavior. [VERIFIED: repo grep] |
| V5 Input Validation | yes [VERIFIED: repo grep] | Rely on Phoenix params + Ecto changesets + Accrue config/schema validation. [VERIFIED: repo grep] |
| V6 Cryptography | yes [VERIFIED: repo grep] | Never hand-roll webhook verification; use Accrue signature verification and generated password hashing stack. [VERIFIED: repo grep][VERIFIED: local Phoenix scaffold probe] |

### Known Threat Patterns for Phoenix + Accrue Host Harness

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsigned or tampered webhook payload accepted by the host endpoint | Spoofing / Tampering | Route-scoped raw-body parser + `Accrue.Webhook.Plug` signature verification before ingest. [VERIFIED: repo grep] |
| Anonymous user reaches `/billing` or destructive admin actions | Elevation of Privilege | Host session auth, explicit admin check, and step-up/audit trail on admin actions. [VERIFIED: repo grep] |
| Host flow silently bypasses public APIs via direct inserts | Repudiation / Tampering | Keep proof-path tests on generated facade calls, mounted routes, and persisted `accrue_events`. [VERIFIED: 10-CONTEXT.md][VERIFIED: repo grep] |
| Secret leakage in logs or docs | Information Disclosure | Keep Stripe/webhook secrets in runtime config and rely on installer redaction behavior. [VERIFIED: repo grep][VERIFIED: CLAUDE.md] |

## Sources

### Primary (HIGH confidence)
- `https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html` - current Phoenix 1.8 generator options and defaults.
- `https://hexdocs.pm/phoenix/mix_phx_gen_auth.html` - current Phoenix auth generator and scope/session patterns.
- `https://playwright.dev/docs/test-webserver` - current Playwright `webServer` orchestration pattern.
- `https://hex.pm/api/packages/phoenix` - Phoenix 1.8.5 release version and publish timestamp.
- `https://hex.pm/api/packages/phoenix_live_view` - LiveView 1.1.28 release version and publish timestamp.
- `https://hex.pm/api/packages/phoenix_ecto` - Phoenix Ecto 4.7.0 release version and publish timestamp.
- `https://hex.pm/api/packages/ecto_sql` - Ecto SQL 3.13.5 release version and publish timestamp.
- `https://hex.pm/api/packages/postgrex` - Postgrex 0.22.0 release version and publish timestamp.
- `https://hex.pm/api/packages/bandit` - Bandit 1.10.4 release version and publish timestamp.
- `https://hex.pm/api/packages/oban` - Oban 2.21.1 release version and publish timestamp.
- `https://hex.pm/api/packages/swoosh` - Swoosh 1.25.0 release version and publish timestamp.
- `npm registry (@playwright/test)` - 1.59.1 version and publish timestamp.
- Repo sources:
  - `/Users/jon/projects/accrue/accrue/lib/mix/tasks/accrue.install.ex`
  - `/Users/jon/projects/accrue/accrue/lib/accrue/router.ex`
  - `/Users/jon/projects/accrue/accrue/lib/accrue/webhook/plug.ex`
  - `/Users/jon/projects/accrue/accrue/lib/accrue/webhook/ingest.ex`
  - `/Users/jon/projects/accrue/accrue/lib/accrue/billable.ex`
  - `/Users/jon/projects/accrue/accrue/lib/accrue/test.ex`
  - `/Users/jon/projects/accrue/accrue/lib/accrue/test/factory.ex`
  - `/Users/jon/projects/accrue/accrue/lib/accrue/test/webhooks.ex`
  - `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex`
  - `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/auth_hook.ex`
  - `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/step_up.ex`
  - `/Users/jon/projects/accrue/accrue_admin/playwright.config.js`
  - `/Users/jon/projects/accrue/accrue_admin/e2e/phase7-uat.spec.js`

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - current package versions, publish dates, and Phoenix/Playwright docs were verified directly. [VERIFIED: hex.pm registry][VERIFIED: npm registry][CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html][CITED: https://playwright.dev/docs/test-webserver]
- Architecture: HIGH - the recommended integration points come straight from current Accrue and `accrue_admin` public modules plus the locked phase decisions. [VERIFIED: repo grep][VERIFIED: 10-CONTEXT.md]
- Pitfalls: HIGH - they come from current generator output, local environment probes, and the existing webhook/admin integration code. [VERIFIED: local Phoenix scaffold probe][VERIFIED: repo grep][VERIFIED: local environment probe]

**Research date:** 2026-04-16
**Valid until:** 2026-05-16
