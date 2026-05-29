---
phase: 149
slug: dunning-state-api-and-headless-component
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
validated: 2026-05-29
reconstructed: true
---

# Phase 149 — Validation Strategy

> Per-phase validation contract. Reconstructed retroactively (State B) during
> `/gsd-audit-milestone v1.45`; the phase was already executed and verified
> (149-VERIFICATION.md, passed 2/2). This contract back-fills the Nyquist
> coverage record and the one missing component test.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | none — uses standard `mix test` per package |
| **Quick run command** | `cd accrue && mix test test/accrue/dunning_test.exs` |
| **Full suite command** | `cd accrue && mix test` ; `cd accrue_admin && mix test test/accrue_admin/components/dunning_banner_test.exs` |
| **Estimated runtime** | ~3 seconds (targeted) |

---

## Sampling Rate

- **After every task commit:** Run the relevant package's targeted test above
- **After every plan wave:** Run the owning package's full `mix test`
- **Before `/gsd-verify-work`:** Both targeted suites green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 149-01-01 | 01 | 1 | BAN-01 | — | Ledger is source of truth; no projection-lag false positives (read-only `exists?` on `accrue_subscriptions`) | unit (DB) | `cd accrue && mix test test/accrue/dunning_test.exs` | ✅ | ✅ green |
| 149-01-02 | 01 | 1 | BAN-01 | — | `requires_attention?/1` true/false/no-customer branches | unit (DB) | `cd accrue && mix test test/accrue/dunning_test.exs` | ✅ | ✅ green |
| 149-02-01 | 02 | 2 | BAN-02 | — | Component renders default message, custom inner_block, and empty branch per `requires_attention?/1` | integration (component + DB) | `cd accrue_admin && mix test test/accrue_admin/components/dunning_banner_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. `accrue/test/accrue/dunning_test.exs`
shipped with plan 149-01. The component behavioral test
(`accrue_admin/test/accrue_admin/components/dunning_banner_test.exs`) was the one
gap — back-filled during this audit, covering all three render branches
(default-message, custom inner_block slot, and the empty not-dunning branch).

---

## Manual-Only Verifications

All phase behaviors have automated verification. (End-to-end visual proof of the
banner in a real host layout is additionally covered downstream by Phase 150's
`examples/accrue_host/test/accrue_host_web/live/dunning_banner_live_test.exs`.)

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (BAN-02 component test back-filled)
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-29

---

## Validation Audit 2026-05-29

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

Gap: BAN-02 component (`AccrueAdmin.Components.DunningBanner.dunning_banner/1`)
had no direct test in its owning package; the `inner_block` slot branch was
untested anywhere. Resolved by adding
`accrue_admin/test/accrue_admin/components/dunning_banner_test.exs` (3 tests, all
green) exercising the real DB-backed `requires_attention?/1` lookup across all
three render branches.
