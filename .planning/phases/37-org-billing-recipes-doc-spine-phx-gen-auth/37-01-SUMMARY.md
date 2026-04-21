---
phase: 37
plan: "01"
status: complete
---

# Plan 37-01 Summary

## Objective

Ship the canonical non-Sigra organization billing guide and a contract test locking ORG-05/ORG-06 narrative anchors.

## Delivered

- `accrue/guides/organization_billing.md` — vertical spine: audience, session→org→billable, ORG-03 table (public/admin/webhook replay/export), minimal host model, phx.gen.auth checklist, bounded User-as-billable aside, `examples/accrue_host` reference table, footguns, related guides. ORG-03 canonical link points at repo `v1.3-REQUIREMENTS.md` so ExDoc does not warn on missing `.planning` paths.
- `accrue/test/accrue/docs/organization_billing_guide_test.exs` — substring guard for mandatory doc anchors.

## Verification

- `cd accrue && mix test test/accrue/docs/organization_billing_guide_test.exs` — pass
- `cd accrue && MIX_ENV=test mix docs` — pass

## Self-Check: PASSED

## key-files.created

- accrue/guides/organization_billing.md
- accrue/test/accrue/docs/organization_billing_guide_test.exs
