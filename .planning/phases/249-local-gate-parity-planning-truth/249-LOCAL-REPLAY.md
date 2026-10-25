# Phase 249 Local Replay Ledger

Created by 249-11; 249-12 and 249-13 append below.

- Replayed at HEAD: `0f802db0e13fe0dcd9fc53b27335a6e5bb3d6737` (clean tree; only untracked `.planning/milestone.lock`)
- Tool: `249-replay-ci-job.py`, sha256 `6e191296814eda299ca465f757ef928d5b7e85408e93270929512e1393eefb07`
- Date: 2026-10-24
- Env for github.event steps: `GITHUB_EVENT_NAME=workflow_dispatch BASE_SHA= BEFORE_SHA=`

## Job: docs-contracts-shift-left (PASS=41, SKIP=7, 0 red)

| # | Step | Result | Seconds |
|---|------|--------|---------|
| 04 | PR claims contract (SL-A) | PASS | 3.8 |
| 05 | Pipefail/SIGPIPE grep idiom ban (SL-D) | PASS | 0.4 |
| 08 | Sensitive token census (SL-C) | PASS | 1.8 |
| 10 | Install Accrue deps (reference scenario) | PASS | 1.5 |
| 11 | verify_package_docs.sh | PASS | 0.9 |
| 12 | Processor support matrix contract | PASS | 0.1 |
| 13 | Core LiveView-runtime-free (ENT-07 D-05) | PASS | 0.1 |
| 14 | Entitlement gate advisory-cache-free (ENT-10 D-04) | PASS | 0.0 |
| 15 | Dunning core Chimeway-free (DUN-03 D-04) | PASS | 0.0 |
| 16 | v1.17 friction + north-star SSOT | PASS | 0.1 |
| 17 | VERIFY-01 README contract | PASS | 0.1 |
| 18 | Docker DX contract | PASS | 0.3 |
| 19 | Production readiness discoverability | PASS | 0.0 |
| 20 | Adoption proof matrix | PASS | 0.1 |
| 21 | Reference scenario public-contract gate | PASS | 0.5 |
| 22 | Core admin invoice VERIFY flow id drift guard | PASS | 0.0 |
| 23 | Stable-core posture contract | PASS | 0.1 |
| 24 | No absolute home paths (PII guard) | PASS | 0.7 |
| 25 | Roadmap hygiene contract | PASS | 0.1 |
| 26 | Release notes freshness contract | PASS | 0.1 |
| 28 | Repository preservation transaction matrix (REPO-02) | PASS | 8.5 |
| 29 | Repository inventory units (REPO-01/02) | PASS | 6.5 |
| 30 | Repository inventory strict fixture contract | PASS | 2.9 |
| 31 | Final handoff invariants | PASS | 0.1 |
| 32 | Exact-SHA CI monitor/wrapper contract (REPO-03) | PASS | 1.1 |
| 33 | Repository truth gap-closure regression suite | PASS | 80.5 |
| 34 | Phase-evidence archive-path sweep (D-22) | PASS | 0.3 |
| 35 | Integration disposition triad (D-04/15/20/21/37) | PASS | 10.6 |
| 36 | Shared module-boundary guard (D-29) | PASS | 0.2 |
| 37 | Recut candidate shape/ancestry (D-01/04/07) | PASS | 9.2 |
| 38 | GATE-01 cohort triad (D-09/10/18) | PASS | 0.6 |
| 39 | Window dispositions triad (D-22/26/30/31) | PASS | 0.8 |
| 40 | Committed window dispositions at pinned SHA (D-16) | PASS | 0.1 |
| 41 | Hygiene dispositions triad (HYG-01) | PASS | 1.8 |
| 42 | Integration PR body contract (REL-04) | PASS | 0.2 |
| 43 | CI baseline triad (D-34) | PASS | 1.3 |
| 44 | CI script contract (D-32) | PASS | 148.0 |
| 48 | Verify tokens completeness (SC#1) | PASS | 0.2 |
| 49 | Verify specimen content coverage (SC#3) | PASS | 0.2 |
| 50 | Brand-admin token parity (SC#2) | PASS | 0.2 |
| 51 | Parity drift detection proof | PASS | 0.2 |
| 27 | Executable UAT contract self-test | SKIP (matched `--skip`, run explicitly below: PASS) | - |

### SKIP rows and reasons

| Step | Reason |
|------|--------|
| 07 SL-F committed PR body matches live PR body | Needs a live PR and GITHUB_TOKEN; routed to Phase 250 by CONTEXT. Not faked. |
| 45 Install tokens harness | Mutates tracked files; runs in a scratch clone in 249-14. |
| 46 Regenerate tokens + specimens | Same (249-14). |
| 47 Tokens/specimens reproducible (D-17) | Same (249-14). |
| 03 SL-E, 06 SL-G | Phase-close gates; see PENDING-CLOSE below. |
| 27 exec-UAT self-test | Matched the exec-UAT skip pattern; its `--self-test` half was run directly and passed. |

### Explicit halves of the phase-close gates (all exit 0)

| Command | Result |
|---------|--------|
| `node --test verify_completion_evidence.mjs` | PASS |
| `verify_completion_evidence.mjs --fixtures --require-completion-evidence --require-table-agreement` | PASS |
| `node --test verify_artifact_fixed_point.mjs` | PASS |
| `verify_artifact_fixed_point.mjs --fixtures --require-acyclic --require-fixed-point --require-digest-match` | PASS |
| `verify_executable_uat_contract.mjs --self-test` | PASS |
| `verify_executable_uat_contract.mjs --all-opted-in` | PASS |

### PENDING-CLOSE real runs (each exits non-zero, resolved by 249-17)

| Step | Observed failure text | Matches plan table? |
|------|-----------------------|---------------------|
| SL-E | `completion evidence: FAIL: GREEN-01 is marked Complete but no *-VERIFICATION.md exists in .planning/phases/249-local-gate-parity-planning-truth` | NO, see deviation |
| SL-G | `artifact fixed point: FAIL: phase 249: zero artifacts discovered -- refusing to report a pass over zero inspected artifacts` | Yes |
| exec-UAT | `executable UAT contract: FAIL: .../249-local-gate-parity-planning-truth: missing automated UAT artifact` | Yes |

**SL-E deviation.** The plan's permitted text (`zero Complete requirements parsed from the traceability table`) was
written assuming the traceability table had no Complete rows. Plans 249-01/03/06 ran `requirements mark-complete`, so
GREEN-01..05 and TRUTH-01/02 are now `Complete` and the gate advanced to its next check: a Complete requirement with
no phase `*-VERIFICATION.md`. The cause is the same close-only artifact (VERIFICATION.md is produced by 249-17), the
gate is not weakened, and no source defect exists. Recorded with its actual text; the 249-17 phase-close run must
turn it green.

## Job: release-manifest-ssot (PASS=5)

| # | Step | Result | Seconds |
|---|------|--------|---------|
| 03 | Install Accrue deps | PASS | 1.6 |
| 04 | Verify Release Please manifest vs mix.exs @version | PASS | 0.0 |
| 05 | Verify linked release contract | PASS | 0.8 |
| 06 | Verify grouped release-PR title round-trips | PASS | 0.0 |
| 07 | Release PR readiness dry run (REL-05) | PASS (no-token branch; GH_TOKEN unset) | 0.0 |

## Job: phase18-tax-gate (PASS=2, SKIP=1)

| # | Step | Result | Seconds |
|---|------|--------|---------|
| 03 | Install Hex | SKIP (matched `--skip`; local toolchain) | - |
| 05 | Install accrue deps | PASS | 1.5 |
| 06 | Run Phase 18 Stripe Tax gate | PASS | 1.2 |

## Job: ios-offline-client (PASS=1)

| # | Step | Result | Seconds |
|---|------|--------|---------|
| 02 | Verify iOS offline client package boundary | PASS | 4.1 |

No reds were found, so no source fixes were needed in this slice.
