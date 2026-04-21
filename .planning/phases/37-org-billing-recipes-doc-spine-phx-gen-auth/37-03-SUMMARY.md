---
phase: 37
plan: "03"
status: complete
---

# Plan 37-03 Summary

## Objective

Wire discoverability for the organization billing spine (installer scrollback, README, quickstart, finance-handoff) and regression-test installer/README literals.

## Delivered

- `accrue/lib/mix/tasks/accrue.install.ex` — `print_auth_guidance/1` non-Sigra branch prints stable `guides/organization_billing.md` and `guides/auth_adapters.md` pointers.
- `accrue/README.md` — **Start here** bullet for organization billing (non-Sigra).
- `accrue/guides/quickstart.md` — **Focused guides** entry for the same spine.
- `accrue/guides/finance-handoff.md` — cross-link before Stripe RR section for billable ownership context.
- `accrue/test/accrue/docs/organization_billing_guide_test.exs` — installer clause + README substring tests.

## Verification

- `mix compile --warnings-as-errors`
- `mix test test/accrue/docs/organization_billing_guide_test.exs test/accrue/docs/community_auth_test.exs test/accrue/docs/sigra_integration_guide_test.exs`
- `MIX_ENV=test mix docs`

## Self-Check: PASSED

## key-files.modified

- accrue/lib/mix/tasks/accrue.install.ex
- accrue/README.md
- accrue/guides/quickstart.md
- accrue/guides/finance-handoff.md
- accrue/test/accrue/docs/organization_billing_guide_test.exs
