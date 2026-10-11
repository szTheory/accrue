---
phase: 246-collection-controls-and-search
plan: 05
subsystem: ui
tags: [phoenix-liveview, responsive-tables, playwright, browser-evidence]
requires:
  - phase: 246-04
    provides: shared responsive table identity cells and copy behavior
provides:
  - committed mounted proof across six real routes, two lanes, two viewports, and two themes
  - strict source, served-asset, and screenshot digest validation
  - responsive record cards with one primary identity and one exact copyable ID
affects: [phase-246-verification, phase-247, admin-tables]
actuals:
  tokens: 101068
  tasks: 2
  commits: 12
plan_head_before: 76512d28611d8fec2425e5b9f4e4c6910b93ea18
plan_head_after: 4a80300f
tech-stack:
  added: []
  patterns: [source-and-served-asset digest-bound browser evidence, distinct card identity badge IDs]
key-files:
  created:
    - examples/accrue_host/e2e/phase246-current-proof.spec.js
    - scripts/ci/verify_phase246_render_proof.mjs
    - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/manifest.json
    - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/montage.png
    - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/VISUAL-REVIEW.md
  modified:
    - examples/accrue_host/playwright.phase246.config.js
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/live/charges_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
    - accrue_admin/lib/accrue_admin/live/coupons_live.ex
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
    - accrue_admin/test/accrue_admin/live/charges_live_test.exs
    - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
    - accrue_admin/test/accrue_admin/live/coupons_live_test.exs
    - accrue_admin/test/accrue_admin/live/events_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
requirements-completed: [FILTER-01, FILTER-02, FILTER-03, TABLE-01]
coverage:
  - id: D1
    description: Mounted filter and identity interactions pass on four ordinary and two isolated held-out production routes.
    requirement: FILTER-01
    verification:
      - kind: e2e
        ref: examples/accrue_host/e2e/phase246-current-proof.spec.js; ordinary and heldout tagged runs; captures/phase246-current-proof/manifest.json
        status: pass
      - kind: other
        ref: node scripts/ci/verify_phase246_render_proof.mjs --manifest .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/manifest.json
        status: pass
    human_judgment: false
  - id: D2
    description: All 24 mounted captures show readable primary identities, exact copy IDs, wrapping, and light/dark parity.
    requirement: TABLE-01
    verification:
      - kind: other
        ref: .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/VISUAL-REVIEW.md
        status: pass
    human_judgment: true
    rationale: The saved image review is an agent visual inspection and does not represent owner approval.
metrics:
  duration: 73min
  completed: 2026-10-11
status: complete
---

# Phase 246 Plan 05: Current Render Proof Summary

**The filter toolbar and five responsive identity consumers now have 24 committed mounted captures bound to production source and served-asset hashes.**

## Performance

- **Duration:** 73 minutes
- **Started:** 2026-10-11T19:11:07Z
- **Completed:** 2026-10-11T20:24:18Z
- **Tasks:** 2/2
- **Files modified:** 45 across source, focused tests, capture harness, and evidence

## Accomplishments

- Added a bounded two-lane Playwright proof for invoices, payments, coupons, events, Connect accounts, and webhooks. It checks real filter transitions, exact copied IDs, visible copy feedback, 44×44 targets, and horizontal overflow at the declared sizes.
- Corrected the five card identity consumers to reuse their table identity helpers. Responsive badge IDs now have a `-card` suffix so desktop and mobile representations do not duplicate DOM IDs. Focused owner tests cover the real rendered card title and exact-ID copy control.
- Retained 24 full-page screenshots from ordinary and held-out routes, with source SHA `39a52efed8fc3a1016f0c636740f5a41bc45540a` and matching served CSS/JS hashes. All product, fixture, and built-asset sources still match that captured revision; later changes were limited to the proof harness and validator.
- Inspected the montage and all 24 full-resolution captures. The agent visual review found no unresolved clipping, duplicate primary identity, or horizontal overflow. This is an agent inspection, not owner approval.

## Verification

- Focused five-owner LiveView test files: **60 tests, 0 failures**.
- `mix format --check-formatted` on the focused source/test files: passed.
- Admin asset build: passed.
- Ordinary and held-out mounted Playwright lanes at source `39a52efe`: **2/2 passed**, with 16 ordinary and 8 held-out images. The held-out lane used the existing isolated SQL Sandbox host on port 4102 and selected the authorized organization scope through the normal UI flow.
- `node --check scripts/ci/verify_phase246_render_proof.mjs`: passed.
- Manifest validator: passed for exactly 24 PNGs across four ordinary and two held-out routes; source commit, unchanged product-source digests, lane asset digests, image hashes, and viewport dimensions match.
- No full 718-test suite was run. The existing Phase 243 protected preview was left read-only; port 4101 and unknown containers were not touched.

## Task Commits

Each task was committed atomically:

1. **Task 1: Prepare bounded current-source mounted proof** - `719ed04a` (proof harness)
2. **Task 1: Prepare bounded current-source mounted proof** - `8af8a034` (invoice filter state)
3. **Task 1: Prepare bounded current-source mounted proof** - `517703f6` (copy target and proof contracts)
4. **Task 1: Prepare bounded current-source mounted proof** - `889d5b32` (mobile card identity)
5. **Task 1: Prepare bounded current-source mounted proof** - `abc4b54b` (unique responsive badge IDs)
6. **Task 1: Prepare bounded current-source mounted proof** - `0c009c3c` (responsive identity assertions)
7. **Task 1: Prepare bounded current-source mounted proof** - `dcd6be32` (captured-source validator)
8. **Task 1: Prepare bounded current-source mounted proof** - `39a52efe` (held-out owner scope)
9. **Task 1: Prepare bounded current-source mounted proof** - `21f0a56d` (exact proof viewports)
10. **Task 1: Prepare bounded current-source mounted proof** - `42b632ac` (full-page capture dimensions)
11. **Task 1: Prepare bounded current-source mounted proof** - `246d8868` (historical full-page validation)
12. **Task 2: Capture, inspect and validate the committed rendered proof** - `4a80300f` (reviewed 24-image proof)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Corrected repeated responsive identity IDs and card identity assertions**
- **Found during:** Task 1
- **Issue:** Desktop and narrow-card copies rendered together with duplicate badge IDs; several card titles did not consistently reuse the same identity as the owning table.
- **Fix:** Reused the owning identity renderers, assigned card badges unique IDs, and added focused assertions for the five real consumers.
- **Files modified:** Five LiveViews and their five focused test files.
- **Verification:** Focused owner suite passed, 60 tests / 0 failures.
- **Committed in:** `889d5b32`, `abc4b54b`, and `0c009c3c`.

**2. [Rule 3 — Blocking issue] Selected the held-out organization using the normal owner-scope flow**
- **Found during:** Task 2
- **Issue:** Directly visiting scoped Connect/webhook routes did not establish an active organization.
- **Fix:** The proof selects the fixture organization in the workspace UI before opening those routes.
- **Files modified:** `examples/accrue_host/e2e/phase246-current-proof.spec.js`.
- **Verification:** Held-out Playwright lane passed against both mounted production routes.
- **Committed in:** `39a52efe`.

**3. [Rule 1 — Validator defect] Accepted the full-page screenshot dimensions the capture spec already produced**
- **Found during:** Task 2
- **Issue:** The initial validator treated full-page PNG heights greater than the viewport as invalid even though `fullPage: true` was intentional and the viewport width remained exact.
- **Fix:** Validated exact viewport width and a PNG height at least as tall as the viewport; recorded `capture_mode: full_page` for each retained image and kept source-history checks for harness files.
- **Files modified:** `scripts/ci/verify_phase246_render_proof.mjs` and the final manifest.
- **Verification:** Manifest validator passed for all 24 captures and all product sources remain byte-identical to the captured commit.
- **Committed in:** `246d8868` and `4a80300f`.

**Total deviations:** 3 auto-fixed. All changes were required to produce trustworthy mounted proof; no product feature scope was added.

## Issues Encountered

Earlier capture attempts are preserved under unique `phase246-current-proof-attempt-*` directories and excluded from the canonical 24-image matrix. The final proof directory refuses overwrite and contains only the validated matrix, montage, manifest, and visual review.

## Next Phase Readiness

Phase 246’s final mounted-evidence gap is closed. The source and rendered artifacts are ready for the phase verification step.

---
*Phase: 246-collection-controls-and-search*
*Completed: 2026-10-11*

## Self-Check: PASSED

- Canonical capture manifest, montage, and visual review exist; the manifest validates 24 PNGs.
- All 12 measured plan commits are ancestors of this branch; the source, evidence, and summary commits are present.
- All plan tasks and stated verification commands completed successfully.
