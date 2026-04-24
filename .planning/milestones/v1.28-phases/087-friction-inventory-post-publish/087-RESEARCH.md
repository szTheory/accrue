# Phase 87 — Friction inventory post-publish — Research

**Question:** What do we need to know to plan **INV-06** well after **v1.28** **PPX-05..08** (Phase **86**)?

## Findings

### CI truth vs frozen prose lists

Merge-blocking job **`docs-contracts-shift-left`** in **`.github/workflows/ci.yml`** (lines **30–54** at current **main**) runs these steps in order:

1. `bash scripts/ci/verify_package_docs.sh`
2. `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
3. `bash scripts/ci/verify_verify01_readme_contract.sh`
4. `bash scripts/ci/verify_production_readiness_discoverability.sh`
5. `bash scripts/ci/verify_adoption_proof_matrix.sh`
6. `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh`

**087-CONTEXT** **D-08** requires **`087-VERIFICATION.md`** to snapshot **exactly** this membership **as at the reviewed commit SHA** (not **085**’s five-script list, which predates **`verify_core_admin_invoice_verify_ids.sh`**).

### Evidence posture (086 vs 087)

**086-VERIFICATION.md** already documents **PPX** machine contract and local green on SHA **`a533474e6928f7ea3656c5182754d1ebafabd93d`**. Per **087-CONTEXT** **D-04** / **D-05**, **087** may **pointer-reference** **086** for duplicate shift-left transcripts **unless** **`.github/workflows/ci.yml`** **`docs-contracts-shift-left`** steps changed between **86**’s SHA and **87**’s reviewed SHA **or** **86** documented an automation gap **87** closes.

Separate job **`release-manifest-ssot`** runs **`bash scripts/ci/verify_release_manifest_alignment.sh`**. **087-CONTEXT** **D-09**: cite **`release-manifest-ssot`** green at the same SHA **only** when Phase **86** touched Release Please / manifest semantics; otherwise pointer-only if **86** already proved it.

**`host-integration`** is merge-blocking and **`needs`** **`docs-contracts-shift-left`**. Canonical step is **`bash scripts/ci/accrue_host_uat.sh`** (plus conditional **`accrue_host_hex_smoke.sh`** on **CI**). **INV-06** evidence should name **`host-integration`** green at reviewed SHA (Actions URL or explicit note that **PR** replay matches job intent per **087-CONTEXT** **D-06**).

### Inventory subsection pattern

Follow **v1.27 INV-05** block: heading **`### v1.28 INV-06 maintainer pass (YYYY-MM-DD)`** only (no SemVer in **`###`** per **D-02**); first paragraph ties **post-PPX** context; **FRG-02** **S1**/**S5** path **(b)** certification; pointer to **`087-VERIFICATION.md`**; **revisit triggers** including **083**-family bullets + **D-11** **PPX-08**-class mirror mismatch bullet (requirement id + outcome, no path enumeration).

Append **after** **`### v1.27 INV-05 maintainer pass (2026-04-24)`** per **D-14**.

### Path (a) vs (b)

Default **(b)** — no new sourced **P1**/**P2** rows unless **FRG-01** bar cleared. **(a)** only if adding stable row ids **and** **`verify_v1_17_friction_research_contract.sh`** co-update same PR (**079** **D-02**).

## Validation Architecture

**Dimension 8 (Nyquist):** This phase is **documentation + planning SSOT**; runtime is proven by existing merge-blocking **CI**. Validation during execution:

| Layer | Role |
|-------|------|
| **Bash contracts** | The six **`docs-contracts-shift-left`** scripts + **`verify_v1_17_friction_research_contract.sh`** on the **frozen reviewed SHA** prove doc/research coherence. |
| **CI jobs** | **`docs-contracts-shift-left`** + **`host-integration`** (and **`release-manifest-ssot`** when **D-09** applies) green at that SHA prove integrator-visible gates. |
| **Inventory contract** | **`verify_v1_17_friction_research_contract.sh`** exit **0** after subsection append proves table/anchor invariants. |

**Sampling:** After inventory edit and after **`087-VERIFICATION.md`** finalization, re-run **`bash scripts/ci/verify_v1_17_friction_research_contract.sh`** from repo root. Before declaring phase complete, confirm **`087-VERIFICATION.md`** contains **`Reviewed commit SHA:`** (or **`Reviewed merge SHA:`**) with **40-char** lowercase hex and enumerated script snapshot matching **`.github/workflows/ci.yml`** at that SHA.

**Manual-only:** Maintainer judgment for path **(b)** prose (no automated test for “no new P1/P2 warranted”).

---

## RESEARCH COMPLETE
