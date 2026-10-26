---
phase: 249-local-gate-parity-planning-truth
plan: "12"
subsystem: ci-local-replay
status: complete
completed: 2026-10-24
requirements-completed: [GREEN-02, GREEN-05]
tags: [replay, release-gate, dialyzer, docs, primary-cell]
key-files:
  modified:
    - .planning/phases/249-local-gate-parity-planning-truth/249-LOCAL-REPLAY.md
    - accrue_admin/lib/accrue_admin/live/customers_live.ex
    - accrue/config/test.exs
    - accrue/test/support/chimeway_test_support.ex
key-decisions:
  - "Dead `== \"queue\"` branch in customers_live removed rather than adding a dialyzer ignore; the OTP 28 exact_compare warning was a real unreachable comparison"
  - "Accrue test repos honor PGPORT (default 5432) so a replay can target an isolated Postgres; CI behavior unchanged"
commits: 3
plan_head_before: 6cc81ea4ac3cbb316225b3250cadef848b4c3003
plan_head_after: 945df5df522ba7b49532a785860f590784721ef7
actuals:
  tokens: 40000
  tasks: 2
  commits: 3
coverage:
  - id: C1
    description: accrue release-gate primary cell green (format, compile, test, credo --strict, dialyzer, docs, since-badges, retired audit)
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 249-replay-ci-job.py --job release-gate --run --skip 'Install Hex' --skip 'portal' --env MIX_ENV=test --env PGUSER=postgres --env PGPASSWORD=postgres --env PGHOST=localhost --env PGPORT=5439 --env ACCRUE_CI_SIGRA= --env ACCRUE_CI_OPENTELEMETRY= --env ACCRUE_OTEL_MATRIX=without_opentelemetry (PASS=19 SKIP=6)"
        status: pass
    human_judgment: false
  - id: C2
    description: accrue_admin release-gate primary cell green including compile, credo and dialyzer
    requirement: GREEN-02
    verification:
      - kind: command
        ref: "same release-gate replay command, accrue_admin steps 18-28 all PASS"
        status: pass
    human_judgment: false
  - id: C3
    description: accrue_portal release-gate steps green
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 249-replay-ci-job.py --job release-gate --run --only 'portal' <same env> (PASS=5)"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 12: Release-gate primary cell replay Summary

The release-gate primary cell (Elixir 1.19.5 / OTP 28, sigra and opentelemetry off) replays fully green for accrue, accrue_admin and accrue_portal, after two real reds were fixed at source.

## Reds found and fixed

1. **accrue_admin dialyzer crash.** dialyxir 1.4.7 threw `{:error, :unknown_warning, :exact_compare}`. Raw format showed the underlying OTP 28 finding at `customers_live.ex:161-162`: `empty_reason/2` returns only `"first-run"`, `"filter"` or `nil`, yet the template compared it to `"queue"`. The branch was unreachable, so it was removed (commit c3a9cad4). No ignore file touched.
2. **accrue test `too_many_connections`.** The shared local Postgres held about 76 of 100 connections for unrelated dev servers. The nested `mix test` in `LiveProofFormatterTest` (and once `ChimewayTest` ECOS-06) could not connect. The test repo configs ignored `PGPORT`, so the suite could not use an isolated server. Commit c359ed82 makes them read `PGPORT` (default 5432). The final run used a private scratch Postgres on port 5439; CI is unchanged.

## Deviations from Plan

- [Rule 3 - Blocking] Added `PGPORT` support to accrue test config (above). The plan's literal command used the shared server; the final replay adds `--env PGPORT=5439`.
- accrue_admin and accrue_portal test configs do not read `PGPORT`; they ran on the shared server and passed.
- Test runs used random seeds, with no retries and no pinned seed. The first runs failed, and each was fixed at source before the clean re-run.
- The plan's "hex.audit" step has no distinct step in the replayed job; the retired package audit steps cover it and passed.

## Known Stubs

None.

## Self-Check: PASSED

Commits c3a9cad4, c359ed82 and the ledger commit exist on the branch; the ledger holds the final tables.
