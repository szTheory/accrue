---
created: 2026-06-19T20:06:14Z
completed: 2026-07-03
title: White-label billing portal design system
area: ui
status: complete
files:
  - accrue_portal/lib/accrue_portal/live/home_live.ex
  - accrue_portal/lib/accrue_portal/live/subscriptions_live.ex
  - accrue_portal/lib/accrue_portal/live/payment_methods_live.ex
  - accrue_portal/lib/accrue_portal/live/invoices_live.ex
  - accrue_portal/priv/static/accrue_portal.css
  - examples/accrue_host/lib/accrue_host/demo_brand.ex
---

## Problem

The mounted customer billing portal at `/billing` is provided by `accrue_portal`,
so it should be white-label friendly while still looking polished out of the box.
During CohortFlow UAT, the portal showed correct seeded billing data, but the UI
felt under-designed compared with the host demo brand. The portal should be able
to adopt host/demo brand colors and identity so the CohortFlow example proves the
white-label story instead of looking like a disconnected generic package screen.

Concrete observed issue: `/billing/subscriptions` renders `View details` as an
unstyled plain anchor:

```html
<a href="/billing/subscriptions/...">View details</a>
```

That link should use a portal button/action component style. This is a symptom of
a broader missing portal design-system pass: links, buttons, metrics, cards,
lists, empty states, detail pages, and navigation should have consistent,
brandable component primitives.

## Solution

Plan a future `accrue_portal` design-system and white-label pass:

- Define the brand contract for mounted portals: which values come from Accrue
  defaults, which can be overridden by host apps, and how `examples/accrue_host`
  supplies the CohortFlow brand.
- Make the CohortFlow demo portal use the same brand colors/feel as the rest of
  the example app while keeping the portal generic enough for other hosts.
- Add reusable portal component classes/patterns for primary buttons, secondary
  buttons, inline links, action groups, metric tiles, lists, empty states, detail
  sections, and forms.
- Replace the unstyled `View details` link on `/billing/subscriptions` with the
  appropriate action component.
- Add visual/UI regression coverage for the portal dashboard, subscriptions,
  payment methods, invoices, and subscription detail pages under the CohortFlow
  brand.
- Document the white-label capability so adopters understand that `/billing` is
  package-provided by Accrue but host-branded by configuration.

## Resolution

Resolved as a captured future-hardening input, not immediate implementation
scope. Phase 201 folded this todo as concrete portal parity evidence, and Phase
204 ranked narrow portal readiness as future work while explicitly avoiding a
broad portal redesign in v1.55. The actionable work now lives in
`.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md`.
