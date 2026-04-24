# Phase 82: First-hour portal spine - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`082-CONTEXT.md`**.

**Date:** 2026-04-24  
**Phase:** 82-first-hour-portal-spine  
**Areas discussed:** First Hour doc layout, Adoption proof matrix + verifier, Host README Observability, CHANGELOG + verification artifact home  
**Method:** User requested **all** areas + parallel **generalPurpose** research subagents; principal synthesized one coherent policy set.

---

## Area 1 — First Hour opening block (checkout vs portal prose)

| Approach | Description | Selected |
|----------|-------------|----------|
| A | Two **parallel paragraphs** (checkout, then portal) + optional one-line intro | ✓ |
| B | One **merged** paragraph (both APIs + tuples) | |
| C | **Bulleted** “server-side sessions” without full paragraph shape | |

**User's choice:** **A** (via “all” + delegate to research-backed recommendation)  
**Notes:** Matches **INT-13** “same **shape** as checkout,” grep-first CI culture, Stripe/Cashier/Pay pattern of **named, repeatable blocks** per product; avoids merged-tuple blur and shallow bullets.

---

## Area 2 — Adoption proof matrix + `verify_adoption_proof_matrix.sh`

| Approach | Description | Selected |
|----------|-------------|----------|
| A | **Second table row** full parity + **3** new `require_substring` lines | ✓ |
| B | Shorter row (telemetry / First Hour only) | |
| C2 | Single **widened** row (checkout + portal in one cell) | |

**User's choice:** **A** (layout **C1** — separate row, not mega-cell)  
**Notes:** Preserves **ORG-09** “one row ≈ one claim”; rejects false-green loose needles.

---

## Area 3 — Host README `## Observability`

| Approach | Description | Selected |
|----------|-------------|----------|
| A | **Second sibling bullet** mirroring checkout bullet | ✓ |
| B | One combined “Billing facades” bullet | |
| C | README **cross-link only**; literals only in First Hour | |

**User's choice:** **A**  
**Notes:** Aligns with existing **`verify_package_docs.sh`** contract on README literals; **C** needs explicit verifier redesign — deferred.

---

## Area 4 — CHANGELOG + `082-VERIFICATION.md` placement

| Approach | Description | Selected |
|----------|-------------|----------|
| B | **`.planning/milestones/v1.26-phases/082-…/082-VERIFICATION.md`** canonical | ✓ |
| A | `.planning/phases/082-…` as sole canonical | |
| C | PR body / commits only | |

**User's choice:** **B**  
**Notes:** Matches **079–081** milestone tree auditability; CHANGELOG = **Documentation** + **CI** (if scripts change) + **Telemetry** only if emission truth changes.

---

## Claude's Discretion

- Intro line wording in **First Hour**; matrix cell phrasing preserving literals; **`082-VERIFICATION.md`** layout.

## Deferred Ideas

- README literal migration away from **`verify_package_docs.sh`** needles — future phase only.
