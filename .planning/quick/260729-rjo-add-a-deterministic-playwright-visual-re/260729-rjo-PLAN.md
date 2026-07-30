---
phase: quick-260729-rjo
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: true
requirements: [REIGN-04]
files_modified:
  - accrue_admin/playwright.config.js
  - accrue_admin/package.json
  - accrue_admin/package-lock.json
  - accrue_admin/e2e/support/admin-visual-helpers.js
  - accrue_admin/e2e/admin-visual-regression-phase211.spec.js
  - accrue_admin/e2e/admin-visuals.spec.js
  - .github/workflows/accrue_admin_browser.yml

must_haves:
  truths:
    - "A deterministic toHaveScreenshot pixel-diff gate is wired into the merge-blocking browser-uat job, guarded to skip (stay green) until Linux baselines are committed, then blocking."
    - "A new desktop-only spec asserts toHaveScreenshot for dashboard, subscriptions, subscription-detail (fullPage) and component-kitchen (viewport) in light and dark, with per-surface masks for non-deterministic datetimes."
    - "admin-visuals.spec.js still passes after reset/seed/login/hideCaptureOnlyChrome are extracted to a shared helper module (behavior-preserving)."
    - "A pull_request-triggered visual-baselines-mint job mints Linux baselines and uploads them as artifact phase211-visual-baselines."
  artifacts:
    - accrue_admin/e2e/support/admin-visual-helpers.js
    - accrue_admin/e2e/admin-visual-regression-phase211.spec.js
    - accrue_admin/playwright.config.js
    - .github/workflows/accrue_admin_browser.yml
  key_links:
    - "New spec require()s ./support/admin-visual-helpers for the shared reset/seed/login/hideCaptureOnlyChrome helpers."
    - "snapshotPathTemplate routes baselines to the committed e2e/__screenshots__/{projectName}/ path (not git-ignored test-results/)."
    - "CI gate step is gated on steps.vrbaseline.outputs.present == 'true' with NO continue-on-error."
---

<objective>
Build the **Part A** visual-regression gate from the approved plan: a deterministic Playwright `toHaveScreenshot` pixel-diff that replaces Phase 211's two human-only visual UAT checkpoints (211-02 D4, 211-04 D5). This plan produces the config, a shared helper module, the new assertion spec, the npm script, and the CI wiring (baseline-guarded blocking gate + a `pull_request`-triggered baseline-mint job).

Purpose: convert a one-time human PNG approval into a permanent, no-human, no-LLM, no-API-key deterministic guard that blocks any future CSS regression on the four Phase-211 checkpoint surfaces.

Output: modified `playwright.config.js`, `package.json` (+ lockfile), refactored `admin-visuals.spec.js`, new `e2e/support/admin-visual-helpers.js`, new `e2e/admin-visual-regression-phase211.spec.js`, and updated `.github/workflows/accrue_admin_browser.yml`.

**EXPLICITLY OUT OF SCOPE for this plan (do NOT do these — the orchestrator handles them after a CI baseline round-trip):**
- Generating or committing any baseline PNGs. Baselines are OS/font-stack specific and MUST be minted on Linux CI, NEVER locally on macOS.
- Running `npm run e2e:visual-regression` locally in any form. A first run with no baseline **writes** a macOS baseline (implicit `--update-snapshots` behavior on missing snapshots) — this is the exact hazard to avoid. Do NOT run it, and NEVER pass `--update-snapshots`.
- Part B: flipping 211-02 D4 / 211-04 D5 coverage blocks, editing `211-VALIDATION.md`, deleting `211-UAT.md`, or re-running `/gsd-verify-work`.
- Touching any `accrue/lib` core code, or adding any nav room/route.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
</execution_context>

<context>
# AUTHORITATIVE SPEC — transcribe §1–§6 verbatim for exact config/mask/YAML snippets.
# This plan is a faithful transcription of Part A; do not re-design.
@/Users/jon/.claude/plans/can-u-do-it-humming-seahorse.md

# Source of the helpers to extract + the exact seed sequence and theme-toggle mechanics to reuse.
@/Users/jon/projects/accrue/accrue_admin/e2e/admin-visuals.spec.js

# Files to modify.
@/Users/jon/projects/accrue/accrue_admin/playwright.config.js
@/Users/jon/projects/accrue/accrue_admin/package.json
@/Users/jon/projects/accrue/.github/workflows/accrue_admin_browser.yml

# Grounded selector facts (confirmed at planning time):
# - subscriptions list data_table is NOT selectable (default false, not overridden) → NO leading
#   checkbox column → "Renews / ends" is genuinely the 4th column → td:nth-child(4) is correct.
# - time.ax-timeline-time exists (components/timeline.ex); .ax-body is app-wide so the
#   subscription-detail mask MUST text-filter it (hasText /Renews|Ends|Ended|Campaign started/).
# - route /billing/dev/components exists (router.ex); dev toolbar/command palette hidden via
#   hideCaptureOnlyChrome before every shot.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add screenshot tolerance config, pin Playwright exactly, and extract shared e2e helpers (behavior-preserving)</name>
  <files>accrue_admin/playwright.config.js, accrue_admin/package.json, accrue_admin/package-lock.json, accrue_admin/e2e/support/admin-visual-helpers.js, accrue_admin/e2e/admin-visuals.spec.js</files>
  <action>
Implement approved-plan §1 and §2 exactly.

§1 — playwright.config.js: Extend the existing `expect` object (do NOT drop `timeout: 5_000`) to also carry a `toHaveScreenshot` block with these exact keys/values: `threshold: 0.2`, `maxDiffPixelRatio: 0.01`, `animations: "disabled"`, `caret: "hide"`, `scale: "css"`. Add a top-level `snapshotPathTemplate` key equal to `e2e/__screenshots__/{projectName}/{arg}{ext}`, placed as a sibling of `outputDir`. Leave `use.screenshot: "only-on-failure"` and everything else untouched. Copy the block verbatim from approved plan §1.

§1 — package.json + lockfile: pin `@playwright/test` to an exact version (drop the `^`) so a minor bump cannot invalidate committed baselines. Pin to the version currently resolved in the lockfile (confirmed `1.59.1` at planning time — do NOT downgrade to 1.57.0). Do this via `cd accrue_admin && npm install --save-exact @playwright/test@1.59.1`, which both writes the caret-free spec into package.json and resyncs package-lock.json so `npm ci` keeps passing in CI. Verify no other deps churned unexpectedly in the lock diff.

§2 — Create `accrue_admin/e2e/support/admin-visual-helpers.js` as a CommonJS module (`module.exports = { ... }`). Move the four generic helpers out of `admin-visuals.spec.js` verbatim (behavior-preserving): `reset(request)`, `seed(request, fixture)`, `login(page, target = "/billing")`, and `hideCaptureOnlyChrome(page)`. The module requires `{ expect } = require("@playwright/test")` for the `reset`/`seed` assertions. Do NOT move or export `captureThemes`, `captureBBoxes`, `REGION_SELECTORS`, or `VIEWPORT_ONLY_SURFACES` — those write PNGs / are capture-only and must stay local to `admin-visuals.spec.js`.

§2 — Refactor `accrue_admin/e2e/admin-visuals.spec.js`: delete the four moved local function definitions and instead `const { reset, seed, login, hideCaptureOnlyChrome } = require("./support/admin-visual-helpers");`. Keep `captureThemes`, `captureBBoxes`, the defensive `REGION_SELECTORS` require, and `VIEWPORT_ONLY_SURFACES` exactly where they are (captureThemes still calls the now-imported `hideCaptureOnlyChrome`). This is a pure move — the capture spec's runtime behavior must be identical.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue_admin && npm run e2e:visuals:png-only</automated>
    <automated>cd /Users/jon/projects/accrue/accrue_admin && node -e "const p=require('./package.json'); if(/[\^~><=]/.test(p.devDependencies['@playwright/test'])) { console.error('caret/range still present'); process.exit(1); } console.log('pinned:', p.devDependencies['@playwright/test'])"</automated>
  </verify>
  <done>The capture spec (`e2e:visuals:png-only`) is still green after the helper extraction (behavior-preserving move confirmed); `playwright.config.js` carries the `toHaveScreenshot` tolerance block and the committed `snapshotPathTemplate`; `@playwright/test` is pinned to an exact version with package-lock.json in sync; `admin-visual-helpers.js` exists exporting the four shared helpers and `admin-visuals.spec.js` imports them.</done>
</task>

<task type="auto">
  <name>Task 2: Add the deterministic visual-regression spec and its npm script</name>
  <files>accrue_admin/e2e/admin-visual-regression-phase211.spec.js, accrue_admin/package.json</files>
  <action>
Implement approved-plan §3, §4, and the npm-script half of §5.

Create `accrue_admin/e2e/admin-visual-regression-phase211.spec.js` (CommonJS). Import `{ test, expect } = require("@playwright/test")` and `{ reset, seed, login, hideCaptureOnlyChrome } = require("./support/admin-visual-helpers")`.

Structure (mirror the seed sequence and theme-toggle mechanics from `admin-visuals.spec.js`):
- `test.use({ reducedMotion: "reduce" })`.
- Desktop-only: skip every test unless `testInfo.project.name === "chromium-desktop"` (use `test.skip(({}, testInfo) => testInfo.project.name !== "chromium-desktop", "desktop-only visual baselines")`).
- `test.beforeEach` calls `reset(request)`.
- In the test body, seed the same three fixtures with NO intermediate reset, in this order: `operator-flows`, then `dashboard` (capture the returned object — it carries `subscription_id`), then `edge-states`. This matches the exact merged-fixture sequence the capture spec relies on.
- Assert `toHaveScreenshot` for these 4 surfaces × 2 themes (light first, then dark), naming files `${name}.png` (light) and `${name}-dark.png` (dark) — the same filename convention `captureThemes` uses:
  - `dashboard` → route `/billing` → fullPage
  - `subscriptions` → route `/billing/subscriptions` → fullPage
  - `subscription-detail` → route `/billing/subscriptions/${dash.subscription_id}` → fullPage
  - `component-kitchen` → route `/billing/dev/components` → **viewport-only** (fullPage: false)
- For each surface: `await login(page, route)`, then `await hideCaptureOnlyChrome(page)`, then gate on `await expect(page.locator("#main-content")).toBeVisible()`. For each theme, set it via `await page.evaluate((t) => document.documentElement.setAttribute("data-theme", t), theme)` before the assertion (exactly how `captureThemes` toggles). Call `await expect(page).toHaveScreenshot("<file>.png", { fullPage, animations: "disabled", mask: maskLocators(page, name), maskColor: "#FF00FF" })`.

§4 — Per-surface `maskLocators(page, name)` returning an array of Locators (mask non-deterministic absolute datetimes only; do NOT freeze the clock — freezing would require rewriting shared `test/support/e2e_fixtures.ex`, out of scope):
  - `dashboard` → `[ page.locator("time.ax-timeline-time"), page.locator(".ax-dashboard-audit-summary em") ]` (the audit-summary "Timestamp" `<em>`). Do NOT mask KPI counts — they are deterministic. Confirm the audit-summary `<em>` selector against the rendered dashboard at implement time; if the `<em>` is ambiguous, scope it to the "Timestamp" row within `.ax-dashboard-audit-summary`.
  - `subscriptions` → `[ page.locator("tbody tr td:nth-child(4)") ]`. GROUNDED: the subscriptions `data_table` is not `selectable` (no leading checkbox column), and "Renews / ends" is column 4, so `td:nth-child(4)` is correct — no offset adjustment needed.
  - `subscription-detail` → `[ page.locator("time.ax-timeline-time"), page.locator(".ax-body").filter({ hasText: /Renews|Ends|Ended|Campaign started/ }) ]`. `.ax-body` is app-wide, so the `hasText` filter is mandatory; pin the regex alternation to the actual rendered `Copy.*` strings on the detail page at implement time.
  - `component-kitchen` → `[]` (fully static hardcoded literal timestamps; no mask).

§5 (npm script only) — In `accrue_admin/package.json`, add near the other `e2e:*` scripts, verbatim from approved plan §5:
`"e2e:visual-regression": "playwright test e2e/admin-visual-regression-phase211.spec.js --project=chromium-desktop --workers=1"`

CONSTRAINT — local verification only. Do NOT run `npm run e2e:visual-regression` (a missing-baseline run writes a macOS baseline). Do NOT pass `--update-snapshots`. Limit local checks to parse/list sanity (see verify). If a selector-only mask feels brittle, prefer a slightly broader selector-based mask over touching `accrue_admin/lib` templates — the `data-ax-visual-mask` template fallback mentioned in §4 is OUT OF SCOPE for this plan (confined file set); flag it rather than expanding scope. Mask correctness is ultimately proven when baselines mint on CI (orchestrator step, not here).
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue_admin && node --check e2e/admin-visual-regression-phase211.spec.js</automated>
    <automated>cd /Users/jon/projects/accrue/accrue_admin && node --check e2e/support/admin-visual-helpers.js</automated>
    <automated>cd /Users/jon/projects/accrue/accrue_admin && npx playwright test e2e/admin-visual-regression-phase211.spec.js --project=chromium-desktop --list</automated>
    <automated>cd /Users/jon/projects/accrue/accrue_admin && node -e "const p=require('./package.json'); if(!p.scripts['e2e:visual-regression']) process.exit(1); console.log(p.scripts['e2e:visual-regression'])"</automated>
  </verify>
  <done>`admin-visual-regression-phase211.spec.js` parses (`node --check`) and its test tree enumerates via `playwright test --list` (require of the shared helper resolves; 4 surfaces × 2 themes present, all gated desktop-only); the `e2e:visual-regression` npm script matches §5 verbatim; NO baseline PNGs were written locally and `--update-snapshots` was never invoked.</done>
</task>

<task type="auto">
  <name>Task 3: Wire the baseline-guarded blocking CI gate and the pull_request baseline-mint job</name>
  <files>.github/workflows/accrue_admin_browser.yml</files>
  <action>
Implement approved-plan §5 (CI gate) and §6 (mint job) — transcribe the YAML verbatim from those sections.

§5 — In the existing merge-blocking `browser-uat` job, immediately AFTER the `Run browser UAT` step (`cd accrue_admin && npm run e2e`), insert two steps:
  1. `- name: Check for committed visual baselines` with `id: vrbaseline`. Its `run:` is a shell block: if `ls accrue_admin/e2e/__screenshots__/chromium-desktop/*.png` succeeds (redirect stdout+stderr to /dev/null), append `present=true` to `$GITHUB_OUTPUT`, else append `present=false`.
  2. `- name: Phase 211 visual regression gate` with `if: steps.vrbaseline.outputs.present == 'true'` and `run: cd accrue_admin && npm run e2e:visual-regression`. NO `continue-on-error` — once baselines exist a pixel diff fails the job and blocks merge; before baselines exist the step is skipped (job stays green), so wiring the gate never reds main.
The existing `if: failure()` uploads of `playwright-report` + `test-results` already capture the `-expected/-actual/-diff` triplet — leave them as-is.

§6 — Add a NEW, separate, non-blocking job `visual-baselines-mint` to the same workflow file. It mirrors `browser-uat`'s environment: `runs-on: ubuntu-24.04`, the same `postgres:15` service block, the same `env:` (MIX_ENV/PGUSER/PGPASSWORD/PGHOST/ACCRUE_ADMIN_E2E_PORT), and the same setup steps (checkout → setup-beam OTP 28.0 / Elixir 1.19.5 → `mix local.hex 2.4.2 --force` → setup-node 22 with npm cache → `cd accrue_admin && mix deps.get` → `mix compile --warnings-as-errors` → `npm ci` → `npx playwright install --with-deps chromium`). Its terminal steps:
  - `- name: Mint visual baselines` → `run: cd accrue_admin && npm run e2e:visual-regression -- --update-snapshots` (this is the ONLY place `--update-snapshots` appears, and it runs on Linux CI — the whole point of minting in CI).
  - `- name: Upload minted baselines` → `actions/upload-artifact@v7` with `name: phase211-visual-baselines` and `path: accrue_admin/e2e/__screenshots__` (use `if: always()` so the artifact uploads even if the mint step's own screenshot compare is noisy).
The job triggers off the workflow's existing `on: pull_request` (and `workflow_dispatch` for manual re-mints once merged). It is non-blocking because it is a separate, non-required job that produces an artifact — it does not gate `browser-uat`.

Scope guards: do NOT touch `ci.yml`'s `playwright-e2e` job (that is `accrue_host`), and do NOT rely on / modify the parked `admin-ui-ratchet-guardrails` job.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue && ruby -ryaml -e "YAML.load_file('.github/workflows/accrue_admin_browser.yml'); puts 'yaml-ok'"</automated>
    <automated>cd /Users/jon/projects/accrue && grep -q 'id: vrbaseline' .github/workflows/accrue_admin_browser.yml && grep -q "steps.vrbaseline.outputs.present == 'true'" .github/workflows/accrue_admin_browser.yml && grep -q 'Phase 211 visual regression gate' .github/workflows/accrue_admin_browser.yml && grep -q 'visual-baselines-mint' .github/workflows/accrue_admin_browser.yml && grep -q 'phase211-visual-baselines' .github/workflows/accrue_admin_browser.yml && grep -q 'update-snapshots' .github/workflows/accrue_admin_browser.yml && echo tokens-ok</automated>
  </verify>
  <done>The workflow file is valid YAML; the `browser-uat` job carries the `vrbaseline` presence check and the `if`-guarded `Phase 211 visual regression gate` step (no `continue-on-error`) right after `Run browser UAT`; a separate non-blocking `visual-baselines-mint` job exists that mints on Linux with `--update-snapshots` and uploads artifact `phase211-visual-baselines`; `ci.yml` and the parked ratchet job are untouched.</done>
</task>

</tasks>

<threat_model>
This plan adds only dev/test tooling and CI wiring — no runtime code, no new attack surface in the shipped library.

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-rjo-01 | Tampering | `visual-baselines-mint` job on `pull_request` (public repo, fork PRs) | low | accept | The gate and mint jobs require NO secrets and NO `ANTHROPIC_API_KEY` — the pixel-diff is fully deterministic with no LLM on the path. Nothing sensitive is exposed to fork PR code. |
| T-rjo-02 | Elevation | Gate silently non-blocking forever | low | mitigate | The `if: steps.vrbaseline.outputs.present == 'true'` guard is presence-based, not `continue-on-error`; once Linux baselines are committed (orchestrator step, out of this plan) the gate is fully blocking with no override. |
</threat_model>

<verification>
- `cd accrue_admin && npm run e2e:visuals:png-only` stays green after the helper extraction (behavior-preserving).
- `node --check` + `playwright test --list` confirm the new spec parses and enumerates 4 surfaces × 2 themes (desktop-only), without running assertions or writing any baseline.
- `@playwright/test` is caret-free in package.json with package-lock.json in sync.
- The workflow YAML is valid and contains the guarded blocking gate + the mint job with `--update-snapshots` + artifact upload.
- Scope: `git diff --stat -- accrue/lib` is empty; no router/nav changes; edits confined to the 7 declared files.
- NO baseline PNGs were created locally; `--update-snapshots` appears ONLY inside the CI mint job.
</verification>

<success_criteria>
- Part A of the approved plan (§1–§6) is implemented exactly, matching the config values, mask strategy, npm script, and CI YAML.
- The capture spec still passes; the new spec parses and lists cleanly; the CI file is valid and structurally complete.
- Part B and any baseline generation/commit are left untouched for the orchestrator's post-CI-round-trip steps.
</success_criteria>

<output>
Create `.planning/quick/260729-rjo-add-a-deterministic-playwright-visual-re/260729-rjo-SUMMARY.md` when done, noting: files changed, the confirmed `td:nth-child(4)` mask grounding, and an explicit statement that no baseline PNGs were minted locally (baselines are pending the CI mint job).
</output>