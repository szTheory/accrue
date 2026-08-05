---
phase: 220
slug: first-adopter-proof-and-release-gates
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-04
---

# Phase 220 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Ecto, SwiftPM XCTest, and existing Phoenix-host browser checks |
| **Config file** | `accrue/test/test_helper.exs`; `examples/accrue_host/test/test_helper.exs`; `examples/crosswake_tracer/Package.swift` |
| **Quick run command** | `cd accrue && mix test test/accrue/entitlements/<phase220-files> --seed 458442` |
| **Full suite command** | `cd accrue && mix test.all && cd ../examples/accrue_host && mix verify.full && cd ../crosswake_tracer && swift test` |
| **Estimated runtime** | Established suite; run focused tests per task and the full suite per wave |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit, Swift, or shell gate relevant to the changed consumer.
- **After every plan wave:** Run `cd accrue && mix test.all`, plus the relevant host or Swift command.
- **Before `$gsd-verify-work`:** Run the full Elixir, host, Swift, and newly wired documentation/release gate suites.
- **Max feedback latency:** Keep feedback within a single focused test or gate run.

---

## Per-Task Verification Map

| Requirement | Secure behavior | Test type | Automated command | File exists | Status |
|-------------|-----------------|-----------|-------------------|-------------|--------|
| PROOF-01 | Same-account Apple→web and Stripe→iOS projections converge without reconciliation; no client reducer becomes authoritative. | Repo + host integration | `bash scripts/ci/verify_release_contract.sh` | ✅ `reference_scenario_conformance_test.exs`, host conformance | ✅ covered |
| PROOF-02 | Closed scenario lanes and public-only fixtures cover duplicate prevention, offline continuity, reconnect, revocation, device replacement, deny tombstones, clock rollback, and key rotation. | Unit, integration, Swift vector | `bash scripts/ci/verify_release_contract.sh` | ✅ reference-scenario family suites and Swift consumer tests | ✅ covered |
| PROOF-03 | Diagnostic projection exposes only closed redacted values; host mutation controls are authorized, understandable, and keyboard-safe. | Unit + ConnTest/LiveView | `bash scripts/ci/verify_release_contract.sh` | ✅ `admin_test.exs` and diagnostic LiveView/browser tests | ✅ covered |
| PROOF-04 | Repairs are lock-safe, idempotent, audited, bounded, and converge without hidden finance/provider mutation. | Transactional integration + property | `bash scripts/ci/verify_release_contract.sh` | ✅ `repair_drills_test.exs` | ✅ covered |
| PROOF-05 | Versioned facts generate exact capability limits, and gates reject contrary public claims or runtime-feasibility inflation. | Shell + docs tests | `bash scripts/ci/verify_release_contract.sh` | ✅ reference-contract, adoption-matrix, release-contract, and docs tests | ✅ covered |

---

## Wave 0 Requirements

- [x] Strict scenario schema/parser with stable IDs, closed lanes, and redaction contract.
- [x] Elixir consumers invoke production contexts; the exact-oracle mutation proof covers all 224 declared transition leaves.
- [x] Host and Swift scenario consumers are keyed by the same IDs.
- [x] Diagnostic allowlist/forbidden-field and transactional repair-drill coverage exists.
- [x] Fixture-to-public-matrix generator/check and contradictory-claim CI gates exist.

---

## Manual-Only Verifications

| Behavior | Requirement | Why manual | Test instructions |
|----------|-------------|------------|-------------------|
| Physical-device and required bridge evidence for Crosswake runtime feasibility | PROOF-01, PROOF-02, PROOF-05 | The tracer correctly reports `feasibility_blocked`; vectors, simulators, and browser checks cannot establish mobile runtime feasibility. | Verify the capability report remains blocked unless the required bridge and physical-device evidence are attached; confirm public material retains the same lane/status. |
| Whole-contract review of public v1.59 material | PROOF-05 | Structural gates enforce the generated contract and known prohibitions, but cannot assess every prose implication. | Review the matrix, release guide, runbooks, App Review guidance, release notes, and adopter copy together for privacy, lifecycle, finance, and offline-expansion overclaims. |

---

## Validation Sign-Off

- [x] All planned tasks have automated verification or are covered by the coordinated release gate.
- [x] Sampling continuity: no three consecutive tasks lack automated verification.
- [x] Wave 0 requirements are implemented and covered.
- [x] No watch-mode flags are used.
- [x] `nyquist_compliant: true` was set after the coordinated release gate passed on 2026-08-05.

**Approval:** validated — automated coverage is complete; two judgment/runtime backstops remain manual-only.

## Validation Audit 2026-08-05

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 2 |

The existing strategy was audited against all 23 PLAN/SUMMARY pairs and the phase verification report. The coordinated `bash scripts/ci/verify_release_contract.sh` gate passed on 2026-08-05. It exercises the fixture/matrix, adoption, release-contract, and linked-release checks; requirement-specific tests named above provide the corresponding behavioral evidence.
