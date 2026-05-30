# Architecture Research — v1.47

**Researched:** 2026-05-30
**Scope:** ENT-10 concurrency fix (WR-05) + IN-01..04 polish + three adopter-proof gaps

---

## ENT-10 Fix Integration Points

### Where write_entitlement_summary/8 lives

`write_entitlement_summary/8` is a private function in `Accrue.Webhook.DefaultHandler` at line 579.
Call chain from webhook delivery:

```
DispatchWorker (Oban job)
  → handle_event("entitlements.active_entitlement_summary.updated", event, ctx)
  → dispatch/5 (gates on Accrue.Config.stripe_native_sync?/0)
  → reduce_entitlement_summary/4
  → reduce_entitlement_summary_for_customer/7   ← Repo.transact wraps this
      → check_stale/2
      → write_entitlement_summary/8             ← the target function
          → upsert_entitlement_summary/2        ← WR-05 target
          → maybe_record_summary_event/3
```

### WR-05: Repo.insert with on_conflict — what changes, what stays

**Current state (as of v1.46):** `upsert_entitlement_summary/2` at line 669 already implements the WR-05 fix. It uses `Repo.insert/2` with `conflict_target: :customer_id`, `on_conflict: {:replace_all_except, [...]}`, and an `on_conflict_where:` clause that enforces the skip-stale watermark at the DB level. The optimistic lock path (`Ecto.Changeset.optimistic_lock(:lock_version)`) has been replaced.

**However:** The `EntitlementSummary.force_changeset/2` schema function (entitlement_summary.ex line 85) still calls `|> optimistic_lock(:lock_version)` and the schema still declares `field(:lock_version, :integer, default: 1)`. These are now vestigial — the changeset is used as the source of attrs fed into the upsert, but since `upsert_entitlement_summary/2` calls `Repo.insert` (not `Repo.update`), `optimistic_lock/2` in the changeset has no effect on the DB-level conflict path. This is a documentation/cleanup concern (IN-03/IN-04 territory) rather than a functional bug.

**What changes for WR-05 if not already shipped:**
- `upsert_entitlement_summary/2`: replace the `Repo.get_by` + conditional insert/update pattern (row=nil → insert, row=existing → optimistic update) with `Repo.insert` with `on_conflict` as already done.
- `EntitlementSummary.force_changeset/2`: remove `optimistic_lock(:lock_version)` since it serves no purpose on the DB upsert path. The `@cast_fields` list already includes `:lock_version` but it's a no-op.
- The `lock_version` column itself can remain in the schema (removing it requires a migration); removing the changeset call is a code-only change.

**What stays unchanged:**
- `reduce_entitlement_summary_for_customer/7` — the `Repo.transact` wrapper, the `check_stale/2` application-level guard (still the first line of defense before the DB-level watermark check), and the orphan-deferred path all stay.
- `write_entitlement_summary/8` — the material-change detection (`summary_material_change?/3`), the `stamp_summary_watermark/4` monotonicity guard (WR-02), the ledger write (`maybe_record_summary_event/3`), and the telemetry emissions all stay.
- The `Accrue.Config.stripe_native_sync?/0` gate in `dispatch/5` — off by default, unchanged.

### IN-01: Set :processor in write_entitlement_summary/8

**Current state:** Line 595 in DefaultHandler sets `processor: processor_name()`. `processor_name/0` at line 1716 reads `Processor.__impl__()` — this returns the currently configured processor module (Fake, Stripe, or Braintree). For Stripe-native sync this is almost always correct, but if a host has configured Braintree as the default processor and happens to receive a Stripe entitlements webhook (e.g. during a migration), `processor_name()` would return `"braintree"`.

**The fix:** Pass the `processor` argument already threaded through from `handle_event/3` → `dispatch/5` → `reduce_entitlement_summary/4` → `reduce_entitlement_summary_for_customer/7` down into `write_entitlement_summary/8` and use it directly (e.g. `to_string(processor)`) rather than calling `processor_name()`. The `processor` atom is already in scope in `reduce_entitlement_summary_for_customer/7` — it just needs to be passed as an additional argument to `write_entitlement_summary`.

**Signature change:** `write_entitlement_summary/8` becomes `write_entitlement_summary/9` (adds `processor`), or the attrs map construction is moved to the caller with `processor` already resolved. Either approach is local to DefaultHandler — no public API change.

**What stays:** The `Repo.get_by(Customer, processor_id: cus_id, processor: to_string(processor))` call at line 537 already scopes by processor. This is the correct ENT-10 scoping pattern that v1.46 applied to customer lookup — IN-01 closes the same gap at the write side.

### IN-02: Pass raw boolean-or-nil for livemode

**Current state:** Line 597 sets `livemode: get(obj, :livemode)`. The `get/2` helper at line 1735 does dual atom/string key lookup and returns `nil` on miss. The `EntitlementSummary` schema declares `field(:livemode, :boolean)` — Ecto will cast a nil correctly as nil, so the schema handles it. The concern is whether the `get/2` call can return something non-boolean (e.g. a string `"true"` from a string-keyed map). In the Stripe webhook payload, `livemode` is always a boolean, and the Fake synthesizes it as a boolean atom. String-keyed JSON payloads from the real webhook path will have `"livemode"` as `true/false` (JSON bool). This is low risk in practice.

**The fix (if needed):** Explicit coercion — `livemode: coerce_bool(get(obj, :livemode))` — where `coerce_bool(true) = true`, `coerce_bool(false) = false`, `coerce_bool(nil) = nil`, `coerce_bool(_) = nil`. This ensures "unknown" (nil) is preserved as nil rather than defaulting to false. Local helper addition to DefaultHandler; no schema change.

### IN-03/IN-04: StripeFixtures moduledoc polish + metrics counter

**IN-03 (StripeFixtures moduledoc):** `Accrue.Test.StripeFixtures` at `accrue/test/support/stripe_fixtures.ex` has a moduledoc. The polish target is likely adding an `entitlement_summary_updated/1` fixture function (currently absent from the file) to make the test module complete and self-describing. This is a new function addition to the test support file, not a modification of existing functions.

**IN-04 (metrics counter or documented omission):** The `write_entitlement_summary/8` telemetry path emits `[:accrue, :entitlements, :summary_synced]` (line 614) with a `count: 1` measurement. If a `TelemetryMetrics.counter/2` definition is missing from `Accrue.Telemetry` (or wherever Accrue's default metrics module lives), IN-04 adds it. If the metrics module deliberately omits advisory-cache metrics (reasonable since the cache is observational-only), IN-04 documents the omission in the telemetry catalog. Either path is additive-only; no existing metric definitions change.

---

## Adopter-Proof Integration Points

### Proof 1: Entitlements route guard (already partially proven)

**What exists:** The `AdvancedReportsLive` at `/app/reports/advanced` is already gated by `Accrue.Live.Entitlements` with `{:require_feature, :advanced_reports}` in the router's `live_session :entitled_reports` block (router.ex lines 50-55). `AccrueHostWeb.EntitlementsGuardTest` at `test/accrue_host_web/live/entitlements_guard_test.exs` tests both the entitled (premium plan → access) and non-entitled (basic plan → redirect) cases.

**What's missing for v1.47:** The test exists and covers both cases. The `AdvancedReportsLive` template is a stub. A v1.47 pass may enrich the template to show entitlement data (e.g. `Accrue.features_for/1` output) for documentation value, and optionally add a Plug-pipeline guard test for a non-LiveView route using `Accrue.Plug.RequireEntitlement`.

**Integration point:** `examples/accrue_host/lib/accrue_host_web/router.ex` — existing `live_session :entitled_reports` block. No new modules needed unless adding a Plug-pipeline equivalent. The `config.exs` entitlements plan config already maps `premium` plan → `[:advanced_reports]` feature.

**New vs modified:** Existing test at `test/accrue_host_web/live/entitlements_guard_test.exs` — may need expansion. `AdvancedReportsLive` template may need fleshing out. Router is unchanged.

### Proof 2: Metered usage adopter-proof

**What exists:** `AccrueHost.Billing.report_usage_for_scope/3` at billing.ex line 159 wraps `Accrue.Billing.report_usage/3`. `SubscriptionLive` has a `simulate_api_call` event handler at line 192 that calls `report_usage_for_scope/3` with `"api_calls"`. The UI already renders a "Metered Usage Demo (PROOF-04)" section with a "Simulate API Call" button at line 349.

**What's missing for v1.47:** A dedicated test file proving the metered usage flow from the adopter's perspective. The proof needs: (a) a test that calls `report_usage_for_scope/3` and asserts the Fake records a meter event, and (b) a test that the LiveView button dispatches the event and shows a flash. The `Plans.all()` already includes `"price_metered"` (unit_amount 0).

**Integration point:** `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` — add a `simulate_api_call` test case. No new modules needed. The metered plan (`"price_metered"`) is already defined in `Plans.all()` and `Plans.ids()`.

**New vs modified:** The UI handler in SubscriptionLive already exists (line 192). The `report_usage_for_scope/3` host facade exists. The missing piece is a test that exercises the full path: subscribe to metered plan → click button → assert `{:ok, _event}` from Fake. This is a new test, not a new module.

### Proof 3: Oban cron adopter-proof

**What exists:** `config.exs` lines 48-55 already wire four Oban crons: `DunningSweeper` (*/15), `DetectExpiringCards` (@daily), `MeterEventsReconciler` (* * * * *), and `MeteredRenewalReconciler` (*/5). `RecoveryWiringTest` at `test/accrue_host/recovery_wiring_test.exs` proves the recovery crons (DetectExpiringCards, MeterEventsReconciler, MeteredRenewalReconciler) are present and can execute. `DunningWiringTest` proves the dunning sweeper path end-to-end (enqueue → drain → recovery → sweep).

**What's missing for v1.47:** A test that explicitly asserts `DunningSweeper` is in the crontab (analogous to `RecoveryWiringTest`'s assertion pattern). `DunningWiringTest` proves the sweeper executes but doesn't assert the crontab entry. Alternatively, if an MRR snapshotting cron exists in `accrue` core, adding it to the crontab and asserting its presence closes the proof.

**Integration point:** `examples/accrue_host/config/config.exs` — `Oban.Plugins.Cron` crontab list for any new entry. `examples/accrue_host/lib/accrue_host/application.ex` — Oban is already in the supervision tree (line 14), no changes needed. The `accrue_scheduled` queue (config.exs line 45) is the correct queue for any new cron worker.

**New vs modified:** If adding an MRR cron entry, config.exs gets a new crontab line and a new test assertion. If the proof is the dunning sweeper, the test addition is to `recovery_wiring_test.exs` or a new `dunning_cron_wiring_test.exs`. No new host workers or supervision children.

---

## Suggested Build Order

### Phase A: WR-05 + IN-01..02 — Core correctness in DefaultHandler

**Rationale:** These are changes to `accrue` core (`default_handler.ex`, `entitlement_summary.ex`). They are self-contained, don't touch `examples/`, and represent correctness work that should be verified before the rest of the milestone is closed.

Tasks:
1. Confirm/finalize `upsert_entitlement_summary/2` uses `Repo.insert on_conflict` (may already be done per line 676; if so, remove the vestigial `optimistic_lock/2` from `EntitlementSummary.force_changeset/2`).
2. Pass `processor` from the already-threaded argument into `write_entitlement_summary` attrs assembly instead of calling `processor_name()`. Signature becomes `/9` or attrs are built in the caller.
3. Add `coerce_bool/1` guard for `livemode` if the team judges it necessary for nil-preservation.
4. Update `entitlement_summary_test.exs` in `accrue/test/` to exercise the upsert + correct processor behavior.

**No router or host-app changes needed.** No migration needed (the `lock_version` column can stay; only the changeset call is removed).

### Phase B: IN-03/IN-04 — StripeFixtures polish + metrics catalog

**Rationale:** These are additive-only changes to test support and observability. They don't block the adopter-proofs but should land before the final docs pass.

Tasks:
1. Add `entitlement_summary_updated/1` to `Accrue.Test.StripeFixtures`.
2. Add or document the `[:accrue, :entitlements, :summary_synced]` counter in the telemetry catalog / metrics module.
3. No schema changes. No host-app changes. Can run in parallel with Phase A.

### Phase C: Entitlements gating adopter-proof — verify and optionally enrich

**Rationale:** The route guard LiveView path already exists with passing tests. Phase C is a verification pass plus any additional coverage (Plug guard, richer template).

Tasks:
1. Verify `EntitlementsGuardTest` covers the redirect case with correct flash copy — current test already does this.
2. Optionally add a Plug-pipeline guard test for a non-LiveView route.
3. Enrich `AdvancedReportsLive` template to show entitlement data if documentation value warrants it.
4. All changes in `examples/accrue_host/` only — no `accrue` core changes.

**Dependency on Phase A:** None. The entitlement guard reads from the local plan config, not the `EntitlementSummary` table. The WR-05 fix is orthogonal to the gate path.

### Phase D: Metered usage adopter-proof — new test, no new module

**Rationale:** The UI and host facade both exist. Phase D adds the missing test coverage.

Tasks:
1. Add a test in `test/accrue_host_web/live/subscription_live_test.exs` or a new `metered_usage_proof_test.exs` that:
   - Subscribes the org to `"price_metered"`.
   - Calls `Billing.report_usage_for_scope/3` or clicks "Simulate API Call" via `Phoenix.LiveViewTest`.
   - Asserts the flash shows "Usage reported: 1 API call recorded."
   - Optionally asserts a Fake meter event was recorded.
2. No new modules in `accrue_host/lib/`. No config changes.

**Dependency on Phase A:** None — `Accrue.Billing.report_usage/3` is already implemented.

### Phase E: Oban cron adopter-proof — verify or extend config

**Rationale:** The dunning sweeper and recovery crons are already wired and tested. Phase E closes the gap on explicit crontab assertion.

Tasks (choose one):
- **Option 1 (verify):** Assert that `DunningSweeper` is present in the crontab. Add to `recovery_wiring_test.exs` or write `dunning_cron_wiring_test.exs`. Test-only addition.
- **Option 2 (extend):** If an MRR snapshotting cron exists in `accrue` core (check `Accrue.Jobs.*`), add it to the crontab in `config.exs` and add a test assertion. No new host workers needed.

**Dependency on Phase A:** None. Oban cron wiring is independent of the entitlement cache.

### Build order summary

```
Phase A (WR-05 + IN-01..02)   ← accrue core; no adopter-host impact
Phase B (IN-03..04)            ← additive; parallel with A if in separate PRs
  ↓ (for docs/telemetry accuracy)
Phase C (Entitlements proof)   ← examples/accrue_host; independent of A/B
Phase D (Metered usage proof)  ← examples/accrue_host; independent of A/B
Phase E (Oban cron proof)      ← examples/accrue_host; independent of A/B
```

Phases C, D, E are mutually independent and can run in parallel or sequence after A/B. Phase A is the only phase with a correctness dependency (IN-01 must land before the entitlement summary is considered processor-accurate), but the adopter-proof tests for entitlements (Phase C) don't test the summary table path — they test the local plan gate — so C/D/E are truly unblocked even before A lands.

---

## Cross-cutting Notes

**The entitlement summary table is never read by the gate path.** `Accrue.Live.Entitlements` on_mount guard, `Accrue.entitled?/2`, and `Accrue.has_active_plan?/2` all read from the local plan config (`config :accrue, :entitlements, plans: [...]`). The WR-05/IN-01 fixes affect only the write path for the observational advisory cache. This means the adopter-proof tests (Phase C) do not need to trigger webhook events or seed the `accrue_entitlement_summaries` table — they only need a live subscription on the correct plan.

**The `processor` argument threading in DefaultHandler is already in place through `dispatch/5`.** The `handle_event` clause at line 126 passes `event.processor` to `dispatch/5`, which passes it to `reduce_entitlement_summary/4`, which passes it to `reduce_entitlement_summary_for_customer/7`. The gap is only in `write_entitlement_summary/8`, which calls `processor_name()` (global impl lookup) instead of using the already-threaded atom. This is a one-argument-pass fix with no structural refactor needed.

**The Oban supervision tree in `application.ex` needs no changes.** Oban is already started with `{Oban, Application.fetch_env!(:accrue_host, Oban)}`. Adding a cron entry is a `config.exs` change only. The `accrue_scheduled` queue (already in config.exs line 45) is the correct queue for any new cron worker.

**`AdvancedReportsLive` is a stub but `EntitlementsGuardTest` is already merge-blocking.** The test covers both the positive (access granted) and negative (redirect + flash) cases. v1.47 Phase C is likely a verification pass unless richer template content is specifically called for in the REQUIREMENTS.

**No migration is required for any v1.47 changes.** Removing `optimistic_lock/2` from `EntitlementSummary.force_changeset/2` is a code-only change. The `lock_version` column remains in the DB and schema definition; it just stops being used in the changeset (it's already ignored by the `Repo.insert on_conflict` path).
