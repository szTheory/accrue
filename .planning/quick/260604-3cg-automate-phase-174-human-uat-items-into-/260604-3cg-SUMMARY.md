---
quick_task: 260604-3cg
date: 2026-06-04
status: complete
commits:
  - hash: a228bda5
    message: "test(174): automate human-UAT items into CI — token render, CSS wiring, Playwright computed-style"
  - hash: e481b3e7
    message: "docs(174): retire human gate — both UAT items now automated by CI"
files_modified:
  - accrue_admin/test/accrue_admin/dev/component_registry_test.exs
  - accrue_admin/test/accrue_admin/components/dunning_banner_test.exs
  - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
  - accrue_admin/e2e/kitchen-banner.spec.js
  - .planning/phases/174-a-design-system-gap-closure-token-completeness/174-VERIFICATION.md
  - .planning/phases/174-a-design-system-gap-closure-token-completeness/174-HUMAN-UAT.md
---

# Quick Task 260604-3cg: Automate Phase 174 Human UAT Items into CI

Both Phase 174 human-verification items fully shifted left into CI: ExUnit render + CSS-wiring gates plus a Playwright computed-style spec, eliminating all manual browser verification.

## What Was Done

### Task 1: ExUnit tests + kitchen LiveView

**component_registry_test.exs** — Added test (d): mounts `/billing/dev/components` via the existing session/live pattern, iterates every `ComponentRegistry.entries()` token and asserts it appears in the rendered HTML, then refutes three phantom token names (`--ax-neutral`, `--ax-ink`, `--ax-info`). Reuses the already-defined `theme_css_path()` and `app_css_path()` private helpers with no redefinition.

**dunning_banner_test.exs** — Added "ax-banner-danger CSS class wires background and text to danger tokens (no browser needed)" inside the existing `describe "dunning_banner/1"` block. Reads `app.css` and `theme.css` at test-time via two new private helpers; asserts `background-color: var(--ax-danger-surface)`, `color: var(--ax-danger-readable)`, and the three token definitions in `theme.css`. No repo/factory setup required.

**component_kitchen_live.ex** — Added a Banners showcase section after the Cards section and before the outer `</section>` (ax-page close). Contains a `div` with `data-ax-kitchen-banner="danger" class="ax-banner ax-banner-danger"` — no new alias needed (plain div with CSS classes, not a component call).

### Task 2: Playwright computed-style spec

Created `accrue_admin/e2e/kitchen-banner.spec.js` mirroring `admin-a11y.spec.js` helper style. The spec:
1. Logs in via `/__e2e__/login?to=/billing/dev/components`
2. Enables `reducedMotion: "reduce"` (zeroes transitions)
3. For both light and dark themes: sets `data-theme` attribute, reads `backgroundColor` and `color` via `window.getComputedStyle`
4. Asserts background is not `rgba(0, 0, 0, 0)` in either theme
5. Asserts text color differs between light and dark (proving `--ax-danger-readable` cascade drives painted color)

### Task 3: Planning doc updates

**174-VERIFICATION.md** — Removed `human_verification:` block from frontmatter, changed `status: human_needed` to `status: verified`, added automation note at top of body.

**174-HUMAN-UAT.md** — Changed `status: partial` to `status: complete`, both test items `result: pass` with automation notes, `passed: 2 / pending: 0`, Current Test section set to `[testing complete]`.

## Verification Results

### mix test gate

```
cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs \
                            test/accrue_admin/components/dunning_banner_test.exs
```

**Result: 8 tests, 0 failures**
- component_registry_test.exs: 4 tests (3 existing + 1 new test d)
- dunning_banner_test.exs: 4 tests (3 existing + 1 new CSS-wiring test)

### Playwright e2e gate (best-effort locally)

```
cd accrue_admin && npm run e2e -- e2e/kitchen-banner.spec.js
```

**Result: 2 passed (chromium-desktop + chromium-mobile)** — local e2e server was available; both projects passed in 5.2s.

### Documentation gate

```
grep "status: verified" .planning/phases/174-.../174-VERIFICATION.md  → MATCH
grep "status: complete" .planning/phases/174-.../174-HUMAN-UAT.md     → MATCH
```

## Commits

| Commit | Message | Files |
|--------|---------|-------|
| `a228bda5` | test(174): automate human-UAT items into CI — token render, CSS wiring, Playwright computed-style | component_registry_test.exs, dunning_banner_test.exs, component_kitchen_live.ex, e2e/kitchen-banner.spec.js |
| `e481b3e7` | docs(174): retire human gate — both UAT items now automated by CI | 174-VERIFICATION.md, 174-HUMAN-UAT.md |

## Deviations

None — plan executed exactly as written. The Playwright e2e ran successfully locally (e2e server was available), eliminating the "best-effort only" caveat noted in the plan.

## Self-Check

- [x] All 6 named files modified/created
- [x] 8 ExUnit tests pass (0 failures)
- [x] 2 Playwright tests pass (chromium-desktop + chromium-mobile)
- [x] 174-VERIFICATION.md: `status: verified`, `human_verification:` block absent, automation note present
- [x] 174-HUMAN-UAT.md: `status: complete`, `passed: 2`, `pending: 0`, both tests `result: pass`
- [x] Zero CSS file changes
- [x] Zero changes to unrelated pre-existing files
- [x] Two commits at correct hashes verified via `git log --oneline -5`
