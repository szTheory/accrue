---
phase: 21-admin-and-host-ux-proof
slug: admin-and-host-ux-proof
status: approved
shadcn_initialized: false
preset: none
created: 2026-04-17
---

# Phase 21 — UI Design Contract

> Visual and interaction contract for admin + host VERIFY-01 proof surfaces. **Inherits Phase 20 admin/host tokens and copy**; adds list signals, tax-health tri-state, and evaluator-facing host demo chrome.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none |
| Preset | not applicable |
| Component library | Phoenix LiveView + existing `ax-*` admin components + host Tailwind/daisyUI |
| Icon library | Heroicons only where already used in touched surfaces |
| Font | Same system stack as Phase 20 (`examples/accrue_host/assets/css/app.css`, `accrue_admin/assets/css/theme.css`) |

Source: `.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md` remains the baseline; Phase 21 does not introduce new UI kits or registries.

---

## Spacing Scale

Same as Phase 20: multiples of 4px; 44px minimum hit targets for compact actions.

**Phase 21 additions:**

- **List signal chips** (ownership + tax health on money indexes): use `sm` gap between the two chips and `md` padding from row edge; never stack more than two chips in the primary row — overflow goes to detail.
- **Tax & ownership card** on detail: single `ax-card` (or equivalent) at `lg` padding; internal sections separated by `md`, no nested card.

---

## Typography

Inherit Phase 20 table (body 16px / label 14px semibold / heading 20px / display 28px).

**List signals:** render chip label text at **12px semibold** uppercase only if it matches existing admin “eyebrow” pattern elsewhere; otherwise use **14px semibold** sentence case for tri-state labels (`Off`, `Active`, `Invalid or blocked`) to preserve readability.

---

## Color

Inherit Phase 20 semantic tokens (`--ax-base`, `--ax-accent`, warning/error for risk).

**Tax health tri-state (must not read as binary “tax on”):**

| State | Visual treatment |
|-------|------------------|
| `off` | Muted neutral surface + neutral text (tax not applicable or disabled) |
| `active` | Success-adjacent **border or dot only** — not a full green fill bar |
| `invalid_or_blocked` | Warning/error border + warning text — **always** paired with short explanation in detail card |

Ownership class (`User` vs `Org`): use the same **scoped-owner badge** treatment as Phase 20 (`var(--ax-accent)` border for emphasis only on the badge, not the whole row).

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA (host org billing) | Start organization subscription (unchanged where already present) |
| Tax invalid / blocked headline | Tax location needs attention |
| Tax invalid / blocked body | Update the customer tax location before tax-enabled charges can proceed. |
| Empty index signal | — (indexes keep existing empty tables; do not add marketing empty states in Phase 21) |
| Cross-org denial (admin) | `You don't have access to billing for this organization.` (exact — locked in Phase 20) |
| Ambiguous webhook replay | `Ownership couldn't be verified for this webhook. Replay is unavailable until the linked billing owner is resolved.` |

**Tenant chrome (`?org=` active):**

| Element | Copy |
|---------|------|
| Shell label | Active organization |
| Value | Human-readable **organization display name** (not raw slug in primary chrome; slug may appear in secondary text or URL only) |

Copy rules (from CONTEXT D-02/D-03):

- Name **organization** consistently in host-facing copy; use **owner** in admin only when exposing model-level fields.
- No raw JSON blobs, processor IDs in primary chrome, or “tenant/scope/policy” jargon in user-facing strings.
- Playwright and integration assertions must target **these** strings — do not invent parallel UX copy in tests.

---

## Interaction Contract

1. **Money-relevant indexes** (`customers`, `subscriptions`, `invoices`, `charges`): each row shows **exactly two** compact derived signals: (1) ownership class, (2) tax health tri-state, both from the **same** classification function as detail (CONTEXT D-02).
2. **Detail pages**: authoritative **Tax & ownership** card with plain language, effective behavior, blockers, next steps.
3. **`?org=` preservation**: every `link`, `navigate`, and `push_patch` from Phase 20 patterns must keep org query when org scope is active; new Phase 21 links must be checked for dropped `?org=`.
4. **Playwright**: desktop Chromium full matrix on PR; mobile as **tagged** subset (`@mobile`) or CI schedule per CONTEXT D-01.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not required |
| Third-party | none | not required |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS (inherits Phase 20 + Phase 21 locked strings)
- [x] Dimension 2 Visuals: PASS (chips + card patterns defined)
- [x] Dimension 3 Color: PASS (tri-state semantics)
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-04-17 (derived from `21-CONTEXT.md` + `20-UI-SPEC.md` for Cursor plan-phase where full `gsd-ui-phase` pipeline is unavailable)
