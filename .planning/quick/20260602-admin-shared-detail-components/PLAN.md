---
quick_id: 260602-l2n
slug: admin-shared-detail-components
status: complete
---

# Adopt shared Detail components across remaining admin detail screens

Apply the `AccrueAdmin.Components.Detail` pattern (already established in
`charge_live.ex`) to the five remaining detail LiveViews, for design-system
consistency. Conservative refactor — consistency, not redesign.

## Scope (accrue_admin/ only)
1. lib/accrue_admin/live/subscription_live.ex
2. lib/accrue_admin/live/customer_live.ex
3. lib/accrue_admin/live/invoice_live.ex
4. lib/accrue_admin/live/connect_account_live.ex
5. lib/accrue_admin/live/webhook_live.ex

## Approach per screen
- Replace bespoke summary/header markup with `Detail.summary_card` (status →
  `:status`, key facts → `:facts`, primary/secondary actions → `:actions`).
- Render flat label/value attribute lists with `Detail.detail_field_list`.
- Wrap titled content blocks in `Detail.detail_section` where it improves
  consistency without fighting existing structure.
- Reuse existing formatting helpers verbatim. Keep all phx-* handlers, forms,
  data-role/test-hook attrs, breadcrumbs, RelatedResources, StepUpAuthModal,
  TaxOwnershipCard, KpiCard.

## Verification (sequential — shared _build)
After EACH screen:
- `mix compile --warnings-as-errors`
- `mix test` (full suite)
Do not advance until both pass.

## Out of bounds
examples/, scripts/, .github/, accrue_portal/, accrue_admin router.ex.
Do NOT run asset build (no CSS changes).
