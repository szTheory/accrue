---
phase: 243-integrated-evidence-and-feedback-preview
plan: 01
subsystem: testing
human_judgment: false
tags: [playwright, visual-regression, linux, baselines]
requires: []
provides:
  - Twelve-member selected Linux baseline contract and per-file negative controls
  - Invoice list-to-detail action-review composition in the incumbent visual owner
  - Reviewed Linux baselines passing the existing blocking comparison
affects: [EVR-03, 243-02]
actuals:
  tokens: 7395
  tasks: 2
  commits: 4
plan_head_before: f64a06e2b7134b861ab04a13ab2f146ff5e9a71e
plan_head_after: 0197f4bad11d7b667a6359aba7adfae666f9dd95
tech-stack:
  added: []
  patterns: [timestamp-only masking with rendered-target assertions]
key-files:
  created:
    - .planning/phases/243-integrated-evidence-and-feedback-preview/tdd/243-01-01-red.json
    - accrue_admin/e2e/__screenshots__/visual-desktop/invoices.png
    - accrue_admin/e2e/__screenshots__/visual-desktop/invoices-dark.png
    - accrue_admin/e2e/__screenshots__/visual-desktop/invoice-detail.png
    - accrue_admin/e2e/__screenshots__/visual-desktop/invoice-detail-dark.png
  modified:
    - accrue_admin/e2e/admin-visual-regression-phase211.spec.js
    - accrue_admin/e2e/visual-baseline-set.cjs
    - accrue_admin/test/js/visual_baseline_set_test.mjs
    - accrue_admin/e2e/__screenshots__/visual-desktop/dashboard.png
    - accrue_admin/e2e/__screenshots__/visual-desktop/dashboard-dark.png
    - accrue_admin/e2e/__screenshots__/visual-desktop/subscriptions.png
    - accrue_admin/e2e/__screenshots__/visual-desktop/subscriptions-dark.png
    - accrue_admin/e2e/__screenshots__/visual-desktop/subscription-detail.png
    - accrue_admin/e2e/__screenshots__/visual-desktop/subscription-detail-dark.png
    - accrue_admin/e2e/__screenshots__/visual-desktop/component-kitchen.png
    - accrue_admin/e2e/__screenshots__/visual-desktop/component-kitchen-dark.png
    - accrue_admin/e2e/admin-group-contracts.spec.js
    - accrue_admin/e2e/admin-interactions.spec.js
    - accrue_admin/e2e/admin-spec-overview-phase194.spec.js
    - accrue_admin/e2e/phase7-uat.spec.js
    - .planning/WINDOWS.md
    - .planning/STATE.md
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
decisions:
  - "Selected the seeded invoice list and open action-review composition in light and dark themes."
  - "Published only to the authorized validation ref gsd/phase-243-linux-evidence; no main-branch update was made."
requirements-completed: [EVR-03]
coverage:
  - id: D1
    description: Twelve expected Linux baseline names, invoice list/detail review path, and per-file guard controls.
    requirement: EVR-03
    verification:
      - kind: unit
        ref: "cd accrue_admin && node --test test/js/visual_baseline_set_test.mjs"
        status: pass
      - kind: other
        ref: "Disposable local visual run: all six light/dark surface compositions rendered; masks had positive targets and exclusions."
        status: pass
      - kind: integration
        ref: "GitHub Actions run 38083267168 at 0197f4bad11d7b667a6359aba7adfae666f9dd95: Browser UAT, Admin hooks/baseline tests, complete set guard and Phase 211 visual comparison all passed."
        status: pass
    human_judgment: false
    rationale: Linux artifact comparisons were reviewed in one bounded contact-sheet batch; CI then passed the existing comparison against all twelve committed PNGs.
duration: 144min
completed: 2026-10-10
status: complete
---

# Phase 243 Plan 01: Integrated Evidence and Feedback Preview Summary

**The invoice list-to-review journey and twelve reviewed Linux screenshots now pass the existing blocking visual comparison at the unchanged thresholds.**

## Performance

- **Duration:** 144 min, including the restart and remote workflow wait
- **Started:** 2026-10-10T18:14:02Z
- **Completed:** 2026-10-10T20:38:31Z
- **Tasks:** 2 of 2 completed
- **Files modified:** 19 source, test and image files across the plan tasks; planning metadata is recorded separately

## Accomplishments

- Added light/dark invoice list and invoice detail/action-review compositions to the incumbent Phase 211 Playwright visual owner. The detail capture opens the existing review panel without confirming the action.
- Replaced broad and positional timestamp masks with label-scoped, value-only masks. Each selected composition checks mounted timestamp targets and confirms identity, amount, state, action, error and label text remains outside the masks.
- Froze the expected set at twelve PNGs and added controls for absent, empty, one-image and every individually missing-image case.
- Updated stale browser UAT assertions against current rendered UI and the approved Phase 240–242 contracts. The full remote Browser UAT passed; it retains meaningful behavior checks and owner-specific action/auth assertions.
- Reviewed the Ubuntu artifact in one bounded before/current/diff batch. The capture set preserved protected invoice/customer/owner/amount facts, and the timestamp-only masks did not obscure them. Existing screenshots reflected current UI; four invoice screenshots were new.
- Committed all twelve Linux PNGs and passed the normal, unchanged Playwright visual regression comparison.

## Task Commits

1. **Task 243-01-01: Prove one invoice journey and faithful rendered masks in the incumbent visual owner** — `dd11264d` (feat)
2. **Align Browser UAT with current admin surfaces** — `7528b447` (fix)
3. **Pass visual timestamp masks as locator list** — `2c59529b` (fix)
4. **Validate rendered visual timestamp anchors** — `73f93cb6` (fix)
5. **Task 243-01-02: Review deliberate Ubuntu goldens and pass the unchanged blocking comparison** — `0197f4ba` (test)

## Verification and Provenance

- `node --test accrue_admin/test/js/visual_baseline_set_test.mjs` passed all 17 tests. The baseline-set guard passed against the twelve committed files.
- A disposable local Playwright visual run exercised all six light/dark compositions and produced twelve temporary captures outside the repository; those captures were inspection evidence only and were not committed.
- Ubuntu mint run `38082811261` used source `73f93cb6786e767c8fd748e0ce886bf128102d97`. Its mint and upload succeeded. Reviewed artifact `phase211-visual-baselines`, ID `11681192100`, size 2,546,760 bytes, SHA-256 `548bdf297b0d196ee47079da8a25929b3f9d32d84e02eacd1fc7f86d00b8343c`, contained the twelve captures committed as `0197f4ba`. The artifact was retrieved from the workflow run and reviewed as a single bounded batch before commit.
- The normal incumbent workflow then ran on committed source/image revision `0197f4bad11d7b667a6359aba7adfae666f9dd95`. Run `38083267168` completed successfully. Browser UAT passed, the Node hook and baseline set tests passed, the complete committed set guard passed, and `e2e:visual-regression` passed. Its accompanying Linux mint job also succeeded and uploaded artifact ID `11681422640`.
- Runner: `ubuntu-24.04`; Node 22; Playwright `1.59.1`; lockfile SHA-256 `f85f06ce8e9408d70a2acc7026f73387874e13f0e166b9e0f7cf00a2d8af80ac`; browser visual spec SHA-256 `78ba4140f828369125f8d4ccd7289aeef1cfbb6cfaab9e23b0da04f885dc33b7`; baseline guard SHA-256 `3a1e1a01a7de154eca246a22023c68a2760199e595eabb1736b724dfebbc4b66`; fixture SHA-256 `33eafebeb6539eaf92a06f160bc72b40b4f50e69b1e989c61adafc44e104223b`.
- Fixtures reset and seeded `phase191-matrix`, `operator-flows`, `dashboard`, and `edge-states`; captures used the seeded dashboard subscription and Phase 191 invoice. The existing Chromium `visual-desktop` project and package assets were used. Workflow settings were unchanged: threshold `0.2`, `maxDiffPixelRatio: 0.01`.
- Source and baselines were pushed to authorized validation ref `gsd/phase-243-linux-evidence`. No merge or default-branch update occurred.

## Deviations from Plan

**1. [Rule 1 - Bug] Updated stale browser UAT selectors and copy assertions to the current approved UI.**
- **Found during:** Task 243-01-01 verification
- **Issue:** Several existing probes used obsolete shell, zone-order, dashboard, mobile-menu, and DLQ copy assertions; Linux UAT exposed the same stale contracts.
- **Fix:** Corrected the named probes against current rendered surfaces and preserved their behavioral, negative-control, authorization and action-owner assertions.
- **Files modified:** `admin-group-contracts.spec.js`, `admin-interactions.spec.js`, `admin-spec-overview-phase194.spec.js`, `phase7-uat.spec.js`
- **Commits:** `7528b447`, with visual-mask follow-up corrections in `2c59529b` and `73f93cb6`.

**2. [Rule 3 - Blocking issue] Published the committed source to the authorized validation ref to enable the existing Linux workflows.**
- **Found during:** Task 243-01-02
- **Issue:** The local sequential checkout branch had no remote ref, so the incumbent mint workflow could not resolve it.
- **Fix:** Used the user-authorized non-force push to `gsd/phase-243-linux-evidence`, then dispatched the existing workflow; no workflow lane or threshold changed.
- **Verification:** Run `38083267168` passed the normal required comparison.

## Failed Run History

- `38075816533` at `bc375386`: initial Ubuntu mint failed.
- `38081293532` at `7528b447`: Browser UAT passed; the complete-set guard correctly failed because the four invoice PNGs had not yet been committed.
- `38081671658` at `2c59529b`: Browser UAT passed; the guard correctly reported the four not-yet-committed invoice PNGs.
- `38082811261` at `73f93cb6`: mint and artifact upload succeeded, but the normal job correctly failed the complete-set guard before the reviewed PNG commit existed.
- `38083267168` at `0197f4ba`: mint and normal Browser UAT, complete-set guard and pixel comparison all passed.

## Next Phase Readiness

Plan 243-01 and requirement EVR-03 are complete. Plan 243-02 remains independently halted on the existing Phase 234 “Back to results” assertion; this plan did not change its files or status.

## Self-Check: PASSED

- The twelve tracked Linux baselines, source/test files, and Task 1 RED evidence exist.
- Task commits `dd11264d`, `7528b447`, `2c59529b`, `73f93cb6`, and `0197f4ba` are ancestors of HEAD.
- The normal Ubuntu workflow completed successfully at the committed revision; its complete-set guard and visual comparison both passed.
