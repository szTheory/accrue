---
phase: 174
plan: 04
subsystem: accrue_admin/test
tags: [design-system, component-registry, drift-prevention, test, dsy-03]
dependency_graph:
  requires: [174-03]
  provides: [component-registry-drift-test, dsy-03-complete]
  affects:
    - accrue_admin/test/accrue_admin/dev/component_registry_test.exs
tech_stack:
  added: []
  patterns:
    - LiveCase + Phoenix.Component use for live/2 + render_component combined in one test module
    - MapSet equality assertion for component variant drift detection
    - targeted regex anchor on base class to avoid capturing inner child element classes
key_files:
  created:
    - accrue_admin/test/accrue_admin/dev/component_registry_test.exs
  modified: []
decisions:
  - "use Phoenix.Component added to LiveCase-based test module to bring in ~H sigil for render_component wrapping function"
  - "render_component wrapping function uses assigns.variant (not a captured outer binding) to avoid unused-variable compiler warning in HEEx lambda"
  - "extract_button_class/1 anchors regex on ax-button to avoid capturing inner child element classes (pitfall 5 from RESEARCH.md)"
metrics:
  duration: 5m
  completed: "2026-06-03"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 1
---

# Phase 174 Plan 04: ComponentRegistryTest Drift-Prevention Test Summary

**One-liner:** Created AccrueAdmin.Dev.ComponentRegistryTest with two drift-prevention tests — live/2 page render coverage for all 15 registry entries and MapSet equality assertion for Button family ax_class set vs. component render outputs (including danger variant), enforcing D-21 in CI.

## What Was Built

### Task 1: ComponentRegistryTest drift-prevention test (b0c67dd6)

New file at `accrue_admin/test/accrue_admin/dev/component_registry_test.exs`.

**Module design:**
- `use AccrueAdmin.LiveCase, async: false` — DB sandbox for test (a)'s LiveView mount
- `use Phoenix.Component` — brings in `~H` sigil for test (b)'s render_component wrapping function
- Aliases: `AccrueAdmin.Dev.ComponentRegistry`, `AccrueAdmin.Components.Button`

**Test (a) — page render coverage:**

Initializes a test session with `admin_token: "admin"`, calls `live(conn, "/billing/dev/components")`, then iterates every entry in `ComponentRegistry.entries()`. For each entry, splits `ax_class` on `" "` with `parts: 2` to extract the variant-specific class (second element), and asserts it appears in the rendered HTML with a clear error message including the full `ax_class`.

Catches: a section failing to render, a variant rendering under the wrong class, a registry entry with a wrong ax_class value. Covers all 15 entries (4 button + 5 status + 6 card).

**Test (b) — Button family drift detection:**

Builds `registry_classes` MapSet from `ComponentRegistry.variants_for("button") |> MapSet.new(& &1.ax_class)`.

Builds `component_classes` MapSet by rendering each of `["primary", "secondary", "ghost", "danger"]` via `render_component(fn assigns -> ~H"""<Button.button variant={assigns.variant} type="button">Label</Button.button>""" end, %{variant: variant})`, extracting the class attribute via `extract_button_class/1`, then collecting into a MapSet.

Asserts `registry_classes == component_classes` with a descriptive diff in the failure message. If a 5th Button variant is added to `button_variant_class/1` without a registry entry, this test fails CI before the PR merges.

**Private helper `extract_button_class/1`:**

Uses `Regex.run(~r/class="(ax-button[^"]+)"/, html)` anchored on `ax-button` to target the button element's class attribute specifically, avoiding false-positive matches on inner child element class attributes (RESEARCH.md pitfall 5). On no-match, calls `flunk/1` with the raw HTML — silent false-positives are impossible.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write ComponentRegistryTest drift-prevention test | b0c67dd6 | accrue_admin/test/accrue_admin/dev/component_registry_test.exs |

## Verification Results

Plan-level acceptance criteria (all pass):

1. File exists: `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` — PASS
2. `mix test test/accrue_admin/dev/component_registry_test.exs` → exit 0, 2 tests, 0 failures — PASS
3. Test (a) passes: all registry variant classes found in /dev/components page HTML — PASS
4. Test (b) passes: registry Button ax_class set == component render outputs MapSet (all 4 variants including danger) — PASS
5. `grep -c 'danger' .../component_registry_test.exs` → 3 (>= 1) — PASS
6. `mix test --seed 0` → 171 tests, 0 failures — PASS

Phase gate verifications (all pass):

7. `bash scripts/ci/verify_package_docs.sh` → exit 0 — PASS
8. `grep -E 'line-height: [0-9]\.[0-9]' app.css` → ZERO results — PASS
9. `grep -E 'letter-spacing: -?[0-9.]+em' app.css` → ZERO results — PASS
10. `grep -E '@media \((min|max)-width: [0-9.]+px\)' app.css | grep -v '\-\-ax-bp-'` → ZERO results — PASS
11. `grep -rn 'style=' dunning_banner.ex` → ZERO results — PASS
12. `mix test test/accrue/docs/package_docs_verifier_test.exs` → 9 tests, 0 failures — PASS

## Deviations from Plan

### Auto-applied judgment (within plan scope)

**1. [Rule 1 - Bug] Added `use Phoenix.Component` for ~H sigil availability**
- **Found during:** Task 1 — first test run
- **Issue:** `AccrueAdmin.LiveCase` imports `Phoenix.LiveViewTest`, `Plug.Conn`, and `Phoenix.ConnTest` but does NOT import `Phoenix.Component`. The `~H` sigil required for the `render_component` wrapping function was undefined.
- **Fix:** Added `use Phoenix.Component` to the test module, consistent with `display_components_test.exs` which uses the same pattern (lines 4: `use Phoenix.Component`).
- **Files modified:** accrue_admin/test/accrue_admin/dev/component_registry_test.exs

**2. [Rule 1 - Bug] Fixed unused-variable warning in HEEx lambda**
- **Found during:** Task 1 — first test run (compiler warning)
- **Issue:** The plan's PATTERNS.md suggested `variant = assigns.variant` inside the lambda body before `~H`. This creates an unused binding (`variant`) because the outer closure variable `variant` is what the compiler sees; inside the `~H` block, `assigns.variant` is the correct way to reference the assign.
- **Fix:** Removed the intermediate binding; use `assigns.variant` directly inside `~H`.
- **Files modified:** accrue_admin/test/accrue_admin/dev/component_registry_test.exs

## Known Stubs

None. Both tests exercise real rendered HTML from live components, not mock or placeholder data.

## Threat Flags

None. The test file is test-only, no production surface introduced.

## Self-Check: PASSED

- [x] `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` exists
- [x] Commit b0c67dd6 exists in git log
- [x] 2 tests, 0 failures (isolated run)
- [x] 171 tests, 0 failures (full admin suite --seed 0)
- [x] `danger` appears 3 times in test file
- [x] All 6 phase gate verifications pass
- [x] DSY-03 D-21 enforcement: adding a 5th Button variant without registry entry fails test (b)
