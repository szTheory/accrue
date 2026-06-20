---
quick_id: 260620-n4q
slug: theme-picker-segmented
date: 2026-06-20
---

# Quick Task: Redesign the color-theme picker as an on-brand segmented control

## Problem

The admin light/dark/system picker rendered as **three disconnected pill
buttons** (`.ax-theme-toggle` / `.ax-theme-button`) — separate borders + gap,
reading as cheap. Inline markup in `topbar.ex`, not a real component.

## Fix (researched + synthesized; see plan)

A **unified segmented control**: one recessed track with the active option as a
contained, raised "thumb" + subtle Cobalt accent ring; icon + label per segment;
labels collapse to icon-only < 768px. On-brand ("quiet polish", Cobalt accent,
Geist labels, Heroicons inline, 180ms ease-out, reduced-motion). Extracted into a
reusable component and registered in the component lab.

Kept the persistence/resolution spine **unchanged** (cookie `accrue_theme` +
localStorage + `data-theme`, anti-FOUC, `brand_plug`, session, `[data-theme]`
CSS) and the `data-theme-target` JS contract stable.

## Changes
- **NEW** `components/theme_picker.ex` — `role="radiogroup"` + `role="radio"`
  segments, `aria-checked`, per-option `aria-label`, roving `tabindex`,
  `data-theme-target`.
- `components/icon.ex` — added Heroicons v2 outline `:sun`, `:moon`,
  `:computer_desktop`.
- `components/topbar.ex` — render `<ThemePicker.theme_picker theme={@theme} />`;
  removed `theme_button_class/2`.
- `assets/css/app.css` — removed all `.ax-theme-button*` / `.ax-theme-toggle`
  refs across the shared grouped selectors; added `.ax-theme-picker` +
  `.ax-theme-picker-option(-active)` + `.ax-theme-picker-label` (tokens only) +
  responsive label collapse + dark/system@dark active-pin.
- `assets/js/hooks/accrue_theme.js` — active-state sync now toggles the new class,
  sets `aria-checked`, manages roving `tabindex`; added arrow-key nav
  (Left/Up/Right/Down/Home/End). Persistence untouched.
- `dev/component_registry.ex` + `dev/component_kitchen_live.ex` — registered the
  `theme-picker` family (specimens: system + light-active) so it shows at
  `/dev/components`.
- **NEW** `test/.../components/theme_picker_test.exs`.
- Rebuilt committed bundles `priv/static/accrue_admin.{css,js}`.

## Verification
- `mix compile --warnings-as-errors` clean; `mix accrue_admin.assets.build` +
  `mix test` → **324 tests, 0 failures**.
- Bundle: `ax-theme-picker` present, `ax-theme-button` gone; JS carries
  `keydown`/`ArrowRight`/`radiogroup`/new active class.
- Demo hot-recompiled accrue_admin on next request (reloadable_apps).

## Out of scope
- persistence/resolution spine, anti-FOUC, brand_plug, session, `[data-theme]`
  theming; sidebar/favicon/logo; no new deps; no host changes.
