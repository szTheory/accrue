# Phase 21 plan 05 — summary

- **Tenant chrome:** `AppShell` shows an `Active organization` banner when `@active_organization_name` is set (from `AccrueAdmin.AuthHook` via `OwnerScope.active_organization_banner_name/1`). Sidebar nav still preserves `?org=` via existing `current_path` parsing.
- **Session contract:** `OwnerScope` threads `active_organization_name` (optional); host sets `put_session(:active_organization_name, …)` in `UserAuth` default-org assignment and `OrganizationScopeController`.
- **Tax & ownership card:** New `TaxOwnershipCard` + `TaxOwnershipRow` helpers; detail pages (`CustomerLive`, `SubscriptionLive`, `InvoiceLive`, `ChargeLive`) render the card using `BillingPresentation`.
- **Tests:** `app_shell_test.exs`; detail LiveView tests assert `Tax &amp; ownership` in HTML; org-scoped `customer_live_test` asserts banner copy; `admin_mount_test` asserts forwarded session name and `organization_display_name` on `OwnerScope`.

Verification: `cd accrue_admin && mix test --warnings-as-errors test/accrue_admin/components/app_shell_test.exs test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs` and host `admin_mount_test.exs`.
