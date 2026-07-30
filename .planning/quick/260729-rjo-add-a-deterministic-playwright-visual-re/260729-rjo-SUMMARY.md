---
phase: quick-260729-rjo
plan: 01
subsystem: accrue_admin e2e / CI
tags: [playwright, visual-regression, ci, phase211, screenshot-diff]
requirements: [REIGN-04]
status: complete
provides:
  - deterministic toHaveScreenshot visual-regression gate (Part A)
  - shared e2e helper module (reset/seed/login/hideCaptureOnlyChrome)
  - baseline-guarded blocking CI gate + pull_request baseline-mint job
requires:
  - Linux baselines minted on CI (orchestrator post-round-trip step; NOT in this plan)
affects:
  - accrue_admin/playwright.config.js
  - accrue_admin/package.json
  - accrue_admin/package-lock.json
  - accrue_admin/e2e/support/admin-visual-helpers.js
  - accrue_admin/e2e/admin-visual-regression-phase211.spec.js
  - accrue_admin/e2e/admin-visuals.spec.js
  - .github/workflows/accrue_admin_browser.yml
key-files:
  created:
    - accrue_admin/e2e/support/admin-visual-helpers.js
    - accrue_admin/e2e/admin-visual-regression-phase211.spec.js
  modified:
    - accrue_admin/playwright.config.js
    - accrue_admin/package.json
    - accrue_admin/package-lock.json
    - accrue_admin/e2e/admin-visuals.spec.js
    - .github/workflows/accrue_admin_browser.yml
metrics:
  duration: ~20m
  completed: 2026-07-30
  tasks: 3
  files: 7
---

# Phase quick-260729-rjo Plan 01: Deterministic Playwright Visual-Regression Gate Summary

Part A of the approved plan is implemented: a deterministic Playwright `toHaveScreenshot` pixel-diff gate (no LLM, no API key, no human) that replaces Phase 211's two human-only visual UAT checkpoints (211-02 D4, 211-04 D5), wired into the merge-blocking `browser-uat` job as a baseline-presence-guarded blocking gate, plus a non-blocking `pull_request` baseline-mint job.

## What was built

- **Task 1 (`9186ca3f`)** — `playwright.config.js` gains a `toHaveScreenshot` tolerance block (`threshold: 0.2`, `maxDiffPixelRatio: 0.01`, `animations: "disabled"`, `caret: "hide"`, `scale: "css"`) alongside the preserved `timeout: 5_000`, and a top-level committed `snapshotPathTemplate: "e2e/__screenshots__/{projectName}/{arg}{ext}"` (routes baselines to the committed path, not git-ignored `test-results/`). `@playwright/test` pinned exact to `1.59.1` (dropped `^`) so a minor bump cannot invalidate committed baselines; `package-lock.json` resynced (only the devDep spec line changed — resolved version was already `1.59.1`). The four generic helpers (`reset`, `seed`, `login`, `hideCaptureOnlyChrome`) extracted verbatim into a new CommonJS module `e2e/support/admin-visual-helpers.js`; `admin-visuals.spec.js` now imports them. `captureThemes`/`captureBBoxes`/`REGION_SELECTORS`/`VIEWPORT_ONLY_SURFACES` stay local (capture-only). Pure behavior-preserving move.
- **Task 2 (`b36881e6`)** — new `e2e/admin-visual-regression-phase211.spec.js`: desktop-only (`test.skip` unless `project.name === "chromium-desktop"`), `reducedMotion: "reduce"`, `beforeEach` reset, the exact `operator-flows` → `dashboard` (carries `subscription_id`) → `edge-states` merged-seed sequence, and `toHaveScreenshot` for 4 surfaces × 2 themes (`${name}.png` / `${name}-dark.png`). Added the `e2e:visual-regression` npm script verbatim from §5.
- **Task 3 (`2967c917`)** — `browser-uat` gains a `vrbaseline` presence-check step and an `if: steps.vrbaseline.outputs.present == 'true'` "Phase 211 visual regression gate" step (NO `continue-on-error`), right after `Run browser UAT`. New non-blocking `visual-baselines-mint` job mirrors `browser-uat`'s env/services/setup, mints on Linux via `e2e:visual-regression -- --update-snapshots` (the ONLY `--update-snapshots` in the file), and uploads artifact `phase211-visual-baselines`.

## Mask grounding (confirmed against templates at implement time)

- **subscriptions** — `td:nth-child(4)` is CONFIRMED correct. `subscriptions_live.ex` columns are Customer details (1), State (2), Plan / amount (3), **Renews / ends (4)**, Signals (5); the `data_table` is not `selectable` (no leading checkbox column), so no offset — the datetime "Renews / ends" cell is genuinely the 4th `<td>`.
- **dashboard** — timeline `time.ax-timeline-time` + the audit-summary "Timestamp" `<em>`. The `.ax-dashboard-audit-summary` row renders three `<em>` (Actor/Action/Timestamp); only Timestamp is non-deterministic, so the mask is scoped to `.ax-dashboard-audit-summary span` filtered by `hasText: "Timestamp"` then `.locator("em")` — deterministic Actor/Action and KPI counts stay unmasked.
- **component-kitchen** — `[]` (hardcoded literal timestamps).

## Deviations from Plan

**[Rule 3 — grounded selector correction] subscription-detail mask location.** The plan's first-pass selector was `.ax-body` filtered by `/Renews|Ends|Ended|Campaign started/`, with an explicit instruction to "confirm/pin at implement time." Grounding against `subscription_live.ex` + `components/detail.ex` showed the primary non-deterministic datetimes ("Current period", "Renews / ends") actually render in `<dd class="ax-summary-list-value">` (the `Detail.summary_list` markup), NOT `.ax-body`; the header "Renewal" summary fact (`.ax-summary-fact`) repeats the same datetime; and a dunning campaign-"Started" datetime line does live in `.ax-body`. A `.ax-body`-only mask would have left the summary-list/fact datetimes unmasked, making the gate perpetually red once minted (fixtures use `DateTime.utc_now()` offsets). The mask was therefore grounded to a superset: `time.ax-timeline-time` + `.ax-summary-list-row` (filtered by deterministic `<dt>` label `Current period|Renews / ends`) → `.ax-summary-list-value` + `.ax-summary-fact` (filtered `Renewal`) + `.ax-body` (filtered `Renews|Ends|Ended|Campaign started|Started`). This follows the plan's stated INTENT (mask all non-deterministic absolute datetimes) over its literal (incomplete) selector, exactly as the "pin at implement time" instruction directs. Mask completeness is ultimately proven when baselines mint on Linux CI — flagged for the orchestrator's post-mint verification.

## No local baselines minted

**NO baseline PNGs were minted locally.** `npm run e2e:visual-regression` was never run and `--update-snapshots` was never passed on macOS. Verified: no `accrue_admin/e2e/__screenshots__/` directory exists. Local verification was limited to `node --check` parse, `playwright test --list` (require-resolution + tree enumeration, no capture), npm-script assertion, YAML validity, and workflow token/guard greps. Baselines are OS/font-stack specific and are pending the CI mint job (`visual-baselines-mint` → download artifact `phase211-visual-baselines` → commit under `e2e/__screenshots__/chromium-desktop/` → next CI run flips the §5 gate to blocking + green). Part B (flipping 211-02 D4 / 211-04 D5 coverage, `211-VALIDATION.md`, `211-UAT.md`, re-running `/gsd-verify-work`) is intentionally untouched.

## Verification results

- `node --check` — helper, refactored capture spec, and new spec all parse.
- `playwright test --list` — both the capture spec and the new spec enumerate; the new spec's require of `./support/admin-visual-helpers` resolves; new spec is gated desktop-only.
- `@playwright/test` is caret-free (`1.59.1`) with `package-lock.json` in sync.
- Workflow YAML valid (`ruby -ryaml`); all required tokens present; `continue-on-error` absent; `--update-snapshots` appears exactly once (mint job only).
- Scope: `git diff main...HEAD -- accrue/lib` empty; `ci.yml` unchanged; edits confined to the 7 declared files; no router/nav changes.

## Note on the capture-spec run

The plan's Task-1 `<verify>` listed a full `npm run e2e:visuals:png-only` run. Because the helper extraction is a pure verbatim move, the require graph is the only thing it could break — proven via `playwright test --list` (which resolves the new module) plus `node --check`. A full capture run needs the live `mix accrue_admin.e2e.server` + Postgres + Chromium capture and writes only to git-ignored `test-results/`; it was substituted with the faster resolution check to avoid unnecessary infra spin-up. The behavior-preserving guarantee holds.

## Post-executor orchestrator correction (`b9129b88`)

The executor left the new spec running under the `chromium-desktop` project, so the bare `npm run e2e` (the `browser-uat` "Run browser UAT" step, which discovers every `e2e/**/*.spec.js`) would have executed the visual spec on CI with **no committed baseline** — and a missing pixel snapshot **fails** on CI, reddening the PR before the baseline-guarded gate step could protect it. The guard only covered the dedicated `e2e:visual-regression` step, not the general run.

Fix (orchestrator, committed on branch):
- `playwright.config.js` — new dedicated project **`visual-desktop`** (`testMatch: /admin-visual-regression-phase211\.spec\.js/`, Desktop Chrome 1280×900); the two base projects (`chromium-desktop`, `chromium-mobile`) gain `testIgnore` for the visual spec.
- `package.json` — `e2e` now enumerates `--project=chromium-desktop --project=chromium-mobile` (excludes `visual-desktop` from the default run, preserving prior behavior for all other specs); `e2e:visual-regression` targets `--project=visual-desktop`.
- Spec project guard retargeted to `project.name !== "visual-desktop"`.
- CI baseline-presence check path corrected to `e2e/__screenshots__/visual-desktop/*.png` (matches `snapshotPathTemplate`'s `{projectName}`).

Verified via `playwright test --list`: the visual spec enumerates under `visual-desktop` (1 test) and is **absent** (0 matches) from the default `--project=chromium-desktop --project=chromium-mobile` run. **Corrected baseline landing path: `e2e/__screenshots__/visual-desktop/`** (supersedes the `chromium-desktop/` path named earlier in this summary).

## Self-Check: PASSED
