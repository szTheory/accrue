# Phase 189: Primitive & Form Components + Component Lab — Pattern Map

**Mapped:** 2026-06-17
**Files analyzed:** 13 primary edit surfaces + 2 new component families (newly created)
**Analogs found:** 13 / 13 primary surfaces; 0 analogs for newly-created component files

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | data-model/config | transform | itself (schema extension) | exact — extend in place |
| `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` | component (LiveView) | request-response (SSR) | itself (renderer conversion) | exact — convert hand-authored sections |
| `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` | test | CRUD (registry reads) | itself (tests (a)–(d) as analog for new (e)/(f)) | exact |
| `accrue_admin/assets/css/app.css` | config/CSS | transform | itself — extend `.ax-dev-variant-row` / `.ax-dev-grid` block | exact |
| `accrue_admin/assets/css/theme.css` | config/CSS | transform | itself — extend `html.accrue-admin[data-theme="dark"]` block | exact |
| `accrue_admin/e2e/admin-a11y.spec.js` | test (e2e) | event-driven | itself — `scan()` helper pattern | exact |
| `accrue_admin/e2e/admin-interactions.spec.js` | test (e2e) | event-driven | itself — `makeRecorder`/`observe`/`scrollProbe`/`focusCycleProbe` | exact |
| `scripts/ci/verify_package_docs.sh` | CI/utility | batch | itself — Phase-188 FND-01/FND-02 guard blocks | exact |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | test | batch | itself — `seed_tmp_dir!` + negative-fixture tests (z-index / font-literal) | exact |
| `accrue_admin/lib/accrue_admin/components/button.ex` | component | request-response | itself (root fix) | exact |
| `accrue_admin/lib/accrue_admin/components/input.ex` | component | request-response | itself (root fix) | exact |
| `accrue_admin/lib/accrue_admin/components/select.ex` | component | request-response | itself (root fix) | exact |
| `accrue_admin/lib/accrue_admin/components/status_badge.ex` | component | request-response | itself (root fix) | exact |
| `accrue_admin/lib/accrue_admin/components/icon.ex` | component | request-response | itself (registry entry only) | exact |
| `accrue_admin/lib/accrue_admin/components/money_formatter.ex` | component | request-response | itself (registry entry + class pass-through audit) | exact |
| `accrue_admin/lib/accrue_admin/components/json_viewer.ex` | component | request-response | itself (registry entry) | exact |
| New: `textarea.ex`, `checkbox.ex`, `radio.ex`, `toggle.ex`, `spinner.ex`, `tooltip.ex`, `empty_state.ex`, `inline_id.ex` | component | request-response | `input.ex` / `button.ex` / `status_badge.ex` (role-match) | role-match |

---

## Pattern Assignments

### `component_registry.ex` — Schema Extension

**Analog:** itself (lines 1–214 are the sole analog)

**Current entry shape** (lines 30–35 — button primary as canonical example):
```elixir
%{
  family: "button",
  variant: "primary",
  ax_class: "ax-button ax-button-primary",
  tokens: ["--ax-accent-strong", "--ax-accent-contrast", "--ax-transition-colors"]
}
```

**Phase 189 adds three new fields per entry** (Claude's discretion on exact schema shape per CONTEXT.md):
```elixir
%{
  family: "button",
  variant: "primary",
  ax_class: "ax-button ax-button-primary",
  tokens: ["--ax-accent-strong", "--ax-accent-contrast", "--ax-transition-colors"],
  # Phase 189 additions:
  applicable_states: ["default", "hover", "focus", "active", "pressed", "disabled", "loading", "overflow"],
  na_states: [
    %{state: "selected", reason: "button has no selection state — use aria-pressed for toggle buttons separately"},
    %{state: "empty", reason: "not applicable to button — it always has a label"},
    %{state: "error", reason: "button cannot be in an error state — use form validation at field level"}
  ],
  specimens: [
    %{label: "Default", props: %{variant: "primary", type: "button"}, content: "Primary action"},
    %{label: "Long label", props: %{variant: "primary", type: "button"}, content: "Save and continue to the next step in the configuration wizard"}
  ]
}
```

**Guard: ax_class must always have two space-separated classes** (variant-presence test (a) splits on first space — lines 26–27 of test file):
```elixir
# REQUIRED: ax_class must always have at least two space-separated tokens
# or test (a) pattern-match `[_base, variant_class] = String.split(ax_class, " ", parts: 2)` crashes.
# Foundation entries like "ax-foundation ax-foundation-type" already satisfy this.
```

**Module guard pattern** (lines 1–2 — keep for all new entries):
```elixir
if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.ComponentRegistry do
```

**`variants_for/1` helper** (lines 208–213 — used by kitchen renderer, keep intact):
```elixir
def variants_for(family) do
  Enum.filter(entries(), &(&1.family == family))
end
```

---

### `component_kitchen_live.ex` — Registry-Driven Matrix Renderer

**Analog:** itself (lines 164–231 are the registry-driven section analogs)

**D-07 gotcha comment** (lines 166–168 — replace this comment + the section below it):
```elixir
<%!-- Buttons variant reference. Each component is shown ONCE; review light vs
     dark with the page theme toggle (the per-specimen light/dark wrappers used to
     be inert — no CSS re-themed them — so they only looked like duplicates). --%>
```

**Current registry-driven loop pattern** (lines 172–186 — copy this for the new matrix renderer, then extend with two-column light/dark structure):
```elixir
<div class="ax-dev-grid">
  <%= for entry <- ComponentRegistry.variants_for("button") do %>
    <div class="ax-dev-variant-row">
      <Button.button variant={entry.variant} type="button">
        <%= String.capitalize(entry.variant) %>
      </Button.button>
      <dl class="ax-dev-token-dl">
        <dt class="ax-label"><code><%= entry.ax_class %></code></dt>
        <%= for token <- entry.tokens do %>
          <dd class="ax-dev-token">
            <span :if={color_token?(token)} class="ax-token-swatch" style={"background: var(#{token})"}></span>
            <code :if={!color_token?(token)} class="ax-type-code-xs ax-token-kind"><%= token_kind(token) %></code>
            <code class="ax-type-code-xs"><%= token %></code>
          </dd>
        <% end %>
      </dl>
    </div>
  <% end %>
</div>
```

**New pattern: two-column state-grid** (replaces the above per-family; `data-theme` drives D-07 genuine token re-scope):
```heex
<%!-- State-matrix renderer: rows = applicable states; light + dark columns side-by-side.
     .ax-dev-state-grid-col[data-theme] re-scopes --ax-* tokens via the theme.css
     `.accrue-admin [data-theme="dark"]` sub-tree selector added in Phase 189. --%>
<section :if={@available?} class="ax-card ax-dev-stack" data-ax-family={entry.family}>
  <p class="ax-label"><%= entry.family %></p>
  <div class="ax-dev-state-grid">
    <div class="ax-dev-state-grid-col" data-theme="light">
      <p class="ax-dev-state-grid-col-header ax-label">Light</p>
      <%= for state <- entry.applicable_states do %>
        <div class="ax-dev-state-cell" data-ax-state={state}>
          <span class="ax-dev-state-cell-label ax-type-code-xs ax-muted"><%= state %></span>
          <%!-- render specimen for this state --%>
        </div>
      <% end %>
      <%= for %{state: state, reason: reason} <- entry.na_states do %>
        <div class="ax-dev-state-cell ax-dev-state-cell-na" data-ax-state={state} data-ax-na-reason={reason}>
          <span class="ax-dev-state-cell-label ax-type-code-xs ax-muted"><%= state %> (n/a)</span>
          <span class="ax-type-code-xs ax-muted"><%= reason %></span>
        </div>
      <% end %>
    </div>
    <div class="ax-dev-state-grid-col" data-theme="dark">
      <%!-- mirror of light column --%>
    </div>
  </div>
</section>
```

**Private helper functions** (lines 472–496 — all reusable in the matrix renderer, keep untouched):
```elixir
defp color_token?(token), do: not non_color_token?(token)

defp non_color_token?(token) do
  String.contains?(token, "-font") or
    String.contains?(token, "tracking") or
    String.contains?(token, "shadow") or
    String.contains?(token, "transition") or
    String.starts_with?(token, "--ax-z-") or
    token == "--ax-measure"
end

defp token_kind(token) do
  cond do
    String.contains?(token, "-font") -> "font"
    String.contains?(token, "tracking") -> "tracking"
    String.contains?(token, "shadow") -> "shadow"
    String.contains?(token, "transition") -> "motion"
    String.starts_with?(token, "--ax-z-") -> "z-index"
    token == "--ax-measure" -> "measure"
    true -> "color"
  end
end
```

**`assign_shell/4` deficiency** (lines 451–462 — currently missing `:active_organization_name`):
```elixir
defp assign_shell(socket, admin, path, title) do
  socket
  |> assign(:page_title, title)
  |> assign(:brand, admin["brand"] || default_brand())
  |> assign(:theme, admin["theme"] || "system")
  |> assign(:csp_nonce, admin["csp_nonce"])
  |> assign(:brand_css_path, admin["brand_css_path"])
  |> assign(:assets_css_path, admin["assets_css_path"])
  |> assign(:assets_js_path, admin["assets_js_path"])
  |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
  |> assign(:current_path, (admin["mount_path"] || "/billing") <> path)
  # Phase 189 must add: |> assign(:active_organization_name, admin["active_organization_name"])
end
```

---

### `component_registry_test.exs` — New Tests (e) and (f)

**Analog:** itself — tests (a)–(d) as structural patterns (lines 19–169)

**Test (a) mount + assert pattern** (lines 19–33 — copy for new test (e)):
```elixir
test "every registry variant appears in the /dev/components page render", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  assert {:ok, _view, html} = live(conn, "/billing/dev/components")

  for %{ax_class: ax_class} <- ComponentRegistry.entries() do
    [_base, variant_class] = String.split(ax_class, " ", parts: 2)
    assert html =~ variant_class,
           "registry variant #{inspect(ax_class)} — variant class #{inspect(variant_class)} " <>
             "was not found in the /dev/components page HTML"
  end
end
```

**New test (e): state-matrix structural markup** — copy (a) mount pattern, assert state cells and n/a cells:
```elixir
test "state-matrix grid renders applicable_states and na_states for every entry that has them", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  assert {:ok, _view, html} = live(conn, "/billing/dev/components")

  for entry <- ComponentRegistry.entries(),
      Map.has_key?(entry, :applicable_states) do
    for state <- entry.applicable_states do
      assert html =~ ~s(data-ax-state="#{state}"),
             "registry entry #{entry.family}/#{entry.variant}: state #{inspect(state)} " <>
               "not found as data-ax-state attribute in /dev/components HTML"
    end

    for %{state: state} <- Map.get(entry, :na_states, []) do
      assert html =~ ~s(data-ax-state="#{state}"),
             "registry entry #{entry.family}/#{entry.variant}: n/a state #{inspect(state)} " <>
               "not found in /dev/components HTML (n/a rows must still render with stated reason)"
    end
  end
end
```

**New test (f): theme column data-attributes** — copy (a) mount pattern, assert column wrappers:
```elixir
test "rendered /dev/components page has at least one light and one dark theme column", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  assert {:ok, _view, html} = live(conn, "/billing/dev/components")

  assert html =~ ~s(data-theme="light"),
         "no .ax-dev-state-grid-col[data-theme=\"light\"] found in /dev/components HTML"
  assert html =~ ~s(data-theme="dark"),
         "no .ax-dev-state-grid-col[data-theme=\"dark\"] found in /dev/components HTML"
end
```

**Test (c) token-validity** (lines 93–120 — the new primitive entries must list their tokens here; no structural change needed, just ensure new entries populate `tokens`):
```elixir
# known_in_layouts allowlist: unchanged — only --ax-accent / --ax-accent-contrast
known_in_layouts = ["--ax-accent", "--ax-accent-contrast"]
```

**Test (d) phantom-token refutes** (lines 148–169 — keep existing refutes, add none for Phase 189):
```elixir
refute html =~ "--ax-neutral"
refute html =~ "--ax-ink"
refute html =~ "--ax-info"
```

**CSS path helpers** (lines 171–177 — reuse unchanged for new token-validity checks):
```elixir
defp theme_css_path do
  Path.expand("../../../assets/css/theme.css", __DIR__)
end

defp app_css_path do
  Path.expand("../../../assets/css/app.css", __DIR__)
end
```

---

### `app.css` — `.ax-dev-state-grid` Addition + Primitive Root Fixes

**Analog:** itself — existing `.ax-dev-grid` / `.ax-dev-variant-row` block (lines 160–229)

**Existing `.ax-dev-*` pattern** (lines 160–229 — copy display/gap/flex convention):
```css
.ax-dev-toolbar,
.ax-dev-toolbar-links,
.ax-dev-grid,
.ax-dev-stack {
  display: flex;
}

.ax-dev-toolbar,
.ax-dev-stack {
  gap: var(--ax-space-md);
}

.ax-dev-toolbar-links,
.ax-dev-grid {
  gap: var(--ax-space-sm);
  flex-wrap: wrap;
}

/* Component-kitchen specimen rows: the live component once, then its token map
   below it (no light/dark duplication — review themes via the page toggle). */
.ax-dev-variant-row {
  display: flex;
  flex-direction: column;
  gap: var(--ax-space-sm);
}
```

**New `.ax-dev-state-grid` block** (add after the existing `.ax-dev-variant-row` block, ~line 230):
```css
/* Phase 189 — state-matrix lab renderer (two-column light/dark grid per family) */
.ax-dev-state-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1px;
  border: 1px solid var(--ax-border);
  border-radius: var(--ax-radius-md);
  overflow: hidden;
  background: var(--ax-border);
}

.ax-dev-state-grid-col {
  display: flex;
  flex-direction: column;
  gap: 1px;
  background: var(--ax-border);
}

.ax-dev-state-grid-col-header {
  padding: var(--ax-space-sm) var(--ax-space-md);
  background: var(--ax-sunken);
}

.ax-dev-state-cell {
  display: flex;
  flex-direction: column;
  gap: var(--ax-space-sm);
  padding: var(--ax-space-md);
  background: var(--ax-base);
  min-height: 4rem;
}

.ax-dev-state-cell-na {
  background: var(--ax-sunken);
  opacity: 0.6;
}

@media (max-width: 599.98px) { /* --ax-bp-sm ↓ */
  .ax-dev-state-grid {
    grid-template-columns: 1fr;
  }
}
```

**Button root defects** (lines 1268–1338 — current state before Phase 189 fixes):
```css
/* CURRENT (defective) — Phase 189 migrates each of these: */
.ax-button {
  /* ax-type-exception: ... */
  font-size: 0.875rem;        /* → font: var(--ax-type-label-font); letter-spacing: var(--ax-type-label-tracking); */
  font-weight: 600;           /* (absorbed into composed role) */
  line-height: var(--ax-leading-normal); /* (absorbed into composed role) */
}

.ax-button[aria-disabled="true"],
.ax-button:disabled {
  opacity: 0.5;               /* → opacity: var(--ax-disabled-opacity); */
  pointer-events: none;       /* KEEP for click-blocking but ADD cursor: var(--ax-disabled-cursor); */
}
```

**Focus-visible block** (lines 2898–2917 — the authoritative pattern; `.ax-button` is already in the Phase-188 consolidated block; verify `.ax-field-control:focus-visible` at line 1758 is REPLACED by this block):
```css
/* Phase 188 consolidated focus-visible block — the ONLY place focus ring is set.
   Lines 1758-1762 (.ax-field-control:focus-visible { border-color:...; outline: none; })
   MUST be removed in Phase 189; this block already covers it. */
.ax-button:focus-visible,
.ax-sidebar-link:focus-visible,
/* ... (many selectors) ... */
.ax-field-control:focus-visible,
.ax-select-control:focus-visible,
/* ... */ {
  border-color: var(--ax-focus-ring);
  outline: 2px solid var(--ax-focus-ring);
  outline-offset: 2px;
  box-shadow: var(--ax-focus-shadow);
}
```

**IMPORTANT:** Lines 1687–1692 (`.ax-input:focus-visible, .ax-select:focus-visible, .ax-checkbox:focus-visible { border-color:...; outline: none; }`) and lines 1758–1762 (`.ax-field-control:focus-visible { border-color:...; outline: none; }`) must be REMOVED — they shadow the correct Phase-188 block.

**Field error token defect** (lines 1764–1783 — wrong token, Phase 189 fixes):
```css
/* CURRENT (defective): */
.ax-field-control-error {
  border-color: var(--ax-warning);    /* → var(--ax-status-danger-border) */
}
.ax-field-error {
  color: var(--ax-warning);           /* → var(--ax-status-danger-text) */
}
```

**StatusBadge token defect** (lines 1352–1375 — color-mix formulas replaced by status tokens):
```css
/* CURRENT (defective — uses color-mix instead of Phase-188 status tokens): */
.ax-status-badge-moss {
  background: color-mix(in srgb, var(--ax-success) 14%, var(--ax-elevated));
  color: var(--ax-success-readable);
}
/* Phase 189 replacement: */
/* .ax-status-badge-moss {
     background: var(--ax-status-success-bg);
     color: var(--ax-status-success-text);
     border: 1px solid var(--ax-status-success-border);
   } */
```

---

### `theme.css` — Sub-Tree Dark Selector (D-07 Critical Path)

**Analog:** itself — existing `html.accrue-admin[data-theme="dark"]` block (lines 218–276)

**Current dark selector chain** (lines 218–276):
```css
html.accrue-admin[data-theme="dark"] {
  --ax-base: #0f1318;
  --ax-elevated: #171d24;
  --ax-sunken: #0b1015;
  --ax-primary: #f4f7fa;
  --ax-muted: #a8b2bc;
  /* ... full dark token block (lines 218-276) ... */
  color-scheme: dark;
}
```

**Phase 189 addition** — add IMMEDIATELY AFTER the existing `html.accrue-admin[data-theme="dark"]` block, before the `@media (prefers-color-scheme: dark)` block at line 278. Must be a verbatim copy of the FULL token block from the existing dark selector:
```css
/* Phase 189 — Sub-tree theme scoping for the component lab state-matrix columns.
   Keeps html.accrue-admin[data-theme="dark"] for full-page production use;
   adds .accrue-admin [data-theme="dark"] so any DESCENDANT element with
   data-theme="dark" inside .accrue-admin genuinely re-scopes --ax-* tokens.
   Standard pattern (Radix, Primer): must contain the FULL dark token set — no subset. */
html.accrue-admin [data-theme="dark"],
.accrue-admin [data-theme="dark"] {
  --ax-base: #0f1318;
  --ax-elevated: #171d24;
  --ax-sunken: #0b1015;
  --ax-primary: #f4f7fa;
  --ax-muted: #a8b2bc;
  /* COPY THE FULL TOKEN BLOCK FROM html.accrue-admin[data-theme="dark"] VERBATIM */
  color-scheme: dark;
}
```

---

### `admin-a11y.spec.js` — Kitchen Route Extension

**Analog:** itself — existing `scan()` helper (lines 23–28) and surfaces loop (lines 50–88)

**`scan()` helper** (lines 23–28 — copy exactly, reuse for kitchen surface):
```js
async function scan(page, theme) {
  await page.evaluate((t) => document.documentElement.setAttribute("data-theme", t), theme);
  await page.waitForTimeout(50);
  const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
  return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}
```

**Surfaces array** (lines 50–72 — add `/billing/dev/components` as new entry, matching tuple shape `[name, path]`):
```js
const surfaces = [
  // ... existing 21 surfaces ...
  ["component-kitchen", "/billing/dev/components"]  // Phase 189: full state-matrix + both themes in one scan
];
```

**Failure reporting** (lines 74–90 — no change, failure loop covers all surfaces generically):
```js
for (const [name, path] of surfaces) {
  await login(page, path);
  await expect(page.locator("#main-content")).toBeVisible();
  for (const theme of ["light", "dark"]) {
    const violations = await scan(page, theme);
    for (const v of violations) {
      failures.push(`${name} [${theme}] ${v.id}: ...`);
    }
  }
}
```

---

### `admin-interactions.spec.js` — Component State Probes

**Analog:** itself — `makeRecorder` (lines 57–102), `observe` (lines 65–92), `scrollProbe` (lines 173–215), `focusCycleProbe` (lines 217–239), `topElementAt` (lines 127–139)

**`makeRecorder` factory** (lines 57–102 — copy for component-kitchen probes; the `projectName` param becomes the Playwright project name e.g. `"chromium-desktop"`):
```js
function makeRecorder(projectName) {
  const rows = [];
  let sequence = 0;
  function observe(row) {
    sequence += 1;
    const complete = {
      probe_id: row.probe_id || `ixn-${String(sequence).padStart(3, "0")}`,
      cell_id: row.cell_id || `p187__${slug(row.surface || row.interaction_class)}__${projectName}__${slug(row.state || "interactive-open")}__d11`,
      // ... all OBSERVATION_FIELDS ...
    };
    rows.push(complete);
    return complete;
  }
  function write() { /* writes NDJSON to test-results/admin-interactions/${projectName}/observations.ndjson */ }
  return { observe, write, rows };
}
```

**`scrollProbe` pattern** (lines 173–215 — copy for overflow cell assertions; `scrollWidth <= clientWidth`):
```js
async function scrollProbe(page, selector, recorder, surface, notes) {
  const metrics = await locator.evaluate((element) => {
    element.scrollTop = element.scrollHeight;
    return {
      scrollWidth: element.scrollWidth,
      clientWidth: element.clientWidth,
      // ...
    };
  });
  recorder.observe({
    interaction_class: "scroll-reachability",
    coverage_status: metrics.scrollWidth <= metrics.clientWidth ? "covered" : "gap",
    failure_kind: metrics.scrollWidth > metrics.clientWidth ? "content-overflow-escape" : null,
    overlay_tags: ["scroll-reachability"],
  });
}
```

**New Phase 189 probe pattern** — add after existing helper functions, before the `test.describe` block. Copy `observe` call structure exactly:
```js
// Phase 189 — focus-ring probe for interactive primitives
async function focusRingProbe(page, selector, recorder, surface, state) {
  const el = page.locator(selector).first();
  await el.focus();
  const styles = await el.evaluate((element) => {
    const cs = getComputedStyle(element);
    return {
      outlineWidth: cs.outlineWidth,
      outlineOffset: cs.outlineOffset,
      boxShadow: cs.boxShadow,
      cursor: cs.cursor,
    };
  });
  recorder.observe({
    interaction_class: "focus-ring",
    cell_id: `p187__${surface}__${recorder._projectName}__light__interactive-open__d07`,
    surface,
    surface_type: "component",
    state,
    rubric_dimension: "focus-semantics",
    target_selector: selector,
    expected: "outlineWidth >= 2px; outlineOffset >= 2px; box-shadow present",
    actual: JSON.stringify(styles),
    assertions: ["outline-width-2px", "outline-offset-2px"],
    coverage_status:
      parseFloat(styles.outlineWidth) >= 2 && parseFloat(styles.outlineOffset) >= 2
        ? "covered"
        : "gap",
    failure_kind: parseFloat(styles.outlineWidth) < 2 ? "focus-ring-missing" : null,
    overlay_tags: ["focus-restore"],
  });
}

// Phase 189 — theme delta assertion (D-07 resolution proof)
async function themeColumnDeltaProbe(page, recorder) {
  const { lightBase, darkBase } = await page.evaluate(() => {
    const light = document.querySelector('.ax-dev-state-grid-col[data-theme="light"]');
    const dark = document.querySelector('.ax-dev-state-grid-col[data-theme="dark"]');
    if (!light || !dark) return { lightBase: null, darkBase: null };
    return {
      lightBase: getComputedStyle(light).getPropertyValue("--ax-base").trim(),
      darkBase: getComputedStyle(dark).getPropertyValue("--ax-base").trim(),
    };
  });
  recorder.observe({
    interaction_class: "theme-column-delta",
    cell_id: "p187__component-kitchen__chromium-desktop__light__default-populated__d01",
    surface: "component-kitchen",
    surface_type: "component",
    state: "default-populated",
    rubric_dimension: "color-theme",
    target_selector: ".ax-dev-state-grid-col[data-theme]",
    expected: "lightBase !== darkBase (columns resolve genuinely different --ax-base values)",
    actual: JSON.stringify({ lightBase, darkBase }),
    assertions: ["resolved-color-delta"],
    coverage_status: lightBase && darkBase && lightBase !== darkBase ? "covered" : "gap",
    failure_kind: lightBase === darkBase ? "theme-column-inert" : null,
    overlay_tags: [],
  });
}
```

**Cell-id grammar** (frozen, from baseline-manifest.js — follow this exactly):
```
p187__{surface}__{mode}__{theme}__{state}__{dXX}

Phase 189 component-kitchen cells:
- surface:  "component-kitchen" (route-level) OR per-family like "button", "input"
- mode:     "chromium-desktop" or "chromium-mobile"
- theme:    "light" or "dark"
- state:    Phase-187 taxonomy: "default-populated", "disabled-readonly", "overflow",
            "long-content", "error", "loading", "interactive-open"
            (NOT the Phase-189 matrix vocabulary — map: disabled→disabled-readonly,
             hover/focus/active→interactive-open, overflow→overflow)
- dXX:      d01–d12 for the 12 rubric dimensions
```

---

### `verify_package_docs.sh` — CMP-05 Guard

**Analog:** itself — Phase-188 FND-01 (raw-type guard, lines 375–389) and FND-02 (z-index guard, lines 362–373)

**FND-02 z-index guard pattern** (lines 362–373 — copy `perl -0ne` + `[[ -z ... ]] || fail` idiom):
```bash
z_index_hit=$(
  perl -0ne '
    s{/\*.*?\*/}{}gs;
    while (/z-index\s*:\s*(-?[0-9]+)/gi) {
      my $value = $1;
      next if $value eq "-1" || $value eq "0" || $value eq "1";
      print "$value\n";
      last;
    }
  ' "$app_css"
)
[[ -z "$z_index_hit" ]] || fail "$app_css must not contain z-index literals outside micro-stacking exceptions (FND-02 z-index literals)"
```

**FND-01 raw-type guard pattern** (lines 375–389 — copy `awk` + allowlist comment idiom):
```bash
raw_type_hit=$(
  awk '
    /ax-type-exception:/ { in_type_exception = 1; next }
    /(font-size|font-weight|line-height|letter-spacing|font-family)[[:space:]]*:/ {
      if (!in_font_face && !in_type_exception && ...) { print FNR ":" $0; exit }
    }
    in_type_exception && /\}/ { in_type_exception = 0 }
  ' "$app_css"
)
[[ -z "$raw_type_hit" ]] || fail "..."
```

**Phase 189 CMP-05 guard** (add at end of file, after motion guards ~line 471, before final `echo`):
```bash
# Phase 189 CMP-05: no per-page CSS overrides of primitive ax-* classes.
# Only app.css and theme.css may define primitive selectors.
primitive_override_hit=$(
  find "$ROOT_DIR/accrue_admin/assets/css" -name "*.css" \
    ! -name "app.css" ! -name "theme.css" -print0 |
    xargs -0 grep -E '\.ax-(button|field|input|select|status-badge|icon|money|json|empty)[^{]*\{' 2>/dev/null |
    head -n 1
)
[[ -z "$primitive_override_hit" ]] || fail "per-page CSS overrides of primitive ax-* classes are not allowed (CMP-05): $primitive_override_hit"

# Phase 189 CMP-05: no raw inline style= on primitive component wrappers.
inline_style_hit=$(
  find "$ROOT_DIR/accrue_admin/lib" -type f \( -name '*.ex' -o -name '*.heex' \) -print0 |
    xargs -0 perl -0ne '
      while (/~H"""(.*?)"""/sg) {
        my $tmpl = $1;
        while ($tmpl =~ /<[a-z][^>]*class="[^"]*\b(ax-button|ax-field|ax-input|ax-select|ax-status-badge|ax-money|ax-json)\b[^"]*"[^>]*style=/g) {
          print "$ARGV: $1\n";
          last;
        }
      }
    ' 2>/dev/null |
    head -n 1
)
[[ -z "$inline_style_hit" ]] || fail "raw inline style= on primitive ax-* elements is not allowed (CMP-05): $inline_style_hit"
```

---

### `package_docs_verifier_test.exs` — CMP-05 Negative Fixture

**Analog:** itself — any of the `seed_tmp_dir!` + injection + `run_verifier` + assert pattern tests (e.g., z-index test lines 457–469, font-literal test lines 471–483)

**z-index negative fixture** (lines 457–469 — the cleanest analog; copy exactly):
```elixir
test "package docs verifier rejects z-index literals in package CSS" do
  tmp_dir = tmp_dir!()
  seed_tmp_dir!(tmp_dir)

  app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
  File.write!(app_css_path, File.read!(app_css_path) <> "\n.ax-drift { z-index: 999; }\n")

  {output, status} = run_verifier(tmp_dir)

  assert status != 0
  assert output =~ "[verify_package_docs]"
  assert output =~ "z-index literals"
end
```

**Phase 189 CMP-05 negative fixture** (add two new tests following the same pattern):
```elixir
test "package docs verifier rejects per-page CSS overrides of primitive ax-* classes (CMP-05)" do
  tmp_dir = tmp_dir!()
  seed_tmp_dir!(tmp_dir)

  # Inject a violating page-specific CSS file (NOT app.css / theme.css)
  page_css_dir = Path.join(tmp_dir, "accrue_admin/assets/css")
  File.mkdir_p!(page_css_dir)
  File.write!(
    Path.join(page_css_dir, "page-overrides.css"),
    ".ax-button { font-size: 1rem; }\n"
  )

  {output, status} = run_verifier(tmp_dir)

  assert status != 0
  assert output =~ "[verify_package_docs]"
  assert output =~ "CMP-05"
end

test "package docs verifier rejects raw inline style= on primitive ax-* elements (CMP-05)" do
  tmp_dir = tmp_dir!()
  seed_tmp_dir!(tmp_dir)

  kitchen_path = Path.join(tmp_dir, "accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex")
  original = File.read!(kitchen_path)

  # Inject a style= attribute on an element that also carries ax-button
  drifted =
    String.replace(
      original,
      ~s(<Button.button variant="primary" type="button">Primary action</Button.button>),
      ~s(<button class="ax-button ax-button-primary" style="color: red;" type="button">Primary action</button>),
      global: false
    )

  File.write!(kitchen_path, drifted)

  {output, status} = run_verifier(tmp_dir)

  assert status != 0
  assert output =~ "[verify_package_docs]"
  assert output =~ "CMP-05"
end
```

**`seed_tmp_dir!` must include any files the CMP-05 guard scans** (lines 623–670). The guard scans `accrue_admin/assets/css/` and `accrue_admin/lib/`. Both are already seeded. No new `copy_fixture!` calls required for the CSS guard. The inline-style guard scans `accrue_admin/lib/` — `component_kitchen_live.ex` is already seeded at line 657.

---

## Per-Family Primitive Component Patterns

### `button.ex` — Root Fixes

**Current source** (lines 1–41):
```elixir
defmodule AccrueAdmin.Components.Button do
  use Phoenix.Component

  attr(:variant, :string, default: "primary")
  attr(:type, :string, default: "button")
  attr(:href, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:class, :string, default: nil)
  attr(:rest, :global,
    include: ~w(method name value form phx-click phx-submit phx-value-id aria-label))
  slot(:inner_block, required: true)

  def button(assigns) do
    classes = ["ax-button", button_variant_class(assigns.variant), assigns.class]
    assigns = assign(assigns, :classes, classes)
    ~H"""
    <a :if={@href && !@disabled} href={@href} class={@classes} {@rest}>...</a>
    <a :if={@href && @disabled} class={@classes} aria-disabled="true" tabindex="-1" {@rest}>...</a>
    <button :if={!@href} type={@type} class={@classes} disabled={@disabled} {@rest}>...</button>
    """
  end
  defp button_variant_class("secondary"), do: "ax-button-secondary"
  defp button_variant_class("ghost"),     do: "ax-button-ghost"
  defp button_variant_class("danger"),    do: "ax-button-danger"
  defp button_variant_class(_variant),    do: "ax-button-primary"
end
```

**Phase 189 must add** to HEEx: `aria-busy={@loading}` on the `<button>` when a `loading` attr is added; `loading: false` attr declaration. No public API changes — keep existing attrs, add `loading`.

### `input.ex` — Root Fixes

**Current source** (lines 1–60 — key defect at line 41):
```elixir
<p :for={error <- @errors} id={@id <> "-error"} class="ax-field-error"><%= error %></p>
# DEFECT: multiple errors → multiple elements with same id. Fix:
# Option A: <p :for={{error, i} <- Enum.with_index(@errors)} id={@id <> "-error-#{i}"} ...>
# Option B: wrap all errors in <div id={@id <> "-errors"}> + update described_by/3
```

**`described_by/3` helper** (lines 46–55 — the accumulation pattern to keep, just update the ID referenced):
```elixir
defp described_by(id, help_text, errors) do
  []
  |> maybe_add(help_text && id <> "-help")
  |> maybe_add(errors != [] && id <> "-error")  # update to id <> "-errors" if using wrapper div
  |> Enum.join(" ")
  |> case do
    "" -> nil
    value -> value
  end
end
```

### `select.ex` — Root Fixes

Same `described_by/3` defect as `input.ex` (lines 56–65). Same fix applies. CSS fix: `outline: none` on `.ax-select-control:focus-visible` (found at line 1688–1692 in app.css) removed by the Phase-188 consolidated focus block.

### `status_badge.ex` — Root Fixes

**Current source** (lines 1–51 — component itself is correct; CSS is defective):
```elixir
~H"""
<span class={["ax-status-badge", "ax-status-badge-" <> @tone]}>
  <span class="ax-status-dot" aria-hidden="true"></span>
  <span><%= @label_text %></span>
</span>
"""
```

No HEEx changes needed. CSS fix only: migrate `.ax-status-badge-{tone}` rules from `color-mix()` formulas to `--ax-status-{role}-bg/text/border` tokens.

### `icon.ex` — Registry Entry Only

**Current source** (lines 39–58 — already correct):
```elixir
def icon(assigns) do
  ~H"""
  <svg
    class={["ax-icon", "ax-icon-#{@size}", @class]}
    aria-hidden={if @label, do: "false", else: "true"}
    role={if @label, do: "img"}
    aria-label={@label}
    {@rest}
  >
    <title :if={@label}><%= @label %></title>
    <%= Phoenix.HTML.raw(paths(@name)) %>
  </svg>
  """
end
```

No HEEx changes. Add to registry with `applicable_states: ["default"]`, all others in `na_states` with reason "non-interactive display primitive".

### `money_formatter.ex` — Registry Entry + Audit

**Current source** (lines 19–26 — class pass-through is the audit surface):
```elixir
~H"""
<span class={["ax-money", @class]} data-locale={resolved_locale(@locale, @customer)}>
  <%= @formatted_money %>
</span>
"""
```

The `@class` pass-through means consuming pages CAN inject overriding classes onto `ax-money`. Phase 189 must scan consuming templates to confirm no pages currently override `ax-money` — if they do, the CMP-05 guard would catch it. No component change needed unless overrides are found.

### `json_viewer.ex` — Registry Entry

**Current source** (line 25 — outer class combines ax-card with ax-json-viewer):
```elixir
<section id={@id} class="ax-card ax-json-viewer" aria-label={@label}>
```

For lab specimens, the matrix renderer should instantiate `JsonViewer` with `class="ax-json-viewer"` only (omit `ax-card` to avoid card padding doubling inside a `ax-dev-state-cell`). This is done in the registry `specimens` field, not in the component itself.

---

## Newly-Created Component Families (No Analog in Codebase)

These primitives have NO existing `*.ex` component module. Pattern mapping defaults to the closest role-match analog.

| Primitive | Role-Match Analog | Decision Required |
|-----------|-------------------|-------------------|
| `textarea.ex` | `input.ex` (same form-field pattern, `ax-field` wrapper + `ax-field-control`) | Create as thin wrapper; type="textarea" → `<textarea>` element |
| `checkbox.ex` | `input.ex` (same `ax-field` + described_by pattern); CSS class `.ax-checkbox` already exists | Create module; use `.ax-checkbox` CSS class already in app.css |
| `radio.ex` | `input.ex` / `checkbox.ex` pattern | Create module; add `.ax-radio` CSS class |
| `toggle.ex` | `button.ex` (aria-pressed pattern) + `checkbox.ex` (checked state) | Create module with `role="switch"` + `aria-checked` |
| `spinner.ex` | `icon.ex` (display primitive, no interaction) | CSS-only or thin component wrapping `.ax-spinner` class (already in app.css line 2131) |
| `skeleton.ex` | `icon.ex` (CSS-only display) | CSS class `.ax-skeleton` already in app.css lines 2847–2872; accept inline CSS class |
| `tooltip.ex` | `dropdown_menu.ex` (popover layer pattern) | Create; must use `--ax-z-popover` layer (300) |
| `empty_state.ex` | `status_badge.ex` (display-only, no hover/cursor) | Extract inline pattern from kitchen ~lines 157–161 |
| `inline_id.ex` | `money_formatter.ex` (display span with CSS class) | Thin component; use `.ax-type-code` or new `.ax-inline-id` class |

**Role-match pattern from `input.ex`** (lines 1–60 — use for textarea, checkbox, radio):
```elixir
defmodule AccrueAdmin.Components.Textarea do
  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:label, :string, required: true)
  attr(:value, :string, default: nil)
  attr(:rows, :integer, default: 4)
  attr(:help_text, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:rest, :global, include: ~w(disabled placeholder readonly phx-debounce phx-hook required))

  def textarea(assigns) do
    assigns = assign(assigns, :has_errors, assigns.errors != [])
    ~H"""
    <div class="ax-field">
      <label for={@id} class="ax-field-label"><%= @label %></label>
      <textarea
        id={@id}
        name={@name}
        rows={@rows}
        class={["ax-field-control", @has_errors && "ax-field-control-error"]}
        aria-invalid={if(@has_errors, do: "true", else: "false")}
        aria-describedby={...}
        {@rest}
      ><%= @value %></textarea>
      <p :if={@help_text} id={@id <> "-help"} class="ax-field-help"><%= @help_text %></p>
      <%!-- use Enum.with_index to avoid duplicate IDs --%>
      <p :for={{error, i} <- Enum.with_index(@errors)} id={@id <> "-error-#{i}"} class="ax-field-error"><%= error %></p>
    </div>
    """
  end
end
```

---

## Shared Patterns

### Mix.env() Guard (all dev-only modules)
**Source:** `component_registry.ex` lines 1–2; `component_kitchen_live.ex` lines 1–2
**Apply to:** All new component lab modules (`ComponentRegistry`, `ComponentKitchenLive`, and any dev-only helpers)
```elixir
if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.SomeModule do
    @moduledoc false
    # ...
  end
end
```

### Phoenix.Component `use` pattern
**Source:** `button.ex` line 6; `input.ex` line 6; `status_badge.ex` line 6
**Apply to:** All new `*.ex` component modules (textarea, checkbox, radio, toggle, spinner, tooltip, empty_state, inline_id)
```elixir
use Phoenix.Component
```

### `attr(:rest, :global, include: ...)` pattern
**Source:** `button.ex` lines 14–16; `input.ex` lines 17–20
**Apply to:** All interactive component modules — include relevant HTML/phx attrs
```elixir
attr(:rest, :global,
  include: ~w(disabled phx-click phx-hook aria-label))
```

### `@moduledoc false` for dev modules
**Source:** `component_registry.ex` line 3; `component_kitchen_live.ex` line 3
**Apply to:** All `AccrueAdmin.Dev.*` modules
```elixir
@moduledoc false
```

### Focus-ring contract (Phase-188 token consumption)
**Source:** `app.css` lines 2898–2917
**Apply to:** ALL interactive primitive CSS selectors in Phase 189 root fixes; DO NOT add per-selector `outline: none` rules
```css
/* The ONLY focus-ring setter — the consolidated block at ~line 2898.
   Add new selectors TO this block; never add standalone :focus-visible rules
   that set outline: none without the full ring contract. */
outline: 2px solid var(--ax-focus-ring);
outline-offset: 2px;
box-shadow: var(--ax-focus-shadow);
```

### Disabled state token consumption
**Source:** `app.css` lines 2919–2929
**Apply to:** All form control disabled CSS rules in Phase 189 root fixes
```css
.ax-button[aria-disabled="true"],
.ax-button:disabled,
.ax-disabled,
[aria-disabled="true"] {
  color: var(--ax-disabled-text);
  background: var(--ax-disabled-bg);
  border-color: var(--ax-disabled-border);
  opacity: var(--ax-disabled-opacity);
  cursor: var(--ax-disabled-cursor);
  pointer-events: none;
}
```

### Readonly state token consumption
**Source:** `app.css` lines 2934–2951
**Apply to:** All form control readonly CSS rules in Phase 189
```css
.ax-input[readonly],
.ax-select[readonly],
.ax-field-control[readonly] {
  color: var(--ax-readonly-text);
  background: var(--ax-readonly-bg);
  border-color: transparent;
  cursor: default;
  user-select: text;
}
```

### `AccrueAdmin.LiveCase` usage in registry tests
**Source:** `component_registry_test.exs` lines 7–10
**Apply to:** New tests (e) and (f); both need the LiveView mount for HTML assertions
```elixir
use AccrueAdmin.LiveCase, async: false
use Phoenix.Component
```

### `observe()` row shape (NDJSON ledger)
**Source:** `admin-interactions.spec.js` lines 65–92 (all OBSERVATION_FIELDS)
**Apply to:** All new component-kitchen probe `observe()` calls — every field must be present
```js
const OBSERVATION_FIELDS = [
  "probe_id", "interaction_class", "cell_id", "surface", "surface_type",
  "state", "rubric_dimension", "overlay_tags", "coverage_status",
  "target_selector", "expected", "actual", "assertions",
  "evidence_refs", "failure_kind", "notes"
];
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| New `*.ex` for toggle/tooltip/spinner | component | request-response | No existing toggle, tooltip, or dedicated spinner component module in `accrue_admin/lib/accrue_admin/components/`; closest role-match is `button.ex` + `input.ex` |
| `.ax-dev-state-grid` CSS block | config/CSS | transform | No existing state-grid layout CSS; closest analog is `.ax-dev-grid` (flex, not grid) — new block must be authored from scratch following the `--ax-border`/`--ax-base`/`--ax-space-*` token conventions |

---

## Metadata

**Analog search scope:** `accrue_admin/lib/`, `accrue_admin/assets/css/`, `accrue_admin/e2e/`, `accrue_admin/test/`, `accrue/test/accrue/docs/`, `scripts/ci/`
**Files scanned:** 13 primary edit surfaces read in full
**Pattern extraction date:** 2026-06-17
