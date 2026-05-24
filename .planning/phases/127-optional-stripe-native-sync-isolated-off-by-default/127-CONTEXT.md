# Phase 127: Optional Stripe-Native Sync (isolated, off by default) - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

> **How these decisions were made:** Four parallel `gsd-advisor-researcher` agents
> researched the coupled gray areas (overlay semantics, config/isolation, schema,
> ledger/telemetry) against idiomatic Elixir/Ecto/Phoenix practice, the
> `lattice_stripe/prompts/` deep-research corpus, `.planning/research/` (esp.
> PITFALLS.md), and peer libs (Pay, Laravel Cashier, supabase/stripe-sync-engine,
> Lago, Stigg, LaunchDarkly/Unleash). All four independently judged their decision
> **additive/reversible — not an irreversible or published-commitment fork** — so
> everything below is locked per the project's cohesive-one-shot-synthesis posture.
> Build on `127-RESEARCH.md`; do not re-derive.

<domain>
## Phase Boundary

**ENT-10 only.** Add an **optional, off-by-default, fully-isolated** path: when a host
explicitly enables it, Accrue ingests Stripe's
`entitlements.active_entitlement_summary.updated` webhook into a **new advisory cache
table** with monotonic ordering. Local plan→feature mapping
(`Accrue.Entitlements.Resolver.LocalMap`) remains the **canonical default** and MUST NOT
regress. With sync disabled (the default), the entitlements surface behaves **byte-for-byte
as after Phase 126** — no Stripe dependency on the core gate path.

**In scope:** new `accrue_entitlement_summaries` table; one config key; a config-gated
webhook reducer clause (monotonic skip-stale); ledger + telemetry for sync state changes;
a read-only core seam exposing the cache; a static isolation CI gate; a new capability-matrix
row; docs (eventual-consistency window + 10-cap + deferred 1.2 read).

**Out of scope:** any change to `entitled?`/`has_active_plan?` gate behavior; full paginated
Stripe Entitlements API reads (deferred to `lattice_stripe ≥ 1.2`); a rendered admin LiveView
panel; metered/tiered entitlement math; gate-influencing overlay semantics.

</domain>

<decisions>
## Implementation Decisions

### Overlay semantics (the central decision)
- **D-01 — OBSERVATIONAL-ONLY overlay.** The advisory cache is **written, ledgered,
  telemetered, and exposed via a read-only core seam — but the gate path
  (`Accrue.entitled?/2`, `has_active_plan?/2`) NEVER reads it.**
  `Accrue.Entitlements.Resolver.__impl__/0` and `LocalMap` are **UNCHANGED**. `entitled?`
  behavior with sync **ON == OFF == Phase 126**; the sole path to `true` remains a resolved
  local affirmative match.
  *Why (decisive):* (1) **Forecloses nothing** — observational→gate-influencing is a strictly
  non-breaking later add; shipping gate-influence first and removing it would BREAK hosts →
  the only choice compatible with "ship complete, zero breaking-change pain through v1.x."
  (2) The local plan→feature map is already positioned as a **superset** across all providers
  (PITFALLS.md:133), so a Stripe-grant the local map lacks means the host *mis-mapped their own
  catalog* — the fix is the existing unmapped-price drift surface, not a stale Stripe snapshot
  silently papering over it (which would be an eventual-consistency authorization surface).
  (3) Makes the static isolation proof **and** the fail-closed property test **trivially true
  even when sync is ON** (the gate literally never references the cache).
  *Peer-lib evidence:* LaunchDarkly/Unleash cache-feeds-decision = perpetual fail-open + stale
  bug class (android-client-sdk#112 "users lose features"); Stigg requires a "degraded answer"
  indicator when a cache gates — impossible to express through a 2-value `entitled?` boolean;
  Pay/Cashier keep the local projection canonical and the webhook a feed (Cashier #1201
  out-of-order clobber); Accrue's OWN PITFALLS.md already ruled twice for "advisory/secondary
  overlay, **not a separate truth**."

- **D-02 — SC#1 wording reconciliation (read before verifying).** Roadmap SC#1's
  "a local cache **used as an advisory overlay**" is realized as an **observational** advisory
  cache in v1.x (recorded + surfaced, **not gate-consulted**). The **gsd-verifier MUST check**:
  "cache is written + monotonic + surfaced (ledger/telemetry/read-seam) + never blocks or
  regresses local-first," **NOT** "the cache changes `entitled?` output." This is the
  maximally-safe realization of SC#1's own "local mapping remains the canonical default" + the
  milestone mandate "without that path being able to block or regress the local-first core
  value." It is **not** a scope/behavior reduction — gate-influencing is a reserved future
  additive enum value (see Deferred). Do not mutate ROADMAP; this CONTEXT note is the SSOT for
  the interpretation.

### Config key shape + isolation (off-by-default, provably inert)
- **D-03 — Config: enum, not boolean.** Add `stripe_native_sync` under the existing
  `:entitlements` `@schema` (config.ex, after `past_due_grace` ~:421):
  `type: {:in, [:disabled, :advisory]}`, `default: :disabled`, boot-validated via NimbleOptions.
  Accessor `stripe_native_sync/0` supplies its own default via
  `entitlements() |> Keyword.get(:stripe_native_sync, :disabled)` (because `entitlements/0` is a
  **raw read** that does not merge nested defaults — identical constraint to `past_due_grace/0`
  at config.ex:770-771). Add ergonomic predicate `stripe_native_sync?/0 → (… != :disabled)`.
  *Why enum:* matches the in-schema `unmapped_action: {:in, [:deny, :raise]}` (config.ex:390)
  and `past_due_grace` enum precedents; lets future modes (`:reconcile` for the deferred 1.2
  paginated read; a future gate-influence value) **append without a breaking config change** —
  a boolean would force a breaking type-flip when the deferred mode lands. `NimbleOptions.docs/1`
  renders the allowed values for free.
  **Doc string MUST state plainly:** *":advisory records Stripe entitlement summaries to an
  advisory cache for audit / telemetry / the admin read-seam; it does **not** change
  `entitled?`/`has_active_plan?` decisions in v1.x (local mapping stays canonical)."* — this
  neutralizes the only DX risk (an operator expecting `:advisory` to alter gating).

- **D-04 — Isolation: runtime config-gate, NOT conditional compilation.** Phase 127 adds
  **zero new deps**, so there is nothing to compile-gate (conditional compilation is reserved
  for optional-dependency *presence* — the Sigra / `Accrue.Live.Entitlements` pattern, which is
  why `verify_core_liveview_runtime_free.sh` exists). Idiomatic Elixir gates *behavior* at
  runtime; the analogous off-lane (`past_due_grace: :none`) is a pure runtime branch
  (`local_map.ex` `none_lane_items/1`). Three-layer proof:
  1. **Runtime gate checked-first**: the DefaultHandler dispatch clause early-returns
     `{:ok, :ignored}` **before any `Repo` call** when `stripe_native_sync?() == false`.
  2. **Static merge-blocking grep gate** `scripts/ci/verify_entitlement_sync_isolation.sh`
     (clone `verify_core_liveview_runtime_free.sh`: same `^[^#]*` comment-anchor + allowlist-
     by-construction + `exit 1` on hit) — asserts no `EntitlementSummary`/cache-module reference
     is reachable from the always-on gate path (`entitlements.ex`, `resolver/local_map.ex`).
     Wire merge-blocking in `docs-contracts-shift-left`.
  3. **Integration test**: assert **zero** `accrue_entitlement_summaries` reads during an
     `entitled?/2` call with sync `:disabled` (assert via Ecto `[:accrue, :repo, :query]`
     telemetry) + surface-parity with a Phase-126 fixture.

### Cache schema / persistence
- **D-05 — Dedicated table, raw JSONB snapshot.** New `accrue_entitlement_summaries`, **one
  row per customer**. Clone the `accrue_subscription_schedules` convention
  (`accrue/lib/accrue/billing/subscription_schedule.ex:36-51`) — a thin local projection with a
  `data :map` JSONB blob + typed columns for what admin/operators read.
  - **Reject** JSONB-on-`accrue_customers` (its watermark would collide with the customer's own
    `last_stripe_event_ts`, corrupting the customer's monotonic gate; mutates the hot row; breaks
    off-lane DB-free).
  - **Reject** `embeds_many` (re-types an explicitly untyped upstream — lattice_stripe 1.1 has no
    Entitlements resource; **0** embeds exist in the codebase; drifts on the next Stripe field).
  - **Reject** normalized child rows (one row/entitlement) — this is **exactly the
    supabase/stripe-sync-engine #280 >10-cap bug** (inline-only ingest silently drops #11+).
  - **Columns:** `id` binary_id (`gen_random_uuid()`); `processor` (default "stripe");
    `customer_id` FK → `accrue_customers` `on_delete: :delete_all`; `stripe_customer_id`
    (denormalized `cus_` for orphan/debug); `livemode`; `entitlement_count` int (admin sort);
    `truncated` bool (← `entitlements.has_more`); `data :map` (raw payload incl. `entitlements.url`
    pagination handle); `synced_at` utc_datetime_usec (event `created`, human-friendly);
    `last_stripe_event_ts` / `last_stripe_event_id` watermark; `lock_version`; timestamps.
  - **Indexes:** `unique_index(:customer_id)` (upsert target / one-per-customer idempotency);
    `index(:stripe_customer_id)`; partial `index(where: truncated = true)` (operators find
    partial caches fast).
  - **Changeset:** `force`-style changeset (Stripe canonical, no status allowlist to fail on) +
    `optimistic_lock(:lock_version)` + `unique_constraint(:customer_id)` +
    `foreign_key_constraint(:customer_id)`. Forward-only migration.

- **D-06 — Monotonic write (reuse, don't reinvent).** Config-gated dispatch clause in
  `DefaultHandler` (mirror the `checkout.session.*` placement). Reuse `check_stale/2` +
  `stamp_watermark/3` **verbatim** (strict `:lt` → skip + `[:accrue, :webhooks, :stale_event]`;
  `:eq`/`:gt` proceed). Read `customer` + `entitlements.data` from the raw `ctx` object via the
  dual atom/string `get/2` helper (the summary object has **no top-level `id`** — key on
  `customer`). Customer-not-found → `[:accrue, :webhooks, :orphan_entitlement_summary]` +
  `{:ok, :deferred}` (clone `orphan_charge`), **never raise, never create a customer**. Malformed
  payload (missing `customer`, non-list `entitlements`) → telemetry + `{:ok, :ignored}`, never
  write garbage.

- **D-07 — Truncation honesty.** Map `entitlements.has_more` → the typed `truncated` column
  (queryable/indexed/operator-visible); preserve `entitlements.url` in `data` for the deferred
  1.2 reconcile. The cache is honestly "partial" for >10-entitlement customers. (Observational-
  only means truncation can never affect a gate decision — but it's surfaced for operators.)

### Audit ledger + telemetry/observability (ENT-05 split)
- **D-08 — Ledger: on-change-only.** Record an `accrue_events` row **only when the cached set
  materially changes** — sorted `{feature_id, lookup_key}` pairs OR `truncated` differs from the
  current row (first-ever write = material). **No** ledger row on stale-skip, orphan/deferred, or
  byte-identical re-delivery (those are telemetry-only). Honors ENT-05 ("deliberate sync **state
  change** → ledger") without webhook-replay bloat, and does **not** duplicate the per-delivery
  `accrue_webhook_events` row that already exists. Event `type`: **`"entitlements.summary.synced"`**
  (matches the namespaced convention: `subscription.created`, `connect.account.deauthorized`, …).
  `idempotency_key: "entitlements.summary.synced:" <> evt_id` → Oban retries collapse via the
  UNIQUE partial index (events.ex:146-154). Ledger `data` = IDs/counts only, **never the raw
  payload**.

- **D-09 — Telemetry.** Span **`[:accrue, :entitlements, :sync]`** (start/stop/exception),
  sitting beside the existing `[:accrue, :entitlements, :check]` — the two-span mirror of the
  ENT-05 split (`:check` = per-decision telemetry-only; `:sync` = state-change ledger+telemetry).
  Cache-write event **`[:accrue, :entitlements, :summary_synced]`**: measurements
  `%{count: 1, entitlement_count: n}`, metadata `%{customer_id, has_more, result: :written | :unchanged}`
  (the `:unchanged` value makes a processed-but-no-op redelivery observable **without** a ledger
  row). **Reuse** `[:accrue, :webhooks, :stale_event]` (`object_type: :entitlement_summary`) — do
  not invent a variant. Orphan: `[:accrue, :webhooks, :orphan_entitlement_summary]`. Ops event
  **`[:accrue, :ops, :entitlement_summary_truncated]`** fired **only when `has_more: true`** (a
  curated "this cache is known-incomplete" signal) — **not** a per-sync heartbeat (routine syncs
  are firehose, not ops). All dims allowlist-safe (IDs + counts); keep `entitlement_count`/
  `has_more` **telemetry-only** (do NOT widen the OTel `@allowed_attributes` allowlist for them —
  bounded/no-PII but keep the OTel surface lean). Never log the raw summary (V7).

### Provider honesty
- **D-10 — Capability matrix: new row, never mutate convergence.** Add a **NEW**
  `entitlements.stripe_native_sync` row (stripe: `native (advisory/observational)`;
  braintree/fake: `unsupported` / out-of-slice). **NEVER** edit the existing
  `entitlements.local_mapping` convergence row — the negative drift guard in
  `verify_processor_support_matrix.sh` fails the build if an `entitlements.*` row sprouts a
  native/unsupported/bounded label there. Same-PR SSOT co-update (code labels +
  `processor-support-matrix.md` + drift gate).

### Surfacing (data exposed, UI deferred)
- **D-11 — Read-only core seam now; admin LiveView panel deferred.** Expose the observational
  cache via a read-only core function (sibling to `Accrue.Entitlements.Admin.resolve_for_customer/1`
  at admin.ex:47, `@doc false`, one-way admin→billing) so the cache is programmatically
  inspectable **without** touching the gate. The **rendered `accrue_admin` "Stripe-native
  (advisory)" panel is DEFERRED** — keeps Phase 127 isolated to core `accrue` (zero accrue_admin
  changes); admin UI is ENT-11 territory (already shipped). It's the natural cheap follow-up.

### Docs
- **D-12 — Docs.** Extend `accrue/guides/entitlements.md`: the eventual-consistency window, the
  10-entitlement inline cap, the deferred 1.2 paginated read, enable steps (config +
  host-owned Stripe Dashboard event-enable), and the plain "advisory = observational, does not
  change `entitled?`" statement. Catalog the new telemetry/ops events in `guides/telemetry.md`.
  Extend `scripts/ci/verify_package_docs.sh` needles. Add a
  `StripeFixtures.entitlement_summary_event/2` test helper (clone `webhook_event/3`).

### Claude's Discretion
- Exact module placement for the cache read/seam logic (a new `Accrue.Entitlements.StripeSync`
  module vs. a sibling fn in `Accrue.Entitlements.Admin`) — planner decides; keep one-way
  admin→billing and the gate path cache-free either way.
- Exact changeset function names, migration timestamp, and whether the reducer lives as a private
  clause in `DefaultHandler` vs. a small delegated helper module — planner decides.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase research & requirements (read first)
- `.planning/phases/127-optional-stripe-native-sync-isolated-off-by-default/127-RESEARCH.md` — the
  deep technical research (patterns, payload shape, pitfalls, validation architecture, sources).
  Build on it; the decisions above resolve its Open Questions Q1-Q5.
- `.planning/ROADMAP.md` — Phase 127 goal + SC#1-4 + milestone "isolated last, must not block core".
- `.planning/REQUIREMENTS.md` — ENT-10.

### Project research (binding inputs)
- `.planning/research/PITFALLS.md` — the "advisory/secondary overlay, NOT a separate truth" stance
  (lines ~75, 84, 110, 133) that D-01 follows.
- `.planning/research/ARCHITECTURE.md` — resolver seam + webhook pipeline shape.
- `.planning/research/STACK.md` — no-new-dep confirmation.
- `.planning/seeds/SEED-002-ecosystem-integrations.md` — future ecosystem bridges (Threadline
  audit, Sigra/Lockspire scopes); **not** this milestone — cross-reference only.

### Idiomatic / DX deep-research corpus (sibling lib `prompts/`)
- `/Users/jon/projects/lattice_stripe/prompts/payments_domain_field_guide.md`
- `/Users/jon/projects/lattice_stripe/prompts/elixir-best-practices-deep-research.md`
- `/Users/jon/projects/lattice_stripe/prompts/elixir-opensource-libs-best-practices-deep-research.md`
- `/Users/jon/projects/lattice_stripe/prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`
- `/Users/jon/projects/lattice_stripe/prompts/stripe-explanation-domain-language-deep-research.md`

### Accrue guides / contracts to extend
- `accrue/guides/entitlements.md` · `accrue/guides/telemetry.md` · `accrue/guides/lifecycle_semantics.md`
- `.planning/processor-support-matrix.md` (+ `scripts/ci/verify_processor_support_matrix.sh`)
- `scripts/ci/verify_core_liveview_runtime_free.sh` (isolation-gate clone target),
  `scripts/ci/verify_package_docs.sh` (doc-needle gate)

### Stripe (external)
- https://docs.stripe.com/billing/entitlements — summary payload, 10-inline cap, `has_more`/`url`,
  persist-and-reconcile guidance.
- https://docs.stripe.com/webhooks — no delivery-order guarantee.
- https://docs.stripe.com/api/entitlements/active-entitlement/list — the DEFERRED 1.2 read.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (clone, don't reinvent)
- `accrue/lib/accrue/webhook/default_handler.ex` — `check_stale/2`, `reduce_row/5`,
  `stamp_watermark/3`, dual atom/string `get/2`, `orphan_charge` telemetry, `record_event/5`.
- `accrue/lib/accrue/billing/subscription_schedule.ex:36-51` — the **schema clone target**
  (thin projection: `data :map` + typed columns + `last_stripe_event_ts/_id` + `lock_version`
  + force changeset + `optimistic_lock`/`unique`/`foreign_key` constraints).
- `accrue/lib/accrue/events.ex:109-154` — `Accrue.Events.record/1` + `idempotency_key` UNIQUE
  partial-index dedup (D-08).
- `accrue/lib/accrue/telemetry/ops.ex` — `emit/3` + `connect_account_deauthorized` (the ops-event
  model for D-09); `accrue/lib/accrue/telemetry/otel.ex` — `@allowed_attributes` / `@prohibited_keys`.
- `accrue/lib/accrue/entitlements/admin.ex:47` — `resolve_for_customer/1` read-seam precedent (D-11).

### Established Patterns (constrain this phase)
- **Fail-closed contract** (`entitlements.ex`): the sole path to `true` is a resolved local
  match — D-01 preserves this absolutely (cache never on the gate path).
- **Zero-cost off-lane** (`resolver/local_map.ex` `none_lane_items/1` for `past_due_grace: :none`)
  — the runtime-gate precedent for D-04.
- **Config enum + raw-read accessor** (`config.ex` `unmapped_action`:390 / `past_due_grace`:421,770)
  — the precedent for D-03.
- **Isolated, well-documented handler with explicit out-of-order semantics**
  (`accrue/lib/accrue/webhook/connect_handler.ex`) — model for documenting WHY this path uses the
  monotonic-snapshot guard (no refetch-canonical: lattice_stripe 1.1 has no Entitlements API).

### Integration Points
- Webhook ingress is **unchanged** (type-agnostic `Plug → Ingest → DispatchWorker`); the summary
  event already flows to `DefaultHandler` via the existing path. New code = a config-gated dispatch
  clause + reducer + the new schema/migration + read seam + CI gate + docs.
- `Resolver.__impl__/0` and `LocalMap` are **NOT touched** (D-01).

</code_context>

<specifics>
## Specific Ideas

- The two `entitlements.*` spans must read as a deliberate mirror of the ENT-05 split:
  `[:accrue, :entitlements, :check]` (per-decision, telemetry-only) and
  `[:accrue, :entitlements, :sync]` (state-change, ledger+telemetry).
- Telemetry `result: :unchanged` is the chosen mechanism for "we processed a redelivery and
  nothing changed" visibility without an audit row — operators get the signal; the ledger stays clean.
- Capability label wording: `native (advisory)` / `native (observational)` so the matrix is honest
  that Stripe-native sync exists but does not gate.

</specifics>

<deferred>
## Deferred Ideas

- **Gate-influencing overlay** (additive union: `entitled?` true if local **OR** cached-Stripe
  grants, never denies) — a future **non-breaking** opt-in via a new enum value (e.g.
  `stripe_native_sync: :influence`). Only if a real need surfaces; D-01 deliberately reserves the
  room without taking on the eventual-consistency authorization surface now.
- **Full paginated entitlement reconcile** (startup/periodic `GET /v1/entitlements/active_entitlements`
  read; the proper fix for missed-webhook staleness and >10-cap completeness) — deferred to
  `lattice_stripe ≥ 1.2` via a future `stripe_native_sync: :reconcile` enum value. (Already a
  milestone Deferred Item.)
- **Rendered `accrue_admin` "Stripe-native (advisory)" read-only panel** — cheap follow-up (the
  read seam from D-11 already exposes the data); out of ENT-10's strict scope, keeps Phase 127
  isolated to core `accrue`.
- **SEED-002 ecosystem integrations** (Threadline audit bridge, Sigra/Lockspire entitlement
  scopes) — a separate seed / future milestone, not this phase.

</deferred>

---

*Phase: 127-optional-stripe-native-sync-isolated-off-by-default*
*Context gathered: 2026-05-24*
