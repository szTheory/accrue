---
phase: 179-f-screenshot-driven-visual-qa-loop-sign-off
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - accrue_admin/e2e/admin-visuals.spec.js
  - accrue_admin/e2e/admin-a11y.spec.js
  - accrue_admin/e2e/admin-motion-trace.spec.js
  - accrue_admin/e2e/score-visuals.mjs
findings:
  critical: 0
  warning: 4
  info: 2
  total: 6
status: issues_found
---

# Phase 179-F: Code Review Report

**Reviewed:** 2026-06-04T00:00:00Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Four QA tooling files reviewed: three Playwright e2e specs and the Node ESM vision-scoring CLI. No hardcoded secrets. The API-key guard in `score-visuals.mjs` is correctly positioned as the first executable statement before any SDK import. Routes are correct (`/billing/payments`, `/billing/connect`, `/billing/analytics/recovery/subscriptions/:id`). All specs use `beforeEach` reset, proper `await` discipline, and `#main-content` visibility gates before assertions.

Two robustness defects in `score-visuals.mjs` require attention: a non-array LLM response silently escalates from a per-image skip into a full process abort, and a `WriteStream` handle is opened but never written to or closed. Two spec-level logic gaps in `admin-motion-trace.spec.js` create false-positive risks: an unscoped panel locator in the dropdown test and silently-skipped collapse assertions in the nav-group test.

---

## Warnings

### WR-01: Non-array LLM response aborts the entire scoring run

**File:** `accrue_admin/e2e/score-visuals.mjs:217-227`

**Issue:** After `JSON.parse(rawText)` succeeds, the code immediately enters `for (const finding of findings)` without checking `Array.isArray(findings)`. If the model returns a valid JSON value that is not an array — a plain object `{}`, `null`, a number, or a bare string — `for...of` throws `TypeError: findings is not iterable`. This escapes the inner `catch` (which only catches `parseErr`) and is caught by the outer `catch (err)` at line 252, which calls `process.exit(1)`. The entire run is terminated, dropping all findings for any remaining PNGs. The LLM can return a non-array response under load, truncation, or instruction-following failure.

**Fix:**
```js
let findings;
try {
  const parsed = JSON.parse(rawText);
  findings = Array.isArray(parsed) ? parsed : null;
} catch (parseErr) {
  console.error(
    `[score-visuals] Failed to parse model response for ${screen} (${viewport}/${theme}): ${parseErr.message}`
  );
  console.error("[score-visuals] Raw response:", rawText.slice(0, 500));
  continue;
}

if (!findings) {
  console.error(
    `[score-visuals] Model returned non-array for ${screen} (${viewport}/${theme}): ${rawText.slice(0, 200)}`
  );
  continue; // skip this image, don't abort the run
}
```

---

### WR-02: `WriteStream` opened but never written to or closed (`!TO_STDOUT` path)

**File:** `accrue_admin/e2e/score-visuals.mjs:167-168, 240-244`

**Issue:** When `TO_STDOUT` is false the code creates a `WriteStream` via `fs.createWriteStream(findingsPath, { flags: "a" })` (line 168) but never calls `.write()` on it — all file writes go through `fs.appendFileSync(findingsPath, line)` at line 243 instead. The stream handle is never `.end()`'d. This leaves an open file descriptor for the entire duration of the run. On error paths that call `process.exit(1)`, the OS reclaims the FD, but in normal operation the stream is garbage-collected without a flush guarantee (no pending data in this case, but the pattern is incorrect and confusing). The dead variable also creates a misleading code path — `findingsOutput` appears to be the write target but is never used in the file mode.

**Fix:** Remove the dead `WriteStream` entirely and use `appendFileSync` consistently (already the actual write path), or switch entirely to the stream and use it for all writes:

```js
// Option A — remove the dead stream, keep appendFileSync (minimal change)
if (!TO_STDOUT) {
  findingsPath = path.join(RESULTS_DIR, "findings.ndjson");
  fs.writeFileSync(findingsPath, ""); // truncate/create
}

// ... in the write block:
if (TO_STDOUT) {
  process.stdout.write(line);
} else {
  fs.appendFileSync(findingsPath, line);
}
```

---

### WR-03: Dropdown panel locator not scoped to the clicked `<details>` element

**File:** `accrue_admin/e2e/admin-motion-trace.spec.js:94-106`

**Issue:** `dropdownSummary` is scoped to `details.ax-dropdown > summary` (first match), but `panel` is located with a separate top-level query `page.locator(".ax-dropdown-panel").first()`. If the customers page renders multiple `details.ax-dropdown` elements, `panel.first()` may resolve to a panel belonging to a *different* dropdown than the one that was clicked. The `toBeVisible()` assertion at line 102 would then pass because a different panel happens to be open, producing a false positive. The `toBeHidden()` assertion at line 106 would similarly check the wrong element.

**Fix:**
```js
const dropdown = page.locator("details.ax-dropdown").first();
const dropdownSummary = dropdown.locator("summary");
const panel = dropdown.locator(".ax-dropdown-panel");

await expect(dropdownSummary).toBeVisible();
await dropdownSummary.click();
await expect(panel).toBeVisible();
await dropdownSummary.click();
await expect(panel).toBeHidden();
```

---

### WR-04: Nav-group collapse assertions silently skipped when `data-controls` attribute is absent

**File:** `accrue_admin/e2e/admin-motion-trace.spec.js:126-144`

**Issue:** `controlledId` is obtained from `toggleButton.getAttribute("data-controls")`. If the attribute is missing (returns `null`), the `if (controlledId)` guards at lines 132 and 140 prevent both `toBeHidden()` and `toBeVisible()` assertions from executing. The test clicks the button twice and then passes with no behavioral verification — it would pass even if the collapse toggle is completely broken. The button's existence (line 123) is asserted, but not its effect.

**Fix:** Assert that the attribute is present before proceeding, so the test fails explicitly rather than silently degrading:

```js
const controlledId = await toggleButton.getAttribute("data-controls");
// Fail loudly if the attribute is absent rather than silently skipping assertions
expect(controlledId, "collapse toggle must have data-controls attribute").toBeTruthy();

await toggleButton.click();
await expect(page.locator(`#${controlledId}`)).toBeHidden();

await toggleButton.click();
await expect(page.locator(`#${controlledId}`)).toBeVisible();
```

---

## Info

### IN-01: `reset()` + `seed()` helpers duplicated verbatim across all three spec files

**File:** `accrue_admin/e2e/admin-visuals.spec.js:3-16`, `accrue_admin/e2e/admin-a11y.spec.js:4-17`, `accrue_admin/e2e/admin-motion-trace.spec.js:31-44`

**Issue:** The `reset()`, `seed()`, and `login()` helpers are copy-pasted identically into all three spec files. The motion-trace file even notes this with "// copied verbatim from admin-visuals.spec.js". Any future change (e.g. error handling improvement, endpoint rename) must be made in three places.

**Fix:** Extract to a shared helper module `accrue_admin/e2e/helpers.js` and `require()` it in each spec:
```js
// e2e/helpers.js
const { expect } = require("@playwright/test");
async function reset(request) { ... }
async function seed(request, fixture) { ... }
async function login(page, target = "/billing") { ... }
module.exports = { reset, seed, login };

// in each spec:
const { reset, seed, login } = require("./helpers");
```

---

### IN-02: Inaccurate "scored" count in final summary when parse errors occur

**File:** `accrue_admin/e2e/score-visuals.mjs:261-264`

**Issue:** The final log line at line 263 reports `pngs.length - skipped` as the count of PNGs scored. However, the `skipped` counter (line 183) only tracks oversized-image skips; it does not count PNGs skipped due to JSON parse failures (`continue` at line 223). If a parse error occurs, the image is counted as "scored" in the summary even though no findings were written for it.

**Fix:** Add a `parseErrors` counter incremented at line 223, and include it in the summary:
```js
let parseErrors = 0;
// ...
// in the parse error catch:
parseErrors++;
continue;
// ...
const scoredNote = parseErrors > 0 ? ` (${parseErrors} parse error(s))` : "";
console.log(
  `[score-visuals] Scored ${pngs.length - skipped - parseErrors} PNGs → ${totalFindings} findings (${belowBar} below bar)${skippedNote}${scoredNote}`
);
```

---

_Reviewed: 2026-06-04T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
