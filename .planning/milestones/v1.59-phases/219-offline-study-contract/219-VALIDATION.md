---
phase: 219
slug: offline-study-contract
status: validated
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
| 219-01-T1/T2 | 219-01 | 1 | OFF-01 | JWS algorithm/key confusion | Public-only compact ES256 proof and JWKS verification | unit + fixture | `cd accrue && mix test test/accrue/entitlements/offline_protocol_test.exs` | ✅ | ✅ green |
| 219-02-T1 | 219-02 | 2 | OFF-02 | Clock rollback/overlong continuity | Fresh/stale/provider-expiry boundaries with no independent 72-hour cutoff | unit + property | `cd accrue && mix test test/accrue/entitlements/offline_test.exs` | ✅ | ✅ green |
| 219-02-T2 | 219-02 | 2 | OFF-03 | Stale value expansion | Stale permits only downloaded lessons and local progress | unit | `cd accrue && mix test test/accrue/entitlements/offline_test.exs` | ✅ | ✅ green |
| 219-02-T1/T2 | 219-02 | 2 | OFF-04 | State collapse/fail-open compatibility | Fresh, stale-offline, denied, and invalid remain distinguishable while boolean gates stay compatible | unit + regression | `cd accrue && mix test test/accrue/entitlements/offline_test.exs test/accrue/entitlements_test.exs` | ✅ | ✅ green |
| 219-03-T1 | 219-03 | 3 | OFF-05, OFF-06 | Constraint bypass/privacy | Apply the real test migration, then execute direct database-constraint, public-JWK, nonce, issuance-ordering, and privacy invariants | integration + direct constraint | `cd accrue && MIX_ENV=test mix ecto.migrate --quiet && mix test test/accrue/entitlements/offline_registration_test.exs` | ✅ | ✅ green |
| 219-03-T2, 219-04-T1/T2 | 219-03, 219-04 | 3-4 | OFF-05 | Partial reconciliation/replay | PoP, durable no-replay work, final locks, issuance, and atomic replacement ordering | integration + fault injection | `cd accrue && mix test test/accrue/entitlements/offline_registration_test.exs test/accrue/entitlements/offline_reconnect_test.exs` | ✅ | ✅ green |
| 219-04-T1, 219-05-T1 | 219-04, 219-05 | 4-5 | OFF-06 | Early verification-key retirement | Reject early removal and retain keys indefinitely for unbounded proofs | integration + fixture boundary | `cd accrue && mix test test/accrue/entitlements/offline_reconnect_test.exs --only issuance` | ✅ | ✅ green |
| 219-01-T1, 219-05-T1/T2 | 219-01, 219-05 | 1,5 | OFF-06 | Binding, rollback, revocation, rotation | Negative Elixir/Swift corpus fails safely; Phase 220's deterministic `key_rotation` scenario proves issued-key retention through expiry plus buffer and public-key retirement in both consumers | unit + property + process crash + integration | `cd accrue && mix test test/accrue/entitlements/offline_protocol_test.exs test/accrue/entitlements/offline_golden_vectors_test.exs test/accrue/entitlements/reference_scenario_device_keys_test.exs && cd ../examples/crosswake_tracer && swift test --filter ReferenceScenarioTests` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/entitlements/offline_protocol_test.exs` — created first by 219-01-T1/T2 for public profile, JWKS, binding, rotation, and OFF-01/OFF-06 negatives.
- [x] `accrue/test/accrue/entitlements/offline_test.exs` — created first by 219-02-T1/T2 for OFF-02/OFF-03/OFF-04 state/action, time boundaries, and gate compatibility.
- [x] `accrue/test/accrue/entitlements/offline_registration_test.exs` and `offline_reconnect_test.exs` — created first by 219-03/04 TDD tasks; 219-03-T1 applies the test migration and runs the focused persistence suite before registration behavior, and later tasks cover PoP, due/pending, terminal issuance, and D-11 key retirement.
- [x] Ordering, denial precedence, clock rollback, privacy, and replacement-crash properties are authored test-first across 219-02 and 219-05.

---

## Manual-Only Verifications

None. Phase 220 closed the prior OFF-06 corpus-level retirement gap with a deterministic `key_rotation` scenario, its real-repository ExUnit consumer, and the Swift scenario-schema consumer. Phase 219's finite and unbounded implementation-level retention boundaries remain independently automated in `offline_reconnect_test.exs`.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or create their Wave 0 dependency before production code.
- [x] Sampling continuity: every task has focused automated verification.
- [x] Wave 0 covers all MISSING references through the mapped TDD tasks.
- [x] No watch-mode flags.
- [x] Targeted commands are scoped to the under-30-second feedback goal; runtime is recorded during execution.
- [x] `nyquist_compliant: true` — Phase 220 supplies deterministic corpus-contract support for issued-proof key rotation/retirement and both language consumers accept the shared scenario schema.

**Approval:** executable evidence only; no manual-only phase acceptance is planned

## Validation Audit 2026-08-04

| Metric | Count |
|--------|-------|
| Gaps found | 2 |
| Resolved | 1 |
| Escalated to Phase 220 | 1 |

- Added an unbounded key-retention regression proving an old key cannot be omitted even ten years later (`1a0930e5`).
- Fresh focused evidence: 45 Elixir tests, 1 property, 0 failures; 27 Swift tests, 0 failures.

## Validation Audit 2026-08-05

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 0 |
| Escalated | 1 |

- Re-audited the deferred OFF-06 corpus rotation/retirement coverage. The existing public corpus and both language consumers cannot represent issued-proof history or retention eligibility without production-facing corpus-contract changes; no implementation changes were made during this validation pass.
- Confirmed focused implementation-level issuance-retention coverage remains green: `cd accrue && mix test test/accrue/entitlements/offline_reconnect_test.exs --only issuance` (3 tests, 0 failures).

## Validation Audit 2026-08-05 (Nyquist closure)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 1 |
| Escalated | 0 |

- Reclassified the prior OFF-06 corpus-retirement gap as covered: Phase 220's shared `key_rotation` scenario creates a finite issued proof, retains the old public `kid` through its required horizon, then permits retirement; `reference_scenario_device_keys_test.exs` passed (4 tests, 0 failures).
- Confirmed the Crosswake Swift consumer recognizes `key_rotation` as a deterministic-conformance scenario: `swift test --filter ReferenceScenarioTests` passed (1 test, 0 failures).
- Re-ran the Phase 219 focused Elixir suites: 44 tests and 1 property, 0 failures.
