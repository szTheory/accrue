---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "15"
subsystem: testing
tags: [visual-regression, playwright, ci, report-artifacts, design-review]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: Phase 254 visual case manifest, corrected CSS, frozen visual allowance, and design-review record
provides:
  - 44 committed Linux visual baselines with identity metadata and attributed changes
  - Browser UAT confirmation and measured visual-cell budget on the pushed head
  - Isolated Phase 252/253 Playwright JSON reports retained with path and SHA-256 evidence
  - Design-review confirmation bound to the committed capture manifest
affects: [254-16, 254-17, 254-18]

actuals:
  tokens: 40000
  tasks: 3
  commits: 23

tech-stack:
  added: []
  patterns:
    - "Store Playwright machine reports outside PLAYWRIGHT_OUTPUT_DIR when later invocations clean that directory"
    - "Bind report evidence to an uploaded JSON file by repository-relative path and SHA-256, and require Phase 252 stdout to equal its report digest"
    - "Refresh visual cost from the successful attempt-1 browser run and append a new budget freeze instead of overwriting the earlier observation"

key-files:
  created:
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-15-SUMMARY.md
    - accrue_admin/e2e/__screenshots__/visual-desktop/manifest.json
    - accrue_admin/e2e/__screenshots__/visual-desktop/phase254-*.png
  modified:
    - .github/workflows/ci.yml
    - scripts/dev/phase252_lab.mjs
    - scripts/ci/verify_phase252_stories.mjs
    - scripts/ci/verify_phase253_compositions.mjs
    - accrue_admin/storybook/phase254-budget.json
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-DESIGN-REVIEW.json
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-DESIGN-REVIEW.md

key-decisions:
  - "The owner accepted attribution of the subscription-list visual changes to A11Y-254-28 and authorized the additional Linux mint recorded as AMD-254-06."
  - "The owner selected fix-in-phase for the Playwright reporter-capture failure; a later artifact inspection also required isolating reports from the output directory cleaned by subsequent runs."
  - "No further escalation was required on Browser UAT 41695128833: its browser, baseline-set, manifest, and visual-regression steps all passed."

patterns-established:
  - "Keep the JSON reporter file in a sibling directory from Playwright's cleanable output directory when sequential reports share one results root."
  - "Verify uploaded machine evidence against both the path and digest recorded in the command results."

requirements-completed: []
requirements-advanced: [CIQ-03, UXQ-04, CIQ-04]

coverage:
  - id: D1
    description: "The 44-image Linux baseline set and identity manifest are committed; changed images are attributed to A11Y-254-28 or the recorded Phase 211 dispositions."
    requirement: CIQ-03
    verification:
      - kind: integration
        ref: "Linux mint run 41682891880; visual-baseline-set.cjs and phase254_visual_manifest.mjs check --base origin merge-base"
        status: pass
    human_judgment: false
  - id: D2
    description: "The pushed head passes the Browser UAT set, identity, and pixel-regression gates, with measured cost inside the frozen allowance."
    requirement: CIQ-03
    verification:
      - kind: e2e
        ref: "AccrueAdmin Browser UAT run 41695128833, attempt 1, head 7e8d0cda49a59bbf1e893ad26a27a93b513bc59f; all 32 Phase 254 visual cells passed"
        status: pass
      - kind: other
        ref: "phase254-budget.json metrics.visual and DEV-254-36: 59 s added job time; 794 ms median and 1195 ms p90 per cell"
        status: pass
    human_judgment: false
  - id: D3
    description: "Phase 252 and Phase 253 reporter files are retained in CI artifacts and match every recorded path and digest; Phase 252 stdout matches its report digest."
    requirement: CIQ-04
    verification:
      - kind: integration
        ref: "CI run 41695128675 phase252-machine-evidence and phase253-machine-evidence artifacts; subscription-render-browser, phase253-compositions-browser and phase254-design-browser path/hash checks"
        status: pass
    human_judgment: false
  - id: D4
    description: "The design-review record is confirmed from the committed Linux captures and the current identity manifest."
    requirement: UXQ-04
    verification:
      - kind: unit
        ref: "node --test scripts/ci/verify_phase254_design_review.test.mjs (51/51); verify_phase254_design_review.mjs --self-test (24 scenarios) and --check --stage confirmed"
        status: pass
    human_judgment: false

human_judgment: false
duration: about 5 days elapsed across sessions
completed: 2026-11-03
status: complete
commits: 23
plan_head_before: b861a6da43a56c4e3d4046e9b13cbfd184b83f66
plan_head_after: 7e8d0cda49a59bbf1e893ad26a27a93b513bc59f
---

# Phase 254 Plan 15: Linux baselines, visual confirmation, and reliable CI report capture

**The 44-image visual set now has Linux-minted identity evidence, the Phase 211 visual gate passes on the pushed head, and CI retains all three Phase 252/253 Playwright reports with verifiable digests.**

## Performance

- **Duration:** about 5 days elapsed across sessions
- **Tasks:** 3 (including owner checkpoints)
- **Files:** 77 changed across the plan's implementation history

## Accomplishments

- Mint run **41682891880**, attempt 1, produced the committed Linux visual set after its three-run stability proof. The 44-image set and identity manifest pass; 20 changed Phase 254 PNGs map to A11Y-254-28, no Phase 211 PNG changed in this mint, and the two subscription-list PNGs are byte-identical to the pre-rebaseline tree. The owner-authorized additional mint is recorded by AMD-254-06.
- Browser UAT **41695128833**, attempt 1 on `7e8d0cda49a59bbf1e893ad26a27a93b513bc59f`, passed browser tests, the strict set guard, identity-manifest check, and Phase 211 pixel gate. Its 1203 s job duration is 59 s above the 1144 s baseline p90 and within the 180 s allowance. The 32 Phase 254 visual cells measured median 794 ms, p90 1195 ms, max 1577 ms and sum 27.153 s; scheduled cancellation remained in the set.
- The design-review record remains `confirmed`, with all 16 capture hashes tied to the committed manifest and its observation refreshed to Browser UAT 41695128833. The 51 design-review tests, 24-scenario self-test, strict baseline checks, manifest check, and budget checks pass.
- The reporter fix reads Playwright JSON from an isolated file, forwards only that report to machine stdout, and records its relative path and digest. A follow-up found the Phase 253 composition report was removed when the next invocation cleaned the shared output directory; commit `7e8d0cda4` moved all three reports into sibling `playwright-reports/` directories and updated CI upload globs.
- CI run **41695128675**, attempt 1 on the same head, passed the required Admin Phase 200 deterministic guardrails job. Its uploaded Phase 252 and Phase 253 results contain the subscription render report, composition report, and design report; all three files match their recorded SHA-256 values, and Phase 252 stdout has the same digest as its JSON report. Their report counts are 15, 152, and 13 tests respectively, with zero skips, failures, or flakes.
- The overall CI run ended with only recorded non-owner reds: SL-G refused to complete without Phase 254 acceptance artifacts (retained by KR-254-06 until Plan 18), and the parked Admin UI ratchet failure was mechanically classified `pre-existing-on-main` against run 40387584954. The Phase 200 owner job remained green; no new owner decision was required.

## Task Commits

1. **254-15-01 — Linux baseline and reporter evidence:** `b6a5ec363` (dedicated rebaseline), `d17710e07` (isolated Playwright JSON capture), and `7e8d0cda4` (preserve all report artifacts). Supporting Phase 254 fixes and run history are recorded in `254-15-CHECKPOINT-LOG.md`.
2. **254-15-02 — Owner disposition:** recorded in the checkpoint log and AMD-254-06. The owner selected `accept-attributable (Rec.)` for the four list images; `fix-in-phase` for the remaining visual identity drift and reporter-capture red; and chose “follow ur recs” for the Linux Storybook/app overlap correction. The exact reporter-capture answer was: “Yeah, we can fix the reporter capture. I want to follow your recommendations. So that sounds good.” No escalation was required after the final Browser UAT passed.
3. **254-15-03 — Confirmation and budget:** the design-review observation now points to run 41695128833; budget metrics and deviations DEV-254-35/36 record the successful observation and the 1195 ms per-cell p90 freeze.

## Verification

- `node --test scripts/ci/verify_phase254_design_review.test.mjs` — 51/51 passed.
- `node scripts/ci/verify_phase254_design_review.mjs --self-test` — 24 scenarios passed; `--check --stage confirmed` passed.
- `node scripts/ci/phase254_budget.mjs --self-test` — 23 scenarios passed; `restamp-manifest --check` passed.
- Strict 44-image baseline set and identity-manifest check passed.
- The Plan 15 acceptance command passed on head `7e8d0cda49a59bbf1e893ad26a27a93b513bc59f`.
- Reporter and command-plan contracts passed 52/52; the strict CI script-contract gate and Phase 200 shell contract passed before the push.

## Deviations from Plan

- After the first CI report-capture fix, artifact inspection showed that the later Phase 253 Playwright invocation deleted the earlier composition report. The owner-authorized in-scope fix moved report files outside the shared cleanable directory and uploaded both Phase 253 reports. The new-head attempt-1 artifacts prove the correction.
- A rolling-window fixture in the full pre-push CI script contract used synthetic August dates while its helper read the real November clock. The test adapter now freezes that fixture clock; production cohort logic is unchanged.
- No visual allowance drop or additional mint was needed. The new Browser UAT remained within the existing allowance.

## Issues Encountered

- The CI workflow remains red on the already accepted SL-G guard until Phase 18 generates real acceptance artifacts. The parked ratchet failure matches the pre-existing main run 40387584954. Neither red is in the measured owner job, which passed.

## User Setup Required

None.

## Next Phase Readiness

- Plan 16 can proceed: the confirmed visual record, successful Browser UAT, reporter hashes and frozen cost are available.
- Plan 18 still owns final CI observation and the existing blocking-human gate for any new out-of-scope red. Do not write Phase 254 acceptance artifacts before Plan 18.

---
*Phase: 254-recurring-quality-reviewed-fixes-and-curation*
*Completed: 2026-11-03*
