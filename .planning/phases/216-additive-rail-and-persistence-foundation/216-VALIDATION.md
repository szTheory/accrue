---
phase: 216
slug: additive-rail-and-persistence-foundation
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-02
updated: 2026-08-02
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
| 216-01-01 | 01 | 1 | RAIL-01, RAIL-02, RAIL-03 | T-216-01, T-216-02, T-216-03, T-216-SC | Explicit Stripe/Apple config reaches one qualified product and one owner-stable account while boot/default and database uniqueness fail closed | tracer + unit/config + integration/DB | `cd accrue && mix test test/accrue/config_entitlements_test.exs test/accrue/entitlements/persistence_test.exs` | Task creates `accrue/test/accrue/entitlements/persistence_test.exs` and extends existing config test in RED step | ⬜ pending |
| 216-02-01 | 02 | 2 | RAIL-01 | T-216-04, T-216-06, T-216-07, T-216-SC | Explicit defaults reject ambiguity while legacy-only and concurrent reads remain deterministic | unit/config | `cd accrue && mix test test/accrue/config_entitlements_test.exs` | ✅ extend | ⬜ pending |
| 216-02-02 | 02 | 2 | RAIL-02 | T-216-05, T-216-06, T-216-07, T-216-SC | Qualified tuple normalization rejects only exact cross-plan collisions and preserves environment isolation | unit/config + compatibility | `cd accrue && mix test test/accrue/config_entitlements_test.exs test/accrue/entitlements/local_map_test.exs` | ✅ extend | ⬜ pending |
| 216-03-01 | 03 | 2 | RAIL-03 | T-216-08, T-216-09, T-216-10, T-216-SC | Observation identity is database-idempotent and row-visible evidence remains bounded/redacted | integration/DB | `cd accrue && mix test test/accrue/entitlements/persistence_test.exs --only observation` | ✅ created by tracer; extend | ⬜ pending |
| 216-03-02 | 03 | 2 | RAIL-03 | T-216-08, T-216-09, T-216-11, T-216-SC | Current-grant uniqueness preserves source-item and superseded history across qualified identities | integration/DB | `cd accrue && mix test test/accrue/entitlements/persistence_test.exs --only grant` | ✅ created by tracer; extend | ⬜ pending |
| 216-03-03 | 03 | 2 | RAIL-03 | T-216-09, T-216-11, T-216-12, T-216-SC | Account-scoped current device uniqueness preserves switching, rotation, and revocation history | integration/DB | `cd accrue && mix test test/accrue/entitlements/persistence_test.exs --only device` | ✅ created by tracer; extend | ⬜ pending |
| 216-04-01 | 04 | 3 | RAIL-01, RAIL-02, RAIL-03 | T-216-13, T-216-SC | Deterministic fixtures contain no live credentials, raw evidence, adopter identity, or PII | fixture + integration/DB | `cd accrue && mix test test/accrue/entitlements/fake_fixture_test.exs` | Task creates test in RED step | ⬜ pending |
| 216-04-02 | 04 | 3 | RAIL-01, RAIL-02, RAIL-03 | T-216-14, T-216-15, T-216-SC | Generated configuration/migration is repeat-safe and guidance never grants Apple gateway authority | installer + unit/config | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/accrue/config_entitlements_test.exs` | ✅ extend | ⬜ pending |

---

## Wave 0 Requirements (Complete)

No standalone Wave 0 plan is required. The finalized plans use task-level TDD and make test creation part of the owning task before production implementation:

- Plan 216-01's Wave-1 tracer creates `accrue/test/accrue/entitlements/persistence_test.exs` and extends `accrue/test/accrue/config_entitlements_test.exs` in its RED step. Plans 216-02 and 216-03 depend on 216-01, so their test expansions cannot run before that scaffold exists.
- Plan 216-04 Task 1 creates `accrue/test/accrue/entitlements/fake_fixture_test.exs` in its RED step before fixture implementation.
- `accrue/test/mix/tasks/accrue_install_test.exs` already exists and Plan 216-04 Task 2 extends it before changing installer output.

This tracer-first dependency shape closes every previously listed missing-test reference without a separate horizontal scaffold task.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All eight finalized tasks have an exact `<automated>` verification command
- [x] Sampling continuity: every task has automated verification
- [x] Wave 0/test creation is reconciled through the Wave-1 tracer and owning TDD RED steps
- [x] No watch-mode flags
- [x] Targeted feedback commands are expected to remain below 120 seconds; execution records the measured full-suite runtime
- [x] `wave_0_complete: true` and `nyquist_compliant: true` are set in frontmatter

**Approval:** ready for execution
