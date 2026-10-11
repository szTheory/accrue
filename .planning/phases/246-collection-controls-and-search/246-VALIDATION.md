---
phase: "246"
slug: "collection-controls-and-search"
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| FILTER-01 | 246-01-02, 246-02-02/03, 246-04-03; T-246-01/02/03 | Visible labels, separate view/constraints, one reset, remove-one X, scope preserved, responsive geometry | planned |
| FILTER-02 | 246-01-01, 246-02-01, 246-04-03; T-246-01/03 | Default/direct comma statuses, within-field OR/across-field AND, input/URL/query/rows agree, clear and back/forward | planned |
| FILTER-03 | 246-02-02/03, 246-04-03; T-246-04 | Search help matches actual predicates, exact relations retained, custom values and owner scope preserved | planned |
| SEARCH-01 | 246-03-01/02, 246-04-03; T-246-05/06 | One active painted/ARIA/Enter target, current loading only, focus return/trap, partial failures and stale generations | planned |
| TABLE-01 | 246-04-01/02/03; T-246-07/08 | Separated exact IDs, bounded row/column geometry, long-name/email/ID wide and 320px narrow stress, full copy access, coherent empty grouping | planned |

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

**Approval:** pending execution.
