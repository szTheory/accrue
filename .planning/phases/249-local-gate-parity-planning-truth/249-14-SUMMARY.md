---
phase: 249-local-gate-parity-planning-truth
plan: "14"
subsystem: ci-local-replay
status: complete
completed: 2026-10-25
requirements-completed: [GREEN-05]
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
  tasks: 2
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
    description: custody-bound host lanes recorded as routed to Phase 250 with the exact ledger lines
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "grep -qF the four 'Routed to Phase 250 (custody: no local preview DB; maintainer decision 2026-10-25)' lines in 249-REPLAY-HOST.md"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 14: Host replay Summary

Tokens determinism and the host mix phases (64 bounded, 237 full tests, 0 failures) are proven locally in fresh scratch clones with real installs and an empty clone status; the custody-bound host lanes and host-docker-smoke are routed to Phase 250 by the maintainer's 2026-10-25 preview-custody decision.

## What passed

- Task 1: tokens harness/regenerate/determinism in a scratch clone, tracked tree clean; `249-REPLAY-HOST.md` created (0ceff6c8).
- Task 2: `phase=bounded_mix_tests` 64 tests, 0 failures and `phase=full_mix_tests` 237 tests, 0 failures at 596ebb1c; clone `git status --porcelain` empty, so the classified-clone-changes block is intentionally empty. Ledger retitled and routing lines recorded.

## Fixes kept (host tests, all committed in the live tree)

| Commit | Fix |
|--------|-----|
| f29c20d6 | host test repo honors PGPORT (default 5432 keeps CI unchanged) |
| 62795089 | admin_webhook_replay_test asserts the shared event label |
| 596ebb1c | phase239 route ledger excludes the Phase 246 sandbox fixture route; recovery_analytics_test copy synced to b4a7eeac |
| 04b581c9 | copy_dashboard.js mirror synced to "Recent activity" |

## Routed to Phase 250

- host-integration dev-boot smoke, browser lane, assert-preserved step, and host Hex smoke: `Routed to Phase 250 (custody: no local preview DB; maintainer decision 2026-10-25)`. Their proof is the remote CI run on the integration head; 249-18 adds the absent-mode in the preview-custody guard that lets them run in hosted CI.
- host-docker-smoke: not run in Phase 249 (orchestrator decision; maintainer marks Docker volumes and images off-limits). No docker command was run by the plan.

## Deviations from Plan

### Earlier blocked run (honest record)

The first execution ended `status: blocked`. `scripts/ci/accrue_host_preview_custody.sh` (Phase 243-02, de9e4d5d) snapshots the maintainer's `accrue-host` Docker preview via `docker compose exec` before dev-boot and browser phases; it failed with `service "db" is not running`. Hosted CI has no such stack, so the gate was probably red on GitHub too (previously masked: the last non-scheduled ci.yml run predates it and scheduled runs skip the job). This was a Rule 4 candidate and was not weakened silently; the maintainer ruled on it (249-CONTEXT) and Task 2 was rewritten (59d44651). Also disclosed: one bare read-only `docker ps` was issued by mistake during diagnosis (output discarded).

### Auto-fixed Issues

The five fixes above: PGPORT [Rule 3], and four stale-contract/drift fixes [Rule 1].

## Known Stubs

None.

## Self-Check: PASSED

Commits 0ceff6c8, f29c20d6, 04b581c9, 62795089, 596ebb1c exist; clones removed.
