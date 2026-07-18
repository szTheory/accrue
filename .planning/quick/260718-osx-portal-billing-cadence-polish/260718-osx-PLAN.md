---
quick_id: 260718-osx
slug: portal-billing-cadence-polish
status: planned
date: 2026-07-18
---

# Quick Task 260718-osx: Polished + Cadence-branded customer billing portal (`/billing`)

## Description

Make the customer billing portal at `http://accrue.localhost/billing` polished
and Cadence-branded. `/billing` is **not** a host page — it is rendered by the
first-party Accrue library **`accrue_portal`** (Accrue's shipped customer
self-service billing portal, module `AccruePortal.Live.HomeLive` + 6 sibling
LiveViews), which the host mounts via the `accrue_portal("/billing", ...)` router
macro. It has its OWN self-contained root layout (`AccruePortal.Layouts.root/1`)
and hand-written, committed CSS (`accrue_portal/priv/static/accrue_portal.css`,
`.portal-*` classes) that consumes color tokens from core `accrue`'s
`priv/static/brand.css`. It is a *third* surface, distinct from the Cadence host
(daisyUI/Tailwind) and Accrue Admin.

**Root cause (confirmed):**
1. **The brand bridge is plumbed but never rendered.** The demo config sets
   `business_name: "Cadence"`, `accent_color: "#26785F"`, `secondary_color:
   "#3E6E91"`. That flows BrandPlug → session → `AuthHook` → a `@brand` assign
   (ATOM keys) reaching `root/1` on both dead + live render — but the
   layout/pages never consume the accent, logo, or fonts. Only `business_name`
   surfaces (as the "Cadence billing" text). So Cadence's green never renders.
   `font_stack` is the only brand field not yet in BrandPlug's `Map.take`.
2. **The default CSS is thin AND hardcodes literals** — single 720px column, no
   type scale, no hover/focus states, primary CTA (`#2f6e58`) + body gradient
   hardcoded instead of tokens.

`accrue/guides/branding.md` already promises branding covers "the mounted
customer portal", so wiring the host brand into the portal delivers a
documented-but-unbuilt promise. There is no demo-only fix (CSS/layout live in the
library packages) — this is a small, principled change to first-party packages,
consistent with Accrue's "ship complete" posture.

**Decisions (confirmed with user):** Cadence-branded **+** polished (build the
host-brand bridge AND polish, with a clean neutral-Accrue fallback for
un-configured adopters); **full portal** (all 7 pages via the shared `.portal-*`
CSS + per-page markup refinement).

**Confirmed plumbing the bridge relies on:** CSP is `style-src 'self'
'nonce-<nonce>'` (`csp_plug.ex`) and `@csp_nonce` reaches the layout → a nonce'd
inline `<style nonce={@csp_nonce}>` brand bridge is CSP-safe; `img-src 'self'
data: https:` allows an https logo. `@brand` (atom keys) present on both dead +
live render.

## Guardrails (binding)

- **Additive-only to `brand.css`.** Keep existing `--accrue-*` token **names**
  stable (header calls them a stable v1.0 public API — renaming = breaking;
  adding is fine).
- **Sanitize interpolated brand values before raw-emitting** the inline style:
  hex-only for colors (already config-validated), safe charset for the font
  stack. Trust boundary is host-owned config, not user input — sanitize anyway.
- **Neutral-Accrue fallback must still render** with no host brand configured —
  un-configured adopters get the polished default.
- **CSS + thin layout/markup only.** NO wording/behavior changes — copy stays in
  `copy.ex`. NO new deps (portal CSS is hand-written & committed — edit directly,
  no build step; served md5-hashed, recompiled automatically).
- **Dark mode is an OPTIONAL stretch**, not required for "done".
- Leave pre-existing dirty working-tree files + `mix.lock` untouched.
- Do NOT touch the dunning-banner follow-up (see below).

## Task 1: Token API + brand bridge + plug

**Files:**
- `accrue/priv/static/brand.css`
- `accrue_portal/lib/accrue_portal/brand_plug.ex`
- `accrue_portal/lib/accrue_portal/layouts.ex`

**Action:**

1. **`accrue/priv/static/brand.css` (additive only)** — add brand-bridge + polish
   tokens with neutral-Accrue defaults (existing `--accrue-*` names untouched):
   - `--accrue-brand-accent: var(--accrue-moss);` (host overrides this)
   - `--accrue-brand-accent-strong: #4d8a70;` (hover/active)
   - `--accrue-brand-accent-contrast: #ffffff;`
   - `--accrue-brand-secondary: var(--accrue-slate);`
   - `--accrue-brand-font: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;`
   - `--accrue-surface: #ffffff;` `--accrue-surface-muted: var(--accrue-paper);`
   - `--accrue-border: var(--accrue-fog);`
   - `--accrue-shadow: 0 1px 2px rgba(17,20,24,.04), 0 12px 32px rgba(36,48,59,.06);`
   - `--accrue-radius: 14px;` `--accrue-radius-sm: 10px;`
   - Optional stretch: a `@media (prefers-color-scheme: dark)` block redefining
     surface/border/ink.
2. **`accrue_portal/lib/accrue_portal/brand_plug.ex`** — add `:font_stack` to the
   `Map.take/2` list so the portal can consume the host's configured font. One line.
3. **`accrue_portal/lib/accrue_portal/layouts.ex` — `root/1`:**
   - After the `<link>` tags, inject a nonce'd inline style overriding the
     brand-bridge tokens from `@brand` (only for present values). A private
     `brand_overrides/1` builds
     `:root{--accrue-brand-accent:…;--accrue-brand-accent-contrast:…;--accrue-brand-secondary:…;--accrue-brand-font:…}`
     from `@brand[:accent_color]` / `[:secondary_color]` / `[:font_stack]`,
     emitted via `<style nonce={@csp_nonce}>`. **Sanitize** interpolated values
     (hex-only for colors; safe charset for font) before raw-emitting.
   - Add a slim brand top bar as consistent chrome across every portal page:
     `<header class="portal-topbar">` showing `@brand[:logo_url]` `<img>` if set,
     else the `business_name` wordmark; wraps `@inner_content`. Keep it tasteful
     so it complements (not duplicates) each page's hero heading.

**Verify:** `cd accrue && mix compile` clean; `cd accrue_portal && mix compile`
clean. `@brand[:accent_color]` renders into the `:root` override on both dead +
live render; with no host brand configured, the neutral-Accrue defaults render.

**Done:** Cadence accent/secondary/font + logo/wordmark flow from `@brand`
through a CSP-safe nonce'd `<style>` and a `.portal-topbar`; `font_stack` reaches
the portal; un-configured fallback still renders.

## Task 2: Token-driven CSS polish

**Files:** `accrue_portal/priv/static/accrue_portal.css`

**Action:** Kill hardcoded literals; drive everything from the Task-1 tokens.

- `body`: `--accrue-brand-font` + token background (drop the hardcoded
  gradient/font stack).
- `.portal-button-primary`: `var(--accrue-brand-accent)` /
  `--accrue-brand-accent-contrast` + **`:hover` and `:focus-visible`** states
  (currently none) using `--accrue-brand-accent-strong` + focus ring. Kill `#2f6e58`.
- `.portal-nav a` / `.portal-button-secondary`: token surfaces + hover/focus.
- `.portal-card`: `--accrue-surface` / `--accrue-border` / `--accrue-shadow` /
  `--accrue-radius`.
- Type scale for `h1` / `h2`; new `.portal-metric-label` (the count `<h2>`s are
  unstyled today); tighten `.portal-metric`.
- New shared helpers applied across pages: `.portal-topbar`, `.portal-subtitle`,
  `.portal-status` (semantic pill: moss/amber/cobalt), `.portal-empty`
  (empty-state), `.portal-link`.
- `a` links → brand secondary/accent + hover underline; `:focus-visible` outlines
  on all interactive elements.
- Keep + extend the responsive `@media (max-width:700px)`. Optional
  `prefers-color-scheme: dark` (stretch).

**Verify:** `cd accrue_portal && mix compile` clean (served CSS is md5-hashed at
compile time → new hash picked up automatically). No hardcoded `#2f6e58` or
hardcoded body gradient remain; `.portal-button-primary` reads
`var(--accrue-brand-accent)` and has `:hover`/`:focus-visible` states.

**Done:** portal CSS is token-driven with a type scale, card/surface polish,
hover + visible focus states, and the new shared helper classes.

## Task 3: Per-page markup refinement (all 7 portal LiveViews)

**Files (all under `accrue_portal/lib/accrue_portal/live/`):**
- `home_live.ex`
- `subscriptions_live.ex`
- `subscription_live.ex` (incl. the `render(%{subscription: nil})` empty clause)
- `payment_methods_live.ex`
- `add_payment_method_live.ex`
- `invoices_live.ex`
- `checkout_live.ex`

**Action:** Apply the new shared classes so every page looks finished — most
inherit the CSS lift automatically; add classes only where under-marked-up.
**Copy stays in `copy.ex` (no wording changes).**

- `home_live.ex`: `.portal-empty` wrapper, `.portal-metric-label` on the counts,
  `.portal-status` on the status line.
- The remaining six (`subscriptions_live.ex`, `subscription_live.ex`,
  `payment_methods_live.ex`, `add_payment_method_live.ex`, `invoices_live.ex`,
  `checkout_live.ex`): consistent status pills (`.portal-status`), empty-states
  (`.portal-empty`), headings, and button classes.

**Verify:** `cd accrue_portal && mix compile` clean; `cd accrue_portal && mix
test` green (watch for tests asserting `.portal-*` markup or brand text — update
markup, not copy). Live Playwright on `http://accrue.localhost/billing` (log in
via a persona — e.g. Ops Manager past-due, or Team Lead): confirm (a) Cadence
green on CTAs/eyebrow, (b) polished cards/type/hover+focus, (c) logo/wordmark
topbar, (d) walk nav → subscriptions/invoices/payment-methods show consistent
styling. Keyboard-tab the CTAs → visible focus rings.

**Done:** all 7 portal pages render finished and consistently styled with the
shared classes; no wording/behavior changes.

## Verification (overall)

1. `cd accrue && mix compile` → clean.
2. `cd accrue_portal && mix compile` → clean.
3. `cd accrue_portal && mix test` → green (watch for tests asserting `.portal-*`
   markup / brand text).
4. Recompile/reload the demo host (served portal CSS is md5-hashed at compile
   time → new hash picked up automatically). Playwright on
   `http://accrue.localhost/billing` (log in via a persona): confirm (a) Cadence
   green on CTAs/eyebrow, (b) polished cards/type/hover+focus, (c) logo/wordmark
   topbar, (d) walk nav → subscriptions/invoices/payment-methods show consistent
   styling. Compare against the bare "before" screenshot.
5. Keyboard-tab the CTAs → visible focus rings (accessibility).

## Follow-up captured (separate task — do NOT fix now)

- **Unstyled dunning banner on `/app/billing`.** "Action Required: We were unable
  to process your recent payment…" renders as raw unstyled text. Source:
  `AccrueAdmin.Components.DunningBanner.dunning_banner`, invoked inside the host
  `Layouts.app/1`
  (`examples/accrue_host/lib/accrue_host_web/components/layouts.ex`). Same class
  of problem (a first-party Accrue component whose styling doesn't land in the
  Cadence host), but a separate `accrue_admin` component → its own quick task.
  User asked to note, not fix now.
