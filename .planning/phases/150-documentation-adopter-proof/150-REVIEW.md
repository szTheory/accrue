---
phase: 150-documentation-adopter-proof
reviewed: 2026-05-28T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - accrue/guides/dunning.md
  - examples/accrue_host/docs/adoption-proof-matrix.md
  - examples/accrue_host/lib/accrue_host_web/components/layouts.ex
  - examples/accrue_host/priv/repo/seeds.exs
  - examples/accrue_host/test/accrue_host_web/live/dunning_banner_live_test.exs
  - scripts/ci/verify_adoption_proof_matrix.sh
findings:
  critical: 1
  warning: 5
  info: 4
  total: 10
status: issues_found
---

# Phase 150: Code Review Report

**Reviewed:** 2026-05-28
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

This phase is documentation + adopter-proof scaffolding (a dunning guide, an adoption-proof
matrix doc, the host layout banner wiring, demo seeds, a LiveView banner test, and a CI
substring gate). Cross-referencing against the actual `accrue` source surfaced one
correctness defect that is load-bearing for the phase's stated goal: the demo seeds attempt
to spread dunning ledger events across distinct time windows by passing a `timestamp:` key to
`Accrue.Events.record/1`, but that key is **not a field on the event schema and is silently
dropped** — every seeded event lands at `inserted_at = now()`, defeating the documented
window-distribution intent that the recovery dashboard analytics filter on. Plus a route-path
mismatch between the matrix doc and the actual dashboard route, a couple of internal
inconsistencies in the seeds/layout, and several doc/quality nits.

The CI gate (`verify_adoption_proof_matrix.sh`) was checked against the live matrix content —
all required substrings are present and no stale-wording tripwires fire, so the gate will pass.

## Critical Issues

### CR-01: Seeds pass a non-existent `timestamp:` field to `Events.record/1` — silently dropped, all dunning events land at `now()`

**File:** `examples/accrue_host/priv/repo/seeds.exs:135-205`
**Issue:** The seeds compute `days_ago.(5)`, `days_ago.(25)`, `days_ago.(60)`, etc. and pass them
as `timestamp:` to `Accrue.Events.record/1` with the explicit intent (per the inline comments
"7d window", "30d window", "Active (90d window)") of placing events into distinct analytics
time windows. But `Accrue.Events.Event` has **no `:timestamp` field** — its only time column is
`field(:inserted_at, :utc_datetime_usec, read_after_writes: true)` (set by the DB at insert),
and `@cast_fields` (`accrue/lib/accrue/events/event.ex:51-55`) does not include `timestamp`.
`Events.normalize/1` (`accrue/lib/accrue/events.ex:162-169`) passes the key through, but
`Event.changeset/1` casts only `@cast_fields`, so `timestamp` is **silently discarded**. Every
seeded event therefore gets `inserted_at = now()`.

The recovery analytics that the matrix row (line 30) says these seeds prove
(`Accrue.Analytics.Dunning`, e.g. `recovered_vs_lost_mrr/1`) window on `inserted_at`
(`accrue/lib/accrue/analytics/dunning.ex:304-311`: `where: e.inserted_at >= ^since` /
`<= ^until`). Because all seed events collapse to `now()`, any windowed KPI (e.g. a "last 7d"
card) will show the 30d/90d events too, and the seeds do not exercise window boundaries at all.
The data is "deterministic" only in the trivial sense that it is all timestamped identically.

**Fix:** Set `inserted_at` explicitly (the field that actually exists and is what the analytics
filter on), not `timestamp`. Since `inserted_at` is `read_after_writes` and not in `@cast_fields`,
back-dating requires either adding `inserted_at` to the cast/normalize path in `Accrue.Events`
or writing the rows with an explicit timestamp via `Repo.insert_all/Repo.update_all` after
`Events.record`. Minimal targeted fix in seeds (replace the dropped `timestamp:` and back-date):

```elixir
# after Events.record(...) returns {:ok, %Event{id: id}}
{:ok, ev} = Events.record(%{type: "dunning.recovered", subject_type: "Subscription",
  subject_id: sub_7d, data: %{campaign_anchor: anchor_7d, mrr_value_cents: 12000, currency: "usd"}})

import Ecto.Query
Repo.update_all(
  from(e in Accrue.Events.Event, where: e.id == ^ev.id),
  set: [inserted_at: days_ago.(3)]
)
```

(Or, preferred: add first-class support for an explicit `inserted_at`/`occurred_at` on
`Accrue.Events.record/1` so seeds and back-dating callers do not have to reach around the API.)
Either way, the silent `timestamp:` drop must be removed — passing a key that the API throws
away is a latent correctness trap for every future seed/fixture author.

## Warnings

### WR-01: Matrix advertises route `/billing/analytics/recovery`, but the dashboard lives at `/admin/analytics/recovery`

**File:** `examples/accrue_host/docs/adoption-proof-matrix.md:30`
**Issue:** The Recovered Revenue Dashboard row links the proof to `/billing/analytics/recovery`.
The actual proof test (`examples/accrue_host/test/accrue_host_web/live/recovery_analytics_test.exs:22`)
mounts `live(conn, "/admin/analytics/recovery")`. An adoption-proof matrix whose entire purpose
is to be an accurate, evaluator-facing index of "what is proven, where" must not point readers
at a non-existent route. (No `/billing/analytics/recovery` route exists in the host router.)
**Fix:** Change the matrix cell to `/admin/analytics/recovery` to match the router + test, or
add the `/billing/...` route if that is the intended public path.

### WR-02: Seeded dunning events use phantom `Ecto.UUID.generate()` subject_ids with no backing subscriptions

**File:** `examples/accrue_host/priv/repo/seeds.exs:140,168,188`
**Issue:** `sub_7d`/`sub_30d`/`sub_90d` are freshly generated UUIDs that do not correspond to any
row in `accrue_subscriptions`. The MRR roll-up analytics (`recovered_vs_lost_mrr/1`) read events
by `type` + `currency` only, so they work — but the sibling analytics the dashboard also renders
join against the subscriptions table by `subject_id` (e.g. the At-Risk / `in_campaign`-style
query at `accrue/lib/accrue/analytics/dunning.ex:246` references
`accrue_subscriptions`/`subject_id`). Those will silently find nothing for the phantom IDs, so
any "At-Risk Subscriptions" content driven off the seeded events is hollow. The test
(`recovery_analytics_test.exs:35`) only asserts the *heading* "At-Risk Subscriptions" renders,
not that any seeded row appears — so this gap is not caught.
**Fix:** Either anchor the seeded dunning events on the real `past_due_subscription.id` created
just above (so the campaign/at-risk joins resolve), or document explicitly in the seed comments
that these UUIDs are roll-up-only fixtures and the at-risk table is intentionally empty.

### WR-03: `Events.record` in seeds is not idempotent — re-running inflates the dashboard

**File:** `examples/accrue_host/priv/repo/seeds.exs:143-205`
**Issue:** The header comment (lines 32-34) claims the seeds are "seeded idempotently ... so
`mix ecto.reset` / re-running this script never crashes" — but that guard (`Repo.get_by`) only
covers users/orgs/memberships. The six `Events.record(...)` calls have no idempotency key and no
`get_by` guard, so each `mix run priv/repo/seeds.exs` invocation **appends another full set** of
dunning events. Re-running the seeds without a DB reset doubles/triples the Recovered/Exhausted
MRR shown on the dashboard. The "deterministic seeds" framing in the matrix (line 30) is only
true on a fresh DB.
**Fix:** Guard the event inserts (e.g. skip if events already exist for the demo subject_ids, or
pass a stable `idempotency_key` so the `on_conflict: :nothing` partial-unique path in
`Accrue.Events.insert_opts/1` dedupes them), and tighten the comment to scope the idempotency
claim to accounts/orgs only.

### WR-04: `recovery_analytics_test.exs` runs the full host seed script (with its account side effects) inside ConnCase setup

**File:** `examples/accrue_host/test/accrue_host_web/live/recovery_analytics_test.exs:11`
**Issue:** `Code.require_file("priv/repo/seeds.exs")` executes the entire demo-seed program —
including registering `healthy@example.com` / `past-due@example.com`, creating orgs, confirming
users, setting passwords, and subscribing via the Fake processor — purely to obtain three sets
of ledger events for a dashboard render assertion. This couples an analytics-rendering test to
the full account/billing seed path: any future change to user registration, org creation, or the
Fake `subscribe` flow can break a test that is nominally about recovery KPIs, with a confusing
failure far from its cause. It also makes the test order-fragile if seeds are ever made
non-idempotent in a way the sandbox doesn't fully isolate.
**Fix:** Have the test insert only the handful of `dunning.*` events it asserts on (or call a
small dedicated fixture helper), instead of `require`-ing the whole seed script.

### WR-05: Seeds bypass the host facade and call `Accrue.Billing.subscribe/2` directly

**File:** `examples/accrue_host/priv/repo/seeds.exs:107,120`
**Issue:** The dunning guide and the rest of the host code route subscription creation through the
generated host facade `AccrueHost.Billing` (e.g. `AccrueHost.Billing.subscribe/3`,
`subscribe_active_organization/3`) — the documented "host policy hook" boundary. The seeds reach
past it and call core `Accrue.Billing.subscribe(org, "price_basic")` directly while using
`AccrueHost.Billing.billing_state_for/1` two lines above. This is an inconsistent boundary that
models the opposite of what the guide teaches adopters (the guide's whole "pass a resolved
customer / go through the facade" message), in the very example host meant to demonstrate the
pattern.
**Fix:** Use `AccrueHost.Billing.subscribe(org, "price_basic")` for consistency with the facade
boundary the host otherwise enforces.

## Info

### IN-01: Unused binding `_healthy_state` followed by a redundant `billing_state_for` call

**File:** `examples/accrue_host/priv/repo/seeds.exs:101-108`
**Issue:** Line 101 binds `{:ok, _healthy_state} = AccrueHost.Billing.billing_state_for(healthy_org)`
and discards it, then lines 103-106 call `billing_state_for(healthy_org)` again inside the
`unless match?`. The first call is dead (a wasted query whose result is thrown away).
**Fix:** Drop line 101; keep only the `unless match?(...)` guard which does its own lookup.

### IN-02: `recovered_vs_lost/1` double-counting note is subtly imprecise

**File:** `accrue/guides/dunning.md:230-233`
**Issue:** The guide states a `dunning.exhausted` event "followed by a manual recovery action
(logged separately) counts as `lost` at the campaign level." `Accrue.Billing.Dunning.recovered_vs_lost/1`
folds ledger events by type; whether a later manual-recovery action re-flips the tally depends on
what event that action writes. The sentence reads as a guarantee but is really describing the
absence of a re-credit path — easy to misread as "exhausted is permanently sticky."
**Fix:** Tighten to: "a later manual recovery is logged as its own event and does not retroactively
move an earlier `dunning.exhausted` out of the `lost` bucket."

### IN-03: Matrix opening paragraph is a 1-sentence run-on wall

**File:** `examples/accrue_host/docs/adoption-proof-matrix.md:5`
**Issue:** Line 5 packs ~8 distinct contractual claims (provider honesty, swap_plan/preview
contract, update_customer/cancel semantics, Braintree advisory status) into a single ~12-line
sentence. For an evaluator-facing index doc this hurts scannability and makes it easy for one
clause to silently drift out of sync with code while the CI substring gate still passes.
**Fix:** Split into 3-4 sentences or a short bulleted contract list.

### IN-04: Layout `dunning_customer/1` swallows the error tuple shape silently

**File:** `examples/accrue_host/lib/accrue_host_web/components/layouts.ex:85-92`
**Issue:** `dunning_customer/1` matches only `{:ok, %{customer: %Customer{}}}` and funnels every
other return — including `{:error, :no_active_organization}` or an unexpected shape — to `nil` via
a bare `_ -> nil`. This is the right product behavior (render nothing), but the catch-all also
hides genuinely unexpected return shapes from `billing_state_for_scope/1`, so a future contract
regression there would fail open silently rather than surface in dev. Acceptable for a banner, but
worth a comment noting the intentional fail-closed-to-nil.
**Fix:** Add a one-line comment that the catch-all intentionally renders no banner on any non-`{:ok, customer}`
result; optionally match `{:error, _}` explicitly and let truly unexpected shapes raise in dev.

---

_Reviewed: 2026-05-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
