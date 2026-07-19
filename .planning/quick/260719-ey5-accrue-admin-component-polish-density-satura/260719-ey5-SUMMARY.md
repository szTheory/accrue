---
quick_id: 260719-ey5
title: accrue_admin component de-garish + density polish (re-skin Phase 2)
status: complete
date: 2026-07-19
mode: quick
---

# accrue_admin component polish — de-saturate status treatments + tighten over-padded regions — Summary

Toned down the genuinely over-saturated `/admin` status treatments and tightened the one
genuinely over-padded region to operator-console density, then rebuilt the shipped bundle.
Cobalt (`--ax-accent` `#5D79F6`) and all status hues (moss/amber/danger) unchanged — this was
a SATURATION/heaviness reduction only. No hue/palette/IA/layout/markup/copy change. Both light
and dark verified legible at WCAG AA. All automated gates green.

## Commits

| Task | Commit | Message | Files |
| ---- | ------- | ------- | ----- |
| A | `f8c528cc` | style(260719-ey5): de-saturate over-garish admin status treatments | `accrue_admin/assets/css/app.css` |
| B | `341fafba` | style(260719-ey5): tighten over-padded alert banner to operator density | `accrue_admin/assets/css/app.css` |
| C | `b775b121` | chore(260719-ey5): rebuild shipped accrue_admin.css bundle | `accrue_admin/priv/static/accrue_admin.css` |

## What changed — before → after (for the PNG review)

### Task A — de-garish (class-level, `app.css`; theme.css NOT touched)

1. **Header health chip `.ax-home-health-status`** (dashboard) — the primary offender.
   - `background: var(--ax-status-warning-solid)` (solid full-strength amber fill) →
     `background: var(--ax-status-warning-bg)` (tinted amber surface, theme-aware).
   - `color: var(--ax-status-warning-on-solid)` (near-black on-solid) →
     `color: var(--ax-warning-readable)` (kept `!important`; `#7a4b00` light / `#f0c36a` dark).
   - Border unchanged (`--ax-status-warning-border`). Now matches the brand's tinted-surface +
     border + strong-hue-on-text pattern (identical treatment to `.ax-attention-priority-warning`).
   - **Look for:** the amber "needs attention" chip in the dashboard header is now a soft tinted
     pill with dark-amber text, NOT a solid saturated amber block.

2. **`.ax-button-primary`** — softened in **dark / system-dark only** (light unchanged).
   - Added `html.accrue-admin[data-theme="dark"] .ax-button-primary` + a mirrored
     `@media (prefers-color-scheme: dark) html.accrue-admin[data-theme="system"] .ax-button-primary`
     block, both: `background: color-mix(in srgb, var(--ax-accent) 62%, var(--ax-elevated))`.
   - Light mode keeps `--ax-accent-strong` exactly as-is; hover/active still darken from there.
   - White `--ax-accent-contrast` text on the new dark fill computes to ~6.9:1 (well above AA 4.5:1).
   - **Look for (DARK only):** a row of primary buttons reads as calmer, slightly less-saturated
     cobalt against the near-black chrome — confident, not neon. Light mode buttons look identical.

3. **`.ax-home-customer-search-strip`** (dashboard blue band).
   - `background: color-mix(--ax-accent-subtle 76%, --ax-elevated)` → `55%` (gentler tint).
   - `border: 2px solid --ax-accent-border` → `1px`.
   - Strong-hue text (`--ax-accent-readable`) and the `-action` button unchanged.
   - **Look for:** the customer-search band reads as gentle accent emphasis, not a saturated blue bar.

4. **`.ax-attention-summary-warning`** (verdict bar tint).
   - `color-mix(--ax-status-warning-bg 66%, --ax-elevated)` → `40%`.
   - **Look for:** the warning verdict bar is a lighter, calmer amber tint.

### Task B — density (class-level, `app.css`)

5. **`.ax-banner`** (the shared red alert/danger banner base) — the one genuine over-padded region.
   - `padding: var(--ax-space-md)` (16px all sides) →
     `padding: var(--ax-space-sm) var(--ax-space-md)` (8px top/bottom, 16px sides).
   - Stepped one existing space token down; horizontal comfort preserved; text banner so no
     touch-target concern.
   - **Look for:** the dunning/danger banner is tighter top-to-bottom, no longer airy.

### Task C — bundle
- `cd accrue_admin && mix accrue_admin.assets.build` regenerated `priv/static/accrue_admin.css`
  (embedded at compile time). All 5 source edits confirmed present in the minified bundle.
  `accrue_admin.js` unchanged (no JS edits).

## Candidates deliberately LEFT as already-calm / already-tight

The admin has been through many ratchet rounds; most named candidates were already at
operator-console density or already using the tinted-surface pattern. Confirmed by inspecting
current source values and intentionally left untouched:

**Already-calm treatments (Task A):** `.ax-attention-row:first-child` (56% danger tint + 3px
left-accent — correct pattern); `.ax-attention-priority-{danger,warning,info}` (raw
`--ax-status-*-bg` tints); `.ax-attention-dot-*` (full-strength hue cue, intentional);
`.ax-health-summary-*` tints; all `--ax-status-*-solid` uses that remain are on warning/recovery
**button CTAs** (`.ax-button-warning` etc.), where a solid fill is the correct button pattern —
NOT garish status chips. `.ax-detail-open-invoice-queue` (subscription-detail) has a similar 2px
accent band but was NOT in the plan's enumerated Task A offender list and is off the reviewed
surfaces, so left for scope discipline.

**Already-tight regions (Task B):** `.ax-subscription-row-signal-*` / `.ax-webhook-row-status`
(padding `0`–`0.1875rem`); `.ax-related` (`0.0625rem 0.25rem`), `.ax-related-list`
(gap `--ax-space-2xs`), `.ax-related-item` (`0.0625rem 0.375rem`); `.ax-detail-section`
(gap `0`, margin `0`), `.ax-detail-section-head` (padding-block `0.03125rem`);
`.ax-detail-open-invoice-queue` (`0.1875rem 0.375rem`); `.ax-inline-worklist` primary queue
banner (`0 0.25rem` — already zero vertical); `.ax-subscriptions-page .ax-data-table-grid td`
(`0.0625rem 0.125rem`). `.ax-summary-list-row` base (`--ax-space-md 0`) has an intentional
`-compact` variant and was not a plan-named target — left as an intentional detail-view default.

## Deviations from Plan

None — plan executed as written. Task A touched only `app.css` (no shared status-fill token in
`theme.css` needed a change; all edits use theme-aware tokens that auto-adapt), so `theme.css` was
correctly left unstaged. The dark `.ax-button-primary` override follows the existing established
dark + system-dark mirror pattern already used in `app.css` (e.g. sidebar nav overrides ~L847-874).

## WCAG AA notes
- Health chip: `#7a4b00` on `#fff5db` (light) and `#f0c36a` on `#2a2111` (dark) — both high contrast.
- Dark primary button: white on `color-mix(--ax-accent 62%, --ax-elevated)` ≈ #4356A6 → ~6.9:1.

## Verification (automated gates — all green)
- `cd accrue_admin && mix accrue_admin.assets.build` → exit 0.
- `cd accrue_admin && mix compile --warnings-as-errors` → exit 0.
- `cd accrue_admin && git diff --exit-code -- priv/static/accrue_admin.css` (post-commit) → clean (exit 0).
- Task A grep: `.ax-home-health-status` now uses `var(--ax-status-warning-bg)` tinted surface (no
  `--ax-status-warning-solid` on the chip); `.ax-button-primary` dark override + system-dark mirror
  present; `.ax-home-customer-search-strip` at 55% + 1px. Confirmed in source and minified bundle.
- Task B grep: only the `.ax-banner` spacing token value changed (1 line); no new selectors, no
  layout properties altered.
- Pre-existing dirty working-tree files + `mix.lock` untouched (staged only intended paths per task).

Visual confirmation (dashboard + subscriptions, light + dark PNGs via Playwright) is the
orchestrator's step — not run here.

## Self-Check: PASSED
- Commits exist: `f8c528cc`, `341fafba`, `b775b121` (all found in `git log`).
- Files present: `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`,
  this SUMMARY.md.
- All 5 source edits verified present in the rebuilt `priv/static/accrue_admin.css` bundle.
