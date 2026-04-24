# Phase 76 — Pattern map

## PATTERN MAPPING COMPLETE

| Intended change | Analog | Excerpt / rule |
|-----------------|--------|----------------|
| Submodule for surface copy | `accrue_admin/lib/accrue_admin/copy/subscription.ex` | One function per string; `@moduledoc false`. |
| Facade `defdelegate` | `accrue_admin/lib/accrue_admin/copy.ex` | `alias AccrueAdmin.Copy.Subscription` + `defdelegate subscription_page_title(), to: Subscription`. |
| LiveView tab panel | `customer_live.ex` `"invoices"` branch | `h3.ax-heading` + `Copy.customer_detail_no_invoices()` empty pattern. |
| LiveView test | `customer_live_test.exs` invoices empty test | `assert html =~ Copy.customer_detail_no_invoices()`. |
