# Phase 179: F — Screenshot-Driven Visual QA Loop & Sign-off - Research

**Researched:** 2026-06-04
**Domain:** Playwright screenshot sweep / LLM vision-scoring / axe accessibility / motion trace / milestone sign-off
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **Sweep scope:** drive from Phase 178 STATE-MATRIX.md — all ~20 screens + detail pages + seeded states across {desktop 1280×800, mobile 360px} × {light, dark} = 4 cells per screen.
- **LLM scoring:** Node script `accrue_admin/e2e/score-visuals.mjs` — reads PNGs, sends to vision LLM with 10-dim rubric, emits structured JSON findings schema `{screen, viewport, theme, dimension, score 0–3, defect, suggested_fix}`.
- **Remediation cap:** ~3 rounds; Phase 176 already confirmed all 21 screens ≥2 so minimal fixes expected.
- **Executability boundary (user-accepted):** this phase BUILDS harness + scoring script + scorecard scaffold + documented run procedure, and runs what is runnable autonomously (axe, screenshot capture if server is up). Vision-scoring photographic sign-off run is the **consolidated human/CI gate** for deferred 175–178 visual UATs. Do NOT claim a full autonomous vision run.
- **No new product screens/features** — pure QA tooling + evidence.
- **axe both themes:** extend `admin-a11y.spec.js` to full inventory + mobile + seeded edge states; assert 0 critical/serious violations.
- **Motion trace:** add Playwright trace/video capture for motion surfaces (drawer / command palette / dropdown / nav-collapse) — needed because static PNGs can't verify animation.
- **SIGN-OFF.md:** aggregate 176 rubric (21/21 ≥2) + 177 motion + 178 state coverage + axe both themes + screenshot evidence as milestone "done" proof.
- **CSS architecture:** custom `ax-*` BEM-adjacent CSS + tokens. No Tailwind migration.
- **No regressions:** 262 admin tests + host tests must stay green.

### Claude's Discretion

- Exact Playwright projects/viewport-loop structure for the 4 cells; whether mobile is a separate project or an in-test loop.
- The scoring script's exact CLI/API shape (which vision model, how PNGs are batched) — provided the findings JSON schema is honored and an API key is the only missing runtime input.
- The exact set of seeded states swept per screen (baseline always; edge states per the matrix where cheap).
- Whether the motion trace is a dedicated spec or a flag on the visuals spec.
- The SIGN-OFF.md exact layout, as long as it aggregates the four prior phases' evidence + axe + screenshots into one milestone "done" proof.

### Deferred Ideas (OUT OF SCOPE)

- The actual vision-LLM photographic sign-off run (capture 80+ shots, score, remediate, human-review).
- Any product feature work.
- Re-doing the rubric/motion/seed work from phases 174–178.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QA-01 | Playwright screenshot harness sweeps the full screen inventory (all ~20 screens incl. detail pages) across {desktop, mobile} × {light, dark} | Playwright config already has 2 projects (chromium-desktop + chromium-mobile); spec already namespaces output by `testInfo.project.name`; sweep needs 21-screen list from STATE-MATRIX |
| QA-02 | An LLM-analysis step scores each screenshot against the 10-dimension rubric and emits structured findings (screen, dimension, score, defect, suggested fix) | `@anthropic-ai/sdk` 0.100.1 on npm (Anthropic official); vision via messages API with base64 image blocks; no new runtime deps if fetch used directly |
| QA-03 | Final scorecard shows every dimension ≥2 across all four matrix cells with before/after evidence, and axe passes in both light and dark themes | 176-SCORECARD.md provides before-scores (21/21 ≥2 after waves); axe spec needs full inventory extension; SIGN-OFF.md scaffold to produce |
</phase_requirements>

---

## Summary

Phase 179 is a **tooling-build phase**, not a feature phase. Its job is to extend the already-working Playwright harness to sweep all 21 screens across 4 matrix cells, write the LLM vision-scoring script that a human/CI operator runs with an API key, extend axe to the full inventory, capture a motion trace for the Phase 177 deferred UAT, and produce the SIGN-OFF.md that closes the v1.51 milestone. No new admin UI screens are built.

The most important codebase discovery is that **the Playwright config already defines both `chromium-desktop` (1280×900) and `chromium-mobile` (Pixel 5, 393×727) projects** — the 2-project / 4-cell sweep structure is already there. The existing `admin-visuals.spec.js` already namespaces output to `test-results/admin-visuals/${project}` using `testInfo.project.name`. The primary work is: (a) expand the `shots[]` array from 12 entries to 21 entries using the seeded IDs the fixtures return, (b) write `score-visuals.mjs`, (c) extend `admin-a11y.spec.js` similarly, (d) add a motion-trace spec, and (e) write the SIGN-OFF.md scaffold.

The scoring script requires `@anthropic-ai/sdk` 0.100.1 — this is Anthropic's own npm package, verified on the npm registry, no postinstall script, safe to add as a `devDependency`. The script must no-op gracefully when `ANTHROPIC_API_KEY` is absent so CI without the key does not fail the build. The 176-SCORECARD.md "after-scores" table (21/21 ≥2, all waves complete) is the direct source for the SIGN-OFF's "before" column.

**Primary recommendation:** Expand `admin-visuals.spec.js` to 21 screens using the STATE-MATRIX fixture map, use the `chromium-mobile` project that already exists, write `score-visuals.mjs` with the `@anthropic-ai/sdk`, gate on `ANTHROPIC_API_KEY` env var, and scaffold SIGN-OFF.md with evidence placeholders for the photographic gate to fill.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Screenshot sweep (4-cell inventory) | E2E test tooling | — | Playwright runs against the live server; screenshots are test artifacts, not app code |
| Mobile viewport capture | E2E test tooling | — | Playwright `chromium-mobile` project (Pixel 5) already in config; no app change needed |
| Light/dark theme toggle during capture | Browser / Client | E2E test tooling | `data-theme` attr set via `page.evaluate` — app reads it; test drives it |
| axe accessibility sweep | E2E test tooling | — | `@axe-core/playwright` already installed; extend surface list |
| Motion trace capture | E2E test tooling | — | Playwright `trace` / `recordVideo` project option; dedicated spec |
| LLM vision-scoring script | Node CLI (dev tooling) | — | Runs outside the test suite; reads PNGs from test-results/; calls Anthropic API |
| Remediation loop | Developer workflow | — | Human interprets findings JSON → edits CSS → re-shoots; no automation needed |
| SIGN-OFF.md | Planning artifact | — | Markdown document aggregating evidence; consumed by milestone audit |
| Seed/login endpoints | Backend / API (test-only) | — | `/__e2e__/seed/<fixture>` + `/__e2e__/login` are E2E plug routes (MIX_ENV=test) |

---

## Standard Stack

### Core (no new packages beyond one dev dep)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@playwright/test` | 1.60.0 (npm) / 1.59.1 (installed) | Screenshot capture, axe sweep, motion trace | Already installed; powers all existing e2e specs |
| `@axe-core/playwright` | 4.11.3 (npm, installed) | Automated accessibility scan | Already installed; powers `admin-a11y.spec.js` |
| `@anthropic-ai/sdk` | 0.100.1 | Vision-scoring script — Anthropic messages API with image blocks | Official Anthropic npm package; no postinstall; integrates natively with Claude vision |

### No other new packages are needed.

The scoring script uses Node's built-in `fs`, `path`, and the SDK's `messages.create` API. No additional HTTP client, image-processing, or CLI framework is required.

**Installation (devDependency, `accrue_admin` only):**
```bash
cd accrue_admin && npm install --save-dev @anthropic-ai/sdk
```

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `@anthropic-ai/sdk` | Raw `fetch` to `api.anthropic.com/v1/messages` | `fetch` works but requires hand-rolling auth headers, retry, and error handling that the SDK provides; SDK adds no new transitive deps in a dev-only context |
| `claude-3-7-sonnet` vision model | `claude-opus-4-*` | Sonnet is faster/cheaper for automated sweep scoring; Opus for deep review of borderline cases |
| Playwright `recordVideo` | Playwright `trace` | Traces (zip with screenshots + actions) are richer for async debugging; video is larger and sufficient for pure visual review. Either works; motion trace (ZIP) is preferred for its network timeline data |

---

## Package Legitimacy Audit

> slopcheck is only available in Python mode and erroneously flags npm packages as "pypi missing". The audit below uses npm registry verification directly.

| Package | Registry | Age | Downloads | Source Repo | Verification | Disposition |
|---------|----------|-----|-----------|-------------|--------------|-------------|
| `@anthropic-ai/sdk` | npm | Active | High (official SDK) | github.com/anthropics/anthropic-sdk-node | `npm view` shows `"author": "Anthropic <support@anthropic.com>"`, version 0.100.1, no postinstall script [VERIFIED: npm registry + anthropic.com/claude] | Approved |
| `@playwright/test` | npm | Active | Very high | github.com/microsoft/playwright | `npm view` shows `"author": "Microsoft Corporation"`, 1.60.0 [VERIFIED: npm registry + playwright.dev] | Already installed |
| `@axe-core/playwright` | npm | Active | High | github.com/dequelabs/axe-core-npm | version 4.11.3 [VERIFIED: npm registry + deque labs] | Already installed |

**Packages removed due to slopcheck verdict:** none (slopcheck ran in Python mode — npm packages were verified directly via `npm view`)
**Packages flagged as suspicious:** none

---

## Architecture Patterns

### System Architecture Diagram

```
[Test operator / CI]
     |
     v (npm run e2e:visuals:png-only)
[Playwright test runner]
     |--- chromium-desktop (1280×900) ---+
     |--- chromium-mobile (Pixel 5 393×727) ---+
          |
          v (webServer autostart: mix accrue_admin.e2e.server)
     [AccrueAdmin E2E Server (MIX_ENV=test)]
          |--- POST /__e2e__/reset
          |--- POST /__e2e__/seed/<fixture> ---> [E2E Fixtures (Ecto/TestRepo)] ---> [PostgreSQL test DB]
          |--- GET  /__e2e__/login?to=<path>
          |--- GET  /billing/<screen-path>  ---> [LiveView screens]
          |
          v (page.screenshot / fullPage: true)
     [test-results/admin-visuals/<project>/<screen>[-dark].png]
          |
          v (npm run score-visuals or node e2e/score-visuals.mjs)
     [score-visuals.mjs] ---(if ANTHROPIC_API_KEY set)---> [Anthropic Messages API (claude-3-7-sonnet)]
          |
          v
     [findings.json] ---> [developer remediates] ---> [re-shoot] ---> [re-score]
          |
          v (human/CI photographic gate)
     [SIGN-OFF.md scorecard] <--- aggregates 176/177/178 evidence + axe + screenshot findings
```

### Recommended Project Structure

No new directories. All additions are in existing locations:

```
accrue_admin/
├── e2e/
│   ├── admin-visuals.spec.js      # EXTEND: 12 → 21 screens, uses both projects already
│   ├── admin-a11y.spec.js         # EXTEND: 12 → 21 screens + mobile + edge states
│   ├── admin-motion-trace.spec.js # NEW: traces motion surfaces (drawer, palette, dropdown)
│   └── score-visuals.mjs          # NEW: LLM vision-scoring script
├── package.json                   # ADD @anthropic-ai/sdk devDep + score-visuals script
└── playwright.config.js           # NO CHANGE: chromium-desktop + chromium-mobile already present
.planning/phases/179-.../
└── SIGN-OFF.md                    # NEW: milestone done-proof scaffold
```

### Pattern 1: Expanded Shots Array (admin-visuals.spec.js)

**What:** Replace the 12-entry `shots[]` with a 21-entry array derived from the STATE-MATRIX, using IDs returned by multiple fixture calls.

**When to use:** Always — this is the core sweep extension.

**Key discovery:** The existing spec calls only `seed("operator-flows")` which returns `{charge_id, source_event_id, single_webhook_id, bulk_webhook_id}`. To sweep all 21 screens, the extended spec must call multiple fixtures and merge their IDs:

```javascript
// Source: codebase — accrue_admin/e2e/admin-visuals.spec.js pattern + e2e_plug.ex fixture map
async function seedAll(request) {
  const opFlows    = await seed(request, "operator-flows");
  // operator-flows returns: { charge_id, source_event_id, single_webhook_id, bulk_webhook_id }
  const dashboard  = await seed(request, "dashboard");
  // dashboard returns: { customer_id, subscription_id, event_id }
  const edgeStates = await seed(request, "edge-states");
  // edge-states returns: { at_risk_sub_id, canceling_sub_id, jpy_invoice_id, jpy_charge_id,
  //                        dunning_customer_id, long_name_customer_id, coupon_id,
  //                        promo_code_id, connect_account_id }
  return { ...opFlows, ...dashboard, ...edgeStates };
}
```

**Important:** `reset()` must be called only ONCE (in `beforeEach`) and then all seed fixtures called WITHOUT intermediate resets — fixtures use `System.unique_integer` processor IDs so they never collide.

**The 21 screens + their seed requirements:**

| Screen | Path | Fixture IDs needed |
|--------|------|--------------------|
| dashboard | `/billing` | dashboard (customer_id, subscription_id) |
| customers | `/billing/customers` | operator-flows or dashboard |
| customer-detail | `/billing/customers/:customer_id` | dashboard.customer_id |
| subscriptions | `/billing/subscriptions` | operator-flows or dashboard |
| subscription-detail | `/billing/subscriptions/:subscription_id` | dashboard.subscription_id |
| invoices | `/billing/invoices` | dashboard |
| invoice-detail | `/billing/invoices/:jpy_invoice_id` | edge-states.jpy_invoice_id |
| charges | `/billing/charges` | operator-flows.charge_id |
| charge-detail | `/billing/charges/:charge_id` | operator-flows.charge_id |
| coupons | `/billing/coupons` | edge-states.coupon_id |
| coupon-detail | `/billing/coupons/:coupon_id` | edge-states.coupon_id |
| promotion-codes | `/billing/promotion-codes` | edge-states.promo_code_id |
| promo-code-detail | `/billing/promotion-codes/:promo_code_id` | edge-states.promo_code_id |
| connect | `/billing/connect` | edge-states.connect_account_id |
| connect-detail | `/billing/connect/:connect_account_id` | edge-states.connect_account_id |
| events | `/billing/events` | operator-flows.source_event_id |
| event-detail | `/billing/events/:source_event_id` | operator-flows.source_event_id |
| webhooks | `/billing/webhooks` | operator-flows.single_webhook_id |
| webhook-detail | `/billing/webhooks/:single_webhook_id` | operator-flows.single_webhook_id |
| recovery | `/billing/analytics/recovery` | edge-states |
| campaign-detail | `/billing/analytics/recovery/subscriptions/:at_risk_sub_id` | edge-states.at_risk_sub_id |

**Note on coupons/promo-codes:** The `edge-states` fixture inserts one coupon and one promo code so list screens will be populated. The `host:showcase.exs` note in STATE-MATRIX refers to dev-only seeds; for E2E test context `edge-states` is sufficient.

### Pattern 2: Mobile Viewport — No Config Change Needed

**What:** The `chromium-mobile` project (Pixel 5, 393×727) is already declared in `playwright.config.js`. The `e2e:visuals:png-only` npm script runs Playwright against both projects by default (no `--project` filter). Each project name is passed via `testInfo.project.name` and used as the subfolder in `test-results/admin-visuals/<project>/`.

**Discovery:** The spec already has `const project = testInfo.project.name;` and `const dir = \`test-results/admin-visuals/${project}\``. Running `npm run e2e:visuals:png-only` already produces `test-results/admin-visuals/chromium-desktop/` AND `test-results/admin-visuals/chromium-mobile/` today for the 12 existing screens. The "mobile viewport" part of QA-01 is **already scaffolded** — it just needs the screen list expanded.

**Pixel 5 viewport is 393×727, not 360×800.** The design target is "usable @360px" — 393px satisfies the intent. No viewport override is needed in the spec.

### Pattern 3: LLM Scoring Script (score-visuals.mjs)

**What:** A standalone ESM script that reads PNG files from `test-results/admin-visuals/`, sends each to the Anthropic messages API with the rubric prompt, parses structured JSON findings.

**Key design constraints:**
- **No-op when no API key:** wrap the main logic in `if (!process.env.ANTHROPIC_API_KEY) { console.log('ANTHROPIC_API_KEY not set — skipping'); process.exit(0); }`
- **Base64 encode each PNG** for the Anthropic `image` content block.
- **Batch by screen** (4 PNGs per screen = 4 cells); one API call per screen to keep context tight.
- **Emit a findings NDJSON** (`findings.ndjson`) and a summary CSV/markdown.

```javascript
// Source: @anthropic-ai/sdk documentation (messages API with vision)
import Anthropic from "@anthropic-ai/sdk";
import fs from "fs";
import path from "path";

const client = new Anthropic(); // reads ANTHROPIC_API_KEY from env
// ...

const response = await client.messages.create({
  model: "claude-sonnet-4-5",  // or claude-opus-4-5 for deeper review
  max_tokens: 1024,
  messages: [{
    role: "user",
    content: [
      { type: "image", source: { type: "base64", media_type: "image/png", data: b64 } },
      { type: "text", text: RUBRIC_PROMPT }
    ]
  }]
});
```

**Findings JSON schema (locked in CONTEXT.md):**
```json
{
  "screen": "coupon-detail",
  "viewport": "chromium-mobile",
  "theme": "dark",
  "dimension": 5,
  "dimension_name": "responsive/mobile-first",
  "score": 2,
  "defect": null,
  "suggested_fix": null
}
```

**Rubric prompt template (from design source §6):**
The prompt must include all 10 dimensions with their scoring criteria (0–3, ≥2 = pass):
① token compliance ② visual hierarchy ③ spacing rhythm ④ state coverage ⑤ responsive/mobile-first ⑥ contrast ⑦ focus & semantics ⑧ brand expression ⑨ motion ⑩ reuse/DRY

**npm script addition:**
```json
"score-visuals": "node e2e/score-visuals.mjs"
```

### Pattern 4: axe Extension (admin-a11y.spec.js)

**What:** The existing spec scans 12 surfaces in light+dark. Extend to all 21 surfaces + add edge-state surfaces (seeded dunning/at-risk badges in dark).

**Key pattern — the existing spec is well-structured for extension:**
- `reset()` in `beforeEach`
- single seed call at test start
- `surfaces[]` array iterates screens
- `scan(page, theme)` helper handles the kill-transitions + axe sequence

**Extension changes:**
1. Add `seed("edge-states")` call alongside `seed("operator-flows")` and merge IDs.
2. Expand `surfaces[]` from 12 to 21 entries using merged IDs (same table as visuals sweep).
3. The `chromium-mobile` project is already in the config — when `npm run e2e:a11y` runs, it uses both projects. No change to the spec for mobile; Playwright drives the viewport.
4. Add the note that the axe spec already calls `page.emulateMedia({ reducedMotion: "reduce" })` to stabilize theme-transition colours — this is correct and must be retained.

### Pattern 5: Motion Trace Spec (admin-motion-trace.spec.js)

**What:** A dedicated spec that captures Playwright traces (`.zip` files containing screenshots + action timeline) for the 4 motion surfaces: drawer, command palette, dropdown, nav-collapse.

**Playwright trace config options:**
- `trace: "on"` in the project `use` block forces trace recording for all tests.
- Or, within a test: `await context.tracing.start({ screenshots: true, snapshots: true })` / `await context.tracing.stop({ path: 'trace.zip' })`.
- The existing config uses `trace: "retain-on-failure"` globally — the motion spec should override to `"on"` for its context to always capture.

**Recommended approach:** A dedicated `admin-motion-trace.spec.js` that:
1. Uses `test.use({ trace: "on" })` at the suite level.
2. Navigates to the surfaces that show the animated elements.
3. Triggers each motion surface (open drawer, open palette, open dropdown, collapse nav group).
4. `expect` the element to be visible; traces are captured automatically.
5. Output: `test-results/<test-name>/trace.zip` — reviewable with `npx playwright show-trace`.

**Motion surfaces to cover (from Phase 177 spec):**
- Drawer: `/billing/webhooks/:single_webhook_id` → open the webhook actions drawer
- Command palette: any page → trigger `data-role="command-palette-trigger"` click
- Dropdown: any page → click the "More ▾" button in customer-360 or a nav chevron
- Nav collapse: sidebar collapse buttons for Recovery/Developer/Catalog groups

**Trace artifact review:** `npx playwright show-trace test-results/admin-motion-trace-*/trace.zip` opens the Playwright Trace Viewer (browser UI) — reviewable without a server.

### Pattern 6: SIGN-OFF.md Scaffold

**What:** A milestone "done" proof document aggregating all five prior phases + axe + screenshot evidence.

**Minimum sections:**
1. **Rubric scorecard** — 21 rows × 10 dims × 4 cells, "before" seeded from 176-SCORECARD after-scores, "after" = photographic-pass results.
2. **Axe status** — light and dark, both themes, 0 violations (or findings list).
3. **Motion confirmation** — trace review status per surface; reduced-motion spec pass.
4. **State coverage** — STATE-MATRIX gap-closure status (178 evidence link).
5. **Design-system completeness** — token compliance (174 evidence link).
6. **IA persona paths** — persona-path check (175 evidence link).
7. **Screenshot evidence** — directory listing of `test-results/admin-visuals/<project>/` (gitignored; referenced not embedded).
8. **Human/CI gate status** — placeholder: "Vision-scoring photographic run: [PENDING — run `npm run score-visuals` with ANTHROPIC_API_KEY + live server]".

### Anti-Patterns to Avoid

- **Resetting between fixture calls:** `reset()` in `beforeEach` is correct once; calling `reset()` between `seed("operator-flows")` and `seed("edge-states")` within the same test wipes the first fixture. The fixtures use `System.unique_integer` processor IDs — they are safe to accumulate without reset.
- **Committing PNGs:** `test-results/` is already in the root `.gitignore`. Never add PNG output to git. Only `findings.ndjson` (if small) or a scorecard summary (markdown) should be committed.
- **Claiming the vision run ran when it didn't:** The scoring script must log clearly when `ANTHROPIC_API_KEY` is absent. The SIGN-OFF.md placeholder must be honest that the photographic gate is pending.
- **Using `trace: "on"` globally:** This will bloat all test output. The motion trace should be confined to `admin-motion-trace.spec.js` via `test.use({ trace: "on" })`.
- **Using a viewport loop inside the test instead of Playwright projects:** The `chromium-mobile` project already exists in `playwright.config.js`. A viewport loop inside the test body duplicates the project mechanism and produces confusing output. Use the existing project structure.
- **Batching all 84 PNGs (21 screens × 4 cells) in one API call:** The Anthropic API has a 20 image block limit per request as of training knowledge. Score per-screen (4 images) or per-cell (1 image). Per-screen (4 images = all 4 cells for one screen) is the cleanest batch unit.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-viewport sweep | Viewport loop inside test body | Playwright projects (already in config) | Projects are the idiomatic Playwright mechanism; test.use() per-project is the right seam |
| Vision API HTTP calls | Raw fetch + base64 construction | `@anthropic-ai/sdk` | SDK handles auth, retries, error classification; zero runtime deps in a dev-only context |
| Accessibility scanning | Custom color-contrast math | `@axe-core/playwright` (already installed) | axe handles WCAG 2AA color-contrast, ARIA, semantics — hand-rolled contrast math misses many edge cases |
| Trace playback UI | Custom HTML viewer | `npx playwright show-trace <file>` | Playwright's built-in Trace Viewer is the standard tool; zero setup required |
| PNG file discovery | Custom glob | Node `fs.readdirSync` or `glob` (built-in Node 22) | `fs.readdirSync` + filter on `.png` is 3 lines; no extra package needed |

**Key insight:** This phase builds on already-installed tooling. The only genuine addition is `@anthropic-ai/sdk` as a dev dependency, which brings zero transitive runtime deps.

---

## Common Pitfalls

### Pitfall 1: `chromium-mobile` Project Already Exists — Don't Duplicate

**What goes wrong:** Adding a second mobile viewport approach (in-test `page.setViewportSize`) when the `chromium-mobile` project in `playwright.config.js` already handles it. Produces duplicate screenshots with confusing naming.

**Why it happens:** The research doc mentions "mobile 360px" and one might reach for `page.setViewportSize(360, 800)` inside the test. But the Playwright config already has `chromium-mobile: Pixel 5 (393×727)`.

**How to avoid:** Use `testInfo.project.name` as the directory key — already in the spec. The existing project structure **is** the 4-cell sweep. Just expand the shots array.

**Warning signs:** Two separate viewport capture patterns in the same spec file.

### Pitfall 2: Multiple Fixtures Accumulate Without Reset (Correct) But Can Overflow

**What goes wrong:** Calling `seed("overflow")` after `seed("operator-flows")` + `seed("edge-states")` creates 26+ customers in addition to the operator-flows/edge-states entities. This is fine for overflow screens but makes list-screen screenshots very long. For the basic populated sweep, omit the overflow fixture.

**Why it happens:** STATE-MATRIX documents overflow separately — it's for a specific overflow-state screenshot, not the baseline pass.

**How to avoid:** The baseline sweep uses `operator-flows + dashboard + edge-states` only. If overflow screenshots are desired, seed overflow in a separate test with its own reset.

### Pitfall 3: PNG Base64 Size Limits

**What goes wrong:** `fullPage: true` screenshots of long list screens (e.g. invoices with 26+ rows from overflow fixture) can exceed API payload limits.

**Why it happens:** Full-page screenshots of dense list screens can be 5–15 MB. Base64 encoding adds ~33%.

**How to avoid:** For the scoring sweep, use the baseline fixture (not overflow). Optionally add a `clip` option or resize screenshots before encoding. The `fullPage: true` is correct for complete visual capture but the scoring script should handle large images gracefully (e.g. warn and skip if > 5 MB base64).

### Pitfall 4: Theme Toggle Race Condition in axe Scans

**What goes wrong:** axe reads mid-transition blended colors (false-grey), reporting false contrast failures.

**Why it happens:** The admin CSS has `transition: background var(--ax-transition-theme)` on many surfaces. Toggling `data-theme` mid-transition causes axe to snapshot blended colors.

**How to avoid:** The existing `admin-a11y.spec.js` already handles this correctly: `page.emulateMedia({ reducedMotion: "reduce" })` + `page.waitForTimeout(50)` in the `scan()` helper. The extended spec must retain this pattern — do not change the scan helper.

### Pitfall 5: score-visuals.mjs Exits Non-Zero Without API Key

**What goes wrong:** CI runs `score-visuals` as part of a gate; without `ANTHROPIC_API_KEY`, the script throws and fails the build.

**Why it happens:** Default `@anthropic-ai/sdk` behaviour — `new Anthropic()` reads `ANTHROPIC_API_KEY`; if missing, constructor throws or `messages.create` throws.

**How to avoid:** Check for the key before constructing the client:
```javascript
if (!process.env.ANTHROPIC_API_KEY) {
  console.log("[score-visuals] ANTHROPIC_API_KEY not set — skipping (human/CI gate only)");
  process.exit(0);
}
const client = new Anthropic();
```

### Pitfall 6: SIGN-OFF.md Claims a Completed Vision Run That Didn't Happen

**What goes wrong:** The scaffold is written as if the photographic run completed, misleading the milestone audit.

**Why it happens:** Optimistic writing.

**How to avoid:** The SIGN-OFF.md scaffold must use explicit `[PENDING: ...]` placeholders in every section that requires the vision-scoring run. The audit reader must be able to distinguish "scaffold exists" from "run completed".

---

## Code Examples

### Admin Visuals Spec — Expanded Seed + Shots Pattern

```javascript
// Source: codebase — accrue_admin/e2e/admin-visuals.spec.js + e2e_plug.ex fixture contracts
test("captures every primary admin surface in light and dark", async ({ page, request }, testInfo) => {
  // Seed all three fixtures without intermediate resets.
  // operator-flows returns: { charge_id, source_event_id, single_webhook_id, bulk_webhook_id }
  // dashboard returns:      { customer_id, subscription_id, event_id }
  // edge-states returns:    { at_risk_sub_id, canceling_sub_id, jpy_invoice_id, jpy_charge_id,
  //                           dunning_customer_id, long_name_customer_id, coupon_id,
  //                           promo_code_id, connect_account_id }
  const opFlows    = await seed(request, "operator-flows");
  const dash       = await seed(request, "dashboard");
  const edge       = await seed(request, "edge-states");
  const project    = testInfo.project.name;

  const shots = [
    ["dashboard",          "/billing"],
    ["customers",          "/billing/customers"],
    ["customer-detail",    `/billing/customers/${dash.customer_id}`],
    ["subscriptions",      "/billing/subscriptions"],
    ["subscription-detail",`/billing/subscriptions/${dash.subscription_id}`],
    ["invoices",           "/billing/invoices"],
    ["invoice-detail",     `/billing/invoices/${edge.jpy_invoice_id}`],
    ["charges",            "/billing/charges"],
    ["charge-detail",      `/billing/charges/${opFlows.charge_id}`],
    ["coupons",            "/billing/coupons"],
    ["coupon-detail",      `/billing/coupons/${edge.coupon_id}`],
    ["promotion-codes",    "/billing/promotion-codes"],
    ["promo-code-detail",  `/billing/promotion-codes/${edge.promo_code_id}`],
    ["connect",            "/billing/connect"],
    ["connect-detail",     `/billing/connect/${edge.connect_account_id}`],
    ["events",             "/billing/events"],
    ["event-detail",       `/billing/events/${opFlows.source_event_id}`],
    ["webhooks",           "/billing/webhooks"],
    ["webhook-detail",     `/billing/webhooks/${opFlows.single_webhook_id}`],
    ["recovery",           "/billing/analytics/recovery"],
    ["campaign-detail",    `/billing/analytics/recovery/subscriptions/${edge.at_risk_sub_id}`],
  ];

  for (const [name, path] of shots) {
    await login(page, path);
    await captureThemes(page, name, project);
  }
});
```

### Motion Trace Spec Pattern

```javascript
// Source: Playwright docs — context.tracing API
const { test, expect } = require("@playwright/test");

test.use({ trace: "on" }); // force trace for every test in this suite

test("motion trace — drawer open/close on webhook-detail", async ({ page, request }) => {
  await reset(request);
  const data = await seed(request, "operator-flows");
  await login(page, `/billing/webhooks/${data.single_webhook_id}`);
  await expect(page.locator("#main-content")).toBeVisible();

  // Trigger drawer open — adjust selector to match actual action button
  await page.click('[data-role="action-drawer-trigger"]');
  await expect(page.locator(".ax-drawer")).toBeVisible();
  // Trace captures the transition frames
  await page.click('[data-role="action-drawer-close"]');
});
// Trace is saved to test-results/<test-name>/trace.zip
// Review with: npx playwright show-trace test-results/.../trace.zip
```

### score-visuals.mjs — Skeleton

```javascript
// Source: @anthropic-ai/sdk npm package (Anthropic official)
import Anthropic from "@anthropic-ai/sdk";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

if (!process.env.ANTHROPIC_API_KEY) {
  console.log("[score-visuals] ANTHROPIC_API_KEY not set — skipping (human/CI gate only)");
  process.exit(0);
}

const client = new Anthropic();
const RESULTS_DIR = path.join(__dirname, "../test-results/admin-visuals");

const RUBRIC_PROMPT = `
You are scoring a screenshot of an Elixir/Phoenix admin billing UI against a 10-dimension rubric.
Score each dimension 0–3 (pass = ≥2). Reply with a JSON array of findings, one per dimension.

Schema per finding:
{ "screen": "<name>", "viewport": "<project>", "theme": "<light|dark>",
  "dimension": <1-10>, "dimension_name": "<name>",
  "score": <0-3>, "defect": "<string or null>", "suggested_fix": "<string or null>" }

Dimensions:
1. token-compliance: no literal hex/px inline styles
2. visual-hierarchy: eyebrow → heading → body tiers present
3. spacing-rhythm: consistent spacing, no arbitrary gaps
4. state-coverage: empty/error/populated states handled
5. responsive-mobile-first: usable at this viewport, no overflow
6. contrast: WCAG AA color contrast, no color-only status
7. focus-semantics: semantic HTML, ARIA labels, dl/dt/dd for key-value
8. brand-expression: brand fonts, tabular numerals, appropriate display type
9. motion: token-based, functional (N/A for static screenshot — score 2 if no visible jank)
10. reuse-dry: consistent component patterns, no hand-rolled duplicates
`;

// ... (glob PNGs, group by screen, batch 4 cells per screen, call API, emit ndjson)
```

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Playwright 1.59.1 (installed) + ExUnit (Elixir) |
| Config file | `accrue_admin/playwright.config.js` |
| Quick run command (axe only) | `cd accrue_admin && npm run e2e:a11y` |
| Screenshot capture command | `cd accrue_admin && npm run e2e:visuals:png-only` |
| Full Elixir suite | `cd accrue_admin && mix test --seed 0` |
| Motion trace | `cd accrue_admin && npx playwright test e2e/admin-motion-trace.spec.js` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Runnable Without API Key |
|--------|----------|-----------|-------------------|--------------------------|
| QA-01 | Screenshot sweep: 21 screens × 4 cells (desktop+mobile × light+dark) | e2e / screenshot | `npm run e2e:visuals:png-only` (needs live server) | Yes — no API key needed for capture |
| QA-02 | LLM scores each PNG against 10-dim rubric, emits structured findings JSON | e2e / manual gate | `npm run score-visuals` (needs ANTHROPIC_API_KEY + PNGs) | No — requires key + prior capture run |
| QA-03a | axe 0 critical/serious violations in light + dark, all 21 screens | e2e / accessibility | `npm run e2e:a11y` (needs live server) | Yes |
| QA-03b | Final scorecard ≥2 all dims | manual / sign-off | Human review of findings.ndjson → SIGN-OFF.md | Human gate |
| MOT (deferred 177) | Motion surfaces produce Playwright traces reviewable in Trace Viewer | e2e / trace | `npx playwright test e2e/admin-motion-trace.spec.js` | Yes |
| SEED (deferred 178) | Dark-contrast axe pass on seeded edge-state entities | e2e (part of axe extension) | `npm run e2e:a11y` with edge-states seeded | Yes |
| Regression | 262 Elixir admin tests stay green | unit / integration | `mix test --seed 0` | Yes |

### What CAN'T Run Autonomously (Human/CI Gate)

The following require a human or CI operator with credentials and a running server:

1. **Vision-scoring photographic run** (`npm run score-visuals`): requires `ANTHROPIC_API_KEY` + prior screenshot capture. This closes deferred UATs from phases 175, 176, 177, 178.
2. **Screenshot capture** (`npm run e2e:visuals:png-only`): requires `mix accrue_admin.e2e.server` running (PostgreSQL up, Elixir compiled). The `webServer` config in `playwright.config.js` automates server startup via `reuseExistingServer: !process.env.CI` — in CI, it always starts a fresh server.
3. **Motion live quality review**: The trace files are machine-generated but require a human to view them with `npx playwright show-trace` and judge animation quality.

### What CAN Run Autonomously (During Plan Execution)

1. `npm install --save-dev @anthropic-ai/sdk` — package install
2. Spec file creation/editing — code changes
3. `score-visuals.mjs` script creation — code changes
4. `SIGN-OFF.md` scaffold creation — documentation
5. Elixir suite regression check: `cd accrue_admin && mix test --seed 0` — must stay at 262 green
6. Lint/parse check on new `.js` / `.mjs` files

### Wave 0 Gaps (must exist before execution waves)

- [ ] `accrue_admin/e2e/score-visuals.mjs` — NEW file (Wave 1)
- [ ] `accrue_admin/e2e/admin-motion-trace.spec.js` — NEW file (Wave 1)
- [ ] `@anthropic-ai/sdk` in `accrue_admin/package.json` devDependencies (Wave 1)
- [ ] `score-visuals` script in `package.json` scripts (Wave 1)
- [ ] SIGN-OFF.md scaffold at `.planning/phases/179-.../SIGN-OFF.md` (Wave 1)

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | score-visuals.mjs, Playwright | ✓ | v22.14.0 | — |
| npm | Package install | ✓ | 11.1.0 | — |
| Playwright Chromium | Screenshot sweep, axe, motion trace | ✓ | Cached in ~/Library/Caches/ms-playwright/chromium-1223 | `npm run e2e:install` |
| @playwright/test (installed) | All e2e specs | ✓ | 1.59.1 | — |
| @axe-core/playwright (installed) | axe sweep | ✓ | 4.11.3 | — |
| Elixir / OTP | E2E server, Elixir suite | ✓ | OTP 28 | — |
| PostgreSQL | E2E test DB | ✓ | 14.17 | — |
| @anthropic-ai/sdk | score-visuals.mjs | ✗ (not yet installed) | 0.100.1 on npm | Script no-ops if ANTHROPIC_API_KEY absent |
| ANTHROPIC_API_KEY | Vision-scoring run | ✗ (CI/human gate) | — | Script exits 0 with warning when absent |
| Chrome.app / google-chrome | Playwright uses its own Chromium binary, not system Chrome | ✓ (system Chrome present, irrelevant) | — | Playwright uses cached Playwright Chromium |

**Missing dependencies with no fallback:**
- None that block the build phase. The scoring run requires the API key, but that is the explicit human/CI gate.

**Missing dependencies with fallback:**
- `@anthropic-ai/sdk` (not yet installed) — `npm install --save-dev @anthropic-ai/sdk` in Wave 1; script no-ops without API key.

---

## Security Domain

The phase adds QA tooling only. The relevant security considerations are:

### Applicable ASVS Categories

| ASVS Category | Applies | Notes |
|---------------|---------|-------|
| V2 Authentication | No | No auth logic changed |
| V3 Session Management | No | Session logic unchanged |
| V4 Access Control | No | E2E endpoints remain test/dev-only |
| V5 Input Validation | No | score-visuals reads local PNGs, no user input |
| V6 Cryptography | No | |

### Key Security Constraint (from CLAUDE.md)

The E2E plug routes (`/__e2e__/seed/`, `/__e2e__/login`, `/__e2e__/reset`) are compiled under `MIX_ENV=test` only and excluded from the Hex package. This must remain true after any changes to `e2e_plug.ex` or `e2e_fixtures.ex`.

The `score-visuals.mjs` script reads the `ANTHROPIC_API_KEY` from environment — never hardcode, never commit. The `.gitignore` already excludes `test-results/` so PNGs are never committed.

---

## Open Questions (RESOLVED)

1. **Motion trace trigger selectors** — RESOLVED via PATTERNS.md component template audit.
   - Command palette: `#search-trigger` (phx-click="open" on topbar.ex)
   - Dropdown: `details.ax-dropdown > summary`
   - Nav-collapse: `[data-collapse-toggle="true"]`
   - Webhook replay drawer: `data-role="replay-single"`

2. **`connect-accounts` route slug** — RESOLVED: route is `/billing/connect` (confirmed from router.ex grep; shots array uses this path).

3. **Scoring script model recommendation** — RESOLVED: default `claude-sonnet-4-5` with `SCORE_MODEL` env var override; `@anthropic-ai/sdk` 0.100.1 selected (Anthropic official npm package, verified in Package Legitimacy Audit).

4. **Campaign-detail route** — RESOLVED: route is `/billing/analytics/recovery/subscriptions/:at_risk_sub_id` (confirmed from router.ex; shots array uses this pattern).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `coupons` and `promotion-codes` list screens will be populated by the `edge-states` fixture (which inserts 1 coupon + 1 promo code) | Standard Stack — shots array | List screens may show with only 1 row; still "populated" per rubric; low risk |
| A2 | The campaign-detail route accepts a subscription UUID directly: `/billing/analytics/recovery/subscriptions/:at_risk_sub_id` | Code Examples | If route accepts a different param, the URL pattern is wrong; verify from router.ex |
| A3 | `claude-sonnet-4-5` is available in the Anthropic messages API for vision | Code Examples | If not, use `claude-opus-4-5` or check current model availability |
| A4 | The motion-trace spec can trigger the detail drawer via `data-role="action-drawer-trigger"` | Code Examples | The actual selector may differ; must verify from component templates |

**Assumptions in this table require validation** before the plan executor writes the corresponding code. Router audit and component template audit are Wave 0 tasks.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 12-screen visuals sweep (operator-flows only) | 21-screen sweep (3 fixtures merged) | Phase 179 | All detail pages + specialist screens covered |
| No LLM scoring | score-visuals.mjs with structured findings | Phase 179 | Photographic evidence replaces code-level audit only |
| axe on 12 surfaces | axe on 21 surfaces + mobile project | Phase 179 | Closes 178 deferred UAT item 2 (dark-contrast edge states) |
| No motion trace | Playwright trace on 4 motion surfaces | Phase 179 | Closes 177 deferred UAT items 1+2 |
| Per-phase HUMAN-UAT.md pending items | Single SIGN-OFF.md consolidation | Phase 179 | One artifact proves milestone "done" |

---

## Sources

### Primary (HIGH confidence — codebase direct read)

- `accrue_admin/playwright.config.js` — confirmed `chromium-desktop` + `chromium-mobile` projects, `webServer` autostart, `trace: "retain-on-failure"` global, `outputDir: "test-results"`
- `accrue_admin/e2e/admin-visuals.spec.js` — confirmed `captureThemes` + `testInfo.project.name` namespacing, 12-shot inventory, `seed("operator-flows")` only
- `accrue_admin/e2e/admin-a11y.spec.js` — confirmed `emulateMedia({ reducedMotion: "reduce" })`, `scan(page, theme)` helper, 12-surface inventory
- `accrue_admin/e2e/reduced-motion.spec.js` — confirmed Phase 177 token collapse tests (drawer/dropdown/palette/button)
- `accrue_admin/test/support/e2e_fixtures.ex` — confirmed fixture return maps: operator-flows, dashboard, edge-states, overflow
- `accrue_admin/test/support/e2e_plug.ex` — confirmed POST routes for all 4 fixtures
- `accrue_admin/package.json` — confirmed npm scripts, installed deps (`@playwright/test@^1.57.0`, `@axe-core/playwright@^4.11.3`)
- `.planning/phases/178-e-seed-expressiveness-state-coverage/STATE-MATRIX.md` — 21-screen inventory, fixture-to-screen mapping
- `.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md` — after-scores (21/21 ≥2), before-scores for SIGN-OFF
- `.planning/phases/177-d-motion-micro-interaction-design/177-HUMAN-UAT.md` — confirmed 2 deferred items (reduced-motion spec + live motion quality pass)
- `.planning/phases/178-e-seed-expressiveness-state-coverage/178-HUMAN-UAT.md` — confirmed 3 deferred items
- `.planning/phases/175-b-persona-driven-ia-spine/175-HUMAN-UAT.md` — confirmed 4+ deferred items
- `.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-HUMAN-UAT.md` — confirmed 3 deferred items (deferred to Phase 179)
- Root `.gitignore` — confirmed `test-results/` and `playwright-report/` gitignored
- `.planning/config.json` — confirmed `workflow.nyquist_validation: true`

### Secondary (HIGH confidence — npm registry)

- `npm view @playwright/test` — version 1.60.0, author: Microsoft Corporation [VERIFIED: npm registry]
- `npm view @axe-core/playwright` — version 4.11.3 [VERIFIED: npm registry]
- `npm view @anthropic-ai/sdk` — version 0.100.1, author: Anthropic, no postinstall script [VERIFIED: npm registry]
- Playwright Chromium cache: `~/Library/Caches/ms-playwright/chromium-1223` — confirmed present
- Pixel 5 viewport: confirmed `{width: 393, height: 727}` from installed Playwright devices

### Tertiary (MEDIUM confidence — design doc)

- `.planning/research/v1.51-admin-ui-depth-design.md` §4, §6, §7 — Phase F scope, rubric dimensions, "motion needs trace/video review" guardrail

---

## Metadata

**Confidence breakdown:**
- Sweep expansion: HIGH — exact fixture return maps read from source, playwright.config.js confirms 2-project setup already exists
- Scoring script architecture: HIGH — @anthropic-ai/sdk verified on npm, SDK pattern is standard
- axe extension: HIGH — existing spec is well-structured, pattern is direct extension
- Motion trace: MEDIUM — Playwright trace API is standard but exact trigger selectors for drawer/palette not verified (marked ASSUMED, Wave 0 task)
- SIGN-OFF.md layout: HIGH — all evidence sources confirmed present

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable tooling; Playwright/SDK versions may update but pattern stays valid)
