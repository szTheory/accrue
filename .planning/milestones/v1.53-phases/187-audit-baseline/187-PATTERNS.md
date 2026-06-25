# Phase 187: Audit & Baseline - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/187-audit-baseline/187-RUBRIC.md` | config/documentation | transform | `.planning/milestones/v1.51-phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md` | role-match |
| `.planning/phases/187-audit-baseline/187-BASELINE.md` | report/documentation | batch | `.planning/milestones/v1.51-phases/179-f-screenshot-driven-visual-qa-loop-sign-off/SIGN-OFF.md` | role-match |
| `.planning/phases/187-audit-baseline/baseline.cells.json` | data artifact | batch | `accrue_admin/e2e/admin-visuals.spec.js` + `admin-a11y.spec.js` surface arrays | partial |
| `.planning/phases/187-audit-baseline/defects.ndjson` | data artifact | streaming | `accrue_admin/e2e/score-visuals.mjs` findings writer | role-match |
| `.planning/phases/187-audit-baseline/artifacts.manifest.json` | data artifact | file-I/O | `accrue_admin/playwright.config.js` + `admin-motion-trace.spec.js` trace path convention | partial |
| `.planning/phases/187-audit-baseline/schemas/baseline-cell.schema.json` | config/schema | validation | `score-visuals.mjs` parsed/enriched finding shape | partial |
| `.planning/phases/187-audit-baseline/schemas/defect.schema.json` | config/schema | validation | `score-visuals.mjs` parsed/enriched finding shape | partial |
| `accrue_admin/e2e/baseline-manifest.js` | config/utility | transform | `accrue_admin/e2e/admin-visuals.spec.js` surface list | role-match |
| `accrue_admin/e2e/admin-baseline.spec.js` | test | request-response + file-I/O | `accrue_admin/e2e/admin-visuals.spec.js` + `admin-a11y.spec.js` | exact |
| `accrue_admin/e2e/admin-interactions.spec.js` | test | event-driven + file-I/O | `accrue_admin/e2e/admin-motion-trace.spec.js` | exact |
| `accrue_admin/e2e/baseline-artifacts.mjs` | utility | batch + file-I/O | `accrue_admin/e2e/score-visuals.mjs` | role-match |
| `accrue_admin/e2e/score-visuals.mjs` | utility | batch + file-I/O | existing same file | exact |
| `accrue_admin/test/support/e2e_fixtures.ex` / `e2e_plug.ex` | test support/service | CRUD + request-response | existing same files | exact |

## Pattern Assignments

### `.planning/phases/187-audit-baseline/187-RUBRIC.md` (config/documentation, transform)

**Analog:** `.planning/milestones/v1.51-phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md`

**Rubric table pattern** (lines 24-38):
```markdown
| # | Dimension | Passing signal (code-level) | Score 0-3; >=2 = pass |
|---|-----------|-----------------------------|-----------------------|
| ① | Token compliance | No `style=` / bare hex in live template ... | 3 = clean; 1 = inline style present |
| ⑦ | Focus & semantics | `aria-*`/`scope=`/`role=` present; `dl/dt/dd` for field lists ... | 3 = full; 2 = partial aria; 1 = missing ... |
| ⑩ | Reuse/DRY | `Detail.summary_card`/`detail_section`/`detail_field_list` used ... | 3 = all primitives; 2 = summary_card+detail_section used; 1 = hand-rolled ... |
```

**Phase 187 adjustment:** keep dimensions 1-10 semantically compatible, add `11 interaction-integrity` and `12 microcopy`, then document overlay tags separately rather than as a 13th dimension.

### `.planning/phases/187-audit-baseline/187-BASELINE.md` (report/documentation, batch)

**Analog:** `.planning/milestones/v1.51-phases/179-f-screenshot-driven-visual-qa-loop-sign-off/SIGN-OFF.md`

**Gate status and usage pattern** (lines 7-20):
```markdown
**Gate status:**
Partial: screenshot capture, axe sweep, and motion trace capture passed ...

## Section 1 — How to Use This Document

1. All **PENDING** cells require a live server + API key or human review.
2. Run the commands listed in each section to populate the PENDING cells.
3. Fill in the After-column scores from `findings.ndjson` output.
```

**Scorecard pattern** (lines 24-34):
```markdown
## Section 2 — Rubric Scorecard

**Before-column source:** 176-SCORECARD.md after-scores ...
**After-column source:** [PENDING — vision-LLM scoring from `npm run score-visuals` ...]

| Screen | Before min (176-SCORECARD) | Before pass? | After min (photographic gate) | After pass? |
```

**Checklist/requirement mapping pattern** (lines 201-220):
```markdown
- [x] Full 4-cell screenshot capture (84 PNGs) — `npm run e2e:visuals:png-only`
- [ ] Vision-LLM scoring all dimensions >= 2 — `ANTHROPIC_API_KEY=... npm run score-visuals`
- [x] Axe 0 critical/serious in light + dark across all 21 screens — `npm run e2e:a11y`

**QA requirement mapping:**
- QA-01 ... closed by `admin-a11y.spec.js` ... + `admin-visuals.spec.js` ...
```

### `accrue_admin/e2e/baseline-manifest.js` (config/utility, transform)

**Analog:** `accrue_admin/e2e/admin-visuals.spec.js`

**Imports/helper conventions** (lines 1-16):
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
```

**Surface inventory pattern** (lines 49-71):
```javascript
const shots = [
  ["dashboard",           "/billing"],
  ["customers",           "/billing/customers"],
  ["customer-detail",     `/billing/customers/${dash.customer_id}`],
  ["payments",            "/billing/payments"],
  ["charge-detail",       `/billing/payments/${opFlows.charge_id}`],
  ["webhooks",            "/billing/webhooks"],
  ["webhook-detail",      `/billing/webhooks/${opFlows.single_webhook_id}`],
  ["campaign-detail",     `/billing/analytics/recovery/subscriptions/${edge.at_risk_sub_id}`],
];
```

**Apply:** lift the array into a CommonJS manifest export with stable `cell_id`, `surface_type`, `persona_job`, `seed`, `state`, `themes`, `projects`, `status`, and `evidence` fields. Keep current route names from this file, especially `/billing/payments`, `/billing/connect`, and recovery subscription detail.

### `accrue_admin/e2e/admin-baseline.spec.js` (test, request-response + file-I/O)

**Analog:** `accrue_admin/e2e/admin-visuals.spec.js` and `admin-a11y.spec.js`

**Theme screenshot pattern** (`admin-visuals.spec.js` lines 18-28):
```javascript
async function captureThemes(page, name, project) {
  await expect(page.locator("#main-content")).toBeVisible();
  const dir = `test-results/admin-visuals/${project}`;
  await page.evaluate(() => document.documentElement.setAttribute("data-theme", "light"));
  await page.screenshot({ path: `${dir}/${name}.png`, fullPage: true });
  await page.evaluate(() => document.documentElement.setAttribute("data-theme", "dark"));
  await page.screenshot({ path: `${dir}/${name}-dark.png`, fullPage: true });
}
```

**Seed-before-sweep pattern** (`admin-visuals.spec.js` lines 30-47):
```javascript
test.describe("Admin visual inventory", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  test("captures every primary admin surface in light and dark", async ({ page, request }, testInfo) => {
    test.setTimeout(120_000);
    const opFlows = await seed(request, "operator-flows");
    const dash    = await seed(request, "dashboard");
    const edge    = await seed(request, "edge-states");
    const project = testInfo.project.name;
```

**Axe scan pattern** (`admin-a11y.spec.js` lines 19-28, 80-90):
```javascript
async function scan(page, theme) {
  await page.evaluate((t) => document.documentElement.setAttribute("data-theme", t), theme);
  await page.waitForTimeout(50);
  const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
  return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}

const violations = await scan(page, theme);
for (const v of violations) {
  failures.push(`${name} [${theme}] ${v.id}: ${v.nodes[0]?.target.join(" ")}`);
}
expect(failures, `axe violations:\n${failures.join("\n")}`).toEqual([]);
```

**Apply:** drive screenshots and axe from `baseline-manifest.js`; record `covered`, `gap`, and `n/a` cells instead of only screenshots. Reuse `testInfo.project.name` and the existing `test-results/admin-visuals/{project}` convention for evidence paths.

### `accrue_admin/e2e/admin-interactions.spec.js` (test, event-driven + file-I/O)

**Analog:** `accrue_admin/e2e/admin-motion-trace.spec.js`

**Trace-first setup** (lines 23-27):
```javascript
const { test, expect } = require("@playwright/test");

// trace: "on" — file-scoped override for motion capture (global config has "retain-on-failure")
test.use({ trace: "on" });
```

**Open/escape interaction pattern** (lines 63-78):
```javascript
await seed(request, "operator-flows");
await login(page, "/billing");
await expect(page.locator("#main-content")).toBeVisible();

await page.click("#search-trigger");
const palette = page.locator(".ax-command-palette-wrapper");
await expect(palette).toBeVisible();
await expect(palette).toHaveAttribute("data-open", "true");

await page.keyboard.press("Escape");
await expect(palette).toHaveAttribute("data-open", "false");
```

**Accessible state/assertion pattern** (lines 118-149):
```javascript
const toggleButton = page.locator('[data-collapse-toggle="true"]').first();
const controlledId = await toggleButton.getAttribute("aria-controls");
expect(controlledId, "collapse toggle must have data-controls attribute").toBeTruthy();

const controlledList = page.locator(`#${controlledId}`);
await toggleButton.click();
await expect(toggleButton).toHaveAttribute("aria-expanded", "false");
await expect(controlledList).toBeHidden();
await toggleButton.click();
await expect(controlledList).toBeVisible();
```

**Actionability/overlay probe pattern** (lines 160-170):
```javascript
const opFlows = await seed(request, "operator-flows");
await login(page, `/billing/webhooks/${opFlows.single_webhook_id}`);
await expect(page.locator("#main-content")).toBeVisible();

const replayTrigger = page.locator('[data-role="replay-single"]').first();
await expect(replayTrigger).toBeVisible();
await replayTrigger.click();

const confirmation = page.locator('[data-role="replay-confirm"]');
await expect(confirmation).toBeVisible();
```

**Apply:** keep `trace: "on"` file-scoped. Do not use `{ force: true }` for baseline probes; an intercepted click is a defect candidate with overlay tags `actionability` and often `layer-z-index`.

### `accrue_admin/e2e/baseline-artifacts.mjs` (utility, batch + file-I/O)

**Analog:** `accrue_admin/e2e/score-visuals.mjs`

**Node ESM imports/config pattern** (lines 24-50):
```javascript
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const RESULTS_DIR = path.join(__dirname, "../test-results/admin-visuals");
const TO_STDOUT = process.argv.includes("--stdout");
```

**Discovery pattern** (lines 111-145):
```javascript
function discoverPngs() {
  if (!fs.existsSync(RESULTS_DIR)) {
    console.log(`[score-visuals] RESULTS_DIR not found: ${RESULTS_DIR}`);
    return [];
  }

  const projects = ["chromium-desktop", "chromium-mobile"];
  const pngs = [];
  for (const projectName of projects) {
    const projectDir = path.join(RESULTS_DIR, projectName);
    if (!fs.existsSync(projectDir)) {
      continue;
    }
    const files = fs.readdirSync(projectDir).filter((f) => f.endsWith(".png"));
```

**NDJSON writer pattern** (lines 162-168, 246-251):
```javascript
if (TO_STDOUT) {
  findingsOutput = process.stdout;
} else {
  findingsPath = path.join(RESULTS_DIR, "findings.ndjson");
  fs.writeFileSync(findingsPath, "");
}

const line = JSON.stringify(enriched) + "\n";
fs.appendFileSync(findingsPath, line);
```

**Apply:** write committed artifacts only under `.planning/phases/187-audit-baseline/`; reference bulky PNG/trace/axe files by path/checksum in `artifacts.manifest.json`.

### `accrue_admin/e2e/score-visuals.mjs` (utility, batch + file-I/O)

**Analog:** existing same file

**Optional API key guard** (lines 30-42):
```javascript
if (!process.env.ANTHROPIC_API_KEY) {
  console.log("[score-visuals] ANTHROPIC_API_KEY not set — skipping (human/CI gate only)");
  process.exit(0);
}

const { default: Anthropic } = await import("@anthropic-ai/sdk");
const client = new Anthropic();
```

**Current rubric/prompt shape to update** (lines 52-67, 93-106):
```javascript
const DIMENSIONS = [
  { id: 1, name: "token-compliance" },
  ...
  { id: 10, name: "reuse-dry" },
];

Return a JSON array only ...
"dimension": <integer 1-10>,
...
Include one object per dimension per screenshot. Return exactly 10 objects for each image evaluated.
```

**Parse/enrich pattern** (lines 214-244):
```javascript
const parsed = JSON.parse(rawText);
findings = Array.isArray(parsed) ? parsed : null;

const enriched = {
  screen,
  viewport,
  theme,
  dimension: finding.dimension,
  dimension_name: finding.dimension_name,
  score: finding.score,
  defect: finding.defect ?? null,
  suggested_fix: finding.suggested_fix ?? null,
};
```

**Apply:** extend `DIMENSIONS` and prompt to 12 dimensions; enrich with authoritative `cell_id`/surface metadata from the manifest where available. Validate expected count is 12 per image/cell.

### `accrue_admin/test/support/e2e_fixtures.ex` and `e2e_plug.ex` (test support/service, CRUD + request-response)

**Analog:** existing same files

**Plug route pattern** (`e2e_plug.ex` lines 28-68):
```elixir
post "/__e2e__/reset" do
  Fixtures.reset!()
  json(conn, 200, %{ok: true})
end

post "/__e2e__/seed/dashboard" do
  json(conn, 200, Fixtures.seed_dashboard!())
end

post "/__e2e__/seed/operator-flows" do
  json(conn, 200, Fixtures.seed_operator_flows!())
end
```

**JSON response helper** (`e2e_plug.ex` lines 78-84):
```elixir
defp json(conn, status, payload) do
  body = Jason.encode!(payload)

  conn
  |> put_resp_content_type("application/json")
  |> send_resp(status, body)
end
```

**Fixture reset pattern** (`e2e_fixtures.ex` lines 32-40):
```elixir
def reset! do
  tables = @public_tables ++ Enum.map(@accrue_tables, &Accrue.Migration.qualified_table/1)
  TestRepo.query!("TRUNCATE TABLE #{Enum.join(tables, ", ")} RESTART IDENTITY CASCADE", [])
  :ok = Accrue.Processor.Fake.reset()
  :ok = Accrue.Actor.put_operation_id("e2e-" <> Ecto.UUID.generate())
  :ok
end
```

**Named state fixture pattern** (`e2e_fixtures.ex` lines 81-142, 144-245):
```elixir
def seed_operator_flows! do
  customer = insert_customer(%{name: "E2E Charge Customer", email: "charge-e2e@example.com"})
  subscription = insert_subscription(customer, %{status: :active, processor_id: "sub_e2e_refund"})
  charge = insert_charge(customer, subscription, %{processor_id: "ch_e2e_refund", status: "succeeded"})
  ...
  %{charge_id: charge.id, source_event_id: source_event.id, single_webhook_id: single_webhook.id}
end

def seed_overflow! do
  customers = Enum.map(1..26, fn i -> insert_customer(%{name: "E2E Overflow Customer #{i}"}) end)
  %{first_customer_id: List.first(customers).id}
end
```

**Apply:** add only minimal named seeds/endpoints for unreachable Phase 187 cells. Keep routes under `/__e2e__`, return IDs needed by Playwright, and avoid production auth or router changes.

### `.planning/phases/187-audit-baseline/baseline.cells.json` (data artifact, batch)

**Analog:** surface arrays in `admin-visuals.spec.js` and `admin-a11y.spec.js`

**Existing coverage source** (`admin-a11y.spec.js` lines 50-72):
```javascript
const surfaces = [
  ["dashboard",           "/billing"],
  ["customers",           "/billing/customers"],
  ["customer-detail",     `/billing/customers/${dash.customer_id}`],
  ...
  ["campaign-detail",     `/billing/analytics/recovery/subscriptions/${edge.at_risk_sub_id}`]
];
```

**Apply:** one JSON object per audited surface/mode/theme/state/dimension cell. Required fields should include `cell_id`, `surface`, `surface_type`, `mode`, `theme`, `state`, `dimension`, `score`, `coverage_status`, `evidence_refs`, and `notes`.

### `.planning/phases/187-audit-baseline/defects.ndjson` (data artifact, streaming)

**Analog:** `score-visuals.mjs` NDJSON output

**Writer pattern** (`score-visuals.mjs` lines 233-251):
```javascript
for (const finding of findings) {
  const enriched = {
    screen,
    viewport,
    theme,
    dimension: finding.dimension,
    dimension_name: finding.dimension_name,
    score: finding.score,
    defect: finding.defect ?? null,
    suggested_fix: finding.suggested_fix ?? null,
  };

  const line = JSON.stringify(enriched) + "\n";
  fs.appendFileSync(findingsPath, line);
}
```

**Apply:** preserve one JSON object per line. Use stable IDs like `AX187-001`; include `severity`, `surface`, `surface_type`, `persona_job`, `reproduction`, `expected`, `actual`, `rubric_dimension`, `overlay_tags`, `cell_id`, `evidence_refs`, `owner_phase`, `status`, and `notes`.

### `.planning/phases/187-audit-baseline/artifacts.manifest.json` (data artifact, file-I/O)

**Analog:** `accrue_admin/playwright.config.js` and `admin-motion-trace.spec.js`

**Generated output configuration** (`playwright.config.js` lines 14-35):
```javascript
use: {
  baseURL,
  trace: "retain-on-failure",
  screenshot: "only-on-failure"
},
...
outputDir: "test-results"
```

**Trace artifact convention** (`admin-motion-trace.spec.js` lines 8-10, 18-20):
```javascript
 *   Artifacts: test-results/<test-name>/trace.zip
 *   Review with: npx playwright show-trace test-results/.../trace.zip
 *
 * trace: "on" is FILE-SCOPED via test.use() — does NOT modify playwright.config.js.
```

**Apply:** manifest entries should reference `test-results/...` paths and checksums; do not commit generated PNGs or trace zips by default.

### `.planning/phases/187-audit-baseline/schemas/*.schema.json` (config/schema, validation)

**Analog:** `score-visuals.mjs` parse/enrich shape and Phase 187 context minimum fields

**Parse failure handling pattern** (`score-visuals.mjs` lines 214-230):
```javascript
try {
  const parsed = JSON.parse(rawText);
  findings = Array.isArray(parsed) ? parsed : null;
} catch (parseErr) {
  console.error(`[score-visuals] Failed to parse model response for ${screen} (${viewport}/${theme}): ${parseErr.message}`);
  continue;
}

if (!findings) {
  console.error(`[score-visuals] Model returned non-array for ${screen} (${viewport}/${theme})`);
  continue;
}
```

**Apply:** schemas should validate the committed artifact shape, not model output directly. Model-supplied values must be overridden by manifest metadata before artifact writing.

### `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` / `component_registry.ex` (existing analog for component rows)

**Analog role:** component-lab source for manifest component and component-group rows.

**Registry entry pattern** (`component_registry.ex` lines 20-38, 134-138):
```elixir
@spec entries() :: [entry()]
def entries do
  [
    %{
      family: "button",
      variant: "primary",
      ax_class: "ax-button ax-button-primary",
      tokens: ["--ax-accent-strong", "--ax-accent-contrast", "--ax-transition-colors"]
    },
    ...
  ]
end

def variants_for(family) do
  Enum.filter(entries(), &(&1.family == family))
end
```

**Kitchen rendering pattern** (`component_kitchen_live.ex` lines 167-188):
```elixir
<%= for entry <- ComponentRegistry.variants_for("button") do %>
  <div class="ax-dev-variant-row">
    <div data-ax-theme="light">
      <Button.button variant={entry.variant} type="button">
        <%= String.capitalize(entry.variant) %>
      </Button.button>
    </div>
    <div data-ax-theme="dark" style="background: var(--ax-base); padding: var(--ax-space-sm);">
      <Button.button variant={entry.variant} type="button">
        <%= String.capitalize(entry.variant) %>
      </Button.button>
    </div>
    <dl class="ax-dev-token-dl">
      <dt class="ax-label"><code><%= entry.ax_class %></code></dt>
```

**Apply:** baseline manifest component rows should start from registry families and `/dev/components`; no PhoenixStorybook adoption.

## Shared Patterns

### Playwright Project/Server Contract

**Source:** `accrue_admin/playwright.config.js` lines 7-35

**Apply to:** all new E2E specs

```javascript
module.exports = defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: false,
  workers: 1,
  use: {
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure"
  },
  webServer: {
    command: `MIX_ENV=test ACCRUE_ADMIN_E2E_PORT=${port} mix accrue_admin.e2e.server`,
    url: `${baseURL}/__e2e__/health`,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000
  },
  projects: [
    { name: "chromium-desktop", use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } } },
    { name: "chromium-mobile", use: { ...devices["Pixel 5"] } }
  ],
  outputDir: "test-results"
});
```

### E2E Auth/Fixture Helpers

**Source:** `admin-visuals.spec.js` lines 3-16

**Apply to:** `admin-baseline.spec.js`, `admin-interactions.spec.js`

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
```

### Brand/Microcopy Lens

**Source:** `brandbook/voice.md` lines 11-17 and `brandbook/copy.md` lines 194-218

**Apply to:** `187-RUBRIC.md`, `187-BASELINE.md`, `defects.ndjson` microcopy findings

```markdown
Measured. Accrue doesn't oversell. Every claim is sized to what the library actually does.
Exact. Accrue names things precisely: context functions, append-only ledgers, merge-blocking CI, Fake-backed proof paths.
Native. Accrue speaks in Phoenix-developer idioms — Ecto schemas, OTP supervision, mix tasks, plugs, contexts.
Durable. Accrue copy ages well.

Tone: Precise=5 / Formal=3 (error/empty-state surface). No apologetic softening. State the fact; give the next action.
```

### Token/Design-System Lens

**Source:** `brandbook/tokens/README.md` lines 44-47, 64-99

**Apply to:** rubric dimension 1, contrast/dark-mode findings, component rows

```markdown
Typography, spacing, radius, focus-ring, and state tokens are reference-only in the brand layer. The admin `--ax-*` tokens in `accrue_admin/assets/css/theme.css` are the authoritative implementation SSOT.

Space sm | `--ax-space-sm` | `0.5rem` (8px)
Focus ring color | `--ax-focus-ring` | `color-mix(in oklch, var(--ax-accent) 70%, white)`
Disabled | Composited with `--ax-muted` ...
Loading / skeleton | Shimmer animation via `background-position` ...
```

### Prior Guardrails

**Source:** `.planning/research/v1.51-admin-ui-depth-design.md` lines 155-168

**Apply to:** all planner actions

```markdown
- No Tailwind migration — stay on custom `ax-*` CSS + tokens.
- No new billing primitives / domain features — quality investment in a shipped surface only.
- No breaking changes — route reshaping ships with redirects; component public APIs stay backward-compatible.
- No re-doing the v1.50 foundation — extend tokens, reuse the Playwright/axe harness.
```

## No Analog Found

No planned file is without a usable analog. The weakest analogs are the JSON schemas and `artifacts.manifest.json`; derive their field names from Phase 187 decisions and their file-I/O behavior from `score-visuals.mjs` plus Playwright `test-results` conventions.

## Metadata

**Analog search scope:** `accrue_admin/e2e`, `accrue_admin/test/support`, `accrue_admin/lib/accrue_admin/dev`, `brandbook`, `.planning` prior v1.51 artifacts
**Files scanned:** 40+ candidate files via `rg --files`, then 13 primary analogs read
**Pattern extraction date:** 2026-06-14
