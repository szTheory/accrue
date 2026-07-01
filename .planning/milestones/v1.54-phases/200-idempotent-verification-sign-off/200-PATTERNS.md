# Phase 200: Idempotent verification & sign-off - Pattern Map

**Mapped:** 2026-06-30
**Files analyzed:** 28 new/modified source, CI, and phase artifact files
**Analogs found:** 28 / 28

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/lib/accrue_admin/dev/storybook.ex` | config/provider | request-response | `accrue_admin/lib/accrue_admin/dev/storybook.ex` | exact-self |
| `accrue_admin/storybook/_support/registry_story.ex` | utility/provider | transform | `accrue_admin/storybook/_support/registry_story.ex` | exact-self |
| `accrue_admin/storybook/components/*.story.exs` | component/story | transform, request-response | `accrue_admin/storybook/_support/registry_story.ex` | role-match |
| `accrue_admin/storybook/groups/*.story.exs` | component/story | transform, request-response | `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | role-match |
| `accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs` | test | transform, request-response | `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` | exact-role |
| `accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs` or `accrue_admin/test/accrue_admin/assets_test.exs` | test | request-response, file-I/O | `accrue_admin/test/accrue_admin/assets_test.exs` | exact-role |
| `accrue_admin/test/accrue_admin/theme_test.exs` | test | transform, file-I/O | `accrue_admin/test/accrue_admin/theme_test.exs` | exact-self |
| `accrue_admin/e2e/admin-storybook-a11y-phase200.spec.js` | test | request-response, browser | `accrue_admin/e2e/admin-a11y.spec.js` | exact-role |
| `accrue_admin/e2e/admin-page-flow-phase200.spec.js` | test | request-response, browser | `accrue_admin/e2e/admin-page-flow-phase191.spec.js` | exact-role |
| `accrue_admin/e2e/phase200-scorecard.mjs` | utility/script | batch, transform, file-I/O | `accrue_admin/e2e/phase192-scorecard.mjs` | exact-role |
| `scripts/ci/verify_phase200_scorecard.mjs` | utility/script | batch, file-I/O | `scripts/ci/verify_phase192_scorecard.mjs` | exact-role |
| `scripts/ci/verify_phase200_signoff.mjs` | utility/script | batch, file-I/O | `scripts/ci/verify_phase192_signoff.mjs` | exact-role |
| `scripts/ci/verify_phase200_admin_guardrails.sh` | utility/script | batch, process orchestration | `scripts/ci/verify_phase192_admin_guardrails.sh` | exact-role |
| `scripts/ci/verify_phase200_ci_contract.sh` | utility/script | batch, source guard | `scripts/ci/verify_phase192_ci_contract.sh` | exact-role |
| `scripts/ci/verify_phase200_guardrail_contract.sh` | utility/script | batch, source guard | `scripts/ci/verify_phase192_guardrail_contract.sh` | exact-role |
| `accrue_admin/package.json` | config | batch command aliases | `accrue_admin/package.json` | exact-self |
| `.github/workflows/ci.yml` | config | CI batch | `.github/workflows/ci.yml` | exact-self |
| `.planning/phases/200-idempotent-verification-sign-off/baseline.union.cells.json` | artifact | batch, file-I/O | `accrue_admin/e2e/phase192-scorecard.mjs` | role-match |
| `.planning/phases/200-idempotent-verification-sign-off/final.cells.json` | artifact | batch, file-I/O | `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/final.cells.json` | exact-shape |
| `.planning/phases/200-idempotent-verification-sign-off/scorecard.delta.json` | artifact | batch, file-I/O | `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/scorecard.delta.json` | exact-shape |
| `.planning/phases/200-idempotent-verification-sign-off/regressions.ndjson` | artifact | batch, file-I/O | `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/regressions.ndjson` | exact-shape |
| `.planning/phases/200-idempotent-verification-sign-off/artifacts.manifest.json` | artifact | batch, file-I/O | `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/artifacts.manifest.json` | exact-shape |
| `.planning/phases/200-idempotent-verification-sign-off/200-SCORECARD.md` | artifact/report | batch, summary | `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/192-SCORECARD.md` | exact-role |
| `.planning/phases/200-idempotent-verification-sign-off/200-STORYBOOK-COVERAGE.md` | artifact/report | batch, summary | `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` plus `192-SCORECARD.md` | role-match |
| `.planning/phases/200-idempotent-verification-sign-off/200-SIGN-OFF.md` | artifact/report | human sign-off, batch | `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/192-SIGN-OFF.md` | exact-role |
| `.planning/phases/200-idempotent-verification-sign-off/200-VERIFICATION.md` | artifact/report | batch, summary | `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/192-VERIFICATION.md` | exact-role |
| `.planning/REQUIREMENTS.md` | planning config | state reconciliation | `.planning/REQUIREMENTS.md` | exact-self |
| `.planning/STATE.md` | planning config | state reconciliation | `.planning/STATE.md` | exact-self |

## Pattern Assignments

### `accrue_admin/lib/accrue_admin/dev/storybook.ex` (config/provider, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/dev/storybook.ex`

**Imports/config pattern** (lines 1-19):
```elixir
if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.Storybook do
    @moduledoc false

    use PhoenixStorybook,
      otp_app: :accrue_admin,
      content_path: Path.expand("../../../../storybook", __DIR__),
      css_path: AccrueAdmin.Assets.hashed_path(:storybook_css, "/dev/storybook"),
      js_path: AccrueAdmin.Assets.hashed_path(:storybook_js, "/dev/storybook"),
      sandbox_class: "accrue-admin",
      color_mode_sandbox_dark_class: "ax-theme-dark-shim"
  end
end
```

**Phase 200 application:** keep the `Mix.env() != :prod` guard and committed asset paths. Add `color_mode: true` next to `color_mode_sandbox_dark_class`, matching the Phase 200 decision and research example. Do not add a Tailwind build path.

---

### `accrue_admin/storybook/_support/registry_story.ex` (utility/provider, transform)

**Analog:** `accrue_admin/storybook/_support/registry_story.ex`

**Imports and SSOT pattern** (lines 1-13):
```elixir
if Mix.env() != :prod do
  defmodule AccrueAdmin.Storybook.RegistryStory do
    @moduledoc false

    alias PhoenixStorybook.Stories.Variation
```

**Registry-to-variation transform pattern** (lines 21-43):
```elixir
@spec variations_for(String.t()) :: [Variation.t()]
def variations_for(family) when is_binary(family) do
  family
  |> AccrueAdmin.Dev.ComponentRegistry.variants_for()
  |> Enum.flat_map(fn entry ->
    specimens = entry[:specimens] || []

    specimens
    |> Enum.with_index()
    |> Enum.map(fn {specimen, idx} ->
      id_str =
        entry.variant
        |> String.replace("-", "_")
        |> then(&"#{&1}_#{idx}")

      %Variation{
        id: String.to_atom(id_str),
        attributes: specimen[:props] || %{},
        slots: if(specimen[:content], do: [specimen[:content]], else: []),
        description: specimen[:label] || ""
      }
    end)
  end)
end
```

**Phase 200 application:** extend this module rather than creating parallel Storybook metadata. Add stable slugified IDs, `na_states` notes, unique DOM IDs, state groups, and template/named-slot escape hatches here.

---

### `accrue_admin/storybook/components/*.story.exs` and `accrue_admin/storybook/groups/*.story.exs` (component/story, transform)

**Analogs:** `accrue_admin/lib/accrue_admin/dev/component_registry.ex`, `accrue_admin/storybook/_support/registry_story.ex`

**Registry metadata shape** (lines 5-27):
```elixir
@type entry :: %{
        family: String.t(),
        variant: String.t(),
        ax_class: String.t(),
        tokens: [String.t()],
        applicable_states: [String.t()] | nil,
        na_states: [%{state: String.t(), reason: String.t()}] | nil,
        specimens: [%{label: String.t(), props: map(), content: String.t() | nil}] | nil
      }

@type group_contract :: %{
        name: String.t(),
        slug: String.t(),
        proof_id: String.t(),
        required_states: [String.t()],
        primary_components: [String.t()],
        locators: [String.t()],
        phase191_handoff_tags: [String.t()],
        behavior_contracts: [String.t()],
        hierarchy: [String.t()],
        representative_route_category: String.t(),
        decisions: [String.t()]
      }
```

**Group contract pattern** (lines 36-58):
```elixir
def group_contracts do
  [
    %{
      name: "page-header/actions/breadcrumbs",
      slug: "page-header-actions-breadcrumbs",
      proof_id: "grp190-page-header-actions-breadcrumbs",
      required_states: ["long-content", "overflow", "mobile-wrap", "dark-mode"],
      primary_components: ["Breadcrumbs", "Button", "AppShell page header"],
      locators: group_locators("page-header-actions-breadcrumbs"),
      phase191_handoff_tags: ["liveview-patch-focus", "microcopy"],
      behavior_contracts: [
        "Breadcrumbs orient before the task heading.",
        "Primary action remains in the same visual band as the task.",
        "Mobile wraps actions below the title without separating context."
      ],
      hierarchy: [
        "orientation",
        "task heading",
        "supporting copy",
        "primary and secondary actions"
      ],
      representative_route_category: "admin page header",
      decisions: ["D-01", "D-02", "D-05", "D-16", "D-17", "D-20", "D-21"]
    },
```

**Lookup/accessor pattern** (lines 288-298, 2141-2150):
```elixir
@doc "Ordered Phase 190 component-group slugs for data-component-group locators."
@spec component_group_slugs() :: [String.t()]
def component_group_slugs do
  Enum.map(group_contracts(), & &1.slug)
end

@doc "Looks up a group contract by its static Phase 190 slug."
@spec group_contract_by_slug(String.t()) :: group_contract() | nil
def group_contract_by_slug(slug) when is_binary(slug) do
  Enum.find(group_contracts(), &(&1.slug == slug))
end

def variants_for(family) do
  Enum.filter(entries(), &(&1.family == family))
end

defp group_locators(slug) do
  [
    ~s([data-component-group="#{slug}"]),
    "#grp190-#{slug}",
    "/billing/dev/components?group=#{slug}"
  ]
end
```

**Representative entry pattern** (lines 323-364):
```elixir
%{
  family: "button",
  variant: "primary",
  ax_class: "ax-button ax-button-primary",
  tokens: ["--ax-accent-strong", "--ax-accent-contrast", "--ax-transition-colors"],
  applicable_states: [
    "default",
    "hover",
    "focus",
    "active",
    "pressed",
    "disabled",
    "loading",
    "overflow"
  ],
  na_states: [
    %{
      state: "selected",
      reason:
        "button has no selection state - use aria-pressed for toggle buttons separately"
    },
    %{state: "empty", reason: "button always has a label"},
    %{state: "error", reason: "button conveys intent via variant, not validation state"}
  ],
  specimens: [
    %{
      label: "Default",
      props: %{variant: "primary", type: "button"},
      content: "Save changes"
    },
    %{label: "Short", props: %{variant: "primary", type: "button"}, content: "Go"},
    %{
      label: "Long label (overflow)",
      props: %{variant: "primary", type: "button"},
      content: "Export all subscription events to CSV"
    },
    %{
      label: "Disabled",
      props: %{variant: "primary", type: "button", disabled: true},
      content: "Archived"
    },
```

**Phase 200 application:** story modules should call registry helpers and `RegistryStory`, not duplicate family names, variant lists, tokens, state names, or group contracts.

---

### `accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs` (test, transform/request-response)

**Analogs:** `accrue_admin/test/accrue_admin/dev/component_registry_test.exs`, `accrue_admin/test/accrue_admin/dev/component_group_registry_test.exs`

**Case/import pattern** (`component_registry_test.exs` lines 7-13):
```elixir
use AccrueAdmin.LiveCase, async: false

use Phoenix.Component

alias AccrueAdmin.Components.Button
alias AccrueAdmin.Dev.ComponentRegistry
```

**Dynamic registry coverage pattern** (`component_registry_test.exs` lines 69-82):
```elixir
test "every registry variant appears in the /dev/components page render", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  assert {:ok, _view, html} = live(conn, "/billing/dev/components")

  for %{ax_class: ax_class} <- ComponentRegistry.entries() do
    [_base, variant_class] = String.split(ax_class, " ", parts: 2)

    assert html =~ variant_class,
           "registry variant #{inspect(ax_class)} - variant class #{inspect(variant_class)} " <>
             "was not found in the /dev/components page HTML"
  end
end
```

**Group contract completeness pattern** (`component_group_registry_test.exs` lines 62-78):
```elixir
test "each group contract has proof IDs, locators, components, and handoff metadata" do
  proof_ids = Enum.map(ComponentRegistry.group_contracts(), & &1.proof_id)

  assert Enum.uniq(proof_ids) == proof_ids

  for contract <- ComponentRegistry.group_contracts() do
    assert is_binary(contract.proof_id) and String.starts_with?(contract.proof_id, "grp190-")
    assert Enum.any?(contract.locators, &(&1 == ~s([data-component-group="#{contract.slug}"])))
    assert Enum.any?(contract.locators, &(&1 == "##{contract.proof_id}"))
    assert contract.primary_components != []
    assert contract.required_states != []
    assert contract.behavior_contracts != []
    assert contract.hierarchy != []
    assert contract.representative_route_category != ""
    assert contract.phase191_handoff_tags != []
  end
end
```

**Rendered proof-root pattern** (`component_group_registry_test.exs` lines 136-157):
```elixir
test "mounted kitchen renders exactly one proof root for each group contract", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  assert {:ok, _view, html} = live(conn, "/billing/dev/components")
  document = Floki.parse_document!(html)

  proof_roots = Floki.find(document, "section.ax-dev-group-specimen[data-component-group]")
  assert length(proof_roots) == length(ComponentRegistry.group_contracts())

  for contract <- ComponentRegistry.group_contracts() do
    nodes =
      Floki.find(
        document,
        ~s([id="#{contract.proof_id}"][data-component-group="#{contract.slug}"])
      )

    assert length(nodes) == 1,
           "expected exactly one mounted group proof root for #{contract.slug}"

    assert Floki.attribute(nodes, "id") == [contract.proof_id]
  end
end
```

**Phase 200 application:** derive expected Storybook families/groups from `ComponentRegistry.entries/0` and `group_contracts/0`; do not assert snapshot counts like 30/42/8.

---

### `accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs` or `accrue_admin/test/accrue_admin/assets_test.exs` (test, request-response/file-I/O)

**Analog:** `accrue_admin/test/accrue_admin/assets_test.exs`

**ConnCase and mounted asset route pattern** (lines 1-5, 16-29):
```elixir
defmodule AccrueAdmin.AssetsTest do
  use AccrueAdmin.ConnCase, async: true

  import Plug.Conn

  test "serves css from the mounted package route" do
    conn =
      :get
      |> build_conn(AccrueAdmin.Assets.hashed_path(:css, "/billing"))
      |> Plug.Test.init_test_session(%{})
      |> AccrueAdmin.TestRouter.call([])

    assert conn.status == 200
    assert get_resp_header(conn, "cache-control") == ["public, max-age=31536000, immutable"]
    assert get_resp_header(conn, "content-type") == ["text/css; charset=utf-8"]

    assert conn.resp_body ==
             File.read!(Application.app_dir(:accrue_admin, "priv/static/accrue_admin.css"))
  end
```

**JS asset route pattern** (lines 31-43):
```elixir
test "serves js from the mounted package route" do
  conn =
    :get
    |> build_conn(AccrueAdmin.Assets.hashed_path(:js, "/billing"))
    |> Plug.Test.init_test_session(%{})
    |> AccrueAdmin.TestRouter.call([])

  assert conn.status == 200
  assert get_resp_header(conn, "content-type") == ["application/javascript; charset=utf-8"]

  assert conn.resp_body ==
           File.read!(Application.app_dir(:accrue_admin, "priv/static/accrue_admin.js"))
end
```

**Phase 200 application:** copy this request/response style for `:storybook_css` and `:storybook_js` under the mounted Storybook path. Assert 200, correct content type, immutable cache header for CSS if route uses it, and response body equality to committed `priv/static/storybook.css` and `priv/static/storybook.js`.

---

### `accrue_admin/test/accrue_admin/theme_test.exs` (test, transform/file-I/O)

**Analogs:** `accrue_admin/test/accrue_admin/theme_test.exs`, `accrue_admin/lib/accrue_admin/layouts.ex`, `accrue_admin/assets/js/hooks/accrue_theme.js`

**Anti-FOUC ordering pattern** (`theme_test.exs` lines 98-130):
```elixir
test "root layout keeps anti-fouc ordering ahead of stylesheet loading" do
  html =
    render_component(&AccrueAdmin.Layouts.root/1, %{
      page_title: "Billing",
      theme: "system",
      csp_nonce: "nonce-123",
      brand: %{
        app_name: "Accrue Ops",
        logo_url: nil,
        accent_hex: "#5D79F6",
        accent_contrast_hex: "#FFFFFF"
      },
      brand_css_path: "/billing/assets/brand.css",
      assets_css_path: "/billing/assets/app.css",
      assets_js_path: "/billing/assets/app.js",
      inner_content: Phoenix.HTML.raw("<main>Shell</main>")
    })

  anti_fouc_index = find_index(html, "document.documentElement.dataset.theme")
  brand_css_index = find_index(html, ~s(href="/billing/assets/brand.css"))
  app_css_index = find_index(html, ~s(href="/billing/assets/app.css"))
  runtime_style_index = find_index(html, "--ax-accent: #5D79F6;")
  js_index = find_index(html, ~s(src="/billing/assets/app.js"))

  assert anti_fouc_index
  assert brand_css_index
  assert app_css_index
  assert runtime_style_index
  assert js_index
  assert anti_fouc_index < brand_css_index
  assert brand_css_index < app_css_index
  assert app_css_index < runtime_style_index
  assert runtime_style_index < js_index
end
```

**Production theme key pattern** (`theme_test.exs` lines 133-154; `layouts.ex` lines 56-75):
```elixir
test "Phase 199 anti-fouc script resolves cookie before localStorage using production key" do
  script = AccrueAdmin.Layouts.anti_fouc_script()

  assert script =~ ~s(const key = "accrue_theme";)
  assert script =~ "document.cookie"
  assert script =~ "safeDecodeTheme"
  assert script =~ "window.localStorage.getItem(key)"
  refute script =~ "accrue_admin_theme"

  cookie_index = find_index(script, "allowed.has(cookieValue)")
  local_storage_index = find_index(script, "allowed.has(storedValue)")
  data_theme_index = find_index(script, "document.documentElement.dataset.theme = theme")
  persist_index = find_index(script, "window.localStorage.setItem(key, theme)")

  assert cookie_index < local_storage_index
  assert local_storage_index < data_theme_index
  assert data_theme_index < persist_index
end

@spec anti_fouc_script() :: String.t()
def anti_fouc_script do
  """
  (() => {
    const key = "accrue_theme";
    const allowed = new Set(["light", "dark", "system"]);
    const safeDecodeTheme = (value) => {
      try {
        return decodeURIComponent(value);
      } catch (_error) {
        return null;
      }
    };
    const fromCookie = document.cookie.split("; ").find((chunk) => chunk.startsWith(`${key}=`));
    const cookieValue = fromCookie ? safeDecodeTheme(fromCookie.split("=").slice(1).join("=")) : null;
    const storedValue = window.localStorage.getItem(key);
    const theme = allowed.has(cookieValue) ? cookieValue : allowed.has(storedValue) ? storedValue : "system";
    document.documentElement.dataset.theme = theme;
    window.localStorage.setItem(key, theme);
  })();
  """
end
```

**Hook production path pattern** (`accrue_theme.js` lines 1-13):
```javascript
export const THEME_COOKIE = "accrue_theme";
export const ALLOWED_THEMES = new Set(["light", "dark", "system"]);

export function sanitizeTheme(theme) {
  return ALLOWED_THEMES.has(theme) ? theme : "system";
}

export function setThemePreference(theme) {
  const value = sanitizeTheme(theme);
  document.documentElement.dataset.theme = value;
  window.localStorage.setItem(THEME_COOKIE, value);
  document.cookie = `${THEME_COOKIE}=${encodeURIComponent(value)}; path=/; max-age=31536000; samesite=lax`;
  return value;
}
```

**Phase 200 application:** Storybook settled light/dark scans may force `data-theme`, but no-FOUC/persistence proof must use this production `accrue_theme` path and malformed-value handling.

---

### `accrue_admin/e2e/admin-storybook-a11y-phase200.spec.js` (test, request-response/browser)

**Analog:** `accrue_admin/e2e/admin-a11y.spec.js`

**Imports and E2E auth/fixture pattern** (lines 1-17):
```javascript
const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

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

**Settled axe scan pattern** (lines 19-28):
```javascript
async function scan(page, theme) {
  await page.evaluate((t) => document.documentElement.setAttribute("data-theme", t), theme);
  await page.waitForTimeout(50);
  const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
  return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}
```

**Surface matrix pattern** (lines 38-92):
```javascript
test("no critical/serious axe violations across primary surfaces", async ({ page, request }) => {
  test.setTimeout(120_000);

  await page.emulateMedia({ reducedMotion: "reduce" });

  const opFlows = await seed(request, "operator-flows");
  const dash = await seed(request, "dashboard");
  const edge = await seed(request, "edge-states");

  const surfaces = [
    ["dashboard",           "/billing"],
    ["customers",           "/billing/customers"],
    ["customer-detail",     `/billing/customers/${dash.customer_id}`],
    ["subscriptions",       "/billing/subscriptions"],
    ["subscription-detail", `/billing/subscriptions/${dash.subscription_id}`],
    ["component-kitchen",   "/billing/dev/components"]
  ];

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
});
```

**Phase 200 application:** replace hardcoded route list with discovered completed Storybook story URLs plus primary admin page-flow routes. Keep reduced motion for settled scans and filter to critical/serious blockers.

---

### `accrue_admin/e2e/admin-page-flow-phase200.spec.js` (test, request-response/browser)

**Analogs:** `accrue_admin/e2e/admin-page-flow-phase191.spec.js`, `accrue_admin/e2e/phase191-page-flow-helpers.js`

**Helper import and trace pattern** (`admin-page-flow-phase191.spec.js` lines 1-22):
```javascript
const fs = require("fs");
const path = require("path");
const { test, expect } = require("@playwright/test");

const {
  PHASE191_VIEWPORTS,
  PHASE191_STATES,
  loadPhase191Defects,
  phase191PageFlows,
  resolvePhase191Route,
  seedScenarioForSurface,
  setPhase191Theme,
  assertNoBodyFocus,
  assertFocusWithin,
  assertTopPointerTarget,
  assertScrollReachable,
  assertNoHorizontalClip,
  phase191CoverageRows,
  normalizeTag,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });
```

**Route/fixture matrix pattern** (`admin-page-flow-phase191.spec.js` lines 169-195):
```javascript
test("AX187-116 AX187-442 AX187-443 AX187-444 AX187-445 route every manifest page-flow through fixtures @fixtures @ax187", async ({
  request,
}) => {
  await reset(request);
  const fixtureData = await seedPhase191Matrix(request);
  const flows = phase191PageFlows();

  expect(flows).toHaveLength(21);
  expect(PHASE191_STATES).toEqual([
    "default-populated",
    "empty",
    "loading",
    "error",
    "permission-denied",
    "disconnected-reconnecting",
    "overflow",
    "long-content",
    "interactive-open",
  ]);

  for (const flow of flows) {
    const scenario = seedScenarioForSurface(flow);
    const route = resolvePhase191Route(flow, fixtureData);
    expect(route, `${flow.surface} route should resolve from ${scenario}`).toMatch(/^\/billing/);
    expect(route, `${flow.surface} route should not contain unresolved params`).not.toContain(":");
  }
});
```

**Responsive/theme loop pattern** (`admin-page-flow-phase191.spec.js` lines 197-221):
```javascript
for (const viewport of PHASE191_VIEWPORTS) {
  await page.setViewportSize({ width: viewport.width, height: viewport.height });

  for (const theme of ["light", "dark"]) {
    for (const flow of phase191PageFlows()) {
      await login(page, resolvePhase191Route(flow, fixtureData));
      await setPhase191Theme(page, theme);
      await assertNoHorizontalClip(page, "#main-content, main, .ax-data-table-shell, [data-role='card-list']", `${flow.surface} ${viewport.name} ${theme}`);
      await assertNoBodyFocus(page, `${flow.surface} initial focus`);

      const scrollTarget = page.locator("#main-content, main").first();
      await assertScrollReachable(scrollTarget, `${flow.surface} main content`);
      await expect(page.locator("body")).not.toContainText(GENERIC_ERROR_COPY_PATTERN);
    }
  }
}
```

**Helper patterns** (`phase191-page-flow-helpers.js` lines 50-62, 119-131, 270-303, 480-500):
```javascript
function readNdjson(filePath) {
  return fs
    .readFileSync(filePath, "utf8")
    .split(/\r?\n/)
    .filter(Boolean)
    .map((line, index) => {
      try {
        return JSON.parse(line);
      } catch (error) {
        throw new Error(`${filePath}:${index + 1}: ${error.message}`);
      }
    });
}

async function setPhase191Theme(page, theme) {
  if (!["light", "dark"].includes(theme)) {
    throw new Error(`Unsupported Phase 191 theme: ${theme}`);
  }

  await page.evaluate((value) => {
    document.documentElement.setAttribute("data-theme", value);
    document.documentElement.dataset.theme = value;
    window.localStorage?.setItem("accrue_admin_theme", value);
  }, theme);

  if (typeof page.waitForTimeout === "function") await page.waitForTimeout(50);
}

async function assertNoHorizontalClip(page, selector = "body", label = selector) {
  const result = await page.evaluate((targetSelector) => {
    const failures = [];
    const documentOverflow = document.documentElement.scrollWidth - document.documentElement.clientWidth;

    for (const element of document.querySelectorAll(targetSelector)) {
      const rect = element.getBoundingClientRect();
      const style = window.getComputedStyle(element);
      if (style.display === "none" || style.visibility === "hidden" || rect.width === 0 || rect.height === 0) {
        continue;
      }

      if (rect.left < -1 || rect.right > window.innerWidth + 1) {
        failures.push({
          text: (element.textContent || element.getAttribute("aria-label") || element.tagName)
            .trim()
            .replace(/\s+/g, " ")
            .slice(0, 80),
          left: rect.left,
          right: rect.right,
          viewport: window.innerWidth,
        });
      }
    }

    return { documentOverflow, failures };
  }, selector);

  if (result.documentOverflow > 1 || result.failures.length > 0) {
    throw new Error(`Phase 191 clipping assertion failed for ${label}: ${JSON.stringify(result)}`);
  }

  return result;
}

module.exports = {
  PHASE191_VIEWPORTS,
  PHASE191_STATES,
  loadPhase191Defects,
  phase191PageFlows,
  resolvePhase191Route,
  seedScenarioForSurface,
  setPhase191Theme,
  assertNoBodyFocus,
  assertFocusWithin,
  assertTopPointerTarget,
  assertScrollReachable,
  assertNoHorizontalClip,
  assertNoBodyFocusAfterNavigation,
  assertRouteFocusAndScroll,
  assertNoStaleOverlayState,
  assertFloatingAdjacentToTrigger,
  phase191CoverageRows,
  normalizeTag,
  cellsForSurface,
};
```

**Phase 200 application:** page-flow final evidence should close `p193` pending rows with `coverage_status: "covered"`, score floor `>= 2`, evidence refs, and no unresolved route params.

---

### Reduced-motion and interaction guardrails (applies to Phase 200 browser specs)

**Analog:** `accrue_admin/e2e/reduced-motion.spec.js`

**Behavioral duration pattern** (lines 116-156):
```javascript
test.describe("Reduced motion - bundle override collapses transitions to instant (D-15)", () => {
  test("with prefers-reduced-motion:reduce, .ax-button transition-duration collapses to 0s on every segment", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await login(page, "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const durations = await buttonTransitionDurations(page);

    expect(durations, ".ax-button must be present on /billing/dev/components").not.toBeNull();
    expect(
      durations.length,
      `--ax-transition-base is a multi-property bundle - expected a comma-list of durations, got ${JSON.stringify(durations)}`
    ).toBeGreaterThan(0);

    for (const seg of durations) {
      expect(
        seg,
        `under reduced-motion, every .ax-button transition segment must be "0s" (instant) - got segments ${JSON.stringify(durations)}`
      ).toBe("0s");
    }
  });

  test("WITHOUT reduced-motion the same .ax-button has a NON-zero transition-duration (proves the override is the cause of the collapse)", async ({ page }) => {
    await login(page, "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const durations = await buttonTransitionDurations(page);
    const hasNonZero = durations.some((seg) => seg !== "0s");
    expect(hasNonZero).toBe(true);
  });
});
```

**Travel/focus behavior pattern** (lines 322-363):
```javascript
test("with prefers-reduced-motion:reduce, actual drawer enter classes have no desktop or mobile travel", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });

  await page.setViewportSize({ width: 1024, height: 720 });
  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();
  const desktop = await computedStyleForFixtureClass(page, "ax-drawer-enter-from");

  expect(
    isIdentityTransform(desktop.transform),
    `desktop drawer enter-from should collapse to identity transform under reduced motion, got ${desktop.transform}`
  ).toBe(true);
  for (const seg of desktop.transitionDuration) {
    expect(durationToMs(seg), `desktop drawer transition should be instant, got ${desktop.transitionDuration}`).toBeLessThanOrEqual(1);
  }

  await page.setViewportSize({ width: 375, height: 667 });
  const mobile = await computedStyleForFixtureClass(page, "ax-drawer-enter-from");

  expect(
    isIdentityTransform(mobile.transform),
    `mobile drawer enter-from should collapse to identity transform under reduced motion, got ${mobile.transform}`
  ).toBe(true);
  for (const seg of mobile.transitionDuration) {
    expect(durationToMs(seg), `mobile drawer transition should be instant, got ${mobile.transitionDuration}`).toBeLessThanOrEqual(1);
  }
});

test("focus ring forced state is instant without relying on reduced-motion emulation", async ({ page }) => {
  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();

  const durations = await forcedFocusRingTransitionDurations(page);

  expect(durations.length, "forced focus fixture should expose computed transition durations").toBeGreaterThan(0);
  for (const seg of durations) {
    expect(
      durationToMs(seg),
      `focus-ring styling must not inherit animated control transitions, got ${JSON.stringify(durations)}`
    ).toBeLessThanOrEqual(1);
  }
});
```

**Phase 200 application:** reduced-motion proof must assert actual computed duration/travel/focus behavior, not token presence alone.

---

### `accrue_admin/e2e/phase200-scorecard.mjs` and Phase 200 structured artifacts (utility/script, batch/file-I/O)

**Analog:** `accrue_admin/e2e/phase192-scorecard.mjs`

**Imports/path pattern** (lines 1-30):
```javascript
import fs from "fs";
import os from "os";
import path from "path";
import { createHash } from "crypto";
import { fileURLToPath } from "url";

import manifest from "./baseline-manifest.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const adminRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(adminRoot, "..");
const testResultsRoot = path.join(adminRoot, "test-results");
const PHASE187_DIR = ".planning/phases/187-audit-baseline";
const PHASE192_DIR = ".planning/phases/192-idempotent-verification-sign-off";
const phaseDir = path.join(repoRoot, PHASE192_DIR);

const DEFAULT_INPUTS = {
  baselinePath: path.join(repoRoot, PHASE187_DIR, "baseline.cells.json"),
  evidenceRoot: testResultsRoot,
};

const OUTPUTS = {
  finalCells: path.join(phaseDir, "final.cells.json"),
  delta: path.join(phaseDir, "scorecard.delta.json"),
  regressions: path.join(phaseDir, "regressions.ndjson"),
  manifest: path.join(phaseDir, "artifacts.manifest.json"),
  markdown: path.join(phaseDir, "192-SCORECARD.md"),
};
```

**Phase 200 application:** replace with explicit Phase 200 paths:
- component baseline: `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.cells.json`
- page-flow baseline: `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.page-flow.cells.json`
- outputs under `.planning/phases/200-idempotent-verification-sign-off/`
- write `baseline.union.cells.json` as an additional output.

**Structured read/write pattern** (lines 203-245):
```javascript
function readJson(absPath) {
  try {
    return JSON.parse(fs.readFileSync(absPath, "utf8"));
  } catch (error) {
    throw new Error(`Unable to parse JSON at ${absPath}: ${error.message}`);
  }
}

function readNdjson(absPath) {
  const rows = [];
  const body = fs.readFileSync(absPath, "utf8");
  body.split(/\r?\n/).forEach((line, index) => {
    if (!line.trim()) return;
    try {
      rows.push(JSON.parse(line));
    } catch (error) {
      throw new Error(`Unable to parse NDJSON at ${absPath}:${index + 1}: ${error.message}`);
    }
  });
  return rows;
}

function writeJson(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, `${JSON.stringify(value, null, 2)}\n`);
}

function writeText(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, value);
}
```

**Regression comparison pattern** (lines 412-484):
```javascript
function compareCells(baselineRows, finalRows, deltaRows) {
  const baselineById = new Map(baselineRows.map((cell) => [cell.cell_id, cell]));
  const finalById = new Map(finalRows.map((cell) => [cell.cell_id, cell]));
  const regressions = [];
  const comparableIds = new Set([...finalById.keys()]);

  for (const finalCell of finalRows) {
    const baseline = baselineById.get(finalCell.cell_id);
    const correction = deltaRows.find((row) => isBaselineCorrection(row, finalCell.cell_id, baselineById));

    if (!baseline && !correction) {
      regressions.push(
        regressionRow(
          "baseline-correction-required",
          null,
          finalCell,
          "Final cell is not present in the frozen Phase 187 baseline and has no structured correction."
        )
      );
      continue;
    }

    if (finalCell.evidence_refs.length === 0) {
      regressions.push(regressionRow("missing-evidence", baseline, finalCell, "Comparable final cell has no evidence refs."));
    }

    if (!baseline) continue;

    const baselineScore = scoreValue(baseline.score);
    const finalScore = scoreValue(finalCell.score);
    if (baselineScore !== null && (finalScore === null || finalScore < baselineScore)) {
      regressions.push(
        regressionRow(
          "score-downgrade",
          baseline,
          finalCell,
          `Final score ${finalScore} is below Phase 187 baseline score ${baselineScore}.`
        )
      );
    }

    if (
      baseline.coverage_status === "covered" &&
      ["gap", "missing", "unreachable"].includes(finalCell.coverage_status) &&
      !correction
    ) {
      regressions.push(
        regressionRow(
          "coverage-downgrade",
          baseline,
          finalCell,
          `Coverage downgraded from covered to ${finalCell.coverage_status}.`
        )
      );
    }
  }
```

**Generator orchestration pattern** (lines 731-778):
```javascript
export function generatePhase192Scorecard(options = {}) {
  const baselinePath = path.resolve(options.baselinePath || DEFAULT_INPUTS.baselinePath);
  const evidenceRoot = path.resolve(options.evidenceRoot || DEFAULT_INPUTS.evidenceRoot);
  const outputPaths = { ...OUTPUTS, ...(options.outputs || {}) };
  const dryRun = Boolean(options.dryRun);

  const baselineRows = readJson(baselinePath);
  if (!Array.isArray(baselineRows)) throw new Error("baseline.cells.json must be an array.");
  const baselineById = new Map(baselineRows.map((cell) => [cell.cell_id, cell]));
  const lensFiles = discoverLensFiles(evidenceRoot, options.lensInputs || []);
  const artifactFiles = discoverArtifactFiles(evidenceRoot, options.lensInputs || []);
  const normalized = normalizeEvidence(lensFiles, baselineById);
  const finalCells = normalized.cells.length > 0 ? normalized.cells : fallbackCellsFromBaseline(baselineRows);
  const initialDelta = normalized.corrections;
  const comparison = compareCells(baselineRows, finalCells, initialDelta);
  const regressions = [...normalized.failures, ...comparison.regressions];
  const deltaRows = [...comparison.deltaRows, ...initialDelta];
  const referencedRefs = finalCells.flatMap((cell) => cell.evidence_refs || []);
  const manifestContent = evidenceInventory(artifactFiles.length > 0 ? artifactFiles : lensFiles, outputPaths, referencedRefs);
  const markdownContent = renderMarkdown({ finalCells, deltaRows, regressions, manifestContent, dryRun });

  const packageResult = {
    finalCells,
    deltaRows,
    regressions,
    manifest: manifestContent,
    markdown: markdownContent,
    summary: {
      baseline_cells: baselineRows.length,
      final_cells: finalCells.length,
      delta_rows: deltaRows.length,
      regression_rows: regressions.length,
      lens_inputs: lensFiles.length,
      dry_run: dryRun,
    },
    outputPaths,
  };

  if (!dryRun && options.write !== false) {
    writeJson(outputPaths.finalCells, finalCells);
    writeJson(outputPaths.delta, deltaRows);
    writeText(outputPaths.regressions, regressions.map((row) => JSON.stringify(row)).join("\n") + (regressions.length ? "\n" : ""));
    writeJson(outputPaths.manifest, manifestContent);
    writeText(outputPaths.markdown, markdownContent);
  }

  return packageResult;
}
```

**Self-test pattern** (lines 833-915):
```javascript
function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase192-scorecard-"));
  try {
    const baseline = [fixtureCell()];

    const positive = runFixture(path.join(root, "positive"), baseline, [fixtureCell({ score: 3 })]);
    assertSelfTest("positive fixture produces one final cell", positive.finalCells.length === 1);
    assertSelfTest("positive fixture produces one passing delta", positive.deltaRows.length === 1);
    assertSelfTest("positive fixture has zero regressions", positive.regressions.length === 0);
    assertSelfTest("positive fixture preserves manifest evidence refs", positive.manifest.evidence.length > 0);

    const scoreDowngrade = runFixture(path.join(root, "score-downgrade"), baseline, [fixtureCell({ score: 1 })]);
    assertSelfTest(
      "score downgrade produces score-downgrade row",
      scoreDowngrade.regressions.some((row) => row.kind === "score-downgrade")
    );

    const missingEvidence = runFixture(path.join(root, "missing-evidence"), baseline, [
      fixtureCell({ evidence_refs: [], evidence_lenses: ["interaction-trace"] }),
    ]);
    assertSelfTest(
      "missing evidence produces missing-evidence row",
      missingEvidence.regressions.some((row) => row.kind === "missing-evidence")
    );

    console.log("Phase 192 scorecard reducer self-test passed.");
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}
```

**Phase 200 application:** add self-tests for duplicate union IDs, 30,348 expected union rows unless dedupe proof differs, `p193` pending rows becoming `covered`, score floor `>= 2`, and non-empty `regressions.ndjson` blocking.

---

### `scripts/ci/verify_phase200_scorecard.mjs` (utility/script, batch/file-I/O)

**Analog:** `scripts/ci/verify_phase192_scorecard.mjs`

**Paths and allowed roots pattern** (lines 1-17, 108-112):
```javascript
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, "..", "..");
const PHASE192_DIR = ".planning/phases/192-idempotent-verification-sign-off";

const DEFAULT_INPUTS = {
  baselinePath: path.join(REPO_ROOT, ".planning/phases/187-audit-baseline/baseline.cells.json"),
  finalCellsPath: path.join(REPO_ROOT, PHASE192_DIR, "final.cells.json"),
  deltaPath: path.join(REPO_ROOT, PHASE192_DIR, "scorecard.delta.json"),
  regressionsPath: path.join(REPO_ROOT, PHASE192_DIR, "regressions.ndjson"),
  manifestPath: path.join(REPO_ROOT, PHASE192_DIR, "artifacts.manifest.json"),
};

const ALLOWED_ARTIFACT_ROOTS = [
  "accrue_admin/test-results/",
  "accrue_admin/playwright-report/",
  `${PHASE192_DIR}/`,
];
```

**Shape validation pattern** (lines 210-248):
```javascript
function validateBaselineCellShape(cell, failures, label = "final.cells.json") {
  const required = [
    "cell_id",
    "surface",
    "surface_type",
    "mode",
    "viewport_width",
    "theme",
    "state",
    "dimension",
    "dimension_name",
    "score",
    "coverage_status",
    "evidence_refs",
    "notes",
  ];

  for (const field of required) {
    if (!(field in cell)) failures.push(`${label}: ${formatCell(cell)} missing ${field}.`);
  }

  const dimension = Number(cell.dimension);
  if (!DIMENSIONS.has(dimension) || cell.dimension_name !== DIMENSIONS.get(dimension)) {
    failures.push(`${label}: ${formatCell(cell)} has invalid D-09/D-12 dimension mapping.`);
  }
  if (!validCellGrammar(cell)) {
    failures.push(`${label}: ${formatCell(cell)} violates frozen p187__...__dXX grammar.`);
  }
  if (!COVERAGE_RANK.has(cell.coverage_status)) {
    failures.push(`${label}: ${formatCell(cell)} has invalid coverage_status.`);
  }
  const score = scoreValue(cell.score);
  if (Number.isNaN(score)) {
    failures.push(`${label}: ${formatCell(cell)} has invalid score; expected 0, 1, 2, 3, or null.`);
  }
  if (!Array.isArray(cell.evidence_refs)) {
    failures.push(`${label}: ${formatCell(cell)} evidence_refs must be an array.`);
  }
}
```

**Artifact reference validation pattern** (lines 277-288, 347-369):
```javascript
function validArtifactRef(ref) {
  const value = String(ref || "");
  if (value.startsWith("playwright-trace:")) return true;
  if (!value || path.isAbsolute(value) || value.includes("\\") || value.split("/").includes("..")) return false;
  return ALLOWED_ARTIFACT_ROOTS.some((root) => value.startsWith(root));
}

function validateArtifactRef(ref, label, failures) {
  if (!validArtifactRef(ref)) {
    failures.push(`${label}: invalid artifact ref "${ref}" (D-16/T-192-03 repo-relative generated roots only).`);
  }
}

function validateEvidence(row, label, failures, manifestRefs) {
  const refs = evidenceRefs(row);
  if (refs.length === 0) {
    failures.push(`${label}: ${row.cell_id || row.id || "(row)"} lacks D-16 evidence refs.`);
    return;
  }
  for (const ref of refs) {
    validateArtifactRef(ref, label, failures);
    if (manifestRefs.size > 0 && !manifestRefs.has(ref)) {
      failures.push(`${label}: ${row.cell_id || row.id || "(row)"} references ${ref} not present in artifacts.manifest.json.`);
    }
  }
  const lenses = rowLenses(row);
  for (const lens of lenses) {
    if (!ALLOWED_LENSES.has(lens)) {
      failures.push(`${label}: ${row.cell_id || row.id || "(row)"} uses unknown evidence lens "${lens}".`);
    }
  }
  if (requiresDeterministicSupport(row) && supportIsVisualOnly(row)) {
    failures.push(
      `${label}: ${row.cell_id || row.id || "(row)"} relies only on visual/model/maintainer evidence for a D-17/D-18 deterministic claim.`
    );
  }
}
```

**Verifier entrypoint pattern** (lines 493-537):
```javascript
export function verifyPhase192Scorecard(options = {}) {
  const paths = { ...DEFAULT_INPUTS, ...options };
  const manifestResult = validateManifest(paths.manifestPath);
  const manifestRefs = allArtifactRefs(manifestResult);

  if (options.manifestOnly) {
    const failures = manifestResult.failures;
    return {
      ok: failureCount(failures) === 0,
      summary: { manifest_entries: manifestResult.entries.length },
      failures,
    };
  }

  const shapeFailures = { malformedRows: [] };
  const baselineRows = asArray(readJson(paths.baselinePath), "baseline.cells.json", shapeFailures.malformedRows);
  const finalRows = asArray(readJson(paths.finalCellsPath), "final.cells.json", shapeFailures.malformedRows);
  const deltaRows = asArray(readJson(paths.deltaPath), "scorecard.delta.json", shapeFailures.malformedRows);
  const regressions = readNdjson(paths.regressionsPath);
  const regressionFailures = { regressions: [], missingEvidence: [] };

  if (regressions.length > 0) {
    for (const row of regressions) {
      regressionFailures.regressions.push(
        `${row.id || row.cell_id || "(regression row)"} blocks sign-off; regressions.ndjson must be empty.`
      );
      validateEvidence(row, "regressions.ndjson", regressionFailures.missingEvidence, manifestRefs);
    }
  }

  const comparisonFailures = compareFinalCells(baselineRows, finalRows, deltaRows, manifestRefs);
  const failures = mergeFailureMaps(manifestResult.failures, shapeFailures, comparisonFailures, regressionFailures);

  return {
    ok: failureCount(failures) === 0,
    summary: {
      baseline_cells: baselineRows.length,
      final_cells: finalRows.length,
      delta_rows: deltaRows.length,
      regression_rows: regressions.length,
      manifest_entries: manifestResult.entries.length,
    },
    failures,
  };
}
```

**Phase 200 application:** verifier must read `baseline.union.cells.json` or both component/page-flow baselines, enforce empty regressions, enforce no coverage downgrade, and add a Phase 200-specific rule that every `p193` row is `covered` with evidence and score `>= 2`.

---

### `scripts/ci/verify_phase200_signoff.mjs` and `200-SIGN-OFF.md` (utility/script, human sign-off/file-I/O)

**Analogs:** `scripts/ci/verify_phase192_signoff.mjs`, `192-SIGN-OFF.md`

**Required artifacts and guardrails pattern** (`verify_phase192_signoff.mjs` lines 11-26):
```javascript
const REQUIRED_ARTIFACTS = [
  "final.cells.json",
  "scorecard.delta.json",
  "regressions.ndjson",
  "artifacts.manifest.json",
];

const REQUIRED_GUARDRAILS = [
  { name: "baseline:parse", markers: ["baseline:parse"] },
  { name: "verify_phase191_ax187_coverage", markers: ["verify_phase191_ax187_coverage"] },
  { name: "e2e:group-contracts", markers: ["e2e:group-contracts"] },
  { name: "e2e:phase191", markers: ["e2e:phase191"] },
  { name: "e2e:a11y", markers: ["e2e:a11y"] },
  { name: "reduced-motion", markers: ["reduced-motion"] },
  { name: "component-lab coverage", markers: ["component-lab", "component lab"] },
];
```

**Markdown parsing pattern** (lines 113-157):
```javascript
function sectionSource(markdown, headingMatcher) {
  const lines = markdown.split(/\r?\n/);
  const start = lines.findIndex((line) => /^#{1,4}\s+/.test(line) && headingMatcher.test(line));
  if (start === -1) return "";
  const out = [];
  for (let index = start + 1; index < lines.length; index += 1) {
    if (/^#{1,4}\s+/.test(lines[index])) break;
    out.push(lines[index]);
  }
  return out.join("\n");
}

function parseMarkdownTables(markdown) {
  const lines = markdown.split(/\r?\n/);
  const tables = [];
  for (let index = 0; index < lines.length; index += 1) {
    if (!/^\s*\|.+\|\s*$/.test(lines[index])) continue;
    if (!/^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$/.test(lines[index + 1] || "")) continue;

    const headers = splitTableRow(lines[index]).map(normalize);
    const rows = [];
    index += 2;
    while (index < lines.length && /^\s*\|.+\|\s*$/.test(lines[index])) {
      const cells = splitTableRow(lines[index]);
      const row = {};
      headers.forEach((header, headerIndex) => {
        row[header] = cells[headerIndex] || "";
      });
      rows.push(row);
      index += 1;
    }
    tables.push({ headers, rows });
    index -= 1;
  }
  return tables;
}
```

**Sign-off structure validation pattern** (lines 182-222, 272-329):
```javascript
function validateArtifactLinks(markdown, failures) {
  for (const artifact of REQUIRED_ARTIFACTS) {
    if (!markdown.includes(artifact)) {
      failures.artifacts.push(`192-SIGN-OFF.md must link or literally reference ${artifact}.`);
    }
  }
}

function validateExecutiveSections(markdown, failures) {
  const normalized = normalize(markdown);
  const required = [
    { name: "executive status", markers: ["executive status"] },
    { name: "baseline comparison summary", markers: ["baseline comparison", "final score >= phase 187 baseline"] },
    { name: "CI guardrail status", markers: ["ci guardrail"] },
    { name: "curated gallery", markers: ["curated gallery"] },
    { name: "maintainer checklist", markers: ["maintainer checklist"] },
  ];

  for (const section of required) {
    if (!hasAny(normalized, section.markers)) {
      failures.structure.push(`Missing ${section.name} section/content required by D-30.`);
    }
  }
}

function validateTraceRefs(markdown, failures) {
  const traceSource = `${sectionSource(markdown, /trace/i)}\n${sectionSource(markdown, /curated gallery/i)}`;
  for (const category of TRACE_CATEGORIES) {
    if (!hasAny(traceSource, category.markers)) {
      failures.traces.push(`Missing trace ref category for ${category.name}.`);
      continue;
    }
    const line = traceSource
      .split(/\r?\n/)
      .find((candidate) => hasAny(candidate, category.markers));
    if (!line || evidenceRefs(line).length === 0) {
      failures.traces.push(`${category.name} must cite a deterministic trace/evidence ref.`);
    }
  }
}

function validateEvidenceRefs(markdown, failures) {
  const refs = evidenceRefs(markdown);
  if (refs.length === 0) {
    failures.evidence.push("192-SIGN-OFF.md must include concrete repo-relative evidence refs.");
  }
  for (const ref of refs) {
    if (!validEvidenceRef(ref)) {
      failures.evidence.push(`Invalid evidence ref: ${ref}`);
    }
  }
}
```

**Verifier entrypoint pattern** (lines 345-374):
```javascript
export function verifyPhase192Signoff(options = {}) {
  const signoffPath = options.signoffPath || DEFAULT_SIGNOFF_PATH;
  const markdown = options.markdown ?? readFile(signoffPath);
  const failures = {
    structure: [],
    artifacts: [],
    guardrails: [],
    gallery: [],
    traces: [],
    checklist: [],
    evidence: [],
  };

  validateExecutiveSections(markdown, failures);
  validateArtifactLinks(markdown, failures);
  validateGuardrails(markdown, failures);
  validateGallery(markdown, failures);
  validateTraceRefs(markdown, failures);
  validateChecklist(markdown, failures);
  validateEvidenceRefs(markdown, failures);

  return {
    ok: failureCount(failures) === 0,
    summary: {
      signoff_path: signoffPath,
      artifact_refs: REQUIRED_ARTIFACTS.filter((artifact) => markdown.includes(artifact)).length,
      evidence_refs: evidenceRefs(markdown).length,
    },
    failures,
  };
}
```

**Final sign-off artifact shape** (`192-SIGN-OFF.md` lines 3-36, 89-127):
```markdown
## Executive Status

PASS - Phase 192 sign-off outcome is ACCEPT; passed until structured evidence proves otherwise. The maintainer decision surface is this file, not raw `test-results` output or the full final-cell corpus.

Required repairs before ACCEPT:
- None. Structured evidence is present and no blocking regression rows were found.

## Baseline Comparison

Final score >= Phase 187 baseline is accepted only when structured artifacts prove every comparable cell. Current structured summary:

- final cells: 21276
- comparable cells: 21276
- regression rows: 0
- scorecard summary present: yes

Structured artifact refs:
- .planning/phases/192-idempotent-verification-sign-off/final.cells.json
- .planning/phases/192-idempotent-verification-sign-off/scorecard.delta.json
- .planning/phases/192-idempotent-verification-sign-off/regressions.ndjson
- .planning/phases/192-idempotent-verification-sign-off/artifacts.manifest.json
- .planning/phases/192-idempotent-verification-sign-off/192-SCORECARD.md

## Interaction Trace References

- focus trap: .planning/phases/192-idempotent-verification-sign-off/artifacts.manifest.json#trace-focus-trap
- focus restore: .planning/phases/192-idempotent-verification-sign-off/artifacts.manifest.json#trace-focus-restore
- Escape: .planning/phases/192-idempotent-verification-sign-off/artifacts.manifest.json#trace-escape
- outside click: .planning/phases/192-idempotent-verification-sign-off/artifacts.manifest.json#trace-outside-click
- scroll reachability: .planning/phases/192-idempotent-verification-sign-off/artifacts.manifest.json#trace-scroll-reachability
- LiveView patch focus: .planning/phases/192-idempotent-verification-sign-off/artifacts.manifest.json#trace-liveview-patch-focus
- actionability: .planning/phases/192-idempotent-verification-sign-off/artifacts.manifest.json#trace-actionability

Final maintainer decision: ACCEPT. Evidence source: .planning/phases/192-idempotent-verification-sign-off/artifacts.manifest.json.
```

**Phase 200 application:** update the verifier to require the exact final line prefix `Final maintainer decision: ACCEPT` or `Final maintainer decision: REJECT`, not the older `Final maintainer outcome` fallback. Add required artifacts `baseline.union.cells.json`, `200-SCORECARD.md`, `200-STORYBOOK-COVERAGE.md`, and `200-VERIFICATION.md`.

---

### `scripts/ci/verify_phase200_admin_guardrails.sh`, `package.json`, and CI workflow (batch/process orchestration)

**Analogs:** `scripts/ci/verify_phase192_admin_guardrails.sh`, `accrue_admin/package.json`, `.github/workflows/ci.yml`, `.github/workflows/accrue_admin_browser.yml`

**Shell runner pattern** (`verify_phase192_admin_guardrails.sh` lines 1-20):
```bash
#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

run_step() {
  local label="$1"
  shift

  echo "==> ${label}"
  (cd "$root_dir" && "$@")
}

run_step "Phase 187 baseline artifacts parse" bash -c "cd accrue_admin && npm run baseline:parse"
run_step "Phase 191 AX187 coverage verifier" node scripts/ci/verify_phase191_ax187_coverage.mjs
run_step "Phase 190 admin group contracts" bash -c "cd accrue_admin && npm run e2e:group-contracts"
run_step "Phase 191 admin page-flow interactions" bash -c "cd accrue_admin && npm run e2e:phase191"
run_step "Admin axe accessibility" bash -c "cd accrue_admin && npm run e2e:a11y"
run_step "Admin reduced-motion guardrail" bash -c "cd accrue_admin && npx playwright test e2e/reduced-motion.spec.js --workers=1"
run_step "Phase 192 component-lab structural coverage" bash -c "cd accrue_admin && npm run phase192:component-lab"
```

**Package script pattern** (`accrue_admin/package.json` lines 4-23):
```json
"scripts": {
  "e2e": "env -u NO_COLOR playwright test",
  "e2e:group-contracts": "env -u NO_COLOR playwright test e2e/admin-group-contracts.spec.js --timeout=60000 --workers=1",
  "e2e:phase191": "env -u NO_COLOR playwright test e2e/admin-page-flow-phase191.spec.js --timeout=60000 --workers=1",
  "e2e:phase199": "env -u NO_COLOR playwright test e2e/admin-interaction-overlay-phase199.spec.js --timeout=60000 --workers=1",
  "e2e:a11y": "env -u NO_COLOR playwright test e2e/admin-a11y.spec.js",
  "e2e:install": "playwright install chromium",
  "baseline:artifacts": "node e2e/baseline-artifacts.mjs",
  "baseline:parse": "node -e 'const fs=require(\"fs\"), path=require(\"path\"); const root=path.resolve(\"..\"); JSON.parse(fs.readFileSync(path.join(root,\".planning/phases/187-audit-baseline/baseline.cells.json\"),\"utf8\")); const nd=fs.readFileSync(path.join(root,\".planning/phases/187-audit-baseline/defects.ndjson\"),\"utf8\").split(/\\r?\\n/).filter(Boolean); for (const line of nd) JSON.parse(line); JSON.parse(fs.readFileSync(path.join(root,\".planning/phases/187-audit-baseline/artifacts.manifest.json\"),\"utf8\")); console.log(\"baseline artifacts parse ok\")'",
  "phase192:component-lab": "mix test test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/component_group_registry_test.exs",
  "phase192:guardrails": "bash ../scripts/ci/verify_phase192_admin_guardrails.sh",
  "phase192:scorecard": "node e2e/phase192-scorecard.mjs",
  "phase192:signoff": "node e2e/phase192-gallery.mjs"
}
```

**CI job pattern** (`.github/workflows/ci.yml` lines 580-660):
```yaml
env:
  MIX_ENV: test
  PGUSER: postgres
  PGPASSWORD: postgres
  PGHOST: localhost
  ACCRUE_ADMIN_E2E_PORT: 4018

steps:
  - uses: actions/checkout@v6

  - name: Phase 192 CI contract
    run: bash scripts/ci/verify_phase192_ci_contract.sh

  - name: Set up BEAM
    uses: erlef/setup-beam@v1
    with:
      otp-version: '28.0'
      elixir-version: '1.19.5'

  - name: Set up Node
    uses: actions/setup-node@v6
    with:
      node-version: '22'
      cache: npm
      cache-dependency-path: accrue_admin/package-lock.json

  - name: Install admin deps
    run: cd accrue_admin && mix deps.get

  - name: Compile admin package
    run: cd accrue_admin && mix compile --warnings-as-errors

  - name: Install browser deps
    run: cd accrue_admin && npm ci

  - name: Install Chromium
    run: cd accrue_admin && npx playwright install --with-deps chromium

  - name: Phase 192 local guardrail contract
    run: bash scripts/ci/verify_phase192_guardrail_contract.sh

  - name: Run Phase 192 admin hardening guardrails
    run: bash scripts/ci/verify_phase192_admin_guardrails.sh

  - name: Upload Phase 192 generated evidence
    if: always()
    uses: actions/upload-artifact@v7
    with:
      name: phase192-generated-evidence
      path: |
        .planning/phases/192-idempotent-verification-sign-off/final.cells.json
        .planning/phases/192-idempotent-verification-sign-off/scorecard.delta.json
        .planning/phases/192-idempotent-verification-sign-off/regressions.ndjson
```

**Browser workflow setup pattern** (`accrue_admin_browser.yml` lines 39-79):
```yaml
env:
  MIX_ENV: test
  PGUSER: postgres
  PGPASSWORD: postgres
  PGHOST: localhost
  ACCRUE_ADMIN_E2E_PORT: 4017

steps:
  - uses: actions/checkout@v6

  - name: Set up BEAM
    uses: erlef/setup-beam@v1
    with:
      otp-version: "28.0"
      elixir-version: "1.19.5"

  - name: Set up Node
    uses: actions/setup-node@v6
    with:
      node-version: "22"
      cache: npm
      cache-dependency-path: accrue_admin/package-lock.json

  - name: Install Elixir deps
    run: cd accrue_admin && mix deps.get

  - name: Compile admin package
    run: cd accrue_admin && mix compile --warnings-as-errors

  - name: Install browser deps
    run: cd accrue_admin && npm ci

  - name: Install Chromium
    run: cd accrue_admin && npx playwright install --with-deps chromium

  - name: Run browser UAT
    run: cd accrue_admin && npm run e2e
```

**CI contract pattern** (`verify_phase192_ci_contract.sh` lines 63-77, 82-120, 127-137):
```bash
for file in "$ci_file" "$runner_file" "$guardrail_contract_file"; do
  require_file "$file"
done

require_fixed "$ci_file" "admin-group-contracts:"
require_fixed "$ci_file" "cd accrue_admin && npm run e2e:group-contracts"
require_fixed "$ci_file" "admin-hardening-guardrails:"
require_fixed "$ci_file" "Admin hardening guardrails (Phase 192)"
require_fixed "$ci_file" "bash scripts/ci/verify_phase192_ci_contract.sh"
require_fixed "$ci_file" "bash scripts/ci/verify_phase192_guardrail_contract.sh"
require_fixed "$ci_file" "bash scripts/ci/verify_phase192_admin_guardrails.sh"
require_fixed "$ci_file" "phase192-admin-playwright-report"
require_fixed "$ci_file" "phase192-admin-playwright-evidence"
require_fixed "$ci_file" "phase192-generated-evidence"

for needle in \
  "if: github.event_name != 'schedule'" \
  "runs-on: ubuntu-24.04" \
  "image: postgres:15" \
  "MIX_ENV: test" \
  "PGUSER: postgres" \
  "PGPASSWORD: postgres" \
  "PGHOST: localhost" \
  "ACCRUE_ADMIN_E2E_PORT: 4018" \
  "uses: actions/checkout@v6" \
  "uses: erlef/setup-beam@v1" \
  "otp-version: '28.0'" \
  "elixir-version: '1.19.5'" \
  "mix local.hex --force" \
  "uses: actions/setup-node@v6" \
  "node-version: '22'" \
  "cache-dependency-path: accrue_admin/package-lock.json" \
  "cd accrue_admin && mix deps.get" \
  "cd accrue_admin && mix compile --warnings-as-errors" \
  "cd accrue_admin && npm ci" \
  "cd accrue_admin && npx playwright install --with-deps chromium" \
  "bash scripts/ci/verify_phase192_ci_contract.sh" \
  "bash scripts/ci/verify_phase192_guardrail_contract.sh" \
  "bash scripts/ci/verify_phase192_admin_guardrails.sh" \
  "phase192-admin-playwright-report" \
  "path: accrue_admin/playwright-report" \
  "phase192-admin-playwright-evidence" \
  "path: accrue_admin/test-results" \
  "phase192-generated-evidence" \
  ".planning/phases/192-idempotent-verification-sign-off/final.cells.json" \
  ".planning/phases/192-idempotent-verification-sign-off/scorecard.delta.json" \
  ".planning/phases/192-idempotent-verification-sign-off/regressions.ndjson" \
  ".planning/phases/192-idempotent-verification-sign-off/artifacts.manifest.json" \
  ".planning/phases/192-idempotent-verification-sign-off/192-SCORECARD.md" \
  "if-no-files-found: ignore"
do
  require_source_fixed "admin-hardening-guardrails job" "$phase192_job" "$needle"
done

for pattern in \
  'npm run e2e([[:space:]"'\'';&|]|$)' \
  'playwright test([[:space:]]+--|[[:space:]]*(["'\'';&|]|$))' \
  'score-visuals' \
  'baseline:artifacts|baseline-artifacts' \
  'screenshot[[:space:]_-]*capture|capture[[:space:]_-]*screenshot' \
  'trace[[:space:]_-]*capture|capture[[:space:]_-]*trace' \
  'maintainer[[:space:]_-]*sign|sign[[:space:]_-]+off|sign[[:space:]_]+off|signoff'
do
  require_source_absent_regex "admin-hardening-guardrails run commands" "$phase192_run_lines" "$pattern"
done
```

**Phase 200 application:** CI should run deterministic Phase 200 guardrails, not model judge or maintainer sign-off generation. Include Storybook structural/theming checks, Storybook a11y, page-flow Phase 200 proof, Phase 199 E2E, scorecard verifier, sign-off verifier, and host/adopter leak checks.

---

### Phase 200 markdown artifacts and planning reconciliation

**Analogs:** `192-SCORECARD.md`, `192-SIGN-OFF.md`, `192-VERIFICATION.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `brandbook/voice.md`

**Scorecard markdown pattern** (`192-SCORECARD.md` lines 1-29):
```markdown
# Phase 192 Scorecard

**Status:** pass

## Blocking Regressions

No blocking regressions recorded.

## Structured Summary

- Final cells: 21276
- Covered final cells: 4303
- Delta rows: 21276
- Regression rows: 0
- Score downgrades: 0
- Coverage downgrades: 0
- Missing evidence rows: 0
- Manifest evidence entries: 4264
- CI guardrail status: see artifacts.manifest.json
- Maintainer sign-off state: pending 192-SIGN-OFF.md

## Canonical Artifacts

- final.cells.json
- scorecard.delta.json
- regressions.ndjson
- artifacts.manifest.json

This markdown is derived from structured reducer output. Structured JSON and NDJSON artifacts remain canonical.
```

**Verification report pattern** (`192-VERIFICATION.md` lines 1-17, 27-35, 45-59, 61-74):
```markdown
---
phase: 192-idempotent-verification-sign-off
verified: 2026-06-20T14:30:00Z
status: passed
score: 3/3 roadmap success criteria verified
requirements_total: 3
requirements_passed: 3
human_verification_required: true
human_verification_completed: true
human_verification_completed_at: 2026-06-20
overrides_applied: 0
behavior_unverified: 0
gaps: []
residual_risks:
  - "CI runs the deterministic admin-hardening guardrail boundary (verify_phase192_admin_guardrails.sh) but does not regenerate or re-verify the final scorecard/sign-off artifacts in CI. Accepted as local closeout evidence per the v1.53 milestone audit recommendation; scorecard/sign-off are reproducible locally via npm run phase192:scorecard / phase192:signoff and their verifiers."
  - "Final Playwright screenshots and trace ZIPs are recorded as manifest command/evidence refs rather than committed binary artifacts (avoids bulky planning commits)."
---

## Goal Achievement

| # | Roadmap success criterion | Status | Evidence |
|---|---|---|---|
| 1 | Each level (component / group / page) is scored by an adversarial multi-lens judge (correctness, a11y, brand, interaction), and the final scorecard is >= the Phase-187 baseline on every dimension/cell with zero regressions. | VERIFIED | `192-SCORECARD.md` (status: pass) and `scorecard.delta.json`: 21,276 final cells, 21,276 comparable/delta rows, 0 regression rows, 0 score downgrades, 0 coverage downgrades, 0 missing-evidence rows. `regressions.ndjson` is empty. `node scripts/ci/verify_phase192_scorecard.mjs` passed. |

## Artifact Verification

| Artifact | Status | Details |
|---|---|---|
| `192-SCORECARD.md` | VERIFIED | Status pass; structured summary with 21,276 final cells, 0 regressions, 0 downgrades. |
| `final.cells.json` | VERIFIED | Canonical final cell matrix (21,276 cells); JSON parse check passed in 192-06. |
| `scorecard.delta.json` | VERIFIED | 21,276 delta rows comparing Phase 187 -> Phase 192; 0 regression/downgrade rows. |
| `regressions.ndjson` | VERIFIED | Zero blocking regression rows. |
| `artifacts.manifest.json` | VERIFIED | 4,264 manifest evidence entries; final command refs, generated artifacts, referenced baseline evidence, and guardrail statuses. |
| `192-SIGN-OFF.md` | VERIFIED | Executive Status ACCEPT; 17-lens maintainer checklist all ACCEPT; 46-row curated gallery. |

## Behavioral Evidence

| Command | Result | Notes |
|---|---|---|
| `cd accrue_admin && npm run phase192:scorecard` | PASS | Regenerated final scorecard artifacts. |
| `node scripts/ci/verify_phase192_scorecard.mjs` | PASS | 21,276 final cells, 21,276 delta rows, 0 regressions, 4,264 manifest entries. |
| `node scripts/ci/verify_phase192_signoff.mjs` | PASS | Sign-off package valid. |
| `bash scripts/ci/verify_phase192_admin_guardrails.sh` | PASS | baseline:parse, AX187 coverage, group-contracts, phase191 interactions, a11y, reduced-motion, component-lab coverage. |
```

**Current requirement/state markers to reconcile** (`.planning/REQUIREMENTS.md` lines 52-53, 88-90, 116-120; `.planning/STATE.md` lines 29-31, 53, 59-61):
```markdown
- [ ] **STY-02**: Every `ComponentRegistry` family and all 8 group contracts have a generated (registry-driven) story - the registry stays the single source of truth; the in-app `/dev/components` kitchen and the Phase-189/190 drift tests stay green.
- [ ] **STY-03**: Stories render correctly in both color modes against the shipped committed `ax-*` bundle (not a Tailwind rebuild), with the `html.accrue-admin[data-theme]` scoping bridged into Storybook's sandbox.

- [ ] **VER-01**: The merged `regressions.ndjson` shows zero regressions versus the union baseline (component + group + page-flow cells) across viewport x theme x state - every inherited cell scores >= its baseline.
- [ ] **VER-02**: axe-core color-contrast + name/role passes over rendered stories and page-flow routes; no-FOUC/persistence/system-emulation checks are green; and the reduced-motion + group-contract + a11y guardrail suites pass in CI.
- [ ] **VER-03**: An adversarial multi-lens judge (correctness, a11y, brand, interaction) plus a maintainer photographic/interaction checkpoint sign off ACCEPT at each phase boundary and at final sign-off.

| VER-01 | Phase 200 | Pending |
| VER-02 | Phase 200 | Pending |
| VER-03 | Phase 200 | Pending |
| STY-02 | Phase 200 | Pending |
| STY-03 | Phase 200 | Pending |

Phase: 200 - Idempotent verification & sign-off
Status: Phase complete - ready for verification
Last activity: 2026-06-30 - Phase 199 complete, transitioned to Phase 200

| 200 | Idempotent verification & sign-off | VER-01, VER-02, VER-03, STY-02, STY-03 | Not started |
```

**Voice pattern** (`brandbook/voice.md` lines 11-17, 31-33):
```markdown
**Measured.** Accrue doesn't oversell. Every claim is sized to what the library actually does - no superlatives, no adjective-led marketing copy. A measured sentence names a mechanism.

**Exact.** Accrue names things precisely: context functions, append-only ledgers, merge-blocking CI, Fake-backed proof paths.

**Native.** Accrue speaks in Phoenix-developer idioms - Ecto schemas, OTP supervision, mix tasks, plugs, contexts.

**Durable.** Accrue copy ages well. It avoids trend words, metaphors that date quickly, and version-specific promises.

| Write proof-checkable sentences | Write any sentence that can't be verified by reading the source |
| Keep tone calm across all surfaces | Express enthusiasm with exclamation marks or promotional language |
| Use concrete numbers and version strings: "Elixir 1.17+, Phoenix 1.8+" | Use vague scales: "modern," "latest," "cutting-edge" |
```

**Phase 200 application:** when artifacts and verifiers pass, update requirement checkboxes/status rows and state rows to remove `Pending`, `human_needed`, and ambiguous partial status. Keep `200-SIGN-OFF.md` as the single maintainer decision surface.

## Shared Patterns

### Dev/Test-Only Storybook Boundary

**Source:** `accrue_admin/lib/accrue_admin/dev/storybook.ex`
**Apply to:** Storybook backend, support helpers, tests, host/adopter leak checks.

```elixir
if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.Storybook do
    @moduledoc false

    use PhoenixStorybook,
      otp_app: :accrue_admin,
      content_path: Path.expand("../../../../storybook", __DIR__),
      css_path: AccrueAdmin.Assets.hashed_path(:storybook_css, "/dev/storybook"),
      js_path: AccrueAdmin.Assets.hashed_path(:storybook_js, "/dev/storybook"),
      sandbox_class: "accrue-admin",
      color_mode_sandbox_dark_class: "ax-theme-dark-shim"
  end
end
```

### Registry Is The Storybook Source Of Truth

**Source:** `accrue_admin/lib/accrue_admin/dev/component_registry.ex`
**Apply to:** all `.story.exs`, `RegistryStory`, Storybook coverage tests, Storybook coverage report.

```elixir
def component_group_slugs do
  Enum.map(group_contracts(), & &1.slug)
end

def group_contract_by_slug(slug) when is_binary(slug) do
  Enum.find(group_contracts(), &(&1.slug == slug))
end

def variants_for(family) do
  Enum.filter(entries(), &(&1.family == family))
end
```

### Browser Guardrail Style

**Source:** `accrue_admin/e2e/admin-a11y.spec.js`, `admin-page-flow-phase191.spec.js`
**Apply to:** Storybook axe, page-flow Phase 200, no-FOUC/theme, reduced motion, Phase 199 regression specs.

```javascript
await reset(request);
const fixtureData = await seedPhase191Matrix(request);
await login(page, resolvePhase191Route(flow, fixtureData));
await setPhase191Theme(page, theme);
await assertNoHorizontalClip(page, "#main-content, main, .ax-data-table-shell, [data-role='card-list']", `${flow.surface} ${viewport.name} ${theme}`);
await assertNoBodyFocus(page, `${flow.surface} initial focus`);
```

### Structured Artifact Canonicality

**Source:** `accrue_admin/e2e/phase192-scorecard.mjs`, `scripts/ci/verify_phase192_scorecard.mjs`
**Apply to:** scorecard generator, scorecard verifier, sign-off verifier, markdown reports.

```javascript
writeJson(outputPaths.finalCells, finalCells);
writeJson(outputPaths.delta, deltaRows);
writeText(outputPaths.regressions, regressions.map((row) => JSON.stringify(row)).join("\n") + (regressions.length ? "\n" : ""));
writeJson(outputPaths.manifest, manifestContent);
writeText(outputPaths.markdown, markdownContent);
```

### Deterministic CI Boundary

**Source:** `scripts/ci/verify_phase192_admin_guardrails.sh`
**Apply to:** Phase 200 guardrail shell, `package.json`, CI job.

```bash
run_step "Phase 187 baseline artifacts parse" bash -c "cd accrue_admin && npm run baseline:parse"
run_step "Phase 191 AX187 coverage verifier" node scripts/ci/verify_phase191_ax187_coverage.mjs
run_step "Phase 190 admin group contracts" bash -c "cd accrue_admin && npm run e2e:group-contracts"
run_step "Phase 191 admin page-flow interactions" bash -c "cd accrue_admin && npm run e2e:phase191"
run_step "Admin axe accessibility" bash -c "cd accrue_admin && npm run e2e:a11y"
run_step "Admin reduced-motion guardrail" bash -c "cd accrue_admin && npx playwright test e2e/reduced-motion.spec.js --workers=1"
run_step "Phase 192 component-lab structural coverage" bash -c "cd accrue_admin && npm run phase192:component-lab"
```

### Exact Final Decision

**Source:** Phase 200 context decision D-24 plus `192-SIGN-OFF.md`
**Apply to:** `200-SIGN-OFF.md`, `verify_phase200_signoff.mjs`, `200-VERIFICATION.md`.

```markdown
Final maintainer decision: ACCEPT. Evidence source: .planning/phases/192-idempotent-verification-sign-off/artifacts.manifest.json.
```

Phase 200 verifier should accept exactly one final decision line starting with `Final maintainer decision: ACCEPT` or `Final maintainer decision: REJECT`.

## No Analog Found

None. There are no existing `.story.exs` files, but `RegistryStory`, `ComponentRegistry`, and PhoenixStorybook backend configuration are strong role-match analogs for generated/curated component and group stories.

## Metadata

**Analog search scope:** `accrue_admin/storybook`, `accrue_admin/lib/accrue_admin/dev`, `accrue_admin/test/accrue_admin/dev`, `accrue_admin/test/accrue_admin`, `accrue_admin/e2e`, `scripts/ci`, `.github/workflows`, `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `brandbook/voice.md`.

**Files scanned:** 145 source/test/script/workflow paths plus Phase 192 artifacts and planning docs.

**Project instructions read:** `CLAUDE.md`; no `AGENTS.md` or `.claude/CLAUDE.md` was present.

**Project skills:** no project-local skills found in `.claude/skills`, `.agents/skills`, or `.codex/skills`.

**Pattern extraction date:** 2026-06-30.
