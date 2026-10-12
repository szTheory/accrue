---
phase: 247-evidence-true-details-and-analytics
plan: "07"
subsystem: testing
tags: [phoenix, liveview, playwright, visual-proof, recovery]
requires:
  - phase: 247-06
    provides: Payment recovery metrics and detail surfaces for current-revision proof
provides:
  - Bounded ordinary and isolated held-out mounted proof for invoice action review, payment recovery, webhook detail, and replay review
  - Source, served asset, viewport, image digest, and human inspection validation for 16 full-resolution captures
affects: [phase-248-integrated-proof, phase-verification]
actuals:
  tokens: 771294
  tasks: 2
  commits: 11
tech-stack:
  added: []
  patterns: [dedicated Playwright configs per proof lane, source-and-asset-bound capture manifests]
key-files:
  created:
    - examples/accrue_host/e2e/phase247-current-proof.spec.js
    - examples/accrue_host/playwright.phase247-ordinary.config.js
    - scripts/ci/verify_phase247_render_proof.mjs
    - .planning/phases/247-evidence-true-details-and-analytics/captures/phase247-current-proof/manifest.json
    - .planning/phases/247-evidence-true-details-and-analytics/captures/phase247-current-proof/VISUAL-REVIEW.md
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/priv/static/accrue_admin.css
    - scripts/ci/seed_phase245_ordinary.sh
    - .planning/phases/247-evidence-true-details-and-analytics/247-VALIDATION.md
    - .planning/phases/247-evidence-true-details-and-analytics/247-COVERAGE.md
key-decisions:
  - "Use dedicated Phase247 ordinary and held-out Playwright configs because the referenced Phase246 config excludes Phase247 tests."
  - "Keep all six requirements pending phase-level verification; this plan records owning evidence without declaring the phase complete."
patterns-established:
  - "Mounted capture manifests bind each image to committed source, served JS/CSS, actual viewport, and individual visual inspection."
requirements-completed: []
coverage:
  - id: D1
    description: "Invoice action review and payment recovery are captured at wide and narrow viewports in light and dark themes."
    requirement: DETAIL-02
    verification:
      - kind: automated_ui
        ref: "captures/phase247-current-proof/manifest.json; verify_phase247_render_proof.mjs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Held-out populated webhook detail and replay review are captured without submitting replay."
    requirement: DETAIL-01
    verification:
      - kind: e2e
        ref: "phase247-current-proof.spec.js @phase247-current-heldout"
        status: pass
    human_judgment: false
  - id: D3
    description: "All 16 inspected images match the exact source SHA, served assets, requested viewport, and image digest."
    verification:
      - kind: automated_ui
        ref: "node scripts/ci/verify_phase247_render_proof.mjs --manifest captures/phase247-current-proof/manifest.json"
        status: pass
    human_judgment: false
  - id: D4
    description: "Recovery currency pair geometry and mobile page overflow are checked in the owning browser test."
    requirement: METRIC-01
    verification:
      - kind: e2e
        ref: "phase247-current-proof.spec.js recovery geometry assertions"
        status: pass
    human_judgment: false
  - id: D5
    description: "A visual reviewer confirms the representative evidence hierarchy and narrow layouts."
    verification:
      - kind: manual_procedural
        ref: "captures/phase247-current-proof/VISUAL-REVIEW.md"
        status: pass
    human_judgment: true
    rationale: "Visual hierarchy and readability require inspection of the original full-resolution images."
metrics:
  duration: "not reliably recorded across continuation"
  completed: "2026-10-11"
  status: complete
  commits: 11
  plan_head_before: 281d1b452d074c6a191e96adccbfe80b2511b526
  plan_head_after: 3ca1fca94306e67bf1ad82162dda476b35162df8
---

# Phase 247 Plan 07: Current-Revision Detail and Recovery Proof Summary

**Sixteen source- and asset-bound Playwright captures document representative detail and recovery states across both data lanes, viewport sizes, and themes.**

## Performance

- **Duration:** Not reliably recorded across continuation.
- **Completed:** 2026-10-11
- **Tasks:** 2
- **Files modified:** 31 files in the plan diff, including 16 binary screenshots.

## Accomplishments

- Added separate ordinary and held-out Playwright configs and one bounded current-revision proof owner for invoice action review, payment recovery, populated webhook detail, and replay review.
- Captured and individually inspected 16 full-resolution images across 1280×900 and 320×820, light and dark themes. The manifest validates exact source and served CSS/JS hashes, viewport, PNG dimensions, image hashes, and inspection metadata.
- Fixed demonstrated breadcrumb and recovery currency-pair layout defects; added geometry assertions for desktop pairs and mobile stacking. Updated the final validation and coverage ledgers.

## Task Commits

Task 1 proof harness and demonstrated corrections:

- `f7c64d41` add current detail and recovery render proof
- `a40c567d` restore webhook parent breadcrumb evidence
- `03d1002a` authenticate ordinary proof and capture narrow themes
- `98c1086b` bound held-out blocked-state lookup
- `e5e6eefd` keep proof metadata free of auth fields
- `b2fbe79f` preserve recovery KPI value wrapping
- `b4ede491` give recovery currency pairs readable width
- `a2a21d8b` preserve recovery KPI grid override
- `e2350299` assert recovery responsive grid geometry
- `60cbf063` match verifier coverage to scenario keys

Task 2 inspected captures and validation evidence: `3ca1fca9`.

Post-review corrective commits and confirmation:

- `306efe92` fix mobile time control, disclosures, naming and exact UTC conversion
- `9e7ab41b` verify time preference and disclosure interactions
- `f32feec4` place exact-copy probe on timestamp owner
- `ceef2047` target the outer payload disclosure
- `e65fedc6` clarify remaining payment recovery retry language
- `76cb2867` capture idle main focus state
- `4b121d69` capture neutral pointer state
- `a555c507` record post-review confirmation and dispositions

Initial verification gap-closure commits (additive evidence; the summary above records the original Plan 07 completion):

- `19a82faa` test recovery out-of-order completion and negative state claims; add populated isolated webhook payload/activity proof
- `dc5e89cd` wrap long raw payload values at narrow viewport widths
- `48a8d7fd` rebuild checked-in Admin assets for the narrow raw-payload fix

## Files Created/Modified

- `examples/accrue_host/e2e/phase247-current-proof.spec.js` — ordinary and held-out browser flows, viewport/theme matrix, responsive geometry assertions, and source/asset evidence.
- `examples/accrue_host/playwright.phase247-ordinary.config.js`, `examples/accrue_host/playwright.phase247.config.js` — dedicated bounded test selection for each lane.
- `scripts/ci/verify_phase247_render_proof.mjs` — strict source, served asset, viewport, image, and inspection validation.
- `captures/phase247-current-proof/` — 16 full-page images, manifest, and visual review.
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` and its focused test — corrected displayed parent breadcrumb evidence.
- `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css` — recovery currency pair sizing and responsive geometry.
- `scripts/ci/seed_phase245_ordinary.sh` — strict structured identity parsing for guarded local seed handling.
- `247-VALIDATION.md`, `247-COVERAGE.md` — execution status, commands, threat mapping, and fixture limits.

## Decisions Made

- The prescribed Phase246 Playwright config could not be reused because its test match excludes Phase247. Dedicated Phase247 configs preserve the separate ordinary/held-out evidence lanes.
- Requirements remain unmarked in this plan summary until the Phase247 phase verifier completes cross-plan verification.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added dedicated Phase247 Playwright configs.**
- **Found during:** Task 1.
- **Issue:** The plan's Phase246 config command excludes Phase247 tests, so its prescribed runner cannot execute the new owner.
- **Fix:** Added ordinary and held-out Phase247 configs with explicit test selection.
- **Verification:** Both configs list one owner test; ordinary and held-out runs each passed.
- **Committed in:** `f7c64d41`.

**2. [Rule 1 - Bug] Corrected webhook parent breadcrumb evidence and recovery currency-pair sizing.**
- **Found during:** Task 1, full suite and visual inspection.
- **Issue:** A parent breadcrumb used the wrong evidence, and long currency pairs needed enough inline room to keep mobile wrapping readable.
- **Fix:** Corrected the parent value and display width; added owning test assertions and rebuilt assets.
- **Verification:** `mix test --warnings-as-errors --seed 0` passed 727 tests; desktop/mobile geometry assertions passed; final captures were inspected.
- **Committed in:** `a40c567d`, `b4ede491`, `a2a21d8b`, `e2350299`.

**3. [Rule 3 - Blocking] Fixed the capture metadata verifier's coverage key lookup.**
- **Found during:** Task 2.
- **Issue:** The validator constructed duplicate lane prefixes when looking up expected scenario coverage.
- **Fix:** Match the expected scenario keys directly and rerun the strict validator.
- **Verification:** Validator accepted all 16 current source captures and matching served assets.
- **Committed in:** `60cbf063`.

**4. [Rule 3 - Blocking] Made guarded local seed identity parsing tolerate compile output while rejecting ambiguity.**
- **Found during:** Task 1.
- **Issue:** An ordinary host startup emitted a compile banner ahead of its structured database identity.
- **Fix:** Require exactly one structured host identity and compare the database IP against the expected fingerprint; reject wrong or duplicate identity records.
- **Verification:** Positive compile-chatter case passed, wrong identity and duplicate identity cases failed closed, Phase243 custody check passed.
- **Committed in:** `03d1002a`.

**Total deviations:** 4 auto-fixed. They address runner correctness, displayed evidence, demonstrated responsive behavior, and safe local fixture identity. No unrelated feature scope was added.

## Issues Encountered

- Initial ordinary lifecycle omitted `ACCRUE_HOST_SKIP_SEEDS=1`, seeding only the Phase245 ordinary host. The guarded seed wrapper subsequently ran with the skip flag and verified Phase243 remained untouched. This disposition is recorded in `247-VALIDATION.md`.
- The held-out fixture contains two dead webhook deliveries but no separate eligible blocked-detail state. The captured detail has empty Activity and raw payload evidence. These absent visual states are documented in the visual review and validation ledger.
- The ordinary build and test lifecycle used the explicit `accrue-host-phase245-ordinary.localhost` hostname. Port 4101 and the protected Phase243 host remained untouched.

## User Setup Required

None. Local Fake operator login used the repository README credential only in an unprinted temporary variable; no credential entered the manifest, images, logs, or committed artifacts.

## Next Phase Readiness

Current-revision evidence is ready for Phase248 integrated scenario selection and the Phase247 phase verifier. This plan does not declare Phase247 complete.

---
*Phase: 247-evidence-true-details-and-analytics*
*Completed: 2026-10-11*

## Self-Check: PASSED

- Required proof harness, validator, manifest, and visual review files exist.
- All 11 plan commits are ancestors of the current HEAD.
- Captured source SHA and served CSS/JS digests passed the manifest validator.
- Phase progress remains **In Progress** pending the phase verifier; no requirement IDs were marked complete here.

## Post-review Corrections

Applied bounded UI and UTC timestamp fixes in `306efe92`; proof assertions were tightened in `9e7ab41b`, `f32feec4`, `ceef2047`, `76cb2867`, and `4b121d69`; page-specific retry copy was corrected in `e65fedc6`. After the final product edit, focused owners passed 44/44, the Node time-display suite passed 7/7, and the full Admin suite passed 728/728. Assets were built once after product changes (CSS `63a5381be4cc47673e24b4c295e20381b57da06029680819625aff45f2f32b0c`; JS `d5364c9046af7e2f27a23deab81b2045cee87098852f50d66b6b8f6126537e32`). Harness-only edits did not change those assets. Final ordinary and held-out browser lanes each passed 1/1; all 16 final captures were individually inspected and the render-proof validator passed with source `4b121d6997ef5cde1a8a13aaf8b913aaaac87ea9`. Review dispositions are additive in `247-REVIEW-DISPOSITION.md` and `247-UI-REVIEW-DISPOSITION.md`. Phase 247 remains pending the phase verifier.
