---
phase: 215-research-contracts-and-crosswake-feasibility
verified: 2026-08-01T02:36:30Z
status: gaps_found
score: 14/18 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The decision corpus is a closed D-07 contract that implementers can safely drive from."
    status: failed
    reason: "DecisionCases.valid?/1 accepts arbitrary evidence.kind, continuity, and repair atoms, ignores account/device bindings, and permits negative revision_delta. Its property suite only reasserts immutable fixture values rather than exercising a decision operation."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/decision_cases.ex"
        issue: "Lines 73-75 and 91-96 leave claimed closed fields unconstrained."
      - path: "accrue/test/property/entitlement_decision_cases_property_test.exs"
        issue: "Generated inputs do not reach a reducer or implementation under test."
    missing:
      - "Closed validation for every D-07 field, including bindings and non-negative revision delta."
      - "Non-vacuous tests that pass generated evidence/prior state through the consumer operation."
  - truth: "The shared offline corpus proves the declared JWS accept/reject and cache outcomes in both Elixir and Swift."
    status: failed
    reason: "The checked-in fault_before_replace vector declares expected_cache_disposition=allow, but both implementations and both tests observe deny. Expected verification/cache fields are decoded yet never compared to observations; required wrong account/audience/type/algorithm cases are also absent from the corpus."
    artifacts:
      - path: "accrue/priv/entitlements/v1.59-offline-golden-vectors.json"
        issue: "fault_before_replace declares allow although the tested prior cache and observed result are deny."
      - path: "examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift"
        issue: "Lines 25-35 decode expected fields but do not assert them; unknown signed disposition falls through to allow."
      - path: "accrue/test/support/entitlements/offline_golden_vector_verifier.ex"
        issue: "Observed result is not checked against fixture expectations; high-water claims are not type-checked and unknown disposition maps to allow."
    missing:
      - "A complete invalid-input corpus and fixture-to-observation assertions in both language implementations."
      - "Closed claim/disposition validation and corrected, self-validating cache expectations."
  - truth: "A verified newer allow or same/newer signed denial replaces cached state atomically without torn or resurrected state."
    status: failed
    reason: "AtomicOfflineCache.replace uses one shared .<name>.candidate pathname with no lock/actor. Concurrent replacement calls can overwrite or rename each other's candidate, so the single-threaded fault test does not prove the required lifecycle/reconnect invariant. Parent-directory durability after rename is also not established."
    artifacts:
      - path: "examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift"
        issue: "Lines 100-113 use a shared candidate and unsynchronized write/rename sequence."
      - path: "examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift"
        issue: "Only serial before/after rename faults are exercised; no concurrent replacement or crash-reopen durability test exists."
    missing:
      - "Per-cache replacement serialization and unique candidate paths with cleanup."
      - "A concurrent-replacement regression test and a platform-appropriate durable directory-sync/crash-reopen proof."
---

# Phase 215: Research, Contracts, and Crosswake Feasibility Verification Report

**Phase Goal:** Maintainers have one current, evidence-backed multi-rail contract and know whether the required Crosswake client boundary is feasible before runtime coupling begins.
**Verified:** 2026-08-01T02:36:30Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | One current, versioned v1.59 bundle has provenance, choices, confidence, and dated watchlist. | ✓ VERIFIED | `RESEARCH-INDEX.md` leads with `v1.59-AUTHORITY.md`; authority, amendment ledger, and watchlist are dated and the authority gate passed. |
| 2 | One decision table determines duplicate, ordering, revocation, survivor, eligibility, repair, and offline outcomes. | ✗ FAILED | Corpus/table exist, but the claimed closed D-07 validator accepts invalid contract values and the property tests do not execute a decision implementation. |
| 3 | Hosts inspect rail capabilities through a source matrix independent of processors. | ✓ VERIFIED | Typed source registry, JSON mirror, matrix, guide, leakage gate, and 8 scoped tests passed. |
| 4 | The tracer proves every bridge or explicitly blocks mobile runtime coupling. | ✓ VERIFIED | `capability-report.json` has all 13 required rows and overall `feasibility_blocked`; research records unavailable pinned Crosswake/device evidence and bars coupling. |
| 5 | Server/vector/JWS results remain independent of feasibility status. | ✓ VERIFIED | Swift source declares the fixture path test-only and excludes it from capability reporting; the report and reducer contain no 215-05 inputs. |
| 6 | Verified cache replacement is atomic across lifecycle/reconnect work. | ✗ FAILED | Shared candidate filename and no synchronization make the claimed concurrent invariant false despite serial fault tests passing. |
| 7 | D-07 is a closed case schema. | ✗ FAILED | `valid?/1` permits arbitrary field atoms, unchecked bindings, and negative `revision_delta`. |
| 8 | Offline vectors are derived from canonical DecisionCases. | ✓ VERIFIED | `Export.offline_vectors/0` maps canonical `DecisionCases.all/0` IDs/version/disposition; `mix ... --check` passed. |
| 9 | Both implementations prove all required JWS claim and algorithm checks. | ✗ FAILED | Required invalid account/audience/type/algorithm corpus coverage is absent; expected fixture outcomes are not asserted. |
| 10 | Wrong signature/key/device/account/audience/type/algorithm and ordering inputs are actually rejected. | ✗ FAILED | Only signature/key/device/ordering cases are present and tested; declared expectations are not the verification oracle. |
| 11 | Missing Crosswake/device proof cannot waive the server/vector lane. | ✓ VERIFIED | Targeted Elixir and Swift suites run independently while report remains blocked. |
| 12 | Contract-test failure does not become a capability-report status. | ✓ VERIFIED | No vector/JWS reference occurs in capability report/reducer source; tests are separate. |
| 13 | Amendments preserve supersession history and no independent 72-hour policy. | ✓ VERIFIED | Ledger `V159-CLAIM-OFFLINE-001`, dated authority policy, and verifier passed. |
| 14 | Watchlist changes require dated owner reassessment. | ✓ VERIFIED | Complete owner/response tuple contract and authority checks passed. |
| 15 | Source inspection is processor-free and has closed ordered vocabulary. | ✓ VERIFIED | `Source`/`Registry` have fixed source/capability/state lists; matrix leakage verifier passed. |
| 16 | Apple management gives stable external guidance; unavailable control is typed. | ✓ VERIFIED | `Registry.declaration/2` returns externally-managed Apple guidance/URL and typed unavailable error. |
| 17 | Registry boundary cases and output order are deterministic. | ✓ VERIFIED | `validate/1`, fixed lists, and scoped source tests cover empty/duplicate/single-source behavior. |
| 18 | Apple results cannot dispatch Stripe billing mutation paths. | ✓ VERIFIED | Registry contains inspection outcomes only; leakage gate passed. |

**Score:** 14/18 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `v1.59-AUTHORITY.md`, amendments, watchlist verifier | Current governed research bundle | ✓ VERIFIED | Exists, substantive, linked from first index entry; shell verifier passes. |
| DecisionCases, generated JSON/Markdown | Data-only decision contract | ⚠️ HOLLOW | Files are substantive and exporter wiring is real, but public validator/tests do not uphold the claimed closed contract. |
| Source registry/outcome/fixture/matrix verifier | Rail-specific inspection boundary | ✓ VERIFIED | Exists, typed, wired to mirrors, and test/gate evidence passes. |
| Crosswake Swift package/report/research record | Honest prove-or-block boundary | ✓ VERIFIED | Package compiles with no Accrue Crosswake dependency; report is fail-closed. |
| Offline vectors and Elixir/Swift verifier tests | Merge-blocking JWS/cache proof | ✗ STUBBED PROOF | Artifacts run, but the fixture expectation oracle is disconnected and cache atomicity is only serially tested. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Research index | Authority manifest | First v1.59 entry | ✓ WIRED | Explicit first link at `RESEARCH-INDEX.md:7`. |
| Authority manifest | Amendment ledger | Precedence/ledger | ✓ WIRED | Explicit precedence link at `v1.59-AUTHORITY.md:13`. |
| DecisionCases export | Markdown/JSON/offline vectors | Canonical exporter | ✓ WIRED | `Markdown.Export.generated/0` uses `DecisionCases.all/0`; `offline_vectors/0` copies canonical fields. |
| Source registry | Outcome/error types | Typed inspection | ✓ WIRED | `Registry.outcome/2` constructs `Outcome` or `CapabilityError`. |
| Matrix verifier | Capability matrix/guides | Literal parity and leakage scan | ✓ WIRED | `bash scripts/ci/verify_entitlement_source_matrix.sh` passed. |
| Offline corpus | Elixir/Swift observations | Fixture outcome assertion | ✗ NOT WIRED | Both readers decode expected outcome fields but do not compare them to observed values. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Decision-table Markdown/JSON | `cases` | `DecisionCases.all/0` through `Export.generated/0` | Yes, deterministic canonical structs | ✓ FLOWING |
| Offline vectors | canonical case map | `DecisionCases.all/0` through `offline_vectors/0` | Yes for ID/version/disposition | ✓ FLOWING |
| Source fixture/matrix | fixed registry vocabulary/outcomes | `Source` and `Registry` | Yes, deterministic typed outcomes | ✓ FLOWING |
| JWS observations | expected verification/cache fields | corpus JSON | No: decoded expectations never control assertion | ✗ DISCONNECTED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Authority/watchlist drift gate | `bash scripts/ci/verify_v159_authority.sh` | `OK` | ✓ PASS |
| Source matrix/leakage gate | `bash scripts/ci/verify_entitlement_source_matrix.sh` | `OK` | ✓ PASS |
| Decision export and scoped ExUnit contracts | `cd accrue && mix accrue.entitlements.decision_cases --check && mix test ...` | 18 tests, 0 failures | ✓ PASS (insufficient to prove gaps) |
| Swift capability/vector/fault tests | `swift test --filter 'CapabilityReportTests|GoldenVectorTests'` | 5 tests, 0 failures | ✓ PASS (serial only) |

### Probe Execution

Step 7c: SKIPPED — no phase-declared or conventional `probe-*.sh` files were found.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| RSCH-01 | 215-02 | Current versioned research authority | ✓ SATISFIED | Authority/index/ledger/watchlist wiring and verifier pass. |
| RSCH-02 | 215-03, 215-05 | Canonical decision table drives consumers | ✗ BLOCKED | D-07 validation is open; JWS vector expectation contract is internally contradictory and unwired. |
| RSCH-03 | 215-02 | Dated change watchlist with owner/response | ✓ SATISFIED | Complete dated tuples and passing authority verifier. |
| RAIL-04 | 215-04 | Dedicated rail capability inspection matrix | ✓ SATISFIED | Typed registry, mirrors, guard tests, and leakage gate pass. |
| RAIL-05 | 215-01, 215-05 | Honest Crosswake prove-or-block tracer | ✗ BLOCKED | Correctly blocks coupling, but its asserted atomic proof-replacement boundary is unsafe under concurrent calls and not durably proven. |

No orphaned Phase 215 requirements: all five roadmap IDs appear in plan frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `decision_cases.ex` | 73-96 | Open validation presented as closed contract | 🛑 Blocker | Invalid decision cases can pass the advertised contract gate. |
| `offline_golden_vector_verifier.ex` / Swift verifier | observed-result path | Fixture expectations parsed but unused | 🛑 Blocker | A drifted or contradictory golden vector can pass. |
| `AccrueOfflineClient.swift` | 100-113 | Shared unsynchronized candidate pathname | 🛑 Blocker | Concurrent reconciliations can replace the wrong cache data. |
| `entitlement_decision_cases_property_test.exs` | 19-52 | Vacuous generated properties | ⚠️ Warning | Tests do not protect future consumer behavior. |

## Human Verification Required

The following backstop questions remain intentionally non-inferable and need maintainer confirmation after gaps are corrected:

### 1. Authority-bundle completeness

**Test:** Review whether the locked manifest, provenance, amendments, confidence, and dates contain all current v1.59 authority needed for a policy decision.
**Expected:** A maintainer accepts the bundle boundary or records a dated amendment.
**Why human:** Completeness of research authority cannot be inferred from file structure.

### 2. Downstream reducer equivalence

**Test:** When a production reducer exists, run it against the canonical case corpus and compare computed outcomes.
**Expected:** Each reducer outcome matches its canonical decision case or fails closed with a named difference.
**Why human:** Phase 215 deliberately contains no production projector/reducer.

### 3. Crosswake API boundary

**Test:** Obtain the authoritative pinned Crosswake repository/version/build and execute the redacted physical-device proof lane.
**Expected:** Each required bridge is proven with dated evidence, or coupling remains explicitly blocked.
**Why human:** No authoritative Crosswake source or physical-device evidence is checked in.

## Gaps Summary

This phase successfully makes the Crosswake coupling decision visible: runtime coupling is correctly **blocked** pending pinned bridge and device evidence. It also delivers substantive authority and source-capability documents.

However, the bundle is not yet sufficiently evidence-backed to claim the phase goal. The decision schema permits values it calls invalid; the golden-vector proof has a concrete declared-versus-observed cache contradiction and no expectation oracle; and the advertised atomic cache boundary breaks under concurrent replacement. These are blocking contract defects, not deferred Phase 219 behavior: Phase 219 owns production offline continuity, while Phase 215 explicitly claims its test/tracer boundary already proves atomic replacement.

_Verified: 2026-08-01T02:36:30Z_
_Verifier: the agent (gsd-verifier)_
