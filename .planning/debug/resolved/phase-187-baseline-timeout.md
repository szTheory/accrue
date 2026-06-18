---
slug: phase-187-baseline-timeout
status: resolved
trigger: Phase-187 "Admin live interaction baseline" e2e times out >300s — probeAffordanceAndStates in accrue_admin/e2e/admin-interactions.spec.js iterates the ~10x-larger /billing/dev/components DOM. See STATE.md Pending Todos.
created: 2026-06-18
updated: 2026-06-18
---

# Debug Session: phase-187-baseline-timeout

## Symptoms

- **Expected behavior:** The Playwright test `"records trace-backed live interaction observations"` in the `Admin live interaction baseline` describe block (`accrue_admin/e2e/admin-interactions.spec.js:1175`) completes within its `test.setTimeout(180_000)` budget and writes a trace-backed NDJSON observation ledger.
- **Actual behavior:** The test hangs and the run exceeds 300s (overall), failing to complete. STATE.md attributes the hang to `probeAffordanceAndStates` (`admin-interactions.spec.js:631`), the last probe invoked (line 1191), after Phase 189 grew the `/billing/dev/components` (Component Kitchen) page ~10×.
- **Error messages:** Timeout (no specific stack captured yet). Test-level budget is 180s but observed wall time >300s — suggests either multiple Playwright projects each timing out, retries, or a hang upstream of the per-test timeout enforcement.
- **Timeline:** Introduced by Phase 189 (primitive/form components + Component Kitchen redesign, 2026-06-18), which enlarged the `/billing/dev/components` DOM ~10×. Phase-187 baseline observer was not updated. Pre-189 the test passed.
- **Reproduction:** Run the accrue_admin Playwright e2e suite (`admin-interactions.spec.js`), `Admin live interaction baseline` test.

## Evidence (initial, gathered by orchestrator)

- `probeAffordanceAndStates` (line 631) navigates `login(page, "/billing/dev/components")` then runs a small fixed loop of 5 `[selector,label]` pairs, each using `.first()` (NOT a per-node DOM iteration in the current source). Each iteration calls `await visible(locator)` up to ~4 times plus `activeSelector(page)` — repeated locator resolution against the ~10× larger kitchen DOM may be the multiplier, but per-node iteration claimed in STATE.md is not literally present in `probeAffordanceAndStates`.
- STATE.md note (line 220) and Pending Todos finger `probeAffordanceAndStates` specifically, but FOUR other probes run before it in the same test and several also `login(page, "/billing/dev/components")` (e.g. line 534). The actual hang location should be confirmed with a trace/console timing, not assumed.
- Other helpers worth timing: `visible()`, `activeSelector()`, `text()` — any that resolve broad selectors (e.g. `tbody tr, [data-role='card-list'] article`, `.ax-card`) against the kitchen become O(DOM-size).
- The test itself sets `test.setTimeout(180_000)` at line 1176 — so a single test timing out should cap near 180s, not 300s. The >300s figure implies multi-project/retry amplification or a hang that the per-test timeout doesn't cleanly interrupt (e.g. `setOffline` / `waitForLoadState("networkidle")` at line 662 against a heavy LiveView page).

## Current Focus

- **hypothesis:** The ~10× larger `/billing/dev/components` Component Kitchen DOM makes one or more broad-selector locator resolutions (in `probeAffordanceAndStates` and/or the earlier probes that also load that page) run long enough to blow the 180s test budget; STATE.md's "iterates the DOM per-node" framing may be approximate — the real cost is repeated broad-selector resolution and/or `waitForLoadState("networkidle")` never settling on the heavy LiveView page.
- **test:** Run the single test with Playwright tracing/`--reporter=line` and per-probe timing (or bisect by commenting probes) to pinpoint which probe and which call dominates wall time; confirm whether it's `probeAffordanceAndStates` or an earlier `/billing/dev/components` load.
- **expecting:** A specific probe + call site that accounts for the bulk of the >180s.
- **next_action:** RUNNING — instrumented per-probe timing logs added to the baseline test; running single test on chromium-desktop only with raised timeout to capture which probe dominates. Config confirms TWO projects (chromium-desktop + chromium-mobile), workers:1, so the test runs serially TWICE → 2×180s budget = up to 360s > 300s overall amplification.
- **reasoning_checkpoint:**
    hypothesis: "`await locator.hover()` on a disabled `.ax-button` (pointer-events:none) in probeAffordanceAndStates blocks until the 180s test timeout because Playwright actionability never sees the element receive pointer events; two serial projects push overall wall time past 300s."
    confirming_evidence:
      - "Per-iteration logs hang exactly after `visible(button[disabled]...) => true` and never print the disabled-button hover timing."
      - "`.ax-button:disabled { pointer-events: none }` at app.css:1332; Phase 189 added disabled button specimens to the kitchen."
      - "First 4 probes and all earlier loop iterations complete in ms; only the disabled-button hover hangs."
      - "playwright.config.js: 2 projects, workers:1 serial → ≈2×180s ≈ 360s > 300s."
    falsification_test: "Add `{ timeout: 1000 }` to the hover()/focus() calls; if the test still hangs ~180s, the hover hypothesis is wrong. Expected: probe finishes in seconds."
    fix_rationale: "Root cause is an unbounded actionability wait, not broad selectors. Bounding hover()/focus() with a short explicit timeout makes the actionability retry give up in ~1s instead of inheriting the 180s test timeout, while still recording the hover-focus-affordance observation (the .catch() already tolerates the rejection). This is the intent: the probe OBSERVES that disabled/non-interactive affordances are not actionable — a hover that doesn't land is exactly the signal, and shouldn't cost 180s to learn."
    blind_spots: "Have not yet confirmed focus() on the disabled button is harmless (it logged for other selectors but loop died before this one's focus). Bounding both is safe. Also relying on the disabled-button being the FIRST button[disabled] match; if other selectors later in the loop also hit pointer-events:none elements, the same bound applies."
- **tdd_checkpoint:**

## Eliminated

- hypothesis: Broad-selector locator resolution against the ~10× kitchen DOM is O(DOM-size) and dominates wall time.
  evidence: Per-selector `visible()`/`hover()`/`focus()` timing logs show every resolution completes in 10–80ms. The loop is fast. Disproven empirically.
  timestamp: 2026-06-18
- hypothesis: `waitForLoadState("networkidle")` (line 662) never settles on the heavy LiveView page and hangs.
  evidence: The timeout occurs BEFORE line 662 is reached — it hangs inside the for-loop (line 644) on the disabled-button hover, which runs before the loginMember/networkidle block. networkidle is never reached in the failing run.
  timestamp: 2026-06-18

## Evidence

- timestamp: 2026-06-18
  checked: Per-probe timing — commented out first 4 probes, ran probeAffordanceAndStates alone on chromium-desktop.
  found: First 4 probes are fast (probeDropdownPopoverToast 510ms, probeScrollFocusKeyboard 905ms). The hang is entirely inside probeAffordanceAndStates.
  implication: Earlier `/billing/dev/components` loads (line 534) are NOT the problem; the affordance probe is.
- timestamp: 2026-06-18
  checked: Per-iteration timing logs inside the affordance for-loop (line 635).
  found: Loop completes `.ax-card`, `tbody tr...`, `.ax-status` (not visible) fast; then logs `visible(button[disabled], [aria-disabled='true']) => true` and HANGS before logging `hover(button[disabled]...)`. The hover() call on the disabled button never returns. Test times out at exactly that hover.
  implication: The hang is `await locator.hover()` on a disabled button, line 644.
- timestamp: 2026-06-18
  checked: CSS for disabled buttons — accrue_admin/assets/css/app.css:1326-1333 `.ax-button:disabled`.
  found: `.ax-button:disabled { ...; pointer-events: none; }` (line 1332). Phase 189 added disabled `.ax-button` specimens to the Component Kitchen.
  implication: Playwright `hover()` runs actionability checks including "receives pointer events". With `pointer-events: none`, elementFromPoint never returns the element, so hover() retries until the test timeout (180s). `.catch()` only fires after hover throws on timeout, so the test body blocks ~180s. Two Playwright projects (chromium-desktop + chromium-mobile, workers:1, serial) → >300s overall.
- timestamp: 2026-06-18
  checked: playwright.config.js
  found: TWO projects (chromium-desktop, chromium-mobile), workers:1, fullyParallel:false. No per-call timeout on hover().
  implication: Explains the >300s (≈2×180s) overall wall time despite the 180s per-test budget.

## Resolution

root_cause: In probeAffordanceAndStates (admin-interactions.spec.js:644), `await locator.hover().catch(() => {})` is called on a disabled button. Phase 189 introduced disabled `.ax-button` specimens to the Component Kitchen (/billing/dev/components), and `.ax-button:disabled` has `pointer-events: none` (app.css:1332). Playwright's hover() actionability check waits for the element to "receive pointer events", which never happens under `pointer-events: none`, so hover() retries until the 180s test timeout. The `.catch()` cannot help because hover() only rejects at timeout. Two serial Playwright projects amplify the wall time past 300s.
fix: Bound the hover()/focus() calls in probeAffordanceAndStates' affordance for-loop (admin-interactions.spec.js:644) with `{ timeout: 1_000 }`. The actionability retry now gives up in ~1s on `pointer-events: none` disabled specimens instead of inheriting the 180s test budget. All recorder.observe() calls and required observation classes are unchanged.
verification: Full baseline test now passes on BOTH projects (chromium-desktop + chromium-mobile) in 21.0s total (was >300s timeout). All 12 required observation classes + >20 rows assertions pass. Adjacent Phase-189 component-kitchen probe tests (10 tests) also pass in 5.9s — no regression. Instrumentation reverted; diff is the bounded-timeout change only. ORCHESTRATOR RE-VERIFIED 2026-06-18: independent `npm run e2e -- -g "records trace-backed live interaction observations"` → 2 passed (25.7s) across both projects.
files_changed: [accrue_admin/e2e/admin-interactions.spec.js]
