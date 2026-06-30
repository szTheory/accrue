---
phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress
plan: "13"
subsystem: ui
tags:
  - copy
  - microcopy
  - phoenix-liveview
  - phase199
dependency_graph:
  requires:
    - 199-11
    - 199-12
  provides:
    - detail-copy-call-site-contract
    - analytics-campaign-copy-helper-adoption
  affects:
    - accrue_admin/lib/accrue_admin/live/*_live.ex
    - accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex
tech_stack:
  added: []
  patterns:
    - AccrueAdmin.Copy.resource_state_copy/3 for detail empty and error states
    - AccrueAdmin.Copy.action_hidden_context/2 for hidden action labels
    - ExUnit source-contract tests for Copy helper adoption
key_files:
  created:
    - .planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-13-SUMMARY.md
  modified:
    - accrue_admin/test/accrue_admin/copy_test.exs
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/lib/accrue_admin/live/charge_live.ex
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/lib/accrue_admin/live/coupon_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
    - accrue_admin/lib/accrue_admin/live/event_live.ex
    - accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex
decisions:
  - Detail and campaign source contracts explicitly enumerate named files to close the wildcard checker gap.
  - Existing detail/domain Copy helpers were preserved while shared resource-state helpers were used for empty, error, and page-state copy.
  - Read-only Coupon, Promotion Code, and Event detail pages remain action-band-free while their empty and activity copy routes through Copy helpers.
requirements_completed:
  - CPY-01
  - IXN-01
  - IXN-03
metrics:
  started: 2026-06-30T02:05:09Z
  completed: 2026-06-30T02:16:35Z
  duration: 11m26s
  tasks: 1
  files_changed: 12
status: complete
---

# Phase 199 Plan 13: Detail and Analytics Copy Call-Site Sweep Summary

Detail and campaign copy call sites now resolve through Copy helper contracts with object-aware action context.

## Accomplishments

- Added a focused ExUnit source contract that enumerates every detail and analytics file named in the plan, proving they use the Copy/domain helper surface instead of relying on the wildcard checker.
- Routed detail empty, queue, and error copy through `Copy.resource_state_copy/3` across customer, invoice, charge, webhook, connect account, subscription, coupon, promotion code, event, and campaign pages.
- Added `Copy.action_hidden_context/2` to detail drawer, summary-list, replay/refund, and campaign subscription actions where the plan required object-aware hidden labels.
- Preserved read-only reference detail pages for Coupon, Promotion Code, and Event: they still have no action bands, detail drawers, step-up flows, or forms.

## Task Commits

| Task | Commit | Notes |
| --- | --- | --- |
| RED | `9ef93781` | Added failing source contract for named detail and campaign Copy helper call sites. |
| GREEN | `db868521` | Routed the named LiveViews through shared Copy helpers and preserved read-only page constraints. |

## Files Changed

| File | Change |
| --- | --- |
| `accrue_admin/test/accrue_admin/copy_test.exs` | Added CPY-01 source contract for detail and campaign Copy helper adoption. |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | Routed peer empty copy for subscriptions, invoices, and payments through resource-state helpers. |
| `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | Added action hidden context and invoice error copy from resource-state helpers. |
| `accrue_admin/lib/accrue_admin/live/charge_live.ex` | Added refund hidden context and payment helper copy for refund empty/error states. |
| `accrue_admin/lib/accrue_admin/live/webhook_live.ex` | Added replay hidden context and webhook/event queue helper copy. |
| `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` | Added action hidden context and connect account queue helper copy. |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | Added summary/action hidden context plus subscription and dunning helper copy. |
| `accrue_admin/lib/accrue_admin/live/coupon_live.ex` | Routed promotion-code and coupon empty/activity copy through helper-backed copy. |
| `accrue_admin/lib/accrue_admin/live/promotion_code_live.ex` | Routed coupon projection and promotion-code activity copy through helper-backed copy. |
| `accrue_admin/lib/accrue_admin/live/event_live.ex` | Routed event related-resource/activity copy and webhook source fallback through helpers. |
| `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` | Routed empty campaign state through dunning copy and added contextual subscription detail action copy. |

## Evidence

| Check | Result |
| --- | --- |
| RED test | `mix test test/accrue_admin/copy_test.exs --max-failures 5` exited nonzero as expected before implementation because campaign helper adoption was missing. |
| Focused test | `mix test test/accrue_admin/copy_test.exs --max-failures 5` passed with 12 tests and 0 failures. |
| Compile gate | `mix compile --warnings-as-errors` passed. |
| Helper proof | `rg "Copy\.resource_state_copy\|AccrueAdmin\.Copy\.resource_state_copy"` found required helper calls in every named detail and campaign file. |
| Action-context proof | `rg "Copy\.action_hidden_context\|AccrueAdmin\.Copy\.action_hidden_context"` found required hidden action context calls in the actionable detail and campaign files. |
| Read-only proof | `rg "data-ax-action-band\|DetailDrawer\|StepUp\|open_action_drawer\|phx-submit\|data-ax-action-drawer"` returned no matches for Coupon, Promotion Code, and Event detail pages. |

## Wildcard Checker Gap Proof

| Plan file | Copy/domain helper proof |
| --- | --- |
| `customer_live.ex` | `Copy.resource_state_copy(:subscriptions)`, `:invoices`, and `:payments`. |
| `invoice_live.ex` | `Copy.action_hidden_context/2` and `Copy.resource_state_copy(:invoices)`. |
| `charge_live.ex` | `Copy.action_hidden_context/2` and `Copy.resource_state_copy(:payments)`. |
| `webhook_live.ex` | `Copy.action_hidden_context/2`, `Copy.resource_state_copy(:webhooks)`, and `:events`. |
| `connect_account_live.ex` | `AccrueAdmin.Copy.action_hidden_context/2` and `AccrueAdmin.Copy.resource_state_copy(:connect_accounts)`. |
| `subscription_live.ex` | `Copy.action_hidden_context/2`, `Copy.resource_state_copy(:subscriptions)`, and `:dunning`. |
| `coupon_live.ex` | `AccrueAdmin.Copy.resource_state_copy(:coupons)` and `:promotion_codes`. |
| `promotion_code_live.ex` | `AccrueAdmin.Copy.resource_state_copy(:promotion_codes)` and `:coupons`. |
| `event_live.ex` | `Copy.resource_state_copy(:events)` and `:webhooks`. |
| `analytics/campaign_live.ex` | `Copy.resource_state_copy(:dunning)` and `Copy.action_hidden_context/2`. |

## Deviations from Plan

None - plan executed exactly as written.

## Auth Gates

None.

## Known Stubs

None. The stub scan found only existing form placeholders and default empty input values in action forms; no empty/mock rendering stubs were introduced.

## Threat Surface Scan

No new network endpoints, authentication paths, file access patterns, schema changes, or trust-boundary surfaces were introduced.

## TDD Gate Compliance

- RED gate commit present: `9ef93781`.
- GREEN gate commit present after RED: `db868521`.
- No refactor commit was needed.

## Self-Check: PASSED

- Found summary file on disk: `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-13-SUMMARY.md`.
- Found RED commit: `9ef93781`.
- Found GREEN commit: `db868521`.
