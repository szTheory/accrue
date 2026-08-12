---
phase: 226-ci-baseline-proof-semantics
verified: 2026-08-12T20:35:10Z
status: gaps_found
score: 4/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/4
  gaps_closed:
    - "Historical identity, runner, and prerequisite contracts now derive from the immutable workflow source fetched at each run head SHA."
    - "Newline and Markdown-heading URL injection is rejected before the production renderer writes output."
  gaps_remaining:
    - "A syntactically valid GitHub Actions URL from an arbitrary repository is still accepted and rendered as baseline evidence."
  regressions: []
gaps:
  - truth: "Every persisted snapshot, run, job, and cohort record passes full per-kind semantic validation before rendering, and only immutable allowlisted GitHub Actions run/job URLs can become Markdown evidence links."
    status: failed
    reason: "validateRecord() accepts any github.com/<owner>/<repo>/actions/runs/<matching-id> URL. A run record changed from szTheory/accrue to attacker/forged passed validation and renderBaseline() emitted the attacker-controlled evidence link. This is a forged false-evidence path, even though newline/link-closing injection is now rejected."
    artifacts:
      - path: "scripts/ci/collect_ci_baseline.mjs"
        issue: "immutableUrl() constrains only URL shape and numeric IDs; it does not constrain owner/repository to the snapshot's allowlisted repository."
      - path: "scripts/ci/render_ci_baseline.mjs"
        issue: "renderBaseline() trusts validateRecord() and consequently renders the accepted cross-repository URL."
      - path: "scripts/ci/verify_ci_baseline.mjs"
        issue: "The forged-NDJSON regression covers newline injection, but has no cross-repository allowlist negative control."
    missing:
      - "Bind every run/job evidence URL to the snapshot repository (or an explicit immutable repository allowlist) before rendering."
      - "Add a production-renderer regression proving a valid-looking cross-repository GitHub Actions URL is rejected and produces no report."
---

# Phase 226: CI Baseline & Proof Semantics Verification Report

**Phase Goal:** Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Verified:** 2026-08-12T20:35:10Z
**Status:** gaps_found
**Re-verification:** Yes — after Plan 226-20 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Historical identity, runner, matrix, prerequisite, and timing contracts come from the immutable `ci.yml` fetched at each run head SHA. | ✓ VERIFIED | `liveRuns()` fetches source at `head_sha`, hashes and parses that same string, and passes its contracts to identity, runner, eligibility, and `needs` resolution. The fixture injects historical `macos-15`/`release-gate` topology that differs from current `ci.yml` and passes. |
| 2 | Persisted baseline records can render only immutable allowlisted evidence links; forged values cannot make a false report claim. | ✗ FAILED | A copied canonical run whose URL owner/repo was changed from `szTheory/accrue` to `attacker/forged` passed `validateRecord()` and `renderBaseline()`. The report would show the attacker URL as evidence. |
| 3 | The checked-in baseline is deterministic and confirms the measured staged release → host integration → Playwright path rather than queueing. | ✓ VERIFIED | Canonical verifier passed with `--require-critical-path`; independently derived 20 paths, p50 2,083s, p95 2,602s, and `confirmed`. Rendering to an explicit output path byte-matched the committed Markdown. |
| 4 | Required, skipped, and advisory provider evidence remains distinct and a non-run lane cannot be read as release proof. | ✓ VERIFIED | Provider fixtures passed; the focused ExUnit formatter/finalizer suite passed 4 tests; workflow wiring passes the trusted manifest into an always-run finalizer with `--policy required`. |
| 5 | Host/CI setup ownership and diagnostics remain legible without moving the host Playwright proof to CI. | ✓ VERIFIED | `verify_ci_setup_diagnostics.sh` and the required-lane evidence contract both passed. |

**Score:** 4/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | Immutable-source collector and semantic validator | ⚠️ PARTIAL | Substantive and wired; historical topology repair is real, but URL validation lacks a repository allowlist. |
| `scripts/ci/render_ci_baseline.mjs` | Deterministic injection-safe Markdown renderer | ⚠️ PARTIAL | It validates all records before rendering and rejects newline headings, but renders a valid-looking cross-repository URL that validation accepts. |
| `scripts/ci/verify_ci_baseline.mjs` | Historical-topology and forged-record production-path regressions | ⚠️ PARTIAL | The historical-topology and newline-forgery checks pass; no test covers a cross-repository forged URL. |
| `226-CI-BASELINE.ndjson` / `226-CI-BASELINE.md` | Recollected deterministic baseline/report | ⚠️ HOLLOW GUARD | The committed pair verifies and byte-reproduces through the explicit `--out` path, but the general renderer guard admits false evidence links. |
| Provider proof and setup diagnostic artifacts | Provider-state and owner-first evidence | ✓ VERIFIED | Focused provider, formatter, setup, and required-lane commands passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Head-SHA workflow contents | Historical contract resolution | Fetched source → revision, contracts, identity, runner, needs | ✓ WIRED | Code and divergent-topology fixture verify the exact immutable-source path. |
| `validateRecord()` | `renderBaseline()` | Validation before every rendered row/link | ⚠️ PARTIAL | The call is wired, but validation permits cross-repository GitHub URLs. |
| Canonical NDJSON | Canonical Markdown | Renderer invoked with explicit `--out`; byte comparison | ✓ WIRED | Independent explicit-output render matched the committed report byte-for-byte. |
| Live suite manifest | Provider finalizer/summary/artifact | Always-run workflow finalizer | ✓ WIRED | Provider fixture suite and static workflow contract passed. |
| Host wrapper | Setup diagnostic registry | Owner-first diagnostics | ✓ WIRED | Setup diagnostic contract passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Historical collector | Per-run identity, runner, prerequisites, DAG wait | GitHub Contents at each run's `head_sha` plus attempt-scoped jobs | Yes | ✓ FLOWING |
| Baseline report | Canonical record facts and evidence URLs | NDJSON → `validateRecord()` → renderer | Partially | ⚠️ URL source may name an arbitrary GitHub repository |
| Provider proof | Selected/passed/skipped manifest counts | ExUnit formatter → production finalizer | Yes | ✓ FLOWING |
| Setup diagnostics | Ownership/failure facts | Host wrapper/diagnostic registry | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Immutable historical topology and newline-forgery regression | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | `ci baseline fixtures: PASS` | ✓ PASS |
| Frozen staged critical path | `node scripts/ci/verify_ci_baseline.mjs --records … --rendered … --require-critical-path` | Exit 0; 20 paths, p50 2083s, p95 2602s, confirmed | ✓ PASS |
| Explicit-output byte reproduction | `render_ci_baseline.mjs --input … --out /tmp/... && cmp` | Byte-identical | ✓ PASS |
| Cross-repository forged record | `validateRecord({...run_url: attacker/forged...}); renderBaseline(...)` | Both accepted | ✗ FAIL |
| Provider proof classifier | `node scripts/ci/verify_provider_proof.mjs --fixtures` | `provider proof fixtures: PASS` | ✓ PASS |
| Real selected-suite finalizer | `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors` | 4 tests, 0 failures | ✓ PASS |
| Setup ownership diagnostics | `bash scripts/ci/verify_ci_setup_diagnostics.sh` | `ok` | ✓ PASS |
| Required lane boundary | `bash scripts/ci/verify_phase225_required_lane_evidence.sh` | Exit 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 01, 02, 05–07, 12–20 | Durable privacy-safe comparable baseline | ✗ BLOCKED | Historical-topology gap is closed, but cross-repository forged evidence still passes the record-to-report path. |
| BASE-02 | 03, 05–07, 12–20 | Provider proof states visibly distinguished | ✓ SATISFIED | Provider fixtures, formatter integration, and workflow finalizer wiring passed. |
| OWN-01 | 04, 05, 07, 12–20 | Host/CI setup ownership and diagnostics | ✓ SATISFIED | Setup diagnostic and required-lane contracts passed. |

All requirement IDs declared in every Phase 226 plan frontmatter are accounted for. `REQUIREMENTS.md` maps no additional requirement ID to Phase 226; no orphaned requirements were found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/ci/collect_ci_baseline.mjs` | 37–42 | URL validator accepts every GitHub owner/repository | 🛑 Blocker | A forged but syntactically valid Actions URL can be rendered as baseline evidence. |
| `scripts/ci/verify_ci_baseline.mjs` | 518–524 | Forgery regression covers only newline/heading injection | ⚠️ Warning | Cross-repository false-evidence path is untested. |
| `scripts/ci/render_ci_baseline.mjs` | CLI argument parsing | Omitting `--out` treats `--input` as the output path | ℹ️ Info | All canonical paths pass explicit `--out`; this does not cause the blocker above but violates the usage text's optional-output behavior. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in the phase implementation files. No documented or conventional standalone probe scripts were present.

### Gaps Summary

Plan 226-20 genuinely closes the old current-workflow-topology defect: the production collector now resolves historical runs through the fetched source bytes and its divergent topology regression exercises that behavior. It also closes newline Markdown injection. However, its URL rule is only a GitHub-shape rule, not an evidence allowlist. A malicious persisted record can substitute an arbitrary GitHub repository while retaining the numeric run ID, pass validation, and publish a believable but false evidence link. This is a **BLOCKER / Escalation Gate** for BASE-01; Phase 227 does not explicitly schedule this evidence-integrity repair, so it is not deferred.

_Verified: 2026-08-12T20:35:10Z_
_Verifier: the agent (gsd-verifier)_
