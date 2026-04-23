# Phase 65 — P0 admin / operator — Technical research

**Status:** Ready for planning  
**Question answered:** What must be true to **plan** auditable **ADM-12** closure when the **FRG-03** admin slice has **zero** P0 rows?

## Summary

Phase **65** mirrors **64** mechanically but for the **admin / operator** requirement (**ADM-12**). The inventory **`### Backlog — ADM-12 (Phase 65)`** anchor is already merge-protected by **`scripts/ci/verify_v1_17_friction_research_contract.sh`**. With **no** admin P0 rows, closure matches **64-CONTEXT** **D-03** analog: **no** required **`accrue_admin`** / **LiveView** / **Copy** / **VERIFY-01** churn for “nothing shipped.” Closure is **inventory certification** + **lean `65-VERIFICATION.md`** (same **family** as **`63-VERIFICATION.md`** / **`64-VERIFICATION.md`**) + **`REQUIREMENTS.md`** checkbox — **not** new friction-script semantics for admin row counts.

## Key artifacts and contracts

| Artifact | Role |
|----------|------|
| `.planning/research/v1.17-FRICTION-INVENTORY.md` § **Backlog — ADM-12** | Durable **FRG-01/03** “empty queue **or** ship” statement; ROADMAP links here |
| `.planning/phases/64-p0-billing/64-VERIFICATION.md` | Nearest **empty-queue** template sibling (**rollup row** pattern) |
| `.planning/phases/63-p0-integrator-verify-docs/63-VERIFICATION.md` | Multi-row variant; use only if admin P0 rows exist later |
| `scripts/ci/verify_v1_17_friction_research_contract.sh` | Structural anchors only — **do not** extend with admin P0 prose regex without milestone policy |
| `accrue/test/accrue/docs/v1_17_friction_research_contract_test.exs` | ExUnit mirror of friction contract — run after `.planning/` edits that affect inventory/roadmap expectations |

## Planning recommendations

1. **`65-VERIFICATION.md`** — One **ADM-12** rollup row + explicit **empty-queue** acceptance one-liner; proof column cites **`verify_v1_17_friction_research_contract.sh`** + **`mix test …v1_17_friction_research_contract_test.exs`**; add optional **`accrue_admin`** / Playwright proof **only** if executor touches admin routes (this milestone: expect **no** admin-shaped churn line, parallel **64-01** Task 1 narrative).
2. **Inventory** — Add a **maintainer-signed** one-liner under **`### Backlog — ADM-12 (Phase 65)`** pointing at **`65-VERIFICATION.md`**, without inventing fake **P0** rows; keep **FRG-01** pipe table untouched.
3. **`REQUIREMENTS.md`** — Flip **ADM-12** to satisfied only after verification doc + inventory read as one story.
4. **`65-UI-SPEC.md`** — Present so **plan-phase** UI gate does not block on **ROADMAP** substring **“LiveView”**; content is **N/A surfaces** for the certification path.

## Risks / footguns

- **Audit theater:** Checklist without **FRG-03** reconciliation or without runnable proof commands.
- **Silent new P0:** Any future **`accrue_admin`** work must arrive via **FRG-01** row + **→65** disposition.
- **Accidental FRG-01 edit:** Same **high-severity** footgun as Phase **64** — row counts are **CI-enforced**.

## Validation Architecture

**Dimension 8 (Nyquist):** Feedback during execution must be **fast** and **automated** where possible.

| Dimension | Strategy for Phase 65 |
|-----------|-------------------------|
| **Test framework** | **ExUnit** (`mix test` in `accrue/`) |
| **Structural SSOT** | Bash **`verify_v1_17_friction_research_contract.sh`** (no BEAM) |
| **Sampling** | After any `.planning/research/*.md` or `.planning/ROADMAP.md` edit: run friction script **and** `v1_17_friction_research_contract_test.exs` |
| **Manual** | Maintainer read of **`65-VERIFICATION.md`** table against inventory before merge (short) |

**Wave 0:** Not required — existing **ExUnit** + bash verifier cover this phase’s doc-only closure path.

---

## RESEARCH COMPLETE
