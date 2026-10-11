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
- Mounted acceptance: extend the established authenticated host browser lane, with a separate Phase 246 evidence directory. Never invoke Phase 245's evidence-writing sweep after production changes.

## Sampling Rate

Each implementation task runs its focused owning checks. Each completed coherent slice gets one mounted interaction and rendered confirmation batch. The phase closeout runs package and touched existing browser owners. Repeat broader checks only for new changes or failures. Browser operations have explicit deadlines and await LiveView before hook interaction; optional absent metadata does not wait for a selector timeout.

## Per-Task Verification Map

Plans will fill exact task IDs and threat refs before execution.

| Requirement | Test type and owner | Required observations | Status |
|---|---|---|---|
| FILTER-01 | DataTable/FilterChipBar + consumer LiveViews + browser | Visible labels, separate view/constraints, one reset, remove-one X, scope preserved, responsive geometry | pending |
| FILTER-02 | Invoice/subscription query+LiveView+browser history | Default/direct comma statuses, within-field OR/across-field AND, input/URL/query/rows agree, clear and back/forward | pending |
| FILTER-03 | Consumer queries/LiveViews + browser secondary filters | Search help matches actual predicates, exact relations retained, custom values and owner scope preserved | pending |
| SEARCH-01 | GlobalSearch ExUnit, CommandPalette Node, mounted browser | One active painted/ARIA/Enter target, current loading only, focus return/trap, partial failures and stale generations | pending |
| TABLE-01 | Shared/consumer ExUnit + computed-style browser | Separated exact IDs, bounded row/column geometry, long-name/email/ID wide and 320px narrow stress, full copy access, coherent empty grouping | pending |

## Wave 0 Requirements

Existing test infrastructure is available. Extend nearest owners for identified behavior gaps; planner names mounted spec/config and evidence owner explicitly. No assertion-only mirror tests or mandatory new fixture service.

## Manual-Only Verifications

Bounded agent inspection of current screenshots establishes visual hierarchy/craft for changed compositions; checks establish behavior. Owner aesthetic acceptance remains optional feedback, never inferred from green tests. No repeated confirmation-only UAT is required.

## Validation Sign-Off

- [ ] Every plan task has a focused automated check or explicit dependency
- [ ] URL/control/query/result and scope checks wired
- [ ] Current served assets and rendered changed surfaces checked
- [ ] All UI probe categories and held-out long-content backstops have evidence
- [ ] Required package/owning browser checks pass

**Approval:** pending execution.
