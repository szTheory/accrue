# Phase 177: D — Motion & Micro-interaction Design - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 14 (9 motion surfaces + guard script + test fixture + e2e spec + motion.md guide + mix.exs extras)
**Analogs found:** 14 / 14

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` | component | event-driven (mount/remove) | `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/flash_group.ex` | component | event-driven (server push) | `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | component | event-driven (is_open toggle) | `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` + `step_up_auth_modal.ex` | role-match |
| `accrue_admin/assets/css/app.css` (detail_drawer CSS) | CSS | event-driven | `accrue_admin/assets/css/app.css:1218` (chevron rotate) | exact |
| `accrue_admin/assets/css/app.css` (dropdown CSS) | CSS | event-driven | `accrue_admin/assets/css/app.css:1218` (chevron rotate + bundle) | exact |
| `accrue_admin/assets/css/app.css` (global_search CSS) | CSS | event-driven | `accrue_admin/assets/css/app.css:1218` (data-state pattern) | exact |
| `accrue_admin/assets/css/app.css` (tabs CSS) | CSS | event-driven | `accrue_admin/assets/css/app.css:1000` (`.ax-button` transition: bundle) | exact |
| `accrue_admin/assets/css/app.css` (flash CSS) | CSS | event-driven | `accrue_admin/assets/css/app.css:1218` (transition class tuples) | role-match |
| `accrue_admin/assets/css/app.css` (badge CSS) | CSS | event-driven | `accrue_admin/assets/css/app.css:1000` + `1210` | exact |
| `accrue_admin/assets/js/hooks/sidebar_collapse.js` | hook | event-driven | self (transitionend two-step pattern) | self |
| `accrue_admin/e2e/reduced-motion.spec.js` | test (E2E) | request-response | self (D-15 two-test block + `buttonTransitionDurations` helper) | exact |
| `scripts/ci/verify_package_docs.sh` | config/CI guard | batch | self (lines 322–328 breakpoint guard) | exact |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | test (unit) | batch | self (line 241 negative test + `seed_tmp_dir!/1` at line 302) | exact |
| `accrue_admin/guides/motion.md` | documentation | — | `accrue_admin/guides/theme-exceptions.md` (guide extras pattern in mix.exs) | role-match |

---

## Pattern Assignments

### `detail_drawer.ex` + `flash_group.ex` — JS.transition for mount/remove (phx-mounted / phx-remove)

**Analog:** `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` (lines 21–28)

**Core pattern** — `phx-mounted` / `phx-remove` attrs on the `:if`-gated element:

```elixir
# step_up_auth_modal.ex lines 21-28 — the exact shape to replicate
<section
  :if={@pending}
  id="accrue-admin-step-up-dialog"
  class="ax-card ax-step-up-modal"
  role="dialog"
  aria-labelledby="step-up-title"
  phx-mounted={Phoenix.LiveView.JS.push_focus() |> Phoenix.LiveView.JS.focus_first(to: "#accrue-admin-step-up-dialog")}
  phx-remove={Phoenix.LiveView.JS.pop_focus()}
>
```

**What to replicate for `detail_drawer.ex`** — keep `:if={@open}`, add `phx-mounted` and `phx-remove` with `JS.show/hide` + transition class tuples on the `<section>` (lines 22–24). The transition class names resolve to CSS rules in `app.css` (see CSS pattern below). Never pass raw integer durations without a comment citing the token — `time: 240` must note `# --ax-dur-3`.

**What to replicate for `flash_group.ex`** — move `phx-mounted` / `phx-remove` attrs onto each `:for` `<article>` (line 13–16). The `<section>` wrapper `:if={@flashes != []}` can stay; the per-article transitions handle individual mount/remove. Pattern:

```elixir
# flash_group.ex lines 12-16 — current state (no transitions)
<section :if={@flashes != []} class="ax-flash-group" aria-label="Notifications">
  <article
    :for={flash <- @flashes}
    class={["ax-flash", flash_class(flash[:kind])]}
    role="status"
  >
```

Add `phx-mounted` / `phx-remove` on `<article>`, mirroring the step_up_auth_modal `phx-mounted`/`phx-remove` placement, but with `JS.show` / `JS.hide` + transition tuples instead of focus management.

**JS.show/hide API shape** (LiveView 1.1 — three-tuple transition):

```elixir
# Enter (used in phx-mounted):
JS.show(
  transition: {"ax-flash-entering", "ax-flash-enter-from", "ax-flash-enter-to"},
  time: 180  # --ax-dur-2
)

# Exit (used in phx-remove):
JS.hide(
  transition: {"ax-flash-leaving", "ax-flash-leave-from", "ax-flash-leave-to"},
  time: 140  # --ax-dur-exit
)
```

The three-tuple is `{active_class, from_class, to_class}`. LiveView applies: `from_class` → adds `active_class` → removes `from_class`, adds `to_class` (with rAF for the browser to see the from state), waits `time:` ms, then removes all three classes. `time:` MUST equal the CSS `transition-duration` in ms.

---

### `global_search.ex` — switch from class-swap to `data-open` attr toggle

**Analog:** `accrue_admin/lib/accrue_admin/components/global_search.ex` lines 112–127 (current state)

**Current state** (line 112):

```elixir
# global_search.ex line 112 — current: class-swap to "hidden" string
<div id={@id} class={if @is_open, do: "ax-command-palette-wrapper", else: "hidden"}>
```

**What to change:** replace the `class` swap with a `data-open` attribute so CSS transitions can fire. The `hidden` class applies `display: none` immediately, which kills transitions.

```elixir
# Replace line 112 with:
<div id={@id} class="ax-command-palette-wrapper" data-open={to_string(@is_open)}>
```

**CommandPalette hook coupling** — `command_palette.js` lines 19 and 39 check `classList.contains("hidden")` to determine visibility. After the attr change, update both checks to:

```javascript
// command_palette.js line 19 — current:
if (!this.el.parentElement.classList.contains("hidden")) {

// Replace with:
if (this.el.parentElement.dataset.open === "true") {
```

```javascript
// command_palette.js line 39 — current:
if (e.key === "Escape" && !this.el.parentElement.classList.contains("hidden")) {

// Replace with:
if (e.key === "Escape" && this.el.parentElement.dataset.open === "true") {
```

---

### `app.css` — CSS transition on `--ax-transition-*` bundle (the canonical pattern)

**Analog 1 — `--ax-transition-transform` bundle on a toggle:** `app.css:1218–1227` (chevron rotate)

```css
/* app.css lines 1218-1227 — CANONICAL: bundle wired to aria-expanded toggle */
.ax-sidebar-group-chevron {
  color: var(--ax-muted);
  flex: none;
  transition: var(--ax-transition-transform);  /* Phase 174 bundle — reduced-motion free */
}

[aria-expanded="true"] > .ax-sidebar-group-toggle .ax-sidebar-group-chevron,
.ax-sidebar-group-toggle[aria-expanded="true"] .ax-sidebar-group-chevron {
  transform: rotate(90deg);
}
```

**Pattern to replicate for dropdown, tabs, badge:** add `transition: var(--ax-transition-*)` to the base class; add the "active" state selector for the changed value. Never write `transition: color 180ms cubic-bezier(...)` — always use the bundle variable.

**Analog 2 — multi-property bundle on a control:** `app.css:997–1001` (`.ax-button`)

```css
/* app.css lines 997-1001 — multi-property bundle on a control */
.ax-button {
  min-height: 2.75rem;
  padding: 0.625rem 1rem;
  transition: var(--ax-transition-base);  /* 5-property bundle */
}
```

**Pattern to replicate for tabs:** add `transition: var(--ax-transition-colors)` to `.ax-tab` for the color/border crossfade. The selector for the active state is `.ax-tab-active` (already assigned server-side by `tabs.ex:17`).

**Analog 3 — registered exception (two-token asymmetric):** `app.css:1562–1569` — the ONLY sanctioned literal-token mix. For reference to understand what is allowlisted:

```css
/* app.css lines 1562-1569 — REGISTERED EXCEPTION (do not replicate; understand the shape) */
/* Intentional exception: two-token asymmetric transition — not collapsible to a single bundle.
   Color/border/background use --ax-theme-transition (180ms); transform uses --ax-motion-fast (120ms).
   Collapsing would lose the enter/exit speed difference. See Phase 174 Gap 3 resolution. */
transition:
  border-color var(--ax-theme-transition),
  background var(--ax-theme-transition),
  color var(--ax-theme-transition),
  transform var(--ax-motion-fast);
```

Phase 177 must NOT write new rules in this shape — use the standard bundles. This entry is the negative template: it shows what the guard would ban if the `--ax-motion-fast` / `--ax-theme-transition` back-compat aliases weren't in the allowlist.

---

### `app.css` — CSS transition class tuples for JS.show/hide (flash + drawer)

**Pattern** — three CSS class blocks per transition direction, following the LiveView JS.transition three-tuple convention:

```css
/* Enter classes (transition: {"active", "from", "to"}) */
.ax-flash-enter-from {
  opacity: 0;
  transform: translateY(calc(-1 * var(--ax-rise-sm)));  /* --ax-rise-sm collapses to 0px under reduced-motion */
}
.ax-flash-entering {
  transition:
    opacity var(--ax-dur-2) var(--ax-ease-out),      /* 180ms enter */
    transform var(--ax-dur-2) var(--ax-ease-out);
}
.ax-flash-enter-to {
  opacity: 1;
  transform: translateY(0px);
}

/* Exit classes */
.ax-flash-leave-from { opacity: 1; }
.ax-flash-leaving {
  transition: opacity var(--ax-dur-exit) var(--ax-ease-in);  /* 140ms exit — fade only */
}
.ax-flash-leave-to { opacity: 0; }
```

Replicate this six-class structure for each JS.transition surface (detail_drawer). Name the classes to match the component: `ax-drawer-entering` / `ax-drawer-enter-from` / etc. The `--ax-rise-md` token (8px) is used for the drawer (larger travel); `--ax-rise-sm` (4px) for flash/toast.

---

### `app.css` — dropdown CSS transition on `details[open]`

**Analog:** `app.css:1218–1227` (chevron `[aria-expanded]` toggle — same `[attr]` keying pattern)

**Key constraint** (from RESEARCH.md pattern 1): native `<details>` removes `[open]` synchronously on close — the exit transition does NOT fire. For Phase 177, accept symmetric 180ms (both enter and exit use the same `transition:` rule, so the browser animates the enter; the close is instant). If exit asymmetry is desired later, a small JS hook must intercept `toggle`.

```css
/* Pattern for dropdown — add to app.css after existing .ax-dropdown-panel rule */
details.ax-dropdown .ax-dropdown-panel {
  opacity: 0;
  transform: translateY(calc(-1 * var(--ax-rise-sm)));
  pointer-events: none;
  transition:
    opacity var(--ax-dur-2) var(--ax-ease-out),
    transform var(--ax-dur-2) var(--ax-ease-out);
}

details[open].ax-dropdown .ax-dropdown-panel {
  opacity: 1;
  transform: translateY(0px);
  pointer-events: auto;
}
```

The `transform` here uses `--ax-rise-sm` directly (not the bundle) because the dropdown needs both `opacity` and `transform` in a single declaration — `--ax-transition-transform` bundle only covers `transform`. Using `var(--ax-dur-2) var(--ax-ease-out)` on each property satisfies the "no raw literals" rule since these are token references.

---

### `sidebar_collapse.js` — transitionend two-step for link list reveal

**Analog:** `accrue_admin/assets/js/hooks/sidebar_collapse.js` lines 41–47 (current `setExpanded`)

**Current state** (lines 41–47):

```javascript
setExpanded(expanded) {
  this.el.setAttribute("aria-expanded", String(expanded));
  const list = document.getElementById(this.el.dataset.controls);
  if (list) {
    list.hidden = !expanded;  // PROBLEM: display:none kills CSS transitions
  }
},
```

**Key pitfall** (RESEARCH.md pattern 2): `list.hidden = true` sets `display: none` immediately — CSS opacity transitions cannot run.

**What to replicate:** the `transitionend` two-step. For the collapse direction: (a) remove `hidden`, add `ax-collapsing` CSS class to trigger the exit opacity transition, (b) on `transitionend`, set `list.hidden = true` and remove the class. For expand: clear `hidden` first, then let CSS handle the opacity-in.

```javascript
// Replace setExpanded with the two-step pattern:
setExpanded(expanded) {
  this.el.setAttribute("aria-expanded", String(expanded));
  const list = document.getElementById(this.el.dataset.controls);
  if (!list) return;

  if (expanded) {
    // Expand: reveal first, then CSS transition runs opacity 0→1
    list.hidden = false;
    list.classList.remove("ax-collapsed");
  } else {
    // Collapse: trigger exit transition first, set hidden on transitionend
    list.classList.add("ax-collapsed");
    list.addEventListener(
      "transitionend",
      () => {
        list.hidden = true;
        list.classList.remove("ax-collapsed");
      },
      { once: true }
    );
  }
},
```

The `ax-collapsed` CSS class holds `opacity: 0; pointer-events: none;` with a transition. The `hidden` attr is only set AFTER the exit animation completes so AT still skips the content when closed (structural correctness retained).

---

### `e2e/reduced-motion.spec.js` — extend D-15 two-test block for new surfaces

**Analog:** `accrue_admin/e2e/reduced-motion.spec.js` lines 1–64 (entire file — the D-15 two-test block)

**`buttonTransitionDurations` helper** (lines 11–21) — extract the exact shape to create per-surface helpers:

```javascript
// reduced-motion.spec.js lines 11-21 — THE HELPER TEMPLATE
async function buttonTransitionDurations(page) {
  await expect(page.locator(".ax-button").first()).toBeVisible();
  return page.evaluate(() => {
    const el = document.querySelector(".ax-button");
    if (!el) return null;
    return window
      .getComputedStyle(el)
      .transitionDuration.split(",")
      .map((seg) => seg.trim());
  });
}
```

**`test.describe` block structure** (lines 23–64) — the two-test "with reduced / without reduced" pattern:

```javascript
// reduced-motion.spec.js lines 23-44 — TEST 1: with reduced-motion → all 0s
test("with prefers-reduced-motion:reduce, .ax-button transition-duration collapses to 0s on every segment", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();
  const durations = await buttonTransitionDurations(page);
  // assert every segment === "0s"
  for (const seg of durations) {
    expect(seg).toBe("0s");
  }
});

// reduced-motion.spec.js lines 47-63 — TEST 2: without reduced-motion → at least one non-zero
test("WITHOUT reduced-motion the same .ax-button has a NON-zero transition-duration", async ({ page }) => {
  // No emulateMedia
  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();
  const durations = await buttonTransitionDurations(page);
  const hasNonZero = durations.some((seg) => seg !== "0s");
  expect(hasNonZero).toBe(true);
});
```

**What to add** — for each new surface (`.ax-dropdown-panel`, `.ax-command-palette`, `.ax-detail-drawer`), create a new `test.describe` block replicating this exact structure. Rename `buttonTransitionDurations` to e.g. `dropdownTransitionDurations`, `palettePanelTransitionDurations`, etc. — same implementation, different selector. Add a structural check test: `emulateMedia({ reducedMotion: "reduce" })`, trigger the open action, assert `getComputedStyle(el).transform === "none"` (no translate travel) or `transitionDuration` is `"0s"`.

---

### `scripts/ci/verify_package_docs.sh` — add motion guard needles

**Analog:** `scripts/ci/verify_package_docs.sh` lines 322–328 (the Phase 174 breakpoint guard)

**Exact shape to extend** (lines 322–328):

```bash
# Token bypass guards (Phase 174, DSY-01)
app_css="$ROOT_DIR/accrue_admin/assets/css/app.css"
if grep -E '@media \((min|max)-width: [0-9.]+px\)' "$app_css" | grep -qv '\-\-ax-bp-'; then
  fail "$app_css must not have bare breakpoint @media without an --ax-bp-* annotation comment (DSY-01 — add a /* --ax-bp-NAME ↑/↓ */ comment to every breakpoint @media)"
fi
```

**Four new motion guard blocks to add immediately after line 328**, replicating the `if grep ... | grep -qv ... ; then fail "..." ; fi` shape:

```bash
# Motion antipattern guards (Phase 177, MOT-01)
if grep -qE 'transition:\s*all\b' "$app_css"; then
  fail "$app_css must not use 'transition: all' (MOT-01/A1) — name exact properties or use --ax-transition-* bundles"
fi

if grep -qE 'cubic-bezier\(' "$app_css"; then
  fail "$app_css must not contain raw cubic-bezier() literals (MOT-01/A3) — use --ax-ease-* atoms from theme.css"
fi

if grep -E '(transition|animation):[^;]*[0-9]+(ms|s)\b' "$app_css" | grep -qv 'ax-skeleton-shimmer'; then
  fail "$app_css must not have raw ms/s duration literals in transition/animation rules (MOT-01/A3) — use --ax-dur-* tokens; exception: ax-skeleton-shimmer 1.4s is allowlisted"
fi

if grep -qE 'transition:[^;]*\b(height|width|margin|padding|top|left|right|bottom)\b' "$app_css"; then
  fail "$app_css must not animate layout-triggering properties in transition lists (MOT-01/A2) — use opacity/transform only"
fi
```

Also add a guide file existence needle for `motion.md` — replicate the pattern used at line 306 for guide checks:

```bash
# Motion guide existence (Phase 177, MOT-01)
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/motion.md"'
```

---

### `accrue/test/accrue/docs/package_docs_verifier_test.exs` — add negative tests + update seed

**Analog:** `package_docs_verifier_test.exs` lines 241–268 (the breakpoint guard negative test)

**Exact shape to replicate** (lines 241–268):

```elixir
test "package docs verifier rejects unguarded breakpoint @media in app.css" do
  tmp_dir =
    Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

  File.rm_rf!(tmp_dir)
  on_exit(fn -> File.rm_rf(tmp_dir) end)
  seed_tmp_dir!(tmp_dir)

  app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
  original = File.read!(app_css_path)

  drifted =
    original <>
      "\n@media (min-width: 900px) { .ax-drift { display: block; } }\n"

  File.write!(app_css_path, drifted)

  {output, status} =
    System.cmd("bash", [@script_path],
      stderr_to_stdout: true,
      env: [{"ROOT_DIR", tmp_dir}]
    )

  assert status != 0
  assert output =~ "[verify_package_docs]"
  assert output =~ "app.css"
  assert output =~ "--ax-bp-"
end
```

**Add four new test blocks** (one per guard needle), each using the same `seed_tmp_dir!` + `app_css_path` + `File.write!` + `System.cmd` + assertions structure. Inject violations:

- `transition: all` needle → append `\n.ax-drift { transition: all 180ms; }\n`
- `cubic-bezier(` needle → append `\n.ax-drift { transition: opacity cubic-bezier(0.4,0,1,1); }\n`
- Raw ms literal → append `\n.ax-drift { transition: opacity 200ms ease; }\n`
- Layout-thrash → append `\n.ax-drift { transition: height 180ms ease; }\n`

**`seed_tmp_dir!/1`** (lines 302–339) already copies `accrue_admin/assets/css/app.css` at line 331 and `accrue_admin/mix.exs` at line 329. No new `copy_fixture!` calls are needed for the motion guard tests. However, if `"guides/motion.md"` is added as a needle in `verify_package_docs.sh`, add:

```elixir
# In seed_tmp_dir!/1, after line 329 (accrue_admin/mix.exs copy):
copy_fixture!("accrue_admin/guides/motion.md", tmp_dir)
```

without that, the six negative tests that call `seed_tmp_dir!` will fail because the script will try to find the file and fail before reaching the motion guard checks.

---

### `accrue_admin/guides/motion.md` + `accrue_admin/mix.exs` extras

**Analog:** existing guides listed in `accrue_admin/mix.exs` lines 65–75:

```elixir
# mix.exs lines 65-75 — current extras + groups_for_extras
extras: [
  "README.md",
  "guides/admin_ui.md",
  "guides/core-admin-parity.md",
  "guides/theme-exceptions.md"
],
groups_for_extras: [
  Guides: [
    "guides/admin_ui.md",
    "guides/core-admin-parity.md",
    "guides/theme-exceptions.md"
  ]
]
```

**What to add** — add `"guides/motion.md"` to both `extras:` and `groups_for_extras:` (inside the `Guides:` list, or a new `"Motion":` group). The verify_package_docs guard needle `'"guides/motion.md"'` will check that this line exists in `accrue_admin/mix.exs`.

Also add `"guides/motion.md"` to `skip_undefined_reference_warnings_on:` (line 91) to match the pattern for the other guides.

---

## Shared Patterns

### Pattern A: Token Bundle Rule (apply to ALL nine surfaces)

**Source:** `accrue_admin/assets/css/theme.css` lines 82–98 (bundle definitions) + `app.css:997–1001` (consumption example)

All new `transition:` declarations MUST reference a `--ax-transition-*` variable or individual `--ax-dur-*`/`--ax-ease-*` atoms. Never write `180ms` or `cubic-bezier(...)` inline in `app.css`. Every bundle automatically gets reduced-motion correctness from `theme.css:187–211`.

```css
/* Canonical consumption (app.css:1000) */
transition: var(--ax-transition-base);

/* Per-property consumption (for surfaces needing asymmetric durations) */
transition:
  opacity var(--ax-dur-2) var(--ax-ease-out),      /* enter: 180ms */
  transform var(--ax-dur-2) var(--ax-ease-out);
/* exit variant: var(--ax-dur-exit) var(--ax-ease-in) */
```

### Pattern B: phx-mounted / phx-remove (apply to detail_drawer, flash_group)

**Source:** `step_up_auth_modal.ex` lines 25–27

Always add both attrs on the same element that carries `:if={condition}`. `phx-mounted` fires when the element is added to DOM; `phx-remove` fires just before LiveView removes it. The `JS.show/hide` `time:` value must equal the CSS `transition-duration` in ms (comment must cite the token name).

### Pattern C: Reduced-motion free ride (apply to ALL surfaces)

**Source:** `theme.css:187–211`

All surfaces that route transitions through `--ax-transition-*` bundles or `--ax-dur-*`/`--ax-ease-*` atoms get reduced-motion correctness for free. The `@media (prefers-reduced-motion: reduce)` block collapses `--ax-dur-1/3/exit` to `0ms` and `--ax-dur-2` to `1ms` (opacity crossfades retained). No JS code should check `matchMedia('(prefers-reduced-motion: reduce)')` — the token override handles it.

### Pattern D: Guard + test coupling (apply to every new guard needle)

**Source:** `verify_package_docs.sh:322–328` + `package_docs_verifier_test.exs:241–268` + `seed_tmp_dir!/1:302–339`

Every new guard needle added to `verify_package_docs.sh` requires:
1. A negative test in `package_docs_verifier_test.exs` that injects the violation into the seeded `app.css` copy and asserts `status != 0`.
2. The `seed_tmp_dir!/1` function already copies `app.css` — no new `copy_fixture!` needed unless the guard targets a NEW file not already in the seed.
3. Both changes in the same commit (project MEMORY constraint).

---

## No Analog Found

All files have close analogs. No file requires falling back to RESEARCH.md patterns as a substitute.

---

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/components/`, `accrue_admin/assets/css/`, `accrue_admin/assets/js/hooks/`, `accrue_admin/e2e/`, `scripts/ci/`, `accrue/test/accrue/docs/`, `accrue_admin/mix.exs`
**Files scanned:** 14 source files read directly
**Pattern extraction date:** 2026-06-04
