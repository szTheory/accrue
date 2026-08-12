---
phase: 226-ci-baseline-proof-semantics
verified: 2026-08-12T02:47:27Z
status: gaps_found
score: 3/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/4
  gaps_closed:
    - "A newly successful provider proof is anchored to its current SHA and trusted manifest completion, so it renders fresh."
  gaps_remaining:
    - "A maintainer can inspect a durable comparable-run baseline from current GitHub Actions data."
  regressions: []
gaps:
  - truth: "A maintainer can inspect a durable, privacy-safe comparable-run baseline from current GitHub Actions data."
    status: failed
    reason: "The production collector still looks up a prerequisite in a different normalized display-name namespace than the actual CI workflow exposes."
    artifacts:
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "workflowNeeds() returns docs-contracts-shift-left, but the actual job display name Docs and bash contracts (shift-left) normalizes to docs-and-bash-contracts-shift-left. collectBaseline() aborts with an unresolved-prerequisite error."
      - path: "scripts/ci/verify_ci_baseline.mjs"
        issue: "The injected live fixture uses Docs contracts shift-left rather than the real workflow display name, so its passing assertion misses the production identity mismatch."
    missing:
      - "Resolve host-integration's prerequisite using docs-and-bash-contracts-shift-left (or derive workflow dependencies from the actual YAML job graph before matching them to observed display identities)."
      - "Make the live-data fixture use the exact .github/workflows/ci.yml display names and add a regression assertion for Docs and bash contracts (shift-left)."
---

# Phase 226: CI Baseline & Proof Semantics Verification Report

**Phase Goal:** Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Verified:** 2026-08-12T02:47:27Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A maintainer can inspect a durable comparable-run baseline containing workflow wall time, queue delay, job/step durations, reruns, cache behavior, Docker/browser setup cost, provider state, and root-failure signature without sensitive values. | ✗ FAILED | The schema, redaction controls, frozen NDJSON, and renderer are substantive, but the live collector cannot process the real host-integration topology: actual `Docs and bash contracts (shift-left)` becomes `docs-and-bash-contracts-shift-left`; `workflowNeeds()` asks for `docs-contracts-shift-left`, so collection fails closed. |
| 2 | Required, skipped, and advisory provider evidence is visibly distinct, so a skipped or non-run lane cannot be read as release proof. | ✓ VERIFIED | `classifyProviderProof()` retains independent policy/conclusion/state fields; a proved record now anchors `latest_proved_sha` to the current SHA and `latest_proved_at` to the validated manifest completion. The provider fixture gate verifies the current proof renders `Freshness: fresh` while non-run and weaker paths remain distinct. |
| 3 | A host maintainer can identify whether Node, browser installation, and Playwright setup belong to the host or CI and can follow documented diagnostics for each setup failure mode. | ✓ VERIFIED | The stable registry, host wrapper, CI fact artifact, and ownership table are wired. `verify_ci_setup_diagnostics.sh` exercises every code, preserves narrower inner facts, validates aggregate fallback, and retains one-worker/zero-retry failure evidence. |
| 4 | The baseline confirms the roughly 33–36 minute green-run critical path is staged release → host integration → Playwright work rather than runner queueing, or records a contrary measured result. | ✓ VERIFIED | Frozen NDJSON and Markdown pass `verify_ci_baseline.mjs --records … --rendered … --require-critical-path`, which verifies the deterministic compatible-path report and its staged-path conclusion. |

**Score:** 3/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | Read-only, privacy-safe Actions metadata collection | ⚠️ HOLLOW | Exists and validates allowlisted records, but its production live data flow fails on the real docs job display identity. |
| `226-CI-BASELINE.ndjson` and `226-CI-BASELINE.md` | Durable measured before-state and deterministic report | ✓ VERIFIED | 3,020 records and 4,556-line report; the frozen-record and critical-path gate passes. |
| `scripts/ci/provider_proof.mjs` and `render_provider_summary.mjs` | Literal proof-state and freshness classification | ✓ VERIFIED | Current proved state rebases freshness only after all proof predicates pass; static workflow contract and exhaustive fixture gate pass. |
| Setup diagnostic registry, host wrapper, verifier, and README | Owner-first setup diagnostics | ✓ VERIFIED | Scripts, workflow fact destination, and documentation agree; focused contract passes. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Collector `workflowNeeds()` | Live Actions job completion map | normalized prerequisite identity lookup | ✗ NOT_WIRED | `docs-contracts-shift-left` cannot resolve actual CI display identity `docs-and-bash-contracts-shift-left`; direct injected live-path reproduction throws the unresolved prerequisite error. |
| Frozen NDJSON | Generated baseline Markdown | deterministic renderer and byte comparison | ✓ WIRED | `verify_ci_baseline.mjs --records … --rendered … --require-critical-path` passes. |
| CI provider finalizer | Provider classifier and always-run summary | current SHA + trusted manifest → record → summary | ✓ WIRED | The workflow supplies SHA and manifest; provider static contract proves finalize precedes the always-run summary, and fixture coverage proves fresh current output. |
| Host wrapper | Setup diagnostic registry | fact-file delta and `host_gate_failure` fallback | ✓ WIRED | The shell contract proves inner-fact preservation, fallback, exact exit status, and success behavior. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Baseline collector | `needs` → `completedByName` → `dag_wait_ms` | GitHub Actions job display names | No | ✗ DISCONNECTED: the real Docs display name and hard-coded prerequisite normalize differently. |
| Critical-path report | staged compatible paths | Frozen run/job records | Yes | ✓ FLOWING: validated frozen cohort produces the staged release → host → Playwright conclusion. |
| Provider summary | `latest_proved_sha`, `latest_proved_at`, `stale` | Current SHA and validated manifest completion | Yes | ✓ FLOWING: a complete proof replaces its anchor before freshness is rendered. |
| Setup summary | emitted diagnostic fact | Host wrapper, registry, and CI artifact | Yes | ✓ FLOWING: narrow inner fact or aggregate fallback reaches the owner/action/evidence summary. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Baseline fixture engine | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | Exit 0 | ✓ PASS |
| Frozen critical-path report | `node scripts/ci/verify_ci_baseline.mjs --records … --rendered … --require-critical-path` | Exit 0 | ✓ PASS |
| Provider proof state/freshness | `node scripts/ci/verify_provider_proof.mjs --fixtures` | Exit 0 | ✓ PASS |
| Provider manifest producer | `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors` | 2 tests, 0 failures | ✓ PASS |
| Setup diagnostic contract | `bash scripts/ci/verify_ci_setup_diagnostics.sh` | Exit 0 | ✓ PASS |
| Required-lane boundary | `bash scripts/ci/verify_phase225_required_lane_evidence.sh` | Exit 0 | ✓ PASS |
| Actual Docs display-name path | injected `liveRuns()` using exact `.github/workflows/ci.yml` names | `job host-integration has unresolved prerequisite docs-contracts-shift-left` | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 01, 02, 05, 06, 07, 12, 13, 14 | Durable privacy-safe comparable CI baseline | ✗ BLOCKED | Frozen evidence and privacy controls pass, but current Actions metadata cannot become a durable baseline because one real prerequisite identity is unresolved. |
| BASE-02 | 03, 05, 06, 07, 12, 13, 14 | Provider evidence visibly distinguishes proof states | ✓ SATISFIED | Exhaustive classifier/renderer fixtures, current-proof freshness test, workflow contract, and formatter tests all pass. |
| OWN-01 | 04, 05, 07, 12, 13, 14 | Host/CI ownership and setup diagnostics | ✓ SATISFIED | Registry, wrapper, CI plumbing, documentation, and focused shell contract are present and passing. |

All requirement IDs declared by Phase 226 plans are accounted for. `REQUIREMENTS.md` maps no additional requirement to Phase 226, so no requirement is orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | 235 | Hard-coded docs prerequisite identity diverges from actual workflow display name | 🛑 Blocker | Live comparable-run collection fails closed for host integration. |
| `scripts/ci/verify_ci_baseline.mjs` | 227 | Synthetic job label omits `and bash`, hiding the production identity | ⚠️ Warning | A passing fixture does not exercise the actual workflow topology. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in phase implementation files. There are no conventional or phase-declared probes to execute.

### Gaps Summary

Plan 14 correctly closed the provider freshness defect, but it only repaired one of two display-name identity mismatches. The remaining mismatch is reproducible using the current workflow's literal job name and prevents the live collector from producing the durable baseline promised by BASE-01. Phase 227 is limited to a measured critical-path improvement and does not explicitly schedule this collector correctness repair, so the gap is not deferred.

_Verified: 2026-08-12T02:47:27Z_
_Verifier: the agent (gsd-verifier)_
