---
phase: 82
slug: first-hour-portal-spine
requirements: [INT-13]
status: passed
---

# Phase 82 — Verification (INT-13)

**Signed-off commit:** run `git rev-parse HEAD` at verification time and paste the SHA here (maintainer record).

## Merge-blocking commands

From repository root; expect **`verify_package_docs.sh`** to end with **`package docs verified`** and **`verify_adoption_proof_matrix.sh`** to print **`verify_adoption_proof_matrix: OK`** on the last line.

```bash
bash scripts/ci/verify_package_docs.sh
bash scripts/ci/verify_adoption_proof_matrix.sh
```

## Traceability

| Area | Evidence |
|------|----------|
| **INT-13** | `accrue/guides/telemetry.md` anchor `#billing-billing-portal-create`; **First Hour** + host README + adoption matrix carry **`Accrue.Billing.create_billing_portal_session/2`** and **`[:accrue, :billing, :billing_portal, :create]`**; CI needles in **`verify_package_docs.sh`** + **`verify_adoption_proof_matrix.sh`**. |
| **INT-11** | **082-01** markdown spine and **082-02** script/CHANGELOG updates land in the **same PR** when literals or verifier paths change. |
