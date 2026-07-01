---
phase: 197
slug: propagate-list
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-27
audited: 2026-06-28
verification_report: .planning/phases/197-propagate-list/197-VERIFICATION.md
---

# Phase 197 - Nyquist Validation Coverage

Phase 197 is Nyquist-compliant for PRP-01. The stale draft map has been reconciled against all seven PLAN files, all seven SUMMARY files, and `197-VERIFICATION.md`.

## Audit Verdict

| Item | Result |
|------|--------|
| Requirements audited | PRP-01 |
| Phase task map audited | 7 plans, 20 tasks |
| Behavior-unverified gaps | 0 |
| Missing automated commands | 0 |
| Manual-only Phase 197 requirements | 0 |
| Verification report status | passed, 28/28 must-haves verified |
| Current audit status | passed |

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit, Phoenix.LiveViewTest, Playwright through `@playwright/test` |
| Config files | `accrue_admin/test/test_helper.exs`, `accrue_admin/playwright.config.js`, `accrue_admin/package.json` |
| Focused LiveView gate | `cd accrue_admin && mix test test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs --max-failures 3` |
| Query/copy/component gate | `cd accrue_admin && mix test test/accrue_admin/queries/query_modules_test.exs test/accrue_admin/copy_test.exs test/accrue_admin/components/page_header_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs --max-failures 3` |
| Browser gate | `cd accrue_admin && npm run e2e:phase197` |
| Guardrails | `cd accrue_admin && mix compile --warnings-as-errors`; `bash scripts/ci/verify_package_docs.sh` |

## Evidence Commands

Current audit run on 2026-06-28:

| Command | Result | Status |
|---------|--------|--------|
| `cd accrue_admin && mix test test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs --max-failures 3` | 63 tests, 0 failures | green |
| `cd accrue_admin && mix test test/accrue_admin/queries/query_modules_test.exs test/accrue_admin/copy_test.exs test/accrue_admin/components/page_header_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs --max-failures 3` | 64 tests, 0 failures | green |
| `cd accrue_admin && node --check e2e/admin-spec-list-phase197.spec.js` | exit 0 | green |
| `cd accrue_admin && npm run e2e:phase197` | 15 passed, 15 skipped, 0 failed | green |
| `cd accrue_admin && mix compile --warnings-as-errors` | exit 0 | green |
| `bash scripts/ci/verify_package_docs.sh` | package docs verified for `accrue`, `accrue_admin`, and `accrue_portal` 1.4.0 | green |

The 15 Playwright skips are intentional project-scope skips in the Phase 197 representative browser matrix, not validation gaps.

## Requirement Coverage

| Requirement | Behavior | Evidence | Status |
|-------------|----------|----------|--------|
| PRP-01 | All eight remaining list pages conform to SPEC-LIST, adopt `PageHeader`, and carry per-page JTBD microcopy plus populated, first-run-empty, filtered-empty, queue/default-empty where applicable, and loading coverage. | `197-VERIFICATION.md` reports 28/28 must-haves; current focused LiveView, query/copy/component, Playwright, compile, and package-docs gates are green. | satisfied |

## Per-Task Verification Map

| Task ID | Requirement | Behavior | Test Type | Automated Command | Status |
|---------|-------------|----------|-----------|-------------------|--------|
| 197-01-01 | PRP-01 | Test-only LIST contract manifest covers all eight routes, list ids, default lenses, all targets, state copy, clear-all, and loading fixture expectations. | Unit/support + LiveView | Focused LiveView gate | green |
| 197-01-02 | PRP-01 | Webhooks multi-status, Connect attention, and Payments owner-scope RED contracts exist and now pass against implementation. | Integration | Query/copy/component gate | green |
| 197-01-03 | PRP-01 | Phase 197 Playwright spec and `e2e:phase197` command cover all-page smoke plus representative deep checks. | Smoke | `node --check`; browser gate | green |
| 197-02-01 | PRP-01 | Customers, Coupons, and Promotion codes LiveView contracts cover PageHeader, one h1, chips/count/clear-all, defaults, states, and column priority. | Integration | Focused LiveView gate | green |
| 197-02-02 | PRP-01 | Invoices and Payments LiveView contracts cover queue defaults, owner-safe clear-all, states, and route language. | Integration | Focused LiveView gate | green |
| 197-02-03 | PRP-01 | Webhooks, Events, and Connect LiveView contracts cover replay, ledger, attention, owner-safe clear-all, and states. | Integration | Focused LiveView gate | green |
| 197-03-01 | PRP-01 | `AccrueAdmin.Copy` exposes deterministic JTBD, lens, result-label, empty-state, and loading copy for all eight pages. | Unit | Query/copy/component gate | green |
| 197-03-02 | PRP-01 | Webhooks `status=failed,dead` is allowlisted and Connect `needs_attention=true` is a named OR lens. | Integration | Query/copy/component gate | green |
| 197-03-03 | PRP-01 | Payments/Charges owner scope is explicit and enforced before filters, cursors, counts, and projections. | Integration | Query/copy/component gate | green |
| 197-04-01 | PRP-01 | Customers uses all-default LIST behavior with Missing payment method quick lens and four list states. | Integration + smoke | Focused LiveView gate; browser gate | green |
| 197-04-02 | PRP-01 | Coupons uses Valid coupons default, All coupons escape hatch, state-specific copy, and owner-safe links. | Integration + smoke | Focused LiveView gate; browser gate | green |
| 197-04-03 | PRP-01 | Promotion codes uses Active codes default, All promotion codes escape hatch, state-specific copy, and owner-safe links. | Integration + smoke | Focused LiveView gate; browser gate | green |
| 197-05-01 | PRP-01 | Invoices defaults to Needs collection with `status=open,uncollectible`, All invoices one chip away, and scoped clear-all. | Integration + smoke | Focused LiveView gate; browser gate | green |
| 197-05-02 | PRP-01 | Payments defaults to Failed payments on `/payments` through `ChargesLive`, with Payments copy and scoped query behavior. | Integration + smoke | Focused LiveView gate; query/copy/component gate; browser gate | green |
| 197-06-01 | PRP-01 | Webhooks defaults to Needs replay via `status=failed,dead` and preserves selected-row replay semantics. | Integration + smoke | Focused LiveView gate; query/copy/component gate; browser gate | green |
| 197-06-02 | PRP-01 | Events defaults to All ledger and keeps Admin changes as a quick URL-backed lens. | Integration + smoke | Focused LiveView gate; browser gate | green |
| 197-06-03 | PRP-01 | Connect defaults to Needs attention using the named OR query lens and preserves owner scope. | Integration + smoke | Focused LiveView gate; query/copy/component gate; browser gate | green |
| 197-07-01 | PRP-01 | Browser smoke passes across all eight propagated list routes without becoming an exhaustive matrix. | Smoke | Browser gate | green |
| 197-07-02 | PRP-01 | Focused LiveView, query, copy, and component phase gates are green. | Integration | Focused LiveView gate; query/copy/component gate | green |
| 197-07-03 | PRP-01 | Compile and package documentation guardrails pass; broad-suite non-Phase-197 blocker is documented separately. | Guardrail | Compile and package-docs guardrails | green |

## Wave 0 Requirements

- [x] `accrue_admin/test/support/list_contracts.ex` covers customers, invoices, payments/charges, coupons, promotion codes, webhooks, events, and connect.
- [x] `accrue_admin/e2e/admin-spec-list-phase197.spec.js` covers all target routes for PageHeader, exactly one h1, table-first desktop rendering, chip/count/clear affordances, and mobile row-to-card degradation.
- [x] `accrue_admin/package.json` includes `e2e:phase197` pointing at `e2e/admin-spec-list-phase197.spec.js` with deterministic timeout/workers.
- [x] Page-specific copy helpers cover populated, first-run-empty, filtered-empty, queue/default-empty where applicable, and loading states.
- [x] `phase197_state=loading-skeleton` fixture support drives loading proof deterministically.

## Gap Analysis

| Category | Count | Result |
|----------|-------|--------|
| Missing tests | 0 | No uncovered PRP-01 behavior found. |
| Partial/failing phase tests | 0 | Current focused phase gates are green. |
| Missing automated commands | 0 | Every Phase 197 task maps to an automated command. |
| Manual-only Phase 197 requirements | 0 | Browser and LiveView coverage satisfy Phase 197; later milestone visual/photo sign-off remains outside this phase. |

## Known Unrelated Broad-Suite Failure

The Dashboard `$42.50` assertion remains a known broad-suite blocker and is not counted as a Phase 197 validation gap. `197-VERIFICATION.md` classifies it as non-blocking because Phase 197 did not modify Dashboard source/test files and all PRP-01 focused gates are green.

## Validation Audit 2026-06-28

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved by new tests in this audit | 0 |
| Escalated | 0 |
| Skipped requirements | 0 |
| Phase tasks mapped to green automated evidence | 20 |

## Validation Sign-Off

- [x] All tasks have automated verify commands.
- [x] Sampling continuity maintained across Wave 0 through final phase gates.
- [x] Wave 0 contract artifacts exist and pass.
- [x] No watch-mode commands are required.
- [x] Focused feedback latency remains under the planned 3 minute browser-smoke budget.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** passed
