# Phase 213: Stripe-native advisory entitlements sync (observational-only) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-30
**Phase:** 213-stripe-native-advisory-entitlements-sync-observational-only
**Areas discussed:** Fetch seam design, Invocation surface, D-07 fetch_entitled/2, List→summary write

**Mode:** The maintainer selected all four gray areas and asked for deep parallel subagent research (pros/cons/tradeoffs, ecosystem idiom, lessons from Pay/Cashier/stripity_stripe/Stripe, DX/API-consumer lens) followed by a single cohesive one-shot recommendation package — "so I don't have to think." Four `gsd-advisor-researcher` agents ran in parallel, each briefed with the same locked-constraints spine and told which sibling decisions to cohere with. No per-area interactive Q&A; decisions locked from the synthesis.

---

## Fetch seam design

| Option | Description | Selected |
|--------|-------------|----------|
| New `Processor` callback returning a list | `list_active_entitlements/2`, Stripe impl streams via lattice_stripe, Fake seeds | ✓ |
| Overload generic `fetch/2` | Single-object-by-id dispatch table — wrong shape for a customer-scoped list | |
| Call `LatticeStripe.…stream!` directly from `StripeSync` | Fails the CI-enforced facade boundary; needs Bypass (not async/Fake) | |
| Callback + thin domain reconciler | = Option 1 plus a home for reconcile/write | ✓ (this is the shape) |

**Choice:** New optional `Accrue.Processor` callback `list_active_entitlements/2` (mirrors `list_charges/2`), Stripe impl the only `LatticeStripe` caller (CI-enforced facade), drained `stream!` (complete-or-`{:error}`), Fake seed helper for SYNC-05.
**Notes:** Decisive fact — `processor/stripe.ex` is the ONLY file allowed to reference `LatticeStripe` (CI test), which eliminated the "direct call" option outright. Callback declared `@optional_callbacks` so custom/Braintree processors aren't force-broken. Isolation-guard entry symbol = `list_active_entitlements`.

---

## Invocation surface

| Option | Description | Selected |
|--------|-------------|----------|
| On-demand public fn only | `StripeSync.refresh/2`, synchronous | ✓ (core primitive) |
| Oban worker only | Forces async; inert without host queue | |
| Admin "refresh now" button | Brushes the no-admin-redesign fence | (deferred) |
| Oban cron poll-all | Poll-storm / host burden / out of "minimal" | (rejected) |
| Layered (fn + thin worker) | Primitive = truth; thin worker over existing queue | ✓ |

**Choice:** `Accrue.Entitlements.StripeSync.refresh/2` primitive (single source of truth) + thin `RefreshWorker` on the existing `accrue_webhooks` queue; config-off no-op before any I/O; `source: :pull` telemetry; NOT on the top-level `Accrue` gate facade.
**Notes:** Pay `sync!` / Cashier `syncStripeData` lesson — manual sync is an explicit primitive, never a forced cron; but both are synchronous footguns, so ship the async worker so hosts keep the live pull off the request path. Admin button + cron + facade delegate deferred.

---

## D-07 fetch_entitled/2

| Option | Description | Selected |
|--------|-------------|----------|
| A. Implement as observational read | Duplicates two existing observational surfaces; re-introduces a gate-adjacent name | |
| B. Keep deferred + one-line reason | Satisfies SYNC-04 literally but leaves the question "alive" | |
| C. Formally CLOSE (reject), record why | Kills the name permanently; fail-open + naming-trap rationale | ✓ |

**Choice:** Option C — close/reject, not merely defer. Rewrite the `admin.ex` moduledoc deferral line as a permanent "will not be built" closure (network entitlement predicate fails open; contradicts fail-closed local gate D-01/D-11; observational need already served by `summary_for_customer/1` + `resolve_for_customer/1`), mirror in `guides/entitlements.md`. Doc-only; no isolation-guard change.
**Notes:** Two independent forces (fail-open security + naming trap) point the same way; lattice_stripe itself ships the "no `entitled?` helper" warning. SYNC-04 allows implement-or-defer; "close" is the stronger unambiguous form — maintainer may soften to "defer" if they want the door left open.

---

## List→summary write

| Option | Description | Selected |
|--------|-------------|----------|
| Pull writes nil/synthetic event watermark | Either clobbers newer webhooks or can never update — breaks both directions | |
| Two independent guards (event-ts + synced_at) | Does not compose under concurrent pull+webhook | |
| Add a `source`/provenance column | Migration to every adopter for marginal observability | |
| Unify the monotone guard on `synced_at` (both writers) | One freshness axis; composes; code-only, no migration | ✓ (direction) |

**Choice:** Reconstruct summary-shaped `data` jsonb from the streamed list (`truncated: false` always; count = list length; `synced_at = now`); carry the event watermark forward untouched; provenance in `data["_accrue"]` (no migration); extract one shared writer (`Reconcile`) reused by webhook + pull. Unify the `on_conflict` monotonicity guard on `synced_at` — **direction locked, mechanism flagged researcher-verify** because it edits WR-02/ADV-02/ADV-03 concurrency code and the `synced_at_from_event/1` null-evt_ts fallback.
**Notes:** Ordering-safety invariant: for each customer, the row reflects the greatest-`synced_at` observation; a stale pull never clobbers a newer webhook and a webhook is never dropped because a pull ran. Verified `synced_at_from_event(evt_ts) ≡ evt_ts` for real events (falls back to `now()` when timestamp-less — the edge to re-derive). Fallback if the flip proves unsafe: keep `last_stripe_event_ts` as the webhook axis and give the pull a non-invasive composable ordering.

---

## Claude's Discretion

- Shared-writer module name/location (`Accrue.Entitlements.Reconcile` vs folding into `StripeSync`).
- Telemetry meta keys + the `data["_accrue"]` provenance key shape.
- `refresh/2` `{:ok, :unchanged}` vs `{:ok, row}` on an idempotent no-material-change re-pull.
- Exact wording of the D-14 closure one-liner in `admin.ex` + the guide.

## Deferred Ideas

- Admin "refresh now" button on the ENT-11 tab (later 1-liner over `refresh/1`).
- Scheduled/cron poll-all reconcile.
- Top-level `Accrue.refresh_entitlements/1` facade delegate.
- Paginated `entitlements.url` reconcile for the webhook `truncated` case (the pull already cures truncation).
