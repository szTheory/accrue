# Accrue Brand Tokens

`brandbook/tokens/` is the brand-layer token system for Accrue. It documents the seven `--accrue-*` raw palette values, their semantic roles, and how they relate to the admin `--ax-*` implementation tokens.

---

## Generation

`tokens.json` is the **single source of truth (SSOT)** for brand tokens (D-01). `tokens.css` is **GENERATED** — never hand-edit it.

```
node brandbook/tokens/harness/generate-tokens-css.mjs
# or: cd brandbook/tokens/harness && npm run generate
```

CI re-runs the generator and asserts `git diff --exit-code brandbook/tokens/tokens.css`. Any hand-edit to `tokens.css` will fail the determinism gate (D-17, T-184-05).

`node_modules/` is gitignored. Reinstall in CI with:

```
cd brandbook/tokens/harness && npm ci
```

---

## Raw palette + semantic roles

The value-enforced brand layer lives in:

- **`tokens.json`** — DTCG v2025.10 SSOT with structured `$value` objects, `$extensions`, and axMap annotations
- **`tokens.css`** — generated CSS custom properties consumed by admin `theme.css` (via `var(--accrue-*)`)

Seven raw tokens: `--accrue-ink`, `--accrue-slate`, `--accrue-fog`, `--accrue-paper`, `--accrue-moss`, `--accrue-cobalt`, `--accrue-amber`.

Semantic roles (value-enforced, all in `tokens.css`):
- **Surface** — `--accrue-surface-base`, `--accrue-surface-elevated`, `--accrue-surface-sunken`
- **Content** — `--accrue-content-primary`, `--accrue-content-muted`, `--accrue-content-subtle`
- **Interactive** — `--accrue-interactive-accent`, `--accrue-interactive-focus-ring`
- **Feedback** — `--accrue-feedback-success`, `--accrue-feedback-warning`, `--accrue-feedback-danger`, `--accrue-feedback-info`
- **Dark counterparts** — all dark-mode roles in a `:root[data-theme="dark"]` block

---

## Reference-only scales (D-11)

Typography, spacing, radius, focus-ring, and state tokens are **reference-only** in the brand layer. The admin `--ax-*` tokens in `accrue_admin/assets/css/theme.css` are the authoritative implementation SSOT. Scale tokens (`--ax-space-*`, `--ax-radius-*`, `--ax-type-*`) are not minted as additional `--accrue-*` properties — doing so would create a parallel layer that drifts from the admin implementation.

The table below maps brand category to admin token name for design documentation and spec communication.

### Typography

| Brand category | Admin token(s) | Value | Notes |
|---|---|---|---|
| Body font stack | `--ax-font-sans` | `"Geist", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif` | reference-only; admin SSOT — not minted as `--accrue-*` |
| Monospace font stack | `--ax-font-mono` | `"Geist Mono", "SFMono-Regular", "SF Mono", Consolas, "Liberation Mono", monospace` | reference-only; admin SSOT — not minted as `--accrue-*` |
| Type size xs | `--ax-type-xs` | `0.75rem` (12px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Type size sm | `--ax-type-sm` | `0.875rem` (14px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Type size md | `--ax-type-md` | `1rem` (16px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Type size lg | `--ax-type-lg` | `1.25rem` (20px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Type size xl | `--ax-type-xl` | `1.5rem` (24px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Type size 2xl | `--ax-type-2xl` | `1.75rem` (28px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Type size 3xl (display) | `--ax-type-3xl` | `2.25rem` (36px) | reference-only; admin SSOT — not minted as `--accrue-*` |

### Spacing (4px base grid)

| Brand category | Admin token(s) | Value | Notes |
|---|---|---|---|
| Space 2xs | `--ax-space-2xs` | `0.125rem` (2px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Space xs | `--ax-space-xs` | `0.25rem` (4px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Space sm | `--ax-space-sm` | `0.5rem` (8px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Space md | `--ax-space-md` | `1rem` (16px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Space lg | `--ax-space-lg` | `1.5rem` (24px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Space xl | `--ax-space-xl` | `2rem` (32px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Space 2xl | `--ax-space-2xl` | `3rem` (48px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Space 3xl | `--ax-space-3xl` | `4rem` (64px) | reference-only; admin SSOT — not minted as `--accrue-*` |

### Radius

| Brand category | Admin token(s) | Value | Notes |
|---|---|---|---|
| Radius 2xs | `--ax-radius-2xs` | `0.25rem` (4px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Radius sm | `--ax-radius-sm` | `0.5rem` (8px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Radius md | `--ax-radius-md` | `0.625rem` (10px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Radius lg | `--ax-radius-lg` | `0.875rem` (14px) | reference-only; admin SSOT — not minted as `--accrue-*` |
| Radius pill | `--ax-radius-pill` | `999px` | reference-only; admin SSOT — not minted as `--accrue-*` |

### Focus ring

| Brand category | Admin token(s) | Value | Notes |
|---|---|---|---|
| Focus ring color | `--ax-focus-ring` | `color-mix(in oklch, var(--ax-accent) 70%, white)` | Brand spec: 2px solid Cobalt (#5D79F6) focus ring, 2px offset — WCAG 2.4.11 compliant (BRAND-AUDIT §7 item 6). Admin value is a `color-mix()` from accent, not a flat hex — not value-checked. reference-only; admin SSOT — not minted as `--accrue-*` |

### State tokens

| Brand category | Admin token(s) | Notes |
|---|---|---|
| Hover / active | Composed from `--ax-accent-subtle`, `--ax-accent-soft`, `--ax-accent-border` | Named accent-mix steps (color-mix from `--ax-accent`); theme-aware, auto-adapt in dark mode. reference-only; admin SSOT — not minted as `--accrue-*` |
| Disabled | Composited with `--ax-muted` (reduced-opacity treatment via CSS `opacity` or muted color) | Convention: `opacity: 0.4` on disabled surfaces using `--ax-muted` as text; no named `--ax-disabled-*` token currently. reference-only; admin SSOT — not minted as `--accrue-*` |
| Loading / skeleton | Shimmer animation via `background-position` — avoids `background-color` shorthand conflict with `--ax-transition-colors` | Skeleton background uses `--ax-sunken` as base; no named `--ax-loading-*` token currently. reference-only; admin SSOT — not minted as `--accrue-*` |

---

## Brand-only tokens (D-09b)

Four token groups have **no upstream `--ax-*` counterpart** and are documented in `tokens.json` with `axMap: null`. They appear in `tokens.css` with a `/* brand-only: no --ax-* counterpart */` comment:

| Token | Hex | Description |
|---|---|---|
| `--accrue-fog` | `#e9eef2` | Soft neutral light — section backgrounds. No current `--ax-*` semantic binding. |
| `--accrue-cobalt` | `#5d79f6` | Interactive / link states, focus rings. Host app binds this to `--ax-accent`; no flat `--ax-accent` exists in `theme.css`. |
| `--accrue-code-block-surface` | `#e9eef2` | Code block background (= Fog). New brand-layer definition (D-09b); one-line PR ratification recommended. |
| `--accrue-code-block-text` | `#24303b` | Code block foreground (= Slate). New brand-layer definition (D-09b); AAA on Fog surface. |
| `--accrue-callout-surface` | `#f1f5f8` | Callout box background (= Sunken). New brand-layer definition (D-09b); one-line PR ratification recommended. |
| `--accrue-callout-text` | `#111418` | Callout box foreground (= Ink). New brand-layer definition (D-09b); AAA on callout surface. |
| `--accrue-interactive-accent` | `#5d79f6` | Semantic role — equals Cobalt. Brand-only; `--ax-accent` is host-supplied. |
| `--accrue-interactive-focus-ring` | `#5d79f6` | Semantic role — equals Cobalt; see focus-ring spec above. |

The `code-block` and `callout` values are new brand-layer definitions authored in Phase 184 and derived from the existing Fog/Slate/Ink neutral family. They are flagged for one-line PR ratification per D-09b.

---

## Verification

```bash
# Structural completeness assertion (SC#1)
node brandbook/tokens/harness/verify-tokens.mjs

# Regenerate and verify determinism gate
node brandbook/tokens/harness/generate-tokens-css.mjs
git diff --exit-code brandbook/tokens/tokens.css
```
