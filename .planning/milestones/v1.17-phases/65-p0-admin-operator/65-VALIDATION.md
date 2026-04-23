---
phase: 65
slug: p0-admin-operator
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-23
---

# Phase 65 — Validation strategy

> Per-phase validation contract for **ADM-12** closure with **empty** admin P0 queue (certification path).

---

## Test infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `accrue/mix.exs` (test task) |
| **Quick run command** | `cd accrue && mix test test/accrue/docs/v1_17_friction_research_contract_test.exs` |
| **Full suite command** | `cd accrue && mix test` |
| **Structural verifier** | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` (repo root) |
| **Estimated runtime** | ~2–15 minutes depending on full `mix test` scope |

---

## Sampling rate

- **After every task touching `.planning/` or `scripts/ci/verify_v1_17_friction_research_contract.sh`:** Run **structural verifier** + **quick ExUnit** above.
- **Before `/gsd-verify-work`:** Full `mix test` in `accrue/` green on representative machine.
- **Max feedback latency:** Target under 5 minutes for quick path.

---

## Per-task verification map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure behavior | Test type | Automated command | File exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 65-01-01 | 01 | 1 | ADM-12 | T-65-01 / — | No secret literals in planning prose | structural + unit | `bash scripts/ci/verify_v1_17_friction_research_contract.sh`; `cd accrue && mix test test/accrue/docs/v1_17_friction_research_contract_test.exs` | ✅ | ⬜ pending |
| 65-01-02 | 01 | 1 | ADM-12 | T-65-02 / — | Inventory subsection only; FRG-01 table untouched | structural + grep | `bash scripts/ci/verify_v1_17_friction_research_contract.sh`; `rg -n "ADM-12" .planning/research/v1.17-FRICTION-INVENTORY.md` | ✅ | ⬜ pending |
| 65-01-03 | 01 | 1 | ADM-12 | — | N/A (markdown checklist) | grep | `rg -n "ADM-12" .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |

---

## Wave 0 requirements

**Existing infrastructure covers all phase requirements** — no new test stubs required for the empty-queue certification path.

---

## Manual-only verifications

| Behavior | Requirement | Why manual | Test instructions |
|----------|-------------|------------|-------------------|
| Verification doc matches inventory intent | ADM-12 | Maintainer judgment on SSOT wording | Read **`65-VERIFICATION.md`** beside **`### Backlog — ADM-12 (Phase 65)`** in **`v1.17-FRICTION-INVENTORY.md`** |

---

## Validation sign-off

- [x] All tasks have `<automated>` verify or documented manual row
- [x] Sampling continuity: structural + ExUnit after planning edits
- [x] Wave 0 N/A — covered by existing tests
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
