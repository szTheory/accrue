---
phase: 249-local-gate-parity-planning-truth
plan: "15"
subsystem: ci-parity
tags: [playwright, custody, routing]
status: complete
completed: 2026-10-25
requirements-completed: [GREEN-05]
commits: 2
plan_head_before: b21850ecda4d0f9f40d1fd5f620610d2ac38cc14
plan_head_after: b888db7c
actuals:
  tokens: 3000
  tasks: 2
  commits: 2
coverage:
  - id: C1
    description: each playwright shard lists a non-zero test count in a scratch clone with real npm ci
    verification:
      - kind: command
        ref: "npx playwright test --list --shard=N/3 (N=1,2,3): 30, 25, 26 tests"
        status: pass
    human_judgment: false
  - id: C2
    description: custody absent-mode refuses when a preview exists (flag set + preview present)
    verification:
      - kind: command
        ref: "node --test scripts/ci/test_accrue_host_preview_custody.mjs (28/28, incl. absent-mode refuses when a labelled preview volume exists); script unchanged since 84f78f40"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 15: Playwright shard routing Summary

The full playwright-e2e shards 1-3 (including shard-1 conditional lanes and Braintree steps) are routed to Phase 250 remote CI on the integration head. Locally each shard lists a positive test count (30/25/26), proving the lane is non-vacuous. The listing proves non-vacuity only, not that the tests pass.

## Deviations from Plan

**[Task 2 verify adapted]** The classifier denied the live `ACCRUE_HOST_CUSTODY_CI_ABSENT=1 ... preflight browser` run. Per orchestrator ruling, the recorded 249-18 real-run refusal (exit 2, `CI absent-mode found a accrue-host preview instance (10 volumes, 0 containers)`) is substituted. The script is byte-unchanged since 84f78f40, so it applies to these bytes. The repeatable control is the custody node test suite (28/28), which includes the flag-set + preview-present refusal. The verify can still fail: it asserts the unchanged-since check, the named passing test, and the verbatim cited line.

## Known Stubs

None.
