---
quick_id: 260718-s1y
title: Portal light/dark/system theming + picker, brandable in both modes
status: complete
date: 2026-07-18
mode: quick
subsystem: accrue_portal
tags: [theming, portal, css, accessibility, brand]
key-files:
  created: []
  modified:
    - accrue/priv/static/brand.css
    - accrue_portal/priv/static/accrue_portal.css
    - accrue_portal/lib/accrue_portal/layouts.ex
    - accrue_portal/priv/static/accrue_portal.js
metrics:
  tasks_completed: 4
  files_modified: 4
  duration: ~10m
---

# Quick Task 260718-s1y — Summary

Added real light/dark/system theming to the `accrue_portal` customer portal with an
idiomatic segmented picker, persisted via the existing `accrue_theme` cookie, and made the
host brand accent legible in both modes — all library-only (core `accrue` + `accrue_portal`),
no host change, no new deps, no build step.

## What changed

### Task 1 — `accrue/priv/static/brand.css` (additive tokens, three-state theming)
- Replaced the single OS-only `@media (prefers-color-scheme: dark)` block with a three-state
  model:
  - `:root` keeps the light defaults.
  - `:root[data-theme="dark"]` applies the dark tokens explicitly (wins even on a light OS).
  - `@media (prefers-color-scheme: dark) { :root[data-theme="system"], :root:not([data-theme]) { … } }`
    follows the OS only in system / no-attribute mode, so an explicit `data-theme="light"`
    stays light on a dark OS.
- Added `--accrue-brand-accent-text` — light = `var(--accrue-brand-accent)`; dark =
  `color-mix(in srgb, var(--accrue-brand-accent) 60%, #ECF1F5)` so any host accent stays
  legible as text against the dark surface.
- Made `--accrue-brand-accent-strong` derive from the accent (light `color-mix … 82%, black`;
  dark `color-mix … 82%, white`), replacing the fixed `#4D8A70` so hover tracks any host brand.
- All existing `--accrue-*` token names kept stable (additive only). Host inline
  `:root{--accrue-brand-accent:…}` override still wins in both modes.

### Task 2 — `accrue_portal/priv/static/accrue_portal.css`
- Switched `.portal-eyebrow` color and the link-hover color from `--accrue-brand-accent` to
  `--accrue-brand-accent-text` (buttons keep accent bg + accent-contrast text; focus outline
  unchanged).
- Added a compact segmented `.portal-theme-picker` (pill group, `margin-left:auto`) with
  `.portal-theme-option` icon buttons: `--accrue-slate` idle, active via
  `.is-active` / `[aria-pressed="true"]` (`--accrue-surface` bg + `--accrue-brand-accent-text`),
  plus hover and `:focus-visible` states. Fully token-driven.

### Task 3 — `accrue_portal/lib/accrue_portal/layouts.ex`
- Rendered the picker in `.portal-topbar-inner` after the logo/wordmark as a
  `role="group" aria-label="Theme"` control with three `<button type="button">` options
  (`data-portal-theme="system|light|dark"`), each with `aria-pressed={@theme == …}`,
  `class={[…, @theme == … && "is-active"]}`, an `aria-label`, and a small inline SVG
  (monitor / sun / moon). Static HTML; `@theme` was already an assign. The
  brand_style_tag / logo / wordmark / private helpers were left untouched.

### Task 4 — `accrue_portal/priv/static/accrue_portal.js`
- Inside the existing IIFE, added a delegated `document`-level click handler for
  `[data-portal-theme]` (via `event.target.closest`): sets
  `document.documentElement.dataset.theme`, writes the `accrue_theme` cookie
  (`path=/; max-age=31536000; samesite=lax`), and syncs `aria-pressed` + `.is-active` across
  the three buttons. Delegation survives LiveView DOM patches; no inline `<script>` so it stays
  within the CSP `script-src 'self'`. The existing BraintreeHostedFields hook and LiveSocket
  boot are unchanged.

## Verification
- `cd accrue && mix compile` — clean.
- `cd accrue_portal && mix compile` — clean.
- `cd accrue_portal && mix test` — 36 tests, 0 failures.
- Grep confirmed `data-theme="dark"`, `data-theme="light"` (comment scoping note),
  `data-theme="system"`, and `--accrue-brand-accent-text` all present in brand.css.

## Deviations from Plan
None — plan executed exactly as written. No test assertions needed changing (no test asserts
the topbar markup; `router_test.exs` only checks the session `theme` default of `"system"`,
which is unaffected).

## Guardrails honored
- Library-only; no host change; no new deps.
- Existing `--accrue-*` token names kept stable (additive). Neutral-Accrue fallback still
  renders with no host brand configured.
- No deferred items built (single-mode config API, admin config surface, admin re-skin,
  dunning banner).
- Pre-existing dirty working-tree files and `mix.lock` left untouched; staged only the 4
  changed files.

## Commits
- `3a7284f4` feat(260718-s1y): three-state theming + brand-in-both-modes tokens
- `ba6a715c` feat(260718-s1y): portal light/dark/system theme picker

## Self-Check: PASSED
- FOUND: accrue/priv/static/brand.css (committed 3a7284f4)
- FOUND: accrue_portal/priv/static/accrue_portal.css (committed ba6a715c)
- FOUND: accrue_portal/lib/accrue_portal/layouts.ex (committed ba6a715c)
- FOUND: accrue_portal/priv/static/accrue_portal.js (committed ba6a715c)
- FOUND commit: 3a7284f4
- FOUND commit: ba6a715c
