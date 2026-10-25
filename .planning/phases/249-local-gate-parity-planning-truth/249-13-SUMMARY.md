---
phase: 249-local-gate-parity-planning-truth
plan: "13"
subsystem: admin-lane-reverification
status: complete
completed: 2026-10-24
requirements-completed: [GREEN-02, GREEN-04, GREEN-05]
tags: [admin, replay, browser-uat, final-head]
key-files:
  modified:
    - .planning/phases/249-local-gate-parity-planning-truth/249-LOCAL-REPLAY.md
key-decisions:
  - "All admin lanes passed on first run at the final in-tree head; no fixes or classification rows needed"
  - "admin-ui-ratchet-guardrails recorded as ADVISORY (2 ADVISORY-FAIL, continue-on-error in CI, WINDOWS row 11), same verdict as 249-09"
  - "Pixel-diff step skipped; no baselines touched"
commits: 2
plan_head_before: 4daf8a8109dba34d00d2ab3306065b2ad4600ea3
plan_head_after: d51ee4a2
actuals:
  tokens: 15000
  tasks: 2
  commits: 2
coverage:
  - id: C1
    description: admin-drift-docs replays green at the final head
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --job admin-drift-docs --out $(mktemp -d) --run --skip 'Install Chromium' --skip 'Install Hex' --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA= (PASS=4 SKIP=1)"
        status: pass
    human_judgment: false
  - id: C2
    description: admin-group-contracts replays green at the final head
    requirement: GREEN-02
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --job admin-group-contracts --out $(mktemp -d) --run --skip 'Install Chromium' --skip 'Install Hex' --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA= (PASS=6 SKIP=2)"
        status: pass
    human_judgment: false
  - id: C3
    description: admin-hardening-guardrails replays green at the final head
    requirement: GREEN-04
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --job admin-hardening-guardrails --out $(mktemp -d) --run --skip 'Install Chromium' --skip 'Install Hex' --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA= (PASS=7 SKIP=2)"
        status: pass
    human_judgment: false
  - id: C4
    description: admin-phase200-guardrails replays green and Phase 200 output is removed
    requirement: GREEN-04
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --job admin-phase200-guardrails --out $(mktemp -d) --run --skip 'Install Chromium' --skip 'Install Hex' --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA= (PASS=6 SKIP=2); test ! -e .planning/phases/200-idempotent-verification-sign-off"
        status: pass
    human_judgment: false
  - id: C5
    description: admin-ui-ratchet-selftests replays green; ratchet-guardrails recorded advisory as CI treats it
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --job admin-ui-ratchet-selftests --out $(mktemp -d) --run --skip 'Install Chromium' --skip 'Install Hex' --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA= (PASS=5); same with --job admin-ui-ratchet-guardrails (exit 0, ADVISORY-PASS=2 ADVISORY-FAIL=2)"
        status: pass
    human_judgment: false
  - id: C6
    description: Non-visual browser-uat replays green at the final head with the pixel-diff step skipped
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --workflow .github/workflows/accrue_admin_browser.yml --job browser-uat --out $(mktemp -d) --run --skip 'Install Chromium' --skip 'Install Hex' --skip 'Phase 211 visual regression gate' --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA= (PASS=6 SKIP=3)"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 13: Admin lanes re-replayed at the final in-tree head Summary

All five blocking admin ci.yml jobs, the parked advisory ratchet-guardrails job and the non-visual browser-uat lane replay at the post-249-12 head with no failures and no fixes needed.

## Results

- Task 1 (859e3518): drift-docs PASS=4, group-contracts PASS=6, hardening-guardrails PASS=7, phase200-guardrails PASS=6, ratchet-selftests PASS=5; ratchet-guardrails exits 0 with the same two ADVISORY-FAIL steps as 249-09 (frozen evidence, sign-off), which are continue-on-error in CI and parked.
- Task 2 (d51ee4a2): browser-uat PASS=6 SKIP=3 (Hex, Chromium, Phase 211 pixel-diff), including the 463.9s browser UAT step.
- Phase 200 output from the phase200 job was moved to the session scratch directory; `.planning/phases/200-*` is absent. The tree has only the pre-existing untracked `.planning/milestone.lock`.
- The replay was run with the standard env (`GITHUB_EVENT_NAME=workflow_dispatch`, empty `BASE_SHA`/`BEFORE_SHA`). Random seeds, no retries, no observed flakes this run.

## Deviations from Plan

None. The plan's verify command omits `--env` flags; the replays used them as in 249-07..09 (github.event.* is unresolvable locally).

## Self-Check: PASSED

Commits 859e3518 and d51ee4a2 exist; ledger sections for both tasks are present in 249-LOCAL-REPLAY.md.
