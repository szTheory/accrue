---
phase: 215
slug: research-contracts-and-crosswake-feasibility
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-31
---

# Phase 215 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with StreamData property tests; Swift Testing/XCTest for the tracer |
| **Config file** | `accrue/test/test_helper.exs`; tracer package configuration to be added in Wave 0 |
| **Quick run command** | `cd accrue && mix test test/accrue/entitlements` |
| **Full suite command** | `cd accrue && mix test --warnings-as-errors` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task's targeted ExUnit, shell drift, or Swift test command.
- **After every plan wave:** Run `cd accrue && mix test --warnings-as-errors` plus the authority/source verifier scripts created by the phase.
- **Before `$gsd-verify-work`:** The full suite and all contract drift gates must be green; the Crosswake capability report must mark every RAIL-05 bridge `proven` or the overall result `feasibility_blocked`.
- **Max feedback latency:** 120 seconds for the automated quick path; physical-device evidence is a separately recorded manual gate.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 215-01-01 | 01 | 0 | RSCH-01 | T-215-01 | Authority provenance and precedence cannot drift silently | unit + shell drift | `cd accrue && mix test test/accrue/docs` | ❌ W0 | ⬜ pending |
| 215-01-02 | 01 | 0 | RSCH-02 | T-215-02 | Duplicate, ordering, revocation, survivor, and stale cases are deterministic | unit + property | `cd accrue && mix test test/accrue/entitlements/decision_cases_test.exs` | ❌ W0 | ⬜ pending |
| 215-01-03 | 01 | 0 | RSCH-03 | Watchlist ownership and response policy remain explicit | shell/doc drift | `bash scripts/ci/verify_v159_authority.sh` | ❌ W0 | ⬜ pending |
| 215-02-01 | 02 | 1 | RAIL-04 | Source-qualified actions fail closed and never leak processor semantics | unit + negative contract | `cd accrue && mix test test/accrue/entitlements/source_test.exs` | ❌ W0 | ⬜ pending |
| 215-03-01 | 03 | 1 | RAIL-05 | Signed evidence is bound to the expected source, device key, and freshness policy | unit + Swift integration | `cd examples/crosswake_tracer && swift test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/docs/` — authority manifest, ledger, and watchlist contract tests for RSCH-01/03.
- [ ] `accrue/test/accrue/entitlements/decision_cases_test.exs` — exhaustive and property consumers for RSCH-02.
- [ ] `accrue/test/accrue/entitlements/source_test.exs` — closed source registry and processor-leakage negative tests for RAIL-04.
- [ ] `scripts/ci/verify_v159_authority.sh` — deterministic generated-artifact and provenance drift gate.
- [ ] `examples/crosswake_tracer/Package.swift` and test target — golden JWS/JSON bridge harness for RAIL-05.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Secure Enclave key creation, device-only Keychain state, foreground/background lifecycle, reconnect, and physical-device bridge behavior | RAIL-05 | Simulator and host-only tests cannot prove Secure Enclave/device lifecycle semantics; authoritative Crosswake source and a physical device are not yet available | Use the checked-in tracer runbook on an approved physical device, capture a redacted dated capability report, and mark each bridge `proven`; otherwise record the overall result as `feasibility_blocked` and do not begin mobile runtime coupling |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
