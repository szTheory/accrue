---
phase: "246"
slug: "collection-controls-and-search"
status: validated
nyquist_compliant: false
wave_0_complete: true
created: "2026-10-11"
---

# Phase 246 — Validation Strategy

## Test Infrastructure

Existing ExUnit/LiveView, Node built-in hook tests, and authenticated host Playwright owners. No dependency or new CI lane.

- Quick component/hook checks: `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs test/accrue_admin/components/global_search_test.exs` and `node --test test/js/command_palette_test.mjs`.
- Package acceptance: `cd accrue_admin && mix test --warnings-as-errors`.
- Asset acceptance: `cd accrue_admin && mix accrue_admin.assets.build`; verify package compiled and host served CSS/JS match current source.
- Mounted acceptance: `playwright.phase246.config.js` targets the guarded ordinary Fake preview for real journeys, while existing `playwright.config.js` global setup, Ecto Sandbox fixture and the Phase 246 test-host-only authenticated states route produce deterministic loading, error, partial, zero/one/many and long-content cases. Keep browser output under a separate Phase 246 evidence directory. Never invoke Phase 245's evidence-writing sweep after production changes.

## Sampling Rate

Each implementation task runs its focused owning checks. Each completed coherent slice gets one mounted interaction and rendered confirmation batch. The phase closeout runs package and touched existing browser owners. Repeat broader checks only for new changes or failures. Browser operations have explicit deadlines and await LiveView before hook interaction; optional absent metadata does not wait for a selector timeout.

## Per-Task Verification Map

Plan task IDs and threat refs are assigned below; execution fills pass/fail evidence.

| Requirement | Test type and owner | Required observations | Status |
|---|---|---|---|
| FILTER-01 | 246-01-02, 246-02-02/03, 246-04-03; T-246-01/02/03 | Visible labels, separate view/constraints, one reset, remove-one X, scope preserved, responsive geometry | pass (owning ExUnit and Phase 246 browser checks recorded in summaries) |
| FILTER-02 | 246-01-01, 246-02-01, 246-04-03; T-246-01/03 | Default/direct comma statuses, within-field OR/across-field AND, input/URL/query/rows agree, clear and back/forward | pass (owning ExUnit and Phase 246 browser checks recorded in summaries) |
| FILTER-03 | 246-02-02/03, 246-04-03; T-246-04 | Search help matches actual predicates, exact relations retained, custom values and owner scope preserved | pass (owning ExUnit and Phase 246 browser checks recorded in summaries) |
| SEARCH-01 | 246-03-01/02, 246-04-03; T-246-05/06 | One active painted/ARIA/Enter target, current loading only, focus return/trap, partial failures and stale generations | pass (owning Node, asset, and Phase 246 browser checks recorded in summaries) |
| TABLE-01 | 246-04-01/02/03; T-246-07/08 | Separated exact IDs, bounded row/column geometry, long-name/email/ID wide and 320px narrow stress, full copy access, coherent empty grouping | pass for five remaining collection consumers (60 LiveView tests, 0 failures, seed 0) and shared table/copy contracts (35 tests, 0 failures, seed 0); original Phase 246 rendered evidence remains recorded in 246-04-SUMMARY.md |

### Task Verification Map

| Task ID | Requirements | Focused command | Status |
|---|---|---|---|
| 246-01-01 | FILTER-02 | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs`; Phase 246 invoice browser spec | pass |
| 246-01-02 | FILTER-01 | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs test/accrue_admin/live/invoices_live_test.exs` | pass |
| 246-02-01 | FILTER-02, FILTER-01 | `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/coupons_live_test.exs`; Phase 246 collection browser spec | pass |
| 246-02-02 | FILTER-01, FILTER-03 | `cd accrue_admin && mix test test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs` | pass for filter behavior; TABLE-01 gap found separately below |
| 246-02-03 | FILTER-03 | `cd accrue_admin && mix test test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/events_live_test.exs` | pass for filter behavior; TABLE-01 gap found separately below |
| 246-03-01 | SEARCH-01 | `cd accrue_admin && mix test test/accrue_admin/components/global_search_test.exs && mix accrue_admin.assets.build` | pass |
| 246-03-02 | SEARCH-01 | `cd accrue_admin && node --test test/js/command_palette_test.mjs`; Phase 246 search browser specs | pass |
| 246-04-01 | TABLE-01 | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/empty_state_test.exs` | pass |
| 246-04-02 | TABLE-01 | `cd accrue_admin && MIX_ENV=test mix test --warnings-as-errors --seed 0 test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/webhooks_live_test.exs` | pass, 60 tests / 0 failures; shared `data_table_test.exs` and `id_badge_test.exs`: 35 / 0 |
| 246-04-03 | TABLE-01, FILTER-01, SEARCH-01 | Phase 246 table/search/filter browser specs and asset checks | pass per Plan 04 summary |

### Adversarial Gap: Exact-ID Copy on Remaining Collection Consumers

Plan 04's consumer assertions covered invoices, customers, subscriptions, and promotion codes. The shared `DataTable.identity_cell/1` is opt-in; coupons, events, payments, Connect accounts, and webhooks used their own first-column renderers. The five new focused assertions first reproduced the gap (60 tests, 5 failures) and remain as regression coverage. Existing identity-cell and clipboard components now render distinct readable identity and copyable exact identifiers on all five rows. The event action copies the stored event type key, while its accessible label says “Copy event type” to distinguish it from the event row UUID.

| Consumer | Expected behavior | Observed output | Implementation owner |
|---|---|---|---|
| Coupons | Copyable `coupon_spring` ID alongside coupon name | Resolved with `DataTable.identity_cell/1` and `IdBadge`; focused assertion passes | `accrue_admin/lib/accrue_admin/live/coupons_live.ex:236` |
| Events | Copyable exact event type key | Resolved; friendly type label and exact key remain visible, with copy action labeled “Copy event type” | `accrue_admin/lib/accrue_admin/live/events_live.ex:432` |
| Payments | Copyable `ch_open` processor ID | Resolved with customer identity and exact payment ID copy action | `accrue_admin/lib/accrue_admin/live/charges_live.ex:263` |
| Connect accounts | Copyable `acct_match` Stripe ID | Resolved with account email when available and exact Stripe ID copy action | `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex:490` |
| Webhooks | Copyable `evt_dead` processor event ID | Resolved with readable event type and exact processor ID copy action | `accrue_admin/lib/accrue_admin/live/webhooks_live.ex:917` |

The initial RED run failed each assertion because the rendered output lacked the copy action. After the fix, the same five-file command passes all 60 tests with warnings treated as errors and seed 0. The shared DataTable and IdBadge component contracts also pass 35 tests with seed 0.

## Wave 0 Requirements

Existing test infrastructure is available. Extend nearest owners for identified behavior gaps; mounted specs are `examples/accrue_host/e2e/phase246-*.spec.js`, ordinary config is `examples/accrue_host/playwright.phase246.config.js`, held-out config is existing `examples/accrue_host/playwright.config.js`, and evidence belongs under `.planning/phases/246-collection-controls-and-search/captures/`. The held-out state owner is `examples/accrue_host/lib/accrue_host_web/live/phase246_states_live.ex`, gated by `:sql_sandbox` in the existing host router. The guarded ordinary Fake preview supplies real records; the seeded test host supplies exceptional states. No assertion-only mirror tests, production scenario picker or mandatory new fixture service. Phase 243 protected instance and Phase 245 captures remain untouched.

## Manual-Only Verifications

Bounded agent inspection of current screenshots establishes visual hierarchy/craft for changed compositions; checks establish behavior. Owner aesthetic acceptance remains optional feedback, never inferred from green tests. No repeated confirmation-only UAT is required.

## Validation Sign-Off

- [ ] Every plan task has a focused automated check or explicit dependency
- [ ] URL/control/query/result and scope checks wired
- [ ] Current served assets and rendered changed surfaces checked
- [ ] All UI probe categories and held-out long-content backstops have evidence
- [ ] Required package/owning browser checks pass

**Approval:** validation completed for the TABLE-01 identity-copy gap. Nyquist compliance remains false because the broader phase sign-off rows above still include unchecked rendered-evidence criteria.

## Validation Audit 2026-10-11

| Metric | Count |
|---|---|
| Gaps found | 5 |
| Resolved | 5 |
| Escalated | 0 |
