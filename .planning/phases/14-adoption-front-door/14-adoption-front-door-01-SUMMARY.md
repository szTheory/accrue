---
phase: 14-adoption-front-door
plan: 01
subsystem: docs
tags: [readme, docs-contract, elixir, exunit, adoption]
requires:
  - phase: 13-canonical-demo-tutorial
    provides: canonical host-first tutorial, demo labels, and package doc alignment
provides:
  - repository front door README with package map and validation mode labels
  - root README docs contract for public boundaries and route-map links
  - package landing pages aligned around the host-first tutorial order
affects: [README.md, accrue-docs, accrue_admin-docs, phase-14-adoption-front-door]
tech-stack:
  added: []
  patterns: [root-readme-as-route-map, public-boundary-docs-contract, host-first-package-landing-pages]
key-files:
  created:
    - README.md
    - accrue/test/accrue/docs/root_readme_test.exs
  modified:
    - accrue/README.md
    - accrue_admin/README.md
key-decisions:
  - "The root README stays a route map and proof strip, not a second tutorial."
  - "The stable first-time setup surface is repeated across the front door and package docs using only public host-owned boundaries."
  - "accrue_admin stays downstream of core billing and signed-webhook setup."
patterns-established:
  - "Repository-level docs should route to the canonical demo and First Hour guide instead of duplicating executable setup."
  - "New adoption-surface wording gets an ExUnit contract when it defines stable public boundaries."
requirements-completed: [ADOPT-01, ADOPT-02, ADOPT-05, ADOPT-06]
duration: 2min
completed: 2026-04-17
---

# Phase 14 Plan 01: Adoption Front Door Summary

**Root repository front door with a proof-backed package map, stable public setup boundaries, and downstream admin positioning**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-17T08:02:07Z
- **Completed:** 2026-04-17T08:04:17Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Created the root `README.md` as the repo front door that explains what Accrue is, where to start, and how Fake, Stripe test mode, and live Stripe differ.
- Added `root_readme_test.exs` to lock the front-door route map, public setup surface, and forbidden private-module wording.
- Tightened `accrue/README.md` and `accrue_admin/README.md` so both package landing pages route readers into the existing host-first tutorial order.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the repository front door contracts and align the package landing pages** - `94460ca` (`docs`)

**Plan metadata:** pending

## Files Created/Modified

- `README.md` - Root front door with package map, proof strip, stable boundaries, and Fake/test/live labels.
- `accrue/test/accrue/docs/root_readme_test.exs` - ExUnit contract for root README route-map links, public surfaces, and forbidden internals.
- `accrue/README.md` - Compact package landing page aligned to First Hour, testing, webhooks, upgrade, and the canonical local demo.
- `accrue_admin/README.md` - Admin landing page that clearly follows core billing and webhook setup instead of acting as the product entry point.

## Decisions Made

- The root README introduces the repository and sends executable setup back to `examples/accrue_host/README.md` and `accrue/guides/first_hour.md`.
- The supported first-time setup surface is limited to `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`, `AccrueAdmin.Router.accrue_admin/2`, `Accrue.Auth`, and `Accrue.ConfigError`.
- The admin package README now explicitly states that core billing and signed webhook setup come first.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 14-02 can add support intake on top of a stable front door and public-boundary message.
- Phase 14-03 can extend drift verification to release/support surfaces without revisiting the root README structure.

## Self-Check: PASSED

- Verified `.planning/phases/14-adoption-front-door/14-adoption-front-door-01-SUMMARY.md` exists.
- Verified task commit `94460ca` exists in git history.
