# Pitfalls Research

**Domain:** Entitlements / plan-gating layered onto an existing Elixir/Phoenix billing library (Accrue v1.39)
**Researched:** 2026-05-22
**Confidence:** HIGH (codebase-grounded: lifecycle predicates, auth behaviour, telemetry/events contracts read from source; Stripe Entitlements eventual-consistency confirmed via official docs)

> Scope note: these are pitfalls **specific to adding a gate layer** on top of subscription state Accrue already holds. Accrue is feature-complete on billing core (per `research/JTBD-FRONTIER.md`); entitlements is a thin, high-leverage layer, and the danger is precisely that "thin" tempts shortcuts that fail-open, lag reality, or quietly diverge per-provider. Phase numbers below assume the v1.39 plan starts at **Phase 123** (per `PROJECT.md`); the milestone's seven target areas map to roughly: gate-API core, plug guard, LiveView `on_mount` guard, provider-honest matrix + Stripe sync, admin surface, docs. Adjust to the actual roadmap split.

## Critical Pitfalls

### Pitfall 1: Fail-open gating (default-allow on error or unknown plan)

**What goes wrong:**
`entitled?/2` (or `has_active_plan?/2`) returns `true` — or the plug/`on_mount` guard lets the request through — when it *couldn't actually determine* entitlement: the subscription query errored, the plan→feature map had no entry for the customer's plan, the Stripe summary fetch timed out, or the billable was `nil`. A paying-tier feature silently leaks to free/lapsed users. Worse than a billing bug because it's a revenue leak that no error surfaces.

**Why it happens:**
Three idioms in this codebase make fail-open the *accidental* path:
1. Elixir truthiness — `if entitled?(user, :pro), do: ...` treats any non-`false`/non-`nil` as allowed. A function that returns `{:error, reason}` on a query failure is **truthy**, so the gate opens.
2. The existing dev-permissive `Accrue.Auth.Default` returns a stubbed `%{id: "dev"}` user — copying that "be permissive in dev" instinct into entitlements would be catastrophic in prod.
3. An unmapped plan ("the customer is on `price_legacy_2019` which isn't in the host's feature map") naturally falls through to a `nil`/empty-feature lookup that some implementations treat as "no restriction = allow."

**How to avoid:**
- Make the gate a **two-value boolean** (`true`/`false` only) and define `entitled?/2` so the **only** path to `true` is an affirmative, fully-resolved match. Every error tuple, `nil` billable, missing map entry, exception-rescue, and timeout collapses to `false`. Document this as a hard contract in the moduledoc the way `Subscription` documents "use the predicates, not raw `.status`."
- Provide a separate `entitled/2` (or `check_entitlement/2`) that returns `{:ok, true} | {:ok, false} | {:error, reason}` for callers who need to *distinguish* "denied" from "couldn't check" (e.g., to show a "billing temporarily unavailable, try again" page rather than a hard paywall). But the **ergonomic, doc-front-and-center** function (`entitled?/2`) must be the fail-closed boolean. Make the safe default the easy path.
- Rescue exceptions inside the gate, emit a telemetry denial/`:exception` event, then return `false` — never let an exception bubble into a 500 a host might rescue-and-continue.
- Property-test (the project already mandates `stream_data` for money math) that for *all* generated error/edge inputs, `entitled?/2 == false`. A single "fuzz the inputs, assert never-true-on-garbage" property is the strongest guard here.

**Warning signs:**
- `entitled?/2` has a function head returning anything other than `true`/`false`.
- Tests only assert the happy "subscribed → true" path; no test asserts "errored repo → false," "unknown plan → false," "nil user → false."
- Code review sees `case entitled?(...) do {:error, _} -> ...` — the gate leaks error tuples, so it's not a clean boolean.
- A `dev`/`test` branch inside the entitlement resolver.

**Phase to address:**
Gate-API core phase (first entitlements phase, ~Phase 123). Foundational contract; plug, LiveView, and admin all inherit it. Bake the fail-closed property test into that phase's exit criteria.

---

### Pitfall 2: Entitlement truth not mapped onto Accrue's existing lifecycle predicates

**What goes wrong:**
The gate re-derives "is this customer entitled" from raw `subscription.status == :active`, or from the Stripe summary, instead of reusing `Accrue.Billing.Subscription` predicates — and gets the lifecycle edge states wrong:
- **`canceling` (cancel-at-period-end, still in paid window):** `status` is `:active` with `cancel_at_period_end: true`. If you gate on `cancel_at_period_end == false`, you wrongly **revoke access the customer already paid for** until period end. (`canceling?/1` exists for exactly this.)
- **`trialing`:** a trial customer has full access. A literal `status == :active` check wrongly denies trials. (`active?/1` already includes `:trialing`.)
- **`past_due`/`unpaid`:** is a past-due customer still entitled? A *product decision Accrue must surface, not silently make*. Stripe keeps a `past_due` sub active-adjacent during dunning; instant revoke is hostile, never revoking is a leak. The grace overlay already exists (`Dunning`, `dunning_sweepable?/1`, `past_due_since`).
- **`paused`:** `pause_collection` set → typically not entitled, but legacy `:paused` status and modern `pause_collection` map are two shapes (`paused?/1` covers both).
- **`incomplete_expired`:** terminated but `status != :canceled` — `canceled?/1` covers it; a naive `status == :canceled` check misses it and **leaves access on**.

**Why it happens:**
The entitlement layer is new and there's a temptation to compute its own truth from `status` strings or from the Stripe summary, not realizing Accrue already encoded all these edges in `Subscription` predicates + `Billing.Query` fragments. `lifecycle_semantics.md` *explicitly* states `active` = "counts for entitlement purposes" and includes trialing — but a module written in isolation won't honor it.

**How to avoid:**
- Build the resolver **on top of** `Subscription.active?/1`, `canceling?/1`, `past_due?/1`, `paused?/1`, `canceled?/1` and the matching `Billing.Query` fragments — never raw `.status`. "Is there a billing-active subscription" is already solved; entitlements only adds "...and does that sub's plan include feature X."
- Author an explicit **lifecycle→entitlement truth table** in `guides/entitlements.md`, pinned to `lifecycle_semantics.md`'s state glossary. Recommended default: `active`/`trialing`/`canceling` → **entitled**; `paused`/`ended`/`incomplete_expired`/`canceled` → **not entitled**; `past_due` → **entitled during grace window, not entitled after** (reuse the dunning grace overlay; don't invent a second clock).
- Make the `past_due` policy a **documented host-configurable knob** (e.g., `:entitle_past_due?` / grace days) with a fail-safe default, not a hardcoded choice — and emit telemetry when a `past_due` sub is granted on grace so operators see it.
- Add a `Billing.Query.entitling/1` fragment (or reuse `active/1` + grace) so admin/multi-customer queries use the *same* semantics as the per-request predicate. Divergence between the row query and the predicate is its own bug class.

**Warning signs:**
- The entitlements module imports/aliases nothing from `Accrue.Billing.Subscription` or `Accrue.Billing.Query`.
- Any `where: s.status == :active` (without the `cancel_at_period_end`/`ended_at` nuance) in entitlement code.
- No test for "cancel_at_period_end but still in paid window → still entitled" or "trialing → entitled."
- `guides/entitlements.md` describes states without cross-linking `lifecycle_semantics.md`.

**Phase to address:**
Gate-API core phase. The truth table is the spec; reuse-the-predicates is the implementation rule. Single highest-leverage correctness decision in the milestone.

---

### Pitfall 3: Staleness — gating on local projection that lags the processor (and Stripe summary eventual consistency)

**What goes wrong:**
Access reflects the *last webhook Accrue processed*, not live reality:
- Customer upgrades → Stripe charges them → but `customer.subscription.updated` hasn't landed/been dispatched yet (Accrue's path is verify→persist→**enqueue (Oban)**→200, so projection updates *asynchronously after* the 200). For a window the customer paid for Pro but `entitled?(:pro)` is still `false`. They see a paywall for what they just bought.
- Customer downgrades/cancels → webhook lags → they keep premium access (a leak, milder than #1 because it self-heals).
- **Stripe's `entitlements.active_entitlement_summary.updated` is itself eventually consistent**: Stripe explicitly recommends *persisting* the summary locally rather than fetching on demand, and the summary can arrive after the subscription change that caused it. Syncing entitlements from that webhook adds a *second* lagging source on top of the subscription projection.

**Why it happens:**
The v1.39 pitch is "gate on subscription state Accrue already holds locally" — correct and fast, but local state is a *projection* that converges, not an instantaneous mirror (`lifecycle_semantics.md` "Convergence and local truth" says exactly this). Developers reason about it as if it were live.

**How to avoid:**
- **Embrace local projection as the gating truth, on purpose, and document the convergence window.** Don't paper over it with a per-request live Stripe call (Pitfall 4). The answer is: gate locally + minimize the gap + make the gap recoverable.
- **Minimize the gap:** put entitlement-relevant webhooks (`customer.subscription.created/updated/deleted`, `entitlements.active_entitlement_summary.updated`) in a **fast Oban queue** with sane concurrency (project documents `accrue_webhooks: 10`), with the projection write in the dispatch worker, not deferred further.
- **Close the upgrade window deliberately:** when the host *initiates* an upgrade via `Accrue.Billing.swap_plan/3`/`subscribe/3`, optimistically update the local projection (or invalidate cache) *synchronously in that call's transaction* so the user who just upgraded sees access immediately — don't wait for the round-trip webhook. The webhook becomes confirmation/reconciliation, not the first signal.
- **For Stripe Entitlements sync:** treat the summary webhook as **advisory/secondary**, with the subscription projection + host plan→feature map as primary truth (provider-honest: Braintree/Fake have no summary). Store the summary's event id/ts and apply **monotonic ordering** — the schema already has the `last_stripe_event_ts`/`last_stripe_event_id` pattern; mirror it so an out-of-order older summary can't overwrite a newer one. (Stripe's own sync-engine has had bugs here — see Sources.)
- **Make it recoverable:** provide `refresh_entitlements/1` (or rely on existing webhook replay / DLQ admin) so an operator can force-reconcile a customer whose projection is wrong.

**Warning signs:**
- Support pattern of "I upgraded but still see the paywall" / "I cancelled but still have access."
- The summary handler does a blind upsert with no event-ts/id ordering guard.
- The upgrade flow relies *only* on the inbound webhook to flip access (no synchronous optimistic update).
- Entitlement reads and webhook writes race with no documented convergence story.

**Phase to address:**
Split: convergence/optimistic-update in gate-API core; Stripe summary monotonic ordering in the optional-Stripe-sync phase. **Flag the optional-sync phase as needs-deeper-research** — eventual-consistency + out-of-order handling is the subtlest part of the milestone.

---

### Pitfall 4: Per-request Stripe API call (or N+1 queries) on every gate check

**What goes wrong:**
`entitled?/2` reaches out to Stripe (`Entitlements.ActiveEntitlement.list` or a subscription fetch) on every check, or runs a fresh `Repo` query per call. Gate checks happen on *every protected request* and often *multiple times per render* (a plug, then `on_mount`, then several `entitled?` calls inside a LiveView template for show/hide). Result: page latency dominated by billing I/O, Stripe rate-limit exhaustion, and a Stripe outage becoming an outage in the host's authorization path.

**Why it happens:**
Stripe's Entitlements API *exists* and looks like "the source of truth," so a naive impl calls it live. And because the function reads like a cheap predicate (`entitled?`), callers sprinkle it liberally without realizing each call is a DB round-trip or worse.

**How to avoid:**
- **Never call a provider API on the gate path.** Gate exclusively against local state (Stripe's own docs recommend persisting entitlements locally for performance). Provider calls belong in the webhook/sync path.
- **Resolve entitlements once per request and pass them down.** The plug/`on_mount` guard loads the customer's active subscriptions + resolved feature set **once**, stashes it in `conn.assigns`/`socket.assigns` (e.g., `:accrue_entitlements`), and `entitled?/2` reads from that pre-loaded set when present. Kills the in-template N+1 (multiple `entitled?` in one render → one load).
- **Preload subscription items.** A plan→feature map keyed by price/product needs the sub's items; load with `Repo.preload`/a join in the single resolve, not lazily per feature check. The `Subscription has_many :subscription_items` association is the N+1 trap if accessed un-preloaded in a loop.
- **Cache deliberately, invalidate on the write path.** If adding an ETS/Cachex cache for hot customers, the invalidation hooks are the webhook dispatch worker and the host-initiated `swap_plan`/`subscribe`/`cancel` calls — the same places that mutate the projection. **Cache invalidation tied to the wrong event is the classic source of staleness-that-doesn't-self-heal.** Keep the v1.39 default *no cross-request cache* (per-request assign memoization only) unless a benchmark proves a need; a cache adds an invalidation surface that can fail-open (stale "entitled" never cleared).
- Keep `entitled?/2` cheap-by-construction: pure function over an already-loaded entitlement set, O(features), no I/O.

**Warning signs:**
- `lattice_stripe` / processor facade called from inside `entitled?/2`, a plug, or `on_mount`.
- Telemetry shows the `entitled?` span doing DB/HTTP work, or firing N times per request.
- Load test: protected pages slower than unprotected by more than a trivial margin.
- A cache exists but its invalidation isn't wired to the webhook worker.

**Phase to address:**
Gate-API core (per-request resolve + assign memoization) and plug/LiveView guard phases (single-resolve-then-stash). Any cross-request cache gets its own phase with explicit invalidation tests.

---

### Pitfall 5: Provider drift — Stripe native Entitlements vs Braintree/Fake local mapping silently diverging

**What goes wrong:**
Stripe resolves from native Entitlements (or the summary); Braintree and Fake resolve from the host's local plan→feature map. Over time the two answer *differently for the same logical plan* — a feature is in the Stripe product's entitlement set but absent from the local map (or vice versa). Tests run on Fake (deterministic local map) and pass; production on Stripe behaves differently. The support matrix claims parity that doesn't hold.

**Why it happens:**
This is the recurring shape of every prior Accrue dual-provider milestone (v1.33–v1.37 are full of "Stripe native / Braintree bounded / Fake test-only" labels and drift gates). Entitlements is *more* prone to it: Stripe has a first-class Entitlements API and Braintree has nothing equivalent — so the two are structurally different code paths, not two configs of one path.

**How to avoid:**
- **Make the local plan→feature map the canonical resolution path for *all* providers**, and treat Stripe native Entitlements as an *optional, reconciling overlay* on top of it — not a separate truth. Collapses three code paths toward one: every provider answers from the host-declared map; Stripe additionally *can* sync/confirm against the summary. Fake then exercises the same resolution code as prod, not a parallel stub.
- **Provider-honest labels are mandatory**, matching the existing convention: `native` (Stripe summary available), `host-owned` (Braintree/Fake local map), `unsupported` where applicable. Surface in `guides/entitlements.md` and the support matrix exactly like `lifecycle_semantics.md` does for actions/states.
- **Reuse the existing drift-gate machinery.** Prior milestones ship merge-blocking support-matrix/verifier scripts (`verify_package_docs`, `verify_adoption_proof_matrix`, the `docs-contracts-shift-left` bundle). Add an entitlements row + contract verifier so "Stripe native entitlements sync supported" can't merge without proof and Fake/Stripe behavioral parity is asserted.
- **Add a Stripe-mode parity test in the advisory live-Stripe lane** (the project runs a "Stripe test-mode parity (advisory)" CI job). Fake passing is necessary but not sufficient; the advisory lane catches "passes on Fake, diverges on real Stripe."

**Warning signs:**
- Two distinct functions like `resolve_entitlements_stripe/1` and `resolve_entitlements_local/1` with no shared core.
- A feature works in tests (Fake) but a manual Stripe test-mode check shows different access.
- Support matrix says "entitlements: all providers" with no per-provider label.
- No verifier re-fails when the entitlements support claim drifts from code.

**Phase to address:**
Provider-honest-matrix phase + optional-Stripe-sync phase. The "local map canonical, Stripe overlay" architecture decision must be made in gate-API core so all later provider work inherits it.

---

### Pitfall 6: Over-coupling entitlements to Sigra/Lockspire instead of staying adapter-thin and host-owned

**What goes wrong:**
The gate hard-depends on Sigra session shape or Lockspire OAuth scopes — `entitled?` expects a `%Sigra.Session{}`, or the plug reads a Sigra-specific assign, or the LiveView guard assumes Sigra's `on_mount`. Hosts using `phx.gen.auth`, Ueberauth, or custom auth can't use entitlements, or must fake a Sigra shape. Accrue ends up *owning the user schema* it has always refused to own.

**Why it happens:**
SEED-002 #4 explicitly frames entitlements as "Sigra/Lockspire identity tie-in," and the example `Accrue.has_active_plan?(user, "pro")` reads like it knows what a `user` is. Sigra is `optional: true`, but the *temptation* is to build the integration first and the generic path second.

**How to avoid:**
- **Entitlements operate on a *billable*, resolved through the existing `Accrue.Auth` behaviour and the polymorphic billable (`owner_type`/`owner_id`), never on a concrete identity type.** The gate's input is "give me the billable for this conn/socket/user" — which `Accrue.Auth.current_user/1` + the billable lookup already provide. Keep treating the user as an opaque map/struct (the `Auth` behaviour already types it `map() | struct()`).
- **Ship the generic path first, Sigra/Lockspire as a thin documented adapter/guide second.** Per the milestone's own out-of-scope note: "deep Sigra/Lockspire coupling — keep adapter-thin." The plug and `on_mount` guard must work with *any* host auth that implements `Accrue.Auth`, with Sigra wiring as a `guides/` recipe, not a code dependency.
- **No `sigra`/`lockspire` references in `accrue` core entitlement paths.** A Sigra-specific helper, if wanted, lives behind the existing optional-dep conditional-compilation pattern (the `Accrue.Integrations.Sigra` adapter shape), never in the gate hot path.
- Mirror the `Accrue.Auth.Default` posture: a host that wired auth gets entitlements for free; the gate reaches identity *only* through the behaviour facade.

**Warning signs:**
- `Sigra.` or `Lockspire.` appears in `accrue/lib/accrue/entitlements*` or the plug/guard.
- The gate's typespec names a concrete session/user struct instead of `billable`/opaque user.
- The first/only working example requires Sigra installed.
- Tests can't exercise the gate without a Sigra fixture.

**Phase to address:**
Gate-API core (billable-centric, behaviour-mediated input) and plug/LiveView guard phases (host-auth-agnostic). Sigra/Lockspire is a *guide*, deferred per the milestone's scope cut.

---

### Pitfall 7: Config/mapping drift — host plan→feature map drifts from actual Stripe products/prices

**What goes wrong:**
The host declares `%{"pro" => [:advanced_reports, :api_access]}` keyed by a plan name, but the customer's subscription carries a Stripe `price_id`/`product_id` that no longer maps to "pro" (price archived and replaced, a new price added in Dashboard, a typo, a grandfathered legacy price). The lookup misses → depending on Pitfall 1's resolution, everyone on the new price is *denied* everything (support storm) or *granted* everything (leak). It fails **silently** — a missing map key is not an error.

**Why it happens:**
Two sources of truth nobody reconciles: the host's static config map (in `runtime.exs`) and the live Stripe catalog (managed in the Dashboard, changed by non-engineers). This is the entitlements analogue of the `:plan_resolver` drift problem v1.37 already hit for Braintree plan swaps. New Stripe prices never announce themselves to the config map.

**How to avoid:**
- **Validate the plan→feature map shape at boot via `nimble_options`** (the project's config-validation standard) — catches typos/malformed entries at boot, not at first gate check.
- **Make "unmapped plan" a *loud* condition, not silent.** When a gate resolves a subscription whose plan/price has *no* map entry, emit telemetry (`[:accrue, :entitlement, :unmapped_plan]`) and fail **closed** (deny), so it shows up in dashboards and as a denied user, not a silent grant. An unmapped plan granting everything is the worst outcome.
- **Provide a drift-detection mix task / verifier** (on-posture with the project's verifier culture): given the host's map and the live Stripe price/product list, report prices in Stripe with no map entry and map entries pointing at archived/nonexistent prices. Document running it in CI or on deploy — the entitlements parallel to `verify_adoption_proof_matrix`.
- **Key the map on stable identifiers** (price `lookup_key` or product id), and document that archiving a Stripe price requires updating the map in the same change — the same same-PR co-update discipline the project already uses for support-matrix edits.
- Surface a customer's *resolved* entitlements in `accrue_admin` (a milestone target) so operators can spot "this customer's plan resolved to no features" by eye.

**Warning signs:**
- Plan→feature map keyed on display names ("Pro Plan") rather than stable ids.
- No boot-time validation of the map.
- No telemetry/log when a subscription's plan isn't in the map.
- Stripe Dashboard price changes ship without a corresponding config PR.
- Admin can't show why a given customer is/isn't entitled.

**Phase to address:**
Entitlement-model phase (map schema + `nimble_options` validation + unmapped-plan telemetry) and admin-surface phase (operator visibility into resolved entitlements). A drift mix task can be its own small phase or fold into provider-honest-matrix.

---

### Pitfall 8: LiveView `on_mount` guard pitfalls (ordering vs auth, redirect loops, gating after expensive mounts, leaking LiveView into core)

**What goes wrong:**
- **Ordering vs auth:** the entitlement `on_mount` runs *before* the host's auth `on_mount`, so `current_user` isn't assigned → the gate sees `nil` → (if fail-closed, correctly) denies, but the host expected auth-then-entitlement order and gets a confusing redirect, or it runs after a 401 path and double-redirects.
- **Redirect loop:** the guard redirects unentitled users to an upgrade/pricing LiveView that *itself* is (accidentally) under the same gate → infinite redirect.
- **Gating after expensive mount:** the check is placed *inside* `mount/3` after data loading, so expensive queries run for users about to be denied — wasted work and a side-channel (timing/partial render) before redirect.
- **Disconnected vs connected mount:** `on_mount` runs twice (static render + connected). Doing the load only in the connected branch, or expensive provider work in both, causes flicker or double-work.
- **LiveView *socket runtime* leaking into always-compiled core:** to make `on_mount` "first-party," someone references `Phoenix.LiveView` / `on_mount` / `Socket` from an always-compiled core module — violating the real constraint that core stays **LiveView-runtime-free** (no socket-runtime coupling in always-compiled code). Note: `phoenix_live_view` is *already* a required core dep (it ships `Phoenix.Component`/`~H` for the email + invoice render spine), so adding the package is **not** the violation — coupling the socket runtime is.

**Why it happens:**
`on_mount` composition order is subtle and host-controlled; the gate author doesn't control where the host places it. And the milestone wants a first-party LiveView guard, pressuring socket-runtime code into always-compiled core.

**How to avoid:**
- **Ship the `on_mount` guard from CORE `accrue`, conditionally compiled — not from `accrue_admin`, not a new package.** The guard lives at `lib/accrue/live/entitlements.ex` (`Accrue.Live.Entitlements`) and is wrapped in the canonical Sigra 4-pattern (`if Code.ensure_loaded?(Phoenix.LiveView) do … end` + `@compile {:no_warn_undefined, …}` + narrow imports). It gates the *host's own* LiveViews, so placing it in `accrue_admin` would force host route-gating to pull in the entire admin dashboard — a layering inversion. `phoenix_live_view` is already required in core, so no new dep is added. The real invariant is "no always-compiled core module references the LiveView socket runtime," enforced by a merge-blocking static gate (grep/Credo over `lib/accrue/`). Document that hosts add the guard to their *own* LiveView's `on_mount` list.
- **Document required ordering explicitly:** entitlement `on_mount` comes **after** the host's auth `on_mount` (it depends on `current_user`). Provide the exact `live_session`/`on_mount` snippet in `guides/entitlements.md`. Make the guard tolerate (fail-closed on) a missing `current_user` rather than crash, so misordering degrades to "denied," never "500."
- **Halt early, before expensive work:** the guard returns `{:halt, redirect(...)}` from `on_mount` *before* the host's `mount/3` data loading — `on_mount` is exactly the right hook. Never gate inside `mount/3` after loads.
- **Break redirect loops:** document that the upgrade/pricing destination must be *outside* the gated `live_session`. Optionally detect self-redirect and fall through to a plain halt.
- **Handle both mount passes:** keep the guard a pure check over already-resolvable state; resolve once per request and reuse (Pitfall 4); tolerate double invocation idempotently.
- Provide the controller-level `Plug` guard (`require_plan`/`require_feature`) for non-LiveView routes in core (plugs are fine in core — only LiveView is restricted), so non-LiveView hosts still get gating.

**Warning signs:**
- An **always-compiled** core module (anything outside the `if Code.ensure_loaded?(Phoenix.LiveView)` block under `lib/accrue/live/`) references `Phoenix.LiveView` / `on_mount` / `Phoenix.LiveView.Socket` / `Phoenix.Socket`. (A non-optional `phoenix_live_view` in `accrue/mix.exs` is **expected and correct** — it backs `Phoenix.Component` — and is *not* a warning sign.)
- The guide's `on_mount` example places entitlement before auth.
- The pricing/upgrade page is inside the same `live_session` as gated pages.
- `mount/3` loads data then checks entitlement.
- The guard raises (rather than halts/denies) when `current_user` is missing.

**Phase to address:**
LiveView `on_mount` guard phase (cond-compiled guard in core `lib/accrue/live/entitlements.ex`, ordering docs, halt-before-load) and plug-guard phase (controller path in core). The "no always-compiled core module references the LiveView socket runtime" check belongs in that phase's exit criteria as a merge-blocking static gate (grep/Credo over `lib/accrue/`).

---

### Pitfall 9: Quota/seat race conditions (concurrent checks and decrements)

**What goes wrong:**
*Only if seat/quota entitlements are in scope* (the milestone scopes in "seat counts" but explicitly scopes **out** "rich quota/metering-as-entitlement math beyond seat counts"). For seats: two concurrent requests both read "4 of 5 seats used," both pass the check, both add a member → 6 of 5. Classic check-then-act TOCTOU. Over-allocation is a paid-tier leak (free extra seats) and a data-integrity bug.

**Why it happens:**
Seat checks read a count, decide, then write — without atomicity. Phoenix's concurrent request model makes this trivially reproducible under load.

**How to avoid:**
- **Keep v1.39 seat checks a read-only entitlement predicate** (`seats_remaining/1`, `within_seat_limit?/1`) and be explicit that *enforcing* the limit on add is the **host's** atomic operation — Accrue does not own the user/membership schema (Pitfall 6), so it cannot own the atomic seat increment. Document this boundary loudly so hosts don't assume the predicate is enforcement.
- **Where Accrue counts seats**, count from authoritative billing state (subscription `quantity`/item quantity it already tracks via `update_quantity/3`) and the host's member count — and make the *comparison* a point-in-time read, not a guarantee.
- **For hosts that want atomicity, document the pattern:** seat check + member insert in one DB transaction with a row lock or a unique/`check` constraint, or `SELECT ... FOR UPDATE` on the billing row. The project already uses `optimistic_lock(:lock_version)` on the subscription — point hosts at that pattern.
- **Reuse `stream_data`/concurrent tests** to assert no over-allocation under parallel adds, the same rigor as money math.
- Resist scope creep into quota *math* — the milestone already cut it. Seats only: read-predicate + documented host-atomicity.

**Warning signs:**
- A `seats_remaining` function callers use as if it were a lock.
- No transaction/constraint around the host's "add member" path in the example/docs.
- Tests only check seat logic single-threaded.
- Pressure to add metered-quota decrement APIs (out of scope).

**Phase to address:**
Entitlement-model phase (seat predicate read-only, boundary documented). Flag for the roadmapper: if seats are genuinely in scope, the atomicity *guidance* is a docs/example deliverable, not a core API — keep it thin.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| `entitled?/2` returns error tuples / non-boolean | Less wrapping code | Truthiness fail-open (P1); leaks on every error | **Never** — the boolean contract is the whole safety story |
| Gate on raw `subscription.status` | Looks simpler | Wrong on `canceling`/`trialing`/`incomplete_expired`/`paused` (P2) | **Never** — predicates exist and encode the edges |
| Live Stripe call in `entitled?/2` for "freshness" | Always "current" | Latency + rate limits + Stripe outage = auth outage (P4) | **Never** — persist locally per Stripe's own guidance |
| Separate Stripe vs local resolution paths | Each path simple in isolation | Provider drift; Fake-passes-prod-fails (P5) | Only if a shared core resolver underlies both |
| Cross-request cache without invalidation hooks | Fast hot path | Stale "entitled" never clears = persistent leak (P4) | Only with invalidation wired to webhook worker + write path, and only if a benchmark proves need |
| Referencing the LiveView socket runtime (`Phoenix.LiveView` / `on_mount` / `Socket`) from always-compiled core | First-party LV guard | Violates core-stays-LiveView-**runtime**-free constraint (P8) | **Never** — guard lives in cond-compiled core (`lib/accrue/live/entitlements.ex`); a non-optional `phoenix_live_view` dep is fine (backs `Phoenix.Component`) |
| Plan→feature map keyed on display names | Reads nicely | Drift on Dashboard price changes, silent miss (P7) | Only for throwaway demos, never production guidance |
| Seat predicate treated as enforcement | No transaction needed | Over-allocation under concurrency (P9) | Only as a read-only hint with host owning atomicity |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Stripe Entitlements API | Fetching `ActiveEntitlement.list` live on each gate check | Persist the summary locally (Stripe's documented recommendation); gate against local state |
| `entitlements.active_entitlement_summary.updated` webhook | Blind upsert, no ordering guard; treating it as primary truth | Monotonic event-ts/id ordering (mirror `last_stripe_event_ts`/`last_stripe_event_id`); treat as advisory overlay on the host map; known Stripe sync bug truncates >10 entitlements — don't assume completeness |
| Stripe webhook → projection lag | Assuming local state is instantly current after a customer action | Optimistically update projection in the host-initiated `swap_plan`/`subscribe` transaction; webhook reconciles |
| Braintree (no native entitlements) | Building a Braintree-specific entitlement path | Resolve from the canonical host plan→feature map; label `host-owned` |
| `Accrue.Auth` (Sigra/phx.gen.auth/Ueberauth) | Coupling the gate to a concrete session/user type | Take a billable; reach identity only through the `Accrue.Auth` behaviour facade |
| Oban webhook queue | Entitlement webhooks stuck behind slow queues, widening convergence gap | Entitlement-relevant events in a fast queue; projection write in the dispatch worker |
| `accrue_admin` LiveView | Coupling the LiveView socket runtime into always-compiled core to ship the `on_mount` guard | Ship the guard from cond-compiled core (`lib/accrue/live/entitlements.ex`); core stays runtime-LiveView-free (no socket runtime in always-compiled code; `phoenix_live_view` is already a required core dep) |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Per-request provider API call in gate | Protected pages slow; Stripe 429s; auth fails when Stripe is down | Gate on local state only; provider I/O on webhook/sync path | Immediately at any real traffic; worsens with Stripe latency |
| N+1 on `subscription_items` inside per-feature checks | Many small queries per render; `entitled?` span fires N times | Resolve once per request, preload items, stash in assigns, memoize | Pages with several gated UI elements; customer lists |
| No per-request memoization (re-resolve on every `entitled?`) | Repeated identical DB reads within one request | Single resolve in plug/`on_mount` → `assigns[:accrue_entitlements]` | Dashboards/templates with many gate calls |
| Cross-request cache with broken invalidation | Stale grants/denials persist after plan change | Invalidate from webhook worker + host write path; default to no cross-request cache | After every upgrade/downgrade/cancel until TTL |
| Admin "show entitlements for all customers" without query fragments | Slow admin list; full scans | Use `Billing.Query.active/1` + entitling fragment with indexes | As customer count grows (operator-JTBD scale) |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Fail-open on error/unknown plan/nil billable | Paid features leak to free/lapsed users; silent revenue loss | Two-value boolean; only affirmative match returns `true`; property-test never-true-on-garbage |
| Revoking access for `canceling` (paid-through) subs | Customer loses access they paid for; churn + support load | Honor `canceling?/1`; entitled until `current_period_end` |
| Leaving access on for `incomplete_expired` / non-`:canceled` ended subs | Terminated customers keep premium | Use `canceled?/1` (covers `incomplete_expired` + `ended_at`), not `status == :canceled` |
| Trusting a stale cross-request cache as "entitled" | Cancelled customer keeps access indefinitely | Invalidate on write path; prefer per-request resolve |
| Client-side-only gating (hiding UI, no server check) | Hidden features reachable by direct request/API | Server-side plug/`on_mount`/`entitled?` is authoritative; UI hide is cosmetic only |
| Unmapped plan silently granting everything | Mass leak on a Stripe price change | Unmapped → deny + telemetry; boot-validate the map |
| Logging the Stripe entitlement summary with PII | Sensitive data in logs (violates project log-hygiene constraint) | Never log raw summary/customer payloads; events store refs not PII |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Hard paywall during webhook convergence after upgrade | "I paid and still can't use it" | Optimistic projection update on host-initiated upgrade; webhook reconciles |
| Identical "denied" page for "not entitled" vs "couldn't check" | A user who hit a transient error sees a sales paywall | `entitled?` (fail-closed boolean) for gating; `entitled/2` `{:error,_}` lets host show a retry page distinct from upsell |
| Redirect loop into a gated upgrade page | Browser hangs / infinite redirect | Keep upgrade/pricing route outside the gated `live_session` |
| Instant revoke the moment a payment is late (`past_due`) | Hostile to customers in dunning | Honor a grace window (reuse dunning grace overlay); revoke after grace, configurable |
| Flicker between LiveView static and connected mount | UI flashes gated content then redirects | Resolve entitlement in `on_mount` (both passes), halt before render |

## Ledger / Telemetry — what to record vs noise

The immutable `accrue_events` ledger is append-only (PG trigger blocks UPDATE/DELETE) and tamper-evident; flooding it with one row per gate check would bloat it, slow `timeline_for`/`state_as_of`, and drown the signal. The split:

- **Telemetry spans (`:telemetry.span/3` via `Accrue.Telemetry.span/3`) — record every gate check.** Cheap, ephemeral, aggregatable. Emit `[:accrue, :entitlement, :check]` start/stop with metadata: `feature`/`plan`, `result` (granted/denied), `reason` (active/trialing/grace/unmapped/error), provider, billable id. Gives operators allow/deny rates and latency without ledger writes. Emit `:exception` on rescue. Mirror the existing `span_billing` pattern.
- **Immutable ledger (`Accrue.Events.record/1`) — record only *meaningful state changes*, not reads.** Worth recording: entitlement summary synced from Stripe (with event id), an operator manually overriding/comp-ing entitlements in admin, a plan→feature mapping change taking effect, an unmapped-plan denial (rare, security-relevant). **Not** worth recording: routine per-request grant/deny — that's telemetry's job.
- **Reuse `record_multi`** to record entitlement-affecting state changes in the *same transaction* as the projection update (the established pattern), so the audit trail can't diverge from state.
- **Capture actor/trace** via `Accrue.Auth.actor_id/1` on operator-initiated entitlement changes (admin overrides), matching the ledger's existing actor-capture.

## "Looks Done But Isn't" Checklist

- [ ] **`entitled?/2`:** Often missing the error/edge collapse — verify it returns `false` (not an error tuple) for errored repo, `nil` billable, unmapped plan, exception, and Stripe timeout.
- [ ] **Lifecycle mapping:** Often missing trial/canceling/incomplete_expired — verify tests cover trialing→entitled, cancel_at_period_end-in-window→entitled, incomplete_expired→denied, paused→denied, past_due→grace policy.
- [ ] **Convergence:** Often missing the upgrade window — verify a host-initiated upgrade grants access *before* the confirming webhook arrives.
- [ ] **Stripe summary sync:** Often missing ordering — verify an out-of-order older summary can't overwrite a newer one (monotonic ts/id), and that >10-entitlement truncation doesn't silently drop features.
- [ ] **Provider parity:** Often missing real-Stripe check — verify the advisory live-Stripe lane asserts the same access as Fake; verify per-provider support labels exist.
- [ ] **No live API on gate path:** Verify telemetry shows `entitled?` doing zero DB/HTTP work when entitlements are pre-resolved into assigns.
- [ ] **Core stays runtime-LiveView-free:** Verify no always-compiled core module references the LiveView socket runtime (`Phoenix.LiveView` / `on_mount` / `Socket`); the `on_mount` guard ships cond-compiled in core (`lib/accrue/live/entitlements.ex`). A non-optional `phoenix_live_view` dep is expected (backs `Phoenix.Component`), not a violation.
- [ ] **Auth-agnostic:** Verify the gate works with a plain `phx.gen.auth`-shaped user (no Sigra) end to end.
- [ ] **Unmapped plan:** Verify a subscription on a plan absent from the map denies + emits `[:accrue, :entitlement, :unmapped_plan]`.
- [ ] **Telemetry/ledger:** Verify gate decisions emit spans; verify *grants/denials of normal traffic are not flooding the immutable ledger*.
- [ ] **Admin:** Verify `accrue_admin` shows a customer's *resolved* entitlements and *why* (which sub/plan), not just raw status.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Fail-open shipped (leak) | MEDIUM | Flip resolution to fail-closed; add property test; audit telemetry for the leak window; no data migration needed (read-path bug) |
| Gated on raw status (wrong edges) | LOW | Swap to `Subscription` predicates / `Billing.Query` fragments; add edge-state tests |
| Per-request Stripe call shipped | LOW–MEDIUM | Move provider call to webhook/sync path; gate on local state; add per-request memoization |
| Stale cache leaking grants | MEDIUM | Wire invalidation to webhook worker + write path, or remove cache and rely on per-request resolve; force-refresh affected customers |
| Stripe summary out-of-order overwrite | MEDIUM | Add monotonic ts/id guard; replay/refresh affected customers via existing webhook replay/DLQ admin |
| Plan→feature map drift | LOW | Update map (stable-id keyed); run drift mix task; unmapped-plan telemetry tells you who was affected |
| LiveView socket runtime referenced from always-compiled core | MEDIUM | Move the offending reference into the cond-compiled `lib/accrue/live/entitlements.ex` block (or remove it); re-verify the static merge gate over `lib/accrue/` (no `phoenix_live_view` dep removal needed — it backs `Phoenix.Component`) |
| Seat over-allocation | MEDIUM | Add transaction/constraint on host add path; reconcile over-allocated tenants; document host-atomicity |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. Fail-open | Gate-API core (~123) | Property test: `entitled?/2 == false` for all error/edge inputs; no non-boolean head |
| 2. Lifecycle mis-mapping | Gate-API core | Edge-state test matrix (trial/canceling/incomplete_expired/paused/past_due); resolver imports `Subscription`/`Query` |
| 3. Staleness / convergence | Gate-API core + optional-Stripe-sync (**flag: deeper research**) | Test: upgrade grants before webhook; monotonic-ordering test for summary |
| 4. Per-request API call / N+1 | Gate-API core + plug/LiveView guard | Telemetry shows zero I/O on memoized gate; load test parity protected vs unprotected |
| 5. Provider drift | Provider-honest-matrix + Stripe-sync | Shared resolver core; support-matrix verifier re-fails on drift; advisory live-Stripe parity job |
| 6. Auth/identity over-coupling | Gate-API core + plug/LiveView guard | Gate works with plain `phx.gen.auth` user; no Sigra/Lockspire in core entitlement paths |
| 7. Config/mapping drift | Entitlement-model + admin-surface | `nimble_options` boot validation; unmapped-plan telemetry; drift mix task; admin shows resolved entitlements |
| 8. LiveView guard pitfalls | LiveView `on_mount` guard phase | Static merge gate: no always-compiled core module references the LiveView socket runtime (cond-compiled guard in `lib/accrue/live/`); ordering/halt-before-load docs + tests; upgrade route outside gated session |
| 9. Seat race conditions | Entitlement-model (seats only) | Read-only predicate documented as non-enforcing; concurrent add test in example/docs |
| Ledger/telemetry noise | All entitlement phases | Per-check = telemetry only; state-changes = ledger via `record_multi`; ledger row-count sanity test |

## Sources

- `accrue/lib/accrue/billing/subscription.ex` — lifecycle predicates (`active?/1` includes trialing, `canceling?/1`, `past_due?/1`, `canceled?/1` covers `incomplete_expired`/`ended_at`, `paused?/1` covers legacy + `pause_collection`); `optimistic_lock(:lock_version)`; `last_stripe_event_ts`/`last_stripe_event_id` ordering fields. (HIGH — read from source)
- `accrue/lib/accrue/billing/query.ex` — composable query fragments mirroring predicates (`active/1`, `canceling/1`, `dunning_sweep_candidates/2`). (HIGH — source)
- `accrue/guides/lifecycle_semantics.md` — `active` = "counts for entitlement purposes," includes trialing; convergence/local-truth section; provider-label vocabulary (`native`/`host-owned`/`unsupported`/`testing-local-only`). (HIGH — source)
- `accrue/lib/accrue/auth.ex` — `Accrue.Auth` behaviour; user typed `map() | struct()`; `current_user/1`, `actor_id/1`; dev-permissive `Default` that refuses to boot in prod. (HIGH — source)
- `accrue/lib/accrue/events.ex` — append-only ledger `record/1`/`record_multi/2`; immutability trigger; actor/trace capture. (HIGH — source)
- `accrue/lib/accrue/telemetry.ex` + `billing.ex` — `span/3` over `:telemetry.span/3`; `span_billing` pattern for entry points. (HIGH — source)
- `accrue/lib/accrue/config.ex` — `nimble_options` config validation; compile-time vs runtime adapter boundary. (HIGH — source)
- `.planning/PROJECT.md` — v1.39 targets + out-of-scope (no rich quota math, keep Sigra/Lockspire adapter-thin, core stays runtime-LiveView-free — `phoenix_live_view` required for `Phoenix.Component`, no socket-runtime coupling, fast Oban webhook queue concurrency); dual-provider drift-gate culture (v1.33–v1.37). (HIGH)
- `.planning/research/JTBD-FRONTIER.md` — entitlements = #1 gap; "gate on subscription state Accrue already holds locally"; verify→persist→enqueue→200 webhook path. (HIGH)
- `.planning/seeds/SEED-002-ecosystem-integrations.md` #4 — Sigra/Lockspire framing; `Accrue.has_active_plan?(user, "pro")` example. (HIGH)
- Stripe Entitlements docs — recommends persisting active entitlements locally rather than fetching on demand; `entitlements.active_entitlement_summary.updated` webhook is the change signal: https://docs.stripe.com/billing/entitlements (MEDIUM — official docs, verified 2026-05-22)
- Stripe sync-engine issue #280 — summary webhook truncating beyond 10 entitlements (don't assume completeness): https://github.com/stripe/sync-engine/issues/280 (MEDIUM — known issue)
- Stripe events eventual consistency — pagination/skip risks on the events API: https://blog.sequin.io/finding-and-fixing-eventual-consistency-with-stripe-events/ (MEDIUM)
- Fail-open vs fail-closed for entitlement/feature gating — default-deny, sensible defaults, test failure scenarios: https://www.getunleash.io/blog/feature-flag-security-best-practices ; entitlements vs feature flags distinction: https://salable.app/blog/insights/entitlements-future-feature-management (MEDIUM)

---
*Pitfalls research for: entitlements / plan-gating on an existing Elixir/Phoenix billing library (Accrue v1.39)*
*Researched: 2026-05-22*
