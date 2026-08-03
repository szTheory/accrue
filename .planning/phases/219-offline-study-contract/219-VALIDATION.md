---
phase: 219
slug: offline-study-contract
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-03
---

# Phase 219 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mox + StreamData |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/entitlements/offline_golden_vectors_test.exs` |
| **Full suite command** | `cd accrue && mix test.all` |
| **Estimated runtime** | Targeted tests under 30 seconds; full suite runtime measured during execution |

---

## Sampling Rate

- **After every task commit:** Run the task's targeted ExUnit command plus `cd accrue && mix test test/accrue/entitlements/offline_golden_vectors_test.exs`
- **After every plan wave:** Run `cd accrue && mix test.all`
- **Before `$gsd-verify-work`:** Full suite and fixture drift/export checks must be green
- **Max feedback latency:** 30 seconds for targeted checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 219-01-T1/T2 | 219-01 | 1 | OFF-01 | JWS algorithm/key confusion | Public-only compact ES256 proof and JWKS verification | unit + fixture | `cd accrue && mix test test/accrue/entitlements/offline_protocol_test.exs` | ✅ planned TDD | ⬜ pending |
| 219-02-T1 | 219-02 | 2 | OFF-02 | Clock rollback/overlong continuity | Fresh/stale/provider-expiry boundaries with no independent 72-hour cutoff | unit + property | `cd accrue && mix test test/accrue/entitlements/offline_test.exs` | ✅ planned TDD | ⬜ pending |
| 219-02-T2 | 219-02 | 2 | OFF-03 | Stale value expansion | Stale permits only downloaded lessons and local progress | unit | `cd accrue && mix test test/accrue/entitlements/offline_test.exs` | ✅ planned TDD | ⬜ pending |
| 219-02-T1/T2 | 219-02 | 2 | OFF-04 | State collapse/fail-open compatibility | Fresh, stale-offline, denied, and invalid remain distinguishable while boolean gates stay compatible | unit + regression | `cd accrue && mix test test/accrue/entitlements/offline_test.exs test/accrue/entitlements_test.exs` | ✅ planned TDD / ✅ existing | ⬜ pending |
| 219-03-T1 | 219-03 | 3 | OFF-05, OFF-06 | Constraint bypass/privacy | Apply the real test migration, then execute direct database-constraint, public-JWK, nonce, issuance-ordering, and privacy invariants | integration + direct constraint | `cd accrue && MIX_ENV=test mix ecto.migrate --quiet && mix test test/accrue/entitlements/offline_registration_test.exs` | ✅ planned TDD | ⬜ pending |
| 219-03-T2, 219-04-T1/T2 | 219-03, 219-04 | 3-4 | OFF-05 | Partial reconciliation/replay | PoP, due rails, final locks, issuance, and atomic replacement ordering | integration + fault injection | `cd accrue && mix test test/accrue/entitlements/offline_registration_test.exs test/accrue/entitlements/offline_reconnect_test.exs` | ✅ planned TDD | ⬜ pending |
| 219-04-T1, 219-05-T1 | 219-04, 219-05 | 4-5 | OFF-06 | Early verification-key retirement | Derive each old key's eligibility from actual issued proof expiry plus the 86,400-second buffer; reject early removal and retain keys indefinitely for unbounded proofs | integration + fixture boundary | `cd accrue && mix test test/accrue/entitlements/offline_reconnect_test.exs --only issuance && mix test test/accrue/entitlements/offline_golden_vectors_test.exs` | ✅ planned TDD | ⬜ pending |
| 219-01-T1, 219-05-T1/T2 | 219-01, 219-05 | 1,5 | OFF-06 | Binding, rollback, revocation, rotation | Negative Elixir/Swift corpus fails safely without private material leakage | unit + property + process crash | `cd accrue && mix test test/accrue/entitlements/offline_protocol_test.exs test/accrue/entitlements/offline_golden_vectors_test.exs && cd ../examples/crosswake_tracer && swift test` | ✅ planned TDD / ✅ seed | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/entitlements/offline_protocol_test.exs` — created first by 219-01-T1/T2 for public profile, JWKS, binding, rotation, and OFF-01/OFF-06 negatives.
- [x] `accrue/test/accrue/entitlements/offline_test.exs` — created first by 219-02-T1/T2 for OFF-02/OFF-03/OFF-04 state/action, time boundaries, and gate compatibility.
- [x] `accrue/test/accrue/entitlements/offline_registration_test.exs` and `offline_reconnect_test.exs` — created first by 219-03/04 TDD tasks; 219-03-T1 applies the test migration and runs the focused persistence suite before registration behavior, and later tasks cover PoP, due/pending, terminal issuance, and D-11 key retirement.
- [x] Ordering, denial precedence, clock rollback, privacy, and replacement-crash properties are authored test-first across 219-02 and 219-05.

---

## Manual-Only Verifications

All phase behaviors are expected to have automated verification. Any platform-specific fixture-consumer check that cannot run locally must be recorded by the planner with its exact external command and evidence requirement.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or create their Wave 0 dependency before production code.
- [x] Sampling continuity: every task has focused automated verification.
- [x] Wave 0 covers all MISSING references through the mapped TDD tasks.
- [x] No watch-mode flags.
- [x] Targeted commands are scoped to the under-30-second feedback goal; runtime is recorded during execution.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** executable evidence only; no manual-only phase acceptance is planned
