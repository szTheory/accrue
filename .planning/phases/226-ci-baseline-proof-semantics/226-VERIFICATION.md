---
phase: 226-ci-baseline-proof-semantics
verified: 2026-08-12T23:30:48Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "Every persisted snapshot, run, job, and cohort record passes full per-kind semantic validation before rendering, and only immutable allowlisted GitHub Actions run/job URLs can become Markdown evidence links."
  gaps_remaining: []
  regressions: []
---

# Phase 226: CI Baseline & Proof Semantics Verification Report

**Phase Goal:** Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Verified:** 2026-08-12T23:30:48Z
**Status:** passed
**Re-verification:** Yes — after Plan 226-21 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A durable comparable-run baseline contains the required timing, reliability, setup/cache, provider-state, and root-failure facts without sensitive values. | ✓ VERIFIED | `collect_ci_baseline.mjs` allowlists input/record fields and validates schema-v1; the committed NDJSON has no actor, raw branch, token, payload, log, or artifact-content fields. `verify_ci_baseline.mjs --fixtures --expected-repository acme/accrue` passed. |
| 2 | Required, skipped, and advisory provider evidence is visibly distinct; a non-run lane cannot be release proof. | ✓ VERIFIED | `classifyProviderProof()` returns literal independent policy/state/conclusion facts, with `non_run` for unselected triggers. Fixture verifier passed; the `live-stripe` workflow finalizes and summarizes in `if: always()` steps. |
| 3 | Host maintainers can determine Node/browser/Playwright ownership and follow documented, redacted diagnostics for setup failures. | ✓ VERIFIED | The host README supplies the ownership and diagnostic matrix; `verify_ci_setup_diagnostics.sh` passed. An independent `PGDATABASE=billing_database` wrapper invocation observed separate `-d` and `billing_database` argv entries, then emitted `fixture_or_database`, `OWNER=host`, its exact command, evidence location, and exit status. |
| 4 | The frozen baseline establishes the actual approximately 33–36 minute staged release → host integration → Playwright path rather than queueing, or would report a contrary measurement. | ✓ VERIFIED | Canonical verifier passed with `--require-critical-path --expected-repository szTheory/accrue`; it validates 20 compatible paths and the checked-in report records p50 2083s, p95 2602s, and `confirmed`. |
| 5 | Persisted baseline evidence cannot be forged into a false GitHub Actions report by changing repository provenance. | ✓ VERIFIED | `createRepositoryValidationContext()` requires caller-supplied `owner/repository`; `immutableUrl()` and snapshot validation require equality before renderer output. Fixture production-CLI controls reject URL-only and compound forged `attacker/forged` evidence before creating the requested report. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | Read-only normalization, cohort calculation, schema/privacy/provenance validation | ✓ VERIFIED | 483 substantive lines; all URL and record paths require an immutable branded repository-validation context. |
| `scripts/ci/render_ci_baseline.mjs` | Deterministic validated Markdown renderer | ✓ VERIFIED | Validates every record before interpolation; CLI requires one snapshot and `--expected-repository` before any write. |
| `scripts/ci/verify_ci_baseline.mjs` | Baseline, historical-topology, privacy, arithmetic, critical-path, and forged-render regressions | ✓ VERIFIED | 588 substantive lines; fixture suite and canonical critical-path invocation passed. |
| `226-CI-BASELINE.ndjson` and `226-CI-BASELINE.md` | Frozen privacy-safe before-state and report | ✓ VERIFIED | Canonical verifier compared the generated rendering with checked-in Markdown under `szTheory/accrue`. |
| `scripts/ci/provider_proof.mjs`, formatter, and provider renderer | Provider proof state and literal summary | ✓ VERIFIED | Provider fixtures passed; focused formatter/finalizer integration passed 4 tests. |
| Setup diagnostics and host wrapper | Owner-first diagnostics while retaining host proof contract | ✓ VERIFIED | Shell syntax checks and setup contract passed; wrapper preserves the expected `mix verify.full` delegation. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Caller repository argument | Collector, validator, renderer, and verifier APIs | One frozen `createRepositoryValidationContext()` object | ✓ WIRED | CLI `--repo`/`--expected-repository` construction is passed through all evidence-producing paths; plain/missing/mismatched contexts are rejected. |
| NDJSON records | Markdown evidence links | `validateRecord()` before `renderBaseline()` | ✓ WIRED | Snapshot and run/job URLs must match expected repository and numeric IDs before Markdown construction. |
| Canonical NDJSON | Canonical Markdown | Renderer/critical-path verification | ✓ WIRED | Canonical verification passed with explicit repository context. |
| Live suite manifest | Provider finalizer, always-run summary, and artifact | `ACCRUE_PROVIDER_MANIFEST` → `provider_proof.mjs` | ✓ WIRED | Workflow writes manifest, always runs finalizer/summary/artifact, and formatter test exercises finalization. |
| Host wrapper | Setup diagnostic registry | Readiness/browser failures emit code, owner, command, evidence | ✓ WIRED | `fixture_or_database` path was exercised independently and through the shell contract. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Baseline collector/report | Run/job/cohort timing and evidence URL facts | GitHub Actions metadata → schema-v1 NDJSON → validated renderer | Yes | ✓ FLOWING |
| Critical-path report | Staged span samples | 20 matching release-gate, host-integration, and Playwright job records | Yes | ✓ FLOWING |
| Provider summary | Policy/state/count/freshness facts | ExUnit manifest → finalizer record → summary/artifact | Yes | ✓ FLOWING |
| Setup diagnostics | Stable setup fact | Wrapper/browser script → diagnostic registry → fact file/summary | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Cross-repository and injection rejection | `node scripts/ci/verify_ci_baseline.mjs --fixtures --expected-repository acme/accrue` | `ci baseline fixtures: PASS` | ✓ PASS |
| Frozen staged critical path | `node scripts/ci/verify_ci_baseline.mjs --records … --rendered … --require-critical-path --expected-repository szTheory/accrue` | Exit 0; canonical report matches; 20 paths, p50 2083s, p95 2602s | ✓ PASS |
| Provider proof classifier | `node scripts/ci/verify_provider_proof.mjs --fixtures` | `provider proof fixtures: PASS` | ✓ PASS |
| Provider formatter/finalizer seam | `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors` | 4 tests, 0 failures | ✓ PASS |
| Setup diagnostic contract | `bash scripts/ci/verify_ci_setup_diagnostics.sh` | `verify_ci_setup_diagnostics: ok` | ✓ PASS |
| Required-lane preservation | `bash scripts/ci/verify_phase225_required_lane_evidence.sh` | Exit 0; expected run/SHA identified | ✓ PASS |
| `PGDATABASE` readiness argv | Exported `pg_isready` function plus `bash scripts/ci/accrue_host_uat.sh` | Received `-d` and `billing_database` as separate arguments; wrapper exited 89 after the deliberate readiness failure and emitted host diagnostic | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 01, 02, 05–07, 12–21 | Durable privacy-safe comparable baseline | ✓ SATISFIED | Collector, canonical baseline, provenance controls, renderer, fixture suite, and required critical-path verifier all passed. |
| BASE-02 | 03, 05–07, 12–21 | Provider proof states visibly distinguished | ✓ SATISFIED | Provider fixture verifier, focused formatter/finalizer test, workflow finalizer/summary wiring, and guide state table agree. |
| OWN-01 | 04, 05, 07, 12–21 | Host/CI setup ownership and diagnostics | ✓ SATISFIED | Ownership documentation, setup shell contract, direct readiness argv check, and retained host-wrapper delegation passed. |

Every requirement ID declared by Phase 226 plan frontmatter is accounted for. `REQUIREMENTS.md` maps no additional requirement to Phase 226, so no orphaned phase requirement was found. Its traceability table still says “Gaps Found” for all three IDs; that stale planning status is not implementation evidence and does not alter this verification result.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/ci/verify_ci_setup_diagnostics.sh` | 129–135 | The `pg_isready` fixture double chooses only an exit code and does not assert argv shape. | ⚠️ Warning | The independent argv spot-check disproves the review’s asserted production defect: Bash passes `-d` and `$PGDATABASE` separately. The fixture still has weaker regression sensitivity than it should for future argument-construction changes. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in the phase implementation files. No phase-declared or conventional standalone probe script was present.

### Review Finding Resolution

The advisory review’s CR-01 is not reproducible against current Bash semantics. In the actual wrapper command, `${PGDATABASE:+-d "$PGDATABASE"}` expands into the two argv elements `-d` and `billing_database`; it is not one malformed argument. Therefore it does not break OWN-01 or a Phase 226 success criterion. WR-01 is retained above as a test-quality warning, not a blocker.

---

_Verified: 2026-08-12T23:30:48Z_
_Verifier: the agent (gsd-verifier)_
