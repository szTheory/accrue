---
quick_id: 260718-qni
title: Add a short JTBD line to each persona in the nav account-switcher dropdown
status: planned
date: 2026-07-18
mode: quick
---

# Quick Task 260718-qni — Plan

## Goal
The host nav "Switch demo account" dropdown lists each persona by **label** + a muted `workspace · state`
line — it names the account but doesn't say *why you'd pick it / what you'll see*. Add a very short
JTBD ("job to be done") line to each dropdown entry so picking a persona reads as choosing a scenario.
Demo-only; copy lives in `AccrueHost.DemoBrand` (single source), not hardcoded in the template.

## Tasks

### Task 1 — Add `:jtbd` field to each persona
- **files:** `examples/accrue_host/lib/accrue_host/demo_brand.ex`
- **action:** Add a new `:jtbd` key (very short, ≤~5 words, action-first) to each of the 4 maps in
  `@personas`, keeping the existing `:description` (login cards still use it). Copy:
  - Team Lead / Northwind Labs (healthy) → `"Manage a healthy subscription"`
  - Ops Manager / Tidewater Systems (past-due) → `"Recover a past-due payment"`
  - Head of Engineering / Meridian Group (scale) → `"Explore a scale-plan account"`
  - Billing Operator / Accrue Admin (/admin) → `"Run the operator console"`
- **verify:** `cd examples/accrue_host && mix compile --warnings-as-errors` → EXIT 0.
- **done:** All 4 personas carry a `:jtbd` string; `:description` untouched.

### Task 2 — Render the JTBD in the dropdown item
- **files:** `examples/accrue_host/lib/accrue_host_web/components/layouts/root.html.heex`
- **action:** In the `<li :for={persona <- personas}>` block (~lines 86-101), keep the
  `<.demo_login_form persona={persona}>` wrapper, the active-highlight (`bg-base-200` when
  `current_persona.email == persona.email`), and hover styling. Restructure the button's inner text to
  two tight lines:
  - **Line 1:** `flex items-baseline justify-between gap-2` row — `{persona.label}`
    (`text-sm font-semibold`) + `{persona.workspace}` as a light right-aligned tag
    (`text-[11px] text-base-content/45 truncate`).
  - **Line 2:** `{persona.jtbd}` — `text-xs text-base-content/60`.
  This drops the `state` noun from the dropdown (still shown on the login cards) in favor of the JTBD.
  Do NOT change the collapsed trigger button (still shows `current_persona.label`).
- **verify:** `mix compile --warnings-as-errors` EXIT 0; `mix test
  test/accrue_host_web/live/user_live/login_test.exs` green (it only asserts each `persona.label` +
  `persona.workspace` appear in login-page HTML — both still render).
- **done:** Each dropdown entry shows label + workspace tag on line 1 and its JTBD on line 2.

## Guardrails
- Demo-only; no core/library change. Copy in `DemoBrand`, not the template.
- Do NOT touch: the login-page persona cards (keep full `:description`), `demo_login_form`, routing, auth.
- Leave pre-existing dirty working-tree files + `mix.lock` untouched. Atomic commit scoped to the 2 files.

## Verification (end-to-end)
1. `cd examples/accrue_host && mix compile --warnings-as-errors` → EXIT 0.
2. `mix test test/accrue_host_web/live/user_live/login_test.exs` → green.
3. (Optional live) recompile/reload the running demo; open the nav **Switch account** dropdown: 4 entries,
   each with a JTBD subtitle; active persona highlighted; clicking still switches accounts.
