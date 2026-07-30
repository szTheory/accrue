# Phase 213: Stripe-native advisory entitlements sync (observational-only) - Research

**Researched:** 2026-07-30
**Domain:** Elixir/Phoenix billing library entitlement reconciliation, Stripe-native advisory cache sync, Oban worker wrapper, Ecto monotone upsert
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Phase 213 closes the Phase 127 optional Stripe-native entitlements sync deferral by adding an opt-in, client-backed PULL/REFRESH path that fetches a customer's active Stripe entitlements through `LatticeStripe.Entitlements.*` 2.x and writes the existing advisory `Accrue.Billing.EntitlementSummary` cache. The advisory cache remains diagnostics-only and must never become a resolver/guard grant source. `[VERIFIED: .planning/phases/213-stripe-native-advisory-entitlements-sync-observational-only/213-CONTEXT.md]`

Locked implementation decisions from CONTEXT.md:
- D-01/D-02: add one optional `Accrue.Processor` callback, `list_active_entitlements(id(), opts()) :: {:ok, [map()]} | {:error, Exception.t()}`, returning a complete materialized list of string-keyed active-entitlement maps. `[VERIFIED: phase context]`
- D-03: only `accrue/lib/accrue/processor/stripe.ex` may touch `LatticeStripe`; Stripe implementation must call `LatticeStripe.Entitlements.ActiveEntitlement.stream!(client, %{"customer" => id, "limit" => "100"}, opts)` and fully drain it. `[VERIFIED: phase context; accrue/lib/accrue/processor/stripe.ex]`
- D-04: extend `Accrue.Processor.Fake` with per-customer entitlement fixtures and a callback implementation; tests must stay Fake/Test-processor only and async-safe where possible. `[VERIFIED: phase context; accrue/lib/accrue/processor/fake.ex]`
- D-05/D-06: add `Accrue.Entitlements.StripeSync.refresh(customer, opts \\ [])`; it must return `{:ok, :disabled}` before any processor or repo I/O when `stripe_native_sync` is off. `[VERIFIED: phase context; accrue/lib/accrue/config.ex]`
- D-07/D-08/D-10: add a thin `Accrue.Entitlements.StripeSync.RefreshWorker` on the existing `:accrue_webhooks` queue; do not add a top-level `Accrue` facade delegate or admin refresh button in this phase. `[VERIFIED: phase context; accrue/deps/oban/lib/oban/worker.ex]`
- D-09: wrap refresh in `Accrue.Telemetry.span([:accrue, :entitlements, :sync], ...)` and emit the existing `[:accrue, :entitlements, :summary_synced]` event with `source: :pull`. `[VERIFIED: phase context; accrue/lib/accrue/webhook/default_handler.ex]`
- D-11: reconstruct a summary-shaped JSON payload from the streamed list; carry `last_stripe_event_ts` / `last_stripe_event_id` forward untouched for pull writes. The proposed switch to a `synced_at`-based DB monotonicity guard must be re-derived before implementation because it edits correctness-critical concurrency behavior. `[VERIFIED: phase context; accrue/lib/accrue/webhook/default_handler.ex]`
- D-12/D-13: extract the existing webhook summary writer into a shared off-gate module, with provenance stored in `data["_accrue"]`; do not add a migration/source column. `[VERIFIED: phase context; accrue/lib/accrue/billing/entitlement_summary.ex]`
- D-14: close/reject `fetch_entitled/2` in docs/moduledoc; do not add any Stripe-backed entitlement predicate. `[VERIFIED: phase context; accrue/lib/accrue/entitlements/admin.ex]`
- D-15: extend `scripts/ci/verify_entitlement_sync_isolation.sh` to include the new client-fetch symbol and shared-writer symbol, and add a negative-path proof that a gate-to-seam edge fails. `[VERIFIED: phase context; scripts/ci/verify_entitlement_sync_isolation.sh]`

### the agent's Discretion

Planner may choose the shared writer module name/location, exact telemetry metadata keys, exact `data["_accrue"]` provenance shape, exact idempotent refresh return (`{:ok, :unchanged}` vs row), and exact D-14 wording, provided the result stays observational-only and code/docs read as closed, not postponed. `[VERIFIED: phase context]`

### Deferred Ideas (OUT OF SCOPE)

Admin "refresh now" button, scheduled/cron poll-all reconcile, top-level `Accrue.refresh_entitlements/1`, and webhook-side paginated reconcile for already-truncated summary webhook payloads are out of scope. `[VERIFIED: phase context]`
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SYNC-01 | Client-backed advisory refresh fetches active Stripe entitlements via `LatticeStripe.Entitlements.*` and writes `Accrue.Billing.EntitlementSummary`. | Use `Processor.list_active_entitlements/2` -> `StripeSync.refresh/2` -> shared reconciliation writer. `ActiveEntitlement.stream!/3` is present and auto-paginates. `[VERIFIED: accrue/deps/lattice_stripe/lib/lattice_stripe/entitlements/active_entitlement.ex]` |
| SYNC-02 | Sync is opt-in, off by default, and observational-only. | `Accrue.Config.stripe_native_sync/0` defaults `:disabled`; `stripe_native_sync?/0` already gates webhook work. Refresh must mirror the webhook early return before processor/repo I/O. `[VERIFIED: accrue/lib/accrue/config.ex; accrue/lib/accrue/webhook/default_handler.ex]` |
| SYNC-03 | Isolation script covers the new client-fetch path and fails on future gate use. | Extend forbidden-token regex and add a negative-path test/script fixture that proves `list_active_entitlements` and the shared writer symbol are live in the guard. `[VERIFIED: scripts/ci/verify_entitlement_sync_isolation.sh]` |
| SYNC-04 | D-07 `fetch_entitled/2` ambiguity is resolved. | Rewrite the `Admin` moduledoc and guide line to "closed/will-not-build" because network-backed gate predicates fail open; do not add a function. `[VERIFIED: accrue/lib/accrue/entitlements/admin.ex; accrue/deps/lattice_stripe/lib/lattice_stripe/entitlements/active_entitlement.ex]` |
| SYNC-05 | Fake/Test-processor async-safe tests prove cache population and no grant behavior change. | Extend `Processor.Fake.State` and Fake callback; add tests beside `stripe_sync_disabled_isolation_test.exs`, `default_handler_entitlement_summary_test.exs`, and worker tests using existing `BillingCase` / `Oban.Testing` patterns. `[VERIFIED: accrue/test/support/billing_case.ex; accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs]` |
</phase_requirements>

## Summary

The implementation should be an additive pull path over the already-shipped Phase 127 advisory cache, not a new entitlement authority. The current code already has most of the hard pieces: `Accrue.Entitlements.StripeSync` as the read seam, `Accrue.Billing.EntitlementSummary` as the cache row, `DefaultHandler` as the webhook writer with material-change detection and ledger/telemetry behavior, `Accrue.Config.stripe_native_sync?/0` as the off-by-default seam, and a static isolation script proving the grant path does not reference the advisory surface. `[VERIFIED: codebase grep/read]`

The standard path is: add an optional processor callback, implement it in Stripe by draining `LatticeStripe.Entitlements.ActiveEntitlement.stream!/3`, implement it in Fake from seeded state, add `StripeSync.refresh/2`, extract one shared reconciliation writer from `DefaultHandler`, add a thin Oban worker on `:accrue_webhooks`, and extend tests plus the static isolation guard. `[VERIFIED: phase context; local dependency docs]`

**Primary recommendation:** implement the pull path through `Accrue.Processor` and a shared off-gate reconciliation module; do not expose any Stripe-backed grant predicate; add a dedicated plan checkpoint before changing the entitlement-summary upsert guard from `last_stripe_event_ts` to `synced_at`. `[VERIFIED: phase context; accrue/lib/accrue/webhook/default_handler.ex]`

## Project Constraints (from CLAUDE.md)

- Elixir `~> 1.19`, OTP 27+, Phoenix 1.8+, Ecto 3.13, PostgreSQL 14+, `:lattice_stripe` as the Stripe API wrapper, Oban for async jobs, and telemetry for instrumentation are project-standard. `[VERIFIED: CLAUDE.md; accrue/mix.exs]`
- Accrue is a library: host apps own Repo/Oban/ChromicPDF/Finch supervision; Accrue must not start its own Oban or external client processes for this phase. `[VERIFIED: CLAUDE.md; accrue/lib/accrue/webhook/dispatch_worker.ex]`
- Raw Stripe calls are centralized in `Accrue.Processor.Stripe`; the moduledoc says CI enforces `LatticeStripe` references only in `stripe.ex` and `stripe/error_mapper.ex`. `[VERIFIED: accrue/lib/accrue/processor/stripe.ex]`
- Sensitive Stripe data must not be logged; telemetry metadata should carry bounded IDs/counts/provenance, not raw payloads or customer PII. `[VERIFIED: CLAUDE.md; accrue/lib/accrue/processor/stripe.ex]`
- Tests should prefer the Fake processor and local deterministic fixtures over mocking `LatticeStripe` or calling live Stripe. `[VERIFIED: CLAUDE.md; accrue/lib/accrue/processor/fake.ex]`
- GSD workflow says direct repo edits should be made through planning/execution workflows; this research artifact is itself part of `/gsd-plan-phase`. `[VERIFIED: CLAUDE.md]`

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Stripe active-entitlement fetch | Processor adapter boundary | External Stripe API via LatticeStripe | Only `Accrue.Processor.Stripe` may call `LatticeStripe`; every caller uses `Accrue.Processor`. `[VERIFIED: stripe.ex moduledoc]` |
| Advisory refresh orchestration | API / Backend domain seam | Oban worker wrapper | `StripeSync.refresh/2` owns the public primitive; worker only moves it off request path. `[VERIFIED: phase context; Oban.Worker docs]` |
| Cache write / reconciliation | Database / Storage | Backend domain module | Shared writer owns `EntitlementSummary` attrs, material-change detection, upsert, ledger, and telemetry. `[VERIFIED: default_handler.ex]` |
| Grant decisions | API / Backend local resolver | Database local subscription rows | `Resolver.LocalMap` remains the sole canonical gate; advisory cache must never be read by gate files. `[VERIFIED: stripe_sync.ex; isolation script]` |
| Operator diagnostics | Admin/read seam | Advisory cache | `StripeSync.summary_for_customer/1` and `Admin.resolve_for_customer/1` surface state diagnostically, not authoritatively. `[VERIFIED: stripe_sync.ex; admin.ex]` |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:lattice_stripe` | `~> 2.0`, lock currently `2.1.0` | Stripe API client and `LatticeStripe.Entitlements.*` surface | Already standard Accrue Stripe wrapper; 2.x entitlements modules are present locally after Phase 212. `[VERIFIED: mix hex.info; accrue/mix.lock; deps/lattice_stripe]` |
| `:ecto_sql` / PostgreSQL | `3.13.5` / PostgreSQL 14+ | `Repo.transact/1`, `insert on_conflict` upsert, advisory cache persistence | Existing project data layer and current writer mechanism. `[VERIFIED: accrue/mix.lock; default_handler.ex]` |
| `:oban` | `2.23.0` locked | Async refresh worker wrapper on existing queue | Already installed and used for webhook/dunning workers; worker API requires `perform/1`. `[VERIFIED: mix hex.info; accrue/mix.lock; Oban.Worker docs]` |
| `:telemetry` | `1.4.2` locked | Sync span and summary event emission | Existing public entry-point instrumentation pattern. `[VERIFIED: accrue/mix.lock; default_handler.ex]` |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:stream_data` | `1.3.0` locked | Existing property-test dependency | Use only if re-deriving upsert ordering benefits from generated event/pull order permutations. `[VERIFIED: accrue/mix.lock; property tests]` |
| `Oban.Testing` | from Oban `2.23.0` | Worker test helpers | Use for `perform_job/3`, `assert_enqueued/1`, and `all_enqueued/1` in worker tests. `[CITED: https://oban.hexdocs.pm/Oban.Testing.html]` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Processor callback | Direct `LatticeStripe.Entitlements.ActiveEntitlement.stream!/3` from `StripeSync` | Rejected by facade boundary and CI rule; would create a raw SDK call outside `processor/stripe.ex`. `[VERIFIED: phase context; stripe.ex]` |
| `RefreshWorker` on existing queue | New `:accrue_entitlements` queue | Rejected; would require new host wiring and expands scope. Existing `:accrue_webhooks` queue is already documented. `[VERIFIED: phase context; dispatch_worker.ex]` |
| JSON provenance stamp | New `source` DB column | Rejected; no schema migration needed and provenance is diagnostic only. `[VERIFIED: phase context; entitlement_summary.ex]` |

**Installation:**
```bash
# No new package install. Phase 212 already bumped :lattice_stripe to "~> 2.0".
cd accrue && mix deps.get
```

## Package Legitimacy Audit

No new external packages are installed in Phase 213. Existing package facts verified:

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `lattice_stripe` | Hex.pm | 2.0.0 and 2.1.0 published 2026-07-29 | 826 last 7 days / 2,870 all-time from `mix hex.info` | `github.com/szTheory/lattice_stripe` | OK | Approved existing dependency |
| `oban` | Hex.pm | 2.23.0 published 2026-05-27 | 185,253 last 7 days / 25,708,596 all-time from `mix hex.info` | `github.com/oban-bg/oban` | OK | Approved existing dependency |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram

```text
Host/manual trigger or host-scheduled enqueue
        |
        v
Accrue.Entitlements.StripeSync.refresh(customer, opts)
        |
        |-- config :disabled? --> {:ok, :disabled} before Processor/Repo I/O
        |
        v
Accrue.Processor.list_active_entitlements(customer.processor_id, opts)
        |
        |-- Fake adapter --> seeded per-customer entitlement list
        |
        |-- Stripe adapter --> LatticeStripe.ActiveEntitlement.stream!(client, %{"customer" => id, "limit" => "100"})
        |
        v
Shared off-gate reconciler builds summary-shaped payload
        |
        v
Accrue.Billing.EntitlementSummary upsert + material-change ledger + telemetry
        |
        v
Diagnostic read seams: StripeSync.summary_for_customer/1, admin diagnostics

Always-on gate path:
Accrue.entitled?/2 -> Resolver -> Resolver.LocalMap -> local subscription rows
        |
        |  static isolation guard forbids references to StripeSync,
        |  EntitlementSummary, list_active_entitlements, shared writer
        v
No advisory cache dependency
```

### Recommended Project Structure

```text
accrue/lib/accrue/
├── entitlements/
│   ├── stripe_sync.ex              # add refresh/2, keep summary_for_customer/1
│   └── reconcile.ex                # suggested shared writer extracted from DefaultHandler
├── entitlements/stripe_sync/
│   └── refresh_worker.ex           # thin Oban worker, queue: :accrue_webhooks
├── processor.ex                    # optional list_active_entitlements/2 callback + facade
├── processor/
│   ├── stripe.ex                   # only real LatticeStripe call
│   └── fake.ex                     # seeded Fake callback
└── processor/fake/state.ex         # entitlements state map

accrue/test/accrue/
├── entitlements/stripe_sync_refresh_test.exs
├── entitlements/stripe_sync_refresh_worker_test.exs
├── entitlements/stripe_sync_isolation_test.exs
└── webhook/default_handler_entitlement_summary_test.exs
```

### Pattern 1: Optional Processor Callback

**What:** Add a callback and facade method to `Accrue.Processor`, then mark it optional in `@optional_callbacks`. `[VERIFIED: accrue/lib/accrue/processor.ex]`

**When to use:** Any first-party operation that can be Stripe-native but must remain fakeable and safe for non-Stripe adapters. `[VERIFIED: phase context]`

**Example:**
```elixir
@callback list_active_entitlements(id(), opts()) :: {:ok, [map()]} | {:error, Exception.t()}

@optional_callbacks list_active_entitlements: 2

@spec list_active_entitlements(id(), opts()) :: {:ok, [map()]} | {:error, Exception.t()}
def list_active_entitlements(id, opts \\ []) when is_binary(id) and is_list(opts) do
  __impl__().list_active_entitlements(id, opts)
end
```

### Pattern 2: Stripe Adapter Drains the LatticeStripe Stream

**What:** Build the configured client, call `ActiveEntitlement.stream!/3`, materialize with `Enum.map`, and convert structs to plain string-keyed maps shaped like webhook `entitlements.data.data`. `[VERIFIED: deps/lattice_stripe active_entitlement.ex; stripe.ex translate_resource pattern]`

**Example:**
```elixir
alias LatticeStripe.Entitlements.ActiveEntitlement

@impl Accrue.Processor
def list_active_entitlements(id, opts) when is_binary(id) and is_list(opts) do
  client = build_client!(opts)
  stripe_opts = stripe_opts_no_idem(opts)

  entitlements =
    client
    |> ActiveEntitlement.stream!(%{"customer" => id, "limit" => "100"}, stripe_opts)
    |> Enum.map(&active_entitlement_to_wire_map/1)

  {:ok, entitlements}
rescue
  %LatticeStripe.Error{} = raw -> {:error, ErrorMapper.to_accrue_error(raw)}
end
```

### Pattern 3: Thin Oban Worker

**What:** Use `Oban.Worker` with compile-time queue `:accrue_webhooks`; `perform/1` loads the customer or accepts a customer id, calls `StripeSync.refresh/1`, and returns `:ok` / `{:error, reason}` according to Oban result semantics. Oban docs state workers define `perform/1`, queue defaults are compile-time options, and success tuples are marked complete. `[CITED: https://oban.hexdocs.pm/Oban.Worker.html]`

**Example:**
```elixir
defmodule Accrue.Entitlements.StripeSync.RefreshWorker do
  use Oban.Worker, queue: :accrue_webhooks, max_attempts: 25

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"customer_id" => customer_id}}) do
    case Accrue.Repo.get(Accrue.Billing.Customer, customer_id) do
      nil -> {:cancel, :customer_not_found}
      customer -> Accrue.Entitlements.StripeSync.refresh(customer)
    end
  end
end
```

### Anti-Patterns to Avoid

- **Do not call `LatticeStripe` from `StripeSync` or the reconciler:** violates the facade boundary. `[VERIFIED: stripe.ex]`
- **Do not use `list/3` for refresh:** Stripe defaults to 10 items; `stream!/3` follows pages and raises on page failure. `[VERIFIED: deps/lattice_stripe active_entitlement.ex]`
- **Do not create `fetch_entitled/2`:** the name invites authorization misuse; LatticeStripe's own docs warn against network-call gates. `[VERIFIED: admin.ex; deps/lattice_stripe active_entitlement.ex]`
- **Do not add a migration for provenance:** use `data["_accrue"]`; provenance is diagnostic. `[VERIFIED: phase context]`
- **Do not duplicate the webhook writer:** extract it; duplicate material-change, ledger, stale, and telemetry logic will drift. `[VERIFIED: default_handler.ex]`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stripe pagination | Manual `starting_after` loop | `ActiveEntitlement.stream!/3` | Existing SDK stream follows pages and raises on page failure. `[VERIFIED: deps/lattice_stripe]` |
| Background execution | Custom Task/supervisor | `Oban.Worker` | Oban is already installed, tested, and host-wired; Accrue must not start its own job runner. `[VERIFIED: dispatch_worker.ex; Oban docs]` |
| Cache schema/provenance | New source table/column | Existing `EntitlementSummary.data` JSONB + `_accrue` stamp | No migration is needed for diagnostic-only provenance. `[VERIFIED: entitlement_summary.ex; phase context]` |
| Test doubles | Mox over `LatticeStripe` or live Stripe | `Accrue.Processor.Fake` seeded entitlements | Existing Fake processor is the project primary test seam and keeps tests async-safe/no network. `[VERIFIED: fake.ex; BillingCase]` |
| Gate behavior | Stripe-backed predicate | `Resolver.LocalMap` | Local gate is fail-closed and already CI-isolated from advisory cache. `[VERIFIED: stripe_sync.ex; isolation script]` |

**Key insight:** The refresh path may read Stripe and write a cache, but authorization must remain a local subscription-to-feature fold. The plan should make every dependency direction prove that distinction. `[VERIFIED: phase context; current code]`

## Common Pitfalls

### Pitfall 1: Pull writes can corrupt webhook ordering if the upsert guard is changed casually
**What goes wrong:** A pull with no event timestamp updates or blocks a webhook incorrectly. `[VERIFIED: default_handler.ex; phase context]`
**Why it happens:** Current ordering is split: `check_stale/2` uses `last_stripe_event_ts`, and the DB `on_conflict` guard compares `EXCLUDED.last_stripe_event_ts` to the stored watermark. Pulls have no Stripe event watermark. `[VERIFIED: default_handler.ex]`
**How to avoid:** Plan a checkpoint to prove cases: stale pull after newer webhook, newer webhook after pull, timestamp-less webhook edge, concurrent pull+webhook, and equal-timestamp webhook redelivery. `[VERIFIED: phase context; wr05_concurrency_test.exs]`
**Warning signs:** Any plan that simply changes the guard to `synced_at` without updating `check_stale/2`, `stamp_summary_watermark/4`, and concurrency tests is under-specified. `[VERIFIED: codebase]`

### Pitfall 2: `ActiveEntitlementSummary` is not retrievable
**What goes wrong:** Planner asks Stripe adapter to retrieve a summary object. `[VERIFIED: deps/lattice_stripe active_entitlement_summary.ex]`
**Why it happens:** The summary object is webhook-only and has no top-level `id`. `[VERIFIED: deps/lattice_stripe active_entitlement_summary.ex]`
**How to avoid:** Pull active entitlements and reconstruct a summary-shaped cache payload locally. `[VERIFIED: phase context]`
**Warning signs:** References to `ActiveEntitlementSummary.retrieve/3` or a summary id. `[VERIFIED: deps/lattice_stripe active_entitlement_summary.ex]`

### Pitfall 3: Config-off path doing hidden I/O
**What goes wrong:** `refresh/2` fetches the customer row, calls the processor, or opens a transaction before checking config. `[VERIFIED: phase context]`
**Why it happens:** Adding a worker can tempt loading/repo work before the domain seam. `[ASSUMED]`
**How to avoid:** Make `StripeSync.refresh/2` check `Accrue.Config.stripe_native_sync?()` as its first executable branch; worker may load the customer only because it runs after host opted to enqueue, but the public primitive still must be inert. `[VERIFIED: default_handler.ex; config.ex]`
**Warning signs:** Fake `call_count(:list_active_entitlements)` increases when sync is disabled. `[VERIFIED: fake.ex supports call_count]`

### Pitfall 4: Isolation regex only looks complete
**What goes wrong:** The script regex mentions new names but no test proves a real gate-path reference fails. `[VERIFIED: isolation script]`
**Why it happens:** Static gates can become ceremonial without a negative fixture. `[ASSUMED]`
**How to avoid:** Add a test that temporarily writes or feeds a fixture gate-path file containing `list_active_entitlements` / shared-writer symbol before a comment marker and asserts non-zero exit. `[VERIFIED: phase context]`
**Warning signs:** Only the regex changed; no failure-path assertion. `[VERIFIED: phase context]`

### Pitfall 5: Worker args as structs or atoms from DB JSON
**What goes wrong:** Oban job args carry `%Customer{}` or atomized keys from JSON. `[VERIFIED: Oban.Testing docs; dunning_step.ex]`
**Why it happens:** Oban persists args as JSON; tests often hide serialization. `[VERIFIED: Oban.Testing docs]`
**How to avoid:** Use scalar string-keyed args like `%{"customer_id" => customer.id}` and pattern match on string keys in `perform/1`. `[VERIFIED: dunning_step.ex; Oban.Testing docs]`
**Warning signs:** `perform/1` clause matches `%{customer_id: id}` only. `[VERIFIED: Oban.Testing docs]`

## Code Examples

### Fake Seed Helper

```elixir
@spec put_entitlements(String.t(), [map()]) :: :ok
def put_entitlements(customer_processor_id, entitlements)
    when is_binary(customer_processor_id) and is_list(entitlements) do
  call({:put_entitlements, customer_processor_id, entitlements})
end

def handle_call({:list_active_entitlements, id, opts}, _from, state) do
  with_script_or_stub(state, :list_active_entitlements, [id, opts], fn state ->
    {{:ok, Map.get(state.entitlements, id, [])}, state}
  end)
end
```

### Refresh Off-Lane Test

```elixir
test "disabled refresh returns before processor or repo work", %{customer: customer} do
  refute Accrue.Config.stripe_native_sync?()
  before = Fake.call_count(:list_active_entitlements)

  assert {:ok, :disabled} = Accrue.Entitlements.StripeSync.refresh(customer)
  assert Fake.call_count(:list_active_entitlements) == before
  refute Repo.get_by(EntitlementSummary, customer_id: customer.id)
end
```

### Worker Test Pattern

```elixir
use Oban.Testing, repo: Accrue.TestRepo

assert {:ok, _} =
         perform_job(
           Accrue.Entitlements.StripeSync.RefreshWorker,
           %{"customer_id" => customer.id}
         )
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Webhook-only advisory summary cache | Webhook plus opt-in pull refresh from active-entitlement list | Phase 213, after Phase 212 2.x bump | Closes Phase 127 deferral while keeping grants local. `[VERIFIED: requirements; phase context]` |
| Inline summary list may be truncated | Pull uses `stream!/3` with `limit=100` and `truncated=false` on reconstructed summary | LatticeStripe 2.x entitlement API | Cache can be complete for pull path without new grant semantics. `[VERIFIED: deps/lattice_stripe]` |
| D-07 `fetch_entitled/2` deferred | Closed/rejected with reason | Phase 213 | Removes naming ambiguity around Stripe-backed gates. `[VERIFIED: phase context]` |

**Deprecated/outdated:**
- `StripeSync` moduledoc currently says the cache is written exclusively by `DefaultHandler`; implementation must update it to mention webhook + pull writers. `[VERIFIED: accrue/lib/accrue/entitlements/stripe_sync.ex]`
- Existing isolation script token list lacks `list_active_entitlements` and the new shared writer symbol. `[VERIFIED: scripts/ci/verify_entitlement_sync_isolation.sh]`

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A temporary-fixture style negative test is the most practical way to prove the isolation regex catches new symbols. | Pitfalls / Validation | Planner may choose a different proof mechanism; requirement is the failure-path proof, not the exact harness. |
| A2 | Worker should use customer UUID args rather than processor id args. | Architecture / Code Examples | If host scheduling naturally knows only processor ids, worker lookup shape may change; refresh primitive remains customer-backed. |

## Open Questions (RESOLVED)

1. **RESOLVED — the shared writer's DB guard switches from `last_stripe_event_ts` to `synced_at`.**
   - What we know: D-11 recommends it, but flags correctness risk; current code and tests are built around event watermark ordering. `[VERIFIED: phase context; default_handler.ex]`
   - Resolution: Plan 01 Task 2 proves the guard before finalizing it with five edge probes: stale pull after newer webhook, newer webhook after pull, pull begun after stored webhook with watermark preservation, concurrent pull/webhook greatest-`synced_at` convergence, and timestamp-less/equal-time webhook behavior. The implementation retains `check_stale/2`, uses strict-greater `synced_at` conflict semantics, and carries the greatest real webhook watermark across pulls and timestamp-less writes. `[VERIFIED: 213-01-PLAN.md Task 2]`

2. **RESOLVED — the shared writer is `Accrue.Entitlements.Reconcile`.**
   - What we know: `Accrue.Entitlements.Reconcile` is suggested and should stay off gate files. `[VERIFIED: phase context]`
   - Resolution: use `Accrue.Entitlements.Reconcile` to keep `StripeSync` focused on public sync/read primitives and give D-15 an explicit shared-writer isolation token. `[VERIFIED: 213-01-PLAN.md; 213-03-PLAN.md]`

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | Compile/test implementation | yes | Elixir 1.19.5, Mix 1.19.5, OTP 28 | none |
| PostgreSQL | Ecto sandbox tests | yes | `psql` 14.17; `pg_isready` accepting connections | none |
| Docker | Optional host/dev services | yes | 29.5.2 | not required |
| Stripe CLI | Not required by this phase | yes | 1.21.7 | Fake processor tests only |
| Live Stripe credentials | Prohibited for phase tests | not checked | — | Fake processor |

**Missing dependencies with no fallback:** none.

**Missing dependencies with fallback:** live Stripe is intentionally not used; Fake/Test processor is the required fallback. `[VERIFIED: requirements]`

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL Sandbox, Oban.Testing, existing Fake processor |
| Config file | `accrue/test/test_helper.exs`; support cases under `accrue/test/support/` |
| Quick run command | `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_test.exs test/accrue/webhook/default_handler_entitlement_summary_test.exs` |
| Full suite command | `cd accrue && mix test.all` plus `bash scripts/ci/verify_entitlement_sync_isolation.sh` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SYNC-01 | Refresh fetches active entitlements and writes summary row | integration | `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_test.exs` | planned in Plan 01 Task 1 |
| SYNC-02 | Config default/off no-op; grant path unchanged | unit/integration | `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_test.exs test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs` | partial |
| SYNC-03 | Static guard fails on new gate-to-seam edge | script/test | `bash scripts/ci/verify_entitlement_sync_isolation.sh` plus new negative test | partial |
| SYNC-04 | `fetch_entitled/2` closure in moduledoc/guide | docs test or grep | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | partial |
| SYNC-05 | Fake processor covers population and contradictory cache does not affect grants | integration | `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_test.exs` | planned in Plan 01 Task 1 and Plan 03 Task 2 |

### Sampling Rate

- **Per task commit:** targeted `mix test` for touched area plus `bash scripts/ci/verify_entitlement_sync_isolation.sh`.
- **Per wave merge:** `cd accrue && mix test.all`.
- **Phase gate:** full `accrue` gate green before verification; no live Stripe/no Chrome.

### Task-Owned Test Gaps

- [ ] Plan 01 Task 1 creates `accrue/test/accrue/entitlements/stripe_sync_refresh_test.exs` for SYNC-01, SYNC-02, and SYNC-05.
- [ ] Plan 02 Task 2 creates `accrue/test/accrue/entitlements/stripe_sync_refresh_worker_test.exs` for worker behavior.
- [ ] Plan 03 Task 1 creates the negative-path isolation proof for `list_active_entitlements` and the shared-writer token for SYNC-03.
- [ ] Plan 03 Task 2 extends the package-doc verifier with the D-14 closure assertion for SYNC-04.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Host owns authentication; no auth surface added. `[VERIFIED: entitlements guide]` |
| V3 Session Management | no | No session/cookie changes. `[VERIFIED: phase context]` |
| V4 Access Control | yes | Keep `Resolver.LocalMap` as sole grant authority; extend static isolation guard. `[VERIFIED: isolation script; resolver files]` |
| V5 Input Validation | yes | Validate customer shape, processor id presence, list shape, scalar Oban args; never atomize job args. `[VERIFIED: dunning_step.ex; Oban docs]` |
| V6 Cryptography | no | No signing/encryption changes; webhook signature policy unchanged. `[VERIFIED: requirements]` |
| V7 Error Handling / Logging | yes | Map Stripe errors through `ErrorMapper`, avoid raw payload/PII logging, bounded telemetry metadata only. `[VERIFIED: stripe.ex]` |

### Known Threat Patterns for Entitlements Sync

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Fail-open authorization via network-backed entitlement check | Elevation of Privilege | Do not add `fetch_entitled/2`; gate locally and fail closed. `[VERIFIED: LatticeStripe ActiveEntitlement docs; phase context]` |
| Stale or contradictory advisory cache influencing grants | Elevation of Privilege | Static isolation guard plus runtime tests that grants are unchanged with empty/stale/contradictory cache. `[VERIFIED: isolation script; requirements]` |
| Partial Stripe list writes undercount entitlements | Tampering / Denial of Service | Use `stream!/3`, not one-page `list/3`; materialize complete list or return error. `[VERIFIED: deps/lattice_stripe]` |
| Raw Stripe PII in telemetry/logs | Information Disclosure | Emit only IDs/counts/source/result; do not log raw entitlement payload. `[VERIFIED: stripe.ex project PII discipline]` |
| Atom exhaustion from Oban JSON args | Denial of Service | Match string keys; do not convert untrusted job args to atoms. `[VERIFIED: dunning_step.ex; Oban.Testing docs]` |

## Sources

### Primary (HIGH confidence)

- `accrue/deps/lattice_stripe/lib/lattice_stripe/entitlements/active_entitlement.ex` - `stream!/3`, required customer param, pagination, failure behavior, local-gate warning.
- `accrue/deps/lattice_stripe/lib/lattice_stripe/entitlements/active_entitlement_summary.ex` - summary is webhook-only, no id/retrieve, stream-entitlements semantics.
- `accrue/lib/accrue/webhook/default_handler.ex` - current advisory writer, config gate, material-change detection, upsert guard, telemetry.
- `accrue/lib/accrue/billing/entitlement_summary.ex` - cache schema, observational-only contract, force changeset.
- `accrue/lib/accrue/processor.ex`, `processor/stripe.ex`, `processor/fake.ex`, `processor/fake/state.ex` - processor callback/facade patterns and Fake test seam.
- `scripts/ci/verify_entitlement_sync_isolation.sh` - current static gate.
- `mix hex.info lattice_stripe`, `mix hex.info oban`, `accrue/mix.lock` - live/package version metadata.

### Secondary (MEDIUM confidence)

- https://oban.hexdocs.pm/Oban.Worker.html - worker `perform/1`, queue options, return semantics.
- https://oban.hexdocs.pm/Oban.Testing.html - `perform_job`, `assert_enqueued`, manual-mode test helpers.
- https://ecto.hexdocs.pm/Ecto.Repo.html - upsert/on_conflict/stale error documentation cross-check; current implementation still verified locally against Ecto 3.13.5 source.
- https://docs.stripe.com/api/entitlements/active-entitlement/retrieve - Stripe active entitlement shape includes id/object/feature/lookup_key/livemode.

### Tertiary (LOW confidence)

- None used for implementation recommendations. Research-plan seam was attempted but unavailable in this `gsd-tools` install (`Unknown command: research-plan`); local dependency source and official HexDocs/Hex metadata were used instead.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - current lockfiles, `mix hex.info`, and local dependency source agree.
- Architecture: HIGH - phase decisions align with existing processor facade, webhook writer, config seam, and isolation guard.
- Pitfalls: HIGH for upsert/facade/pagination issues verified in code; MEDIUM for exact isolation negative-test harness shape because planner may choose a different proof implementation.

**Research date:** 2026-07-30
**Valid until:** 2026-08-06 for `lattice_stripe`/Oban API details, 2026-08-29 for stable codebase architecture unless Phase 213 implementation changes the writer shape sooner.
