---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Completed 05-05-PLAN.md
last_updated: "2026-04-15T04:36:00.147Z"
last_activity: 2026-04-15
progress:
  total_phases: 9
  completed_phases: 4
  total_plans: 35
  completed_plans: 33
  percent: 94
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-11)

**Core value:** A Phoenix developer can install Accrue + accrue_admin and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit and zero breaking-change pain through v1.x.
**Current focus:** Phase 05 — connect

## Current Position

Phase: 05 (connect) — EXECUTING
Plan: 6 of 7
Status: Ready to execute
Last activity: 2026-04-15

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**

- Total plans completed: 6
- Average duration: N/A
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 6 | - | - |

**Recent Trend:**

- Last 5 plans: none
- Trend: N/A

*Updated after each plan completion*
| Phase 03-core-subscription-lifecycle P01 | 9m | 4 tasks | 18 files |
| Phase 03 P02 | 10m | 3 tasks | 18 files |
| Phase 03 P03 | 25m | 3 tasks | 7 files |
| Phase 03-core-subscription-lifecycle P04 | 35m | 3 tasks | 12 files |
| Phase 03 P05 | 12m | 2 tasks | 5 files |
| Phase 03 P06 | 25m | 3 tasks | 10 files |
| Phase 03-core-subscription-lifecycle P07 | 12m | 3 tasks | 12 files |
| Phase 03 P08 | 15m | 3 tasks | 16 files |
| Phase 04 P01 | 22m | 3 tasks | 10 files |
| Phase 04-advanced-billing-webhook-hardening P02 | 25m | 3 tasks | 15 files |
| Phase 04 P03 | 30m | 2 tasks | 16 files |
| Phase 04-advanced-billing-webhook-hardening P04 | 35m | 3 tasks | 8 files |
| Phase 04-advanced-billing-webhook-hardening P05 | 30m | 2 tasks | 16 files |
| Phase 04-advanced-billing-webhook-hardening P06 | 30m | 2 tasks | 13 files |
| Phase 04-advanced-billing-webhook-hardening P07 | 8m | 2 tasks | 15 files |
| Phase 04-advanced-billing-webhook-hardening P08 | 4m | 2 tasks | 6 files |
| Phase 05-connect P01 | 10m | 2 tasks | 13 files |
| Phase 05-connect P02 | 18m | 2 tasks | 12 files |
| Phase 05 P03 | 9min | 2 tasks | 7 files |
| Phase 05-connect P04 | 10min | 1 tasks | 4 files |
| Phase 05-connect P05 | 20min | 1 tasks | 6 files |

## Accumulated Context

### Decisions

Full decision log lives in PROJECT.md Key Decisions table. Recent decisions affecting current work:

- [Roadmap]: 9-phase topological structure; topological execution 1→9
- [Roadmap]: Fake Processor is primary test surface from Phase 1, not a test-layer afterthought
- [Roadmap]: Money value type lands in Phase 1 so no schema is built with bare-integer amounts
- [Roadmap]: Gift cards (BILL-086, MAIL-gift) deferred to v2, not in v1 scope
- [Roadmap]: DLQ retention default 90 days (WH-11); installer idempotent from day one (INST-07)
- [Phase 03-core-subscription-lifecycle]: defdelegate is compile-checked in modern Elixir — action modules need declarative stubs, not empty bodies
- [Phase 03-core-subscription-lifecycle]: NoRawStatusAccess Credo check scoped to Subscription-shaped code (stripe status atoms) to avoid false positives on WebhookEvent.status
- [Phase 03]: Invoice.changeset/2 @required_fields is empty — state-machine changeset operates on bare structs; processor enforcement lives at Customer level
- [Phase 03]: Accrue.Billing.Query exempt from NoRawStatusAccess: canonical query wrapper, same role as Subscription module for predicates
- [Phase 03]: Invoice rollup columns use bigint not integer: annual enterprise totals and multi-year Subscription Schedule previews can exceed 2^31
- [Phase 03]: advance/2 vs advance_subscription/2 split preserves Phase 1 clock-only API while adding subscription-aware trial crossing
- [Phase 03]: Fake new resources use atom-keyed Stripe-shape maps consistent with Phase 1 + LatticeStripe struct translation pattern
- [Phase 03]: create_charge routes through PaymentIntent.create because lattice_stripe 1.0 removes direct Charge.create per Stripe 2026-03-25.dahlia
- [Phase 03-core-subscription-lifecycle]: NimbleOptions nil defaults require {:or, [:type, nil]} union — bare :string/:pos_integer types fail validate with default: nil
- [Phase 03-core-subscription-lifecycle]: Accrue.Billing.subscribe/3 accepts both billable struct AND %Customer{} directly — tests need manual customer seeding; host-app callers use lazy fetch
- [Phase 03-core-subscription-lifecycle]: Fake gains build_subscription_item/apply_subscription_update/merge_item helpers so flat item patches round-trip through Stripe-shape items.data nesting
- [Phase 03]: InvoiceProjection emits :processor_id (not :stripe_id) for parent invoice; only InvoiceItem uses :stripe_id (D3-15)
- [Phase 03]: InvoiceProjection delegates field lookup to SubscriptionProjection.get/2 for dual-key (atom/string) support — no duplication
- [Phase 03]: run_action/4 is the single D3-18 workflow shape for all 5 invoice actions; only pay_invoice wraps via IntentResult
- [Phase 03]: charge/3 calls Processor.create_charge OUTSIDE Repo.transact so SCA 3DS responses never persist a half-baked Charge row — IntentResult.wrap branches before any DB insert
- [Phase 03]: Fingerprint dedup uses application-level SELECT then rescue Ecto.ConstraintError for concurrent race via partial unique index backstop
- [Phase 03]: set_default_payment_method asserts pm.customer_id==customer.id BEFORE any processor call; raises Accrue.Error.NotAttached — not a tuple return
- [Phase 03]: create_refund returns uniform {:ok, %Refund{}} — fee settlement state is a property (fees_settled?) not a tagged-return branch (D3-47)
- [Phase 03]: Accrue.Repo facade gains get/get_by/get_by!/delete/aggregate delegations for Plan 06 — D-10 host-owns-Repo preserved as pure pass-throughs
- [Phase 03]: DefaultHandler uses Processor.__impl__().fetch(type, id) not a facade Processor.fetch/2 — facade has only @callback
- [Phase 03]: Webhook reducer load_row/2 dispatches per type — subscription/invoice/charge/PM use processor_id, refund uses stripe_id
- [Phase 03]: DefaultHandler ships dual entry points: handle/1 (raw map for Fake.synthesize_event) + handle_event/3 (Dispatch worker) sharing one dispatch/4
- [Phase 03]: DetectExpiringCards dedup via events table fragment (?->>'threshold')::int — no new dedup column on payment_methods
- [Phase 03]: LiveView on_mount hook for operation_id deferred to accrue_admin — LiveView is hard dep only there
- [Phase 03-core-subscription-lifecycle]: Plan 08 factories insert Customer rows directly via changeset (not Billing.create_customer which takes a billable struct), matching existing Phase 04/05/06 test setup pattern
- [Phase 03-core-subscription-lifecycle]: Plan 08 stub event schemas emit via top-level for-loop in schemas.ex file; Code.ensure_loaded!/1 required in tests before function_exported? check
- [Phase 04]: Phase 4 migration timestamps shifted 120xxx→130xxx due to Phase 3 collision
- [Phase 04]: discount_minor column already existed from Phase 3 — Phase 4 adds only total_discount_amounts
- [Phase 04]: Config @schema doc strings must avoid 'LatticeStripe' substring — facade lockdown test scans all lib/ files
- [Phase 04]: Phase 04 P02: report_usage/3 pre-checks identifier outside Repo.transact to avoid in_failed_sql_transaction on unique index trip
- [Phase 04]: Phase 04 P02: meter webhook reducer lives inline in DefaultHandler (matches Phase 3 shape, no webhook/handlers/ subdir)
- [Phase 04]: Phase 04 P03: pause/2 accepts both legacy :behavior atom and new :pause_behavior string; string takes precedence and goes through allowlist validation
- [Phase 04]: Phase 04 P03: comp_subscription/3 delegates to subscribe/3 via new :coupon/:collection_method/:skip_payment_method_check forwarded options rather than duplicating the subscribe path
- [Phase 04]: Phase 04 P03: SubscriptionSchedule webhook reducer uses dedicated subscription_schedule_fetch callback with fetch/2 dispatch clause for reducer ergonomics; out-of-order tolerance via :deferred orphan pattern matching Phase 3 shapes
- [Phase 04-advanced-billing-webhook-hardening]: BILL-15 dunning ships as D4-02 hybrid: pure Dunning policy module + DunningSweeper Oban cron + webhook dunning_exhaustion telemetry. Sweeper calls Stripe only — never flips local status (D2-29). New Subscription predicates dunning_sweepable?/1 and dunning_exhausted_status/1 keep BILL-05 compliance.
- [Phase 04-advanced-billing-webhook-hardening]: Phase 04 P05: close Phase 3 D3-16 accrue_coupons schema/DB drift via migration 20260414130600 (amount_off_minor + redeem_by columns declared on schema but never migrated)
- [Phase 04-advanced-billing-webhook-hardening]: Phase 04 P05: total_discount_amounts stored wrapped as %{data: [...]} because Ecto :map rejects top-level arrays at the jsonb boundary
- [Phase 04-advanced-billing-webhook-hardening]: Phase 04 P05: apply_promotion_code/3 validates :active, :expires_at, :max_redemptions OUTSIDE Repo.transact so crafted/expired inputs never touch Stripe (T-04-05-02)
- [Phase 04-advanced-billing-webhook-hardening]: Phase 04 P05: coupon persistence uses SELECT+insert/update instead of on_conflict: :replace_all_except so the Phase 3 schema/DB drift could not resurface
- [Phase 04-advanced-billing-webhook-hardening]: Phase 04 P06: DLQ uses plain error atoms (no Accrue.Error umbrella struct exists in codebase)
- [Phase 04-advanced-billing-webhook-hardening]: Phase 04 P06: bucket_by/2 uses literal date_trunc strings per :day/:week/:month — parameterized fragments break Postgres GROUP BY equivalence detection
- [Phase 04-advanced-billing-webhook-hardening]: Phase 04 P06: Webhook plug multi-endpoint mode is opt-in via :endpoint init opt — preserves Phase 2 :processor-only callers untouched
- [Phase 04-advanced-billing-webhook-hardening]: Phase 04 P06: Sandbox txn forces Postgres now() to be identical for all rows — query API tests use Ecto.Changeset.change with explicit inserted_at instead of record/1
- [Phase 04-advanced-billing-webhook-hardening]: Phase 04 P07: No local accrue_checkout_sessions/billing_portal_sessions tables — both objects are short-lived bearer credentials; subscription state mirrors via existing customer.subscription.* projection path
- [Phase 04-advanced-billing-webhook-hardening]: Phase 04 P07: Inspect masks use field-allowlist concat (not Inspect.Map.inspect) because algebra rejects nested struct docs in concat/2; mirrors LatticeStripe upstream shape
- [Phase 04-advanced-billing-webhook-hardening]: Phase 04 P07: BillingPortal.Configuration deferred to processor 1.2 — install-time Dashboard checklist (guides/portal_configuration_checklist.md) is canonical; :configuration option already accepts bpc_* for additive future support
- [Phase 04-advanced-billing-webhook-hardening]: Phase 04 P08: Ops emit helper uses Accrue.Actor.current_operation_id/0 (Accrue.Context module does not exist; Actor is canonical pdict facade per D2-12)
- [Phase 04-advanced-billing-webhook-hardening]: Phase 04 P08: Telemetry.Metrics conditional-compile sentinel raises clear install message instead of returning [] — silent empty default would mask missing optional dep
- [Phase 05-connect]: Phase 05 P01: Endpoint name collapse — only :connect persists as :connect; :primary/:unconfigured/nil/custom collapse to :default so schema enum stays minimal
- [Phase 05-connect]: Phase 05 P01: Connect @callback clauses declared @optional_callbacks — Plans 05-02/05-03 add adapter bodies then remove the optional declaration
- [Phase 05-connect]: Phase 05 P01: resolve_stripe_account/1 reads Process.get(:accrue_connected_account_id) directly to avoid compile-time circular dep on Accrue.Connect (lands in Plan 05-02)
- [Phase 05-connect]: Phase 05 P01: Accrue.Config.connect/0 helper added mirroring dunning/0 — resolver uses Keyword.get not nested get/1 because Config module lacks nested lookup
- [Phase 05-connect]: Phase 05 P02: owner_id column as :string (not :binary_id) to match accrue_customers polymorphic-owner precedent (D2-01/02)
- [Phase 05-connect]: Phase 05 P02: Fake scope keyspace via per-resource _accrue_scope stamp, not state-shape refactor — back-compat automatic for Phase 1-4 tests
- [Phase 05-connect]: Phase 05 P02: Caller-side pdict→opts threading pattern for Fake — GenServer runs on separate process, client-side API must read pdict and thread into opts before GenServer.call
- [Phase 05-connect]: Phase 05 P02: delete_account/2 soft-deletes via force_status_changeset deauthorized_at (D5-05 audit trail)
- [Phase 05]: Phase 05 P03: build_platform_client!/1 dedicated helper instead of force_platform(opts) sentinel — resolve_stripe_account/1's || chain treats explicit nil as fall-through, silently inheriting with_account/2 scope onto platform-scoped endpoints.
- [Phase 05]: Phase 05 P03: Express-only guard at Accrue.Connect.create_login_link/2 facade layer, not adapter — returns typed %Accrue.APIError{code: "invalid_request_error"} before any Stripe round-trip, avoiding leak of account type via Stripe 400 payload (T-05-03-02).
- [Phase 05-connect]: Phase 05 P04: Use %Accrue.ConfigError{} for platform_fee validation errors (no Accrue.Error umbrella exists). All percent math in minor-unit integers via Decimal.mult→div 100→round :half_even→to_integer — currency-exponent-agnostic because minor units are integer across all currencies. Final max(result, 0) belt-and-suspenders clamp protects against pathological negative :fixed.
- [Phase 05-connect]: Phase 05 P05: Explicit stripe_account: nil opt as Fake-side platform sentinel — Keyword.has_key?/2 short-circuit in resolve_scope/1 beats the || fall-through that would otherwise leak pdict onto platform-authority calls
- [Phase 05-connect]: Phase 05 P05: separate_charge_and_transfer/2 returns {:error, {:transfer_failed, charge, err}} reconciliation tuple on partial failure (D5-05 events-ledger principle; charge persists, caller reconciles)

### Pending Todos

None yet.

### Blockers/Concerns

- **Release Please v4 monorepo output naming:** verify via dry-run before Phase 9 release work.
- **ChromicPDF on minimal Alpine containers:** needs real-world container testing in Phase 6; PDF.Null adapter is the escape hatch.
- **lattice_stripe 1.1 (BillingMeter/MeterEvent/BillingPortal.Session):** Required for Phase 4 requirements BILL-11 (metered billing) and CHKT-02 (Customer Portal). Upstream work is in-flight in a parallel session targeting 1.1 release. Does NOT block Phase 3 or the rest of Phase 4.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260413-jri | Bump lattice_stripe to ~> 1.0 and unblock Phase 3 | 2026-04-13 | 52bec8e | [260413-jri-bump-lattice-stripe-to-1-0-and-unblock-p](./quick/260413-jri-bump-lattice-stripe-to-1-0-and-unblock-p/) |
| 260414-l9q | Automate Phase 3 human verification items | 2026-04-14 | 560ef2e | [260414-l9q-automate-phase-3-human-verification-item](./quick/260414-l9q-automate-phase-3-human-verification-item/) |

## Session Continuity

Last session: 2026-04-15T04:36:00.143Z
Stopped at: Completed 05-05-PLAN.md
Resume file: None
