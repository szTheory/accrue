---
phase: 7
slug: admin-ui-accrue-admin
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-15
finalized: 2026-04-15
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Finalized during the checker-blocker revision pass on 2026-04-15.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit across `accrue` and `accrue_admin` |
| **Config files** | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, shared cases in `accrue_admin/test/support/` |
| **Quick run command** | Run the task-local `<automated>` command from the active task |
| **Full suite command** | `cd accrue && mix test --warnings-as-errors && cd ../accrue_admin && mix test --warnings-as-errors` |
| **Compile smoke** | `cd accrue_admin && MIX_ENV=prod mix compile` |
| **Estimated runtime** | Task-local: ~5-25s · full phase regression: ~120s |

---

## Sampling Rate

- **After every task commit:** Run that task's `<automated>` verify command exactly as written
- **After every plan wave:** Run the full suite command above
- **Before `/gsd-verify-work`:** Full suite green + `mix credo --strict` in both packages + `mix dialyzer`
- **Max feedback latency:** 30 seconds for task-local checks, 120 seconds for wave checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 07-01-T1 | 01 | 1 | ADMIN-25, ADMIN-26 | integration | `cd accrue_admin && test -f priv/static/accrue_admin.css && test -f priv/static/accrue_admin.js && mix test test/accrue_admin/router_test.exs test/accrue_admin/assets_test.exs` | ⬜ pending |
| 07-01-T2 | 01 | 1 | ADMIN-25, ADMIN-26 | integration | `cd accrue_admin && mix test test/accrue_admin/router_test.exs test/accrue_admin/assets_test.exs --warnings-as-errors` | ⬜ pending |
| 07-02-T1 | 02 | 2 | ADMIN-02, ADMIN-03, ADMIN-04, ADMIN-06 | integration | `cd accrue_admin && mix test test/accrue_admin/theme_test.exs --warnings-as-errors` | ⬜ pending |
| 07-04-T1 | 04 | 2 | AUTH-03, EVT-09, ADMIN-21, ADMIN-22, ADMIN-23 | integration | `cd accrue && mix test test/accrue/events/admin_causality_test.exs --warnings-as-errors` | ⬜ pending |
| 07-04-T2 | 04 | 2 | ADMIN-21, ADMIN-26 | LiveView integration | `cd accrue_admin && mix test test/accrue_admin/live/auth_hook_test.exs test/accrue_admin/live/step_up_test.exs --warnings-as-errors` | ⬜ pending |
| 07-03-T1 | 03 | 2 | ADMIN-07, ADMIN-09, ADMIN-11, ADMIN-13, ADMIN-15, ADMIN-19 | query + migration | `cd accrue_admin && mix test test/accrue_admin/queries/cursor_test.exs test/accrue_admin/queries/query_modules_test.exs --warnings-as-errors` | ⬜ pending |
| 07-09-T1 | 09 | 3 | ADMIN-05, ADMIN-27 | component | `cd accrue_admin && mix test test/accrue_admin/components/navigation_components_test.exs --warnings-as-errors` | ⬜ pending |
| 07-09-T2 | 09 | 3 | ADMIN-27 | component | `cd accrue_admin && mix test test/accrue_admin/components/navigation_components_test.exs --warnings-as-errors` | ⬜ pending |
| 07-10-T1 | 10 | 3 | ADMIN-27 | component | `cd accrue_admin && mix test test/accrue_admin/components/display_components_test.exs --warnings-as-errors` | ⬜ pending |
| 07-10-T2 | 10 | 3 | ADMIN-27 | component | `cd accrue_admin && mix test test/accrue_admin/components/display_components_test.exs --warnings-as-errors` | ⬜ pending |
| 07-11-T1 | 11 | 4 | ADMIN-07, ADMIN-09, ADMIN-11, ADMIN-13, ADMIN-15, ADMIN-16, ADMIN-18, ADMIN-19, ADMIN-27 | component | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs --warnings-as-errors` | ⬜ pending |
| 07-11-T2 | 11 | 4 | ADMIN-02, ADMIN-17, ADMIN-27 | component | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs --warnings-as-errors` | ⬜ pending |
| 07-05-T1 | 05 | 5 | ADMIN-01, ADMIN-07, ADMIN-08, ADMIN-18 | LiveView integration | `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/customer_live_test.exs --warnings-as-errors` | ⬜ pending |
| 07-05-T2 | 05 | 5 | ADMIN-09, ADMIN-10 | LiveView integration | `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/subscription_live_test.exs --warnings-as-errors` | ⬜ pending |
| 07-06-T1 | 06 | 5 | ADMIN-11, ADMIN-12, ADMIN-13, ADMIN-14 | LiveView integration | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/charge_live_test.exs --warnings-as-errors` | ⬜ pending |
| 07-07-T1 | 07 | 5 | ADMIN-16 | LiveView integration | `cd accrue_admin && mix test test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/webhook_live_test.exs --warnings-as-errors` | ⬜ pending |
| 07-07-T2 | 07 | 5 | ADMIN-17, ADMIN-18 | LiveView integration | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/events_live_test.exs --warnings-as-errors` | ⬜ pending |
| 07-12-T1 | 12 | 5 | ADMIN-15 | LiveView integration | `cd accrue_admin && mix test test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs --warnings-as-errors` | ⬜ pending |
| 07-12-T2 | 12 | 5 | ADMIN-19, ADMIN-20 | LiveView integration | `cd accrue_admin && mix test test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/connect_account_live_test.exs --warnings-as-errors` | ⬜ pending |
| 07-08-T1 | 08 | 6 | ADMIN-24 | compile smoke + LiveView integration | `cd accrue_admin && mix test test/accrue_admin/dev/dev_routes_test.exs test/accrue_admin/dev/email_preview_live_test.exs test/accrue_admin/dev/component_kitchen_live_test.exs --warnings-as-errors && MIX_ENV=prod mix compile` | ⬜ pending |
| 07-08-T2 | 08 | 6 | ADMIN-24 | mix task smoke + docs grep | `cd accrue_admin && mix test test/mix/tasks/accrue_admin_assets_build_test.exs --warnings-as-errors && mix accrue_admin.assets.build && test -f ../.github/workflows/accrue_admin_assets.yml && rg -q 'accrue_admin \"/billing\"' guides/admin_ui.md && rg -q 'accrue_admin.assets.build' guides/admin_ui.md` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Nyquist Sampling Continuity Check

- Every plan task now has a concrete `<automated>` command.
- No overloaded plan relies on a broad `mix test` catch-all as its only proof.
- The revised split removes the prior checker risk where shared components, query/DataTable, and invoice-or-coupon-or-connect groupings hid multiple concerns behind one verify loop.

---

## Wave 0 Requirements

These artifacts must exist before later waves are executed against them:

- [ ] `accrue_admin/test/support/conn_case.ex` — admin package connection harness from 07-01
- [ ] `accrue_admin/test/support/live_case.ex` — shared LiveView harness from 07-01
- [ ] `accrue_admin/test/accrue_admin/router_test.exs` — mount/asset route smoke coverage from 07-01
- [ ] `accrue/test/accrue/events/admin_causality_test.exs` — causal event-link regression from 07-04
- [ ] `accrue_admin/test/accrue_admin/components/data_table_test.exs` — shared list primitive regression file from 07-11

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Mobile-first usability on phone viewport | ADMIN-02 | HEEx rendering tests cannot prove practical thumb-target and drawer usability | Mount the admin UI at `/billing`, open in mobile simulator, verify sidebar drawer, card-mode tables, and full-screen detail drawer behavior |
| Theme anti-FOUC and brand override feel | ADMIN-03, ADMIN-04, ADMIN-06 | Ordering and cookie tests do not fully capture first-paint feel in a browser | Load `/billing` with light, dark, and system cookie values and confirm no flash before styles settle |
| Webhook payload inspection ergonomics | ADMIN-16, ADMIN-17 | JSON tree usability and replay confirmation copy are operator UX checks | Open a failed webhook, inspect Tree/Raw/Copy tabs, run single and bulk replay, verify confirmation and progress copy |
| Step-up auth UX | ADMIN-21 | Adapter challenge flow depends on host auth integration | Trigger refund/manual cancel flows in a host app with the configured auth adapter and verify grace-window behavior |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands
- [x] Sampling continuity is preserved across all revised plans
- [x] `07-VALIDATION.md` exists for Nyquist-enabled planning
- [x] Plan-local verify commands are narrow enough to target the artifact under construction
- [x] Promotion-code UI has its own requirement row and test command
- [x] `queries` naming is consistent across Phase 7 docs and plans
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready — Phase 7 revision iteration 2, 2026-04-15
