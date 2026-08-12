---
phase: 226-ci-baseline-proof-semantics
verified: 2026-08-12T15:47:17Z
status: gaps_found
score: 1/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/4
  gaps_closed:
    - "Exact Actions attempt-scoped job retrieval and per-job attempt validation replace the prior all-attempt job fetch."
    - "Runner cohorts now originate in the workflow runs-on contract rather than a raw runner_name projection."
  gaps_remaining: []
  regressions:
    - "Historical DAG compatibility accepts an unknown pre-cutoff topology solely by repository, date, event, and broad job-name prefix."
    - "Runner resolution accepts spoofed job-name prefixes as declared workflow jobs."
    - "A failing initial Postgres readiness check exits the host wrapper before it emits a stable setup diagnostic."
gaps:
  - truth: "A maintainer can inspect a durable comparable-run baseline containing workflow wall time, queue delay, job/step durations, reruns, cache behavior, Docker/browser setup cost, provider state, and root-failure signature without sensitive values."
    status: failed
    reason: "The production collector does not fail closed for unknown historical topology or job identity, so untrusted job timings can enter an apparently trusted cohort."
    artifacts:
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "compatibilityRule() accepts any pre-cutoff szTheory/accrue job whose normalized name equals or starts with an inventory job name, without binding the run to an immutable workflow revision."
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "workflowRunnerImage() accepts broad identity/display-name prefixes, classifying spoofed names as workflow-declared runner contracts."
    missing:
      - "Bind every historical compatibility exception to an immutable audited workflow revision and exact job identity."
      - "Use exact identities or narrowly enumerated matrix suffixes for workflow needs and runner resolution; reject arbitrary suffixes."
  - truth: "A host maintainer can identify whether Node, browser installation, and Playwright setup belong to the host or CI and can follow documented diagnostics for each setup failure mode."
    status: failed
    reason: "The wrapper has set -e enabled when pg_isready fails, so it exits before the existing host_gate_failure diagnostic fallback and emits no setup fact, owner, or repair command."
    artifacts:
      - path: "scripts/ci/accrue_host_uat.sh"
        issue: "Lines 28-35 invoke pg_isready outside an explicit status branch; the fallback at lines 64-71 is unreachable for this prerequisite failure."
    missing:
      - "Handle pg_isready failure explicitly, emit/render the stable diagnostic fact, print FAILED_GATE=host-integration, and add a failing-readiness regression."
  - truth: "The baseline confirms the roughly 33–36 minute green-run critical path is staged release → host integration → Playwright work rather than runner queueing, or records a contrary measured result."
    status: failed
    reason: "The frozen report is reproducible, but its selected paths are derived by a collector that can classify unknown topology and spoofed identities as trusted. Reproducibility cannot establish that the measured paths are comparable."
    artifacts:
      - path: ".planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson"
        issue: "Fresh records pass the renderer gate but retain evidence collected through the non-fail-closed topology/runner resolver."
    missing:
      - "Repair the collector boundaries, add adversarial regressions, recollect the 90-day evidence, and re-run the byte/critical-path gate."
---

# Phase 226: CI Baseline & Proof Semantics Verification Report

**Phase Goal:** Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Verified:** 2026-08-12T15:47:17Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Durable, privacy-safe comparable-run baseline covers all required timing, reliability, setup, provider, and signature facts. | ✗ FAILED | Schema, 3,014-record NDJSON, redaction, and deterministic validation exist; however, injected `Host integration (required deterministic gate) malicious-shard` is accepted by `liveRuns()` with `needs: []` and runner image `github-hosted/ubuntu-24.04`. Unknown topology can enter durable cohort data. |
| 2 | Required, skipped, and advisory provider evidence is visibly distinct; skipped/non-run cannot be release proof. | ✓ VERIFIED | `node scripts/ci/verify_provider_proof.mjs --fixtures` passed. The provider classifier retains independent policy, raw conclusion, state, manifest, SHA, and freshness conditions before rendering proof. |
| 3 | Host versus CI Node/browser/Playwright ownership and setup diagnostics are usable for each documented failure mode. | ✗ FAILED | With a shadowed failing `pg_isready`, `bash scripts/ci/accrue_host_uat.sh` exited 1 and emitted zero setup-fact bytes. The established fallback is never reached. |
| 4 | The frozen evidence proves a 33–36 minute staged release → host integration → Playwright critical path, or records a contrary measured result. | ✗ FAILED | `--require-critical-path` passes and the Markdown is deterministic, but those checks do not exercise the unknown-topology/spoofed-identity path. The baseline conclusion therefore is not comparable-run proof. |

**Score:** 1/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | Read-only metadata collection, exact-attempt isolation, cohorting, timing/reliability derivation | ✗ HOLLOW | Substantive and CLI-wired; exact attempt isolation is fixed, but the historical DAG and runner-contract admission boundaries are overbroad. |
| `scripts/ci/render_ci_baseline.mjs` and frozen NDJSON/Markdown | Deterministic privacy-safe evidence/report | ⚠️ HOLLOW | Records are schema-valid, omit raw runner names/branches, and render byte-consistently, but data provenance is invalidated by the collector gaps. |
| `scripts/ci/provider_proof.mjs`, renderer, verifier, formatter | Literal provider proof-state/freshness classification | ✓ VERIFIED | Substantive, workflow-wired, and covered by the provider fixture gate plus the inherited formatter contract. |
| Setup diagnostic registry, host wrapper, verifier, docs | Owner-first setup diagnostics | ✗ PARTIAL | Browser and delegated-host paths are wired and the existing contract passes, but initial Postgres readiness has no diagnostic path. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Workflow run attempt | `liveRuns()` | Attempt-specific `/attempts/{attempt}/jobs` request and per-job attempt check | ✓ WIRED | Production code at lines 341-346 requests the exact attempt endpoint and rejects an explicit per-job mismatch. |
| Historical run/job metadata | DAG prerequisite resolution | `compatibilityRule()` | ✗ NOT_WIRED | No immutable workflow revision is checked; a date/repo/event/prefix match authorizes a topology exception. |
| Workflow `runs-on` contract | Cohort fingerprint | `workflowRunnerImage()` | ✗ NOT_WIRED | The resolver reads `ci.yml`, but `startsWith()` accepts untrusted suffixes such as `Release gate attacker`. |
| Frozen NDJSON | Baseline Markdown | renderer plus byte/critical-path verification | ✓ WIRED | `node scripts/ci/verify_ci_baseline.mjs --records … --rendered … --require-critical-path` exited 0. |
| Provider finalizer | Provider classifier/always-run summary | current SHA + validated manifest | ✓ WIRED | Provider fixture gate passed; workflow wiring is present in `ci.yml`. |
| Host wrapper | Diagnostic registry | fact-file delta plus fallback | ✗ PARTIAL | Fallback works only after `mix verify.full`; readiness failure occurs before that branch. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Baseline collector | Attempt jobs | GitHub attempt-scoped Actions endpoint | Yes, but admission is unsafe | ⚠️ HOLLOW — exact attempt filtering works; unknown historical/prefix jobs can still become normalized records. |
| Runner cohort | `runner_image` | Parsed `ci.yml` `runs-on` declarations | No trustworthy identity binding | ✗ HOLLOW — a spoofed display-name prefix resolves to `github-hosted/ubuntu-24.04`. |
| Frozen baseline | run/job/cohort records | collector → renderer | Not trustworthy | ✗ HOLLOW — deterministic output cannot correct compromised cohort membership. |
| Provider summary | proof/freshness facts | validated manifest and current SHA | Yes | ✓ FLOWING. |
| Setup summary | diagnostic fact | wrapper/registry | Partial | ✗ DISCONNECTED on initial Postgres readiness failure. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Baseline fixtures | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | Exit 0 | ✓ PASS — does not cover the reproduced spoofed-prefix path. |
| Frozen critical-path report | `node scripts/ci/verify_ci_baseline.mjs --records … --rendered … --require-critical-path` | Exit 0 | ✓ PASS — proves deterministic rendering only. |
| Provider proof state/freshness | `node scripts/ci/verify_provider_proof.mjs --fixtures` | Exit 0 | ✓ PASS |
| Setup diagnostic contract | `bash scripts/ci/verify_ci_setup_diagnostics.sh` | Exit 0 | ✓ PASS — omits initial readiness failure. |
| Required-lane boundary | `bash scripts/ci/verify_phase225_required_lane_evidence.sh` | Exit 0 | ✓ PASS |
| Historical topology / runner spoofing | Injected exported `liveRuns()` and `workflowRunnerImage()` call | Malicious host name normalized with no prerequisites and Ubuntu cohort; `Release gate attacker` also resolves Ubuntu | ✗ FAIL |
| Initial Postgres readiness | Shadowed `pg_isready` returning 1, then `bash scripts/ci/accrue_host_uat.sh` | Exit 1; `setup_fact_bytes=0` | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 01, 02, 05, 06, 07, 12, 13, 14, 15, 16 | Durable privacy-safe comparable CI baseline | ✗ BLOCKED | Exact attempt and raw-runner fixes are present, but the live collector still admits untrusted topology/runner identities through broad historical and prefix rules. |
| BASE-02 | 03, 05, 06, 07, 12, 13, 14, 15, 16 | Provider evidence visibly distinguishes proof states | ✓ SATISFIED | Exhaustive provider fixture gate passed; static workflow route and formatter contract remain present. |
| OWN-01 | 04, 05, 07, 12, 13, 14, 15, 16 | Host/CI setup ownership and diagnostics | ✗ BLOCKED | A normal host database-readiness failure exits without the promised owner-first diagnostic. |

All IDs declared by Phase 226 plans are accounted for. `REQUIREMENTS.md` maps no additional requirement to Phase 226, so there are no orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | 253-258 | Date/repository/event plus prefix historical compatibility, without immutable workflow revision | 🛑 Blocker | Unknown pre-cutoff topology can enter measured evidence. |
| `scripts/ci/collect_ci_baseline.mjs` | 264-268, 322-330 | Broad `startsWith()` identity matching | 🛑 Blocker | Spoofed jobs acquire declared DAG and runner classification. |
| `scripts/ci/accrue_host_uat.sh` | 28-35 | `set -e` readiness call before diagnostic boundary | 🛑 Blocker | A documented host setup failure has no stable fact, owner, or repair command. |
| `scripts/ci/verify_ci_baseline.mjs` | live fixture controls | Missing adversarial unknown-revision/spoofed-suffix controls | ⚠️ Warning | Fixture success did not prove the production fail-closed boundary. |
| `scripts/ci/verify_ci_setup_diagnostics.sh` | setup fixtures | Missing initial-`pg_isready` failure control | ⚠️ Warning | Passing suite does not exercise the wrapper's earliest failure branch. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in phase implementation files. Privacy checks did pass: the frozen 3,014-record data set contains neither `runner_name` nor raw `head_branch`; this does not remedy the comparability failures. There are no conventional or declared executable probes beyond the completed fixture/contract checks.

### Gaps Summary

The Wave 10 repair successfully replaces all-attempt job collection and raw runner-name inference, closing the previous verification gaps. It does not achieve the required fail-closed semantics: broad historical and display-name prefix rules let untrusted metadata become trusted baseline evidence. Separately, the host wrapper omits diagnostics for an initial database-readiness failure. These items are not deferred to Phase 227, whose goal is to optimize an already trustworthy measured path. This remains an **Escalation Gate**: fix the three boundaries and recollect the evidence before Phase 226 can proceed.

_Verified: 2026-08-12T15:47:17Z_
_Verifier: the agent (gsd-verifier)_
