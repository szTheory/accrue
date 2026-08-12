---
phase: 226-ci-baseline-proof-semantics
verified: 2026-08-12T02:12:53Z
status: gaps_found
score: 2/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/4
  gaps_closed:
    - "Omitted baseline provider evidence normalizes to non_run."
    - "Incomplete declared prerequisite topology fails closed."
    - "The host wrapper preserves inner setup facts and falls back to host_gate_failure."
  gaps_remaining: []
  regressions:
    - "Live collector dependency lookup uses a workflow job ID (admin-drift-docs) while observed job records use normalized display names (admin-drift-and-docs)."
    - "Freshly successful provider proof records without prior --latest-proved input are rendered stale."
gaps:
  - truth: "A maintainer can inspect a durable comparable-run baseline from current GitHub Actions data."
    status: failed
    reason: "Live collection cannot resolve the real host-integration prerequisite because workflowNeeds() returns YAML job ID admin-drift-docs but records are indexed by normalized display name admin-drift-and-docs."
    artifacts:
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "workflowNeeds() line 234 and completedByName() line 148 use different identity namespaces; the authenticated live collection also aborts on unresolved declared prerequisites."
    missing:
      - "Use one stable job-identity namespace for workflow dependencies and observed Actions jobs (immediately use admin-drift-and-docs, or derive dependencies from workflow job IDs)."
      - "Add an integration fixture with current CI display names for Admin drift and docs, Host integration, and Docs contracts shift-left, then prove liveRuns/collectBaseline emits records."
  - truth: "Required, skipped, advisory, and non-run provider evidence is visibly and accurately distinct."
    status: failed
    reason: "A newly successful scheduled or manual provider proof receives no current latest_proved_at value, so its record is proved but stale and its summary falsely says Freshness: stale."
    artifacts:
      - path: "scripts/ci/provider_proof.mjs"
        issue: "baseRecord() derives stale from only input.latest_proved_at before classifyProviderProof() returns proved."
      - path: ".github/workflows/ci.yml"
        issue: "The provider finalization step supplies no --latest-proved value or trusted current completion timestamp."
    missing:
      - "On a proved result, bind latest_proved_sha and latest_proved_at to the current proof SHA and trusted manifest completion timestamp before freshness is rendered, or explicitly render current successful proof as fresh."
      - "Add a provider fixture and workflow-contract assertion proving a newly finalized successful provider proof is not stale."
---

# Phase 226: CI Baseline & Proof Semantics Verification Report

**Phase Goal:** Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Verified:** 2026-08-12T02:12:53Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A maintainer can inspect a durable, privacy-safe comparable-run baseline containing timing, reliability, setup/cache, queue/DAG-wait, provider-state, and root-failure facts. | ✗ FAILED | Schema/redaction gates and the frozen snapshot are substantive, but the documented authenticated live collection aborts. `workflowNeeds()` returns `admin-drift-docs`, while actual Actions job display name `Admin drift and docs` normalizes to `admin-drift-and-docs`; direct execution throws `job host-integration has unresolved prerequisite admin-drift-docs`. |
| 2 | The baseline identifies the measured staged release → host integration → Playwright critical path rather than runner queueing or summed work. | ✓ VERIFIED | Frozen-record gate passes. The rendered report has 20 compatible paths, p50 2083s, p95 2602s, and explicitly measures release-gate start through the latest Playwright shard. |
| 3 | Required, skipped, advisory, and non-run provider evidence is visibly and accurately distinct, so a lane cannot be misread as release proof. | ✗ FAILED | The classifier has distinct states, but its finalized current `proved` record has `latest_proved_at: null` and `stale: true`; the renderer says `Freshness: stale` for a proof completed in the current run. |
| 4 | Host maintainers can identify Node/browser/Playwright setup ownership and follow literal diagnostics for setup failure modes. | ✓ VERIFIED | `verify_ci_setup_diagnostics.sh` passes. The wrapper preserves inner setup facts and otherwise emits documented `host_gate_failure`; the ownership table covers Node, Playwright, Linux CI provisioning, and host gate failure. |

**Score:** 2/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` and schema/fixture gate | Privacy-safe comparable-run collection from Actions metadata | ⚠️ HOLLOW | Exists, substantive, and wired to schema/fixtures, but live dependency names cannot resolve observed job display names. |
| `226-CI-BASELINE.ndjson` and `226-CI-BASELINE.md` | Durable measured before-state and deterministic report | ✓ VERIFIED | 3,020 NDJSON records and 4,556-line Markdown report; frozen-record/byte-render critical-path gate passes. |
| `scripts/ci/provider_proof.mjs`, renderer, and CI finalize step | Correct proof state and freshness | ⚠️ PARTIAL | Components and workflow wiring exist, but the data flow omits prior/current proof freshness input and renders a current proof stale. |
| Setup registry, host wrapper, verifier, and README | Literal owner-first setup diagnostics | ✓ VERIFIED | Substantive scripts are wired through the wrapper and documented diagnostic matrix; focused shell contract passes. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Collector `workflowNeeds()` | Live Actions job completion map | normalized prerequisite identity lookup | ✗ NOT_WIRED | `admin-drift-docs` does not match actual normalized display name `admin-drift-and-docs`; collection fails closed instead of producing the durable account. |
| Frozen NDJSON | Generated baseline Markdown | deterministic renderer and byte comparison | ✓ WIRED | `verify_ci_baseline.mjs --records … --rendered … --require-critical-path` passes. |
| CI provider finalize step | Provider classifier/summary | workflow CLI flags → record → Markdown summary | ⚠️ PARTIAL | No `--latest-proved` or current completion input reaches the classifier, so freshness is false despite a newly proved record. |
| Host wrapper | Setup diagnostic registry | fact-file delta / `host_gate_failure` | ✓ WIRED | Wrapper and shell verifier prove inner-fact preservation, fallback, and success branches. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Baseline collector | `needs` → `completedByName` → `dag_wait_ms` | GitHub Actions job display names | No | ✗ DISCONNECTED: dependency names are YAML IDs while observed keys are normalized display names. |
| Critical-path report | staged spans | Frozen run/job records | Yes | ✓ FLOWING: 20 compatible complete paths and visible fingerprint strata. |
| Provider summary | `latest_proved_at`, `stale` | workflow finalization flags / manifest | No | ⚠️ STATIC: no previous or current proved timestamp is supplied; null deterministically becomes stale. |
| Setup summary | emitted diagnostic fact | host wrapper and registry | Yes | ✓ FLOWING: narrowed inner facts or aggregate fallback reach the documented owner/action/evidence record. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Baseline fixture engine | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | PASS | ✓ PASS |
| Frozen critical-path report | `node scripts/ci/verify_ci_baseline.mjs --records … --rendered … --require-critical-path` | PASS | ✓ PASS |
| Provider proof fixture engine | `node scripts/ci/verify_provider_proof.mjs --fixtures` | PASS, but no newly-proved freshness case | ✓ PASS (insufficient coverage) |
| Setup diagnostic contract | `bash scripts/ci/verify_ci_setup_diagnostics.sh` | PASS | ✓ PASS |
| Required-lane boundary | `bash scripts/ci/verify_phase225_required_lane_evidence.sh` | PASS | ✓ PASS |
| Formatter manifest contract | `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors` | 2 tests, 0 failures | ✓ PASS |
| CR-01 exact identity reproduction | `collectBaseline()` with actual display names and `needs: ["admin-drift-docs", …]` | Throws `job host-integration has unresolved prerequisite admin-drift-docs` | ✗ FAIL |
| CR-01 live read-only collection | `node scripts/ci/collect_ci_baseline.mjs --repo szTheory/accrue --workflow ci.yml --window-days 2 --sample-size 20 --out /dev/null` | Authenticated command exits with unresolved `docs-contracts-shift-left` prerequisite | ✗ FAIL |
| CR-02 current proof freshness | `classifyProviderProof()` with valid current manifest and no latest proof input | `{ proof_state: "proved", latest_proved_at: null, stale: true }`; summary says `Freshness: stale` | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 01, 02, 05, 06, 07, 12, 13 | Durable privacy-safe comparable CI baseline | ✗ BLOCKED | Privacy and frozen-artifact checks pass, but the production collection path cannot turn current Actions data into a baseline because prerequisite identity mapping fails. |
| BASE-02 | 03, 05, 06, 07, 12, 13 | Provider evidence visibly distinguishes proof states | ✗ BLOCKED | State labels are present, but stale freshness is part of the visible proof state; a current successful proof is falsely represented as stale. |
| OWN-01 | 04, 05, 07, 12, 13 | Host/CI ownership and setup diagnostics | ✓ SATISFIED | Owner-first registry, wrapper behavior, documentation, and focused shell contract are all present and passing. |

All requirement IDs declared in Phase 226 PLAN frontmatter are accounted for. `REQUIREMENTS.md` maps no additional Phase 226 requirements, so no requirements are orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | 148, 234 | Dependency identity namespace mismatch | 🛑 Blocker | A live comparable baseline cannot be collected from actual workflow jobs. |
| `scripts/ci/provider_proof.mjs` | 81-91, 122 | Current successful proof never updates freshness anchor | 🛑 Blocker | Maintainers receive a false stale signal for an immediately successful provider proof. |
| `scripts/ci/verify_ci_baseline.mjs` | staged fixtures | Test double omits real `Admin drift and docs` dependency path | ⚠️ Warning | Passing fixture suite does not exercise the workflow-display-name integration. |
| `scripts/ci/verify_provider_proof.mjs` | fixture controls | No assertion that a newly proved record is fresh | ⚠️ Warning | Passing provider suite does not exercise the faulty freshness transition. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in phase implementation files. There are no conventional or phase-declared probes to execute.

### Gaps Summary

The prior three gaps are closed and their focused contracts still pass. Two new critical defects independently reproduced from the current codebase prevent the phase goal: live Actions collection cannot make a durable baseline because dependency identities do not match observed jobs, and provider proof freshness mislabels the successful current proof as stale. Phase 227 is an optimization phase and does not explicitly schedule either baseline identity repair or provider-freshness correction, so neither gap is deferred.

_Verified: 2026-08-12T02:12:53Z_
_Verifier: the agent (gsd-verifier)_
