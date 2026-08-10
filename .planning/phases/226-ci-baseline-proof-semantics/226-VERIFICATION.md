---
phase: 226-ci-baseline-proof-semantics
verified: 2026-08-10T21:55:03Z
status: gaps_found
score: 9/14 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 11/14
  gaps_closed:
    - "Canonical cohort count, aggregate proof, measured-field presence, and six-lockfile provenance now have negative controls."
  gaps_remaining:
    - "The privacy contract accepts arbitrary unknown keys and their values."
    - "A classic-protection API failure is recorded as not-found."
    - "Collector output cannot be validated through the documented --input path."
    - "An ineligible run can contain proved lanes."
    - "The stored queue metric is elapsed critical-path time rather than runner queue delay."
  regressions: []
gaps:
  - truth: "BASE-01: The durable baseline is privacy-safe and rejects raw evidence."
    status: failed
    reason: "The verifier uses a forbidden-key blacklist rather than an allowlisted schema; a token-like value under an unrecognised benign key is accepted."
    artifacts:
      - path: "scripts/ci/verify_ci_baseline_contract.sh"
        issue: "Lines 67-68 reject only selected key names and query URLs."
    missing:
      - "Recursively validate the exact allowed object keys and scalar types; add a negative self-test for an unknown key containing sensitive-looking content."
  - truth: "BASE-01: Provider required-check state is an authenticated snapshot, not an inference from a failed provider request."
    status: failed
    reason: "Any failure fetching classic branch protection is converted to not-found and can produce none-enforced."
    artifacts:
      - path: "scripts/ci/capture_ci_baseline.sh"
        issue: "Line 74 maps all non-zero classic API outcomes to response_state not-found."
    missing:
      - "Distinguish a confirmed HTTP 404 from authentication, transport, rate-limit, server, and malformed-response errors; fail collection for every non-404 failure."
  - truth: "BASE-01/BASE-02: Collected metadata is independently verifiable and proves only qualifying required first-attempt dispatch lanes."
    status: failed
    reason: "The collector emits a one-run record without cohort or aggregates but --input always requires the fixed canonical three-run cohort; separately, classification marks successful required jobs as proved without considering run eligibility."
    artifacts:
      - path: "scripts/ci/capture_ci_baseline.sh"
        issue: "Line 67 derives proved from job policy/conclusion only."
      - path: "scripts/ci/verify_ci_baseline_contract.sh"
        issue: "Lines 57-65 require canonical cohort/provenance for every --input, rejecting collector output."
    missing:
      - "Split collector-record validation from canonical-cohort validation, and pass run eligibility into proof-state derivation so reruns/non-dispatch runs cannot be proved."
  - truth: "BASE-01: The baseline distinguishes the staged 33-36 minute critical path from runner queueing and retains complete timing/failure evidence."
    status: failed
    reason: "critical_queue_seconds is calculated as the latest start of serial dependent critical-chain jobs minus run creation: 2,366/2,670/2,167 seconds, while the earliest job starts after only 2/3/5 seconds. The collector also omits API pagination and root signature IDs omit normalized failure conclusions."
    artifacts:
      - path: "scripts/ci/capture_ci_baseline.sh"
        issue: "Lines 59-60 do not paginate jobs/artifacts; line 69 derives queue from latest critical-chain start and signature from lane IDs only."
      - path: ".planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json"
        issue: "The record labels near-wall-time values as queue despite its provider timestamps showing seconds-scale initial queue."
    missing:
      - "Record runner queue from the appropriate initial/root job start boundary, retain staged-chain duration separately, paginate or reject incomplete lists, and include sorted normalized lane-conclusion pairs in the signature and its verification."
---

# Phase 226: CI Baseline & Proof Semantics Verification Report

**Phase Goal:** Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Verified:** 2026-08-10T21:55:03Z
**Status:** gaps_found
**Re-verification:** Yes — after Plan 04 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Metadata-only record for run 31322443304 can be reproduced and safely validated without logs, traces, payloads, environment values, or artifact archives. | ✗ FAILED | Collector avoids log/archive endpoints, but its output is rejected by its documented `--input` path and the verifier accepted an injected `.runs[0].run.evidence = "ghp_exampletokenvalue"`. |
| 2 | Baseline timing distinguishes the staged critical path from seconds-scale runner queueing. | ✗ FAILED | Earliest jobs begin 2/3/5 seconds after each run is created; the stored “queue” is instead 2,366/2,670/2,167 seconds because it uses the latest serial-chain job start. |
| 3 | Every observed lane has distinct policy, conclusion, and proof state; only a qualifying required success can be proved. | ✗ FAILED | A synthetic successful `pull_request`, attempt-2 run was collected with 17 required job observations marked `proved`. |
| 4 | Provider enforcement comes from an effective-rules/classic-protection snapshot, not YAML or an unknown API failure. | ✗ FAILED | `capture_ci_baseline.sh:74` maps every classic API failure to `not-found`, which can falsely render `none-enforced`. |
| 5 | Exactly three eligible green first-attempt dispatches, with documented anchor/cohort SHA provenance, form the canonical cohort. | ✓ VERIFIED | Canonical IDs are 31322443304, 31332551817, and 31344524124; contract self-test rejects altered eligible cohort/provenance. |
| 6 | Inspected ineligible runs remain visible with an exclusion reason. | ✓ VERIFIED | The canonical record has no inspected exclusions; its contract requires a nonempty exclusion reason for every noneligible record. |
| 7 | Eligible-only aggregates retain complete timing, cache, Docker/browser, rerun, provider, and normalized root-failure facts. | ✗ FAILED | Job/artifact APIs are only requested at `per_page=100`; overflow is silently omitted. Root signatures do not include conclusion, and the queue aggregate has the wrong semantic meaning. |
| 8 | Aggregate release proof cannot be satisfied by skipped, advisory, or not-applicable observations. | ✓ VERIFIED | `validate_aggregates` recomputes the required manifest identity set from eligible jobs; self-test rejects all proved-to-skipped and aggregate mutations. |
| 9 | Phase 227 selection requires measured cohort field, JSON path, and critical-path stage. | ✓ VERIFIED | Canonical selection gate and repository contract require eligible IDs, JSON paths, measured range, and affected stage. |
| 10 | New snapshot eligibility requires exact workflow and six lockfile blob equality with anchor. | ✓ VERIFIED | Contract checks exact key set/equality and self-test separately deletes/changes every lockfile plus workflow OID. |
| 11 | CI/host ownership is explicit for Node/npm, browser/Playwright, Postgres, fixtures, ports, and server lifecycle. | ✓ VERIFIED | `226-SETUP-OWNERSHIP.md` provides the requested matrix and points to established owner scripts. |
| 12 | Setup failures have diagnostic, owner, expected signal, and safe next action. | ✓ VERIFIED | Each ownership row provides all four; contract protects command references. |
| 13 | Contract runs once in existing docs-contracts-shift-left without topology rewiring. | ✓ VERIFIED | `.github/workflows/ci.yml:134-135` has one invocation; self-test rejects renamed host job. |
| 14 | Phase 225 proof identities and Phase 192 artifacts remain stable. | ✓ VERIFIED | `bash scripts/ci/verify_phase192_ci_contract.sh` exited 0; baseline contract asserts required/advisory taxonomy and named Phase 192 artifacts. |

**Score:** 9/14 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/ci_baseline_workflow_policy.json` | Versioned lane-policy map | ✓ VERIFIED | 19 lanes; canonical jobs resolve exactly once. |
| `scripts/ci/capture_ci_baseline.sh` | Manifest-driven, metadata-only collector | ⚠️ PARTIAL | Wired to policy/Actions API but has API-error, pagination, proof-eligibility, and signature defects. |
| `scripts/ci/verify_ci_baseline_contract.sh` | Fail-closed baseline/privacy/proof validator | ⚠️ PARTIAL | Strong canonical mutations pass, but unknown-key evidence and collector output are not handled safely. |
| `226-CI-BASELINE.json` | Three-run canonical evidence | ⚠️ HOLLOW | Complete cohort/proof/provenance fields, but queue values encode critical-path elapsed time rather than queue delay. |
| `226-CI-BASELINE.md` | Reviewable rendering | ⚠️ PARTIAL | Renders the misleading queue metric and cannot repair upstream facts. |
| `226-SETUP-OWNERSHIP.md` and `scripts/ci/README.md` | Ownership matrix and discovery route | ✓ VERIFIED | Substantive, cross-linked, and repository-contract protected. |
| `.github/workflows/ci.yml` | Existing shift-left invocation | ✓ VERIFIED | One substantive invocation without topology change. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Collector | Actions metadata APIs | Versioned `gh api` requests | ⚠️ PARTIAL | API version header exists, but list pagination is absent and classic endpoint failures are misclassified. |
| Collector | Policy manifest | `classify_job` | ✓ WIRED | Unknown/ambiguous fixture job exits nonzero. |
| Contract | Canonical baseline | `validate_input`/`validate_aggregates` | ⚠️ PARTIAL | Canonical invariants are recomputed, but not privacy allowlisted and not compatible with collector schema. |
| Baseline Markdown | Canonical facts | Tables/rendering | ⚠️ PARTIAL | Values are present but the queue interpretation is false. |
| Workflow | Contract | `docs-contracts-shift-left` step | ✓ WIRED | Exactly one call at workflow line 135. |
| Ownership runbook | Host/browser owner scripts | Command links | ✓ WIRED | `accrue_host_uat.sh` and `accrue_host_verify_browser.sh` are documented and contract-pinned. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Collector | run/jobs/artifacts/provider snapshot | GitHub Actions API or sanitized fixture | Allowlisted data path exists, but pages after 100 are dropped and classic errors become absence. | ⚠️ PARTIAL |
| Canonical baseline | queue/signature/aggregates | Stored three-run metadata | Cohort values flow into Markdown/contract, but queue derivation is not runner queue. | ✗ HOLLOW SEMANTICS |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Canonical mutation suite | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` | Exit 0; named cohort/proof/provenance mutations rejected. | ✓ PASS |
| Canonical baseline | `bash scripts/ci/verify_ci_baseline_contract.sh` | Exit 0. | ✓ PASS |
| Phase 192 topology/artifacts | `bash scripts/ci/verify_phase192_ci_contract.sh` | Exit 0. | ✓ PASS |
| Unknown sensitive value | mutate canonical with `.runs[0].run.evidence = "ghp_exampletokenvalue"`; run `--input` | Exit 0 (`UNKNOWN_SECRET_ACCEPTED`). | ✗ FAIL |
| Ineligible proof semantics | capture synthetic successful `pull_request` attempt 2 fixture | 17 required job observations emitted as `proved`. | ✗ FAIL |
| Collector-to-verifier API | capture one fixture run, then `verify_ci_baseline_contract.sh --input captured.json` | Nonzero: canonical cohort/provenance required. | ✗ FAIL |

### Probe Execution

No phase-declared or conventional `probe-*.sh` scripts found; skipped.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 226-01, 226-02, 226-03, 226-04 | Durable privacy-safe comparable baseline with complete operational facts | ✗ BLOCKED | Privacy check accepts arbitrary content; provider state can be fabricated after API failure; queue and paginated completeness are wrong. |
| BASE-02 | 226-01, 226-02, 226-03, 226-04 | Required/skipped/advisory evidence cannot be confused | ✗ BLOCKED | An ineligible required successful job is labeled `proved`, violating the qualified-proof predicate. |
| OWN-01 | 226-03, 226-04 | CI versus host setup ownership and diagnostics | ✓ SATISFIED | Ownership matrix, README route, and owner scripts are substantive and protected by the contract. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/ci/capture_ci_baseline.sh` | 74 | Every classic API failure is treated as 404/not-found | 🛑 Blocker | Can falsely report no provider enforcement. |
| `scripts/ci/verify_ci_baseline_contract.sh` | 67-68 | Blacklist rather than strict schema allowlist | 🛑 Blocker | Raw secret/payload/log-like content under unknown keys passes CI. |
| `scripts/ci/capture_ci_baseline.sh` | 59-60 | Missing pagination | 🛑 Blocker | Durable evidence can silently omit jobs/artifacts. |
| `scripts/ci/capture_ci_baseline.sh` | 67, 69 | Eligibility omitted from proof derivation; signature omits conclusion | ⚠️ Warning | Misleading provider proof and reduced diagnostic resolution. |
| Phase-modified files | — | No unreferenced `TBD`/`FIXME`/`XXX` debt markers found | ℹ️ Info | No debt-marker blocker. |

## Human Verification Required

None. The failures are deterministic, locally reproducible contract and data-flow defects; this is an escalation gate for corrective planning, not a UAT judgment call.

## Gaps Summary

Plan 04 closed several original canonical-cohort bypasses, but the phase still misses the goal and both BASE requirements. The strongest evidence is adversarial: the checked-in contract passes while accepting token-like content below an arbitrary key, and the collector independently emits `proved` states for a non-dispatch attempt-2 run. The three queue values are also nearly each run's wall time because they are derived from the latest serial-chain start, whereas the stored job timestamps show the actual initial runner delay is seconds. Phase 227 is not an appropriate defer target: it optimizes a trusted measured baseline and does not promise to repair privacy, capture, or proof semantics.

---

_Verified: 2026-08-10T21:55:03Z_
_Verifier: the agent (gsd-verifier)_
