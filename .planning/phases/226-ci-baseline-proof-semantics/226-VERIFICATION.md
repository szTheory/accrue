---
phase: 226-ci-baseline-proof-semantics
verified: 2026-08-12T18:15:00Z
status: gaps_found
score: 2/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/4
  gaps_closed:
    - "Required live-provider proof now ignores ExUnit excluded events and a real tagged-only selection finalizes as proved."
    - "The selected scheduled/manual provider-policy guide now matches the required workflow finalizer."
  gaps_remaining: []
  regressions:
    - "The baseline collector evaluates historical attempts using the current workflow topology rather than the immutable workflow content fetched at the run head SHA."
    - "The baseline renderer accepts semantically forged records and injects untrusted URL text into Markdown evidence."
gaps:
  - truth: "A maintainer can inspect a durable comparable-run baseline containing workflow wall time, queue delay, job/step durations, reruns, cache behavior, Docker/browser setup cost, provider state, and root-failure signature without sensitive values."
    status: failed
    reason: "The collector fetches each historical workflow source only to hash it, then resolves identities, runners, and prerequisites from the current ci.yml; independently, validation accepts arbitrary URL/timestamp/numeric values and the renderer interpolates a forged run_url into Markdown. The published baseline is therefore not a durable trustworthy account of comparable historical runs."
    artifacts:
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "liveRuns() computes revision from fetched head-SHA content but calls workflowRunnerContracts() with no source at line 383, so historical identity/DAG/runner resolution uses the current workflow."
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "validateRecord() at lines 212-221 checks field presence/enums only and does not enforce immutable URLs, timestamps, identifiers, or non-negative numeric constraints on persisted records."
      - path: "scripts/ci/render_ci_baseline.mjs"
        issue: "run_url and job_url are inserted directly into Markdown link destinations at lines 84-90."
    missing:
      - "Parse and retain runner contracts from the immutable workflow source fetched at each run head SHA; pass those contracts through identity, runner-image, and prerequisite resolution, with a regression whose historical topology differs from the current workflow."
      - "Perform full semantic validation before rendering and reject/escape unsafe link destinations; add a forged-NDJSON regression that proves headings/links cannot be injected."
  - truth: "The baseline confirms the roughly 33–36 minute green-run critical path is staged release → host integration → Playwright work rather than runner queueing, or records a contrary measured result."
    status: failed
    reason: "The committed records render and the percentile calculation runs, but historical paths were admitted and topologized with current-workflow contracts. That makes the claimed 20-path critical-path cohort unreliable after ordinary workflow evolution."
    artifacts:
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "Historical runner/DAG contracts are not bound to the fetched immutable workflow revision."
    missing:
      - "Repair historical contract binding, recollect or revalidate the frozen records, and byte-verify a report whose staged paths derive from the actual workflow topology for each historical attempt."
---

# Phase 226: CI Baseline & Proof Semantics Verification Report

**Phase Goal:** Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Verified:** 2026-08-12T18:15:00Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A maintainer can inspect a durable comparable-run baseline containing workflow wall time, queue delay, job/step durations, reruns, cache behavior, Docker/browser setup cost, provider state, and root-failure signature without sensitive values. | ✗ FAILED | Fixture and committed-record gates pass, but the historical collector uses current workflow contracts after fetching a historical source only for its hash. Further, a semantically forged `run_url` passed `validateRecord()` and rendered a `# FORGED EVIDENCE` Markdown heading. |
| 2 | Required, skipped, and advisory provider evidence is visibly distinct, so a skipped or non-run lane cannot be read as release proof. | ✓ VERIFIED | `verify_provider_proof.mjs --fixtures` passed; the formatter’s explicit `{:excluded, _}` branch leaves counts unchanged; its 4-test focused suite passed and its real `mix test --only live_stripe` subprocess finalized a manifest as `proved`. The workflow and guide bind selected schedule/manual runs to `policy: required`. |
| 3 | A host maintainer can identify whether Node, browser installation, and Playwright setup belong to the host or CI and can follow documented diagnostics for each setup failure mode. | ✓ VERIFIED | `bash scripts/ci/verify_ci_setup_diagnostics.sh` passed; the diagnostic registry, browser wrapper, host wrapper, and owner-first rendered facts are wired and the contract includes initial Postgres-readiness handling. |
| 4 | The baseline confirms the roughly 33–36 minute green-run critical path is staged release → host integration → Playwright work rather than runner queueing, or records a contrary measured result. | ✗ FAILED | The frozen pair reports 20 paths and p50 2083s/p95 2602s, and the critical-path gate passes. However, historical job identity, runner, and dependency contracts are resolved from today’s `ci.yml`, not each run’s immutable source, so this cannot prove the *actual* historical path. |

**Score:** 2/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | Read-only, fail-closed comparable-run collector | ✗ HOLLOW | Exists and has substantial fixtures, but `liveRuns()` fetches historical source at `head_sha` only to calculate a revision; line 383 uses default/current contracts for all historical resolution. |
| `scripts/ci/render_ci_baseline.mjs` | Safe renderer for durable baseline evidence | ✗ HOLLOW | Exists and is invoked by the validation command, but shallow `validateRecord()` permits malicious URLs and the renderer directly interpolates them into Markdown. |
| Frozen NDJSON and Markdown baseline | Durable privacy-safe critical-path evidence | ⚠️ PRESENT, NOT TRUSTWORTHY | 2,009 NDJSON records and deterministic committed Markdown pass their current contract, but that contract misses the two semantic integrity controls above. |
| `scripts/ci/provider_proof.mjs` and `LiveProofFormatter` | Literal provider states and truthful selected-suite manifest | ✓ VERIFIED | Formatter line 48 ignores excluded tests; focused real-selection/finalizer test is wired to `provider_proof.mjs` and passed. |
| Setup diagnostic registry and host wrapper | Owner-first host/CI setup diagnostics | ✓ VERIFIED | Shell diagnostic contract passed across its enumerated setup cases. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Historical Actions workflow contents | Collector identity/runner/DAG resolution | Head-SHA source → workflow contracts | ✗ NOT_WIRED CORRECTLY | The immutable source is fetched at lines 377 and 363-367, but `workflowRunnerContracts()` is invoked without it at line 383. |
| NDJSON record validation | Markdown link output | `validateRecord()` before `renderBaseline()` | ✗ NOT_WIRED CORRECTLY | Validation does not call `immutableUrl()` or semantic timestamp/count checks for persisted records; direct URL interpolation then permits Markdown injection. |
| `mix test.live` | `LiveProofFormatter` manifest | `ACCRUE_PROVIDER_MANIFEST` formatter registration | ✓ WIRED | The focused test exercised real tagged-only selection and proved finalization. |
| Manifest | `provider_proof.mjs --finalize` | Workflow finalizer/always-run summary/artifact | ✓ WIRED | Provider fixtures and focused integration test passed; required schedule/manual policy is present in workflow and guide. |
| Host wrapper | Setup diagnostic registry | readiness branch and fact rendering | ✓ WIRED | Setup contract test passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Baseline collector | Run/job timing, queue, setup, and dependency facts | Attempt-scoped Actions metadata plus **current** workflow contracts | No — historic topology can be misclassified | ✗ DISCONNECTED FROM HISTORICAL SOURCE |
| Baseline report | Links and staged-path measurements | Canonical NDJSON → renderer | No — renderer accepts forged semantic values | ✗ UNSAFE |
| Provider proof record | Aggregate selected/passed/skipped/failed counts | ExUnit formatter → production finalizer | Yes | ✓ FLOWING |
| Setup summary | Owner-first setup diagnostic fact | Host wrapper and diagnostic registry | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Baseline fixtures | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | `ci baseline fixtures: PASS` | ✓ PASS — insufficient for the historical-source and forged-record paths |
| Frozen critical path | `node scripts/ci/verify_ci_baseline.mjs --records … --rendered … --require-critical-path` | Exit 0 | ✓ PASS — verifies the existing records, not their historic topology binding |
| Provider proof classifier | `node scripts/ci/verify_provider_proof.mjs --fixtures` | `provider proof fixtures: PASS` | ✓ PASS |
| Real tagged selection → finalizer | `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors` | 4 tests, 0 failures | ✓ PASS |
| Setup ownership diagnostics | `bash scripts/ci/verify_ci_setup_diagnostics.sh` | `ok` | ✓ PASS |
| Required-lane boundary | `bash scripts/ci/verify_phase225_required_lane_evidence.sh` | Exit 0 | ✓ PASS |
| Forged baseline rendering | In-memory `renderBaseline()` with `run_url` set to `…/999)\\n# FORGED EVIDENCE` | Renderer emitted a new `# FORGED EVIDENCE` heading | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 01, 02, 05–07, 12–19 | Durable, privacy-safe comparable CI baseline | ✗ BLOCKED | Historic-source topology is unwired and persisted record semantic validation is insufficient, so the baseline is not durable trustworthy evidence. |
| BASE-02 | 03, 05–07, 12–19 | Provider evidence visibly distinguishes proof states | ✓ SATISFIED | The real tagged-only formatter/finalizer regression and exhaustive provider fixtures passed; selected required policy is documented and workflow-wired. |
| OWN-01 | 04, 05, 07, 12–19 | Host/CI setup ownership and diagnostics | ✓ SATISFIED | Complete setup-diagnostic contract passed, including early database readiness. |

All three requirement IDs declared in Phase 226 plan frontmatter are accounted for. `REQUIREMENTS.md` maps no additional IDs to Phase 226; no orphaned requirements were found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | 377-398 | Immutable historical workflow content is fetched only for digest; current workflow contracts resolve historic job topology | 🛑 Blocker | Comparable-run admission and critical-path dependencies can be wrong after workflow evolution. |
| `scripts/ci/collect_ci_baseline.mjs` | 212-221 | Persisted record validation checks allowlist/enums but not URL, timestamp, ID, or numeric semantics | 🛑 Blocker | Forged records pass pre-render validation. |
| `scripts/ci/render_ci_baseline.mjs` | 84-90 | Untrusted URL fields interpolate into Markdown link destinations | 🛑 Blocker | A forged record can inject report content/evidence links. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in phase implementation files. The Phase 226 code-review findings CR-01 and CR-02 were independently reproduced from source and, for CR-02, by an in-memory execution; both prevent the phase goal rather than being advisory style concerns. No declared or conventional standalone probe scripts were present.

### Gaps Summary

Plan 19 correctly closes the earlier provider-proof formatter defect, and the setup proof is intact. The remaining fault is the evidence foundation itself: the collector treats historical data as if it had today’s DAG, and the renderer can publish forged Markdown from a syntactically complete record. These are **BLOCKERS / Escalation Gate** failures of BASE-01 and the actual-critical-path claim. Repair both paths, add their missing regressions, then recollect/revalidate and byte-verify the frozen baseline before Phase 227 proceeds.

_Verified: 2026-08-12T18:15:00Z_
_Verifier: the agent (gsd-verifier)_
