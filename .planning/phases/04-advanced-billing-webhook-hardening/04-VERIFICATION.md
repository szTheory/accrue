---
phase: 04-advanced-billing-webhook-hardening
verified: 2026-04-14T22:05:00Z
status: passed
score: 6/6
overrides_applied: 0
re_verification:
  previous_status: none
  previous_score: n/a
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 4: Advanced Billing + Webhook Hardening — Verification Report

**Phase Goal:** Cover the long tail of subscription billing (metered usage, multi-item, comp, dunning, schedules, coupons/promotion codes, Checkout + Customer Portal) and harden the webhook pipeline (DLQ, replay tooling, multi-endpoint, out-of-order resolution, upcasters, events query API, ops telemetry).
**Verified:** 2026-04-14T22:05:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth (ROADMAP SC) | Status | Evidence |
| - | ------------------ | ------ | -------- |
| 1 | Metered subscription via `Accrue.Billing.report_usage/3`; comped/free-tier subscription created without PaymentMethod | VERIFIED | `lib/accrue/billing/meter_event_actions.ex` implements outbox (insert pending → exit txn → call Stripe → flip row) with comments asserting D2-09 (`Stripe call OUTSIDE Repo.transact/2`); `lib/accrue/billing.ex:142` `defdelegate report_usage`; `defdelegate comp_subscription` at `:81`; tests `meter_event_actions_test.exs`, `subscription_pause_resume_test.exs`, `subscription_items_test.exs` all green |
| 2 | Failed payment → `past_due → unpaid` per dunning policy; `[:accrue, :ops, :dunning_exhaustion]` emitted at terminal transition | VERIFIED | `lib/accrue/billing/dunning.ex` (pure policy `compute_terminal_action/2`), `lib/accrue/jobs/dunning_sweeper.ex` (queue `:accrue_dunning`, never touches local status), `lib/accrue/webhook/default_handler.ex` emits `:dunning_exhaustion` on `:past_due → :unpaid|:canceled` diff inside `Repo.transact`; `dunning_exhaustion_test.exs` green |
| 3 | DLQ event can be requeued individually or bulk; pruned after retention via Oban cron | VERIFIED | `lib/accrue/webhooks/dlq.ex` `requeue/1`, `requeue_where/2`, `prune/1`, `prune_succeeded/1` (dual bang/tuple); uses `Oban.insert/2` (line 108) — NOT `Oban.retry_job` per D4-04; `Webhook.Pruner` delegates; `mix accrue.webhooks.replay`/`prune` Mix tasks present; `dlq_test.exs` and `accrue_webhooks_replay_test.exs` green |
| 4 | `Accrue.Events.timeline_for/state_as_of/bucket_by` query API with upcaster chain | VERIFIED | `lib/accrue/events.ex` defines all three; `lib/accrue/events/upcaster_registry.ex` chain composition; `lib/accrue/events/upcasters/v1_to_v2.ex` sample upcaster; `query_api_test.exs`, `upcaster_registry_test.exs` green; "surface-or-die" raises `ArgumentError` + `[:accrue, :ops, :events_upcast_failed]` on unknown schema_version |
| 5 | `Accrue.Checkout.Session.create/2` + `Accrue.BillingPortal.Session` with sane portal config defenses | VERIFIED | `lib/accrue/checkout.ex` (`reconcile/1`), `lib/accrue/checkout/session.ex` (struct, hosted/embedded modes, Inspect mask on `:client_secret`), `lib/accrue/checkout/line_item.ex`, `lib/accrue/billing_portal/session.ex` with `defimpl Inspect` (line 149) masking bearer-credential URL; `guides/portal_configuration_checklist.md` documents CHKT-05 dashboard toggles; `checkout_test.exs`, `billing_portal_test.exs`, `checkout_session_completed_test.exs` green |
| 6 | Coupon / promotion code applied at sub/invoice/checkout produces correct discounted total + `coupon_applied` event | VERIFIED | `lib/accrue/billing/coupon_actions.ex` `apply_promotion_code/3` + delegates at `billing.ex:150-151`; `lib/accrue/billing/invoice.ex` `force_discount_changeset/2` denormalizes Stripe-canonical `total_discount_amounts`; webhook `default_handler.ex` reduces invoice + subscription discount fields; `coupon.applied` accrue_events row recorded; `coupon_actions_test.exs`, `promotion_code_test.exs`, `discount_denormalization_test.exs` green |

**Score:** 6/6 truths verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `accrue/mix.exs` | `lattice_stripe ~> 1.1` | VERIFIED | Line 54: `{:lattice_stripe, "~> 1.1"}` |
| `accrue/lib/accrue/config.ex` | `:dunning`, `:webhook_endpoints`, DLQ keys | VERIFIED | Lines 131, 175, 190, 210 (dead_retention_days, dunning, webhook_endpoints, dlq_replay_max_rows) plus accessor helpers |
| 6 wave-0 migrations (`20260414130000..130500`) + supplemental `130600` | meter_events, schedules, promo_codes, sub dunning/pause cols, invoice discount cols, events idx | VERIFIED | All 7 files present in `priv/repo/migrations/`; ran successfully (test suite passes against migrated schema) |
| `lib/accrue/billing/meter_event.ex` + `meter_event_actions.ex` + `meter_events.ex` + `jobs/meter_events_reconciler.ex` | BILL-13 outbox | VERIFIED | All present; reconciler queue `:accrue_meters`; outbox commit-then-call pattern enforced (line 82 comment) |
| `lib/accrue/billing/subscription_items.ex`, `subscription_schedule.ex`, `subscription_schedule_actions.ex`, `subscription_schedule_projection.ex` | BILL-11/12/14/16 | VERIFIED | All present; multi-item + schedule + comp implemented |
| `lib/accrue/billing/dunning.ex` + `lib/accrue/jobs/dunning_sweeper.ex` | BILL-15 | VERIFIED | Pure policy + Oban cron; sweeper calls Stripe and never touches local status |
| `lib/accrue/billing/coupon_actions.ex`, `promotion_code.ex`, `promotion_code_projection.ex` | BILL-27/28 | VERIFIED | All present; force_discount_changeset on invoice; subscription discount_id projection |
| `lib/accrue/webhooks/dlq.ex` + `lib/mix/tasks/accrue.webhooks.{replay,prune}.ex` + `lib/accrue/webhook/pruner.ex` | WH-08 | VERIFIED | Library + thin Mix wrappers per D4-04 ecosystem precedent |
| `lib/accrue/webhook/plug.ex` multi-endpoint mode | WH-13 | VERIFIED | Multi-endpoint dispatch by `:endpoint` opt + `:webhook_endpoints` config; `multi_endpoint_test.exs` green |
| `lib/accrue/events.ex` + `events/upcaster_registry.ex` + `events/upcasters/v1_to_v2.ex` | EVT-05/06/10 | VERIFIED | Query API + chain registry + sample upcaster |
| `lib/accrue/checkout.ex`, `checkout/session.ex`, `checkout/line_item.ex`, `billing_portal.ex`, `billing_portal/session.ex` | CHKT-01..06 | VERIFIED | Full surface; Inspect masks on bearer credentials |
| `accrue/guides/portal_configuration_checklist.md` | CHKT-05 | VERIFIED | Present |
| `lib/accrue/telemetry/ops.ex`, `lib/accrue/telemetry/metrics.ex`, `guides/telemetry.md` | OBS-03/04/05 | VERIFIED | All present; namespace prefix hardcoded to `[:accrue, :ops]` |

### Key Link Verification

| From | To | Via | Status |
| ---- | -- | --- | ------ |
| `meter_event_actions.ex` | `Accrue.Processor.report_meter_event` | OUTSIDE `Repo.transact/2` (D2-09 hard constraint) | WIRED — line 82 comment + verified order |
| `webhooks/dlq.ex` | `Accrue.Webhook.DispatchWorker` | `Oban.insert/2` (line 108) — never `Oban.retry_job` | WIRED — confirmed pattern matches D4-04 |
| `default_handler.ex` | `[:accrue, :ops, :dunning_exhaustion]` telemetry | status-diff inside Repo.transact for replay idempotency | WIRED — grep matched in default_handler.ex |
| `webhook/plug.ex` | `Accrue.Config.fetch!(:webhook_endpoints)` | endpoint lookup by `:endpoint` opt | WIRED — multi_endpoint_test.exs green |
| `billing_portal/session.ex` | `defimpl Inspect` mask of `:url` | bearer-credential mask | WIRED — line 149 |
| `telemetry/ops.ex` | `:telemetry.execute/3` with `[:accrue, :ops] ++ suffix` | hardcoded prefix (defense in depth) | WIRED — line 55 |
| `billing.ex` facade | per-domain action modules | `defdelegate` for `report_usage`, `comp_subscription`, `add_item`, `apply_promotion_code` | WIRED — lines 81–151 |

### Requirements Coverage

All 21 declared phase-4 requirement IDs verified against implementation. REQUIREMENTS.md marks each as `[x]` and lists all as `Phase 4 | Complete` in the coverage matrix.

| Requirement | Plan | Status | Evidence |
| ----------- | ---- | ------ | -------- |
| BILL-11 (pause_behavior) | 04-03 | SATISFIED | `subscription_actions.ex` extended pause/2 with `:pause_behavior` option; `pause_behavior` column on `accrue_subscriptions` |
| BILL-12 (multi-item) | 04-03 | SATISFIED | `subscription_items.ex` `add_item/remove_item/update_item_quantity` |
| BILL-13 (metered) | 04-02 | SATISFIED | `report_usage/3` outbox + reconciler + Fake/Stripe processors + error webhook |
| BILL-14 (comp) | 04-03 | SATISFIED | `comp_subscription/3` defdelegate at `billing.ex:81` |
| BILL-15 (dunning) | 04-04 | SATISFIED | Pure `Dunning` policy + `DunningSweeper` cron + webhook telemetry diff |
| BILL-16 (schedules) | 04-03 | SATISFIED | `SubscriptionSchedule` schema + projection + actions + webhook reducers |
| BILL-27 (coupon/promo) | 04-05 | SATISFIED | `Coupon`, `PromotionCode`, `coupon_actions.ex` |
| BILL-28 (discount projection) | 04-05 | SATISFIED | `force_discount_changeset/2` + `total_discount_amounts` denormalization |
| CHKT-01..06 | 04-07 | SATISFIED | `Checkout.Session` (hosted/embedded), `LineItem`, `BillingPortal.Session`, `reconcile/1`, install-guide checklist |
| WH-08 (DLQ replay) | 04-06 | SATISFIED | `Accrue.Webhooks.DLQ` + Mix tasks + `Pruner` |
| WH-13 (multi-endpoint) | 04-06 | SATISFIED | Plug `:endpoint` opt + `:webhook_endpoints` config |
| EVT-05 (upcasters) | 04-06 | SATISFIED | `UpcasterRegistry.chain/3` + V1ToV2 sample + surface-or-die |
| EVT-06 (timeline/state_as_of) | 04-06 | SATISFIED | `Accrue.Events.timeline_for/3`, `state_as_of/3` |
| EVT-10 (bucket_by) | 04-06 | SATISFIED | `bucket_by/2` with literal `date_trunc` fragments per atom |
| OBS-03 (ops namespace) | 04-08 | SATISFIED | `Accrue.Telemetry.Ops.emit/3` with hardcoded `[:accrue, :ops]` prefix |
| OBS-04 (span naming guide) | 04-08 | SATISFIED | `guides/telemetry.md` |
| OBS-05 (default metrics recipe) | 04-08 | SATISFIED | `Accrue.Telemetry.Metrics.defaults/0`, conditional compile on `:telemetry_metrics` |

No orphaned requirements found.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
| ---- | ------- | -------- | ------ |
| (none) | TODO/FIXME/placeholder grep on `lib/accrue` returned no matches | — | Clean |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Full test suite passes | `cd accrue && mix test` | `36 properties, 555 tests, 0 failures (2 excluded)` | PASS |
| Phase-4 source modules compile clean | (transitive via test run, `--warnings-as-errors` is project default) | Tests passed | PASS |
| `lattice_stripe ~> 1.1` resolves | mix.exs grep | `{:lattice_stripe, "~> 1.1"}` | PASS |
| Migrations applied | (test suite ran against migrated schema with no failures) | Implicit PASS | PASS |
| `Oban.insert` (not `Oban.retry_job`) used in DLQ requeue | grep on `webhooks/dlq.ex` | `Oban.insert(` at line 108; no `Oban.retry_job` | PASS |
| Stripe call outside `Repo.transact` in metered path | grep + comment on `meter_event_actions.ex:82` | `Stripe call OUTSIDE Repo.transact/2 — D2-09 / D4-03` | PASS |

### Human Verification Required

None. Phase 4 is headless library code — no UI, no email rendering, no real-time behavior. All success criteria are programmatically verifiable through the test suite plus structural grep checks. Real Stripe integration (live test mode) is out of scope per the Fake-processor-as-source-of-truth strategy locked in Phase 1.

### Gaps Summary

No gaps found. All 6 ROADMAP success criteria are met by code that exists, is wired through the `Accrue.Billing` / `Accrue.Webhooks.DLQ` / `Accrue.Events` / `Accrue.Checkout` / `Accrue.BillingPortal` / `Accrue.Telemetry.Ops` public surfaces, and is exercised by a green test suite (555 tests + 36 properties, 0 failures). All 21 declared requirements (BILL-11/12/13/14/15/16/27/28, CHKT-01..06, WH-08, WH-13, EVT-05/06/10, OBS-03/04/05) are SATISFIED. The D4-01 lattice_stripe 1.1 bump landed cleanly; the D4-02 hybrid dunning shape matches the plan; the D4-03 metered outbox preserves the D2-09 transactional invariant; the D4-04 DLQ library + Mix wrapper pattern is implemented per Ecto/Oban ecosystem precedent.

Phase 4 goal achieved. Ready to proceed to Phase 5 (Connect).

---

*Verified: 2026-04-14T22:05:00Z*
*Verifier: Claude (gsd-verifier)*
