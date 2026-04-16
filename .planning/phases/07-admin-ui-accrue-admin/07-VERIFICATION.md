---
phase: 07-admin-ui-accrue-admin
verified: 2026-04-15T19:31:05Z
status: human_needed
score: 5/6 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "Phase 7 admin surfaces remain regression-safe under the phase's own focused verification suite"
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "When `sigra` is present, the admin UI auto-wires Sigra as the auth adapter with no manual config"
    addressed_in: "Phase 8"
    evidence: "Phase 8 goal includes 'Sigra wiring (if present)', and REQUIREMENTS.md maps AUTH-04 and INST-06 to Phase 8 rather than Phase 7."
human_verification:
  - test: "Mobile dashboard and light/dark visual UAT"
    expected: "At a phone viewport, `/billing` remains usable without horizontal overflow, KPI cards and navigation are readable, and light/dark/system theme switching preserves contrast with the Accrue brand palette."
    why_human: "Responsive layout quality, real contrast perception, and theme feel require browser/device inspection beyond static code and LiveView tests."
  - test: "Operator replay/refund flow UAT"
    expected: "A human operator can inspect a failed webhook, use one-click replay and bulk DLQ requeue intentionally, and initiate a refund through the step-up prompt with clear success/error feedback."
    why_human: "The automated tests verify wiring and persistence, but confirmation clarity and end-to-end operator affordance quality are UX judgments."
---

# Phase 7: Admin UI (accrue_admin) Verification Report

**Phase Goal:** The `accrue_admin` companion package ships a mobile-first, light/dark-mode Phoenix LiveView dashboard covering customers, subscriptions, invoices, charges, refunds, coupons, Connect accounts, and a webhook event inspector with one-click replay and DLQ bulk requeue — auth-protected via the `Accrue.Auth` adapter with first-party Sigra auto-detection.
**Verified:** 2026-04-15T19:31:05Z
**Status:** human_needed
**Re-verification:** Yes — after focused admin suite stabilization fix

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A developer can mount `accrue_admin "/billing"`, reach a responsive dashboard, and get themed KPI surfaces without host asset/layout wiring. | ✓ VERIFIED | `accrue_admin/lib/accrue_admin/router.ex` mounts package routes/assets; `layouts.ex` and `components/app_shell.ex` provide theme + shell; `live/dashboard_live.ex` reads KPIs from `Customer`, `Subscription`, `Invoice`, `WebhookEvent`, and `Event`; focused Phase 7 suite now passes as a whole. |
| 2 | Customer detail exposes tabbed subscriptions/invoices/charges/payment methods/events/metadata, with the events tab backed by `accrue_events`. | ✓ VERIFIED | `accrue_admin/lib/accrue_admin/live/customer_live.ex` renders the required tabs and calls `Events.timeline_for("Customer", customer.id, limit: 25)` for the events tab. |
| 3 | Failed webhook rows can be inspected, replayed individually, and bulk requeued from the filtered DLQ slice. | ✓ VERIFIED | `live/webhook_live.ex` calls `DLQ.requeue/1`; `live/webhooks_live.ex` calls `DLQ.requeue_where/1`; webhook inspector/replay tests pass in the aggregate suite. |
| 4 | Refunds initiated from the admin UI require step-up auth, write admin audit events with causal linkage, and show fee-aware refund outcomes. | ✓ VERIFIED | `live/charge_live.ex` routes refunds through `StepUp.require_fresh/4`, `Billing.create_refund/2`, and `Events.record/1`; core causality coverage passes separately in the `accrue` package. |
| 5 | When `sigra` is present, the admin UI auto-wires Sigra as the auth adapter with no manual config, while still enforcing auth via `on_mount` and bridging audit logs to Sigra. | ⚠ DEFERRED | `accrue/lib/accrue/integrations/sigra.ex` provides the first-party adapter and `auth_hook.ex` enforces `on_mount`, but no Phase 7 no-manual-config auto-selection path exists. Deferred to Phase 8 AUTH-04 / INST-06. |
| 6 | Dev-only tooling is compile-gated out of prod and only exposed in dev/test with Fake processor runtime checks. | ✓ VERIFIED | `router.ex`, `components/dev_toolbar.ex`, and `dev/*.ex` gate definitions behind `Mix.env() != :prod`; dev-route, preview, component kitchen, asset task tests pass; `MIX_ENV=prod mix compile` exits 0. |

**Score:** 5/6 truths verified; the unverified Sigra auto-wiring truth is explicitly deferred to Phase 8.

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Sigra auto-wiring with no manual `:auth_adapter` config | Phase 8 | Phase 8 goal includes “Sigra wiring (if present)”; REQUIREMENTS.md maps `AUTH-04` and `INST-06` to Phase 8. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | ----------- | ------ | ------- |
| `accrue_admin/lib/accrue_admin/router.ex` | mount macro, asset routes, live session, page routes, dev gating | ✓ VERIFIED | Defines `defmacro accrue_admin`, package assets, `live_session`, page routes, and compile-gated dev routes. |
| `accrue_admin/lib/accrue_admin/auth_hook.ex` | mount-time admin enforcement | ✓ VERIFIED | `on_mount(:ensure_admin, ...)` resolves `Auth.current_user/1`, assigns `current_admin`, and halts non-admin sessions before render. |
| `accrue_admin/test/accrue_admin/live/auth_hook_test.exs` | stabilized auth/dashboard regression | ✓ VERIFIED | The stale dashboard copy assertion now checks the current dashboard text, and the full focused suite passes in one run. |
| `accrue_admin/lib/accrue_admin/step_up.ex` | shared step-up workflow with audit writes | ✓ VERIFIED | Requires fresh auth, delegates to `Accrue.Auth`, records `admin.step_up.*` events, and tracks grace window state. |
| `accrue_admin/lib/accrue_admin/components/data_table.ex` | shared list primitive for list-heavy pages | ✓ VERIFIED | Implements URL filters, cursor paging, mobile card mode, bulk selection, and poll banner. |
| `accrue_admin/lib/accrue_admin/queries/*.ex` | schema-backed list queries over current projections | ✓ VERIFIED | Customer/subscription/invoice/charge/webhook/event/connect query modules use `Repo` queries against real projection tables. |
| `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` | KPI dashboard | ✓ VERIFIED | Aggregates customers, active subscriptions, invoice balances, webhook backlog, recent events, and webhook health locally. |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | customer detail tabs with event feed | ✓ VERIFIED | Renders all required tabs and uses `Events.timeline_for/3` for event data. |
| `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | invoice detail, PDF path, admin actions | ✓ VERIFIED | Uses `Billing.render_invoice_pdf/2`, invoice workflow APIs, timeline, and admin audit events. |
| `accrue_admin/lib/accrue_admin/live/charge_live.ex` | charge detail and refund flow | ✓ VERIFIED | Shows fee breakdown, refund history, step-up-gated refund flow, and causal admin audit recording. |
| `accrue_admin/lib/accrue_admin/live/webhook_live.ex` and `webhooks_live.ex` | webhook inspector, replay, bulk replay | ✓ VERIFIED | Use `Queries.Webhooks`, `DLQ.requeue/1`, `DLQ.requeue_where/1`, attempt history, and derived event linkage. |
| `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` | Connect detail and fee override UI | ✓ VERIFIED | Validates/saves per-account override in `account.data["platform_fee_override"]` and previews via `Accrue.Connect.platform_fee/2`. |
| `accrue_admin/lib/accrue_admin/dev/clock_live.ex`, `lib/mix/tasks/accrue_admin.assets.build.ex`, `guides/admin_ui.md`, `.github/workflows/accrue_admin_assets.yml` | dev tooling, asset task, docs, CI drift check | ✓ VERIFIED | Dev surfaces are compile gated; asset build task exists; guide documents mounting and asset task; workflow rebuilds bundle and checks drift. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `accrue_admin/lib/accrue_admin/router.ex` | `accrue_admin/lib/accrue_admin/auth_hook.ex` | `live_session ... on_mount: [{AccrueAdmin.AuthHook, :ensure_admin}]` | WIRED | The mount macro hard-wires admin enforcement before any page render. |
| `accrue_admin/lib/accrue_admin/auth_hook.ex` | `accrue/lib/accrue/auth.ex` | `Auth.current_user/1` and `Auth.admin?/1` | WIRED | Admin gating resolves the configured auth adapter at mount time. |
| `accrue_admin/lib/accrue_admin/live/*_live.ex` list pages | `accrue_admin/lib/accrue_admin/components/data_table.ex` + `queries/*.ex` | `live_component module={DataTable}` with `query_module=` | WIRED | Customers, subscriptions, invoices, charges, coupons, promotion codes, connect, webhooks, and events all use the shared list primitive. |
| `customer_live.ex`, `subscription_live.ex`, `invoice_live.ex`, `charge_live.ex` | `accrue/lib/accrue/events.ex` | `Events.timeline_for/3` | WIRED | Detail pages render timelines from `accrue_events`, not local placeholders. |
| `accrue_admin/lib/accrue_admin/live/charge_live.ex` | `accrue_admin/lib/accrue_admin/step_up.ex` + `Accrue.Billing.create_refund/2` | `confirm_refund` -> `StepUp.require_fresh` -> billing facade | WIRED | Refund flow is step-up gated and then executes through core billing APIs. |
| `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | `Accrue.Billing.render_invoice_pdf/2` and invoice workflow APIs | `open_pdf`, `finalize`, `pay`, `void`, `mark_uncollectible` | WIRED | Invoice page reuses Phase 6 PDF rendering and billing mutations. |
| `accrue_admin/lib/accrue_admin/live/webhook_live.ex` / `webhooks_live.ex` | `accrue/lib/accrue/webhooks/dlq.ex` | `DLQ.requeue/1`, `DLQ.requeue_where/1` | WIRED | Single and bulk replay use existing DLQ primitives directly. |
| `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` | `accrue/lib/accrue/connect.ex` | `Connect.platform_fee/2` preview + local `Account` update | WIRED | Preview uses shared fee math; persistence writes only the local override map. |
| `accrue_admin/lib/accrue_admin/live/*` | `accrue/lib/accrue/events.ex` | `Events.record/1` admin audit writes | WIRED | Subscription, invoice, charge, connect, and webhook flows all record admin events. |
| `accrue/lib/accrue/integrations/sigra.ex` | `Accrue.Auth` runtime selection | conditional adapter only | PARTIAL / DEFERRED | Adapter exists and delegates to `Sigra.Auth` / `Sigra.Audit`, but no-manual-config auto-selection is deferred to Phase 8. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `live/dashboard_live.ex` | `@stats`, `@recent_events`, `@webhook_health` | `Repo.aggregate/3` and `Repo.all/1` over `Customer`, `Subscription`, `Invoice`, `WebhookEvent`, `Event` | Yes | ✓ FLOWING |
| `live/customers_live.ex` / `live/customer_live.ex` | rows, tab counts, tab lists, timelines | `Queries.Customers.list/1`, `Repo` aggregates, `Events.timeline_for/3` | Yes | ✓ FLOWING |
| `live/invoice_live.ex` | `@invoice`, `@line_items`, `@timeline_events` | `Repo.get/2` + preload + `Events.timeline_for/3` + `Billing.render_invoice_pdf/2` | Yes | ✓ FLOWING |
| `live/charge_live.ex` | `@charge`, `@refunds`, `@timeline_events` | `Repo.get/2` + preload + `Events.timeline_for/3` + `Billing.create_refund/2` | Yes | ✓ FLOWING |
| `live/webhooks_live.ex` | DataTable rows and summary KPIs | `Queries.Webhooks.list/1` + `Repo.aggregate/3` over `WebhookEvent` | Yes | ✓ FLOWING |
| `live/webhook_live.ex` | `@attempt_history`, `@derived_events`, payload viewer | `Oban.Job`, `Event`, and stored `WebhookEvent.raw_body/data` | Yes | ✓ FLOWING |
| `live/events_live.ex` | global activity rows | `Queries.Events.list/1` + `Repo.aggregate/3` over `Event` | Yes | ✓ FLOWING |
| `live/connect_account_live.ex` | override preview and saved override state | `Account.data` plus `Connect.platform_fee/2` and `Repo.update/1` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Focused Phase 7 admin suite is stable as a whole | `cd accrue_admin && mix test test/accrue_admin/assets_test.exs test/accrue_admin/router_test.exs test/accrue_admin/theme_test.exs test/accrue_admin/queries/cursor_test.exs test/accrue_admin/queries/query_modules_test.exs test/accrue_admin/live/auth_hook_test.exs test/accrue_admin/live/step_up_test.exs test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/connect_account_live_test.exs test/accrue_admin/dev/dev_routes_test.exs test/accrue_admin/dev/email_preview_live_test.exs test/accrue_admin/dev/component_kitchen_live_test.exs test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/components/display_components_test.exs test/accrue_admin/components/data_table_test.exs test/mix/tasks/accrue_admin_assets_build_test.exs --warnings-as-errors` | `73 tests, 0 failures` | ✓ PASS |
| Core admin causality columns and writes work | `cd accrue && mix test test/accrue/events/admin_causality_test.exs --warnings-as-errors` | `2 tests, 0 failures` | ✓ PASS |
| Prod compile excludes dev-only admin tooling | `cd accrue_admin && MIX_ENV=prod mix compile` | compile exited 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| ADMIN-01 | 07-05 | LiveView dashboard with KPIs | ✓ SATISFIED | `live/dashboard_live.ex`; aggregate suite green |
| ADMIN-02 | 07-02, 07-11 | Mobile-first responsive layout | ✓ SATISFIED / HUMAN UAT | `components/app_shell.ex`, `layouts.ex`, `DataTable` card mode; browser/mobile UAT still required |
| ADMIN-03 | 07-02 | Light + dark mode | ✓ SATISFIED / HUMAN UAT | `layouts.ex`, theme assets, `theme_test.exs`; visual contrast UAT still required |
| ADMIN-04 | 07-02 | Brand palette theme | ✓ SATISFIED / HUMAN UAT | theme CSS/preset and shell components |
| ADMIN-05 | 07-09 | Breadcrumbs + flash notifications | ✓ SATISFIED | `components/breadcrumbs.ex`, `flash_group.ex` |
| ADMIN-06 | 07-02 | Brandable via runtime config | ✓ SATISFIED | `brand_plug.ex`, `layouts.ex`, shell brand assigns |
| ADMIN-07 | 07-03, 07-05, 07-11 | Customer list + search + filter | ✓ SATISFIED | `queries/customers.ex`, `live/customers_live.ex`, `DataTable` |
| ADMIN-08 | 07-05 | Customer detail tabs | ✓ SATISFIED | `live/customer_live.ex` |
| ADMIN-09 | 07-03, 07-05, 07-11 | Subscription list + detail with timeline | ✓ SATISFIED | `queries/subscriptions.ex`, `live/subscriptions_live.ex`, `live/subscription_live.ex` |
| ADMIN-10 | 07-05 | Subscription admin actions | ✓ SATISFIED | `live/subscription_live.ex` action handlers + `StepUp` |
| ADMIN-11 | 07-03, 07-06, 07-11 | Invoice list + detail | ✓ SATISFIED | `queries/invoices.ex`, `live/invoices_live.ex`, `live/invoice_live.ex` |
| ADMIN-12 | 07-06 | Invoice admin actions | ✓ SATISFIED | `live/invoice_live.ex` finalize/pay/void/uncollectible actions |
| ADMIN-13 | 07-03, 07-06, 07-11 | Charge list + detail with fee breakdown | ✓ SATISFIED | `queries/charges.ex`, `live/charges_live.ex`, `live/charge_live.ex` |
| ADMIN-14 | 07-06 | Refund admin action | ✓ SATISFIED | `live/charge_live.ex` refund flow and fee-aware messaging |
| ADMIN-15 | 07-03, 07-11, 07-12 | Coupon + PromotionCode management UI | ✓ SATISFIED | `live/coupons_live.ex`, `coupon_live.ex`, `promotion_codes_live.ex`, `promotion_code_live.ex` |
| ADMIN-16 | 07-07, 07-11 | Webhook inspector list/filter/detail | ✓ SATISFIED | `queries/webhooks.ex`, `live/webhooks_live.ex`, `live/webhook_live.ex` |
| ADMIN-17 | 07-07, 07-11 | Webhook replay + DLQ bulk requeue | ✓ SATISFIED | `live/webhook_live.ex`, `live/webhooks_live.ex`, `DLQ` links |
| ADMIN-18 | 07-05, 07-07, 07-11 | Activity feed from `accrue_events` | ✓ SATISFIED | subject timelines + `live/events_live.ex` |
| ADMIN-19 | 07-03, 07-11, 07-12 | Connect list/detail + capability inspector | ✓ SATISFIED | `queries/connect_accounts.ex`, `live/connect_accounts_live.ex`, `live/connect_account_live.ex` |
| ADMIN-20 | 07-12 | Platform fee configuration UI | ✓ SATISFIED | `live/connect_account_live.ex` override preview/save |
| ADMIN-21 | 07-04 | Step-up auth prompt for destructive actions | ✓ SATISFIED | `step_up.ex`, `components/step_up_auth_modal.ex`, destructive LiveViews |
| ADMIN-22 | 07-04 | Admin action audit logging to `accrue_events` | ✓ SATISFIED | `Events.record/1` calls in admin LiveViews |
| ADMIN-23 | 07-04 | Admin actions linked causally to prior events | ✓ SATISFIED | causality migration + action data carrying `caused_by_event_id` / `caused_by_webhook_event_id` |
| ADMIN-24 | 07-08 | Dev-only test-clock UI | ✓ SATISFIED | `dev/clock_live.ex`, compile gating, prod compile spot-check |
| ADMIN-25 | 07-01 | `accrue_admin` router macro | ✓ SATISFIED | `router.ex` `defmacro accrue_admin` |
| ADMIN-26 | 07-01, 07-04 | `on_mount` auth enforcement | ✓ SATISFIED | `router.ex` + `auth_hook.ex` |
| ADMIN-27 | 07-09, 07-10, 07-11 | Shared component library | ✓ SATISFIED | component primitives + `DataTable` |
| AUTH-03 | 07-04 | First-party Sigra adapter | ✓ SATISFIED | `accrue/lib/accrue/integrations/sigra.ex` |
| EVT-09 | 07-04 | Bridge Accrue events to `Sigra.Audit` when present | ✓ SATISFIED | `Accrue.Integrations.Sigra.log_audit/2` delegates to `Sigra.Audit.log/2` |

No orphaned Phase 7 requirement IDs were found outside the plan frontmatter set.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `accrue_admin/lib/accrue_admin/components/input.ex` | 13 | `placeholder` attr | ℹ️ Info | Normal form-component placeholder support; not a stub. |
| `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` | 31 | challenge input placeholder | ℹ️ Info | Real step-up input affordance; not a stub. |
| `accrue_admin/lib/accrue_admin/live/charge_live.ex` | 177 | refund amount/reason placeholders | ℹ️ Info | Real form hints backed by `Billing.create_refund/2`; not a stub. |

No blocker anti-patterns were found. The previous aggregate-suite instability warning is resolved by the green focused suite.

### Human Verification Required

### 1. Mobile Dashboard and Light/Dark Visual UAT

**Test:** Open `/billing` at phone width and desktop width, toggle light/dark/system theme, and inspect dashboard, list tables/card mode, navigation, flash, modal, and detail pages.
**Expected:** No horizontal overflow on phone, readable KPI/list/detail surfaces, usable navigation, and sufficient contrast across Ink/Slate/Fog/Paper + Moss/Cobalt/Amber.
**Why human:** Static tests confirm theme wiring and responsive component paths, but visual quality and contrast perception require browser inspection.

### 2. Operator Replay/Refund Flow UAT

**Test:** As an admin operator, inspect a failed webhook, replay it, bulk-requeue a filtered DLQ slice, then initiate a refund from a charge detail page and complete the step-up prompt.
**Expected:** The operator can understand each action, confirmations/errors are clear, and success states are visible without ambiguity.
**Why human:** Automated tests verify the backend calls and LiveView state changes, but confirmation clarity and operator affordance quality are UX-level checks.

### Gaps Summary

The prior actionable gap is closed. The focused Phase 7 `accrue_admin` suite now passes as a whole (`73 tests, 0 failures`), including the updated `auth_hook_test.exs` assertion for the current dashboard copy. The core admin causality test also passes in the `accrue` package (`2 tests, 0 failures`), and prod compile still succeeds.

The remaining non-passing roadmap wording is the no-manual-config Sigra auto-wiring clause. That remains intentionally deferred to Phase 8, whose install/polish goal explicitly includes Sigra wiring when present. Automated verification is otherwise green; final status is `human_needed` because the phase includes mobile-first visual and operator-flow UX claims that require browser UAT.

---

_Verified: 2026-04-15T19:31:05Z_
_Verifier: Claude (gsd-verifier)_
