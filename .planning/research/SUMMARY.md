# Project Research Summary

**Project:** Accrue — Entitlements / Plan-Gating (v1.39)
**Domain:** First-party feature/access gating layered onto an already-feature-complete Elixir/Phoenix subscription-billing library
**Researched:** 2026-05-22
**Confidence:** HIGH

> Milestone framing (from `JTBD-FRONTIER.md`, do not re-derive): Accrue is feature-complete for its
> core promise. Of everything still missing, **exactly one** item dents the "feature-complete for a
> real SaaS" claim — **entitlements / plan-gating**. You can bill a customer, but Accrue gives you
> nothing first-party to *gate features* on that subscription. A private `Subscription.is_active?/1`
> exists; there is **no public way to gate on it**. Closing that one gap is the whole milestone.

## Executive Summary

This milestone adds the last missing piece of the canonical SaaS loop — **gating access on what a
customer paid for** — to a billing core that already holds the source of truth. The four research
threads converged hard on one shape: entitlements is a **thin derivation layer over local
subscription state Accrue already maintains**, not a new domain. The gate read path is
`billable → Customer → active Subscriptions → SubscriptionItem.price_id → (host plan→feature map) →
boolean`, resolved entirely from the local projection with **zero processor API calls on the hot
path**. Because the subscription mirror is already kept honest by webhooks, the headline JTBD —
"I'm subscribed, gate the pro feature" — ships with **no new tables and no Stripe dependency**.

The single most consequential cross-cutting recommendation is **no new required dependency**. The
core gate API, the controller Plug guard, the LiveView `on_mount` guard, the admin view, and even the
optional Stripe sync are all buildable on Accrue's *existing* matrix. lattice_stripe 1.1.0 was
verified against source to expose **no Entitlements API at all** (zero `entitlement` matches in
`lib/`), so the design is **LOCAL-first plan→feature mapping for all providers** (Stripe/Braintree/
Fake), with an optional thin Stripe sync that consumes the existing generic `%Event{}` webhook
(`entitlements.active_entitlement_summary.updated`) into a cache. Typed upstream lattice_stripe
Entitlements resources are explicitly deferred (a SEED candidate, off the critical path). The only
possible `mix.exs` change is making `phoenix_live_view` `optional: true` in core for the conditionally-
compiled `on_mount` guard — and even that carries a STACK-vs-ARCHITECTURE nuance worth verifying at
phase time (see Gaps).

The dominant risk is **fail-open gating** — a check that silently returns "allowed" when it couldn't
actually resolve entitlement leaks paid features. Elixir truthiness makes this the *accidental* path
(an `{:error, _}` tuple is truthy). The mitigation is structural: `entitled?/2` is a strict two-value
boolean whose **only** path to `true` is an affirmative, fully-resolved match — every error, `nil`
billable, unmapped plan, and exception collapses to `false`, property-tested with `stream_data`.
Three more correctness rules carry the milestone: **reuse the existing `Subscription.active?/1`
lifecycle predicates** (never gate on raw `.status`); split observability so **per-check decisions go
to telemetry only while grant/revoke/sync go to the immutable ledger**; and express provider honesty
through a **Resolver behaviour + capability-matrix rows**, mirroring the established Processor/Auth/
PlanResolver and SCM-06/PROC-24 drift-gate patterns.

## Key Findings

### Recommended Stack

**No new packages.** (Full detail: `STACK.md`.) Every surface — core gate API, Plug guard, LiveView
`on_mount` guard, admin entitlements view, and optional Stripe-webhook consumption — builds on
Accrue's existing dependency matrix. The two must-answer questions both resolved to "no new dep":
lattice_stripe `~> 1.1` does **not** expose Stripe's Entitlements API (verified by reading the
published sibling source — zero `entitlement` / `active_entitlement_summary` matches), and neither
guard needs anything new (`plug` arrives transitively via `phoenix ~> 1.8`; the LiveView guard rides
the existing optional-dep + conditional-compilation pattern). The only candidate `mix.exs` edit is one
`optional: true` declaration for `phoenix_live_view` in core.

**Core technologies (all already in the matrix):**
- `:ecto`/`:ecto_sql`/`:postgrex` (`~> 3.13`/`~> 0.22`) — local plan→feature map + optional active-entitlement cache; the entitlement model is a thin schema/query over data already held. No new persistence tech, no PG extensions.
- `:lattice_stripe` (`~> 1.1`) — optional Stripe sync via the public raw-API escape hatch (`Client.request/2`) + type-agnostic `%Event{}` webhook consumption. **Covers the entire optional Stripe path with no upstream release required.**
- `:oban` (`~> 2.21`) — async refresh of the entitlement projection on the summary webhook, reusing the existing webhook→Oban path.
- `:nimble_options` (`~> 1.1`) — boot-time validation of the host-declared plan→feature config (the project's config-validation + docs standard).
- `:telemetry` (`~> 1.3`) — `[:accrue, :entitlements, :check, :start/stop/exception]` spans on every gate call (mandated for all public entry points).
- `:plug` (transitive via `phoenix ~> 1.8`) — `require_plan`/`require_feature` controller guard; mirrors the shipped `Accrue.Webhook.Plug`.
- `:phoenix_live_view` (`~> 1.1`, declared **`optional: true` in core**) — the `on_mount/4` guard, conditionally compiled like `sigra`/`opentelemetry`. Keeps core LiveView-free for headless/API hosts.
- `:stream_data` (`~> 1.3`) / `:mox` (`~> 1.2`) — property-test the fail-closed invariant; mock the Stripe-sync adapter.

### Expected Features

(Full landscape, competitor analysis, and dependency graph: `FEATURES.md`.) Pay and Laravel Cashier
ship **no first-party entitlements** — their users hand-roll plan→feature maps. Stripe/Chargebee/
Recurly have entitlements but they're processor- or product-locked. Accrue's opening is *idiomatic,
provider-honest, observable Phoenix entitlements*.

**Must have (table stakes — the milestone core):**
- Host-declared plan→feature/quota map + `NimbleOptions` validation — the foundation everything reads; works on every provider.
- `has_active_plan?(billable, plan)` — the literal #1 JTBD; pure derivation over shipped subscription state.
- `entitled?(billable, :feature)` + `features_for(billable)` — capability-level checks (decouple host code from price IDs).
- Seat/quantity quota check (`within_quota?` / `seats_remaining`) — count-of-seats only, reusing shipped `quantity` state.
- Controller Plug guard (`require_plan`/`require_feature`) with fail-closed core + `:on_denied` graceful-UX hook.
- LiveView `on_mount` guard (optional-LiveView, compile-guarded) — the headline differentiator; no comparator ships one.
- Telemetry spans + audit-ledger recording on the right split (see Pitfall 5).
- Fake-processor deterministic proof lane (merge-blocking); provider-honest support matrix.
- `accrue_admin` read-only active-entitlements panel on customer detail.
- `guides/entitlements.md` + JTBD ⛔→✅ flip + First Hour/README spine + doc verifiers.

**Should have (competitive, additive):**
- Optional Stripe Entitlements sync via `entitlements.active_entitlement_summary.updated` — high value but additive; the static host map is the default that works everywhere. Land late or defer one milestone without breaking the core promise.
- `Accrue.Auth`-thin identity tie-in recipe (Sigra/Lockspire optional) — keep adapter-thin per the explicit boundary; can be a docs-led recipe rather than new code.

**Defer (explicitly NOT v1.39):**
- Metered-usage-as-entitlement / overage enforcement — out of scope per PROJECT.md; a heavier, different domain.
- Tiered/range numeric limits beyond seat counts — Chargebee's "Range" type; defer.
- Feature-catalog authoring UI in admin — host/Stripe owns authoring; admin only *displays*.
- Fail-open default, hidden caching, per-request Stripe calls, general feature-flag system — all anti-features.

### Architecture Approach

(Full integration design, data flows, build order: `ARCHITECTURE.md`.) This is an **integration
design against Accrue's feature-complete core**, not a redesign. The central decision is **hybrid:
host-declared static config (validated by `nimble_options`) is the source of truth; an optional synced
cache table is a Stripe-only overlay.** A new top-level `Accrue.Entitlements` context (sibling of
`billing/`, never a dependency of it) wraps each entry in a telemetry span; a `Resolver` behaviour
dispatches `LocalMap` (default, every provider) vs `StripeNative` (opt-in, cache-read). Both guards
ship from core — the Plug guard unconditionally (plug is a hard dep), the LiveView guard as a single
conditionally-compiled file (`Code.ensure_loaded?(Phoenix.LiveView)`), so a headless host never
compiles a LiveView reference. The gate read path **folds existing local state and never calls a
processor** — reusing `Billing.Query.active/1` / `Subscription.active?/1` as the single definition of
"active for entitlement purposes."

**Major components:**
1. `Accrue.Entitlements` (NEW context) — `entitled?/2`, `has_active_plan?/2`, `features_for/1`, `list_entitlements/1`, `grant/3`, `revoke/3`; telemetry-wrapped; ledger records grant/revoke/sync but **not** checks.
2. `Accrue.Entitlements.Resolver` behaviour + `LocalMap` (default) / `StripeNative` (opt-in cache) — the provider-honest seam, dispatched via runtime config like `Processor`/`Auth`/`PlanResolver`.
3. `Accrue.Plug.RequireEntitlement` (NEW core Plug) + `Accrue.Live.Entitlements` (NEW conditionally-compiled `on_mount`) — the two enforcement surfaces.
4. `Accrue.Config` (MODIFIED) — new `:plans` (plan→feature map) + `:entitlements` (resolver/source/sync flags) keys; `Processor.Capabilities` (MODIFIED) — `entitlements:` rows in `@support_labels`/`@provider_support_labels`.
5. Optional `accrue_entitlement_grants` cache table + `Webhook.DefaultHandler` summary clause + `accrue_admin CustomerLive` Entitlements tab — all additive, gated install.

### Critical Pitfalls

(All nine pitfalls, the "looks done but isn't" checklist, and recovery strategies: `PITFALLS.md`.)

1. **Fail-open gating** — an unresolvable check returning truthy leaks paid features (Elixir's `{:error, _}` is truthy → the accidental path). **Avoid:** strict two-value boolean; the only path to `true` is an affirmative resolved match; error/`nil`/unmapped/exception → `false`; offer a separate `{:ok, bool} | {:error, _}` variant for hosts that must distinguish "denied" from "couldn't check"; property-test never-true-on-garbage.
2. **Not reusing lifecycle predicates** — re-deriving entitlement from raw `.status` gets `canceling`/`trialing`/`incomplete_expired`/`paused`/`past_due` wrong. **Avoid:** build on `Subscription.active?/1` + `Billing.Query` fragments (already documented as "active = counts for entitlement purposes"); author an explicit lifecycle→entitlement truth table pinned to `lifecycle_semantics.md`; **trial/past-due/paused/canceling semantics need an explicit requirements decision** (the `past_due`-grace knob especially).
3. **Per-request processor API call / N+1** — calling Stripe (or re-querying) on every check makes a Stripe outage an auth outage. **Avoid:** resolve from local state only; resolve once per request and stash in `conn`/`socket` assigns; preload subscription items; default to no cross-request cache.
4. **Staleness / convergence** — the local projection lags reality after an upgrade (verify→persist→**enqueue**→200), and the Stripe summary is itself eventually-consistent and caps inline entitlements at 10. **Avoid:** gate on local projection on purpose, document the window, optimistically update on host-initiated `swap_plan`/`subscribe`, and for sync apply **monotonic event-ts/id ordering** (mirror the existing `last_stripe_event_ts`/`_id` pattern). **The optional-sync work is the subtlest part of the milestone — flag it needs-deeper-research.**
5. **Ledger vs telemetry mis-split** — recording every gate check floods the immutable ledger and destroys its signal. **Avoid:** per-check decisions → telemetry only (`[:accrue, :entitlements, :check, …]`); grant/revoke/sync → `Accrue.Events.record_multi` in the same transaction as the state change.

Also load-bearing: **provider drift** (Pitfall 5 in the file) — keep the local map the canonical path for *all* providers with Stripe native as a reconciling overlay, behind the existing merge-blocking drift gate; **config/mapping drift** — boot-validate the map, key on stable ids, make unmapped-plan a *loud* fail-closed condition with telemetry; **adapter-thin identity** — gate takes an opaque billable through the `Accrue.Auth` behaviour, never a concrete Sigra/Lockspire type; and **LiveView guard hazards** (ordering vs auth, redirect loops, halt-before-load, never leak LV into core).

## Implications for Roadmap

The research converged on a **dependency-ordered build** where steps 1–5 deliver the headline JTBD
with **no new tables and no Stripe dependency**, and steps 6+ add optional Stripe-native depth that
must not block the core value. Suggested phasing (the roadmapper may merge adjacent steps):

### Phase 1: Config + Gate-API Foundation
**Rationale:** Everything feature-level depends on the host plan→feature/quota map; the fail-closed
contract and lifecycle-predicate reuse must be set here so all later surfaces inherit them. Lowest
risk, highest leverage. (`ARCHITECTURE.md` build steps 1–2.)
**Delivers:** `:plans` + `:entitlements` config keys with `NimbleOptions` validation; `Resolver`
behaviour + `LocalMap`; `Accrue.Entitlements` context with `has_active_plan?/2`, `entitled?/2`,
`features_for/1`; `Accrue` delegates; telemetry spans; Fake-backed tests.
**Addresses (FEATURES):** host map, `has_active_plan?`, `entitled?`/`features_for`, fake proof lane.
**Avoids (PITFALLS):** 1 (fail-open — property-test in exit criteria), 2 (lifecycle truth table +
predicate reuse), 4 (local-only read path), 7 (boot-validate map, unmapped→deny+telemetry).

### Phase 2: Enforcement Surfaces — Plug + LiveView Guards
**Rationale:** Both guards depend on Phase 1 but not on each other (can run in parallel). The Plug
guard is unconditional core; the `on_mount` guard is the constraint-sensitive piece and deserves its
own explicit "core stays LiveView-free" gate. (`ARCHITECTURE.md` steps 3–4.)
**Delivers:** `Accrue.Plug.RequireEntitlement` (fail-closed, `:on_denied` redirect/halt);
`Accrue.Live.Entitlements` `on_mount` (conditionally compiled) + a `without_live_view` CI matrix cell
proving core compiles absent LiveView; the one `phoenix_live_view, optional: true` core declaration.
**Uses (STACK):** `plug` (transitive), `phoenix_live_view` (optional, conditional-compile pattern).
**Implements (ARCH):** the two enforcement components + the LiveView-free reconciliation.
**Avoids (PITFALLS):** 3/4 (single resolve → stash in assigns), 6 (billable-centric, auth-agnostic),
8 (ordering-after-auth docs, halt-before-load, upgrade route outside gated session, no LV in core).

### Phase 3: Provider-Honest Matrix + Seats
**Rationale:** Provider honesty must be wired before any Stripe-specific path so the drift gate exists
first; seat predicates are table-stakes and depend only on shipped `quantity` state. (`ARCHITECTURE.md`
step 5 + FEATURES seat row.)
**Delivers:** `entitlements:` rows in `Processor.Capabilities`; `processor-support-matrix.md` update +
extended merge-blocking drift verifier; `seats_remaining/1` / `within_seat_limit?/1` read-only
predicates with documented host-owned atomicity.
**Addresses (FEATURES):** provider-honest matrix, seat/quantity quota check.
**Avoids (PITFALLS):** 5 (shared resolver core + drift gate, mirrors SCM-06/PROC-24), 9 (seat
predicate is a non-enforcing read; host owns the atomic increment).

### Phase 4: Admin Surface + Docs/JTBD Spine
**Rationale:** Operator visibility into *resolved* entitlements depends on the Phase 1 read API and
is the natural place to surface unmapped-plan drift by eye; the docs spine is the on-brand close.
(`ARCHITECTURE.md` steps 8–9.)
**Delivers:** read-only Entitlements tab on `accrue_admin CustomerLive` (Copy SSOT + VERIFY-01);
`guides/entitlements.md` (with the lifecycle→entitlement truth table); JTBD ⛔→✅ flip in
`jobs_to_be_done.md` + `JTBD-FRONTIER.md` update log; First Hour/README needles + package-doc verifier.
**Addresses (FEATURES):** admin panel, docs/JTBD flip.
**Avoids (PITFALLS):** 7 (admin shows *why* a customer is/isn't entitled).

### Phase 5 (OPTIONAL / may defer one milestone): Stripe-Native Sync
**Rationale:** Additive Stripe depth; the static host map already ships as the default that works on
Braintree/Fake. Should NOT block the milestone's core value. (`ARCHITECTURE.md` steps 6–7.)
**Delivers:** optional `accrue_entitlement_grants` cache + migration (gated install); `StripeNative`
resolver (cache-read only); `grant`/`revoke` + ledger events; `Webhook.DefaultHandler` clause for
`entitlements.active_entitlement_summary.updated` behind `stripe_sync: true`; raw calls hidden behind
a private `Accrue.Billing.Stripe.Entitlements` adapter (so a future typed-lattice_stripe swap is
internal). Document the >10-entitlement pagination limitation as a follow-up.
**Avoids (PITFALLS):** 4 (monotonic ordering, advisory-overlay-not-primary), 5 (Stripe as overlay on
the canonical local map).

### Phase Ordering Rationale

- **Dependency-driven:** the host map → `has_active_plan?` → `entitled?`/`features_for` → guards →
  matrix/seats → admin/docs → optional sync chain is exactly the order the FEATURES dependency graph
  and ARCHITECTURE build order independently produced.
- **Critical-path isolation:** steps 1–5 (≈ Phases 1–4 above) deliver the headline JTBD with **no new
  tables and no Stripe dependency** — the milestone's value lands before any optional Stripe work.
- **Constraint isolation:** the LiveView guard gets explicit treatment (own phase/sub-phase + a
  no-LV-in-core CI gate) because that is the one place the "core stays LiveView-free" promise can
  silently break.
- **Pitfall front-loading:** the two highest-leverage correctness decisions (fail-closed boolean,
  lifecycle-predicate reuse) are baked into Phase 1 exit criteria, so every downstream surface
  inherits them rather than re-deciding.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 5 (Stripe-native sync):** eventual-consistency + out-of-order summary handling + the
  10-entitlement webhook cap is the subtlest part of the milestone; flagged needs-deeper-research by
  both ARCHITECTURE and PITFALLS. Run `/gsd:plan-phase --research-phase` here.

Phases with standard / well-documented patterns (skip research-phase):
- **Phases 1–4:** every seam is codebase-verified and clones an existing Accrue pattern (telemetry
  span, `Events.record`, `nimble_options` schema, `Processor.Capabilities` matrix, conditional-compile
  à la `Integrations.Sigra`, `accrue_admin` Copy/VERIFY-01 discipline). Standard patterns; no external
  research needed beyond the requirements decisions below.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | lattice_stripe "no Entitlements API" verified against source (zero matches); all versions verified live on Hex 2026-05-22; no new deps. |
| Features | HIGH | Official docs for Stripe Entitlements, Cashier, Pay, Chargebee, Recurly; project source-of-truth for scope/non-goals; clear competitor delta. |
| Architecture | HIGH (MEDIUM on Stripe-sync timing) | Integration points read directly from the Accrue codebase; the only MEDIUM is Stripe live-read timing, which is *deferred* anyway (dep lacks the surface). |
| Pitfalls | HIGH | Lifecycle predicates, auth behaviour, telemetry/ledger contracts read from source; Stripe eventual-consistency confirmed via official docs + the known sync-engine #280 issue. |

**Overall confidence:** HIGH

### Gaps to Address

Carry these forward as **explicit requirements decisions** (not blockers — the convergence is strong,
but these are genuine forks the milestone must take a stance on):

- **Trial / past-due / paused / canceling entitlement semantics** — `active?/1` already includes
  `trialing` and `canceling`-in-window; the open decision is the `past_due` (grace) policy and the
  `paused` stance. Recommended default: `active`/`trialing`/`canceling` → entitled; `past_due` →
  entitled during the existing dunning grace window (configurable knob), not after; `paused`/`ended`/
  `incomplete_expired`/`canceled` → not entitled. **Decide in requirements; encode as the truth table.**
- **Seats/quota scope** — is v1.39 boolean-only, or do seat predicates (`seats_remaining`/
  `within_seat_limit?`) ship now? Research recommends seat *predicates* (read-only, host-owned
  atomicity) in scope, metered-quota math out. **Confirm in requirements.**
- **Optional Stripe-sync timing** — does the sync slice ship *in* v1.39 or documented-only / deferred
  one milestone? It is additive and explicitly off the critical path; either is defensible.
- **Configurable host-identity key in the `on_mount` guard** — the guard reads
  `socket.assigns[:current_user] || [:current_scope]`; the assign key should be host-configurable
  rather than hardcoded. Small but worth a requirements line.
- **STACK-vs-ARCHITECTURE nuance on core's current LiveView posture** — STACK states core has *no*
  LiveView dep today and would *add* `phoenix_live_view, optional: true`; ARCHITECTURE notes
  `accrue/mix.exs` *already* declares a non-optional `{:phoenix_live_view, "~> 1.1"}` (for
  `Phoenix.Component`/`~H` in shared invoice components, with `:phoenix` itself `optional: true`).
  This is a **phase-level detail to verify against the live `mix.exs`, not a blocker** — either way the
  `on_mount` guard ships conditionally-compiled and core stays runtime-LiveView-free. Resolve when
  planning Phase 2.

## Sources

### Primary (HIGH confidence)
- `/Users/jon/projects/lattice_stripe` source (read directly) — `@version "1.1.0"`; `lib/.../billing/` = Meter/MeterEvent only; `event.ex` `from_map/1` infallible + type-agnostic `data`; `request.ex`/`client.ex` public `request/2`, `api_version "2026-03-25.dahlia"`; `grep -ri entitlement` → zero matches.
- Accrue codebase (read directly 2026-05-22) — `billing.ex` (`span_billing`, `Repo.transact` + `Events.record`), `processor.ex`/`capabilities.ex` (behaviour + `@provider_support_labels`), `integrations/sigra.ex` (conditional-compile 4-pattern), `events.ex`/`telemetry.ex` (ledger + span/OTel no-op), `auth.ex`/`plan_resolver.ex`/`config.ex` (runtime dispatch + nimble_options), `billing/subscription.ex`+`query.ex`+`subscription_item.ex` (lifecycle predicates + `price_id` path), `plug/*`, `webhook/default_handler.ex`, `accrue_admin .../auth_hook.ex`, `accrue/mix.exs`.
- `guides/lifecycle_semantics.md` — `active` = "counts for entitlement purposes," includes trialing; convergence/local-truth; provider-label vocabulary.
- `.planning/PROJECT.md` — v1.39 goal/scope/non-goals, config-vs-runtime boundary, conditional-compilation pattern, monorepo layout, dual-provider drift-gate culture (v1.33–v1.37).
- `.planning/research/JTBD-FRONTIER.md` — entitlements = #1 gap; "thin, high-leverage layer over local state"; canonical SaaS loop.
- `.planning/seeds/SEED-002-ecosystem-integrations.md` #4 — Sigra/Lockspire adapter-thin identity tie-in.
- Hex.pm API (live 2026-05-22) — `lattice_stripe` 1.1.0, `phoenix_live_view` 1.1.30 stable, `plug` 1.19.2.
- Official docs (HIGH) — Stripe Entitlements API (Feature/ProductFeature/ActiveEntitlement + summary webhook); Laravel Cashier (`subscribed()`, no first-party entitlements); Pay (`active?`/`on_trial?`, no entitlements); Chargebee Features/Entitlements (Switch/Quantity/Range/Custom); Recurly Entitlements.

### Secondary (MEDIUM confidence)
- Stripe Entitlements timing/eventual-consistency + 10-entitlement summary cap — official docs + Stripe sync-engine issue #280.
- Entitlement mental model (boolean vs quota/seat vs metered) — Schematic, Lago, Stigg vendor explainers (consensus).
- Fail-open vs fail-closed for feature gating — Unleash, Salable (default-deny best practice).

### Tertiary (LOW confidence)
- Stripe events eventual-consistency pagination/skip risks — Sequin blog (informs the monotonic-ordering recommendation; validate during Phase 5 planning).

---
*Research completed: 2026-05-22*
*Ready for roadmap: yes*
