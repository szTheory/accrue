---
quick_id: 260719-fz6
title: Admin Home + Subscriptions console-card grammar normalization
status: complete
date: 2026-07-19
mode: quick
scope: Task 1 (Home) + Task 2 (Subscriptions) + Task 3 (rebuild+commit) — all executed
---

# Admin Home console-card grammar normalization — Summary

Normalized the drifted mid-page zones on the admin **Home/dashboard** to ONE console-card
grammar (CSS-only, class-level edits in `accrue_admin/assets/css/app.css`), preserving console
density — no airy inflation. Task 2 (Subscriptions) was intentionally NOT executed; the
orchestrator PNG-verifies Home first and dispatches Subscriptions separately.

## Commit

- `22deb9d7` — `style(260719-fz6): normalize admin Home console-card grammar`
  - Files: `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`
  - theme.css NOT touched (no new token needed — reused existing radius/space tokens).

## Exactly which selectors/values changed (before → after)

Vertical rhythm (one shared rhythm; parent gap owns spacing):
- `.ax-home` gap: `0.0625rem` → `var(--ax-space-md)` (16px between peer sections)
- `.ax-home .ax-home-section` margin-block-start: `0.0625rem` → `0`
- `.ax-home-section` gap: `0` → `var(--ax-space-sm)` (8px heading→body, tightly-related)
- `.ax-launchers` gap: `0.1875rem` → `var(--ax-space-sm)`

Customer-search-strip (NEUTRALIZED — see accent decision below):
- `.ax-home-customer-search-strip` gap: `0.1875rem 0.5rem` → `var(--ax-space-2xs) var(--ax-space-sm)`
- padding: `0.1875rem 0.375rem` → `var(--ax-space-sm)`
- border: `1px solid var(--ax-accent-border)` → `1px solid var(--ax-border)`
- border-radius: `var(--ax-radius-sm)` → `var(--ax-radius-md)`
- background: `color-mix(... --ax-accent-subtle 35% ...)` → `var(--ax-elevated)`
- `.ax-home-customer-search-strip div` gap: `0.03125rem` → `var(--ax-space-2xs)`

Launchers (real interior padding + console radius):
- `.ax-launcher` padding: `0` → `var(--ax-space-sm)` (content no longer butts the border)
- `.ax-launcher` border-radius: `var(--ax-radius-sm)` → `var(--ax-radius-md)`
- (kept internal grid `gap: 0 0.3125rem` — internal label-row gap, not card-level)

Attention rail (de-nest + console grammar on wrapper):
- `.ax-attention` border: `1px solid var(--ax-border-strong)` → `1px solid var(--ax-border)`;
  added `border-radius: var(--ax-radius-md)` (wrapper already has `overflow: hidden` so rows clip)
- `.ax-attention-summary` REMOVED `border: 1px solid var(--ax-border)` and
  `border-radius: var(--ax-radius-sm)`; replaced with `border-bottom: 1px solid var(--ax-border)`
  (divider). padding: `0.0625rem 0.375rem` → `var(--ax-space-sm)`; gap:
  `0.0625rem 0.375rem` → `var(--ax-space-2xs) var(--ax-space-sm)`
- `.ax-attention-summary-warning` REMOVED the full-box `background` tint and blanket
  `border-color`; now `border-bottom-color: var(--ax-status-warning-border)` — warning hue lives
  as a divider accent (text hue on strong/span still preserved by the existing rule), not a box.

## Accent decision (AT MOST ONE accent-tinted zone on Home)

- **KEPT as the single deliberate accent:** `.ax-launcher-primary` (the genuine primary "open
  customer" launcher — 2px accent border + `--ax-accent-subtle 52%` bg, unchanged).
- **NEUTRALIZED:** `.ax-home-customer-search-strip` → plain neutral card (`--ax-border`,
  `--ax-elevated`, no accent tint). Its inline CTA button (`-action`) stays accent — that's a
  button, not a zone tint.
- The tinted `.ax-home-header-health` bar was left intact (danger STATUS semantic, not an accent
  card — explicitly preserved per plan). Net: exactly one accent-tinted zone.

## How `.ax-attention-summary` was de-nested

The bordered `.ax-attention` wrapper previously contained a fully-bordered, radius-sm
`.ax-attention-summary` sub-box (box-in-box). Removed the summary's four-side border + radius and
replaced with a single `border-bottom` divider plus `--ax-space-sm` padding, so the summary now
reads as the first row of the wrapper (separated from the exception rows by a thin divider). The
warning variant keeps its semantic hue as the divider color instead of a nested colored box.

## Density preserved (no airy inflation)

Home was normalized to CONSISTENT + INTENTIONAL, NOT to the airy 24px Customers padding. Card
interiors use `--ax-space-sm` (8px, compact) / section rhythm `--ax-space-md` (16px). No zone was
bumped to `--ax-space-lg` (24px). The already-good `.ax-kpi-*`, event-ledger, and webhook-health
cards were untouched.

## Deviations from Plan

None — plan executed as written for Task 1 + Task 3. Task 2 (Subscriptions) intentionally out of
scope per orchestrator instruction (Home PNG-verified first, then Subscriptions dispatched
separately).

## Verification (executor / mechanical)

- Grep of the edited Home zone selectors: no residual `0.1875rem` / `0.0625rem` / `0.03125rem` /
  `padding: 0;` / `radius-sm` in any normalized selector. (Remaining occurrences elsewhere are in
  intentionally-untouched zones: `.ax-home-header-health`, `.ax-attention-row`,
  `.ax-attention-priority`, `.ax-kpi-*`.)
- `mix accrue_admin.assets.build` → rebuilt bundle; `priv/static/accrue_admin.css` modified.
- `mix compile --warnings-as-errors` → exit 0 (only pre-existing storybook asset-path runtime
  notices, unrelated to this change).
- Post-commit `git diff --exit-code -- priv/static/accrue_admin.css` → CLEAN (bundle committed in
  sync with source).
- Commit contains ONLY `assets/css/app.css` + `priv/static/accrue_admin.css`; pre-existing dirty
  files + `mix.lock` untouched; no `git add -A`.
- Did NOT run ratchet (`ui.round`/`ui.fix`), `--verify-frozen`, or Playwright — final visual
  sign-off is the orchestrator's.

## Self-Check: PASSED
- `accrue_admin/assets/css/app.css` — FOUND (modified, committed in 22deb9d7)
- `accrue_admin/priv/static/accrue_admin.css` — FOUND (rebuilt, committed in 22deb9d7)
- commit `22deb9d7` — FOUND in git log

---

# Task 2 — Subscriptions console-card grammar normalization

Applied the IDENTICAL console-card grammar established on Home to the Subscriptions surface
(top-strip cluster + the table Signals/audit column). CSS-only, class-level app.css edits;
console density preserved (no airy inflation); Cobalt + all status hues kept; NO IA/markup/copy
change (fields regrouped visually, none removed or merged).

## Commit (Task 2)

- `a3b582e0` — `style(260719-fz6): normalize admin Subscriptions to console-card grammar`
  - Files: `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`
  - theme.css NOT touched (reused existing radius/space tokens).

## Root cause fixed: the shared base was accent-tinted

`.ax-inline-worklist` (the base class every subscriptions strip is built on) DEFAULTED to
`border: 1px solid var(--ax-accent-border)` + `--ax-accent-subtle 38%` background — that default
is why "each band looked different." Neutralizing the base fixed most strips in one move; only
genuine-status variants now override.

## Top-strip cluster — selectors changed (before → after)

- `.ax-subscriptions-page` gap: `0.03125rem` → `var(--ax-space-md)` (one section rhythm, matches Home)
- `.ax-inline-worklist` (BASE): gap `0.0625rem 0.25rem` → `var(--ax-space-2xs) var(--ax-space-sm)`;
  padding `0 0.25rem` → `var(--ax-space-sm)`; border `1px solid var(--ax-accent-border)` →
  `1px solid var(--ax-border)`; border-radius `sm` → `md`; background `--ax-accent-subtle 38%` →
  `var(--ax-elevated)`
- `.ax-subscriptions-customer-search-strip` (NEUTRALIZED, matches Home): dropped `2px accent`
  border + `--ax-accent-subtle 72%` bg + `0.125rem 0.375rem` padding overrides → inherits neutral
  base (plain `--ax-border`, `--ax-elevated`, radius-md, space-sm padding). Inline CTA button
  (`.ax-subscriptions-customer-search-action`) stays accent (button, not zone).
- `.ax-subscriptions-invoice-strip`: dropped `padding: 0` + redundant neutral overrides → inherits
  base. Its `-danger` variant keeps the warning box (genuine "collect open invoices" alert).
- `.ax-subscriptions-invoice-records`: dropped `--ax-accent-border` + `--ax-accent-subtle 38%` bg
  + `0.0625rem 0.25rem` padding → inherits neutral base (de-tinted).
- `.ax-subscriptions-invoice-record-list` gap: `0.1875rem` → `var(--ax-space-sm)`
- `.ax-subscriptions-invoice-record` (nested record sub-cards, DE-NESTED): dropped
  `1px solid var(--ax-accent-border)` + `radius-sm` + `--ax-elevated` box → now a borderless field
  with `border-left: 2px solid var(--ax-border)` divider + `var(--ax-space-2xs) 0 var(--ax-space-2xs) var(--ax-space-sm)` padding.
- `.ax-subscriptions-queue-shortcut`: `0 0.3125rem` padding + `68%-transparent` border + `radius-sm`
  + transparent bg → `var(--ax-space-2xs) var(--ax-space-sm)` padding, `1px solid var(--ax-border)`,
  `radius-md`, `var(--ax-elevated)`.
- `.ax-subscriptions-audit-strip`: dropped `0.0625rem 0.375rem` padding + `60%-transparent` border
  + transparent bg → inherits neutral base (plain card).
- `.ax-subscriptions-secondary-strips` grid: gap `0.125rem` → `var(--ax-space-md)`;
  margin-block-start `0.03125rem` → `0` (parent gap owns rhythm).
- `.ax-subscriptions-at-risk-strip` (DE-BOXED, hue kept as accent): dropped `0.0625rem 0.3125rem`
  padding + `warning-52% border-color` + transparent bg → inherits neutral base +
  `border-left: 3px solid var(--ax-status-warning-border)` (warning as a left-accent, not a box).

## Single-accent decision (Subscriptions)

**Zero pure-accent zones** (invariant is "at most one"). The Subscriptions primary is signaled by
the `-invoice-strip-danger` warning box (genuine status) + the primary CTA buttons
(`ax-button-primary`, `.ax-subscriptions-primary-action`) — accent lives in buttons + status hues,
not in a competing tinted zone. This mirrors Home, where the single accent (launcher-primary) has
no true analog here, so none is forced. The customer-search strip was neutralized (as instructed).

## Table "Signals / audit" column — how it was de-nested (the worst offender)

The column (`<span class="ax-stack-sm">`) stacked four individually bordered/tinted sub-boxes.
Each was converted to a borderless field; status hue is preserved as a left-accent bar (not a
bordered tinted box); the fields are grouped by spacing:

- `.ax-subscription-row-audit .ax-audit-fact` ("Audit"): dropped `1px solid var(--ax-border)` +
  `radius-2xs` + `--ax-elevated` bg + `0.03125rem 0.1875rem` padding → `padding: 0; border: 0;
  background: transparent` (plain field).
- `.ax-subscription-row-signal-primary` ("Invoice queue status", both duplicate rules):
  dropped `accent-border` + `--ax-accent-subtle 24%/48%` bg AND the `.ax-webhook-row-status`
  base box → `border: 0; border-left: 3px solid var(--ax-status-warning-border); border-radius: 0;
  background: transparent` (warning left-accent).
- `.ax-subscription-row-signal-secondary` ("Webhook status", both rules): dropped
  `warning-56% border-color` + `--ax-status-warning-bg 30%` box → `border: 0; border-left: 3px
  solid <warning-mix>; background: transparent; padding-left: var(--ax-space-sm)`.
- `.ax-subscription-setup-gap` ("Setup gap", Plan/amount column): dropped `1px solid warning-border`
  + `radius-sm` + `--ax-status-warning-bg 58%` box → `border-left: 3px solid var(--ax-status-warning-border)`
  + `padding-left: var(--ax-space-sm)` (warning left-accent, not a filled box).
- Added scoped rhythm: `.ax-subscriptions-page .ax-data-table-grid td:last-child .ax-stack-sm`
  gap → `var(--ax-space-xs)` (4px) so the now-borderless fields read as grouped fields, not a
  collapsed stack. Owner/Tax stay as small `.ax-chip` label pills (acceptable small-label form,
  not boxes-in-boxes).

Result: the column reads as grouped fields with status carried by small left-accent bars + text,
dense and scannable — no stack of cards.

## Scope notes / deviations

- The base `.ax-inline-worklist` neutralization also touches the subscription **detail** page's
  `.ax-detail-open-invoice-queue` and the dev component-kitchen strips. The detail queue FULLY
  overrides border/background/padding (2px accent), so it keeps its own look — no regression. Dev
  kitchen is dev/test-only. Net visible change is confined to the Subscriptions LIST (the target).
- Left the identity-column accent mini-boxes (`.ax-subscription-row-customer-scope`,
  `.ax-subscription-row-invoice-action`) untouched — not flagged by the coordinator; kept scope
  tight to the Signals/audit column + top strips. Flag for a possible follow-on if the PNG shows
  cross-column inconsistency.
- `.ax-subscriptions-webhook-strip` (a genuine warning strip, order 0) left as-is (status hue).
- No `.ax-subscriptions-mrr*` / `-signal` band selectors exist in app.css — nothing to normalize
  there (the coordinator's MRR/signal reference had no matching class).

## Verification (Task 2)

- `mix accrue_admin.assets.build` → bundle rebuilt; spot-checked built `accrue_admin.css`:
  `.ax-inline-worklist` now `1px solid var(--ax-border)` / `radius-md` / `--ax-elevated`;
  `.ax-subscriptions-invoice-record` now `border-left: 2px solid var(--ax-border)` (no box).
- `mix compile --warnings-as-errors` → exit 0 (only pre-existing storybook asset-path notices).
- Post-commit `git diff --exit-code -- priv/static/accrue_admin.css` → CLEAN.
- Commit `a3b582e0` contains ONLY `assets/css/app.css` + `priv/static/accrue_admin.css`;
  pre-existing dirty files + `mix.lock` untouched; no `git add -A`.
- Did NOT run ratchet / `--verify-frozen` / Playwright — final PNG sign-off (subscriptions
  light+dark vs Customers reference) is the orchestrator's.

## Self-Check (Task 2): PASSED
- `accrue_admin/assets/css/app.css` — FOUND (modified, committed in a3b582e0)
- `accrue_admin/priv/static/accrue_admin.css` — FOUND (rebuilt, committed in a3b582e0)
- commit `a3b582e0` — FOUND in git log
