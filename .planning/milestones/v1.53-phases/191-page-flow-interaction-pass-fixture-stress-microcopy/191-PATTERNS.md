# Phase 191: Page & Flow Interaction Pass + Fixture Stress + Microcopy - Pattern Map

**Mapped:** 2026-06-18  
**Files analyzed:** 49 target files/groups  
**Analogs found:** 48 / 49  
**Context sources:** `191-CONTEXT.md`, `191-RESEARCH.md`, `191-UI-SPEC.md`, `191-VALIDATION.md`  

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/e2e/admin-page-flow-phase191.spec.js` | test | request-response + event-driven browser flows | `accrue_admin/e2e/admin-group-contracts.spec.js`; `accrue_admin/e2e/admin-interactions.spec.js` | role-match |
| `accrue_admin/e2e/baseline-manifest.js` | config | batch + transform | existing same file | exact |
| `accrue_admin/e2e/admin-interactions.spec.js` | test | event-driven browser flows | existing same file | exact |
| `accrue_admin/e2e/admin-group-contracts.spec.js` | test | batch + request-response | existing same file | exact |
| `accrue_admin/e2e/admin-a11y.spec.js` | test | batch + request-response | existing same file | exact |
| `accrue_admin/e2e/admin-visuals.spec.js` | test | batch + file-I/O screenshots | existing same file | exact |
| `accrue_admin/playwright.config.js` | config | test orchestration | existing same file | exact |
| `accrue_admin/package.json` | config | script orchestration | existing same file | exact |
| `accrue_admin/test/support/e2e_plug.ex` | test utility | request-response | existing same file | exact |
| `accrue_admin/test/support/e2e_fixtures.ex` | test utility | CRUD + batch | existing same file | exact |
| `accrue_admin/test/support/e2e_server.ex` | test utility | request-response + config | existing same file | exact |
| `accrue_admin/test/accrue_admin/e2e_fixtures_test.exs` | test | CRUD + request-response | existing same file | exact |
| `examples/accrue_host/priv/repo/seeds.exs` | config/seed | batch + CRUD | existing same file | exact |
| `examples/accrue_host/priv/repo/seeds/edge_states.exs` | config/seed | batch + CRUD | existing same file | exact |
| `examples/accrue_host/priv/repo/seeds/showcase.exs` | config/seed | batch + CRUD + event replay | existing same file | exact |
| `examples/accrue_host/priv/repo/seeds/background_data.exs` | config/seed | batch + CRUD | existing same file | exact |
| `examples/accrue_host/test/seeds_idempotency_test.exs` | test | batch + CRUD verification | existing same file | exact |
| `examples/accrue_host/test/accrue_host/seed_e2e_cleanup_test.exs` | test | batch cleanup verification | existing same file | exact |
| `accrue_admin/assets/js/app.js` | config/bootstrap | event-driven hook registration | existing same file | exact |
| `accrue_admin/assets/js/hooks/dropdown.js` | hook | event-driven overlay interaction | existing same file | exact |
| `accrue_admin/assets/js/hooks/command_palette.js` | hook | event-driven focus/search interaction | existing same file | exact |
| `accrue_admin/assets/js/hooks/accrue_shell_nav.js` | hook | event-driven responsive navigation | existing same file | exact |
| `accrue_admin/assets/js/hooks/focus_trap.js` | hook | event-driven focus containment | `accrue_admin/assets/js/hooks/command_palette.js`; `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` | no exact analog |
| `accrue_admin/assets/css/theme.css` | config/style tokens | transform | existing same file | exact |
| `accrue_admin/assets/css/app.css` | style | transform + responsive layout | existing same file | exact |
| `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` | component | event-driven overlay | existing same file | exact |
| `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` | component | event-driven overlay + request-response action | existing same file | exact |
| `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` | component | event-driven overlay | existing same file | exact |
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | component | event-driven overlay + transform | existing same file | exact |
| `accrue_admin/lib/accrue_admin/components/app_shell.ex` | component | request-response layout + event-driven nav | existing same file | exact |
| `accrue_admin/lib/accrue_admin/components/data_table.ex` | component | CRUD list + transform | existing same file | exact |
| `accrue_admin/lib/accrue_admin/components/empty_state.ex` | component | transform | existing same file | exact |
| `accrue_admin/lib/accrue_admin/components/flash_group.ex` | component | event-driven notification | existing same file | exact |
| `accrue_admin/lib/accrue_admin/copy.ex` | utility | transform | existing same file | exact |
| `accrue_admin/lib/accrue_admin/copy/invoice.ex` | utility | transform | existing same file | exact |
| `accrue_admin/lib/accrue_admin/copy/subscription.ex` | utility | transform | existing same file | exact |
| `accrue_admin/lib/accrue_admin/copy/locked.ex` | utility | transform | existing same file | exact |
| `accrue_admin/lib/accrue_admin/page_live.ex` | controller/live view | request-response + layout | existing same file | exact |
| `accrue_admin/lib/accrue_admin/live/*s_live.ex` list pages | controller/live view | CRUD list + request-response | `customers_live.ex`; `invoices_live.ex`; `analytics/recovery_live.ex` | exact/role-match |
| `accrue_admin/lib/accrue_admin/live/*_live.ex` detail pages | controller/live view | CRUD detail + event-driven actions | `invoice_live.ex`; `charge_live.ex`; `webhook_live.ex` | exact/role-match |
| `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` | controller/live view | request-response dashboard | `page_live.ex`; `analytics/recovery_live.ex` | role-match |
| `accrue_admin/test/js/command_palette_test.mjs` | test | event-driven DOM interaction | existing same file | exact |
| `accrue_admin/test/accrue_admin/components/*_test.exs` | test | component render + transform | `data_table_test.exs`; `global_search_test.exs`; `app_shell_test.exs` | role-match |
| `accrue_admin/test/accrue_admin/live/*_test.exs` | test | request-response + event-driven LiveView | `charge_live_test.exs`; `invoice_live_test.exs`; `webhook_live_test.exs` | role-match |
| `.planning/phases/187-admin-ux-audit/schemas/defect.schema.json` | config/schema | validation transform | existing same file | exact |
| `.planning/phases/187-admin-ux-audit/schemas/baseline-cell.schema.json` | config/schema | validation transform | existing same file | exact |
| `.planning/phases/187-admin-ux-audit/defects.ndjson` | data artifact | batch ledger | existing same file | exact |
| `.planning/phases/190-reconcile-187-audit-ledger-group-dedupe-schema/190-PHASE-191-HANDOFF.md` | artifact | batch handoff | existing same file | exact |
| `.planning/phases/190-reconcile-187-audit-ledger-group-dedupe-schema/190-GROUP-CONTRACTS.md` | artifact | batch contract | existing same file | exact |

## Pattern Assignments

### `accrue_admin/e2e/admin-page-flow-phase191.spec.js` (test, request-response + event-driven browser flows)

**Analog:** `accrue_admin/e2e/admin-group-contracts.spec.js` + `accrue_admin/e2e/admin-interactions.spec.js`  
**Apply to:** New phase-191 E2E page-flow regression spec and any updates to existing E2E specs.

**Imports and ledger paths pattern** (`admin-group-contracts.spec.js` lines 1-10):
```javascript
const fs = require("fs")
const path = require("path")
const { test, expect } = require("@playwright/test")
const {
  ADMIN_BASELINE_MANIFEST,
  ADMIN_BASELINE_DIMENSIONS,
  cellsForSurface,
  cellId
} = require("./baseline-manifest")
```

**Manifest-driven defect group scope** (`admin-group-contracts.spec.js` lines 12-40):
```javascript
const DEFECT_LEDGER_PATH = path.resolve(
  __dirname,
  "../../.planning/phases/187-admin-ux-audit/defects.ndjson"
)

const REQUIRED_HANDOFF_TAGS = new Set([
  "disabled-affordance",
  "layer-z-index",
  "overlay-position",
  "scroll-reachability",
  "focus-restore",
  "copy-recovery",
  "copy-specificity"
])
```

**Reset, seed, login helpers** (`admin-group-contracts.spec.js` lines 139-152):
```javascript
async function resetAndSeed(page) {
  await page.request.post("/__e2e/reset")
  await page.request.post("/__e2e/seed", {
    data: { scenario: "operator-flows" }
  })
}

async function login(page, accountId = "acct_admin") {
  await page.request.post("/__e2e/login", {
    data: { account_id: accountId, role: "admin" }
  })
}
```

**Route resolution and representative route pattern** (`admin-group-contracts.spec.js` lines 94-100, 154-168):
```javascript
const REPRESENTATIVE_ROUTES = {
  dashboard: "/",
  customers: "/customers",
  invoices: "/invoices",
  subscriptions: "/subscriptions",
  charges: "/charges",
  webhooks: "/webhooks"
}

function representativeRouteFor(surface) {
  return REPRESENTATIVE_ROUTES[surface.slug] || surface.path
}
```

**Theme coverage loop** (`admin-group-contracts.spec.js` lines 171-180):
```javascript
async function setTheme(page, theme) {
  await page.evaluate((nextTheme) => {
    document.documentElement.dataset.theme = nextTheme
    window.localStorage.setItem("accrue_admin_theme", nextTheme)
  }, theme)
}
```

**Viewport and layout probes** (`admin-group-contracts.spec.js` lines 206-226, 269-337):
```javascript
function viewportForBreakpoint(breakpoint) {
  if (breakpoint === "mobile") return { width: 390, height: 844 }
  if (breakpoint === "tablet") return { width: 834, height: 1112 }
  return { width: 1440, height: 1000 }
}

async function collectLayoutFacts(page) {
  return await page.evaluate(() => {
    const viewportWidth = window.innerWidth
    const interactive = Array.from(
      document.querySelectorAll("a, button, input, select, textarea, [tabindex]")
    )

    return {
      viewportWidth,
      bodyWidth: document.body.scrollWidth,
      focusableCount: interactive.length
    }
  })
}
```

**Interaction recorder pattern** (`admin-interactions.spec.js` lines 57-102):
```javascript
function makeRecorder() {
  const observations = []

  function record(id, severity, message, details = {}) {
    observations.push({
      id,
      severity,
      message,
      details
    })
  }

  return { observations, record }
}
```

**Interaction probe pattern** (`admin-interactions.spec.js` lines 127-239):
```javascript
async function clickAndRecord(page, selector, recorder, id, message) {
  const element = page.locator(selector).first()
  if ((await element.count()) === 0) {
    recorder.record(id, "medium", message, { selector, state: "missing" })
    return
  }

  await element.click()
}
```

**Modal/drawer/step-up probe scope** (`admin-interactions.spec.js` lines 241-395):
```javascript
async function probeModalAndDrawer(page, recorder) {
  await probeDetailDrawer(page, recorder)
  await probeStepUpModal(page, recorder)
  await probeDropdowns(page, recorder)
}
```

**Expected assertion style for probes** (`admin-interactions.spec.js` lines 1176-1224):
```javascript
test("admin interaction surfaces remain reachable", async ({ page }) => {
  await resetAndSeed(page)
  await login(page)

  const recorder = makeRecorder()
  await page.goto("/")
  await probeModalAndDrawer(page, recorder)

  expect(recorder.observations).toEqual([])
})
```

**Planner notes:**
- Prefer a new focused spec for Phase 191 instead of expanding one monolithic probe. Use the manifest and ledger helpers from `admin-group-contracts.spec.js`.
- Use `admin-interactions.spec.js` for actionability, scroll reachability, top-element, click, focus, modal, drawer, step-up, and dropdown probes.
- Every new observation should include the AX187 defect id, surface slug, breakpoint, theme, and tag where possible so the failure maps back to the ledger.

---

### `accrue_admin/e2e/baseline-manifest.js` (config, batch + transform)

**Analog:** existing same file  
**Apply to:** New phase-191 cells, surface declarations, tag filtering, group scope.

**Dimension grammar** (lines 1-44):
```javascript
const ADMIN_BASELINE_DIMENSIONS = {
  breakpoints: ["mobile", "tablet", "desktop"],
  themes: ["light", "dark", "high-contrast"],
  states: [
    "default",
    "loading",
    "empty",
    "overflow",
    "error",
    "modal",
    "drawer",
    "step-up"
  ],
  tags: [
    "actionability",
    "scroll-reachability",
    "layer-z-index",
    "overlay-position",
    "disabled-affordance",
    "focus-restore",
    "copy-recovery",
    "copy-specificity"
  ]
}
```

**Project/theme/owner-phase pattern** (lines 46-58):
```javascript
const ADMIN_BASELINE_PROJECTS = ["chromium", "webkit"]

const ADMIN_BASELINE_THEMES = {
  light: { colorScheme: "light" },
  dark: { colorScheme: "dark" },
  "high-contrast": { colorScheme: "dark" }
}

const OWNER_PHASES = [187, 190, 191]
```

**Page-flow surface pattern** (lines 83-155):
```javascript
pageSurface("invoices", "/invoices", {
  states: ["default", "empty", "overflow"],
  tags: ["actionability", "copy-specificity", "scroll-reachability"],
  ownerPhases: [187, 190, 191]
})
```

**Surface constructor pattern** (lines 199-226):
```javascript
function pageSurface(slug, path, options = {}) {
  return {
    kind: "page",
    slug,
    path,
    ...surfaceOptions(options)
  }
}

function componentSurface(slug, selector, options = {}) {
  return {
    kind: "component",
    slug,
    selector,
    ...surfaceOptions(options)
  }
}
```

**Component group pattern** (lines 229-241):
```javascript
const COMPONENT_GROUPS = [
  componentSurface("data-table", "[data-testid='data-table']", {
    states: ["default", "loading", "empty", "overflow"],
    tags: ["scroll-reachability", "copy-specificity"]
  })
]
```

**Cell id generation** (lines 263-310):
```javascript
function cellId(parts) {
  return [
    parts.kind,
    parts.slug,
    parts.breakpoint,
    parts.theme,
    parts.state
  ].join(":")
}

function cellsForSurface(surface) {
  return surface.breakpoints.flatMap((breakpoint) =>
    surface.themes.flatMap((theme) =>
      surface.states.map((state) => ({
        id: cellId({ kind: surface.kind, slug: surface.slug, breakpoint, theme, state }),
        surface,
        breakpoint,
        theme,
        state,
        tags: surface.tags
      }))
    )
  )
}
```

**Planner notes:**
- Do not invent new dimension names unless the schemas are updated in the same slice.
- Phase 191 should add only the missing page/component cells needed for overlay, focus, scroll, edge fixture, and microcopy stress.
- Keep `ownerPhases` explicit for new or expanded coverage.

---

### E2E Playwright Config and Scripts

**Files:** `accrue_admin/playwright.config.js`, `accrue_admin/package.json`, existing E2E specs  
**Analogs:** existing same files.

**Config pattern** (`playwright.config.js` lines 7-35):
```javascript
module.exports = defineConfig({
  testDir: "./e2e",
  timeout: 60_000,
  expect: {
    timeout: 10_000
  },
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:4011",
    trace: "retain-on-failure",
    screenshot: "only-on-failure"
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } }
  ]
})
```

**Script pattern** (`package.json` lines 4-12):
```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:a11y": "playwright test e2e/admin-a11y.spec.js",
    "test:visual": "playwright test e2e/admin-visuals.spec.js",
    "baseline:parse": "node e2e/parse-baseline.js"
  }
}
```

**Accessibility route inventory pattern** (`admin-a11y.spec.js` lines 50-91):
```javascript
const ROUTES = [
  "/",
  "/customers",
  "/invoices",
  "/subscriptions",
  "/charges",
  "/webhooks"
]

for (const theme of THEMES) {
  test(`admin pages have no critical accessibility violations in ${theme}`, async ({ page }) => {
    await resetAndSeed(page)
    await login(page)
    await setTheme(page, theme)
    for (const route of ROUTES) {
      await page.goto(route)
      await expect(page.locator("main")).toBeVisible()
    }
  })
}
```

**Visual capture route pattern** (`admin-visuals.spec.js` lines 18-79):
```javascript
const ROUTES = [
  { name: "dashboard", path: "/" },
  { name: "customers", path: "/customers" },
  { name: "invoices", path: "/invoices" }
]

for (const route of ROUTES) {
  test(`${route.name} visual baseline`, async ({ page }) => {
    await resetAndSeed(page)
    await login(page)
    await page.goto(route.path)
    await expect(page).toHaveScreenshot(`${route.name}.png`, { fullPage: true })
  })
}
```

**Planner notes:**
- Add a package script only if the phase creates a new spec that needs stable invocation.
- Keep Playwright browser projects aligned with current `chromium` and `webkit`; do not widen matrix without explicit validation need.
- `baseline:parse` already validates artifacts; reuse that entry point for schema-bound artifact checks.

---

### E2E Support Plug, Fixtures, and Server

**Files:** `accrue_admin/test/support/e2e_plug.ex`, `accrue_admin/test/support/e2e_fixtures.ex`, `accrue_admin/test/support/e2e_server.ex`, `accrue_admin/test/accrue_admin/e2e_fixtures_test.exs`  
**Analogs:** existing same files.

**Plug routing and JSON helper** (`e2e_plug.ex` lines 36-92):
```elixir
post "/__e2e/reset" do
  AccrueAdmin.E2E.Fixtures.reset()
  json(conn, %{ok: true})
end

post "/__e2e/seed" do
  scenario = conn.body_params["scenario"] || "dashboard"
  AccrueAdmin.E2E.Fixtures.seed(scenario)
  json(conn, %{ok: true, scenario: scenario})
end

defp json(conn, payload) do
  conn
  |> put_resp_content_type("application/json")
  |> send_resp(200, Jason.encode!(payload))
end
```

**Login-member route pattern** (`e2e_plug.ex` lines 94-102):
```elixir
post "/__e2e/login-member" do
  account_id = conn.body_params["account_id"] || "acct_admin"
  role = conn.body_params["role"] || "admin"
  member = AccrueAdmin.E2E.Fixtures.member_for(account_id, role)
  json(conn, %{ok: true, member: member})
end
```

**Reset pattern** (`e2e_fixtures.ex` lines 32-40):
```elixir
def reset do
  Repo.delete_all(Accrue.Event)
  Repo.delete_all(Accrue.Invoice)
  Repo.delete_all(Accrue.Subscription)
  Repo.delete_all(Accrue.Customer)
  Repo.delete_all(Accrue.Account)
  :ok
end
```

**Scenario pattern** (`e2e_fixtures.ex` lines 43-79, 81-142, 144-245):
```elixir
def seed("dashboard") do
  reset()
  account = insert_account(%{id: "acct_admin"})
  insert_customer(account, %{id: "cus_dashboard"})
  :ok
end

def seed("operator-flows") do
  reset()
  account = insert_account(%{id: "acct_admin"})
  seed_operator_flows(account)
  :ok
end

def seed("edge-overflow") do
  reset()
  account = insert_account(%{id: "acct_admin"})
  seed_edge_overflow(account)
  :ok
end
```

**Count/assertion helpers** (`e2e_fixtures.ex` lines 247-258):
```elixir
def counts do
  %{
    accounts: Repo.aggregate(Accrue.Account, :count),
    customers: Repo.aggregate(Accrue.Customer, :count),
    subscriptions: Repo.aggregate(Accrue.Subscription, :count),
    invoices: Repo.aggregate(Accrue.Invoice, :count)
  }
end
```

**Insert helper style** (`e2e_fixtures.ex` lines 260-429):
```elixir
defp insert_customer(account, attrs) do
  defaults = %{
    account_id: account.id,
    email: "customer@example.com",
    name: "E2E Customer"
  }

  Repo.insert!(struct(Accrue.Customer, Map.merge(defaults, attrs)))
end
```

**E2E server runtime pattern** (`e2e_server.ex` lines 6-21, 23-48, 64-71, 86-93):
```elixir
if Mix.env() == :test do
  Application.ensure_all_started(:accrue_admin)
end

config = [
  http: [ip: {127, 0, 0, 1}, port: port],
  server: true
]

Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

defmodule AccrueAdmin.E2E.FakeProcessor do
  def process(_event), do: {:ok, %{id: "fake"}}
end
```

**Fixture test pattern** (`e2e_fixtures_test.exs` lines 23-44, 98-140):
```elixir
setup do
  AccrueAdmin.E2E.Fixtures.reset()
  :ok
end

test "edge overflow scenario creates route-backed records" do
  assert :ok = AccrueAdmin.E2E.Fixtures.seed("edge-overflow")
  counts = AccrueAdmin.E2E.Fixtures.counts()
  assert counts.customers > 0
  assert counts.invoices > 0
end
```

**Planner notes:**
- Add Phase 191 fixture stress data as new scenario clauses or helpers inside `E2E.Fixtures`, not ad hoc Playwright setup.
- Every fixture scenario must be deterministic and reset first unless explicitly testing idempotency.
- Add ExUnit coverage for every new E2E fixture scenario before relying on it in Playwright.

---

### Host Seed and Idempotency Patterns

**Files:** `examples/accrue_host/priv/repo/seeds.exs`, `examples/accrue_host/priv/repo/seeds/*.exs`, host seed tests  
**Analogs:** existing same files.

**Seed helper pattern** (`seeds.exs` lines 12-30, 32-38, 40-79, 81-97):
```elixir
defmodule AccrueHost.SeedHelpers do
  def upsert!(schema, attrs, conflict_target) do
    changeset = schema.changeset(struct(schema), attrs)

    Repo.insert!(
      changeset,
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: conflict_target
    )
  end

  def cents(amount), do: Decimal.new(amount)
end
```

**Seed file orchestration** (`seeds.exs` lines 100-109):
```elixir
[
  "seeds/showcase.exs",
  "seeds/edge_states.exs",
  "seeds/background_data.exs"
]
|> Enum.each(fn path ->
  Code.eval_file(Path.join(__DIR__, path))
end)
```

**Edge-state upsert pattern** (`edge_states.exs` lines 35-49):
```elixir
account =
  upsert!(Accrue.Account, %{
    id: "acct_edge_states",
    name: "Edge States Showcase"
  }, [:id])
```

**Fixture stress examples** (`edge_states.exs` lines 56-64, 73-95, 102-111, 138-154):
```elixir
upsert!(Accrue.Customer, %{
  id: "cus_long_name",
  name: String.duplicate("International Enterprise Holdings ", 5),
  email: "long-name@example.com"
}, [:id])

upsert!(Accrue.Subscription, %{
  id: "sub_at_risk",
  status: "past_due",
  current_period_end: DateTime.add(now, -86_400, :second)
}, [:id])

upsert!(Accrue.Invoice, %{
  id: "inv_jpy_zero_decimal",
  currency: "jpy",
  total: 12_345
}, [:id])
```

**Showcase seed comments and upsert helpers** (`showcase.exs` lines 1-13, 69-128):
```elixir
# Showcase seed data is intentionally human-readable and idempotent.

defp upsert_coupon(attrs) do
  upsert!(Accrue.Coupon, attrs, [:id])
end

defp record_event(type, payload) do
  upsert!(Accrue.Event, %{type: type, payload: payload}, [:id])
end
```

**Bulk background data pattern** (`background_data.exs` lines 105-113):
```elixir
Repo.insert_all(
  Accrue.Customer,
  rows,
  on_conflict: {:replace_all_except, [:id, :inserted_at]},
  conflict_target: [:id]
)
```

**Idempotency test pattern** (`seeds_idempotency_test.exs` lines 26-88, 91-102):
```elixir
setup do
  Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
  :ok
end

test "seeds can be run repeatedly without duplicate records" do
  run_seeds()
  first_counts = counts()

  run_seeds()
  second_counts = counts()

  assert second_counts == first_counts
end
```

**Planner notes:**
- Use `upsert!` or `Repo.insert_all(... on_conflict ...)` for all host seed additions.
- Use extreme-but-realistic values: long names, zero-decimal currencies, past-due states, canceling states, large tables, repeated events.
- Update seed idempotency tests if adding new schemas or counts that should stay stable across repeated seed runs.

---

### JavaScript Hook Registration and Focus/Overlay Hooks

**Files:** `accrue_admin/assets/js/app.js`, `accrue_admin/assets/js/hooks/*.js`, `accrue_admin/test/js/command_palette_test.mjs`  
**Analogs:** existing hook files.

**Hook import/registration pattern** (`app.js` lines 1-8, 18-29):
```javascript
import Dropdown from "./hooks/dropdown"
import CommandPalette from "./hooks/command_palette"
import AccrueShellNav from "./hooks/accrue_shell_nav"

let Hooks = {
  Dropdown,
  CommandPalette,
  AccrueShellNav
}
```

**Dropdown lifecycle pattern** (`dropdown.js` lines 1-22):
```javascript
const Dropdown = {
  mounted() {
    this.handleClickAway = (event) => {
      if (!this.el.contains(event.target)) {
        this.pushEventTo(this.el, "close", {})
      }
    }

    document.addEventListener("click", this.handleClickAway)
  },

  destroyed() {
    document.removeEventListener("click", this.handleClickAway)
  }
}
```

**Command palette focus restore pattern** (`command_palette.js` lines 20-44):
```javascript
mounted() {
  this.lastFocusedElement = null

  this.handleOpen = () => {
    this.lastFocusedElement = document.activeElement
    this.focusInput()
  }

  this.handleClose = () => {
    if (this.lastFocusedElement && this.lastFocusedElement.focus) {
      this.lastFocusedElement.focus()
    }
  }
}
```

**Global keyboard pattern** (`command_palette.js` lines 52-62):
```javascript
this.handleKeydown = (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
    event.preventDefault()
    this.pushEvent("open_search", {})
  }
}

window.addEventListener("keydown", this.handleKeydown)
```

**Active selection pattern** (`command_palette.js` lines 115-127):
```javascript
selectActive() {
  const item = this.el.querySelector("[data-active='true']")
  if (item) {
    item.click()
  }
}
```

**Responsive shell nav pattern** (`accrue_shell_nav.js` lines 6-29):
```javascript
mounted() {
  this.handleResize = () => {
    if (window.innerWidth >= 1024) {
      this.pushEventTo(this.el, "close_mobile_nav", {})
    }
  }

  window.addEventListener("resize", this.handleResize)
}

destroyed() {
  window.removeEventListener("resize", this.handleResize)
}
```

**Hook unit test pattern** (`command_palette_test.mjs` lines 29-70):
```javascript
test("restores focus when closing", () => {
  const previous = document.createElement("button")
  document.body.append(previous)
  previous.focus()

  hook.mounted()
  hook.handleOpen()
  hook.handleClose()

  assert.equal(document.activeElement, previous)
})
```

**Planner notes:**
- There is no exact existing generic `focus_trap.js`. If a new primitive is needed, copy lifecycle cleanup discipline from `dropdown.js`, focus restore from `command_palette.js`, and server-driven events from existing LiveView components.
- Do not register a hook unless `app.js` imports and includes it in `Hooks`.
- Add a JS unit test for any new reusable focus primitive.

---

### Overlay, Focus, Scroll, and Layering Components

**Files:** `detail_drawer.ex`, `step_up_auth_modal.ex`, `dropdown_menu.ex`, `global_search.ex`, `app_shell.ex`, `data_table.ex`, `empty_state.ex`, `flash_group.ex`, `app.css`, `theme.css`  
**Analogs:** existing same files.

**Detail drawer API and overlay shell** (`detail_drawer.ex` lines 8-20, 30-49, 57-75):
```elixir
attr :id, :string, required: true
attr :open, :boolean, default: false
attr :title, :string, required: true
slot :inner_block, required: true
slot :footer

def detail_drawer(assigns) do
  ~H"""
  <section
    id={@id}
    role="dialog"
    aria-modal="true"
    aria-labelledby={"#{@id}-title"}
    class={["accrue-detail-drawer", @open && "is-open"]}
  >
  """
end
```

**Step-up modal focus pattern** (`step_up_auth_modal.ex` lines 20-31, 40-64):
```elixir
def step_up_auth_modal(assigns) do
  ~H"""
  <div
    id={@id}
    role="dialog"
    aria-modal="true"
    phx-mounted={JS.push_focus()}
    phx-remove={JS.pop_focus()}
  >
    <form phx-submit={@submit_event}>
      <button type="submit"><%= @confirm_label %></button>
      <button type="button" phx-click={@cancel_event}>Cancel</button>
    </form>
  </div>
  """
end
```

**Dropdown component pattern** (`dropdown_menu.ex` lines 13-29):
```elixir
attr :id, :string, required: true
attr :label, :string, required: true
slot :item, required: true

def dropdown_menu(assigns) do
  ~H"""
  <div id={@id} phx-hook="Dropdown" class="accrue-dropdown">
    <button type="button" aria-haspopup="menu"><%= @label %></button>
    <div role="menu"><%= render_slot(@item) %></div>
  </div>
  """
end
```

**Global search state/events/render pattern** (`global_search.ex` lines 10-97, 130-253):
```elixir
def update(assigns, socket) do
  socket =
    socket
    |> assign(assigns)
    |> assign_new(:open?, fn -> false end)
    |> assign_new(:query, fn -> "" end)

  {:ok, socket}
end

def handle_event("open_search", _params, socket) do
  {:noreply, assign(socket, open?: true)}
end

def render(assigns) do
  ~H"""
  <div id="global-search" phx-hook="CommandPalette">
    <div :if={@open?} role="dialog" aria-modal="true">
      <input type="search" value={@query} />
      <div role="listbox"><%= render_slot(@results) %></div>
    </div>
  </div>
  """
end
```

**App shell slot/layout pattern** (`app_shell.ex` lines 28-52):
```elixir
slot :sidebar
slot :topbar
slot :inner_block, required: true

def app_shell(assigns) do
  ~H"""
  <div class="accrue-shell" phx-hook="AccrueShellNav">
    <aside class="accrue-shell__sidebar"><%= render_slot(@sidebar) %></aside>
    <main id="main-content"><%= render_slot(@inner_block) %></main>
  </div>
  """
end
```

**Data table state and event pattern** (`data_table.ex` lines 15-118, 123-270, 465-471):
```elixir
def update(assigns, socket) do
  socket =
    socket
    |> assign(assigns)
    |> assign(:query, assigns[:query] || "")
    |> reload_rows()

  {:ok, socket}
end

def handle_event("search", %{"q" => query}, socket) do
  {:noreply, socket |> assign(:query, query) |> reload_rows()}
end

defp filtered_empty?(rows, query) do
  rows == [] and String.trim(query || "") != ""
end
```

**Empty state pattern** (`empty_state.ex` lines 1-13, 26-35):
```elixir
attr :title, :string, required: true
attr :description, :string, required: true
slot :action

def empty_state(assigns) do
  ~H"""
  <section class="accrue-empty-state">
    <h2><%= @title %></h2>
    <p><%= @description %></p>
    <%= render_slot(@action) %>
  </section>
  """
end
```

**Flash stacking pattern** (`flash_group.ex` lines 12-23):
```elixir
def flash_group(assigns) do
  ~H"""
  <div class="accrue-flash-group" aria-live="polite">
    <%= for {kind, message} <- @flash do %>
      <div class={"accrue-flash accrue-flash--#{kind}"}><%= message %></div>
    <% end %>
  </div>
  """
end
```

**Theme token source of truth** (`theme.css` lines 16-33, 128-135, 173-214):
```css
:root {
  --accrue-space-1: 0.25rem;
  --accrue-space-2: 0.5rem;
  --accrue-radius-sm: 0.25rem;
  --accrue-z-dropdown: 30;
  --accrue-z-drawer: 40;
  --accrue-z-modal: 50;
  --accrue-z-toast: 60;
}

:focus-visible {
  outline: 2px solid var(--accrue-focus-ring);
  outline-offset: 2px;
}
```

**Dark/high-contrast/reduced-motion pattern** (`theme.css` lines 218-275, 406-433):
```css
:root[data-theme="dark"] {
  color-scheme: dark;
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

**Overlay and layer CSS pattern** (`app.css` lines 1122-1178, 1453-1465, 3444-3483):
```css
.accrue-detail-drawer {
  position: fixed;
  inset: 0 0 0 auto;
  z-index: var(--accrue-z-drawer);
}

.accrue-step-up-modal {
  position: fixed;
  inset: 0;
  z-index: var(--accrue-z-modal);
}

.accrue-flash-group {
  position: fixed;
  z-index: var(--accrue-z-toast);
}
```

**Data table/dropdown responsive pattern** (`app.css` lines 2018-2190):
```css
.accrue-data-table {
  overflow-x: auto;
}

.accrue-dropdown__menu {
  position: absolute;
  z-index: var(--accrue-z-dropdown);
}
```

**Command palette and mobile shell pattern** (`app.css` lines 2303-2445, 2545-2558):
```css
.accrue-command-palette {
  position: fixed;
  inset: 0;
  z-index: var(--accrue-z-modal);
}

@media (max-width: 1023px) {
  .accrue-shell__sidebar {
    position: fixed;
  }
}
```

**Planner notes:**
- Keep layering changes tied to existing `--accrue-z-*` tokens. Do not create local z-index literals unless a token is added.
- Use `JS.push_focus()`/`JS.pop_focus()` for server-rendered dialogs where possible.
- For scroll fixes, prefer stable overflow containers (`overflow-x: auto`, max-height, sticky headers) over content clipping.
- Component copy should flow through `AccrueAdmin.Copy` where a page already uses that pattern.

---

### LiveView Page Flow and Microcopy Patterns

**Files:** `page_live.ex`, `live/*s_live.ex`, `live/*_live.ex`, `live/analytics/recovery_live.ex`, `copy*.ex`  
**Analogs:** existing LiveViews and copy modules.

**Static page shell pattern** (`page_live.ex` lines 9-26, 31-81):
```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:page_title, "Accrue Admin")
   |> assign(:active_nav, :dashboard)}
end

def render(assigns) do
  ~H"""
  <.app_shell active_nav={@active_nav}>
    <section class="accrue-page">
      <h1><%= @page_title %></h1>
    </section>
  </.app_shell>
  """
end
```

**List LiveView pattern** (`customers_live.ex` lines 4-45, 50-128, 134-214):
```elixir
alias AccrueAdmin.Components.DataTable
alias AccrueAdmin.Copy

def mount(_params, _session, socket) do
  {:ok, assign(socket, :page_title, "Customers")}
end

def handle_params(params, _uri, socket) do
  {:noreply, assign(socket, :filters, params)}
end

def render(assigns) do
  ~H"""
  <.live_component
    module={DataTable}
    id="customers-table"
    rows={@customers}
    empty={Copy.index_empty(:customers)}
  />
  """
end
```

**Default-route normalization pattern** (`invoices_live.ex` lines 17-47):
```elixir
def handle_params(params, _uri, socket) do
  if missing_default_filter?(params) do
    {:noreply, push_patch(socket, to: ~p"/invoices?status=open")}
  else
    {:noreply, assign_invoice_state(socket, params)}
  end
end
```

**Queue empty-state helper** (`invoices_live.ex` lines 293-309):
```elixir
defp queue_empty_state(:retries) do
  %{
    title: "No retries queued",
    description: "Failed invoices that need another attempt will appear here."
  }
end
```

**Detail action and step-up event pattern** (`invoice_live.ex` lines 32-99, 576-645):
```elixir
def handle_event("prepare_action", %{"action" => action}, socket) do
  {:noreply, assign(socket, pending_action: action, step_up?: true)}
end

def handle_event("confirm_step_up", %{"code" => code}, socket) do
  with :ok <- verify_step_up(socket.assigns.current_member, code),
       {:ok, invoice} <- execute_invoice_action(socket.assigns.invoice, socket.assigns.pending_action) do
    {:noreply,
     socket
     |> put_flash(:info, "Invoice updated")
     |> assign(invoice: invoice, pending_action: nil, step_up?: false)}
  else
    {:error, reason} -> {:noreply, assign(socket, step_up_error: reason)}
  end
end
```

**Detail render and modal inclusion pattern** (`invoice_live.ex` lines 189-318, 467-471):
```elixir
<section
  class="accrue-detail"
  phx-window-keydown="dismiss_action"
  phx-key="escape"
>
  <.detail_drawer id="invoice-action-drawer" open={@drawer_open?} title="Invoice action">
    ...
  </.detail_drawer>

  <.step_up_auth_modal
    :if={@step_up?}
    id="invoice-step-up"
    submit_event="confirm_step_up"
    cancel_event="cancel_step_up"
  />
</section>
```

**Webhook replay confirmation pattern** (`webhook_live.ex` lines 65-105, 156-193, 291-309, 340-365):
```elixir
def handle_event("prepare_replay", _params, socket) do
  {:noreply, assign(socket, replay_confirmation?: true)}
end

def handle_event("confirm_replay", _params, socket) do
  with {:ok, event} <- replay_webhook(socket.assigns.webhook) do
    record_audit(socket.assigns.current_member, event)
    {:noreply, put_flash(socket, :info, replay_copy(:success))}
  end
end
```

**Charge refund step-up pattern** (`charge_live.ex` lines 29-92, 107-111, 212-253, 293-297, 358-483, 614-628):
```elixir
def handle_event("prepare_refund", params, socket) do
  {:noreply, assign(socket, refund_form: params, step_up?: true)}
end

def handle_event("cancel_step_up", _params, socket) do
  {:noreply, assign(socket, step_up?: false, refund_form: nil)}
end

defp refund_copy(:confirm) do
  "Confirm refund"
end
```

**Recovery page filters/window pattern** (`analytics/recovery_live.ex` lines 25-67, 90-152, 178-210):
```elixir
def handle_params(params, _uri, socket) do
  window = recovery_window(params["window"])
  {:noreply, socket |> assign(:window, window) |> assign_shell()}
end

defp recovery_window("90d"), do: :last_90_days
defp recovery_window(_), do: :last_30_days
```

**Copy delegation pattern** (`copy.ex` lines 9-18, 395-424, 451-590, 598-730):
```elixir
defdelegate invoice_action(action), to: AccrueAdmin.Copy.Invoice
defdelegate subscription_action(action), to: AccrueAdmin.Copy.Subscription

def index_empty(:invoices) do
  %{
    title: "No invoices yet",
    description: "Invoices appear here when billing starts."
  }
end
```

**Domain copy patterns** (`copy/invoice.ex` lines 6-10, 122-137, 181-203; `copy/subscription.ex` lines 20-64; `copy/locked.ex` lines 6-20):
```elixir
def list_empty do
  %{title: "No invoices yet", description: "Invoices appear here after billing starts."}
end

def action(:retry), do: %{label: "Retry payment", confirm: "Retry this payment now?"}

def locked_action(:webhook_replay) do
  "You need replay permission to send this webhook again."
end
```

**Brand voice constraints** (`brandbook/voice.md` lines 11-17, 57, 100-119; `brandbook/copy.md` lines 194-240):
```markdown
- Plainspoken, specific, and calm.
- Error and empty states should explain what happened and what the operator can do next.
- Avoid cute, vague, or blame-oriented words.
```

**Planner notes:**
- Page-flow fixes should stay inside the page/component that owns the broken interaction unless a shared primitive is clearly duplicated.
- Microcopy should use specific recovery guidance: what happened, why the state is safe, and the next action.
- Detail pages with destructive or money-moving actions should follow the existing prepare -> confirm/step-up -> execute -> audit pattern.

---

### Component, LiveView, and Hook Test Patterns

**Files:** `test/js/command_palette_test.mjs`, `test/accrue_admin/components/*_test.exs`, `test/accrue_admin/live/*_test.exs`  
**Analogs:** existing tests.

**JS hook test setup** (`command_palette_test.mjs` lines 29-70):
```javascript
beforeEach(() => {
  document.body.innerHTML = `<div id="palette"><input type="search" /></div>`
})

test("opens with keyboard shortcut", () => {
  hook.mounted()
  window.dispatchEvent(new KeyboardEvent("keydown", { key: "k", metaKey: true }))
  assert.equal(pushes[0].event, "open_search")
})
```

**Data table component test pattern** (`data_table_test.exs` lines 7-123, 238-314, 433-470):
```elixir
test "renders empty state when no rows match filters" do
  html =
    render_component(DataTable, %{
      id: "customers-table",
      rows: [],
      query: "missing",
      empty: %{title: "No matches", description: "Try another search."}
    })

  assert html =~ "No matches"
  assert html =~ "Try another search."
end
```

**Global search contract tests** (`global_search_test.exs` lines 52-110):
```elixir
test "renders command dialog with accessible labels" do
  html = render_component(GlobalSearch, %{id: "global-search", open?: true})

  assert html =~ ~s(role="dialog")
  assert html =~ ~s(aria-modal="true")
end
```

**App shell render contract** (`app_shell_test.exs` lines 10-60):
```elixir
test "renders skip link and main region" do
  html = render_component(AppShell, %{active_nav: :dashboard})

  assert html =~ "Skip to content"
  assert html =~ ~s(id="main-content")
end
```

**LiveView step-up setup and assertions** (`charge_live_test.exs` lines 13-88, 104-210, 212-318):
```elixir
defmodule AuthAdapter do
  def verify_step_up(_member, "123456"), do: :ok
  def verify_step_up(_member, _code), do: {:error, :invalid_code}
end

setup do
  member = insert_member(role: :admin)
  %{member: member}
end

test "requires step-up before refund", %{conn: conn, member: member} do
  {:ok, view, _html} = live(conn, ~p"/charges/ch_test")

  view |> element("button", "Refund") |> render_click()
  assert has_element?(view, "#charge-step-up")
end
```

**Planner notes:**
- Add LiveView tests for any new prepare/cancel/confirm event or Escape-key dismissal.
- Add component tests for new empty/copy states where copy determines recovery guidance.
- Use existing fake auth/payment adapters when exercising step-up, refund, replay, or invoice actions.

---

### Phase 187 Ledger and Phase 190 Handoff Patterns

**Files:** `187/schemas/*.json`, `187/defects.ndjson`, `190-PHASE-191-HANDOFF.md`, `190-GROUP-CONTRACTS.md`  
**Analogs:** existing artifacts.

**Defect schema required fields** (`defect.schema.json` lines 8-24):
```json
{
  "required": [
    "id",
    "phase",
    "surface",
    "severity",
    "status",
    "owner_phase",
    "tags",
    "description"
  ]
}
```

**Defect tag/status grammar** (`defect.schema.json` lines 75-117):
```json
{
  "tags": {
    "items": {
      "enum": [
        "actionability",
        "scroll-reachability",
        "layer-z-index",
        "overlay-position",
        "disabled-affordance",
        "focus-restore",
        "copy-recovery",
        "copy-specificity"
      ]
    }
  },
  "owner_phase": { "enum": [187, 190, 191] },
  "status": { "enum": ["open", "resolved", "deferred"] }
}
```

**Baseline cell schema grammar** (`baseline-cell.schema.json` lines 8-22, 48-84, 104-145):
```json
{
  "required": ["id", "surface", "breakpoint", "theme", "state", "tags"],
  "properties": {
    "breakpoint": { "enum": ["mobile", "tablet", "desktop"] },
    "theme": { "enum": ["light", "dark", "high-contrast"] },
    "state": { "enum": ["default", "loading", "empty", "overflow", "error", "modal", "drawer", "step-up"] }
  }
}
```

**Phase 190 handoff scope** (`190-PHASE-191-HANDOFF.md` lines 30-97):
```markdown
## D-30 Group Contract Handoff

- Start with representative page-flow checks.
- Validate overlay/focus/scroll defects against the normalized ledger.
- Preserve AX187 ids in follow-up artifacts and commit messages where useful.
```

**Group contract artifact shape** (`190-GROUP-CONTRACTS.md` lines 11-20, 50-62, 68-101):
```markdown
| Group | Representative Surface | Required Checks | Owner Phase |
|-------|------------------------|-----------------|-------------|
| Overlay layering | detail drawer / step-up | z-index, focus restore, Escape | 191 |

## Handoff Tags
- disabled-affordance
- layer-z-index
- overlay-position
- scroll-reachability
```

**Ledger sample facts from `defects.ndjson`:**
- `owner_phase: 191` has 178 rows: 70 high severity and 108 medium severity.
- Highest-frequency Phase 191 tags include `actionability` (19), `scroll-reachability` (6), `layer-z-index` (5), `overlay-position` (4), `disabled-affordance` (4), `focus-restore` (4), `copy-recovery` (4), and `copy-specificity` (4).
- Representative AX187 ids inspected for Phase 191 mapping: `AX187-049`, `AX187-097`, `AX187-102`, `AX187-113`, `AX187-116`, `AX187-117`, `AX187-118`, `AX187-436`, `AX187-440`, `AX187-442`.

**Planner notes:**
- Preserve existing schema enums unless the planner explicitly creates a schema migration.
- Update handoff/contract artifacts only if the phase changes coverage truth, not as working notes.
- New E2E failures should point to normalized AX187 defect ids and the manifest cell id.

## Shared Patterns

### Authentication and Session Setup

**Source:** `accrue_admin/test/support/e2e_plug.ex` and LiveView tests  
**Apply to:** Playwright specs, LiveView tests, step-up/replay/refund flows.

```javascript
await page.request.post("/__e2e/reset")
await page.request.post("/__e2e/seed", { data: { scenario: "operator-flows" } })
await page.request.post("/__e2e/login", {
  data: { account_id: "acct_admin", role: "admin" }
})
```

```elixir
setup do
  member = insert_member(role: :admin)
  %{member: member}
end
```

### Error and Recovery Copy

**Source:** `accrue_admin/lib/accrue_admin/copy.ex`, `copy/invoice.ex`, `copy/locked.ex`, brandbook  
**Apply to:** Empty states, filtered-empty states, disabled actions, failed step-up, locked replay/refund actions.

```elixir
%{
  title: "No invoices yet",
  description: "Invoices appear here when billing starts."
}
```

Keep copy specific, calm, and action-oriented. Avoid generic "Something went wrong" when a more precise recovery is available.

### Overlay and Focus Restoration

**Source:** `step_up_auth_modal.ex`, `command_palette.js`, `detail_drawer.ex`, `app.css`, `theme.css`  
**Apply to:** Modal, drawer, command palette, dropdown, mobile nav, flash layering.

```elixir
phx-mounted={JS.push_focus()}
phx-remove={JS.pop_focus()}
```

```javascript
this.lastFocusedElement = document.activeElement
if (this.lastFocusedElement && this.lastFocusedElement.focus) {
  this.lastFocusedElement.focus()
}
```

### Scroll and Overflow

**Source:** `data_table.ex`, `app.css`, `admin-group-contracts.spec.js`  
**Apply to:** Wide tables, drawers with long content, mobile nav, command palette results, route stress fixtures.

```css
.accrue-data-table {
  overflow-x: auto;
}
```

Use Playwright layout facts to detect body overflow, unreachable actions, and hidden focusable controls after fixture expansion.

### Idempotent Fixture Data

**Source:** `E2E.Fixtures`, host seed helpers, seed idempotency tests  
**Apply to:** Any new Phase 191 E2E or host seed fixture.

```elixir
Repo.insert!(
  changeset,
  on_conflict: {:replace_all_except, [:id, :inserted_at]},
  conflict_target: [:id]
)
```

### Artifact Validation

**Source:** `baseline-manifest.js`, `baseline-cell.schema.json`, `defect.schema.json`, `package.json` `baseline:parse`  
**Apply to:** New cells, group-contract references, resolved defect ledger rows.

```javascript
const cells = ADMIN_BASELINE_MANIFEST.flatMap(cellsForSurface)
expect(cells.map((cell) => cell.id)).toContain("page:invoices:mobile:dark:overflow")
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `accrue_admin/assets/js/hooks/focus_trap.js` | hook | event-driven focus containment | No generic reusable focus-trap hook exists. Closest patterns are `command_palette.js` focus restore and LiveView `JS.push_focus()` / `JS.pop_focus()` in `step_up_auth_modal.ex`. |

## Warnings and Constraints

- No `AGENTS.md` was found in the working directory.
- No project-local skill files were found under `.codex/skills/` or `.agents/skills/`.
- `accrue_admin/assets/css/app.css` is larger than 2,000 lines; only targeted non-overlapping ranges were inspected for overlay, table, dropdown, command palette, mobile shell, focus, disabled, and layer-token patterns.
- There is no exact existing Phase 191 page-flow regression spec. Use `admin-group-contracts.spec.js` for manifest/ledger grouping and `admin-interactions.spec.js` for interaction probes.
- `theme.css` is the token source of truth. Treat token changes as shared design-system changes, not one-off page fixes.

## Metadata

**Analog search scope:** `accrue_admin/e2e`, `accrue_admin/test/support`, `accrue_admin/test`, `accrue_admin/assets`, `accrue_admin/lib/accrue_admin`, `examples/accrue_host`, `.planning/phases/187-admin-ux-audit`, `.planning/phases/190-reconcile-187-audit-ledger-group-dedupe-schema`  
**Primary search tools:** `rg --files`, `rg`, targeted line-number reads  
**Files scanned:** 80+ project and planning files; 30+ analog files read for excerpts  
**Pattern extraction date:** 2026-06-18
