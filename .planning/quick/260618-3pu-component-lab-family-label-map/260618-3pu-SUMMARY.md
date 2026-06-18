---
quick_id: 260618-3pu
slug: component-lab-family-label-map
status: complete
date: 2026-06-18
---

# Quick Task 260618-3pu — Summary

## What changed

`accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex`:
- Render: `<%= String.upcase(family) %>` → `<%= family_label(family) %>` (the
  registry-driven matrix family header eyebrow).
- Added private `family_label/1` mapping all 16 `applicable_states` families to
  their approved Phase-189 UI-SPEC `####` copywriting labels (Button, Input,
  Textarea, Checkbox, Radio, Toggle switch, Select, Form field, Status badge,
  Icon, Money, JSON viewer, Loading, Tooltip, Inline code / ID, Empty state),
  plus a humanizing catch-all (`"-" → " "`, capitalize each word) so a future
  unmapped registry family degrades to a readable title instead of a raw token.

## Why

The kitchen headers rendered shouty raw tokens ("BUTTON", "FORM-FIELD",
"JSON-VIEWER"). `189-UI-REVIEW.md` flagged this as a WARNING; STATE.md tracked
it as a Phase 189 follow-up. The labels are sourced from the approved
`189-UI-SPEC.md` component section headings (authoritative copywriting).

## Verification

- `mix compile` clean (no warnings on the changed file).
- Server-rendered LiveView template — pure Elixir render logic, so no Tailwind
  bundle rebuild is required (the app.css/`priv/static` gotcha does not apply).
- All 16 families have an explicit clause; catch-all guards future entries.

## Notes

- Scope held to the header label only — no registry, route, or component API
  changes; backward-compatible.
