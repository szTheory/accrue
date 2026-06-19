---
phase: 191
slug: page-flow-interaction-pass-fixture-stress-microcopy
status: approved
generated: 2026-06-19
owner_phase_191_rows: 178
high_severity_rows: 70
medium_severity_rows: 108
direct_high_coverage: 70
medium_id_tag_coverage: 108
---

# Phase 191 AX187 Coverage Ledger

This ledger records the source-only Phase 191 coverage gate and the automated closeout evidence collected after Plans 01-06 completed.

## Coverage Summary

| Metric | Count | Notes |
|--------|-------|-------|
| Owner-phase 191 AX187 rows | 178 | Source audit reads `.planning/phases/187-audit-baseline/defects.ndjson` and filters `owner_phase == 191`. |
| High-severity rows | 70 | All 70 high-severity rows are directly cited in the Phase 191 spec. |
| Medium-severity rows | 108 | All 108 medium-severity rows are covered by direct AX187 IDs or normalized overlay tags. |
| Normalized overlay tags | 10 | `actionability`, `layer-z-index`, `overlay-position`, `disabled-affordance`, `hover-affordance`, `focus-restore`, `live-focus`, `scroll-reachability`, `copy-recovery`, `copy-specificity`. |

## Automated Evidence

| Command | Result | Notes |
|---------|--------|-------|
| `node scripts/ci/verify_phase191_ax187_coverage.mjs` | pass | Reported `Phase 191 AX187 owner count: 178`, `Direct high-severity coverage: 70/70`, `Medium ID/tag coverage: 108/108`, then exited 0. |
| `cd accrue_admin && npm run e2e:phase191` | pass | 14 tests passed on chromium desktop and mobile. |
| `cd accrue_admin && npm run e2e:a11y` | pass | 2 tests passed. |
| `cd accrue_admin && npm run e2e:group-contracts` | pass | 16 tests passed after rerun without the shared build-lock collision. |
| `cd accrue_admin && mix test test/accrue_admin/copy_test.exs test/accrue_admin/components/app_shell_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/e2e_fixtures_test.exs` | pass | 75 tests passed. |
| `cd examples/accrue_host && mix test test/seeds_idempotency_test.exs test/accrue_host/phase191_seed_reachability_test.exs` | pass | 4 tests passed; host seed contract remained deterministic and idempotent. |

## Evidence Roots

| Root | Use |
|------|-----|
| `accrue_admin/test-results` | Playwright runtime artifact root. No traces or screenshots are committed from this closeout. |
| `.planning/phases/191-page-flow-interaction-pass-fixture-stress-microcopy/191-VALIDATION.md` | Validation state and command summary. |
| `.planning/phases/191-page-flow-interaction-pass-fixture-stress-microcopy/191-01-SUMMARY.md` through `191-06-SUMMARY.md` | Plan-level implementation summaries. |

## Notes

- The `e2e:group-contracts` and `e2e:a11y` browser commands were initially launched in parallel and collided on the shared build directory lock. They were rerun serially; both passed.
- This ledger intentionally stores counts, command results, and artifact roots only. It does not commit browser traces or screenshots.
- Human operator approval passed on 2026-06-19; user confirmed the UAT worked and approved moving beyond the checkpoint.
