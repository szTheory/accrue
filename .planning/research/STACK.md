# Stack Research — v1.57 M1 (Admin Operator Control Plane, IA/grammar pivot)

**Domain:** `accrue_admin` LiveView admin UI — information-architecture + component-cohesion pivot on two outlier pages (Home/dashboard + Subscriptions)
**Researched:** 2026-07-19
**Confidence:** HIGH (grounded in `accrue_admin/mix.exs`, the shipped component library under `lib/accrue_admin/components/`, the two outlier LiveViews, the bespoke `.ax-*` selector census, and the `accrue_admin.assets.build` mix task — not speculation)

## Bottom Line

**No stack additions or changes are needed for M1.** The prior is confirmed: M1 is a pure *composition + IA* exercise on top of an already-mature shared component library and `ax-*` token system. Every building block the pivot requires already ships in `accrue_admin`. The work is *retiring* bespoke markup/CSS on the two outlier pages and re-expressing them with the canonical vocabulary the other ~10 pages already use — not adding technology.

The only defensible **new authored artifact** is a single small shared LiveView function component (a work-queue "callout"/attention strip), built entirely from existing tokens and `.ax-card` — **not a dependency, not a build-tool change, not a token-system change.** Its addition is explicitly pre-authorized by the milestone scope ("one small new shared component allowed only if a work-queue 'callout' shape clearly repeats") and the evidence below shows the shape *does* repeat.

## Recommended Stack

### Core Technologies (all already present — zero change)

| Technology | Version | Purpose | Why (no change) |
|------------|---------|---------|-----------------|
| `:phoenix_live_view` | `~> 1.1` | Renders the admin pages being reworked | Already the admin runtime; the pivot is HEEx re-composition inside existing LiveViews (`dashboard_live.ex`, `subscriptions_live.ex`). No LV feature is missing. |
| `:phoenix` | `~> 1.8` | Router/endpoint | Unchanged — no new routes required by an IA/grammar pivot. |
| `:phoenix_html` | `~> 4.2` | HEEx helpers | Unchanged. |
| `:accrue` (path / `== version`) | `1.4.0` | Billing domain data the pages render | **No core change in M1** — that is explicitly M2 (`blocking_reason_for_owner/1` et al). M1 renders data the outlier pages already load. |
| `ax-*` CSS + design tokens | in-repo (`assets/css/theme.css` + `app.css`) | Styling SSOT (1,452 `.ax-*` rules) | Stays the styling SSOT. The pivot *reduces* bespoke rules; it does not add a styling system. |

### Shared Components to REUSE (the whole M1 toolbox — already shipped)

All under `accrue_admin/lib/accrue_admin/components/`. These are the canonical vocabulary the non-outlier pages (e.g. `invoices_live.ex`, `charges_live.ex`) already compose; M1 brings Home + Subscriptions onto the same set.

| Component | File | Role in M1 |
|-----------|------|-----------|
| `PageHeader` | `page_header.ex` | Breadcrumb/title/actions/stat-strip/filter-toolbar chrome — the "one page header" idiom. Subscriptions already uses it; Home should adopt it. |
| `StatStrip` | `stat_strip.ex` | Quiet inline metric row (`<dl>`) with `moss`/`cobalt`/`amber` tones + optional `href`. The answer-first summary metric row. |
| `KpiCard` | `kpi_card.ex` | Dashboard/detail KPI band (`.ax-card`-based, linkable). Replaces bespoke `.ax-launcher*`/`.ax-home-*` metric tiles on Home. |
| `DataTable` (`filter_toolbar/1`) | `data_table.ex` (31 KB) | Canonical list table + cell idiom + filter toolbar. Subscriptions already imports it. |
| `FilterChipBar` | `filter_chip_bar.ex` | URL-synced active-filter chips + result count + clear-all. |
| `Button` | `button.ex` | `primary`/`secondary`/`ghost`/`danger` variants (anchor or button, loading/disabled). The "one primary action per zone" affordance. |
| `StatusBadge` | `status_badge.ex` | Semantic lifecycle badge with fixed tone mapping — replaces bespoke `.ax-attention-pill*` / `.ax-launcher-health*` inline pills. |
| `EmptyState` | `empty_state.ex` | Non-celebratory empty hero (icon/title/body + optional CTA) — replaces bespoke `.ax-attention-rail--empty` / record-empty markup. |
| `DropdownMenu` (`dropdown_menu/1`, `action_menu/1`) | `dropdown_menu.ex` | Per-row / per-zone action disclosure (link-shaped and event-shaped). Use for any "more actions" the pivot introduces — do **not** hand-roll a menu. |
| `Timeline` | `timeline.ex` | Vertical event/audit timeline — reuse for the Subscriptions "audit trail" strip instead of bespoke `.ax-subscriptions-audit-*`. |
| `Icon` | `icon.ex` | Heroicon set — already used by the bespoke markup; carries over unchanged. |

### One Genuinely-Needed New Component (authored, not a dependency)

| Artifact | Type | Why it's justified |
|----------|------|--------------------|
| `Callout` / `WorkQueueStrip` (working name) | New shared `Phoenix.Component` in `lib/accrue_admin/components/`, styled with existing tokens + `.ax-card` | The work-queue "callout" shape **demonstrably repeats** across both outlier pages (evidence below). Extracting it into one component is the correct way to converge them onto shared vocabulary — the alternative (leaving it as per-page bespoke markup) is exactly the outlier problem M1 exists to fix. |

**Evidence the shape repeats (this is the gate the milestone set):**
- **Home** (`dashboard_live.ex`): the "attention rail" renders `.ax-attention-row` items, each carrying `{priority, severity-tone dot, label text, optional pill, action}` — a severity-toned, action-terminated work-queue row.
- **Subscriptions** (`subscriptions_live.ex`): **three** separate `.ax-inline-worklist` strips (open-invoice strip, at-risk strip, audit strip), each carrying `{copy, exposure/count metric, primary action button}` and a danger variant — the same conceptual shape, duplicated three times.

Four+ near-duplicate instantiations of one shape across two pages is a clear DRY signal. Recommend a single `Callout`/`WorkQueueStrip` component with a `tone`/severity attr, a metric/exposure slot, and one primary-action slot. Keep it **one** component — do not spawn a family (no separate `AttentionCard` + `WorklistStrip` + `HealthSummary`; converge them).

### Development Tools (unchanged)

| Tool | Purpose | Notes |
|------|---------|-------|
| `mix accrue_admin.assets.build` | Rebuilds committed `priv/static/accrue_admin.css` (+ `.js`) | **Load-bearing integration step.** Editing `assets/css/*.css` ships nothing until this runs and the 155 KB `priv/static/accrue_admin.css` bundle is rebuilt and committed (prior lesson: Phase 189 shipped dead CSS by skipping this). |
| `tailwindcss@3.4.17` CLI (via `npx`, `--minify`) | Compile-time CSS minifier only | Invoked *by* the build task on `assets/css/app.css`. This is the "Tailwind = compile-time minifier, not an authoring path" guardrail in the flesh — **do not** author utility classes; author `ax-*` in `theme.css`/`app.css`. |
| `esbuild@0.25.3` (via `npx`) | JS bundling | Untouched by an IA/CSS pivot; M1 is HEEx + CSS. |
| `phoenix_storybook` / `mailglass_admin` (`dev/test` only) | Component lab / mail preview | Existing dev deps. A new `Callout` component *should* get a storybook entry for parity, but that reuses existing dev-only tooling — no new dep. |

## Installation

```bash
# No dependency changes. mix.exs deps/0 stays exactly as-is.
# The only build action after editing HEEx + assets/css:
mix accrue_admin.assets.build     # rebuild priv/static/accrue_admin.css
# then commit the regenerated bundle alongside the source changes.
```

## Alternatives Considered

| Recommended | Alternative | When the alternative would apply |
|-------------|-------------|----------------------------------|
| Reuse shared components as-is | Fork/duplicate components per page | Never here — forking is the outlier disease M1 cures. Compose, don't fork. |
| One `Callout`/`WorkQueueStrip` component | Keep bespoke `.ax-attention-*` + `.ax-inline-worklist-*` markup | Only if the shape did *not* repeat — but it repeats 4+ times, so extract. |
| One `Callout` component | A component *family* (AttentionCard + WorklistStrip + HealthSummary) | Only if the shapes genuinely diverge in structure; current evidence says they're one shape with a tone/severity variant — keep it single. |
| `Timeline` for the audit strip | Bespoke audit markup | Only if audit needs a structure Timeline can't express; it doesn't for a preview strip. |
| `mix accrue_admin.assets.build` | Hand-editing `priv/static/accrue_admin.css` | Never — the bundle is generated; hand-edits get clobbered on next build. |

## What NOT to Use / NOT to Add

| Do NOT add/do | Why | Instead |
|---------------|-----|---------|
| **Any new Hex/npm dependency** | M1 needs zero new capability; the component library + tokens already cover it. Adding a dep expands the audit/security/version-matrix surface for no gain. | Compose existing components. |
| **A Tailwind authoring migration** | Explicitly out of scope and against the standing `ax-*`-SSOT guardrail; Tailwind is only the compile-time minifier. | Author `ax-*` in `theme.css`/`app.css`. |
| **Any core `accrue` change / new billing primitive** | That is M2 (core diagnosis fns) — M1 is admin-only and renders data the pages already load. Core stays LiveView-runtime-free. | Render existing loaded data; defer diagnosis fns to M2. |
| **A replacement for `ax-*`** (new class system, CSS-in-JS, utility-first authoring) | `ax-*` is the styling SSOT (1,452 rules) and the ratchet baseline is anchored to it. | Extend `ax-*` with the new component's classes. |
| **A new charting/JS/date/icon library** | An IA/grammar pivot introduces no new visual primitive that `Icon` + existing CSS can't render. | `Icon` (heroicons) + existing tokens. |
| **`accrue_portal` work** | Out of scope for SEED-004 M1. | N/A. |
| **A hand-rolled dropdown/menu for per-row actions** | `DropdownMenu.dropdown_menu/1` + `action_menu/1` already exist with the accessible disclosure + drawer/step-up event wiring. | Reuse `DropdownMenu`. |
| **New routes / API changes** | Not required by re-composing existing pages. | Keep existing routes. |

## Net CSS Delta (why "no additions" still means real work)

The pivot **removes** bespoke rule sets — it is subtractive, not additive:

| Bespoke selector prefix (page) | Unique selectors (approx) | Fate under M1 |
|-------------------------------|---------------------------|---------------|
| `.ax-home-*` (Home) | ~14 | Retire → `PageHeader` + `StatStrip`/`KpiCard` |
| `.ax-launcher*` (Home) | ~14 | Retire → `KpiCard`/`Button` zones |
| `.ax-attention*` (Home) | ~19 | Retire → new `Callout`/`WorkQueueStrip` |
| `.ax-subscriptions-*` (Subscriptions) | ~31 | Retire → shared header/table/strip vocabulary |
| `.ax-inline-worklist*` (Subscriptions) | ~3 | Retire → new `Callout`/`WorkQueueStrip` |

PROJECT.md's "~325 rules" figure is these prefixes' *full* rule bodies (incl. variants/nested/responsive rules), consistent with the ~81 unique top-level selectors counted here. Net: one new small component's worth of `ax-*` rules **added**, several hundred bespoke rules **removed** → smaller, more cohesive bundle.

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `phoenix_live_view ~> 1.1` | `phoenix ~> 1.8`, `phoenix_html ~> 4.2` | Already resolved and shipping; M1 adds nothing to resolve. |
| `tailwindcss@3.4.17` (build-time) | current `assets/css/app.css` | Pinned in the build task; M1 must not bump it (no reason to). |
| new `Callout` component | existing tokens in `theme.css` | Compiles into the same bundle via the same build task — zero new toolchain. |

## Sources

- `accrue_admin/mix.exs` (deps/0, verified 2026-07-19, HIGH) — no new dep required; deps list is stable.
- `accrue_admin/lib/accrue_admin/components/{page_header,stat_strip,filter_chip_bar,dropdown_menu,kpi_card,button,status_badge,empty_state,timeline}.ex` (HIGH) — confirmed the shared vocabulary already exists and is sufficient.
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` + `subscriptions_live.ex` (HIGH) — confirmed the bespoke `.ax-home-*`/`.ax-launcher*`/`.ax-attention*` and `.ax-subscriptions-*`/`.ax-inline-worklist*` markup and the *repeating* work-queue shape (Home attention rail + 3× Subscriptions worklist strips).
- Bespoke selector census over `assets/` (HIGH) — 14 + 14 + 19 + 31 + 3 unique selectors for the retiring prefixes; 1,452 total `.ax-*` rules.
- `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` (HIGH) — confirmed the build pipeline (Tailwind CLI minify → committed `priv/static/accrue_admin.css`; esbuild for JS) and the "Tailwind = compile-time minifier" guardrail.
- `.planning/PROJECT.md` (v1.57 Current Milestone) + `.planning/seeds/SEED-004-admin-ui-blueprint-redesign.md` (HIGH) — M1 scope, admin-only constraint, one-new-component latitude, `ax-*`-SSOT + no-Tailwind-migration guardrails.

---
*Stack research for: v1.57 M1 admin IA/grammar pivot (accrue_admin-only)*
*Researched: 2026-07-19*
