---
created: 2026-06-21T15:54:29.309Z
title: Shared page_header component for accrue_admin list pages
area: ui
files:
  - accrue_admin/lib/accrue_admin/components/detail.ex (summary_card — the detail-page analog)
  - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex (representative list page)
  - accrue_admin/lib/accrue_admin/components/breadcrumbs.ex
---

## Problem

After quick task `260620-qkx` (de-duplicate orientation chrome), every list/index
LiveView still renders its page header inline as duplicated markup:
`Breadcrumbs.breadcrumbs` + `<h1 class="ax-display">…</h1>` + `<p class="ax-body
ax-page-copy">…</p>`. The chrome cleanup removed the redundant eyebrows and promoted
each hero to a single `<h1>`, but left the structure copy-pasted across ~9 list pages
+ dashboard/analytics. Future header changes mean editing every page; the
single-`<h1>` + breadcrumb→hero→copy contract isn't locked into the design system.

## Solution

Extract a shared `AccrueAdmin.Components.PageHeader` Phoenix.Component (the
list/index-page equivalent of the existing `Detail.summary_card` hero on detail
pages): attrs for breadcrumb `items`, `title` (renders the single `<h1 class="ax-display">`),
and `description`/copy slot. Refactor the ~9 list pages + dashboard/analytics to use
it. Light test updates expected in `navigation_components` + per-page live tests.

Non-urgent design-system tightening — do when next touching admin page headers.
Note: keep exactly one content `<h1>` per page (axe "page-has-heading-one" guardrail).
TBD: whether to fold the breadcrumb into the component or keep it a sibling.
