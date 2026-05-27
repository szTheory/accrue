---
phase: 143
plan: 01
subsystem: accrue
tags:
  - analytics
  - dunning
  - mrr
  - events
  - ecto
requires: []
provides:
  - Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1
  - MRR snapshot on dunning.recovered and dunning.exhausted event payloads
affects:
  - accrue/lib/accrue/webhook/default_handler.ex
tech_stack_added: []
tech_stack_patterns:
  - JSONB aggregation against accrue_events ledger
  - MRR snapshotted at emission time to avoid temporal data leakage
key_files_created:
  - accrue/lib/accrue/analytics/dunning.ex
  - accrue/test/accrue/analytics/dunning_test.exs
key_files_modified:
  - accrue/lib/accrue/webhook/default_handler.ex
key_decisions:
  - Snapshotted mrr_value_cents into the `data` jsonb payload at emission time so analytics never need to reconstruct historical pricing.
  - Aggregated MRR via Ecto JSONB `fragment("(?->>'mrr_value_cents')::integer", e.data)` against the existing `accrue_events` ledger — no new table.
  - Parameterized `:since`/`:until` window via Ecto `^` binding to mitigate T-143-01 (information disclosure / fragment SQL injection).
duration: ~
completed_date: 2026-05-27
---

# Phase 143 Plan 01: MRR Calculation & Dunning Analytics Context Summary

**Snapshotted MRR onto dunning lifecycle events and shipped the `Accrue.Analytics.Dunning` Ecto context that folds the `accrue_events` ledger into a flat recovered-vs-lost MRR map without adding new tables.**

## What shipped

- `Accrue.Webhook.DefaultHandler` now calls `calculate_mrr_cents/1` from Stripe's `data["items"]["data"]` and writes `mrr_value_cents` (plus `currency`) into the `Events.record/Events.record_multi` payload for both `dunning.exhausted` and `dunning.recovered` (default_handler.ex:780–907, calculate_mrr_cents at line 1896).
- `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` aggregates the two event types with a single `group_by` JSONB fragment query and returns `%{recovered_cents: int, lost_cents: int}` (`accrue/lib/accrue/analytics/dunning.ex`). Optional `:since` / `:until` `DateTime` window is applied via parameterized Ecto `where` clauses.
- Test coverage in `accrue/test/accrue/analytics/dunning_test.exs` (83 lines) exercises the aggregation and the windowing.

## Deviations from Plan

None functionally. SUMMARY.md was reconstructed retroactively (see Notes) — the production code in commit `57ce35b4` matches the plan exactly.

## Notes

This summary was written during a `/gsd-execute-phase 143` resume after the original executor committed the plan's source artifacts (commit `57ce35b4 feat(analytics): phase 143 - MRR calculation and dunning analytics context`) but did not write the SUMMARY file. The safe_resume_gate detected the missing SUMMARY against the existing commit and elected "close out manually" — verifying all three `files_modified` artifacts are present on disk before writing this file.

## Self-Check: PASSED

- `accrue/lib/accrue/analytics/dunning.ex` — present (73 LOC).
- `accrue/test/accrue/analytics/dunning_test.exs` — present (83 LOC).
- `accrue/lib/accrue/webhook/default_handler.ex` — `calculate_mrr_cents/1` defined and called from both `dunning.exhausted` and `dunning.recovered` emission paths, with `mrr_value_cents` written into the event `data` map.
- Commit `57ce35b4` covers all three files.
- Threat T-143-01 mitigated: `:since`/`:until` bound via Ecto `^` parameter, never interpolated into the fragment.
