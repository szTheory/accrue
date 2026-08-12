---
phase: 226-ci-baseline-proof-semantics
verified: 2026-08-12T17:24:00Z
status: gaps_found
score: 3/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 1/4
  gaps_closed:
    - "Historical compatibility is now bound to enumerated immutable workflow revisions and exact identities."
    - "Runner cohort resolution now accepts only exact declared workflow identities and finite matrix aliases."
    - "An initial Postgres-readiness failure now emits owner-first fixture_or_database diagnostics before exit."
  gaps_remaining:
    - "The live-provider formatter counts ExUnit excluded tests as selected failures, so a valid tagged live-Stripe suite cannot reach proved."
  regressions: []
gaps:
  - truth: "Required, skipped, and advisory provider evidence is visibly distinct, so a skipped or non-run lane cannot be read as release proof."
    status: failed
    reason: "The workflow-required live-Stripe suite writes an invalid manifest: ExUnit's excluded non-live tests are counted as failures. A successful selected suite therefore finalizes as misconfigured rather than proved."
    artifacts:
      - path: "accrue/test/support/live_proof_formatter.ex"
        issue: "The catch-all increment clause classifies {:excluded, reason} as a selected failure."
      - path: "accrue/test/accrue/live_proof_formatter_test.exs"
        issue: "No test exercises {:excluded, reason} or actual mix test --only live_stripe formatter semantics."
      - path: "guides/testing-live-stripe.md"
        issue: "The documented advisory/continue-on-error expectation contradicts the workflow's required policy."
    missing:
      - "Ignore {:excluded, reason} formatter events so only selected live tests contribute to the manifest."
      - "Add a formatter regression for excluded events (ideally an integration-level test of mix test --only live_stripe semantics)."
      - "Correct the live-Stripe documentation to describe the required scheduled/manual proof policy."
---

# Phase 226: CI Baseline & Proof Semantics Verification Report

**Phase Goal:** Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Verified:** 2026-08-12T17:24:00Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A maintainer can inspect a durable comparable-run baseline containing workflow wall time, queue delay, job/step durations, reruns, cache behavior, Docker/browser setup cost, provider state, and root-failure signature without sensitive values. | ✓ VERIFIED | `verify_ci_baseline --fixtures` passed. Collector now uses enumerated immutable revisions and exact workflow aliases; the 2,009-line frozen NDJSON passes schema/privacy/reproducibility validation and its Markdown states raw logs, actors, branches, secrets, payloads, and artifacts are absent. |
| 2 | Required, skipped, and advisory provider evidence is visibly distinct, so a skipped or non-run lane cannot be read as release proof. | ✗ FAILED | Static fixtures pass, but a real `ACCRUE_PROVIDER_MANIFEST=/tmp/... mix test.live --trace` run wrote `selected_count=2124`, `failed_count=2114`, `skipped_count=10` for `10 tests, 0 failures, 10 skipped (2114 excluded)`. Finalization with this manifest exited 1 and recorded `proof_state=misconfigured`, not `proved`. |
| 3 | A host maintainer can identify whether Node, browser installation, and Playwright setup belong to the host or CI and can follow documented diagnostics for each setup failure mode. | ✓ VERIFIED | `verify_ci_setup_diagnostics.sh` passed, including the initial-readiness control. `accrue_host_uat.sh:32-47` explicitly captures `pg_isready` status and emits/renders `fixture_or_database` with `FAILED_GATE=host-integration`. |
| 4 | The baseline confirms the roughly 33–36 minute green-run critical path is staged release → host integration → Playwright work rather than runner queueing, or records a contrary measured result. | ✓ VERIFIED | Frozen-evidence critical-path gate passed. The rendered report records 20 complete paths, p50 2083s and p95 2602s, measuring release-gate start through latest Playwright completion without summing parallel shards; it separately reports 1,354 root-queue and 354 dependent-DAG-wait observations. |

**Score:** 3/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | Read-only, fail-closed comparable-run collection | ✓ VERIFIED | Substantive, CLI-wired, and fixture-covered. Immutable revision compatibility (`:248-263`) and exact identity resolution (`:296-301`) close the prior unsafe admission paths. |
| Frozen NDJSON and Markdown baseline | Durable privacy-safe critical-path evidence | ✓ VERIFIED | 2,009 NDJSON records and deterministic Markdown are wired by `render_ci_baseline.mjs`; canonical record/render/critical-path validation passed. |
| `scripts/ci/provider_proof.mjs` plus formatter | Literal proof-state and a manifest that can represent a successful selected suite | ✗ HOLLOW | Classifier and fixture gate are substantive, but formatter line 48 turns unselected `{:excluded, _}` events into failures, preventing actual provider proof. |
| Setup diagnostic registry and host wrapper | Owner-first host/CI setup diagnostics | ✓ VERIFIED | Registry, wrapper, verifier, workflow, and docs are connected; initial readiness is explicitly handled. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Actions attempt metadata | Baseline collector | Exact attempt endpoint, attempt matching, immutable revision and workflow identity | ✓ WIRED | Baseline fixture gate exercises rerun, revision, identity, skipped-node, and prerequisite failure controls. |
| Frozen NDJSON | Baseline Markdown | Deterministic renderer and `--require-critical-path` validation | ✓ WIRED | Command exited 0 against canonical evidence. |
| `mix test.live` | `LiveProofFormatter` manifest | `ACCRUE_PROVIDER_MANIFEST` formatter registration in `test_helper.exs` | ✗ NOT_WIRED CORRECTLY | Link executes, but excluded events contaminate selected-test counts. |
| Manifest | `provider_proof.mjs --finalize` | Workflow `live_stripe_suite` → `provider_proof_finalize` steps | ✗ NOT_WIRED CORRECTLY | The actual manifest is rejected as `manifest_invalid`; finalizer exits 1. |
| Host wrapper | Diagnostic registry | Explicit readiness-status branch and rendered setup fact | ✓ WIRED | Setup diagnostic contract passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Baseline collector | run/job/cohort timing facts | Actions attempt-scoped metadata plus revision-pinned workflow contract | Yes | ✓ FLOWING |
| Frozen critical-path report | staged paths / percentiles | Sanitized canonical NDJSON → renderer | Yes | ✓ FLOWING |
| Provider proof record | selected/passed/skipped/failed manifest counts | ExUnit formatter events from `mix test.live` | No — excluded tests become failures | ✗ HOLLOW |
| Setup summary | diagnostic fact | host wrapper and registry | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Comparable-run fixture boundaries | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | Exit 0, `ci baseline fixtures: PASS` | ✓ PASS |
| Frozen critical-path evidence | `node scripts/ci/verify_ci_baseline.mjs --records … --rendered … --require-critical-path` | Exit 0 | ✓ PASS |
| Provider proof unit fixtures | `node scripts/ci/verify_provider_proof.mjs --fixtures` | Exit 0, `provider proof fixtures: PASS` | ✓ PASS — does not cover ExUnit exclusions |
| Actual live-suite manifest | `cd accrue && ACCRUE_PROVIDER_MANIFEST=/tmp/... mix test.live --trace` | Exit 0; `10 tests, 0 failures, 10 skipped (2114 excluded)`; manifest has 2,114 failures | ✗ FAIL |
| Actual provider finalization | `node scripts/ci/provider_proof.mjs --finalize … --manifest /tmp/...` | Exit 1; generated record has `proof_state: misconfigured`, `reason_code: manifest_invalid` | ✗ FAIL |
| Setup diagnostic contract | `bash scripts/ci/verify_ci_setup_diagnostics.sh` | Exit 0, `ok` | ✓ PASS |
| Prior required-lane boundary | `bash scripts/ci/verify_phase225_required_lane_evidence.sh` | Exit 0 | ✓ PASS |
| Formatter unit test | `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors` | 2 tests, 0 failures | ✓ PASS — misleading coverage; it omits excluded-event behavior |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 01, 02, 05, 06, 07, 12–18 | Durable, privacy-safe comparable CI baseline | ✓ SATISFIED | Latest fail-closed collector fixtures and frozen record/render gate pass; report supplies measured 20-path conclusion. |
| BASE-02 | 03, 05–07, 12–18 | Provider evidence visibly distinguishes proof states | ✗ BLOCKED | While states are classified literally, the required live-provider execution cannot create `proved` evidence because the manifest misclassifies excluded tests. |
| OWN-01 | 04, 05, 07, 12–18 | Host/CI setup ownership and diagnostics | ✓ SATISFIED | Owner-first diagnostics including initial Postgres readiness are covered by the shell contract. |

All requirement IDs declared by Phase 226 plan frontmatter are accounted for. `REQUIREMENTS.md` maps no additional IDs to Phase 226; no orphaned requirements were found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `accrue/test/support/live_proof_formatter.ex` | 48-49 | Catch-all maps ExUnit `{:excluded, _}` to a selected failure | 🛑 Blocker | A valid tagged provider run can never become `proved`. |
| `accrue/test/accrue/live_proof_formatter_test.exs` | 6-30 | Test simulates pass/skip/failure only, not excluded events | ⚠️ Warning | Passing test masks the live-suite manifest defect. |
| `guides/testing-live-stripe.md` | 125-132 | Claims advisory `continue-on-error` behavior unlike required workflow finalizer | ⚠️ Warning | Maintainer incident expectations are incorrect. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in phase implementation files. The word “placeholder” occurs only in user-facing test-data guidance and is not a stub. No declared or conventional standalone probes were present beyond the executed fixture/contract checks.

### Gaps Summary

The earlier comparability and setup-diagnostic gaps are closed, and the fresh baseline is credible. The provider state machine is fail-closed, but its execution seam is broken: the formatter treats tests excluded by `--only live_stripe` as selected failures. This is not deferred to Phase 227, whose scope assumes an equally identifiable and recoverable provider proof. It is a **BLOCKER / Escalation Gate**: repair the formatter and its integration coverage, update the contradictory guide, then rerun the provider and full Phase 226 regression contract.

_Verified: 2026-08-12T17:24:00Z_
_Verifier: the agent (gsd-verifier)_
