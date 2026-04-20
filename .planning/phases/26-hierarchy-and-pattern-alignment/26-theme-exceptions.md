# Phase 26 — Theme exceptions (UX-04 registry)

**Purpose:** Single auditable list of **non-token** or **literal color** uses allowed on **Phase 26–touched** HEEx/CSS when semantic variables are insufficient.

**Rules:**

- Prefer **new semantic variables** in `theme.css` over literals in templates.
- Each row: **location** (path), **selector or region**, **rationale**, optional **link** (ADR, issue).

**Registry:** (append rows as exceptions are introduced)

| Location | Selector / region | Rationale | Link |
|----------|-------------------|-----------|------|
| `accrue_admin/lib/accrue_admin/live/*_live.ex` (`default_brand/0`) | `accent_hex` / `accent_contrast_hex` map literals | Package fallback when session omits brand; matches historical admin accent until host `Accrue.Config.branding/0` supplies values — **Phase 26 UX-04** inventory | — |
