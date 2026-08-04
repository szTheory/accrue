---
phase: 220
slug: first-adopter-proof-and-release-gates
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| PROOF-01 | Same-account Apple→web and Stripe→iOS projections converge without reconciliation; no client reducer becomes authoritative. | Repo + host integration | Focused `mix test` plus `cd examples/accrue_host && mix verify` | ❌ Wave 0 | ⬜ pending |
| PROOF-02 | Closed scenario lanes and public-only fixtures cover duplicate prevention, offline continuity, reconnect, revocation, device replacement, deny tombstones, clock rollback, and key rotation. | Unit, integration, Swift vector | Focused Elixir tests plus `cd examples/crosswake_tracer && swift test` | ❌ Wave 0 | ⬜ pending |
| PROOF-03 | Diagnostic projection exposes only closed redacted values; host mutation controls are authorized, understandable, and keyboard-safe. | Unit + ConnTest/LiveView | Focused Admin and host tests | ❌ Wave 0 | ⬜ pending |
| PROOF-04 | Repairs are lock-safe, idempotent, audited, bounded, and converge without hidden finance/provider mutation. | Transactional integration + property | Focused repair-drill tests | ❌ Wave 0 | ⬜ pending |
| PROOF-05 | Versioned facts generate exact capability limits, and gates reject contrary public claims or runtime-feasibility inflation. | Shell + docs tests | `bash scripts/ci/verify_*` and focused docs tests | ❌ Wave 0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `accrue/priv/entitlements/v1.59-reference-scenarios.json` and a strict parser/checker — stable schema, IDs, closed lanes, and redaction contract.
- [ ] Elixir consumer tests that invoke production contexts rather than interpreting fixture semantics.
- [ ] Host and Swift scenario consumers keyed by the same IDs.
- [ ] Bounded diagnostic-projection allowlist/forbidden-field tests and repair-drill transaction tests.
- [ ] Fixture-to-public-matrix generator/check plus a CI script rejecting contradictory claims.

---

## Manual-Only Verifications

| Behavior | Requirement | Why manual | Test instructions |
|----------|-------------|------------|-------------------|
| Physical-device and required bridge evidence for Crosswake runtime feasibility | PROOF-01, PROOF-02, PROOF-05 | The tracer currently reports `feasibility_blocked`; vectors, simulators, and browser checks cannot promote that claim. | Verify the capability report remains blocked unless the required bridge and physical-device evidence are attached; confirm public material retains the same lane/status. |

---

## Validation Sign-Off

- [ ] All planned tasks have an automated verify command or Wave 0 dependency.
- [ ] Sampling continuity: no three consecutive tasks lack automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags are used.
- [ ] `nyquist_compliant: true` is set only after execution validates this strategy.

**Approval:** pending
