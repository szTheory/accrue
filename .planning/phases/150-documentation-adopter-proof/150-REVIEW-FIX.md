---
phase: 150-documentation-adopter-proof
fixed_at: 2026-05-29T01:33:00Z
review_path: .planning/phases/150-documentation-adopter-proof/150-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 150: Code Review Fix Report

**Fixed at:** 2026-05-29T01:33:00Z
**Source review:** .planning/phases/150-documentation-adopter-proof/150-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (1 Critical, 5 Warning — Info findings IN-01..IN-04 are out of scope under `critical_warning`)
- Fixed: 6
- Skipped: 0

## Test verification

Per the task's explicit instruction, the affected example-host suites were run inside the
isolated worktree (with the fixed source) against the live `accrue_host_test` Postgres DB:

- **Targeted run** (`recovery_analytics_test.exs` + `dunning_banner_live_test.exs`, `--seed 0`):
  **3 tests, 0 failures** — confirms the WR-04 fixture rewrite renders the recovery dashboard
  KPIs correctly and that the seed/facade changes do not break the banner-on/banner-off tests.
- **Full host suite** (`mix test --seed 0`): **185 tests, 0 failures** — the 185/185 green
  baseline the executor established is preserved after all six fixes.

## Fixed Issues

### CR-01: Seeds pass a non-existent `timestamp:` field to `Events.record/1`

**Files modified:** `examples/accrue_host/priv/repo/seeds.exs`
**Commit:** 7fde9cac
**Status:** fixed: requires human verification (correctness/behavior change)
**Applied fix:** Removed the silently-dropped `timestamp:` key from all seven
`Events.record/1` calls. Introduced a `record_at.(attrs, at)` helper that records the event,
then back-dates the real `inserted_at` column (the field the analytics actually filter on,
per `accrue/lib/accrue/analytics/dunning.ex:304-311`) via `Repo.update_all`. Added
`import Ecto.Query, only: [from: 2]` to support the back-date query. This makes the seeded
events land in their intended 7d/30d/90d analytics windows instead of all collapsing to
`now()`. Flagged for human verification because it changes the data the windowed KPIs see.

### WR-01: Matrix advertised non-existent route `/billing/analytics/recovery`

**Files modified:** `examples/accrue_host/docs/adoption-proof-matrix.md`
**Commit:** 480ef858
**Applied fix:** Changed the Recovered Revenue Dashboard cell from `/billing/analytics/recovery`
to `/admin/analytics/recovery`, matching the route the `accrue_admin "/admin"` macro mounts and
the route `recovery_analytics_test.exs` exercises. Confirmed the CI substring gate
(`verify_adoption_proof_matrix.sh`) does not reference the route string, so the gate is unaffected.

### WR-02: Seeded dunning events use phantom UUID subject_ids

**Files modified:** `examples/accrue_host/priv/repo/seeds.exs`
**Commit:** 24b1afb5
**Applied fix:** Took the reviewer's second option — added an explicit comment block documenting
that `sub_7d`/`sub_30d`/`sub_90d` are intentionally roll-up-only fixtures (driving
`recovered_vs_lost_mrr/1`, which reads by `type` + `currency` only), that the At-Risk analytics
join on `subject_id` will find nothing for them, and that the real `past_due_subscription` is the
only subscription with a live dunning campaign. Anchoring all three windowed event sets on the
single real subscription was rejected because it would conflate the distinct campaign windows and
collide their `dunning.campaign_started` events.

### WR-03: `Events.record` in seeds was not idempotent

**Files modified:** `examples/accrue_host/priv/repo/seeds.exs`
**Commit:** 3a0f8ae4
**Applied fix:** Extended the `record_at` helper to take a stable `idempotency_key` (independent of
the per-run random `subject_id`) and pass it to `Events.record/1`, so re-running the script without
a DB reset collapses to a no-op via the `on_conflict: :nothing` partial-unique path in
`Accrue.Events.insert_opts/1` rather than appending duplicate events. Each of the seven events got
a deterministic key (`seed-dunning-7d-campaign_started`, etc.). On the dedupe path `record/1`
returns the pre-existing row, so the subsequent back-date simply re-asserts the same `inserted_at`.
Tightened the header comment to note the dunning events are now idempotent too.

### WR-04: `recovery_analytics_test.exs` ran the full host seed script in setup

**Files modified:** `examples/accrue_host/test/accrue_host_web/live/recovery_analytics_test.exs`
**Commit:** 9ecb0920
**Applied fix:** Replaced `Code.require_file("priv/repo/seeds.exs")` with a small inline fixture
that inserts only the two `dunning.*` ledger events the test asserts on (one `dunning.recovered`
USD/12000c and one `dunning.exhausted` JPY/30000c). This decouples the KPI-render assertion from
the full account/org/Fake-subscribe seed path. Both events land within the LiveView's default 30d
window (`recovery_live.ex` defaults to `"30d"`), so the existing `$120.00` / `¥30,000` and heading
assertions still pass. Verified: 3/3 targeted tests and 185/185 full-suite green.

### WR-05: Seeds bypassed the host facade and called `Accrue.Billing.subscribe/2` directly

**Files modified:** `examples/accrue_host/priv/repo/seeds.exs`
**Commit:** b6cfdb4c
**Applied fix:** Changed both direct `Accrue.Billing.subscribe(org, "price_basic")` calls (healthy
and past-due demo orgs) to `AccrueHost.Billing.subscribe(org, "price_basic")`, routing through the
generated host facade (the "host policy hook" boundary the rest of the host enforces and the
dunning guide teaches). The facade `subscribe/3` has a default-arg `opts`, so the 2-arity call is
unchanged in behavior.

## Skipped Issues

None — all in-scope findings were fixed.

> Note: IN-01 through IN-04 (Info tier) were out of scope under the `critical_warning` fix scope
> and were not attempted.

---

_Fixed: 2026-05-29T01:33:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
