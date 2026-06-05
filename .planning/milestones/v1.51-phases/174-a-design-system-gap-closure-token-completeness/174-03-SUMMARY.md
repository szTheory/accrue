---
phase: 174
plan: 03
subsystem: accrue_admin/dev
tags: [design-system, component-registry, kitchen, dev-tools, dsy-03]
dependency_graph:
  requires: [174-01, 174-02]
  provides: [component-registry-data-contract, kitchen-variant-reference]
  affects:
    - accrue_admin/lib/accrue_admin/dev/component_registry.ex
    - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
tech_stack:
  added: []
  patterns:
    - pure data module as component variant registry (entries/0 + variants_for/1)
    - if Mix.env() != :prod do guard for dev-only modules
    - data-ax-theme wrappers for light/dark swatch side-by-side
    - ComponentRegistry as single source of truth for kitchen and drift test
key_files:
  created:
    - accrue_admin/lib/accrue_admin/dev/component_registry.ex
  modified:
    - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
decisions:
  - "Status section uses Enum.zip(ComponentRegistry.variants_for(status), representative atoms) to pair registry entries with valid status atoms without unsafe String.to_existing_atom on tone names"
  - "Badges and Status sections both use status family data but show different perspectives: Badges shows tone axis directly, Status pairs tone with representative status atoms"
  - "Card delta entries use ax_class ax-kpi-delta ax-kpi-delta-{tone} (confirmed from kpi_card.ex kpi_inner rendering logic, not the card root class)"
metrics:
  duration: 10m
  completed: "2026-06-03"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 2
---

# Phase 174 Plan 03: ComponentRegistry + Kitchen Variant Reference Summary

**One-liner:** Created AccrueAdmin.Dev.ComponentRegistry pure data module (15 entries, 3 families) and extended component_kitchen_live.ex with 4 variant-reference sections (Buttons/Badges/Status/Cards) driven from the registry, showing light+dark swatches and token `<dl>` per row.

## What Was Built

### Task 1: AccrueAdmin.Dev.ComponentRegistry (5c2e87c0)

New file at `accrue_admin/lib/accrue_admin/dev/component_registry.ex`.

**Module design:**
- Wrapped in `if Mix.env() != :prod do` (dev-only, consistent with ComponentKitchenLive)
- `@moduledoc false`, pure data, no Phoenix/LiveView dependencies, no `use` macro
- `@type entry :: %{family: String.t(), variant: String.t(), ax_class: String.t(), tokens: [String.t()]}`
- Exports `entries/0` and `variants_for/1`

**15 entries across 3 families:**

Button family (4 variants) — ax_class strings confirmed against `button.ex` class list construction `["ax-button", button_variant_class(variant), class]`:
- `"ax-button ax-button-primary"` — tokens: accent-strong, accent-contrast, transition-colors
- `"ax-button ax-button-secondary"` — tokens: border, elevated, transition-colors
- `"ax-button ax-button-ghost"` — tokens: border, elevated, transition-colors
- `"ax-button ax-button-danger"` — tokens: danger, danger-readable, transition-colors (RESEARCH #4: was absent from kitchen)

Status family (5 tone variants) — ax_class confirmed against `status_badge.ex` class list `["ax-status-badge", "ax-status-badge-" <> tone]`:
- moss, cobalt, amber, slate, ink with appropriate semantic tokens

Card family (6 entries) — base + 5 delta tones confirmed against `kpi_card.ex` `kpi_inner` rendering:
- base: `"ax-card ax-kpi-card"` (the article root class)
- delta tones: `"ax-kpi-delta ax-kpi-delta-{tone}"` (the delta span class, NOT the card root)

### Task 2: Kitchen Variant Reference Extension (56623102)

Extended `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` — all existing content preserved.

**Alias added:**
```elixir
alias AccrueAdmin.Dev.ComponentRegistry
```

**4 new sections added** (all guarded by `:if={@available?}`):

1. **Buttons** — 4 variants from `ComponentRegistry.variants_for("button")`, each row showing `<Button.button variant={entry.variant}>` in light + dark swatches
2. **Badges** — 5 tone variants from `ComponentRegistry.variants_for("status")`, using `tone={entry.variant} status={:active}` to force the correct CSS tone class
3. **Status** — 5 entries via `Enum.zip(ComponentRegistry.variants_for("status"), [:paid, :processing, :past_due, :canceled, :failed])`, pairing registry entries with representative status atoms per tone
4. **Cards** — 6 entries from `ComponentRegistry.variants_for("card")`, base renders a plain KpiCard, delta tones render with `delta` + `delta_tone` attributes

Each row anatomy:
- `<div data-ax-theme="light">` — live component swatch
- `<div data-ax-theme="dark" style="background: var(--ax-base);">` — same component in dark theme
- `<dl class="ax-dev-token-dl">` — `<dt>` with `<code>` showing ax_class, `<dd>` per token

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create AccrueAdmin.Dev.ComponentRegistry data module | 5c2e87c0 | accrue_admin/lib/accrue_admin/dev/component_registry.ex |
| 2 | Extend component_kitchen_live.ex with variant reference rows | 56623102 | accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex |

## Verification Results

Plan-level checks (all pass):

1. `mix compile` → exit 0, no errors (PASS)
2. `ComponentRegistry.variants_for("button") |> Enum.map(& &1.variant)` → `["primary", "secondary", "ghost", "danger"]` (PASS)
3. `ComponentRegistry.entries() |> length()` → `15` (PASS)
4. `grep -c 'data-ax-theme' component_kitchen_live.ex` → `8` >= 8 (PASS)
5. `grep -c 'variants_for(' component_kitchen_live.ex` → `4` >= 4 (PASS)
6. Button danger variant present: `variants_for("button") |> Enum.any?(&(&1.variant == "danger"))` → `true` (PASS)
7. `variants_for("card") |> length()` → `6` (PASS)

## Deviations from Plan

### Auto-applied judgment (within plan scope)

**1. Status section uses Enum.zip instead of String.to_existing_atom**
- **Found during:** Task 2 implementation
- **Issue:** The PATTERNS.md suggested `String.to_existing_atom(entry.variant)` where `entry.variant` is a tone name ("moss", "cobalt" etc.). These are NOT valid status atoms — the actual status atoms are `:paid`, `:active` etc. Using `String.to_existing_atom("moss")` would succeed at atom lookup (atoms are interned globally) but `:moss` is not a meaningful status atom and would render incorrectly as the "ink" (default) tone.
- **Fix:** Status section uses `Enum.zip(ComponentRegistry.variants_for("status"), [:paid, :processing, :past_due, :canceled, :failed])` to pair each registry entry with a representative status atom that maps to that tone. The `tone:` attr overrides the computed tone ensuring correct CSS class output.
- **Files modified:** accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex

## Known Stubs

None. The registry entries are complete data; the kitchen renders live components. No placeholder text or hardcoded empty values.

## Threat Flags

None. Both modules are wrapped in `if Mix.env() != :prod do` — they do not exist in the compiled production release. All data is static and curated (no user input, no DB, no serialization).

## Self-Check: PASSED

- [x] `accrue_admin/lib/accrue_admin/dev/component_registry.ex` exists
- [x] Commit 5c2e87c0 exists in git log
- [x] Commit 56623102 exists in git log
- [x] `entries()` returns 15 entries
- [x] `variants_for("button")` returns 4 entries including danger
- [x] `variants_for("status")` returns 5 entries
- [x] `variants_for("card")` returns 6 entries
- [x] `data-ax-theme` appears 8 times in component_kitchen_live.ex
- [x] `variants_for(` appears 4 times in component_kitchen_live.ex
- [x] `mix compile` exits 0 with no errors
- [x] Both modules wrapped in `if Mix.env() != :prod do`
