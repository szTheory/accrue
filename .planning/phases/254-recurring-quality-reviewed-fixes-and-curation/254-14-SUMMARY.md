---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "14"
subsystem: testing
tags: [visual-regression, playwright, baselines, identity-manifest, mint-workflow, ciq-03]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: 254-13 corrected design review record (16 capture keys), the Phase 253 compiled manifests, the frozen recurring budget
provides:
  - subscription-visual-phase254.spec.js in the existing visual-desktop owner (A4 probe, 24 story and 8 mounted deterministic cases)
  - phase254-visual-cases.json written and drift-checked by phase254_selection.mjs project (AMD-254-02, sourcing.a4 story-routes)
  - phase254_visual_manifest.mjs (build, check --base, seed-legacy, --self-test) and the committed identity manifest of the 12 unchanged Phase 211 baselines
  - a manifest-backed baseline set guard with an independent expected set and a local-only --pre-mint
  - a hardened mint job and a mutation contract; the Phase 211 spec's duplicated case removed and its text-regex fact check replaced by a geometry check
affects: [254-15, 254-17, 254-18]

actuals:
  tokens: 48000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "The expected baseline set comes from a literal legacy list plus the projector-written case list, never from the manifest, so deleting a PNG together with its manifest entry still fails"
    - "A case key is not a file name: Playwright sanitizes toHaveScreenshot names (underscore becomes hyphen), so one exported snapshotFileName() maps key to file in the spec, the guard and the manifest tool"
    - "A story/mounted case proves its own determinism (fixed clock, loaded Geist faces, served asset sha256, theme-token difference with a positive control) before any pixel comparison"

key-files:
  created:
    - accrue_admin/e2e/subscription-visual-phase254.spec.js
    - accrue_admin/storybook/phase254-visual-cases.json
    - scripts/ci/phase254_visual_manifest.mjs
    - scripts/ci/phase254_visual_manifest.test.mjs
    - scripts/ci/phase254_visual_contract.test.mjs
    - accrue_admin/e2e/__screenshots__/visual-desktop/manifest.json
  modified:
    - scripts/ci/phase254_selection.mjs
    - scripts/ci/phase254_selection.test.mjs
    - scripts/ci/phase254_project_ownership.test.mjs
    - accrue_admin/playwright.config.js
    - accrue_admin/e2e/visual-baseline-set.cjs
    - accrue_admin/test/js/visual_baseline_set_test.mjs
    - accrue_admin/e2e/admin-visual-regression-phase211.spec.js
    - .github/workflows/accrue_admin_browser.yml

key-decisions:
  - "A4 outcome: story routes render on the legacy port-4017 server. The probe's positive control (the page story's ready marker and h1) passes and its negative control (a nonexistent story renders no marker) passes, so sourcing.a4 is story-routes and no mounted fallback is used."
  - "Page stories use the compiled manifest's direct_path and collections its iframe_path. The design record's capture route for pages (/billing/dev/storybook/iframe/pages/...) renders no sandbox on the server, so the cases follow the compiled manifest; only the record's keys are bound to the case keys."
  - "Mounted cases capture one element, not the page (see Deviations 1): the review drawer's dialog panel and the open dunning-recovery disclosure with its summary focus-visible."
  - "The manifest is keyed by case key (underscores kept) and records the sanitized file name in each entry; an entry's case_key must equal its key and its file must equal snapshotFileName(key)."
  - "check enforces the Chromium and Playwright versions for every minted entry (read from the installed playwright-core browsers.json, which equals browser.version()), and served/font/scenario digests only for PNGs changed since the merge-base, as D-18 words it."
  - "The mint job takes workflow_dispatch inputs reason and finding_id (with defaults) and applies them to every changed key; per-key refinement is possible at commit time because the guard checks the fields."

patterns-established:
  - "The mutation contract strips YAML comments, isolates one job by its key, and requires each mutation to change the file (a no-op mutation proves nothing)"

requirements-completed: []
requirements-advanced: [CIQ-03]

coverage:
  - id: G1
    description: "Story routes render on the legacy server with a positive and a negative control, and every new visual case reaches its screenshot call with all content assertions passed"
    requirement: CIQ-03
    verification:
      - kind: integration
        ref: "playwright test subscription-visual-phase254.spec.js --project=visual-desktop --update-snapshots=none: 2 A4 tests passed; 32 case tests (equal to cases.length) each failed only with the missing-snapshot error; filtered run (A4 plus phase254-page-active-w1280-light) exactly one case test; e2e/__screenshots__ unchanged after a seeded probe file was detected and removed"
        status: pass
    human_judgment: false
  - id: G2
    description: "The 32 captures are deterministic on one machine"
    requirement: CIQ-03
    verification:
      - kind: integration
        ref: "scratch config (snapshot path outside the repository) with --update-snapshots=all run twice: 32 PNGs, sha256 sums identical across both runs. macOS output, never committed; it proves the determinism assertions, not Linux pixels"
        status: pass
    human_judgment: false
  - id: G3
    description: "The baseline set guard compares PNG set and manifest key set against an independent expected set, byte-checks every PNG and validates fields"
    requirement: CIQ-03
    verification:
      - kind: unit
        ref: "node --test test/js/*.mjs in accrue_admin: 87 pass, including extra file, byte mismatch, field errors, legacy and case PNG removed together with its entry, --pre-mint limits, and a real-directory byte check with a flipped-byte positive control"
        status: pass
      - kind: unit
        ref: "node --test scripts/ci/phase254_visual_manifest.test.mjs (12 pass) and phase254_visual_manifest.mjs --self-test (4 scenarios); a simulated mint (macOS scratch PNGs plus the real identity files, build then strict guard then check) passed with 44 entries"
        status: pass
    human_judgment: false
  - id: G4
    description: "The mint workflow can only change baselines through a successful, explicit, stability-proved mint, and the thresholds, retries and mask rules cannot be loosened silently"
    requirement: CIQ-03
    verification:
      - kind: unit
        ref: "node --test scripts/ci/phase254_visual_contract.test.mjs: 11 pass (--pre-mint, --update-snapshots outside the mint job, no =changed, bare or =all, upload always() or without success(), repeat-each, manifest build, fetch-depth, check step removed or reordered, F3 triggers, threshold, maxDiffPixelRatio, retries, stylePath in config and both specs, looser screenshot call, env switch); verify_ci_efficiency_contract.mjs passes"
        status: pass
    human_judgment: false
  - id: G5
    description: "The Phase 211 geometry check passes on the real masks on all six surfaces, fails when a mask covers the amount, and the 12 existing baselines are byte-unchanged"
    requirement: CIQ-03
    verification:
      - kind: integration
        ref: "scratch-config run of admin-visual-regression-phase211.spec.js with --update-snapshots=all: both tests passed (the 6-surface test and the masked-amount negative control); a seeded mutation that disables the overlap test made the negative control fail; the 12 legacy PNG bytes equal their manifest sha256 (guard byte tests)"
        status: pass
    human_judgment: false

human_judgment: false
duration: about 2h 10min
completed: 2026-10-29
status: complete
commits: 3
plan_head_before: e843850ef28dbd72bbbdd11c2930033bc353a353
plan_head_after: b861a6da43a56c4e3d4046e9b13cbfd184b83f66
---

# Phase 254 Plan 14: Linux baseline owner extension (W5 preparation) Summary

**The existing visual-desktop owner now carries 32 deterministic, content-checked subscription captures (24 story, 8 mounted) behind an identity manifest and a manifest-backed set guard, and the mint workflow can change a baseline only through an explicit, stability-proved, success-only mint; no PNG was minted or committed (254-15 does that on the Linux runner).**

## Performance

- **Duration:** about 2 h 10 min
- **Tasks:** 3 (3 commits; TDD folded, see Deviations 3)
- **Files:** 14 changed (6 created)

## Accomplishments

- **A4 outcome: `story-routes`.** The probe `A4 probe: the page story route renders on the legacy server and a missing story does not` passes on the port-4017 server (positive: `.psb-sandbox .ax-subscription-detail-page` renders with the h1; negative: a nonexistent story renders no marker). `phase254-visual-cases.json` records `sourcing.a4: story-routes`, `probe_error: null`.
- **Case keys (count derived from `cases.length`, 32):** story `phase254-page-<active|scheduled_cancellation|incomplete_evidence|review_cancel_now>-w<320|1280>-<light|dark>` (16) and `phase254-collection-<multiple_rows|partial_cursor_error>-w<320|1280>-<light|dark>` (8); mounted `phase254-mounted-<review-open|disclosure-focus>-w<320|1280>-<light|dark>` (8). All 16 keys of the design review record's captures are case keys (checked by `project --check`).
- **AMD-254-02** (decisions D-16 and D-33; 24 story plus 8 mounted keys; `owner_ack` 2026-10-28 owner-accepted at plan time; no checkpoint) is in `phase254-visual-cases.json` `amendments[]`; the amended text never writes the count as a literal.
- **Determinism per case:** UTC, en-US, reduced motion, `page.clock.setFixedTime("2026-10-25T12:00:00Z")` and a cleared time-display preference before navigation; the LiveView socket connected and every `[data-time-display]` element rewritten to its en-US UTC text; both Geist `FontFace` objects `loaded`; served css/js/woff2 sha256 equal the committed files (and `storybook.css` contains the exact `accrue_admin.css` bytes, D-33); `document.getAnimations().length` 0; the light and dark `--ax-base` tokens differ (the `A4 control` test proves identical tokens are rejected); then identity, amount caveat, state and action assertions; then `toHaveScreenshot(name, { maxDiffPixels: 0, mask: [] })`. Per-case identity JSON lands in `accrue_admin/tmp/phase254/visual-identity/<key>.json`.
- **Identity manifest** `manifest.json`: the 12 Phase 211 baselines (`phase211-committed`, last-changing commit, `mint_run_id: null`). `phase254_visual_manifest.mjs build` produces minted entries (served asset, font and scenario digests, Playwright and browser versions, mint run id and sha, reason, finding id) and rejects a changed key with no reason.
- **Guard** `visual-baseline-set.cjs`: 44 expected names (12 legacy literals plus 32 sanitized case-key file names); fails on missing, extra, byte-mismatched PNGs, manifest entries outside the set, missing entries, missing fields and stray non-PNG files; `--pre-mint` tolerates only the joint absence of a case PNG and its entry, is never accepted by a workflow, and is contract-tested.
- **Workflow:** `browser-uat` gets full history and `phase254_visual_manifest.mjs check --base "$(git merge-base origin/main HEAD)"` between the set guard and the pixel gate; the mint job uses `--update-snapshots=changed`, a `--repeat-each=3 --update-snapshots=none` stability proof on the new spec, the manifest build, the manifest-backed set check, and uploads baselines, identity files and manifest only `if: success()`. Both event triggers also watch `storybook/**`, `dev_support/ui_scenarios/**`, `brandbook/tokens/**` and `scripts/ci/phase254_*` (RESEARCH F3).
- **Contract mutation list (each fails with its own message, real files pass):** `--pre-mint` in a workflow step; `--update-snapshots` outside the mint job; mint without `=changed` (bare, `=all`, or absent); upload under `always()` or with no `success()`; stability proof removed; manifest build removed; mint or gate job without `fetch-depth: 0`; manifest check step removed or moved after the pixel gate; a missing F3 trigger path on either event; widened `threshold` or `maxDiffPixelRatio`; a `retries` key; a `stylePath` in the config, the new spec or the Phase 211 spec; a looser new-spec screenshot call (pixels, non-empty mask, environment switch).
- **Phase 211 spec:** the duplicated `case "invoices"` is gone; the six-category text-regex check is replaced by a geometry check (identity, amount, state, action elements against mask rectangles; a time display's copy button is the masked value itself and is excluded), with a negative control that masks the amount (and the identity) and must fail.

## Task Commits

1. **254-14-01:** `4d6cd84fb` (projector extension, spec, config, workflow triggers, ownership assertion)
2. **254-14-02:** `64b98fe4a` (guard, manifest tooling, legacy manifest, tests)
3. **254-14-03:** `b861a6da4` (workflow hardening, mutation contract, Phase 211 spec fixes)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Mounted cases capture an element, not the page**
- **Found during:** Task 01 (determinism run). The plan names "the page for mounted cases". The seeded mounted detail page renders period and renewal dates stamped at seed time (`DateTime.utc_now()`), and the review drawer's backdrop blurs that page; two identical runs produced different PNGs for `mounted-review-open`. D-19 forbids masks for the new cases, so the volatile text must stay out of the frame.
- **Fix:** `mounted-review-open` captures the dialog panel `#subscription-action-drawer aside[role="dialog"]`; `mounted-disclosure-focus` captures `[data-ax-drill-section="dunning-recovery"]` (static content) with its summary focus-visible. Identity, amount and state facts are asserted on the drawer or on `#main-content`. After the change all 32 PNGs were byte-identical across two local runs.
- **Files modified:** `scripts/ci/phase254_selection.mjs`, `accrue_admin/storybook/phase254-visual-cases.json`, the spec.
- **Commit:** `4d6cd84fb`

**2. [Rule 1 - Bug] Playwright sanitizes the snapshot name**
- **Found during:** Task 01. `toHaveScreenshot("phase254-page-scheduled_cancellation-...png")` writes `...scheduled-cancellation-...png`. A guard that expected `<key>.png` would have rejected every correctly minted underscore key.
- **Fix:** one exported `snapshotFileName(key)` (Playwright's `sanitizeForFilePath` rule, verified against all 32 produced files) used by the spec, the guard and the manifest tool; manifest entries are keyed by case key and record `file`.
- **Commit:** `4d6cd84fb`, `64b98fe4a`

**3. [Process] RED and GREEN landed together**
- The plan marks the tasks `tdd="true"`. The spec and tooling were developed against the running server and their tests (projector tests, the guard's fixture tests, the manifest tests, the mutation contract) were committed with the implementation, not before it. Every rejection test is paired with a passing control and the detectors were proved able to fail (a seeded mutation of the geometry overlap test failed the negative control; fixture tests assert each failure class directly).

**4. [Rule 3 - Blocking] Story action names are production aria-labels**
- The page's primary actions are named `Change plan for subscription <processor id>`; `scheduled_cancellation` has no visible "Cancel renewal" (its menu holds "Resume subscription"), so its visible action expectations are Change plan and Change renewal. Lookups are filtered to visible matches because responsive layouts render table and cards side by side.

**5. [Rule 2 - Missing critical] Ownership assertion**
- `phase254_project_ownership.test.mjs` gained one assertion that the new spec is owned by the visual group, so a second baseline owner cannot appear unnoticed (the file is not in `files_modified`).

### Noted, not changed

- The design review record's `route` for the page captures is `/billing/dev/storybook/iframe/pages/subscription?tab=active`, which renders no sandbox on the server; the real route is `/billing/dev/storybook/pages/subscription?tab=active`. The record is at `corrected`; 254-15 owns the `confirmed` stage and can correct the route text.
- `.planning/config.json` was already modified before this plan and was never staged.

## Known Stubs

None.

## Threat Flags

None beyond the plan's register. T-254-26 (local macOS mint): the local runs used `--update-snapshots=none`, the scratch-config determinism runs wrote only under the session scratch directory, and `e2e/__screenshots__` stayed unchanged (a seeded probe file proved the scoped status can fire). T-254-27 (masked essential facts): new cases have `mask: []`, the Phase 211 geometry check has its negative control. T-254-SC: no dependency installed or changed.

## Open flags for later plans

- **254-15 (mint):** until the mint, `visual-baseline-set.cjs` without `--pre-mint` and the visual gate report the 32 case baselines missing (expected). Dispatch the mint with `reason` and `finding_id` inputs; they apply to every changed key, including legacy keys whose pixels moved. Expect `subscription-detail`, `invoice-detail` and `component-kitchen` (label rule, field-list and wrap changes from 254-12 and 254-13) to change; `subscriptions.png` and `subscriptions-dark.png` must stay byte-identical (trace any list diff to A11Y-254-28 first).
- **Low-information capture:** the `page-review_cancel_now` story captures a tall sandbox in which the fixed drawer fills only the first viewport height, so most of each image is empty. It is deterministic and content-checked; whether to narrow it is a product call for 254-15 or later.
- **Budget:** the new spec adds about 17 s of cases to `browser-uat` (allowance 180 s); the mint job's `--repeat-each=3` adds about one minute, mint-only.
- **Digests:** `phase254-selection.json` bytes were unchanged by the projector extension; no `source_digests` input changed, so recipe R1 to R4 was not needed.
- CIQ-03 is also declared by 254-15 and 254-18, so it stays `requirements-advanced` here.

## Self-Check: PASSED

Created files exist (`accrue_admin/e2e/subscription-visual-phase254.spec.js`, `accrue_admin/storybook/phase254-visual-cases.json`, `scripts/ci/phase254_visual_manifest.mjs`, `scripts/ci/phase254_visual_manifest.test.mjs`, `scripts/ci/phase254_visual_contract.test.mjs`, `accrue_admin/e2e/__screenshots__/visual-desktop/manifest.json`); commits `4d6cd84fb`, `64b98fe4a` and `b861a6da4` are ancestors of HEAD; `git rev-list --count e843850ef28dbd72bbbdd11c2930033bc353a353..HEAD` measured 3 before this summary commit.
