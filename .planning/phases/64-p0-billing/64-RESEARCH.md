# Phase 64 — P0 billing — Technical research

**Status:** Ready for planning  
**Question answered:** What must be true to **plan** auditable **BIL-03** closure when the **FRG-03** billing slice has **zero** P0 rows?

## Summary

Phase **64** mirrors **63** mechanically but for the **billing** requirement (**BIL-03**). The inventory **`### Backlog — BIL-03 (Phase 64)`** anchor is already merge-protected by **`scripts/ci/verify_v1_17_friction_research_contract.sh`**. With **no** billing P0 rows, **D-03** from **64-CONTEXT.md** applies: **no** required **`accrue/CHANGELOG.md`** or **`accrue/guides/telemetry.md`** edits for “nothing shipped.” Closure is **inventory certification** + **lean `64-VERIFICATION.md`** (same **family** as **`63-VERIFICATION.md`**) + **`REQUIREMENTS.md`** checkbox + **`STATE.md`** handoff — **not** new friction-script semantics for billing row counts (**D-01c**).

## Key artifacts and contracts

| Artifact | Role |
|----------|------|
| `.planning/research/v1.17-FRICTION-INVENTORY.md` § **Backlog — BIL-03** | Durable **FRG-01/03** “empty queue **or** ship” statement; ROADMAP links here |
| `.planning/phases/63-p0-integrator-verify-docs/63-VERIFICATION.md` | Layout template: scope paragraph, anchor link, traceability table, merge-blocking vs manual |
| `scripts/ci/verify_v1_17_friction_research_contract.sh` | Structural anchors only — **do not** extend with billing P0 prose regex without milestone policy |
| `accrue/test/accrue/docs/v1_17_friction_research_contract_test.exs` | ExUnit mirror of friction contract — run after `.planning/` edits that affect inventory/roadmap expectations |

## Planning recommendations

1. **`64-VERIFICATION.md`** — One **BIL-03** rollup row + explicit **empty-queue** acceptance one-liner; proof column cites **`verify_v1_17_friction_research_contract.sh`** + **`mix test …v1_17_friction_research_contract_test.exs`** + optional **`mix test test/accrue/billing/`** only if executor touches billing code (this milestone: expect **no** billing-shaped churn line per **D-02a**).
2. **Inventory** — Add a **maintainer-signed** one-liner under **BIL-03** (parallel to closed **INT-10** row **notes** style) pointing at **`64-VERIFICATION.md`**, without inventing fake **P0** rows.
3. **`REQUIREMENTS.md`** — Flip **BIL-03** to satisfied only after verification doc + inventory read as one story.
4. **No UI-SPEC** — Phase is billing closure / certification, not LiveView work (**HAS_UI** false).

## Risks / footguns

- **Audit theater:** Checklist without **FRG-03** reconciliation or without runnable proof commands (**D-01d**, **D-02c**).
- **Wrong audience CHANGELOG:** Process-only “no P0” lines (**D-03c**).
- **Silent new P0:** Any future **Accrue.Billing** / Fake work must arrive via **FRG-01** row + **→64** disposition (**D-04**).

## Validation Architecture

**Dimension 8 (Nyquist):** Feedback during execution must be **fast** and **automated** where possible.

| Dimension | Strategy for Phase 64 |
|-----------|----------------------|
| **Test framework** | **ExUnit** (`mix test` in `accrue/`) |
| **Structural SSOT** | Bash **`verify_v1_17_friction_research_contract.sh`** (no BEAM) |
| **Sampling** | After any `.planning/research/*.md` or `.planning/ROADMAP.md` edit: run friction script **and** `v1_17_friction_research_contract_test.exs` |
| **Manual** | Maintainer read of **`64-VERIFICATION.md`** table against inventory before merge (short) |

**Wave 0:** Not required — existing **ExUnit** + bash verifier cover this phase’s doc-only closure path.

---

## RESEARCH COMPLETE
