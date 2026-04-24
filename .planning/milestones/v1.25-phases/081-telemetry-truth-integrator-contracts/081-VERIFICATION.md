# Phase 81 — Verification (BIL-07, INT-12)

**Completed:** 2026-04-24  
**Context:** [`081-CONTEXT.md`](081-CONTEXT.md)

## Requirements

| ID | Evidence |
|----|----------|
| **BIL-07** | `accrue/guides/telemetry.md` — `accrue.billing.checkout_session.create` / `[:accrue, :billing, :checkout_session, :create]` catalog row, anchor `#billing-checkout-session-create`, allowlisted metadata + cardinality note; **`Last reconciled (billing span examples)`** stamp. `accrue/guides/operator-runbooks.md` — Stripe verification bullet checkout pointer + Fake vs live + anchor link. `accrue/CHANGELOG.md` — Unreleased bullets (telemetry/docs/CI). `billing_span_coverage_test.exs` unchanged (per **D-06**). |
| **INT-12** | Same PR: `accrue/guides/first_hour.md`, `examples/accrue_host/README.md`, `examples/accrue_host/docs/adoption-proof-matrix.md` name **`Accrue.Billing.create_checkout_session/2`** and **`[:accrue, :billing, :checkout_session, :create]`**; `scripts/ci/verify_package_docs.sh` + `scripts/ci/verify_adoption_proof_matrix.sh` needles extended. |

## Commands (merge-blocking subset)

```bash
bash scripts/ci/verify_package_docs.sh
bash scripts/ci/verify_adoption_proof_matrix.sh
```

## ExUnit (when PostgreSQL test role is available)

```bash
cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs \
  test/accrue/telemetry/billing_span_coverage_test.exs \
  test/accrue/billing/checkout_session_facade_test.exs
```

Local agent run: **`verify_*` scripts OK**; full **`mix test`** blocked here on missing `postgres` DB role (environment).
