---
phase: 241-billing-operator-journeys
plan: "07"
subsystem: billing-ui
tags: [playwright, phoenix-liveview, browser-accessibility, asset-provenance]

requires:
  - phase: 241-01
    provides: Subscription invoice destinations and current owner scope
  - phase: 241-02
    provides: Validated invoice return destinations and supported list filters
  - phase: 241-03
    provides: Payment, customer, and subscription contextual returns
  - phase: 241-04
    provides: Recovery windows and scoped campaign returns
  - phase: 241-05
    provides: Subscription action review facts and busy controls
  - phase: 241-06
    provides: Refund and payment-method action reviews
provides:
  - Package browser evidence for current customer-open-invoice membership and customer invoice-tab return
  - Reconnect assertion waits for the established offline state before checking locked controls
  - Mounted host proof for the selected Recovery window, scoped campaign return, and package-served assets
affects: [243]

tech-stack:
  added: []
  patterns:
    - Keep billing journey coverage in the existing package and mounted-host Playwright owners.
    - Compare package, compiled-host, HTTP-served, and browser-request asset bytes by SHA-256.
    - Keep Admin /admin and customer Portal /billing assertions separate.

key-files:
  created: []
  modified:
    - accrue_admin/e2e/admin-page-flow-phase191.spec.js
    - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
    - examples/accrue_host/e2e/phase237-admin-billing.spec.js

key-decisions:
  - "Build package assets once before the package browser runs; their checked-in CSS and JS bytes were already current and remained unchanged."
  - "Use a 7-day Recovery selection to prove window preservation through the campaign detail and return."
  - "Keep mounted host asset provenance and Portal separation in the existing Phase 237 host spec."

requirements-completed: [JRN-01, JRN-02, JRN-03, JRN-04]

actuals:
  tokens: 2378
  tasks: 2
  commits: 2

commits: 2
plan_head_before: d207426353ceb55cfe33ad051550292321601887
plan_head_after: 5b33e9c24846639397ad2d73710e4ed0889884a1

metrics:
  duration: 48 min
  completed: 2026-10-10
  tasks: 2
  files: 3
status: complete
---

# Phase 241 Plan 07: Mounted Billing Journey Proof Summary

**The package and host browser owners now verify customer-scoped invoice navigation, contextual returns, Recovery window preservation, current served assets, and Admin/Portal separation.**

## Performance

- **Duration:** 48 min
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Built accrue_admin assets before fresh-server package browser runs. The build completed successfully; generated CSS and JS matched their checked-in bytes, so neither tracked asset required a diff.
- Added a package browser journey that clicks the subscription customer-open-invoice destination, checks the customer and open-status filters, confirms the exact single invoice ID, then opens that invoice from the customer invoice tab and returns to the same customer/tab.
- Made the incumbent offline-action check wait for the visible LiveView connection-loss state before asserting that the action is disabled.
- Extended the mounted-host browser owner to click a 7-day Recovery campaign, verify owner and window on the return destination, and return to the same scoped window. The host test also checks /admin Admin separately from /billing customer Portal.
- Added the changed billing route sources to host provenance. The assertAssetBytes seam matched package, compiled-host, HTTP-served, and browser-request SHA-256 values for CSS, JS, Geist Sans, and Geist Mono.

## Verification

| Owner | Result |
|---|---|
| CI=1 npm --prefix accrue_admin run e2e:phase191 | 26 passed |
| CI=1 npm --prefix accrue_admin run e2e:phase199 | 23 passed; 15 incumbent project-specific skips |
| MIX_ENV=test mix compile --warnings-as-errors in accrue_admin | Passed |
| MIX_ENV=test mix test in accrue_admin | 642 passed, 0 failures |
| MIX_ENV=test mix compile --warnings-as-errors in examples/accrue_host | Passed |
| CI=1 npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop --workers=1 | 1 passed |

The new Phase 241 invoice journey ran in both package projects and passed in both. The 15 phase199 skips come from existing desktop-only test guards on the mobile project; no newly added test was skipped and all owner commands selected a positive test count.

Package CSS input digests were app.css fba4273889fbf4da70175e5570c7bf0d5a54b911feff22b946f2fc529fb0af9f and theme.css 079ec99553c73c2df07b6212c1bf9eba18645363e278c3fd7d01374990d1c90e. Package JS input app.js was 6b11d62588e4af92b858035121874d1b510aff6e43519e7c8d7198f6af526dae. Built CSS 4b971b0b94e08ee1bb62d47c4142be59ec270daf79e2bad4af73e746d9bb478f and JS c852628a1ab87ba56d8e72153c972d8ce85e6421066b0aef6f3368e6a8186d0a matched compiled and HTTP-served bytes. The host manifest source digest was 34ab002a34b8645aac0dc846c4809b6ba3fd88445f77a44bb75ec5b0d587bb48. Font hashes also matched across package, compiled host, and HTTP response: Geist Sans 28258d0621216948416a859d32487ab6ad1c9effa0d08795698e70be3c917630; Geist Mono 5bc6413e82be410dc057feccee55160495b999d0fe212b7b6c6499b29b8b1e4a.

The browser batch exercised direct 320px and intermediate/desktop layouts, dark/light/System theme behavior, reduced-motion styling, coarse-pointer hit geometry, and long-text wrapping. Effective OS theme changes were emulated by the existing package owner. Actual browser zoom controls, physical devices, assistive-technology speech, and live-provider outcomes were not observed; this execution did not run a separate 200% text-spacing or 400% zoom simulation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Wait for the connection-loss state before asserting disabled actions**
- **Found during:** Task 1
- **Issue:** An incumbent test asserted the refund control was disabled immediately after taking the browser offline, before LiveView had entered its reconnect state.
- **Fix:** Wait for the visible connection-loss announcement, then assert the control remains disabled after the browser emits online.
- **Files modified:** accrue_admin/e2e/admin-page-flow-phase191.spec.js
- **Verification:** Phase191 package browser owner passed (26 tests, 0 failures).
- **Commit:** e93406a1

**2. [Rule 3 - Blocking test issue] Align the host route check with Phase 241 return copy and selected owner**
- **Found during:** Task 2
- **Issue:** The host test expected the retired generic Back to results label. After checking the Portal in a separate session, the Admin host flow also needed to select its organization again.
- **Fix:** Assert Back to Recovery and restore the Admin organization context before continuing the Admin route proof.
- **Files modified:** examples/accrue_host/e2e/phase237-admin-billing.spec.js
- **Verification:** Phase237 mounted-host browser spec passed (1 test, 0 failures).
- **Commit:** 5b33e9c2

**3. [Rule 1 - Bug] Close the action menu before retaining the host subscription screenshot**
- **Found during:** Task 2 visual inspection
- **Issue:** The existing host flow left its action menu open at capture time.
- **Fix:** Dismiss the menu and assert that it is hidden before collecting the screenshot.
- **Files modified:** examples/accrue_host/e2e/phase237-admin-billing.spec.js
- **Verification:** Final Phase237 mounted-host browser spec passed (1 test, 0 failures).
- **Commit:** 5b33e9c2

No production route or trust-boundary changes were introduced. Built CSS/JS remained byte-identical to the checked-in package output.

## Coverage

- **JRN-01 — PASS:** The package browser confirms customer-wide open invoice filters and exact returned invoice membership from the subscription destination.
- **JRN-02 — PASS:** The package browser clicks the customer invoice detail and returns to the same customer invoice tab; owner integration tests remain in the invoice and scoped-path owners.
- **JRN-03 — PASS:** Existing package route flows and the host Recovery journey preserve their selected destination meaning and owner context.
- **JRN-04 — PASS:** Browser owners cover representative review, Escape/focus, held-busy/reconnect, and no-dispatch paths; the complete Admin suite includes exhaustive subscription and payment-method review owner tests.

All coverage uses automated evidence with human_judgment: false; no human UAT gate was introduced. Linux visual goldens remain owned by Phase 243.

## Self-Check: PASSED

- Both task commits are ancestors of HEAD; evaluation scope resolves exactly two plan commits.
- All three modified spec files exist and have no whitespace errors.
- Package and host compile/browser acceptance commands passed; full Admin suite passed with 642 tests and 0 failures.
- No new skip, zero-selected run, stub, TODO, FIXME, route, auth, or schema surface was introduced.

---
*Phase: 241-billing-operator-journeys*
*Completed: 2026-10-10*
