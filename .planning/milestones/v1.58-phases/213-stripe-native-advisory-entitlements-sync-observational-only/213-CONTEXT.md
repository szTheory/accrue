# Phase 213: Stripe-native advisory entitlements sync (observational-only) - Context

**Gathered:** 2026-07-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the Phase 127 "optional Stripe-native entitlements sync" deferral by wiring an **opt-in, client-backed PULL/REFRESH path** that fetches a customer's active Stripe entitlements via the 2.x `LatticeStripe.Entitlements.*` surface and writes them into the **existing** advisory `Accrue.Billing.EntitlementSummary` cache — proving by test that the sync can **never** become a grant gate and that the isolation guard now covers the new surface. Requirements: **SYNC-01, SYNC-02, SYNC-03, SYNC-04, SYNC-05**.

**Inviolable (locked upstream, not re-litigated):**
- **Observational-only (D-01/D-11).** The advisory cache is written + surfaced for diagnostics ONLY; it is **never** read by the resolver/guard grant path. `accrue/lib/accrue/entitlements/resolver/local_map.ex` stays the single canonical, fail-closed, local gate.
- Gate seam is the **existing** `config :accrue, :entitlements, stripe_native_sync: :advisory` (default `:disabled`). The same seam turns on both the webhook path and the new pull path.

**Out of scope this phase:** anything authoritative-for-grant (permanently out by architecture); new **required** deps; admin redesign / new rooms / new nav; `accrue_portal` work; docs/CLAUDE.md/JTBD reconciliation (that is Phase 214 / DOCS-*); pinning `~> 2.1` or chasing 2.1-only features.

</domain>

<decisions>
## Implementation Decisions

These decisions were produced by four parallel domain advisors (one per gray area: fetch seam, invocation surface, D-07, list→summary write), each briefed with the same locked-constraints spine and told to cohere with the others. The maintainer asked for a decisive one-shot package rather than adjudicating each fork. They form one coherent design; they are locked defaults for the researcher/planner unless the maintainer overrides. **One item (D-11) carries genuine correctness risk against existing concurrency code and is explicitly marked researcher-verify, not blind-lock.**

### Fetch seam — how the client-backed pull is wired (SYNC-01, SYNC-05)

- **D-01:** Add ONE new `Accrue.Processor` behaviour callback: `list_active_entitlements(id(), opts()) :: {:ok, [map()]} | {:error, Exception.t()}`, where `id()` is the customer's `processor_id`. It returns a **complete, materialized list of plain string-keyed maps** (`%{"id" => _, "object" => _, "feature" => _, "lookup_key" => _, "livemode" => _}`), mirroring the webhook `entitlements.data.data` element shape so the write path reuses existing pair-extraction logic. Naming/shape mirrors the existing `list_charges/2` / `list_payment_methods/2` callbacks (consumer-perspective least surprise). — **Reversibility:** costly — adds to the published `Accrue.Processor` behaviour contract (mitigated by D-02).
- **D-02:** Declare the new callback in `@optional_callbacks` (like the Connect callbacks already are) so existing custom-processor implementers — and the `Braintree` adapter, which has no Stripe entitlements — are not force-broken by a newly-required callback.
- **D-03:** The **only** file that touches `LatticeStripe` is `accrue/lib/accrue/processor/stripe.ex` — this is a **CI-enforced facade boundary** (its moduledoc lines 12-19; a test scans `lib/accrue/**/*.ex` and fails on any `LatticeStripe` ref outside `stripe.ex` + `stripe/error_mapper.ex`). This decisively eliminates any "call `LatticeStripe.Entitlements.ActiveEntitlement.stream!` directly from `StripeSync`" option. The Stripe impl calls `ActiveEntitlement.stream!(client, %{"customer" => id, "limit" => "100"}, opts)` and **drains it fully** (`Enum.map(&to_plain_map/1)`) — `stream!` follows `has_more` and **raises on a partial page**, so the drain converts truncation into an all-or-`{:error}` boundary. A successful pull is therefore **always complete** (the truncation footgun — a customer with >10 entitlements looking unentitled — cannot occur). `LatticeStripe.Error` is rescued → `ErrorMapper.to_accrue_error/1` like every other callback. (The summary object has no HTTP endpoint — webhook-only — so the pull streams `ActiveEntitlement`s directly; there is nothing to "retrieve".)
- **D-04:** The `Fake` processor (`accrue/lib/accrue/processor/fake.ex`) gets an `entitlements` map in its `%State{}` keyed by customer `processor_id`, a `put_entitlements/2` seed helper, and the callback returning the seeded list (or `[]`). This is what makes **SYNC-05 provable with no live Stripe, no Chrome, fully `async`** via the same named-GenServer + per-test `reset/0` machinery every other Fake callback uses. (CLAUDE.md mandate: Fake Processor over mocking lattice_stripe.)

### Invocation surface — how the refresh is triggered (SYNC-01, SYNC-02)

- **D-05:** The single source of truth is a public domain primitive on the existing observational seam: `Accrue.Entitlements.StripeSync.refresh(customer, opts \\ [])`. Reconciled return contract (merging both advisors): `{:ok, EntitlementSummary.t()}` on write · `{:ok, :disabled}` when the config seam is off · `{:ok, :unchanged}` on a stale/idempotent re-pull with no material change · `{:error, term()}` on pull/write failure. — **Reversibility:** costly — a new public function ships to adopters; removing it later is a breaking change (additive now, safe).
- **D-06:** **Config-off no-op guarantee.** `refresh/2`'s first executable line is `if Accrue.Config.stripe_native_sync?()`, returning `{:ok, :disabled}` **before any Processor callback or Repo touch** — a byte-for-byte mirror of the webhook path's early return at `default_handler.ex:314`. When the seam is off, the refresh path performs zero I/O.
- **D-07:** Ship a **thin** Oban wrapper `Accrue.Entitlements.StripeSync.RefreshWorker` (`use Oban.Worker`) whose `perform/1` just calls `refresh/1` (inherits the config-off no-op). It defaults to the **already-documented `accrue_webhooks` queue** — introduces **no new queue** and no new host wiring; Accrue never starts Oban, so it is simply inert until the host runs that queue (same contract as the existing webhook `DispatchWorker`). This gives hosts an out-of-the-box way to keep the live pull off the request path (the Pay/Cashier footgun: `sync!`/`syncStripeData` are synchronous and devs eat latency calling them in a controller).
- **D-08:** The refresh entry point lives on `Accrue.Entitlements.StripeSync` and is **deliberately NOT added to the top-level `Accrue` facade** — the `Accrue` facade is the *gate* story (`entitled?/2`, `has_active_plan?/2`); a diagnostic sync seam there would invite the exact "does refresh feed grants?" misread that observational-only forbids.
- **D-09:** Telemetry: reuse `Accrue.Telemetry.span([:accrue, :entitlements, :sync], meta, fn -> ... end)` so start/stop/**exception** come free on this public entry point, and the write emits the existing `[:accrue, :entitlements, :summary_synced]` event tagged `source: :pull` so operators can distinguish pull- from webhook-provenance in one stream.
- **D-10 (scope line):** **IN** = `refresh/2` primitive + `RefreshWorker` thin wrapper + `source: :pull` telemetry, reusing existing span/event/queue. **DEFERRED** = admin "refresh now" button (keeps the ENT-11 tab read-only, avoids the admin-redesign fence — becomes a later 1-liner once the primitive exists), cron/scheduled poll-all reconcile (poll-storm / host-burden / out of "minimal"), and a top-level `Accrue.refresh_entitlements/1` facade delegate.

### List→summary write reconciliation (SYNC-01, SYNC-05)

- **D-11 (⚠ researcher-verify, not blind-lock — the one correctness-risk item):** A pull yields a *list*; the cache row is *summary-shaped*. Column mapping: `entitlement_count = length(list)`; `truncated = false` **always** (stream is exhaustive by construction); `synced_at = Accrue.Clock.utc_now()`; `data` (jsonb) = a **reconstructed summary-shaped map** (`object: "entitlements.active_entitlement_summary"`, `customer`, `livemode`, `entitlements: %{object: "list", has_more: false, url: ActiveEntitlement.list_path(), data: [wire maps]}`, plus an `"_accrue" => %{source: "pull", ...}` provenance stamp) so the existing material-change detection + `entitlement_pairs/1` keep working unchanged across webhook↔pull; `stripe_customer_id = customer.processor_id`; `livemode` from the streamed entitlements (reuse `livemode_for_upsert/2`). **The pull carries `last_stripe_event_ts`/`last_stripe_event_id` forward untouched — a poll has no Stripe event and must never advance or wipe the event watermark** (the webhook path's `check_stale/2` pre-filter and WR-02 carry-forward must stay correct after any pull).
    - **The ordering question — direction LOCKED, mechanism to verify.** A pull and a webhook must compose so that: (a) a stale pull never clobbers a strictly-newer webhook; (b) a webhook is never dropped because a pull ran; (c) concurrent pull+webhook can't corrupt the row (respecting ADV-01: `on_conflict` WHERE is the sole guard, no OCC). The advisor's recommended mechanism is to **unify the DB `on_conflict` monotonicity guard on `synced_at` for BOTH writers** (webhook already sets `synced_at = synced_at_from_event(evt_ts) ≡ evt_ts`, so webhook-vs-webhook ordering is unchanged), replacing the current `last_stripe_event_ts` axis at `default_handler.ex:720-721`. **This is code-only, no schema change.** — **Reversibility:** costly — this edits correctness-critical concurrency code (the existing WR-02/ADV-02/ADV-03 null-watermark reasoning is built around the `last_stripe_event_ts` axis; the `synced_at_from_event/1` fallback to `now()` on a timestamp-less event is a real edge that the flip changes). **The researcher/planner MUST re-derive the flip against WR-02/ADV-02/ADV-03 and the null-evt_ts edge before adopting it.** Fallback if the flip proves unsafe: keep `last_stripe_event_ts` as the webhook axis and derive a composable ordering for the pull that does not touch the webhook guard.
- **D-12:** **Extract one shared writer.** Factor `write_entitlement_summary/*` + `upsert_entitlement_summary/*` out of `Accrue.Webhook.DefaultHandler` into a shared module (advisor suggests `Accrue.Entitlements.Reconcile`; exact name is Claude's discretion). Idiomatic Elixir: one write path, two callers — the webhook handler builds attrs from the event, `refresh/2` builds attrs from the streamed list (`provenance: :pull`). The isolation guard forbids the **gate** path from referencing this; a webhook+pull shared writer is explicitly allowed.
- **D-13:** **No migration.** Provenance (`:pull | :webhook`) lives in the `data["_accrue"]` jsonb stamp surfaced by the `StripeSync` read seam. An additive `source` column is rejected — it buys nothing correctness needs, and any migration ships to every adopter (preserves the v1.58 "major dep bump, no adopter pain" posture).

### D-07 `fetch_entitled/2` resolution (SYNC-04)

- **D-14:** **CLOSE (reject), not merely defer.** Do **not** add any `fetch_entitled/2`-style function. Replace the `admin.ex` moduledoc line that currently says the question "stays deferred" with a recorded **closure**: `fetch_entitled/2` is CLOSED / will-not-be-built, because a Stripe-backed `entitled?`/`fetch_entitled` predicate makes an authorization decision behind a network call, which **fails OPEN under network partition** (lattice_stripe's `ActiveEntitlement` moduledoc warning) and contradicts Accrue's fail-closed local canonical gate (D-01/D-11). Its only non-gate value — observing what Stripe last reported — is already served observationally by `Accrue.Entitlements.StripeSync.summary_for_customer/1` (advisory cache, now populated by this phase's refresh) and by `Admin.resolve_for_customer/1`'s `{resolved, unmapped}` diagnostic. Even a *non-predicate* named `fetch_entitled` is a naming trap (a consumer reaching for a gate grabs it and treats the result as authorization). Mirror the same one-liner in `accrue/guides/entitlements.md`. This is a **doc/moduledoc-only change** — no new function, no gate-path edit — so it needs **no** change to the isolation guard and cannot trip it. — **Reversibility:** reversible (docs) but intentionally permanent. Note: SYNC-04's literal wording allows "implement OR defer"; "close" is the stronger, unambiguous form of defer and satisfies "no ambiguity remains" — the maintainer may soften to "defer" if they prefer to leave the door open.

### Isolation guard extension (SYNC-03)

- **D-15:** Extend `scripts/ci/verify_entitlement_sync_isolation.sh`'s forbidden-token alternation from `(EntitlementSummary|StripeSync|accrue_entitlement_summaries|stripe_native_sync)` to also include the **new client-fetch entry symbol `list_active_entitlements`** and the shared-writer symbol (`Reconcile`, or whatever D-12 names it). Any future gate-path file (`entitlements.ex`, `resolver.ex`, `resolver/local_map.ex`) that calls the pull entry point then fails CI at merge — the exact "a deliberately-wired `gate → seam` edge on the new client-fetch entry point makes the script fail" proof SYNC-03 demands. Add a matching **negative-path assertion** to the guard's test (`PackageDocsVerifier`-style or the script's own test) so the new token is proven live (fails on a wired edge), not merely present in the regex.

### Claude's Discretion
- Exact name/location of the shared writer module (`Accrue.Entitlements.Reconcile` vs folding into `StripeSync`) — planner's call, so long as it is off the gate path and covered by D-15.
- Exact telemetry meta keys and the internal `data["_accrue"]` provenance key name/shape.
- Whether `refresh/2` returns `{:ok, :unchanged}` vs `{:ok, row}` on an idempotent no-material-change re-pull (as long as it never emits a duplicate ledger row).
- Exact wording of the D-14 closure one-liner in `admin.ex` + the guide, provided it reads as *decided/closed*, not *postponed*.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope & requirements (binding)
- `.planning/REQUIREMENTS.md` — SYNC-01..05 full text, the D-01/D-11 observational-only invariant, and the "Out of Scope" exclusions.
- `.planning/ROADMAP.md` — Phase 213 goal + the five success criteria; v1.58 scope fence.
- `.planning/seeds/SEED-005-lattice-stripe-entitlements-bump.md` — origin of the bump/sync; breadcrumbs to the existing seam files.
- `.planning/phases/212-*/212-CONTEXT.md` — the completed 2.x bump decisions (D-01..D-11 there) this phase builds on; confirms `~> 2.0` resolves to lattice_stripe **2.1.0**.

### Existing seam & gate code (the surface being extended)
- `accrue/lib/accrue/entitlements/stripe_sync.ex` — the read-only observational seam (`summary_for_customer/1`); the home for the new `refresh/2` primitive.
- `accrue/lib/accrue/entitlements/admin.ex` — the ENT-11 diagnostic seam; the D-07 `fetch_entitled/2` deferral line to rewrite as a closure (D-14).
- `accrue/lib/accrue/entitlements/resolver.ex`, `resolver/local_map.ex`, `guard.ex`, `entitlements.ex` — the ALWAYS-ON, local, fail-closed gate path the pull must never touch.
- `accrue/lib/accrue/billing/entitlement_summary.ex` — the advisory cache schema (`force_changeset/2`; ADV-01 no-OCC; `truncated`/`synced_at`/`last_stripe_event_ts,id` semantics; one-row-per-customer upsert target).
- `accrue/lib/accrue/webhook/default_handler.ex` — the existing webhook write path to extract/share (`reduce_entitlement_summary` → `write_entitlement_summary` → `upsert_entitlement_summary`, the `on_conflict` guard at ~720, `synced_at_from_event/1` at ~750, `stamp_summary_watermark/4`, `livemode_for_upsert/2`, the config-off early return at ~314).

### Processor seam (the fetch callback lives here)
- `accrue/lib/accrue/processor.ex` — the behaviour + `@optional_callbacks`; add `list_active_entitlements/2` (model on `list_charges/2` at ~202).
- `accrue/lib/accrue/processor/stripe.ex` — the CI-enforced `LatticeStripe` facade (moduledoc lines 12-19); `build_client!/1`; the only impl allowed to call `ActiveEntitlement.stream!`.
- `accrue/lib/accrue/processor/fake.ex` — add the `entitlements` state + `put_entitlements/2` seed + callback (SYNC-05 test seam).
- `accrue/lib/accrue/processor/braintree.ex` — must stay green with the callback optional (no Stripe entitlements).
- `accrue/lib/accrue/config.ex` (~527, ~961-979) — the `stripe_native_sync` seam (`stripe_native_sync?/0`).

### lattice_stripe 2.x entitlements API (the pull surface)
- `accrue/deps/lattice_stripe/lib/lattice_stripe/entitlements/active_entitlement.ex` — `list/3`, `stream!/3` (requires `"customer"`, limit default 10/max 100, raises on partial), `retrieve/3`, `list_path/0`; the authoritative "no `entitled?` helper — gate locally, fail closed" warning underpinning D-14.
- `accrue/deps/lattice_stripe/lib/lattice_stripe/entitlements/active_entitlement_summary.ex` — webhook-only (no HTTP retrieve); `stream_entitlements!/3`; the URL-rewrite + truncation notes.

### Isolation guard (SYNC-03)
- `scripts/ci/verify_entitlement_sync_isolation.sh` — the gate→seam merge gate to extend (D-15) + its test.

### Ecosystem best-practices (advisor sources — informative)
- `accrue/guides/entitlements.md`, `../lattice_stripe/guides/entitlements.md` — the "reconcile from the list, gate locally, fail closed" story; where the D-14 guide-mirror goes.
- `accrue/prompts/accrue-best-practices-deep-research-independent.md`, `accrue/prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` — Accrue architecture DNA / facade + reconcile patterns.
- `../lattice_stripe/prompts/elixir-best-practices-deep-research.md`, `phoenix-best-practices-deep-research.md`, `elixir-opensource-libs-best-practices-deep-research.md`, `payments_domain_field_guide.md` — behaviour design, library-Oban usage, reconcile-vs-webhook write ordering.
- `.planning/research/JTBD-FRONTIER.md`, `.planning/research/PITFALLS.md` — entitlements JTBD + the fail-open / stale-cache pitfalls (T-127-09).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Entitlements.StripeSync` already exists as the sole observational read seam — extend it with `refresh/2` rather than creating a new module.
- The webhook write core (`write_entitlement_summary`/`upsert_entitlement_summary` + the monotone `on_conflict` upsert + `livemode_for_upsert/2` + `entitlement_pairs/1` material-change detection) is directly reusable — extract into a shared writer (D-12), don't duplicate.
- The `Accrue.Telemetry.span/3` + the existing `[:accrue, :entitlements, :sync]` / `[:accrue, :entitlements, :summary_synced]` events already exist — reuse with a `source:` tag.
- The `Fake` processor's named-GenServer + `reset/0` per-test machinery is the ready-made SYNC-05 async test harness.
- The existing `accrue_webhooks` Oban queue is the documented home for `RefreshWorker` — no new queue.

### Established Patterns
- **CI-enforced `LatticeStripe` facade** — all Stripe SDK calls go through `processor/stripe.ex` only; every network op is a `Processor` behaviour callback with a `Fake` twin. The pull MUST follow this (D-01/D-03).
- **Config-off early return before any I/O** — the webhook path checks `stripe_native_sync?()` first; the pull mirrors it exactly (D-06).
- **Observational-only one-way dependency** — `seam → billing read`, never `gate → seam`; enforced by the static isolation script (D-15).
- **Monotone upsert, no OCC (ADV-01/02/03)** — `on_conflict` WHERE is the sole concurrency guard; the pull must respect it, not add optimistic locking.

### Integration Points
- New `Accrue.Processor` callback ↔ `stripe.ex` (real) + `fake.ex` (test) + `braintree.ex` (optional/no-op via `@optional_callbacks`).
- `StripeSync.refresh/2` ↔ the new processor callback ↔ the shared writer ↔ `EntitlementSummary` upsert.
- `RefreshWorker` (Oban) ↔ `refresh/1`.
- Isolation script ↔ the new pull-entry + shared-writer symbols.

</code_context>

<specifics>
## Specific Ideas

- Reconciled `refresh/2` return contract: `{:ok, EntitlementSummary.t()} | {:ok, :disabled} | {:ok, :unchanged} | {:error, term()}`.
- New callback signature: `@callback list_active_entitlements(id(), opts()) :: {:ok, [map()]} | {:error, Exception.t()}` (declared `@optional_callbacks`).
- SYNC-05 test must assert (from success criterion #5): the cache populates correctly from `LatticeStripe.Entitlements.*` (Fake-seeded) results; a grant decision is **identical** whether the advisory cache is empty, stale, or directly contradicts the local plan→feature map (proves it is never a gate); and the config defaults to off. Fully `async`, no live Stripe, no Chrome.

</specifics>

<deferred>
## Deferred Ideas

- **Admin "refresh now" button** on the ENT-11 entitlements tab — a later 1-liner over `refresh/1` once the primitive exists; deferred to keep the tab read-only and avoid the admin-redesign fence (SEED-004 M2/M3 territory).
- **Scheduled/cron poll-all reconcile** — deferred (poll-storm, host-burden, out of the "minimal" fence; contradicts opt-in advisory intent).
- **Top-level `Accrue.refresh_entitlements/1` facade delegate** — deferred to keep the `Accrue` facade the gate story, not a sync seam.
- **Paginated `entitlements.url` reconcile for the webhook `truncated` case** — the pull already fully cures truncation; the deferred webhook-side paginated reconcile (from the schema's D-07 note) remains a separate future consideration.

</deferred>

---

*Phase: 213-stripe-native-advisory-entitlements-sync-observational-only*
*Context gathered: 2026-07-30*
