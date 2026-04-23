---
status: passed
phase: 64-p0-billing
verified: "2026-04-23"
---

# Phase 64 — P0 billing verification

Scope: close **BIL-03** for **v1.17** using the inventory section at Markdown link **[### Backlog — BIL-03 (Phase 64)](../../research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64)** in **`v1.17-FRICTION-INVENTORY.md`**. This file is the traceability SSOT for merge-blocking proof on the empty billing **P0** queue path (no **Accrue.Billing** / Fake / **CHANGELOG** / telemetry doc churn this milestone).

| Row ID | Acceptance one-liner | Merge-blocking proof | CI vs manual | Closure status |
|--------|------------------------|----------------------|--------------|----------------|
| BIL-03 | If billing-tagged **P0** rows exist they ship bounded **Accrue.Billing** / **Fake** / **`accrue/guides/telemetry.md`** / **`CHANGELOG`** per **BIL-03**; this milestone has **no such rows** — the inventory documents the empty queue plus maintainer certification (see **`64-VERIFICATION.md`** and the **`### Backlog — BIL-03`** subsection). | `bash scripts/ci/verify_v1_17_friction_research_contract.sh`; `cd accrue && mix test test/accrue/docs/v1_17_friction_research_contract_test.exs` | CI + local manual | closed |
