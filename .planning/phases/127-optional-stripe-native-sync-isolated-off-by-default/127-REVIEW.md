---
phase: 127-optional-stripe-native-sync-isolated-off-by-default
reviewed: 2026-05-24T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - accrue/lib/accrue/billing/entitlement_summary.ex
  - accrue/lib/accrue/config.ex
  - accrue/lib/accrue/entitlements/stripe_sync.ex
  - accrue/lib/accrue/processor/capabilities.ex
  - accrue/lib/accrue/telemetry/metrics.ex
  - accrue/lib/accrue/webhook/default_handler.ex
  - accrue/priv/repo/migrations/20260524120000_create_accrue_entitlement_summaries.exs
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
  - accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs
  - accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs
  - accrue/test/property/entitlement_summary_monotonic_property_test.exs
  - accrue/test/support/stripe_fixtures.ex
  - scripts/ci/verify_entitlement_sync_isolation.sh
  - scripts/ci/verify_package_docs.sh
  - scripts/ci/verify_processor_support_matrix.sh
findings:
  critical: 1
  warning: 5
  info: 4
  total: 10
status: resolved
resolution:
  fixed: [CR-01, WR-01, WR-02, WR-03, WR-04]
  deferred: [WR-05, IN-01, IN-02, IN-03, IN-04]
  resolved_at: 2026-05-24
---

# Phase 127: Code Review Report

**Reviewed:** 2026-05-24
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

Phase 127 adds an optional, off-by-default Stripe-native entitlement-summary
advisory cache (ENT-10). The observational-only isolation invariant is
**well-defended on the gate path**: the gate-path files (`entitlements.ex`,
`resolver.ex`, `local_map.ex`) carry zero references to the cache schema/seam, the
CI static gate enforces this at merge, and the disabled-mode early-return is in the
correct position (before any `Repo` call). The schema, migration, config plumbing,
telemetry wiring, and support-matrix drift guards are all sound.

However, there is one **BLOCKER**: the new reducer is **unreachable from the real
production webhook path**. The `entitlements.active_entitlement_summary` Stripe
object has no top-level `id` (correctly documented everywhere), so the
`%Accrue.Webhook.Event{}` built by `Accrue.Webhook.DispatchWorker` carries
`object_id: nil`. That nil hits the generic `object_id: nil` short-circuit clause in
`handle_event/3` *before* dispatch is ever reached, so a real Stripe webhook for this
type returns `:ok` and writes nothing — the advisory cache will be silently empty in
production even when a host enables `:advisory`. Every test exercises the `handle/1`
raw-map path and never the `handle_event/3`/DispatchWorker path, which is exactly why
this defect passes the suite. This must be fixed before the feature can be claimed to
work end-to-end.

The remaining findings are watermark-monotonicity hardening, a coverage gap, stale
test scaffolding metadata, and minor data-fidelity issues.

## Critical Issues

### CR-01: Entitlement-summary reducer is unreachable from the real webhook dispatch path (object_id: nil short-circuit)

**File:** `accrue/lib/accrue/webhook/default_handler.ex:155-161` (and the unreached dispatch clause at `:276-282`)
**Issue:**
The `entitlements.active_entitlement_summary` object has **no top-level `id`** — this
is stated explicitly in `entitlement_summary.ex:9-13`, the migration moduledoc, and
`stripe_fixtures.ex:438-440` ("intentionally has NO top-level 'id'").

`Accrue.Webhook.Event.from_webhook_event/1` and `from_stripe/2`
(`accrue/lib/accrue/webhook/event.ex:39-43, 71-75`) derive `object_id` from
`data["object"]["id"]`. For this event type that key is absent, so `object_id` is
`nil`.

In the production path, `Accrue.Webhook.DispatchWorker.perform/1`
(`dispatch_worker.ex:62, 90, 111`) calls
`DefaultHandler.handle_event(event.type, event, ctx)`. With
`type == "entitlements.active_entitlement_summary.updated"` and `object_id == nil`,
the **first matching clause** is the generic nil-guard:

```elixir
def handle_event(type, %Accrue.Webhook.Event{object_id: nil}, _ctx) when is_binary(type) do
  :telemetry.execute([:accrue, :webhooks, :missing_object_id], %{}, %{type: type})
  :ok
end
```

This emits `missing_object_id` telemetry and returns `:ok` **before** `dispatch/4`
(and therefore the config gate + `reduce_entitlement_summary/3`) is ever invoked.
Result: with `stripe_native_sync: :advisory` enabled, **no cache row is ever written
from a real Stripe webhook**. The feature is dead on the production path.

Note that meter-error and portal-checkout events (which also lack a usable
`object_id`) each have a *dedicated* `handle_event/3` clause that pulls the object out
of `ctx` (`default_handler.ex:84-113`) and dispatches explicitly. The entitlement
summary type has no such clause, so it falls through to the nil short-circuit. The
summary object IS available in `ctx` — `dispatch_worker.ex:64-68, 75` already places
`data.object` under `ctx.meter_error_object`.

**Fix:** Add a dedicated `handle_event/3` clause for the summary type that pulls the
object from `ctx` and dispatches, mirroring the meter-error/portal pattern, and place
it **above** the `object_id: nil` generic clause. For example:

```elixir
def handle_event(
      "entitlements.active_entitlement_summary.updated",
      %Accrue.Webhook.Event{} = event,
      ctx
    ) do
  obj = entitlement_summary_object_from_ctx(ctx)

  case dispatch(event.type, event.processor_event_id, event.created_at, obj) do
    {:ok, _} -> :ok
    other -> other
  end
end

defp entitlement_summary_object_from_ctx(ctx) when is_map(ctx) do
  Map.get(ctx, :meter_error_object) || Map.get(ctx, "meter_error_object") || %{}
end
```

(Or surface the object under a clearer ctx key in `DispatchWorker` and read that.)
Then **add a test that drives the real path** —
`Accrue.Webhook.DefaultHandler.handle_event("entitlements.active_entitlement_summary.updated", %Accrue.Webhook.Event{object_id: nil, ...}, ctx)` with the summary object in `ctx`
— asserting a row is written. See WR-01.

## Warnings

### WR-01: Zero test coverage of the real `handle_event/3`/DispatchWorker path for this event type

**File:** `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` (whole module); `accrue/test/property/entitlement_summary_monotonic_property_test.exs`
**Issue:**
Every assertion in the entitlement-summary test suite calls
`Accrue.Webhook.DefaultHandler.handle(event)` (the raw-map `handle/1` entry used by
`Fake.synthesize_event`). None exercises `handle_event/3` with an
`%Accrue.Webhook.Event{}` and a ctx, which is the path real Stripe webhooks take via
`Accrue.Webhook.DispatchWorker`. This blind spot is precisely what allowed CR-01 to
ship green. The phase brief calls this sync "the production path"; the production path
is untested.
**Fix:** Add at least one test that builds the lean `%Accrue.Webhook.Event{}` (with
`object_id: nil`, the type, `created_at`, `processor_event_id`) plus a ctx carrying
the summary object, calls `handle_event/3`, and asserts a row is written (and the
stale/orphan/malformed branches behave). Prefer routing through
`DispatchWorker`-equivalent construction to lock in the contract end-to-end.

### WR-02: A nil/missing event timestamp wipes the watermark, weakening the monotonic guarantee

**File:** `accrue/lib/accrue/webhook/default_handler.ex:528-551` (via `stamp_watermark/3` at `:1309-1311`)
**Issue:**
When `evt_ts` is `nil` (malformed/missing `created`), `check_stale(row, nil)` returns
`:ok` (`:1287`), then `write_entitlement_summary/8` calls
`stamp_watermark(attrs, nil, evt_id)`, persisting `last_stripe_event_ts: nil`. A
subsequent stale check `check_stale(%{last_stripe_event_ts: nil}, _)` also returns
`:ok` (`:1286`), so stale protection is disabled for that customer until a
timestamped event re-stamps it. A null-timestamp event can therefore clobber a
newer-by-timestamp snapshot and let a later older event overwrite — a hole in the
"highest event timestamp always wins" monotonic invariant the phase promises.
This mirrors the existing reducers' behavior, but the entitlement-summary reducer is
the one whose explicit contract (D-06, the monotonic property test) is monotonicity.
**Fix:** Do not overwrite a non-nil watermark with `nil`. When `evt_ts == nil`, either
preserve the prior `last_stripe_event_ts`/`_id` or skip the write (treat as
non-material). For example, only stamp when `evt_ts` is a `%DateTime{}`:

```elixir
defp stamp_watermark(attrs, %DateTime{} = ts, id),
  do: Map.merge(attrs, %{last_stripe_event_ts: ts, last_stripe_event_id: id})

defp stamp_watermark(attrs, _ts, _id), do: attrs
```

(Scope the change to the summary reducer if changing the shared helper risks other
reducers.)

### WR-03: `stripe_native` static-isolation gate does not catch a config-flag leak into the gate path

**File:** `scripts/ci/verify_entitlement_sync_isolation.sh:46-47`
**Issue:**
The gate greps for `EntitlementSummary|StripeSync|accrue_entitlement_summaries` only.
A future refactor could fail-open without touching any of those tokens — e.g.
`local_map.ex` reading `Accrue.Config.stripe_native_sync?()` and then consulting
Stripe-reported state to widen a grant. That is the exact "advisory cache influences
the gate" hazard the gate exists to block, yet it would pass because the config
predicate name is not in the alternation.
**Fix:** Add the config predicate/flag to the scanned pattern so the gate also fails
on a gate-path reference to the sync mode, e.g.:

```bash
'^[^#]*(EntitlementSummary|StripeSync|accrue_entitlement_summaries|stripe_native_sync)'
```

### WR-04: Stale `:pending_plan_02` moduletags and "EXCLUDED / RED" moduledocs contradict the now-active suite

**File:** `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs:33`; `accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs:28`; `accrue/test/property/entitlement_summary_monotonic_property_test.exs:26`
**Issue:**
`test/test_helper.exs:66-70` states the `:pending_plan_02` exclusion was removed and
these files "now run in the default suite," and `ExUnit.configure(exclude: ...)` no
longer lists `:pending_plan_02`. But all three files still carry
`@moduletag :pending_plan_02`, and their moduledocs still assert they are "EXCLUDED by
default" and "intentionally RED this wave." Because the tag is not excluded, the tests
do run — so the metadata is now false and actively misleading to anyone diagnosing the
suite (it implies these tests are skipped/red when they are green-and-running). The
risk: a future reader may re-add `:pending_plan_02` to the exclude list trusting the
docs, silently disabling the only coverage for this feature.
**Fix:** Remove the `@moduletag :pending_plan_02` from all three files and update the
moduledocs to drop the "EXCLUDED by default / RED this wave" language now that Plan 02
landed.

### WR-05: Concurrent webhook delivery for the same customer can raise `Ecto.StaleEntryError` instead of resolving gracefully

**File:** `accrue/lib/accrue/webhook/default_handler.ex:613-623`; `accrue/lib/accrue/billing/entitlement_summary.ex:82-88`
**Issue:**
`force_changeset/2` carries `optimistic_lock(:lock_version)`. Two Oban jobs processing
two summary events for the same customer concurrently (each in its own
`Repo.transact`) will both load the same `lock_version`; the second `Repo.update`
raises `Ecto.StaleEntryError`, which escapes `Repo.transact` and propagates as a job
crash. The insert path similarly races on the `unique_index(:customer_id)`
(`migration :42`) — the second insert raises a constraint error rather than upserting.
Oban will retry, so this is self-healing, but it produces noisy crashes and relies on
retry rather than handling the expected concurrent-delivery case. The other reducers
use plain `changeset/2` (no optimistic lock) so they do not hit this; the summary
reducer is the one that opted into the lock without a retry/recover path.
**Fix:** Either (a) catch `Ecto.StaleEntryError`/constraint errors in the summary
upsert and re-read+retry once within the transaction, or (b) use a DB-level upsert
(`Repo.insert(..., on_conflict: ..., conflict_target: :customer_id)`) so concurrent
deliveries serialize at the unique index instead of crashing. Confirm the chosen path
still honors the stale-skip watermark.

## Info

### IN-01: Reducer always records `processor: "stripe"` (schema default) even under the Fake processor

**File:** `accrue/lib/accrue/webhook/default_handler.ex:540-549`
**Issue:** `write_entitlement_summary/8` omits `:processor` from `attrs`, so inserts
fall back to the schema default `"stripe"` (`entitlement_summary.ex:53`) even when the
configured processor is `fake` (as in all tests). Harmless today (the cache is
Stripe-native by definition and keyed on `customer_id`), but the stored value is
inaccurate for non-Stripe customers.
**Fix:** Set `processor: processor_name()` in `attrs`, or document that this column is
always `"stripe"` for the advisory cache.

### IN-02: `livemode` collapses unknown to `false`, dropping the nullable distinction

**File:** `accrue/lib/accrue/webhook/default_handler.ex:545`
**Issue:** `livemode: get(obj, :livemode) == true` writes `false` when the key is
absent, even though the column is nullable (`migration :30`) and could record
"unknown." Minor fidelity loss; not a correctness problem.
**Fix:** If the unknown/false distinction matters to operators, pass through the raw
boolean-or-nil; otherwise leave as-is.

### IN-03: `stripe_fixtures.ex` moduledoc still says "Phase 3 tests" though it now hosts the Phase 127 fixture

**File:** `accrue/test/support/stripe_fixtures.ex:3`
**Issue:** The moduledoc scopes the file to "Phase 3 tests," but it now includes the
Phase 127 `entitlement_summary_event/2` fixture (and Phase 5 Connect fixtures). Stale
scoping comment.
**Fix:** Generalize the moduledoc wording (e.g., "canned Stripe payloads for the
webhook/reducer test suite").

### IN-04: No `summary_synced` counter accompanies the new telemetry events (intentional but undocumented gap)

**File:** `accrue/lib/accrue/telemetry/metrics.ex:88`
**Issue:** The reducer emits `[:accrue, :entitlements, :summary_synced]` and the
`[:accrue, :entitlements, :sync]` span, but `defaults/0` only adds the
`entitlement_summary_truncated` counter. This is a defensible host-choice omission
(metrics are opt-in), but a reader auditing the recipe may assume the synced event is
unmonitored by oversight.
**Fix (optional):** Either add a `counter("accrue.entitlements.summary_synced.count",
tags: [:result])` to the default recipe or note in the metrics moduledoc that
`summary_synced` is intentionally left to host metric definitions.

---

## Resolution (2026-05-24, execute-phase code_review_gate)

**Fixed in-phase** (commits `34ecc32`, `4ba9ae6`; the post-merge fixture fix
`9b47fa8` is unrelated to these findings):

- **CR-01** (blocker) — Added a dedicated `handle_event/3` clause for
  `entitlements.active_entitlement_summary.updated` that pulls the full object
  from `ctx` (DispatchWorker's `:meter_error_object`) and dispatches, placed
  above the `object_id: nil` short-circuit. The reducer is now reachable on the
  real production webhook path. New helper `entitlement_summary_object_from_ctx/1`.
- **WR-01** — Added regression tests driving the real `handle_event/3` path for
  both enabled (row written) and disabled (inert) lanes.
- **WR-02** — `stamp_summary_watermark/4` refuses to overwrite a non-nil
  watermark with `nil` (scoped to the summary reducer; shared `stamp_watermark/3`
  untouched).
- **WR-03** — Added `stripe_native_sync` to the isolation gate's grep alternation.
- **WR-04** — Removed the stale `:pending_plan_02` moduletags + "RED/EXCLUDED"
  moduledocs from all three summary test files.

Full suite green after fixes: **50 properties, 1477 tests, 0 failures** (`--seed 0`).

**Deferred** (tracked in `.planning/todos/pending/`, non-blocking for ENT-10):

- **WR-05** — Concurrent same-customer delivery raises `Ecto.StaleEntryError`;
  self-healing via Oban retry (25 attempts). Fix (on_conflict upsert or
  rescue+retry) is a write-semantics change deferred to a follow-up.
- **IN-01/02** — `processor` defaults to `"stripe"` and `livemode` collapses
  unknown→`false`; harmless for a Stripe-native, customer-keyed advisory cache.
- **IN-03** — `stripe_fixtures.ex` moduledoc still scoped to "Phase 3" (cosmetic).
- **IN-04** — No default `summary_synced` counter (intentional host-choice).

---

_Reviewed: 2026-05-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
