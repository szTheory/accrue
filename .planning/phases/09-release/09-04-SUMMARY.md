---
phase: 09-release
plan: 04
subsystem: docs
tags: [exdoc, hexdocs, guides, webhook, upgrade, sigra]
requires:
  - phase: 09-release
    provides: README-first ExDoc wiring and release-doc warning gate
provides:
  - Sigra integration guide for the first-party auth adapter path
  - custom processor and PDF adapter extension guides
  - webhook safety and upgrade policy guides for v1.0 consumers
affects: [release docs, extension points, webhook operations, upgrade policy]
tech-stack:
  added: []
  patterns: [placeholder-only docs snippets, README-first ExDoc extras, warnings-as-errors docs verification]
key-files:
  created: [accrue/guides/sigra_integration.md, accrue/guides/custom_processors.md, accrue/guides/custom_pdf_adapter.md, accrue/guides/webhook_gotchas.md, accrue/guides/upgrade.md]
  modified: []
key-decisions:
  - "Keep all extension and webhook examples at the documented behaviour/config boundary so the guides do not imply support for private internals."
  - "Use placeholder-only snippets for adapters and webhook configuration, with explicit warnings against committing real secrets or processor identifiers."
patterns-established:
  - "Guide-level extension docs should point to stable facade and behaviour modules, then verify flows through host-facing Accrue.Test or docs build commands."
  - "Webhook and upgrade guides should state security and compatibility rules directly instead of relying on implied repo conventions."
requirements-completed: [OSS-15, OSS-16]
duration: 5m
completed: 2026-04-16
---

# Phase 09 Plan 04: Accrue Guides Extensions Summary

**Release-grade extension, webhook, and upgrade guides covering Sigra auth wiring, custom adapter boundaries, replay-safe webhook setup, and the v1.x deprecation contract**

## Performance

- **Duration:** 5m
- **Started:** 2026-04-16T00:14:56Z
- **Completed:** 2026-04-16T00:18:19Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added the missing Sigra, custom processor, and custom PDF adapter guides with the exact public config and behaviour references required for release.
- Added a webhook gotchas guide that calls out raw-body ordering, mandatory signature verification, secret hygiene, current-object refetching, and replay-path discipline.
- Added an upgrade guide that anchors package consumers on per-package changelogs, a v1.x deprecation cycle, and warning-gated verification commands in consuming apps.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write the extension-point guides for Sigra, processors, and PDF adapters** - `7bb999d` (feat)
2. **Task 2: Write the webhook gotchas and upgrade guides** - `fd1993e` (feat)

## Files Created/Modified
- `accrue/guides/sigra_integration.md` - First-party Sigra adapter setup and audit-flow verification guide.
- `accrue/guides/custom_processors.md` - Behaviour-level custom processor contract, runtime wiring, and Fake-first testing guidance.
- `accrue/guides/custom_pdf_adapter.md` - Custom PDF adapter contract, runtime config, null-adapter fallback, and docs-gate verification guidance.
- `accrue/guides/webhook_gotchas.md` - Raw-body, signature, rotation, refetch, and replay/DLQ field guide.
- `accrue/guides/upgrade.md` - v1.0 baseline, deprecation-window, changelog, and consumer-side verification guide.

## Decisions Made
- Kept the new guides anchored on public behaviours and config keys so the release docs do not create unsupported stability promises around internal modules.
- Reused the Fake Processor and docs warning gate as the verification story for extension guides, rather than inventing new one-off testing surfaces.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The `accrue` guide map now covers the remaining release docs named in the roadmap and README surface.
- Later release work can rely on these guides when validating overall release readiness and public package polish.

## Self-Check: PASSED

- Found `.planning/phases/09-release/09-04-SUMMARY.md`
- Found `accrue/guides/sigra_integration.md`
- Found `accrue/guides/custom_processors.md`
- Found `accrue/guides/custom_pdf_adapter.md`
- Found `accrue/guides/webhook_gotchas.md`
- Found `accrue/guides/upgrade.md`
- Found commit `7bb999d`
- Found commit `fd1993e`
