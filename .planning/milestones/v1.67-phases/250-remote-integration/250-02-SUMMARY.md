---
phase: 250-remote-integration
plan: "02"
subsystem: ci-root-cause-fixes
status: complete
completed: 2026-10-25
requirements-completed: []
tags: [ci, timezone, playwright, negative-control, d1, d2, d3]
key-files:
  created:
    - .planning/phases/250-remote-integration/250-INTEGRATION-PR.md
  modified:
    - accrue_admin/config/test.exs
    - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
    - accrue_admin/test/js/time_display_test.mjs
    - .github/workflows/ci.yml
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
key-decisions:
  - "D1: LAND-02/03 reworded; ratchet-parked and dispatch/push-only jobs are outside the PR bar"
  - "D2: accrue_events.inserted_at session-timezone dependence deferred as HIGH to v1.68; no migration"
  - "D3: 250-INTEGRATION-PR.md committed with the PR 49 marker; not published here"
plan_head_before: f0e6ab44ea3163b2d5d2973cb18ac5de85d153e7
plan_head_after: 9b68d1e7b3726a65cfed4ef58392dad4bedb6898
commits: 4
actuals:
  tokens: 14000
  tasks: 3
  commits: 4
coverage:
  - id: F1
    description: RecoveryLiveTest clock is ceiling plus 2s and the admin TestRepo pins UTC; honors PGPORT
    requirement: LAND-02
    verification:
      - kind: command
        ref: "cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs on a private America/New_York Postgres: 33 tests, 0 failures"
        status: pass
      - kind: command
        ref: "cd accrue_admin && mix test --warnings-as-errors on the same server: 746 tests, 0 failures; mix format --check-formatted"
        status: pass
      - kind: command
        ref: "negative control, pin only: 33 tests, 8 failures (file lines 73, 90, 106, 326, 374, 416, 846, 869)"
        status: pass
    human_judgment: false
  - id: F2
    description: docs job runs npm ci in examples/accrue_host before the D-32 step and caches both lockfiles
    requirement: LAND-02
    verification:
      - kind: command
        ref: "clean clone of the commit: after npm ci, node scripts/ci/verify_ci_script_contract.mjs --repo . --require-guard-coverage --require-non-vacuity --require-cohort-floor prints PASS"
        status: pass
      - kind: command
        ref: "negative control, clean clone without node_modules: prints FAIL naming test_accrue_host_preview_custody.mjs and test_accrue_host_proof_paths.mjs, rc 1"
        status: pass
    human_judgment: false
  - id: F3
    description: time_display_test.mjs pins process.env.TZ
    requirement: LAND-02
    verification:
      - kind: command
        ref: "TZ=UTC, America/New_York and Asia/Tokyo each: node --test accrue_admin/test/js/time_display_test.mjs # fail 0; cd accrue_admin && TZ=UTC node --test test/js/*.mjs # pass 69 fail 0"
        status: pass
      - kind: command
        ref: "negative control, pin absent under TZ=UTC: # fail 1"
        status: pass
    human_judgment: false
  - id: D1
    description: LAND-02/03 reworded per D1, D2 deferral recorded, PR 49 body file committed
    requirement: LAND-02
    verification:
      - kind: command
        ref: "bash scripts/ci/verify_roadmap_hygiene.sh; bash scripts/ci/verify_v1_17_friction_research_contract.sh; bash scripts/ci/verify_no_home_paths.sh --repo; node scripts/ci/verify_sensitive_token_census.mjs --repo . --census .planning/hygiene/sensitive-token-census.json --require-scope-lock --require-ratchet --require-no-cleartext"
        status: pass
    human_judgment: false
---

# Phase 250 Plan 02: Root-Cause Fixes Summary

Three CI reds measured at `23bee494` (RecoveryLiveTest timezone skew, D-32 cohort missing Playwright deps, time_display host-zone read) are fixed in separate commits, each with a recorded negative control; D1/D2/D3 are recorded in the planning docs. Nothing was pushed.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | 4a94f7b8 | fix(250-02): ceil RecoveryLiveTest clock and pin admin test PG timezone to UTC |
| 2a | f6e89e85 | ci(250-02): install host Playwright deps before the D-32 cohort |
| 2b | a3a14ed7 | test(250-02): pin time_display test timezone |
| 3 | 9b68d1e7 | docs(250-02): reword LAND-02/03 per D1, defer D2, add PR #49 body file |

## Negative controls

| Fix | Control | Result |
|-----|---------|--------|
| RecoveryLiveTest | baseline, unmodified, NY server | 33/0 (masking reproduced) |
| | pin only | 33 tests, 8 failures at lines 73, 90, 106, 326, 374, 416, 846, 869 |
| | pin plus fix; full admin suite | 33/0; 746 tests, 0 failures |
| D-32 | clean clone, no node_modules | FAIL naming the two host cohort files, rc 1 |
| | after `npm ci` | PASS (require-cohort-floor, require-guard-coverage, require-non-vacuity) |
| time_display | pin removed, TZ=UTC | # fail 1 |
| | pin, three zones | 8/8 each |

## Deviations from Plan

**1. [Rule 3 - Blocking] Private Postgres socket path.** The scratchpad path exceeds the 103-byte Unix socket limit, so the server would not start. It was started with `-k /tmp/pg250s` and TCP on 127.0.0.1:5439; data directory stayed under the scratchpad. Stopped afterwards. The initdb default locale also failed once; `--locale=en_US.UTF-8` fixed it.

**2. [Rule 3 - Blocking] `port:` key added to the TestRepo config** (planned step 2). CI leaves PGPORT unset, so it still uses 5432.

**3. Commit count.** `commits: 4` is measured at SUMMARY write time (base `f0e6ab44`); the SUMMARY and re-mint commits follow it.

## Known Stubs

None.

## Deferred

D2: `accrue_events.inserted_at` session-timezone dependence, HIGH, v1.68. No migration was written.
