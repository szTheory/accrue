---
phase: 249-local-gate-parity-planning-truth
plan: "18"
subsystem: ci-host-custody
status: complete
completed: 2026-10-25
requirements-completed: [GREEN-05]
tags: [preview-custody, ci-absent-mode, host-integration, playwright-e2e]
key-files:
  modified:
    - scripts/ci/accrue_host_preview_custody.sh
    - scripts/ci/accrue_host_preview_custody_test_entry.mjs
    - scripts/ci/test_accrue_host_preview_custody.mjs
    - .github/workflows/ci.yml
commits: 3
plan_head_before: c566d233937745865b95244de31d015f84a7bc36
plan_head_after: 5d9229f6
actuals:
  tasks: 3
  commits: 3
coverage:
  - id: C1
    description: absent-mode negative controls and positives (volume, container, daemon error, docker missing, non-1 flag, foreign listener, snapshot/assert-preserved, env-fixture guard)
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "node --test --test-reporter=tap scripts/ci/test_accrue_host_preview_custody.mjs (28 pass, 0 fail; 18 absent-matching TAP lines)"
        status: pass
    human_judgment: false
  - id: C2
    description: test entry self-test and D-32 CI-script contract stay green
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "node --test scripts/ci/accrue_host_preview_custody_test_entry.mjs (6 pass); node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor (PASS)"
        status: pass
    human_judgment: false
  - id: C3
    description: flag set in exactly host-integration and playwright-e2e job env
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 yaml check over .github/workflows/ci.yml jobs env (['host-integration','playwright-e2e'])"
        status: pass
    human_judgment: false
  - id: C4
    description: archive sweep and docs-contracts replay (with 249-11 skips) green
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "node scripts/ci/verify_phase230_archive_invariants.mjs --repo . (pass 2, fail 0); 249-replay-ci-job.py --job docs-contracts-shift-left --run with PENDING-CLOSE skips (PASS=41 SKIP=7, rc 0; 2 UNRESOLVED need GITHUB_TOKEN / RELEASE_PLEASE_PR as before)"
        status: pass
    human_judgment: false
  - id: C5
    description: real local run with the flag refuses (positive control) and an invalid flag value refuses
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "ACCRUE_HOST_CUSTODY_CI_ABSENT=1 node scripts/ci/accrue_host_preview_custody.sh preflight browser (exit 2); ACCRUE_HOST_CUSTODY_CI_ABSENT=yes (exit 2)"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 18: Host custody CI absent-mode Summary

Explicit opt-in `ACCRUE_HOST_CUSTODY_CI_ABSENT=1` lets the host preview-custody check pass on hosted runners only when absence of any `accrue-host` preview is proven; the flag is set solely in host-integration and playwright-e2e.

## What changed

- `accrue_host_preview_custody.sh`: `ciAbsentMode()` (unset = today's path byte-for-byte; `1` = absent-mode; anything else refuses), `previewAbsence()` (ENOENT = absent; any labelled volume or container, spawn error or non-zero docker status refuses), `assertTarget()` split out so listener-ownership and proof-target checks still run in absent-mode. snapshot/assert-preserved record and re-verify `absent:<project>:<reason>`.
- Test entry accepts `snapshot` / `assert-preserved` and passes `absence` fixtures only through `run({ fixturePath })`; the caller-env fixture guard is untouched and tested with the flag set.
- `ci.yml`: flag plus two-line rationale comment in the two job-level env blocks.

## Real-run positive control (maintainer machine has a preview)

```
$ ACCRUE_HOST_CUSTODY_CI_ABSENT=1 node scripts/ci/accrue_host_preview_custody.sh preflight browser
[preview-custody] REFUSED: CI absent-mode found a accrue-host preview instance (10 volumes, 0 containers)
exit 2
$ ACCRUE_HOST_CUSTODY_CI_ABSENT=yes ... preflight browser
[preview-custody] REFUSED: ACCRUE_HOST_CUSTODY_CI_ABSENT must be unset or 1
exit 2
```

Only the script's own read-only docker queries ran.

## Deviations from Plan

None. Note: the plan said fixtures carry `absence` and an `env` override; no `env` override was needed because the flag is read from the spawned process environment, which the test helper already supplies.

## Receipt note

`scripts/ci/accrue_host_preview_custody.sh` is listed in the v1.66 Phase 245 capture `source_digests`. Its entry is now historical; `verify_phase245_baseline.mjs` live check will report it stale alongside app.css, under the deferred REQUIREMENTS item "Re-capture or formally retire drifted phase 245/248 evidence verifiers".

## Known Stubs

None.

## Self-Check: PASSED

Commits 5f4a12dd, 84f78f40, 5d9229f6 exist; modified files present.
