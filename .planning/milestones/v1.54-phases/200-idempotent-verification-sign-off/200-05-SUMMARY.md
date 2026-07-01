---
phase: 200-idempotent-verification-sign-off
plan: "05"
subsystem: ci
tags: [phase200, guardrails, ci, playwright, storybook, scorecard, sign-off]
requires:
  - phase: 200-idempotent-verification-sign-off
    provides: Plan 200-02 rendered Storybook/page-flow browser evidence commands
  - phase: 200-idempotent-verification-sign-off
    provides: Plan 200-03 union scorecard generator and verifier
  - phase: 200-idempotent-verification-sign-off
    provides: Plan 200-04 judge/sign-off verifier contract
provides:
  - Serial local deterministic Phase 200 guardrail runner
  - Static guardrail command contract for local/package scripts
  - Static CI topology contract for the Phase 200 merge-blocking job
  - Phase 200 package aliases for Storybook, scorecard, sign-off, and guardrails
  - Merge-blocking CI job with Phase 200 evidence uploads
affects: [phase-200, ci, verification, storybook, sign-off]
tech-stack:
  added: []
  patterns:
    - serial bash guardrail runner with explicit step labels
    - static shell contracts that reject broad/model/human generation commands
    - CI job routes expensive browser verification through one deterministic runner
key-files:
  created:
    - scripts/ci/verify_phase200_admin_guardrails.sh
    - scripts/ci/verify_phase200_guardrail_contract.sh
    - scripts/ci/verify_phase200_ci_contract.sh
  modified:
    - accrue_admin/package.json
    - .github/workflows/ci.yml
key-decisions:
  - "Phase 200 CI uses a dedicated admin-phase200-guardrails job rather than mutating the Phase 192 guardrail job."
  - "The local runner always regenerates/verifies the union baseline and only runs full scorecard verification when final artifacts exist."
  - "CI invokes static contracts before the serial runner and does not inline broad Playwright, judge generation, or maintainer sign-off generation commands."
patterns-established:
  - "Package aliases expose direct deterministic Phase 200 commands while phase200:guardrails delegates to the repo-root runner."
  - "CI contract scripts inspect only the Phase 200 job run lines for forbidden direct commands, keeping the runner as the single orchestration surface."
requirements-completed: [VER-02, VER-03, STY-02, STY-03]
duration: 7m 14s
completed: 2026-06-30
status: complete
---

# Phase 200 Plan 05: Deterministic Guardrail Runner and CI Summary

**Deterministic Phase 200 guardrail runner, package aliases, and merge-blocking CI topology with static no-model/no-human command contracts**

## Performance

- **Duration:** 7m 14s
- **Started:** 2026-06-30T17:11:09Z
- **Completed:** 2026-06-30T17:18:23Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `verify_phase200_admin_guardrails.sh`, a serial repo-root runner with explicit labels for package docs, Storybook coverage/a11y, registry/group drift, page-flow, Phase 199, reduced-motion, scorecard, and sign-off verification.
- Added static local and CI contracts that require the expected Phase 200 commands and reject broad Playwright, visual/model scoring, screenshot/trace generation, judge generation, and maintainer sign-off generation paths.
- Added `phase200:storybook`, `phase200:scorecard`, `phase200:signoff`, and `phase200:guardrails` npm aliases in `accrue_admin/package.json`.
- Added the merge-blocking `admin-phase200-guardrails` GitHub Actions job with artifact uploads for Phase 200 generated evidence and Playwright output.

## Task Commits

1. **Task 1 RED: local guardrail contract** - `e35663cf` (`test`)
2. **Task 1 GREEN: local runner and package aliases** - `419000c8` (`feat`)
3. **Task 2 RED: CI topology contract** - `62551c0d` (`test`)
4. **Task 2 GREEN: CI guardrail job wiring** - `79f268eb` (`feat`)

## Files Created/Modified

- `scripts/ci/verify_phase200_admin_guardrails.sh` - Serial local deterministic Phase 200 runner.
- `scripts/ci/verify_phase200_guardrail_contract.sh` - Static contract for runner commands and Phase 200 package aliases.
- `scripts/ci/verify_phase200_ci_contract.sh` - Static contract for CI job topology, artifact uploads, annotation sweep inclusion, and forbidden CI run lines.
- `accrue_admin/package.json` - Adds Phase 200 deterministic command aliases.
- `.github/workflows/ci.yml` - Adds `admin-phase200-guardrails` and includes it in annotation sweep.

## Verification

| Command | Result |
| --- | --- |
| `bash -n scripts/ci/verify_phase200_admin_guardrails.sh` | Passed |
| `bash -n scripts/ci/verify_phase200_guardrail_contract.sh` | Passed |
| `bash scripts/ci/verify_phase200_guardrail_contract.sh` | Passed |
| `node -e "const pkg=require('./accrue_admin/package.json'); for (const k of ['phase200:storybook','phase200:scorecard','phase200:signoff','phase200:guardrails']) { if (!pkg.scripts[k]) throw new Error('missing '+k); } console.log('phase200 package scripts ok')"` | Passed |
| `PATH=/usr/bin:/bin:/usr/sbin:/sbin ruby -e "require 'yaml'; YAML.load_file('.github/workflows/ci.yml'); puts 'ci yaml ok'"` | Passed |
| `bash -n scripts/ci/verify_phase200_ci_contract.sh` | Passed |
| `bash scripts/ci/verify_phase200_ci_contract.sh` | Passed |

The full Phase 200 browser guardrail runner was not executed locally in this plan; the plan-level contract required static syntax/contract/YAML checks, and Plan 200-06 owns final full guardrail execution before ACCEPT.

## Decisions Made

- Added a dedicated `admin-phase200-guardrails` job so Phase 192 remains an archived hardening guardrail lane while Phase 200 can upload its own evidence package.
- Kept full scorecard verification conditional in the local runner: baseline-only verification is always deterministic, and full verification runs automatically once Plan 200-06 produces final artifacts.
- Routed CI through `verify_phase200_admin_guardrails.sh` instead of inlining Playwright or Node verifier commands, making the static CI contract small and enforceable.
- Left final `VER-03` ACCEPT and `.planning/REQUIREMENTS.md` reconciliation to Plan 200-06, which explicitly owns maintainer sign-off.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The TDD RED gates failed for their intended missing-runner and missing-CI-job reasons before GREEN implementation.

## Threat Notes

- T-200-17 mitigated by static local and CI contracts that require expected commands and reject model/human generation paths.
- T-200-18 mitigated by a serial runner that uses focused one-worker Playwright commands for stateful browser matrices.
- T-200-19 mitigated by stable `if: always()` artifact uploads for Phase 200 generated evidence and Playwright outputs.
- T-200-20 unchanged: uploaded paths are repo-local generated evidence only; no new secrets or external credentials were introduced.
- T-200-SC unchanged: no package-manager installs or dependency changes were performed.

## Auth Gates

None.

## Known Stubs

None. Stub scan over all created/modified files found no TODO, FIXME, placeholder, coming-soon, not-available, or hardcoded empty UI data patterns.

## TDD Gate Compliance

- RED commits present: `e35663cf`, `62551c0d`
- GREEN commits present after RED commits: `419000c8`, `79f268eb`
- No refactor commits were needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 200-06 can run `bash scripts/ci/verify_phase200_admin_guardrails.sh`, generate final scorecard/sign-off artifacts, replace the current REJECT draft with maintainer ACCEPT if all gates pass, and reconcile `VER-03` plus Phase 200 state.

## Self-Check: PASSED

- Created/modified source and CI files exist.
- Summary file exists.
- Task commits `e35663cf`, `419000c8`, `62551c0d`, and `79f268eb` are reachable in git history.
- No tracked file deletions were introduced by the plan task commits.
- Unrelated `.planning/research/.cache/` remains untracked and untouched.

---
*Phase: 200-idempotent-verification-sign-off*
*Completed: 2026-06-30*
