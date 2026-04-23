# Phase 66 — Research: Deferred UAT + evaluator proof

**Milestone:** v1.18 — Onboarding confidence  
**Researched:** 2026-04-23  
**Question:** What do you need to know to **plan** this phase well?

---

## 1. Executive summary

- **Normative exit criteria** for UAT-01..UAT-05 and PROOF-01 live only in **`.planning/REQUIREMENTS.md`**; **`66-VERIFICATION.md`** is the evidence ledger; flip **`REQUIREMENTS.md`** checkboxes and the traceability table when proof is real.
- **Most UAT rows** can lean on **existing** merge-blocking shift-left: **`docs-contracts-shift-left`** runs **`verify_package_docs.sh`**, **`verify_v1_17_friction_research_contract.sh`**, **`verify_verify01_readme_contract.sh`**, **`verify_adoption_proof_matrix.sh`**, **`verify_core_admin_invoice_verify_ids.sh`** (job key **`docs-contracts-shift-left`**, workflow file **`.github/workflows/ci.yml`**, top-level name **`CI`** per file).
- **UAT-01 / UAT-02 / UAT-03** overlap **INT-10** automation: `verify_v1_17_friction_research_contract.sh` + ExUnit mirror **`accrue/test/accrue/docs/v1_17_friction_research_contract_test.exs`** already encode inventory shape, **STATE**/**PROJECT** pointer substrings, **S1**/**S5** rows, and **ROADMAP** FRG-03 inventory anchors.
- **UAT-04** (archive file present + narrative consistency) is **not** fully covered by that script: there is **no** current bash gate that `test -f` **`.planning/milestones/v1.17-REQUIREMENTS.md`** — plan either **maintainer sign-off** or a **one-line** add to an existing **`verify_*.sh`** (per D-02b) rather than prose snapshots.
- **PROOF-01** is **matrix-first**: **`examples/accrue_host/docs/adoption-proof-matrix.md`** is human SSOT; **`scripts/ci/verify_adoption_proof_matrix.sh`** is substring/needle regression; **`accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs`** runs the script; semantic alignment with **`evaluator-walkthrough-script.md`** + host **README** adoption/VERIFY section is a **single sitting** read (D-05), not a new exhaustive inventory.
- **Single canonical path** for phase artifacts: **`.planning/phases/66-onboarding-confidence/`** (D-01); no second slug directory, no symlinks.
- **`62-UAT.md`** already carries a **2026-04-23 supersession blockquote** pointing at **`REQUIREMENTS.md`**, **66-VERIFICATION**, **UAT-04**, and **`v1.17-REQUIREMENTS.md`** — planning should **verify** it matches D-03c intent rather than assume another rewrite.

---

## 2. Current repo facts (commands, job ids, file paths)

| Kind | Grep-friendly string / path |
|------|------------------------------|
| Workflow | `name: CI` in **`.github/workflows/ci.yml`** |
| Merge-blocking shift-left job id | `docs-contracts-shift-left` (see header comment: merge-blocking on `pull_request` includes this id) |
| Shift-left step names (in order) | `verify_package_docs.sh`; `v1.17 friction + north-star SSOT contract`; `VERIFY-01 README contract`; `Adoption proof matrix contract`; `Core admin invoice VERIFY flow id drift guard` |
| Bash one-liners (repo root) | `bash scripts/ci/verify_package_docs.sh`; `bash scripts/ci/verify_v1_17_friction_research_contract.sh`; `bash scripts/ci/verify_verify01_readme_contract.sh`; `bash scripts/ci/verify_adoption_proof_matrix.sh`; `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh` |
| Friction success token | `verify_v1_17_friction_research_contract: OK` (stderr/stdout) |
| Adoption matrix success token | `verify_adoption_proof_matrix: OK` |
| ExUnit mirrors | `accrue/test/accrue/docs/v1_17_friction_research_contract_test.exs` (calls `../scripts/ci/verify_v1_17_friction_research_contract.sh`); `package_docs_verifier_test.exs` (full `verify_package_docs.sh` + fixtures); `organization_billing_org09_matrix_test.exs` (runs `verify_adoption_proof_matrix.sh` from **repo root** `cd: root`) |
| Matrix / walkthrough | **`examples/accrue_host/docs/adoption-proof-matrix.md`**; **`examples/accrue_host/docs/evaluator-walkthrough-script.md`**; host **`examples/accrue_host/README.md`** |
| Friction + north star SSOT | **`.planning/research/v1.17-FRICTION-INVENTORY.md`**; **`.planning/research/v1.17-north-star.md`** |
| UAT-04 archive | **`.planning/milestones/v1.17-REQUIREMENTS.md`** |
| Phase dir | **`.planning/phases/66-onboarding-confidence/`** — owns **`66-VERIFICATION.md`** (to be added), **`66-CONTEXT.md`** (exists) |
| Verifier map | **`scripts/ci/README.md`** (ADOPT, ORG-09, INT-06..INT-10 triage) |
| Historical scenarios | **`.planning/milestones/v1.17-phases/62-friction-triage-north-star/62-UAT.md`** (banner present lines 9–11) |
| State pointer lines | **`.planning/STATE.md`** — `Friction inventory (FRG-01):` → `v1.17-FRICTION-INVENTORY.md`; `North star + stop rules (FRG-02):` → `v1.17-north-star.md` |
| REQUIREMENTS traceability | **`.planning/REQUIREMENTS.md`** table “Requirement \| Phase \| Status” — all six rows `66 \| Pending` until closure |

**Note:** Some older verification rows (e.g. **63-VERIFICATION.md**) say `CI (verify_package_docs job)` — the **actual** job id is **`docs-contracts-shift-left`**. For **66-VERIFICATION.md** D-04, prefer **workflow `CI` + job `docs-contracts-shift-left` + step names** to match `ci.yml` and avoid link rot.

---

## 3. Risks / footguns

- **Job naming drift:** Contributors grep **`verify_package_docs`**; CI’s **`jobs:`** key is **`docs-contracts-shift-left`**. Mismatch in **66-VERIFICATION.md** “Automation” column confuses “which gate failed?”.
- **UAT-04 vs automation:** No script currently proves **`v1.17-REQUIREMENTS.md`** on disk; deleting the file would **not** fail **`verify_v1_17_friction_research_contract.sh`**. If you add a file-existence check, do it in **bash** and optionally mirror in ExUnit like other scripts — do **not** snapshot full **REQUIREMENTS** prose.
- **Windows / path hygiene:** D-01 rejects symlinks for phase aliasing; **`.planning/`** paths use **forward slashes**; scripts resolve **`repo_root`** via `cd` + `BASH_SOURCE` (bash-only; CI is Linux).
- **Churn traps:** D-02c — avoid golden files for **PROJECT** / marketing copy. Right automation = **substrings, file presence,** stable anchors already in **shift-left** scripts.
- **PROOF-01 taxonomy edits:** D-05b — if ORG-07/08/09 labels or matrix headings change, **ship matrix + `verify_adoption_proof_matrix.sh` + (if applicable) `organization_billing_org09_matrix_test.exs` literals** in one change set; INT-07 doc ties ExUnit to ORG-09 matrix literals.
- **62-UAT.md:** Body is **historical**; do not “fix” test results to v1.18 — closure lives in **66-VERIFICATION** (D-03).

---

## 4. Recommended plan waves (high level)

| Wave | Intent | Likely file touch list |
|------|--------|------------------------|
| **1 — Ledger + traceability** | Add **`66-VERIFICATION.md`** (YAML frontmatter + one matrix per D-04; columns: Row ID, Acceptance, Merge-blocking proof, Automation, Evidence, Closure). | **`66-VERIFICATION.md`**; optional tweak **`REQUIREMENTS.md`** checkboxes when rows truly closed. |
| **2 — UAT rows mapped to existing gates** | For each of **UAT-01..UAT-05**, row up **`bash …` / `mix test …`** strings that **already** run in CI; mark which cells are **maintainer-signed** spot-checks vs **CI** (D-02a). | Same; **`STATE.md`** (clear **`Deferred Items`** UAT row per ROADMAP success criterion 2). |
| **3 — Gaps: thin scripts only** | If **UAT-04** (file existence) or **UAT-05** (P0+ROADMAP spot-check) needs a binary invariant, add **one** small `verify_*.sh` (or extend **`verify_v1_17_friction_research_contract.sh`**) + optional ExUnit mirror. | **`scripts/ci/*.sh`**; **`accrue/test/accrue/docs/*_test.exs`**; **`scripts/ci/README.md`** INT row if new contract; **`.github/workflows/ci.yml`** new step *only* if a new script must run in **docs-contracts-shift-left**. |
| **4 — PROOF-01** | Run local shift-left bundle; do semantic pass **matrix + evaluator walkthrough + host README**; fix contradictions; record commands + `workflow: CI; job: docs-contracts-shift-left` in **66-VERIFICATION** PROOF-01 row. | **`adoption-proof-matrix.md`**, **`evaluator-walkthrough-script.md`**, **`examples/accrue_host/README.md`**, **`verify_adoption_proof_matrix.sh`** (only with intentional matrix edits) |

**62-UAT.md:** Confirm existing banner satisfies D-03c; edit only if wording/anchors need tightening — **errata style**, not body rewrite.

---

## Validation Architecture

**Purpose:** Defend “proof” without running the **full** `release-gate` matrix on every local iteration.

### Sampling strategy

| Layer | What to run | When |
|-------|-------------|------|
| **A — Planning SSOT (fast, no BEAM DB)** | From repo root: the five **`docs-contracts-shift-left`** bash commands (see §2). | Every change touching **`.planning/research/*`**, **`STATE.md`**, **ROADMAP** anchors, or adoption docs. |
| **B — ExUnit doc contracts** | `cd accrue && mix test test/accrue/docs/v1_17_friction_research_contract_test.exs test/accrue/docs/organization_billing_org09_matrix_test.exs` (add paths if new mirrors appear). | After editing scripts mirrored by tests or when refactoring **`test/accrue/docs`**. |
| **C — Broader package docs tests** | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` (heavier, fixtures). | When root README, guides, or **`verify_package_docs.sh`** requirements change. |
| **D — Full CI equivalent** | Push / PR: GitHub **CI** workflow — merge-blocking includes **`docs-contracts-shift-left`** + **`release-gate`** + **`host-integration`** (see **`ci.yml`** header comments). | Before calling phase **execute** done; at minimum before merging **66** work. |

**Link to `docs-contracts-shift-left`:** It is the **single** bucket for package/adoption/VERIFY-01/v1.17 planning bash contracts. **66-VERIFICATION.md** “Automation” column should cite it explicitly (D-04b).

### Per-requirement: suggested automated vs manual proof

| ID | Primary automated signal (if any) | Manual / maintainer row |
|----|-----------------------------------|-------------------------|
| **UAT-01** | `verify_v1_17_friction_research_contract.sh` + `v1_17_friction_research_contract_test.exs` | Optional note that **62-UAT** scenario 1 is **superseded** by REQUIREMENTS; cite inventory rows “by inspection” only if script gaps remain. |
| **UAT-02** | Same script: **`STATE.md`** must contain **`.planning/research/v1.17-FRICTION-INVENTORY.md`** | Sign-off that pointer layout is still intentional after any **STATE** edit. |
| **UAT-03** | Same script: **`v1.17-north-star.md`**, **S1**/**S5** rows; **STATE** + **PROJECT** name **`v1.17-north-star.md`** | Optional extra doc read if you want explicit “S2–S4” narrative beyond **S1**/**S5** checks. |
| **UAT-04** | **Gap:** add **`[[ -f .planning/milestones/v1.17-REQUIREMENTS.md ]]`** to a **verify_** or maintainer **ls** in **66-VERIFICATION** | **PROJECT** / **STATE** do not contradict shipped **FRG/INT/BIL/ADM** (semantic read; no essay CI). |
| **UAT-05** | Partial: **ROADMAP** FRG-03 anchors to inventory backlogs; full P0 row ↔ inventory consistency may need **rg** + spot-check | Maintainer lists commands (e.g. `rg` on **`milestones/v1.17-phases/`** links, inventory **P0** rows) in **66-VERIFICATION**. |
| **PROOF-01** | `verify_adoption_proof_matrix.sh` + `organization_billing_org09_matrix_test.exs`; **`verify_package_docs.sh`** if README/matrix pins move | “Single sitting” read: matrix ↔ walkthrough ↔ host README; record reviewer + date in **66-VERIFICATION** or **STATE** if policy requires. |

**Full `mix test` / `release-gate`:** Still required for **unrelated** code changes; for **66** doc-only work, **A + B** often suffices until pre-merge **D**.

---

## 6. Open questions (minimal)

- **UAT-04 file check:** Add to **`verify_v1_17_friction_research_contract.sh`** (keeps v1.17 “bundle” in one place) vs new **`verify_v1_17_milestone_archives.sh`** — trade-off: one script vs. clearer name for archive-only invariants.
- **66-VERIFICATION frontmatter fields:** Match **63-VERIFICATION** (`status`, `phase`, `verified`) vs **D-04a** “yaml frontmatter + short scope” only — pick one template for v1.18 phases.
- **STATE `Deferred Items` table:** ROADMAP asks to clear the Phase **62** UAT gap when closed — exact row text TBD at execute (replace with “closed in 66” vs remove row).

## RESEARCH COMPLETE
