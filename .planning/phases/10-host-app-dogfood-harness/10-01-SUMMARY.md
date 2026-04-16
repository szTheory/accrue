---
phase: 10-host-app-dogfood-harness
plan: 01
subsystem: testing
tags: [phoenix, elixir, postgres, accrue, accrue_admin, host-app]
requires:
  - phase: v1.0
    provides: public Accrue and AccrueAdmin package surfaces
provides:
  - Phoenix host app scaffold at examples/accrue_host
  - Local path dependency wiring for accrue and accrue_admin
  - Host-owned Repo test config and Fake processor runtime defaults
affects: [phase-10, host-app, installer, ci, docs]
tech-stack:
  added: [phoenix-host-app]
  patterns: [generator-first-host-app, host-owned-accrue-config]
key-files:
  created:
    - examples/accrue_host/mix.exs
    - examples/accrue_host/config/test.exs
    - examples/accrue_host/config/runtime.exs
    - examples/accrue_host/lib/accrue_host/application.ex
    - examples/accrue_host/lib/accrue_host/repo.ex
  modified: []
key-decisions:
  - "Keep the generated Phoenix scaffold intact and only patch the host-owned Accrue boundaries needed for path deps and explicit test/runtime config."
  - "Pin the host app to Accrue.Processor.Fake plus an env-driven webhook signing secret default so later dogfood flows do not rely on private machine-local secrets."
patterns-established:
  - "Generator-first host app: create the example with phx.new and adapt it instead of hand-building a fixture."
  - "Host-owned Accrue wiring: the host app config owns Repo and runtime settings while using local sibling path deps."
requirements-completed: [HOST-01]
duration: 14min
completed: 2026-04-16
---

# Phase 10 Plan 01: Host App Dogfood Harness Summary

**Phoenix host app scaffold with sibling path deps, host-owned Repo wiring, and Fake-backed Accrue runtime defaults**

## Performance

- **Duration:** 14 min
- **Started:** 2026-04-16T16:28:00Z
- **Completed:** 2026-04-16T16:42:00Z
- **Tasks:** 1
- **Files modified:** 47

## Accomplishments
- Generated a real Phoenix app at `examples/accrue_host` as the visible host-app harness baseline.
- Wired `../../accrue` and `../../accrue_admin` as local path dependencies in the host Mix project.
- Added explicit host-owned test and runtime config for `AccrueHost.Repo`, `Accrue.Processor.Fake`, and webhook signing secrets.

## Task Commits

Each task was committed atomically:

1. **Task 1: Generate the Phoenix host app foundation with sibling path dependencies** - `a6bff58` (feat)

## Files Created/Modified
- `examples/accrue_host/mix.exs` - host Phoenix Mix project with local sibling deps
- `examples/accrue_host/config/test.exs` - test Repo defaults and Accrue Fake processor wiring
- `examples/accrue_host/config/runtime.exs` - runtime Fake processor and webhook secret defaults
- `examples/accrue_host/lib/accrue_host/application.ex` - generated host supervision tree
- `examples/accrue_host/lib/accrue_host/repo.ex` - host-owned Ecto Repo
- `examples/accrue_host/lib/accrue_host_web/endpoint.ex` - generated endpoint retained for later installer/auth/admin work

## Decisions Made
- Kept the Phoenix-generated app structure intact so later plans can dogfood public install/auth/admin flows on a normal host app.
- Left Repo ownership and Accrue runtime wiring in host config instead of borrowing any private fixture helpers or hidden state.

## Deviations from Plan

- Used `mix phx.new ... --install` during scaffold generation so the host app landed with a resolved `mix.lock` and could immediately pass the plan's `mix deps.get && mix compile` verification. The resulting scaffold still matches the required Phoenix host-app shape.

## Issues Encountered
None

## User Setup Required

None - no external service configuration required for this plan's compile gate.

## Next Phase Readiness
- `examples/accrue_host` now exists as the phase baseline for auth scaffolding in Plan 10-02.
- The host app already compiles against local `accrue` and `accrue_admin`, so later plans can focus on public integration boundaries rather than bootstrapping.

## Self-Check: PASSED
- Found `.planning/phases/10-host-app-dogfood-harness/10-01-SUMMARY.md`
- Found commit `a6bff58` in git history

---
*Phase: 10-host-app-dogfood-harness*
*Completed: 2026-04-16*
