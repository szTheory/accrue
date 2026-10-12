---
phase: 248-reproducible-scenarios-and-integrated-proof
plan: "01"
subsystem: testing
tags: [playwright, phoenix, rendered-proof, preview-custody]
requires:
  - phase: 245-rendered-baseline-and-realistic-preview
    provides: guarded ordinary preview and isolated test database custody
provides:
  - Documented explicit ordinary and held-out Admin scenario commands
  - Mounted Playwright proof for ordinary, empty, failed-webhook, and long-name states
  - Eight current inspected screenshots with source, served-asset, route, and image provenance
affects: [phase-248-plan-02, visual-verification, preview-custody]
actuals:
  tokens: 19219
  tasks: 2
  commits: 11
plan_head_before: 2d6aef9f6b2bc0705ae876b56070a908d5dba850
plan_head_after: b2817ebcffa44531f8ea726f85693addf87c0835
tech-stack:
  added: []
  patterns: [explicit Playwright lane selection, exact route/query verification, source and served-asset digest binding]
key-files:
  created:
    - examples/accrue_host/e2e/phase248-scenarios.spec.js
    - examples/accrue_host/e2e/phase248-heldout-setup.js
    - examples/accrue_host/playwright.phase248-ordinary.config.js
    - examples/accrue_host/playwright.phase248-heldout.config.js
    - scripts/ci/verify_phase248_render_proof.mjs
    - .planning/phases/248-reproducible-scenarios-and-integrated-proof/captures/phase248-current-proof/manifest.json
  modified:
    - examples/accrue_host/README.md
    - .planning/debug/phase248-ordinary-login.md
key-decisions:
  - "Keep the ordinary lane on the existing Phase 245 host; run exceptional scenarios only on the guarded 4102 test database."
  - "Use viewport-sized captures and require explicit full-size visual inspection metadata for every image."
patterns-established:
  - "Scenario routes and query parameters are verified exactly, with owner scope and read-only action checks."
  - "Capture manifests bind source files, served CSS/JS bytes, and image bytes to the tested revision."
requirements-completed: [DEMO-02]
coverage:
  - id: D1
    description: "Reviewers can explicitly select ordinary, empty, failed-webhook, and long-name boundary Admin states."
    requirement: DEMO-02
    verification:
      - kind: e2e
        ref: "Playwright ordinary lane: phase248-scenarios.spec.js @phase248-ordinary"
        status: pass
      - kind: e2e
        ref: "Playwright held-out lane: phase248-scenarios.spec.js @phase248-heldout"
        status: pass
    human_judgment: false
  - id: D2
    description: "Current rendered states are tied to inspected screenshots and exact source and served asset digests."
    requirement: PROOF-01
    verification:
      - kind: automated_ui
        ref: "scripts/ci/verify_phase248_render_proof.mjs --manifest .planning/phases/248-reproducible-scenarios-and-integrated-proof/captures/phase248-current-proof/manifest.json"
        status: pass
    human_judgment: true
    rationale: "The captures were individually inspected at original resolution; the full findings ledger remains Plan 02 work."
status: complete
---

# Phase 248 Plan 01: Reproducible Scenarios and Integrated Proof Summary

Four explicit Admin scenarios now have mounted browser checks and current, inspected render evidence. The ordinary invoice review stays on the existing Phase 245 preview; empty, failed-webhook, and long-name cases use the isolated held-out lane.

## Accomplishments

- Documented guarded scenario selection and kept the operator credential in process memory.
- Fixed ordinary login by anchoring the README credential match to the operator account and waiting for the CSRF-protected login request to complete before admin navigation.
- Added dedicated ordinary and held-out Playwright configurations, exact route/query and owner checks, true zero-record verification, a seeded existing long-name boundary fixture, and strict source/asset/image validation.
- Captured eight current viewport screenshots: wide/light and narrow/dark ordinary invoice review; wide/light and narrow/dark empty subscriptions; wide/dark and narrow/light failed webhook; wide/dark and narrow/light long-name boundary.
- Inspected all eight images individually at original resolution and recorded inspection notes and timestamps in the manifest.

## Verification

- Ordinary lane: `ACCRUE_HOST_ORDINARY_BASE_URL=http://accrue-host-phase245-ordinary.localhost/ PHASE248_PROOF_LANE=ordinary npm --prefix examples/accrue_host run e2e -- --config=playwright.phase248-ordinary.config.js e2e/phase248-scenarios.spec.js --project=chromium-desktop --grep @phase248-ordinary --workers=1` — 1 passed.
- Held-out lane: `ACCRUE_HOST_HELDOUT_BASE_URL=http://127.0.0.1:4102/ PHASE248_PROOF_LANE=heldout npm --prefix examples/accrue_host run e2e -- --config=playwright.phase248-heldout.config.js e2e/phase248-scenarios.spec.js --project=chromium-desktop --grep @phase248-heldout --workers=1` — 3 passed, ordinary test intentionally skipped.
- `node scripts/ci/verify_phase248_render_proof.mjs --manifest .planning/phases/248-reproducible-scenarios-and-integrated-proof/captures/phase248-current-proof/manifest.json` — validated all 8 inspected captures, current source revision, served CSS/JS bytes and hashes, and image digests.
- `node scripts/ci/test_accrue_host_preview_custody.mjs` — 13 passed.
- The separate ordinary-slice validator also passed for both ordinary captures.

The custody preflight's canonical Compose-target fingerprint reported its target stopped; a separate live process check showed the ordinary Phase 245 preview and protected Phase 243 preview were running. Both remained untouched throughout. The held-out browser server used native PostgreSQL test database `accrue_host_test` on port 4102 and exited after the run. No shared preview was restarted, reseeded, or stopped.

## Decisions Made

- Kept all exceptional fixture setup inside the held-out 4102 lane and reused the existing edge-state seed fixture.
- Used exact route query validation so owner selection, unfiltered collection state, and preserved return navigation are part of the evidence contract.
- Kept the payment/webhook action at review; no action was submitted.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Repaired ordinary operator login and login sequencing**
- **Found during:** Task 1
- **Issue:** A broad password regex matched beyond the operator README entry; admin navigation could race the CSRF login POST and miss its session cookie.
- **Fix:** Anchored the credential match to the exact operator entry and awaited the page request-context login response before navigation.
- **Files modified:** `examples/accrue_host/README.md`, `examples/accrue_host/e2e/phase248-scenarios.spec.js`, `.planning/debug/phase248-ordinary-login.md`
- **Verification:** Ordinary lane passed after the fix.
- **Committed in:** `929b140b`

**2. [Rule 1 - Bug] Tightened viewport framing and ordinary capture dimensions**
- **Found during:** Task 1 visual inspection
- **Issue:** Full-page screenshots extended beyond the fixed review drawer and did not prove the visible viewport state.
- **Fix:** Capture the viewport and verify its dimensions against the declared matrix.
- **Files modified:** `examples/accrue_host/e2e/phase248-scenarios.spec.js`, `scripts/ci/verify_phase248_render_proof.mjs`
- **Verification:** Both ordinary variants inspected and passed the proof validator.
- **Committed in:** `64c45e90`

**3. [Rule 1 - Bug] Corrected held-out lane skip, count parsing, and exact route checks**
- **Found during:** Task 2
- **Issue:** The ordinary test used an unavailable skip helper in the held-out lane, logger output preceded the empty count, and assertions needed to preserve owner/query identity.
- **Fix:** Use the test skip helper, parse a unique count marker and require exact route/query values and genuine unfiltered zero-record state.
- **Files modified:** `examples/accrue_host/e2e/phase248-scenarios.spec.js`, `scripts/ci/verify_phase248_render_proof.mjs`
- **Verification:** Held-out empty and failure scenarios passed; full manifest validation passed.
- **Committed in:** `4093555b`, `fd07509d`, `5806fd48`

**4. [Rule 2 - Missing critical fixture setup] Seeded the existing boundary fixture only in held-out setup**
- **Found during:** Task 2
- **Issue:** Existing test seed cleanup removed the edge-state customer needed to prove the boundary case.
- **Fix:** Chain the existing edge fixture seed in a setup guarded to the explicit held-out lane and port 4102.
- **Files modified:** `examples/accrue_host/e2e/phase248-heldout-setup.js`, `examples/accrue_host/playwright.phase248-heldout.config.js`
- **Verification:** The long-name boundary case passed in the complete held-out matrix.
- **Committed in:** `4093555b`

**5. [Rule 1 - Bug] Asserted boundary identity on the active detail page**
- **Found during:** Task 2 final matrix
- **Issue:** A locator for the list row was reused after navigation, although the detail view correctly displayed the long-name heading instead of the email.
- **Fix:** Keep the exact email check on the list row and assert the name against the current detail page.
- **Files modified:** `examples/accrue_host/e2e/phase248-scenarios.spec.js`
- **Verification:** Full held-out matrix passed.
- **Committed in:** `5548e3fd`

**Total deviations:** 5 auto-fixed. **Impact:** Each correction was required for reliable, isolated scenario selection or accurate evidence; no production scenario controls or unrelated product behavior were added.

## Issues Encountered

- The first complete held-out rerun caught a stale list-row locator after detail navigation. The test now checks the exact email before navigation and the long-name heading on detail; the subsequent full matrix passed.
- The Sigra failure-lockout UTC datetime exception remains recorded in the debug notes; no failed-password retries were made and no unrelated production change was introduced.
- Existing compiler warnings surfaced in the held-out build and were outside this plan's scope.

## Next Phase Readiness

Plan 01 scenario evidence is complete. Plan 02 still owns the canonical owner-finding to fix/disposition to executed-check ledger and final cross-phase acceptance trail; therefore PROOF-01 remains open at the phase level.

## Self-Check: PASSED

- Summary and all nine files in the current capture directory exist.
- All 11 measured plan commits are ancestors of the recorded plan head.
- Full manifest verification passed after the latest capture refresh.

---
*Phase: 248*
*Completed: 2026-10-11*

## Corrective proof addendum (2026-10-12)

Code-review warning WR-01 was addressed by commits `13729468` and `112d484d`. The mounted boundary assertion now compares the complete seeded Unicode value exactly. Per-viewport empty-state framing now scrolls and checks the heading and explanation after every resize. The final ordinary matrix passed 1/1 and held-out matrix passed 3/3 at harness source `112d484d729e0867a9e04ebc1ad133e2ba91cdcb`. Ten fresh images were individually inspected and recorded at that source. Original eight images and their source-`5548e3fd` manifest remain unchanged under `captures/phase248-initial-proof/`.

## Task Commits (corrective fixture lifecycle regression)

1. **Clean held-out edge fixture after browser setup and on partial seed failure** — `c95f89b7` (fix). The exact 13 host tests passed after cleanup; the held-out lifecycle contract passed 4/4. See `248-REGRESSION.md` for the failure, guarded deletion scope, and test evidence. This harness-only correction follows the ten inspected captures and does not change their recorded source fingerprints.
