---
phase: 179-f-screenshot-driven-visual-qa-loop-sign-off
fixed_at: 2026-06-04T00:00:00Z
review_path: .planning/phases/179-f-screenshot-driven-visual-qa-loop-sign-off/179-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 179: Code Review Fix Report

**Fixed at:** 2026-06-04T00:00:00Z
**Source review:** .planning/phases/179-f-screenshot-driven-visual-qa-loop-sign-off/179-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (WR-01 through WR-04; IN-01 and IN-02 out of scope per fix_scope: critical_warning)
- Fixed: 4
- Skipped: 0

## Fixed Issues

### WR-01: Non-array LLM response aborts the entire scoring run

**Files modified:** `accrue_admin/e2e/score-visuals.mjs`
**Commit:** 427da8b9
**Applied fix:** Inside the try/catch block, `JSON.parse(rawText)` now assigns into a local `parsed` variable. `findings` is set to `parsed` only when `Array.isArray(parsed)` is true, otherwise `null`. A post-try guard on `!findings` emits a descriptive error and `continue`s to the next PNG rather than propagating a TypeError into the outer catch that calls `process.exit(1)`. Both the parse-error path and the non-array path now result in per-image skip events, leaving the rest of the scoring run intact.

---

### WR-02: `WriteStream` opened but never written to or closed (`!TO_STDOUT` path)

**Files modified:** `accrue_admin/e2e/score-visuals.mjs`
**Commit:** 8fc694bc
**Applied fix:** Removed the `findingsOutput = fs.createWriteStream(findingsPath, { flags: "a" })` line entirely. The `fs.writeFileSync(findingsPath, "")` truncation call is retained so reruns do not concatenate stale findings. The `findingsOutput` variable still holds `process.stdout` for the `TO_STDOUT` branch; in the file branch it is no longer assigned (it was never used there). All file writes continue to use `fs.appendFileSync(findingsPath, line)` as before.

---

### WR-03: Dropdown panel locator not scoped to the clicked `<details>` element

**Files modified:** `accrue_admin/e2e/admin-motion-trace.spec.js`
**Commit:** d013676b
**Applied fix:** Introduced a `dropdown` locator (`page.locator("details.ax-dropdown").first()`) and derived both `dropdownSummary` (`dropdown.locator("summary")`) and `panel` (`dropdown.locator(".ax-dropdown-panel")`) from it. This ensures `toBeVisible()` and `toBeHidden()` assertions target the panel that belongs to the clicked dropdown, not an arbitrary first match across the entire page.

---

### WR-04: Nav-group collapse assertions silently skipped when `data-controls` attribute is absent

**Files modified:** `accrue_admin/e2e/admin-motion-trace.spec.js`
**Commit:** 7b998a10
**Applied fix:** Replaced both `if (controlledId)` guards with a hard `expect(controlledId, "collapse toggle must have data-controls attribute").toBeTruthy()` assertion immediately after `getAttribute`. The two `groupLinks` locator variables were inlined directly into the `expect()` calls. The test now fails explicitly when the attribute is absent rather than silently passing with zero behavioral verification.

---

_Fixed: 2026-06-04T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
