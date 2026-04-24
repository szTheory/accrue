# Plan 082-01 — Summary

## Objective

INT-13 integrator markdown: telemetry anchor for billing portal create, First Hour portal paragraph after checkout, adoption-proof-matrix blocking row, host README Observability + proof capsule pointer.

## Completed

- `accrue/guides/telemetry.md`: `<a id="billing-billing-portal-create"></a>` before `accrue.billing.billing_portal.create` (checkout-aligned pattern).
- `accrue/guides/first_hour.md`: Customer Portal helper sentence + paragraph with `Accrue.Billing.create_billing_portal_session/2`, `[:accrue, :billing, :billing_portal, :create]`, link to `telemetry.md#billing-billing-portal-create`.
- `examples/accrue_host/docs/adoption-proof-matrix.md`: sibling blocking row for portal facade + test path.
- `examples/accrue_host/README.md`: **Billing portal facade** bullet; proof opening line linking First Hour + both facade APIs + `#observability`.

## Self-Check

- `rg` acceptance criteria from PLAN.md: PASSED (manual).
- Merge-blocking verifiers: run after **082-02** landed CI needles — **`verify_package_docs.sh`** + **`verify_adoption_proof_matrix.sh`** exit **0**.

## key-files.created

- (none — edits only)

## key-files.modified

- `accrue/guides/telemetry.md`
- `accrue/guides/first_hour.md`
- `examples/accrue_host/docs/adoption-proof-matrix.md`
- `examples/accrue_host/README.md`
