---
phase: 23-ecosystem-stability-and-demo-visuals
plan: "02"
subsystem: testing
tags: [playwright, e2e, documentation]
requirements-completed:
  - UX-DEMO-01
key-files:
  created: []
  modified: []
completed: 2026-04-20
---

# Phase 23 plan 02: demo visuals documentation

**Canonical Fake-backed screenshot path is already documented and scripted; no repo edits were required on re-verification.**

## Accomplishments

- Confirmed `examples/accrue_host/package.json` defines `e2e:visuals` as  
  `playwright test e2e/phase13-canonical-demo.spec.js --grep @phase15-trust` (matches plan must-have).
- Confirmed `examples/accrue_host/README.md` **Visual walkthrough (Fake-backed)** section documents:
  - Local PNG directory under `test-results/phase15-trust/<project>/`
  - Optional HTML report via `npx playwright show-report`
  - CI artifact name **`accrue-host-phase15-screenshots`** and workflow reference
  - One-command `npm run e2e:visuals` after `npm ci` / `npm run e2e:install`
- Confirmed repository root `README.md` already links to the same section (`#visual-walkthrough-fake-backed`) for maintainers.

## Self-Check: PASSED

- [x] README contract for paths, report, and CI artifact name — satisfied.
- [x] `npm run e2e:visuals` shortcut with `@phase15-trust` grep — satisfied.
