---
phase: 237-admin-invoices-payments-recovery
plan: "08"
subsystem: testing
tags: [playwright, phoenix-liveview, admin-billing, screenshots, ci]
requires:
  - phase: 237-04
    provides: scoped invoice collection and detail
  - phase: 237-05
    provides: staged invoice action review
  - phase: 237-06
    provides: charge and refund review contracts
  - phase: 237-07
    provides: recovery scope and return context
provides:
  - Read-only served browser coverage for invoice review and recovery navigation
  - Current-source screenshots and a SHA-256 evidence manifest
  - Confirmation that the existing blocking host Playwright job discovers the spec
affects: [admin-billing, phase-237-verification, host-playwright-ci]
actuals:
  tokens: 71062
  tasks: 2
  commits: 1
commits: 1
plan_head_before: e89fc4351058401e4f4860d48f8a7c1dc7a1b444
plan_head_after: 6d72e33d0e9d9c8656568dc6af4aba289c9ef75a
tech-stack:
  added: []
  patterns: [read-only served Playwright evidence, deterministic host recovery fixture]
key-files:
  created:
    - examples/accrue_host/e2e/phase237-admin-billing.spec.js
    - .planning/phases/237-admin-invoices-payments-recovery/captures/237-08/manifest.json
    - .planning/phases/237-admin-invoices-payments-recovery/captures/237-08/invoice-collection.png
    - .planning/phases/237-admin-invoices-payments-recovery/captures/237-08/invoice-review.png
    - .planning/phases/237-admin-invoices-payments-recovery/captures/237-08/recovery.png
  modified:
    - scripts/ci/accrue_host_seed_e2e.exs
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
    - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
key-decisions:
  - "Keep browser evidence read-only: stage and inspect payment review, then cancel without confirming or dispatching."
  - "Use the existing playwright-e2e lane and unrestricted Playwright discovery; no new CI lane is needed."
  - "Use Accrue.Clock for recovery UTC window bounds so campaign age and fixture time share one clock."
patterns-established:
  - "Browser manifests bind screenshots to source file hashes, served stylesheet bytes, routes, viewport, and theme."
requirements-completed: [ADM-02, ADM-05, ADM-06]
coverage:
  - id: D1
    description: "Served invoice collection and staged payment review are keyboard-accessible, scoped, responsive, and canceled before any billing mutation; recovery navigation preserves owner and window."
    requirement: ADM-05
    verification:
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase237-admin-billing.spec.js"
        status: pass
      - kind: automated_ui
        ref: ".planning/phases/237-admin-invoices-payments-recovery/captures/237-08/manifest.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "The focused Phase 237 browser spec is selected by the existing host Playwright configuration used by the blocking playwright-e2e CI job."
    verification:
      - kind: integration
        ref: "npx playwright test --list e2e/phase237-admin-billing.spec.js --project=chromium-desktop"
        status: pass
    human_judgment: false
  - id: D3
    description: "Recovery clock alignment and all Admin recovery LiveView contracts pass in the full package suite."
    verification:
      - kind: unit
        ref: "cd accrue_admin && mix test --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 16min
completed: 2026-10-09
status: complete
---

# Phase 237 Plan 08: Served Admin browser and CI proof Summary

**A read-only served browser journey now proves scoped invoice review, safe cancellation, and recovery return context, with hash-verified screenshots wired into the existing blocking Playwright lane.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-10-09T00:49:00Z
- **Completed:** 2026-10-09T01:05:25Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added a focused served Playwright journey covering invoice collection, staged payment review, cancellation, real foreign-owner denial, and recovery window → scoped record → return navigation.
- Captured current-source invoice collection, invoice review, and dark recovery screenshots. The manifest validates 8 source hashes and all 3 screenshot hashes/byte counts; it records `read_only: true` and `confirmed_or_dispatched: false`.
- Confirmed the existing `.github/workflows/ci.yml` `playwright-e2e` job runs unrestricted `npx playwright test --shard=...`, and Playwright lists this spec under the current host configuration.
- Added one deterministic recovery campaign to the existing host seed and its cleanup allowlist, keeping campaign timestamps on `Accrue.Clock`.

## Task Commits

1. **Task 1: Prove representative served Admin flows** - `6d72e33d` (`test(237-08): prove served admin billing journeys`)
2. **Task 2: Confirm recurring host CI discovery** - verification-only; CI discovery is captured in this summary and the final planning metadata commit.

## Files Created/Modified

- `examples/accrue_host/e2e/phase237-admin-billing.spec.js` - read-only route, review, keyboard, theme, responsive, denial, and current-asset proof.
- `.planning/phases/237-admin-invoices-payments-recovery/captures/237-08/` - three screenshots and their source/asset-bound manifest.
- `scripts/ci/accrue_host_seed_e2e.exs` - deterministic recovery campaign fixture and cleanup allowlist entry.
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` - recovery windows use the canonical Accrue clock.
- `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` - integration clock aligns with database timestamps and preserves UTC microsecond precision.
- `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css` - long customer identities wrap at narrow widths.

## Decisions Made

- The browser opens the supported payment review and cancels before confirmation; processor outcomes remain covered by the Fake-backed LiveView suites.
- The existing blocking CI job is the recurring verification lane; a separate job would duplicate its discovery and setup.
- Recovery screen windows use `Accrue.Clock.utc_now()` so the displayed campaign age and seeded campaign anchor agree under the deterministic host test clock.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Added a deterministic recovery campaign to the host seed**
- **Found during:** Task 1 (Prove representative served Admin flows)
- **Issue:** The existing host E2E seed had no organization-owned active recovery campaign, so the planned recovery record and return journey had no row to follow.
- **Fix:** Added an isolated past-due subscription and campaign-start event under the existing Admin E2E Alpha customer, and added its processor ID to the seed cleanup allowlist.
- **Files modified:** `scripts/ci/accrue_host_seed_e2e.exs`
- **Verification:** Served browser journey passed; screenshot shows one active campaign and “Past due 5 days.”
- **Committed in:** `6d72e33d`

**2. [Rule 1 - Bug] Aligned recovery windows with the canonical application clock**
- **Found during:** Task 1 (Prove representative served Admin flows)
- **Issue:** `RecoveryLive` bounded the selected window with wall-clock UTC while recovery campaign age used `Accrue.Clock`; the host test server's fixed clock made the campaign age and selected window disagree.
- **Fix:** Use `Accrue.Clock.utc_now()` for the 7/30/90-day window bounds and align recovery integration-test time with database timestamps, preserving required microsecond precision for inserted fixtures.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`, `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs`
- **Verification:** Recovery suite 27/27 and full `accrue_admin` suite 581/581 passed; served browser journey passed.
- **Committed in:** `6d72e33d`

**3. [Rule 1 - Bug] Wrapped long recovery customer identities on mobile**
- **Found during:** Task 1 (Prove representative served Admin flows)
- **Issue:** The in-memory long-identity responsive assertion exposed a narrow card label that could overflow at 320 CSS pixels.
- **Fix:** Added `overflow-wrap: anywhere` to the at-risk card identity heading and rebuilt the served stylesheet.
- **Files modified:** `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`
- **Verification:** Browser journey passed at 320 CSS pixels and the served stylesheet hash matched the built bundle.
- **Committed in:** `6d72e33d`

**Total deviations:** 3 auto-fixed (1 blocking seed fixture, 2 correctness/layout bugs)
**Impact on plan:** These changes made the specified recovery path executable and its clock/layout evidence truthful; CI topology and package dependencies remain unchanged.

## Verification Results

- `npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop` — 1 passed. Chromium required macOS Mach port access outside the sandbox; the permitted escalated rerun passed.
- `npx playwright test --list e2e/phase237-admin-billing.spec.js --project=chromium-desktop` — 1 test discovered.
- `.github/workflows/ci.yml` `playwright-e2e` runs `npx playwright test --shard=${{ matrix.shard }}/${{ strategy.job-total }}` with no spec exclusion; no workflow edit was needed.
- `cd accrue_admin && mix test --warnings-as-errors` — 581 tests, 0 failures.
- `git diff --check` — passed.
- Manifest revalidation — 8/8 source files and 3/3 screenshots match recorded SHA-256 and byte counts; `source_sha` matches recomputation.

## Issues Encountered

- The repository already had unrelated dirty configuration, Phase 233 screenshots, a Braintree test, and `.planning/milestone.lock`; these were preserved and not staged.
- The default npm cache was not writable in the sandbox. Asset compilation succeeded using a temporary cache under `/private/tmp`.
- No live-provider settlement was attempted or inferred; evidence is deterministic seeded host data.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

All Phase 237 plans now have automated verification evidence, and the existing host Playwright CI job covers the served journey. No confirmation-only UAT is required for this browser proof.

## Self-Check: PASSED

- Summary file exists at the required phase path.
- Task commit `6d72e33d` exists in the current history.
- Manifest source and screenshot hashes were recomputed with zero mismatches.

## Security Audit Follow-up (2026-10-09)

- Closed the audit gap for `T-237-19`: the host seed now creates a real invoice owned by the Beta organization, and the served browser journey requests that invoice under Alpha scope.
- The browser asserts the invoice ID and invoice number do not appear in Alpha’s collection or the restricted detail response; the UI shows the generic “Access restricted” message.
- Added seed cleanup coverage proving the Beta-owned invoice/customer is removed and recreated with correct ownership on rerun.
- Commit: `3de23b59` (`fix(237-08): verify denial against a real foreign invoice`).
- Verification after the fix commit: `npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop` — 1 passed. The payment review remained canceled before confirmation or dispatch.
- Security auditor retest is the remaining confirmation for this closure; no human UAT is required.
