# Phase 67: Proof contracts — Context

**Gathered:** 2026-04-23  
**Status:** Ready for execution planning

## Phase boundary

Deliver **PRF-01** and **PRF-02** for milestone **v1.19**: strengthen merge-blocking alignment between **`examples/accrue_host/docs/adoption-proof-matrix.md`** and **`scripts/ci/verify_adoption_proof_matrix.sh`**, and document the **matrix + script (+ ExUnit)** co-update rule in **`scripts/ci/README.md`**. This closes the **v1.17-P1-001** risk class (taxonomy edits that desync needles) **before** **Phase 68** Hex publish.

**Out of scope:** Changing **REL-** / **DOC-** / **HYG-** requirements except where a **PRF** edit must touch a shared literal (prefer minimal diffs).

## Inputs

- **`.planning/research/v1.17-FRICTION-INVENTORY.md`** — row **v1.17-P1-001**
- **`scripts/ci/verify_adoption_proof_matrix.sh`** — current `require_substring` needles
- **`examples/accrue_host/docs/adoption-proof-matrix.md`** — SSOT prose and headings
- **`accrue/test/accrue/docs/`** — any adoption-matrix / org-matrix ExUnit contracts that duplicate literals
- **`.planning/milestones/v1.18-REQUIREMENTS.md`** — **PROOF-01** definition (precedent)

## Success (phase)

1. CI fails on intentional matrix taxonomy edits until **script** (and tests, if any) are updated in the **same** change set (**PRF-01**).
2. **`scripts/ci/README.md`** triage section cites **`verify_adoption_proof_matrix.sh`** and states the co-update rule (**PRF-02**).
