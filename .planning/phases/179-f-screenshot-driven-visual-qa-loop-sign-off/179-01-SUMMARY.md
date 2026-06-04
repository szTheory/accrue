---
phase: 179-f-screenshot-driven-visual-qa-loop-sign-off
plan: "01"
subsystem: accrue_admin/e2e
tags: [playwright, e2e, visual-qa, screenshot, npm]
dependency_graph:
  requires: [178-e-seed-expressiveness-state-coverage]
  provides: [21-screen-visual-sweep, score-visuals-harness]
  affects: [accrue_admin/e2e/admin-visuals.spec.js, accrue_admin/package.json]
tech_stack:
  added: ["@anthropic-ai/sdk ^0.100.1 (devDependency)"]
  patterns: ["multi-fixture seed without intermediate reset()", "21-entry shots[] with 3 merged fixture maps"]
key_files:
  modified:
    - accrue_admin/e2e/admin-visuals.spec.js
    - accrue_admin/package.json
    - accrue_admin/package-lock.json
decisions:
  - "Used PATTERNS.md corrected route slugs verbatim: /billing/payments (not /charges), /billing/connect (not /connect-accounts), /billing/analytics/recovery/subscriptions/:id (not /campaigns/:id)"
  - "No intermediate reset() between fixture calls — System.unique_integer processor IDs ensure accumulation safety"
  - "@anthropic-ai/sdk declared as devDependency only, never added to runtime Hex deps"
metrics:
  duration: "~5 minutes"
  completed: "2026-06-04"
  tasks: 2
  files_changed: 3
---

# Phase 179 Plan 01: Expand Visual Sweep 12→21 Screens + @anthropic-ai/sdk Summary

**One-liner:** 21-screen Playwright visual sweep using 3-fixture multi-seed (operator-flows + dashboard + edge-states) with corrected route slugs and @anthropic-ai/sdk devDep for scoring script.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Expand admin-visuals.spec.js to 21-screen multi-fixture sweep | 01644e90 | accrue_admin/e2e/admin-visuals.spec.js |
| 2 | Add @anthropic-ai/sdk devDependency and score-visuals npm script | c7cbfafe | accrue_admin/package.json, package-lock.json |

## What Was Built

### Task 1 — admin-visuals.spec.js (21 shots, 3 fixtures)

Replaced the single `seed("operator-flows")` + 12-entry `shots[]` with:

- Three sequential seed calls: `opFlows = await seed(request, "operator-flows")`, `dash = await seed(request, "dashboard")`, `edge = await seed(request, "edge-states")` — no intermediate `reset()` between them.
- 21-entry `shots[]` covering all index pages plus all detail pages:
  - dashboard, customers, customer-detail, subscriptions, subscription-detail
  - invoices, invoice-detail, payments, charge-detail
  - coupons, coupon-detail, promotion-codes, promo-code-detail
  - connect, connect-detail, events, event-detail
  - webhooks, webhook-detail, recovery, campaign-detail

All four helper functions (reset, seed, login, captureThemes) and the `test.describe`/`beforeEach` wrapper retained verbatim. The desktop+mobile Playwright projects give {desktop, mobile} cells; data-theme toggle gives {light, dark} — 4 cells total (21 screens × 4 = 84 screenshots per full run).

### Task 2 — package.json + package-lock.json

- Added `"@anthropic-ai/sdk": "^0.100.1"` to `devDependencies` (e2e/dev tooling, never in Hex runtime deps)
- Added `"score-visuals": "node e2e/score-visuals.mjs"` to `scripts`
- `npm install` completed: 7 packages added, 0 vulnerabilities; package-lock.json updated

## Verification Results

| Check | Result |
|-------|--------|
| `npx playwright test --list` shows 2 entries (desktop + mobile) | PASS |
| shots[] count = 21 | PASS |
| `/billing/payments` appears twice (list + detail) | PASS |
| `/billing/connect-accounts` count = 0 | PASS |
| `/billing/charges` count = 0 | PASS |
| No `/campaigns/` in route slugs (comment only) | PASS |
| `@anthropic-ai/sdk` in devDependencies | PASS |
| `score-visuals` script in package.json | PASS |
| `mix test --seed 0` = 262 tests, 0 failures | PASS |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — this plan adds e2e tooling; no UI stubs introduced.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| T-179-01 mitigated | accrue_admin/package.json | @anthropic-ai/sdk 0.100.1 verified via Package Legitimacy Audit (Anthropic official, no postinstall script); devDependency only |

## Self-Check: PASSED

- [x] accrue_admin/e2e/admin-visuals.spec.js — modified and committed at 01644e90
- [x] accrue_admin/package.json — modified and committed at c7cbfafe
- [x] accrue_admin/package-lock.json — updated and committed at c7cbfafe
- [x] 01644e90 confirmed in git log
- [x] c7cbfafe confirmed in git log
- [x] 262 tests, 0 failures (regression check passed)
