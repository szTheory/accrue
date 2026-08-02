---
phase: 216
slug: additive-rail-and-persistence-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-02
---

# Phase 216 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Ecto SQL Sandbox |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/config_entitlements_test.exs` |
| **Full suite command** | `cd accrue && mix test.all` |
| **Estimated runtime** | Quick suite ~2 seconds; full-suite runtime measured during execution |

---

## Sampling Rate

- **After every task commit:** Run the targeted `mix test` command for the touched config or schema test file.
- **After every plan wave:** Run `cd accrue && mix test`.
- **Before `$gsd-verify-work`:** Run `cd accrue && mix test.all`; the full suite must be green.
- **Max feedback latency:** 120 seconds for the per-task targeted suite.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 216-01-01 | 01 | 1 | RAIL-01 | — | Contradictory rail/default configuration fails closed at boot | unit/config | `cd accrue && mix test test/accrue/config_entitlements_test.exs` | ✅ extend | ⬜ pending |
| 216-01-02 | 01 | 1 | RAIL-02 | — | Rail/environment-qualified identifiers reject only true tuple collisions | unit/config | `cd accrue && mix test test/accrue/config_entitlements_test.exs` | ✅ extend | ⬜ pending |
| 216-02-01 | 02 | 2 | RAIL-03 | — | Database uniqueness and partial indexes reject duplicate/racing durable state | integration/DB | `cd accrue && mix test test/accrue/entitlements/persistence_test.exs` | ❌ W0 | ⬜ pending |
| 216-02-02 | 02 | 2 | RAIL-03 | — | Superseded/revoked records retain history and stable identity | integration/DB | `cd accrue && mix test test/accrue/entitlements/persistence_test.exs` | ❌ W0 | ⬜ pending |

*Task IDs and plan allocation are provisional until PLAN.md files are finalized.*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/entitlements/persistence_test.exs` — migrations, constraints, idempotency, and current grant/device history for RAIL-03.
- [ ] `accrue/test/accrue/entitlements/fake_fixture_test.exs` — deterministic fixtures covering both rails and Apple environments.
- [ ] Extend `accrue/test/accrue/config_entitlements_test.exs` — RAIL-01/02 compatibility and catalog collision matrix.
- [ ] Extend installer/generated-host migration tests — validate the D-17 propagation path.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120 seconds
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
