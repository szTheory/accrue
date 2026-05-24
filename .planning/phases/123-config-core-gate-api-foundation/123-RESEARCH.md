# Phase 123: Config + Core Gate API Foundation - Research

**Researched:** 2026-05-22
**Domain:** Local-state entitlements — `:entitlements` config schema (NimbleOptions, boot-validated), the `Accrue.Entitlements` context + `Resolver` behaviour seam (`LocalMap` default), the four fail-closed gate functions, and `[:accrue, :entitlements, :check]` telemetry/OTel spans. [VERIFIED: `123-CONTEXT.md`; `.planning/research/{SUMMARY,ARCHITECTURE,PITFALLS}.md`; `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; codebase source files cited inline]
**Confidence:** HIGH [VERIFIED: every locked decision in CONTEXT.md is research-backed and cross-referenced to an in-repo, line-anchored analog; greenfield package tree, zero new external deps]

> **Reconstruction note (2026-05-22):** Sections **Code Examples**, **State of the Art**,
> **Assumptions Log**, **Open Questions (RESOLVED)**, **Environment Availability**, and
> **Validation Architecture** are the original verbatim content. The surrounding scaffolding
> sections (**User Constraints**, **Phase Requirements**, **Summary**, **Architectural
> Responsibility Map**, **Project Constraints**, **Standard Stack**, **Architecture Patterns**,
> **Don't Hand-Roll**, **Common Pitfalls**, **Security Domain**, **Sources**, **Metadata**) were
> reconstructed from the authoritative co-located artifacts — `123-CONTEXT.md` (locked decisions),
> `123-PATTERNS.md` (line-anchored analog map, itself derived from this RESEARCH), `123-VALIDATION.md`,
> and `.planning/research/{SUMMARY,ARCHITECTURE,PITFALLS}.md` — after a tooling overwrite. All facts
> below are still verified against those sources; build to `123-CONTEXT.md` for locked decisions.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (full set in `123-CONTEXT.md` — abbreviated here)

**A — Plan→Feature/Quota Config Schema (ENT-01)**
- **D-01:** One top-level `:entitlements` keyword list, **runtime** (`Application.get_env`, NOT `compile_env!` — host-owned catalog data that differs per env), but boot-validated loudly.
- **D-02:** Key on logical plan **atoms**, not raw price_ids. Each plan: `features: [atom]`, `limits: [atom: pos_integer]`, `price_ids: [string]`.
- **D-03:** Inner keys: `:plans` (atom-keyed), `:resolver` (module, default `LocalMap`), `:unmapped_action` (`:deny` | `:raise`, default `:deny`).
- **D-04:** Unmapped = loud fail-closed (both layers). Boot builds a `price_id → plan` reverse index; same price_id under two plans **raises at boot** (`Accrue.ConfigError`). Check-time unmapped → `false` (`:deny`) + `reason: :unmapped_plan`; `:raise` for strict envs. Never silent-allow.
- **D-05:** One source of truth for plan identity — do not conflict with `Accrue.PlanResolver` (processor mechanics); the entitlement map answers *feature* questions, joined on `SubscriptionItem.price_id`.

**B — Public Gate API & Fail-Closed Contract (ENT-02/03/04)**
- **D-06:** Four total functions on `Accrue`, `defdelegate` → `Accrue.Entitlements`: `has_active_plan?(billable, plan) :: boolean()` (`plan :: atom() | String.t()`); `entitled?(billable, feature) :: boolean()`; `features_for(billable) :: [atom()]` (sorted, deduped, UNION across all active subs; `MapSet` internal, never leaked); `entitlement_quantity(billable, quota_key) :: non_neg_integer()` (`min(cap, quantity)` when a cap exists else quantity, fail-closed `0`).
- **D-07:** Boolean-only API. **Do NOT** ship a `fetch_entitled/2` `{:ok,bool}|{:error,_}` variant in Phase 123 — a truthy `{:error,_}` tuple is the exact fail-open footgun the milestone exists to prevent; the "denied vs couldn't-check" diagnostic goes to telemetry `reason` metadata, not a code API.
- **D-08:** Fail-closed mechanics — a single private resolver returns `{:ok, true} | {:ok, false} | {:error, reason}`; `{:ok, true}` is the **sole** true-path; `{:ok,false}`/`{:error,_}`/`nil`/wrong-type → fail-closed; wrapped in `try/rescue/catch` so exceptions/throws/exits collapse to `false`/`[]`/`0`.
- **D-09:** Read path = zero processor calls, no cross-request cache: `billable → read-only Customer lookup → Billing.Query.active/1 → SubscriptionItem.price_id → reverse-index plan → features/limits`. Reuse `Subscription.active?/1` (never raw `.status`). **Do NOT call `Accrue.Billing.customer/1`** (effectful). billable is opaque via `Accrue.Auth`.
- **D-10:** Property test invariant — for all garbage/edge inputs (nil, non-billable, no-customer, no-active-sub, unmapped price_id, raising stub): `entitled?/2 → false`, `entitlement_quantity/2 → 0`, `features_for/1 → []`; `entitled?/2` true **iff** the resolved active feature set contains the feature. (never-true-on-garbage + true-iff-affirmative-match.)

**C — Module Layout & Resolver Seam**
- **D-11:** Ship the `Resolver` behaviour seam NOW with a single `LocalMap` impl (behaviour-first habit; makes 125/127 purely additive).
- **D-12:** New files under `accrue/lib/accrue/entitlements/`: `entitlements.ex`, `resolver.ex` (`@callback resolve/2`, no `capabilities/0` yet), `resolver/local_map.ex`, `plan.ex` (pure value struct, no Ecto). MODIFY `config.ex` and `accrue.ex`.
- **D-13:** Dispatch runtime: `Application.get_env(:accrue, :entitlements, []) |> Keyword.get(:resolver, LocalMap)`. Local-only in 123.
- **D-14 (LOCKED):** One-way dependency — `Accrue.Entitlements.*` reads `Billing.*`; nothing under `lib/accrue/billing/` may reference `Accrue.Entitlements.*`. Enforce with a grep/Credo gate.
- **D-15:** Additive-proof for 125 (capability-matrix rows) and 127 (StripeNative resolver + cache) — zero edits to 123's public path.

**D — Telemetry / Observability Contract (ENT-05)**
- **D-16 (LOCKED):** Plural events `[:accrue, :entitlements, :check, :start|:stop|:exception]`; OTel span `accrue.entitlements.check`. Supersedes the singular `[:accrue, :entitlement, :check]` in ROADMAP SC#5 + ENT-05 (reconcile in this phase).
- **D-17:** Reuse `Accrue.Telemetry.span/3` **inline** (mirror `storage.ex`); no `span_entitlement` wrapper.
- **D-18:** Metadata map `%{feature, result: boolean, resolver: :local_map, reason: :entitled|:not_entitled|:unmapped_plan|:no_active_subscription|:error, subject_type, subject_id}`. `subject_id` = internal UUID, span metadata only, never a metric tag, never PII.
- **D-19:** OTel allowlist additions (atom + string forms): `:feature`, `:result`, `:resolver`, `:reason`, `:subject_type`, `:subject_id`. Bridge no-ops when `:opentelemetry` absent.
- **D-20:** Fail-closed visibility — unmapped-plan deny emits `reason: :unmapped_plan` in `:stop`. No separate `:unmapped` event.
- **D-21 (CONFIRMED):** Phase 123 writes ZERO `accrue_events` rows. `Accrue.Events.record/1`/`record_multi/3` NOT called in the check path — per-check decisions are telemetry-only forever.

### Deferred Ideas (OUT OF SCOPE for 123)
- `fetch_entitled/2` tuple variant (defer to a sourced host need, D-07).
- ENT-08 capability-matrix rows + drift gate → Phase 125.
- Lifecycle→entitlement truth-table SSOT + `past_due` grace → Phase 125 (123 inherits `active?/1`).
- Plug/LiveView guards (ENT-06/07) → Phase 124.
- Admin entitlements view + `guides/entitlements.md` → Phase 126.
- Stripe-native webhook→cache sync + grant/revoke + ledger writes (ENT-10) → Phase 127.
- Atomic seat enforcement — host-owned recipe, never a core API.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ENT-01 | A `:entitlements` plan→feature/quota config map validates at boot (NimbleOptions); duplicate price_id across plans raises `Accrue.ConfigError`. [VERIFIED: REQUIREMENTS.md / D-01..05] | Standard Stack, Architecture Patterns, Common Pitfalls (#7 config drift), Validation Architecture. |
| ENT-02 | `has_active_plan?/2` answers from local subscription state (atom + price_id string), reusing `Subscription.active?/1`. [VERIFIED: REQUIREMENTS.md / D-06/09] | Architecture Patterns, Code Examples (active subs fold), Validation Architecture. |
| ENT-03 | `entitled?/2` + `features_for/1` are fail-closed; true iff the resolved active feature set matches. [VERIFIED: REQUIREMENTS.md / D-06/08/10] | Architecture Patterns (fail-closed), Common Pitfalls (#1 fail-open), Property Test Spec. |
| ENT-04 | `entitlement_quantity/2` returns `min(cap, quantity)` else quantity, fail-closed `0`. [VERIFIED: REQUIREMENTS.md / D-06] | Code Examples (subs+items fold), Validation Architecture. |
| ENT-05 | Every check emits `[:accrue, :entitlements, :check, :start/:stop/:exception]` with D-18 metadata; zero `accrue_events` rows. [VERIFIED: REQUIREMENTS.md / D-16..21] | Architecture Patterns (inline span), Common Pitfalls (#5 ledger/telemetry split), Telemetry Contract Test Spec. |
</phase_requirements>

## Summary

The milestone research threads converged on one shape: **entitlements is a thin derivation layer over local subscription state**, not a new persistence subsystem. Phase 123 builds that layer's spine — a host-declared `plan → feature/quota` map (config), a `Resolver` behaviour seam with a single `LocalMap` default impl, and four fail-closed gate functions on `Accrue` that read local `Subscription`/`SubscriptionItem` state with **zero processor calls** and **zero ledger writes**. No new tables, no Ecto schema, no Stripe dependency in this phase.

The two highest-leverage correctness decisions are front-loaded into 123's exit criteria so every downstream surface (Plug/LiveView guards in 124, admin view in 126, optional Stripe sync in 127) inherits them: (1) **fail-closed boolean** — `{:ok, true}` is the sole true-path, every error/exception/nil/garbage input collapses to `false`/`[]`/`0`, pinned by the load-bearing `stream_data` property test (D-10); (2) **lifecycle-predicate reuse** — `Subscription.active?/1`/`Query.active/1` are the truth, never raw `.status`. This phase is purely additive to the existing codebase (no refactor) and leaves the Resolver seam ready for 127's `StripeNative` second impl.

## Architectural Responsibility Map

| Concern | Tier | Owner Module | Notes |
|---------|------|--------------|-------|
| Plan→feature/quota catalog | config | `Accrue.Config` (`:entitlements` schema + accessor + boot collision guard) | runtime data, boot-validated (D-01) |
| Public gate API (4 fns) | context/facade | `Accrue.Entitlements` (+ `Accrue` delegates) | inline telemetry, fail-closed (D-06/08/17) |
| Resolution contract | behaviour | `Accrue.Entitlements.Resolver` (`@callback resolve/2`, `__impl__/0`) | runtime dispatch seam (D-11/13) |
| Default resolution | service | `Accrue.Entitlements.Resolver.LocalMap` | read-only Ecto fold (D-09) |
| Resolved value shape | model | `Accrue.Entitlements.Plan` | pure value struct, NO Ecto (D-12) |
| Lifecycle truth | reused | `Accrue.Billing.{Subscription,Query}` | never re-derived from `.status` (D-09, Pitfall 2) |
| Observability | cross-cutting | `Accrue.Telemetry.span/3` + `Telemetry.OTel` allowlist | plural events, PII-bounded (D-16/18/19) |

## Project Constraints (from CLAUDE.md)

- Elixir 1.17+ / OTP 27+ / Phoenix 1.8+ / Ecto 3.13+ / PostgreSQL 14+. No new external dependencies in this phase (everything needed is already declared).
- `accrue` core stays LiveView-free (no `phoenix_live_view` reference here — guards are Phase 124).
- Sensitive fields never logged; entitlement telemetry carries internal UUIDs only, never email/name/external ids (D-18; enforced by the OTel `@prohibited_keys`).
- All public entry points emit `:telemetry` start/stop/exception; OTel span helpers no-op when `:opentelemetry` absent.
- Config-vs-runtime boundary: adapter *modules* via `compile_env!`; host *data*/flags via runtime `get_env`, boot-validated. The `:entitlements` map is host data → runtime (D-01).

## Standard Stack

No new dependencies. The phase uses only already-declared deps:

| Dependency | Used For | Version | Status |
|------------|----------|---------|--------|
| `:nimble_options` | `:entitlements` schema validation | `~> 1.1` | declared |
| `:ecto`/`:ecto_sql`/`:postgrex` | read-only Customer/Subscription/Item query | `~> 3.13` / `~> 0.22` | declared |
| `:telemetry` | `[:accrue, :entitlements, :check]` spans | `~> 1.3` | declared |
| `:stream_data` | D-10 fail-closed property test | `~> 1.3` (test) | declared |
| `:opentelemetry` (optional) | OTel attribute enrichment | `~> 1.7` | optional; bridge no-ops if absent |

## Architecture Patterns

(Full line-anchored analog map in `123-PATTERNS.md`. Key patterns, summarized:)

1. **Inline telemetry-span facade** — mirror `accrue/lib/accrue/storage.ex` L42-48. `Accrue.Telemetry.span([:accrue, :entitlements, :check], metadata, fn -> ... end)` for each of the four public fns. **Critical:** `Accrue.Telemetry.span/3` (`telemetry.ex` L74-83) builds `base_metadata` once and reuses it for `:start` AND `:stop` — compute the decision (`result`, `reason`) BEFORE opening the span (resolves Assumption A2).
2. **Behaviour + runtime dispatch** — mirror `processor.ex` L347-348 `__impl__/0`; read `:entitlements`→`:resolver`, default `LocalMap` (D-13).
3. **Fail-closed boolean predicate** — mirror `subscription.ex` L146-149 `active?/1` (sole-affirmative head + catch-all `false`); wrap in `try/rescue/catch` (D-08).
4. **Lifecycle truth reuse** — `Query.active/1` (`query.ex` L30-32) / `Subscription.active?/1`; never raw `.status` (Pitfall 2).
5. **Config schema + boot validation** — extend `@schema` (clone `:branding` nested-keys block); place the cross-plan price_id-collision guard in `maybe_validate_boot_setup!/1` raising `Accrue.ConfigError` (D-04).
6. **One-way dependency gate (D-14)** — verify `! grep -rq "Accrue.Entitlements" accrue/lib/accrue/billing/ accrue/lib/accrue/billing.ex`.

## Don't Hand-Roll

- **Active-subscription detection** — use `Query.active/1` / `Subscription.active?/1`, do not re-implement the `:active`/`:trialing` lifecycle check (Pitfall 2).
- **Telemetry spans** — use `Accrue.Telemetry.span/3`, do not call `:telemetry.span` directly (it carries actor + OTel bridge + no-op handling).
- **Config validation** — use the NimbleOptions `@schema` + `validate_at_boot!/0` machinery, do not hand-roll `with`-chains (NimbleOptions also generates the `Accrue.Config` docs).
- **Read-only customer lookup** — clone the private `billing.ex` `fetch_customer/2` query body; do not call the effectful `Billing.customer/1` (D-09).

## Common Pitfalls

1. **Fail-open on error/nil (the accidental path).** Elixir truthiness makes a truthy `{:error, _}` tuple silently grant access. Mitigation is structural: boolean-only API (D-07), `{:ok, true}` as the sole true-path, `try/rescue/catch` collapse (D-08). This is the milestone's reason to exist; pinned by the D-10 property test.
2. **Not reusing lifecycle predicates.** Re-deriving entitlement from raw `.status` mishandles `canceling`/`trialing`/`incomplete_expired`/`paused`/`past_due`. Build on `Subscription.active?/1`/`Query.active/1` ("active = counts for entitlement purposes"). 123 inherits whatever `active?/1` decides; the `past_due` grace knob is Phase 125.
3. **Processor coupling on the gate path.** Calling Stripe (or the effectful `Billing.customer/1`) on a check couples authz to processor availability. Local-only resolution (D-09/13).
4. **Config / mapping drift.** Boot-validate the map, key on stable plan ids, make unmapped-plan a **loud** fail-closed condition with `reason: :unmapped_plan` telemetry; duplicate price_id raises at boot (D-04/D-20).
5. **Ledger vs telemetry mis-split.** Recording every gate check floods the immutable ledger and destroys its signal. Per-check decisions → telemetry only; grant/revoke/sync (Phase 127) → `Accrue.Events` (D-21).

## Code Examples

### Reading the runtime `:entitlements` config (mirror `branding/0`)
```elixir
# Source: accrue/lib/accrue/config.ex L685-731 (verified pattern)
@spec entitlements() :: keyword()
def entitlements, do: get!(:entitlements)   # get!/1 falls back to schema default [] — config.ex L394-405
# (a defaults-merge accessor like branding/0 is optional here; the schema's nested defaults
#  already normalize plan entries when validated. Mirror branding/0 only if call sites need
#  Keyword.fetch! safety on partial plan entries.)
```

### Read-only customer lookup the Resolver must build (NOT `Billing.customer/1`)
```elixir
# Derived from billing.ex L788-796 (private fetch_customer/2) + billable.ex L66 (__accrue__)
# Build inside the Resolver — there is no public read-only equivalent.
defp read_only_customer(%{__struct__: mod, id: id}) do
  owner_type = mod.__accrue__(:billable_type)   # billable.ex L66
  owner_id = to_string(id)
  import Ecto.Query
  Accrue.Repo.one(
    from c in Accrue.Billing.Customer,
      where: c.owner_type == ^owner_type and c.owner_id == ^owner_id,
      limit: 1
  )
end
defp read_only_customer(_), do: nil   # nil / wrong-shape billable → fail-closed
```

### Active subs + items fold (read path core)
```elixir
# Source: query.ex L30-32 (active/1) + customer.ex has_many subscriptions/subscription_items
import Ecto.Query
alias Accrue.Billing.{Subscription, SubscriptionItem, Query}

def active_price_ids(customer_id) do
  Query.active(Subscription)
  |> where([s], s.customer_id == ^customer_id)
  |> join(:inner, [s], i in SubscriptionItem, on: i.subscription_id == s.id)
  |> select([_s, i], {i.price_id, i.quantity})
  |> Accrue.Repo.all()
end
```

### Telemetry contract test pattern (mirror `storage/null_test.exs`)
```elixir
# Source: test/accrue/storage/null_test.exs L46-101 (verified pattern)
setup do
  test_pid = self(); ref = make_ref(); handler_id = {__MODULE__, ref}
  :telemetry.attach_many(handler_id,
    [[:accrue,:entitlements,:check,:start],
     [:accrue,:entitlements,:check,:stop],
     [:accrue,:entitlements,:check,:exception]],
    fn name, m, meta, _ -> send(test_pid, {:telemetry_event, name, m, meta}) end, nil)
  on_exit(fn -> :telemetry.detach(handler_id) end)
  :ok
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ARCHITECTURE.md` price_id-keyed `:plans` config + `Config.plans/0` | Logical-plan-atom-keyed single `:entitlements` key (D-02/03) | discuss-phase 2026-05-22 | Build to CONTEXT.md schema fragment, not the ARCHITECTURE sample. |
| `ARCHITECTURE.md` resolver calling `Accrue.Billing.customer/1` | Read-only customer lookup (D-09) | discuss-phase 2026-05-22 | Resolver builds its own read-only `Customer` query. |
| `span_entitlement/4` wrapper (ARCHITECTURE) | Inline `Accrue.Telemetry.span/3` (D-17) | discuss-phase 2026-05-22 | No wrapper; single-op domain. |
| Singular `[:accrue, :entitlement, :check]` (ROADMAP SC#5 / ENT-05) | Plural `[:accrue, :entitlements, :check]` (D-16) | discuss-phase 2026-05-22 | Reconcile ROADMAP + ENT-05 docs to plural in this phase. |

**Deprecated/outdated for this phase:**
- The ARCHITECTURE.md "Pattern 1 / Pattern 3 / Anti-Pattern" *code samples* (config + resolver). The *prose* guidance there remains valid.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | NimbleOptions `~> 1.1` supports the `keys: [*: [...]]` wildcard with nested `:keys` exactly as the locked D-02 fragment uses it. No live `[*: ...]` precedent exists in the current `@schema` (closest is the fully-named `:branding` nested keys). | Standard Stack / D-02 verification | If the wildcard nesting validates differently than expected, the schema fragment needs a small adjustment — surfaces immediately at first `mix compile` + boot validation, low blast radius. Recommend the planner add a boot-validation unit test that exercises the exact locked fragment shape early. |
| A2 | `Accrue.Telemetry.span/3` can carry the decided `result`/`reason` into `:stop` metadata by passing them in the initial metadata map (compute decision before opening the span, or rely on the `{result, metadata}` shape at L79-83). | Pattern 1 | If the desired enrichment requires post-hoc metadata mutation the helper does not support, the planner may need a thin local pattern (still using `span/3`); verify exact shape against `telemetry.ex` L74-83 during planning. Low risk — both styles are supported by `:telemetry.span`. |

**Both assumptions are mechanical and self-revealing at compile/test time.** No compliance, security-standard, retention, or performance assumption is being made — those are all locked by CONTEXT.md or N/A for this phase.

## Open Questions (RESOLVED)

1. **Read-only customer lookup placement (private helper vs. new public Billing read fn)**
   - What we know: D-09 forbids `Accrue.Billing.customer/1`; the only read-only equivalent (`fetch_customer/2`) is private (`billing.ex` L788).
   - What's unclear: whether to (a) inline the read-only query inside `Accrue.Entitlements.Resolver.LocalMap`, or (b) add a public read-only `Accrue.Billing` accessor (e.g. `fetch_customer_for/1`) that the Resolver calls.
   - Recommendation: **(a) inline inside the Resolver** for 123 to keep D-14's one-way dependency crisp and avoid widening the Billing public surface. Revisit (b) only if 124's Plug/LiveView guards want the same lookup. (If the planner prefers (b), it is still acyclic — entitlements→billing — and does not violate D-14.)
   - **RESOLVED:** Option (a) — inline the read-only `Customer` query inside `Accrue.Entitlements.Resolver.LocalMap.resolve/2` per D-09/D-14 (clone the `billing.ex` L788-796 `fetch_customer/2` query body; never call the effectful `Billing.customer/1`, never widen the Billing public surface). Implemented by Plan 123-03 Task 2.

2. **`has_active_plan?/2` price_id-string semantics**
   - What we know: D-06 says a price_id string is accepted and "resolves through the same map."
   - What's unclear: whether `has_active_plan?(billable, "price_pro_monthly")` means "does the billable have an active sub on a plan whose `price_ids` include that string" (reverse-index → plan → has-active) — almost certainly yes, by symmetry with the atom path.
   - Recommendation: implement string arg = reverse-index the price_id to its plan atom, then apply the same active-plan check; if the string maps to no plan, return `false` (fail-closed, `reason: :unmapped_plan`). Add an explicit unit test for both arg forms.
   - **RESOLVED:** String arg = reverse-index the `price_id` string to its plan atom, then test membership in the resolved set of ALL active plan atoms; unmapped/garbage string → `false` (fail-closed, `reason: :unmapped_plan`). The atom arg tests membership in the same active-plans set directly. Multi-active-plan customers (two active subs on different mapped plans) return `true` for BOTH plans, consistent with the UNION semantics of `entitled?/2`/`features_for/1`. Implemented by Plan 123-03 Task 2 (resolver carries an `active_plans` set) + Task 3 (`has_active_plan?/2` membership), pinned by the two-active-plan test cases in Plans 123-03 and 123-04.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compilation | ✓ | 1.19.5 (floor 1.17) | — |
| Erlang/OTP | Runtime | ✓ | 28 (floor 27) | — |
| `:nimble_options` | `:entitlements` schema | ✓ (dep) | `~> 1.1` | — |
| `:telemetry` | check spans | ✓ (dep) | `~> 1.3` | — |
| `:ecto`/`:ecto_sql`/`:postgrex` | read-only query | ✓ (dep) | `~> 3.13` / `~> 0.22` | — |
| `:stream_data` | fail-closed property test | ✓ (dep, test) | `~> 1.3` | — |
| `:opentelemetry` | OTel attribute enrichment | optional | `~> 1.7` | `OTel.span/3` no-ops when absent — already handled |
| PostgreSQL (test repo) | Resolver read-path integration tests | ✓ (test harness: `Accrue.TestRepo` + SQL Sandbox) | PG 14+ | — |
| `Accrue.Processor.Fake` | factory-backed test subscriptions | ✓ (in `lib/`, started by `BillingCase`) | — | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** `:opentelemetry` (optional; bridge no-ops). No code path blocks on it.

## Validation Architecture

> `nyquist_validation` is treated as enabled (no `false` found in config scope for this phase). This section is the spec for `123-VALIDATION.md`.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (stdlib) + `ExUnitProperties`/`StreamData ~> 1.3` for the property test |
| Config file | `accrue/mix.exs` (`{:stream_data, "~> 1.3", only: [:dev, :test]}` L93); test helper `accrue/test/test_helper.exs` |
| Case templates | `Accrue.BillingCase` (`test/support/billing_case.ex` — SQL Sandbox + Fake processor + test clock + factory aliases); plain `ExUnit.Case, async: false` for config-mutating tests |
| Quick run command | `mix test test/accrue/entitlements_test.exs` (single file, < 10s) |
| Full suite command | `mix test` (full); `mix test test/accrue/entitlements_test.exs test/accrue/entitlements/ test/accrue/config_entitlements_test.exs test/property/entitlements_fail_closed_property_test.exs` (phase subset) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ENT-01 | Valid `:entitlements` config validates at boot | unit | `mix test test/accrue/config_entitlements_test.exs -x` | ❌ Wave 0 |
| ENT-01 | Invalid `:entitlements` (bad type) raises at boot | unit | same file | ❌ Wave 0 |
| ENT-01 | Duplicate price_id across two plans raises `Accrue.ConfigError` at boot | unit | same file | ❌ Wave 0 |
| ENT-02 | `has_active_plan?/2` true for active sub on mapped plan (atom + price_id string) | example | `mix test test/accrue/entitlements_test.exs -x` | ❌ Wave 0 |
| ENT-02 | `has_active_plan?/2` reuses `active?/1` truth (trialing → true; canceled → false) | example | same file | ❌ Wave 0 |
| ENT-02 | `has_active_plan?/2` true for BOTH plans when a billable holds two active subs on different mapped plans (multi-active-plan, D-06/09) | example | same file | ❌ Wave 0 |
| ENT-03 | `entitled?/2` true iff resolved active feature set contains feature | example + property | `mix test test/property/entitlements_fail_closed_property_test.exs` | ❌ Wave 0 |
| ENT-03 | `features_for/1` sorted, deduped UNION across active subs; never returns `MapSet` | example | `mix test test/accrue/entitlements_test.exs` | ❌ Wave 0 |
| ENT-03 | Fail-closed: nil/non-billable/no-customer/no-active-sub/unmapped/raising-stub → false/[]/0 | property | `mix test test/property/entitlements_fail_closed_property_test.exs` | ❌ Wave 0 |
| ENT-04 | `entitlement_quantity/2` = `min(cap, quantity)` when cap exists, else quantity; 0 fail-closed | example | `mix test test/accrue/entitlements_test.exs` | ❌ Wave 0 |
| ENT-05 | `[:accrue,:entitlements,:check,:start/:stop/:exception]` emitted with D-18 metadata | example (telemetry handler) | `mix test test/accrue/entitlements_test.exs` | ❌ Wave 0 |
| ENT-05 | `reason: :unmapped_plan` in `:stop` metadata on unmapped-plan deny | example | same file | ❌ Wave 0 |
| ENT-05 | OTel `sanitize_attributes/1` retains the 6 new keys | unit | `mix test test/accrue/telemetry/otel_test.exs` (extend existing) | ❌ Wave 0 (extend) |
| ENT-05 | Ledger boundary: `Accrue.Events.record/1` NOT called during a check | example | `mix test test/accrue/entitlements_test.exs` | ❌ Wave 0 |
| D-14 | No `lib/accrue/billing/**` references `Accrue.Entitlements.*` | static grep / Credo | `! grep -rq "Accrue.Entitlements" accrue/lib/accrue/billing/ accrue/lib/accrue/billing.ex` | ✅ passes today |

### Property Test Spec (D-10 — the load-bearing test)
File: `test/property/entitlements_fail_closed_property_test.exs` (`use ExUnit.Case` + `use ExUnitProperties`; mirror `test/property/connect_platform_fee_property_test.exs` L1-44).

**Generators (garbage / edge inputs — assert never-true):**
- `StreamData.one_of([constant(nil), term(), integer(), string(:ascii), atom(:alphanumeric)])` — nil + arbitrary non-billable terms.
- billable struct with a valid shape but **no** `accrue_customers` row (no customer).
- billable with a customer but **no** active subscription (e.g. only a `canceled_subscription/1`).
- billable with an **active** subscription whose `price_id` is **not** in any plan's `price_ids` (unmapped).
- a **raising resolver/Repo stub** (configure `:entitlements` `resolver:` to a module whose `resolve/2` raises, or inject a stub that raises) — proves `try/rescue/catch` collapses to fail-closed.

**Invariants (for ALL of the above):**
- `Accrue.entitled?(input, any_feature) == false`
- `Accrue.entitlement_quantity(input, any_quota_key) == 0`
- `Accrue.features_for(input) == []`

**Affirmative-match property (true-iff):** for a billable with an active subscription on a mapped plan whose feature set is `F`, `entitled?(billable, feat) == MapSet.member?(F, feat)` for any `feat` drawn from `F ∪ {unmapped_feature}`. This pins the dual property: never-true-on-garbage AND true-iff-affirmative-match.

**Multi-active-plan affirmative case (D-06/09):** for a billable holding **two** active subscriptions on **two different** mapped plans P1 (price `price_p1`) and P2 (price `price_p2`), assert `has_active_plan?(billable, :p1) == true` AND `has_active_plan?(billable, :p2) == true` (and, by symmetry, true for each plan's price_id string). This pins that the resolver carries the **set** of active plans (not a single representative `:plan`), keeping `has_active_plan?/2` consistent with the UNION semantics of `entitled?/2`/`features_for/1` and never producing a fail-closed-but-wrong false negative for a real second active plan. (Garbage/unmapped plan args still → false.)

**Fixtures:** use `Accrue.Test.Factory.active_subscription(%{price_id: "price_pro_monthly"})` / `trialing_subscription/1` / `canceled_subscription/1` (factory.ex L92-203, returns `%{customer:, subscription:, items:}`). Set `:entitlements` config in `setup` via `Application.put_env(:accrue, :entitlements, [...])` with `on_exit` restore (mirror `storage/null_test.exs` L6-19); use `async: false` because the test mutates app env.

### Boot-Validation Test Spec
File: `test/accrue/config_entitlements_test.exs` (`use ExUnit.Case, async: false`).
- Valid config → `Accrue.Config.validate_at_boot!() == :ok` (or `validate!/1` on the fragment).
- Invalid type (e.g. `plans: [pro: [features: "not-a-list"]]`) → raises `NimbleOptions.ValidationError`.
- Duplicate price_id across two plans → raises `Accrue.ConfigError` with a message naming both plans + the price_id (the D-04 collision guard).
- Empty/absent `:entitlements` → defaults to `[]` and validates clean (schema `default: []`).
- Note: `validate_at_boot!/0` also runs `maybe_validate_boot_setup!/1` which calls `ensure_migrations_current!` outside `:test`; tests should call the schema validation path directly or run under `:test` env so the migration check is skipped (`config.ex` L789).

### Telemetry / OTel Contract Test Spec
In `test/accrue/entitlements_test.exs` (telemetry) + extend `test/accrue/telemetry/otel_test.exs` (OTel).
- Attach to the three plural events `[:accrue, :entitlements, :check, :start|:stop|:exception]`; call each public fn; assert `:start` + `:stop` received and `:stop` metadata contains `feature`, `result` (boolean), `resolver: :local_map`, `reason` (in the D-18 atom set), `subject_type`, `subject_id`.
- Assert metadata does NOT contain `:email`/`:name`/external ids (PII boundary, D-18).
- Unmapped-plan check → assert `reason: :unmapped_plan` in `:stop` (D-20).
- OTel: assert `Accrue.Telemetry.OTel.sanitize_attributes/1` retains all six new keys (`:feature`, `:result`, `:resolver`, `:reason`, `:subject_type`, `:subject_id`, atom + string forms) mapped to `accrue.<key>` (D-19).
- Ledger boundary (D-21): count `accrue_events` rows before/after a batch of checks; assert unchanged.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V4 Access Control | yes | The gate functions ARE the access-control decision — they MUST fail closed. `{:ok, true}` is the sole grant path; nil/error/exception/unmapped → deny (D-08). Pinned by the D-10 property test. [VERIFIED: D-06/08/10] |
| V5 Input Validation | yes | The billable arg is untrusted (possibly nil/wrong-type/garbage). Guarded by struct-head matching + catch-all clauses → fail-closed, never a crash that leaks state (D-08). [VERIFIED: D-08] |
| V7 Error Handling & Logging | yes | Per-check decisions emit telemetry (`reason` diagnostic) but write ZERO ledger rows (D-21); telemetry metadata is PII-bounded — internal UUID only, never email/name/external id (D-18). [VERIFIED: D-18/21] |
| V6 Cryptography | no | Phase 123 introduces no cryptographic behavior. [VERIFIED: scope is config + read-path + telemetry] |
| V2 Authentication | no | Accrue does not own auth; billable is opaque via the `Accrue.Auth` behaviour. [VERIFIED: D-09] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Fail-open on error/exception/nil (free user gets a paid feature) | Elevation of Privilege | Boolean-only API (D-07); `{:ok, true}` sole true-path; `try/rescue/catch` collapse (D-08); D-10 property proof. |
| Unmapped price_id silently allows | Elevation of Privilege | Check-time unmapped → false (`:deny` default) + `reason: :unmapped_plan` (D-04/D-20); duplicate price_id raises at boot. |
| **Multi-active-plan false negative** — a single representative `:plan` makes `has_active_plan?(billable, other_plan)` wrongly return false for a real second active plan | Elevation of Privilege (fail-closed-but-WRONG) | Resolver carries the **set** of all active plan atoms; `has_active_plan?/2` tests set membership; pinned by the two-different-active-plans test (D-06/09). |
| Processor coupling on the gate path | Denial of Service | Local-only resolution (D-09/13); never `Processor.*` or effectful `Billing.customer/1`. |
| PII in check telemetry | Information Disclosure | `subject_id` = internal UUID only; OTel `@prohibited_keys` + strict allowlist; test asserts no `:email`/`:name` (D-18). |
| Re-deriving "active" from raw `.status` | Tampering | Reuse `Subscription.active?/1`/`Query.active/1` (Pitfall 2); grep-asserted absent of `s.status`. |
| Recording per-check decisions floods the immutable ledger | Tampering | ZERO `Accrue.Events.record/1`/`record_multi/3` in the check path (D-21); ledger-boundary row-count test. |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/123-config-core-gate-api-foundation/123-CONTEXT.md` — locked Phase 123 scope, decisions (D-01..21), canonical refs, code context. [VERIFIED: file read]
- `.planning/phases/123-config-core-gate-api-foundation/123-PATTERNS.md` — line-anchored analog map for every created/modified file (derived from this RESEARCH). [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` — ENT-01..05 requirement text + milestone goal/out-of-scope. [VERIFIED: file read]
- `.planning/ROADMAP.md` — Phase 123 goal, depends-on, 5 success criteria. [VERIFIED: file read]
- `.planning/research/{SUMMARY,ARCHITECTURE,PITFALLS,FEATURES,JTBD-FRONTIER}.md` — convergent milestone design, Pitfalls 1–5/7, Phase-1 deliverables. [VERIFIED: file read]
- `accrue/lib/accrue/config.ex` — `@schema` (`:branding` nested-keys L272-305), `branding/0`/`merge_with_defaults` (L685-731), `get!/1` (L394-405), `validate_descending/1` (L846-863), `maybe_validate_boot_setup!/1` (L786-798), `plan_resolver/0` (L570-576). [VERIFIED: file read]
- `accrue/lib/accrue/billing.ex` — private `fetch_customer/2` (L788-796), effectful `customer/1` (L754-786). [VERIFIED: file read]
- `accrue/lib/accrue/billing/{query.ex (active/1 L30-32), subscription.ex (active?/1 L146-149), subscription_item.ex (price_id L26, quantity L29), customer.ex (owner_type/owner_id L48-49, has_many :subscriptions L65)}`. [VERIFIED: file read]
- `accrue/lib/accrue/{processor.ex (__impl__/0 L347-348), auth.ex (behaviour + impl/0 L41-47/L105), plan_resolver.ex (resolved_plan typespec L27-39), storage.ex (inline-span facade L42-79), telemetry.ex (span/3 L74-83), telemetry/otel.ex (@allowed_attributes L12-27, sanitize_attributes L99-111), events.ex (record/1 L109, record_multi/3 L135), errors.ex (ConfigError L112-127), billable.ex (__accrue__ L66)}`. [VERIFIED: file read]
- `accrue/lib/accrue/test/factory.ex` (L92-203), `accrue/test/support/billing_case.ex`, `accrue/test/accrue/storage/null_test.exs` (L6-19, L46-101), `accrue/test/property/connect_platform_fee_property_test.exs` (L1-44). [VERIFIED: file read]
- Local environment checks 2026-05-22 — Elixir 1.19.5 / OTP 28; `stream_data ~> 1.3` declared (`accrue/mix.exs` L93). [VERIFIED: local checks]

### Secondary (MEDIUM confidence)
- `accrue/guides/lifecycle_semantics.md` — "active = counts for entitlement purposes" vocabulary (the truth Phase 125 will pin). [VERIFIED: referenced in CONTEXT canonical refs]

### Tertiary (LOW confidence)
- None. All substantive claims are drawn from repo-local artifacts. [VERIFIED: research inputs]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new dependencies; everything needed (`nimble_options`, `ecto`, `telemetry`, `stream_data`) is already declared. [VERIFIED: CLAUDE.md, mix.exs]
- Architecture: HIGH — every created/modified file has an in-repo, line-anchored analog (123-PATTERNS.md: 14/14). [VERIFIED: analog map]
- Pitfalls: HIGH — the fail-open and lifecycle-predicate hazards are directly visible in code and front-loaded into 123 exit criteria. [VERIFIED: source + milestone PITFALLS.md]

**Research date:** 2026-05-22 [VERIFIED: local session date]
**Valid until:** 2026-06-21 for planning purposes, unless Phase 123 scope or the billing read-path semantics change before execution. [VERIFIED: stable greenfield package tree]

**Reconstruction provenance (2026-05-22):** The scaffolding sections were rebuilt from the co-located authoritative artifacts (CONTEXT/PATTERNS/VALIDATION + milestone research) after a tooling overwrite truncated this file; the original verbatim content (Code Examples → Validation Architecture) was preserved from in-context reads. No locked decision or test contract changed during reconstruction.
