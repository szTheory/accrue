---
phase: 218
slug: apple-observation-and-repair
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| TBD | TBD | 0 | AAPL-01 | Bind/reassignment | Verified UUID binds once; races and conflicts remain non-granting | integration + property | `cd accrue && mix test test/accrue/entitlements/apple_lineage_test.exs test/property/apple_lineage_property_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | 0 | AAPL-02 | Forgery/algorithm confusion | Bad algorithm, root, purpose, time, bundle, environment, or app identity is rejected | unit corpus | `cd accrue && mix test test/accrue/entitlements/apple_verifier_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | 0 | AAPL-03 | Replay/order/flood | Duplicate and out-of-order evidence converges; terminal quarantine never grants | integration + property | `cd accrue && mix test test/accrue/entitlements/apple_intake_test.exs test/property/apple_convergence_property_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | 0 | AAPL-04 | Partial-page/cursor loss | Status/history repair commits cursors only after the final page and resumes safely | worker + integration | `cd accrue && mix test test/accrue/entitlements/apple_reconciliation_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | 0 | AAPL-05 | Provider lifecycle crossover | Apple guidance is externally managed and no Apple path reaches Stripe lifecycle mutation | unit + negative guard | `cd accrue && mix test test/accrue/entitlements/apple_source_isolation_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. Planner replaces TBD task/plan/wave values with final IDs.*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/entitlements/apple_verifier_test.exs` — golden and hostile JWS fixtures for AAPL-02.
- [ ] `accrue/test/accrue/entitlements/apple_lineage_test.exs` — bind-once and conflict integration coverage for AAPL-01.
- [ ] `accrue/test/property/apple_lineage_property_test.exs` — race/property proof for AAPL-01.
- [ ] `accrue/test/accrue/entitlements/apple_intake_test.exs` — disposition and ordering coverage for AAPL-03.
- [ ] `accrue/test/property/apple_convergence_property_test.exs` — convergence property proof for AAPL-03.
- [ ] `accrue/test/accrue/entitlements/apple_reconciliation_test.exs` — paging, final-cursor, outage, status, and history coverage for AAPL-04.
- [ ] `accrue/test/accrue/entitlements/apple_source_isolation_test.exs` — lifecycle isolation and external-management guidance for AAPL-05.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Apple sandbox/provider fidelity | AAPL-01–AAPL-04 | Apple credentials and a sandbox app are not available in the repository environment | Once a host supplies credentials, run purchase, restore, notification, status, and transaction-history flows against Apple sandbox; retain deterministic fake/golden-fixture tests as merge-blocking coverage. |
| Candidate Apple library admission | AAPL-02, AAPL-04 | The low-adoption library requires hostile-chain, privacy, API, and supervision review before adoption | Review the adapter behind a private behaviour; confirm rejection corpus, redaction, timeout/retry behavior, and fallback adapter viability before selecting it. |

---

## Validation Sign-Off

- [ ] All tasks have automated verification or explicit Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers every missing test reference.
- [ ] No watch-mode flags.
- [ ] Feedback latency stays within one task.
- [ ] Golden verification, bind-race, cursor, redaction, and Apple-to-Stripe negative cases are green.
- [ ] `nyquist_compliant: true` is set in frontmatter after validation.

**Approval:** pending
