---
phase: 220-first-adopter-proof-and-release-gates
verified: 2026-08-05T14:40:00Z
status: human_needed
score: 5/5 must-haves verified
behavior_unverified: 2
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "The deterministic 27-action aggregate now compares every declared result, durable, and cache leaf with an independently collected production transition."
    - "The refund/retraction fixture is aligned with the production cache-replacement outcome, and unchanged-observation mutations prove every declared scalar leaf is load-bearing."
  gaps_remaining: []
  regressions: []
behavior_unverified_items:
  - truth: "Crosswake mobile runtime feasibility remains accurately represented by the public contract."
    test: "Review the capability report against actual bridge-compile and physical-device evidence."
    expected: "The public status remains feasibility_blocked unless both required evidence kinds support promotion."
    why_human: "The checked-in report and Swift tests prove the blocked state and fail closed, but cannot establish mobile runtime feasibility."
  - truth: "Public material stays within the additive v1.59 privacy, lifecycle, finance, and offline-expansion limits."
    test: "Review the generated matrix, release guide, runbooks, App Review material, and adopter-facing copy as one public contract."
    expected: "No material claims more than its evidence lane or the documented provider-control, privacy, lifecycle, and offline limits."
    why_human: "This retained prohibition is a judgment-tier review; structural release-contract checks cannot certify every prose implication."
human_verification:
  - test: "Review Crosswake capability evidence."
    expected: "Capability remains feasibility_blocked until bridge and physical-device evidence are both present."
    why_human: "Runtime feasibility is a backstop judgment outside the server/fixture test boundary."
  - test: "Review public v1.59 boundary material as a whole."
    expected: "All claims remain within the documented additive and privacy-bounded contract."
    why_human: "Meaning and scope of public claims require human judgment."
---

# Phase 220: First-adopter proof and release gates — Verification Report

**Phase Goal:** The anonymized B2C Alpha reference host and public release contract prove that multi-rail access and offline study are safe, diagnosable, and operable.

**Verified:** 2026-08-05T14:40:00Z  
**Status:** human_needed  
**Re-verification:** Yes — after Plans 220-21 and 220-22 closed the prior fixture-oracle gap.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Apple-to-web and Stripe-to-iOS access converge for one account without manual reconciliation. | ✓ VERIFIED | Host conformance tests exercise `apple_purchase_to_web_login` and `stripe_purchase_to_ios_login` through the configured Repo; both passed in the root gate. |
| 2 | Credential-free deterministic checks prove duplicate-purchase prevention, stale study continuity, restricted expansion, reconnect, revocation, survivor grants, device replacement, deny tombstones, clock rollback, and key rotation. | ✓ VERIFIED | The 27-action corpus has 224 scalar result/durable/cache leaves. Aggregate conformance executes each action once, requires exact production-derived transition equality, then mutates every leaf and requires `assert_transition/2` to fail; the 51-test credential-free suite passed. |
| 3 | An operator can inspect a privacy-bounded account diagnostic. | ✓ VERIFIED | `Admin.diagnostic_for_account/2` returns a closed projection excluding raw observations, ownership, device identifiers, proofs, queue data, and provider responses; the authorized LiveView calls it and the coordinated gate passed. |
| 4 | Bounded repair actions and runbooks cover required operational incidents without routine reconstruction. | ✓ VERIFIED | `repair_drills_test.exs`, including duplicate-charge escalation, outage, backlog, device replacement, and signing-key rotation, is part of the passing coordinated command; adoption and release-contract gates also passed. |
| 5 | Public materials and conformance gates describe the additive v1.59 contract and limits. | ✓ VERIFIED | The root gate validates generated matrix drift, public contract/adoption scripts, host and Swift consumers, and CI wiring; it completed successfully. |

**Score:** 5/5 truths verified (2 additional judgment/runtime backstops are present but require human review).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/priv/entitlements/v1.59-reference-scenarios.json` | Closed deterministic contract | ✓ VERIFIED | 27 deterministic actions and their bounded expected transition leaves are loaded by the strict scenario checker. |
| `accrue/test/support/entitlements/reference_scenario_executor.ex` | Production-backed seven-family dispatcher and exact assertion boundary | ✓ VERIFIED | Maps every action kind to a named family; `declared_transition_matches?/2` compares result, durable, and cache only after a family collects the production projection. |
| `accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs` | Aggregate exact-oracle and mutation proof | ✓ VERIFIED | Test asserts declared/observed leaf-path inventory equality and requires an assertion failure for each unequal mutation. |
| `accrue/lib/accrue/entitlements/admin.ex` | Closed privacy-bounded diagnostic projection | ✓ VERIFIED | Builds bounded snapshot/provider/eligibility/device/recovery/next-action maps from the Repo, with documented exclusions. |
| `scripts/ci/verify_reference_scenario_contract.sh` | Credential-free coordinated release gate | ✓ VERIFIED | Invokes core scenario/repair tests, host conformance, Swift tests, adoption proof, and release contract; it passed from repository root. |
| `220-ALPHA-CROSSWAKE-READINESS-BOUNDARY.md` | Three-owner readiness explanation and seam checklist | ✓ VERIFIED | Separates Accrue contract proof, Crosswake runtime proof, and Alpha-owned production integration evidence; Alpha remains external and unevaluated. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Aggregate conformance | `ReferenceScenarioExecutor.execute_action/3` | Ordered action execution | ✓ WIRED | Every deterministic action is executed before its transition assertion. |
| Bounded collector | fixture `expected_transition` | `assert_transition/2` | ✓ WIRED | All family branches combine family semantics with exact `result`, `durable`, and `cache` equality; no collector module reads expectation data. |
| Mutation harness | exact assertion boundary | Mutate one expected scalar against unchanged observation | ✓ WIRED | The aggregate enumerates each scalar path, calls `assert_transition/2`, and expects `ExUnit.AssertionError` containing scenario/order/kind/path. |
| CI workflow | root release verifier | `docs-contracts-shift-left` job | ✓ WIRED | `.github/workflows/ci.yml` invokes `bash scripts/ci/verify_reference_scenario_contract.sh`. |
| Host diagnostic | core diagnostic | authorized LiveView lookup | ✓ WIRED | `EntitlementDiagnosticsLive` calls `Admin.diagnostic_for_account(account, repo: repo)`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Scenario family executors | `observed.declared_transition` | Real production contexts plus fresh Repo reads | Yes | ✓ FLOWING |
| Aggregate oracle | expected versus observed leaf comparison | Decoded fixture used only after execution | Yes; all 224 declared leaves are mutation-tested | ✓ FLOWING |
| Diagnostic LiveView | `diagnostic` | Authorized account lookup → `Admin.diagnostic_for_account/2` | Yes; closed projection is rendered | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Complete credential-free Phase 220 gate | `bash scripts/ci/verify_reference_scenario_contract.sh` | Exit 0: 51 Elixir tests, 2 host conformance tests, 28 Swift tests, generated/adoption/release-contract checks all passed. | ✓ PASS |
| Exact fixture-oracle enforcement | Included `every declared transition leaf rejects a mutation against its unchanged production observation` test | The command passed after enumerating every action's expected scalar leaves and requiring each mutation to fail. | ✓ PASS |
| Crosswake evidence boundary | Included Swift capability-report tests | Checked-in report remains `feasibility_blocked`; missing bridge/device evidence fails closed. | ✓ PASS (blocked-state contract) |
| Alpha/Crosswake readiness explanation | `220-ALPHA-CROSSWAKE-READINESS-BOUNDARY.md` | Maps the three proof owners and their non-implications without claiming external Alpha evidence. | ✓ PASS (documentation boundary) |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PROOF-01 | 01, 05–07, 20, 22 | Apple/Stripe multi-rail convergence | ✓ SATISFIED | Both named host scenarios passed in the root gate. |
| PROOF-02 | 01, 07–22 | Credential-free deterministic lifecycle/offline proof | ✓ SATISFIED | 27-action exact collector-to-oracle proof plus exhaustive leaf-mutation test passed. |
| PROOF-03 | 02, 05–06, 20, 22 | Privacy-bounded operator diagnostic | ✓ SATISFIED | Core diagnostic/host tests are included in the coordinated gate; closed projection is wired to the host. |
| PROOF-04 | 03, 05–06, 20, 22 | Bounded repair and operational runbooks | ✓ SATISFIED | Passing repair drills and public adoption/release-contract gates cover the planned incidents. |
| PROOF-05 | 04–06, 20, 22 | Additive public contract and release gates | ✓ SATISFIED | Generator, public contract, adoption matrix, release contract, and CI entrypoint all passed. |

All five Phase-220 requirements are claimed by plans; none is orphaned. Phase 220 is the final milestone phase, so no items were deferred.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `accrue/lib/accrue/entitlements/reference_scenarios.ex` | 9–10, 60 | Compiler reports three unused module attributes during the gate. | ⚠️ Warning | Does not weaken the executed contract, but should be cleaned up to keep release-gate output free of avoidable warnings. |
| `accrue/test/support/entitlements/reference_scenario_executor.ex` | 184 | Compiler warns about parentheses after `||`. | ⚠️ Warning | The evaluated expression passed its exact-oracle mutation tests; parenthesizing would remove ambiguity. |

No `TBD`, `FIXME`, or `XXX` markers, placeholder returns, empty implementation paths, or expectation-reading collector modules were found in the Phase-220 execution artifacts.

## Human Verification Required

### 1. Alpha/Crosswake runtime boundary

**Test:** Read the [Alpha/Crosswake readiness boundary](220-ALPHA-CROSSWAKE-READINESS-BOUNDARY.md), then compare the capability report to actual bridge-compile and physical-device evidence.

**Expected:** The three owners remain distinct: Accrue contract proof is reusable conformance evidence, Crosswake runtime proof remains `feasibility_blocked` until both evidence kinds exist, and Alpha-owned production integration evidence remains external and unevaluated here. No public material promotes runtime or Alpha integration based on fixture or server evidence.

**Why human:** Automated tests verify the fail-closed blocked state and documentation structure, not real mobile runtime feasibility or Alpha's separately owned integration/release evidence.

### 2. Public v1.59 boundary review

**Test:** Read the generated capability matrix, release guide, runbooks, App Review guidance, release notes, and adopter material together.

**Expected:** Their claims stay within the additive contract: no raw transaction/proof/token/PII exposure, no unsupported cross-rail lifecycle mutation, and no expansion while stale/offline.

**Why human:** The release checks enforce stated strings and structure, but the meaning of all public claims is a judgment-tier prohibition.

## Gaps Summary

The previous fixture-oracle blocker is closed: production-derived transitions are now compared exactly, and a mutation proof prevents declared leaves from becoming decorative. G-220-1 is also resolved only as an explanation/ownership gap through the [Alpha/Crosswake readiness boundary](220-ALPHA-CROSSWAKE-READINESS-BOUNDARY.md); it does not claim Crosswake runtime or Alpha integration evidence. No code or wiring gap remains. The phase awaits only the two explicitly retained human backstop reviews above.

---

_Verified: 2026-08-05T14:40:00Z_  
_Verifier: the agent (gsd-verifier)_
