---
phase: 166-adoption-dx-docs
plan: 01
subsystem: examples/accrue_host
tags: [docker, phoenix, config, docs-contract]
requires:
  - phase: 164-02
    provides: PGHOST-based Docker/native database selection
  - phase: 165-04
    provides: CI Docker smoke against localhost:4000
provides:
  - Docker-aware Phoenix dev endpoint bind
  - Local evidence for the README Docker browser contract precondition
affects: [examples/accrue_host, adoption-dx-docs]
tech-stack:
  added: []
  patterns:
    - PGHOST=db selects container-safe development behavior while native development stays loopback-bound.
key-files:
  created: []
  modified:
    - examples/accrue_host/config/dev.exs
key-decisions:
  - "Use the existing Compose PGHOST=db signal to bind the Phoenix dev endpoint to all interfaces only inside Docker."
patterns-established:
  - "Docker-specific dev behavior is selected from existing Compose environment, not extra evaluator setup."
requirements-completed: [DOC-02]
duration: 2 min
completed: 2026-06-02
---

# Phase 166 Plan 01: Docker Browser Endpoint Contract Summary

**Phoenix dev endpoint now binds through Docker Compose while native development remains loopback-only**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-02T07:38:55Z
- **Completed:** 2026-06-02T07:40:41Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added an `endpoint_ip` selector in `examples/accrue_host/config/dev.exs` using the existing `PGHOST=db` Compose signal.
- Preserved native Phoenix development on `{127, 0, 0, 1}` while allowing the Docker web service to listen on `{0, 0, 0, 0}` through the published `4000:4000` port.
- Verified the Docker Compose configuration and attempted the localhost browser smoke needed before Phase 166 makes Docker the primary evaluator path.

## Task Commits

Each task was committed atomically:

1. **Tasks 1-2: Make the dev endpoint bind Docker-aware and record smoke contract** - `130e9f3e` (fix)

**Plan metadata:** committed during closeout.

## Files Created/Modified

- `examples/accrue_host/config/dev.exs` - Selects `http: [ip: endpoint_ip]` from `PGHOST=db` for Docker or loopback for native development.

## Decisions Made

- Reused `PGHOST=db` rather than adding a new Docker-only environment variable, matching the existing Compose contract and Phase 164 database-host pattern.
- Did not change README text in this plan; the endpoint contract is now ready for the documentation waves.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The full Docker browser smoke was environment-blocked after image build: Docker could not bind `127.0.0.1:4000` because port `4000` was already allocated on the host. The command cleaned up with `docker compose down --volumes --remove-orphans`.
- `cd examples/accrue_host && docker compose config >/dev/null` passed.

## Verification

- `grep -Fq 'endpoint_ip = if System.get_env("PGHOST") == "db"' examples/accrue_host/config/dev.exs` -> passed
- `grep -Fq 'http: [ip: endpoint_ip]' examples/accrue_host/config/dev.exs` -> passed
- `cd examples/accrue_host && mix format config/dev.exs` -> passed
- `cd examples/accrue_host && docker compose config >/dev/null` -> passed
- Docker boot smoke -> blocked by host port `4000` already allocated

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 2 can safely make Docker the primary README evaluator path. The only unresolved item is local machine port availability for the optional smoke rerun; CI should exercise the clean Docker path.

## Self-Check: PASSED

---
*Phase: 166-adoption-dx-docs*
*Completed: 2026-06-02*
