---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Completed 07-09-PLAN.md
last_updated: "2026-04-15T17:39:53.582Z"
last_activity: 2026-04-15
progress:
  total_phases: 9
  completed_phases: 6
  total_plans: 54
  completed_plans: 47
  percent: 87
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-11)

**Core value:** A Phoenix developer can install Accrue + accrue_admin and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit and zero breaking-change pain through v1.x.
**Current focus:** Phase 07 — admin-ui-accrue-admin

## Current Position

Phase: 07 (admin-ui-accrue-admin) — EXECUTING
Plan: 6 of 12
Status: Ready to execute
Last activity: 2026-04-15

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**

- Total plans completed: 13
- Average duration: N/A
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 6 | - | - |
| 06 | 7 | - | - |

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
| Phase 05 P06 | 15min | 1 tasks | 3 files |
| Phase 05-connect P07 | 45min | 1 tasks | 6 files |
| Phase 06-email-pdf P01 | 6min | 3 tasks | 9 files |
| Phase 06-email-pdf P02 | 10min | 3 tasks | 10 files |
| Phase 06-email-pdf P03 | 10min | 3 tasks | 15 files |
| Phase 06-email-pdf P04 | 10m | 3 tasks | 11 files |
| Phase 06-email-pdf P05 | 8m | 3 tasks | 33 files |
| Phase 06-email-pdf P06 | ~8m | 3 tasks | 26 files |
| Phase 06-email-pdf P07 | 30m | 3 tasks | 15 files |
| Phase 07-admin-ui-accrue-admin P01 | 8m | 2 tasks | 21 files |
| Phase 07-admin-ui-accrue-admin P02 | 8m | 1 tasks | 21 files |
| Phase 07 P03 | 9m | 1 tasks | 16 files |
| Phase 07-admin-ui-accrue-admin P04 | 9m | 2 tasks | 17 files |
| Phase 07 P09 | 9m | 2 tasks | 12 files |

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
- [Phase 05]: Plan 06: Refetch-canonical (Connect.retrieve_account/2) as Pitfall 3 mitigation — no watermark column added
- [Phase 05]: Plan 06: Payload beyond event.object_id loaded from persisted accrue_webhook_events.data via ctx.webhook_event_id
- [Phase 05-connect]: Plan 07: Pitfall 5 boot warning is Logger.warning (non-fatal) — dev/test fixtures legitimately reuse webhook secrets
- [Phase 05-connect]: Plan 07: live_stripe suite guards against sk_live_ keys via setup_all prefix check (T-05-07-03 spoofing mitigation)
- [Phase 06-email-pdf]: Phase 06 P01: Nested :branding schema uses NimbleOptions keys: sub-schema with required: true on inner :from_email/:support_email — outer default: [] still validates because NimbleOptions enforces nested required when outer default materializes
- [Phase 06-email-pdf]: Phase 06 P01: branding/0 reads raw env + merges schema defaults via merge_with_defaults/1; validate_at_boot!/0 still runs full NimbleOptions validation at supervisor start
- [Phase 06-email-pdf]: Phase 06 P01: warn_deprecated_branding/0 uses :persistent_term dedupe (one warn per BEAM boot); log message contains key NAMES only, never flat-key values (T-06-01-02 mitigation)
- [Phase 06-email-pdf]: Phase 06 P01: preferred_locale/preferred_timezone columns are raw string(35)/string(64); no validate_inclusion — library cannot know host CLDR compile-time set (D6-03)
- [Phase 06-email-pdf]: Phase 6 P02: Accrue.Error.PdfDisabled co-located in errors.ex per taxonomy precedent; no new lib/accrue/error/ directory
- [Phase 06-email-pdf]: Phase 6 P02: PdfDisabled docs_url constant is byte-identical to {#null-adapter} anchor in guides/pdf.md — single source of truth, grep-guardable in CI
- [Phase 06-email-pdf]: Phase 6 P02: :storage_adapter registered in Accrue.Config NimbleOptions schema alongside :pdf_adapter/:auth_adapter with default Accrue.Storage.Null
- [Phase 06-email-pdf]: Phase 6 P02: Storage telemetry metadata is {adapter, key, bytes} where bytes is byte_size/1 scalar — raw binary never enters span metadata (T-06-02-02)
- [Phase 06-email-pdf]: Phase 6 P03: phoenix_live_view ~> 1.1 added as non-optional runtime dep — Phoenix.Component + ~H sigil live in lib/accrue/invoices/components.ex and layouts.ex, so compile-time availability is mandatory; spike confirms no LiveView socket/mount machinery runs at library call time
- [Phase 06-email-pdf]: Phase 6 P03: HtmlBridge canonical call path is component |> apply([assigns]) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary() — verified via 5-test spike; Research [ASSUMED A1/A9] now VERIFIED
- [Phase 06-email-pdf]: Phase 6 P03: format_money/3 never raises — try/rescue → locale_fallback telemetry → en retry → format_money_failed telemetry → raw fallback binary; StreamData property covers 180 iterations across currency × locale matrix without failure
- [Phase 06-email-pdf]: Phase 6 P03: RenderContext.branding is frozen exactly once in Render.build_assigns/2 — Pitfall 8 enforced by single Accrue.Config.branding() call site in render.ex, proven by put_env mutation regression test
- [Phase 06-email-pdf]: Phase 6 P03: Layouts.print_shell ships print-safe CSS (body margin 0 + page-break-inside avoid) but NO CSS paper-size rules — ChromicPDF adapter options carry paper size (Pitfall 6); prefer_css_page_size must stay disabled in Plan 06-06
- [Phase 06-email-pdf]: Phase 6 P03: Shared transactional.{mjml,text}.eex layouts ship as REFERENCE scaffolds (mjml_eex has no HEEx slot equivalent) — per-type email templates COPY the scaffold; BODY BLOCK markers are intentional extension points, not stubs
- [Phase 06-email-pdf]: Accrue.Mailer.Test sidesteps Oban entirely — async-safe intent-tuple adapter (D6-05)
- [Phase 06-email-pdf]: MFA override rung forwards [type | args] so one chooser can handle many types
- [Phase 06-email-pdf]: enrich/2 Customer hydration is best-effort (try/rescue/catch → nil) — Pitfall 5 no-raise trumps fail-loud
- [Phase 06-email-pdf]: Phase 6 P05: 8 non-invoice email modules are ~40 LOC each (half the ~80 LOC target) because per-type prose lives in templates; modules are pure subject/1 + render_text/1 boilerplate
- [Phase 06-email-pdf]: Phase 6 P05: MAIL-15 multipart coverage guard uses public Accrue.Workers.Mailer.resolve_template/1 fall-through — no need to promote private default_template/1
- [Phase 06-email-pdf]: Phase 6 P05: Accrue.Emails.Receipt (MAIL-03 canonical) coexists with legacy Accrue.Emails.PaymentSucceeded — both registered in dispatch table, downstream dispatches by atom
- [Phase 06-email-pdf]: Phase 6 P06: Accrue.Invoices lazy-render PDF facade — Process.whereis(ChromicPDF) safety net surfaces missing supervisor child as {:error, :chromic_pdf_not_started} before touching Render.build_assigns (Pitfall 4); safe_build_assigns wraps rescue for Ecto.NoResultsError + other exceptions as T-06-06-08 mitigation
- [Phase 06-email-pdf]: Phase 6 P06: RefundIssued + CouponApplied skip shared invoice components (invoice_header/line_items/totals) deliberately — refunds and coupons are distinct flows; embedding would force misleading invoice-shaped render. Only invoice_finalized + invoice_paid embed the full component stack
- [Phase 06-email-pdf]: Phase 6 P06: InvoicePaymentFailed CTA routes to ctx.invoice.hosted_invoice_url (Stripe-hosted pay page) not host-supplied update_pm_url — MAIL-09 requires a payable surface, not a payment-method edit surface
- [Phase 06-email-pdf]: Phase 6 P06: Accrue.Emails.Fixtures lives in lib/ (not test/support/) with static 'April 15, 2026' formatted_issued_at — zero DateTime.utc_now or Repo calls, deterministic output enforceable by test
- [Phase 06-email-pdf]: Webhook reducers dispatch mailer AFTER Repo.transact returns — rollbacks never leak ghost emails
- [Phase 06-email-pdf]: mix accrue.mail.preview uses Mix.Task.run(loadpaths) not app.start — fixtures are pure data, no repo needed
- [Phase 07]: Phase 07 P01 mounts accrue_admin through a package-owned router macro with hash-addressed asset routes and explicit session-key forwarding.
- [Phase 07]: Phase 07 P01 ships a placeholder LiveView/root layout so later admin plans inherit a real live_session boundary instead of scaffolding their own.
- [Phase 07]: Accrue custom Credo checks compile only in dev/test paths so sibling packages can depend on :accrue without Credo at runtime.
- [Phase 07-admin-ui-accrue-admin]: Brand values continue to flow from Accrue.Config.branding/0; the admin package only derives display-safe app name, logo URL, and accent contrast.
- [Phase 07-admin-ui-accrue-admin]: The shell ships as semantic CSS plus a private Tailwind preset/config pair so later admin components can reuse tokens without depending on host tooling.
- [Phase 07-admin-ui-accrue-admin]: Theme persistence lives in the accrue_theme cookie with system as the only fallback for invalid client input in both Plug and browser paths.
- [Phase 07]: Admin list queries return explicit row maps instead of whole schemas so metadata/data blobs do not bleed into list rendering by default.
- [Phase 07]: The admin package now boots its own sandboxed test repo against accrue migrations so list-query behavior is verified against real schema and index state.
- [Phase 07]: Cursor tampering fails closed to first-page semantics via HMAC-signed opaque tokens, preserving cursor pagination without offset fallback.
- [Phase 07-admin-ui-accrue-admin]: Step-up verification delegates to optional Accrue.Auth callbacks, with dev/test auto-approval and prod fail-closed behavior preserved in Accrue.Auth.Default.
- [Phase 07-admin-ui-accrue-admin]: Step-up audit rows use a separate admin.step_up.* stream on Accrue.Events so verification outcomes are durable without polluting domain event types.
- [Phase 07-admin-ui-accrue-admin]: Causal linkage uses both caused_by_event_id and caused_by_webhook_event_id so admin actions and webhook-derived follow-ons stay first-class without overloading one column.
- [Phase 07]: Shared admin controls stay as pure function components with explicit attrs and escaped text rendering rather than host-coupled helpers.
- [Phase 07]: Status badges map fixed billing states onto the locked Moss, Cobalt, Amber, Slate, and Ink semantics instead of caller-defined colors.
- [Phase 07]: Dropdown menus use native disclosure plus text labels so later pages inherit accessible actions without icon-only affordances.

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

Last session: 2026-04-15T17:39:53.579Z
Stopped at: Completed 07-09-PLAN.md
Resume file: None
