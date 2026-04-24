# Phase 87: Friction inventory post-publish — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`087-CONTEXT.md`**.

**Date:** 2026-04-24  
**Phase:** 87 — Friction inventory post-publish  
**Areas discussed:** Inventory heading · 087-VERIFICATION depth · Verifier bundle · Revisit triggers · Path (a)/(b) carry-forward

---

## Gray area 1 — Inventory subsection title

| Option | Description | Selected |
|--------|-------------|----------|
| A | `### v1.<MILESTONE> INV-<NN> maintainer pass (<YYYY-MM-DD>)` — matches INV-03..05 | ✓ |
| B | Requirement-first heading — breaks established grep | |
| C | “Maintainer pass” before INV id — weaker `rg INV-06` | |
| D | Hex SemVer inside `###` — heading churn / drift | |

**User's choice:** Auto-resolved via **all** + parallel research — **Option A** (`### v1.28 INV-06 maintainer pass (YYYY-MM-DD)`).

**Notes:** Subagent research confirmed **Pay/Cashier/Stripe** public changelogs use **SemVer** in user-facing docs while **Accrue** planning SSOT correctly uses **planning milestone + INV** in internal `###` lines; SemVer + SHA stay in body / **087-VERIFICATION**.

---

## Gray area 2 — `087-VERIFICATION.md` depth

| Option | Description | Selected |
|--------|-------------|----------|
| A | Always lean 085-style only | |
| B | Always mandate full transcript annex when shift-left changes (even if 86 captured it) | |
| C | Lean default + transcript annex iff shift-left delta not already in **086-VERIFICATION** (or 86 exception gap) | ✓ |

**User's choice:** Research-backed **Option C** — composes with **086-CONTEXT** **D-04** without duplicate PPX certification.

---

## Gray area 3 — Verifier bundle enumeration

| Option | Description | Selected |
|--------|-------------|----------|
| A | Frozen list from **085** forever | |
| B | CI-derived only — no enumerated snapshot | |
| C | Hybrid — normative = **`ci.yml` @ reviewed SHA** steps under **`docs-contracts-shift-left`** + **`host-integration`**; **087-VERIFICATION** = enumerated snapshot + CI link | ✓ |

**User's choice:** **Option C** — avoids **085 vs live `ci.yml`** drift (**verify_core_admin_invoice_verify_ids.sh`**, **`verify_release_manifest_alignment.sh`** job split).

---

## Gray area 4 — Revisit triggers

| Option | Description | Selected |
|--------|-------------|----------|
| A | **083** family only | |
| B | Enumerate **PROJECT** / **MILESTONES** / **STATE** paths in inventory | |
| C | **083** family + **one** **PPX-08**-framed registry/planning mismatch bullet (pointer, no filename laundry list) | ✓ |

**User's choice:** **Option C** — closes mirror-without-publish gap without trigger spam.

---

## Claude's Discretion

- Minor wording in revisit-trigger bullet; transcript subsection layout in **087-VERIFICATION.md**.

## Deferred Ideas

- Scripted auto-parse of **`ci.yml`** for INV bundles — deferred (see **087-CONTEXT** `<deferred>`).
