---
phase: 240
review: 240-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "Invoice review dismissal does not explain its non-mutating action"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "Invoice collection page repeats filter and result hierarchy"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Shared health snapshot uses unapproved typography weights"
open: 0
total: 3
recorded: 2026-10-09T23:39:32.081Z
---

# Phase 240: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | 240-REVIEW-FIX.md |
| WR-02 | warning | fixed | 240-REVIEW-FIX.md |
| WR-03 | warning | fixed | 240-REVIEW-FIX.md |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
