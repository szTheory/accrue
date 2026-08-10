---
phase: 226-ci-baseline-proof-semantics
verified: 2026-08-10T22:05:00Z
status: gaps_found
score: 11/14 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "BASE-01: The durable comparable-run baseline includes queue delay and root-failure signature across the cohort."
    status: failed
    reason: "Only the anchor run records critical_queue_seconds; no run or aggregate contains a root-failure signature, so the required reviewable baseline facts are absent."
    artifacts:
      - path: ".planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json"
        issue: "No root_failure_signature field exists; runs 31332551817 and 31344524124 have no queue metric."
    missing:
      - "Capture and validate a privacy-safe root-failure signature and comparable queue metrics for every eligible run (or an explicit measured aggregate)."
  - truth: "BASE-01/BASE-02: The canonical three-run cohort and aggregate proof semantics are fail-closed."
    status: failed
    reason: "The verifier accepts a one-run baseline, accepts a baseline with every proved lane changed to skipped, and accepts a null critical queue metric."
    artifacts:
      - path: "scripts/ci/verify_ci_baseline_contract.sh"
        issue: "validate_input only requires a nonempty runs array and validates lane shape; it neither recomputes aggregate proof nor enforces cohort count, queue evidence, or aggregate derivation."
    missing:
      - "Make validate_input reject missing cohort/eligible-run invariants, missing measured fields, and aggregates inconsistent with the eligible required-proved lanes."
  - truth: "The new snapshot is eligible only when its workflow and six lockfile blobs equal the anchor snapshot."
    status: failed
    reason: "The equality is recorded in JSON but is not validated for an input baseline; deleting cohort provenance and reducing runs to one still returns success."
    artifacts:
      - path: "scripts/ci/verify_ci_baseline_contract.sh"
        issue: "validate_input does not require or compare anchor/cohort workflow_blob_oid and lockfile_blob_oids."
    missing:
      - "Require the complete anchor/cohort provenance shape and exact workflow plus six-lockfile equality in the contract, with a negative self-test."
---

# Phase 226: CI Baseline & Proof Semantics Verification Report

**Phase Goal:** Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Verified:** 2026-08-10T22:05:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Metadata-only record for run 31322443304 can be reproduced without logs, traces, payloads, environment values, or artifact archives. | ✓ VERIFIED | `capture_ci_baseline.sh` reduces API/fixture payloads to explicit allowlists; `--self-test` rejects injected `env` and query-token URL data. |
| 2 | The initial record reports 2,380s wall time, ~39m36s required chain, and seconds-scale queue. | ✓ VERIFIED | Canonical JSON records 2,380s and 11s queue for run 31322443304; baseline Markdown records the ~39m36s staged chain. |
| 3 | Observed lanes carry policy, conclusion, and proof_state; only qualifying required successes can be `proved`. | ✓ VERIFIED | JSON lanes carry the three fields; `validate_input` restricts `proved` to required, successful, eligible attempt-1 lanes. |
| 4 | Provider enforcement is sourced from effective-rules/classic-protection snapshot, not inferred from YAML. | ✓ VERIFIED | Canonical snapshot is `rules_response_state: ok`, `classic_response_state: not-found`, `enforcement_state: none-enforced`; README states this is captured snapshot evidence only. |
| 5 | Three eligible green, first-attempt workflow_dispatch runs exist; the two new runs use the cohort branch SHA. | ✓ VERIFIED | Runs 31322443304, 31332551817, and 31344524124 are eligible attempt 1; the latter two have `5da8e6b…`, matching `cohort.remote_snapshot.remote_sha`. |
| 6 | Inspected ineligible runs remain visible with an exclusion reason. | ✓ VERIFIED | `cohort.exclusions` is explicitly `[]`; no rejected candidate was inspected. Collector supplies `exclusion_reason` for non-eligible records. |
| 7 | Timing, cache, Docker/browser setup, rerun, provider, and root-failure facts are derived only from the eligible cohort. | ✗ FAILED | Wall/cache/rerun/provider facts are present, but no `root_failure_signature` exists and only the anchor has a queue metric. |
| 8 | Aggregate proof cannot be satisfied by skipped, advisory, or not-applicable observations. | ✗ FAILED | A mutated baseline with all `proved` lanes converted to `skipped` passed `verify_ci_baseline_contract.sh --input`. |
| 9 | Phase 227 selection requires measured cohort field, JSON path, and critical-path stage. | ✓ VERIFIED | `phase_227_selection_gate` has required field list and two candidates; repository contract requires nonempty evidence fields. |
| 10 | New snapshot eligibility requires exact workflow and six lockfile blob equality with anchor. | ✗ FAILED | Equality is recorded, but an input with `cohort` deleted and only one run still passes the contract. |
| 11 | CI/host ownership is explicit for Node/npm, browser/Playwright, Postgres, fixtures, ports, and server lifecycle. | ✓ VERIFIED | `226-SETUP-OWNERSHIP.md` matrix assigns each requested surface and links existing owner scripts. |
| 12 | Each setup failure has a diagnostic, owner, expected signal, and safe next action. | ✓ VERIFIED | Each ownership-matrix row contains all four fields and runnable commands. |
| 13 | Baseline contract runs in existing `docs-contracts-shift-left` without proof-topology rewiring; provider enforcement remains snapshot-scoped. | ✓ VERIFIED | Workflow has exactly one invocation at line 135; task-base diff adds only that step. Contract self-test rejects renamed `host-integration`. |
| 14 | Phase 225 required/advisory identities and Phase 192 artifact names remain stable. | ✓ VERIFIED | `verify_phase192_ci_contract.sh` passes; topology contract requires the three Phase 192 artifact names and release-gate required/advisory matrix policy. |

**Score:** 11/14 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/capture_ci_baseline.sh` | metadata-only collector | ✓ VERIFIED | 135-line executable; used by contract self-test with sanitized fixture inputs. |
| `scripts/ci/verify_ci_baseline_contract.sh` | baseline/proof/privacy/topology contract | ⚠️ PARTIAL | 175-line executable and CI-wired, but fails the three fail-closed invariants above. |
| `226-CI-BASELINE.json` | canonical cohort facts | ⚠️ PARTIAL | Substantive and consumed by contract; lacks root signature and full queue evidence. |
| `226-CI-BASELINE.md` | reviewable baseline | ✓ VERIFIED | Renders cohort, timing, proof/provider boundary, and selection gate from the stored baseline. |
| `226-SETUP-OWNERSHIP.md` | ownership/diagnostic matrix | ✓ VERIFIED | Linked from `scripts/ci/README.md` and references both owner scripts. |
| `scripts/ci/README.md` | discoverable CI entry point | ✓ VERIFIED | Phase-226 triage points to verifier and ownership runbook. |
| `.github/workflows/ci.yml` | existing shift-left invocation | ✓ VERIFIED | Exactly one added contract step in existing job; no job-key/needs change in phase diff. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| collector | GitHub Actions metadata APIs | versioned read-only `gh api` + jq allowlists | ✓ WIRED | `X-GitHub-Api-Version: 2022-11-28` and fixture path exercised by self-test. |
| contract | canonical JSON | schema/privacy/proof assertions | ⚠️ PARTIAL | It consumes JSON but omits critical cohort/proof/provenance validation. |
| baseline JSON | collector | collector-compatible run records | ✓ WIRED | Canonical records match collector's run/job/artifact schema. |
| baseline Markdown | Phase 227 selection | candidate evidence references | ✓ WIRED | Documents required selection inputs and cites eligible cohort. |
| workflow | contract | one docs-contracts-shift-left step | ✓ WIRED | `.github/workflows/ci.yml:135`. |
| ownership runbook | host UAT/browser scripts | existing command references | ✓ WIRED | Both `accrue_host_uat.sh` and `accrue_host_verify_browser.sh` are linked with diagnostics. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `capture_ci_baseline.sh` | run/jobs/artifacts/provider snapshot | GitHub Actions APIs or sanitized fixture files | allowlisted metadata | ✓ FLOWING |
| canonical JSON | CI baseline facts | three captured Actions runs plus recorded snapshot | real run IDs and timestamps | ⚠️ PARTIAL — required root signature/complete queue data absent |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Contract fixture and negative controls | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` | exit 0; expected unsafe-input mutations rejected | ✓ PASS |
| Canonical baseline validation | `bash scripts/ci/verify_ci_baseline_contract.sh` | exit 0 | ✓ PASS |
| Phase 192 artifact/CI contract | `bash scripts/ci/verify_phase192_ci_contract.sh` | exit 0 | ✓ PASS |
| Input must require three-run cohort | mutated one-run input | exit 0 (`ONE_RUN_ACCEPTED`) | ✗ FAIL |
| Input must require a proved lane | all-proved-to-skipped input | exit 0 (`NO_PROVED_ACCEPTED`) | ✗ FAIL |
| Input must require queue metric | null queue input | exit 0 (`NO_QUEUE_ACCEPTED`) | ✗ FAIL |

### Probe Execution

No phase-declared or conventional `probe-*.sh` scripts found; skipped.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 226-01, 226-02, 226-03 | Durable privacy-safe comparable baseline including timing, queue, jobs/steps, reruns, cache, Docker/browser, provider, and root signature | ✗ BLOCKED | Root-failure signature is absent; queue evidence is only present for anchor and core cohort invariants are not enforced. |
| BASE-02 | 226-01, 226-02, 226-03 | Required, skipped, and advisory evidence cannot be confused | ✗ BLOCKED | Vocabulary is visible, but a no-proved-lane baseline is accepted, so the claimed aggregate proof safeguard is not fail-closed. |
| OWN-01 | 226-03 | CI versus host Node/browser/Playwright ownership and diagnostics | ✓ SATISFIED | Full ownership matrix and command-first diagnostics are linked from `scripts/ci/README.md`. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| Phase-modified files | — | No unreferenced `TBD`/`FIXME`/`XXX`, placeholder, or empty implementation markers found | ℹ️ Info | No debt-marker blocker. |

## Human Verification Required

None. The blocking gaps are deterministically observable in the checked-in baseline and contract; provider branch-protection semantics are deliberately reported only as captured snapshot evidence, not claimed as live enforcement.

## Gaps Summary

The phase has substantial working evidence: a metadata-only collector, a three-run record, explicit provider-snapshot language, CI topology protection, and a useful host runbook. It does not yet achieve the durable, fail-closed baseline goal. The checked-in contract accepts materially incomplete or semantically invalid baselines, and the required root-failure signature is not recorded. These gaps are not deferred by Phase 227: its goal is a measured improvement using Phase 226's baseline, not construction of the missing baseline evidence/validation.

---

_Verified: 2026-08-10T22:05:00Z_
_Verifier: the agent (gsd-verifier)_
