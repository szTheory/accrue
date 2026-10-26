---
phase: 249-local-gate-parity-planning-truth
plan: "10"
subsystem: planning-truth-ledger
status: complete
completed: 2026-10-24
requirements-completed: [GREEN-01]
tags: [windows-ledger, sl-a, d-16, waivers]
key-files:
  modified:
    - .planning/WINDOWS.md
key-decisions:
  - "A1: rows 20,28,29,30,37,38 marked fixed only after re-running their proofs green; rows 15-19,36 waived with owner/cause/release-impact reasons"
  - "All dispositions written via gsd-tools windows fixed|waive; table never hand-edited"
commits: 2
plan_head_before: bf3b16ec
plan_head_after: a81aac20
actuals:
  tokens: 20000
  tasks: 2
  commits: 2
coverage:
  - id: C20
    description: Row 20 (Portal origin / org shared-billing route) fixed; portal suite green
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "cd accrue_portal && mix test --warnings-as-errors (111 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: C28
    description: Row 28 (charge_live return destination) fixed
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/coupons_live_test.exs (72 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: C29
    description: Row 29 (confirmation controls disabled/loading) fixed
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs (in the 72-test run, 0 failures)"
        status: pass
    human_judgment: false
  - id: C30
    description: Row 30 (copy_strings.json) fixed; regenerated output byte-identical to committed file
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "mix accrue_admin.export_copy_strings --out $t/copy_strings.json && cmp $t/copy_strings.json examples/accrue_host/e2e/generated/copy_strings.json (identical, 123 strings)"
        status: pass
    human_judgment: false
  - id: C37
    description: Row 37 (coupon q URLs keep Valid selection) fixed
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "cd accrue_admin && mix test test/accrue_admin/live/coupons_live_test.exs (in the 72-test run, 0 failures)"
        status: pass
    human_judgment: false
  - id: C38
    description: Row 38 (time_display.js rejects impossible ISO) fixed
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "node --test accrue_admin/test/js/time_display_test.mjs (8 pass, 0 fail)"
        status: pass
    human_judgment: false
  - id: SL-A
    description: open_count is 0 and the PR claims contract passes
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "python3 249-replay-ci-job.py --job docs-contracts-shift-left --run --only 'PR claims contract' (PASS 04)"
        status: pass
    human_judgment: false
  - id: D16
    description: Scoped D-16 join and window triad pass
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "replay --only 'Committed window dispositions' --only 'Window dispositions triad' (PASS 39, PASS 40; TOTALS PASS=3)"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 10: Window ledger dispositioned Summary

All 12 open ship-window rows are dispositioned: 6 fixed after green re-proof, 6 waived with owner, cause and release impact. The ledger now reads `open_count: 0` (waived 12, fixed 26, total 38), and the SL-A and D-16 steps pass.

## Deviations from Plan

None. Every proving command passed on the first run, so no row was demoted to a waiver. Row 30 needed no regeneration because the committed `copy_strings.json` already matched.

## Notes

- The replay tool's `--only` filter also surfaced two unrelated steps as UNRESOLVED (SL-F needs `GITHUB_TOKEN`, step 11 needs `RELEASE_PLEASE_PR`). They are environment-gated and outside this plan's scope.
- Row 20 has no file path in the ledger. I proved it with the full `accrue_portal` suite, as the plan specified.

## Known Stubs

None.

## Self-Check: PASSED

Commits 4d123e2f and a81aac20 are in the branch history. `open_count: 0` appears once in WINDOWS.md.
