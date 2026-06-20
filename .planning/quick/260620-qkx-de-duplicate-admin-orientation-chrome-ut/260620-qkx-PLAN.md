---
phase: quick-260620-qkx
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - accrue_admin/lib/accrue_admin/components/topbar.ex
  - accrue_admin/lib/accrue_admin/components/app_shell.ex
  - accrue_admin/lib/accrue_admin/components/detail.ex
  - accrue_admin/assets/css/app.css
  - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
  - accrue_admin/lib/accrue_admin/live/customers_live.ex
  - accrue_admin/lib/accrue_admin/live/invoices_live.ex
  - accrue_admin/lib/accrue_admin/live/charges_live.ex
  - accrue_admin/lib/accrue_admin/live/coupons_live.ex
  - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex
  - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
  - accrue_admin/lib/accrue_admin/live/events_live.ex
  - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
  - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
  - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
  - accrue_admin/lib/accrue_admin/dev/clock_live.ex
  - accrue_admin/lib/accrue_admin/dev/fake_inspect_live.ex
  - accrue_admin/lib/accrue_admin/dev/webhook_fixture_live.ex
  - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
  - accrue_admin/lib/accrue_admin/dev/email_preview_live.ex
  - accrue_admin/test/accrue_admin/components/app_shell_test.exs
  - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
  - accrue_admin/assets/vendor/topbar.js
  - accrue_admin/assets/js/app.js
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/accrue_admin.js
autonomous: true
requirements: [QKX-A, QKX-B]

must_haves:
  truths:
    - "On every admin page the topbar shows only search, menu, and theme controls — no brand name, no page title, no brand chip"
    - "Every admin page renders exactly one content <h1> (the visible page hero / detail summary title)"
    - "The skip link (#main-content) remains the topbar's first focusable child"
    - "The configured brand app_name remains the accessible name of the sidebar home/brand lockup"
    - "Navigating between admin sections shows a thin accent-colored top progress bar wired to phx:page-loading events"
    - "The progress bar respects prefers-reduced-motion (shows immediately, no shimmer delay) and reads --ax-accent for white-label color"
  artifacts:
    - path: "accrue_admin/lib/accrue_admin/components/topbar.ex"
      provides: "Utility-bar topbar (skip link + actions only)"
      contains: "ax-topbar-actions"
    - path: "accrue_admin/assets/vendor/topbar.js"
      provides: "Vendored MIT topbar progress-bar library"
      contains: "topbar"
    - path: "accrue_admin/priv/static/accrue_admin.js"
      provides: "Rebuilt JS bundle including topbar wiring"
      contains: "topbar"
    - path: "accrue_admin/priv/static/accrue_admin.css"
      provides: "Rebuilt CSS bundle with brand-chip rules removed"
  key_links:
    - from: "accrue_admin/lib/accrue_admin/components/app_shell.ex"
      to: "accrue_admin/lib/accrue_admin/components/topbar.ex"
      via: "<Topbar.topbar> call no longer passes brand/page_title"
      pattern: "Topbar.topbar"
    - from: "accrue_admin/assets/js/app.js"
      to: "accrue_admin/assets/vendor/topbar.js"
      via: "import topbar from vendor; config + page-loading listeners"
      pattern: "vendor/topbar"
---

<objective>
Faithful transcription of an already-approved (ExitPlanMode) plan: de-duplicate the admin orientation chrome and add a Turbo-style navigation loading bar.

Part A collapses the topbar to a pure utility bar (search · menu · theme), removes the redundant brand chip and the topbar page-title/eyebrow, and promotes each page's visible hero to the document's single `<h1>` (since the only `<h1>` today lives in the now-removed topbar copy block). It also removes the redundant page-header eyebrows that merely echo the section name already shown by the breadcrumb.

Part B vendors the canonical MIT `topbar` JS (the file `phx.new` ships) and wires it to LiveView `phx:page-loading-start/stop` events, colored from the live `--ax-accent` token (white-label aware, reduced-motion aware).

Purpose: One distinct orientation path per page (sidebar = brand+section, breadcrumb = hierarchy, hero = purpose), better heading semantics (visible subject is the h1, not chrome), and live feedback during LiveView navigation.

Output: Reduced topbar, single-h1 pages, vendored+wired loading bar, and the rebuilt committed `priv/static/accrue_admin.{css,js}` bundle (admin serves the committed bundle; `assets_test.exs` asserts its md5).

NON-NEGOTIABLE LOCKED DECISIONS (per the approved plan — do NOT redesign):
- Topbar form factor LOCKED to "utility bar" (search + menu + theme only, no title text).
- ZERO data/domain/host changes. Keep all ~25 `assign(:page_title, …)` call sites — `page_title` still feeds `layouts.ex`'s document `<title>`; only the topbar stops rendering it.
- KEEP the skip link as the topbar's first focusable child. KEEP the summary-card eyebrow ("Customer detail" etc.). Only remove the redundant PAGE-HEADER eyebrows (right after breadcrumbs) — NOT `ax-eyebrow` used as in-card/section labels.
- CSS grouped-selector care: remove ONLY `.ax-topbar-copy` / `.ax-topbar-brand-chip` / `.ax-topbar-brand-name`; KEEP shared `.ax-eyebrow` / `.ax-display` / `.ax-heading`; split any shared group rather than deleting a shared selector. Tokens only, no hardcoded hex.
- Do NOT touch `examples/accrue_host/mix.lock` or `.planning/research/.cache/`. Do NOT update ROADMAP.md. No new mix deps (topbar is vendored). No new shared `page_header` component (note as a future seed).
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@accrue_admin/lib/accrue_admin/components/topbar.ex
@accrue_admin/lib/accrue_admin/components/app_shell.ex
@accrue_admin/lib/accrue_admin/components/detail.ex
@accrue_admin/lib/accrue_admin/components/sidebar.ex
@accrue_admin/lib/accrue_admin/csp_plug.ex
@accrue_admin/assets/js/app.js
@accrue_admin/test/accrue_admin/components/app_shell_test.exs
</context>

<tasks>

<task type="auto">
  <name>Task 1 (Part A): De-duplicate orientation chrome — utility-bar topbar, single content h1, drop redundant eyebrows</name>
  <files>accrue_admin/lib/accrue_admin/components/topbar.ex, accrue_admin/lib/accrue_admin/components/app_shell.ex, accrue_admin/lib/accrue_admin/components/detail.ex, accrue_admin/assets/css/app.css, accrue_admin/lib/accrue_admin/live/subscriptions_live.ex, accrue_admin/lib/accrue_admin/live/customers_live.ex, accrue_admin/lib/accrue_admin/live/invoices_live.ex, accrue_admin/lib/accrue_admin/live/charges_live.ex, accrue_admin/lib/accrue_admin/live/coupons_live.ex, accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex, accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex, accrue_admin/lib/accrue_admin/live/events_live.ex, accrue_admin/lib/accrue_admin/live/webhooks_live.ex, accrue_admin/lib/accrue_admin/live/dashboard_live.ex, accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex, accrue_admin/lib/accrue_admin/dev/clock_live.ex, accrue_admin/lib/accrue_admin/dev/fake_inspect_live.ex, accrue_admin/lib/accrue_admin/dev/webhook_fixture_live.ex, accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex, accrue_admin/lib/accrue_admin/dev/email_preview_live.ex, accrue_admin/test/accrue_admin/components/app_shell_test.exs, accrue_admin/test/accrue_admin/live/invoices_live_test.exs</files>
  <action>
A1 — Topbar (components/topbar.ex). Reduce to a utility bar. Remove the `ax-topbar-copy` block (the `ax-eyebrow` app_name and the `ax-heading` page_title) AND the entire `ax-topbar-brand-chip` div (the `ax-label` "Brand" + `ax-topbar-brand-name`). KEEP the skip link as the header's first child, moved directly under `<header class="ax-topbar">` and before `ax-topbar-actions`. Remove the now-unused `attr(:brand, …)` and `attr(:page_title, …)` declarations; keep `attr(:theme, …)`. The resulting markup: `<header class="ax-topbar">`, then `<a href="#main-content" class="ax-skip-link">Skip to content</a>`, then the existing `<div class="ax-topbar-actions">` (search trigger, menu toggle, ThemePicker) unchanged.

A1b — app_shell.ex. Update the `<Topbar.topbar … />` call (currently passes brand + page_title + theme) to pass only `theme={@theme}`. Leave every other app_shell assign and the `attr(:page_title, …)` / `attr(:brand, …)` on app_shell itself intact (page_title still flows to layouts.ex `<title>` and brand still flows to the sidebar).

A2 — Promote each page hero to `<h1>` (exactly one content `<h1>` per page). List/dashboard/analytics/dev heroes currently use `<h2 class="ax-display">…</h2>`; change the tag `<h2>`→`<h1>` and KEEP `class="ax-display"` (CSS unaffected) at every one of these 17 hero sites: subscriptions_live (line ~93), customers_live (~67), invoices_live (~69), charges_live (~69), coupons_live (~51), promotion_codes_live (~50), connect_accounts_live (~50), events_live (~87), webhooks_live (~138), dashboard_live (~52), analytics/recovery_live (~104), dev/clock_live (~67), dev/fake_inspect_live (~48), dev/webhook_fixture_live (~79), dev/component_kitchen_live (~84), dev/email_preview_live (~56). For detail pages: in components/detail.ex `summary_card`, change `<h2 class="ax-summary-title">`→`<h1 class="ax-summary-title">` (one edit covers ALL detail pages including analytics/campaign_live, which has no own hero and relies on summary_card). KEEP the summary-card eyebrow line (`<p :if={@eyebrow} class="ax-eyebrow">`) — it is a record-type label, not a section echo.

A2b — Remove redundant page-header eyebrows (the `<p class="ax-eyebrow">…</p>` placed right after the breadcrumb on list pages, which only echoes the section name the breadcrumb already shows). Remove ONLY these 9 list-page header eyebrows: subscriptions_live (~92 "Subscriptions"), customers_live (~66 "Customers"), charges_live (~68 "Charges"), invoices_live (~68 `Copy.invoices_index_eyebrow()`), coupons_live (~50 `Copy.coupon_index_eyebrow()`), promotion_codes_live (~49 `Copy.promotion_codes_index_eyebrow()`), connect_accounts_live (~49 `Copy.connect_accounts_eyebrow()`), events_live (~86 `billing_events_eyebrow(@current_owner_scope)`), analytics/recovery_live (~102 "Recovery Dashboard"). Do NOT remove webhooks_live's "Webhook operations" eyebrow if it pairs with the hero header — re-confirm by reading context: remove it only if it is the redundant page-header eyebrow directly above the `ax-display` hero (it is, at ~137). Do NOT touch in-card/section `ax-eyebrow` labels: charge_live "Fee breakdown"/"Refund", subscription_live "Tax risk"/"Admin actions"/dunning/related-card, webhooks_live "DLQ bulk replay", invoice_live tax-risk/actions/pdf eyebrows — these are in-card labels and STAY.

A2c — events_live.ex has a private `billing_events_eyebrow/1` helper (lines ~207-210) used ONLY by the removed header eyebrow; remove the now-orphaned private helper. (The two `Copy.billing_events_eyebrow_organization/0` and `_global/0` it delegated to are reached nowhere else — leave the Copy functions in place to avoid widening scope; deleting only the call site is sufficient and keeps Copy modules untouched per "grep first, remove only zero-reference".)

A3 — CSS (assets/css/app.css) — grouped-selector care. Remove ONLY the topbar-copy/brand-chip rules. From the read of app.css the relevant lines are: a standalone `.ax-topbar-brand-chip { … }` (~591), `.ax-topbar-brand-chip { … }` (~682), `.ax-topbar-brand-chip` (~901) + `.ax-topbar-brand-name` (~910), the dark/system theme grouped rules at ~920-922 and ~928-930 (`html.accrue-admin[data-theme="dark"] .ax-topbar-brand-chip, … .ax-label, … .ax-topbar-brand-name`), and the `@media` block `.ax-topbar-brand-chip` (~2754). Before deleting any selector, confirm it is NOT grouped with a shared selector you must keep; the lines at ~524-525 group `.ax-topbar, .ax-topbar-actions, …` — KEEP those (they style the surviving header + actions). If a brand-chip selector shares a rule body with `.ax-eyebrow`/`.ax-display`/`.ax-heading`/`.ax-label` or `.ax-topbar`/`.ax-topbar-actions`, SPLIT the group and delete only the brand-chip selector (theme-picker lesson). Also remove any `.ax-topbar-copy` rule if present. After removal, `.ax-topbar` has just the skip link + right-side actions — ensure actions stay right-aligned (e.g. `justify-content: flex-end` on `.ax-topbar`, tokens only, no hardcoded hex). KEEP `.ax-eyebrow`, `.ax-display`, `.ax-heading`, `.ax-label`, `.ax-skip-link` intact.

A5 — Tests. (1) test/accrue_admin/components/app_shell_test.exs "topbar renders configured admin brand name" currently asserts `html =~ "Accrue Admin"` via the removed chip — re-point it: the brand `app_name` must still be honored where it now lives. The sidebar renders the brand via an inline SVG with a hardcoded `aria-label="Accrue"` / `<title>Accrue</title>` (logo_url path uses `alt={@brand.app_name}`). For white-label correctness, make the sidebar brand lockup expose `@brand.app_name` as its accessible name: in components/sidebar.ex set the SVG `aria-label` and `<title>` to `@brand.app_name` (replace the hardcoded "Accrue"); if the brand lockup is not already a home link, do not add routing — just ensure the accessible name is `@brand.app_name`. Then re-point the test to assert the brand `app_name` ("Accrue Admin") appears as the sidebar accessible name AND/OR in the document is honored — assert `html =~ "Accrue Admin"` still passes via the sidebar `aria-label`/`<title>`, and add `refute html =~ ~s(ax-topbar-brand-chip)` plus an assertion that the topbar no longer renders the page title (e.g. the topbar region does not contain the `ax-heading` page-title element). Keep the existing `refute html =~ "Internal billing operations"`. (2) test/accrue_admin/live/invoices_live_test.exs line ~63 asserts `html =~ AccrueAdmin.Copy.Invoice.invoices_index_eyebrow()` — that eyebrow is now removed from the page; remove or re-point that single assertion (prefer removing the stale eyebrow assertion; do NOT assert removed chrome). Keep all breadcrumb and navigation_components tests green (unchanged).

Do NOT rebuild the bundle in this task — the CSS change is rebuilt+committed together with Part B's JS change in Task 2 (single bundle rebuild covers both). Commit Part A source changes as one atomic commit.
  </action>
  <verify>
    <automated>cd accrue_admin && mix compile --warnings-as-errors 2>&1 | tail -5 && mix test test/accrue_admin/components/app_shell_test.exs test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/live/invoices_live_test.exs 2>&1 | tail -15</automated>
  </verify>
  <done>topbar.ex renders only skip link + ax-topbar-actions (no brand chip, no page-title/eyebrow); app_shell passes only theme to topbar; detail.ex summary_card title is `<h1>`; all 17 list/dashboard/analytics/dev heroes are `<h1 class="ax-display">`; 9 redundant page-header eyebrows removed (in-card eyebrows kept); orphan `billing_events_eyebrow/1` helper removed; CSS brand-chip/brand-name/topbar-copy rules removed with shared selectors split-and-kept and actions right-aligned; sidebar brand accessible name = `@brand.app_name`; app_shell_test re-pointed (asserts brand honored in sidebar + refutes brand chip + refutes topbar page title); invoices_live_test stale eyebrow assertion removed; `mix compile --warnings-as-errors` clean and the three named test files green.</done>
</task>

<task type="auto">
  <name>Task 2 (Part B): Vendor + wire the navigation loading bar, rebuild and commit the bundle, resolve CSP</name>
  <files>accrue_admin/assets/vendor/topbar.js, accrue_admin/assets/js/app.js, accrue_admin/priv/static/accrue_admin.js, accrue_admin/priv/static/accrue_admin.css</files>
  <action>
B1 — Vendor topbar (assets/vendor/topbar.js). Create the directory if absent. Vendor the canonical MIT `topbar` library — the exact file `phx.new` ships (current 3.x line). RETAIN the original MIT license header comment verbatim (copyright Buu Nguyen, MIT). The file must be a self-contained ES module ending with `export default topbar` (the phx.new build exports default) so `import topbar from "../vendor/topbar.js"` works with the esbuild `--format=esm --bundle` pipeline. There is NO node_modules — this matches the repo's relative-import convention (app.js already imports phoenix via `../../deps/...`). Do NOT add a mix/npm dependency.

B2 — Wire it (assets/js/app.js). Add, without touching any existing import, hook, or `liveSocket` setup:
  - `import topbar from "../vendor/topbar.js"` alongside the other top-of-file imports.
  - After the imports (module top level, runs on deferred load — the runtime brand `<style>` is already applied by then so `--ax-accent` is live): read the accent at config time —
    read `getComputedStyle(document.documentElement).getPropertyValue("--ax-accent")`, trim it, fall back to `"#5D79F6"` if empty (white-label aware Cobalt default).
  - `topbar.config({ barColors: { 0: accent }, shadowColor: "rgba(0,0,0,.15)", barThickness: 2 })`.
  - `const reduce = window.matchMedia("(prefers-reduced-motion: reduce)")`.
  - `window.addEventListener("phx:page-loading-start", () => topbar.show(reduce.matches ? 0 : 300))` — the 300ms delay avoids a flash on instant nav; under reduced-motion show immediately (functional feedback, no shimmer delay).
  - `window.addEventListener("phx:page-loading-stop", () => topbar.hide())`.
  Keep all existing hooks/init (`ready(...)`, `CommandPalette`, `ConnectionState`, `FocusTrap`, `SidebarCollapse`, `liveSocket.connect()`) untouched.

B4 — CSP resolution (REQUIRED, do not skip — concrete finding, not a guess). The admin CSP is set in lib/accrue_admin/csp_plug.ex as `style-src 'self' 'nonce-#{nonce}'` with NO `'unsafe-inline'`. The vendored `topbar` creates a `<canvas>` and sets inline styles on it via the JS DOM API (`canvas.style.position = "fixed"`, `style.top/left/right/margin/padding = 0`, `style.zIndex = 100001`, and `canvas.style.opacity` during show/hide). Chromium enforces `style-src` against JS-set inline style properties when `'unsafe-inline'` is absent, so the progress-bar canvas styling WILL be blocked and the bar will not render. Resolve by relaxing the admin `style-src` MINIMALLY rather than patching the vendored lib: in csp_plug.ex add `'unsafe-inline'` to the `style-src` directive ONLY (leave `script-src` strict — keep its nonce, no `'unsafe-inline'` on scripts). Keep the existing `'nonce-#{nonce}'` so the nonced runtime theme `<style>` still validates. SURFACE this CSP relaxation prominently in the SUMMARY (it is a security-boundary change: admin style-src now permits inline styles to allow the canvas progress bar). Do NOT relax script-src. Do NOT patch topbar.js to dodge CSP.

B3 — Rebuild + commit the bundle. Run `cd accrue_admin && mix accrue_admin.assets.build` — this regenerates BOTH `priv/static/accrue_admin.css` (changed by Part A's CSS edits) and `priv/static/accrue_admin.js` (changed by Part B's app.js edits, with topbar bundled in). The admin serves the COMMITTED bundle and `AccrueAdmin.Assets` recomputes md5 at compile time from the committed bytes, so `assets_test.exs` will assert the new committed hash — both regenerated files MUST be committed. Commit Part B (vendor/topbar.js + app.js + csp_plug.ex + both rebuilt priv/static files) as the second atomic commit.
  </action>
  <verify>
    <automated>cd accrue_admin && mix accrue_admin.assets.build && mix compile --warnings-as-errors 2>&1 | tail -5 && grep -c topbar priv/static/accrue_admin.js && ! grep -q "ax-topbar-brand-chip" priv/static/accrue_admin.css && grep -q "ax-eyebrow" priv/static/accrue_admin.css && grep -q "ax-display" priv/static/accrue_admin.css && mix test test/accrue_admin/assets_test.exs 2>&1 | tail -8</automated>
  </verify>
  <done>assets/vendor/topbar.js exists with MIT header and `export default topbar`; app.js imports it, reads `--ax-accent` (fallback #5D79F6), configures barThickness 2 + shadowColor, and wires phx:page-loading-start/stop with reduced-motion handling, all existing hooks untouched; csp_plug.ex style-src includes `'unsafe-inline'` (script-src still strict) and the change is surfaced in SUMMARY; `mix accrue_admin.assets.build` regenerates both bundles; `grep -c topbar priv/static/accrue_admin.js` ≥ 1; `ax-topbar-brand-chip` absent from built CSS; `ax-eyebrow` and `ax-display` still present in built CSS; both rebuilt priv/static files committed; `assets_test.exs` green (committed-hash assertions pass).</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| browser → admin LiveView | Admin operator's browser renders served HTML/JS/CSS under a strict CSP |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-qkx-01 | Tampering / Information disclosure | csp_plug.ex `style-src` relaxation (`'unsafe-inline'`) | accept (scoped) | Relax `style-src` ONLY (script-src stays nonce-strict, no `'unsafe-inline'` on scripts). Admin is an internal operator surface; permitting inline *styles* (no script execution) to let the vendored topbar canvas render is low-risk. Surfaced explicitly in SUMMARY as a security-boundary change. Do NOT relax script-src. |
| T-qkx-02 | Tampering | vendored assets/vendor/topbar.js | mitigate | Vendor the canonical MIT phx.new file with its license header retained; no npm/mix dependency added (no supply-chain install surface); reviewed inline before commit. |
| T-qkx-SC | Tampering | npm/pip/cargo installs | n/a | No package-manager installs in this plan — topbar is vendored as a source file, no new mix deps, no node_modules. |
</threat_model>

<verification>
Run from repo root:
1. `cd accrue_admin && mix accrue_admin.assets.build && mix compile --warnings-as-errors` — clean (no warnings).
2. `cd accrue_admin && mix test` — all green, especially: `components/app_shell_test.exs`, `components/navigation_components_test.exs`, `assets_test.exs`, the live suites (incl. `live/invoices_live_test.exs`), and the axe-a11y / component-lab guardrails (exactly one `<h1>` per page; `page-has-heading-one` stays green).
3. `cd accrue_admin && grep -c topbar priv/static/accrue_admin.js` — ≥ 1.
4. `cd accrue_admin && grep -q "ax-topbar-brand-chip" priv/static/accrue_admin.css; echo $?` — non-zero (gone); `grep -q "ax-eyebrow" priv/static/accrue_admin.css && grep -q "ax-display" priv/static/accrue_admin.css` — both present.
5. Manual visual spot-check (optional, host hot-reloads via reloadable_apps after the bundle rebuild) at `http://accrue.localhost/admin/subscriptions`: topbar shows only search/menu/theme (no "Accrue Admin", no page title, no brand chip); one orientation path = sidebar active + breadcrumb "Dashboard / Subscriptions" + single `<h1>` "Lifecycle-safe subscription search" + copy; navigating between sections runs a thin Cobalt progress bar along the top (no flash on instant loads; reduced-motion shows bar immediately, no shimmer delay); light/dark/system clean; no CSP console errors. Detail page (a customer) → single `<h1>` (summary-card title), breadcrumb intact, no topbar title.
</verification>

<success_criteria>
- Topbar is a pure utility bar (search · menu · theme) on every admin page; brand chip and topbar page-title/eyebrow gone; skip link is the topbar's first focusable child.
- Every admin page (list, detail, dashboard, analytics, dev) ends with exactly ONE content `<h1>`; axe `page-has-heading-one` guardrail green.
- 9 redundant page-header eyebrows removed; all in-card/section `ax-eyebrow` labels and the detail summary-card eyebrow retained.
- Brand `app_name` is the sidebar brand-lockup accessible name (white-label correct); app_shell_test re-pointed.
- Vendored MIT `topbar` wired to `phx:page-loading-start/stop`, accent from `--ax-accent` (fallback #5D79F6), barThickness 2, reduced-motion aware; existing hooks untouched.
- Admin `style-src` minimally relaxed (`'unsafe-inline'` on styles only; script-src stays strict) with the change surfaced in SUMMARY.
- `priv/static/accrue_admin.{css,js}` rebuilt and committed; `assets_test.exs` committed-hash assertions pass.
- Two atomic commits (Part A chrome, Part B loading bar incl. rebuilt bundle); ROADMAP.md untouched; no `examples/accrue_host/mix.lock` or `.planning/research/.cache/` changes; no new mix deps.
- Future seed noted: a shared `page_header` component consolidation is worthwhile but out of scope here.
</success_criteria>

<output>
Create `.planning/quick/260620-qkx-de-duplicate-admin-orientation-chrome-ut/260620-qkx-SUMMARY.md` when done. In the SUMMARY, prominently record: (1) the CSP `style-src` relaxation as a security-boundary change, and (2) the future seed — a shared `page_header` component consolidation (deferred, not built).
</output>
