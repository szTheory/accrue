# Phase 194: Exemplar A — Dashboard - Pattern Map

**Mapped:** 2026-06-25
**Files analyzed:** 6 (2 LiveView modify, 1 CSS modify + committed bundle, 1 new e2e spec, 1 CI guard modify, 1 ExUnit mirror modify)
**Analogs found:** 6 / 6 (every change has an in-repo template; this is a wiring phase, not a build)

> All changes are additive markers, a single render re-order, light CSS, a new e2e spec, and one coupled source-guard. No new dependencies, no new domain code, no new routes. Every analog is the file being edited or a sibling guard already in the same file. Copy from the cited excerpts verbatim.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` (modify) | LiveView (render) | request-response (HEEx render) | itself (in-place marker add) — and existing `data-command-palette-trigger` attr at L105 | exact (self) |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` (modify) | LiveView (render) | request-response (HEEx render) | itself (render-block re-order L145–152) | exact (self) |
| `accrue_admin/assets/css/app.css` (modify) | config/style (CSS source) | transform (built → committed bundle) | existing `.ax-empty` / `.ax-attention*` blocks (L3228–3336) | exact (sibling rule) |
| `accrue_admin/priv/static/accrue_admin.css` (regenerate) | build artifact (served bundle) | transform (tailwind CLI minify) | `mix accrue_admin.assets.build` task | exact |
| `accrue_admin/e2e/<new>-spec-overview.spec.js` (new) | test (Playwright page-flow) | event-driven (browser assertions) | `admin-page-flow-phase191.spec.js` + `phase191-page-flow-helpers.js` | role+flow match |
| `scripts/ci/verify_package_docs.sh` (modify) | test infra (CI source guard) | batch/transform (grep/perl source lint) | RES-04 Guards A/C at L552–586 | exact (sibling guard) |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` (modify) | test (ExUnit negative test) | request-response (run verifier, assert fail) | the 3 CSS-guard negative tests at L457–523 + `seed_tmp_dir!` L665–717 | exact (sibling test) |

## Pattern Assignments

### `dashboard_live.ex` (LiveView render — additive `data-ax-*` markers + empty-rail hero class)

**Analog:** itself. `render/1` is L39–234. Source DOM order is already `attention(L57) < task(L93) < kpi(L149) < recent(L198)` — D-05's index invariant holds from marker placement alone; **do NOT move any `<section>`**.

**Zone-marker placement (D-04/D-05)** — add one attribute per existing zone `<section>`:
- L57 `<section class="ax-home-section" aria-label="Billing exceptions">` → add `data-ax-zone="attention-rail"`
- L93 `<section class="ax-home-section" aria-label="Tasks">` → add `data-ax-zone="task-launcher"`
- L149 `<section class="ax-home-section" aria-label={...}>` → add `data-ax-zone="kpi-cluster"`
- L198 `<section class="ax-grid ax-grid-2" ...>` → add `data-ax-zone="recent-activity"`

**⌘K additive marker** — the existing button at L100–106 (DO NOT rename `data-command-palette-trigger`; `command_palette.js` binds it):
```elixir
<button
  type="button"
  class="ax-input-search"
  role="search"
  aria-label="Search"
  data-command-palette-trigger="true"
  data-ax-command-palette-trigger="true"   <%!-- ADD this sibling marker only --%>
>
```

**Empty-rail hero (D-06)** — the existing empty card at L85–89 is the elevate target. Add the SPEC-OVERVIEW-named class `.ax-attention-rail--empty` alongside `ax-card ax-empty`, keep it non-interactive (no `role="button"`, no on-click), keep the existing `Copy.home_attention_empty_title/0` + `Copy.home_attention_empty_copy/0` (elevate hierarchy, do not rewrite copy):
```elixir
<div :if={@attention == []} class="ax-card ax-empty ax-attention-rail--empty">
  <Icon.icon name={:check_circle} size="lg" class="ax-empty-icon" />
  <p class="ax-empty-title"><%= Copy.home_attention_empty_title() %></p>
  <p class="ax-body ax-empty-copy"><%= Copy.home_attention_empty_copy() %></p>
</div>
```

**Copy convention (CLAUDE.md):** all strings via `AccrueAdmin.Copy.*` — never inline. The dashboard imports it at L14 (`alias AccrueAdmin.Copy`).

---

### `recovery_live.ex` (LiveView render — the single structural change + zone markers)

**Analog:** itself. `render/1` is L90–156. The one load-bearing change (D-01): **swap so `AtRiskTable` renders above `FunnelChart`.** Today L145–150 (`FunnelChart.funnel_chart`) renders *before* L152 (`AtRiskTable.at_risk_table`). After the swap:
```elixir
<AtRiskTable.at_risk_table rows={@at_risk} base_path={@admin_mount_path} />

<FunnelChart.funnel_chart
  entered={@funnel.entered}
  recovered={@funnel.recovered}
  exhausted={@funnel.exhausted}
  active={@funnel.active}
/>
```

**Hero pair stays leading (D-02):** the `@kpi_pairs` loop at L121–143 (Recovered MRR / Exhausted MRR) is unchanged — confirm it remains above the now-promoted table.

**Recovery zone markers (Q-A, planner discretion):** Recovery has NO attention/exception rail; its leading zone IS the hero metric pair. The load-bearing machine check is **at-risk-table DOM index < funnel DOM index** (no chart before the work-queue). Recommendation: mark only what the assertion needs — put a `data-ax-zone` on the hero `<section>` (L122) and on the at-risk table wrapper — do NOT force an `attention-rail` marker onto a page with no rail. The single h1 is already present at L104 (`<h1 class="ax-display">`).

---

### `app.css` (CSS source — light polish, MUST rebuild the committed bundle)

**Analog:** the existing `.ax-empty*` block at **L3330–3336** and `.ax-attention*` block at **L3228–3327**. Add the new `.ax-attention-rail--empty` rule directly beside `.ax-empty` (L3332), token-only:
```css
/* SPEC-OVERVIEW (Phase 194): elevated healthy "all clear" hero — NON-INTERACTIVE.
   No cursor:pointer, no :hover rule on .ax-attention-rail--empty (D-06 guard). */
.ax-attention-rail--empty {
  /* elevate hierarchy with EXISTING tokens only: e.g. larger gap/padding via --ax-space-*,
     stronger title via --ax-type-* — introduce NO new tokens (CONTEXT guardrail) */
}
```

**KPI demotion / exception emphasis (D-03 "light polish"):** scope to the `.ax-kpi-*` grid framing (card weight, label contrast via `--ax-muted`) and the `.ax-attention*` weight — bounded, no broad rework. Existing token ladder: `--ax-space-*` (Spacing Scale in UI-SPEC), `--ax-type-*`, `--ax-muted`, status/money tokens. KPI value type lives in the `KpiCard` component classes.

**RES-04 guards that WILL trip you (verified L552–586):**
- Guard A (L555–568): raw px on `padding|margin|gap` outside `var(--ax-` fails CI — use `--ax-space-*` tokens, or annotate `/* ax-spacing-exception: ... */`.
- Guard B (L571): `:focus` without `:focus-visible` fails.
- Guard C (L575–586): `text-overflow:ellipsis` without `min-width:0` in the same block fails.

**Build invariant (Pitfall 1 — Phase 189 shipped dead CSS this way):** editing `app.css` ships NOTHING. After every CSS edit run from `accrue_admin/`:
```bash
mix accrue_admin.assets.build
git add accrue_admin/priv/static/accrue_admin.css
```
The served file is committed `priv/static/accrue_admin.css`, not `app.css`. The plan MUST make rebuild+commit an explicit, verifiable step (assert `git diff --stat` includes `priv/static/accrue_admin.css` whenever `app.css` changed). The JS bundle is NOT touched (D-04).

---

### `<new>-spec-overview.spec.js` (new Playwright page-flow spec — reuses 191 helpers)

**Analog:** `accrue_admin/e2e/admin-page-flow-phase191.spec.js`. Copy its scaffolding patterns:
- **Helper import** (spec L5–20): import from `./phase191-page-flow-helpers.js`. The assertion API is exported at helpers L315–331: `assertFocusWithin(page, target, label)`, `assertTopPointerTarget(locator, label)`, `assertScrollReachable(locator, label)`, `assertNoHorizontalClip(page, selector, label)`, `assertNoBodyFocus(page, label)`.
- **Trace + describe** (spec L22, L139): `test.use({ trace: "retain-on-failure" });` and `test.describe(...)`.
- **Reset / seed / login** (spec L82–93, L130–133):
```javascript
async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}
async function seedScenario(request, scenario, { optional = false } = {}) {
  const response = await request.post(`/__e2e__/seed/${scenario}`);
  if (optional && response.status() === 404) return {};
  expect(response.ok(), `seed ${scenario} should return 2xx`).toBeTruthy();
  return response.json();
}
async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
  await expect(page.locator("#main-content, main").first()).toBeVisible();
}
```
- **Viewport loop** (spec L205–208): `page.setViewportSize(...)` over `PHASE191_VIEWPORTS`; theme via `setPhase191Theme(page, theme)`.

**SPEC-OVERVIEW invariant assertions to add (none exist yet — 194 is the first enforcer):**
```javascript
const { assertFocusWithin, assertTopPointerTarget } = require("./phase191-page-flow-helpers.js");

// one h1
expect(await page.locator("h1").count()).toBe(1);

// ⌘K present + focusable (binds the NEW marker)
const kbd = page.locator("[data-ax-command-palette-trigger]");
await expect(kbd).toBeVisible();
await kbd.focus();
await assertFocusWithin(page, kbd, "command palette trigger");

// zone DOM order (D-05)
const order = await page.evaluate(() =>
  [...document.querySelectorAll("[data-ax-zone]")].map((n) => n.dataset.axZone)
);
expect(order.indexOf("attention-rail")).toBeLessThan(order.indexOf("task-launcher"));
expect(order.indexOf("task-launcher")).toBeLessThan(order.indexOf("kpi-cluster"));

// empty-rail non-interactive (seed the empty attention state first; assert NOT a pointer target)
// recovery: at-risk-table DOM index < funnel DOM index (no chart before work-queue)
```
Quick run: `cd accrue_admin && npx playwright test e2e/<new>-spec-overview.spec.js --workers=1`.

---

### `verify_package_docs.sh` (new empty-rail source guard — sibling to RES-04 Guards)

**Analog:** Guard C block-scan at **L575–586** (perl `-0ne` over `$app_css`). `$app_css` is defined at L323. Helpers: `require_regex` (L30–35), `fail` (L9–12). Place the new guard immediately after Guard C (~L586), before the spec-guide existence checks (L588). Block-scan style matching Guard C:
```bash
# Guard D — Empty-rail non-interactivity (Phase 194, SPEC-OVERVIEW)
empty_rail_pointer_hit=$(
  perl -0ne '
    while (/\.ax-attention-rail--empty[^{]*\{([^}]*)\}/gs) {
      my $block = $1;
      if ($block =~ /cursor\s*:\s*pointer/) { print "found cursor:pointer on empty rail\n"; last; }
    }
  ' "$app_css" || true
)
[[ -z "$empty_rail_pointer_hit" ]] || fail "$app_css must not put cursor:pointer on .ax-attention-rail--empty (SPEC-OVERVIEW non-interactive empty-rail guard)"
```
A `grep -E` line-guard is also acceptable; the block-scan mirrors the existing Guard C convention. Keep the `fail` message text stable so the ExUnit mirror can `=~`-match it.

---

### `package_docs_verifier_test.exs` (new negative test — D-08 coupling, MANDATORY mirror)

**Analog:** the CSS-guard negative tests at **L457–523** (e.g. "rejects z-index literals" L457–469, "rejects raw type declarations" L511–523). `app.css` is already in the seed set (`seed_tmp_dir!` L697 `copy_fixture!("accrue_admin/assets/css/app.css", ...)`), so the needle binds. Use the **append-with-trailing-`\n`** pattern (193-05 deviation; full-replace breaks earlier token guards):
```elixir
test "package docs verifier rejects cursor:pointer on .ax-attention-rail--empty (Phase 194)" do
  tmp_dir = tmp_dir!()
  seed_tmp_dir!(tmp_dir)

  app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
  File.write!(
    app_css_path,
    File.read!(app_css_path) <> "\n.ax-attention-rail--empty { cursor: pointer; }\n"
  )

  {output, status} = run_verifier(tmp_dir)

  assert status != 0
  assert output =~ "[verify_package_docs]"
  assert output =~ "empty-rail"   # match a stable substring of the new fail message
end
```
**D-08 coupling (MEMORY: verify_package_docs ↔ test coupling):** the standalone script can be green while `mix test` fails all negative tests if the needle is unmirrored. Verify both:
`cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` and `bash scripts/ci/verify_package_docs.sh`.

## Shared Patterns

### Additive `data-ax-*` markers (never rename behavior attrs)
**Source:** dashboard `data-command-palette-trigger` at L105 (kept).
**Apply to:** both LiveViews. New `data-ax-zone` + `data-ax-command-palette-trigger` are detection-only static enum values (no PII/IDs). The JS hook (`command_palette.js`) is untouched (D-04).

### Centralized copy
**Source:** `AccrueAdmin.Copy` (aliased dashboard L14, recovery uses `Copy.*`).
**Apply to:** any text in either LiveView. Empty-state copy is *elevated in hierarchy*, not rewritten — keep `home_attention_empty_title/0` + `home_attention_empty_copy/0`.

### Token-only CSS (no new tokens, no raw px)
**Source:** `.ax-empty` block L3332–3336 (all `var(--ax-space-*)` / `var(--ax-type-*)`).
**Apply to:** all CSS deltas. RES-04 Guard A bans raw px on padding/margin/gap.

### Committed-bundle rebuild
**Source:** `mix accrue_admin.assets.build` (tailwind CLI minify → `priv/static/accrue_admin.css`).
**Apply to:** every `app.css` edit. Rebuild + `git add` the bundle or nothing ships.

### Source-guard ↔ ExUnit mirror coupling (D-08)
**Source:** RES-04 Guards (sh L552–586) ↔ negative tests (exs L457–523) ↔ `seed_tmp_dir!` (exs L665–717).
**Apply to:** the new empty-rail guard. Needle in sh MUST be mirrored by a negative test against the already-seeded `app.css`.

## No Analog Found

None. Every file has an exact in-repo template (the file itself, a sibling guard, or the 191 helper library).

## Scoring (not a file — context for the planner)

The page-flow cells **already exist and are `pending`** in `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.page-flow.cells.json` (432 `p193__dashboard__*` + 432 `p193__recovery__*`). Phase 194 **scores** them (sets `score`, flips `coverage_status` to `covered`) — it does NOT create cells. The zero-regression gate is `phase192-scorecard.mjs` `score-downgrade` against the `p187__` v1.53 baseline (`baseline.cells.json`). Open Q-B: confirm the `p193`↔`p187` baseline-lookup keying in `phase192-scorecard.mjs` (~L401/L457) before writing the SC3 gate assertion.

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/live/`, `accrue_admin/assets/css/`, `accrue_admin/e2e/`, `scripts/ci/`, `accrue/test/accrue/docs/`.
**Files scanned:** 7 (2 LiveViews, app.css, 2 e2e files, verify_package_docs.sh, package_docs_verifier_test.exs).
**Pattern extraction date:** 2026-06-25
