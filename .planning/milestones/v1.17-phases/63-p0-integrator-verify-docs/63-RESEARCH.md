# Phase 63 — Technical Research

**Question:** What do we need to know to plan **INT-10** / **v1.17-P0-001** and **v1.17-P0-002** well?

## Findings

### P0-001 — Pins, Hex honesty, First Hour

- **SSOT:** `scripts/ci/verify_package_docs.sh` already extracts `@version` from `accrue/mix.exs` and `accrue_admin/mix.exs`, requires lockstep equality, and `require_fixed` pins `{:accrue, "~> $accrue_version"}` / `{:accrue_admin, "~> $accrue_admin_version"}` in `accrue/guides/first_hour.md` plus `> **Hex vs `main`:**` blocks in package READMEs and root README.
- **Gap vs intent:** Inventory row **v1.17-P0-001** calls out integrator confusion on **pre-1.0** and **Hex vs `path:`**. First Hour already has a Hex-vs-main callout and lockfile sentence; remaining work is **tightening skimmable prose** (three facts: Hex story, workspace alignment, pre-1.0 + lockfile) without introducing a third numeric SSOT (no badges/version tables outside enforced literals).
- **Dual snippet:** Optional **Hex** + **`path:`** blocks are allowed only if extended `require_fixed` / `require_any_fixed` keeps both honest — mirror patterns from small Hex libs if pursued.

### P0-002 — `host-integration` discoverability

- **Current shape:** `.github/workflows/ci.yml` job **`host-integration`** runs `bash scripts/ci/accrue_host_uat.sh`, which prints `=== Accrue host UAT ===` then delegates to `examples/accrue_host` **`mix verify.full`**. That alias chains: `verify.install` → bounded script → `verify` → regression → dev boot → browser scripts (`scripts/ci/accrue_host_verify_*.sh`).
- **Gap:** Sub-scripts (`accrue_host_verify_test_bounded.sh`, `accrue_host_verify_test_full.sh`, `accrue_host_verify_dev_boot.sh`, `accrue_host_verify_browser.sh`) emit **no** consistent stderr prefix naming which gate failed; first failure is often a raw `mix test` or Playwright line.
- **Lever (D-02a):** Add a **single prefix family** (e.g. **`[host-integration]`**) at the start of each sub-phase (and optionally a **`FAILED_GATE=...`** line on `ERR` from the repo-root wrapper) so the **first scroll** maps to one contract. Align mentally with **`[verify_package_docs]`** / **`verify_v1_17_friction_research_contract:`** style already documented in `scripts/ci/README.md`.
- **Docs (D-02b):** Extend `scripts/ci/README.md` with a **short** subsection: prefix → meaning → link to `examples/accrue_host/README.md#proof-and-verification`. Do not duplicate full `ci.yml` job inventory.

### Governance (D-03)

- Closure updates **`v1.17-P0-001` / `v1.17-P0-002`** rows: `status`, signed **`notes`**, without breaking **`verify_v1_17_friction_research_contract.sh`** needles (four inventory rows, two P0 with `| INT-10 |` and `| →63 |`, backlog anchors).
- **`REQUIREMENTS.md`** **INT-10** checkbox flips only when evidence exists in **`63-VERIFICATION.md`** + committed rows.

### Traceability artifact (D-04)

- **`63-VERIFICATION.md`:** Scope pointer to inventory **### Backlog — INT-10**, table rows for **v1.17-P0-001**, **v1.17-P0-002**, rollup **INT-10**, merge-blocking proof commands, CI vs manual split — lean, no essay-length `ci.yml` restatement.

## Risks / non-goals

- **No** `host-integration` job split in Phase 63 (defer per CONTEXT D-02c).
- **No** billing (**BIL-03**) or admin LiveView (**ADM-12**) scope.

## Validation Architecture

Phase 63 validation is **bash-contract + ExUnit smoke** aligned with prior INT phases:

| Dimension | Approach |
|-----------|----------|
| **Doc / pin truth** | `bash scripts/ci/verify_package_docs.sh` (merge-blocking in docs lane) + `mix test accrue/test/accrue/docs/package_docs_verifier_test.exs` |
| **Planning SSOT** | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` + `mix test accrue/test/accrue/docs/v1_17_friction_research_contract_test.exs` |
| **VERIFY-01 depth** | `bash scripts/ci/verify_verify01_readme_contract.sh` when host README sections touched |
| **Host lane** | Local repro: `bash scripts/ci/accrue_host_uat.sh` (CI-equivalent entrypoint); after prefix work, log greps for `[host-integration]` prove discoverability |
| **Sampling** | After each plan wave: `mix test test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/v1_17_friction_research_contract_test.exs` from `accrue/`; full doc contract: `bash scripts/ci/verify_package_docs.sh` |

Nyquist Dimension 8 (continuous verification) is satisfied by keeping **existing** verifier tests green and adding **grep-stable** log-prefix acceptance where new behavior is introduced.

---

## RESEARCH COMPLETE
