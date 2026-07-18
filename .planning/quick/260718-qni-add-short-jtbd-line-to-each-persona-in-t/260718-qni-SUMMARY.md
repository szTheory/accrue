---
quick_id: 260718-qni
title: Add a short JTBD line to each persona in the nav account-switcher dropdown
status: complete
date: 2026-07-18
mode: quick
commit: ae940cb1
files_changed: 2
---

# Quick Task 260718-qni — Summary

Added a short "job to be done" (JTBD) line to each persona in the host nav
"Switch demo account" dropdown so picking an account reads as choosing a scenario.
Demo-only; JTBD copy lives in `AccrueHost.DemoBrand` (single source), not the template.

## What changed

### Task 1 — `:jtbd` field on each persona
`examples/accrue_host/lib/accrue_host/demo_brand.ex`
- Added a new `:jtbd` key to each of the 4 maps in `@personas`, leaving `:description` untouched
  (login cards still use `:description`):
  - Team Lead / Northwind Labs (healthy@example.com) → "Manage a healthy subscription"
  - Ops Manager / Tidewater Systems (past-due@example.com) → "Recover a past-due payment"
  - Head of Engineering / Meridian Group (enterprise@example.com) → "Explore a scale-plan account"
  - Billing Operator / Accrue Admin (admin@example.com) → "Run the operator console"

### Task 2 — Render JTBD in the dropdown item
`examples/accrue_host/lib/accrue_host_web/components/layouts/root.html.heex`
- In the `<li :for={persona <- personas}>` block, kept the `<.demo_login_form>` wrapper,
  active-highlight (`bg-base-200` when `current_persona.email == persona.email`), and button classes.
- Replaced the inner two `<span>`s with:
  - Line 1: `flex items-baseline justify-between gap-2` row — `{persona.label}`
    (`text-sm font-semibold`) + `{persona.workspace}` as a light right tag
    (`text-[11px] text-base-content/45 truncate`).
  - Line 2: `{persona.jtbd}` (`text-xs text-base-content/60`).
- This drops the old `{persona.workspace} · {persona.state}` line in favor of the workspace tag + JTBD.
- Collapsed trigger button (~lines 66-78) left unchanged (still shows `current_persona.label`).

## Verification
- `cd examples/accrue_host && mix compile --warnings-as-errors` → EXIT 0.
- `mix test test/accrue_host_web/live/user_live/login_test.exs` → 2 tests, 0 failures.

## Deviations from Plan
None to the code change. Environmental note: the working tree carried a large
**pre-existing** dirty `mix.lock` (an unrelated dependency-upgrade experiment: hackney 1→4,
braintree, mint, quic/webtransport/h2, etc.) that referenced un-fetched deps and blocked compile.
Per the guardrails this file was left untouched. To run verification, `mix deps.get` was used to
fetch the already-locked versions (this does not rewrite `mix.lock`; sha unchanged before/after),
after which compile and tests passed. `mix.lock` remains dirty and unstaged; only the two source
files were staged and committed.

## Guardrails honored
- Demo-only; no core/library change. Copy lives in `DemoBrand`, not the template.
- Login-page persona cards (`login.ex`), `demo_login_form`, routing, and auth unchanged.
- Pre-existing dirty working-tree files and `mix.lock` left untouched; atomic commit scoped to the 2 files.

## Self-Check: PASSED
- FOUND: lib/accrue_host/demo_brand.ex (`:jtbd` on all 4 personas)
- FOUND: lib/accrue_host_web/components/layouts/root.html.heex (workspace tag + JTBD lines)
- FOUND: commit ae940cb1 (2 files changed, mix.lock excluded)
