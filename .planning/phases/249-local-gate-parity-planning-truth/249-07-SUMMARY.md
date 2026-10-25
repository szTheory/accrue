---
phase: 249-local-gate-parity-planning-truth
plan: "07"
subsystem: admin-browser-gates
status: complete
completed: 2026-10-24
requirements-completed: [GREEN-02, GREEN-04]
tags: [phase190, group-contracts, stale-contract, probe-classification]
key-files:
  created:
    - .planning/phases/249-local-gate-parity-planning-truth/249-PROBE-CLASSIFICATION.md
  modified:
    - accrue_admin/e2e/admin-group-contracts.spec.js
key-decisions:
  - "All failing probes classified stale-contract with commit receipts (b4a7eeac, e6f39cef); none were regressions"
  - "UTC disclosure kept enforced via nav accessible-name assertion instead of dropping the check"
commits: 2
plan_head_before: aaf05d08b3db047cc0425bc358a7f5203739ec1c
plan_head_after: a3719272768b3c3387038f8a6b6210ebfd80d79c
actuals:
  tokens: 30000
  tasks: 2
  commits: 2
coverage:
  - id: C1
    description: Phase 190 group-contract gate green on chromium-desktop and chromium-mobile after classifying and updating stale probes
    requirement: GREEN-04
    verification:
      - kind: command
        ref: "cd accrue_admin && MIX_ENV=test ACCRUE_ADMIN_E2E_PORT=4017 npm run e2e:group-contracts"
        status: pass
      - kind: command
        ref: "grep -c -E '\\| (stale-contract|regression) \\|' .planning/phases/249-local-gate-parity-planning-truth/249-PROBE-CLASSIFICATION.md"
        status: pass
    human_judgment: false
  - id: C2
    description: Full admin-group-contracts job replays green including compile and Phase 190 contract steps
    requirement: GREEN-02
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --job admin-group-contracts --out $(mktemp -d) --run --skip 'Install Chromium' --skip 'Install Hex' --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA="
        status: pass
      - kind: command
        ref: "bash scripts/ci/verify_phase190_automation_contract.sh"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 07: Phase 190 group-contract probes Summary

Three failing Phase 190 probes (six runs across desktop and mobile) were stale literals after intentional admin copy and header changes; the spec now asserts current values and the gate and full job replay are green.

## Outcomes

1. **Classification (285c01bd).** Baseline: 6 of 16 failed. Window label lost its trailing "UTC" in b4a7eeac; the invoices heading became "Invoices" in b4a7eeac; the webhook detail moved to the shared PageHeader group `webhook-detail-header` with new replay copy in e6f39cef (247-04). Fixing the first failure of each test revealed the two webhook assertions behind the invoice heading. All rows are `stale-contract` with commit and note receipts in `249-PROBE-CLASSIFICATION.md`.
2. **Specificity kept.** Window: visible `30 days` plus an assertion that `nav[aria-label*="UTC"]` is visible. Heading: exact role/name `Invoices`. Webhook: the new header group, observed-status role, and the exact new replay sentence (with the "Replay is unavailable" alternative retained).
3. **Job replay (a3719272).** `admin-group-contracts` replays PASS=6 SKIP=2 (Install Hex, Install Chromium); Lanes section recorded.

## Deviations from Plan

**1. [Rule 3 - Blocking] Replay step 02 needs event env.** Without `github.event.*` values the "Detect Phase 190 browser-relevant changes" step failed locally; replayed with `--env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA=`. No repo change.

**2. Plan expected 3 stale entries; 2 further webhook assertions surfaced** behind the first failure (as the plan anticipated in action step 5); handled identically.

## Known Stubs

None.

## Self-Check: PASSED

Commits 285c01bd and a3719272 present; spec and ledger exist; no skips/fixme added; no generated output left in tree.
