# Requirements: Accrue

## Milestone: v1.45 — Multi-channel Dunning (In-App Banners)

Current focus: **In-App Banners**. Expand dunning beyond email by providing an idiomatic Phoenix LiveView component and API helper for displaying "Update your card" banners directly within the host application.

### Public API & Core Math (BAN)

- [ ] **BAN-01** — Dunning state public API.
  - `Accrue.Dunning.requires_attention?(customer_id)` (or equivalent signature) returns a boolean indicating if the customer is currently in an active dunning campaign that requires action.
  - Optionally returns `{:true, campaign}` to allow the host app to customize the message.
  - Uses the ledger as the source of truth (via `Accrue.Billing.Query.in_active_dunning_campaign/1` or similar, avoiding projection lag false positives).

- [ ] **BAN-02** — Headless Dunning Banner Component.
  - `Accrue.Components.DunningBanner` or `AccrueWeb.Components.DunningBanner` HEEx component.
  - Headless/minimally styled so host apps can drop it into `app.html.heex` or root layouts without dictating CSS.
  - Automatically queries `requires_attention?/1` if a customer is passed in.

### Documentation & Adopter Proof (BAN)

- [ ] **BAN-03** — Integration Documentation.
  - `guides/dunning.md` is updated with a section on "In-App Banners".
  - Examples showing how to mount the component or use the helper in a Phoenix app.

- [ ] **BAN-04** — Adopter-proof matrix row + example-host wiring.
  - The `examples/accrue_host` app demonstrates the banner in its UI when the test user is in dunning.

### Out of Scope
- **SMS/Push via Chimeway** — explicit non-goal; high compliance risk.
- **Rich Metered/Tiered Entitlement Math** — explicit non-goal; overbuilding.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BAN-01 | Phase 149 | Planned |
| BAN-02 | Phase 149 | Planned |
| BAN-03 | Phase 150 | Planned |
| BAN-04 | Phase 150 | Planned |
