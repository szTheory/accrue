---
phase: 227-measured-critical-path-improvement
verified: 2026-08-28T20:14:27Z
status: gaps_found
score: 5/11 must-haves verified
behavior_unverified: 0
overrides_applied: 0
unverified_prohibition_count: 12
decision_coverage:
  honored: 23
  total: 23
  not_honored: []
gaps:
  - truth: "One validated CI critical-path change reduces measured wait or duplicate work without removing required proof."
    status: failed
    reason: "The final cohort has only two admitted observations, --require-kept exits nonzero, PATH-02 is explicitly unmet, and the terminal state is rollback_applied_unverified rather than kept."
    artifacts:
      - path: ".planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson"
        issue: "Three final attempts are recorded, but one is a deterministic required-lane failure and only two are reclassified as admitted observations."
      - path: ".planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md"
        issue: "The report states PATH-02 is unmet and records no validated before/after improvement."
    missing:
      - "Three valid, independent attempt-1 observations at one candidate SHA with a complete required proof vector."
      - "A passing keep decision with the staged-path median and maximum-observation predicates satisfied."
  - truth: "The critical-path decision gate fails closed on exact sample, proof-vector, job-role, privacy, and CLI contracts."
    status: failed
    reason: "Independent adversarial checks showed that the verifier accepts duplicate push samples as a keep cohort, arbitrary required-job keys, repeated Playwright job URLs, nested forbidden evidence fields, and unknown/no-op CLI flags."
    artifacts:
      - path: "scripts/ci/verify_ci_critical_path.mjs"
        issue: "Admission and terminal checks are substantive and wired, but they do not enforce the declared contract strongly enough to be a safe decision gate."
      - path: ".planning/phases/227-measured-critical-path-improvement/fixtures/ci-critical-path-cases.json"
        issue: "The fixture coverage omits the adversarial cases above; terminal fixtures use synthetic job_0..job_9 identities instead of the twelve contractual identities."
    missing:
      - "Exactly-three unique workflow_dispatch attempt-1 sample enforcement at one SHA/fingerprint/provider state."
      - "Exact required job identities and role-bound, unique job URLs for candidates and rollback proof."
      - "Recursive privacy/schema validation and strict CLI option/action parsing."
      - "Negative regression fixtures for each fail-open path."
  - truth: "The Phase 227 checks and maintainer report remain reproducible from immutable fixtures and the durable NDJSON source."
    status: failed
    reason: "The documented fixture/preflight command fails against the current workflow digest, and renderCriticalPathEvidence throws because the terminal ledger has no comparison/post_run records. The checked-in rollback report is therefore not byte-reproducible through the shipped renderer."
    artifacts:
      - path: "scripts/ci/verify_ci_critical_path.mjs"
        issue: "verifyFixtures reads mutable .github/workflows/ci.yml; the renderer supports the earlier comparison grammar, not the terminal rollback ledger."
      - path: "scripts/ci/README.md"
        issue: "The documented Phase 227 preflight command exits 1 on the reviewed source tree."
      - path: ".planning/phases/227-measured-critical-path-improvement/227-VALIDATION.md"
        issue: "Still status: draft, nyquist_compliant: false, and wave_0_complete: false."
    missing:
      - "An immutable Phase 227 workflow fixture or explicitly versioned compatibility contract."
      - "A deterministic terminal rollback renderer that byte-matches 227-CI-CRITICAL-PATH.md."
      - "A green validation sign-off after the corrected checks pass."
deferred:
  - truth: "A fresh provider attempt proves the repaired Stripe webhook-signing boot contract without exposing secrets."
    addressed_in: "Phase 228"
    evidence: "Phase 228 explicitly owns STRIPE_WEBHOOK_SECRET CI/runtime wiring, deterministic no-network fixtures, and at most one freshly authorized attempt-1 provider dispatch. This does not supply Phase 227's missing three-run critical-path comparison."
---

# Phase 227: Measured Critical-Path Improvement Verification Report

**Phase Goal:** Maintainers receive one demonstrably faster CI critical path while every required release, host, browser, and provider proof remains equally identifiable and recoverable.
**Verified:** 2026-08-28T20:14:27Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

The phase safely returned to the prior dependency graph, but it did not deliver a validated faster critical path. The codebase also cannot safely use the Phase 227 verifier as a future keep/rollback decision gate because several malformed or fabricated evidence shapes pass.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Maintainers can identify the selected path/edge, frozen before state, and rollback procedure. | ✓ VERIFIED | `227-CI-CRITICAL-PATH.md` names the host prerequisite edge, frozen Phase 226 facts, candidate/restored SHAs, terminal state, and rollback history. |
| 2 | The candidate changed one host prerequisite and the exact inverse restored it without other Phase 227 workflow changes. | ✓ VERIFIED | `git diff d1244ee5..80f60193 -- .github/workflows/ci.yml` is one insertion/one deletion: restoring `admin-drift-docs` in `host-integration.needs`. |
| 3 | One validated change reduces measured critical-path wait without losing proof. | ✗ FAILED | Only two observations are admitted; `--require-kept` exits 1; the report explicitly says PATH-02 is unmet. |
| 4 | Exact required job/check identities, proof labels, upload conditions, artifacts, and retention semantics are enforced. | ✗ FAILED | The manifest carries only a subset of these semantics, candidate admission accepts arbitrary job keys, role-swapped URLs are accepted, and the current workflow check fails at a digest mismatch before meaningful contract assertions. |
| 5 | The three Phase 226 frozen inputs retain their recorded SHA-256 digests. | ✓ VERIFIED | Recomputed digests exactly match `5fbde56d...`, `768e67bf...`, and `6d193382...`; the frozen baseline verifier passes. |
| 6 | Exactly three successful, independent, attempt-1 candidate observations are measured and retained. | ✗ FAILED | Three attempts exist, but run `31715606960` failed a required lane; only `31715609742` and `31715612044` are admitted. No valid median can close the phase. |
| 7 | A live negative control proves aggregate failure after independent host/browser completion with retained evidence. | ? UNCERTAIN | The ledger contains the detailed immutable record for run `31660617339`, but live GitHub revalidation could not run in this sandbox. Repository evidence is present; external truth was not independently refreshed. |
| 8 | Local checks and live Actions evidence are labeled separately. | ✓ VERIFIED | The ledger/report distinguish local controls, immutable runs, provider state, candidate classification, and rollback state. |
| 9 | The durable evidence pack is recursively privacy-safe and deterministically rendered from NDJSON. | ✗ FAILED | A nested `provider_payload` field passes CLI evidence validation, and `renderCriticalPathEvidence()` throws on the terminal ledger instead of reproducing the checked-in Markdown. |
| 10 | Exactly three final attempts, all exclusions, and the no-rerun/no-replacement budget are retained. | ✓ VERIFIED | The ledger has three `candidate_run` records, ten exclusions, two append-only reclassifications, one post-correction restoration run, and terminal `run_budget: exhausted` / `additional_dispatch_authorized: false`. |
| 11 | Terminal admission and rollback verification fail closed on incomplete or fabricated proof. | ✗ FAILED | `verifyFinalDecision()` accepts forged required-job identities and a rollback whose three Playwright URLs all reference the same job. |

**Score:** 5/11 truths verified (0 present-but-behavior-unverified; 1 external truth uncertain)

### Deferred Item

| Item | Addressed In | Evidence |
| --- | --- | --- |
| Stripe webhook-signing boot repair and one fresh provider attempt | Phase 228 | Phase 228 success criteria explicitly cover `STRIPE_WEBHOOK_SECRET`, deterministic missing-config fixtures, and one fresh provider dispatch. They do not cover Phase 227's missing performance cohort. |

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/verify_ci_critical_path.mjs` | Workflow/evidence verifier and fixture runner | ✗ FAILED | Exists (491 lines), exports the planned functions, and is invoked by CLI, but the decision gate is fail-open and its documented fixture command is red. |
| `227-ci-contract.json` | Exact identity, graph, proof, artifact, and rollback contract | ⚠ PARTIAL | Exists and is consumed, but does not encode/enforce all promised upload conditions, retention semantics, or exact live role binding. |
| `fixtures/ci-critical-path-cases.json` | Positive and negative controls | ⚠ PARTIAL | Exists and is consumed, but misses duplicate cohort, wrong event, forged identity, duplicate URL, nested privacy, and no-op CLI cases. |
| `.github/workflows/ci.yml` | Candidate edge or exact inverse | ✓ VERIFIED | Current graph is the exact inverse: host waits for Admin drift and docs; Playwright still waits for host; annotation sweep remains `always()` fan-in. |
| `COVERAGE.md` | No-new-API declaration | ✓ VERIFIED | Exists and remains substantive. |
| `227-CI-CRITICAL-PATH.ndjson` | Append-only sanitized evidence ledger | ⚠ PARTIAL | Exists (24 records) with immutable IDs and terminal rollback facts; recursive privacy is not enforced and live refresh was unavailable. |
| `227-CI-CRITICAL-PATH.md` | Deterministic maintainer report | ✗ FAILED | Substantive and honest, but disconnected from the shipped renderer for the terminal record grammar. |
| `scripts/ci/README.md` | Reproducible operator commands | ✗ FAILED | The documented fixture/preflight command at lines 67-70 exits 1 against the current workflow. |
| `227-VALIDATION.md` | Executed Nyquist validation map | ✗ FAILED | Exists but remains draft / non-compliant / Wave 0 incomplete, consistent with the skipped kept-only Task 3. |

The Plan 03 `227-VERIFICATION.md` artifact was conditional on a kept result. That precondition was false; this file is the verifier-owned report, not evidence that executor Task 3 ran.

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `.github/workflows/ci.yml` | `227-ci-contract.json` | `verifyWorkflowContract()` | ✗ NOT WIRED FOR CURRENT TREE | The call exists, but it rejects the current Phase 228-expanded workflow at the digest check. Phase 228 does not explicitly promise to repair the historical verifier. |
| `verify_ci_critical_path.mjs` | Phase 226 frozen inputs | SHA-256 validation | ✓ WIRED | All three hashes are read and recomputed; values match. |
| GitHub Actions run/job/artifact API | `227-CI-CRITICAL-PATH.ndjson` | repository-bound live validation | ? UNCERTAIN | Code and immutable records exist; network access was unavailable for this verifier run. |
| `227-CI-CRITICAL-PATH.ndjson` | `227-CI-CRITICAL-PATH.md` | deterministic rendering | ✗ NOT WIRED | The terminal ledger has no `comparison`/`post_run` records expected by `renderCriticalPathEvidence()`, which throws before rendering. |
| terminal ledger decision | `.github/workflows/ci.yml` | exact inverse commit | ✓ WIRED | Git history proves candidate SHA `d1244ee5...` to restored SHA `80f60193...` changed only the one `needs` array. |

## Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `227-CI-CRITICAL-PATH.ndjson` | Run IDs, job URLs, conclusions, artifacts, states | Recorded GitHub Actions facts | Repository-bound identifiers are present; live refresh unavailable | ⚠ PARTIAL |
| `227-CI-CRITICAL-PATH.md` | Current fact and terminal rollback narrative | NDJSON ledger | Content is substantive, but no functioning deterministic renderer reaches it | ✗ DISCONNECTED |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Script parses | `node --check scripts/ci/verify_ci_critical_path.mjs` | exit 0 | ✓ PASS |
| Documented fixtures/preflight work | `node ...verify_ci_critical_path.mjs --fixtures --workflow ... --contract ...` | digest mismatch; exit 1 | ✗ FAIL |
| Duplicate push records cannot create keep | Direct call with the same push record three times | returned `{keep:true, observations:3}` | ✗ FAIL |
| Required job identities are exact | Forge two admitted candidates with `forged_0..forged_9` keys | terminal verifier still passed | ✗ FAIL |
| Playwright shards are unique and role-bound | Repeat one job URL three times in rollback proof | terminal verifier still passed | ✗ FAIL |
| Evidence privacy is recursive | Add nested `provider_payload` and run `--require-final-decision` | exit 0 | ✗ FAIL |
| Unknown CLI actions fail | Run misspelled `--verify-live-action` | exit 0 without verification | ✗ FAIL |
| Kept result exists | `--require-kept` on durable evidence | fewer than three eligible observations; exit 1 | ✗ FAIL (goal absent) |
| Verified restoration exists | `--require-rollback-verified` | latest rollback is not verified; exit 1 | ✗ FAIL |
| Frozen baseline/provider/setup controls | baseline fixtures + frozen records + provider fixtures + setup diagnostics | all exit 0 | ✓ PASS |
| Targeted application proof tests | `mix test test/accrue/docs/release_guidance_test.exs test/accrue/live_proof_formatter_test.exs` | 7 tests, 0 failures | ✓ PASS |
| Phase 225 live required-lane evidence | `bash scripts/ci/verify_phase225_required_lane_evidence.sh` | GitHub API unavailable | ? SKIP |

## Probe Execution

No Phase 227 probe scripts were declared or discovered. Step 7c is not applicable; the phase uses direct Node/shell fixture commands instead.

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PATH-01 | 01, 02, 03 | Measured path, selected edge, before evidence, rollback | ✓ SATISFIED | Frozen baseline, selected host dependency, exact candidate/restored SHAs, and rollback record are visible. |
| PATH-02 | 01, 02, 03 | Validated improvement without proof removal | ✗ BLOCKED | Two admitted observations are insufficient; no keep decision or validated reduction exists. |
| SAFE-01 | 01, 02, 03 | Stable required-check identity and artifacts | ✓ SATISFIED WITH VERIFIER GAP | The actual Phase 227 candidate-to-inverse diff changes one edge and retains required paths/artifacts, but the enforcement script is incomplete. |
| SAFE-02 | 01, 02, 03 | Negative control, rollback path, no masking | ✓ SATISFIED WITH VERIFIER GAP | Failure observations remain retained, the exact inverse was applied, no candidate rerun/replacement is recorded, and the terminal state is honest; adversarial validation gaps remain. |

All four requirement IDs declared in every PLAN frontmatter are accounted for. REQUIREMENTS.md marks all four complete, but PATH-02's checked box conflicts with the actual terminal evidence and this verification verdict.

## Test Quality Audit

| Test / Fixture | Linked Requirements | Active | Skipped | Circular | Assertion Level | Verdict |
| --- | --- | ---: | ---: | --- | --- | --- |
| `verifyFixtures()` in `verify_ci_critical_path.mjs` | PATH-01, PATH-02, SAFE-01, SAFE-02 | Yes | 0 | No | Value/behavioral | ✗ BLOCKER — suite is red before most assertions and omits six reproduced fail-open classes. |
| `release_guidance_test.exs` | SAFE-01 | 3 | 0 | No | Value | ✓ PASS |
| `live_proof_formatter_test.exs` | SAFE-01, SAFE-02 | 4 | 0 | No | Behavioral | ✓ PASS |

**Disabled requirement tests:** 0  
**Circular patterns detected:** 0  
**Insufficient critical-path assertions:** 6 reproduced classes — BLOCKER

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | ---: | --- | --- | --- |
| `verify_ci_critical_path.mjs` | 101-119 | Broad event admission, `>= 3`, no uniqueness/SHA/provider enforcement | 🛑 Blocker | Fabricated duplicate push cohort can return keep. |
| `verify_ci_critical_path.mjs` | 144-164 | Arbitrary job-key count instead of exact identities | 🛑 Blocker | Missing or renamed required jobs can be represented as complete. |
| `verify_ci_critical_path.mjs` | 168-215, 374-420 | URL/conclusion checks without unique shard or stable role identity | 🛑 Blocker | Repeated or role-swapped jobs can prove rollback. |
| `verify_ci_critical_path.mjs` | 279-297 | Top-level-only privacy scan | 🛑 Blocker | Nested secret/payload-shaped fields enter durable evidence. |
| `verify_ci_critical_path.mjs` | 229-243 | Fixtures coupled to mutable live workflow | 🛑 Blocker | Historical fixture command becomes permanently red after later workflow evolution. |
| `verify_ci_critical_path.mjs` | 441-491 | No strict option allowlist or required action | 🛑 Blocker | Typos can exit successfully after doing no work. |
| `verify_provider_proof.mjs` | 15 | URL pathname used without `fileURLToPath()` | ⚠ Warning | Checkout paths containing spaces are misresolved. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in phase-modified files.

## Prohibitions Review

All 12 PLAN prohibitions remain descriptor-less and `flagged-unverified`; none has a `verification: test|judgment` disposition. They are therefore not silently passed. Non-authoritative code review found:

- The reports do not overclaim causality or a kept improvement; they explicitly state PATH-02 is unmet.
- Failed attempts remain visible and no candidate rerun/replacement is recorded.
- The verifier nevertheless permits fabricated decision evidence, incomplete identity proof, nested sensitive-field shapes, and no-op CLI success.

**Flag:** `unverified-prohibition — human review recommended` for all 12 items. These flags do not override the concrete blockers above.

## Human Verification Required

### Refresh the Phase 227 negative-control evidence

**Test:** With authenticated read access, re-run the repository-bound live verifier for negative-control run `31660617339` without launching or mutating any workflow.

**Expected:** The recorded annotation marker is present, host and all Playwright shards succeeded, annotation sweep failed, artifact presence matches the ledger, and the temporary ref is absent.

**Why human/external:** Network access to the GitHub Actions API was unavailable in this verification environment. This check cannot rescue PATH-02 or the verifier blockers.

## Decision Coverage

All 23 trackable CONTEXT.md decisions are honored by shipped artifacts according to the non-blocking decision-coverage gate.

## Gaps Summary

Phase 227 achieved an honest, exact rollback—not its phase goal. The primary blocker is the missing three-observation validated improvement. Independently, the critical-path verifier is unsafe as a decision gate and its fixtures/report rendering are not stable or reproducible on the current tree. Phase 228 specifically owns the Stripe webhook-signing boot repair and one fresh provider attempt, but it does not supply Phase 227's missing critical-path comparison and does not make this phase pass.

---

_Verified: 2026-08-28T20:14:27Z_  
_Verifier: the agent (gsd-verifier)_
