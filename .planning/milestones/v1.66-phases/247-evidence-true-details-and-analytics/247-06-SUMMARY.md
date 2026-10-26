---
phase: 247-evidence-true-details-and-analytics
plan: "06"
subsystem: payments
tags: [phoenix, liveview, recovery, analytics, currency]
requires:
  - phase: 247-05
    provides: evidence-true billing copy and concrete navigation conventions
provides:
  - Per-currency recovered and exhausted MRR cards with distinct unavailable and zero states.
  - Payment recovery page naming with separate UTC-window and historical-coverage context.
affects: [247-07, recovery-analytics, admin-copy]
tech-stack:
  added: []
  patterns: [paired currency KPI cards, named cutoff-semantics help]
key-files:
  created: []
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/components/window_selector.ex
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
decisions:
  - Preserve the Dunning query, formulas, owner scope, and UTC boundaries while changing presentation.
  - Pair recovered and exhausted values per currency; zero remains a value and missing or unsupported amounts remain unavailable.
  - Describe historical coverage separately from the selected UTC window and name the cutoff-semantics documentation destination.
metrics:
  duration: 15min
  completed_date: 2026-10-11
status: complete
actuals:
  tokens: 71889
  tasks: 2
  commits: 5
plan_head_before: 61b5f37a7bdc034ff1f63e07b16e74ca4164e303
plan_head_after: 646d8d2c662e2bcee0e600eb33fde02825bcb91d
commits: 5
requirements-completed: []
---

# Phase 247 Plan 06: Currency-True Payment Recovery Summary

**Payment recovery now presents paired currency-specific recurring-revenue metrics with truthful unavailable states, clear monthly definitions, and separate UTC-window and historical-coverage context.**

## Accomplishments

- Kept recovered and exhausted MRR cards together by currency, preserving supported values, actual zero, missing amounts, and unsupported currency as distinct visible states.
- Replaced the “Money Saved” and “Churned Revenue” claims and delta prose with one concise monthly recurring-revenue definition per metric.
- Named the page “Payment recovery,” removed the artificial Analytics breadcrumb, and separated historical coverage text from the active UTC window selector.
- Rebuilt the package CSS bundle so the new token-based pairing, wrapping, and narrow layout rules are served by the Admin package.

## Task Commits

1. **Task 1 RED: recovery presentation cases** — `dac599f6`
2. **Task 1 GREEN: pair currency recovery metrics** — `166fc96c`
3. **Task 2: clarify recovery window and coverage** — `32064e69`
4. **No-new-public-symbol correction** — `646d8d2c`

An earlier documentation closeout commit (`44c72ba9`) is included in the measured commit count and superseded when this summary's final metrics were refreshed.

## Validation

- RED: the target LiveView test failed on the expected missing monthly definition assertion before implementation.
- GREEN: `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` — 32 tests, 0 failures.
- `mix format --check-formatted` passed for the modified Elixir sources and test.
- `git diff --check` passed.
- `NPM_CONFIG_CACHE=/private/tmp/accrue247-npm-cache mix accrue_admin.assets.build` completed successfully; generated CSS is committed with its source.

## Deviations from Plan

None. The first asset build attempt could not write to the user-level npm cache, so the successful build used a temporary cache under `/private/tmp`; no project dependency changed.

## Issues Encountered

The default npm cache path was not writable in this environment. Redirecting npm’s cache to `/private/tmp/accrue247-npm-cache` allowed the planned asset build to complete.

## Deferred Issues

None.

## Self-Check: PASSED

The modified source and generated asset files exist. All three task commits are ancestors of the current plan head. The suite, formatting check, and diff check passed.

---
*Phase: 247-evidence-true-details-and-analytics*
*Completed: 2026-10-11*
