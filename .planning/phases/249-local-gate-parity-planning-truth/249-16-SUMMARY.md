---
phase: 249-local-gate-parity-planning-truth
plan: "16"
subsystem: ci-local-replay
status: complete
completed: 2026-10-25
requirements-completed: [GREEN-05]
tags: [replay, release-gate, matrix, floor, opentelemetry, sigra]
key-files:
  created:
    - .planning/phases/249-local-gate-parity-planning-truth/249-REPLAY-CELLS.md
key-decisions:
  - "Cells run in separate --no-local clones against a private Postgres on 5439, then clones and server removed"
commits: 1
plan_head_before: 87670b16456aa286421fd8dded28f1e4222772f5
plan_head_after: aadb612e
actuals:
  tokens: 15000
  tasks: 2
  commits: 1
coverage:
  - id: C1
    description: release-gate Floor cell (Elixir 1.19.0 / OTP 28, required) green
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "ASDF_ELIXIR_VERSION=1.19.0-otp-28 python3 249-replay-ci-job.py --job release-gate --run --skip 'Install Hex' --skip portal --env MIX_ENV=test --env PGUSER=postgres --env PGPASSWORD=postgres --env PGHOST=localhost --env PGPORT=5439 --env ACCRUE_CI_SIGRA= --env ACCRUE_CI_OPENTELEMETRY= --env ACCRUE_OTEL_MATRIX=without_opentelemetry (PASS=19 SKIP=6)"
        status: pass
    human_judgment: false
  - id: C2
    description: release-gate Primary+OpenTelemetry cell (required) green
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 249-replay-ci-job.py --job release-gate --run --skip 'Install Hex' --skip portal --env MIX_ENV=test --env PGUSER=postgres --env PGPASSWORD=postgres --env PGHOST=localhost --env PGPORT=5439 --env ACCRUE_CI_SIGRA= --env ACCRUE_CI_OPENTELEMETRY=1 --env ACCRUE_OTEL_MATRIX=with_opentelemetry (PASS=19 SKIP=6)"
        status: pass
    human_judgment: false
  - id: C3
    description: release-gate Sigra cell (advisory) green; recorded as advisory only
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 249-replay-ci-job.py --job release-gate --run --skip 'Install Hex' --skip portal --env MIX_ENV=test --env PGUSER=postgres --env PGPASSWORD=postgres --env PGHOST=localhost --env PGPORT=5439 --env ACCRUE_CI_SIGRA=1 --env ACCRUE_CI_OPENTELEMETRY= --env ACCRUE_OTEL_MATRIX=without_opentelemetry (PASS=19 SKIP=6)"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 16: Release-gate matrix cells Summary

Floor (1.19.0/OTP 28) and Primary+OpenTelemetry required cells pass in isolated scratch clones; the advisory Sigra cell also passes (`SIGRA: ADVISORY-PASS`).

## Results

See `249-REPLAY-CELLS.md`. Each cell: PASS=19 SKIP=6 (skips are Install Hex and the five accrue_portal steps, covered in 249-12). Clone `git status --porcelain` was empty for every cell, so there was no mix.lock or deps churn to classify.

## Deviations from Plan

None to code. One procedural note: the first Sigra attempt omitted the OpenTelemetry env vars (replay tool flagged them UNRESOLVED), so it was discarded and re-run with the exact CI env. No source fixes were needed. The private Postgres on 5439 followed 249-12; shared 5432 was avoided and not touched.

## Known Stubs

None.

## Self-Check: PASSED

- 249-REPLAY-CELLS.md exists; contains exactly one `SIGRA: ADVISORY-PASS` line.
- Commit aadb612e is in HEAD; clones and scratch Postgres removed.
