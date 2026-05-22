# Feature Research — Entitlements / Plan-Gating

**Domain:** First-party feature-gating layer for an Elixir/Phoenix subscription-billing library (Accrue v1.39)
**Researched:** 2026-05-22
**Confidence:** HIGH

> Scope guardrail: this file covers **only** the entitlements / plan-gating milestone (v1.39). All
> existing billing surface (subscription lifecycle, checkout, invoices, refunds, coupons, metering,
> tax, webhooks, dunning, audit ledger, telemetry, `accrue_admin`) is shipped and **out of scope to
> re-research**. The headline fact framing this milestone: a private `Subscription.is_active?/1`
> exists, but there is **no public way to gate a feature** on it. Closing that single gap is the whole
> milestone. (Sources: `.planning/research/JTBD-FRONTIER.md`, `accrue/guides/jobs_to_be_done.md`.)

## The mental model (read this first)

Every entitlement system answers one question — **"is this billable allowed to do X right now?"** — by
resolving a chain:

```
plan / product (what they bought)
   └─ maps to ──> features + quotas (what that grant unlocks)
        └─ checked against ──> the billable's CURRENT subscription state (do they still hold it?)
             └─ yields ──> allow | deny | (allow-with-limit)
```

The industry splits "what a grant unlocks" into three entitlement shapes (Chargebee names all four
explicitly; Stripe ships only the first; Schematic/Stigg/Lago describe the same taxonomy):

| Shape | Question it answers | Example | Accrue v1.39 posture |
|-------|---------------------|---------|----------------------|
| **Boolean / switch** | Do they have the feature at all? | "Pro unlocks SSO" | **Table stakes — the milestone core** |
| **Numeric quota / seat** | How many are they allowed? | "Team plan = 10 seats" | **Table stakes (seat counts only)** |
| **Tiered limit / range / metered-as-entitlement** | How much of a metered resource? | "5,000 API calls/mo, then block" | **Anti-feature for v1.39** (explicitly out of scope per `PROJECT.md`; defer the metering→quota math) |

Two truths from the project context shape every recommendation below:

1. **Accrue already holds the source of truth it needs.** Subscription state (status, plan/price,
   quantity) is a faithful local mirror kept honest by webhooks. Entitlements is a *thin derivation
   layer over data already present* — not a new domain. This is why JTBD-FRONTIER ranks it the
   fastest high-value win.
2. **Accrue is provider-honest.** Stripe ships a first-class Entitlements API; Braintree has none; the
   Fake processor must be deterministic. The gate must read the same regardless, with honest support
   labels — exactly the pattern already used for `swap_plan` / `cancel_at_period_end`.

---

## Feature Landscape

### Table Stakes (Phoenix devs expect these the moment billing works)

Missing any of these makes the milestone feel incomplete — "I'm subscribed, now what do I gate on?"

| Feature | Why Expected | Complexity | Notes / Dependency |
|---------|--------------|------------|--------------------|
| **`has_active_plan?(billable, plan)`** core check | The literal #1 JTBD ("I'm subscribed — gate the pro feature"). Direct analog of Cashier `subscribed()` / Pay `active?`. | **LOW** | Reads existing local subscription status + plan/price. Pure derivation over shipped `Subscription.is_active?/1`. No external call. |
| **`entitled?(billable, :feature)`** feature-level check | Devs gate on *capabilities* (`:sso`, `:advanced_reports`), not raw plan strings — decouples code from pricing. Stripe's whole `lookup_key` model exists for this. | **LOW–MEDIUM** | Requires the plan→feature map (next row). Returns boolean. |
| **Host-declared plan→feature/quota map** | Source of truth that works on **every** provider, including Braintree/Fake which have no entitlements API. Mirrors how Pay/Cashier shops hand-roll it today. | **MEDIUM** | Static config (e.g. `config :accrue, :entitlements, ...`) validated via `NimbleOptions` (already a dep). Foundational — everything else depends on it. |
| **`features_for(billable)` / list active entitlements** | Devs render "your plan includes…" UI and operators audit access. Stripe exposes `GET /v1/entitlements/active_entitlements`; Recurly/Chargebee have the same list endpoint. | **LOW–MEDIUM** | Derives the resolved feature set from current subscription(s) + map. |
| **Seat / quantity quota check** (`within_quota?` / `seats_remaining`) | Per-seat SaaS is ubiquitous; subscription `quantity` already exists locally. Cashier/Pay shops check this manually. | **MEDIUM** | Reads existing `quantity` / `update_quantity` state. Count-of-seats only, **not** metered-usage math. |
| **Controller Plug guard** (`require_plan` / `require_feature`) | The idiomatic Phoenix enforcement surface — pipelines gate routes. Cashier ships middleware; Pay shops write before_actions. | **MEDIUM** | Thin Plug over the core checks. Must degrade gracefully (redirect/halt), not just raise. SEED-002 #4 names this explicitly. |
| **LiveView `on_mount` guard** | Phoenix SaaS is LiveView-first; route-level gating for `live_session`. No comparator offers this — but Phoenix devs *expect* it because every other Phoenix concern (auth) ships one. | **MEDIUM** | Must keep `phoenix_live_view` **optional in core** (it's a hard dep only in `accrue_admin`). Compile-guard like the other optional integrations. |
| **Fail-closed default + explicit graceful UX** | Security expectation: an unknown/unresolvable entitlement must **deny** by default (don't leak paid features). But UX expectation: deny should redirect to an upgrade prompt, not a bare 403. | **MEDIUM** | Configurable `:on_denied` (redirect path / handler) at the guard layer; fail-closed in the *function* layer. See Pitfalls. |
| **Telemetry + audit-ledger recording on gate decisions** | Accrue's whole moat is observability + tamper-evident ledger; an ungoverned gate would be inconsistent with the rest of the library. PROJECT.md mandates telemetry on all public entry points. | **MEDIUM** | `[:accrue, :entitlements, :check, :start/:stop/:exception]` spans; record grant/deny to `Accrue.Events`. Reuses shipped span + ledger infra. |
| **Fake-processor deterministic proof lane** | The Fake is "the merge-blocking proof lane the library ships on." Entitlements must be testable with no network. | **LOW** | Fake resolves entitlements from the same host map / in-memory subscription state. |
| **Admin surface: show a customer's active entitlements** | Operators must answer "what does this customer have access to right now?" Chargebee/Recurly admin both show this; it's a basic support-desk need. | **MEDIUM** | New read-only panel/tab in `accrue_admin` customer detail. Reuses `features_for/1`. Must follow shipped `AccrueAdmin.Copy` SSOT + `ax-*`/theme/VERIFY-01 discipline. |
| **`guides/entitlements.md` + JTBD ⛔→✅ flip + First Hour spine** | Every shipped Accrue capability has the docs/proof-matrix rigor; entitlements without it would be off-brand. | **LOW–MEDIUM** | Doc contract verifiers (`verify_package_docs`, adoption matrix needles) per established pattern. |

### Differentiators (where Accrue leads — Pay & Cashier have NONE of this)

The ecosystem benchmark (JTBD-FRONTIER) is unambiguous: **Pay and Laravel Cashier ship no first-party
entitlements at all** — their users hand-roll plan→feature maps. Stripe/Chargebee/Recurly have
entitlements but they're processor- or product-locked. Accrue's opening is *idiomatic Phoenix
entitlements that are provider-honest and observable*.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **First-party LiveView `on_mount` entitlement guard** | No comparator ships one. This is the single most "Phoenix-native" differentiator — gating a `live_session` on what someone paid for, in one line. | **MEDIUM** | The headline DX win. Optional-LiveView discipline keeps core clean. |
| **Provider-honest entitlement matrix** (Stripe native · Braintree/Fake local map · Fake proof) | Honesty Pay/Cashier don't need (single-provider) and Stripe can't give (Stripe-only). The gate reads identically; support labels tell the truth — same pattern as `swap_plan`. | **MEDIUM** | Reuses shipped support-matrix + drift-gate machinery. |
| **Optional Stripe Entitlements sync** via `entitlements.active_entitlement_summary.updated` | Lets a shop that manages features in the Stripe Dashboard get the same gate without re-declaring the map in Elixir. Matches Stripe's recommended "persist entitlements internally for fast auth checks" guidance. | **MEDIUM–HIGH** | Consume the webhook (ingest path already exists), project into a local entitlement table, fall back to host map. Keep **optional** — the static map is the default that works everywhere. |
| **Gate decisions in the tamper-evident audit ledger** | "Why was this user denied SSO on March 1?" answerable with proof. Stripe/Chargebee/Recurly don't expose an immutable gate-decision trail. Extends an existing moat to a new surface. | **MEDIUM** | Append-only `Accrue.Events` already enforces immutability at the PG-trigger level. |
| **`Accrue.Auth`-adapter-thin identity tie-in (Sigra/Lockspire optional)** | SEED-002 #4: map entitlement checks onto host session identity / OAuth scopes — *without Accrue owning the user schema*. Enterprise-credible, but never required. | **MEDIUM** | Keep adapter-thin per the milestone's explicit "no deep Sigra/Lockspire coupling" boundary. The gate takes a billable; identity wiring is the host's. |

### Anti-Features (commonly requested for entitlements — wrong for Accrue v1.39)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Metered-usage-as-entitlement / overage enforcement** (count API calls, block at 5k, apply overage) | Chargebee/Stigg/Lago market it; feels like "complete" entitlements. | Explicitly out of scope per `PROJECT.md` v1.39 ("rich quota/metering-as-entitlement math beyond seat counts"). It's a different, heavier domain — needs real-time counters + reconciliation. Accrue's metering already exists for *billing*; fusing it into *gating* invites the FIN-03/analytics scope-creep trap JTBD-FRONTIER warns against. | Seat/quantity quotas only in v1.39. Metered gating is a future-milestone candidate, gated on a sourced request. |
| **Accrue-owned feature-catalog CRUD UI** (define/edit features in `accrue_admin`) | Chargebee/Recurly have a feature-builder UI; feels expected. | Makes Accrue the catalog source of truth, fighting both Stripe's native catalog and the host's static config. Mirrors the deferred "Stripe Dashboard meter setup UX stays host/Stripe documentation" decision in `PROJECT.md`. | Host declares features in config (default) **or** in the Stripe Dashboard (synced). Admin **shows** entitlements, doesn't author them. |
| **Building a general-purpose feature-flag system** | "Entitlements ≈ feature flags" conflation is everywhere in the search results. | Feature flags (gradual rollout, A/B, kill switches) are an orthogonal concern (LaunchDarkly territory). Entitlements gate on *paid grants*, not rollout state. Scope-creep into a non-billing product. | Gate strictly on billing/subscription state. If a host wants rollout flags, that's their flag lib feeding the host map. |
| **Fail-open by default** | "Don't lock users out on a transient error" is a tempting safety default. | Fail-open leaks paid features whenever the check errors — a revenue + trust hole. Inconsistent with a billing library's duty. | **Fail-closed by default** in the function layer; let hosts opt into graceful fallback explicitly, with the denial logged to telemetry/ledger. |
| **Real-time entitlement recompute on every Stripe change with strong consistency guarantees** | "My gate must reflect Stripe instantly." | Stripe's `active_entitlement_summary.updated` is webhook-driven and Stripe itself recommends persisting locally; chasing strict real-time consistency re-introduces the "block page render on a Stripe call" anti-pattern Accrue explicitly avoids. | Gate on the **local mirror** (already webhook-synced); sync is eventually-consistent and that's the documented, honest contract. |
| **Caching entitlement results behind the host's back** | "Checks should be fast." | The local check *is already fast* (one Ecto read). A hidden cache creates stale-grant bugs (denied user still sees feature) that are nasty to debug. | No hidden cache in v1.39. Each check reads the local mirror. Document the read cost; let hosts cache if they measure a need. |

---

## Feature Dependencies

```
Host-declared plan→feature/quota map  (FOUNDATION)
        │
        ├──required-by──> entitled?(billable, :feature)
        │                      │
        │                      ├──required-by──> features_for(billable)
        │                      ├──required-by──> Plug guard (require_feature)
        │                      └──required-by──> LiveView on_mount guard (require_feature)
        │
        └──required-by──> within_quota? / seats_remaining   (also needs: subscription quantity — SHIPPED)

has_active_plan?(billable, plan)  ──depends-on──> Subscription status mirror  (SHIPPED)

Telemetry spans + audit-ledger recording  ──enhances──> ALL checks  (infra SHIPPED)

Optional Stripe Entitlements sync
        ├──depends-on──> webhook ingest path  (SHIPPED)
        ├──depends-on──> new local entitlement projection table  (NEW)
        └──provides-alternative-source-for──> entitled? / features_for
                 (host map remains the default fallback)

Admin "active entitlements" panel  ──depends-on──> features_for(billable)
        └──depends-on──> accrue_admin LiveView + AccrueAdmin.Copy + VERIFY-01  (SHIPPED)

Accrue.Auth-thin identity tie-in  ──enhances──> Plug + on_mount guards  (Accrue.Auth SHIPPED; keep thin)
```

### Dependency Notes

- **Everything feature-level depends on the host map.** Build the plan→feature/quota declaration +
  validation first; `entitled?`, `features_for`, and both guards are thin layers on it.
- **`has_active_plan?` depends only on shipped subscription state** — it can land independently and
  earliest (lowest complexity, validates the whole approach).
- **Both guards depend on the core checks**, not on each other. The Plug guard has no LiveView
  dependency; the `on_mount` guard must compile-guard `phoenix_live_view` (optional in core).
- **Stripe sync is additive, not foundational.** It's an alternative *source* feeding the same
  `entitled?`/`features_for` surface. The static host map must work with zero sync wired — that's
  what keeps Braintree/Fake honest.
- **Quota/seat checks depend on shipped `quantity` state**, reusing `update_quantity`/`update_item_quantity`.
- **Telemetry + ledger recording reuse shipped infra** — no new foundation, but every check must be
  instrumented to stay consistent with the rest of Accrue.

---

## MVP Definition

> "MVP" here = the v1.39 milestone scope. Per the project's "ship complete, not MVP" doctrine, the
> milestone ships as a coherent complete layer — but ordering within it still matters for phases.

### Launch With (v1.39 core)

- [ ] **Host-declared plan→feature/quota map + NimbleOptions validation** — the foundation everything reads.
- [ ] **`has_active_plan?(billable, plan)`** — earliest, lowest-risk, validates the derivation approach.
- [ ] **`entitled?(billable, :feature)` + `features_for(billable)`** — the core feature-level surface.
- [ ] **Seat/quantity quota check** (`within_quota?` / `seats_remaining`) — table-stakes count-quota.
- [ ] **Controller Plug guard** (`require_plan` / `require_feature`) with fail-closed + `:on_denied` UX hook.
- [ ] **LiveView `on_mount` guard** (optional-LiveView, compile-guarded) — the headline differentiator.
- [ ] **Telemetry spans + audit-ledger recording** on all checks.
- [ ] **Fake-processor deterministic proof lane** — merge-blocking.
- [ ] **Provider-honest support matrix** (Stripe native · Braintree/Fake local map).
- [ ] **`accrue_admin` active-entitlements panel** (read-only) on customer detail.
- [ ] **`guides/entitlements.md` + JTBD ⛔→✅ flip + First Hour/README spine + doc verifiers.**

### Add After (this milestone, if capacity — else next)

- [ ] **Optional Stripe Entitlements sync** via `entitlements.active_entitlement_summary.updated` — high value but additive; the host map ships first as the default. Reasonable to land late in the milestone or defer one milestone without breaking the core promise.
- [ ] **`Accrue.Auth`-thin identity tie-in recipe** (Sigra/Lockspire optional) — keep adapter-thin per the explicit milestone boundary; can be a docs-led recipe rather than new code.

### Future Consideration (explicitly NOT v1.39)

- [ ] **Metered-usage-as-entitlement / overage enforcement** — out of scope per `PROJECT.md`; future milestone, sourced-request-gated.
- [ ] **Tiered/range numeric limits beyond seat counts** — Chargebee's "Range" type; defer.
- [ ] **Feature-catalog authoring UI in admin** — host/Stripe owns authoring; admin only displays.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Host plan→feature/quota map + validation | HIGH | MEDIUM | P1 (foundation) |
| `has_active_plan?` | HIGH | LOW | P1 |
| `entitled?` / `features_for` | HIGH | LOW–MEDIUM | P1 |
| Seat/quantity quota check | HIGH | MEDIUM | P1 |
| Controller Plug guard | HIGH | MEDIUM | P1 |
| LiveView `on_mount` guard | HIGH | MEDIUM | P1 (differentiator) |
| Fail-closed + graceful `:on_denied` UX | HIGH | MEDIUM | P1 |
| Telemetry + audit-ledger recording | MEDIUM | MEDIUM | P1 (on-brand) |
| Fake deterministic proof lane | HIGH | LOW | P1 |
| Provider-honest support matrix | MEDIUM | MEDIUM | P1 |
| Admin active-entitlements panel | MEDIUM | MEDIUM | P1 |
| `guides/entitlements.md` + doc spine | MEDIUM | LOW–MEDIUM | P1 |
| Optional Stripe Entitlements sync | MEDIUM–HIGH | MEDIUM–HIGH | P2 |
| `Accrue.Auth`-thin identity recipe | MEDIUM | MEDIUM | P2 |
| Metered-as-entitlement / overage | (deferred) | HIGH | P3 (out of scope) |
| Feature-catalog authoring UI | LOW | HIGH | P3 (anti-feature) |

**Priority key:** P1 = milestone core · P2 = additive, land late or next milestone · P3 = future/out-of-scope.

---

## Competitor Feature Analysis

| Capability | Pay (Rails) | Laravel Cashier | Stripe Billing native | Chargebee / Recurly | Accrue v1.39 plan |
|------------|-------------|-----------------|-----------------------|---------------------|-------------------|
| First-party entitlements? | **⛔ none** | **⛔ none** | ✅ Entitlements API (2024) | ✅ mature | ✅ first-party (the milestone) |
| Plan/active check | `subscription.active?`, `on_trial?`, `on_trial_or_subscribed?` | `subscribed()`, `subscribedToPrice()` | subscription status | yes | `has_active_plan?` |
| Feature-level check | hand-rolled by host | hand-rolled by host | `lookup_key` on ActiveEntitlement | feature objects | `entitled?(billable, :feature)` |
| Boolean features | host code | host code | ✅ (boolean-only) | ✅ Switch type | ✅ |
| Numeric quota / seat | host code (uses `quantity`) | host code (uses `quantity`) | ⛔ (boolean-only) | ✅ Quantity/Range type | ✅ seat counts only |
| Tiered/metered-as-entitlement | ⛔ | ⛔ | ⛔ | ✅ | **anti-feature (defer)** |
| Source of truth | local subscription | local subscription | Stripe catalog (Feature/ProductFeature) | their catalog | **host static map (default) + optional Stripe sync** |
| Enforcement helpers | before_action (host) | middleware | none (you build it) | SDK/API | **Plug guard + LiveView on_mount** |
| Webhook for entitlement change | n/a | n/a | `entitlements.active_entitlement_summary.updated` | webhooks | **optionally consumed** |
| Gate-decision audit trail | ⛔ | ⛔ | ⛔ | partial | ✅ tamper-evident ledger (differentiator) |
| Observability on checks | ⛔ | ⛔ | n/a | n/a | ✅ telemetry spans (differentiator) |

**How Stripe's native Entitlements API works (HIGH confidence — official docs):**
- **`Feature`** object: `name` + immutable `lookup_key` (your gate key) + `metadata`. Created via
  `POST /v1/entitlements/features`.
- **`ProductFeature`**: links a `Feature` to a Stripe `Product` (`POST /v1/products/{id}/features`). One
  feature can attach to many products.
- **`ActiveEntitlement`**: a customer's single active feature grant; carries `feature` + `lookup_key` +
  `livemode`. Listed via `GET /v1/entitlements/active_entitlements?customer={id}`.
- **`ActiveEntitlementSummary`**: all active entitlements for a customer; the webhook payload caps at
  **10** entitlements — fetch the rest via `entitlements.url`.
- **Computation:** subscribing to a product **automatically** creates ActiveEntitlements for that
  product's features; cancel/failure revokes them. Created **simultaneously with the subscription**
  (no documented intentional lag, but it's eventually-consistent via webhook).
- **Webhook:** `entitlements.active_entitlement_summary.updated` fires on subscribe/change/cancel.
  Stripe's own guidance: **persist entitlements internally for fast auth checks** and reconcile by
  calling the list endpoint — exactly the local-mirror model Accrue already uses everywhere.
- **Boolean only:** Stripe Entitlements has **no quota/metered tier** — features are on/off. (This is
  why Accrue must source seat quotas from local `quantity`, not from Stripe Entitlements.)

**Provider-honesty summary (the matrix Accrue must ship):**
- **Stripe:** native Entitlements available → optional sync from the summary webhook; OR host static map.
- **Braintree:** **no entitlements API** → local plan→feature mapping is the *only* path (same shape as
  the local promo-discount mapping shipped in v1.33).
- **Fake:** deterministic resolution from the host map / in-memory subscription state → merge-blocking proof lane.

---

## Pitfalls flagged for requirements (entitlements-specific)

These are feature-shaping decisions the requirements must take a stance on, not just implementation hazards:

1. **Fail-open is the cardinal sin.** Default must be fail-closed at the function layer; graceful UX
   (redirect/upgrade-prompt) is a *guard-layer* opt-in, and every denial must be logged. A check that
   silently returns "allowed" on error leaks paid features.
2. **Trial/grace/past-due ambiguity.** `has_active_plan?` must take an explicit, documented stance on
   `:trialing`, `:past_due` (grace), and `:paused` — Cashier's `subscribed()` counts trials as active;
   Pay separates `active?` from `on_trial?`. Accrue should mirror its own shipped lifecycle semantics
   (`lifecycle_semantics.md`) and be explicit, since "is a trialing/grace user entitled?" is the most
   common real-world dispute. Depends on shipped subscription-state semantics.
3. **Plan-string coupling.** Encourage `entitled?(:feature)` over `has_active_plan?("price_pro")` in
   docs so host code doesn't hard-code price IDs — the same decoupling Stripe's `lookup_key` exists for.
4. **Stripe sync staleness / 10-entitlement webhook cap.** If sync is built, the local projection must
   reconcile via the list endpoint (not trust the capped webhook payload) — a known Stripe gotcha
   (sync-engine issue #280). Document that sync is eventually-consistent.
5. **LiveView optionality.** The `on_mount` guard must not pull `phoenix_live_view` into core deps —
   compile-guard it like the other optional integrations, or the "core stays LiveView-free" constraint
   breaks.

---

## Sources

- **Stripe Entitlements API** (HIGH — official docs): https://docs.stripe.com/billing/entitlements ·
  Active Entitlement object/list: https://docs.stripe.com/api/entitlements/active-entitlement ·
  webhook timing + 10-cap gotcha: https://docs.stripe.com/billing/subscriptions/webhooks ,
  https://github.com/stripe/sync-engine/issues/280
- **Laravel Cashier** (HIGH — official docs): subscription checks `subscribed()` / incomplete payment —
  https://laravel.com/docs/13.x/billing — confirms **no first-party feature entitlements** (host hand-rolls).
- **Pay (Rails)** (HIGH — official docs): `active?` / `on_trial?` / `on_trial_or_subscribed?` —
  https://github.com/pay-rails/pay/blob/main/docs/6_subscriptions.md — confirms **no entitlements layer**.
- **Chargebee Features/Entitlements** (HIGH — official docs): four types (Switch/Quantity/Range/Custom),
  plan mapping, subscription overrides — https://www.chargebee.com/docs/billing/2.0/entitlements/features-overview ,
  https://apidocs.chargebee.com/docs/api/subscription_entitlements
- **Recurly Entitlements** (MEDIUM–HIGH — official docs): entitlements granted via plan/add-on purchase,
  list-active-entitlements-per-account API — https://docs.recurly.com/docs/entitlements
- **Entitlement mental model** (MEDIUM — multiple vendor explainers agree): boolean vs quota/seat vs
  metered, enforcement allow/deny/limit — https://schematichq.com/blog/software-entitlements ,
  https://getlago.com/blog/saas-entitlements , https://www.stigg.io/blog-posts/entitlements-untangled-the-modern-way-to-software-monetization
- **Project context** (HIGH — repo source of truth): `.planning/PROJECT.md` (v1.39 goal/scope/non-goals),
  `.planning/research/JTBD-FRONTIER.md` (benchmark + #1 ranking), `.planning/seeds/SEED-002-ecosystem-integrations.md`
  (#4 Sigra/Lockspire tie-in), `accrue/guides/jobs_to_be_done.md` (mental model, "thin layer" framing).

---
*Feature research for: entitlements / plan-gating (Accrue v1.39)*
*Researched: 2026-05-22*
