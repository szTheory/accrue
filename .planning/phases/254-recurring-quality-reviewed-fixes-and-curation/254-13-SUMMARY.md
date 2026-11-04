---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "13"
subsystem: testing
tags: [copy, design-review, red-evidence, aggregate-lanes, digest-regeneration, uxq-04]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: 254-12 CSS/contract corrections, 254-12-01 red evidence, the AMD-254-04/05 verifier rules and the 30 fixed routed accessibility defects
provides:
  - subscription_action_copy_test.exs (five DR-254-05 tests) and 254-13-01-red-evidence.json, written only by --record-red from the parsed ExUnit output
  - Copy.subscription_action_activity_link_label/0 and public SubscriptionLive.action_activity_path/3, called by the LiveView and by the story adapter
  - two new lanes of the Phase 253 aggregate (phase254-action-copy, phase254-design-browser), so the correction batch's tests run in the required owner
  - the design review record at stage corrected with AMD-254-04 and AMD-254-05
affects: [254-14, 254-15, 254-17, 254-18]

actuals:
  tokens: 17442
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Copy-tier red tests reach the not-yet-existing owners through an owner_exported?/3 guard, so the module compiles and every test fails on its own assertion (left false, right true) rather than on an undefined-function crash that the red parser would classify as broken"
    - "A literal-count guard runs git grep -c -F -e <label> over the production paths, and is proved able to find a hit by running the same helper against a seeded mkdtemp scratch repository first"
    - "The aggregate's design lane uses a new playwright-titles reporter: complete passing report, every test in the phase254-design project, exact per-key test counts, assertion bindings matched to executed titles"

key-files:
  created:
    - accrue_admin/test/accrue_admin/dev/subscription_action_copy_test.exs
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-13-01-red-evidence.json
  modified:
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/storybook/_support/subscription_page_scenarios.ex
    - scripts/ci/verify_phase253_compositions.mjs
    - scripts/ci/verify_phase253_compositions.test.mjs
    - scripts/ci/verify_phase254_design_review.test.mjs
    - storybook/phase252-manifest.json
    - guides/subscription-story-coverage.md
    - accrue_admin/storybook/subscription-curation.json
    - accrue_admin/storybook/phase254-selection.json
    - accrue_admin/storybook/phase254-budget.json
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-DESIGN-REVIEW.json
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-DESIGN-REVIEW.md

key-decisions:
  - "The Phase 253 aggregate admits the batch's tests as two appended lanes rather than as extra files on an existing lane: the composition browser lane validates an exact cell universe and would reject any extra spec, so a separate playwright-titles lane with source-bound per-key counts keeps both contracts exact."
  - "Both new lanes are appended after the existing ten, so plan[5] (the compositions browser lane the runner indexes) and every earlier lane identity are unchanged."
  - "fix_commit is 88cd27cdc (the GREEN copy commit), the last correction commit of the batch; the CSS artifacts at that commit equal the 254-12 values, so the assets block carries the same four sha256 values."
  - "DR-254-08 stays deferred: none of the 30 routed entries at eefee2a62 names summary.ax-detail-section-head (A11Y-254-22 names summary.ax-button); its deferral trigger now reads as the design decision alone."

patterns-established:
  - "A batch that fixes a copy owner re-runs the full digest recipe R1-R4 in the same commit (subscription_live.ex is a source_digests input), then the aggregate sees fresh digests"

requirements-completed: []
requirements-advanced: [UXQ-04]

coverage:
  - id: F1
    description: "The DR-254-05 copy tests are red on the pre-fix tree from parsed ExUnit output: five failing tests, all keyed DR-254-05, every one an assertion failure, and the evidence file equals the parsed failures"
    requirement: UXQ-04
    verification:
      - kind: unit
        ref: "lab ExUnit run of subscription_action_copy_test.exs on 0f7b2b014 exited 2 (5 tests, 5 failures); verify_phase254_design_review.mjs --record-red --format exunit wrote 254-13-01-red-evidence.json and --check-red --format exunit reproduced it"
        status: pass
    human_judgment: false
  - id: F2
    description: "The result link label and href have one owner each and production and story both call them: five tests pass, the literal guard finds exactly one occurrence (copy.ex) after finding the seeded occurrence in a scratch repository, and the existing mounted result-link tests still pass"
    requirement: UXQ-04
    verification:
      - kind: unit
        ref: "subscription_action_copy_test.exs 5 tests 0 failures (lab and db-free); subscription_page_slice_test.exs 7, subscription_manifest_test.exs 22, subscription_compositions_manifest_test.exs 9 pass db-free; subscription_live_test.exs and subscription_journey_test.exs pass in the lab"
        status: pass
    human_judgment: false
  - id: F3
    description: "The design spec and the copy test run in the required owner: the Phase 253 aggregate passed with 12 serial lanes, 151 browser cells, phase254-action-copy 5 tests and phase254-design-browser 13 tests, and the newest results bundle names both"
    requirement: UXQ-04
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_phase253_compositions.mjs exited 0 (run c3c62d3a...); npm --prefix accrue_admin run phase252:check passed 21 commands; results.json contains subscription-design-phase254 and subscription_action_copy_test; verify_phase253_compositions.test.mjs 23 tests include the new lane inventory and design-evidence rejection scenarios"
        status: pass
    human_judgment: false
  - id: F4
    description: "Every digest artifact equals its regenerated value at the GREEN commit and the host copy export is byte-identical"
    requirement: UXQ-04
    verification:
      - kind: integration
        ref: "SubscriptionManifest.verify!/1 accepts the committed manifest and the regenerated guide equals the committed guide; verify_phase254_curation.mjs, phase254_selection.mjs project --check, phase254_budget.mjs restamp-manifest --check (DEV-254-21, f16cf209eada) and phase254_budget.mjs check pass; two mix accrue_admin.export_copy_strings --out runs left copy_strings.json at sha256 6a5e3920...d817 (no diff)"
        status: pass
    human_judgment: false
  - id: F5
    description: "The design review record is at stage corrected with fix_commit 88cd27cdc, every fixed finding tied to test ids and red evidence, both contract-amended findings tied to the edited 253-UI-SPEC.md rows, and AMD-254-04 and AMD-254-05 accepted by the verifier's rules"
    requirement: UXQ-04
    verification:
      - kind: unit
        ref: "node scripts/ci/verify_phase254_design_review.mjs --check --stage corrected exited 0 (9 findings, 16 captures, 7 verdicts, 6 deferrals; Markdown view current); node --test scripts/ci/verify_phase254_design_review.test.mjs 46 pass; --self-test 20 scenarios"
        status: pass
    human_judgment: false

human_judgment: false
duration: about 30 min
completed: 2026-10-29
status: complete
commits: 3
plan_head_before: 0f7b2b0145f08be2ec3ea69e4152cf9000e33343
plan_head_after: 09f37058c10b0e8a408bfc72108b7263452574ae
---

# Phase 254 Plan 13: Correction batch, copy part and batch close Summary

**The action-result link label and href now have one owner each (`Copy.subscription_action_activity_link_label/0`, `SubscriptionLive.action_activity_path/3`) used by the LiveView and the story adapter alike, proved red-then-green from parsed ExUnit output, admitted with the 254-12 design spec to two new lanes of the Phase 253 aggregate, and the design review record is closed at stage corrected.**

## Performance

- **Duration:** about 30 min of execution
- **Tasks:** 3 (3 commits: RED, GREEN, record)

## Accomplishments

- **254-13-01 RED (`68f9dd05d`):** five `DR-254-05` ExUnit tests on the pre-fix tree failed on their own assertions (owner functions absent; the label literal in two files). The positive control inside the literal guard (seeded scratch repository) passed, so the real-scan failure is evidence. `254-13-01-red-evidence.json` was written only by `--record-red --format exunit` and reproduced by `--check-red`.
- **254-13-02 GREEN (`88cd27cdc`):** `Copy.subscription_action_activity_link_label/0`; public `@doc false` `SubscriptionLive.action_activity_path/3` with the private socket wrapper delegating; `put_action_result` and the story adapter call both. Digest recipe R1 to R4 applied in the same commit. The aggregate gained `phase254-action-copy` (db-free ExUnit lane, five assertion bindings) and `phase254-design-browser` (the 254-12 spec, exact per-key counts 4/4/1/4).
- **254-13-03 (`09f37058c`):** record at stage corrected.

## Evidence for the next plans

- **Red evidence:** `254-12-01-red-evidence.json` (DR-254-01, 02:source, 03) and `254-13-01-red-evidence.json` (DR-254-05).
- **fix_commit:** `88cd27cdcede5f00594896b6b752069be7ede0ac`.
- **Final finding states:** DR-254-01 fixed, DR-254-02 contract-amended, DR-254-03 fixed, DR-254-04 contract-amended, DR-254-05 fixed, DR-254-06 deferred, DR-254-07 deferred, DR-254-08 deferred (re-dispositioned, no defect routed), DR-254-09 deferred. Amendments: AMD-254-03, AMD-254-04, AMD-254-05 (`affected_cells` = 102 routed cells outside the 16, recomputed from `eefee2a62958dbdefe426d5434ed133e91b3e8ec`; 10 inside).
- **Budget restamp:** `DEV-254-21`, cause `254-13-02`, manifest_sha256 `e29aeda0382c` to `f16cf209eada`.
- **Aggregate run:** `accrue_admin/tmp/phase253/ci-results/c3c62d3aebff6e428bfe1f44e4b9084e/results.json` (12 lanes, 151 browser cells, 152 compositions-lane tests).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The aggregate could not admit the tests as the plan worded it**
- **Found during:** Task 02. The plan says to "add" the design spec and copy test to the aggregate's lanes. The composition browser lane validates an exact cell universe plus reconcile project (`exactSet` of report identities against cell rows), so an extra spec fails it, and `exunitNoStart` takes a single file.
- **Fix:** two appended lanes with their own contracts (new `playwright-titles` reporter kind with `validateDesignEvidence`, source-bound per-key counts; db-free ExUnit lane), `REQUIRED_COMMAND_IDS` and `ASSERTION_BINDINGS` extended, and tests for the plan, the accepted control and six rejections. Appended after the existing ten so `plan[5]` and all earlier identities are unchanged.
- **Files modified:** `scripts/ci/verify_phase253_compositions.mjs`, `scripts/ci/verify_phase253_compositions.test.mjs` (neither is a manifest `source_digests` input).
- **Commit:** `88cd27cdc`

**2. [Rule 3 - Blocking] The plan's verify commands omit required arguments**
- The lab verify `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test ...` runs `mix` at the repository root and fails with "Could not find a Mix.Project"; I ran it with `sh -c "cd accrue_admin && MIX_ENV=test mix test ..."` exactly as the aggregate does. `mix accrue_admin.export_copy_strings` requires `--out`; I passed `--out ../examples/accrue_host/e2e/generated/copy_strings.json` as `scripts/ci/accrue_host_verify_browser.sh` does. No behavior of the plan changed.

**3. [Rule 1 - Bug] Four tests in `verify_phase254_design_review.test.mjs` pinned the real record at stage assessment**
- Moving the record to corrected is this plan's purpose, so the four real-record tests now assert stage corrected with stronger checks (no pending test, red evidence per fixed finding, the two contract-amended test lists, amendment ids, a stale-sha control at the new stage, and the CLI rejecting the other two stages beside a passing control).
- **Commit:** `09f37058c`

### Noted, not changed

- **Same defects elsewhere, not routed:** `charges_live.ex` repeated "Customer details" link name and `component_kitchen_live.ex` two aria-label-without-role summaries remain as 254-12 recorded them.
- **Presentation tests and the local compiled manifest:** after editing `subscription_live.ex`, `verify_phase253_presentation.test.mjs` fails until the aggregate regenerates the ignored `accrue_admin/tmp/phase253/manifest.json`; it passed (8 of 8) inside the aggregate and in the final run of the four contract test files (72 pass).
- **Host copy export:** the committed `copy_strings.json` contains neither the new label nor `subscription_action_recorded_info`, so the export is a filtered subset and was already fresh (no diff).
- **Gate by-products:** none; the only uncommitted file at the end is the pre-existing `.planning/config.json`, never staged. No stale e2e servers (port 4017 free before and after).

## Known Stubs

None.

## Threat Flags

None. T-254-25 (copy_strings drift): two consecutive exports left the same sha256 and no diff. T-254-38 (batch recorded without tests): `--check --stage corrected` requires tests, red evidence and the contract text per finding. T-254-SC: no dependency changed.

## Open flags for later plans

- **254-14 and 254-15 (baselines):** unchanged from 254-12: label, field-list and wrap changes alter detail, invoice and kitchen pixels; confirm `subscriptions.png` and `subscriptions-dark.png` stay byte-identical and trace any list change to A11Y-254-28 first.
- **254-15:** the pre-push gate now runs the two new aggregate lanes (about 20 s more); the first CI run of `phase254-design-browser` needs the lab browser lane in the `admin-phase200-guardrails` environment, which already runs the composition browser lane.
- **254-17 and 254-18:** UXQ-04 is declared by 254-15, 254-17 and 254-18, so it stays `requirements-advanced` here. The record is at corrected; `confirmed` (captures with png_sha256 and per-finding verdicts) is for 254-15.
- Editing `verify_phase253_compositions.mjs` is not a digest input; editing `subscription_live.ex`, `subscriptions_live.ex` or `copy.ex`-adjacent manifest sources again needs recipe R1 to R4.

## Self-Check: PASSED

Created files exist (`subscription_action_copy_test.exs`, `254-13-01-red-evidence.json`); commits `68f9dd05d`, `88cd27cdc` and `09f37058c` are ancestors of HEAD; `git rev-list --count 0f7b2b0145f08be2ec3ea69e4152cf9000e33343..HEAD` measured 3 before this summary commit.
