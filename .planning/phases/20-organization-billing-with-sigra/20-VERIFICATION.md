---
phase: 20-organization-billing-with-sigra
verified: 2026-04-17T21:01:31Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "Org-scoped admin KPI summaries now use owner-scoped queries."
    - "Webhook list pagination, poll counts, and bulk replay counts now scope before user-visible counts."
    - "Customer, subscription, webhook list, and app shell navigation now preserve `?org=`."
    - "Webhook detail Dashboard/Webhooks breadcrumbs and `current_path` now preserve organization scope."
  gaps_remaining: []
  regressions: []
---

# Phase 20: Organization Billing With Sigra Verification Report

**Phase Goal:** A Sigra-backed Phoenix host can bill the active organization, while Accrue's generic billable model remains the public ownership contract for non-Sigra hosts.
**Verified:** 2026-04-17T21:01:31Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A host organization schema can `use Accrue.Billable` and round-trip through `Accrue.Billing.customer/1` with `owner_type` and `owner_id` preserved. | ✓ VERIFIED | Phase contract in [.planning/ROADMAP.md](/Users/jon/projects/accrue/.planning/ROADMAP.md#L81); existing host proof remains aligned with Phase 20 artifacts and no new regressions were introduced in the current tree. |
| 2 | Sigra scope, membership, and active organization context drive the canonical host billing proof. | ✓ VERIFIED | Existing host proof remains intact. No current-tree changes touched the host-side Sigra scope flow, so the previously verified focused host proof remains the relevant regression evidence: `MIX_ENV=test mix test --warnings-as-errors test/accrue_host_web/org_billing_access_test.exs test/accrue_host_web/admin_webhook_replay_test.exs` -> 3 tests, 0 failures. |
| 3 | Org admins can create/view/manage billing only for their allowed active organization; cross-org access attempts fail server-side and are covered by tests. | ✓ VERIFIED | Cross-org denial is enforced and covered in [examples/accrue_host/test/accrue_host_web/org_billing_access_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/org_billing_access_test.exs#L11), [accrue_admin/test/accrue_admin/live/customer_live_test.exs](/Users/jon/projects/accrue/accrue_admin/test/accrue_admin/live/customer_live_test.exs#L155), [accrue_admin/test/accrue_admin/live/subscription_live_test.exs](/Users/jon/projects/accrue/accrue_admin/test/accrue_admin/live/subscription_live_test.exs#L153), and [accrue_admin/test/accrue_admin/live/webhook_live_test.exs](/Users/jon/projects/accrue/accrue_admin/test/accrue_admin/live/webhook_live_test.exs#L185). |
| 4 | Org-scoped admin KPI summaries use row-scoped owner filters instead of global counts. | ✓ VERIFIED | Customer KPIs scope through `scoped_customers/1` in [accrue_admin/lib/accrue_admin/live/customers_live.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customers_live.ex#L140); subscription KPIs scope through `scoped_subscriptions/1` in [accrue_admin/lib/accrue_admin/live/subscriptions_live.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscriptions_live.ex#L151); webhook KPIs scope through `Webhooks.count/2` in [accrue_admin/lib/accrue_admin/live/webhooks_live.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhooks_live.ex#L283). |
| 5 | Webhook pagination, polling counts, and bulk replay counts respect org scope before user-visible counts are shown. | ✓ VERIFIED | `list/1`, `count_newer_than/1`, `bulk_replay_count/2`, and `count/2` all scope rows before counts/pagination are exposed in [accrue_admin/lib/accrue_admin/queries/webhooks.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/webhooks.ex#L20); targeted coverage exists in [accrue_admin/test/accrue_admin/live/webhooks_live_test.exs](/Users/jon/projects/accrue/accrue_admin/test/accrue_admin/live/webhooks_live_test.exs#L72), and the focused current-tree admin suite passed: `mix test --warnings-as-errors test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhooks_live_test.exs` -> 8 tests, 0 failures. |
| 6 | Organization-scoped admin navigation preserves `?org=` across customers, subscriptions, webhook list/detail, and app shell navigation. | ✓ VERIFIED | Customer and subscription list/detail links remain scoped in [accrue_admin/lib/accrue_admin/live/customer_live.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex#L76) and [accrue_admin/lib/accrue_admin/live/subscription_live.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex#L113); app shell nav still derives `org` from `current_path` in [accrue_admin/lib/accrue_admin/components/app_shell.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/components/app_shell.ex#L17); and webhook detail now scopes both breadcrumb hrefs and `current_path` through `scoped_mount_path/4` and `scoped_admin_path/3` in [accrue_admin/lib/accrue_admin/live/webhook_live.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex#L111). |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue_admin/lib/accrue_admin/live/customers_live.ex` | Org-scoped customer KPIs and scoped customer links | ✓ VERIFIED | `customer_summary/1` filters by org owner id, and `customer_link/3` appends `?org=` for organization scope. |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | Scoped customer detail breadcrumbs, tabs, and subscription links | ✓ VERIFIED | Breadcrumbs, tab hrefs, and subscription detail links all use `scoped_mount_path/4`. |
| `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | Org-scoped subscription KPIs and scoped row links | ✓ VERIFIED | Summary queries join through customer owner scope; customer and subscription row links append `?org=`. |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | Scoped subscription detail breadcrumbs | ✓ VERIFIED | Detail breadcrumb/index links use the scoped helper. |
| `accrue_admin/lib/accrue_admin/queries/webhooks.ex` | Owner-scoped webhook list/poll/count/replay loaders | ✓ VERIFIED | List, poll counts, summary counts, and replay counts all scope via `scope_rows/2` and `prove_row_scope/2`. |
| `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` | Scoped webhook summary and detail links | ✓ VERIFIED | KPI summary calls scoped query functions and row links preserve `?org=`. |
| `accrue_admin/lib/accrue_admin/live/webhook_live.ex` | Scoped webhook detail navigation | ✓ VERIFIED | Breadcrumbs, activity-feed link, derived-event links, and assigned `current_path` all thread organization scope through the scoped helpers. |
| `accrue_admin/lib/accrue_admin/components/app_shell.ex` | App shell navigation preserves active org slug | ✓ VERIFIED | Sidebar links derive `org` from `current_path` and append it to all nav items. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `customers_live.ex` | customer detail | scoped `customer_link/3` | WIRED | Customer list row links preserve `?org=`. |
| `customer_live.ex` | customer tabs and subscription detail | `scoped_mount_path/4` | WIRED | Breadcrumbs, tabs, and nested subscription links preserve `?org=`. |
| `subscriptions_live.ex` | customer/subscription detail | `scoped_path/3` | WIRED | Both row-link paths preserve `?org=`. |
| `subscription_live.ex` | subscription index/dashboard | `scoped_mount_path/3` | WIRED | Subscription detail breadcrumbs preserve `?org=`. |
| `webhooks_live.ex` | webhook detail | `webhook_link/3` | WIRED | Webhook list row links preserve `?org=`. |
| `webhook_live.ex` | dashboard/webhook index | `scoped_mount_path/4` breadcrumb hrefs and scoped `current_path` | WIRED | Dashboard and Webhooks breadcrumb links, plus the page `current_path`, preserve `?org=<slug>` from `current_owner_scope`. |
| `AppShell.app_shell/1` | sidebar navigation | `org_slug(current_path)` -> `nav_href/3` | WIRED | Shell links preserve the current org slug across sections. |
| `DataTable` | webhook polling banner | `count_newer_than/1` with `owner_scope` | WIRED | Poll path threads `current_owner_scope` into query options before counting newer rows. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `customers_live.ex` | `@summary` | `customer_summary/1` -> scoped Ecto aggregates | Yes | ✓ FLOWING |
| `subscriptions_live.ex` | `@summary` | `subscription_summary/1` -> scoped Ecto aggregates | Yes | ✓ FLOWING |
| `webhooks_live.ex` | `@summary`, DataTable rows | `Webhooks.count/2`, `bulk_replay_count/2`, `list/1` | Yes | ✓ FLOWING |
| `app_shell.ex` | `@nav_items` | `org_slug(current_path)` -> `nav_href/3` | Yes | ✓ FLOWING |
| `webhook_live.ex` | breadcrumb hrefs, activity links, `@current_path` | `@current_owner_scope` -> `scoped_mount_path/4` and `scoped_admin_path/3` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused admin regressions for webhook scope, breadcrumbs, and replay | `cd accrue_admin && mix test --warnings-as-errors test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhooks_live_test.exs` | `8 tests, 0 failures` | ✓ PASS |
| Host-mounted denial and replay proof | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host_web/org_billing_access_test.exs test/accrue_host_web/admin_webhook_replay_test.exs` | `3 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `ORG-01` | `20-01-PLAN.md` | Host app can make an organization billable using Accrue's existing ownership model. | ✓ SATISFIED | Phase 20 host organization billing proof remains intact and unregressed. |
| `ORG-02` | `20-02-PLAN.md` | Sigra-backed host flow can bill the active organization while preserving membership and admin scope boundaries. | ✓ SATISFIED | Focused host tests still pass and cross-org denial remains enforced. |
| `ORG-03` | `20-03` through `20-06` | Org admins cannot access or mutate another organization's billing state through public, admin, webhook replay, or export paths. | ✓ SATISFIED | Cross-org loader denial and replay blocking are covered in admin and host tests. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `accrue_admin/lib/accrue_admin/queries/webhooks.ex` | 30 | `Repo.all()` before in-memory org scoping | ⚠️ Warning | Functionally correct for the current gap set, but webhook list/count paths still scan/filter in memory rather than proving scope in SQL. |

### Gaps Summary

No remaining Phase 20 gaps were found in this re-verification pass. The final webhook detail navigation issue is closed: Dashboard/Webhooks breadcrumbs and the page `current_path` now preserve organization scope, and the focused admin webhook suite passes against the current tree.

---

_Verified: 2026-04-17T21:01:31Z_
_Verifier: Claude (gsd-verifier)_
