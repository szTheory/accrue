---
phase: 215-research-contracts-and-crosswake-feasibility
verified: 2026-08-02T02:49:00Z
status: passed
score: 19/19 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 18/19
  gaps_closed:
    - "The public URL-based validator now rejects every noncanonical report root, including a complete synthetic proven report and evidence tree."
  gaps_remaining: []
  regressions: []
---

# Phase 215: Research, Contracts, and Crosswake Feasibility Verification Report

**Phase Goal:** Maintainers have one current, evidence-backed multi-rail contract and know whether the required Crosswake client boundary is feasible before runtime coupling begins.
**Verified:** 2026-08-02T02:49:00Z
**Status:** passed
**Re-verification:** Yes — after Plan 215-15 gap closure.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | One current v1.59 bundle has provenance, choices, confidence, and a dated watchlist. | ✓ VERIFIED | `bash scripts/ci/verify_v159_authority.sh` passed; the index links the authority manifest, amendment ledger, and watchlist. |
| 2 | One decision table determines projection, eligibility, repair, and offline-continuity outcomes. | ✓ VERIFIED | `mix accrue.entitlements.decision_cases --check` and the focused ExUnit/property/vector suite passed: 5 properties, 20 tests. |
| 3 | Hosts inspect rail capabilities through a source matrix independent of processors. | ✓ VERIFIED | `verify_entitlement_source_matrix.sh` passed; `Source.Registry` returns typed `Outcome`/`CapabilityError` without processor dispatch. |
| 4 | The checked-in Crosswake tracer proves every required bridge or explicitly blocks runtime coupling before later phases rely on it. | ✓ VERIFIED | The canonical report is uniformly `feasibility_blocked` for unavailable pinned bridge/device lanes; the validator can only evaluate the validator-owned canonical report path. |
| 5 | Server/vector/JWS results remain independent of feasibility status. | ✓ VERIFIED | The Swift vector reader is documented test-only and does not feed the feasibility reducer; both vector consumers passed while the report remained blocked. |
| 6 | A verified newer allow or same/newer signed denial cannot be undone by stale evidence across restart/reconnect. | ✓ VERIFIED | Full Swift suite passed authenticated-envelope, recovery, interprocess, and signed-denial ordering tests. |
| 7 | D-07 is a closed case schema. | ✓ VERIFIED | Decision-case validation, deterministic export, and property coverage passed. |
| 8 | Offline vectors are canonically bound to each DecisionCase and prove declared JWS/cache outcomes in both languages. | ✓ VERIFIED | Export drift check plus Elixir and Swift GoldenVector tests passed. |
| 9 | Required JWS claim and algorithm checks execute in both implementations. | ✓ VERIFIED | Focused Elixir vector suite and Swift GoldenVector suite passed. |
| 10 | Wrong signature/key/device/account/audience/type/algorithm and ordering inputs fail closed. | ✓ VERIFIED | Canonical invalid-vector, rollback, and denial-precedence regressions passed in both readers. |
| 11 | Missing Crosswake/device proof cannot waive the server/vector lane. | ✓ VERIFIED | Vectors passed while `capability-report.json` remained uniformly `feasibility_blocked`. |
| 12 | Contract-test failure does not become a capability-report status. | ✓ VERIFIED | Static trace: `OfflineGoldenVectorVerifier` has no feasibility-reducer input; report validation only reduces report/evidence fields. |
| 13 | Amendments preserve supersession history and no independent 72-hour policy exists. | ✓ VERIFIED | The authority gate passed against the authority manifest and amendment ledger. |
| 14 | Watchlist changes require dated owner reassessment. | ✓ VERIFIED | The authority/watchlist gate enforces the dated monitor/trigger/owner/response tuple. |
| 15 | Source inspection is processor-free and uses a closed ordered vocabulary. | ✓ VERIFIED | Source-matrix conformance and processor-leakage gate passed. |
| 16 | Apple management gives stable external guidance and unavailable control is typed. | ✓ VERIFIED | `Source.Registry` emits `externally_managed` Apple guidance/URL and typed `CapabilityError` for unavailable operations. |
| 17 | Registry boundary cases and output order are deterministic. | ✓ VERIFIED | Registry validation and source-matrix conformance gate passed. |
| 18 | Apple results cannot dispatch Stripe billing mutation paths. | ✓ VERIFIED | Processor-leakage gate passed. |
| 19 | No public data-only or alternate-root route can manufacture a proven feasibility decision without canonical evidence provenance. | ✓ VERIFIED | Both validator entry points compare a standardized caller URL to the validator-derived canonical report URL before decoding; the focused complete hostile-root regression passed. |

**Score:** 19/19 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact group | Expected | Status | Details |
| --- | --- | --- | --- |
| Authority manifest, ledger, and watchlist verifier | Current governed v1.59 bundle | ✓ VERIFIED | All 3 Plan 215-02 artifacts are substantive, indexed, and gate-protected. |
| DecisionCases and generated Markdown/JSON/offline vectors | Canonical decision contract | ✓ VERIFIED | All Plan 215-03/05/06/07/09 artifacts exist; export check proves current generated data flow. |
| Source registry, outcomes, fixture, and matrix verifier | Rail-specific inspection boundary | ✓ VERIFIED | Typed, ordered, processor-independent artefacts are live and gate-protected. |
| Crosswake Swift package, report, runbook, validator, and tests | Honest prove-or-block boundary | ✓ VERIFIED | 25 Swift phase artifacts are substantive and exercised by the 23-test package suite. |
| Authenticated cache and process harness | Durable monotonic native cache proof | ✓ VERIFIED | HMAC envelope, locking, recovery, and process harness are wired by passing tests. |
| Plan 215-15 canonical-root guard and hostile fixture | Immutable public proof authority | ✓ VERIFIED | `hasCanonicalReportIdentity` protects public and internal validation seams; the fixture has all lanes and nonempty evidence files. |

All 49 declared plan artifacts exist and passed the substantive artifact check. No dynamic UI artifacts require an additional UI data-flow trace.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Research index | Authority manifest and amendment ledger | First v1.59 authority entry and precedence link | ✓ WIRED | Authority gate passed. |
| DecisionCases | Markdown, JSON, and offline vectors | `Export.generated/0` reads `DecisionCases.all/0` and emits all checked-in outputs | ✓ WIRED | Export drift check passed. |
| Source registry | Typed outcomes and capability matrix | Ordered inspection plus literal/leakage gate | ✓ WIRED | Source-matrix gate passed. |
| Swift/Elixir readers | Canonical offline fixture and DecisionCase bindings | Exact field/identity/claim comparisons | ✓ WIRED | Both reader suites passed. |
| `ProofHighWater` and cache writer | Shared `ProofReplacementOrder` | Signed-denial ordering before durable replacement | ✓ WIRED | Tested by the full Swift package. |
| Public and internal report validators | Canonical `capability-report.json` | Standardized equality to validator-owned URL before decode or evidence evaluation | ✓ WIRED | Complete temporary proven root is rejected; canonical report validates as blocked. |
| Proven rows | Evidence files | Canonical root, containment, kind, regular/nonempty file, terminal reason, and device checks | ✓ WIRED | Code path retained after the identity guard; mutation/capability suite passed. |

The generic key-link helper reports nine symbolic-component links as unresolved because their `from` values are symbols rather than relative file paths. Manual source-to-test tracing above verifies those links; none is missing or partial.

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| Decision documentation and JSON | Canonical cases | `DecisionCases.all/0` through deterministic export | Yes | ✓ FLOWING |
| Offline corpus | Case/version/disposition and expected outcomes | Generated cases/specifications into both readers | Yes | ✓ FLOWING |
| Cache ordering after restart | Authenticated payload/revision/disposition | HMAC envelope and path-scoped coordination | Yes | ✓ FLOWING |
| Current feasibility status | Report rows/reason | Canonical checked-in report with unavailable bridge/device evidence | Yes — returns the honest blocked disposition | ✓ FLOWING |
| Public proven evaluation | Report URL and evidence root | Validator-owned canonical location, then evidence checks | Yes — alternate roots throw before evaluation | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Root-substitution resistance | `swift test --filter 'CapabilityReportTests/completeTemporaryProvenReportIsRejected'` | Complete synthetic proven tree rejected | ✓ PASS |
| Capability report behavior | `swift test --filter CapabilityReportTests` | 9 tests, 0 failures | ✓ PASS |
| Tracer/vector/cache contract | `swift test` | 23 tests, 0 failures | ✓ PASS |
| Authority/watchlist contract | `bash scripts/ci/verify_v159_authority.sh` | `OK` | ✓ PASS |
| Source matrix/leakage contract | `bash scripts/ci/verify_entitlement_source_matrix.sh` | `OK` | ✓ PASS |
| Decision export and Elixir contract | `mix accrue.entitlements.decision_cases --check && mix test ...` | 5 properties, 20 tests, 0 failures | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no phase-declared or conventional `probe-*.sh` files were found.

### Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| RSCH-01 | 215-02, 215-08, 215-12, 215-14 | Current versioned research authority | ✓ SATISFIED | Authority/index/ledger/watchlist gate passes. |
| RSCH-02 | 215-03, 215-05–215-10, 215-12, 215-14 | Canonical decision table drives consumers | ✓ SATISFIED | Canonical source, generated views, drift detection, and reader tests pass. |
| RSCH-03 | 215-02, 215-08, 215-12, 215-14 | Dated owner/response watchlist | ✓ SATISFIED | Authority gate passes. |
| RAIL-04 | 215-04, 215-08, 215-12, 215-14 | Dedicated rail capability inspection matrix | ✓ SATISFIED | Typed registry/matrix and leakage gate pass. |
| RAIL-05 | 215-01, 215-05, 215-07–215-15 | Honest Crosswake prove-or-block tracer | ✓ SATISFIED | Canonical report explicitly blocks coupling; canonical-root guard and hostile-root regression prevent a fabricated proof authority. |

All roadmap Phase-215 requirements occur in PLAN frontmatter. No orphaned requirement was found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift` | 751–785 | Future `.proven` evidence accepts canonical-root files by path/kind/nonempty checks and device text markers, not content hashes/build attestation. | ⚠️ WARNING | Future hardening required before converting the report to `.proven`; does not alter the current blocked result. |
| `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift` | 777–785 | Physical-device completion is marker-based rather than a structured versioned record. | ⚠️ WARNING | Same future-proof concern; canonical report currently remains blocked because required bridge/device evidence is unavailable. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt marker was found in phase-modified implementation artifacts.

### Review-Warning Disposition

`215-REVIEW.md` warnings WR-01 and WR-02 are legitimate hardening work for the later event where a maintainer proposes a `.proven` report. They are not Phase-215 blockers: the phase contract permits an evidence-backed explicit block, and the checked-in canonical artifact is uniformly `feasibility_blocked` because the pinned Crosswake bridge and physical-device evidence are unavailable. The Plan 215-15 guard removes the actual current blocker: no caller-selected complete tree can reach `.proven`.

Before changing the canonical report to `.proven`, add structured, immutable build/device-evidence attestation and negative placeholder mutations. That is a future acceptance condition, not a reason to claim current runtime coupling is feasible.

### Gaps Summary

None. The prior canonical-report-root gap is closed and no later-phase deferral was needed.

---

_Verified: 2026-08-02T02:49:00Z_
_Verifier: the agent (gsd-verifier)_
