---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "03"
subsystem: testing
tags: [ci, github-actions, triage, playwright, storybook, phase252-lab, budget]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: 254-01 measure tooling and budget record, 254-02 guarded CI scripts and listable default Playwright projects
  - phase: 252-production-backed-subscription-stories
    provides: the production-boundary, lab and story lanes that ran on a CI runner for the first time here
  - phase: 253-real-groups-and-a-whole-subscription-job
    provides: the composition aggregate that ran on a CI runner for the first time here
provides:
  - the first CI-runner observations of the unchanged subscription lanes (29 attempt-1 informs_only samples with fingerprints and cache outcomes)
  - mechanical red triage (classifyRed, ownedPaths, triage verb) and DEV-254-02 closed with 32 settled entries
  - known_reds[] KR-254-01..06 with the owner's verbatim answers
  - the Phase 252/253 lanes and the Phase 200 guardrails job green on a hosted runner (CI 40805796792, Browser UAT 40805796802)
affects: [254-04, 254-07, 254-09, 254-15, 254-18]

actuals:
  tokens: 118000
  tasks: 3
  commits: 40

tech-stack:
  added: []
  patterns:
    - "A CI-only widening is keyed on GITHUB_ACTIONS=true and an explicit address class, never on the absence of a local check; every copy of the identity check carries the same rule"
    - "A lane that reads a gitignored proof must produce it itself; reproduce by deleting the file before believing a local pass"
    - "Run the whole job in a clean scratch worktree with no asdf, GITHUB_ACTIONS=true and fresh deps before spending a 30 minute CI cycle"

key-files:
  created:
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-03-CHECKPOINT-LOG.md
  modified:
    - scripts/ci/phase254_measure.mjs
    - scripts/ci/phase254_measure.test.mjs
    - accrue_admin/storybook/phase254-budget.json
    - accrue_admin/e2e/phase200-storybook-helpers.js
    - accrue_admin/e2e/admin-storybook-a11y-phase200.spec.js
    - accrue_admin/assets/js/hooks/dropdown.js
    - accrue_admin/priv/static/accrue_admin.js
    - accrue_admin/priv/static/storybook.css
    - accrue_admin/lib/accrue_admin/components/overlay.ex
    - scripts/dev/phase252_lab.mjs
    - scripts/ci/verify_phase252_production_boundary.mjs
    - scripts/ci/verify_phase253_compositions.mjs
    - .github/workflows/ci.yml
    - brandbook/tokens/harness/parity-check.mjs

key-decisions:
  - "Owner round 1: KR-254-01..04 all fix-in-phase (accept-known-red was never available for the owner-job entries)."
  - "Owner round 2: A 'CI-only private-range (Rec.)' fix-in-phase; B 'accept-known-red (Rec.)' until 254-18; no premature VERIFICATION or UAT artifacts."
  - "The overlay popover shell is a non-modal dialog, not role=menu: it hosts a heading, body and footer, which axe rejects as menu children; menus with menu items are DropdownMenu."
  - "The Phase 200 guardrails job runs on OTP 28.1 (as publish-hex.yml does) because Hex 2.4.2 cannot mix hex.build on OTP 28.0; the Phase 200 CI contract needle moved with it."
  - "The Phase 253 aggregate runs the transport-proof lane once before the manifest lane instead of reordering, because the runner's first-lane bookkeeping is positional."

patterns-established:
  - "Mechanical triage has a known weakness: extractFailingPaths takes the first path-like token in a log, so a lane whose failure is only in the uploaded results.json is mis-attributed"

requirements-completed: []
requirements-advanced: [CIQ-04]

coverage:
  - id: D1
    description: "First CI-runner observations of the unchanged subscription lanes are recorded with fingerprints, cache outcomes and attempt 1; no run was rerun"
    requirement: CIQ-04
    verification:
      - kind: integration
        ref: "node -e budget check from the plan: metrics.ci holds admin-phase200-guardrails and browser-uat samples with attempt 1, conclusion, fingerprint.image_os, numeric cache hits/misses and informs_only true (29 samples; runs listed below)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every red is classified by the mechanical triage and dispositioned; DEV-254-02 is closed with zero unresolved entries"
    requirement: CIQ-04
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap scripts/ci/phase254_measure.test.mjs (47 pass, 0 fail); node scripts/ci/phase254_measure.mjs --self-test (6 scenarios)"
        status: pass
      - kind: integration
        ref: "the plan's DEV-254-02 closing check exits 0: status accepted, closed_by 254-03, closing run ids 40805796792 and 40805796802, unresolved_entries 0, after.cells 166 >= before.cells 166"
        status: pass
    human_judgment: false
  - id: D3
    description: "The four owner-decided entries and the unmasked in-scope reds are fixed and re-observed as attempt 1 of new commits"
    requirement: CIQ-04
    verification:
      - kind: e2e
        ref: "Browser UAT 40805796802 success (a11y scan, action-menu geometry, Phase 211 gate); CI 40805796792 Admin Phase 200 deterministic guardrails success, 21 Phase 252 lanes and 10 Phase 253 lanes passed"
        status: pass
    human_judgment: false

duration: 9h
completed: 2026-10-28
status: complete
commits: 40
plan_head_before: eb92ca7da3c66027d53718a4e30dc641b7761522
plan_head_after: b7c3a67cd48ce48bbbff080b6bd10cddef5416d5
---

# Phase 254 Plan 03: First CI-runner observation and triage (W1) Summary

**The Phase 252/253 lanes ran on a hosted runner for the first time; 32 reds were triaged, every in-scope one fixed and re-observed as attempt 1, and the Phase 200 guardrails and Browser UAT jobs are green on head 396bebd2b with one owner-accepted known red.**

## Owner answers (verbatim)

- 254-03-01 push decision: "Yeah, I approve the push." (option push-approved)
- 254-03-03 round 1, per entry, all `fix-in-phase`:
  - KR-254-01 (docs-contracts SL-A, claim C1 `open_count: 0`): fix-in-phase
  - KR-254-02 (admin-phase200-guardrails, Storybook settled light/dark scan): fix-in-phase
  - KR-254-03 (browser-uat, same scan): fix-in-phase
  - KR-254-04 (browser-uat, action menu geometry at tablet-768): fix-in-phase
- 254-03-03 round 2:
  - A (admin-phase200-guardrails, phase252_lab loopback identity vs the Postgres service container bridge address): "CI-only private-range (Rec.)" -> fix-in-phase (KR-254-05)
  - B (docs-contracts SL-G "phase 254: zero artifacts discovered" and Executable UAT contract "missing automated UAT artifact"): "accept-known-red (Rec.)" -> accept-known-red until 254-18 (KR-254-06)

## Pre-push gate, push and observation runs

- Push: branch `gsd/phase-252-production-backed-subscription-stories`, upstream set, draft PR #58 (`isDraft` true, never changed). The pre-push gate passed on every pushed commit; the first push also needed 5a2b1aa3d. Final head `396bebd2b`.
- Final attempt-1 runs on `396bebd2b`: CI 40805796792, AccrueAdmin Browser UAT 40805796802. Reference origin/main runs: ci.yml 40387584954, accrue_admin_browser.yml 40361348536, critical-path median 1513 s.
- Attempt-1 runs recorded in `metrics.ci` (29 samples): CI 40727439541, 40732595137, 40735861913, 40742671473, 40745556555, 40749794325, 40772241218, 40776699867, 40780561652, 40785879805, 40788637630, 40792116994, 40798600410, 40800356007, 40805796792; Browser UAT 40727439599, 40732595360, 40735861909, 40742671507, 40745556594, 40749794313, 40772241229, 40776699800, 40780561519, 40785879793, 40788637635, 40792116996, 40800355998, 40805796802.
- One `workflow_dispatch` run (40771021813) minted the Linux visual baselines; it is a mint run, not a measurement sample.
- No job was rerun. Superseded pull_request runs were cancelled by the repository's own concurrency group.

## DEV-254-02 closing values

Status `accepted` (one accept-known-red), `closed_by` 254-03, `closing_measurement` `{run_ids: [40805796792, 40805796802], unresolved_entries: 0}`, `before {cells 166, owners 2}`, `after {cells 166, owners 2}`. 32 entries: each fixed with a `fixed_in_sha` and `followup_run_id`, pre-existing on main (the parked ratchet guardrails job, WINDOWS row 11), or matched by a `known_reds[]` decision.

## Fixes by entry

| Entry | Root cause | Fix commits |
|---|---|---|
| KR-254-01 | WINDOWS.md rows 41 and 42 open, so claim C1 measured 0 | f274cf40f closes both with executed test evidence (open_count 0) |
| KR-254-02/03 | The helper dispatched `psb:set-color-mode` before the LiveView joined (listener registered in the hook `mounted()`), page stories never receive the color-mode class, group stories host sandboxes in preview routes; once reachable the scan found a 2.22:1 dark link and an `aria-required-children` critical | 234c31f30, 4fed14b43, 7a7db0031 |
| KR-254-04 | `positionDropdown()` read the panel mid CSS transition; RED 4/8 under 8x CPU throttle, green 8/8 at 8x and 12x | 95e5ff595 |
| Phase 211 visual gate | intentional Phase 253 identity wrap (913 to 932 px) | 365338781, baselines minted on the runner |
| `production-packages` lane | no asdf on runners, missing deps for accrue and accrue_portal, Hex 2.4.2 `hex.build` fails on OTP 28.0 | 30f4504e6, 721472f18, a0397c884 |
| KR-254-05 (lab identity) | loopback-only server address assumed in five places, plus an inherited admin port | fd47a1dac, 30bbbbe15, d0120840c then cc5f6b200, 3258e94e0, a696e32ee |
| Release gate dialyzer (4 legs) | unreachable fallback clause created by the KR-254-05 edit | 30bbbbe15 |
| Phase 253 manifest lane | read a gitignored `transport.json` written by a later lane; passed locally on a leftover file | 396bebd2b |
| Brand-admin parity (not CI-observed) | the single-sourced light block's selector list hid the `html.accrue-admin` scope | 3fef7f655 |

## Known red (owner-accepted, KR-254-06)

Docs and bash contracts (shift-left) fails at SL-G because `STATE.md` points at phase 254, which has no committed `*-VERIFICATION.md` or `*-UAT.md` until 254-18; the Executable UAT contract step would fail the same way (reproduced locally, skipped behind SL-G on CI). Host integration, Playwright E2E shards and Host Docker smoke have `needs: docs-contracts-shift-left` and stay unobserved until then. No premature artifacts were generated. The parked ratchet guardrails job is also red, as on origin/main (waived, WINDOWS row 11).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Triage attributed the production-packages red to the wrong path**
- **Found during:** run 40763504835 triage
- **Issue:** `extractFailingPaths` takes the first path-like token in the job log, so a lane whose failure text lives only in the uploaded `results.json` was attributed to `e2e/admin-group-contracts.spec.js` (out-of-scope-branch-only); the failing path was the owned `verify_phase252_production_boundary.mjs`.
- **Fix:** classified by hand from the results bundle and recorded in the entry; the extractor itself is not changed here. Recommend preferring lane results over log scraping in a later plan.
- **Files modified:** accrue_admin/storybook/phase254-budget.json
- **Commit:** f402a62c1 / d3739014d

**2. [Rule 1 - Bug] Component semantics change: overlay popover is role=dialog, not role=menu**
- **Found during:** KR-254-02/03 (axe `aria-required-children`, critical, on `.ax-dropdown-panel`)
- **Fix:** `Overlay` popover renders `role="dialog"` with no `aria-modal`; its unit test updated. Menus with menu items remain `DropdownMenu`. No other consumer of the popover presentation exists outside the story and that test.
- **Commit:** 7a7db0031

**3. [Rule 3 - Blocking] CI workflow and contract edits**
- A deps step for accrue, accrue_portal and accrue_host in the Phase 200 guardrails job (721472f18, a696e32ee) and OTP 28.1 for that job (a0397c884), which also edits the pinned `otp-version` needle in `verify_phase200_ci_contract.sh`. Every other job keeps OTP 28.0.

**4. [Rule 2 - Missing critical] Test-support and config identity checks mirror the CI rule**
- `accrue_admin/config/test.exs`, `test/support/e2e_server.ex` and the scenario-repo test assert carry the same GITHUB_ACTIONS-only RFC 1918 allowance as `phase252_lab.mjs`; the lab has unit tests for CI-accepts-private, non-CI-rejects, public-rejected-in-CI and database/role mismatches, passing with and without `GITHUB_ACTIONS=true`. The Elixir mirrors are checked by the lane itself, not by unit tests.

**5. [Rule 1 - Bug] Dual-stack loopback made an equality pin wrong**
- d0120840c pinned the scenario-repo connection to the lab value; reproduced locally that psql (`::1`) and the test repo (`127.0.0.1`) can differ, so cc5f6b200 replaced it with the loopback list plus the CI private range.

### Process notes (not code deviations)

- The pre-push gate did not include the docs-contracts job, so SL-G, the parity audit and the Executable UAT contract were found only after the first full CI run; the job's steps were then run locally (the parity red was found and fixed that way). One push (30bbbbe15) was made before the gate finished; the gate passed on it afterwards.
- Local passes were repeatedly misleading: gitignored leftovers (`transport.json`) and the macOS `/var` symlink in `TMPDIR` masked or invented failures. The decisive proof was a clean scratch worktree with no asdf, `GITHUB_ACTIONS=true` and fresh deps running the whole Phase 200 guardrails script.
- D-24 attribution note for 254-09: the Phase 253 aggregate now runs `phase253-collection-live` once as a transport proof before `phase253-manifest-contract`; the cold compile is recorded in the bundle's `transport_proof` field, not in its `commands`.
- `accrue_admin/tmp/phase252/render-results.json` (tracked) was modified by failed local runs and restored from git; a stray beam process on port 4561 belonged to an unrelated project and was left alone.

## Known Stubs

None.

## Threat Flags

None added. The CI-only address allowance is limited to the three RFC 1918 IPv4 blocks under GITHUB_ACTIONS=true; public addresses are rejected there too and local runs stay strictly loopback (T-254-05 mitigations unchanged: census and no-home-paths passed on every pushed commit; T-254-SC: no installs, D-01 - dependency fetches in scratch worktrees used the existing lockfiles).

## Open flags for later plans

- `manifest_sha256` restamp of the budget record is still deferred to 254-09-02 (the budget file changed here only in `metrics.ci`, `known_reds` and `deviations`).
- host-integration, playwright-e2e and host-docker-smoke are unobserved until 254-18 (KR-254-06).
- `extractFailingPaths` should prefer lane results over log scraping.

## Self-Check: PASSED

All fourteen modified paths and the checkpoint log exist, the closing commit `b7c3a67cd` and the final code commit `396bebd2b` are ancestors of HEAD, `git rev-list --count eb92ca7da..HEAD` measured 39 before this summary commit (40 including it), the plan's DEV-254-02 closing check and the metrics.ci check both exit 0, the 47 measure tests and the 6-scenario self-test pass, and PR #58 is still a draft.

---
*Phase: 254-recurring-quality-reviewed-fixes-and-curation*
*Completed: 2026-10-28*
