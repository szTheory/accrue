# Phase 83: Friction inventory post-touch - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`083-CONTEXT.md`**.

**Date:** 2026-04-24  
**Phase:** 83 — Friction inventory post-touch  
**Areas discussed:** Evidence path (a)/(b); INV-04 verifier bundle; SSOT vs `083-VERIFICATION.md`; SHA discipline; row counts + script; revisit triggers  
**Mode:** `[config: discuss_auto_all_gray_areas]` auto-selected all gray areas; `[config: research_before_questions]` informed defaults.

---

## Evidence path (a) vs (b)

| Option | Description | Selected |
|--------|-------------|----------|
| Default (b) | Dated certification unless ranked FRG-01 bar cleared | ✓ |
| Favor (a) | Add P1/P2 rows whenever INT-13 docs change | |
| Strict (a)-only | Always append rows after milestone touch | |

**User's choice:** Config-driven auto-resolution — **default (b)** per Phase **79** maintainer culture and **FRG-02** **S1**/**S5**.  
**Notes:** Escalate to **(a)** only when a new row beats extending existing **`notes`**.

---

## INV-04 verifier bundle vs Phase 79 (INV-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Full INV-04 list | All five named checks in REQUIREMENTS + script when counts change | ✓ |
| INV-03-minimal three | Omit `docs-contracts-shift-left` from certification prose | |
| Verifiers in verification doc only | Inventory subsection stays minimal | |

**User's choice:** **Full INV-04 list** in attestation / methodology — **`docs-contracts-shift-left`** is merge-blocking scope for this certification, not optional.

---

## Where certification lives

| Option | Description | Selected |
|--------|-------------|----------|
| Split inventory + `083-VERIFICATION.md` | Single attestation voice in inventory; methodology in milestone tree | ✓ |
| Verification doc only | | |
| Inventory only (long appendix) | | |

**User's choice:** **Split** — **`### v1.26 INV-04 maintainer pass (date)`** in **`v1.17-FRICTION-INVENTORY.md`** after **v1.25 INV-03** block; **`083-VERIFICATION.md`** for transcripts and commands.

---

## Reviewed SHA discipline

| Option | Description | Selected |
|--------|-------------|----------|
| Single explicit `main` merge SHA | Reproducible checkout + verifier bundle | ✓ |
| Date-only / branch tip fuzzy | | |

**User's choice:** **Single SHA** (Phase **79** pattern).

---

## Row counts vs `verify_v1_17_friction_research_contract.sh`

| Option | Description | Selected |
|--------|-------------|----------|
| Same-PR honest script update when (a) changes counts | | ✓ |
| Avoid new rows to keep counts | | |

**User's choice:** **Same-PR** script update; never merge rows to game counts.

---

## Revisit triggers

| Option | Description | Selected |
|--------|-------------|----------|
| v1.25-style + INT-13 / portal drift | Hex publish, matrix taxonomy, CI failures + billing-portal spine drift | ✓ |
| Copy v1.25 verbatim | | |

**User's choice:** **Extend** v1.25 trigger family with **INT-13-class** integrator drift language.

---

## Claude's Discretion

- Exact subsection prose wording in **`v1.17-FRICTION-INVENTORY.md`** (must keep falsifiable verifier names + SHA).
- **`083-VERIFICATION.md`** table layout — must remain audit-friendly.

## Deferred Ideas

- Verifier structural refactor away from magic row counts — future phase.
