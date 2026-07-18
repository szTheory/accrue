---
quick_id: 260718-osx
slug: portal-billing-cadence-polish
status: complete
date: 2026-07-18
tasks_completed: 3
tasks_total: 3
files_changed: 9
commits:
  - ca5dd2f7
  - 690e03f2
  - 5f221975
---

# Quick Task 260718-osx: Polished + Cadence-branded customer billing portal — Summary

Wired the host brand bridge into the first-party `accrue_portal` and made the
portal's hand-written CSS fully token-driven with polish, so the mounted
customer portal at `/billing` now renders the host's configured brand (Cadence
green + secondary + font + logo/wordmark) with a clean neutral-Accrue fallback
for un-configured adopters. CSS + thin-markup only; no wording/behavior changes,
no new deps.

## What changed

### Task 1 — Token API + brand bridge + plug (commit `ca5dd2f7`)
- `accrue/priv/static/brand.css`: **additive-only** `--accrue-brand-*` bridge
  tokens (`accent` / `accent-strong` / `accent-contrast` / `secondary` / `font`)
  plus surface/shape polish tokens (`--accrue-surface`, `--accrue-surface-muted`,
  `--accrue-border`, `--accrue-shadow`, `--accrue-radius[-sm]`) with
  neutral-Accrue defaults, plus an optional `prefers-color-scheme: dark` surface
  pass. No existing `--accrue-*` token name was renamed or removed (stable v1.0
  API preserved).
- `accrue_portal/lib/accrue_portal/brand_plug.ex`: added `:font_stack` to the
  `Map.take/2` list so the portal consumes the host's configured font.
- `accrue_portal/lib/accrue_portal/layouts.ex`: `root/1` now emits a CSP-safe
  nonce'd `<style>` `:root{}` override built from `@brand` (only for present,
  sanitized values), plus a slim `.portal-topbar` (host `logo_url` `<img>` if
  set, else the `business_name` wordmark) wrapping every portal page.

### Task 2 — Token-driven CSS polish (commit `690e03f2`)
- `accrue_portal/priv/static/accrue_portal.css` rewritten to drive
  body/cards/buttons/links off the tokens; removed the hardcoded `#2f6e58`
  primary and the hardcoded body gradient. Added `:hover` + `:focus-visible`
  states on all interactive elements (visible focus rings), a type scale
  (h1/h2/h3), and new shared helpers: `.portal-topbar`, `.portal-subtitle`,
  `.portal-metric-label`, `.portal-status` pills (active/warning/info),
  `.portal-empty`, `.portal-link`, and `.portal-stack` (previously referenced by
  pages but undefined). Card/surface polish via the new tokens; extended the
  `max-width: 700px` responsive block.

### Task 3 — Per-page markup refinement (commit `5f221975`)
- Applied the shared classes across the pages that were under-marked-up:
  - `home_live`: `.portal-metric-label` on count headings, `.portal-empty`
    empty state, status pill on the recent-subscription status line.
  - `subscriptions_live` / `subscription_live`: status pills (variant derived
    from lifecycle status), `.portal-empty` state, consistent button-classed
    view/back CTAs.
  - `payment_methods_live`: `.portal-empty` state, default-method status pill.
  - `invoices_live`: `.portal-empty` state, status pill (variant from invoice
    status).
- `checkout_live` and `add_payment_method_live` were left as-is — already
  adequately marked up; they inherit the token-driven CSS lift automatically.
- Copy stays entirely in `copy.ex`; the only new functions are presentation-only
  private `status_variant/1` mappers (status atom → pill variant class).

## Deviations from Plan

None material. One small in-scope addition beyond the literal task text:
`.portal-metric-label` was defined under `.portal-shell .portal-metric-label`
(specificity bump) so it beats the base `.portal-shell h2` rule — required for
the metric-label markup to actually take effect. Also added a `.portal-stack`
rule (the class was already referenced by several pages but had no CSS).

## Guardrails honored
- Additive-only to `brand.css` (no `--accrue-*` renames/removals).
- Interpolated brand values sanitized before raw-emit: colors hex-only
  (`^#[0-9a-fA-F]{3,8}$`), font restricted to a safe declaration charset, logo
  URL restricted to http(s)/root-relative/`data:image`. The `<style>` element is
  nonce'd (CSP `style-src 'self' 'nonce-…'`); the whole tag is assembled in a
  helper and emitted as a raw safe string because HEEx treats `<style>` bodies
  as verbatim (a `{}`-interpolated body renders literally — verified and
  corrected during Task 1).
- Neutral-Accrue fallback renders when `@brand` is empty (no `<style>` override,
  token defaults apply).
- CSS + thin markup only; no wording/behavior changes; no new deps.
- Left pre-existing dirty working-tree files and `mix.lock` untouched — staged
  only intentionally-changed files. (`examples/accrue_host/mix.lock` shows an
  unrelated external churn from a background process; not staged, not touched.)
- Did NOT touch the `/app/billing` dunning-banner follow-up.

## Verification
- `cd accrue && mix compile --warnings-as-errors` → clean.
- `cd accrue_portal && mix compile --warnings-as-errors` → clean.
- `cd accrue_portal && mix test` → **36 tests, 0 failures**. No test needed
  modification: the status-pill span-wraps preserve the asserted text, the
  `home_live` `<p class="portal-metric">` markup is unchanged (its exact-regex
  assertion still holds), and the `subscription_live` recovery-banner
  `a.portal-button-primary` selector is preserved.
- `mix format --check-formatted` → clean on all changed Elixir files.
- Render-level check of `AccruePortal.Layouts.root/1`: with the Cadence brand,
  emits `<style nonce="…">:root{--accrue-brand-accent:#26785F;…}</style>` and a
  `.portal-topbar` wordmark; with an empty brand, emits no override `<style>`
  (neutral fallback) — confirmed.

### Live browser confirmation (deferred, non-blocking)
The running demo container (`accrue-host-web-1`) is a build that predates these
source changes — the monorepo path deps are compiled into the image, so a live
Playwright screenshot at `http://accrue.localhost/billing` would only reflect
these changes after a host recompile/rebuild. All binding verification gates
(dual compile clean, portal tests green, format clean) pass, and the branded
output was verified at the render + test level. A live screenshot pass should be
run after the next host rebuild.

## Follow-up captured (not fixed here)
- Unstyled dunning banner on `/app/billing`
  (`AccrueAdmin.Components.DunningBanner`) — separate `accrue_admin` quick task,
  intentionally out of scope.

## Self-Check: PASSED
- `accrue/priv/static/brand.css` — FOUND (committed `ca5dd2f7`)
- `accrue_portal/lib/accrue_portal/brand_plug.ex` — FOUND (committed `ca5dd2f7`)
- `accrue_portal/lib/accrue_portal/layouts.ex` — FOUND (committed `ca5dd2f7`)
- `accrue_portal/priv/static/accrue_portal.css` — FOUND (committed `690e03f2`, `5f221975`)
- 5 portal LiveViews — FOUND (committed `5f221975`)
- Commits `ca5dd2f7`, `690e03f2`, `5f221975` — all present in `git log`.
