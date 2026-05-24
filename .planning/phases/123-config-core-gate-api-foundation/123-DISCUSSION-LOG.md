# Phase 123: Config + Core Gate API Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-22
**Phase:** 123-config-core-gate-api-foundation
**Areas discussed:** Config schema (A), Gate API surface & contracts (B), Module layout & Resolver-seam timing (C), Telemetry/observability contract (D)

**Mode:** Cohesive-synthesis (standing user preference `feedback_decision_synthesis_style`).
5 parallel `gsd-advisor-researcher` agents — one per gray area, plus one to settle the
dual-API fork. Each researched pros/cons, idiomatic Elixir/Phoenix/Plug/Ecto, cross-language
lessons (Pay, Cashier, Stripe Entitlements, Chargebee, Recurly, LaunchDarkly, Unleash,
OpenFeature, pricing_plans), DX/footguns, and the `.planning/research/` dir. The user declined
to adjudicate the one fork I surfaced (dual-API) and directed me to research + decide it —
recorded as a sharpened auto-resolve bar (see Claude's Discretion).

---

## A — Plan→Feature/Quota Config Schema (ENT-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Logical-plan-keyed map + `price_ids:` per plan | `pro: [features:, limits:, price_ids:]`; canonical plan identity, churn-resilient, native NimbleOptions atom-key validation | ✓ |
| price_id-keyed map | `"price_abc" => [features:]`; zero indirection but Cashier's coupling pain, stringly-typed, no logical tier | |
| Stripe-Entitlements-synced | Provider is source of truth | (out of scope — Phase 127) |

**Choice:** Logical-plan keying. Top-level `:entitlements` runtime keyword list with `:plans`,
`:resolver`, `:unmapped_action` (default `:deny`); boot-built price_id→plan reverse index;
collision raises at boot.
**Notes:** Runtime side (host catalog data, may differ per env), boot-validated. Seats =
`min(config :limits cap, subscription quantity)`.

---

## B — Public Gate API Surface & Fail-Closed Contract (ENT-02/03/04)

| Option | Description | Selected |
|--------|-------------|----------|
| Boolean-only | 4 fail-closed value/predicate fns; diagnostic via telemetry `reason` | ✓ |
| Dual API now | also ship `fetch_entitled/2 :: {:ok,bool}\|{:error,_}` | |
| `?`-predicate raising on infra error | explicit error vs false | (rejected — violates fail-closed) |

**Choice:** Boolean-only. `has_active_plan?/2`, `entitled?/2`, `features_for/1` (sorted/deduped/
union), `entitlement_quantity/2` (fail-closed `0`), all delegated `Accrue.*` → `Accrue.Entitlements`.
**Notes:** Single private resolver `{:ok,true}|{:ok,false}|{:error,_}` collapsed to a boolean
with `try/rescue/catch`. Read-only path (no `Billing.customer/1`). `stream_data`
never-true-on-garbage property test. Dual-API fork → see Claude's Discretion.

---

## C — Module Layout & Resolver-Seam Timing (architecture)

| Option | Description | Selected |
|--------|-------------|----------|
| Seam now (`Resolver` behaviour + `LocalMap` only) | matches Accrue behaviour-first habit; 125/127 purely additive | ✓ |
| Inline now, extract behaviour in 125 | smallest 123 diff but forces a refactor of the shipped gate in 125 | |

**Choice:** Seam now. New `lib/accrue/entitlements/` tree (`entitlements.ex`, `resolver.ex`,
`resolver/local_map.ex`, `plan.ex`); runtime dispatch like `Processor`/`plan_resolver`;
one-way dep (entitlements→billing) grep-enforced. ENT-08's capability matrix + drift gate
stay in Phase 125.
**Notes:** Touches the locked roadmap on its face but does not contradict it (125 still owns
ENT-08). Auto-applied as a Claude-owned architecture call.

---

## D — Telemetry / Observability Contract (ENT-05)

| Option | Description | Selected |
|--------|-------------|----------|
| `[:accrue, :entitlements, :check]` (plural) | matches house style (domain=layer name) + `:webhooks` precedent | ✓ |
| `[:accrue, :entitlement, :check]` (singular) | literal ROADMAP/ENT-05 text | |
| new `span_entitlement` wrapper | vs reuse `Telemetry.span/3` inline | (rejected — single-op domain) |

**Choice:** Plural event name (supersedes the singular slip in ROADMAP SC#5 + ENT-05 — reconcile
those docs). Reuse `Telemetry.span/3` inline (storage.ex template). Bounded-cardinality
metadata (`feature`, `result`, `resolver`, `reason`, span-only `subject_id`). OTel allowlist
additions. **Zero ledger writes in Phase 123.**
**Notes:** Verified `:webhooks`/`:billing`/`:storage` prefixes in `lib/` — domain segment is
the layer name; `Accrue.Entitlements` is plural.

---

## Claude's Discretion

- **Dual-API fork (B) — researched & auto-resolved to boolean-only.** I surfaced this via
  AskUserQuestion; the user declined to answer and instructed me to research it with subagents
  and decide ("except for VERY impactful ones I might actually care about"). A dedicated
  `gsd-advisor-researcher` settled it: a `?`-predicate + `fetch_`-tuple pairing exists nowhere
  in Accrue (tuple/bang pairs are I/O-only); ENT-03/04/05 enumerate only boolean/value fns and
  route diagnostics to telemetry; a truthy `{:error,_}` would ship the fail-open footgun the
  milestone prevents; `fetch_entitled/2` is additive-safe to add later. **Lesson recorded:**
  sharpened the auto-resolve bar — additive-safe / reversible decisions are auto-resolvable even
  when public-API-shaped. Persisted as `config.json#discuss_high_impact_confirm_bar` and in the
  `feedback_decision_synthesis_style` memory.
- Logical-plan keying, `unmapped_action: :deny`, `min(cap, quantity)` seats, resolver-seam-now,
  plural telemetry name + doc reconcile — all auto-applied (research-backed, reversible/additive).

## Deferred Ideas

- `fetch_entitled/2` / `fetch_entitlement_quantity/2` diagnostic API — additive, on sourced need.
- ENT-08 capability matrix + drift gate → Phase 125; ENT-09 truth table + past_due grace → 125.
- ENT-06/07 Plug + LiveView guards → Phase 124 (verify mix.exs LiveView posture there).
- ENT-11/12 admin view + guides + JTBD flip → Phase 126.
- ENT-10 optional Stripe-native sync + grant/revoke + ledger writes → Phase 127.
- Atomic seat enforcement — host-owned recipe, never a core API.
</content>
