---
phase: 41-host-metrics-wiring-cross-domain-example
plan: 02
subsystem: infra
tags: [telemetry, observability, obs-02, phoenix, guide]

requires:
  - phase: 41-01
    provides: Shared ops inventory and TEL-01 parity tests
provides:
  - Cross-domain subscription narrative in guides/telemetry.md
  - Example host with ++ defaults/0 and AccrueOpsTelemetry attach
affects: [41-03]

tech-stack:
  added: []
  patterns:
    - "GenServer attach-once + detach for :telemetry handler in example host"

key-files:
  created:
    - examples/accrue_host/lib/accrue_host/accrue_ops_telemetry.ex
  modified:
    - accrue/guides/telemetry.md
    - examples/accrue_host/lib/accrue_host_web/telemetry.ex
    - examples/accrue_host/lib/accrue_host/application.ex
    - examples/accrue_host/mix.exs
    - examples/accrue_host/README.md

key-decisions:
  - "Primary attach targets [:accrue, :ops, :webhook_dlq, :dead_lettered] per 41-RESEARCH"

patterns-established:
  - "Guide anchor Cross-domain host subscription ↔ AccrueHost.AccrueOpsTelemetry comment contract"

requirements-completed: [OBS-02]

duration: 18min
completed: 2026-04-21
---

# Phase 41: Host metrics wiring — Plan 02 Summary

**Shipped OBS-02: a public-API-only cross-domain section in `telemetry.md`, a matching supervised attach module in `examples/accrue_host`, and `metrics/0` now appends `Accrue.Telemetry.Metrics.defaults/0`.**

## Performance

- **Duration:** ~18 min
- **Tasks:** 3

## Accomplishments

- Replaced the ad-hoc cross-domain snippet with `## Cross-domain host subscription` (attach/4, catalog pointer, billing span caution, OTel-only escape hatch).
- Example host merges Accrue default metrics and starts `AccrueHost.AccrueOpsTelemetry` after `AccrueHostWeb.Telemetry`.
- README links maintainers to the guide anchor.

## Task Commits

1. **Task 1: Guide** — `ded6413` (docs)
2. **Task 2: Example host** — `5556604` (feat)
3. **Task 3: README** — `c8fe077` (docs)

## Verification

- `cd examples/accrue_host && mix compile` — PASS

## Self-Check: PASSED

## Issues Encountered

`mix deps.get` in the example app can block on interactive Git auth for optional deps; `mix compile` alone succeeded against the existing lockfile.

## Deviations

None.
