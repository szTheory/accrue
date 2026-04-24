# Phase 67 — Proof contracts — Research synthesis

**Role:** gsd-phase-researcher  
**Date:** 2026-04-23  
**Question answered:** What do I need to know to **plan** this phase well?

---

## Executive summary

Phase 67 closes **PRF-01** and **PRF-02** for milestone **v1.19** by tightening the **single mechanical owner** story between **`examples/accrue_host/docs/adoption-proof-matrix.md`** (human SSOT) and **`scripts/ci/verify_adoption_proof_matrix.sh`** (merge-blocking needles), and by making the **co-update** rule obvious in **`scripts/ci/README.md`**. The motivating risk is **`v1.17-P1-001`**: taxonomy or archetype edits to the matrix can drift from CI needles because prose and grep lists are maintained separately.

**Planning stance (from `67-CONTEXT.md`, locked):** Keep **bash** as the canonical needle list; keep **ExUnit** as a thin “script runs and prints OK” harness; do **not** duplicate substring inventories in Elixir unless a future requirement forces parsing in Mix. Extend **`scripts/ci/README.md`** triage for **PRF-02**; add **`require_substring`** only for **slow-changing, user-visible** anchors (per **D-02**), not full-doc snapshots or wording polish.

---

## Requirements trace (planning inputs)

| ID | Text (abridged) | Planning implication |
|----|-----------------|------------------------|
| **PRF-01** | Merge-blocking checks cover **taxonomy / archetype / row-id** alignment between matrix, script, and related ExUnit; intentional matrix edits **must** update needles in the **same change set**. | Inventory matrix headings and stable row tokens; map each to present/absent needle; choose **minimal** new `require_substring` lines; verify CI + `mix test` path stay green. |
| **PRF-02** | **`scripts/ci/README.md`** documents triage for **`verify_adoption_proof_matrix.sh`**, including **matrix + script + tests co-update** and pointer to matrix SSOT. | Extend **`### Triage: verify_adoption_proof_matrix.sh`** (and optionally cross-link **INT-07** row) without duplicating the full needle list in prose—point to script + matrix paths. |

**Friction driver:** **`v1.17-P1-001`** (`.planning/research/v1.17-FRICTION-INVENTORY.md`) — *Adoption proof matrix vs `verify_adoption_proof_matrix.sh` needles drift on taxonomy edits*; `ci_contract`: **merge_blocking**; workaround already points at **`scripts/ci/README.md`** § triage—Phase 67 makes that workaround **complete** (co-update rule explicit) and reduces drift class via needles + discipline.

---

## Current `require_substring` inventory (canonical list)

All checks use **`grep -Fq`** against **`examples/accrue_host/docs/adoption-proof-matrix.md`**. Failure format:  
`verify_adoption_proof_matrix: matrix missing <label> (expected substring: <needle>)`

| Order | Needle | Human label in script |
|-------|--------|----------------------|
| 1 | `## Layering note (local proof vs merge-blocking CI)` | Layer B/C layering heading |
| 2 | `**Layer B (local Fake-backed proof):**` | Layer B label |
| 3 | `**Layer C (merge-blocking \`docs-contracts-shift-left\` + \`host-integration`):**` | Layer C label |
| 4 | `verify_v1_17_friction_research_contract.sh` | v1.17 planning SSOT script name in matrix |
| 5 | `verify_verify01_readme_contract.sh` | VERIFY-01 shift-left script name in matrix |
| 6 | `accrue_host_hex_smoke.sh` | Hex smoke script name in matrix layering note |
| 7 | `## Organization billing proof (ORG-09)` | ORG-09 section heading |
| 8 | `### Primary archetype (merge-blocking)` | primary archetype heading |
| 9 | `### Recipe lanes (advisory by default)` | recipe lanes heading |
| 10 | `scripts/ci/verify_adoption_proof_matrix.sh` | script path literal |
| 11 | `phx.gen.auth` | phx.gen.auth mention |
| 12 | `use Accrue.Billable` | Accrue.Billable hook |
| 13 | `non-Sigra` | non-Sigra framing |
| 14 | `ORG-07` | ORG-07 row |
| 15 | `ORG-08` | ORG-08 row |

**Note:** **`verify_package_docs.sh`** appears inside the Layer C paragraph in the matrix but is **not** its own standalone `require_substring`—it is only guaranteed indirectly if the full Layer C sentence stays intact; the Layer C **label** needle does not include the package-docs script name by itself.

---

## Likely gaps (ORG-09, taxonomy, archetype rows)

Use this as a **planning checklist**, not a mandate to needle everything.

**Already well covered for ORG-09 core story**

- Section title **ORG-09**, **Primary archetype (merge-blocking)** vs **Recipe lanes (advisory by default)**, **non-Sigra** + **`phx.gen.auth`** + **`use Accrue.Billable`**, advisory **ORG-07** / **ORG-08** tokens, self-referential script path.

**Under-covered or asymmetric (candidates for PRF-01 “minimal add”)**

1. **Layer C script list completeness** — The matrix Layer C sentence lists **`verify_package_docs.sh`**, friction contract, VERIFY-01, adoption matrix, and **`verify_core_admin_invoice_verify_ids.sh`**. The verifier needles three script basenames but **does not** assert **`verify_core_admin_invoice_verify_ids.sh`**. If the goal is “matrix and CI story stay aligned,” one short needle for that basename is a **low-churn** fix aligned with **v1.17-P1-001** (taxonomy of what merge-blocking docs gates claim).
2. **ORG-05 / ORG-06** — The primary archetype row text references **ORG-05/ORG-06 alignment** with the organization billing guide. Those tokens are **not** needled today; if archetype/guide cross-refs are part of “taxonomy,” adding **`ORG-05`** and **`ORG-06`** (or a single stable phrase) is optional—**risk** is false positives if those IDs move to footnotes; **benefit** is locking the **mainline vs advisory** narrative to guide taxonomy.
3. **Blocking vs advisory section headers** — **`## Blocking: Fake-backed host + browser`** and **`## Advisory: Stripe test mode`** are strong structural anchors but **higher editorial churn**; match **D-02** (“stop at diminishing returns”)—only add if inventory shows repeated accidental deletion.
4. **Intro / realism paragraph** — Mentions **`Accrue.Processor.Fake`**, **`lattice_stripe`**, proof lanes; valuable for readers, usually **too volatile** for substring gates unless a single phrase is declared stable policy.
5. **Pow / custom org labels** — Needles **`ORG-07`** / **`ORG-08`** but not **`Pow`** or **“Custom organization”**; row ids may suffice if the inventory confirms ids are the taxonomy SSOT.

**Explicit non-goals (per context)**

- Full-file golden snapshots; heavy regex on prose; **Mix task** replacement of the script; **`needles.json`** codegen in this phase.

---

## PRF-01 vs PRF-02 (plan split hint)

- **PRF-01** is **mechanical**: edit **`verify_adoption_proof_matrix.sh`** after **`67-01`**-style matrix ↔ needle inventory; run **`docs-contracts-shift-left`** equivalents locally; keep **`OrganizationBillingOrg09MatrixTest`** passing without new Elixir string lists.
- **PRF-02** is **documentation**: same PR (or immediately adjacent) updates **`scripts/ci/README.md`** so contributors see **SSOT path**, **bash as regression harness**, **job name `docs-contracts-shift-left`**, **`verify_adoption_proof_matrix:`** stderr prefix meaning, and **one change set: matrix → script → (only if needed) ExUnit with literals**—today INT-07 table partially states this; triage bullets should state it **verbatim** for ORG-09.

---

## `scripts/ci/README.md` triage text (current vs desired)

**Current (`### Triage: verify_adoption_proof_matrix.sh`, ~3 lines):** Maps stderr prefix to ORG-09 class failures; lists representative missing literals; says fix matrix first then needles on intentional taxonomy edit.

**Gaps for PRF-02:**

- Does not name **`examples/accrue_host/docs/adoption-proof-matrix.md`** as the **SSOT path** (only “`adoption-proof-matrix.md`” basename in one place).
- Does not state **`docs-contracts-shift-left`** as the CI home for this script (Layer C already says it in the matrix; triage should **repeat for discoverability**).
- Does not spell **“same PR / commit: matrix + script + any ExUnit that embeds matrix literals”** — **INT-07** row mentions `organization_billing_org09_matrix_test.exs` when literals change; triage should align wording with **INT-07** to avoid **triple maintenance** (bash + README + table) — README should **summarize rule** and **point** to script file as needle SSOT, not duplicate every needle.

---

## Avoid duplicate Elixir literals

**Established pattern:** `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs` shells out to **`bash scripts/ci/verify_adoption_proof_matrix.sh`** from repo root, asserts exit `0` and output contains **`verify_adoption_proof_matrix: OK`**. No substring list in Elixir.

**Planning rules:**

- If a new invariant is expressible in **`require_substring`**, add it **only** to the bash script.
- Add Elixir-side asserts **only** when bash cannot express the contract (none identified for 67).
- If **`organization_billing_guide_test.exs`** (or others) already pin ORG-09 guide phrases, avoid **copy-pasting matrix sentences** into ExUnit—prefer bash needles or guide-specific tests, not a second matrix mirror (**D-05** / **v1.17-P1-001** lesson).

---

## Validation Architecture

**Goal:** Every planner knows exactly how this gate runs locally, in package tests, and in CI.

1. **Bash verifier (merge-blocking SSOT for substrings)**  
   - **Path:** `scripts/ci/verify_adoption_proof_matrix.sh`  
   - **Run from:** repository root (`repo_root` is derived from script location).  
   - **Success token:** stdout line **`verify_adoption_proof_matrix: OK`** (stderr uses **`verify_adoption_proof_matrix:`** prefix on failure—keep stable for log triage).  
   - **Contract style:** `require_substring <needle> <label>` → `grep -Fq` on the matrix file.

2. **ExUnit (package-level parity, thin harness)**  
   - **Path:** `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs`  
   - **Module:** `Accrue.Docs.OrganizationBillingOrg09MatrixTest`  
   - **Behavior:** `System.cmd("bash", [script], cd: root, stderr_to_stdout: true)`; assert exit `0` and output `=~ "verify_adoption_proof_matrix: OK"`.  
   - **Related:** `organization_billing_guide_test.exs` for guide contracts—**INT-07** says touch matrix test when ORG-09 matrix literals change; keep **INT-07** and triage text consistent after edits.

3. **CI job `docs-contracts-shift-left`**  
   - **Workflow:** `.github/workflows/ci.yml`  
   - **Job id:** `docs-contracts-shift-left` (display name: **Docs and bash contracts (shift-left)**).  
   - **Step name:** `Adoption proof matrix contract` → `bash scripts/ci/verify_adoption_proof_matrix.sh`  
   - **Order context:** Same job runs `verify_package_docs.sh`, `verify_v1_17_friction_research_contract.sh`, `verify_verify01_readme_contract.sh`, then **adoption proof matrix**, then `verify_core_admin_invoice_verify_ids.sh`. **`host-integration`** `needs: [admin-drift-docs, docs-contracts-shift-left]`—shift-left failures block host integration.

**Planner verification checklist:** After any matrix or script change: `bash scripts/ci/verify_adoption_proof_matrix.sh` from root; `mix test test/accrue/docs/organization_billing_org09_matrix_test.exs` from **`accrue/`**; confirm full CI job **`docs-contracts-shift-left`** would remain green.

---

## Cohesion with Phase 68+

Phase **67** is intentionally **before** Hex publish (**68**) and doc pin sweeps (**69**): proof contracts reduce **false confidence** from a green matrix prose change that silently drops merge-blocking semantics.

---

## RESEARCH COMPLETE
