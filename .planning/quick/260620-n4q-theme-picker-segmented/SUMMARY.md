---
quick_id: 260620-n4q
slug: theme-picker-segmented
date: 2026-06-20
status: complete
---

# Summary: Theme picker → on-brand segmented control + design-system component

## What changed
- NEW `components/theme_picker.ex` (radiogroup, icon+text segments, aria-checked,
  roving tabindex, data-theme-target). Topbar now renders it; `theme_button_class/2`
  removed.
- `icon.ex`: added Heroicons v2 outline `:sun`, `:moon`, `:computer_desktop`.
- `app.css`: removed every `.ax-theme-button*`/`.ax-theme-toggle` ref from the
  shared grouped selectors; added `.ax-theme-picker` recessed track +
  `.ax-theme-picker-option(-active)` raised thumb (Cobalt accent-border ring) +
  label collapse < 768px + dark active-pin. Tokens only.
- `accrue_theme.js`: persistence untouched; active-sync now toggles the new class
  + `aria-checked` + roving tabindex; added arrow-key nav.
- Component lab: registered `theme-picker` family (registry + kitchen) → shows at
  `/dev/components` with system + light-active specimens.
- NEW `theme_picker_test.exs`; rebuilt committed `priv/static/accrue_admin.{css,js}`.

## Result
`mix compile --warnings-as-errors` clean; `mix test` → **324 tests, 0 failures**
(320 + 4 new). Bundle confirmed (`ax-theme-picker` in, `ax-theme-button` out; JS
carries keydown/ArrowRight/radiogroup). Demo hot-recompiled, no restart.

## Notes / decisions
- Form factor (icon + text segmented) chosen by the user from 3 researched
  options.
- Kept persistence/resolution spine + `data-theme-target` contract stable (no
  e2e/test breakage; no test pinned the old `.ax-theme-button` markup).
- Dark mode: active segment + brand chip pinned `#f4f7fa` (host-token safe);
  inactive uses `--ax-muted` — the active affordance is the raised thumb + ring,
  so it survives regardless of text color.
- Registry `ax_class` must be "base variant" (two classes) per the
  ComponentRegistry render-coverage guardrail → used
  `"ax-theme-picker ax-theme-picker-option"`.
