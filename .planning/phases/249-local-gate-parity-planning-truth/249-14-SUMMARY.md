---
phase: 249-local-gate-parity-planning-truth
plan: "14"
subsystem: ci-local-replay
status: blocked
completed: 2026-10-24
requirements-completed: []
tags: [replay, host-integration, tokens, preview-custody]
key-files:
  created:
    - .planning/phases/249-local-gate-parity-planning-truth/249-REPLAY-HOST.md
  modified:
    - examples/accrue_host/config/test.exs
    - examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs
    - examples/accrue_host/test/accrue_host_web/phase239_route_coverage_contract_test.exs
    - examples/accrue_host/test/accrue_host_web/live/recovery_analytics_test.exs
    - examples/accrue_host/e2e/support/copy_dashboard.js
commits: 5
actuals:
  tasks: 1
  commits: 5
coverage:
  - id: C1
    description: tokens install, regenerate and determinism pass in a scratch clone with no tracked diff
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 249-replay-ci-job.py --job docs-contracts-shift-left --run --only 'Install tokens harness' --only 'Regenerate tokens' --only 'Tokens/specimens are reproducible' (PASS=3; git status --porcelain --untracked-files=no empty)"
        status: pass
    human_judgment: false
  - id: C2
    description: host-integration host mix test phases (bounded 64 tests, full 237 tests) pass in a fresh scratch clone
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 249-replay-ci-job.py --job host-integration --run --skip 'Install Hex' --skip 'Install Chromium' --env PGPORT=5439 ... (phase=bounded_mix_tests 64/0, phase=full_mix_tests 237/0)"
        status: pass
    human_judgment: false
  - id: C3
    description: host-integration end to end (dev-boot smoke, browser lane, hex smoke) passes
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "same host-integration replay; step 10 FAIL in phase=dev_boot_smoke at accrue_host_preview_custody.sh snapshot (docker compose exec, service db not running)"
        status: fail
    human_judgment: false
---

# Phase 249 Plan 14: Host replay Summary

Tokens determinism passes, and the host Elixir suites (64 bounded and 237 full tests) pass after five stale-contract fixes, but the host-integration lane is BLOCKED at the Phase 243 preview-custody gate, which needs the maintainer's Docker `accrue-host` preview stack. GREEN-05 is NOT claimed.

## What passed

- Task 1: tokens harness/regenerate/determinism in a scratch clone, tracked tree clean. `249-REPLAY-HOST.md` created with the routing section and an (intentionally empty) classified block; committed 0ceff6c8.
- Task 2 partial: after fixes, `phase=bounded_mix_tests` 64/0 and `phase=full_mix_tests` 237/0 at HEAD 596ebb1c in a fresh clone with real installs and a private Postgres (port 5439). Clone `git status --porcelain` was empty.

## Deviations from Plan

### Auto-fixed Issues (all committed in the live tree, re-proven in a fresh clone)

1. **[Rule 3 - Blocking] host test repo ignored PGPORT** (f29c20d6). Shared Postgres was at 79/100 connections; default 5432 preserved so CI is unchanged (same as 249-12).
2. **[Rule 1 - stale contract] admin_webhook_replay_test** (62795089): events list shows the shared label since 1cd93201; now asserts `Copy.billing_event_label/1`.
3. **[Rule 1 - stale contract] phase239 route ledger** (596ebb1c): host-owned Phase 246 sandbox fixture route `/admin/__phase246/states` is excluded from the frozen v1.63 package ledger comparison.
4. **[Rule 1 - stale contract] recovery_analytics_test** (596ebb1c): copy renamed by b4a7eeac (Unrecovered MRR, Payment recovery funnel, Subscriptions in retry).
5. **[Rule 1 - drift] copy_dashboard.js** (04b581c9): unused mirror synced to "Recent activity" (249-09 note).

### Blocker (Rule 4 candidate, NOT fixed)

`scripts/ci/accrue_host_preview_custody.sh` (Phase 243-02, de9e4d5d) snapshots the maintainer's Docker preview via `docker compose exec` before the dev-boot and browser phases. It fails when that stack is not running, and hosted CI has no such stack, so `host-integration` is probably red on GitHub too; the last non-scheduled ci.yml run (2026-09-18) predates the gate and scheduled runs skip the job. The dev-boot smoke, Playwright browser lane and `assert-preserved` remain unproven. Fixing needs a decision on the custody guard (no-op when no preview project exists / in CI, or explicit opt-out) and is not a silent weakening I should make. Recommend routing with host-docker-smoke to Phase 250 or a plan 249-18.

## Routing

host-docker-smoke is routed to Phase 250 by orchestrator decision (maintainer marks Docker volumes and images off-limits). No docker command was issued by the executor on purpose; one bare read-only `docker ps` was issued by mistake during diagnosis (output discarded). The custody scripts themselves issue read-only docker calls (volume ls, ps, compose config/exec).

## Known Stubs

None.

## State updates

Not performed: plan is not complete, so STATE/ROADMAP plan progress and requirements were left untouched.

## Self-Check: PASSED

Commits 0ceff6c8, f29c20d6, 04b581c9, 62795089, 596ebb1c exist on the branch; clones removed; scratch Postgres stopped; ports 4100/4101/5439 free.
