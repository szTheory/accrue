---
phase: 226-ci-baseline-proof-semantics
verified: 2026-08-11T02:31:57Z
status: gaps_found
score: 11/14 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 11/14
  gaps_closed:
    - "Public collector-record and canonical validation now derive staged_critical_chain_seconds from policy-bound job timestamps."
    - "Public collector-record and canonical validation now derive root_failure_signature.category and ID from normalized failing-lane pairs."
  gaps_remaining:
    - "Canonical validation accepts privacy.logs_downloaded=true because its strict canonical predicate is overwritten by a later type-tree predicate."
    - "Canonical validation accepts a policy_manifest schema version that differs from the checked-in policy."
    - "Repository topology validation declares but does not compare matrix-expanded display names."
    - "The collector can mark a non-main workflow_dispatch run as eligible/release-proved while pairing it with main branch-protection data."
  regressions: []
gaps:
  - truth: "BASE-01: The canonical durable baseline remains privacy-safe and cannot claim raw logs were downloaded."
    status: failed
    reason: "A canonical copy with privacy.logs_downloaded=true passes the public --input validator."
    artifacts:
      - path: "scripts/ci/verify_ci_baseline_contract.sh"
        issue: "The strict def canonical at line 201 is overwritten by the type_tree-only def canonical at line 206, so its privacy false-value checks do not execute."
    missing:
      - "Compose the strict canonical predicate with the type-tree check (do not redefine it), require all four privacy collection booleans false in canonical mode, and add public true-flag mutations."
  - truth: "BASE-01: The durable comparable-run baseline is tied to the current versioned policy contract."
    status: failed
    reason: "The canonical input declares policy_manifest.schema_version 2 while the checked-in policy is version 3, and public canonical validation exits zero."
    artifacts:
      - path: "scripts/ci/verify_ci_baseline_contract.sh"
        issue: "validate_canonical_cohort type-checks policy_manifest at line 201 but never compares it to the checked-in manifest."
      - path: ".planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json"
        issue: "Its policy manifest snapshot is stale (schema_version 2)."
    missing:
      - "Require canonical policy_manifest.schema_version and workflow to equal the checked-in policy, then update canonical evidence deliberately and add a stale-version public mutation."
  - truth: "BASE-01: The versioned workflow policy remains an accurate authority for the live CI topology and future comparable-run collection."
    status: failed
    reason: "Changing the release matrix compatibility value from Floor to Foundation changes the rendered Actions display name but validate_repository_contract still exits zero."
    artifacts:
      - path: "scripts/ci/verify_ci_baseline_contract.sh"
        issue: "The release-support display_names loop at line 253 is a no-op; Playwright checks only the shard literal."
    missing:
      - "Derive and compare every policy display_names entry from the live release matrix and Playwright shard configuration; retain fail-first display-name drift mutations."
  - truth: "BASE-02: Provider evidence attached to an eligible run cannot be mistaken for main-branch release proof."
    status: failed
    reason: "Collector eligibility only checks event, first attempt, completion, and success. It neither retains nor requires head_branch/ref=main, although provider enforcement is fetched from /branches/main."
    artifacts:
      - path: "scripts/ci/capture_ci_baseline.sh"
        issue: "build_run lines 92 and 98-107 omit head_branch/ref and base_eligible has no main-scope predicate; lines 111-114 still capture main protection data."
    missing:
      - "Allowlist and record the run branch/ref, require main before eligible/release-proof publication, and add a feature-branch fixture that fails closed."
---

# Phase 226: CI Baseline & Proof Semantics Verification Report

**Phase Goal:** Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Verified:** 2026-08-11T02:31:57Z
**Status:** gaps_found
**Re-verification:** Yes — after Plan 10 gap closure and independent review

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A durable, privacy-safe comparable-run baseline contains workflow wall time, queue delay, job/step durations, reruns, cache/setup, provider state, and root signature. | ✗ FAILED | The data is present and Plan 10 authenticates chain/signature facts, but canonical mode accepts `privacy.logs_downloaded=true`, accepts a stale policy snapshot, does not validate topology display names, and collected runs need not be in the `main` protection scope. |
| 2 | Required, skipped, advisory, and non-applicable evidence is distinct; non-run evidence cannot be release proof. | ✗ FAILED | Lane-state derivation and exact required-lane completeness work, but a successful feature-branch dispatch can be represented with `/branches/main` protection data as eligible/release proof. |
| 3 | Maintainers can identify CI versus host Node/browser/Playwright setup ownership and diagnose each documented failure mode. | ✓ VERIFIED | `226-SETUP-OWNERSHIP.md` gives CI/host owner, first command, expected signal, and safe action for Node, npm, Chromium, Playwright, Postgres, fixtures, ports, and server lifecycle. |
| 4 | The measured 33–36 minute green-run critical path is staged release → host integration → Playwright work, not queueing. | ✓ VERIFIED | The checked-in cohort has 2/3/5-second queues and 2376/2683/2176-second chains. Fresh coherent-duration forgery is rejected by the public validator after timestamp re-derivation. |
| 5 | Collection and both public modes bind workflow origin, complete release proof, and live topology to policy. | ✗ FAILED | Workflow-name and lane-completeness checks work, but canonical policy version is not bound and generated display-name topology is not compared to the policy. |
| 6 | Exactly three eligible green first-attempt dispatches with fixed workflow/six-lockfile provenance form the cohort. | ✓ VERIFIED | Canonical IDs are 31322443304, 31332551817, and 31344524124; fixed ID/provenance and public canonical checks pass. |
| 7 | Eligible-only aggregates retain timing, cache/setup, rerun, provider, and normalized root-failure facts. | ✓ VERIFIED | `candidate_derived_run_semantics` runs before `validate_aggregates`; coherent per-run chain/aggregate and category-ID forgeries are rejected. |
| 8 | Phase 227 selection is constrained to measured cohort fields and a critical-path stage. | ✓ VERIFIED | `phase_227_selection_gate.required_evidence_fields` is exactly the four required contract fields. |
| 9 | Provider enforcement is captured from effective-rules/classic-protection data and errors cannot imply no enforcement. | ✓ VERIFIED | Fixture error paths in the self-test fail; only confirmed classic 404 becomes `not-found`. |
| 10 | Inspected ineligible evidence retains exclusion reasons and zero proved lanes. | ✓ VERIFIED | Exact-schema and public ineligible-proof mutations enforce this distinction. |
| 11 | The contract executes once in the existing shift-left CI job without changing protected identities. | ✓ VERIFIED | `.github/workflows/ci.yml:134-135` invokes it once; `verify_phase192_ci_contract.sh` passes. |
| 12 | The documented ownership route and Phase 192 artifact contract remain stable. | ✓ VERIFIED | Ownership commands are present in the runbook and the Phase 192 verifier exits zero. |
| 13 | Collector records have a strict scalar identifier boundary. | ⚠️ WARNING | Collector-record schema still accepts fractional `run.id`/job/artifact IDs because it checks `type==number`, not integer. This is an observable schema weakness, not a separate roadmap blocker. |
| 14 | The versioned policy is substantive and consumed by collection, public validation, and repository topology validation. | ✓ VERIFIED | The 18-lane policy is consumed by collector and both public validators; its generated-display-name enforcement is nevertheless incomplete (gap 2). |

**Score:** 11/14 truths verified (0 present, behavior-unverified)

### Plan Must-Have Coverage

All ten PLAN frontmatters were checked. Their detailed truths consolidate into the fourteen observable contracts above. Plan 10's duration/category predicates and negative controls are present and pass fresh public mutations. Plans 01–09 remain blocked where their claimed policy/current-topology/main-protection linkage is falsified by the three gaps above; no plan must-have reduces the four ROADMAP success criteria.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/ci_baseline_workflow_policy.json` | Versioned workflow/lane/topology authority | ⚠️ PARTIAL | Substantive 18-lane manifest, but its declared matrix display names have no live generated-name comparison. |
| `scripts/ci/capture_ci_baseline.sh` | Metadata-only Actions collector | ✗ PARTIAL / BLOCKER | Read-only allowlisted collection works, but it does not capture or require the `main` ref before eligible/release-proof publication. |
| `scripts/ci/verify_ci_baseline_contract.sh` | Fail-closed evidence/proof validator | ✗ PARTIAL / BLOCKER | Plan 10 derived facts are correctly authenticated, but canonical privacy flags, policy freshness, and generated matrix topology are not fail-closed. |
| `226-CI-BASELINE.json` | Authoritative three-run cohort | ✗ HOLLOW TRUST BOUNDARY | Its stated no-logs posture and schema-version-2 policy snapshot are accepted without the required current-policy/privacy binding. |
| `226-CI-BASELINE.md` | Derived human rendering | ✓ VERIFIED | Identifies JSON authority and contains no raw logs, traces, payloads, archives, or server output. |
| `226-SETUP-OWNERSHIP.md` / `scripts/ci/README.md` | Ownership matrix and discovery route | ✓ VERIFIED | Command-first runbook links existing host scripts and states ownership boundaries. |
| `.github/workflows/ci.yml` | Existing shift-left invocation | ⚠️ PARTIAL | Exactly one invocation is present, but a release-matrix value can drift from policy-generated display names without the repository gate failing. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Collector | Actions metadata APIs | Versioned read-only `gh` GETs, immediate `jq` allowlists | ✓ WIRED | No raw-log/archive/payload retrieval path. |
| Run metadata | `policy.workflow` | Collector and public-validator equality | ✓ WIRED | Non-`CI` workflow mutations reject. |
| Run branch/ref | `main` protection snapshot | Eligibility/release-proof binding | ✗ NOT WIRED | Main protection is fetched independently; collector omits `head_branch`/ref and does not require `main`. |
| Eligible jobs | Required policy identities | Exact observed/proved identity sets | ✓ WIRED | Required-lane removal rejects. |
| Chain timestamps | `run.staged_critical_chain_seconds` | Policy-bound shared derived-run predicate | ✓ WIRED | Fresh coherent aggregate forgery rejects. |
| Failing lanes | Signature category and ID | Pair-derived category and versioned ID | ✓ WIRED | Fresh all-success category forgery rejects. |
| Canonical privacy flags | No raw diagnostic collection claim | Canonical public validator | ✗ NOT WIRED | `privacy.logs_downloaded=true` passes because the strict canonical predicate is overwritten. |
| Live matrix values | `workflow_topology.display_names` | Repository topology validator | ✗ NOT WIRED | `display_names` loop is a no-op; `Floor`→`Foundation` mutation exits zero. |
| Canonical policy snapshot | Checked-in policy | Canonical public validator | ✗ NOT WIRED | Candidate schema version 2 passes against policy version 3. |
| CI workflow | Validator | `docs-contracts-shift-left` step | ✓ WIRED | `.github/workflows/ci.yml:134-135`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Collector | Runs, jobs, artifacts, provider snapshot | GitHub Actions metadata APIs / strict fixtures | ⚠️ UNSCOPED | Real metadata flows, but the run's branch/ref is discarded while provider data is specifically for `main`. |
| Baseline cohort | Queue, staged-chain, proof, provider, root signature | Stored three-run job metadata | ⚠️ UNSAFE BOUNDARY | Timing/signature are authenticated, but canonical privacy flags and policy snapshot freshness are not. |
| Ownership runbook | Owner/diagnostic commands | Existing CI and host scripts | ✓ FLOWING | Referenced commands exist in scripts/workflow. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Checked-in baseline and repository contract | `bash scripts/ci/verify_ci_baseline_contract.sh` | Exit 0 | ✓ PASS |
| Adversarial validator suite | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` | Exit 0; expected negative-control errors then `self-test ok` | ✓ PASS |
| Phase 192 preservation | `bash scripts/ci/verify_phase192_ci_contract.sh` | Exit 0 | ✓ PASS |
| Plan 10 coherent duration forgery | Canonical copy: change per-run duration and coherent aggregate | Non-zero: `candidate staged critical-chain timing failed` | ✓ PASS |
| Plan 10 category forgery | Canonical copy: recompute forged all-success signature category/ID | Non-zero: `canonical cohort contract failed` | ✓ PASS |
| Canonical privacy claim | Canonical copy: set `privacy.logs_downloaded=true` | Exit 0 | ✗ FAIL |
| Review CR-01: stale policy version | Canonical copy with `policy_manifest.schema_version=2` | Exit 0 | ✗ FAIL |
| Review CR-02: matrix display-name drift | Temporary CI copy with `Floor`→`Foundation`, then `validate_repository_contract` | Exit 0 | ✗ FAIL |
| Review CR-03: main-scope eligibility | Static source trace of `build_run` and `base_eligible` | No `head_branch`/ref capture or main predicate; protection fetch remains `/branches/main` | ✗ FAIL |

### Probe Execution

No phase-declared or conventional `probe-*.sh` scripts exist; skipped.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 226-01 through 226-10 | Durable privacy-safe baseline of comparable workflow/timing/provider/signature facts | ✗ BLOCKED | Canonical mode accepts `logs_downloaded=true`, a stale policy snapshot, and undetected generated display-name drift; non-main runs can also be marked eligible. |
| BASE-02 | 226-01 through 226-09 | Required/skipped/advisory evidence cannot be confused with release proof | ✗ BLOCKED | Exact lane vocabulary works, but main branch-protection evidence can be paired with a feature-branch run and presented as release proof. |
| OWN-01 | 226-03 through 226-09 | CI versus host setup ownership and diagnostics | ✓ SATISFIED | Substantive ownership matrix, README route, CI invocation, and Phase 192 preservation check pass. |

All three IDs declared across the ten phase plans are accounted for. `REQUIREMENTS.md` maps no additional requirement to Phase 226, so there are no orphaned requirements. Phase 227 only improves an already trustworthy critical path and does not explicitly repair these evidence-authentication gaps; none is deferred.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/ci/verify_ci_baseline_contract.sh` | 201 | Canonical policy manifest type-checked but not matched to current policy | 🛑 Blocker | Stale evidence contract is accepted. |
| `scripts/ci/verify_ci_baseline_contract.sh` | 201, 206 | Duplicate `def canonical` overwrites strict privacy/schema predicate | 🛑 Blocker | Canonical `privacy.logs_downloaded=true` is accepted. |
| `scripts/ci/verify_ci_baseline_contract.sh` | 253 | `display_names` loop is a no-op | 🛑 Blocker | Live matrix display-name drift escapes policy topology gate. |
| `scripts/ci/capture_ci_baseline.sh` | 92, 98-107, 111-114 | Main protection snapshot is paired with branch-unspecified eligible run | 🛑 Blocker | Non-main run may be misrepresented as main release proof. |
| `scripts/ci/verify_ci_baseline_contract.sh` | 156-160 | Collector scalar IDs accept non-integer numbers | ⚠️ Warning | Fractional provider identifiers cross public collector schema. |
| Phase-modified files | — | No unreferenced `TBD`, `FIXME`, or `XXX` markers found | ℹ️ Info | No debt-marker blocker. |

### Human Verification Required

None. Every unresolved condition is reproducible by a local public validator or static source trace. This is an Escalation Gate to implementation revision, not a UAT decision.

### Gaps Summary

Plan 10 genuinely closes the two prior BASE-01 gaps: the public boundary now authenticates duration from policy-bound timestamps and signature classification from failing-lane pairs. That does not achieve the phase goal. Canonical mode accepts a false no-raw-logs claim and an obsolete policy version, the topology gate does not prove generated matrix display names match live CI, and the collector can attach main branch-protection facts to a successful run from another branch. These failures directly undermine privacy, comparable-run, and provider-proof semantics; Phase 227 does not schedule a repair for them.

---

_Verified: 2026-08-11T02:31:57Z_
_Verifier: the agent (gsd-verifier)_
