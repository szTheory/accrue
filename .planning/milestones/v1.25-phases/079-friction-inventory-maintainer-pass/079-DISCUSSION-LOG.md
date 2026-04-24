# Phase 79: Friction inventory maintainer pass - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **079-CONTEXT.md**.

**Date:** 2026-04-24  
**Phase:** 79-friction-inventory-maintainer-pass  
**Areas discussed:** Evidence path (a)/(b); Certification placement; Reviewed SHA scope; Inventory rows vs verifier counts; GSD discuss defaults  
**Mode:** Research-backed synthesis via parallel subagents + maintainer preference to shift defaults left.

---

## Evidence path (INV-03 (a) vs (b))

| Option | Description | Selected |
|--------|-------------|----------|
| Default (a) | Add P1/P2 rows whenever friction “feels” present | |
| Default (b) | Dated certification unless ranked evidence clears P1/P2 bar | ✓ |
| Hybrid | (b) default + explicit triggers; (a) only with primary sources / merge-blocking story | ✓ (refined) |

**User's choice:** Default **(b)** with **(a)** only for ranked, sourced friction; aligns with **S1/S5** and INV-03 falsifiable certification.  
**Notes:** Research drew on Stripe changelog discipline, Kubernetes structured notices, Go module policy — avoid row inflation and certification theater.

---

## Certification placement

| Option | Description | Selected |
|--------|-------------|----------|
| Inventory only | All prose in `v1.17-FRICTION-INVENTORY.md` | Partial |
| Phase only | Attestation only in `079-VERIFICATION.md` | |
| Split | Canonical paragraph in inventory; methodology/evidence in `079-VERIFICATION.md` | ✓ |

**User's choice:** **Split** — normative certification in **inventory**; evidence trail in **079-VERIFICATION.md** with pointer to single attestation voice (no duplicate cert paragraphs).

---

## Reviewed SHA scope

| Option | Description | Selected |
|--------|-------------|----------|
| Single merge SHA | One reproducible `main` merge commit | ✓ |
| Commit window | Range / last N commits | |
| Tag-only | Only release tag without commit | |

**User's choice:** **One explicit `main` merge SHA** + verifier bundle run on that tree; re-cert = new SHA + new runs.  
**Notes:** Avoid “window” footgun (green at tip ≠ all intermediates).

---

## Inventory rows vs verifier script

| Option | Description | Selected |
|--------|-------------|----------|
| Merge rows to keep counts | Replace P1/P2 to appease bash counts | |
| Append + same-PR script update | New stable id rows; update `verify_v1_17_friction_research_contract.sh` counts | ✓ |
| Structural refactor | Drop counts for checksum/schema checks | Deferred |

**User's choice:** **Append + co-update script** in same PR; **defer** structural verifier refactor.  
**Notes:** Research (semver parsers, snapshot tests) favors structural invariants long-term; current repo contract stays honest via paired edits.

---

## Claude's Discretion

- **Verifier long-term shape:** Deferred to a future hygiene phase unless explicitly scoped (**079-CONTEXT.md** `<deferred>`).

## Deferred Ideas

- Migrate `verify_v1_17_friction_research_contract.sh` from magic row counts to structural / checksum validation.
