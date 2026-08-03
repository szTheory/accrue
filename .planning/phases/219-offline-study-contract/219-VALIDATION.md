---
phase: 219
slug: offline-study-contract
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 219-TBD | TBD | TBD | OFF-01 | JWS algorithm/key confusion | Public-only compact ES256 proof and JWKS verification | unit + fixture | `cd accrue && mix test test/accrue/entitlements/offline_protocol_test.exs` | ❌ W0 | ⬜ pending |
| 219-TBD | TBD | TBD | OFF-02 | Clock rollback/overlong continuity | Fresh/stale/provider-expiry boundaries with no independent 72-hour cutoff | unit + property | `cd accrue && mix test test/accrue/entitlements/offline_test.exs` | ❌ W0 | ⬜ pending |
| 219-TBD | TBD | TBD | OFF-03 | Stale value expansion | Stale permits only downloaded lessons and local progress | unit | `cd accrue && mix test test/accrue/entitlements/offline_test.exs` | ❌ W0 | ⬜ pending |
| 219-TBD | TBD | TBD | OFF-04 | State collapse/fail-open compatibility | Fresh, stale-offline, denied, and invalid remain distinguishable while boolean gates stay compatible | unit + regression | `cd accrue && mix test test/accrue/entitlements/offline_test.exs test/accrue/entitlements_test.exs` | ❌ W0 / ✅ | ⬜ pending |
| 219-TBD | TBD | TBD | OFF-05 | Partial reconciliation/replay | Due rails settle before final lock and atomic proof replacement | integration + fault injection | `cd accrue && mix test test/accrue/entitlements/offline_reconnect_test.exs` | ❌ W0 | ⬜ pending |
| 219-TBD | TBD | TBD | OFF-06 | Binding, rollback, revocation, rotation | Negative corpus fails safely without private material leakage | unit + property | `cd accrue && mix test test/accrue/entitlements/offline_protocol_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/entitlements/offline_protocol_test.exs` — public profile, JWKS, binding, rotation, and negative vectors for OFF-01/OFF-06
- [ ] `accrue/test/accrue/entitlements/offline_test.exs` — state/action policy, time boundaries, and boolean compatibility for OFF-02/OFF-03/OFF-04
- [ ] `accrue/test/accrue/entitlements/offline_reconnect_test.exs` — transaction locking, due/pending/final issuance, and crash replacement for OFF-05
- [ ] Property cases for ordering, deny precedence, clock rollback, and no-private-material regression

---

## Manual-Only Verifications

All phase behaviors are expected to have automated verification. Any platform-specific fixture-consumer check that cannot run locally must be recorded by the planner with its exact external command and evidence requirement.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for targeted checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
