# Phase 127: Optional Stripe-Native Sync (isolated, off by default) - Research

**Researched:** 2026-05-24
**Domain:** Stripe Entitlements webhook ingestion → advisory local cache (overlay over local-first canonical resolution); eventual consistency + out-of-order/replay correctness; config-gated isolation
**Confidence:** HIGH (codebase analogs + Stripe official docs + vendored lattice_stripe source all verified this session)

## Summary

Phase 127 adds an **optional, off-by-default, fully-isolated** path: when a host explicitly enables it, Accrue ingests Stripe's `entitlements.active_entitlement_summary.updated` webhook into a **new advisory cache table**, used only as an *overlay* — local plan→feature mapping (`Accrue.Entitlements.Resolver.LocalMap`) remains the canonical default. The hard parts the roadmap flagged (eventual consistency, out-of-order/replayed summaries, the 10-entitlement inline cap) all have **clean, already-established precedents in this codebase**: the `last_stripe_event_ts`/`last_stripe_event_id` monotonic skip-stale gate (`Accrue.Webhook.DefaultHandler.check_stale/2`), the resolver seam (`Accrue.Entitlements.Resolver.__impl__/0`), the config-gated optional-feature pattern (`Accrue.Config` + `:none` default lanes), and the parallel isolated webhook handler (`Accrue.Webhook.ConnectHandler` selected by `row.endpoint`).

Two ground-truth facts drive the design. **(1)** The vendored `lattice_stripe 1.1.0` has **zero Entitlements support** — no `Billing.ActiveEntitlementSummary`, no `Entitlements.ActiveEntitlement.list`, no event-type-specific decoding (verified by reading `deps/lattice_stripe/lib/`). But this does **not** block webhook *ingestion*: `LatticeStripe.Event` keeps `data` as a raw untyped map for **all** event types, so the summary payload is already fully available via the existing webhook plug → `accrue_webhook_events.data` → handler `ctx` path. The 1.2 dependency is **only** for the *deferred* full paginated **API read** (`GET /v1/entitlements/active_entitlements`), which Phase 127 does NOT implement. **(2)** Stripe's webhook delivers a **full snapshot** of up to **10** inline entitlements (`data.object.entitlements.data`, max 10), plus `has_more` and a `url` pagination handle; it gives **no delivery-order guarantee** and no documented propagation-lag SLA.

**Primary recommendation:** Build a new `accrue_entitlement_summaries` table (one row per customer) written by a config-gated reducer clause that mirrors `check_stale/2` exactly (monotonic on event `created`-ts, tie-breaking on event id), wired as an *overlay* resolver decision that the canonical `LocalMap` falls back to — never the reverse. Gate the entire path on a new `:entitlements` → `:stripe_native_sync` config key defaulting to **disabled**; when disabled, the reducer clause early-returns before any DB read and the resolver never consults the cache, so the surface is byte-for-byte identical to Phase 126. Prove isolation with a static grep gate (no cache reference reachable from the default gate path when off) plus an integration test asserting zero cache reads with sync disabled.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Webhook signature verify + raw-body persist | API / Backend (`Accrue.Webhook.Plug` → `Ingest`) | — | Already exists; type-agnostic; summary event flows through unchanged. No new ingress code. |
| Summary event → cache write (monotonic) | API / Backend (Oban async handler) | Database / Storage | New reducer clause in `DefaultHandler` (or a dedicated registered handler), config-gated; writes the new advisory cache table inside `Repo.transact/1`. |
| Advisory cache storage + monotonic watermark | Database / Storage (`accrue_entitlement_summaries`) | — | New `accrue_*` table; clones the `last_stripe_event_ts`/`_id` columns + the JSONB `data` convention. |
| Entitlement resolution (canonical) | API / Backend (`Resolver.LocalMap`) | — | UNCHANGED — local-first remains canonical. Overlay is additive and subordinate. |
| Overlay merge (advisory) | API / Backend (resolver/context seam) | Database / Storage | New resolver behavior reads the cache ONLY when sync is enabled; never overrides a canonical local grant decision in a way that can fail-open or regress. |
| Config gate (off by default) | API / Backend (`Accrue.Config`) | — | New `:stripe_native_sync` key under `:entitlements`; boot-validated; default disabled. |
| Capability advertisement | API / Backend (`Processor.Capabilities`) | — | New Stripe-only capability KEY (e.g. `entitlements.stripe_native_sync`), NOT a mutation of the existing `entitlements.local_mapping` convergence row. |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ENT-10 | When explicitly enabled (off by default), Accrue consumes Stripe's `entitlements.active_entitlement_summary.updated` webhook into a local cache used as an advisory overlay with monotonic ordering; local mapping remains the canonical default. Live Stripe entitlement API reads are deferred (depends on `lattice_stripe ≥ 1.2`). | Webhook shape + ingestion path (Q1), 10-cap + deferral boundary (Q2), eventual-consistency overlay semantics (Q3), monotonic conflict rule (Q4), schema (Q5), isolation proof (Q6), validation architecture (Q7), pitfalls (Q8) — all below. |
</phase_requirements>

## User Constraints

> No CONTEXT.md exists for this phase yet — research precedes discuss-phase. There are NO locked user decisions. The decisions that discuss-phase must make are enumerated in **Open Questions** below. The constraints below are derived from CLAUDE.md, ROADMAP success criteria, and STATE.md decisions — treat them as binding inputs to planning.

### Binding constraints (from CLAUDE.md / ROADMAP SC / STATE decisions — NOT user-overridable without re-discussion)

- **Local-first is canonical and MUST NOT regress.** Stripe-native sync is the milestone's deliberate slip-point — additive, optional, off-by-default, isolated. Bias every recommendation toward "cannot block or regress the local-first core." (ROADMAP Notes; STATE 2026-05-22 decision.)
- **Off by default.** With sync disabled (the default), the entitlements surface behaves exactly as after Phase 126 — no Stripe dependency on the core gate path (ROADMAP SC#3).
- **Monotonic ordering required.** Cache writes apply monotonic event-ts/id ordering so out-of-order or replayed summaries cannot regress the cache, **mirroring the existing `last_stripe_event_ts`/`_id` pattern** (ROADMAP SC#2).
- **Full paginated reads are DEFERRED** to `lattice_stripe ≥ 1.2` and must be documented as a follow-up (ROADMAP SC#4; STATE Deferred Items: "Typed upstream Stripe Entitlements resources + live API reads — deferred to lattice_stripe ≥ 1.2").
- **Webhook signature verification mandatory and non-bypassable**; raw-body plug before `Plug.Parsers`; sensitive Stripe fields never logged; payment-method PII stored as references only (CLAUDE.md Security). The summary payload carries `feature`/`lookup_key` IDs (not PII) — but the cache must never log raw payloads.
- **Telemetry on all public entry points** (start/stop/exception); OTel span helpers; per-check decisions → telemetry only; deliberate grant/revoke/**sync** state changes → immutable event ledger (CLAUDE.md Observability; ENT-05 split). A *sync* cache write IS a "sync state change" → it SHOULD record an `accrue_events` ledger row (unlike per-check decisions).
- **Core stays LiveView-runtime-free** (unaffected — this is server/backend code, no LiveView surface).
- **No new required dependency.** `lattice_stripe ~> 1.1`, `oban`, `ecto_sql`, `telemetry`, `nimble_options`, `jason`, `stream_data`, `mox` are already declared. This phase adds **zero** external packages.

## Standard Stack

This phase introduces **no new external libraries**. Every dependency it needs is already declared in `accrue/mix.exs` and verified present in `mix.lock`.

### Core (already present — verified in `accrue/mix.exs` + `mix.lock`)
| Library | Version (lock) | Purpose | Why Standard |
|---------|----------------|---------|--------------|
| `:ecto_sql` | 3.13.x | New `accrue_entitlement_summaries` migration + schema + `Repo.transact/1` | Already the persistence layer for every `accrue_*` table. `[CITED: accrue/mix.exs:54]` |
| `:lattice_stripe` | 1.1.0 (locked) | Webhook construct/verify + raw `Event.data` map | Already the Stripe wrapper. Decodes the summary event's raw `data.object` today (no typed resource needed for ingestion). `[VERIFIED: deps/lattice_stripe/lib/lattice_stripe/event.ex source read this session]` |
| `:oban` | 2.21.x | Async webhook dispatch (`DispatchWorker`) | The summary reducer runs inside the existing async handler chain. `[CITED: accrue/mix.exs:55]` |
| `:nimble_options` | 1.1.x | New `:stripe_native_sync` config key, boot-validated | The single config-validation tool for `Accrue.Config`. `[CITED: accrue/lib/accrue/config.ex]` |
| `:telemetry` | 1.3.x | Cache-write telemetry + stale-skip telemetry | Mandatory observability. `[CITED: accrue/mix.exs:60]` |
| `:jason` | 1.4.x | JSONB `data` encode/decode for the cached summary | Already used for every `accrue_*` jsonb column. `[CITED: accrue/mix.exs:62]` |

### Supporting (test-only — already present)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:stream_data` | 1.3.x | Property test for the monotonic regression invariant | Generate arbitrary event orderings; assert cache never regresses. `[CITED: accrue/mix.exs:99]` |
| `:mox` | 1.2.x | (Likely unneeded — Fake processor synth path preferred) | Only if a processor behaviour must be mocked; prefer `Processor.Fake.synthesize_event`. `[CITED: accrue/mix.exs:98]` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New `accrue_entitlement_summaries` table | JSONB overlay column on `accrue_customers` | A dedicated table is cleaner: it carries its own `last_stripe_event_ts`/`_id` watermark (the monotonic guard is per-summary, not per-customer-row), keeps the off-by-default path from touching the hot `accrue_customers` row at all, and is trivially droppable. **Recommend the dedicated table.** (See Q5.) |
| Config-gated clause inside `DefaultHandler` | Registered user-handler via `:webhook_handlers` | DefaultHandler is **non-disableable** and runs for ALL events — so a clause there must early-return when off. A *registered handler* (`Accrue.Config.webhook_handlers/0`) is naturally opt-in (host adds it), but the roadmap wants Accrue-owned ingestion behind a flag, not host-wired. **Recommend a config-gated DefaultHandler clause** (mirrors how `checkout.session.*` lives in DefaultHandler) — but the dispatch clause must guard on `Accrue.Config` before any work. |

**Installation:** None. No `mix deps.get` change.

**Version verification:** `lattice_stripe` pinned `~> 1.1`, locked `1.1.0` — entitlements API absent (verified by source read, see Q1/Q2). No version bump in this phase; the 1.2 bump is the *deferred* follow-up.

## Package Legitimacy Audit

**N/A — this phase installs no external packages.** Every library it uses is already declared in `accrue/mix.exs` and present in `accrue/mix.lock` (verified this session). No new `mix deps.get`, no registry additions, no slopcheck surface. The only "new" code artifacts are an Ecto migration, a schema module, a config key, a resolver/overlay change, a handler clause, and tests — all first-party.

## Architecture Patterns

### System Architecture Diagram

```
                    SYNC DISABLED (default)                    SYNC ENABLED (opt-in)
                    ───────────────────────                    ─────────────────────

  Stripe ──webhook──> Accrue.Webhook.Plug (verify sig, raw body before Parsers)
                              │
                              ▼
                    Accrue.Webhook.Ingest  ──> accrue_webhook_events (raw data persisted)
                              │                        │
                              ▼                        ▼ (Oban)
                    Accrue.Webhook.DispatchWorker ──> DefaultHandler.handle_event/3
                              │                              │
            type == "entitlements.active_entitlement_summary.updated"?
                              │                              │
                  ┌──────────┴───────────┐      ┌───────────┴────────────────────┐
                  │ Config.stripe_native │      │ Config.stripe_native_sync? YES  │
                  │ _sync? NO            │      │                                 │
                  ▼                      │      ▼                                 │
            EARLY RETURN :ok            │   reduce_entitlement_summary/...        │
            (no DB read, no cache)      │      │  Repo.transact:                  │
                                        │      │   1. resolve cus_ -> Customer    │
                                        │      │   2. load cache row by customer  │
                                        │      │   3. check_stale (monotonic)     │
                                        │      │      └ stale -> :stale telemetry  │
                                        │      │   4. upsert summary + stamp ts/id│
                                        │      │   5. Events.record (sync event)  │
                                        │      └──> accrue_entitlement_summaries   │
                                        │                                          │
   ──────────── READ / GATE PATH (Accrue.entitled? / has_active_plan?) ───────────
                                        │                                          │
        Accrue.Entitlements.entitled?(billable, feature)                          │
                  │                                                                │
                  ▼                                                                │
        Resolver.__impl__().resolve(billable)                                     │
                  │                                                                │
        LocalMap.resolve  ── CANONICAL (local subscription state, zero proc calls)│
                  │                                                                │
        sync enabled? ──NO──> return canonical (Phase-126-identical)              │
                  │                                                                │
                 YES ──> merge advisory overlay (additive only; cache NEVER       │
                          overrides a canonical grant in a fail-open direction)   ◄┘
```

### Recommended Project Structure (new/changed files)
```
accrue/
├── lib/accrue/
│   ├── config.ex                                  # ADD :stripe_native_sync key under :entitlements
│   ├── billing/
│   │   └── entitlement_summary.ex                 # NEW Ecto schema (accrue_entitlement_summaries)
│   ├── entitlements/
│   │   ├── stripe_sync.ex                         # NEW: cache read/overlay-merge + enabled?/0 gate
│   │   └── resolver/local_map.ex                  # (canonical; overlay merges AROUND it, not inside)
│   └── webhook/
│       └── default_handler.ex                     # ADD config-gated dispatch clause + reduce_entitlement_summary
├── priv/repo/migrations/
│   └── 2026MMDDHHMMSS_create_accrue_entitlement_summaries.exs   # NEW
└── test/
    ├── accrue/webhook/default_handler_entitlement_summary_test.exs   # NEW (webhook->cache integration)
    ├── property/entitlement_summary_monotonic_property_test.exs      # NEW (ordering invariant)
    └── accrue/entitlements/stripe_sync_disabled_isolation_test.exs   # NEW (off = no cache read)
```

### Pattern 1: Monotonic skip-stale watermark (THE canonical pattern to mirror)
**What:** Before applying a webhook write, compare the event's `created` timestamp to the row's stored `last_stripe_event_ts`. If strictly older (`:lt`), skip and emit stale telemetry. Ties (`:eq`) and newer (`:gt`) proceed. Stamp `last_stripe_event_ts`/`last_stripe_event_id` on every write so the next out-of-order event can skip.
**When to use:** Every cache write in this phase.
**Example (the exact code to clone):**
```elixir
# Source: accrue/lib/accrue/webhook/default_handler.ex:1058-1104 [VERIFIED: source read]
defp reduce_row(object_type, stripe_id, evt_ts, evt_id, fun) do
  Repo.transact(fn ->
    row = load_row(object_type, stripe_id)
    case check_stale(row, evt_ts) do
      :stale ->
        :telemetry.execute([:accrue, :webhooks, :stale_event], %{},
          %{object_type: object_type, stripe_id: stripe_id, event_id: evt_id})
        {:ok, :stale}
      :ok -> fun.(row)
    end
  end)
end

defp check_stale(nil, _evt_ts), do: :ok
defp check_stale(%{last_stripe_event_ts: nil}, _evt_ts), do: :ok
defp check_stale(_row, nil), do: :ok
defp check_stale(%{last_stripe_event_ts: last}, evt_ts) do
  case DateTime.compare(evt_ts, last) do
    :lt -> :stale
    _ -> :ok   # :eq and :gt proceed
  end
end

defp stamp_watermark(attrs, evt_ts, evt_id),
  do: Map.merge(attrs, %{last_stripe_event_ts: evt_ts, last_stripe_event_id: evt_id})
```
The `evt_ts` derives from the raw event `created` unix timestamp (`DateTime.from_unix!/1`) — see `DefaultHandler.handle/1` lines 189-194 and `Accrue.Webhook.Event.from_stripe/2` lines 45-49. `[VERIFIED: source read]`

### Pattern 2: Config-gated optional feature with a zero-cost "off" lane
**What:** A new key under `:entitlements` in the `@schema`, boot-validated, defaulting to disabled. The runtime hot path checks the config first and takes a zero-DB-read branch when off — mirroring how `past_due_grace: :none` (the default) takes the lean `none_lane_items/1` path with "zero query/compute change."
**When to use:** Both the webhook reducer clause AND the resolver overlay must short-circuit on this flag before touching the cache.
**Example:**
```elixir
# Mirror of Accrue.Config past_due_grace accessor — Source: accrue/lib/accrue/config.ex:770-771 [VERIFIED]
# Add to @schema under :entitlements keys (config.ex:356-431):
stripe_native_sync: [
  type: :boolean,                       # or {:in, [:disabled, :advisory]} for future-proofing
  default: false,
  doc: "Opt-in: consume entitlements.active_entitlement_summary.updated into an " <>
       "advisory local cache (overlay only; local mapping stays canonical). " <>
       "Default false — the entire path is inert when disabled. See guides/entitlements.md."
],

# Accessor:
@spec stripe_native_sync?() :: boolean()
def stripe_native_sync?, do: entitlements() |> Keyword.get(:stripe_native_sync, false)
```
Note `entitlements/0` is a **raw read** (does NOT merge nested schema defaults — see config.ex:883-905 moduledoc and `past_due_grace/0` comment at 762-769), so the accessor MUST supply the `false` default itself via `Keyword.get/3`. `[VERIFIED: source read]`

### Pattern 3: Parallel isolated handler / refetch-canonical-vs-snapshot (precedent)
**What:** `Accrue.Webhook.ConnectHandler` is a fully separate handler module selected by `row.endpoint` at dispatch time (`DispatchWorker` lines 84-88). It documents a DIFFERENT out-of-order strategy: "refetch canonical rather than compare timestamps" because a Stripe round-trip always returns current state. **For Phase 127 we deliberately CANNOT refetch canonical** (no `lattice_stripe` Entitlements API in 1.1), so we MUST use the timestamp-monotonic strategy (Pattern 1) instead. This is the key reason the summary path differs from Connect.
**When to use:** Read `ConnectHandler`'s moduledoc as the model for an isolated, well-documented handler with explicit out-of-order semantics — but use Pattern 1's monotonic guard, not Connect's refetch.
**Source:** `accrue/lib/accrue/webhook/connect_handler.ex:1-66`, `accrue/lib/accrue/webhook/dispatch_worker.ex:81-94`. `[VERIFIED: source read]`

### Pattern 4: Reading the raw summary payload in the handler (no object_id)
**What:** The lean `Accrue.Webhook.Event` struct only carries `object_id` extracted from `data.object.id`. The summary object has **no `id`** at `data.object` level (its identity is `customer`), so `Event.object_id` will be `nil` for this event. The full payload is available two ways: (a) the `DispatchWorker` already extracts `row.data["data"]["object"]` into `ctx.meter_error_object` (generic — reusable; DispatchWorker lines 64-76), or (b) the `handle/1` raw-map path extracts `data.object` directly. The summary reducer must read `customer` and `entitlements.data` from this raw object, NOT from `Event.object_id`.
**Source:** `accrue/lib/accrue/webhook/event.ex:38-43`, `accrue/lib/accrue/webhook/dispatch_worker.ex:64-76`. `[VERIFIED: source read]`

### Anti-Patterns to Avoid
- **Making the cache canonical.** The overlay must NEVER be the sole path to a `true` gate decision in a way that regresses local-first. The resolver fail-closed contract (only an affirmative resolved match → `true`) must hold; an advisory overlay can only *augment* within the documented advisory semantics, never *override* a canonical local grant in a fail-open direction. (See Q3.)
- **Refetch-canonical for the summary.** Tempting (it's how Connect/DefaultHandler dodge out-of-order), but **impossible in 1.1** (no Entitlements list API). Do not write a `Processor.fetch(:entitlement_summary, ...)` call — there is no such resource. Use the snapshot + monotonic guard.
- **Mutating the `entitlements.local_mapping` convergence row** in `Processor.Capabilities` / the support matrix. The drift gate (`scripts/ci/verify_processor_support_matrix.sh:104-112`) has a NEGATIVE guard that *fails the build* if an `entitlements.*` row sprouts a `native`/`unsupported`/`bounded` label. Phase 127 must add a **new** capability key (e.g. `entitlements.stripe_native_sync` with `stripe: native`, others `unsupported`/`out of slice`), a NEW matrix row — never edit the convergence row.
- **Logging the raw summary payload.** `feature`/`lookup_key`/`customer` are IDs, not PII, but the security posture forbids logging raw Stripe payloads; cache-write telemetry must carry only IDs/counts (allowlist-safe dimensions), never the whole `data` blob.
- **Touching the hot path when off.** Any config read that's not short-circuited, or a resolver branch that loads the cache table before checking `stripe_native_sync?`, breaks SC#3. The off lane must be provably DB-free.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Out-of-order / replay protection | A custom version-vector or "last seen" map | `check_stale/2` + `last_stripe_event_ts`/`_id` columns (Pattern 1) | Already battle-tested across 9 schemas; has tie/nil/strict-`:lt` semantics worked out + telemetry. `[VERIFIED]` |
| Webhook signature verify + raw-body persist | Re-parse the request | Existing `Accrue.Webhook.Plug` → `Ingest` (unchanged) | Summary event flows through the existing type-agnostic ingress; mandatory non-bypassable verification already enforced. `[VERIFIED]` |
| Config validation + boot-fail | Hand `with`-chains | `NimbleOptions` `@schema` entry under `:entitlements` | Boot-validated, docs-for-free, fail-loud. `[VERIFIED]` |
| Resolver dispatch / overlay seam | A new bespoke read API | `Accrue.Entitlements.Resolver.__impl__/0` seam (already exists for exactly this) | The resolver seam was built so an alternate/overlay source plugs in without touching the gate API. `[VERIFIED: resolver.ex:73-78]` |
| Sync state-change audit | A new ledger mechanism | `Accrue.Events.record/1` (called in the same `Repo.transact`) | A sync cache write IS a deliberate sync state change (ENT-05 split says these → ledger). Clone `record_event/5` shape. `[VERIFIED]` |
| Customer `cus_` → local row | A new query | `Repo.get_by(Customer, processor_id: cus_id)` (the pattern used in every reducer, e.g. charge upsert line 828) | Standard customer resolution; tolerate-miss → `:deferred` telemetry like `orphan_charge`. `[VERIFIED]` |

**Key insight:** Phase 127 is **90% pattern reuse**. The only genuinely new artifacts are one table, one config key, one handler clause, and an overlay-merge decision. The riskiest design choice is not *how* to write the cache (Pattern 1 is settled) — it's the **overlay semantics** (Q3) and the **isolation proof** (Q6), both of which are decisions for discuss-phase.

## Runtime State Inventory

This phase is **additive/greenfield, not a rename/refactor/migration**. There is no existing renamed string, no stored data to migrate, no OS-registered state, no secret/env-var rename, and no stale build artifact. The one new persistent artifact is the new `accrue_entitlement_summaries` table created by a forward migration.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — new table only; no existing rows reference the new feature. | New `CREATE TABLE` migration (forward-only). |
| Live service config | Stripe must have the `entitlements.active_entitlement_summary.updated` event enabled on the host's webhook endpoint — but that is host-owned Dashboard config, documented in the guide, NOT an Accrue artifact. | Document in `guides/entitlements.md` (host action). |
| OS-registered state | None — verified (no scheduler/pm2/systemd surface in this phase). | None. |
| Secrets/env vars | None new. Existing `:webhook_signing_secret` already covers the endpoint; the summary event verifies under the same secret. | None. |
| Build artifacts | None — pure Elixir, no NIF/egg-info/binary. | None. |

## Common Pitfalls

### Pitfall 1: Out-of-order / replayed summary regressing the cache
**What goes wrong:** Stripe gives NO delivery-order guarantee. A "customer downgraded to 1 entitlement" summary (newer) can arrive before "customer had 5 entitlements" (older) finishes processing, or a webhook retry replays an old summary, overwriting newer state.
**Why it happens:** The summary is a full snapshot; a naive "last write wins" clobbers newer state with an older snapshot.
**How to avoid:** Monotonic guard (Pattern 1) keyed on the event `created` timestamp with the event `id` as the stored tie-tracker. Strict `:lt` → skip + `:stale` telemetry. See Q4 for the exact invariant.
**Warning signs:** A property test that shuffles event order and asserts final cache state == the highest-timestamp event's snapshot.
**Evidence:** Stripe explicitly states order is not guaranteed `[CITED: docs.stripe.com/webhooks]`; codebase has `default_handler_out_of_order_test.exs` as the clone target. `[VERIFIED]`

### Pitfall 2: The 10-entitlement inline cap producing a partial/misleading cache
**What goes wrong:** A customer with >10 active entitlements gets only the first 10 in `entitlements.data`; `has_more: true`. If Accrue caches those 10 as "the complete set," entitlements 11+ are silently missing → a wrong (fail-OPEN-shaped, but actually fail-CLOSED for the missing ones) cache.
**Why it happens:** The webhook is capped at 10; full reconciliation needs the paginated API (`GET /v1/entitlements/active_entitlements`), which `lattice_stripe 1.1` cannot call.
**How to avoid:** **Persist `has_more` on the cache row.** When `has_more: true`, mark the cache as **partial/truncated** and ensure the overlay treats a truncated summary as advisory-only (never authoritative for absence). Because local mapping is canonical, a truncated cache cannot cause a wrong *grant* — the danger is only if the overlay were ever to *deny* based on absence, which the design forbids. Document the cap and the deferred full-read.
**Warning signs:** A cache row with `has_more: true` and exactly 10 entitlements; an overlay decision that denies based on the cache.
**Evidence:** "entitlements.data array contains a maximum of 10 entitlements... use the entitlements.url field to fetch the complete, paginated list" `[CITED: docs.stripe.com/billing/entitlements]`. The GitHub issue `supabase/stripe-sync-engine#280` is a real-world instance of exactly this bug (>10 entitlements not processed past #10) `[CITED: github.com/supabase/stripe-sync-engine/issues/280]`.

### Pitfall 3: The overlay accidentally becoming canonical
**What goes wrong:** A refactor wires the resolver to prefer the cache, or the gate API reads the cache directly, making Stripe state the source of truth — violating local-first and coupling the gate path to Stripe.
**Why it happens:** Overlay/canonical precedence is a subtle ordering decision; easy to invert.
**How to avoid:** The resolver seam (`__impl__/0`) keeps `LocalMap` as default. The overlay is a *merge around* the canonical result, gated on `stripe_native_sync?`. A static gate (Q6) proves the default gate path has no reachable cache reference when off.
**Warning signs:** `entitled?/2` referencing `EntitlementSummary` directly; the fail-closed property test failing.

### Pitfall 4: The cache going stale silently (eventual consistency window)
**What goes wrong:** A Stripe-side change hasn't yet produced a webhook (lag), or a webhook failed delivery, so the cache is behind reality. If the cache were canonical, a just-purchased feature would read `false`.
**Why it happens:** No documented propagation SLA; webhooks can fail/retry.
**How to avoid:** Local-first canonical resolution means the cache being stale never produces a wrong gate decision — the local subscription projection (updated by `customer.subscription.*` webhooks on the same monotonic discipline) is the truth. Document the eventual-consistency window as an inherent property of the advisory overlay. The deferred 1.2 follow-up (startup/periodic API reconcile) is the proper fix for missed webhooks.
**Warning signs:** Tests assuming the cache is fresh immediately after a Stripe change.
**Evidence:** Stripe docs recommend the List API "on application startup... or to reconcile state after a webhook delivery failure" — i.e. webhooks alone can miss `[CITED: docs.stripe.com/billing/entitlements]`.

### Pitfall 5: Customer-not-found (webhook-first / unknown customer)
**What goes wrong:** A summary arrives for a `cus_` with no local `accrue_customers` row (webhook-first, or Connect, or a customer created out-of-band).
**Why it happens:** Same out-of-order class as `orphan_charge`/`orphan_checkout_session`.
**How to avoid:** Tolerate the miss — emit an orphan/deferred telemetry event (clone the `[:accrue, :webhooks, :orphan_charge]` shape, default_handler.ex:841-848) and return `{:ok, :deferred}` rather than raise inside `Repo.transact`. Do NOT create a customer (that would hit the processor). The cache simply isn't written until the customer exists.
**Warning signs:** `Ecto.NoResultsError` inside the reducer transaction.

### Pitfall 6: Cache poisoning from a malformed summary
**What goes wrong:** A payload with missing `customer`, non-list `entitlements`, or unexpected shape crashes the reducer or writes garbage.
**Why it happens:** Untyped raw map (`lattice_stripe` doesn't decode this event type).
**How to avoid:** Defensive extraction with the dual atom/string `get/2` helper (default_handler.ex:1136-1140), validate `customer` is a binary and `entitlements.data` is a list before writing; on a shape mismatch, emit telemetry and `{:ok, :ignored}`. The handler is already rescue-wrapped (`safe_handle/2`, dispatch_worker.ex:110-125) so a crash is isolated — but prefer explicit validation over relying on the rescue.
**Warning signs:** Handler exceptions in `[:accrue, :webhook, :handler, :exception]` telemetry.

### Pitfall 7: Missing cache-write observability
**What goes wrong:** Operators can't see whether sync is working, how often summaries are stale-skipped, or truncated.
**How to avoid:** Emit (a) a cache-write telemetry span/event with `%{customer_id, entitlement_count, has_more, result}` (allowlist-safe IDs/counts only), (b) reuse `[:accrue, :webhooks, :stale_event]` (or a sync-specific variant) on skip, and (c) record an `accrue_events` ledger row for the sync state change (ENT-05: sync changes → ledger). Mirror `Accrue.Telemetry.Ops.emit/3` (ops.ex:58) for an `[:accrue, :ops, :entitlement_summary_synced]`-style event, like `connect_account_deauthorized`.
**Warning signs:** No telemetry attached in tests; silent cache.

## Code Examples

### Webhook payload shape (the exact object to parse)
```json
// Source: docs.stripe.com/billing/entitlements [CITED] — full snapshot, max 10 inline
{
  "id": "evt_1OcCWTLkdIwHu7ixbUwdUFui",
  "type": "entitlements.active_entitlement_summary.updated",
  "created": 1706111369,
  "data": {
    "object": {
      "object": "entitlements.active_entitlement_summary",
      "customer": "cus_ABC123customer",
      "livemode": false,
      "entitlements": {
        "object": "list",
        "data": [
          {
            "id": "ent_test_61QG5x2cU1GluFTYs41JqiESbLiX8C8O",
            "object": "entitlements.active_entitlement",
            "feature": "feat_test_61QGU1MWyFMSP9YBZ41ClCIKljWvsTgu",
            "lookup_key": "premium-support",
            "livemode": false
          }
        ],
        "has_more": false,
        "url": "/v1/customer/cus_ABC123customer/entitlements"
      }
    },
    "previous_attributes": { "entitlements": { "data": [] } }
  },
  "livemode": false
}
```
Parse: `customer` (string, → local customer), `entitlements.data` (list, ≤10 of `{id, feature, lookup_key}`), `entitlements.has_more` (truncation flag), `entitlements.url` (deferred pagination handle). Watermark from top-level `id` + `created`.

### Dispatch clause skeleton (config-gated, in DefaultHandler)
```elixir
# New clause near checkout.session (default_handler.ex:250). Pattern only — verify against live source.
defp dispatch("entitlements.active_entitlement_summary.updated", evt_id, evt_ts, obj) do
  if Accrue.Config.stripe_native_sync?() do
    reduce_entitlement_summary(evt_id, evt_ts, obj)   # mirrors reduce_row + check_stale
  else
    {:ok, :ignored}   # OFF lane: zero DB read, byte-for-byte Phase-126 behavior
  end
end
```

### Monotonic upsert (clone of Pattern 1, keyed on customer)
```elixir
# Pattern — load cache by customer, skip-stale, upsert + stamp, ledger. [composed from VERIFIED analogs]
defp reduce_entitlement_summary(evt_id, evt_ts, obj) do
  Repo.transact(fn ->
    cus_id = get(obj, :customer)
    case cus_id && Repo.get_by(Customer, processor_id: cus_id) do
      %Customer{} = customer ->
        row = Repo.get_by(EntitlementSummary, customer_id: customer.id)
        case check_stale(row, evt_ts) do                    # SAME helper as Pattern 1
          :stale ->
            :telemetry.execute([:accrue, :webhooks, :stale_event], %{},
              %{object_type: :entitlement_summary, stripe_id: cus_id, event_id: evt_id})
            {:ok, :stale}
          :ok ->
            attrs = build_summary_attrs(obj) |> stamp_watermark(evt_ts, evt_id)
            with {:ok, saved} <- upsert_summary(row, customer, attrs),
                 {:ok, _} <- record_event("entitlements.summary.synced",
                               "EntitlementSummary", saved.id, evt_id) do
              {:ok, saved}
            end
        end
      _ ->
        :telemetry.execute([:accrue, :webhooks, :orphan_entitlement_summary], %{},
          %{customer_stripe_id: cus_id})
        {:ok, :deferred}
    end
  end)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Pre-2024: SaaS gating purely from subscription/price webhooks | Stripe Entitlements (Features + Products + active-entitlement summaries) | Stripe Entitlements GA 2024 | Accrue can *optionally* consume native entitlement summaries — but local mapping (price→feature) remains a superset that doesn't require Stripe Entitlements at all. |
| Trust the webhook payload snapshot | Refetch canonical state from API on each event (Stripe best practice) | Ongoing | NOT available for entitlement summaries in `lattice_stripe 1.1` (no list API) → Accrue uses monotonic-snapshot instead; full-read reconcile deferred to 1.2. |

**Deprecated/outdated:**
- Treating the summary's inline `entitlements.data` as the complete set: wrong for >10 entitlements; always check `has_more`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `lattice_stripe 1.2` (the deferred dependency) will add an Entitlements `ActiveEntitlement.list`-style resource. No public changelog/roadmap was findable this session; this is inferred from the STATE.md deferral note + the 1.1 gap. | User Constraints / Q2 | If 1.2 lands without entitlements, the deferred full-read follow-up slips further — but Phase 127 itself is unaffected (it doesn't depend on 1.2). |
| A2 | A *sync* cache write should record an `accrue_events` ledger row (ENT-05 says "deliberate ... sync state changes are recorded in the immutable event ledger"). The wording maps cleanly, but discuss-phase should confirm the exact event `type` string and whether every summary write (vs. only meaningful changes) ledgers. | User Constraints / Pitfall 7 | Over-ledgering bloats the audit table; under-ledgering misses the ENT-05 intent. Low risk (reversible). |
| A3 | The advisory overlay merges *additively around* the canonical `LocalMap` result rather than via a wrapping resolver module. The exact composition point (wrap resolver vs. merge in context vs. a new combining resolver) is a discuss-phase decision. | Open Questions Q1 | Wrong composition could leak the cache into the off lane; mitigated by the isolation gate (Q6). |
| A4 | The summary `data.object` has no top-level `id`, so `Accrue.Webhook.Event.object_id` is `nil` for this event and the reducer reads `customer` from the raw `ctx` object. Verified against the documented payload (no `id` at object level) + `Event.from_stripe/2` extraction logic, but not against a live event. | Pattern 4 | If a future Stripe payload adds an object `id`, no harm — the reducer keys on `customer` regardless. Very low risk. |

## Open Questions

> These are the decisions **discuss-phase must make** (no CONTEXT.md exists yet).

1. **Overlay composition mechanism.**
   - What we know: the resolver seam (`__impl__/0`) supports an alternate resolver; the overlay must be additive and subordinate to canonical local-first.
   - What's unclear: do we (a) write a combining resolver that calls `LocalMap` then merges the cache, (b) merge in `Accrue.Entitlements.StripeSync` consulted by the context after `LocalMap`, or (c) leave the resolver untouched and expose the cache via a separate read-only diagnostic only? Option (c) is the most conservative (cache is purely informational, never affects gate decisions) and most defensible against "cannot regress local-first."
   - Recommendation: Lean toward (b) or (c). **(c) is the safest interpretation** of SC#1's "advisory overlay" — discuss-phase should confirm whether the overlay must actually influence gate decisions or merely be a *recorded, observable* advisory cache (the latter trivially satisfies "cannot block/regress core"). This is the single most impactful fork.

2. **Config key shape: boolean vs. mode enum.**
   - What we know: default must be off.
   - What's unclear: `stripe_native_sync: false` (boolean) vs. `:disabled | :advisory` (enum, room for a future `:authoritative`/`:reconcile` mode).
   - Recommendation: enum `{:in, [:disabled, :advisory]}` default `:disabled` — future-proofs the 1.2 reconcile mode without a breaking config change. Low impact; auto-resolvable.

3. **Ledger event type + granularity (A2).** Confirm the `accrue_events` `type` string (e.g. `"entitlements.summary.synced"`) and whether every write ledgers or only on change. Low impact.

4. **Truncated-cache semantics (`has_more: true`).** Confirm the cache stores `has_more` and that a truncated summary is flagged partial. Given the conservative overlay (Q1), truncation is harmless to gate decisions; confirm it's still surfaced to operators. Low impact.

5. **Should the admin surface (Phase 126) show the advisory cache?** Out of ENT-10's strict scope (ENT-11 is done), but discuss-phase may want a read-only "Stripe-native (advisory)" panel. Defer unless cheap.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL 14+ | New `accrue_entitlement_summaries` table (`gen_random_uuid()`) | ✓ (project floor) | 14+ | — (hard floor, already required) |
| `:ecto_sql` / `:postgrex` | Migration + schema | ✓ | 3.13.x / 0.22.x | — |
| `:lattice_stripe` 1.1.0 | Webhook construct/verify + raw `Event.data` | ✓ (locked) | 1.1.0 | — (ingestion only; NO entitlements API needed for this phase) |
| `:lattice_stripe` ≥ 1.2 | DEFERRED full paginated API read | ✗ (not yet released) | — | Deferred follow-up; Phase 127 does not use it. Monotonic-snapshot covers the in-scope path. |
| `:oban` | Async handler dispatch | ✓ | 2.21.x | — |

**Missing dependencies with no fallback:** None for the in-scope work.
**Missing dependencies with fallback:** `lattice_stripe ≥ 1.2` (full API reconcile) — fallback is the deferred follow-up; the webhook-snapshot + monotonic path is the complete in-scope deliverable and needs nothing beyond 1.1.

## Validation Architecture

> `nyquist_validation` is enabled (config.json `workflow.nyquist_validation: true`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + `stream_data` (property) + `Processor.Fake.synthesize_event` (in-process webhook synth) |
| Config file | `accrue/test/test_helper.exs` (live_stripe tag excluded by default) |
| Quick run command | `mix test accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs -x` (from `accrue/`) |
| Full suite command | `cd accrue && mix test.all` (format-check + credo --strict + warnings-as-errors + test) `[VERIFIED: mix.exs:106-114]` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ENT-10 | Enabled: summary webhook → cache write (customer, ≤10 entitlements, has_more) | integration | `mix test accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ❌ Wave 0 |
| ENT-10 | Out-of-order / replayed summary cannot regress cache (monotonic) | property | `mix test accrue/test/property/entitlement_summary_monotonic_property_test.exs` | ❌ Wave 0 |
| ENT-10 | Tie (`:eq` ts) processes; strict `:lt` skips with `:stale_event` telemetry | unit | (in the integration file) | ❌ Wave 0 |
| ENT-10 | Disabled (default): zero cache read on gate path; surface == Phase 126 | isolation/integration | `mix test accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs` | ❌ Wave 0 |
| ENT-10 | Disabled: static check — no cache reference reachable from the default gate path | static grep gate | `scripts/ci/verify_entitlement_sync_isolation.sh` (new, clone `verify_core_liveview_runtime_free.sh`) | ❌ Wave 0 |
| ENT-10 | Customer-not-found → `:deferred` + orphan telemetry, no raise | unit | (in the integration file) | ❌ Wave 0 |
| ENT-10 | Truncated summary (`has_more: true`) flagged partial; never denies a gate | unit | (in the integration file) | ❌ Wave 0 |
| ENT-10 | Capability matrix: NEW `entitlements.stripe_native_sync` row; convergence row untouched | drift gate | `scripts/ci/verify_processor_support_matrix.sh` (extend) | ✓ (extend existing) |
| ENT-10 | Fail-closed contract still holds with overlay present | property (existing) | `mix test accrue/test/property/entitlements_fail_closed_property_test.exs` | ✓ (must stay green) |
| ENT-10 | Docs: eventual-consistency window + 10-cap + deferred 1.2 read documented | doc verifier | `scripts/ci/verify_package_docs.sh` (extend needles) + `guides/entitlements.md` | ✓ (extend) |

### Sampling Rate
- **Per task commit:** the focused new test file(s) above, `-x`.
- **Per wave merge:** `cd accrue && mix test --seed 0` (dodge known-flaky `PdfTest`, per project memory) + the new isolation/drift scripts.
- **Phase gate:** `cd accrue && mix test.all` green + `accrue_admin` suite green + all new/extended CI scripts exit 0, before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` — webhook→cache integration (clone `default_handler_phase3_test.exs` + `_out_of_order_test.exs`); covers ENT-10 enabled/stale/tie/orphan/truncated.
- [ ] `accrue/test/property/entitlement_summary_monotonic_property_test.exs` — shuffle-order invariant (clone `entitlements_fail_closed_property_test.exs` structure + `stream_data` generators).
- [ ] `accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs` — off-by-default: assert no cache table read + surface parity with Phase 126.
- [ ] `scripts/ci/verify_entitlement_sync_isolation.sh` — static grep gate (clone `verify_core_liveview_runtime_free.sh`): no cache module reference reachable from the always-on gate path. Wire merge-blocking in `docs-contracts-shift-left`.
- [ ] Fixtures: a `StripeFixtures.entitlement_summary_event/2` helper (clone the existing `StripeFixtures.webhook_event/3` + `subscription_created/1` shape used in `_out_of_order_test.exs`).
- [ ] Migration test coverage via `Accrue.BillingCase` (table exists, columns present).

*(Framework already installed — no install command needed. All gaps are new test/fixture files + one CI script, plus extensions to two existing scripts.)*

## Security Domain

> `security_enforcement` not set to `false` in config → enabled.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface added (server-side webhook + cache). |
| V3 Session Management | no | — |
| V4 Access Control | yes | The cache is advisory ONLY; it must NEVER fail-open a gate decision. Canonical local-first resolution + fail-closed contract is the access-control control. The isolation gate (Q6) ensures the off path is uncoupled. |
| V5 Input Validation | yes | Defensive extraction of the untyped summary payload (`customer` binary, `entitlements.data` list); reject malformed shapes (`{:ok, :ignored}`), never write garbage. NimbleOptions validates the config key at boot. |
| V6 Cryptography | yes (existing) | Webhook signature verification (HMAC) is mandatory + non-bypassable — already enforced by `Accrue.Webhook.Plug`/`Signature`; the summary event verifies under the same `:webhook_signing_secret`. Do not bypass. |
| V7 Logging | yes | Never log the raw summary payload. Cache-write telemetry/ledger carries IDs + counts only (allowlist-safe), never `feature`/`lookup_key` values en masse or the whole `data` blob. |

### Known Threat Patterns for Stripe-webhook → advisory cache (Elixir/Ecto/Oban)
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged/replayed webhook | Spoofing / Tampering | Mandatory signature verify (existing) + idempotent ingest (`UNIQUE(processor, processor_event_id)`, `Ingest`) + monotonic skip-stale (Pattern 1). |
| Out-of-order snapshot clobber | Tampering | `check_stale/2` monotonic guard keyed on event `created` ts. |
| Cache poisoning via malformed payload | Tampering | Input validation (V5) + rescue-wrapped handler (`safe_handle/2`). |
| Privilege escalation via stale/partial cache | Elevation of Privilege | Advisory-only overlay; canonical local-first; fail-closed contract preserved; truncated (`has_more`) cache flagged partial and never used to deny. |
| Sensitive data leakage in logs | Information Disclosure | No raw-payload logging; allowlist-safe telemetry dimensions (V7). |
| Audit gap on sync changes | Repudiation | `accrue_events` ledger row per sync state change (ENT-05). |

## Sources

### Primary (HIGH confidence)
- **Codebase (read this session):**
  - `accrue/lib/accrue/webhook/default_handler.ex` — `check_stale/2` (1078-1087), `reduce_row/5` (1058-1076), `stamp_watermark/3` (1102-1104), `dispatch/4` clauses (205-268), `handle/1` raw-map ts derivation (183-197), orphan telemetry (841-848), dual `get/2` (1136-1140).
  - `accrue/lib/accrue/billing/subscription.ex` — `last_stripe_event_ts`/`_id` schema columns (77-78), cast (95), `force_status_changeset/2` (106-113).
  - `accrue/lib/accrue/entitlements/resolver.ex` — `__impl__/0` seam (73-78), `resolved` type (52-60).
  - `accrue/lib/accrue/entitlements/resolver/local_map.ex` — canonical fold, `none_lane_items/1` zero-cost off lane (193-201).
  - `accrue/lib/accrue/entitlements.ex` — fail-closed contract + telemetry split (1-48, 177-187).
  - `accrue/lib/accrue/webhook/ingest.ex` — idempotent transactional ingest (1-127).
  - `accrue/lib/accrue/webhook/dispatch_worker.ex` — handler selection by `row.endpoint` (84-88), `ctx` raw-object extraction (64-76), `safe_handle/2` rescue (110-125).
  - `accrue/lib/accrue/webhook/connect_handler.ex` — isolated-handler + out-of-order precedent (1-66).
  - `accrue/lib/accrue/webhook/event.ex` — lean struct, `object_id` extraction (38-43).
  - `accrue/lib/accrue/processor/capabilities.ex` — entitlements convergence row (60-112).
  - `accrue/lib/accrue/config.ex` — `:entitlements` schema (356-431), `past_due_grace/0` raw-read accessor (762-771), `entitlements/0` (883-905).
  - `accrue/deps/lattice_stripe/lib/lattice_stripe/event.ex` — raw untyped `data` for ALL event types (213-229); **no entitlements module exists** (verified `find deps/lattice_stripe/lib -iname '*entitl*'` → empty).
  - `scripts/ci/verify_processor_support_matrix.sh` — drift gate + negative divergence guard (60, 104-112).
  - `accrue/test/accrue/webhook/default_handler_out_of_order_test.exs` — monotonic test clone target.
  - `accrue/test/property/entitlements_fail_closed_property_test.exs` — property test clone target.
  - `accrue/mix.exs` — deps (54-99), `test.all` alias (106-114).
- **Stripe official docs:**
  - https://docs.stripe.com/billing/entitlements — webhook payload shape, 10-inline cap, `has_more`/`url`, full-snapshot semantics, List-API fallback recommendation.
  - https://docs.stripe.com/api/entitlements/active-entitlement/list — `GET /v1/entitlements/active_entitlements` (customer, limit 1-100 default 10, cursor pagination) — the DEFERRED 1.2 read.
  - https://docs.stripe.com/webhooks — no delivery-order guarantee; idempotency + fetch-current-state best practices.

### Secondary (MEDIUM confidence)
- https://github.com/supabase/stripe-sync-engine/issues/280 — real-world instance of the >10-entitlement cap bug (corroborates Pitfall 2).
- https://github.com/laravel/cashier-stripe/issues/1201 — out-of-order webhook causing wrong subscription state (corroborates Pitfall 1).

### Tertiary (LOW confidence)
- `lattice_stripe 1.2` entitlements roadmap — not findable on public web index (sibling/private Hex package); the 1.2 dependency for full reads is inferred from STATE.md deferral + the verified 1.1 gap (see A1).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; all verified present in mix.lock + source.
- Architecture / patterns: HIGH — every pattern is an existing, source-verified codebase analog.
- Stripe webhook facts (shape, 10-cap, ordering): HIGH — official Stripe docs + corroborating issues.
- lattice_stripe 1.1 entitlements gap: HIGH — vendored source read (no entitlements module).
- lattice_stripe 1.2 timeline: LOW — inferred, no public source (A1).
- Overlay composition decision: MEDIUM — multiple valid approaches; flagged for discuss-phase (Q1, A3).

**Research date:** 2026-05-24
**Valid until:** 2026-06-23 (stable — billing core + Stripe Entitlements API are mature; re-check only if `lattice_stripe` bumps to 1.2 or Stripe changes the summary event shape).
