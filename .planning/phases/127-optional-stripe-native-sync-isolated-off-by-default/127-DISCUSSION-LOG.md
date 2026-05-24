# Phase 127: Optional Stripe-Native Sync (isolated, off by default) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-24
**Phase:** 127-optional-stripe-native-sync-isolated-off-by-default
**Areas discussed:** Overlay semantics, Config shape + isolation enforcement, Cache schema/persistence, Audit ledger + telemetry/observability

---

> **Method.** The user declined per-area Q&A and invoked the standing cohesive-one-shot-synthesis
> preference: deep parallel research, then a single coherent recommendation set, surfacing only
> truly-irreversible/published forks. Four `gsd-advisor-researcher` agents ran in parallel — one
> per area — grounded in `127-RESEARCH.md`, the `lattice_stripe/prompts/` deep-research corpus,
> `.planning/research/` (esp. PITFALLS.md), the live codebase, and peer libraries (Pay, Laravel
> Cashier, supabase/stripe-sync-engine, Lago, Stigg, LaunchDarkly/Unleash). All four independently
> concluded their decision was additive/reversible — **no fork cleared the surface-to-user bar** —
> so everything was decided. The original AskUserQuestion fork (overlay semantics) was withdrawn
> and decided by research.

## Overlay semantics

| Option | Description | Selected |
|--------|-------------|----------|
| A. Observational-only | Cache written/ledgered/telemetered/read-seam-exposed; gate path NEVER reads it; `entitled?` ON == OFF == Phase 126 | ✓ |
| B-merge. Additive overlay | `entitled?` true if local OR cached-Stripe grants (additive union, never denies), composed around `LocalMap` | |
| B-combining. Resolver swap | Replace `Resolver.__impl__/0` impl to merge cache — rejected (hijacks the host resolver-swap seam, hardest to prove inert) | |

**Choice:** A (Observational-only). **Notes:** Decisive rationale — forecloses nothing
(A→B is non-breaking; B→A would break hosts → aligns with "zero breaking-change through v1.x");
local map is already a superset, so B "solves" a host catalog-mapping bug by introducing an
eventual-consistency authorization surface; A makes the isolation proof + fail-closed property
trivially true even when ON. Peer-lib evidence: LaunchDarkly/Unleash cache-feeds-decision fail-open
+ stale bug class; Stigg needs a degraded-answer indicator if a cache gates (impossible via a 2-value
boolean); Accrue's own PITFALLS.md already ruled "advisory/secondary overlay, not a separate truth."
SC#1's "advisory overlay" reconciled to "observational advisory cache" for the verifier (D-02).

---

## Config shape + isolation enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Boolean `stripe_native_sync: false` | Simplest; but a future `:reconcile`/influence mode forces a breaking type-flip | |
| Enum `{:in, [:disabled, :advisory]}` default `:disabled` | Append-only future-proof; matches `unmapped_action`/`past_due_grace` enum precedent; self-documenting | ✓ |
| Richer enum `[:disabled, :observe, :reconcile]` now | Ships unimplemented modes (footgun: a value whose name doesn't match behavior) | |
| Isolation: conditional compilation | Rejected — no new dep to gate on; reserved for optional-dep presence | |
| Isolation: runtime gate + static grep gate + zero-read test | Idiomatic (mirrors `past_due_grace: :none` runtime off-lane) | ✓ |

**Choice:** Enum + runtime-gate three-layer proof. **Notes:** Enum lets `:reconcile` (1.2) and a
future gate-influence value append without host churn; accessor supplies its own default via
`Keyword.get/3` (entitlements/0 is a raw read). Isolation = runtime gate checked-first +
`scripts/ci/verify_entitlement_sync_isolation.sh` (clone of the LiveView-runtime-free gate) +
`[:accrue, :repo, :query]` zero-read integration test. Peer footgun: oban#216 (boolean that couldn't
grow into a list).

---

## Cache schema / persistence

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated `accrue_entitlement_summaries` table + raw JSONB `data` | One row/customer; own watermark; droppable; matches `subscription_schedules` convention | ✓ |
| JSONB column on `accrue_customers` | Rejected — watermark collision on the hot row; breaks off-lane DB-free | |
| `embeds_many` typed snapshot | Rejected — re-types an untyped upstream; 0 embeds in codebase; drifts | |
| Normalized child rows (one/entitlement) | Rejected — = the supabase/stripe-sync-engine #280 >10-cap bug | |

**Choice:** Dedicated table, raw JSONB snapshot, typed `truncated`/`entitlement_count`/`synced_at`
columns + cloned `last_stripe_event_ts/_id` watermark, unique on `customer_id`, FK on_delete:
:delete_all, optimistic_lock. **Notes:** supabase/stripe-sync-engine stores list-shaped Stripe
fields as JSONB (typed columns only for queried fields) — the exact pattern; `has_more` → typed
`truncated` column so partial caches are honest, not silent.

---

## Audit ledger + telemetry/observability

| Option | Description | Selected |
|--------|-------------|----------|
| Ledger every write | Rejected — audit bloat under webhook replay; duplicates `accrue_webhook_events` | |
| Ledger on-change-only | Row only when the cached set or `truncated` materially changes; ENT-05 intent, no bloat | ✓ |
| Ledger never | Rejected — contradicts ENT-05 (sync state change → ledger) | |

**Choice:** On-change-only, `type: "entitlements.summary.synced"`, idempotency_key on the Stripe
`evt_id`. Telemetry: span `[:accrue, :entitlements, :sync]` (mirror of `:check`); cache-write
`[:accrue, :entitlements, :summary_synced]` with `result: :written | :unchanged`; reuse
`[:accrue, :webhooks, :stale_event]`; orphan `[:accrue, :webhooks, :orphan_entitlement_summary]`;
ops `[:accrue, :ops, :entitlement_summary_truncated]` only on `has_more: true` (not per-sync).
**Notes:** Lago dedupes by transaction_id, Cashier under-logs (no idempotency) — Accrue's in-library
audit + idempotency is a differentiator. Allowlist-safe dims only; never log raw payload (V7).

---

## Claude's Discretion

- Exact module placement for cache read/seam logic (new `Accrue.Entitlements.StripeSync` vs. sibling
  fn in `Accrue.Entitlements.Admin`); exact changeset fn names, migration timestamp, and whether the
  reducer is a private DefaultHandler clause vs. a delegated helper. Gate path stays cache-free either way.

## Deferred Ideas

- Gate-influencing overlay (additive union) — future non-breaking opt-in (`:influence` enum value).
- Full paginated entitlement reconcile — deferred to `lattice_stripe ≥ 1.2` (`:reconcile` enum value).
- Rendered `accrue_admin` "Stripe-native (advisory)" read-only panel — cheap follow-up; seam exists.
- SEED-002 ecosystem integrations (Threadline audit, Sigra/Lockspire scopes) — separate seed.
