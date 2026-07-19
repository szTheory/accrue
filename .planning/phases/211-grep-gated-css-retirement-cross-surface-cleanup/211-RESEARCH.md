# Phase 211: Grep-gated CSS retirement & cross-surface cleanup - Research

**Researched:** 2026-07-19
**Domain:** CSS dead-code retirement in a Phoenix/LiveView admin package (grep-based liveness census, Tailwind bundle rebuild, dev-tooling secondary-surface cleanup)
**Confidence:** HIGH (every finding below is `[VERIFIED: codebase grep/read]` against the actual repository state on 2026-07-19, cross-validated against the Phase 209-03 / 210-03 SUMMARY.md grep-gate results, not training-data assumptions)

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REIGN-04 | Retire bespoke `.ax-home-*`/`.ax-launcher*`/`.ax-attention*`/`.ax-subscriptions-*`/`.ax-inline-worklist*`/`.ax-subscription-row-*` CSS (grep-gated — ONLY zero-reference classes; classes still used by `subscription_live.ex` preserved), rebuild the committed bundle, migrate test/e2e selectors in the same phase | Full class-by-class census below (`## Class Census`) is the direct implementation input; `## Bundle Rebuild` gives exact commands; `## Test/E2E Migration Surface` proves zero migrations are actually needed (already done in 209/210) |

No CONTEXT.md exists for this phase yet (directory was empty at research time) — no locked user decisions to carry forward. The ROADMAP.md Phase 211 entry and REQUIREMENTS.md REIGN-04 text are the binding scope definition and are treated as authoritative constraints throughout this document.
</phase_requirements>

## Summary

The safe-retirement approach is: (1) run an exact-token grep census (not substring matching — see Risks) across `lib/`, `test/`, `e2e/` for every selector actually defined under the eight named `.ax-*` prefix families in `assets/css/app.css`; (2) delete only the rule blocks whose selector has zero references anywhere in the three trees, being careful with comma-separated and compound selectors that mix a dead class with a still-live one; (3) rebuild `priv/static/accrue_admin.css`/`.js` via the existing `mix accrue_admin.assets.build` task and manually recompose `priv/static/storybook.css` (which has no dedicated rebuild task — it is a hand-composed concatenation of three parts); (4) confirm the component kitchen needs **no markup changes** (it never referenced any of the dead classes) and only the ratchet's `region-tags.js` needs a one-line selector fix; (5) confirm — via a project-wide grep, not assumption — that **zero test/e2e assertions reference any of the 92 dead classes**, because Phases 209 and 210 already migrated their own selectors as part of their own success criteria, so REIGN-04's "migrate test/e2e assertions" clause is already satisfied and this phase's job is verification, not migration.

Of the 108 unique class selectors defined across the eight candidate families, **92 are dead (zero references) and safe to delete**, and **16 are live and must be preserved** — including some that are NOT the ones the ROADMAP explicitly names as shared (`.ax-inline-worklist*`, `.ax-audit-summary-row`), but also several `.ax-home-*`/`.ax-launcher*`/`.ax-attention*` classes that Phase 210 deliberately **kept** as the new reigned markup's own structural wrapper classes (confirmed by an explicit in-CSS comment: `/* Phase 210 — reigned three-tile launcher grid (additive). ... this layer does not touch any .ax-launcher* rule (Phase 211 retires those). */`). One class in particular — `.ax-subscription-setup-gap` — is a genuine landmine: it is named inside the "ax-subscription-setup*" family the ROADMAP/success-criteria list for retirement, but it is **actively rendered today** by `subscriptions_live.ex`'s compact cell idiom (the very idiom Phase 209 built) and must be preserved, not deleted.

**Primary recommendation:** Delete the 92 zero-reference selectors (grouped below), preserve the 16 live ones verbatim, rebuild both `accrue_admin.css`/`.js` (via the mix task) and `storybook.css` (via manual recomposition — no task exists), fix the single dangling `region-tags.js` selector, and treat the "test/e2e migration" success-criterion clause as a verification step (grep confirms clean) rather than an editing step.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CSS rule retirement (source) | Frontend Server (SSR component library) | — | `assets/css/app.css` is the Tailwind-processed source-of-truth for the `accrue_admin` LiveView package; it has no browser-tier or API-tier component. |
| Served CSS bundle | Frontend Server (SSR component library) | CDN/Static (served as an immutable, hashed, cache-control:max-age=31536000 asset via `AccrueAdmin.Assets` plug) | `priv/static/accrue_admin.css` is compiled at "build time" (a mix task, not deploy-time) and then served as a static, hash-named, browser-cacheable artifact — a hybrid of Frontend-Server-owned source and CDN-style immutable delivery. |
| Dev-only component kitchen / Storybook | Frontend Server (dev/test-only LiveView routes, `if Mix.env() != :prod`) | — | Never reachable in prod (`Code.ensure_loaded?` + env guards); purely a design/QA surface, no runtime/API tier involvement. |
| Ratchet `region-tags.js` selector map | Frontend Server (dev/test tooling, Node.js, off the deploy path) | — | Pure identity/selector-mapping metadata for the parked, maintainer-run v1.56 ratchet; never executes in the shipped admin app. |
| Test/e2e selector assertions | Frontend Server (LiveView unit tests) + Browser (Playwright e2e) | — | Split naturally between ExUnit/Floki (server-rendered HTML assertions) and Playwright (real browser DOM/CSS assertions). |

## Class Census

Methodology: for each of the 108 unique `.ax-*` class-selector names actually defined in `accrue_admin/assets/css/app.css` under the eight candidate prefixes (`ax-home-`, `ax-launcher`, `ax-attention`, `ax-health-summary`, `ax-subscriptions-`, `ax-subscription-row-`, `ax-subscription-setup`, plus the shared `ax-inline-worklist`/`ax-audit-summary-row`), an **exact-token** search was run with `rg -lP "(?<![\w-])CLASSNAME(?![\w-])"` across `accrue_admin/lib/`, `accrue_admin/test/`, `accrue_admin/e2e/`. This lookbehind/lookahead pattern excludes both partial-word matches (e.g. `ax-launcher` inside `ax-launchers`) and data-attribute false positives (e.g. `ax-launcher-primary` inside `data-ax-launcher-primary`) — see `## Risks & Landmines` for why a naive substring grep gives the wrong answer for 3 classes.

### PRESERVE (16 classes — live, do not delete)

| Class | Referenced by | Reason |
|-------|---------------|--------|
| `ax-home` | `lib/accrue_admin/live/dashboard_live.ex:64` | Root section wrapper (`class="ax-page ax-home"`) — kept as Home's page-scope hook for the `.ax-home > .ax-page-header` etc. override rules (see Adjacent Findings below). |
| `ax-home-section` | `dashboard_live.ex` (×3, zone wrappers) | Kept as the generic zone-wrapper class for all 4 Home zones post-reign. |
| `ax-home-launcher-card` | `dashboard_live.ex` (×3, launcher tiles) | Phase 210's **new** launcher tile primitive — explicitly documented in-CSS: "Tiles are now `.ax-card` primitives keyed off `data-ax-launcher-primary`; this layer does not touch any `.ax-launcher*` rule (Phase 211 retires those)." |
| `ax-home-launcher-icon` | `dashboard_live.ex` (×3) | Same Phase 210 launcher-tile primitive, icon slot. |
| `ax-home-launcher-action` | `dashboard_live.ex` (×3) | Same Phase 210 launcher-tile primitive, action-label slot. |
| `ax-launchers` | `dashboard_live.ex:179` (`class="ax-launchers ax-launchers-tri"`) | Grid wrapper for the 3-tile launcher grid — **not** the same class as the old bare `.ax-launcher` (singular) rule set, which is dead (see below). |
| `ax-launchers-tri` | `dashboard_live.ex:179` | 3-column grid modifier for the above. |
| `ax-attention` | `dashboard_live.ex:149` (`class="ax-card ax-attention"`) | Populated attention-rail wrapper. |
| `ax-attention-row` | `dashboard_live.ex:150` | Per-signal row inside the attention rail. |
| `ax-attention-text` | `dashboard_live.ex:156` | Text span inside each attention row. |
| `ax-attention-rail--empty` | `dashboard_live.ex:169` (EmptyState `class=`) + `e2e/admin-spec-overview-phase194.spec.js:96` (`.ax-attention-rail--empty` locator, the D-06 empty-rail gate) | Empty-state variant of the rail. Note this is the ONLY member of the `ax-attention*` family that is a compound/modifier name (`--empty`) rather than a hyphen-chain — do not confuse with the *bare* `ax-attention-rail` selector referenced by `region-tags.js`, which does not exist anywhere in the CSS (see `## Secondary Surfaces`). |
| `ax-subscription-setup-gap` | `lib/accrue_admin/live/subscriptions_live.ex:418` (`setup_gap_cell/2` helper, raw HTML span) | **Landmine.** Named inside the "ax-subscription-setup*" family the ROADMAP lists for retirement, but it is live — rendered by the Subscriptions LIST page's compact-cell idiom (`plan_amount_cell/1` → `setup_gap_cell/2`) built during Phase 209. Must be preserved. |
| `ax-inline-worklist` | `subscription_live.ex:304`, `component_kitchen_live.ex` (×4) | Shared card-strip primitive; ROADMAP-documented as shared with the out-of-scope detail page. |
| `ax-inline-worklist-actions` | `component_kitchen_live.ex` (×4) | Sibling of the above — only referenced by the kitchen today (not by `subscription_live.ex`, which uses a different action-button layout at that call site), but still live. |
| `ax-inline-worklist-copy` | `subscription_live.ex:305`, `component_kitchen_live.ex` (×4) | Sibling of the above; ROADMAP-named shared class. |
| `ax-audit-summary-row` | `dashboard_live.ex:311`, `subscription_live.ex:480`, `component_kitchen_live.ex` (×2) | ROADMAP-named shared class; heaviest reuse of the 16 — 4 distinct call sites. |

### DELETE (92 classes — zero references, safe to remove)

**`ax-home-*` (10 dead of 16 total in family):**
`ax-home-customer-search-cta`, `ax-home-customer-search-strip`, `ax-home-customer-search-strip-action`, `ax-home-header-health`, `ax-home-health-answer`, `ax-home-health-label`, `ax-home-health-metric`, `ax-home-health-metrics`, `ax-home-health-status`, `ax-home-primary-action`, `ax-home-search`, `ax-home-secondary-action`

(11 listed — the CSS also nests descendant rules under the dead ancestors, e.g. `.ax-home-header-health .ax-status-badge`, `.ax-home-header-health strong`, `.ax-home-header-health span`, `.ax-home-health-metric strong, .ax-home-health-metric em` — these must be deleted too since their ancestor selector never matches; see rule-count note below.)

**`ax-launcher*` (bare/old family — 13 of 13 dead; this is the *entire* pre-Phase-210 launcher-tile rule set, explicitly flagged in-CSS as Phase 211's job):**
`ax-launcher`, `ax-launcher-action`, `ax-launcher-action-button`, `ax-launcher-copy`, `ax-launcher-customer`, `ax-launcher-health`, `ax-launcher-icon`, `ax-launcher-meta`, `ax-launcher-meta-actions`, `ax-launcher-meta-warn`, `ax-launcher-primary`, `ax-launcher-recovery`, `ax-launcher-title`

**`ax-attention*` (11 of 15 total in family dead):**
`ax-attention-action`, `ax-attention-dot`, `ax-attention-dot-danger`, `ax-attention-dot-info`, `ax-attention-dot-warning`, `ax-attention-pill`, `ax-attention-pill-danger`, `ax-attention-pill-info`, `ax-attention-pill-warning`, `ax-attention-priority`, `ax-attention-priority-danger`, `ax-attention-priority-info`, `ax-attention-priority-warning`, `ax-attention-summary`, `ax-attention-summary-warning`

**`ax-health-summary*` (4 of 4 — entire family dead; this was the pre-Phase-210 Home health-summary component, fully retired in markup already):**
`ax-health-summary`, `ax-health-summary-amber`, `ax-health-summary-moss`, `ax-health-summary-prominent`

**`ax-subscriptions-*` (31 of 31 — entire family dead; these are the five bespoke list bands Phase 209 already removed from markup):**
`ax-subscriptions-at-risk-strip`, `ax-subscriptions-audit-strip`, `ax-subscriptions-customer-search-action`, `ax-subscriptions-customer-search-strip`, `ax-subscriptions-exposure`, `ax-subscriptions-header`, `ax-subscriptions-heading-metric`, `ax-subscriptions-heading-verdict`, `ax-subscriptions-health-hero`, `ax-subscriptions-health-line`, `ax-subscriptions-invoice-record`, `ax-subscriptions-invoice-record-empty`, `ax-subscriptions-invoice-record-list`, `ax-subscriptions-invoice-records`, `ax-subscriptions-invoice-strip`, `ax-subscriptions-invoice-strip-danger`, `ax-subscriptions-kpi-row`, `ax-subscriptions-page`, `ax-subscriptions-primary-action`, `ax-subscriptions-primary-workspace`, `ax-subscriptions-priority-actions`, `ax-subscriptions-priority-copy`, `ax-subscriptions-queue-shortcut`, `ax-subscriptions-route-line`, `ax-subscriptions-secondary-group`, `ax-subscriptions-secondary-group-primary`, `ax-subscriptions-secondary-link`, `ax-subscriptions-secondary-strips`, `ax-subscriptions-utility-strip`, `ax-subscriptions-webhook-strip`, `ax-subscriptions-webhook-workspace`

**`ax-subscription-row-*` (17 of 17 — entire family dead; the per-row bespoke cell markup Phase 209 replaced with the shared compact idiom):**
`ax-subscription-row-admin-chips`, `ax-subscription-row-audit`, `ax-subscription-row-audit-primary`, `ax-subscription-row-customer`, `ax-subscription-row-customer-scope`, `ax-subscription-row-id`, `ax-subscription-row-invoice-action`, `ax-subscription-row-invoice-controls`, `ax-subscription-row-invoice-primary`, `ax-subscription-row-invoices`, `ax-subscription-row-meta`, `ax-subscription-row-meta-grid`, `ax-subscription-row-primary-line`, `ax-subscription-row-signal-primary`, `ax-subscription-row-signal-secondary`, `ax-subscription-row-state`, `ax-subscription-row-webhook-action`

**`ax-subscription-setup*` (0 of 1 dead — the single member, `ax-subscription-setup-gap`, is PRESERVE; see above. Do not delete anything from this family.)**

### Rule-count vs. selector-count note

The 92 dead selector *names* above correspond to a considerably larger number of CSS *rule blocks* once media queries, pseudo-classes (`:hover`, `:focus-visible`), and multi-selector comma groups are counted — consistent with the ROADMAP's "~325 rules" figure (e.g. `.ax-launcher:hover, .ax-launcher:focus-visible { ... }` is one dead selector name producing 2 additional grouped-selector occurrences; `.ax-launcher-recovery .ax-launcher-title, .ax-launcher-recovery .ax-launcher-copy, .ax-launcher-recovery .ax-launcher-meta, .ax-launcher-recovery .ax-launcher-health, .ax-launcher-recovery .ax-launcher-meta-warn { ... }` is 5 grouped selectors in one rule). The planner should delete by **contiguous source region** per family (the families are laid out in clearly-commented contiguous blocks: `ax-launcher*` spans app.css lines ~6083-6274; `ax-subscriptions-*`/`ax-subscription-row-*`/`ax-subscription-setup-gap` span ~1086-4429; `ax-attention*`/`ax-health-summary*` span ~2986-6045; `ax-home-*` health/search remnants span ~5611-5781) rather than selector-by-selector, then re-run the orphan guard (see `## Orphan/Dangling Guard`) to catch stragglers.

### Adjacent findings — dead CSS outside the 8 named families (bonus, not in REIGN-04's literal text)

While tracing the `.ax-home` block (app.css lines 5578-5799) line-by-line to resolve the PRESERVE/DELETE calls above, three **additional** dead rules surfaced that use class names **outside** the 8 named candidate prefixes, caused by the same Phase 210 PageHeader migration:

| Selector | Line | Status | Why |
|----------|------|--------|-----|
| `.ax-home .ax-page-header-compact { gap: 0.125rem; }` | ~5635 | DEAD (orphan) | `dashboard_live.ex` no longer passes a `class="ax-page-header-compact"` variant to `PageHeader.page_header` (it did in the pre-210 hand-rolled header). The bare `.ax-page-header-compact` class is still alive globally (used by `component_kitchen_live.ex`'s own hand-rolled header), just never nested under `.ax-home` anymore. |
| `.ax-home .ax-page-actions { gap: 0.125rem; }` | ~5770 | DEAD (orphan) | Same root cause: `PageHeader.page_header` renders `class="ax-page-header-actions"` (note the extra `-header-`), not `ax-page-actions`. The bare `.ax-page-actions` class is alive elsewhere (`charge_live.ex`, `connect_account_live.ex`, `subscription_live.ex`, `invoice_live.ex`, `component_kitchen_live.ex` all still hand-roll `<div class="ax-page-actions">`), just never nested under `.ax-home`. |
| `.ax-home .ax-page-actions .ax-button-sm { min-height: 1.5rem; padding: 0.125rem 0.4375rem; }` | ~5774 | DEAD (orphan) | Same as above (compound of the dead ancestor). |
| `.ax-dashboard-title-row { display: flex; ... }` | ~5600 | DEAD (orphan) | Zero references anywhere in `lib/`, `test/`, `e2e/`. Pre-210 hand-rolled-header remnant. |
| `.ax-dashboard-title-row .ax-display { width: auto; }` | ~5607 | DEAD (orphan) | Same. |

**Confirmed LIVE and must stay** in the same block: `.ax-home { gap: var(--ax-space-md); }`, `.ax-home > .ax-page-header { gap: 0; padding-block: 0; }` (PageHeader IS rendered as `.ax-home`'s direct child, root class literally `ax-page-header`), `.ax-home > .ax-page-header .ax-display` and `.ax-home > .ax-page-header .ax-page-copy` (both rendered by `PageHeader`'s title/description slots), `.ax-home .ax-home-section { margin-block-start: 0; }`, `.ax-home [data-ax-zone="attention-rail"] .ax-section-head .ax-heading { ... }`, and `.ax-home [data-ax-zone="attention-rail"], .ax-home [data-ax-zone="task-launcher"], .ax-home [data-ax-zone="kpi-cluster"] { margin-block-start: 0; }` (all match real `data-ax-zone` attributes in `dashboard_live.ex`).

**Recommendation:** fold these 5 extra dead rules into this phase's deletion pass (they are trivially safe, zero-reference-confirmed, and directly caused by the same Home reign this phase is cleaning up after) rather than leaving a second round of invisible dead CSS. They are NOT required by REIGN-04's literal wording, so if the planner prefers to stay strictly scoped to the named families, it is acceptable to leave them — but flag that decision explicitly rather than silently drop it, since the general orphan guard (below) will surface them anyway.

## Bundle Rebuild

**Command:** `cd accrue_admin && mix accrue_admin.assets.build`

**What it does** (from `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex`, read in full):
1. Runs `npx --yes tailwindcss@3.4.17 --input assets/css/app.css --output priv/static/accrue_admin.css --minify`
2. Runs `npx --yes esbuild@0.25.3 assets/js/app.js --bundle --format=esm --minify --outfile=priv/static/accrue_admin.js`
3. Both tool versions are pinned inline in the task (not in `package.json`) — `@tailwind_version "tailwindcss@3.4.17"`, `@esbuild_version "esbuild@0.25.3"`.
4. Output: exactly two files, `priv/static/accrue_admin.css` and `priv/static/accrue_admin.js`, both **fixed filenames** (no content-hash in the filename itself — the hash lives only in the *served URL path*, computed separately at compile time by `AccrueAdmin.Assets`).

**Determinism:** given the same `app.css`/`app.js` source and the same pinned tool versions, output is deterministic (confirmed: Phase 209's rebuild produced a "zero diff" when no CSS actually changed that phase — see 209-03-SUMMARY.md D4). Since this phase DOES change `app.css` (by deleting rules), expect a real, large diff in `accrue_admin.css` (shrinking) and no diff in `accrue_admin.js` (JS untouched).

**What must be committed:** both `priv/static/accrue_admin.css` and `priv/static/accrue_admin.js` in the same commit as the `assets/css/app.css` source edit — per the established Phase 209/210 convention, and because `AccrueAdmin.Assets` reads these files via `File.read!/1` into **compile-time module attributes** (`@css_body = File.read!(@css_file)`, hashed via `:md5 |> :crypto.hash(...)`), so the served bytes and the served hash-in-URL only update when the package is recompiled with the new committed file present. Skipping the commit — or committing the source edit without the rebuild — silently ships dead CSS, exactly the failure mode the ROADMAP calls out.

**Storybook CSS has NO automated rebuild task.** Confirmed via `mix.exs` (no storybook-related mix alias), `package.json` (no storybook build script — only `phase200:storybook` which *tests* the existing bundle, never builds it), and the Phase 193-04 SUMMARY, which documents `priv/static/storybook.css` as a **one-time hand-composed** commit (`21f570fe`). The file's own header comment states the recipe:

```
/* Composition: (1) PhoenixStorybook sandbox CSS  (2) accrue_admin.css  (3) dark-mode shim */
```

Concretely, `storybook.css` = `deps/phoenix_storybook/priv/static/css/phoenix_storybook.css` (verbatim, currently 59,022 bytes) + a literal marker comment `/* === accrue_admin.css bundle === */` + the full contents of `priv/static/accrue_admin.css` (verbatim) + a literal marker comment `/* === D-17 Spike B: dark-mode class-to-attribute shim === */` + a fixed, hand-written `.psb-sandbox.accrue-admin.ax-theme-dark-shim { --ax-*: ...; }` block (unrelated to this phase — do not touch it). To rebuild after retiring CSS:

```bash
cd accrue_admin
mix accrue_admin.assets.build   # regenerates priv/static/accrue_admin.css (and .js, unchanged)

# Recompose storybook.css: PSB CSS + fresh accrue_admin.css + the UNCHANGED dark-mode shim tail.
# The shim tail starts at the "/* === D-17 Spike B" marker and must be preserved byte-for-byte.
awk '/\/\* === D-17 Spike B/{found=1} found' priv/static/storybook.css > /tmp/storybook-shim-tail.css

{
  printf '/* D-17 spike D recorded decision: Storybook CSS served via AccrueAdmin.Assets committed-bundle route; no Tailwind rebuild required */\n'
  printf '/* This bundle is committed to git and served by AccrueAdmin.Assets.asset(:storybook_css) */\n'
  printf '/* Composition: (1) PhoenixStorybook sandbox CSS  (2) accrue_admin.css  (3) dark-mode shim */\n\n'
  cat deps/phoenix_storybook/priv/static/css/phoenix_storybook.css
  printf '\n/* === accrue_admin.css bundle === */\n'
  cat priv/static/accrue_admin.css
  printf '\n'
  cat /tmp/storybook-shim-tail.css
} > priv/static/storybook.css
```

This is a manual/scripted recomposition, not a single mix task — the plan should either (a) run the shell recipe above verbatim as a task step, or (b) invest in a tiny new mix task (`mix accrue_admin.storybook.assets.build` or similar) that codifies it — the latter is a reasonable scope addition since it directly de-risks "forgot to rebuild storybook.css" for all future phases, but is not strictly required by REIGN-04's text. Recommend documenting the decision either way rather than silently hand-editing.

**Verification that storybook.css actually needs a rebuild this phase:** confirmed — a grep of the current committed `priv/static/storybook.css` for the 8 candidate-family prefixes finds `.ax-attention*`, `.ax-home`, `.ax-home-search`, `.ax-home-section`, `.ax-launcher*` present (it is a byte-for-byte embed of the **pre-retirement** `accrue_admin.css`). None of these appear in any `storybook/` source `.story.exs` file (confirmed by grep — zero hits), so the fix is a pure rebuild/recomposition, no story-source edits needed.

## Secondary Surfaces

### Component kitchen (`accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex`)

**Finding: the kitchen renders NONE of the 92 dead classes today.** A full-file grep for the 8 candidate prefixes (`ax-launcher\b`, `ax-attention\b`, `ax-home-`, `ax-subscriptions-`, `ax-subscription-row-`, `ax-health-summary`, `ax-subscription-setup`) returns zero matches. The kitchen DOES use the two PRESERVE shared families extensively and correctly: `ax-inline-worklist`/`ax-inline-worklist-copy`/`ax-inline-worklist-actions` (4 sections: production-strip, invoice-preview, webhook-preview, audit-strip) and `ax-audit-summary-row` (2 places: the audit-log-card preview and the drawer-form group specimen). **No markup changes are required in the kitchen for REIGN-04.** The ROADMAP's phrasing ("component kitchen no longer renders retired vocabulary") is satisfied vacuously — it never rendered any of the truly-dead vocabulary; only the *committed CSS bundle it depends on* (`storybook.css`, embedding a stale `accrue_admin.css`) needs the rebuild described above.

### Storybook (`priv/static/storybook.css` + `storybook/` sources)

Covered fully in `## Bundle Rebuild` above. Summary: rebuild-only, no story-source edits.

**Phase 200 storybook specs that must stay green** (identified by grep + `package.json`):
- `test/accrue_admin/dev/storybook_coverage_test.exs` — asserts `ComponentRegistry` ↔ story coverage-row parity; zero coupling to CSS content (reads Elixir data structures, not rendered class strings). Safe by inspection.
- `test/accrue_admin/dev/storybook_asset_test.exs` — asserts the storybook CSS/JS assets are served byte-identically to the committed files and that dev-only routes are absent from prod-like routers. Byte-equality is computed dynamically (`File.read!/1` at test time), not hardcoded, so it is safe against any content change — but WILL fail if `storybook.css` is not rebuilt/recomposed after `accrue_admin.css` changes (the served bytes must match the committed file, but there's no cross-check that the committed file is *fresh*; only a human/CI process, or the orphan guard, can catch staleness).
- `test/accrue_admin/theme_test.exs` — asserts the storybook dark-mode shim mirrors every dark `--ax-*` token from `theme.css`. Unrelated to `.ax-home*`/`.ax-launcher*`/etc rule content; theme tokens are untouched by this phase. Safe.
- `e2e/admin-storybook-a11y-phase200.spec.js` (run via `npm run phase200:storybook`, which chains the three unit tests above + this Playwright a11y scan) — axe accessibility scan over storybook pages. Storybook never renders dashboard/subscriptions markup (it renders isolated component specimens), so retiring dead Home/Subscriptions CSS cannot introduce new a11y violations here. Safe, but must run after the `storybook.css` recomposition to avoid a stale/broken stylesheet failing to load.

Both `css_hash()`/`storybook_css_hash()` are computed dynamically from file content at compile time (`AccrueAdmin.Assets`), and the only tests referencing hashes (`assets_test.exs`, `router_test.exs`) derive the expected value from `AccrueAdmin.Assets.css_hash()` itself rather than hardcoding a literal — confirmed safe against content changes.

### Ratchet `region-tags.js` (`accrue_admin/e2e/ratchet/region-tags.js`)

**Finding:** `REGION_SELECTORS["attention-rail"]` is hardcoded to `"ax-attention-rail"` with an inline `// TODO: confirm selector` comment (line 91). This selector **never existed** as a real CSS class — grepping `assets/css/app.css` for `ax-attention-rail` finds only the three `.ax-attention-rail--empty` rules (the *empty-state modifier*, a different, longer class name). The map has been dangling since it was authored in Phase 205/206 (pre-dating both reign phases).

**Why it's safe/low-risk today:** `REGION_SELECTORS` is explicitly documented as non-identity metadata — "a `null`/absent selector is the intended safe fallback (never a crash): `region_tag` is derived from model output via `normalizeRegion`, never from this map, so a wrong or missing selector cannot affect identity/claim-key." The pure self-test (`runSelfTest()`) never exercises `REGION_SELECTORS` at all. This is why the fix is "opportunistic" per the phase description — nothing currently breaks from the dangling value.

**Recommended non-dangling replacement:** `[data-ax-zone="attention-rail"]` — this is the actual, stable, live selector for the attention-rail region in `dashboard_live.ex` (`<section class="ax-home-section" aria-label="Billing exceptions" data-ax-zone="attention-rail">`), and it is **already** the selector the phase-199 Playwright ratchet guards were retargeted to during Phase 210 (210-03-SUMMARY.md, Task 2: "Retarget the two `.ax-attention-rail` ratchet guards to `[data-ax-zone=attention-rail]`" — commit `22486e63`). Using the same selector in `region-tags.js` keeps the two "attention rail" identifiers (the live e2e guards and the ratchet's region map) consistent for the first time.

```js
// region-tags.js line 91, recommended fix:
"attention-rail": "[data-ax-zone='attention-rail']", // fixed 2026: matches phase199 guard selector + dashboard_live.ex data-ax-zone
```

Note: other `REGION_SELECTORS` entries (`toolbar`, `tab-bar`, `kpi-row`, `detail-panel`, `related-panel`, `timeline`, `payload-viewer`, `content-body`, `layer`) carry the same `// TODO: confirm selector` marker and are ALSO unconfirmed/possibly-dangling, but they map to regions entirely outside this phase's named scope (not `ax-attention*`) — out of scope for REIGN-04, left untouched, flagged here only for completeness/an Open Question below.

## Test/E2E Migration Surface

**Definitive finding: zero migrations are needed.** A project-wide grep of `accrue_admin/test/` and `accrue_admin/e2e/` for all 8 candidate prefixes returns exactly 3 hits, none of which reference a DELETE-verdict class:

| File | Line | Match | Verdict |
|------|------|-------|---------|
| `test/accrue_admin/live/dashboard_live_test.exs` | 125 | `assert html =~ "data-ax-launcher-primary"` | Not a CSS class at all — a `data-*` attribute, already correct (migrated in Phase 210). No action. |
| `e2e/admin-spec-overview-phase194.spec.js` | 96 | `page.locator(".ax-attention-rail--empty")` | PRESERVE class (see census). No action. |
| `e2e/ratchet/region-tags.js` | 91 | `"attention-rail": "ax-attention-rail"` | The one genuine fix — see `## Secondary Surfaces` above. Not a test assertion (a dev-tool selector map), so it doesn't affect any live gate, but it's the one line to change. |

This is expected and consistent with the 209-03 and 210-03 SUMMARY.md evidence read during this research: both prior phases explicitly migrated their own test/e2e selectors as part of *their* success criteria (209-03 migrated `subscriptions_live_test.exs` fully — 12/12 green, post-reign shape; 210-03 migrated `dashboard_live_test.exs` and retargeted the phase199 `.ax-attention-rail*` guards to `[data-ax-zone=attention-rail]`). REIGN-04's "all in-repo test/e2e selector assertions on retired classes are migrated in the same phase" clause should be read as **already satisfied** by the time Phase 211 starts; this phase's job is to *verify* that (the grep above), not to *perform* new migrations.

**How to run the relevant suites** (from `accrue_admin/package.json` + `mix.exs`):

| Gate | Command | Purpose |
|------|---------|---------|
| Full unit suite | `cd accrue_admin && mix test` | All ExUnit tests, including `dashboard_live_test.exs`, `subscriptions_live_test.exs`, storybook tests. |
| Home overview gate | `npm run e2e:phase194` (`playwright test e2e/admin-spec-overview-phase194.spec.js --timeout=60000 --workers=1`) | Includes the D-06 empty-rail check on `.ax-attention-rail--empty` (PRESERVE). |
| Interaction/overlay gate | `npm run e2e:phase199` (`e2e/admin-interaction-overlay-phase199.spec.js`) | Focus-ring ratchet guards — already retargeted off dead classes. |
| Accessibility gate | `npm run e2e:a11y` (`e2e/admin-a11y.spec.js`) | axe scan; expect the 2 pre-approved-deferred dark-mode contrast items (subscription-detail + component-kitchen) and nothing new. |
| Storybook gate | `npm run phase200:storybook` | Chains 3 unit tests + the storybook a11y Playwright spec. |
| Subscriptions list/detail gates | `npm run e2e:phase196`, `npm run e2e:phase197` | Cover the Subscriptions list surface this phase's deletions touch. |
| Full e2e suite | `npm run e2e` (bare `playwright test`, all 22 specs × 2 projects: `chromium-desktop`, `chromium-mobile`) | The "admin e2e suite" success-criterion 5 refers to. |

`copy_strings.json` regeneration (`mix accrue_admin.export_copy_strings`) is **not required** this phase — REIGN-04 is a pure CSS/selector-cleanup requirement with no copy changes; the artifact should show a zero diff if regenerated, matching the Phase 209 "confirmed, not skipped" pattern for artifacts that don't actually change.

## Orphan/Dangling Guard

**No existing script does this.** Surveyed `scripts/ci/*.mjs`/`*.sh` (45+ existing verify scripts) and `accrue_admin/e2e/*.mjs` (`score-visuals.mjs`, `phase200-scorecard.mjs`, `baseline-parse.mjs`, etc.) — none perform a CSS-selector-vs-source liveness census. The closest structural precedent is `region-tags.js`'s own `runSelfTest()` (a pure, dependency-free, `node:crypto`-only self-test invoked via `node region-tags.js`) and the various `verify_*.mjs` scripts' `--self-test` convention (e.g. `ratchet:self-test`, `phase200:scorecard`'s self-test mode) — **reuse this pattern**, don't invent a new one.

**Recommended design** (new, small, standalone script — e.g. `accrue_admin/e2e/verify-css-census.mjs` or `scripts/ci/verify_admin_css_orphans.mjs`, following the existing `verify_*` naming convention):

1. **Extract** every `.ax-[a-zA-Z0-9_-]+` class-selector token from `accrue_admin/assets/css/app.css` (regex extraction on the *source*, not the minified bundle — source has stable formatting and one-rule-per-line-ish structure making regex extraction reliable; the minified bundle is a legitimate secondary target for a "bundle vs source parity" check but the primary liveness question is against source).
2. **Search** for each token, exact-match (the same `(?<![\w-])TOKEN(?![\w-])` lookaround pattern validated in this research — NOT a plain substring `grep -l`, which produces false positives/negatives as demonstrated above) across `accrue_admin/lib/**/*.ex`, `accrue_admin/storybook/**/*.exs`, `accrue_admin/test/**/*.{ex,exs}`, `accrue_admin/e2e/**/*.js`.
3. **Report (a)** — orphan rules: CSS selectors with zero matches anywhere → candidates for deletion (this generalizes beyond the 8 named families and will also surface the 5 "Adjacent findings" above, e.g. `ax-page-actions`/`ax-dashboard-title-row` compound orphans, for free).
4. **Report (b)** — missing rules: literal `ax-*` class tokens found in source `class="..."` (and `class={[...]}` list literals) with no matching CSS selector → lower-severity, informational (an unstyled class renders visibly in dev, so this is lower-risk than an orphan rule, but still useful).
5. **Allowlist mechanism required for false positives from dynamic/interpolated classes** — e.g. `component_kitchen_live.ex` builds `class={"ax-foundation-status ax-foundation-status-#{status}"}` and `data-ax-force={force}`-driven variants; a pure static grep cannot resolve `#{status}` interpolation. Verified this is NOT an issue for any of the 8 REIGN-04 families (checked explicitly — no `#{...}` interpolation touches any `ax-home`/`ax-launcher`/`ax-attention`/`ax-subscription*`/`ax-health-summary`/`ax-inline-worklist`/`ax-audit-summary-row` class anywhere in `dashboard_live.ex`, `subscriptions_live.ex`, `subscription_live.ex`, or `component_kitchen_live.ex`), but a *general* orphan guard reused for future phases will need either a small denylist/allowlist of known-dynamic prefixes (`ax-foundation-status-`, `ax-dev-state-cell` etc.) or an inline suppression comment convention to avoid false "orphan" reports on those.
6. **Self-test mode** (`--self-test`): hand-written fixture CSS + fixture source strings covering (i) a genuinely orphaned rule, (ii) a genuinely live rule, (iii) the exact-token boundary cases that caused false positives in this research (`ax-launcher` vs `ax-launchers`, `ax-launcher-primary` vs `data-ax-launcher-primary`) — asserting the tool gets all three right, mirroring `region-tags.js`'s own self-test discipline.
7. **Exit code:** non-zero if orphan rules are found (matching the "cheap guard confirms" wording of success criterion 3) — but keep the report advisory-friendly (list every finding, don't just fail silently) since a maintainer may want to triage before deleting.

Keep this **genuinely cheap**: no browser, no build step, no network — pure regex extraction + `rg`/Node `fs.readFileSync` + string matching, runnable in well under a second. This is explicitly a guard, not a new framework; do not over-engineer it into a second ratchet.

## Validation Architecture

> `workflow.nyquist_validation` is `true` in `.planning/config.json` (not absent, not false) — this section is required.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir, `mix test`) + Playwright `^1.57.0` (Node, `accrue_admin/e2e/*.spec.js`) |
| Config file | `accrue_admin/test/test_helper.exs` (ExUnit) + `accrue_admin/playwright.config.js` (Playwright, `testDir: "./e2e"`, `workers: 1`, two projects: `chromium-desktop`/`chromium-mobile`) |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs` |
| Full suite command | `cd accrue_admin && mix test && npm run e2e` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REIGN-04 (SC1: zero-ref grep census) | Grep census over `lib/`, `test/`, `e2e/` for each candidate class | unit/script | `rg -lP "(?<![\w-])CLASS(?![\w-])" accrue_admin/lib accrue_admin/test accrue_admin/e2e` per class, or the new orphan guard (once built) | ✅ (ripgrep already present; orphan guard is Wave 0 new) |
| REIGN-04 (SC2: detail-page preservation) | `.ax-inline-worklist*`/`.ax-audit-summary-row` and any other `subscription_live.ex`-referenced class survive; detail page visually unbroken | e2e/manual_procedural | `npx playwright test e2e/admin-spec-detail-phase195.spec.js e2e/admin-spec-detail-phase198.spec.js` + PNG read | ✅ |
| REIGN-04 (SC3: bundle rebuild + orphan guard) | `accrue_admin.css`/`.js` rebuilt+committed; new orphan guard passes | unit/script | `mix accrue_admin.assets.build` (exit 0) + new guard script (exit 0) | ⚠️ orphan guard script is new — Wave 0 gap |
| REIGN-04 (SC4: kitchen/storybook/region-tags) | Kitchen renders no dead vocab (already true); storybook.css rebuilt; phase200 storybook specs green; `region-tags.js` fixed | unit/e2e | `npm run phase200:storybook` (chains storybook unit tests + a11y spec) | ✅ |
| REIGN-04 (SC5: full suite green, no scope breach) | `mix test` + full e2e green across the phase boundary; diff touches no `accrue/lib`, no new nav room | unit/e2e/script | `mix test && npm run e2e`; `git diff --stat -- ../accrue/lib` (expect empty) | ✅ |

### Sampling Rate
- **Per task commit:** targeted unit test for the touched surface (`dashboard_live_test.exs` / `subscriptions_live_test.exs` / storybook tests as relevant) + the new orphan-guard script.
- **Per wave merge:** `mix test` (full accrue_admin unit suite) + the 3 named e2e gates (phase194, phase199, admin-a11y) + `npm run phase200:storybook`.
- **Phase gate:** full `mix test` + full `npm run e2e` (all 22 specs × 2 projects) green before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `accrue_admin/e2e/verify-css-census.mjs` (or `scripts/ci/verify_admin_css_orphans.mjs`) — the orphan/dangling guard does not exist yet; must be authored this phase per success criterion 3. Include a `--self-test` mode per repo convention.
- [ ] Capture the **current** (pre-Phase-211) `mix test` pass/fail baseline as a Wave 0 step — see `## Risks & Landmines` (pre-existing failures) — so "no red left behind" is measured against the correct starting point, not an assumed-clean baseline.
- [ ] No test-framework install gaps: ExUnit and Playwright are both already configured and passing as of Phase 210 (confirmed `mix test`/`npm run e2e` tooling present and versioned).

## Security Domain

`security_enforcement` is absent from `.planning/config.json` (treated as enabled per protocol), but this phase has **no security-relevant surface**: it deletes unused CSS selectors and dev-tooling metadata, touches no auth/session/webhook/input-validation code, and adds no new externally-reachable route or user input path. ASVS categories V2 (Auth), V3 (Session), V4 (Access Control), V5 (Input Validation), V6 (Cryptography) are all **not applicable** — no code in scope handles credentials, sessions, authorization checks, user input parsing, or cryptography. The only "threat" adjacent to this phase's scope is the general CSS-retirement risk of breaking the **rendered** admin UI (a correctness/availability concern, not a security one), which is fully covered by the PNG-parity and full-e2e-suite gates above.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | no | n/a — no auth code touched |
| V3 Session Management | no | n/a |
| V4 Access Control | no | n/a |
| V5 Input Validation | no | n/a — no new user input surface |
| V6 Cryptography | no | n/a |

No STRIDE-relevant threat patterns apply to a CSS-source-file deletion + static-bundle-rebuild change.

## Package Legitimacy Audit

Not applicable — this phase installs **no new packages**. `mix accrue_admin.assets.build` invokes two already-pinned, already-in-use tool versions via `npx` (`tailwindcss@3.4.17`, `esbuild@0.25.3`), both of which are pre-existing dependencies of this task (unchanged by this phase) and were already vetted when the task itself was authored. No `mix.exs`/`package.json` dependency additions are proposed anywhere in this research.

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

## Common Pitfalls

### Pitfall 1: Substring/attribute false positives in the liveness grep
**What goes wrong:** A naive `grep -l "ax-launcher"` (or `grep -l "ax-launcher-primary"`) reports the bare `ax-launcher`/`ax-launcher-primary` classes as "live" because `ax-launchers` and `data-ax-launcher-primary` contain them as substrings.
**Why it happens:** `\b` word-boundary regex treats `-` as a non-word character, so it fires at the same position whether the neighboring token is a hyphen-suffix continuation (`ax-launchers`) or an unrelated `data-` attribute prefix (`data-ax-launcher-primary`) — both look like valid boundaries to a naive `\b`-based check.
**How to avoid:** use the `(?<![\w-])TOKEN(?![\w-])` lookaround pattern validated in this research (excludes both a preceding hyphen and a following word/hyphen character), or extract `class="..."`/`class={[...]}` attribute values and tokenize on whitespace before comparing.
**Warning signs:** a "live" class that never actually appears when you manually open the file and search for the literal `class="..."` string.

### Pitfall 2: Deleting a comma-grouped selector wholesale when only one branch is dead
**What goes wrong:** `@media (min-width: 1024px) { .ax-shell-content:has(> .ax-subscriptions-page), .ax-shell-content:has(> .ax-subscription-detail-page), .ax-shell-content:has(> .ax-home) { padding-top: 0; } }` (app.css ~6286) has 3 comma-separated branches; only the first (`.ax-subscriptions-page`) is dead. Deleting the whole rule silently removes the `padding-top: 0` behavior from the still-live `.ax-subscription-detail-page` and `.ax-home` routes.
**Why it happens:** grep/`rg` matches the rule *block*, not the individual comma-branch, so a naive "this block mentions a dead class, delete the block" heuristic over-deletes.
**How to avoid:** for every dead-class match inside a multi-selector comma list, remove only that comma-branch, keeping the rest of the rule intact.
**Warning signs:** a shared layout rule (padding/margin/display) silently regresses on a page whose own class wasn't in your deletion list.

### Pitfall 3: Assuming "named family = fully dead"
**What goes wrong:** Treating `.ax-subscription-setup-gap` as dead because it's inside the "ax-subscription-setup*" family the ROADMAP names for retirement.
**Why it happens:** the ROADMAP/success-criteria prose names *families* (prefixes), but liveness is a per-selector fact, not a per-family one — Phase 209's own compact-cell rebuild happened to reuse a class from a family otherwise being retired.
**How to avoid:** always grep every individual selector name, never bulk-delete by prefix match alone.
**Warning signs:** a rendering regression on the Subscriptions list's "setup gap" cell (missing border-left/warning-color treatment) after deletion.

### Pitfall 4: Forgetting `storybook.css` has no build task
**What goes wrong:** running only `mix accrue_admin.assets.build` and assuming all committed CSS artifacts are fresh; `storybook.css` silently keeps embedding the stale, pre-retirement `accrue_admin.css`.
**Why it happens:** `storybook.css` was authored as a one-time hand-composed commit in Phase 193 with no follow-up automation; there's no `mix storybook.assets.build` task to remind you.
**How to avoid:** always pair the `mix accrue_admin.assets.build` step with the manual/scripted `storybook.css` recomposition described in `## Bundle Rebuild`.
**Warning signs:** `npm run phase200:storybook` (or its underlying `storybook_asset_test.exs`) still passes (byte-equality is self-consistent), but the served storybook page visually/structurally still contains dead-class remnants if anyone inspects it — a silent, hard-to-notice staleness bug.

### Pitfall 5: Compile-time asset caching masking a rebuild
**What goes wrong:** `AccrueAdmin.Assets` reads `priv/static/accrue_admin.css`/`storybook.css` into **module attributes at compile time** (`@css_body File.read!(@css_file)`). If the host app (or `mix test`) doesn't recompile `accrue_admin` after the files change on disk, stale bytes keep being served in a long-running `iex`/dev session.
**Why it happens:** `@external_resource` is declared (so `mix compile` *will* detect the file changed and recompile), but a hot-reloading dev server or an already-booted BEAM node holding old compiled code won't automatically pick it up without an explicit recompile/restart.
**How to avoid:** always run (or let CI run) a full `mix compile`/`mix test` after touching either CSS file, not just re-request the page in a stale running server.
**Warning signs:** `git diff` shows the CSS changed, but a manually-tested running dev server still renders the old styles.

## Runtime State Inventory

> Not applicable — this is a CSS retirement / dev-tooling cleanup phase, not a rename/refactor/migration phase. No renamed identifiers, no stored data, no OS-registered state, no secrets, no build-artifact rename is involved. Skipping per the trigger condition in the protocol.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The recommended `region-tags.js` fix (`[data-ax-zone='attention-rail']`) is the "correct" non-dangling selector | Secondary Surfaces | Low — `REGION_SELECTORS` is documented as non-identity/never-crashes metadata; a wrong choice here has zero effect on the ratchet's actual behavior (self-test doesn't touch it), only on the map's own internal consistency/documentation value. |
| A2 | Folding the 5 "Adjacent findings" (outside the 8 named families) into this phase's deletion is a reasonable scope extension rather than scope creep | Class Census (Adjacent findings) | Low-Medium — these are independently zero-reference-verified dead rules, but they are not literally named in REIGN-04's text; if the maintainer wants strict scope discipline, leave them for a follow-up and note the decision explicitly rather than silently including or silently dropping them. |
| A3 | Building a dedicated `mix accrue_admin.storybook.assets.build` task (rather than a one-off shell recipe) is worth the extra scope | Bundle Rebuild | Low — either approach achieves the phase's goal; the shell recipe is sufficient and lower-risk to introduce late in a milestone that explicitly says "no new deps/no scope creep," but a task would prevent this exact staleness bug from recurring on ALL future phases. Flagged as a planner/maintainer judgment call, not a blocking risk. |

**If this table is empty:** N/A — see entries above; none of these are compliance/security/retention-policy claims, all are low-blast-radius implementation-detail judgment calls appropriate for the planner to resolve.

## Open Questions

1. **Should the 5 "Adjacent findings" dead rules (outside the 8 named REIGN-04 families) be deleted in this phase or deferred?**
   - What we know: all 5 are zero-reference-confirmed dead, caused by the same Phase 210 PageHeader migration this phase is cleaning up after.
   - What's unclear: whether "grep-gated... the bespoke [8 named families]... sets (~325 rules) are removed" in the ROADMAP is meant as an exhaustive boundary or an illustrative one.
   - Recommendation: include them (trivially safe, same root cause, avoids a second invisible-dead-CSS round), but call out the decision explicitly in the plan rather than silently expanding scope.

2. **Should the general orphan/dangling guard (task E) be wired into CI as a blocking check, or left as a manually-run advisory script this phase?**
   - What we know: no existing CI workflow references any CSS-orphan check; `.github/workflows/` was not part of this phase's named scope.
   - What's unclear: whether adding a new required CI check is itself a scope concern for a milestone whose guardrails say "no new deps, no CI required-check topology changes" (echoing the sibling v1.55 CI-audit precedent).
   - Recommendation: build the script and run it manually as part of this phase's own verification (satisfies success criterion 3's literal wording — "a cheap guard confirms..." — without requiring it to be a wired CI gate); leave CI-wiring as an explicit follow-up decision for the maintainer, not an implicit part of this phase.

3. **Are the other `REGION_SELECTORS` `// TODO: confirm selector` entries (toolbar, tab-bar, kpi-row, detail-panel, related-panel, timeline, payload-viewer, content-body, layer) in scope for "opportunistic" fixing alongside `attention-rail`?**
   - What we know: they carry the identical dangling-marker pattern and the identical "never crashes, self-test doesn't touch it" safety profile.
   - What's unclear: REIGN-04's text names only the `attention-rail` (`.ax-attention*`) family; the others map to regions with no relationship to this phase's CSS retirement.
   - Recommendation: leave them untouched — fixing `attention-rail` is justified because it's a direct, provable side-effect of this phase's own `.ax-attention*` census; the others are an unrelated, separately-scoped cleanup (v1.56 ratchet re-freeze territory, per the milestone's own "ratchet re-freeze is a post-M3 breadcrumb, not an M1 task" guardrail).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | `npx` tool invocations inside `mix accrue_admin.assets.build`, Playwright e2e | ✓ | v22.14.0 | — |
| npx | Downloads/runs pinned `tailwindcss@3.4.17` / `esbuild@0.25.3` on demand | ✓ | 11.1.0 | — |
| Elixir/Mix | `mix test`, `mix accrue_admin.assets.build`, `mix accrue_admin.export_copy_strings` | ✓ | Elixir 1.19.5 / Mix 1.19.5 (OTP 28) | — |
| Playwright | Full e2e suite + storybook a11y spec | ✓ | 1.59.1 | — |
| ripgrep (`rg`) | Recommended for the exact-token census grep and the new orphan guard's shell-assisted verification | ✓ | present at `/opt/homebrew/bin/rg` | plain POSIX `grep -E` with the same lookaround pattern is NOT portable (BRE/ERE lack lookaround) — if `rg`/`grep -P` (GNU grep/PCRE) is unavailable in CI, the Node-based orphan guard script itself (regex via JS, which supports lookaround) is the portable fallback. |

**Missing dependencies with no fallback:** none — all required tooling is present and already used successfully by Phases 209/210 in this exact environment.

## Sources

### Primary (HIGH confidence — direct codebase inspection this session)
- `accrue_admin/assets/css/app.css` (8091 lines) — full selector extraction for all 8 candidate families + adjacent `.ax-home` block read in full (lines 5570-6390+).
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` — full file read, confirms Phase 210's actual reigned markup and its retained structural classes.
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` — targeted read, confirms `ax-subscription-setup-gap` liveness via `setup_gap_cell/2`.
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — targeted grep/read, confirms detail-page-shared class usage.
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` (1894 lines, read in full) — confirms zero dead-vocabulary usage.
- `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` — full read, exact rebuild command/output-file contract.
- `accrue_admin/lib/accrue_admin/assets.ex`, `accrue_admin/lib/accrue_admin/dev/storybook.ex` — full reads, hashed-path/compile-time-caching mechanics.
- `accrue_admin/e2e/ratchet/region-tags.js` (460 lines, read in full) — dangling `attention-rail` selector confirmed, self-test scope confirmed.
- `accrue_admin/package.json`, `accrue_admin/mix.exs`, `accrue_admin/playwright.config.js` — full reads, test/build entry points.
- `.planning/phases/209-.../209-03-SUMMARY.md`, `.planning/phases/210-.../210-03-SUMMARY.md` — cross-validation of this research's census against the prior phases' own grep-gate results (independently confirms `ax-inline-worklist`/`ax-audit-summary-row` residual-ownership file sets and the `region-tags.js` retargeting history).
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/config.json` — phase scope, requirement text, milestone guardrails, nyquist_validation flag.
- Live environment probes: `node --version`, `npx --version`, `elixir --version`, `mix --version`, `npx playwright --version`, `rg` presence.

### Secondary (MEDIUM confidence)
- None — no external web/docs research was needed for this phase; it is entirely a same-repository grep/read exercise with no third-party library or API surface.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Class census (DELETE/PRESERVE): HIGH — every verdict is a direct, reproducible grep result against the current repository state, cross-validated against two independent prior-phase grep-gates (209-03, 210-03).
- Bundle rebuild mechanics: HIGH — read the actual mix task source and the actual `storybook.css` composition header/history commit.
- Secondary surfaces (kitchen/storybook/region-tags): HIGH — full-file reads, not inference.
- Test/e2e migration surface: HIGH — exhaustive project-wide grep, zero ambiguity in the result.
- Orphan guard design: MEDIUM — the recommended design is sound and follows established repo conventions, but it is a *new* script with no existing precedent to directly verify against; the self-test approach mitigates this.

**Research date:** 2026-07-19
**Valid until:** ~14 days (fast-moving — this research is tightly coupled to the exact current state of `app.css`/`dashboard_live.ex`/`subscriptions_live.ex`; any further commits to those files before Phase 211 executes should trigger a re-grep of the census, not a full re-research).
