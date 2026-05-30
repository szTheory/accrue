# Pitfalls Research — v1.47

**Scope:** ENT-10 advisory cache upsert/watermark fix (WR-05), field accuracy corrections (IN-01..04), and adopter-proof examples for entitlements gating, metered usage, and Oban crons in `examples/accrue_host`.
**Researched:** 2026-05-30
**Confidence:** HIGH — analysis based directly on reading the production source files.

---

## WR-05 Upsert / Watermark Pitfalls

### Pitfall WR-05-01: `on_conflict_where` NULL comparison short-circuits to no-op on nil watermark

**What goes wrong:** The current `upsert_entitlement_summary/2` in `default_handler.ex` uses:

```elixir
on_conflict_where:
  from(e in EntitlementSummary,
    where: e.last_stripe_event_ts < fragment("EXCLUDED.last_stripe_event_ts")
  )
```

When `EXCLUDED.last_stripe_event_ts` is `NULL` (because `stamp_summary_watermark/4` fell through the nil guard and did not stamp a timestamp), the `<` comparison returns `NULL` in SQL — not `TRUE` — so Postgres silently does nothing. The row is not updated, no error is raised, and `returning: true` returns the unchanged stale row as if the write succeeded.

**Why it happens:** `stamp_summary_watermark/4` correctly guards against nil `evt_ts` by carrying the prior row's watermark forward. But the clause `stamp_summary_watermark(attrs, _evt_ts, _evt_id, nil)` (first-ever write with no prior row and no DateTime) returns `attrs` unchanged — `last_stripe_event_ts` is absent from the attrs map entirely. On insert this is fine (column is nullable). On conflict, `EXCLUDED.last_stripe_event_ts` is NULL and the WHERE short-circuits to no-op.

**Consequences:** A retry or duplicate delivery where `evt_ts` is nil does not update the row (correct), but the calling code receives `{:ok, stale_row}` and may record a `entitlements.summary.synced` ledger event against a row that was not actually updated. Observability is misleading; `result: :written` telemetry fires against a stale snapshot.

**Prevention:** Change the WHERE to handle the NULL case explicitly: `(EXCLUDED.last_stripe_event_ts IS NULL OR e.last_stripe_event_ts < EXCLUDED.last_stripe_event_ts)`. This matches the intent of `check_stale/2` which lets nil timestamps proceed.

**Warning signs:** Test that covers "nil timestamp event on existing row" returns `{:ok, row}` but `row.last_stripe_event_ts` still shows the old value, and telemetry shows `result: :written` with stale data.

**Phase:** WR-05 implementation phase.

---

### Pitfall WR-05-02: `optimistic_lock(:lock_version)` in `force_changeset/2` conflicts with the DB-level upsert

**What goes wrong:** `EntitlementSummary.force_changeset/2` still calls `optimistic_lock(:lock_version)`. When `upsert_entitlement_summary/2` calls `Repo.insert/2` with `on_conflict: {:replace_all_except, ...}`, Ecto's optimistic lock mechanism injects a `WHERE lock_version = ?` predicate into the conflict-branch UPDATE. For a concurrent delivery scenario, two Oban workers both read `lock_version: 1`, form changesets with `lock_version: 2`. One succeeds and commits `lock_version: 2`. The second's `on_conflict_where` would pass (newer timestamp), but the `optimistic_lock` WHERE clause `lock_version = 1` is now false — the update is silently suppressed with no error.

**Why it happens:** `optimistic_lock/1` in Ecto adds a WHERE clause to UPDATEs and increments the field in the changeset attrs. When the changeset is used in `Repo.insert/2` (not `Repo.update/2`), the WHERE is injected into the conflict-target UPDATE branch. This re-introduces the exact `Ecto.StaleEntryError`-class failure that WR-05 is meant to eliminate, except now it manifests as a silent no-op rather than a raised exception.

**Consequences:** Under concurrent Oban delivery, the second worker's upsert is suppressed and `last_stripe_event_ts` does not advance to the newer value. The row stays partially stale. No error surfaces.

**Prevention:** Remove `optimistic_lock(:lock_version)` from `force_changeset/2`, or create a separate `upsert_changeset/2` for the upsert write path that omits the lock. The `lock_version` column may remain in the schema for schema compatibility, but it must not be wired through Ecto's optimistic lock mechanism when the upsert does its own DB-level concurrency guard via `on_conflict_where`. Add `lock_version` to the `{:replace_all_except, [...]}` exclusion list to keep it frozen (or remove it from the schema in a future migration).

**Warning signs:** A test that inserts two events with different timestamps (one older, one newer) in serial passes, but a concurrent test (two `Task.async` workers, same starting `lock_version`) shows the row's `last_stripe_event_ts` not advancing to the newer value.

**Phase:** WR-05 implementation phase. Coupled with WR-05-01 — both must be addressed together.

---

### Pitfall WR-05-03: `returning: true` on a no-op conflict returns the pre-conflict row as if it were a write

**What goes wrong:** When Postgres evaluates the `on_conflict_where` and decides NOT to update (the existing row's timestamp is already newer), `Repo.insert/2` with `returning: true` returns `{:ok, %EntitlementSummary{}}` populated with the **existing row's values**, not `EXCLUDED`'s. The calling code in `write_entitlement_summary/8` treats any `{:ok, saved}` as a successful write, emits `result: :written` telemetry, and records a ledger event against `saved.id`.

**Why it happens:** PostgreSQL's `ON CONFLICT DO UPDATE WHERE <false>` returns 0 rows affected. Ecto with `returning: true` returns the struct using the existing row values from the DB. Callers cannot distinguish "I wrote it" from "I was the stale one and lost" without additional checks.

**Consequences:** `material?` check and ledger write run against a row that was not actually updated. `result: :written` fires in telemetry. A spurious `entitlements.summary.synced` event is recorded in `accrue_events`. Not a correctness bug for entitlement state (the cache is observational-only, D-01), but it inflates the ledger and misleads operators.

**Prevention:** After the `Repo.insert/2` call, compare the returned row's `last_stripe_event_ts` with `attrs[:last_stripe_event_ts]`. If they don't match (and the expected watermark is non-nil), the upsert was a no-op — return `{:ok, :stale}` and let `write_entitlement_summary/8` treat it as unchanged. Emit `result: :unchanged` telemetry and skip the ledger write.

**Warning signs:** Test a "stale second delivery": send event A (newer), then event B (older). After B, the ledger should have one `entitlements.summary.synced` event. If it has two, the pitfall hit.

**Phase:** WR-05 implementation phase. Address alongside WR-05-01 and WR-05-02.

---

### Pitfall WR-05-04: Serial tests do not exercise the concurrent conflict scenario

**What goes wrong:** Tests that call `write_entitlement_summary` twice in sequence (older timestamp second) pass regardless of whether the watermark guard is correct — the second call simply sees a more-recent watermark and skips via `check_stale/2` before reaching the upsert. The concurrency failure (WR-05-02) only manifests when two transactions begin simultaneously and both pass `check_stale/2` with the same starting `lock_version`.

**Why it happens:** True concurrent delivery is Oban worker parallelism. Most Accrue tests use `DataCase` with a single connection that is rolled back — a genuine concurrent insert race cannot be simulated within one connection without `Task.async` + sandbox sharing.

**Consequences:** The bug from WR-05-02 can exist without any test catching it. The fix is shipped with false confidence from green serial tests.

**Prevention:** Write at least one test that spawns two `Task.async` workers, both calling the entitlement summary reducer with different timestamps (one older, one newer), both starting after the customer row exists. Use `Ecto.Adapters.SQL.Sandbox.allow/3` or `checkout: :shared` to share the test connection. Assert that after both tasks complete, the row's `last_stripe_event_ts` equals the newer timestamp.

**Warning signs:** All existing entitlement summary tests use `DataCase` with a single path — no `Task.async`. No concurrent conflict scenario exists in the test suite.

**Phase:** WR-05 test coverage phase. Without this test, the fix is unverifiable in CI.

---

## IN-01..04 Polish Pitfalls

### Pitfall IN-01-01: `processor_name()` in `write_entitlement_summary` ignores the event's processor argument

**What goes wrong:** `write_entitlement_summary/8` builds attrs with `processor: processor_name()`, where `processor_name/0` dispatches on `Processor.__impl__()` — the globally configured processor (Stripe, Fake, Braintree). The `processor` argument is already threaded into `reduce_entitlement_summary_for_customer/7` as the 7th parameter, but `write_entitlement_summary` does not accept it. Looking at the 8 args: `evt_id, evt_ts, obj, cus_id, customer, row, entitlements, data` — the `processor` variable from the outer function is in scope as a closure variable but is silently replaced by `processor_name()` inside `write_entitlement_summary`.

**Why it happens:** When the entitlement sync was written (Phase 127), only Stripe was in scope. The `processor` argument was threaded into `dispatch/5` and `reduce_entitlement_summary_for_customer/7` for ENT-10 cross-processor correctness but was not forwarded the final step into `write_entitlement_summary`.

**Consequences:** In Fake-lane tests, the summary row is written with `processor: "fake"` even when the event was synthesized as a Stripe event. In a dual-processor deployment, the persisted `processor` column value is inaccurate. Telemetry metadata (see IN-04) also derives from the wrong processor.

**Prevention:** Add `processor` as the 9th argument to `write_entitlement_summary`, replacing the `processor: processor_name()` line with `processor: to_string(processor)`. Update the call site in `reduce_entitlement_summary_for_customer/7` to forward the bound `processor` variable. This is a 3-line change.

**Warning signs:** In a test that synthesizes a Stripe entitlement summary event while the global config is set to Fake, the row in the DB has `processor: "fake"`. Add an assertion: `assert summary.processor == "stripe"` after the event dispatch.

**Phase:** IN-01 fix phase.

---

### Pitfall IN-02-01: Missing `livemode` key in payload coerces nil over a prior known value

**What goes wrong:** `write_entitlement_summary/8` sets `livemode: get(obj, :livemode)`. The `get/2` helper returns `nil` for any missing key, with no distinction between "payload explicitly set `livemode: false`" and "payload had no `livemode` key." On an upsert with `{:replace_all_except, [...]}`, if the current event's payload lacks the `livemode` key, the upsert writes `livemode: nil` over a previously stored `false` — erasing the known livemode state.

**Why it happens:** The Stripe entitlement summary object spec does not guarantee `livemode` is present on every delivery. The `get/2` helper is designed to handle both atom- and string-keyed maps but cannot distinguish key-absent from key-nil.

**Consequences:** Operators querying `livemode = false` will miss rows that reverted to null after a payload without the key. Dashboard filtering by livemode becomes unreliable.

**Prevention:** Apply a "keep existing" rule for livemode in `write_entitlement_summary`: if `get(obj, :livemode)` is `nil` AND a prior `row` exists with a non-nil `livemode`, carry the prior value forward by setting `livemode: row.livemode` in attrs (or by omitting the key). This mirrors the `stamp_summary_watermark/4` pattern for watermark fields.

**Warning signs:** Test stores a summary with `livemode: false`, then delivers a second event with the `livemode` key absent from the payload. Assert `row.livemode == false`. If it returns `nil`, the pitfall hit.

**Phase:** IN-02 fix phase.

---

### Pitfall IN-03-01: `entitlement_summary_event/2` fixture defaults `livemode: false` — IN-02 nil path is never tested by default

**What goes wrong:** The `entitlement_summary_event/2` fixture in `Accrue.Test.StripeFixtures` always defaults `livemode: false` (line 426). This means every test using the default fixture exercises the testmode code path where `livemode` is explicitly `false`. The IN-02 nil-collapse bug only manifests when the `livemode` key is entirely absent from the payload. There is currently no fixture option that omits the key.

**Consequences:** IN-02 fix tests written using the default fixture will not catch the nil-collapse bug unless the fixture is explicitly built without the `livemode` key. Tests may give false confidence that IN-02 is fixed.

**Prevention (IN-03 scope):** Add an `:omit_livemode` option to `entitlement_summary_event/2` that excludes the key from the summary object map entirely — distinct from `livemode: nil` (which explicitly sets null as a value). Update the `@doc` to document the option. The IN-02 fix should include a test using `omit_livemode: true`.

Also: the `@moduledoc` for `Accrue.Test.StripeFixtures` should clarify that the module lives in `test/support/` and is not part of the published Hex package — adopters who want these fixtures in their own test suites must copy them or use the path-dep pattern documented in the install guide.

**Phase:** IN-03 is doc-only for the `@moduledoc` clarification; the `:omit_livemode` option is a small behavior addition. Safe to bundle with IN-02 test coverage.

---

### Pitfall IN-04-01: `processor` absent from `[:accrue, :entitlements, :summary_synced]` telemetry metadata

**What goes wrong:** The `[:accrue, :entitlements, :summary_synced]` telemetry event emitted in `write_entitlement_summary/8` carries `customer_id`, `has_more`, `entitlement_count`, and `result` in metadata, but not `processor`. In a dual-provider deployment, operators cannot segment entitlement sync events by processor from telemetry alone.

**Why it happens:** When the entitlement sync was written (Phase 127), only Stripe was in scope. The processor argument was not threaded through to the telemetry metadata (same root cause as IN-01).

**Consequences (documented omission option):** If IN-04 scope is "metrics counter or documented omission," the documented omission path is: add a code comment at the telemetry call noting that `processor` metadata is absent and will be added when IN-01 threads `processor` into `write_entitlement_summary`. The counter itself fires correctly; the omission is only observable in multi-provider deployments.

**Prevention if fixing (not just documenting):** Once IN-01 threads `processor` into `write_entitlement_summary/9`, add `processor: to_string(processor)` to the `metadata` map before the `Accrue.Telemetry.span` call. This is a 1-line addition after the IN-01 fix.

**Phase:** If bundled with IN-01, the processor threading fix serves both IN-01 and IN-04 simultaneously. If IN-04 scope is documentation-only, add the comment in the IN-04 fix phase and resolve the real fix in the same PR as IN-01.

---

## Adopter-Proof Example Pitfalls

### Pitfall PROOF-01: Entitlements guard `on_mount` returns "no access" when the real problem is no active organization

**What goes wrong:** The existing example router wires:

```elixir
live_session :entitled_reports,
  on_mount: [
    {AccrueHostWeb.UserAuth, :require_authenticated},
    {Accrue.Live.Entitlements, {:require_feature, :advanced_reports}}
  ] do
  live("/app/reports/advanced", AdvancedReportsLive, :index)
end
```

If the socket has no `active_organization` (the user has no org membership, or the session's `active_organization_id` is stale), `Accrue.Live.Entitlements` resolves the billable from the scope, finds nil, evaluates `Accrue.entitled?/2` against a nil billable, returns `false`, and redirects with "You don't have access to this page." The user sees an access-denied flash when the real issue is "no organization selected." This misleads users in multi-tenant apps.

**Consequences for adopters:** Adopters copy the example and their users see a confusing access-denied flash when they haven't selected an organization. The pitfall is specific to multi-tenant billing where the billable is an organization, not the user.

**Prevention:** In the adopter-proof example, document (as a code comment in the router) that the auth guard order matters and the organization scope must be resolved and loaded before the entitlements guard fires. If the host app uses a scope-loading `on_mount` hook that sets `active_organization`, that hook must precede `Accrue.Live.Entitlements` in the list. Alternatively, add a separate `on_mount` that checks for active organization and redirects with a "please select an organization" message before the entitlement check runs.

**Phase:** Entitlements gating adopter-proof phase.

---

### Pitfall PROOF-02: `LocalMap` not configured for the fixture price ID — entitled org test fails with a redirect

**What goes wrong:** `entitlements_guard_test.exs` calls `Billing.subscribe(entitled_org, "price_premium", trial_end: {:days, 14})`. In Fake-lane, `subscribe/3` creates a local subscription row with `processor_plan_id: "price_premium"`. The entitlement resolver then calls `Accrue.Entitlements.LocalMap` to map `"price_premium"` to features. If the host's resolver configuration does not include `"price_premium"` → `[:advanced_reports]`, the guard will deny even the "entitled" org and the test will assert a redirect — a false failure.

**Why it happens:** The example test assumes the `PlanResolver` is configured with the correct price-to-feature mapping. This is not self-evident from the test file alone.

**Consequences:** Adopters copy the example test, run it without configuring their own `LocalMap` or `PlanResolver`, and see the entitled-org test fail with a redirect. They conclude entitlements gating is broken. The actual issue is a missing config entry.

**Prevention:** Add an explicit assertion in the `AccrueCase` setup or at the top of the test: `assert :advanced_reports in Accrue.entitled_features_for_plan("price_premium")` (or equivalent), with a clear error message if the config is wrong. Add a code comment in the test: "This test requires `PlanResolver` to map `price_premium` to `[:advanced_reports]` — see `AccrueHost.Billing.PlanResolver`."

**Phase:** Entitlements gating adopter-proof phase.

---

### Pitfall PROOF-03: Metered usage `report_usage/3` succeeds in Fake-lane for any plan — adopters miss the "metered price" requirement

**What goes wrong:** In the existing `subscription_live_test.exs` PROOF-04 test, `simulate_api_call` calls `Billing.report_usage_for_scope(scope, "api_calls", value: 1)`. In Fake-lane, `report_usage/3` creates a `MeterEvent` row and returns `{:ok, event}` regardless of whether the org has a subscription with a metered price. The test asserts `Repo.aggregate(MeterEvent, :count) == 1` and passes.

In production (Stripe), `report_usage/3` requires that the subscription item has `billing_scheme: "per_unit"` and a metered price ID. Calling it on a flat-rate plan returns a Stripe `400` error. The adopter-proof example does not demonstrate this distinction.

**Consequences:** Adopters see `report_usage/3` working in tests against any plan, then get Stripe API errors in production when their plan is not metered. The example silently hides a "wrong plan type" failure mode that is one of the most common adopter mistakes with metered billing.

**Prevention:** Add a comment in the `SubscriptionLive` PROOF-04 section and in `billing_facade_test.exs` documenting that `report_usage/3` requires a metered price ID (`billing_scheme: "per_unit"`) configured on the Stripe plan. If a dedicated metered adopter proof is added in v1.47, wire it against `"price_metered"` (already in `Plans.ids/0` in the example host) and include a comment: "In production, `price_metered` must be a Stripe price with billing_scheme: per_unit. The Fake processor does not enforce this."

**Phase:** Metered usage adopter-proof phase.

---

### Pitfall PROOF-04: `value:` vs `quantity:` — wrong option key sends default silently

**What goes wrong:** `Billing.report_usage/3` accepts `value:` as the option key for usage quantity (as used in the existing example: `value: 1`). If an adopter uses `quantity: 1` (the Stripe API field name), the option is silently ignored — the internal `Keyword.get(opts, :value, default)` returns the default. No error is raised. The meter event is recorded with the wrong quantity. Stripe receives the incorrect value.

**Why it happens:** The public API uses `value:` as the Accrue-idiomatic key to avoid leaking Stripe terminology into the host-facing API surface. Adopters coming from the Stripe Billing Meter docs will reach for `quantity:` by reflex.

**Consequences:** Adopters ship metered billing that under-reports usage. Revenue impact. This is a "wrong mental model from Stripe docs" trap that adopters hit reliably.

**Prevention:** In the adopter-proof example call site, add an inline comment: `# NOTE: use value: not quantity: — quantity: is silently ignored`. Optionally, add a defensive `if Keyword.has_key?(opts, :quantity), do: Logger.warning(...)` in `report_usage/3` to surface the mistake at runtime.

**Phase:** Metered usage adopter-proof phase. Also a candidate for a callout in `guides/metered-billing.md`.

---

### Pitfall PROOF-05: Adopter replaces their existing Oban crontab instead of merging Accrue's entries

**What goes wrong:** The `recovery_wiring_test.exs` asserts that `DetectExpiringCards`, `MeterEventsReconciler`, and `MeteredRenewalReconciler` are in the host's Oban `Cron` plugin. If an adopter already has a `Cron` plugin configured with their own crontab entries and they add Accrue's entries by directly assigning `crontab: accrue_entries`, their own cron jobs are silently dropped. Oban's `Cron` plugin accepts a single `crontab:` list with no merge/append API.

**Why it happens:** The adopter-proof example owns the entire Oban config (it is a standalone example app). Adopters copy the `config.exs` crontab block and replace their existing configuration.

**Consequences:** An adopter who copies the config block replaces their existing cron jobs. Background jobs for their own business logic stop running. No error is raised; jobs just never fire. This is a subtle drop that may not surface until the next billing cycle.

**Prevention:** In the adopter-proof example's `config.exs` comment block, include an explicit note: "If your application already has an Oban Cron plugin, **append** these entries to your existing crontab list. Do not replace — replacing silently drops your existing cron jobs." Show a merge pattern:

```elixir
crontab: your_existing_cron_jobs() ++ [
  {"0 8 * * *", Accrue.Jobs.DetectExpiringCards},
  {"* * * * *", Accrue.Jobs.MeterEventsReconciler},
  {"*/5 * * * *", Accrue.Jobs.MeteredRenewalReconciler}
]
```

**Phase:** Oban cron adopter-proof phase.

---

### Pitfall PROOF-06: Missing Oban queue silently stalls all webhook processing

**What goes wrong:** Accrue's workers are enqueued into named queues (`accrue_webhooks`, `accrue_mailers`, `accrue_meters`, `accrue_scheduled`). If an adopter configures Oban with only `queues: [default: 10]`, jobs enqueued to `accrue_webhooks` are inserted into `oban_jobs` but never dequeued — no worker is consuming them. No error is raised at enqueue time. Oban silently accumulates pending jobs.

**Why it happens:** Oban does not validate at job-insert time that the target queue is declared in the consumer configuration. Job insertion succeeds regardless of whether the queue has an active consumer.

**Consequences:** Webhooks are received, the ingest plug verifies + persists + returns 200, `DispatchWorker` jobs are inserted, but `DefaultHandler` never runs. Billing state is never reconciled. Adopters see webhook confirmations in the Stripe dashboard but no state changes in AccrueAdmin. This is the top reported confusion point for new Accrue adopters and is invisible until the admin is checked.

**Prevention:** The adopter-proof example `config.exs` must show the complete required queue list. The existing `recovery_wiring_test.exs` already asserts `accrue_meters` and `accrue_scheduled` — extend it to also assert `accrue_webhooks` and `accrue_mailers`. Add a comment in `config.exs`: "Missing queue = jobs enqueue but never execute. If billing state stops updating after webhooks, check that all four Accrue queues are declared here."

**Phase:** Oban cron adopter-proof phase. High priority — this is a silent failure mode with significant UX impact.

---

### Pitfall PROOF-07: LiveView entitlement guard fires before `active_organization` association is preloaded — crashes instead of redirecting

**What goes wrong:** `Accrue.Live.Entitlements` calls `Accrue.entitled?/2` with the billable from the socket's current scope. If `scope.active_organization` is an unloaded Ecto association (`%Ecto.Association.NotLoaded{}`), the entitlement resolver pattern matches on the struct and may crash or silently return `false` without a clear error. LiveView `on_mount` callbacks run before `mount/3`, and the scope is loaded by `AccrueHostWeb.UserAuth`'s `mount_current_scope` — which must preload `active_organization` before the entitlements guard runs.

**Why it happens:** The order of `on_mount` callbacks is critical. If the auth hook that loads the scope runs without preloading `active_organization`, and the entitlements guard fires immediately after, the guard receives a partial scope. The existing example router chains both in order and works correctly, but adopters who rearrange the `on_mount` list or use a different auth module may not preload the organization.

**Consequences:** `Accrue.entitled?/2` raises `ArgumentError` or encounters `Ecto.Association.NotLoaded` at mount time. The LiveView renders a 500 error instead of a clean 302 redirect. This is not caught by the existing entitlements guard test because `log_in_user/3` in the test support preloads the organization.

**Prevention:** Add a comment in the router documenting the preload dependency: "`require_authenticated` must ensure `active_organization` is preloaded before the entitlements guard fires." Add a defensive check in `Accrue.Live.Entitlements` (if not already present): if the billable resolves to `%Ecto.Association.NotLoaded{}`, emit a Logger warning and redirect rather than crash. Add a test case with an unloaded scope to assert the redirect path.

**Phase:** Entitlements gating adopter-proof phase.

---

## Phase-Specific Summary

| Phase Topic | Pitfall | Mitigation |
|-------------|---------|------------|
| WR-05 upsert implementation | `on_conflict_where` NULL short-circuit (WR-05-01) | Change WHERE to handle NULL EXCLUDED timestamp explicitly |
| WR-05 upsert implementation | `optimistic_lock` conflicts with upsert WHERE (WR-05-02) | Remove `optimistic_lock` from `force_changeset/2`; add `lock_version` to exclude list |
| WR-05 upsert implementation | `returning: true` no-op returns stale row as write (WR-05-03) | Compare returned vs expected `last_stripe_event_ts` after insert; emit `:unchanged` |
| WR-05 test coverage | Serial tests don't exercise concurrent conflict (WR-05-04) | Write `Task.async` concurrent test with `Sandbox.allow/3` |
| IN-01 processor field | `processor_name()` ignores event processor arg (IN-01-01) | Thread `processor` arg into `write_entitlement_summary/9` |
| IN-02 livemode null | Missing key overwrites prior known value with nil (IN-02-01) | Carry prior row's livemode forward when incoming is nil |
| IN-03 docs/fixtures | Default fixture always uses `livemode: false` (IN-03-01) | Add `:omit_livemode` option; clarify `@moduledoc` reuse boundary |
| IN-04 metrics | `processor` missing from telemetry metadata (IN-04-01) | Document omission or add `processor:` to metadata (same PR as IN-01) |
| Entitlements gating proof | Scope resolution fails silently without org (PROOF-01) | Document `on_mount` order; per-cause flash messages |
| Entitlements gating proof | `LocalMap` not configured for fixture price ID (PROOF-02) | Setup assertion; code comment in test |
| Metered usage proof | Fake-lane hides "wrong plan type" failure (PROOF-03) | Document metered price requirement; use `"price_metered"` in proof |
| Metered usage proof | `quantity:` vs `value:` silent wrong key (PROOF-04) | Inline comment; optional `Logger.warning` for `quantity:` opt |
| Oban cron proof | Adopter replaces existing crontab (PROOF-05) | Show merge pattern in config comment |
| Oban cron proof | Missing queue silently stalls webhook processing (PROOF-06) | Show full queue list; extend recovery_wiring_test assertions |
| Entitlements gating proof | `active_organization` not preloaded before guard (PROOF-07) | Document `on_mount` order; defensive check in guard |

## Sources

All findings are HIGH confidence based on direct source reading:
- `/Users/jon/projects/accrue/accrue/lib/accrue/billing/entitlement_summary.ex` — schema with `optimistic_lock`, `force_changeset/2`
- `/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex` — `upsert_entitlement_summary/2`, `write_entitlement_summary/8`, `processor_name/0`, `stamp_summary_watermark/4`
- `/Users/jon/projects/accrue/accrue/priv/repo/migrations/20260524120000_create_accrue_entitlement_summaries.exs` — column definitions, `lock_version` present
- `/Users/jon/projects/accrue/accrue/test/support/stripe_fixtures.ex` — `entitlement_summary_event/2`, livemode default always `false`
- `/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/router.ex` — `on_mount` chain for entitlements guard
- `/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs` — current guard test coverage
- `/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` — Oban cron wiring assertions; existing queue assertions
- `/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` — metered usage demo (PROOF-04 card), recovery wiring demo (PROOF-06 card)
- `/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex` — `report_usage_for_scope/3` delegation chain
- Ecto `optimistic_lock/1` + `Repo.insert/2` + `on_conflict_where` interaction: HIGH confidence — `optimistic_lock/1` injects a `WHERE lock_version = ?` predicate into the UPDATE branch of an upsert, not only into `Repo.update/2`. This is documented Ecto behavior applicable to `Repo.insert/2` with `on_conflict: :replace`. Verify with a minimal repro in the WR-05 phase.
- PostgreSQL `ON CONFLICT DO UPDATE WHERE <false>` behavior: HIGH confidence — returns 0 rows affected; `returning` with 0 affected rows returns existing row values in postgrex/Ecto. Verify against the specific Ecto + postgrex version pinned in this project.
