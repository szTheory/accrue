---
phase: 38-org-billing-recipes-pow-custom-org-boundaries
plan: 01
subsystem: docs
tags: [pow, organization-billing, accrue-auth, guides]

requires: []
provides:
  - ORG-07 Pow-oriented checklist in organization_billing.md
  - Cross-link from auth_adapters MyApp.Auth.Pow section
  - Contract-test needles for ORG-07 literals
affects: []

tech-stack:
  added: []
  patterns:
    - "Pow identity is separate from membership-gated active organization"

key-files:
  created: []
  modified:
    - accrue/guides/organization_billing.md
    - accrue/guides/auth_adapters.md
    - accrue/test/accrue/docs/organization_billing_guide_test.exs

key-decisions:
  - "ORG-03 intro uses contiguous Phase 38 substring for doc contract tests."

patterns-established:
  - "Pow checklist mirrors phx.gen.auth shape without implying Pow infers org tenancy."

requirements-completed: [ORG-07]

duration: 25min
completed: 2026-04-21
---

# Phase 38 plan 01 summary

**Pow-oriented ORG-07 recipe is now a first-class subsection of the organization billing spine, with auth_adapters cross-navigation and executable needle tests.**

## Task commits

1. **Task 1: Pow checklist** — `fe9ecd5` (docs)
2. **Task 2: auth_adapters link** — `8f3ee5f` (docs)
3. **Task 3: guide tests + Phase 38 anchor** — `4152f48` (test)

## Self-Check: PASSED

- `cd accrue && mix test test/accrue/docs/organization_billing_guide_test.exs`
- `cd accrue && MIX_ENV=test mix docs`
