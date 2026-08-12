---
phase: 226-ci-baseline-proof-semantics
verified: 2026-08-12T03:16:00Z
status: gaps_found
score: 2/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/4
  gaps_closed:
    - "The exact Docs and bash contracts (shift-left) display identity now resolves to docs-and-bash-contracts-shift-left in the live collector."
  gaps_remaining: []
  regressions:
    - "Comparable-run collection still merges jobs from prior rerun attempts into the current workflow run."
    - "Comparable-run cohorting labels every runner with a runner name github-hosted rather than preserving an observed runner class or image."
gaps:
  - truth: "A maintainer can inspect a durable comparable-run baseline containing workflow wall time, queue delay, job/step durations, reruns, cache behavior, Docker/browser setup cost, provider state, and root-failure signature without sensitive values."
    status: failed
    reason: "The live collector can assemble one current run from jobs belonging to different rerun attempts and places both self-hosted and GitHub-hosted jobs in the same fabricated github-hosted runner-image cohort. This invalidates the comparable-run data flow that BASE-01 requires."
    artifacts:
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "liveRuns() requests jobs?filter=all while retaining only the workflow run's run_attempt; it discards per-job attempt identity before collectBaseline()."
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "runner_image is inferred as github-hosted whenever runner_name is present, although runner_name does not establish hostedness or an image/version."
      - path: "scripts/ci/verify_ci_baseline.mjs"
        issue: "Fixtures cover separate rerun run objects and hand-authored ubuntu-24.04 images, not a live API-shaped all-attempt job response or runner-class/image distinction."
    missing:
      - "Request latest-attempt jobs (or otherwise bind every retained job to the workflow run's attempt) and add a liveRuns() regression that proves older-attempt jobs cannot reach normalized records."
      - "Derive an auditable, privacy-safe runner class/image from trusted workflow configuration or fail closed when it cannot be resolved; prove distinct runner classes produce distinct cohort fingerprints."
  - truth: "The baseline confirms the roughly 33–36 minute green-run critical path is staged release → host integration → Playwright work rather than runner queueing, or records a contrary measured result."
    status: failed
    reason: "The checked-in renderer is reproducible, but its selected staged paths inherit the collector's attempt mixing and fabricated runner-image cohorting. Therefore the report cannot establish that its 33–36 minute conclusion is an actual comparable-run result."
    artifacts:
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "Invalid live cohort inputs flow directly into the frozen-record generation and staged-path derivation."
    missing:
      - "Repair and regression-test attempt isolation and real runner classification, then recollect and byte-verify the baseline before treating the critical-path statement as measured evidence."
---

# Phase 226: CI Baseline & Proof Semantics Verification Report

**Phase Goal:** Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Verified:** 2026-08-12T03:16:00Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A maintainer can inspect a durable comparable-run baseline containing workflow wall time, queue delay, job/step durations, reruns, cache behavior, Docker/browser setup cost, provider state, and root-failure signature without sensitive values. | ✗ FAILED | The schema, redaction, frozen NDJSON, and renderer exist, but the production collector uses `jobs?filter=all` and erases job-attempt identity; it also fabricates `github-hosted` from any `runner_name`. A direct injected call returned prior and current attempt jobs together under run attempt 2, both labeled `github-hosted` even when their runner name was `self-hosted-linux-x64`. |
| 2 | Required, skipped, and advisory provider evidence is visibly distinct, so a skipped or non-run lane cannot be read as release proof. | ✓ VERIFIED | `node scripts/ci/verify_provider_proof.mjs --fixtures` passed; focused formatter test passed (2 tests). The classifier retains independent policy/state/conclusion facts and only promotes a fully validated manifest-backed execution. |
| 3 | A host maintainer can identify whether Node, browser installation, and Playwright setup belong to the host or CI and can follow documented diagnostics for each setup failure mode. | ✓ VERIFIED | Stable diagnostic registry, host wrapper, CI fact artifact, and ownership documentation are wired; `bash scripts/ci/verify_ci_setup_diagnostics.sh` passed. |
| 4 | The baseline confirms the roughly 33–36 minute green-run critical path is staged release → host integration → Playwright work rather than runner queueing, or records a contrary measured result. | ✗ FAILED | The frozen record/render gate passes, but reproducibility does not cure invalid cohort inputs. Attempt-mixed jobs and fabricated runner classes can yield a false staged-path population, so the rendered conclusion is not proven to describe comparable actual runs. |

**Score:** 2/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | Read-only, privacy-safe Actions metadata collection and comparable cohort derivation | ✗ HOLLOW | 304 substantive lines and called by the CLI, but its live data flow retains all rerun-attempt jobs and invents runner class. |
| `226-CI-BASELINE.ndjson` and `226-CI-BASELINE.md` | Durable measured before-state and deterministic report | ⚠️ HOLLOW | 3,020 records / 4,556 lines; byte-reproducible gate passes, but the evidence was generated from collector semantics that do not preserve a comparable cohort. |
| `scripts/ci/provider_proof.mjs` and `render_provider_summary.mjs` | Literal proof-state and freshness classification | ✓ VERIFIED | Substantive, workflow-wired, and exercised by the provider fixture suite and formatter test. |
| Setup diagnostic registry, host wrapper, verifier, and README | Owner-first setup diagnostics | ✓ VERIFIED | Substantive, wired to CI and host paths, and exercised by the focused shell contract. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `liveRuns()` | GitHub Actions job attempts | `jobs?filter=all` → raw `jobs` | ✗ NOT_WIRED | Line 276 requests all attempts; only the run-level `run_attempt` survives. No per-job attempt is retained or filtered. |
| Live runner metadata | `cohortFingerprint()` | `runner_name` → `runner_image` | ✗ NOT_WIRED | Line 278 maps any truthy `runner_name` to `github-hosted`; line 67 treats that fabricated value as a cohort input. |
| Frozen NDJSON | Generated baseline Markdown | Deterministic renderer and byte comparison | ✓ WIRED | `node scripts/ci/verify_ci_baseline.mjs --records … --rendered … --require-critical-path` passed. |
| CI provider finalizer | Provider classifier and always-run summary | Current SHA + validated manifest → record → summary | ✓ WIRED | Static workflow contract plus fixture/formatter checks passed. |
| Host wrapper | Setup diagnostic registry | Fact-file delta and `host_gate_failure` fallback | ✓ WIRED | Focused shell contract passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Baseline collector | `jobs` / `run_attempt` | Actions jobs endpoint | No | ✗ MIXED: all historical attempts are returned and then combined under one current run attempt. |
| Cohort fingerprint | `runner_images` | `runner_name` projection | No | ✗ FABRICATED: source does not observe hostedness or image; it assigns `github-hosted` to any runner name. |
| Provider summary | `latest_proved_sha`, `latest_proved_at`, `stale` | Current SHA and validated manifest completion | Yes | ✓ FLOWING. |
| Setup summary | Emitted diagnostic fact | Host wrapper, registry, and CI artifact | Yes | ✓ FLOWING. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Baseline fixture engine | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | Exit 0 | ✓ PASS — inadequate for live rerun/image paths. |
| Frozen critical-path report | `node scripts/ci/verify_ci_baseline.mjs --records … --rendered … --require-critical-path` | Exit 0 | ✓ PASS — proves deterministic rendering only. |
| Live all-attempt isolation | Injected `liveRuns()` with run attempt 2 and one previous-attempt plus one current-attempt job | Endpoint was `jobs?filter=all`; both jobs returned in run attempt 2 | ✗ FAIL |
| Live runner classification | Same injected call, `runner_name: self-hosted-linux-x64` | Both jobs normalized to `runner_image: github-hosted` | ✗ FAIL |
| Provider proof state/freshness | `node scripts/ci/verify_provider_proof.mjs --fixtures` | Exit 0 | ✓ PASS |
| Provider manifest producer | `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors` | 2 tests, 0 failures | ✓ PASS |
| Setup diagnostic contract | `bash scripts/ci/verify_ci_setup_diagnostics.sh` | Exit 0 | ✓ PASS |
| Required-lane boundary | `bash scripts/ci/verify_phase225_required_lane_evidence.sh` | Exit 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 01, 02, 05, 06, 07, 12, 13, 14, 15 | Durable privacy-safe comparable CI baseline | ✗ BLOCKED | The live collector's two data-integrity defects invalidate comparable cohort and critical-path evidence despite passing frozen fixture/render checks. |
| BASE-02 | 03, 05, 06, 07, 12, 13, 14, 15 | Provider evidence visibly distinguishes proof states | ✓ SATISFIED | Exhaustive classifier/renderer fixtures and the focused formatter test pass. |
| OWN-01 | 04, 05, 07, 12, 13, 14, 15 | Host/CI ownership and setup diagnostics | ✓ SATISFIED | Registry, wrapper, CI plumbing, docs, and focused shell contract pass. |

All requirement IDs declared by Phase 226 plans are accounted for. `REQUIREMENTS.md` maps no additional requirement to Phase 226, so no requirement is orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | 276 | `filter=all` combines prior rerun attempts without preserving or filtering job attempt identity | 🛑 Blocker | A successful current run can contain older stage timings, failures, or duplicates. |
| `scripts/ci/collect_ci_baseline.mjs` | 278 | Truthy `runner_name` is represented as `github-hosted` | 🛑 Blocker | Self-hosted and changed-image jobs can be mixed in a purported comparable runner cohort. |
| `scripts/ci/verify_ci_baseline.mjs` | 114–118, 171–174, 230–248 | Tests model reruns as separate runs and hard-code image labels; the API-shaped live fixture has no multiple-attempt or runner-class controls | ⚠️ Warning | Passing tests do not exercise the stated production invariants. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in phase implementation files. The documentation references to deliberately invalid placeholder Stripe data are not implementation stubs. There are no conventional or phase-declared probes to execute.

### Gaps Summary

The Plan 15 display-name repair closes the prior prerequisite-identity defect. It does not address the independent baseline-correctness defects identified in review, both of which are reproduced from the current production code. These are not deferred: Phase 227's goal is a measured improvement, not repair of Phase 226's collector evidence semantics. This is an **Escalation Gate**: the baseline and critical-path claims cannot be accepted until the collector is corrected and the evidence recollected.

_Verified: 2026-08-12T03:16:00Z_
_Verifier: the agent (gsd-verifier)_
