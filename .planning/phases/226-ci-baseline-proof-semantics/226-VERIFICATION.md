---
phase: 226-ci-baseline-proof-semantics
verified: 2026-08-11T19:01:13Z
status: gaps_found
score: 2/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "A maintainer can inspect a durable comparable-run baseline containing workflow wall time, queue delay, job/step durations, reruns, cache behavior, Docker/browser setup cost, provider state, and root-failure signature without sensitive values."
    status: failed
    reason: "The live collector labels every ordinary full-CI run provider_state: non_run, while cohort qualification rejects non_run. It therefore excludes every live full-CI success from timing samples and can never produce a ready 20-run timing cohort."
    artifacts:
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "liveRuns() sets provider_state to non_run (line 263); summarizeCohorts() filters non_run from qualifying samples (line 161)."
      - path: "scripts/ci/verify_ci_baseline.mjs"
        issue: "The 20-run ready fixture uses the default proved state and contains no full-CI non_run regression case."
    missing:
      - "Qualify timing by full-CI topology/event rather than provider proof state, and add a 20-run non_run push/pull-request regression fixture."
  - truth: "The baseline records a measured roughly 33–36 minute staged release → host integration → Playwright critical path, or a contrary measured result, rather than runner queueing."
    status: failed
    reason: "All frozen cohorts report sample_count 0 because of the live qualification defect; the report consequently makes no comparable timing claim. Its named-path total is not a valid cohort percentile."
    artifacts:
      - path: ".planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson"
        issue: "Every cohort record is insufficient_sample with sample_count 0."
      - path: ".planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md"
        issue: "It states no critical-path percentile claim, so it cannot distinguish the requested actual critical path."
    missing:
      - "Repair qualification, recollect the frozen snapshot, regenerate the Markdown, and retain either a valid staged-path measurement or a valid contrary result."
  - truth: "CI baseline and provider-proof timestamp arithmetic fail closed on invalid timestamps."
    status: failed
    reason: "Both timestamp validators accept calendar-impossible canonical-looking strings because Date.parse normalizes them instead of rejecting them. This contradicts the plan's malformed-timestamp fail-first coverage and allows corrupted timing/freshness facts."
    artifacts:
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "timestamp() at lines 22-26 accepts 2026-02-30T00:00:00Z."
      - path: "scripts/ci/provider_proof.mjs"
        issue: "timestamp() at lines 21-24 also accepts the impossible date."
    missing:
      - "Require canonical UTC format plus a toISOString() round-trip, and add invalid-day and invalid-leap-day tests to both fixture gates."
---

# Phase 226: CI Baseline & Proof Semantics Verification Report

**Phase Goal:** Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Verified:** 2026-08-11T19:01:13Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Durable privacy-safe comparable-run baseline exposes the required timing, reliability, cache/setup, provider, and failure facts. | ✗ FAILED | Records and rendering are present and privacy checks pass, but live full-CI runs are all excluded from timing cohorts by their `non_run` provider state. |
| 2 | Required, skipped, and advisory provider evidence is visibly distinct; a non-run lane cannot be release proof. | ✓ VERIFIED | `verify_provider_proof.mjs --fixtures` passes; it exercises both policies and all six states. `ci.yml` finalizes and renders the record in the `live-stripe` job; the guide explicitly states that `non_run` provides no proof. |
| 3 | Host maintainers can determine ownership of Node/browser/Playwright setup and follow setup diagnostics. | ✓ VERIFIED | `verify_ci_setup_diagnostics.sh` passes; the host README has the host/CI ownership matrix and fixed next commands; the CI workflow exports the redacted setup-facts artifact. |
| 4 | Baseline confirms the staged 33–36 minute critical path or records a valid contrary measured result rather than queueing. | ✗ FAILED | The frozen report declares `insufficient_sample` for every cohort and no percentile claim. Its zero qualifying counts stem from the collector predicate, not valid full-CI scarcity. |

**Score:** 2/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact group | Expected | Status | Details |
| --- | --- | --- | --- |
| Collector, renderer, verifier, schema, baseline fixtures | Normalization and deterministic rendering | ⚠️ HOLLOW | All five are substantive and wired; fixture and byte-render checks pass, but the live collector's qualifying data flow is wrong. |
| Frozen NDJSON, generated Markdown, validation ledger | Durable before-state account | ⚠️ HOLLOW | Files exist and `verify_ci_baseline --records --rendered` plus a fresh renderer/cmp pass, but every cohort has zero qualifying samples. |
| Provider classifier, summary renderer, verifier, ExUnit manifest/fixture | Fail-closed provider state | ✓ VERIFIED | Artifacts are substantive; `node scripts/ci/verify_provider_proof.mjs --fixtures` and the single formatter test both pass. |
| Setup diagnostics, host wrapper/preflight, host package declaration | Owner-first setup diagnostics | ✓ VERIFIED | Artifacts are substantive, exercised by the shell contract, and used from the host wrapper/CI workflow. |
| CI workflow and maintainer docs | Always-run evidence plumbing and triage | ✓ VERIFIED | `ci.yml` wires provider preflight/finalize/summary/artifact and CI setup facts; README/guides link the commands and ownership matrix. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Collector | schema-v1 | strict record allowlists | ✓ WIRED | `validateRecord()` reads schema-v1; artifact verifier reports the link. |
| Fixture verifier | collector/renderer | imported exports and end-to-end fixture | ✓ WIRED | Direct imports run collection and render assertions. |
| Frozen NDJSON | Markdown | deterministic renderer | ✓ WIRED | Fresh `/tmp` render byte-compared equal to checked-in Markdown. |
| ExUnit formatter | provider classifier | manifest environment and CI finalize | ✓ WIRED | `ACCRUE_PROVIDER_MANIFEST` is written by the test formatter and consumed by `provider_proof.mjs` from `ci.yml`. |
| Host scripts/workflow | setup diagnostic registry | emitted facts and always-run summary | ✓ WIRED | `accrue_host_*` scripts invoke `ci_setup_diagnostic.sh`; `host-integration` publishes the artifact/summary. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| `collect_ci_baseline.mjs` | qualifying cohort durations | GitHub Actions run/job metadata | No — ordinary live full-CI records are filtered out by `provider_state !== non_run`. | ✗ DISCONNECTED |
| `226-CI-BASELINE.md` | cohort/reliability tables | checked-in NDJSON via `renderBaseline` | Yes, but timing sample data is hollow because upstream qualification yields zero. | ⚠️ HOLLOW |
| Provider summary | classified record | CI manifest → `provider_proof.mjs` → renderer | Yes in deterministic fixtures and workflow wiring. | ✓ FLOWING |
| Setup summary | `ACCRUE_CI_SETUP_FACTS` | diagnostic registry → host workflow artifact/summary | Yes in shell contract and workflow wiring. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Baseline fixture engine | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | PASS | ✓ PASS (but insufficient coverage) |
| Frozen baseline reproducibility | `verify_ci_baseline --records ... --rendered ...` and fresh render/cmp | PASS | ✓ PASS |
| Provider proof state machine | `node scripts/ci/verify_provider_proof.mjs --fixtures` | PASS | ✓ PASS |
| Formatter manifest contract | `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors` | 2 tests, 0 failures | ✓ PASS |
| Setup diagnostic contract | `scripts/ci/verify_ci_setup_diagnostics.sh` | PASS | ✓ PASS |
| Live full-CI timing qualification | 20 current full-CI `non_run` runs passed to `summarizeCohorts()` | `sample_count: 0`, `insufficient_sample` | ✗ FAIL |
| Calendar-invalid timestamps | `normalizeRun()` and `validateProviderManifest()` with `2026-02-30T00:00:00Z` | accepted | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 01, 02, 05 | Durable privacy-safe comparable CI baseline | ✗ BLOCKED | The data flow makes every live full-CI timing cohort empty; invalid calendar timestamps also do not fail closed. |
| BASE-02 | 03, 05 | Provider evidence visibly distinguishes required/skipped/advisory proof | ✓ SATISFIED | State-machine fixtures, formatter test, always-run workflow wiring, and maintainer guide corroborate it. |
| OWN-01 | 04, 05 | Host/CI ownership and setup diagnostics | ✓ SATISFIED | Shell verifier passes; owner-first registry, host wrapper, CI artifact, and docs are wired. |

All three requirement IDs declared in phase PLAN frontmatter are accounted for. No orphaned Phase 226 requirements were found in `REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | 161, 263 | Contradictory qualification state | 🛑 Blocker | Valid full-CI live data can never establish a timing cohort. |
| `scripts/ci/collect_ci_baseline.mjs` | 22-26 | `Date.parse` accepts normalized impossible dates | 🛑 Blocker | Corrupt timing data can be persisted and used in cohort arithmetic. |
| `scripts/ci/provider_proof.mjs` | 21-24 | `Date.parse` accepts normalized impossible dates | 🛑 Blocker | Corrupt timestamps can alter freshness outcomes. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in the phase implementation files. The word “placeholder” occurs only in user-facing Stripe test-data guidance, not an implementation stub.

### Gaps Summary

The phase has strong deterministic provider and ownership contracts, and the privacy-safe renderer is reproducible. However, the core BASE-01 live collection path has a contradictory predicate: it deliberately classifies ordinary CI as `non_run` for provider proof, then excludes that same state from CI timing. This makes the frozen baseline incapable of measuring a comparable green CI cohort and therefore incapable of distinguishing the actual critical path. Calendar-invalid timestamps also pass both relevant validators, contrary to the planned malformed-timestamp controls. These are blocking implementation gaps, not human-UAT uncertainty.

_Verified: 2026-08-11T19:01:13Z_
_Verifier: the agent (gsd-verifier)_
