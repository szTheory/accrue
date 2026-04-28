---
phase: 091-pre-publish-prep
plan: 01
subsystem: docs
tags: [release, changelog, cadence]

key-files:
  modified:
    - accrue/CHANGELOG.md
    - accrue_admin/CHANGELOG.md
    - RELEASING.md
    - accrue/guides/maturity-and-maintenance.md
    - accrue/guides/upgrade.md

requirements-completed: [REL-06, REL-07]
---

# Phase 91 Plan 01: Stable changelog preload and post-1.0 cadence contract

## Accomplishments

- Added the locked `**1.0.0 — Stable.**` preambles to both package changelogs under `## Unreleased`.
- Replaced the pre-1.0 release runbook framing with `## Post-1.0 cadence (maintainer intent)`.
- Renamed the routine release section to `## Routine linked releases (Release Please + Hex)`.
- Updated the maintainer guides so the supported-surface and upgrade docs point at the post-1.0 cadence contract.

## Task Commits

1. **Task 1: Add the locked REL-06 changelog preambles** — `7cf363c`
2. **Task 2: Replace the pre-1.0 release runbook with the post-1.0 cadence contract** — `7cf363c`

**Plan metadata:** `7cf363c` (`docs(091-01): preload stable changelog and cadence contract`)

## Verification

- `rg -Fq '**1.0.0 — Stable.** This release commits Accrue to v1.x API stability' accrue/CHANGELOG.md`
- `rg -Fq '**1.0.0 — Stable.** Released in lockstep with \`accrue\` 1.0.0.' accrue_admin/CHANGELOG.md`
- `! rg -n '^## 1\.0\.0' accrue/CHANGELOG.md accrue_admin/CHANGELOG.md`
- `rg -Fq '## Post-1.0 cadence (maintainer intent)' RELEASING.md`
- `rg -Fq '## Routine linked releases (Release Please + Hex)' RELEASING.md`
- `rg -Fq 'critical security fixes are forward-ported to the latest minor of the previous major for 6 months' RELEASING.md`
- `rg -Fq '1.0.x minor' accrue/guides/maturity-and-maintenance.md`
- `rg -Fq '#post-1-0-cadence-maintainer-intent' accrue/guides/upgrade.md`

## Deviations from Plan

- The two plan tasks landed in a single commit (`7cf363c`) instead of one commit per task. The file boundaries and verifications still match the plan exactly.

## Issues Encountered

None.

## Self-Check: PASSED
