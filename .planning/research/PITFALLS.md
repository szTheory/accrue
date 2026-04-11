# Pitfalls Research

**Domain:** Elixir/Phoenix billing library (Stripe-first, OSS)
**Researched:** 2026-04-11
**Confidence:** HIGH (Stripe gotchas, webhook pitfalls, Elixir OSS patterns — all well-documented in Stripe docs, Pay/Cashier/dj-stripe issue trackers, and Elixir community conventions). MEDIUM on ChromicPDF and Release Please monorepo specifics.

> **Scope note:** This document catalogues pitfalls NOT already pre-mitigated by Accrue's architectural decisions in `PROJECT.md`. Pre-mitigated traps (polymorphic billable, raw-body plug ordering, Fake Processor, DB idempotency, ChromicPDF behaviour, Postgres-only, Stripe-first) are referenced only when they interact with a live pitfall.

---

## Critical Pitfalls

### Pitfall 1: `cancel_at_period_end=true` treated as "canceled" in access control

**What goes wrong:**
User clicks "cancel" in portal. Stripe sets `cancel_at_period_end: true` but `status: "active"` and subscription keeps billing until `current_period_end`. Developer writes `if subscription.status == "canceled", do: deny_access`, which returns false, so access is granted. Separately, developer writes `if subscription.canceled?, do: deny_access` and immediately cuts off a user who paid through month-end. Both sides of the bug ship simultaneously in different apps.

**Why it happens:**
Stripe's state model has two orthogonal flags: `status` (billing state machine) and `cancel_at_period_end` (intent flag). Most developers model cancellation as a single boolean. The Stripe dashboard also labels these as "canceling" which has no machine-readable equivalent.

**How to avoid:**
Expose three canonical predicates on `Accrue.Billing.Subscription`:
- `active?/1` — true when `status in ["active", "trialing"]` AND (`cancel_at_period_end == false` OR `current_period_end > now`)
- `canceling?/1` — true when `cancel_at_period_end == true` AND `status == "active"`
- `canceled?/1` — true when `status == "canceled"` OR (`cancel_at_period_end == true` AND `current_period_end <= now`)

Document these in ExDoc with a state-transition diagram. Never expose raw `status` as the access-control primitive in examples.

**Warning signs:**
- Tests for "user cancels" that only assert on `status`
- Code that does `subscription.status == "canceled"` anywhere
- Support tickets mentioning "I canceled but I'm still being charged" or "I paid for the month but lost access"

**Phase to address:** Subscription domain modeling phase (first Billing phase).

---

### Pitfall 2: `incomplete` subscriptions treated as active, then silently expiring after 23 hours

**What goes wrong:**
First invoice of a new subscription fails (bad card, 3DS pending). Stripe creates the subscription with `status: "incomplete"` and a 23-hour window to pay. App code treats all non-`canceled` subs as granting access, so user gets 23 hours of free access, then silently disappears as `incomplete_expired` with no webhook the app is watching.

**Why it happens:**
`incomplete` is undocumented in Cashier-style tutorials. Most code paths assume successful first charge. The 23-hour window is a grace mechanism for 3DS/SCA flows, not a "free trial."

**How to avoid:**
- `Subscription.active?/1` must exclude `"incomplete"` and `"incomplete_expired"`
- Subscribe to `customer.subscription.updated` AND `invoice.payment_action_required` webhooks
- Emit an `Accrue.Events` record on `incomplete` → `incomplete_expired` transition so it's audit-visible
- Ship a high-signal ops telemetry event `[:accrue, :subscription, :incomplete_expired]` for SRE dashboards

**Warning signs:**
- Users report "I had to enter my card twice"
- `incomplete_expired` subscriptions accumulating in the DB with no followup
- Missing `payment_action_required` handler in integration tests

**Phase to address:** Subscription domain phase + Webhook handler contract phase.

---

### Pitfall 3: Zero-decimal currencies multiplied by 100

**What goes wrong:**
Developer sees Stripe amounts are in "cents" and writes `amount * 100` everywhere. For JPY, KRW, VND, CLP (zero-decimal currencies) this is catastrophic — a ¥500 charge becomes ¥50,000. For BHD, KWD, JOD (three-decimal currencies) it's under-charging by 10x.

**Why it happens:**
Stripe's "all amounts in the smallest currency unit" line is easy to skim as "amounts in cents." Test fixtures are always USD. Most libraries never audit currency handling.

**How to avoid:**
- `Accrue.Money` type that wraps `{amount_minor :: integer, currency :: String.t()}` — never a bare integer
- Use `ex_money` or a hand-rolled currency table that encodes decimal exponent per ISO 4217 currency
- Reject bare integers at API boundaries: `Accrue.Billing.create_charge(customer, Money.new(500, "JPY"))` not `create_charge(customer, 500, "JPY")`
- Fake Processor must simulate a JPY charge in tests; include at least one zero-decimal test case per flow
- Document the zero-decimal list in the Money module docs

**Warning signs:**
- `amount * 100` or `amount / 100` anywhere in the codebase
- Hard-coded `cents` in identifier or parameter names
- Test fixtures only in USD
- No `currency` column on `Charge`/`Invoice` line item schemas

**Phase to address:** Money/currency foundation phase (must land before Charge/Invoice/Subscription).

---

### Pitfall 4: Proration default behavior surprising users

**What goes wrong:**
User upgrades plan mid-cycle. Stripe's default `proration_behavior` on subscription updates has changed between API versions and is different for different endpoints. User expected to be charged prorated difference; instead gets a full second invoice, or a $0 upgrade, or an invoice they can't explain. Disputes and chargebacks follow.

**Why it happens:**
Stripe has three proration modes: `create_prorations` (default on most endpoints), `always_invoice`, `none`. Behavior depends on whether you're using Subscriptions or Subscription Schedules, whether there's a pending invoice, and whether billing_cycle_anchor is being reset. Libraries that silently inherit the default leak this complexity.

**How to avoke:**
- `Accrue.Billing.swap_plan/3` MUST take an explicit `:proration` option — never inherit Stripe's default silently
- Default in Accrue: `:create_prorations` with documented behavior and a warning in ExDoc linking to Stripe proration docs
- Expose `Accrue.Billing.preview_upcoming_invoice/2` so apps can show the user the proration BEFORE committing
- Integration test matrix: upgrade, downgrade, same-tier-different-interval, each with `:create_prorations`, `:always_invoice`, `:none`

**Warning signs:**
- Any Accrue function that calls Stripe subscription update without an explicit proration parameter
- No `preview_upcoming_invoice` helper
- Plan-change tests that only assert on resulting plan_id, not on invoice line items

**Phase to address:** Subscription lifecycle phase.

---

### Pitfall 5: Idempotency key replay with different params returning 400 errors

**What goes wrong:**
App retries a charge with the same idempotency key but slightly different parameters (e.g., different `description`, or a recalculated amount after a race). Stripe returns `400 Idempotency-Key-In-Use` or `"Keys for idempotent requests can only be used with the same parameters they were first used with"`. User sees a generic error; developer panics and retries with a new key, causing double-charge.

**Why it happens:**
Stripe holds idempotency keys for 24 hours and pins them to the full request body. Teams assume idempotency means "replay-safe for any retry." It doesn't.

**How to avoid:**
- Generate idempotency keys as hashes of `{operation, subject_id, canonical_params}` — deterministic but parameter-aware
- Store generated keys in `accrue_events` so we can trace "why did this op use key X"
- Treat `IdempotencyError` from `lattice_stripe` as a distinct error class in `Accrue.Error` hierarchy with guidance: "this means your retry changed parameters; either use the original params or generate a new key"
- Oban retries must use the SAME idempotency key on each attempt (attach it to job args, not regenerate)

**Warning signs:**
- `UUID.uuid4()` or `:crypto.strong_rand_bytes` used as idempotency key generator
- Idempotency key generation inside a function that closes over mutable state (clock, `now()`)
- No `IdempotencyError` class in the error hierarchy

**Phase to address:** Processor wrapper + error hierarchy phase (early, foundational).

---

### Pitfall 6: Stripe fees not refunded on refunds — silent margin erosion

**What goes wrong:**
Customer pays $100, Stripe takes $3.20 fee, merchant nets $96.80. Customer requests refund. Stripe returns $100 to the customer. Stripe does NOT return the $3.20 fee. Merchant is out $3.20 on every refund. Over thousands of refunds this becomes a real line on the P&L that nobody modeled.

**Why it happens:**
The Stripe dashboard UI shows "refunded" cleanly and hides the fee asymmetry. Refund webhooks include fee data only if you expand the `balance_transaction`. Cashier/Pay never surfaced this.

**How to avoid:**
- `Accrue.Billing.Refund` schema MUST include `stripe_fee_refunded_amount` (usually 0) and `merchant_loss_amount` fields
- Expand `balance_transaction` on refund webhook handling and persist fee detail
- Admin UI refund row shows gross, fee, net returned, merchant loss — not just "refunded"
- Document in "Refunds" guide: "Stripe does not return processing fees on refunds; Accrue surfaces this so you can account for it."

**Warning signs:**
- `Refund` schema has only `amount` field
- Admin UI shows "refunded: $100" with no fee breakdown
- No merchant-loss aggregation query

**Phase to address:** Refund domain phase + Admin UI refund inspector phase.

---

### Pitfall 7: Webhook event ordering and duplicate delivery assumed linear

**What goes wrong:**
Stripe sends `customer.subscription.created`, then `customer.subscription.updated`, then `customer.subscription.deleted`. Due to network retries, the app receives them as created → deleted → updated. Handler processes them in arrival order. Subscription ends up `updated` state (alive) when it should be `deleted` (gone). OR: the same `updated` event arrives 3 times in 2 seconds (Stripe retry before ACK settles) and is processed 3 times.

**Why it happens:**
Webhook delivery is at-least-once and unordered. Stripe's own docs say "do not depend on order of delivery." DB unique constraint on `processor_event_id` catches exact duplicates, but NOT order inversions. Developers assume TCP = ordered = handled in order.

**How to avoid:**
- Every handler must re-fetch the CURRENT object from Stripe (or from the `data` jsonb) rather than trusting the event snapshot as authoritative state. Events are notifications, not state.
- Store `created_at` (Stripe's) on `accrue_webhook_events` and resolve state from the newest event per subject, not the most recently arrived
- Pattern in docs: "match on event type, then reconcile from current remote state, then persist"
- Handler idempotency is layered: (a) DB unique on `processor_event_id`, (b) handler must be safe to re-run, (c) Oban worker uses `unique: [keys: [:event_id]]`

**Warning signs:**
- Handler code that reads event payload and writes that payload directly to the DB as the new state
- No re-fetch step
- Test suite that only tests events in-order

**Phase to address:** Webhook dispatch + handler contract phase.

---

### Pitfall 8: Trace_id / actor_id gaps in event ledger

**What goes wrong:**
An audit investigation asks "who refunded $10,000 to customer X on March 3?" The `accrue_events` row shows `{event: "refund.created", amount: 10000, actor_id: nil, trace_id: nil}`. Nobody knows if it was an admin, a webhook retry, a scheduled job, or the user themselves via portal. Audit log is useless at the moment it's needed.

**Why it happens:**
Events are written from many contexts: LiveView admin actions, webhook handlers (no "user"), Oban background jobs, Phoenix controllers, programmatic `Accrue.Billing` context calls from host app code. Each context has a different "who is doing this" model. System-initiated events (webhook, dunning) have no `current_user` in scope. OpenTelemetry context propagation through Oban jobs is easy to drop at the enqueue/perform boundary.

**How to avoid:**
- `actor_type` field on `accrue_events` with enum: `user | system | webhook | oban | admin`
- `actor_id` nullable, but `actor_type` NOT NULL — so you always know WHICH KIND of actor even if no user
- `actor_meta` jsonb with context-specific detail (webhook_event_id, oban_job_id, admin_session_id)
- OTel `trace_id` and `span_id` captured from `OpenTelemetry.Tracer.current_span_ctx()` at event write time
- Oban job perform wraps in explicit span, attaches trace_id to job args so cross-process correlation survives
- Credo/Boundary rule or custom Credo check: `Accrue.Events.record/1` calls must pass an `%ActorContext{}` struct, never nil

**Warning signs:**
- `actor_id` column without `actor_type`
- Any `Events.record` call site that passes `actor_id: nil` without `actor_type`
- No OTel propagation tests
- `trace_id` column exists but >10% of rows have it null

**Phase to address:** Event ledger foundation phase.

---

### Pitfall 9: Events written but state mutation rolled back (or vice versa)

**What goes wrong:**
Handler does `Accrue.Events.record(...)` followed by `Repo.update(subscription_changeset)`. Update fails a validation. Event is already persisted. Audit log now claims a state change that never happened. OR the inverse: state mutated, then `Events.record` raises, and there's no audit trail of a real change.

**Why it happens:**
`Ecto.Multi` is the idiomatic answer but people don't reach for it on "simple" updates. Append-only event writes feel naturally independent so developers separate them.

**How to avoid:**
- `Accrue.Billing` context functions use `Repo.transact` (or `Ecto.Multi`) with event recording as the LAST step in the same transaction — if anything fails, everything rolls back, including the event
- Expose `Accrue.Events.record_in_multi/2` helper that adds an insert_all op to a Multi; no standalone `record/1` in business-logic call sites
- Integration test: force a validation error after an event is staged, assert the event is NOT in the DB after the transaction fails
- Document pattern in Event Ledger guide with a "do / don't" code example

**Warning signs:**
- `Events.record(...)` outside a Multi/transact block in domain code
- Any domain function that writes state and events in separate `Repo` calls
- Event count != state mutation count in audit diff queries

**Phase to address:** Event ledger foundation phase + Domain modeling phase (enforce in code review standards).

---

### Pitfall 10: Audit trail silently mutable (DELETE / UPDATE not revoked)

**What goes wrong:**
The migration creates `accrue_events` with `CREATE TABLE ... (...)`. Months later, someone runs `Repo.delete_all(from e in AccrueEvent, where: e.inserted_at < ^cutoff)` to "clean up old events." The audit trail is now a lie. Or an admin tool has an "edit event" button because the dev forgot the table is supposed to be append-only.

**Why it happens:**
Postgres grants full CRUD by default to the role that runs migrations. "Append-only" is a developer discipline, not enforced. Ecto has no concept of read/append-only schemas.

**How to avoid:**
- Migration explicitly `REVOKE UPDATE, DELETE, TRUNCATE ON accrue_events FROM PUBLIC`
- Add a Postgres trigger that raises on UPDATE or DELETE: `CREATE TRIGGER prevent_event_mutation ... FOR EACH ROW EXECUTE FUNCTION raise_exception('accrue_events is append-only')`
- No `Ecto.Schema` for AccrueEvent exposes `update_changeset` — only `insert_changeset`
- `Accrue.Events` module has `record/1` and query functions, NO `update/2` or `delete/2`
- Integration test: attempt `Repo.update` and `Repo.delete` on an event and assert both raise
- Document the "append-only" contract in the Event Ledger guide

**Warning signs:**
- Migration that creates `accrue_events` without corresponding REVOKE
- Any `update_changeset` function on the event schema
- `Repo.delete_all` on events table anywhere in the codebase
- Admin UI with edit/delete affordance on event rows

**Phase to address:** Event ledger foundation phase.

---

### Pitfall 11: Webhook handler timeouts causing Stripe retries = duplicate processing

**What goes wrong:**
Handler takes 40 seconds because it's doing synchronous Stripe API calls inside the webhook controller. Stripe's webhook timeout is 30 seconds; Stripe marks it as failed and retries after backoff. Second attempt arrives; DB idempotency catches the exact replay, BUT the first attempt is still running in a zombie process and completes the state mutation a moment later. Race condition produces inconsistent state.

**Why it happens:**
Developers put business logic directly in the webhook controller. The "pipeline" Accrue provides (verify → persist → enqueue → 200) works only if the enqueue is fast and the handler runs async. People shortcut this "for simple cases."

**How to avoid:**
- `Accrue.Webhooks.Plug` pipeline returns `200` after verify → DB insert → Oban enqueue. Handler never runs in the HTTP request path, period.
- User's handler module has `@behaviour Accrue.WebhookHandler` with `handle_event/1` called ONLY by the Oban worker, never by a Plug
- Compile-time check (Credo or boundary): `Accrue.WebhookHandler` callbacks cannot be called from any module under `MyAppWeb.*`
- Oban worker uses `unique: [keys: [:event_id], period: :infinity]` so even if somehow two jobs are enqueued for one event, only one runs
- p99 latency SLO: webhook request <100ms (per CONSTRAINTS in PROJECT.md)
- Load test: fire 1000 duplicate webhook events, assert exactly one handler run per unique event_id

**Warning signs:**
- Any function call from `Accrue.Webhooks.Plug` that isn't `verify`, `persist`, `enqueue`, or `send_resp`
- User docs showing `handle_event` called from a controller
- Webhook latency p99 > 100ms

**Phase to address:** Webhook pipeline phase.

---

### Pitfall 12: Signing secret rotation breaks all webhooks

**What goes wrong:**
Security rotates the Stripe webhook signing secret. Dev updates `config :accrue, :webhook_secret, "whsec_new..."`. For the 2-minute window between Stripe issuing the new secret and the deploy completing, webhooks signed with the old secret are rejected. Dead-letter fills up. OR: Stripe allows multi-endpoint with separate secrets, and the app only supports one, so rollout requires downtime.

**Why it happens:**
Stripe dashboards let you have multiple active signing secrets during rotation. Libraries often support only a single secret.

**How to avoid:**
- `config :accrue, :webhook_secrets, ["whsec_current", "whsec_previous"]` — list, not single string
- Verification tries each secret; accepts if ANY matches
- Telemetry event `[:accrue, :webhook, :verified]` includes which secret index matched; ops can see "secret 1 is unused" and retire it safely
- Document rotation procedure in ops guide

**Warning signs:**
- `:webhook_secret` as a single string in config
- No test covering verification with multiple secrets
- Rotation procedure not documented

**Phase to address:** Webhook pipeline phase.

---

### Pitfall 13: Stripe Connect multi-account webhooks misrouted

**What goes wrong:**
Platform receives webhooks for connected accounts. The event payload has `account: "acct_1234"` but the handler treats it as if it's for the platform account. Subscription on connected account A gets applied to customer on platform account B. This is the worst kind of billing bug: silent cross-account data corruption.

**Why it happens:**
Stripe Connect webhooks to platform include an `account` top-level field. Single-account code paths ignore it. Dev tests with a single account in Stripe test mode.

**How to avoid:**
- `Accrue.Billing.Customer` always has a `stripe_account_id` (nullable for non-Connect apps)
- Webhook persister populates `stripe_account_id` from the top-level `account` field
- All lookups scoped by `{stripe_account_id, stripe_customer_id}` — never `stripe_customer_id` alone
- Connect integration test: simulate two accounts with colliding customer IDs, assert they're kept separate
- Document Connect setup in a dedicated guide

**Warning signs:**
- `from c in Customer, where: c.stripe_customer_id == ^id` anywhere (missing account scope)
- Unique index is only on `stripe_customer_id` instead of `(stripe_account_id, stripe_customer_id)`
- No Connect test fixtures in Fake Processor

**Phase to address:** Connect support phase (later) but the schema foundation (account_id column + composite index) must land in the initial Customer schema phase.

---

### Pitfall 14: Oban retries double-writing events without idempotency_key on the event itself

**What goes wrong:**
Oban retries a webhook handler after transient DB error. The handler inserts an event, then fails at state mutation. Multi rolls back correctly. Second attempt runs, but the handler generates a fresh event struct (new UUID) and inserts AGAIN — two events for one logical action. DB idempotency on `webhook_events` protected the webhook record, but NOT the business events the handler writes during processing.

**Why it happens:**
Event idempotency is easy to reason about at the webhook boundary but gets lost deeper in the handler when business events are synthesized.

**How to avoid:**
- Each business event has an `idempotency_key` column with a unique index
- Key is derived deterministically from `{subject_type, subject_id, event_type, source_event_id}` — stable across retries
- `Accrue.Events.record_in_multi` uses `on_conflict: :nothing` with `conflict_target: :idempotency_key` — retries are no-ops
- Handler contract docs: "your handler may run multiple times. Any event you generate must have a stable idempotency_key."

**Warning signs:**
- Event table has no `idempotency_key` unique index
- Events use `Ecto.UUID.generate()` as primary identifier for dedupe
- Retry test inserts 2 events for 1 logical action

**Phase to address:** Event ledger foundation phase.

---

## Elixir OSS Library Pitfalls

### Pitfall 15: Leaking dependency modules through public API

**What goes wrong:**
User's code ends up with `alias Stripe.Subscription` or `Swoosh.Email` in their Billing context because Accrue's functions return those types. Months later, Accrue upgrades `lattice_stripe` to a version that renamed a module; user's code breaks even though they never upgraded Accrue's major version. Accrue is stuck on old deps or breaks SemVer.

**Why it happens:**
Easiest implementation returns the raw type. Wrapping everything is tedious. Until it isn't.

**How to avoid:**
- Every public `Accrue.Billing.*` function returns `Accrue.Billing.*` structs, never `Stripe.*` or `Swoosh.*`
- `Accrue.Mailer.deliver/1` takes `Accrue.Email.t()` (an Accrue struct), converts to Swoosh internally
- Dialyzer specs on all public functions reference only Accrue types
- Module boundary check (Boundary or custom Credo rule): `Accrue.Billing.*` may not expose `Stripe.*` or `Swoosh.*` in function specs or return values
- ExDoc lint: search generated docs for `Stripe.` or `Swoosh.` mentions in public API pages — fail CI if present

**Warning signs:**
- `@spec ... :: Stripe.Subscription.t()` anywhere in `lib/accrue/billing/`
- Docstring examples use `alias Stripe.X`
- User guide has `iex> %Stripe.Customer{...}`

**Phase to address:** Public API design phase + every phase's code review.

---

### Pitfall 16: Compile-time config for things that need runtime flexibility

**What goes wrong:**
`config :accrue, :stripe_api_key, System.get_env("STRIPE_API_KEY")` in `config.exs`. The env var read happens at COMPILE time, not runtime. Release build in CI has no `STRIPE_API_KEY`, so the compiled release carries `nil`. Deploy succeeds, app starts, first webhook call returns `Stripe.AuthenticationError: "No API key provided"`.

**Why it happens:**
`config.exs` / `dev.exs` / `prod.exs` are compile-time. `runtime.exs` is runtime. The difference is subtle and `config.exs` is the default tutorial example in much of the Elixir world.

**How to avoid:**
- Accrue documentation ONLY shows `runtime.exs` examples for secrets
- `Accrue.Config` module reads from application env at runtime, not via module attribute
- `mix accrue.install` generates config into `runtime.exs` (not `config.exs`)
- NimbleOptions schema validates at application start, fails fast with a clear error: "STRIPE_API_KEY is nil; ensure it's set in runtime.exs, not config.exs"

**Warning signs:**
- Any `@api_key Application.compile_env(:accrue, :stripe_api_key)` in library code
- Install generator writes to `config.exs` for secrets
- No runtime validation at app boot

**Phase to address:** Configuration + installer phase.

---

### Pitfall 17: Macro abuse where a behaviour or plain function would do

**What goes wrong:**
`use Accrue.Billable` injects 40 functions, 3 module attributes, and changes how `@before_compile` works. User tries to subclass or wrap it; AST gymnastics ensue. Debugging requires reading macro expansion output. New contributors bounce off the codebase.

**Why it happens:**
Macros feel powerful. Rails-style DSLs are tempting. Every library author goes through a macro-heavy phase.

**How to avoid:**
- `use Accrue.Billable` macro injects the MINIMUM: one association, one helper function, done. Everything else is behaviour callbacks or functions the user calls explicitly.
- Behaviours (`@behaviour`) for integration points (`Accrue.Auth`, `Accrue.Mailer`, `Accrue.PDF`, `Accrue.Processor`)
- Document in CONTRIBUTING.md: "Prefer a function. If not, a behaviour. Macros require maintainer approval in PR review."
- Credo check for module LOC in `lib/accrue/billable.ex` — if the `__using__` body grows past ~30 lines, that's a signal
- Dialyzer must pass on user code that uses `use Accrue.Billable` — any generated function must have correct specs

**Warning signs:**
- `use Accrue.Billable` injects more than a handful of things
- `quote do ... end` blocks longer than 20 lines
- `@before_compile` or `@after_compile` hooks
- Docs that say "some magic happens when you use this"

**Phase to address:** Ongoing — enforced in code review + CONTRIBUTING.md authoring phase.

---

### Pitfall 18: `Application.get_env` scattered as implicit global state

**What goes wrong:**
`Application.get_env(:accrue, :processor)` sprinkled across 30 files. Tests need to override it in 30 places. `Application.put_env` during tests leaks state between tests when `async: true`. A user wants two separate Accrue configurations (e.g., platform + Connect sub-account) and finds out it's impossible because config is global.

**Why it happens:**
Easiest thing to write. Common in older Elixir libs. Nobody stops you.

**How to avoid:**
- `Accrue.Config` is a single module that returns a struct built once at app boot (validated via NimbleOptions)
- Business functions accept an explicit `opts \\ []` and read overrides from there before falling back to `Accrue.Config.default/0`
- Test helpers pass `opts: [processor: Accrue.Processor.Fake]` to function calls, never mutate app env
- `Application.get_env` allowed ONLY inside `Accrue.Config` module; enforced via Boundary or Credo check

**Warning signs:**
- `Application.get_env(:accrue, ...)` in any file other than `lib/accrue/config.ex`
- Test helpers that call `Application.put_env`
- Functions with no `opts` parameter that still read global config

**Phase to address:** Configuration phase + processor abstraction phase.

---

### Pitfall 19: Missing test adapters — users forced to mock Accrue internals

**What goes wrong:**
User wants to test their `handle_event/1` handler. Accrue provides no `Accrue.Test` helper to trigger an event synthetically. User writes `Mox`-style mocks for `Accrue.Billing.create_subscription/2` by hand, or worse, puts `Mock` around the entire `Accrue.Billing` module. Their tests become coupled to Accrue's internals.

**Why it happens:**
Test adapters are an afterthought. Fake Processor was planned (good), but test adapters for Mailer, PDF, Auth, Webhooks are often not.

**How to avoid:**
- `Accrue.Test` module ships with:
  - `Accrue.Test.trigger_webhook(event_type, payload_overrides)` — synthesizes + delivers a webhook end-to-end
  - `Accrue.Test.advance_clock(duration)` — coordinated between Fake Processor and Oban test clock
  - `assert_email_sent/1` macro (wraps Swoosh.TestAssertions)
  - `assert_pdf_rendered/1` macro (uses `Accrue.PDF.Test` adapter)
  - `Accrue.Test.as_actor(actor, fun)` — sets actor context for event recording
- `Accrue.Auth.Test`, `Accrue.Mailer.Test`, `Accrue.PDF.Test` shipped alongside real adapters
- Integration tests in the Accrue repo itself USE these helpers so they're dogfooded

**Warning signs:**
- No `Accrue.Test` module
- Accrue's own test suite has hand-rolled webhook fixtures inline in test files
- User issues asking "how do I test X?"

**Phase to address:** Testing-first phase (parallel with Fake Processor, not after domain work).

---

### Pitfall 20: Optional dependencies not marked as optional

**What goes wrong:**
Core `accrue` pulls in `phoenix_live_view` as a hard dep because `Accrue.Billing.PortalController` renders a LiveView. Headless API-only user installs `accrue` and gets LiveView's 20+ transitive deps they don't want. OR: `accrue` depends on `sigra` directly, preventing users of pow/phx.gen.auth from installing.

**Why it happens:**
`{:phoenix_live_view, "~> 1.0"}` without `optional: true` is one character away from `{:phoenix_live_view, "~> 1.0", optional: true}`.

**How to avoid:**
- Core `accrue` has ZERO LiveView dependency (Admin UI lives in `accrue_admin`)
- `sigra` listed as `optional: true` in accrue mix.exs
- `Code.ensure_loaded?(Sigra)` checks at runtime for the Sigra adapter; adapter module itself is conditionally compiled via `if Code.ensure_loaded?(Sigra)`
- CI matrix includes "minimal deps" job: install `accrue` with NO optional deps, compile, run core tests
- `mix hex.audit` and `mix deps.tree` reviewed at publish time

**Warning signs:**
- `accrue/mix.exs` deps list includes phoenix_live_view, phoenix_html, or sigra without `optional: true`
- `Accrue.Integrations.Sigra` compiles even when Sigra is not installed
- Minimal-deps CI job missing

**Phase to address:** Package structure + CI setup phase.

---

### Pitfall 21: Migration timestamp collisions with host app

**What goes wrong:**
`mix accrue.install` copies `20260411120000_create_accrue_billing.exs` into `priv/repo/migrations/`. Host app already has `20260411120000_add_users_email.exs`. Ecto migration path is silently ambiguous; one migration "wins" at runtime, the other is skipped. Or `mix ecto.migrate` errors on duplicate version.

**Why it happens:**
Libraries ship pre-dated migration files. Any collision with host app's existing migration version is a bug waiting to happen.

**How to avoid:**
- `mix accrue.install` GENERATES migration files using `DateTime.utc_now()` at the moment of install, not ships pre-dated files
- Generator inserts migrations one-per-call-to-Ecto-migrations-generator-API so Ecto's own timestamp-bumping kicks in
- Installer is idempotent: re-running detects "already installed" by checking for the presence of a sentinel migration, refuses to duplicate (or adds a `--force` flag)
- Installer writes migrations in sub-second-separated batch (e.g., N migrations get N sequential timestamps)
- Integration test: install into a scratch Phoenix app, run `mix ecto.migrate`, re-run `mix accrue.install`, assert no duplicate migrations

**Warning signs:**
- Pre-dated `.exs` files in `priv/templates/migrations/`
- Installer that's not idempotent
- No "re-install" test case

**Phase to address:** Installer phase.

---

### Pitfall 22: Monorepo Release Please tag collisions

**What goes wrong:**
`accrue v1.2.0` and `accrue_admin v1.2.0` both need to publish. Release Please is configured to bump in lockstep; a change to only `accrue_admin` bumps both. OR: two git tags `v1.2.0` collide because Release Please isn't configured with per-package tag prefixes. Hex publish for the second package fails or publishes with stale docs.

**Why it happens:**
Release Please's default config is single-package. Monorepo mode requires explicit `release-please-config.json` with per-component settings. `accrue-v1.0.0` vs `accrue_admin-v1.0.0` tag prefixes are a must.

**How to avoid:**
- Release Please config uses `packages` with per-path versioning and `"component": "accrue"` / `"component": "accrue_admin"`
- Tag prefix set to `accrue-v` and `accrue_admin-v` respectively
- Each package has its own `CHANGELOG.md`, its own version in `mix.exs`
- GHA publish job matrix over packages; only publishes packages whose version changed in the release PR
- Dry-run in CI before merging release PR: `mix hex.publish --dry-run` for each changed package

**Warning signs:**
- Single `VERSION` file at monorepo root
- Single `CHANGELOG.md`
- Tag format `v1.0.0` without package prefix

**Phase to address:** CI/CD + release tooling phase.

---

### Pitfall 23: Hex publish without GHA secret = manual failure

**What goes wrong:**
Merging release PR triggers publish workflow; workflow fails because `HEX_API_KEY` secret isn't set. Maintainer notices three days later when users can't install the new version.

**Why it happens:**
Secrets are set in GitHub repo settings, invisible in the YAML. Easy to forget on initial setup.

**How to avoid:**
- Publish workflow has a `pre-flight` job that checks `secrets.HEX_API_KEY` is non-empty; fails fast with a clear error
- Document GHA secrets required in `CONTRIBUTING.md` maintainer section
- First publish is manual to verify the flow
- Post-publish verification step: `curl https://hex.pm/api/packages/accrue` and assert latest version matches what we just published

**Warning signs:**
- No pre-flight check
- No post-publish verification
- Release workflow has only been run once, at v1.0.0

**Phase to address:** CI/CD + release tooling phase.

---

### Pitfall 24: PLT cache key wrong — Dialyzer reruns from scratch every CI

**What goes wrong:**
CI takes 12 minutes. 9 of those are Dialyzer rebuilding PLTs. Team disables Dialyzer in PR workflow. Type errors ship. Weeks later, a subtle bug traces back to a Dialyzer warning that was never caught.

**Why it happens:**
PLT cache key needs to include Elixir version, OTP version, mix.lock hash, and Dialyzer config hash. Default `actions/cache@v4` examples use only one or two of these.

**How to avoid:**
- Cache key: `plt-${{ runner.os }}-otp${{ matrix.otp }}-elixir${{ matrix.elixir }}-${{ hashFiles('mix.lock') }}`
- Cache `~/.mix` and `priv/plts/` directories
- First CI run takes 10 minutes; subsequent runs <30 seconds for PLT
- `mix dialyzer --plt` step only runs if cache miss (check with `if: steps.plt_cache.outputs.cache-hit != 'true'`)
- Dialyzer is in the default CI matrix, not opt-in

**Warning signs:**
- PR CI runs > 5 minutes on the Dialyzer step
- PLT cache keys using only `hashFiles('mix.lock')`
- Dialyzer disabled "temporarily" in CI

**Phase to address:** CI/CD phase.

---

## Admin UI Pitfalls

### Pitfall 25: PII visible to admins without access control

**What goes wrong:**
Admin dashboard shows customer email, last-4 card, billing address for every customer. A customer support agent with dashboard access can browse any customer's financial history. Compliance (GDPR, PCI DSS scope expansion) becomes a surprise finding in an audit.

**Why it happens:**
The easy implementation is "admin sees everything." Role-based data scoping is more work.

**How to avoid:**
- `Accrue.Auth` behaviour has `can?/3` callback — every admin LiveView mount and action checks `can?(user, :view, resource)`
- Default `Accrue.Auth.Default` is deny-by-default — user MUST implement or opt in
- Schema has `redact: true` on sensitive fields (email, address); admin LiveView explicitly decides which to un-redact per role
- Audit log every admin data access via `Accrue.Events` (actor_type: admin, action: :view, subject_id: ...)
- Document "admin UI is not a license to bypass authz"

**Warning signs:**
- Admin LiveView with no `handle_params` auth check beyond "logged in"
- Email/address fields displayed without `redact: true` consideration
- No "who viewed customer X" audit query

**Phase to address:** Admin UI auth phase.

---

### Pitfall 26: Admin actions unaudited (who refunded $10k?)

**What goes wrong:**
Admin clicks "refund" on a $10,000 invoice. Action succeeds. `accrue_events` records `refund.created` with `actor_type: webhook` because the refund was processed via a Stripe webhook after the admin action initiated it, NOT as an admin-initiated event. Audit trail doesn't show which human clicked the button.

**Why it happens:**
The "who clicked" (admin) and the "what was the effect" (webhook later) are two different events, and the causal link is easily lost.

**How to avoid:**
- Every admin mutation LiveView action records a `admin.action.*` event BEFORE dispatching to `Accrue.Billing` — actor_type: admin, admin_session_id in actor_meta
- Downstream event (e.g., from webhook) stores `caused_by_event_id` pointing to the admin event
- Admin UI "event timeline" view follows the causal chain: admin click → API call → webhook → state mutation
- Integration test: click refund as admin, assert both admin event and webhook event exist and are causally linked

**Warning signs:**
- Admin LiveView handle_event calls `Accrue.Billing` directly without recording an admin event first
- `accrue_events` has no `caused_by_event_id` column
- Event timeline has "gaps" between user action and system effect

**Phase to address:** Admin UI + Event ledger phase (crosscut).

---

### Pitfall 27: No 2FA/reconfirmation for destructive admin actions

**What goes wrong:**
Admin is session-hijacked or leaves laptop open. Attacker clicks "refund all" on a customer. 5 minutes of damage before anyone notices.

**Why it happens:**
2FA is typically at login only, not at action time.

**How to avoid:**
- `Accrue.Auth` behaviour has `require_step_up/2` callback — admin UI calls it before high-risk actions (refund > threshold, mass delete, webhook replay to production)
- Sigra adapter implements step-up via its 2FA or password re-entry
- Default adapter requires password re-entry for threshold-configurable actions
- Configurable threshold: `config :accrue_admin, step_up_threshold_cents: 1_000_00`
- Admin actions above threshold emit telemetry `[:accrue_admin, :step_up, :required|:completed|:denied]`

**Warning signs:**
- High-dollar admin actions require only a normal session
- No `require_step_up` in `Accrue.Auth` contract
- No "dangerous action" taxonomy in admin UI

**Phase to address:** Admin UI auth phase.

---

### Pitfall 28: Live webhook replay without dry-run = production disaster

**What goes wrong:**
Admin debugging a failed webhook clicks "replay." The event is `invoice.payment_succeeded`, so the handler runs and emails the customer "thanks for your payment!" again — for the 5th time (because this event has been replayed 5 times during debugging). Customer is now confused and angry.

**Why it happens:**
Replay looks like a harmless debug tool. Side effects of handlers are invisible from the admin UI.

**How to avoid:**
- Admin replay UI defaults to DRY-RUN mode: handler runs in a transaction that's rolled back, with a side-effect log shown (emails that WOULD send, state changes that WOULD happen)
- Explicit "commit replay" requires step-up auth (pitfall 27)
- Replay inserts a new `accrue_webhook_events` row with `replayed_from_id` linkage — never overwrites the original
- Handler has a `@callback dry_run?() :: boolean` and checks it before side effects; Fake Mailer and Fake Processor are used during dry-run
- Bulk replay (dead-letter requeue) requires explicit confirmation count-match: "Type REPLAY 47 to requeue 47 events"

**Warning signs:**
- Replay button with no mode toggle
- No `dry_run` capability in handler contract
- Bulk replay doesn't require confirmation

**Phase to address:** Admin UI webhook inspector phase.

---

### Pitfall 29: Branding customization breaks dark mode contrast

**What goes wrong:**
User sets `accent_color: "#FFEB3B"` (bright yellow). Light mode looks fine. Dark mode uses the same accent on a dark background, contrast ratio is 1.8:1 (WCAG fails), text is unreadable.

**Why it happens:**
Single accent color token drives both modes. Dark mode needs either a separate token or a derived value.

**How to avoid:**
- Branding config takes a single accent, then DERIVES the dark-mode accent via color math (lightness shift) OR requires an explicit `accent_dark` override
- Contrast check at config validation: NimbleOptions validator runs WCAG contrast calculation on `(accent, background)` for both modes; warns if <4.5:1
- Admin UI preview page shows both modes side-by-side at install time
- Default brand palette (Ink/Slate/Fog/Paper + Moss/Cobalt/Amber from PROJECT.md) is WCAG-AA tested for both modes — reference implementation

**Warning signs:**
- Single `accent` config with no dark-mode handling
- No contrast validator
- No dark-mode preview in admin UI

**Phase to address:** Admin UI theming phase.

---

### Pitfall 30: LiveView auth gated only at mount, not at handle_event

**What goes wrong:**
Admin mounts the page. Their role is revoked server-side (admin demoted). LiveView is still connected. They click "refund $5000." `handle_event` runs without re-checking auth. Action succeeds despite revoked privileges.

**Why it happens:**
`on_mount` hooks are common; `handle_event`-level authz is less idiomatic. LiveView's long-lived connection model means auth state can go stale.

**How to avoid:**
- Every `handle_event` in admin LiveViews checks auth via a helper: `with :ok <- Auth.authorize(socket, event, params), do: ...`
- Role changes emit a PubSub message that admin LiveViews subscribe to; on message, `push_navigate` to a re-mount
- Session token carries a `revocation_generation`; if socket's stored generation < current, force disconnect
- Integration test: mount as admin, demote, attempt handle_event, assert 403/redirect

**Warning signs:**
- `handle_event` implementations that don't call an authorize helper
- No PubSub-based role invalidation
- Long-lived LiveView connections trusted to remain authorized

**Phase to address:** Admin UI auth phase.

---

## Email Pitfalls

### Pitfall 31: HTML-only emails (no text part) = spam score hit

**What goes wrong:**
Receipts are HEEx-rendered HTML. No plain-text alternative. Gmail / Outlook flag them with elevated spam probability. Deliverability drops. Users report "I never got my receipt."

**Why it happens:**
Rendering HTML is the easy default. Plain-text rendering is a separate branch. MJML output is HTML-only.

**How to avoid:**
- Every `Accrue.Email.*` template has both `.html.heex` AND `.text.eex` (or a shared HEEx component that renders to both via a context flag)
- `Accrue.Mailer.deliver/1` REQUIRES both parts; raises on single-part emails in non-test env
- Test helper `assert_email_sent/1` asserts both parts present
- Swoosh's `premail_ex` integration for HTML-to-text fallback is acceptable as a last resort but templates are preferred

**Warning signs:**
- Email template file has only `.html.heex` counterpart
- `Accrue.Mailer.deliver` accepts a single `:html_body`
- Swoosh email struct has `text_body: nil` in production

**Phase to address:** Email foundation phase.

---

### Pitfall 32: Email rendering broken in Outlook (MSO conditional comments)

**What goes wrong:**
Template uses CSS grid or flexbox. Gmail and Apple Mail render it. Outlook (Windows desktop, which uses Word's rendering engine) renders it as a stacked mess with misaligned columns.

**Why it happens:**
Outlook Word rendering is a 1998-era engine that doesn't support most modern CSS. It requires `<!--[if mso]>...<![endif]-->` conditional blocks and `<table>` layouts.

**How to avoid:**
- Use MJML (via `swoosh_mjml`) for all HTML email layout — MJML compiles to Outlook-safe table layouts
- Test suite includes Litmus or Email on Acid snapshot tests (or at minimum, manual QA checklist referencing major clients: Gmail web, Gmail iOS, Outlook 365, Outlook desktop Windows, Apple Mail macOS, Apple Mail iOS)
- Default templates ship tested across the checklist
- Document in theming guide: "If you override a template, test in Outlook first."

**Warning signs:**
- HEEx templates use `display: flex` or `display: grid`
- No MJML in email template files
- No email client QA checklist

**Phase to address:** Email foundation phase.

---

### Pitfall 33: Bounce / complaint webhooks from email provider ignored

**What goes wrong:**
Customer's email bounces. Accrue keeps sending receipts and dunning emails. Email provider reputation drops. Eventually provider suspends sending. OR: customer marks receipt as spam. Same result.

**Why it happens:**
Swoosh adapters receive bounce/complaint webhooks but the library doesn't process them by default. It's expected you wire them up.

**How to avoid:**
- `Accrue.Mailer.Webhooks` plug handles bounce/complaint events from configured Swoosh adapter (SES, Postmark, SendGrid all differ)
- Customer `email_deliverability_status` field: `:ok | :soft_bounce | :hard_bounce | :complaint`
- On `hard_bounce` or `complaint`, automatically suppress further non-critical emails to that address; critical emails (payment_failed) still go but with a warning
- Admin UI shows deliverability status per customer
- Doc: "You must wire the Swoosh bounce webhook to Accrue.Mailer.Webhooks — here's how for each provider."

**Warning signs:**
- No bounce webhook handling
- No `email_deliverability_status` column
- All customers get all emails regardless of history

**Phase to address:** Email foundation phase (basic handler) + observability phase (full metrics).

---

## PDF Pitfalls

### Pitfall 34: Chrome not installed in production image

**What goes wrong:**
Dockerfile builds an Elixir release. ChromicPDF needs Chrome at runtime. Production image doesn't have Chrome. First invoice generation crashes with `** (ChromicPDF.ChromeNotFound)`. Customer gets no PDF, webhook retries until dead-letter.

**Why it happens:**
Developer's local machine has Chrome. Slim production images don't. The error doesn't surface until the first real PDF request.

**How to avoid:**
- `Accrue.PDF.health_check/0` runs at app boot, verifies Chrome is callable; fails loudly on startup if missing (not on first use)
- Document Dockerfile additions for each common base image (Debian slim, Alpine) in the PDF guide
- `mix accrue.install` emits a warning + docs link if it detects the host app uses a common base image
- CI smoke test: build a release in a scratch container, render one PDF
- Fallback path: `Accrue.PDF` adapter swap to a sidecar service (Gotenberg) via config for Chrome-hostile environments — documented

**Warning signs:**
- No health check on PDF adapter at boot
- PDF errors only surface on first use, not boot
- No Dockerfile documentation

**Phase to address:** PDF foundation phase.

---

### Pitfall 35: Timezone + locale rendering surprises

**What goes wrong:**
Invoice PDF says "Due date: Jan 1, 2026" but customer is in Tokyo and their "now" is already Jan 2. Or: amount formatted as `$1,000.00` for a German customer expecting `1.000,00 €`. Customer confused or angry.

**Why it happens:**
Templates default to UTC and en-US locale. Customer's timezone and locale live on the billable entity but templates don't thread them through.

**How to avoid:**
- `Accrue.Billing.Customer` has `timezone` and `locale` fields (nullable, fall back to config default)
- Template rendering context always includes `{tz: customer.timezone || config_default, locale: customer.locale || config_default}`
- Use `cldr` (ex_cldr) for number/currency/date formatting — NOT raw `Date.to_iso8601` or `Number.to_string`
- Test fixtures include at least one non-USD, non-UTC customer (JPY Tokyo, EUR Berlin)
- ExDoc guide: "Localization" with tz/locale configuration examples

**Warning signs:**
- Templates call `DateTime.to_iso8601` directly
- No `timezone`/`locale` on customer schema
- No ex_cldr dep
- Only en-US test fixtures

**Phase to address:** PDF + email foundation phase.

---

### Pitfall 36: Font fallback differs between dev and prod

**What goes wrong:**
Template uses `font-family: "Inter", sans-serif`. Local Chrome has Inter installed. Production Chrome in a slim container has only DejaVu. PDF in CI shows Inter. PDF in prod shows DejaVu. Support tickets "the PDF looks different from what I saw in staging."

**Why it happens:**
Web fonts aren't embedded in Chrome by default; slim base images strip bundled fonts.

**How to avoid:**
- Bundle Inter (or whichever brand font) as `.woff2` files in `priv/fonts/` of `accrue_admin` / `accrue`
- Template CSS uses `@font-face` with file:// URLs pointing at the bundled font
- ChromicPDF configured with `--disable-remote-fonts` so there's NO silent network fetch fallback
- CI test: render a reference invoice in the CI container (which matches prod base image) and diff against a golden PDF
- Snapshot testing via `assert_pdf_rendered/1` compares byte-for-byte after a layout-aware normalization

**Warning signs:**
- Template references a font via Google Fonts URL
- No `priv/fonts/` in the repo
- No golden PDF snapshot test

**Phase to address:** PDF foundation phase.

---

## Testing Pitfalls

### Pitfall 37: Fake Processor state leaks across async tests

**What goes wrong:**
Fake Processor backed by a global `Agent` or `:ets` table. Test A creates customer, test B (running async) sees it, assertion fails. Or: test A mutates a subscription, test B reads stale state. Team disables `async: true`, test suite slows 10x.

**Why it happens:**
Process-shared state is the natural Elixir pattern for "in-memory fake." Per-test isolation requires more thought.

**How to avoid:**
- Fake Processor state is per-test, keyed by `self()` PID or an explicit test context passed into every call
- OR: Fake Processor is a GenServer started per-test via `start_supervised!(Accrue.Processor.Fake)` in setup, state dies with the test
- `async: true` MUST work across Accrue's own test suite (proves isolation)
- Ecto Sandbox integration: Fake Processor uses `Ecto.Adapters.SQL.Sandbox.allow` when it spawns any background processes
- Document: "Your tests can (and should) use `async: true` with Accrue.Test"

**Warning signs:**
- Fake Processor module has `Agent.start_link(name: __MODULE__)` globally
- Accrue's own test suite has `async: false` with "flaky otherwise" comments
- User reports cross-test contamination

**Phase to address:** Fake Processor + testing helpers phase.

---

### Pitfall 38: Test clock drift between Fake Processor and Stripe test mode

**What goes wrong:**
User has some tests using Fake Processor (fast) and some using Stripe test mode (integration). Fake Processor's test clock is at `t+30 days`. Stripe test mode's test clock is still at `t+0`. Tests pass in Fake, fail in Stripe test mode. User debugs for an hour.

**Why it happens:**
Stripe has its own Test Clocks feature (separate API). Fake Processor has its own. They're not synchronized. User may not realize they're different clocks.

**How to avoid:**
- `Accrue.Test.advance_clock/1` advances BOTH the Fake Processor clock AND (if configured) the current Stripe test clock via Stripe's test-clock API
- Document the two modes clearly: "Fake tests run in <1ms; Stripe test-mode tests run in seconds but validate the real API"
- Integration test category explicitly tagged `:integration` and skipped in default `mix test`
- Accrue's own CI has a nightly job that runs integration tests against a test Stripe account

**Warning signs:**
- `Accrue.Test.advance_clock` only touches Fake
- No `:integration` tag
- No nightly integration CI

**Phase to address:** Testing helpers + CI phase.

---

### Pitfall 39: Tests accidentally hit live Stripe

**What goes wrong:**
Environment variable `STRIPE_API_KEY` in test environment is accidentally the live key (dev typos, CI secret leak). Tests run, create real customers, real charges, real emails to real addresses. Nightmare.

**Why it happens:**
Stripe's test keys and live keys are distinguishable by prefix (`sk_test_` vs `sk_live_`) but nothing else guards against confusion.

**How to avoid:**
- `Accrue.Processor.Stripe.init/1` REFUSES any `sk_live_*` key when `Mix.env() == :test` — raises at startup
- Default test config uses `Accrue.Processor.Fake` — the only way to even reach Stripe in tests is explicit opt-in for `:integration` tag
- GHA has a repo-level rule: `STRIPE_API_KEY` secret must start with `sk_test_` (enforced by a lint step)
- Document: "Live Stripe keys must never be in a test environment."

**Warning signs:**
- No prefix check on API key
- Test environment allowed to use real Stripe by default
- No CI lint on secret prefixes

**Phase to address:** Processor + CI setup phase.

---

### Pitfall 40: Flaky Oban test setup

**What goes wrong:**
Tests pass locally but fail in CI. Or: a test that enqueues a job passes sometimes and not others because `Oban.Testing` isn't set up correctly. `Oban.drain_queue/1` is called in some tests but not others. Jobs pile up in the test DB, leak to the next test.

**Why it happens:**
Oban has three test modes: `:inline`, `:manual`, `:testing`. Choosing the wrong one, or mixing them, causes flakes.

**How to avoid:**
- `config :accrue, Oban, testing: :manual` in test.exs (jobs are enqueued, not auto-run; tests explicitly `Oban.drain_queue` or `perform_job`)
- `Accrue.Test.run_enqueued_jobs/1` helper makes the drain explicit and scoped
- Test template shows: enqueue action → assert job enqueued → drain → assert side effects
- CI runs with `--trace --seed 0` and a second time with `--seed 12345` — any flake shows up immediately

**Warning signs:**
- No explicit Oban testing config
- Tests that work only with `:inline` mode
- CI that reruns flaky tests instead of fixing them

**Phase to address:** Testing helpers + CI phase.

---

## Migration & Upgrade Pitfalls

### Pitfall 41: No upcaster path for event schema evolution

**What goes wrong:**
v1.0 stores events with `{schema_version: 1, data: %{amount: 1000}}`. v1.1 changes schema to `{amount_cents: 1000, currency: "USD"}`. Old events can't be replayed because the shape changed. Timeline query returns errors. Team resorts to "just don't query pre-v1.1 events."

**Why it happens:**
`schema_version` is written but no upcaster is built. Evolution-readiness is easy to claim and hard to prove.

**How to avoid:**
- `Accrue.Events.Upcaster` behaviour: `upcast(event_type, from_version, to_version, data) :: data`
- Event read path ALWAYS runs through upcasters: `Event.data` getter resolves to the latest schema version via a chain of upcasters
- Writing new event types adds upcasters in the SAME PR — enforced by Credo check: any new version of an event type without a corresponding upcaster from the previous version fails CI
- Test: write an event in "old shape," upgrade library, read it, assert it comes back in "new shape"

**Warning signs:**
- `schema_version` column but no `Upcaster` module
- Event schema changed in a PR with no upcaster added
- Timeline queries that pattern-match on raw jsonb keys instead of going through a parser

**Phase to address:** Event ledger foundation phase.

---

### Pitfall 42: Major version upgrade path undocumented

**What goes wrong:**
Accrue v2.0 renames `Accrue.Billing.Customer` to `Accrue.Billing.Billable`. Users upgrading from v1.x have no migration guide. Some users stay on v1.x forever. Security patches have to be backported. Maintenance burden explodes. This is exactly what happened with Pay v2→v3.

**Why it happens:**
Library authors assume "major version = breaking changes allowed" without providing the ergonomics of migration. Semver is necessary but not sufficient.

**How to avoid:**
- Every major version ships with a `UPGRADING-v{N}.md` guide in the repo root
- Deprecation cycle: a thing to be removed in v2.0 is deprecated (with warnings) in v1.x for at least one minor version
- `mix accrue.upgrade` task that runs codemods for automatic rewrites (AST transformation via Sourceror)
- "Stable public API facade" (from PROJECT.md Key Decisions) is the commit: modules under `Accrue.Billing` are frozen, anything else is "subject to change, use at your own risk"
- Release Please config ensures BREAKING CHANGE commit messages always bump major version

**Warning signs:**
- No `UPGRADING*.md` in the repo
- No `@deprecated` attributes on anything that's about to be removed
- No codemod tooling
- Unclear public API boundary

**Phase to address:** Public API design phase + ongoing enforcement.

---

### Pitfall 43: `mix accrue.install` not idempotent — running twice duplicates files

**What goes wrong:**
Dev runs `mix accrue.install`. Installer copies generated Billing context, migrations, admin routes. Dev realizes they want a different billable schema, runs it again. Second run adds a SECOND copy of the Billing context file. Compile error.

**Why it happens:**
Generators that use `copy_file` without a conflict strategy produce this.

**How to avoid:**
- Installer detects existing files and asks: skip / overwrite / merge
- `--force` flag for CI or re-init scenarios
- State file `priv/accrue/installed.exs` records what was generated and when; second run detects it
- Integration test: run install, run install again, assert no duplicates + clear prompt

**Warning signs:**
- Installer uses raw `File.write!` with no conflict check
- No state tracking
- Re-run test case missing

**Phase to address:** Installer phase.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Return raw Stripe structs from Accrue.Billing | Zero wrapper code | Users couple to Stripe types; breaks SemVer on stripe dep upgrade | Never — this is the #1 lesson from Cashier and dj-stripe |
| `Application.get_env` in business logic | Quick config access | Tests need mutex, no per-call overrides, hides configuration | Never — use `Accrue.Config` module |
| Single `webhook_secret` config | Simple to document | Zero-downtime rotation impossible | Never — list from day 1 |
| Store amount as bare integer cents | Simple column type | Zero-decimal currencies break, multi-currency math wrong | Never — use `Accrue.Money` |
| Pre-dated migration files in templates | Simplest generator | Timestamp collisions with host app | Never — generate at install time |
| HTML-only emails | Half the templates to write | Spam score penalty, deliverability loss | Never — always include text part |
| `on_mount` auth only, no `handle_event` checks | Simpler LiveView code | Stale privileges, session lag vulnerabilities | Never — LiveView connections outlive sessions |
| Skip `dry_run` for webhook replay | Faster admin UI dev | Production disasters on replay | Never after v1.0 |
| Integer `actor_id` without `actor_type` | Saves a column | Audit trail useless when actor is system | Never |
| Ship v1.0 without `UPGRADING.md` | Less docs work | Users stuck on v1.x forever, backport burden | Only if no v2.0 planned, which isn't realistic |
| Skip Dialyzer in CI to save time | Faster CI | Type errors ship, subtle runtime bugs | Only during bootstrap (< 1 week), never after |
| Fake Processor shared Agent | Simpler impl | async tests break, slow suite | Only in the first sketch, removed before merge |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Stripe webhooks | Parse body before raw-capture plug | Raw-body plug FIRST (pre-mitigated in Accrue) |
| Stripe webhooks | Trust event payload as canonical state | Re-fetch current state OR persist event snapshot with timestamp ordering |
| Stripe idempotency keys | Random UUID per retry | Deterministic hash of (op, subject, params) |
| Stripe amounts | `amount * 100` | `Accrue.Money` type, currency-aware |
| Stripe Connect | Scope lookups only by `stripe_customer_id` | Always scope by `(stripe_account_id, stripe_customer_id)` |
| Stripe proration | Inherit default silently | Explicit `:proration` option, preview before commit |
| Stripe fees on refund | Assume refund returns everything | Expand balance_transaction, surface merchant loss |
| Stripe test clocks | Assume local time == Stripe time | Synchronized advance via `Accrue.Test.advance_clock` |
| Stripe API version | Float with latest | Pin via `lattice_stripe`, document upgrade procedure |
| Oban jobs | Regenerate idempotency key on retry | Attach to job args, reuse verbatim |
| Oban jobs | Rely on default uniqueness | `unique: [keys: [:event_id]]` explicit |
| Swoosh bounce webhooks | Ignored | Route into `Accrue.Mailer.Webhooks` handler |
| Swoosh test mode | Assume auto-setup | `assert_email_sent/1` requires `Swoosh.TestAssertions` imported |
| OTel context | Drops across Oban perform boundary | Attach trace_id to job args, re-establish span in perform |
| ChromicPDF | Chrome discovered at first use | Health check at boot, fail fast |
| ChromicPDF | Rely on system fonts | Bundle fonts in `priv/fonts/`, disable remote fonts |
| ex_cldr | Not used, raw formatters | Currency/date/number always through CLDR |
| Phoenix LiveView | `on_mount` auth only | `handle_event` auth checks too |
| Phoenix LiveView | LiveView as a hard dep in core | `accrue_admin` only; core stays headless |
| Sigra | Hard dep | `optional: true`, conditionally-compiled adapter |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| No index on `accrue_events(subject_type, subject_id, inserted_at)` | Timeline queries slow, p99 grows | Composite index from day 1 | 10k+ events per subject |
| Webhook handler runs synchronously in request path | Webhook p99 > 100ms, Stripe retries | Enqueue to Oban, 200 immediately | 50+ webhooks/sec |
| `Repo.preload` loops inside admin LiveView lists | N+1 queries | Explicit `preload: [:customer, :subscription]` + pagination | 100+ rows in list view |
| Full event timeline query without cursor | OOM on long-lived customers | Cursor-based pagination | Customer with 1000+ events |
| Fake Processor deep copy of large maps per call | Slow tests | Persistent data structures (maps) not copied | 500+ tests using Fake |
| Webhook event search without GIN index on `data` jsonb | Admin UI search slow | GIN index on `data` for common search keys | 100k+ events |
| Dialyzer PLT rebuild on every CI | 10min CI runs | Proper cache key | Every PR |
| `Oban.drain_queue` in tests without filter | All queues drained, cross-test interference | Queue-scoped drain | Test suite 500+ |
| Emails rendered inline in web request | Request timeout | Enqueue to Oban mail queue | 1 req/sec sustained |
| ChromicPDF pool too small | PDF request queue grows unbounded | Configure pool size via NimbleOptions, surface metric | 10+ concurrent invoice finalizations |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Logging Stripe event payloads in full | PAN/PII in logs — PCI scope expansion | Redact `payment_method.card.*`, email, address in log formatter |
| Storing card data "just the last 4" in custom column | PCI scope creep | Store only Stripe reference; if display needed, fetch from Stripe at render time |
| Webhook endpoint accepts unsigned requests in dev | Dev habit leaks to prod | No bypass flag in config; test env uses Fake Processor which doesn't need verification; prod is always verified |
| Admin UI without CSRF on non-GET | Session riding | Phoenix's default CSRF protection enabled in admin router explicitly; test that forms fail without token |
| `actor_id` trusted from client | Audit log spoofing | `actor_id` ALWAYS set server-side from session, never from params |
| Event ledger mutable | Audit trail lies | REVOKE UPDATE/DELETE + trigger (pitfall 10) |
| Email template HTML injection | XSS in customer email | HEEx auto-escapes; never use `{:safe, raw_string}` with user-supplied content |
| PDF generation from user-supplied HTML | SSRF / file:// escapes via ChromicPDF | Templates only; no user-controlled HTML; Chrome sandbox enabled |
| Webhook replay without authz | Anyone with admin access can fire events | `require_step_up` + dry-run default |
| Rate limit not applied to Portal redirects | Enumeration attacks on customer IDs | Plug rate limiter on portal + signed short-lived tokens |
| API key in compiled release (compile env var) | Leaked secrets in release artifact | `runtime.exs` only, documented prominently |
| Error messages leaking Stripe internals | Info disclosure | `Accrue.Error` hierarchy presents friendly messages; raw errors only in logs |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| "Plan changed" notification sent before proration confirmed | User gets "success" then an unexpected invoice | `preview_upcoming_invoice` + confirm flow, THEN notify |
| Cancellation flow with no "save" offer (off by default OK, but no hook) | Lost revenue | Document hook point for host app to inject retention flow |
| Trial-ending email 0 days before end | No time to act | 3-day warning + 1-day warning + day-of email |
| Dunning emails every day for 14 days | Email fatigue | Exponential backoff: day 1, 3, 7, 14 |
| Failed payment shows generic "error" | User doesn't know what to fix | Surface `decline_code` into user-facing message ("Your card was declined — please try another") |
| Invoice PDF only in email attachment | User can't re-download from app | Persistent URL for invoice PDF, documented auth requirement |
| Portal session URL shared across tabs | Confusing UX | One-time portal link per session |
| Admin UI search doesn't handle Stripe IDs | Can't find customer by `cus_123` | Indexed search across `stripe_*_id` columns |
| No "impersonate" audit trail | Support can't prove why they viewed a customer | Every impersonation records an event (prep for future sigra impersonation) |
| Dark mode is an afterthought | Devs who like dark mode bounce | Default theme is dark-mode-complete from day 1 |
| Event timeline shows raw event types | Incomprehensible to support agents | Human-readable labels via i18n table, drill-down to raw |

---

## "Looks Done But Isn't" Checklist

- [ ] **Subscription model:** Often missing distinction between `canceling?` and `canceled?` — verify three-predicate API exposed
- [ ] **Subscription model:** Often missing `incomplete` / `incomplete_expired` handling — verify Fake Processor exercises this path
- [ ] **Money handling:** Often missing zero-decimal currency test — verify JPY test fixture exists
- [ ] **Idempotency:** Often missing deterministic key generation — verify no `UUID.uuid4()` or `Ecto.UUID.generate` in charge creation path
- [ ] **Refunds:** Often missing fee-loss surfacing — verify `merchant_loss_amount` in `Refund` schema
- [ ] **Webhook ordering:** Often missing re-fetch-current-state step — verify handler pattern in docs
- [ ] **Event ledger:** Often missing `REVOKE UPDATE, DELETE` — verify migration
- [ ] **Event ledger:** Often missing `actor_type` column — verify NOT NULL constraint
- [ ] **Event ledger:** Often missing upcaster path — verify `Upcaster` behaviour + test
- [ ] **Event ledger:** Often missing transactional atomicity — verify `Events.record_in_multi` is the only public write API
- [ ] **Webhook pipeline:** Often missing secret rotation — verify `webhook_secrets` list config
- [ ] **Webhook pipeline:** Often missing p99 <100ms verification — verify load test exists
- [ ] **Stripe Connect:** Often missing account_id scoping — verify composite unique index
- [ ] **Admin UI:** Often missing `handle_event` authz — verify all handlers call `authorize/3`
- [ ] **Admin UI:** Often missing admin action audit event — verify every mutation emits `admin.action.*`
- [ ] **Admin UI:** Often missing step-up for destructive actions — verify `require_step_up` in admin refund/delete
- [ ] **Admin UI:** Often missing dry-run on webhook replay — verify default mode is dry-run
- [ ] **Admin UI:** Often missing dark mode contrast validation — verify NimbleOptions contrast check
- [ ] **Email:** Often missing text alternative — verify `deliver/1` rejects HTML-only
- [ ] **Email:** Often missing Outlook rendering — verify MJML used
- [ ] **Email:** Often missing bounce handling — verify `Mailer.Webhooks` plug
- [ ] **PDF:** Often missing Chrome health check — verify boot-time validation
- [ ] **PDF:** Often missing bundled fonts — verify `priv/fonts/` exists
- [ ] **PDF:** Often missing golden snapshot test — verify CI renders reference invoice
- [ ] **Localization:** Often missing customer timezone/locale — verify schema columns + ex_cldr
- [ ] **Public API:** Often missing boundary check — verify no `Stripe.*` in specs
- [ ] **Public API:** Often missing `UPGRADING.md` — verify doc stub exists pre-v1.0
- [ ] **Configuration:** Often missing `runtime.exs` examples — verify installer writes there
- [ ] **Configuration:** Often missing secret validation — verify `sk_live_` rejected in test env
- [ ] **Installer:** Often missing idempotency — verify re-run test
- [ ] **Installer:** Often missing migration collision handling — verify `DateTime.utc_now` timestamps
- [ ] **Testing:** Often missing `Accrue.Test` module — verify public test helpers shipped
- [ ] **Testing:** Often missing async-safe Fake Processor — verify `async: true` works in Accrue's own suite
- [ ] **Testing:** Often missing integration test tag — verify `:integration` tag + nightly CI
- [ ] **CI:** Often missing Dialyzer PLT cache — verify PR runs <1min on Dialyzer
- [ ] **CI:** Often missing minimal-deps job — verify no-optional-deps build passes
- [ ] **CI:** Often missing Hex publish dry-run — verify pre-flight step
- [ ] **Monorepo release:** Often missing per-package tags — verify `accrue-v*` and `accrue_admin-v*` prefixes
- [ ] **Observability:** Often missing structured errors — verify `Accrue.Error` hierarchy with `decline_code`, etc.
- [ ] **Observability:** Often missing high-signal ops events — verify revenue-loss / webhook-DLQ telemetry
- [ ] **Security:** Often missing log redaction — verify no raw event payloads in logs
- [ ] **Optional deps:** Often missing `optional: true` — verify `sigra`, LiveView marked correctly

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Leaked Stripe types in public API | HIGH | Introduce wrapper types, deprecate old signatures with warnings, codemod, major version bump |
| Zero-decimal currency bug already in production | HIGH | Audit all JPY/KRW charges, reconcile with Stripe, issue refunds, post-mortem |
| Event ledger mutable (missing REVOKE) | MEDIUM | Add migration with REVOKE + trigger, re-verify audit claims, backfill `actor_type` if missing |
| Webhook handler ran duplicate due to no idempotency_key | MEDIUM | Add unique index with `ON CONFLICT DO NOTHING`, backfill keys, dedupe historical events |
| `cancel_at_period_end` access-control bug | MEDIUM | Add canonical predicates, audit all `subscription.status` call sites, add integration tests |
| Chrome missing in prod | LOW | Rebuild image with Chrome, add health check, add to Dockerfile template |
| PLT cache wrong | LOW | Fix cache key, next CI run is slow, subsequent runs fast |
| Signing secret rotation downtime | LOW-MEDIUM | Add secret list config, deploy, re-verify failed webhook events |
| Migration timestamp collision | MEDIUM | Manually renumber, reconcile with host app, document in install guide |
| Release Please monorepo collision | LOW | Fix `release-please-config.json`, manually tag, resume normal cadence |
| HTML-only emails | LOW | Add text parts to all templates, redeploy; deliverability recovers over days |
| Upcaster path missing after schema change | HIGH | Backfill transformation via Oban job, ship upcaster, validate with random-sample reads |
| No UPGRADING.md for v2.0 | HIGH | Write retroactively, issue patch v2.0.1 with migration guide, over-communicate |
| LiveView `handle_event` auth bug exploited | HIGH | Revoke sessions, audit logs, add authorize wrapper, notify affected users |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. `cancel_at_period_end` access control | Subscription domain phase | Unit tests on `active?/canceling?/canceled?` + access-control integration test |
| 2. `incomplete` subs treated as active | Subscription + Webhook phase | Fake Processor exercises incomplete path |
| 3. Zero-decimal currency bugs | Money foundation phase (earliest) | JPY/KRW test fixtures; no bare integer amounts in boundary |
| 4. Proration default surprises | Subscription lifecycle phase | Matrix test of proration modes |
| 5. Idempotency key replay 400s | Processor wrapper + error hierarchy phase | Retry test with same+diff params |
| 6. Stripe fees on refund not surfaced | Refund domain phase | Schema has `merchant_loss_amount`, admin UI shows it |
| 7. Webhook order / duplicate delivery | Webhook dispatch phase | Out-of-order test + duplicate-delivery test |
| 8. Trace_id / actor_id gaps | Event ledger foundation phase | `actor_type` NOT NULL constraint + boundary check |
| 9. Event/state transaction rollback | Event ledger + Domain phase | Force-fail Multi test |
| 10. Audit mutable (no REVOKE) | Event ledger foundation phase | Integration test: DELETE/UPDATE raises |
| 11. Webhook handler in request path | Webhook pipeline phase | p99 <100ms load test + Credo rule |
| 12. Signing secret rotation | Webhook pipeline phase | Multi-secret verification test |
| 13. Connect account misrouting | Customer schema phase (account_id column) + Connect phase | Two-account collision test |
| 14. Oban event double-write | Event ledger foundation phase | Retry produces one event |
| 15. Leaking dep types in public API | Public API design phase (early) + ongoing | Boundary check + docs lint |
| 16. Compile-time config for secrets | Configuration phase | `runtime.exs` generator + NimbleOptions fail-fast |
| 17. Macro abuse | Ongoing review; Billable macro phase | `__using__` LOC budget + Dialyzer on generated functions |
| 18. `Application.get_env` scattered | Configuration phase | Boundary check: `get_env` only in `Accrue.Config` |
| 19. Missing test adapters | Testing-first phase (parallel with Fake Processor) | `Accrue.Test` module shipped + dogfooded |
| 20. Hard optional deps | Package structure + CI phase | Minimal-deps CI job |
| 21. Migration timestamp collisions | Installer phase | Re-install test |
| 22. Monorepo Release Please collisions | CI/CD + release tooling phase | Per-package tag prefixes + dry-run |
| 23. Hex publish secret missing | CI/CD + release tooling phase | Pre-flight secret check |
| 24. PLT cache wrong | CI/CD phase | PR runs <1min on Dialyzer |
| 25. Admin PII exposure | Admin UI auth phase | `can?/3` enforced, `redact: true` on schemas |
| 26. Admin actions unaudited | Admin UI + Event ledger crosscut | `caused_by_event_id` chain test |
| 27. No 2FA for destructive actions | Admin UI auth phase | `require_step_up` callback + threshold config |
| 28. Live webhook replay without dry-run | Admin UI webhook inspector phase | Default is dry-run, commit requires step-up |
| 29. Branding breaks dark mode contrast | Admin UI theming phase | WCAG validator in NimbleOptions |
| 30. LiveView auth only at mount | Admin UI auth phase | `handle_event` authorize helper |
| 31. HTML-only emails | Email foundation phase | `deliver/1` requires both parts |
| 32. Outlook rendering broken | Email foundation phase | MJML + client QA checklist |
| 33. Bounce webhooks ignored | Email foundation phase | `Mailer.Webhooks` plug + deliverability status |
| 34. Chrome not in prod | PDF foundation phase | Boot health check + Dockerfile docs |
| 35. TZ/locale surprises | PDF + Email foundation phase | Non-US fixtures + ex_cldr |
| 36. Font fallback divergence | PDF foundation phase | Bundled fonts + golden PDF snapshot |
| 37. Fake Processor state leaks | Fake Processor phase | Accrue's own suite runs `async: true` |
| 38. Test clock drift | Testing helpers + CI phase | `advance_clock` syncs both + `:integration` tag |
| 39. Tests hit live Stripe | Processor + CI phase | `sk_live_` prefix rejected in test env |
| 40. Flaky Oban tests | Testing helpers + CI phase | `:manual` mode + explicit drain helper |
| 41. No upcaster path | Event ledger foundation phase | `Upcaster` behaviour + read-old-write-new test |
| 42. Undocumented major upgrade path | Public API + docs phase | `UPGRADING.md` stub from day 1 |
| 43. Installer not idempotent | Installer phase | Re-run test |

---

## Sources

- Stripe API documentation — Subscriptions, Webhooks, Idempotency, Test Clocks, Connect, Refunds, Zero-decimal currencies (https://stripe.com/docs)
- Stripe engineering blog on thin events vs snapshot events (API version 2024+)
- Laravel Cashier CHANGELOG — regret notes on multi-processor abstraction
- Pay (Rails) v2→v3 migration guide and issue tracker
- dj-stripe issue tracker — JSON blob convergence history
- Bling (Elixir) source and issue tracker — known gaps
- Oban documentation — testing modes, unique jobs
- ChromicPDF documentation — Chrome discovery, pool configuration, sandbox
- Swoosh documentation — bounce webhooks, test assertions, adapter catalog
- ex_cldr documentation — formatting, currency
- Release Please monorepo mode documentation — per-package tag prefixes
- NimbleOptions documentation — runtime validation patterns
- Elixir School / Plataformatec posts on macro-vs-behaviour trade-offs
- Context7: `lattice_stripe` (sibling project v0.2.0)
- PROJECT.md (sibling file) — architectural pre-mitigations already decided
- Personal experience: billing systems at multiple companies, Stripe integration in Elixir, LiveView production deployments

---
*Pitfalls research for: Accrue (Elixir/Phoenix billing library)*
*Researched: 2026-04-11*
