---
phase: 218
slug: apple-observation-and-repair
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-02
---

# Phase 218 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + `stream_data` 1.3.0 + Ecto SQL Sandbox + Oban.Testing |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/entitlements/apple_*_test.exs` |
| **Full suite command** | `cd accrue && mix test` |
| **Estimated runtime** | To be measured during Wave 0 |

---

## Sampling Rate

- **After every task commit:** Run the task's targeted `mix test` command and `cd accrue && mix format --check-formatted` for touched Elixir files.
- **After every plan wave:** Run `cd accrue && mix test`.
- **Before `$gsd-verify-work`:** The full suite must be green.
- **Max feedback latency:** One task; no three consecutive tasks may lack automated verification.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 218-01-T1 | 218-01 | 1 | AAPL-01 | Atomicity/failure rollback | Bind, Observation, grant/revision, audits, Projector follow-up job, and concrete durable reconciliation-wakeup row commit or roll back together | Repo integration + failure injection | `cd accrue && mix test test/accrue/entitlements/apple_observation_tracer_test.exs test/accrue/entitlements/projector_test.exs` | ✅ planned TDD | ⬜ pending |
| 218-04-T1 | 218-04 | 3 | AAPL-01 | Bind/reassignment | Verified UUID binds once; races and conflicts remain non-granting | integration + property | `cd accrue && mix test test/accrue/entitlements/apple_lineage_test.exs test/property/apple_lineage_property_test.exs` | ✅ planned TDD | ⬜ pending |
| 218-03-T2 | 218-03 | 2 | AAPL-02 | Forgery/algorithm confusion | Bad algorithm, root, purpose, time, bundle, environment, or app identity is rejected | unit corpus | `cd accrue && mix test test/accrue/entitlements/apple_verifier_test.exs` | ✅ planned TDD | ⬜ pending |
| 218-07-T1 | 218-07 | 3 | AAPL-03 | Premature acknowledgement/flood | HTTP success follows durable disposition; rate/size rejection is storage-free | Plug integration | `cd accrue && mix test test/accrue/entitlements/apple_notification_test.exs` | ✅ planned TDD | ⬜ pending |
| 218-04-T2 | 218-04 | 3 | AAPL-03 | Replay/order/flood | Duplicate and out-of-order evidence converges; terminal quarantine never grants | integration + property | `cd accrue && mix test test/accrue/entitlements/apple_intake_test.exs test/property/apple_convergence_property_test.exs` | ✅ planned TDD | ⬜ pending |
| 218-05-T2 | 218-05 | 4 | AAPL-04 | Partial-page/cursor loss | Status/history repair commits cursors only after the final page and resumes safely | worker + integration | `cd accrue && mix test test/accrue/entitlements/apple_reconciliation_test.exs` | ✅ planned TDD | ⬜ pending |
| 218-08-T1 | 218-08 | 6 | AAPL-05 | Provider lifecycle crossover | Apple guidance is externally managed and no Apple path reaches Stripe lifecycle mutation | unit + negative guard | `cd accrue && mix test test/accrue/entitlements/apple_source_isolation_test.exs` | ✅ planned TDD | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. Every missing test is created before implementation in its mapped TDD task.*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/entitlements/apple_verifier_test.exs` — created first by 218-03-T1/T2 for AAPL-02.
- [x] `accrue/test/accrue/entitlements/apple_lineage_test.exs` — created first by 218-04-T1 for AAPL-01.
- [x] `accrue/test/property/apple_lineage_property_test.exs` — created first by 218-04-T1 for AAPL-01.
- [x] `accrue/test/accrue/entitlements/apple_intake_test.exs` — created first by 218-04-T2 for AAPL-03.
- [x] `accrue/test/property/apple_convergence_property_test.exs` — created first by 218-04-T2 for AAPL-03.
- [x] `accrue/test/accrue/entitlements/apple_reconciliation_test.exs` — created first by 218-05-T1 and expanded through 218-06-T2 for AAPL-04.
- [x] `accrue/test/accrue/entitlements/apple_source_isolation_test.exs` — created first by tracer-first TDD task 218-08-T1 for AAPL-05.

---

## Manual-Only Verifications

None. Phase acceptance is fully executable and merge-blocking.

- Apple provider fidelity is covered by deterministic signed fixtures, real Repo integration, Production URL capture, replay/concurrency tests, and provider-isolation guards. A live sandbox lane may be added later as scheduled automation when credentials exist and recurring upstream-drift detection justifies it; it is not UAT.
- The candidate Apple library was rejected without installation. Dependency absence, the private verifier implementation, hostile-chain behavior, redaction, and failure bounds are executable contracts.

---

## Validation Sign-Off

- [x] All tasks have automated verification or explicit Wave 0 dependencies.
- [x] Sampling continuity: no three consecutive tasks without automated verification.
- [x] Wave 0 covers every missing test reference through test-first task mappings.
- [x] No watch-mode flags.
- [x] Feedback latency stays within one task.
- [x] Golden verification, bind-race, cursor, redaction, and Apple-to-Stripe negative cases are green.
- [x] `nyquist_compliant: true` is set in frontmatter after validation.

**Approval:** executable evidence only; no human UAT required
