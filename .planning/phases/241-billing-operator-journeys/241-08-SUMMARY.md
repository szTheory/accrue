---
phase: 241-billing-operator-journeys
plan: "08"
subsystem: billing-ui
tags: [playwright, phoenix-liveview, css, asset-provenance, spacing]

requires:
  - phase: 241-07
    provides: Existing Phase 199 mounted billing fixtures and Phase 241 responsive/action owners
  - phase: 242
    provides: D-20/D-21 bounded mounted confirmation and package asset provenance constraints
provides:
  - Recurring mounted computed-style coverage for invoice/subscription action bands and an active dunning action row
  - 4px --ax-space-xs spacing for both named billing action selectors in source and rebuilt package CSS
  - Focused package CSS/JS/Geist route byte identity evidence
affects: [241-verification, 243]

actuals:
  tokens: 66467
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 31466e9a2e31d5d101c91549e3de0916afd43fd7
plan_head_after: 65c4d0436ad1c0be7b583bdb778259946c6a3ed2

tech-stack:
  added: []
  patterns:
    - Measure mounted action gaps against a computed token in the existing recurring package browser owner.
    - Compare source, package output, compiled output, and package-served assets by SHA-256.

key-files:
  created:
    - .planning/phases/241-billing-operator-journeys/241-08-SUMMARY.md
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
    - accrue_admin/priv/static/accrue_admin.css

key-decisions:
  - "Use the existing --ax-space-xs token for both billing action selectors so the action groups follow the approved 4px rhythm."
  - "Retain package route evidence as package-scoped; no host-served or production-host claim is made by the package asset test."

requirements-completed: [JRN-01, JRN-02, JRN-03, JRN-04]
human_judgment: false
coverage:
  - id: D1
    description: Invoice and subscription action bands plus the active dunning action row compute to the 4px spacing token and retain narrow/coarse access.
    requirement: JRN-04
    verification:
      - kind: automated_ui
        ref: "CI=1 npm --prefix accrue_admin run e2e:phase199 -- --grep '@phase241 action spacing' --project=chromium-desktop --project=chromium-mobile (2 passed)"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix test test/accrue_admin/assets_test.exs (4 tests, 0 failures)"
        status: pass
    human_judgment: false

duration: 9min
completed: 2026-10-10
status: complete
---

# Phase 241 Plan 08: Billing Action Spacing Summary

**Mounted invoice and subscription action groups now use the approved 4px `--ax-space-xs` rhythm with recurring narrow/coarse browser coverage and package asset identity checks.**

## Performance

- **Duration:** 9 minutes
- **Started:** 2026-10-10T15:45:44Z
- **Completed:** 2026-10-10T15:53:11Z
- **Tasks:** 2
- **Files modified:** 3 production/test files

## Accomplishments

- Added one recurring Phase 199 browser case measuring the invoice action band, subscription action band, and active subscription dunning action row against a computed `--ax-space-xs` gap.
- Changed exactly the two named source declarations to `gap: var(--ax-space-xs)` and rebuilt the tracked package CSS.
- Confirmed desktop and mobile action buttons remain 44 CSS px high at 320 CSS px, with no ordinary page overflow; confirmed a separate touch-enabled context reports a coarse pointer and retains the same action geometry.
- Ran the existing package asset owner: CSS, JS, and both self-hosted Geist font routes passed their byte/route assertions.

## TDD Evidence

- **RED:** Before the CSS correction, the exact mounted measurements were invoice action band `2px`, subscription action band `2px`, active dunning action row `3px`, and computed token `4px`. Primary action heights were `44px`; the 320px document had no horizontal overflow. The focused desktop/mobile batch failed on the planned invoice computed-gap equality assertion (2 failures, 0 skipped). A single-project JUnit capture was accepted by `gsd_run check tdd-red-evidence` as `RED_EVIDENCE_OK` with `target_test_failed`.
- **GREEN:** After the source correction and explicit package asset rebuild, the designated focused desktop/mobile acceptance batch passed (2 passed, 0 failed). All three mounted gaps were `4px`, each matched the computed token, both primary action groups retained `44px` action buttons, the separate coarse-pointer context passed, and no measured page overflowed. An earlier JUnit-reporter attempt made before the RED report-format correction also ran green in both projects; it is recorded below and was not treated as another acceptance batch.
- **REFACTOR:** None needed.
- **Commit sequence:** `c7600753` RED test commit, followed by `65c4d043` GREEN CSS/package build commit.

## Package Asset Provenance

| Layer | SHA-256 | Result |
|---|---|---|
| CSS source `assets/css/app.css` | `6d6af462d2b1f9717ba5fae6f5aba8a3703978be3f49e1c21f2b930ae25e62dc` | Contains the two 4px-token declarations |
| Tracked package CSS `priv/static/accrue_admin.css` | `089878ed3cba5377be66c12c1958d728873d327c4666c7ec293e21cc8188633e` | Rebuilt; differs from prior CSS output |
| Compiled test package CSS | `089878ed3cba5377be66c12c1958d728873d327c4666c7ec293e21cc8188633e` | Byte-identical to tracked package CSS |
| Package JS | `36974c751ef3c9df6f40a2ff7fa09c04d85819dac2de74804d8438f6c3be3085` | Unchanged from pre-plan revision |
| Geist Sans font | `28258d0621216948416a859d32487ab6ad1c9effa0d08795698e70be3c917630` | Unchanged from pre-plan revision |
| Geist Mono font | `5bc6413e82be410dc057feccee55160495b999d0fe212b7b6c6499b29b8b1e4a` | Unchanged from pre-plan revision |

`MIX_ENV=test mix test test/accrue_admin/assets_test.exs` passed 4 tests with 0 failures. That existing owner exercises the package CSS, JS, Geist Sans, and Geist Mono routes and compares their responses with package bytes. The mounted browser owner exercises the package output on disposable Phase 199 fixtures. This plan did not exercise the Phase 237 host compilation or HTTP-served host identity; those claims remain unobserved here.

## Task Commits

1. **Task 1 RED:** `c7600753` — `test(241-08): assert mounted billing action spacing`
2. **Task 1 GREEN:** `65c4d043` — `feat(241-08): align billing action gaps to 4px token`

Task 2 reused Task 1's single confirming browser result and ran the package asset tests; it needed no additional production-code change.

## Files Created/Modified

- `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` — Recurring computed spacing, narrow layout, and coarse-pointer geometry assertions.
- `accrue_admin/assets/css/app.css` — Two named action gaps now use `--ax-space-xs`.
- `accrue_admin/priv/static/accrue_admin.css` — Explicitly rebuilt package CSS output.

## Decisions Made

- Used the existing 4px spacing role for both named action selectors, preserving the unrelated dense-data 2px and structural 1px exceptions.
- Used the active dunning subscription from the seeded Phase 199 recovery fixtures to exercise the conditional `.ax-detail-actions-row`; the ordinary subscription fixture does not render that conditional row.
- Kept package route identity separate from host-served claims and did not run the capture-writing Phase 237 owner.

## Deviations from Plan

**1. [Rule 3 - Blocking] Used a task-scoped npm cache for the asset build.**
- **Found during:** Task 1
- **Issue:** The default npm cache contained root-owned files and the first build failed with `EPERM` while opening its cache temp file.
- **Fix:** Re-ran the same asset build with `npm_config_cache=/private/tmp/accrue2418-npm-cache`; no package was installed or changed.
- **Files modified:** None beyond the planned files.
- **Verification:** The package build completed and emitted the tracked CSS/JS assets.

**Total deviations:** 1 auto-fixed (Rule 3 - Blocking). The mounted subscription fixture was adjusted to use the seeded recovery subscription so the conditional dunning row was present; this stayed within the planned existing owner and fixture scope.

## Issues Encountered

- The initial sandboxed Chromium launch failed before test execution due to macOS MachPort restrictions. The same bounded command was rerun with the authorized elevated execution path; subsequent browser runs reached the assertions.
- The initial fixture assumption that the normal subscription route rendered `.ax-detail-actions-row` was false. The test now measures that selector on the active seeded recovery subscription and measures the standard action band on both invoice and subscription details.
- A JUnit-format RED run initially included both projects and produced duplicate target identities; the single-project desktop report resolved uniquely and passed the required classifier. The final GREEN acceptance remained the planned desktop/mobile batch.
- One JUnit-reporter attempt ran after the CSS correction and passed in both projects before the valid single-project RED capture was produced. The source and built CSS were restored to the verified pre-fix state for that RED capture, then corrected and rebuilt. The extra green reporter run is retained in this execution record and is not counted as an additional acceptance batch.

## Threat Flags

None. No network endpoint, authorization path, file access pattern, or schema boundary changed.

## TDD Gate Compliance

- RED evidence classifier: `RED_EVIDENCE_OK`, `target_test_failed`; target test executed and failed on the expected computed-style assertion, not fixture/startup/syntax behavior.
- RED commit precedes GREEN: `c7600753` → `65c4d043`.
- GREEN evidence: selected mounted browser owner passed in both desktop and mobile projects.

## Next Phase Readiness

Plan 241-08's named source and mounted package gap is closed. The phase verifier should now refresh the truth-25 verdict through the normal post-wave gate. Phase 242's historical 80/80 result and 19 automated UAT items remain unchanged. Package-route tests do not establish host-served identity; Phase 243 retains its reviewed Linux golden and stable preview scope.

---
*Phase: 241-billing-operator-journeys*
*Completed: 2026-10-10*

## Self-Check: PASSED

- Summary file exists at the required phase path.
- RED commit `c7600753` and GREEN commit `65c4d043` are ancestors of the current HEAD.
- Two measured plan commits are present after `plan_head_before`.
