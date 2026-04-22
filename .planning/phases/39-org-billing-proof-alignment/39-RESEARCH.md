# Phase 39 — Technical Research

**Phase:** 39 — Org billing proof alignment  
**Question:** What do we need to know to **plan** ORG-09 (adoption matrix + verifier ownership) without diluting VERIFY-01?

## Findings

### Policy already in repo

- **`examples/accrue_host/docs/adoption-proof-matrix.md`** splits **blocking** (Fake + deterministic CI) vs **advisory** (live Stripe). ORG-09 must **extend** this doc, not redefine VERIFY-01.
- **`scripts/ci/verify_verify01_readme_contract.sh`** already pins README substrings including `docs/adoption-proof-matrix.md`. Per **D-11** (CONTEXT), new matrix invariants belong in a **dedicated** script `scripts/ci/verify_adoption_proof_matrix.sh`, not as a second awk taxonomy inside the VERIFY-01 script.
- **`host-integration`** (`.github/workflows/ci.yml`) already runs `verify_verify01_readme_contract.sh` first — the natural home for an additional bash gate with the same triage story as ADOPT-02.
- **`scripts/ci/README.md`** uses a four-column table for ADOPT rows; ORG-09 needs a **parallel** `## ORG gates (v1.8 org billing proof)` subsection (**D-14**) so REQ-ID namespaces stay legible.

### Honesty / least-surprise (ORG-09 wording)

- **Non-Sigra** in ORG-09 means **identity + billable resolution** per `guides/organization_billing.md` (`Accrue.Auth`, `Accrue.Billable`, host facade) — **not** a promise that `examples/accrue_host` drops Sigra as a demo implementation (**D-02**). Matrix prose must say this explicitly to avoid “repo is Sigra-free” misreads.

### Executable vs prose-only blocking

- Any row labeled merge-adjacent **blocking** must name a **verifier that fails CI** when content drifts (**D-07**). The new bash script is the primary machine owner; optional **ExUnit wrapper** (mirror `phase_31_nyquist_validation_test.exs`) is a **release-gate** safety net if we want `accrue` package CI to catch “script deleted” — **D-12** is discretionary.

### Doc-test cross-links (accrue package)

- **`accrue/test/accrue/docs/organization_billing_guide_test.exs`** is the established needle list for `organization_billing.md`. ORG-09 should add **minimal literals** tying the guide to the matrix / ORG-09 headings so `mix test` in `accrue` catches broken cross-navigation without new Playwright (**D-06**, **D-20**).

### Risks

- **Verifier duplication:** keep VERIFY-01 script narrow; matrix semantics live only in `verify_adoption_proof_matrix.sh`.
- **Table drift:** bash checks should key off **stable substrings** agreed in PLAN-01, not free-form prose.

## Validation Architecture

This phase is **documentation + bash + lightweight ExUnit**; automated feedback must prove (1) matrix contains ORG-09 semantics and stable needles, (2) new bash verifier passes on green tree, (3) CI invokes it in `host-integration`, (4) contributor map lists ORG-09 with triage hints, (5) guide doc-test needles stay green.

### Dimension 8 — Doc, script, and CI sampling

| Dimension | Signal | Instrument |
|-----------|--------|------------|
| Matrix ORG-09 | Required headings / literals / archetype honesty | `verify_adoption_proof_matrix.sh` + `rg` on `adoption-proof-matrix.md` |
| VERIFY-01 isolation | README contract script unchanged except optional single pin | `bash scripts/ci/verify_verify01_readme_contract.sh` |
| Contributor map | ORG subsection + ORG-09 row | `rg` on `scripts/ci/README.md` |
| CI wiring | Script runs in `host-integration` | `.github/workflows/ci.yml` grep |
| Guide needles | ORG-09 cross-link literals | `mix test test/accrue/docs/organization_billing_guide_test.exs` |

### Manual-only (acceptable)

- Evaluator readability of matrix tables — human spot-check at SUMMARY time.

---

## RESEARCH COMPLETE

*Phase 39 — research synthesized 2026-04-21 for `/gsd-plan-phase 39`.*
