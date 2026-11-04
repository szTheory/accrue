---
phase: 252
review: 252-REVIEW.md
titles: json
findings:
  - id: CR-03
    severity: critical
    disposition: fixed
    title: "Extra malformed prohibition entries are silently ignored"
  - id: CR-04
    severity: critical
    disposition: fixed
    title: "Plans 09/10 used for coverage are absent from the freshness snapshot"
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "Storybook theme check adds the missing application scope"
  - id: CR-02
    severity: critical
    disposition: fixed
    title: "Passing exit codes turn skipped required tests into passing evidence"
open: 0
total: 4
recorded: 2026-10-27T15:19:42.249Z
---

# Phase 252: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-03 | critical | fixed | 252-REVIEW-FIX.md |
| CR-04 | critical | fixed | 252-REVIEW-FIX.md |
| CR-01 | critical | fixed | 252-REVIEW-FIX.md (not in the current review) |
| CR-02 | critical | fixed | 252-REVIEW-FIX.md (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
