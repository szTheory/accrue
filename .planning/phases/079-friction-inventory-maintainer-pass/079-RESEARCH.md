# Phase 79 — Friction inventory maintainer pass — Research

**Question:** What do we need to know to plan **INV-03** well?

## Summary

**INV-03** is a post–**v1.24** maintainer pass on **`.planning/research/v1.17-FRICTION-INVENTORY.md`**. The requirement allows two mutually exclusive outcomes:

1. **Path (a):** Add **new sourced** **P1**/**P2** rows (full column contract, stable **`v1.17-P*-NNN`** ids, **append-only**) when ranked evidence on **`main`** warrants it. If row **counts** change, **`scripts/ci/verify_v1_17_friction_research_contract.sh`** must be updated **in the same PR** (hard asserts: 5 total rows, 2 P0, 2 P1, 1 P2 today).

2. **Path (b):** Publish a **dated maintainer certification** that no new sourced rows were warranted, with **falsifiable** pointers: one explicit **`main` merge commit SHA**, **`verify_package_docs`**, **`verify_adoption_proof_matrix.sh`**, and **VERIFY-01** / **`host-integration`** green on that tree.

**Canonical precedent:** **`### v1.20 evidence refresh (maintainer pass — 2026-04-24)`** in the same inventory file — normative paragraph + **revisit trigger**. Phase **70** verification (`.planning/milestones/v1.20-phases/70-friction-evidence-refresh/70-VERIFICATION.md`) shows the evidence-pack style for inventory passes.

## Implementation anchors

| Topic | Detail |
|-------|--------|
| SSOT | **`.planning/research/v1.17-FRICTION-INVENTORY.md`** — table + maintainer subsections; do not duplicate full inventory in ROADMAP |
| Row ids | **`v1.17-P0-NNN` / `P1-NNN` / `P2-NNN`** — never renumber; append only |
| Contract script | **`scripts/ci/verify_v1_17_friction_research_contract.sh`** — row counts, backlog headers, STATE/PROJECT/ROADMAP/north-star pointers |
| Certification split (CONTEXT D-04/D-05) | **Normative** one-paragraph cert **in inventory**; **`079-VERIFICATION.md`** holds methodology/commands and **links up** to inventory — no second independent “we certify” paragraph |
| SHA discipline | Single merge **SHA**, not a window; moving SHA implies re-running named verifiers |

## Verifier bundle (name in INV-03 + shift-left helpers)

Executor should capture command transcripts (or local exit codes) in **`079-VERIFICATION.md`**:

```bash
bash scripts/ci/verify_v1_17_friction_research_contract.sh
bash scripts/ci/verify_package_docs.sh
bash scripts/ci/verify_adoption_proof_matrix.sh
bash scripts/ci/verify_verify01_readme_contract.sh
```

**host-integration** is typically CI-orchestrated; if not runnable locally in one shot, document the **workflow job id** (`.github/workflows/ci.yml`) and the **exact SHA** verified in CI for the merge, consistent with project triage culture in **`scripts/ci/README.md`**.

## Pitfalls

- **Silent row-count drift:** Adding a row without updating **`verify_v1_17_friction_research_contract.sh`** breaks **`docs-contracts-shift-left`** — forbidden by INV-03.
- **Theater certification:** Dated text without SHA + named verifier bundle fails falsifiability.
- **Dual attestation:** Long independent certification in **`079-VERIFICATION.md`** that could drift from inventory — violates D-05; link + methodology only outside inventory.

## Open questions for executor (not blockers for planning)

- Whether **path (a)** or **(b)** is chosen depends on maintainer review of **`main`** after v1.24 ship — plans must support **either** outcome without presupposing the decision.

## Validation Architecture

**Dimension 8 (Nyquist) — feedback loops for this phase**

| Dimension | How satisfied |
|-----------|----------------|
| Structural inventory + script | **`verify_v1_17_friction_research_contract.sh`** after every edit to **`v1.17-FRICTION-INVENTORY.md`** (and after script edits if path (a)) |
| Doc-contracts cluster | **`verify_package_docs.sh`** when inventory or planning mirrors that affect package docs change |
| Matrix / VERIFY-01 prose | **`verify_adoption_proof_matrix.sh`**, **`verify_verify01_readme_contract.sh`** as named in INV-03 (b) |
| Phase evidence | **`079-VERIFICATION.md`** lists commands + SHA; first line points to inventory subsection for normative cert |

**Wave 0:** Not applicable — no new test framework; reuse existing bash gates.

**Sampling:** After each task that touches **`v1.17-FRICTION-INVENTORY.md`** or **`verify_v1_17_friction_research_contract.sh`**, run **`bash scripts/ci/verify_v1_17_friction_research_contract.sh`** from repo root (must print **`verify_v1_17_friction_research_contract: OK`**).

---

## RESEARCH COMPLETE
