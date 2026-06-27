---
phase: 197
slug: propagate-list
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-27
---

# Phase 197 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source detail:
> `.planning/phases/197-propagate-list/197-RESEARCH.md` Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest for list contracts; Playwright through `@playwright/test` 1.59.1 for rendered desktop/mobile browser smoke |
| **Config file** | `accrue_admin/test/test_helper.exs`, `accrue_admin/playwright.config.js`, `accrue_admin/package.json` |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs` |
| **Full suite command** | `cd accrue_admin && mix test --warnings-as-errors && npm run e2e:phase197` |
| **Estimated runtime** | Focused LiveView run under 90 seconds; phase Playwright smoke under 3 minutes with `--workers=1`; full suite depends on existing app baseline |

---

## Sampling Rate

- **After every task commit:** Run the touched page's LiveView test plus any touched query/component test named in that task.
- **After every plan wave:** Run the eight target LiveView tests and `cd accrue_admin && npm run e2e:phase197`.
- **Before `/gsd:verify-work`:** Run `cd accrue_admin && mix test --warnings-as-errors && npm run e2e:phase197`; run asset build if CSS or JS changed.
- **Max feedback latency:** 3 minutes for the phase browser smoke; per-page LiveView checks should stay under 60 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 197-00-01 | TBD | 0 | PRP-01 | T-197-01 | Test-only LIST manifest names every target route, list id, default lens, and expected per-page copy without changing runtime scope | ExUnit support | `cd accrue_admin && mix test test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs` | No, W0 | pending |
| 197-00-02 | TBD | 0 | PRP-01 | T-197-02 | Browser proof checks public UI markers and static text only; it must not expose owner ids or raw secret-bearing values | Playwright | `cd accrue_admin && npx playwright test e2e/admin-spec-list-phase197.spec.js --timeout=60000 --workers=1` | No, W0 | pending |
| 197-00-03 | TBD | 0 | PRP-01 | T-197-03 | Clear-all and filter paths preserve `current_owner_scope` / `org` context across list pages | LiveView + query tests | `cd accrue_admin && mix test test/accrue_admin/live/*_live_test.exs --warnings-as-errors` | Partial, expand per page | pending |
| 197-00-04 | TBD | 0 | PRP-01 | T-197-04 | Webhooks status filters are allowlisted and selected-row replay remains scoped before requeue | LiveView + query tests | `cd accrue_admin && mix test test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/queries/webhooks_test.exs` | Partial, expand | pending |
| 197-00-05 | TBD | 0 | PRP-01 | T-197-05 | Connect `needs_attention` lens is expressed as a bounded query predicate and does not silently drop actionable accounts | LiveView + query tests | `cd accrue_admin && mix test test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/queries/connect_accounts_test.exs` | Partial, expand | pending |
| 197-00-06 | TBD | 0 | PRP-01 | T-197-06 | Charges/payments owner-scope behavior is explicit before the Payments page adopts owner-scope-preserving clear/filter links | LiveView + query tests | `cd accrue_admin && mix test test/accrue_admin/live/charges_live_test.exs test/accrue_admin/queries/charges_test.exs` | Partial, expand | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `accrue_admin/test/support/list_contracts.ex` or an equivalent test-only manifest covers the eight target pages: customers, invoices, payments/charges, coupons, promotion codes, webhooks, events, and connect.
- [ ] `accrue_admin/e2e/admin-spec-list-phase197.spec.js` covers all target routes for PageHeader, exactly one h1, table-first rendering, chip/count/clear affordances, and row-to-card degradation.
- [ ] `accrue_admin/package.json` includes `e2e:phase197` pointing at `e2e/admin-spec-list-phase197.spec.js` with deterministic timeout/workers.
- [ ] Page-specific copy helpers or equivalent per-page state strings cover populated, first-run-empty, filtered-empty, and loading states.
- [ ] Representative fixture support can drive `loading-skeleton` deterministically, preferably through one shared `phase197_state=loading-skeleton` test param unless a page needs narrower fixtures.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual scan order and density across the eight propagated list pages | PRP-01 | DOM assertions can prove structure, but final hierarchy and truncation need human inspection in desktop/mobile and light/dark modes | After `npm run e2e:phase197`, inspect the Playwright traces/screenshots or live pages for table-first density, PageHeader hierarchy, chip readability, and row-to-card degradation with no clipping. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency under 3 minutes
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 passes

**Approval:** pending
