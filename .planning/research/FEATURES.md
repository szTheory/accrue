# Features Research — v1.47

**Domain:** Open-source Elixir/Phoenix billing library adopter-proof completeness + ENT-10 advisory-cache polish
**Researched:** 2026-05-30
**Confidence:** HIGH — grounded entirely in source inspection of the existing codebase, no speculation

---

## Context: What Already Exists

Reading the source before describing the gap:

- **Entitlements gating** is fully operational in `examples/accrue_host`. The router already has a `live_session :entitled_reports` with `{Accrue.Live.Entitlements, {:require_feature, :advanced_reports}}` guard. `entitlements_guard_test.exs` (2 tests: entitled org gets access, non-entitled org is redirected to "/" with flash) is the existing proof. `AdvancedReportsLive` is a minimal stub module. The `advanced_reports` feature is mapped via `price_premium` in `config/config.exs`.

- **Metered usage** is proven in `subscription_live_test.exs` PROOF-04: a "Simulate API Call" button triggers `Billing.report_usage_for_scope/3 → Accrue.Billing.MeterEventActions.report_usage/3`, inserts a `MeterEvent` row, and the test asserts the row exists and `event_name == "api_calls"`. The UI card exists in `SubscriptionLive` at `data-role="metered-usage-demo"`. Already in the adoption-proof matrix as "demonstrates metered usage reporting (PROOF-04)".

- **Oban cron** is already wired in `config/config.exs`: `DunningSweeper` (*/15), `DetectExpiringCards` (@daily), `MeterEventsReconciler` (* * * * *), `MeteredRenewalReconciler` (*/5). `dunning_wiring_test.exs` proves the dunning campaign + sweeper. `recovery_wiring_test.exs` (PROOF-06) proves `DetectExpiringCards` and `MeterEventsReconciler` queue presence. The adoption-proof matrix already tracks these.

- **ENT-10 concurrent write (WR-05)**: The `upsert_entitlement_summary/2` function in `DefaultHandler` already has the WR-05 upsert path implemented via `Repo.insert/2` with `on_conflict: {:replace_all_except, ...}` and `on_conflict_where` enforcing monotonic skip-stale at the DB level. The comment reads "WR-05: move from optimistic_lock with Repo.update to a DB-level atomic upsert." This means WR-05 may already be implemented but the milestone scope treats it as something to close/verify.

- **IN-01 (processor field)**: `write_entitlement_summary/8` always stamps `processor: processor_name()` at line 595. `processor_name()` is `"stripe"` for the Stripe handler. Whether this is accurate for non-Stripe (Braintree would return `"braintree"`) depends on the dispatch path — the entitlement summary event is Stripe-specific, so the issue is whether it could ever be called from a Braintree context where `processor_name()` would incorrectly return `"braintree"`. IN-01 = ensure it reads from `processor` arg not `processor_name()`.

- **IN-02 (livemode null fidelity)**: Line 596 writes `livemode: get(obj, :livemode)`. If the field is absent from the webhook payload, `get/2` returns `nil`, which maps to a DB `NULL`. The schema declares `field(:livemode, :boolean)` with no default. So `nil` (unknown) is preserved as `NULL` — IN-02 may already be correct, but the milestone scope wants to confirm/verify this is explicit.

- **IN-03 (stripe_fixtures moduledoc)**: `Accrue.Emails.Fixtures` has a full `@moduledoc` — but IN-03 mentions "stripe_fixtures" which may refer to `Accrue.Test.Webhooks` or a separate fixtures module for Stripe webhook payloads. This needs code inspection to pinpoint.

- **IN-04 (metrics counter)**: `Accrue.Telemetry.Metrics.defaults()` already has `counter("accrue.entitlements.summary_synced.count", tags: [:result])` and `counter("accrue.ops.entitlement_summary_truncated.count")`. IN-04 is either adding a missing counter or documenting why an expected one is absent.

---

## ENT-10 Fix Behaviors (table stakes)

These are correctness fixes — each is a must-have for shipping v1.47.

### WR-05: Concurrent entitlement summary writes

**What the fix must do:**
- Replace the optimistic-lock `Repo.update` path with a DB-level upsert via `Repo.insert/2` with `conflict_target: :customer_id` and `on_conflict: {:replace_all_except, [:id, :inserted_at, :customer_id]}`.
- The `on_conflict_where` clause must enforce the skip-stale monotonic watermark at the DB level: `e.last_stripe_event_ts < fragment("EXCLUDED.last_stripe_event_ts")`.
- Result: concurrent Oban delivery retries for the same customer can no longer raise `Ecto.StaleEntryError`. The upsert either wins (newer timestamp) or no-ops (stale).
- **Status from source inspection:** The code at lines 669–687 of `default_handler.ex` already shows the upsert implementation with the comment "WR-05: move from optimistic_lock..." This means the implementation exists. The v1.47 task is verification/testing, not net-new code — unless the schema `force_changeset/2` still has `optimistic_lock(:lock_version)` (it does, line 83 of `entitlement_summary.ex`), which may conflict with the upsert path. The `optimistic_lock` in the changeset is benign for upsert paths because Ecto's upsert bypasses the OCC check, but the `lock_version` field in `@cast_fields` means it's still cast. This needs explicit verification that `Ecto.StaleEntryError` is unreachable on the new path.
- **Dependency:** requires `accrue_entitlement_summaries` table with `unique constraint on customer_id` (the upsert conflict target) — already in schema.

### IN-01: Processor field accuracy

**What the fix must do:**
- `write_entitlement_summary/8` must stamp `:processor` from the `processor` argument passed through `reduce_entitlement_summary/4`, not from `processor_name()` (which reads the global configured processor, not the event's originating processor).
- For Stripe events, `processor` arg is `:stripe` (atom), `processor_name()` returns `"stripe"` (string) — currently equivalent. But if the event somehow dispatches through a Braintree context, `processor_name()` would return `"braintree"` which would be wrong for a Stripe entitlement event.
- Fix: use `to_string(processor)` from the arg rather than `processor_name()`.
- **Complexity:** Low — a 1-line change in `write_entitlement_summary/8`.

### IN-02: Livemode null fidelity

**What the fix must do:**
- When the `entitlements.active_entitlement_summary.updated` webhook payload lacks a `livemode` field (or has `null`), the DB row must record `NULL` (not `false`).
- Currently: `livemode: get(obj, :livemode)` — `get/2` returns `nil` for absent keys, which writes `NULL` to a `field(:livemode, :boolean)` column. This is already correct behavior.
- The fix is explicit: ensure no coercion (e.g., `|| false`) has been added, and add a comment documenting the intent. May be a no-op code change, non-zero documentation change.
- **Complexity:** Very low — likely a comment + test assertion that `livemode: nil` in payload produces `NULL` in DB.

### IN-03: Stripe fixtures moduledoc cosmetic

**What the fix must do:**
- The target module is identified in the milestone as "stripe_fixtures" — most likely `Accrue.Test.Webhooks` (which generates Stripe-shaped webhook payloads for test use) or possibly an `Accrue.Processor.Stripe.Fixtures` module.
- The fix is a `@moduledoc` addition or improvement — pure documentation, no behavior change.
- **Complexity:** Very low — cosmetic only. No logic change, no test impact.

### IN-04: Metrics counter or documented omission

**What the fix must do:**
- Either add a missing telemetry counter to `Accrue.Telemetry.Metrics.defaults/0` for ENT-10 flows, OR write an explicit doc comment explaining why a particular counter is intentionally absent (e.g., "per-customer entitlement sync count is not a default metric because customer_id is high-cardinality").
- Existing counters already cover `summary_synced.count` (tags: `[:result]`) and `entitlement_summary_truncated.count`. A candidate missing counter: `accrue.ops.entitlement_summary_orphaned.count` (the `[:accrue, :webhooks, :orphan_entitlement_summary]` telemetry event has no corresponding metrics line).
- **Complexity:** Low — either a 1-line counter addition in `Accrue.Telemetry.Metrics.defaults/0` or a doc note.

---

## Adopter-Proof: Entitlements Gating

**Current state:** Already substantially complete. The router has the `live_session :entitled_reports` with `{Accrue.Live.Entitlements, {:require_feature, :advanced_reports}}`. `AdvancedReportsLive` renders content. `entitlements_guard_test.exs` has both the grant and deny paths. The adoption-proof matrix tracks this row.

### Table stakes (must-have for v1.47 closeout)

- The gated route (`/app/reports/advanced`) and `live_session :entitled_reports` with `on_mount` guard must exist in the router and compile cleanly.
- The guard must use the canonical form from `guides/entitlements.md`: auth `on_mount` hook first, then `{Accrue.Live.Entitlements, {:require_feature, :advanced_reports}}`.
- `entitlements_guard_test.exs` must cover both the grant path (entitled org with `price_premium` plan → 200 + page content) and the deny path (non-entitled org → redirect to "/" with flash error). Both tests must pass in `mix test`.
- The entitlements catalog in `config/config.exs` must map `price_premium → features: [:advanced_reports]` — already present.
- The `AdvancedReportsLive` stub must render something distinct enough to assert `html =~ "Advanced Reports"` and `html =~ "You have access to this premium feature"` — already present.
- The adoption-proof matrix row for "Entitlement gating" must reference the correct file and route — already present.

**Dependencies on existing capabilities:** `Accrue.Live.Entitlements` (conditionally compiled, ships in core), `Accrue.Entitlements.Resolver.LocalMap` (reads local subscription state, zero Stripe calls on the gate path), `Accrue.Config.entitlements()` boot validation.

### Nice-to-have (deferred or optional enrichment)

- A second gated route demonstrating `{:require_plan, :premium}` (plan-level guard) alongside the feature guard — shows both API shapes to readers. Low complexity, high instructional value, not required for v1.47.
- A comment in `AdvancedReportsLive` linking to `guides/entitlements.md` as the canonical resource — zero complexity, pure docs.
- A plug-pipeline example in the router (`require_feature/1` macro in a `pipeline`) — the guide shows this pattern but the example host only demonstrates the `live_session` / `on_mount` form. Adding a controller route with a pipeline guard would complete the picture. Deferred unless the v1.47 scope explicitly adds a controller route.

---

## Adopter-Proof: Metered Usage

**Current state:** Already substantially complete. `subscription_live_test.exs` PROOF-04 covers the button click → `report_usage_for_scope/3` → `MeterEvent` DB row path. The UI card exists in `SubscriptionLive`. `AccrueHost.Billing.report_usage_for_scope/3` is the host facade. The adoption-proof matrix tracks this as PROOF-04.

### Table stakes (must-have for v1.47 closeout)

- `Billing.report_usage_for_scope/3` in `AccrueHost.Billing` must delegate to `Accrue.Billing.report_usage/3` (or `Accrue.report_usage/3`) and handle `:no_active_organization` and `:forbidden` errors explicitly. Already present.
- The `SubscriptionLive` UI card with `data-role="metered-usage-demo"` must exist and show the "Simulate API Call" button only when there is an active subscription — already gated by `if @subscription`.
- PROOF-04 test must assert: button renders, click succeeds, flash shows "Usage reported: 1 API call recorded.", exactly 1 `MeterEvent` row exists, `event_name == "api_calls"`. Already present.
- The event name `"api_calls"` must match a configured Stripe Meter definition name (in Fake, meter definitions are registered via `Accrue.Billing.MeterDefinitions`; in test, the Fake accepts any event name). The proof only needs to be Fake-consistent.
- The adoption-proof matrix must reference PROOF-04 — already present.

**Dependencies on existing capabilities:** `Accrue.Billing.MeterEventActions.report_usage/3` (transactional-outbox, idempotent via `identifier`), `Accrue.Jobs.MeterEventsReconciler` (reconciles `pending` rows the sync path missed — already in host cron config), Fake processor `report_meter_event/1` stub.

### Nice-to-have (deferred or optional enrichment)

- Show the `MeterEvent` row count or `event_name` in the rendered UI after a click (the current proof only flashes a message). This would make the proof more visual for adopters reading the code. Moderate complexity (requires a DB query on the socket side to reflect state).
- Add an `operation_id` to the simulated call so the proof also demonstrates idempotency (the same button click with the same `operation_id` produces 1 row, not 2). Requires wiring `operation_id` through the form/event — low-medium complexity.
- Demonstrate `record_usage!/3` (bang variant) with a comment explaining when to prefer the bang. Very low complexity, high instructional value.

---

## Adopter-Proof: Oban Cron

**Current state:** `DunningSweeper`, `DetectExpiringCards`, `MeterEventsReconciler`, and `MeteredRenewalReconciler` are already wired in `config/config.exs` under `Oban.Plugins.Cron`. `dunning_wiring_test.exs` proves the sweeper queue. `recovery_wiring_test.exs` (PROOF-06) proves `DetectExpiringCards` + `MeterEventsReconciler` queue presence. Both are in the adoption-proof matrix.

The v1.47 task is not adding new crons — it is enriching the proof to make the wiring more legible and ensuring each Accrue cron job is explicitly proven.

### Table stakes (must-have for v1.47 closeout)

- The `config/config.exs` Oban cron block must contain all four Accrue cron workers: `DunningSweeper`, `DetectExpiringCards`, `MeterEventsReconciler`, `MeteredRenewalReconciler`. Already present.
- Each queue that these workers use must appear in the host's `queues:` list: `accrue_dunning: 2`, `accrue_scheduled: 5`, `accrue_meters: 5`. Already present.
- `recovery_wiring_test.exs` must assert that `DunningSweeper`, `DetectExpiringCards`, and `MeterEventsReconciler` are enqueue-able and drain without error on a queue that exists — the "queue is wired" proof. Currently it uses `Oban.Testing` to confirm the job can be inserted; it should also assert the worker module is recognized by Oban (i.e., `use Oban.Worker` is satisfied). Already present.
- The adoption-proof matrix "Recovery wiring (PROOF-06)" row must reference the correct test file — already present.
- The `DunningSweeper` moduledoc's "Host wiring" section must show a code snippet that matches the exact config shape in `config/config.exs` — already aligned.

**Dependencies on existing capabilities:** `Oban.Plugins.Cron` (community Oban, already a transitive dep via host), `Accrue.Jobs.DunningSweeper` (Oban.Worker, `queue: :accrue_dunning`), `Accrue.Jobs.MeterEventsReconciler` (queue: `:accrue_meters`), `Accrue.Jobs.DetectExpiringCards` (queue: `:accrue_scheduled`), `Accrue.Jobs.MeteredRenewalReconciler` (queue: `:accrue_scheduled`).

### Nice-to-have (deferred or optional enrichment)

- An explicit test asserting that when the `accrue_dunning` queue is drained with no dunning candidates, the sweeper returns `{:ok, 0}` (the no-op case) — makes the "installed but idle" production behavior visible. Very low complexity.
- A comment in `config/config.exs` next to each cron entry explaining what it does and which guide to read — zero runtime complexity, high documentation value for adopters copying the config.
- Demonstrate `Oban.Plugins.Pruner` rationale in a comment: why `max_age: 60 * 60 * 24` (24 hours) is the example host's choice. This shows adopters that Accrue doesn't dictate pruning policy. Zero runtime complexity.

---

## Feature Dependencies Map

```
WR-05 (upsert fix)
  └─ depends on: accrue_entitlement_summaries table with unique_constraint(:customer_id)
                 (already migrated in prior phases)
  └─ interaction: EntitlementSummary.force_changeset/2 still has optimistic_lock(:lock_version)
                  — must verify this is harmless on upsert path (it is: upsert bypasses OCC)

IN-01 (processor field)
  └─ depends on: dispatch path passing `processor` atom through to write_entitlement_summary/8
                 (already wired: reduce_entitlement_summary/4 receives processor arg)

IN-02 (livemode null fidelity)
  └─ depends on: schema field(:livemode, :boolean) with no default (already correct)
  └─ interaction: must NOT add "|| false" coercion anywhere in the write path

IN-03 (moduledoc cosmetic)
  └─ depends on: identifying the exact target module ("stripe_fixtures")
  └─ interaction: none — pure docs

IN-04 (metrics counter)
  └─ depends on: identifying which counter is missing or documenting the omission
  └─ interaction: Accrue.Telemetry.Metrics.defaults/0 is conditionally compiled
                  (only when :telemetry_metrics dep present)

Entitlements gating proof
  └─ depends on: Accrue.Live.Entitlements (cond-compiled, ships in core)
               + entitlements config with price_premium -> :advanced_reports
               + AdvancedReportsLive stub module
               + entitlements_guard_test.exs (both grant + deny)
  └─ Already present: all of the above exist

Metered usage proof
  └─ depends on: Accrue.Billing.MeterEventActions.report_usage/3
               + AccrueHost.Billing.report_usage_for_scope/3 facade
               + MeterEvent schema + migration
               + Fake processor report_meter_event/1 stub
  └─ Already present: all of the above exist

Oban cron proof
  └─ depends on: all four Accrue cron workers (already exist as modules)
               + host Oban config with matching queues (already present)
               + recovery_wiring_test.exs + dunning_wiring_test.exs (already exist)
  └─ Already present: all of the above exist
```

---

## MVP Recommendation (v1.47 scope)

The v1.47 milestone is a polish and verification milestone, not a net-new feature milestone. The adopter-proof work is primarily closing gaps in proof legibility and test coverage, not writing new behavior.

**Already done, verify and close:**
1. WR-05 — upsert implementation exists; verify `Ecto.StaleEntryError` cannot occur, add a concurrency regression test.
2. IN-01 — 1-line change in `write_entitlement_summary/8` if not already using the `processor` arg; add a test.
3. IN-02 — audit `livemode` write path; add a test asserting `nil` payload field produces `NULL` DB column.
4. IN-03 — add/improve `@moduledoc` on the target fixtures module.
5. IN-04 — add the missing counter or document the omission with a comment.
6. Entitlements gating — already proven; ensure adoption-proof-matrix needle is correct and `mix test` passes.
7. Metered usage — already proven; ensure PROOF-04 test still passes after any WR-05/IN changes.
8. Oban cron — already wired; ensure `recovery_wiring_test.exs` covers all four workers, not just two.

**Defer:**
- Plug pipeline entitlements gating example (controller route + `require_feature/1` macro) — instructional value but not blocking.
- `operation_id` idempotency demonstration in metered usage UI — nice-to-have, not required for v1.47 closeout.
- Explicit no-op sweeper test (`{:ok, 0}` when no candidates) — not blocking.

---

## Sources

All HIGH confidence — direct source inspection of the Accrue repository at commit HEAD (2026-05-30):

- `/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex` (lines 579–687: write_entitlement_summary, upsert_entitlement_summary, WR-05 comment)
- `/Users/jon/projects/accrue/accrue/lib/accrue/billing/entitlement_summary.ex` (schema, force_changeset, optimistic_lock)
- `/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/router.ex` (live_session :entitled_reports)
- `/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs` (grant + deny tests)
- `/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` (PROOF-04)
- `/Users/jon/projects/accrue/examples/accrue_host/config/config.exs` (Oban cron config)
- `/Users/jon/projects/accrue/examples/accrue_host/docs/adoption-proof-matrix.md` (matrix rows)
- `/Users/jon/projects/accrue/accrue/lib/accrue/telemetry/metrics.ex` (defaults/0 counter list)
- `/Users/jon/projects/accrue/accrue/guides/entitlements.md` (canonical guard patterns)
- `/Users/jon/projects/accrue/.planning/PROJECT.md` (v1.47 goal + feature list)
