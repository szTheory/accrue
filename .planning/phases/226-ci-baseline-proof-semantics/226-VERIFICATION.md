---
phase: 226-ci-baseline-proof-semantics
verified: 2026-08-11T22:47:47Z
status: gaps_found
score: 2/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/4
  gaps_closed:
    - "Full-CI timing qualification now ignores provider_state and accepts non_run push/pull-request fixture cohorts."
    - "Baseline and provider timestamp validators now reject calendar-impossible UTC values via canonical round trips."
    - "The frozen report now contains a 20-run compatible staged-path measurement with p50/p95 values."
  gaps_remaining: []
  regressions: []
gaps:
  - truth: "The durable comparable-run baseline never records ordinary full-CI input as provider proof unless that proof was explicitly supplied."
    status: failed
    reason: "normalizeRun() defaults a missing provider_state to proved for every non-scheduled run; direct collector input can therefore persist false provider proof."
    artifacts:
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "Line 95 selects proved when provider_state is omitted; the fixture gate contains no omitted-state negative control."
    missing:
      - "Default omitted state to non_run or reject it, then add a successful push/pull-request missing-provider-state regression."
  - truth: "The durable baseline distinguishes root runner queue from dependent-job DAG wait without silently corrupting incomplete dependency topology."
    status: failed
    reason: "normalizeJob() drops unresolved prerequisites, then serializes an Infinity DAG wait as null; liveRuns() also removes unavailable dependencies before normalization."
    artifacts:
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "Lines 114-117 use filter(Boolean) before Math.max, while lines 260-261 erase unresolved needs; incomplete topology is reported as null rather than rejected."
    missing:
      - "Fail closed when any declared prerequisite lacks a completion and add a missing-prerequisite fixture."
  - truth: "Host setup diagnostics report the literal failing boundary and owner rather than reclassifying unrelated host-gate failures as browser-launch failures."
    status: failed
    reason: "The host wrapper emits browser_launch for every mix verify.full failure, including compile, database, formatting, generated-artifact, or other non-browser failures."
    artifacts:
      - path: "scripts/ci/accrue_host_uat.sh"
        issue: "Lines 48-50 unconditionally emit and render browser_launch after any delegated gate failure."
    missing:
      - "Preserve an inner emitted setup fact, or use a distinct accurately named wrapper failure code only when no lower-level diagnostic exists."
---

# Phase 226: CI Baseline & Proof Semantics Verification Report

**Phase Goal:** Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Verified:** 2026-08-11T22:47:47Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A durable, privacy-safe comparable-run baseline records trustworthy timing, reliability, cache/setup, queue/DAG-wait, and provider-state facts. | ✗ FAILED | Schema, redaction checks, and frozen records exist, but missing provider state becomes `proved` and an unresolved dependency becomes an indistinguishable null DAG wait. |
| 2 | The report provides a measured actual staged critical path rather than runner queueing or a summed aggregate. | ✓ VERIFIED | Frozen-record gate with `--require-critical-path` passes; the generated report states 20 compatible paths, p50 2083s and p95 2602s from release-gate start through the latest Playwright shard. |
| 3 | Required, skipped, advisory, and non-run provider evidence remain visibly distinct, so the checked-in full-CI account does not claim provider proof. | ✓ VERIFIED | `verify_provider_proof.mjs --fixtures` passes; all 228 frozen run records are `non_run`; the report explicitly says full-CI success is not live-provider proof. |
| 4 | Host maintainers receive literal, owner-first setup diagnostics across the documented failure boundaries. | ✗ FAILED | The shell contract passes its covered cases, but the top-level wrapper labels every `mix verify.full` failure `browser_launch`, including failures outside the browser boundary. |

**Score:** 2/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact group | Expected | Status | Details |
| --- | --- | --- | --- |
| Collector, schema, renderer, and baseline fixture gate | Privacy-safe normalization and comparable timing/reliability facts | ⚠️ HOLLOW | Files are substantive and wired; 2 provider/topology error paths can write misleading facts. |
| Frozen NDJSON and generated Markdown | Durable measured before-state | ✓ VERIFIED | 3,020 records (228 runs, 2,642 jobs, 149 cohort rows); fresh validation and byte comparison pass. |
| Provider classifier, summary renderer, and ExUnit formatter | Fail-closed, visible provider proof state | ✓ VERIFIED | State-machine fixture gate and focused formatter test pass; workflow wiring is present. |
| Setup diagnostic registry and host wrappers | Literal owner-first host/CI diagnostics | ⚠️ PARTIAL | Registry and verifier are substantive, but `accrue_host_uat.sh` overwrites unrelated final failures as browser failures. |
| CI workflow and maintainer documentation | Always-run evidence plumbing and triage | ✓ VERIFIED | Workflow exports provider/setup artifacts and docs point maintainers to the generated report and diagnostics. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `collect_ci_baseline.mjs` | `schema-v1.json` | strict record allowlists | ✓ WIRED | `validateRecord()` reads the schema and rejects unknown record fields. |
| `verify_ci_baseline.mjs` | collector and renderer | imported exports and fixture/record gates | ✓ WIRED | Both `--fixtures` and frozen-record/byte-render gates passed. |
| Frozen NDJSON | `226-CI-BASELINE.md` | deterministic renderer | ✓ WIRED | The rendered file is byte-identical under the verifier. |
| ExUnit formatter | provider classifier | `ACCRUE_PROVIDER_MANIFEST` in workflow finalize | ✓ WIRED | Provider fixtures and focused ExUnit test passed. |
| Host wrapper/workflow | setup diagnostic registry | emitted facts and always-run summary | ⚠️ PARTIAL | Wiring exists, but the wrapper's fallback code is too broad to preserve literal failure classification. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| Baseline collector | run/job/cohort timing facts | GitHub Actions run and job metadata | Yes, but omitted provider state and incomplete `needs` topology are not fail-closed. | ⚠️ PARTIAL |
| Critical-path report | selected per-run staged spans | Frozen NDJSON → `deriveStagedPathPercentiles` | Yes — 20 compatible complete paths, with eight visible fingerprint strata. | ✓ FLOWING |
| Provider summary | classified proof record | CI manifest → provider classifier → summary | Yes in fixtures, formatter test, and CI wiring. | ✓ FLOWING |
| Setup summary | setup fact record | host/CI scripts → diagnostic registry → artifact/summary | Partial — wrapper can append a false browser classification. | ⚠️ PARTIAL |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Baseline fixture engine | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | PASS | ✓ PASS |
| Frozen critical-path report | `node scripts/ci/verify_ci_baseline.mjs --records … --rendered … --require-critical-path` | PASS | ✓ PASS |
| Provider proof state machine | `node scripts/ci/verify_provider_proof.mjs --fixtures` | PASS | ✓ PASS |
| Formatter manifest contract | `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors` | 2 tests, 0 failures | ✓ PASS |
| Setup diagnostic contract | `bash scripts/ci/verify_ci_setup_diagnostics.sh` | PASS | ✓ PASS |
| Required-lane boundary | `bash scripts/ci/verify_phase225_required_lane_evidence.sh` | PASS | ✓ PASS |
| Missing provider state | `collectBaseline()` with a valid push fixture minus `provider_state` | Output persisted `provider_state: "proved"` | ✗ FAIL |
| Missing prerequisite | `collectBaseline()` with `needs: ["missing-prerequisite"]` | Output serialized `dag_wait_ms: null` rather than rejecting topology | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 01, 02, 05, 06, 07, 12 | Durable privacy-safe comparable CI baseline | ✗ BLOCKED | Core staged-path measurement is sound, but provider-state defaulting and DAG-wait topology corruption make the broader durable facts account unreliable. |
| BASE-02 | 03, 05, 06, 07, 12 | Provider evidence visibly distinguishes proof states | ✓ SATISFIED | Classifier/formatter fixture evidence, CI wiring, and the all-`non_run` frozen account meet the requirement. |
| OWN-01 | 04, 05, 07, 12 | Host/CI ownership and setup diagnostics | ✗ BLOCKED | A generic top-level browser failure code masks the actual owner/boundary for non-browser host-gate failures. |

All requirement IDs declared in Phase 226 PLAN frontmatter are accounted for. `REQUIREMENTS.md` maps no additional Phase 226 requirements, so none are orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | 95 | Non-scheduled input defaults to `proved` | 🛑 Blocker | A durable baseline can falsely claim provider proof. |
| `scripts/ci/collect_ci_baseline.mjs` | 114-117, 260-261 | Missing dependencies are erased/null-serialized | 🛑 Blocker | DAG wait is confused with absent wait, corrupting timing evidence. |
| `scripts/ci/accrue_host_uat.sh` | 48-50 | Unconditional `browser_launch` fallback | 🛑 Blocker | Host failure ownership/repair guidance can be false. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in the phase implementation files. The existing code-review findings were independently reproduced: CR-01 and WR-02 block the baseline truth; WR-01 blocks the ownership/diagnostic truth.

### Gaps Summary

The preceding re-verification gaps are closed: the non-run cohort predicate, canonical timestamp validation, and frozen critical-path evidence all work and their deterministic gates pass. However, three observable error paths still produce misleading durable facts. They are not deferred by Phase 227, whose roadmap contract is an optimization phase rather than a correction to baseline/proof/ownership semantics. The phase goal therefore remains unachieved until the collector and host wrapper fail closed or retain literal classifications.

_Verified: 2026-08-11T22:47:47Z_
_Verifier: the agent (gsd-verifier)_
