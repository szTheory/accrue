# Phase 179: F — Screenshot-Driven Visual QA Loop & Sign-off - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 5 new/modified files
**Analogs found:** 4 / 5 (score-visuals.mjs is net-new with no direct analog; SIGN-OFF.md has a structural analog)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/e2e/admin-visuals.spec.js` | e2e test | request-response | self (extend in-place) | exact — already has all helpers; shots[] expansion only |
| `accrue_admin/e2e/admin-a11y.spec.js` | e2e test | request-response | self (extend in-place) | exact — already has scan()/surfaces[] pattern; surfaces[] expansion only |
| `accrue_admin/e2e/admin-motion-trace.spec.js` | e2e test | event-driven | `admin-visuals.spec.js` + `reduced-motion.spec.js` | role-match — same seed/login helpers, different assertion type |
| `accrue_admin/e2e/score-visuals.mjs` | Node CLI utility | batch transform | none (net-new tooling) | no analog — reference RESEARCH.md SDK pattern |
| `.planning/phases/179-.../SIGN-OFF.md` | planning artifact | — | `176-SCORECARD.md` (structural) | role-match — same scorecard table shape |

---

## Critical Route Corrections (from router.ex audit)

**The RESEARCH.md shots table contains incorrect route slugs. The authoritative slugs from `accrue_admin/lib/accrue_admin/router.ex` lines 63–94 are:**

| Screen | Correct path | Research doc said | Fix |
|--------|-------------|-------------------|-----|
| charges list | `/billing/payments` | `/billing/charges` | Router has redirect: `/charges` → `/payments` (line 63-66); canonical is `/payments` |
| charge detail | `/billing/payments/:id` | `/billing/charges/:charge_id` | Same redirect applies |
| connect list | `/billing/connect` | `/billing/connect-accounts` | Router uses `/connect` not `/connect-accounts` |
| connect detail | `/billing/connect/:id` | `/billing/connect-accounts/:connect_account_id` | Same |
| campaign detail | `/billing/analytics/recovery/subscriptions/:id` | `/billing/analytics/recovery/campaigns/:at_risk_sub_id` | Router uses `subscriptions/:id` not `campaigns/:id` |

These corrections must be applied in the shots[] and surfaces[] arrays. Every other path in the research doc matches the router.

---

## Pattern Assignments

### `accrue_admin/e2e/admin-visuals.spec.js` (e2e test, extend in-place)

**Analog:** self — `accrue_admin/e2e/admin-visuals.spec.js` (lines 1–65)

**Existing helpers to retain verbatim** (lines 1–28):
```javascript
async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function seed(request, fixture) {
  const response = await request.post(`/__e2e__/seed/${fixture}`);
  expect(response.ok()).toBeTruthy();
  return response.json();
}

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
}

async function captureThemes(page, name, project) {
  await expect(page.locator("#main-content")).toBeVisible();
  const dir = `test-results/admin-visuals/${project}`;
  await page.evaluate(() => document.documentElement.setAttribute("data-theme", "light"));
  await page.screenshot({ path: `${dir}/${name}.png`, fullPage: true });
  await page.evaluate(() => document.documentElement.setAttribute("data-theme", "dark"));
  await page.screenshot({ path: `${dir}/${name}-dark.png`, fullPage: true });
}
```

**Test structure to retain** (lines 30–33):
```javascript
test.describe("Admin visual inventory", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });
```

**What changes:** Replace the single `seed("operator-flows")` call and 12-entry shots[] with a multi-fixture seed + 21-entry shots[]. The `project = testInfo.project.name` line (line 40) and `captureThemes` loop (lines 60–63) are unchanged.

**Multi-fixture seed pattern** (from `e2e_fixtures.ex` + `e2e_plug.ex` return maps, confirmed):
```javascript
// operator-flows → { charge_id, source_event_id, single_webhook_id, bulk_webhook_id }
// dashboard      → { customer_id, subscription_id, event_id }
// edge-states    → { at_risk_sub_id, canceling_sub_id, jpy_invoice_id, jpy_charge_id,
//                    dunning_customer_id, long_name_customer_id, coupon_id,
//                    promo_code_id, connect_account_id }
// DO NOT call reset() between fixture calls — processor_ids use System.unique_integer,
// no collision risk.
const opFlows = await seed(request, "operator-flows");
const dash    = await seed(request, "dashboard");
const edge    = await seed(request, "edge-states");
const project = testInfo.project.name;
```

**Corrected 21-entry shots[] (route-slugs verified against router.ex lines 72–94):**
```javascript
const shots = [
  ["dashboard",          "/billing"],
  ["customers",          "/billing/customers"],
  ["customer-detail",    `/billing/customers/${dash.customer_id}`],
  ["subscriptions",      "/billing/subscriptions"],
  ["subscription-detail",`/billing/subscriptions/${dash.subscription_id}`],
  ["invoices",           "/billing/invoices"],
  ["invoice-detail",     `/billing/invoices/${edge.jpy_invoice_id}`],
  ["payments",           "/billing/payments"],           // NOTE: /payments not /charges
  ["charge-detail",      `/billing/payments/${opFlows.charge_id}`],
  ["coupons",            "/billing/coupons"],
  ["coupon-detail",      `/billing/coupons/${edge.coupon_id}`],
  ["promotion-codes",    "/billing/promotion-codes"],
  ["promo-code-detail",  `/billing/promotion-codes/${edge.promo_code_id}`],
  ["connect",            "/billing/connect"],             // NOTE: /connect not /connect-accounts
  ["connect-detail",     `/billing/connect/${edge.connect_account_id}`],
  ["events",             "/billing/events"],
  ["event-detail",       `/billing/events/${opFlows.source_event_id}`],
  ["webhooks",           "/billing/webhooks"],
  ["webhook-detail",     `/billing/webhooks/${opFlows.single_webhook_id}`],
  ["recovery",           "/billing/analytics/recovery"],
  ["campaign-detail",    `/billing/analytics/recovery/subscriptions/${edge.at_risk_sub_id}`],
  // NOTE: route is /analytics/recovery/subscriptions/:id (line 94 of router.ex)
];
```

---

### `accrue_admin/e2e/admin-a11y.spec.js` (e2e test, extend in-place)

**Analog:** self — `accrue_admin/e2e/admin-a11y.spec.js` (lines 1–75)

**Existing helpers to retain verbatim** (lines 1–28): same `reset`, `seed`, `login` helpers as visuals spec.

**scan() helper — retain exactly** (lines 23–28):
```javascript
async function scan(page, theme) {
  await page.evaluate((t) => document.documentElement.setAttribute("data-theme", t), theme);
  await page.waitForTimeout(50);   // wait for settled token colours — do NOT remove
  const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
  return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}
```

**Test structure to retain** (lines 35–40):
```javascript
await page.emulateMedia({ reducedMotion: "reduce" }); // kills theme-transition for stable colours
const data = await seed(request, "operator-flows");
```

**What changes:** Add multi-fixture seed (same pattern as visuals spec) and expand surfaces[] from 12 to 21 entries using the same corrected route slugs. The failure accumulation and assertion pattern (lines 57–73) is unchanged:
```javascript
const failures = [];
for (const [name, path] of surfaces) {
  await login(page, path);
  await expect(page.locator("#main-content")).toBeVisible();
  for (const theme of ["light", "dark"]) {
    const violations = await scan(page, theme);
    for (const v of violations) {
      const d = v.nodes[0] && (v.nodes[0].any[0] || v.nodes[0].all[0]);
      const detail = d && d.data ? ` fg=${d.data.fgColor} bg=${d.data.bgColor} r=${d.data.contrastRatio}` : "";
      failures.push(`${name} [${theme}] ${v.id}: ${v.nodes[0]?.target.join(" ")}${detail}`);
    }
  }
}
expect(failures, `axe violations:\n${failures.join("\n")}`).toEqual([]);
```

---

### `accrue_admin/e2e/admin-motion-trace.spec.js` (NEW — net-new file)

**Analog:** `accrue_admin/e2e/admin-visuals.spec.js` for seed/login/reset helpers; `accrue_admin/e2e/reduced-motion.spec.js` for the pattern of navigating to a surface and reading computed state.

**Copy these helpers verbatim** from admin-visuals.spec.js:
```javascript
const { test, expect } = require("@playwright/test");

async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function seed(request, fixture) {
  const response = await request.post(`/__e2e__/seed/${fixture}`);
  expect(response.ok()).toBeTruthy();
  return response.json();
}

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
}
```

**Suite-level trace override** (Playwright docs — force trace for all tests in this file only):
```javascript
test.use({ trace: "on" }); // override global "retain-on-failure" for motion capture
```

**beforeEach pattern** (copy from admin-visuals.spec.js lines 31–33):
```javascript
test.describe("Motion trace — animated surface capture", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });
```

**Motion surfaces and their trigger selectors** (from component template audit):

1. **Drawer** — `detail_drawer.ex` uses `:if={@open}` conditional render. The drawer is conditionally rendered (not in DOM when closed). The `webhook_live.ex` triggers are `phx-click="prepare_replay"` (data-role="replay-single") and `phx-click="confirm_replay"` (data-role="confirm-replay") — the drawer shell (`.ax-detail-drawer-shell`) is shown via `phx-mounted` JS transition. Navigate to webhook-detail and trigger replay flow to see the drawer enter animation.

2. **Command palette** — `topbar.ex` line 25-26: `id="search-trigger"` with `phx-click="open"`. Use `page.click('#search-trigger')` to open the `ax-command-palette-wrapper`. The palette's open state is `data-open="true"` on `div.ax-command-palette-wrapper` (global_search.ex line 115).

3. **Dropdown** — `dropdown_menu.ex` uses native `<details>` disclosure semantics (`.ax-dropdown`). The panel is `.ax-dropdown-panel`. Open via `page.click('details.ax-dropdown > summary')` on any page that has a dropdown.

4. **Nav-collapse** — `sidebar.ex` lines 52-69: `<button class="ax-sidebar-group-toggle" data-collapse-toggle="true">` with `aria-controls="sidebar-group-links-{slug}"`. Use `page.click('[data-collapse-toggle="true"]')` to toggle a collapsible group (Recovery, Developer, or Catalog — all have `group_meta.collapsible = true`).

**Trace artifact review command** (document in spec comments):
```javascript
// Trace artifacts: test-results/<test-name>/trace.zip
// Review with: npx playwright show-trace test-results/.../trace.zip
```

---

### `accrue_admin/e2e/score-visuals.mjs` (NEW — net-new, no codebase analog)

**No analog in this repo.** Pattern is from `@anthropic-ai/sdk` documentation + Node ESM conventions.

**ESM script header pattern** (Node ESM, no existing .mjs in project e2e/ directory):
```javascript
import Anthropic from "@anthropic-ai/sdk";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
```

**API key guard — must be first executable statement after imports** (RESEARCH.md pattern, confirmed as required):
```javascript
if (!process.env.ANTHROPIC_API_KEY) {
  console.log("[score-visuals] ANTHROPIC_API_KEY not set — skipping (human/CI gate only)");
  process.exit(0);
}
const client = new Anthropic(); // reads ANTHROPIC_API_KEY from env
```

**Model selection** — default `claude-sonnet-4-5`, allow override via env:
```javascript
const model = process.env.SCORE_MODEL || "claude-sonnet-4-5";
```

**Image content block shape** (Anthropic messages API with vision):
```javascript
const response = await client.messages.create({
  model,
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

**Findings JSON schema** (locked in CONTEXT.md — do not deviate):
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

**PNG discovery** — use `fs.readdirSync` + `.filter(f => f.endsWith(".png"))`, not a glob package:
```javascript
const RESULTS_DIR = path.join(__dirname, "../test-results/admin-visuals");
// projects: chromium-desktop, chromium-mobile
// files: <name>.png (light) and <name>-dark.png (dark)
```

**Large-image guard** (RESEARCH.md Pitfall 3):
```javascript
const MAX_B64_BYTES = 5 * 1024 * 1024; // 5 MB
const b64 = fs.readFileSync(pngPath, "base64");
if (b64.length > MAX_B64_BYTES) {
  console.warn(`[score-visuals] Skipping ${pngPath} — base64 size ${b64.length} exceeds 5 MB limit`);
  continue;
}
```

**npm script** to add in `accrue_admin/package.json`:
```json
"score-visuals": "node e2e/score-visuals.mjs"
```

**devDependency** to add in `accrue_admin/package.json`:
```json
"@anthropic-ai/sdk": "^0.100.1"
```

---

### `.planning/phases/179-.../SIGN-OFF.md` (NEW — planning artifact)

**Structural analog:** `.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md`

From the scorecard analog, adopt: the per-screen × per-dimension table shape, the "before" column sourced from prior phase evidence, explicit pass/fail notation (≥2 = pass).

**Required sections** (from CONTEXT.md QA-03 + RESEARCH.md Pattern 6):

1. Milestone header with phase scope (174–179) and gate status
2. Rubric scorecard — 21 screen rows × 10 dimension columns × "before (from 176-SCORECARD after-scores)" / "after (photographic gate)" columns
3. Axe status table — light + dark + mobile columns, 0 violations assertion
4. Motion confirmation — 4 surfaces × trace captured / quality reviewed columns; reduced-motion spec link
5. State coverage — STATE-MATRIX 178 gap-closure reference
6. Design-system completeness — 174 token audit evidence link
7. IA persona paths — 175 HUMAN-UAT evidence link
8. Screenshot evidence directory reference (gitignored; not embedded)
9. Human/CI gate status — MUST use `[PENDING: ...]` placeholder for the photographic run

**PENDING placeholder wording to use literally:**
```
Vision-scoring photographic run: [PENDING — run `npm run score-visuals` with ANTHROPIC_API_KEY + live server]
```

---

## Shared Patterns

### seed/login/reset Helpers
**Source:** `accrue_admin/e2e/admin-visuals.spec.js` lines 3–16
**Apply to:** `admin-motion-trace.spec.js` (copy verbatim)
All three e2e specs use identical `reset(request)`, `seed(request, fixture)`, and `login(page, target)` helpers — there is no shared utility file; the convention is to copy them at the top of each spec.

### Multi-fixture Seed Without Intermediate Reset
**Source:** `accrue_admin/test/support/e2e_fixtures.ex` — `insert_customer` default uses `System.unique_integer([:positive])` for `processor_id` (line 258), making fixtures accumulation-safe.
**Apply to:** `admin-visuals.spec.js`, `admin-a11y.spec.js`
Pattern: call `reset()` ONCE in `beforeEach`, then call `seed("operator-flows")`, `seed("dashboard")`, `seed("edge-states")` in sequence without any intermediate `reset()`. Merge returned maps with spread/`Object.assign`.

### `test.beforeEach` Reset Pattern
**Source:** `accrue_admin/e2e/admin-visuals.spec.js` lines 31–33; `accrue_admin/e2e/admin-a11y.spec.js` lines 30–32
**Apply to:** `admin-motion-trace.spec.js`
```javascript
test.describe("...", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });
  // ...
```

### `#main-content` Visibility Gate
**Source:** `accrue_admin/e2e/admin-visuals.spec.js` line 22; `admin-a11y.spec.js` line 61
**Apply to:** `admin-motion-trace.spec.js`
Always `await expect(page.locator("#main-content")).toBeVisible()` after `login()` before any interaction or capture. This is the stable "page settled" signal across all e2e specs.

### `emulateMedia({ reducedMotion: "reduce" })` for axe
**Source:** `accrue_admin/e2e/admin-a11y.spec.js` line 39
**Apply to:** axe extension in `admin-a11y.spec.js` — retain in the extended version; do NOT add to the visuals or motion trace specs.

### `test.use({ trace: "on" })` Scoping
**Source:** Playwright docs (no existing in-repo example — this pattern is new)
**Apply to:** `admin-motion-trace.spec.js` only — must NOT be added globally in `playwright.config.js` (would bloat all test output). The global config already has `trace: "retain-on-failure"`.

---

## Route Slug Reference (verified from `router.ex` lines 63–94)

| Screen | Verified path |
|--------|--------------|
| Dashboard | `/billing` |
| Customers | `/billing/customers` |
| Customer detail | `/billing/customers/:id` |
| Subscriptions | `/billing/subscriptions` |
| Subscription detail | `/billing/subscriptions/:id` |
| Invoices | `/billing/invoices` |
| Invoice detail | `/billing/invoices/:id` |
| Charges/Payments | `/billing/payments` (canonical; `/billing/charges` redirects here) |
| Charge detail | `/billing/payments/:id` |
| Coupons | `/billing/coupons` |
| Coupon detail | `/billing/coupons/:id` |
| Promotion codes | `/billing/promotion-codes` |
| Promo code detail | `/billing/promotion-codes/:id` |
| Connect accounts | `/billing/connect` (NOT `/billing/connect-accounts`) |
| Connect detail | `/billing/connect/:id` |
| Events | `/billing/events` |
| Event detail | `/billing/events/:id` |
| Webhooks | `/billing/webhooks` |
| Webhook detail | `/billing/webhooks/:id` |
| Recovery | `/billing/analytics/recovery` |
| Campaign detail | `/billing/analytics/recovery/subscriptions/:id` (NOT `/campaigns/:id`) |

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `accrue_admin/e2e/score-visuals.mjs` | Node CLI utility | batch transform | No Node scripts in this repo (no `scripts/` directory); tooling is Playwright specs only. Pattern comes from `@anthropic-ai/sdk` npm docs + RESEARCH.md Pattern 3. |

---

## Metadata

**Analog search scope:** `accrue_admin/e2e/`, `accrue_admin/lib/accrue_admin/components/`, `accrue_admin/lib/accrue_admin/live/`, `accrue_admin/lib/accrue_admin/router.ex`, `accrue_admin/test/support/`, `accrue_admin/package.json`, `accrue_admin/playwright.config.js`
**Files scanned:** 12
**Key discovery:** The router uses `/billing/payments` (not `/billing/charges`) and `/billing/connect` (not `/billing/connect-accounts`) and `/analytics/recovery/subscriptions/:id` (not `/campaigns/:id`) — the RESEARCH.md shots table has these wrong. The drawer (`detail_drawer.ex`) is a component but is not yet wired to any live view via open/close events; the closest interactive motion surface for the trace spec is the replay workflow on webhook-detail (uses `data-role="replay-single"` phx-click trigger) and the command palette (triggered via `#search-trigger` phx-click="open" in topbar.ex).
**Pattern extraction date:** 2026-06-04
