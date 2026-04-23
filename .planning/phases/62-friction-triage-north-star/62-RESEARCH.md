# Phase 62 — Technical research

**Question:** What do we need to know to **plan** friction triage + north star well?

## Scope recap

Phase **62** closes **FRG-01**, **FRG-02**, **FRG-03** with **markdown-only** artifacts under **`.planning/`** (see **62-CONTEXT.md** D-01..D-05). Execution code is **63–65**.

## Evidence sources (scan order)

1. **`examples/accrue_host/README.md`** — golden-path steps, VERIFY hops, known friction language.
2. **`examples/accrue_host/docs/adoption-proof-matrix.md`** — row IDs for `sources` column (`matrix:…`).
3. **`scripts/ci/README.md`** + named **`scripts/ci/verify_*.sh`** — `ci_contract` values (`merge_blocking` vs `advisory`) and script paths for citations.
4. **`accrue/guides/first_hour.md`** — integrator obligations vs nice-to-haves.
5. **Recent milestone archives** — `.planning/milestones/v1.16-*` or phase notes for recurring pain (optional secondary tier with promotion hypothesis).

## Row schema (implementation)

- **Two axes** per **FRG-01** row: `ci_contract`, `integrator_impact` (definitions in **`v1.17-north-star.md`** pointer + inventory header).
- **Stable IDs:** `v1.17-P0-001` … append-only; never renumber.
- **`frg03_disposition`:** `→63` | `→64` | `→65` | `not_v1.17` | `downgraded` — every **P0** must resolve for **FRG-03** success criteria.
- **Defer / not_v1.17:** maintainer-signed rationale + revisit + future owner (**REQUIREMENTS** FRG-01 wording).

## FRG-02 status

Canonical prose already lives in **`.planning/research/v1.17-north-star.md`**. Remaining work is **verification**: **`.planning/PROJECT.md`** § Current milestone and **`.planning/STATE.md`** must **link** to that file and the inventory (no duplicate essays).

## FRG-03 closure test

From **ROADMAP** success criterion **3**: every **P0** row either maps **`req`** to **INT-10** / **BIL-03** / **ADM-12** with matching **`frg03_disposition`**, or **`not_v1.17`** with rationale in **`notes`**.

## Pitfalls

- **Duplicating** P0 tables in ROADMAP or STATE (forbidden by D-01c, D-04a).
- **Treating CI-only flakes** as long-lived P0 without integrator story — use D-02a bar; downgrade with signed note when appropriate.
- **Empty inventory** — template example row must be replaced by real rows **or** explicit “**P0 certified empty**” maintainer paragraph (only if evidence scan truly finds zero P0s).

## Validation Architecture

Phase verification is **document + contract** based (no app test suite as primary signal).

| Dimension | Strategy |
|-----------|----------|
| **Correctness** | Grep for required strings, stable IDs, column headers; manual read of P0 ↔ FRG-03 mapping. |
| **Completeness** | Checklist in **REQUIREMENTS.md** for FRG-01..03; success criteria in **ROADMAP.md** Phase 62. |
| **Drift** | Single SSOT tables in **`v1.17-FRICTION-INVENTORY.md`**; PROJECT/STATE are pointers only. |
| **Security** | Do not paste **live secrets** or **production Stripe identifiers** into inventory `sources` — use verifier names, public doc paths, or redacted issue links. |

**Automated helpers (post-edit):**

- `rg "v1\\.17-P0-" .planning/research/v1.17-FRICTION-INVENTORY.md`
- `rg "v1\\.17-north-star\\.md|v1\\.17-FRICTION-INVENTORY\\.md" .planning/PROJECT.md .planning/STATE.md`
- `bash scripts/ci/verify_package_docs.sh` — run after any edit to **published** doc paths under **`accrue/`** / **`accrue_admin/`** that this phase might touch (unlikely for pure `.planning/` work; required if a task edits guides/README).

---

## RESEARCH COMPLETE

Ready for **62-VALIDATION.md** + PLAN.md generation.
