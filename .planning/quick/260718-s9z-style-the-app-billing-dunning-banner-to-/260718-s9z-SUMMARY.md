---
quick_id: 260718-s9z
title: Style the /app/billing dunning banner to match the Cadence design system
status: complete
date: 2026-07-18
mode: quick
commit: e76ad7e1
files_changed: 1
---

# Quick Task 260718-s9z — Summary

Styled the `/app/billing` dunning banner so it renders as a Cadence-styled amber warning card instead of raw unstyled text.

## What changed

Single-file host-only edit to `examples/accrue_host/lib/accrue_host_web/components/layouts.ex` (`app/1`):

- **Moved** the `<%= if customer = dunning_customer(@current_scope) do %> … <% end %>` block from outside the `<div class="mx-auto max-w-6xl space-y-4">` to **inside it as the first child** (before `{render_slot(@inner_block)}`), so the banner aligns with the page cards and inherits `space-y-4` spacing.
- **Kept** the `if customer = dunning_customer(...)` gate and the `<AccrueAdmin.Components.DunningBanner.dunning_banner customer={customer}>` wrapper, so `Accrue.Dunning.requires_attention?/1` still controls visibility.
- **Passed a Cadence-styled inner slot** composed from host utilities + daisyUI semantic tokens (`warning`, `base-content`) and `<.icon name="hero-exclamation-triangle">` — no accrue_admin classes, no daisyUI `.alert` component. This overrides the component's headless `ax-banner` default (whose CSS the Cadence host never loads).

## Root cause

The host `Layouts.app/1` called the headless `AccrueAdmin.Components.DunningBanner.dunning_banner customer={customer}` with **no inner block**, so it fell through to the component's `ax-banner ax-banner-danger` default markup — accrue_admin design-system classes the Cadence host never bundles — rendering full-bleed unstyled text.

## Verification

- `cd examples/accrue_host && mix compile --warnings-as-errors` → **EXIT 0**.
- No test asserts the banner markup (`seeds_idempotency_test` checks dunning DATA, not markup), so behavior is unchanged for gating.

## Guardrails honored

- Did NOT modify `AccrueAdmin.Components.DunningBanner` (its default stays for the admin app).
- No new deps. `dunning_customer/1`, `flash_group`, and all other functions untouched.
- Staged and committed ONLY `examples/accrue_host/lib/accrue_host_web/components/layouts.ex`; pre-existing dirty files and `mix.lock` left untouched. Single atomic commit `e76ad7e1`.

## Self-Check: PASSED

- File exists and is committed: `examples/accrue_host/lib/accrue_host_web/components/layouts.ex`
- Commit exists: `e76ad7e1`
