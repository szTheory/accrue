---
status: passed
phase: 63-p0-integrator-verify-docs
verified: "2026-04-23"
---

# Phase 63 — P0 integrator / VERIFY / docs verification

Scope: close **INT-10** backlog items **`v1.17-P0-001`** and **`v1.17-P0-002`** from [### Backlog — INT-10 (Phase 63)](../../research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63) in **`v1.17-FRICTION-INVENTORY.md`**. This file is the traceability SSOT for merge-blocking proof tied to plans **63-01** and **63-02**.

| Row ID | Acceptance one-liner | Merge-blocking proof | CI vs manual | Closure status |
|--------|------------------------|----------------------|--------------|----------------|
| v1.17-P0-001 | Integrators can skim Hex vs branch, workspace lockstep, and pre-1.0 lockfile discipline without a third numeric SSOT | `bash scripts/ci/verify_package_docs.sh`; `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | CI (`verify_package_docs` job) + local manual | closed |
| v1.17-P0-002 | Host-integration failures name the failing phase via `[host-integration]` and a single `FAILED_GATE=host-integration` banner on wrapper failure | `bash scripts/ci/accrue_host_uat.sh` (delegates to `examples/accrue_host` `mix verify.full`); `rg '\[host-integration\] phase=' scripts/ci/accrue_host_verify_*.sh` | CI (`host-integration` job) + local manual | closed |
| INT-10 | P0 integrator / VERIFY / docs closure for FRG-03 INT-10 slice | Same commands as **v1.17-P0-001** and **v1.17-P0-002** above; `bash scripts/ci/verify_v1_17_friction_research_contract.sh`; `cd accrue && mix test test/accrue/docs/v1_17_friction_research_contract_test.exs` | CI + local manual | closed |
