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
  - Browser evidence for every eligible subscription and payment-method review variant
  - Executable text-enlargement and 400%-equivalent reflow evidence across changed billing consumers
  - Recovery table overflow containment through a named keyboard-focusable local scroll region
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
  created:
    - .planning/phases/241-billing-operator-journeys/evidence/phase237-exemplar/manifest.json
    - .planning/phases/241-billing-operator-journeys/evidence/phase237-exemplar/invoice-review.png
    - .planning/phases/241-billing-operator-journeys/evidence/phase237-exemplar/invoice-collection.png
    - .planning/phases/241-billing-operator-journeys/evidence/phase237-exemplar/recovery.png
    - .planning/phases/241-billing-operator-journeys/evidence/phase237-exemplar/subscription-detail.png
    - .planning/phases/241-billing-operator-journeys/evidence/phase237-exemplar/subscription-detail-narrow.png
    - .planning/phases/241-billing-operator-journeys/241-UI-FIX.md
  modified:
    - accrue_admin/e2e/admin-page-flow-phase191.spec.js
    - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
    - accrue_admin/test/support/e2e_fixtures.ex
    - accrue_admin/test/support/e2e_plug.ex
    - accrue_admin/lib/accrue_admin/components/at_risk_table.ex
    - accrue_admin/test/accrue_admin/components/at_risk_table_test.exs
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - accrue_admin/priv/static/accrue_admin.css
    - examples/accrue_host/e2e/phase237-admin-billing.spec.js
    - examples/accrue_host/lib/accrue_host_web/router.ex
    - examples/accrue_host/lib/accrue_host_web/controllers/organization_scope_controller.ex

key-decisions:
  - "Rebuild the package CSS after the Recovery table overflow fix, then verify the compiled-host and HTTP-served bytes against the package output."
  - "Use a dedicated disposable review matrix to exercise all supported subscription and payment-method variants without changing shared route seeds."
  - "Measure 200% text enlargement by doubling snapshotted computed font sizes; simulate supported 400% reflow with a 320 CSS-pixel viewport."
  - "Keep the seven-column Recovery table keyboard-reachable in a labeled local scroll region under text and viewport stress."
  - "Use a 7-day Recovery selection to prove window preservation through the campaign detail and return."
  - "Keep mounted host asset provenance and Portal separation in the existing Phase 237 host spec."
  - "Close the Phase 241 subscription UI audit findings in e51f3e31 and record current captures, computed styles, and bounded verification results in 241-UI-FIX.md."

requirements-completed: [JRN-01, JRN-02, JRN-03, JRN-04]

coverage:
  - id: D1
    description: Package subscription navigation returns the exact customer-open invoice set, and opening an invoice from the customer tab returns to that same tab.
    requirement: JRN-01
    verification:
      - kind: browser
        ref: "accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js#@phase241 subscription open-invoice destination preserves customer scope and contextual return"
        status: pass
      - kind: browser-suite
        ref: "CI=1 npm run e2e:phase191 (28 passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: Contextual billing destinations preserve their return context, Recovery selection, and scoped campaign return.
    requirement: JRN-02
    verification:
      - kind: browser
        ref: "examples/accrue_host/e2e/phase237-admin-billing.spec.js#Phase 237 served invoice and recovery journeys stay scoped and read-only"
        status: pass
      - kind: browser
        ref: "accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js#@phase241 subscription open-invoice destination preserves customer scope and contextual return"
        status: pass
    human_judgment: false
  - id: D3
    description: Every eligible subscription action review, Resume review, and both payment-method action reviews opens in the browser and shows the exact selected record and consequence before dismissal.
    requirement: JRN-04
    verification:
      - kind: browser
        ref: "accrue_admin/e2e/admin-page-flow-phase191.spec.js#@phase241 every eligible subscription and payment-method review opens in the browser (10 subscription reviews; 2 payment-method reviews)"
        status: pass
      - kind: browser-suite
        ref: "CI=1 npm run e2e:phase191 (28 passed; new case not skipped)"
        status: pass
    human_judgment: false
  - id: D4
    description: Seven changed billing consumers retain reachable geometry with measured 2x text sizing plus WCAG text spacing and a 320 CSS-pixel viewport simulation of 400% zoom.
    requirement: JRN-03
    verification:
      - kind: browser
        ref: "accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js#@phase241 200% text, WCAG text spacing, and 400% reflow simulation keep changed billing consumers reachable"
        status: pass
      - kind: browser-suite
        ref: "CI=1 npm run e2e:phase199 (new stress case passed; 24 passed, 15 incumbent skips)"
        status: pass
    human_judgment: false
  - id: D5
    description: The Recovery at-risk table exposes its wide data as a named, keyboard-focusable local scroll region while keeping the page itself within the viewport.
    requirement: JRN-03
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/components/at_risk_table_test.exs#renders desktop table and mobile cards under the shared group contract"
        status: pass
      - kind: browser
        ref: "examples/accrue_host/e2e/phase237-admin-billing.spec.js (1 passed after host recompile)"
        status: pass
    human_judgment: false
  - id: D6
    description: Existing browser owners retain keyboard focus, reconnect and busy behavior, effective theme, responsive geometry, and mounted-host asset provenance across changed billing consumers.
    requirement: JRN-02
    verification:
      - kind: browser
        ref: "accrue_admin/e2e/admin-page-flow-phase191.spec.js#LiveView patch and reconnect states keep focus stable"
        status: pass
      - kind: browser
        ref: "accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js#System keeps one stored choice while effective colors follow OS through patch and reload"
        status: pass
      - kind: browser
        ref: "examples/accrue_host/e2e/phase237-admin-billing.spec.js#Phase 237 served invoice and recovery journeys stay scoped and read-only"
        status: pass
    human_judgment: false
  - id: D7
    description: A staged invoice review can be dismissed without invoking the Fake provider action callback, measured directly in the disposable host Ecto sandbox.
    requirement: JRN-04
    verification:
      - kind: browser
        ref: "examples/accrue_host/e2e/phase237-admin-billing.spec.js#Phase 237 served invoice and recovery journeys stay scoped and read-only (authoritative invoice_action count delta 0)"
        status: pass
    human_judgment: false

actuals:
  tokens: 79747
  tasks: 2
  commits: 7

commits: 7
plan_head_before: d207426353ceb55cfe33ad051550292321601887
plan_head_after: 1b902e9fa77446e56039f7214f451a182667c18c

metrics:
  duration: 228 min
  completed: 2026-10-10
  tasks: 2
  files: 8
status: complete
---

# Phase 241 Plan 07: Mounted Billing Journey Proof Summary

**The package and host browser owners now verify customer-scoped invoice navigation, contextual returns, Recovery window preservation, current served assets, and Admin/Portal separation.**

## Performance

- **Duration:** 66 min
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Built accrue_admin assets before package browser runs. Acceptance stress exposed a wide Recovery table expanding the document; added a labeled, keyboard-focusable local scroll region, rebuilt CSS, and recompiled the mounted host. Package, compiled-host, HTTP-served, and browser-request CSS hashes matched. JS remained byte-identical.
- Added a package browser journey that clicks the subscription customer-open-invoice destination, checks the customer and open-status filters, confirms the exact single invoice ID, then opens that invoice from the customer invoice tab and returns to the same customer/tab.
- Made the incumbent offline-action check wait for the visible LiveView connection-loss state before asserting that the action is disabled.
- Extended the mounted-host browser owner to click a 7-day Recovery campaign, verify owner and window on the return destination, and return to the same scoped window. The host test also checks /admin Admin separately from /billing customer Portal.
- Added the changed billing route sources to host provenance. The assertAssetBytes seam matched package, compiled-host, HTTP-served, and browser-request SHA-256 values for CSS, JS, Geist Sans, and Geist Mono.
- Added a disposable review-matrix fixture endpoint because the existing shared phase191/199 seeds did not contain both payment-method records and a scheduled-cancel subscription. The new case opens all nine eligible subscription mutation reviews, the eligible Resume review, and both payment-method reviews, then dismisses without dispatch.
- Added measured 2x computed text sizing with WCAG text-spacing overrides and a separate 320 CSS-pixel reflow simulation across subscription, invoice results/detail, payment detail, customer payment methods, Recovery list, and campaign detail.

## Verification

| Owner | Result |
|---|---|
| CI=1 npm run e2e:phase191 | 28 passed |
| CI=1 npm run e2e:phase199 | 24 passed; 15 incumbent skips; one incumbent Chromium launch timeout (isolated rerun: 1 passed) |
| Focused Phase241 text and reflow acceptance | 1 passed across 7 consumers |
| Focused Phase241 subscription/payment-method review acceptance | 1 passed; 10 subscription reviews and 2 payment-method reviews |
| MIX_ENV=test mix test test/accrue_admin/components/at_risk_table_test.exs | 6 passed |
| MIX_ENV=test mix compile --warnings-as-errors in accrue_admin | Passed |
| MIX_ENV=test mix compile --warnings-as-errors in examples/accrue_host | Passed |
| CI=1 npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop --workers=1 | 1 passed after CSS rebuild and host recompile |

The 15 Phase199 skips are incumbent project-specific skips; neither new acceptance test was skipped. The Phase199 owner command had one unrelated incumbent drawer test fail because Chromium launch exceeded 180 seconds; that same test passed when rerun alone. The Phase191 suite passed in full after correcting the new test's ambiguous summary-action locator.

Package CSS input digests are app.css 00b9435dbf82d8a383e5e4df0bde0f09de40f58071697b8b64033eb236694df7 and theme.css 079ec99553c73c2df07b6212c1bf9eba18645363e278c3fd7d01374990d1c90e. Package JS input app.js is 6b11d62588e4af92b858035121874d1b510aff6e43519e7c8d7198f6af526dae. Built CSS d2ca57e4aa4209fbd68ac2a87dbd630cc3028bb4e999c044424674f5d0c1593f and JS c852628a1ab87ba56d8e72153c972d8ce85e6421066b0aef6f3368e6a8186d0a matched compiled-host bytes; the Phase237 browser owner also verified HTTP-served and browser-request hashes. Font hashes matched across package, compiled host, and HTTP response: Geist Sans 28258d0621216948416a859d32487ab6ad1c9effa0d08795698e70be3c917630; Geist Mono 5bc6413e82be410dc057feccee55160495b999d0fe212b7b6c6499b29b8b1e4a.

The browser batch exercised direct 320px and intermediate/desktop layouts, dark/light/System theme behavior, reduced-motion styling, coarse-pointer hit geometry, and long-text wrapping. The new text stress case applies a measured 2x computed font size to each rendered element before applying WCAG-style line, letter, and word spacing. The 400% check is a supported viewport simulation: a 1280 CSS-pixel reference becomes a 320 CSS-pixel viewport. It does not operate the browser zoom control or represent a physical zoom session. Physical devices, assistive-technology speech, and live-provider outcomes were not observed; final Linux visual goldens remain owned by Phase 243.

The dedicated review fixture supports the browser acceptance without changing the shared Phase191/199 route seeds. The test targets the canonical action controls, checks exact review facts, and returns to the detail view without dispatching. The mounted host dismissal now compares authoritative Fake `invoice_action` call counts immediately before staging and after Escape; the observed count was 0→0. The Recovery table correction is limited to making its existing seven-column content scroll locally and keyboard-reachably when it exceeds the available width.

### Security acceptance follow-up

The host invoice review now reads `invoice_action` provider callback counts from an authenticated GET oracle mounted only when the existing SQL-sandbox test configuration is enabled; the controller also returns 404 when that runtime flag is off. On the disposable host fixture, the mounted spec measured `0` before review and `0` after Escape dismissal (`delta: 0`) and recorded both values in the capture manifest. This proves the staged/dismissed review did not dispatch through the Fake provider; it does not infer dispatch state from persisted rows or HTTP method observation. The browser runner passed 1/1 after sandbox launch permissions were granted.

Fresh Playwright output is preserved at `.planning/phases/241-billing-operator-journeys/evidence/phase237-exemplar/`; its manifest includes the authoritative count and hashes for the screenshots. The five Phase 240 capture outputs were confirmed clean before the browser run, then restored from HEAD after preserving these Phase 241 copies.

Follow-up commit: `a009148b` (`test(241-security): measure mounted review dispatches`).
Evidence commit: `f85e07cd` (`docs(241-security): preserve mounted host evidence`).

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

**4. [Rule 1 - Bug] Keep the wide Recovery table from expanding the browser page**
- **Found during:** Acceptance gap closure
- **Issue:** The seven-column at-risk table expanded the document beyond the viewport during the 2x text and spacing stress case.
- **Fix:** Put the existing table in a labeled, keyboard-focusable local horizontal scroll region and rebuild the package stylesheet.
- **Files modified:** accrue_admin/lib/accrue_admin/components/at_risk_table.ex, accrue_admin/assets/css/app.css, accrue_admin/priv/static/accrue_admin.css
- **Verification:** At-risk component test passed 6/6; Phase199 stress test passed; host compiled and Phase237 browser owner passed.
- **Commit:** 1b902e9f

**5. [Rule 3 - Blocking test issue] Add disposable fixtures for every eligible review variant**
- **Found during:** Acceptance gap closure
- **Issue:** Existing phase191/199 shared route seeds lacked a scheduled-cancel subscription and two distinct payment methods, so the browser could not open every supported review.
- **Fix:** Add a dedicated E2E-only review-matrix seed and route; keep existing shared route seeds unchanged. The test dismisses every review without dispatch.
- **Files modified:** accrue_admin/test/support/e2e_fixtures.ex, accrue_admin/test/support/e2e_plug.ex, accrue_admin/e2e/admin-page-flow-phase191.spec.js
- **Verification:** Focused browser test passed; Phase191 owner suite passed 28/28.
- **Commit:** 1b902e9f

**6. [Rule 1 - Bug] Target canonical subscription review controls in browser coverage**
- **Found during:** Phase191 owner confirmation
- **Issue:** The broad “Change plan” locator selected a summary control rather than the intended action-review button.
- **Fix:** Anchor the action labels to the canonical subscription action names.
- **Files modified:** accrue_admin/e2e/admin-page-flow-phase191.spec.js
- **Verification:** Focused browser test passed; Phase191 owner suite passed 28/28.
- **Commit:** 1b902e9f

No production route or trust-boundary changes were introduced. The follow-up adds only the authenticated, SQL-sandbox-gated test oracle described below. The rebuilt package CSS includes the Recovery table scroll-region rule; the generated JavaScript remained byte-identical.

## Coverage

- **JRN-01 — PASS:** The package browser confirms customer-wide open invoice filters and exact returned invoice membership from the subscription destination.
- **JRN-02 — PASS:** The package browser clicks the customer invoice detail and returns to the same customer invoice tab; owner integration tests remain in the invoice and scoped-path owners.
- **JRN-03 — PASS:** Existing package route flows and the host Recovery journey preserve their selected destination meaning and owner context.
- **JRN-04 — PASS:** Browser acceptance opens all nine active subscription action reviews, the eligible Resume review, and both payment-method reviews, checks the exact records/effects, then dismisses without dispatch.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: test_only_observability | `examples/accrue_host/lib/accrue_host_web/router.ex` | Authenticated Fake callback-count GET route is compiled into the existing SQL-sandbox host test router only; controller runtime-checks the same flag and returns 404 when disabled. |

All listed acceptance coverage uses automated evidence with human_judgment: false; no human UAT gate was introduced. Linux visual goldens remain owned by Phase 243. The executable-UAT generator validated the summary coverage entries but cannot produce `241-UAT.md` because the phase has no `241-VERIFICATION.md`; no verifier artifact was fabricated. Physical zoom controls, speech output, and live-provider outcomes remain limited as recorded above.

## Self-Check: PASSED

- All seven YAML coverage entries include executable verification references and `human_judgment: false`.
- Both new browser cases ran and passed; neither was skipped. Phase191 passed 28/28; Phase199 had 24 passes, 15 incumbent skips, and one incumbent launch timeout that passed in isolation.
- The at-risk component test passed 6/6, package assets rebuilt, host compiled, and the mounted-host browser owner passed 1/1.
- Physical zoom controls, assistive-technology speech, and live-provider outcomes remain outside this automated evidence; the 400% check is a documented 320 CSS-pixel viewport simulation.
- The summary coverage entries pass the validator's field checks, but the validator cannot generate its separate automated UAT artifact until a genuine `241-VERIFICATION.md` exists; no artifact was fabricated.
- Security follow-up host evidence measured the Fake invoice action callback at 0 before review and 0 after Escape dismissal; see `241-SECURITY-FIX.md`.

---
*Phase: 241-billing-operator-journeys*
*Completed: 2026-10-10*

## UI Audit Correction Batch

- **Commit:** `e51f3e31` (`fix(241-ui): close subscription audit findings`).
- Restored 24px/600 subscription title type and 4px summary/action spacing; kept the existing effective facts row rule and its wrap behavior.
- Replaced duplicated warning-styled recovery navigation in the no-campaign state with one scoped `ax-link`; retained the warning status and missing-fact wording.
- Added owning LiveView uniqueness coverage, mounted-host exact-link/computed-style checks, and synchronous Phase 241 2× text-size measurement to avoid LiveView root-swap races.
- Verification details, current desktop/narrow evidence, browser run results and limits: `241-UI-FIX.md`.
