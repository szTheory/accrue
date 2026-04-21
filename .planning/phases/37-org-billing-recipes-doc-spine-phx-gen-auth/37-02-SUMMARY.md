---
phase: 37
plan: "02"
status: complete
---

# Plan 37-02 Summary

## Objective

Make non-Sigra organization billing the default reading path from `auth_adapters.md` and `sigra_integration.md` without moving the full `Accrue.Auth` contract out of the adapter guide.

## Delivered

- `accrue/guides/auth_adapters.md` — new **Choosing an adapter (Sigra is optional)** hub after the opening framing, linking `organization_billing.md` and `sigra_integration.md`.
- `accrue/test/accrue/docs/community_auth_test.exs` — asserts hub strings and spine filename.
- `accrue/guides/sigra_integration.md` — **Not using Sigra?** callout before `## Add the dependency`.
- `accrue/test/accrue/docs/sigra_integration_guide_test.exs` — ordering guard (`Not using Sigra` before dependency section).

## Verification

- `mix test test/accrue/docs/community_auth_test.exs`
- `mix test test/accrue/docs/sigra_integration_guide_test.exs`
- `MIX_ENV=test mix docs`

## Self-Check: PASSED

## key-files.created

- accrue/test/accrue/docs/sigra_integration_guide_test.exs
