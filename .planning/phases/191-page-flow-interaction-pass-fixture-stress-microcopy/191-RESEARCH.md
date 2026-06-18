# Phase 191: Page & Flow Interaction Pass + Fixture Stress + Microcopy - Research

**Researched:** 2026-06-18
**Domain:** Phoenix LiveView admin interaction regression, E2E fixtures, Playwright page-flow testing, Accrue admin microcopy
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Discussion Outcome

- **D-01:** No additional user-facing decisions are required before planning.
  Phase 191 already has a locked UI-SPEC plus a Phase 190 handoff; the remaining
  choices are technical planning and research choices.
- **D-02:** Treat the corrected behavior in `191-UI-SPEC.md` as the regression
  target. Do not encode broken Phase 187 observations as expected behavior.
- **D-03:** Keep Phase 191 bounded to page-flow integration, fixture reachability,
  and microcopy. New capabilities discovered while walking pages belong in
  deferred ideas or later phases.

### Interaction Closure

- **D-04:** Phase 191 must close the Phase 190 D-30 handoff categories:
  focus trap, focus restore, Escape, click outside, scroll reachability, overlay
  position/layering, LiveView patch focus, fixture gaps, and microcopy.
- **D-05:** Active modal, drawer, command-palette, dropdown/popover, mobile nav,
  and protected confirmation behavior must be deterministic: focus stays inside
  while active, background controls are unreachable, close restores focus to the
  trigger or a stable fallback, Escape does not submit or navigate, and outside
  click never confirms or mutates billing state.
- **D-06:** LiveView patch, filter submit, pagination/load-more, row selection,
  tab/window change, optimistic update, reconnect, and async action completion
  must leave focus on a retained control, updated state alert, or page heading.
  Focus must not land on `body` or behind an overlay.
- **D-07:** Regression tests and planning artifacts must cite AX187 IDs or
  overlay tags for the behavior they cover.

### Page Matrix And Fixtures

- **D-08:** The page-flow matrix comes from `baseline-manifest.js` and the
  expanded `191-UI-SPEC.md` viewport/theme contract. Use the canonical surfaces
  and jobs-to-be-done already defined there.
- **D-09:** Fixture work should extend `examples/accrue_host` seeds and
  `accrue_admin/test/support` E2E forcing helpers only. Keep seeds deterministic,
  re-runnable, and namespaced (`e2e_phase191_*` or an equivalent clear namespace).
- **D-10:** One-click reachability is required. Each state cell must be reachable
  from a deterministic route, fixture endpoint, query param, dashboard launcher,
  filter chip, component proof link, or E2E helper without manual database edits.
- **D-11:** Existing host fixture assets already cover long names,
  multi-currency/JPY, dunning/at-risk, canceling subscriptions, webhook failure,
  overflow rows, and basic member-login permission probing. Phase 191 must fill
  the missing cells rather than duplicating these blindly.

### Microcopy

- **D-12:** Use the Accrue voice contract: measured, exact, native, durable.
  Copy must name the affected object, route, event, invoice, subscription,
  charge, customer, owner scope, config key, or recovery path.
- **D-13:** Empty-state copy must distinguish true empty, filtered empty, data
  unavailable, permission denied, and disconnected/reconnecting. Error copy must
  say what happened and what to do next.
- **D-14:** Destructive and consequential confirmations must name the action,
  specific object, billing effect, and audit consequence when applicable.

### Verification Evidence

- **D-15:** Evidence belongs in existing ignored Playwright output paths such as
  `accrue_admin/test-results`; committed planning artifacts should store
  references and summaries, not generated screenshots/traces.
- **D-16:** Keep existing gates green while adding Phase 191 coverage, especially
  `cd accrue_admin && npm run e2e:group-contracts`, touched admin a11y specs, and
  host seed idempotency tests.

### the agent's Discretion

- Exact plan decomposition, test file names, fixture endpoint/query-param shape,
  and sharding strategy are left to researcher/planner discretion, provided the
  locked UI-SPEC, canonical page matrix, and AX187/tag traceability are preserved.
- Technical choices for focus management may use Phoenix LiveView JS, small
  package-local hooks, or existing hooks/components. Do not add a broad client
  framework or third-party UI primitive library to solve this phase.

### Deferred Ideas (OUT OF SCOPE)

- New billing domain features, new billing primitives, or public API/route
  breakage.
- `accrue_portal` work, host/demo chrome redesign, or product changes outside
  `accrue_admin` and `examples/accrue_host` fixture/test support.
- shadcn, third-party UI registries, Tailwind utility authoring, PhoenixStorybook,
  a new UI package, or a new visual-regression service.
- Re-opening Phase 188 token decisions, Phase 189 primitive decisions, or Phase
  190 group-contract decisions unless a root defect in those layers blocks this
  phase's page-flow contract.
</user_constraints>

## Summary

Phase 191 should be planned as a page-flow integration hardening pass over the existing `accrue_admin` LiveView admin UI, not as a component redesign or product-feature phase. The canonical page set is the 21 `page-flow` surfaces exported by `accrue_admin/e2e/baseline-manifest.js`, with nine flow states and light/dark themes; the UI-SPEC expands viewport validation to 320, 375, 768, 1024, and 1440 widths. [VERIFIED: codebase grep] [VERIFIED: 191-UI-SPEC.md]

The highest-value implementation path is to fix shared interaction primitives first: `DetailDrawer`, `StepUpAuthModal`, `DropdownMenu`, `GlobalSearch`/`CommandPalette`, `accrue_shell_nav`, and LiveView patch focus behavior used by list/detail flows. Phoenix LiveView already provides `JS.focus`, `JS.focus_first`, `JS.push_focus`, `JS.pop_focus`, and `Phoenix.Component.focus_wrap/1`, so the planner should prefer those and small package-local hooks over third-party focus libraries. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#focus_wrap/1]

Fixture work should extend two existing seams: test-only `AccrueAdmin.E2E.Plug`/`E2E.Fixtures` for deterministic regression tests and `examples/accrue_host/priv/repo/seeds/*.exs` for click-through host coverage. Existing seeds already cover several edge states, but Phase 187 shows stable empty/error/loading/permission/disconnected fixtures are still missing or unreachable for some flows. [VERIFIED: codebase grep] [VERIFIED: Phase 187 defects.ndjson]

**Primary recommendation:** Plan Phase 191 in three implementation tracks: shared interaction fixes with AX187-tagged regression tests, deterministic fixture reachability, and page-level microcopy/state rendering, while keeping `npm run e2e:group-contracts`, admin a11y, and host seed idempotency green. [VERIFIED: CONTEXT.md] [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Modal, drawer, dropdown, command-palette, mobile-nav focus and dismissal | Browser / Client | Frontend Server (LiveView) | Focus trapping, Escape/outside-click, scroll lock, and active element restoration are browser behaviors, but LiveView renders the active overlay and handles server events. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] [VERIFIED: codebase grep] |
| LiveView patch focus after filters, pagination, tabs, row selection, async completion, reconnect | Frontend Server (LiveView) | Browser / Client | `handle_params/3` and rendered diffs update page state; hooks or JS commands can restore focus to a retained control, alert, or heading after the patch. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [VERIFIED: codebase grep] |
| Disconnected/reconnecting communication and stale mutating-action disablement | Frontend Server (LiveView) | Browser / Client | `phx-connected` and `phx-disconnected` lifecycle bindings only work inside LiveView containers, so root-layout-only status UI is insufficient. [CITED: https://hexdocs.pm/phoenix_live_view/js-interop.html] [VERIFIED: accrue_admin/lib/accrue_admin/layouts.ex] |
| Page-flow matrix traversal | Browser / Client Test Harness | Frontend Server (LiveView) | Playwright owns the cross-page journey and viewport/theme matrix; LiveView pages must expose stable roles, states, and focus targets for assertions. [VERIFIED: accrue_admin/e2e/baseline-manifest.js] [CITED: https://playwright.dev/docs/actionability] |
| E2E forcing endpoints and admin test login | API / Backend Test Support | Database / Storage | `AccrueAdmin.E2E.Server` only runs in `MIX_ENV=test`, and `E2E.Plug` already exposes reset/login/seed endpoints under `/__e2e__/*`. [VERIFIED: accrue_admin/test/support/e2e_server.ex] [VERIFIED: accrue_admin/test/support/e2e_plug.ex] |
| Host click-through fixture data | Database / Storage | API / Backend | `examples/accrue_host` seeds create deterministic billing records via keyed inserts and `on_conflict: :nothing`; Phase 191 should add missing records there rather than manual DB edits. [VERIFIED: examples/accrue_host/priv/repo/seeds/*.exs] |
| Microcopy cleanup | Frontend Server (LiveView) | Browser / Client | Empty/error/permission/disconnected/destructive-confirmation copy is rendered by LiveView components/pages and verified through DOM assertions. [VERIFIED: brandbook/voice.md] [VERIFIED: 191-UI-SPEC.md] |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| IXN-01 | Every modal and drawer renders above its scrim, is visible/interactive, traps focus, restores focus, and dismisses via Escape/click-outside. | Use `StepUpAuthModal`, `DetailDrawer`, `focus_wrap`, LiveView JS focus helpers, and AX187-097..118 regression tests. [VERIFIED: REQUIREMENTS.md] [VERIFIED: codebase grep] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] |
| IXN-02 | Scrolling works on every page/container with no traps or unreachable content. | Cover AX187-436..439 and AX187-446..447; assert drawer/modal/dropdown/page scroll targets in Playwright. [VERIFIED: Phase 187 defects.ndjson] |
| IXN-03 | Focus is never lost/hidden after LiveView patch, and keyboard-only operation completes every primary flow. | Exercise filters, pagination, load-more, row selection, tabs/windows, async completion, reconnect; assert focus not `body`. [VERIFIED: 191-UI-SPEC.md] [CITED: https://playwright.dev/docs/actionability] |
| IXN-04 | Floating/overlay elements position correctly and do not obscure controls. | Preserve `--ax-z-*` layer tokens and test dropdown/popover/command/menu top hit targets. [VERIFIED: accrue_admin/assets/css/theme.css] [VERIFIED: Phase 187 defects.ndjson] |
| IXN-05 | Every Phase 187 interaction defect is fixed and regression tested. | Owner `191` ledger has 178 rows: 70 high, 108 medium; tests must cite AX187 IDs or overlay tags. [VERIFIED: Phase 187 defects.ndjson] |
| PAGE-01 | Every admin page is walked across happy, empty, loading, error, permission-denied, boundary, and advanced paths. | `baseline-manifest.js` exports 21 page-flow surfaces and nine flow states; missing stable state fixtures must be added. [VERIFIED: accrue_admin/e2e/baseline-manifest.js] |
| PAGE-02 | Empty states explain next useful action and distinguish no data, unavailable, permission denied. | Existing `DataTable` has empty/filtered-empty structure; Phase 187 AX187-440/441 shows empty-state reachability/copy gaps. [VERIFIED: codebase grep] [VERIFIED: Phase 187 defects.ndjson] |
| PAGE-03 | Disconnected/reconnecting is communicated and stale mutating actions are disabled. | Add LiveView-contained lifecycle status and Playwright offline/reconnect tests; root layout alone cannot host `phx-disconnected` behavior. [CITED: https://hexdocs.pm/phoenix_live_view/js-interop.html] [CITED: https://playwright.dev/docs/api/class-browsercontext#browser-context-set-offline] |
| PAGE-04 | Every page is verified at 320/375/768/1024/1440 widths in light/dark. | Existing Playwright config has desktop and Pixel 5 projects; Phase 191 tests need explicit viewport loops or project additions. [VERIFIED: accrue_admin/playwright.config.js] [VERIFIED: 191-UI-SPEC.md] |
| CPY-01 | Error messages state what happened and how to recover. | Accrue voice requires measured, exact, native, durable copy; UI-SPEC provides error/disconnected/recovered examples. [VERIFIED: brandbook/voice.md] [VERIFIED: 191-UI-SPEC.md] |
| CPY-02 | Destructive confirmations name the specific object and consequence. | `StepUpAuthModal` callers in charge, invoice, and subscription LiveViews are the main confirmation surfaces. [VERIFIED: codebase grep] |
| CPY-03 | Domain vocabulary is consistent across headings, tabs, filters, buttons, alerts. | Use existing copy helpers where present and audit inline strings in LiveViews/components. [VERIFIED: codebase grep] [VERIFIED: brandbook/copy.md] |
| SEED-01 | Host seeds reach every matrix cell in one click, including missing optional, permission-denied, boundary pagination, high counts, non-ASCII, disconnected/reconnecting. | Extend `examples/accrue_host` seeds plus E2E forcing endpoints; current seeds cover long names, JPY, dunning/at-risk, canceling, webhook failure, and overflow. [VERIFIED: examples/accrue_host/priv/repo/seeds/*.exs] |
| SEED-02 | Seed expansion is idempotent and deterministic. | Existing seed tests assert no duplicate seed-dunning events; new rows should use keyed insert/upsert patterns and namespace `e2e_phase191_*`. [VERIFIED: examples/accrue_host/test/seeds_idempotency_test.exs] [VERIFIED: CONTEXT.md] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- This repository is Accrue, an Elixir/Phoenix billing library with `accrue_admin` as the embeddable admin UI package. [VERIFIED: CLAUDE.md]
- Project-specific skills were not found in `.claude/skills` or `.agents/skills`; no project skill overrides apply. [VERIFIED: filesystem scan]
- Work must preserve GSD phase artifacts and should not rewrite unrelated user/worktree changes. [VERIFIED: CLAUDE.md] [VERIFIED: git status]
- No `AGENTS.md` exists, so there are no additional AGENTS.md directives to include. [VERIFIED: filesystem scan]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Phoenix | Locked 1.8.7; latest observed 1.8.8 | Router, endpoint, components, LiveView host integration | Existing admin router and package mount use Phoenix 1.8; do not upgrade for this phase. [VERIFIED: mix hex.info phoenix] [VERIFIED: accrue_admin/mix.exs] |
| Phoenix LiveView | Locked 1.1.31; latest observed 1.2.3 | Server-rendered interactive admin pages, JS commands, hooks, lifecycle bindings | Existing admin pages are LiveViews/LiveComponents, and official docs provide focus and lifecycle primitives needed here. [VERIFIED: mix hex.info phoenix_live_view] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html] |
| `Phoenix.Component.focus_wrap/1` | Included with LiveView lock | Focus containment for modals, dialogs, and menus | Official component wraps tab focus around a container; use it before custom focus-trap code. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#focus_wrap/1] |
| Existing `ax-*` CSS/token system | Package-local | Layering, focus, spacing, type roles, state styling | Phase 188 made `--ax-*` tokens the admin SSOT; layer tokens are `--ax-z-sticky/dropdown/popover/drawer/modal/toast`. [VERIFIED: 188-CONTEXT.md] [VERIFIED: accrue_admin/assets/css/theme.css] |
| Playwright test runner | Locked 1.59.1; npm latest observed 1.61.0 | Browser-level page-flow regression tests | Existing E2E suite uses Playwright; actionability and focus assertions directly fit overlay/focus defects. [VERIFIED: package-lock.json] [CITED: https://playwright.dev/docs/actionability] |
| ExUnit / Mix | 1.19.5 | Elixir tests and seed idempotency tests | Existing host/admin tests use Mix and ExUnit; no new test framework needed. [VERIFIED: environment probe] [VERIFIED: examples/accrue_host/test/seeds_idempotency_test.exs] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `@axe-core/playwright` | Locked/latest observed 4.11.3 | Critical/serious accessibility checks across admin pages | Keep `npm run e2e:a11y` green after interaction and copy changes. [VERIFIED: npm view @axe-core/playwright] [VERIFIED: accrue_admin/e2e/admin-a11y.spec.js] |
| `AccrueAdmin.E2E.Plug` | Package-local | Reset, login, seed, and forced state endpoints | Add Phase 191 deterministic state forcing here, not in production router. [VERIFIED: accrue_admin/test/support/e2e_plug.ex] |
| `AccrueAdmin.E2E.Fixtures` | Package-local | Test database setup for Playwright flows | Add stable IDs and return payload fields for one-click route building. [VERIFIED: accrue_admin/test/support/e2e_fixtures.ex] |
| `examples/accrue_host` seeds | Package-local | Host click-through demo/fixture data | Add deterministic `e2e_phase191_*` records and update idempotency coverage. [VERIFIED: examples/accrue_host/priv/repo/seeds/*.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| LiveView JS + `focus_wrap` + small local hooks | Third-party focus-trap/dialog package | Rejected by context: no broad third-party UI primitive library; extra package adds integration and legitimacy risk. [VERIFIED: CONTEXT.md] |
| Existing Playwright E2E suite | New pixel-diff/visual service | Rejected by context: pixel-diff tooling is out of scope; existing output paths already hold evidence. [VERIFIED: CONTEXT.md] |
| `baseline-manifest.js` page-flow matrix | A new hand-written page inventory | Rejected because Phase 187/191 contracts freeze the manifest/cell grammar. [VERIFIED: accrue_admin/e2e/baseline-manifest.js] [VERIFIED: 191-UI-SPEC.md] |
| Test-only E2E forcing endpoints | Manual database edits or production-only query params | Rejected because one-click reachability and no public route/API breaks are locked. [VERIFIED: CONTEXT.md] |

**Installation:**

No new packages are recommended for Phase 191. Use the existing lockfiles. [VERIFIED: package.json] [VERIFIED: CONTEXT.md]

```bash
cd accrue_admin && npm ci
cd accrue_admin && mix deps.get
```

**Version verification:** `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, `npm view @playwright/test version`, and `npm view @axe-core/playwright version` were run on 2026-06-18. [VERIFIED: command output]

## Package Legitimacy Audit

No new external packages should be installed for this phase. Existing referenced npm test tools were checked because the research names them. [VERIFIED: package-legitimacy gate] [VERIFIED: npm view]

| Package | Registry | Age / Publish Signal | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|----------------------|-----------|-------------|---------|-------------|
| `@playwright/test` | npm | Latest publish flagged as too-new by the gate; repo lock uses 1.59.1 | 42,434,109/week | github.com/microsoft/playwright | SUS | Keep existing lockfile. Planner must add `checkpoint:human-verify` before any Playwright install/upgrade. [VERIFIED: package-legitimacy gate] |
| `@axe-core/playwright` | npm | Latest observed 4.11.3; modified 2026-06-15 | 5,196,540/week | github.com/dequelabs/axe-core-npm | OK | Approved as existing lockfile dependency. [VERIFIED: package-legitimacy gate] |

**Packages removed due to SLOP verdict:** none. [VERIFIED: package-legitimacy gate]
**Packages flagged as suspicious SUS:** `@playwright/test` only if the planner installs or upgrades it; no action needed when using the existing lockfile. [VERIFIED: package-legitimacy gate]

## Architecture Patterns

### System Architecture Diagram

```text
Playwright page-flow spec
  -> /__e2e__/reset + /__e2e__/seed/* + /__e2e__/login
  -> AccrueAdmin.E2E.Plug (test endpoint only)
  -> AccrueAdmin.E2E.Fixtures + TestRepo
  -> LiveView admin route from baseline-manifest.js
  -> Shared components/hooks (AppShell, DataTable, DetailDrawer, StepUpAuthModal, DropdownMenu, GlobalSearch, mobile nav)
  -> Browser interaction assertions (focus, scroll, hit target, Escape, outside click, reconnect, copy)
  -> Evidence under accrue_admin/test-results and AX187/tag-linked regression results
```

The production admin route tree remains `AccrueAdmin.Router.accrue_admin/2`; test forcing enters through `AccrueAdmin.E2E.Server` and `E2E.Plug`, which require `MIX_ENV=test`. [VERIFIED: accrue_admin/lib/accrue_admin/router.ex] [VERIFIED: accrue_admin/test/support/e2e_server.ex]

### Recommended Project Structure

```text
accrue_admin/
+-- assets/js/hooks/        # small package-local hooks for focus/overlay/mobile-nav behavior
+-- assets/css/             # ax token consumers; no literal z-index additions
+-- lib/accrue_admin/components/
|   +-- detail_drawer.ex
|   +-- step_up_auth_modal.ex
|   +-- dropdown_menu.ex
|   +-- global_search.ex
|   +-- app_shell.ex
+-- lib/accrue_admin/live/  # page-specific state/copy/focus fallbacks when shared components are insufficient
+-- test/support/           # E2E plug/fixtures for deterministic state forcing
+-- e2e/                    # AX187-tagged Playwright regression specs

examples/accrue_host/
+-- priv/repo/seeds/        # deterministic click-through seed records
+-- test/                   # seed idempotency and cleanup tests
```

This structure follows existing package boundaries and avoids public route/API changes. [VERIFIED: codebase grep] [VERIFIED: CONTEXT.md]

### Pattern 1: Shared Overlay Fixes Before Page-Specific Fixes

**What:** Repair focus, scroll, Escape, outside-click, and layering in shared components/hooks first, then add page-specific code only for page-local state. [VERIFIED: codebase grep]

**When to use:** Use for `DetailDrawer`, `StepUpAuthModal`, `DropdownMenu`, command palette, mobile nav, and page action confirmations. [VERIFIED: Phase 187 defects.ndjson] [VERIFIED: 191-UI-SPEC.md]

**Example:**

```elixir
# Source: Phoenix.Component docs and existing StepUpAuthModal pattern.
# Keep the actual implementation inside the package component.
<.focus_wrap id="accrue-admin-step-up-focus">
  <div
    id="accrue-admin-step-up-dialog"
    role="dialog"
    aria-modal="true"
    phx-mounted={
      Phoenix.LiveView.JS.push_focus()
      |> Phoenix.LiveView.JS.focus_first(to: "#accrue-admin-step-up-dialog")
    }
    phx-remove={Phoenix.LiveView.JS.pop_focus()}
  >
    ...
  </div>
</.focus_wrap>
```

LiveView docs identify `focus_first`, `push_focus`, and `pop_focus`; `focus_wrap/1` wraps tab focus around modal/dialog/menu containers. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#focus_wrap/1]

### Pattern 2: AX187-Tagged Regression Tests

**What:** Convert Phase 187 observation gaps into corrected behavior assertions that cite `AX187-*` IDs or overlay tags. [VERIFIED: CONTEXT.md] [VERIFIED: Phase 187 defects.ndjson]

**When to use:** Every interaction fix, fixture reachability fix, and microcopy correction that closes a ledger row. [VERIFIED: CONTEXT.md]

**Example:**

```javascript
// Source: existing Playwright suite + Playwright actionability docs.
test("AX187-117 webhook replay confirmation closes with Escape and restores focus", async ({ page }) => {
  await seedOperatorFlows(page);
  await login(page);
  await page.goto(replayWebhookPath);

  const trigger = page.getByRole("button", { name: /replay webhook/i });
  await trigger.click();

  const dialog = page.getByRole("dialog", { name: /replay/i });
  await expect(dialog).toBeVisible();

  await page.keyboard.press("Escape");
  await expect(dialog).toBeHidden();
  await expect(trigger).toBeFocused();
});
```

Playwright `locator.click()` waits for visibility, stability, event receivability, and enabled state; focus assertions are built in. [CITED: https://playwright.dev/docs/actionability]

### Pattern 3: Deterministic Fixture State Forcing

**What:** Add explicit seeded records or test-only forcing controls so each matrix state is reachable in one click. [VERIFIED: CONTEXT.md]

**When to use:** Empty, loading, error, permission-denied, disconnected/reconnecting, overflow, boundary pagination, non-ASCII, null/missing optional fields, and high-count cases. [VERIFIED: REQUIREMENTS.md]

**Example:**

```elixir
# Source: existing examples/accrue_host seed upsert style.
upsert.(Customer, &Customer.changeset/2, "cus_e2e_phase191_missing_optional", %{
  owner_id: owner.id,
  processor: "fake",
  processor_id: "cus_e2e_phase191_missing_optional",
  name: "Phase 191 Optional Field Probe",
  email: nil
})
```

Existing seed files use deterministic processor IDs and `on_conflict: :nothing` or get-or-insert behavior; Phase 191 should follow that pattern. [VERIFIED: examples/accrue_host/priv/repo/seeds/edge_states.exs] [VERIFIED: examples/accrue_host/priv/repo/seeds/showcase.exs]

### Pattern 4: LiveView-Contained Connection State

**What:** Render reconnect/disconnect state inside the LiveView container and disable stale mutating actions while disconnected. [CITED: https://hexdocs.pm/phoenix_live_view/js-interop.html] [VERIFIED: 191-UI-SPEC.md]

**When to use:** Admin app shell or page content that participates in the LiveView render tree. Do not rely on root layout markup for `phx-disconnected` because LiveView docs say lifecycle bindings only work inside a LiveView container. [CITED: https://hexdocs.pm/phoenix_live_view/js-interop.html] [VERIFIED: accrue_admin/lib/accrue_admin/layouts.ex]

### Anti-Patterns to Avoid

- **Encoding Phase 187 broken observations as passing behavior:** Phase 191 must assert corrected behavior from `191-UI-SPEC.md`. [VERIFIED: CONTEXT.md]
- **Adding a UI framework or primitive package:** Context explicitly forbids broad client frameworks and third-party UI primitive libraries for this phase. [VERIFIED: CONTEXT.md]
- **Literal z-index repairs:** Use `--ax-z-*` tokens, since Phase 188 centralized the layer stack and `theme.css` defines the current values. [VERIFIED: 188-CONTEXT.md] [VERIFIED: accrue_admin/assets/css/theme.css]
- **Manual DB setup for page states:** One-click reachability is locked; manual DB edits fail SEED-01/SEED-02. [VERIFIED: CONTEXT.md] [VERIFIED: REQUIREMENTS.md]
- **A separate page inventory:** Use `baseline-manifest.js` and Phase 187 cell IDs so Phase 192 can compare forward progress. [VERIFIED: accrue_admin/e2e/baseline-manifest.js] [VERIFIED: 187-BASELINE.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Page-flow inventory | New hard-coded route/state list | `baseline-manifest.js` `SURFACES.filter(surface_type === "page-flow")` | Keeps Phase 187/192 cell grammar and owner-phase routing intact. [VERIFIED: codebase grep] |
| Modal focus stack | Third-party focus-trap package or broad UI primitive library | `Phoenix.Component.focus_wrap/1`, `JS.focus_first`, `JS.push_focus`, `JS.pop_focus`, and small local hooks | Official LiveView primitives cover the needed focus behavior and phase context forbids broad third-party primitives. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#focus_wrap/1] [VERIFIED: CONTEXT.md] |
| Overlay hit-target testing | Forced clicks that bypass actionability | Normal Playwright locators and `expect(...).toBeVisible/toBeFocused/toBeDisabled` | Playwright actionability catches obscured controls, disabled controls, and unstable elements. [CITED: https://playwright.dev/docs/actionability] |
| Disconnected/reconnecting simulation | Manual browser/network setup instructions | Playwright `browserContext.setOffline(true/false)` plus LiveView lifecycle UI | Playwright supports offline emulation, and LiveView exposes lifecycle bindings. [CITED: https://playwright.dev/docs/api/class-browsercontext#browser-context-set-offline] [CITED: https://hexdocs.pm/phoenix_live_view/js-interop.html] |
| Seed state setup | Manual SQL or duplicated random seed rows | Existing keyed seed helpers, `on_conflict: :nothing`, and E2E endpoints | Existing idempotency tests enforce re-runnable seed behavior. [VERIFIED: examples/accrue_host/test/seeds_idempotency_test.exs] |
| Visual regression tooling | New pixel-diff service | Existing Playwright/a11y/baseline evidence paths | Pixel-diff tooling is explicitly deferred. [VERIFIED: CONTEXT.md] |

**Key insight:** Most failures are integration failures across already-existing pieces, not missing primitives. Planning should spend tasks on shared behavior contracts, deterministic state reachability, and regression tests rather than new abstractions. [VERIFIED: Phase 187 defects.ndjson] [VERIFIED: 190-PHASE-191-HANDOFF.md]

## Common Pitfalls

### Pitfall 1: Focus Trap Without Focus Restore

**What goes wrong:** Tab stays in the overlay, but closing leaves focus on `body` or a removed element. [VERIFIED: Phase 187 defects.ndjson]
**Why it happens:** LiveView patches can remove the trigger or replace the surrounding DOM before client focus is restored. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [VERIFIED: Phase 187 defects.ndjson]
**How to avoid:** Store trigger focus with LiveView JS where possible; define a fallback order of retained trigger, state alert, then page heading. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html] [VERIFIED: 191-UI-SPEC.md]
**Warning signs:** `document.activeElement` is `body`, a hidden element, or an element behind an active overlay after close/patch. [VERIFIED: 191-UI-SPEC.md]

### Pitfall 2: `phx-disconnected` In The Root Layout

**What goes wrong:** Disconnected UI is rendered outside the LiveView container and never receives LiveView lifecycle callbacks. [CITED: https://hexdocs.pm/phoenix_live_view/js-interop.html]
**Why it happens:** Root layout markup is a regular view around the LiveView, and LiveView docs state `phx-connected`/`phx-disconnected` only take effect inside LiveView containers. [CITED: https://hexdocs.pm/phoenix_live_view/js-interop.html] [VERIFIED: accrue_admin/lib/accrue_admin/layouts.ex]
**How to avoid:** Put connection state UI in `AppShell` or page LiveView markup, and test with `browserContext.setOffline`. [VERIFIED: accrue_admin/lib/accrue_admin/components/app_shell.ex] [CITED: https://playwright.dev/docs/api/class-browsercontext#browser-context-set-offline]
**Warning signs:** Offline test never exposes the status text, or mutating buttons remain enabled while offline. [VERIFIED: REQUIREMENTS.md]

### Pitfall 3: Treating Observation Specs As Regression Specs

**What goes wrong:** Tests keep recording defects instead of asserting fixed behavior. [VERIFIED: accrue_admin/e2e/admin-interactions.spec.js]
**Why it happens:** `admin-interactions.spec.js` was built as a Phase 187 observation probe and writes observations to NDJSON. [VERIFIED: accrue_admin/e2e/admin-interactions.spec.js]
**How to avoid:** Add Phase 191 regression specs or refactor targeted probes into assertions with AX187 IDs. [VERIFIED: CONTEXT.md]
**Warning signs:** A test only appends observation rows and has no `expect` for corrected behavior. [VERIFIED: codebase grep]

### Pitfall 4: Fixture Coverage That Is Reachable Only By A Human

**What goes wrong:** A state exists in the database but cannot be reached by one click from a deterministic URL or helper. [VERIFIED: CONTEXT.md]
**Why it happens:** Seeds create records without returning IDs, route builders, filters, or dashboard launch points. [VERIFIED: accrue_admin/test/support/e2e_fixtures.ex]
**How to avoid:** Return route-building IDs from E2E seed endpoints and add host seed links/filter chips where appropriate. [VERIFIED: accrue_admin/test/support/e2e_plug.ex] [VERIFIED: accrue_admin/e2e/baseline-manifest.js]
**Warning signs:** Playwright setup must query the DB directly or hard-code IDs not emitted by the seed endpoint. [VERIFIED: 191-UI-SPEC.md]

### Pitfall 5: Upgrading Playwright During Interaction Work

**What goes wrong:** Test behavior changes are mixed with app behavior changes. [ASSUMED]
**Why it happens:** npm latest for `@playwright/test` was observed as 1.61.0, while the repo lockfile uses 1.59.1; the package-legitimacy seam flags the latest publish as too-new. [VERIFIED: npm view] [VERIFIED: package-legitimacy gate]
**How to avoid:** Use the lockfile version unless a separate upgrade task and human checkpoint are added. [VERIFIED: package-lock.json]
**Warning signs:** `package-lock.json` changes only because `npm install` was run during a page-flow task. [ASSUMED]

## Code Examples

### One-Click Page Route Builder

```javascript
// Source: baseline-manifest.js exports SURFACES and routeBuilder metadata.
const pageFlows = manifest.SURFACES.filter((surface) => surface.surface_type === "page-flow");

async function resolveFlowRoute(page, flow) {
  const seed = flow.routeBuilder?.fixture || "dashboard";
  const ids = await postJson(page, `/__e2e__/seed/${seed}`);
  return flow.route.replace(/:([a-z_]+)/g, (_, key) => ids[key]);
}
```

Use existing `/__e2e__/seed/*` endpoints and returned fixture IDs to avoid hard-coded database IDs. [VERIFIED: accrue_admin/e2e/baseline-manifest.js] [VERIFIED: accrue_admin/test/support/e2e_plug.ex]

### Scroll Reachability Probe

```javascript
// Source: existing admin-interactions scroll probe pattern.
const target = page.locator(".ax-detail-drawer-body");
await expect(target).toBeVisible();
const before = await target.evaluate((el) => el.scrollTop);
await target.evaluate((el) => { el.scrollTop = el.scrollHeight; });
const after = await target.evaluate((el) => el.scrollTop);
expect(after).toBeGreaterThanOrEqual(before);
```

Use for AX187-436..439 and AX187-446..447, but assert real containers rather than recording an observation. [VERIFIED: Phase 187 defects.ndjson] [VERIFIED: accrue_admin/e2e/admin-interactions.spec.js]

### Disconnected/Reconnected Test

```javascript
// Source: Playwright BrowserContext docs.
await context.setOffline(true);
await expect(page.getByRole("status", { name: /connection lost|reconnecting/i })).toBeVisible();
await expect(page.getByRole("button", { name: /refund|void|replay|cancel/i })).toBeDisabled();

await context.setOffline(false);
await expect(page.getByRole("status", { name: /connection restored/i })).toBeVisible();
```

`browserContext.setOffline` emulates offline network state. [CITED: https://playwright.dev/docs/api/class-browsercontext#browser-context-set-offline]

### Destructive Confirmation Copy Assertion

```javascript
// Source: 191-UI-SPEC microcopy contract.
await expect(page.getByRole("dialog")).toContainText(/Refund .* charge/i);
await expect(page.getByRole("dialog")).toContainText(/billing|ledger|audit|event/i);
```

Destructive confirmations must name the action, object, billing effect, and audit consequence when applicable. [VERIFIED: 191-UI-SPEC.md] [VERIFIED: CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 187 observation rows | Phase 191 corrected regression assertions | Phase 191 context on 2026-06-18 | Tests must prove intended behavior, not merely log broken behavior. [VERIFIED: CONTEXT.md] |
| Primitive/component proof only | Page-flow matrix across real admin routes | Phase 191 UI-SPEC | Shared components must be proven inside real pages and JTBD flows. [VERIFIED: 191-UI-SPEC.md] |
| Manifest desktop/mobile projects at 1440/390 | UI-SPEC requires 320/375/768/1024/1440 light/dark | Phase 191 UI-SPEC | Planner must add viewport loops or Playwright projects for Phase 191 evidence. [VERIFIED: accrue_admin/e2e/baseline-manifest.js] [VERIFIED: 191-UI-SPEC.md] |
| Host seeds cover selected edge states | One-click coverage for every page-flow state cell | Phase 191 context | Fixture tasks must close missing loading/error/permission/disconnected/optional/high-count cells. [VERIFIED: CONTEXT.md] |

**Deprecated/outdated:**

- Treating `admin-interactions.spec.js` as sufficient regression coverage is outdated; it is observation-oriented and Phase 191 needs assertions. [VERIFIED: accrue_admin/e2e/admin-interactions.spec.js] [VERIFIED: CONTEXT.md]
- Using Tailwind/shadcn/PhoenixStorybook/pixel-diff as the next step is out of scope for this phase. [VERIFIED: CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Playwright upgrades during this phase would mix toolchain behavior changes with app behavior changes. | Common Pitfalls | Planner may either over-constrain package changes or fail to add a checkpoint for an intentional upgrade. |
| A2 | `package-lock.json` churn from `npm install` during page-flow work is likely accidental unless tied to an explicit upgrade task. | Common Pitfalls | Planner may need to permit lockfile churn if implementation discovers a required test-tool bug. |

## Open Questions

1. **Should permission-denied become a stable rendered admin state or remain redirect-only outside tests?**
   - What we know: `AuthHook` rejects non-admin users before render, and E2E has member-login helpers. [VERIFIED: accrue_admin/lib/accrue_admin/auth_hook.ex] [VERIFIED: accrue_admin/test/support/e2e_auth_adapter.ex]
   - What's unclear: Whether PAGE-02 permission-denied should be proven through a test-only forced page state, a rendered package state, or existing redirect semantics. [VERIFIED: REQUIREMENTS.md]
   - Recommendation: Planner should create an early design/task checkpoint for permission-denied reachability that preserves no public route/API breaks. [VERIFIED: CONTEXT.md]

2. **Which state cells require host seeds versus E2E-only forcing?**
   - What we know: Host seeds should support one-click click-through, while E2E forcing can hold artificial loading/error/disconnected states. [VERIFIED: CONTEXT.md] [VERIFIED: accrue_admin/test/support/e2e_plug.ex]
   - What's unclear: The exact split per page-flow state after current seed coverage is enumerated. [VERIFIED: codebase grep]
   - Recommendation: Planner should schedule a Wave 0 matrix audit from `baseline-manifest.js` before fixture implementation. [VERIFIED: 191-UI-SPEC.md]

3. **Should viewport coverage be implemented by Playwright projects or per-test loops?**
   - What we know: Current `playwright.config.js` defines desktop 1280x900 and Pixel 5 projects, while UI-SPEC requires 320/375/768/1024/1440. [VERIFIED: accrue_admin/playwright.config.js] [VERIFIED: 191-UI-SPEC.md]
   - What's unclear: Whether runtime and artifact volume favor project expansion or explicit `page.setViewportSize` loops in targeted Phase 191 specs. [ASSUMED]
   - Recommendation: Use loops for targeted AX187/page-flow regression tests unless the planner needs CI project-level reporting. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix tests and E2E server | yes | 1.19.5 / OTP 28 | none needed. [VERIFIED: environment probe] |
| Mix | Admin/host tests | yes | 1.19.5 | none needed. [VERIFIED: environment probe] |
| Node.js | Playwright/npm scripts | yes | 22.14.0 | none needed. [VERIFIED: environment probe] |
| npm | Playwright dependencies | yes | 11.1.0 | none needed. [VERIFIED: environment probe] |
| Playwright CLI | E2E tests | yes | 1.59.1 lockfile CLI | Use `cd accrue_admin && npm ci` if missing. [VERIFIED: environment probe] |
| Test endpoint | E2E server | yes | `mix accrue_admin.e2e.server` | none needed. [VERIFIED: accrue_admin/playwright.config.js] |

**Missing dependencies with no fallback:** none found. [VERIFIED: environment probe]

**Missing dependencies with fallback:** none found. [VERIFIED: environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Playwright 1.59.1 for browser flows; ExUnit/Mix 1.19.5 for Elixir and seed tests. [VERIFIED: package-lock.json] [VERIFIED: environment probe] |
| Config file | `accrue_admin/playwright.config.js`; Mix project configs in `accrue_admin/mix.exs` and `examples/accrue_host/mix.exs`. [VERIFIED: codebase grep] |
| Quick run command | `cd accrue_admin && npm run e2e:group-contracts` for shared UI contracts; add focused Phase 191 spec commands as tests are created. [VERIFIED: package.json] |
| Full suite command | `cd accrue_admin && npm run e2e:a11y && npm run e2e -- e2e/admin-interactions.spec.js && npm run e2e:group-contracts` plus touched `mix test` and host seed tests. [VERIFIED: package.json] [VERIFIED: examples/accrue_host/test/seeds_idempotency_test.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| IXN-01 | Overlay visibility, layer, focus trap/restore, Escape/outside click | E2E regression | `cd accrue_admin && npm run e2e -- e2e/admin-page-flow-phase191.spec.js` | no, Wave 0. [VERIFIED: codebase grep] |
| IXN-02 | Page/container scroll reachability | E2E regression | `cd accrue_admin && npm run e2e -- e2e/admin-page-flow-phase191.spec.js` | no, Wave 0. [VERIFIED: Phase 187 defects.ndjson] |
| IXN-03 | LiveView patch focus and keyboard-only flows | E2E regression | `cd accrue_admin && npm run e2e -- e2e/admin-page-flow-phase191.spec.js` | no, Wave 0. [VERIFIED: 191-UI-SPEC.md] |
| IXN-04 | Floating overlay position and non-obscuring hit targets | E2E regression | `cd accrue_admin && npm run e2e:group-contracts` plus Phase 191 page-flow spec | partial; group contract exists, page-flow spec missing. [VERIFIED: admin-group-contracts.spec.js] |
| IXN-05 | Every owner 191 defect covered | E2E/regression artifact audit | `cd accrue_admin && npm run e2e -- e2e/admin-page-flow-phase191.spec.js` plus AX187 coverage audit | no, Wave 0. [VERIFIED: Phase 187 defects.ndjson] |
| PAGE-01 | 21 admin page flows across required states | E2E matrix | `cd accrue_admin && npm run e2e -- e2e/admin-page-flow-phase191.spec.js` | no, Wave 0. [VERIFIED: baseline-manifest.js] |
| PAGE-02 | Empty/unavailable/permission-denied distinction | E2E + copy assertions | Phase 191 page-flow spec | no, Wave 0. [VERIFIED: REQUIREMENTS.md] |
| PAGE-03 | Disconnected/reconnecting status and disabled stale actions | E2E offline/reconnect | Phase 191 page-flow spec using `context.setOffline` | no, Wave 0. [CITED: https://playwright.dev/docs/api/class-browsercontext#browser-context-set-offline] |
| PAGE-04 | 320/375/768/1024/1440 light/dark layout pass | E2E viewport loop | Phase 191 page-flow spec | no, Wave 0. [VERIFIED: 191-UI-SPEC.md] |
| CPY-01..03 | Error, destructive, and vocabulary copy | E2E DOM assertions + optional copy export audit | Phase 191 page-flow spec and copy audit command if added | partial; copy helpers exist, phase spec missing. [VERIFIED: codebase grep] |
| SEED-01 | One-click fixture reachability | ExUnit + E2E smoke | `cd examples/accrue_host && mix test test/seeds_idempotency_test.exs`; Phase 191 E2E fixture smoke | partial; existing seed test exists. [VERIFIED: examples/accrue_host/test/seeds_idempotency_test.exs] |
| SEED-02 | Idempotent deterministic seed expansion | ExUnit | `cd examples/accrue_host && mix test test/seeds_idempotency_test.exs` | yes, may need updates. [VERIFIED: examples/accrue_host/test/seeds_idempotency_test.exs] |

### Sampling Rate

- **Per task commit:** Run the most focused Mix/Playwright spec for touched files, plus `cd accrue_admin && npm run e2e:group-contracts` after shared component/hook changes. [VERIFIED: package.json]
- **Per wave merge:** Run Phase 191 page-flow spec, `npm run e2e:group-contracts`, touched a11y specs, and affected Mix tests. [VERIFIED: CONTEXT.md]
- **Phase gate:** `cd accrue_admin && npm run e2e:a11y && npm run e2e:group-contracts && npm run e2e -- e2e/admin-interactions.spec.js` plus Phase 191 regression spec and host seed idempotency tests. [VERIFIED: package.json] [VERIFIED: CONTEXT.md]

### Wave 0 Gaps

- [ ] `accrue_admin/e2e/admin-page-flow-phase191.spec.js` or equivalent: AX187-tagged assertions for overlays, scroll, focus patching, states, copy, and fixtures. [VERIFIED: codebase grep]
- [ ] A fixture matrix helper that consumes `baseline-manifest.js` `SURFACES` and E2E seed payloads. [VERIFIED: baseline-manifest.js]
- [ ] E2E forcing endpoints/helpers for stable empty, loading, error, permission-denied, disconnected/reconnecting, null optional, boundary pagination, non-ASCII, and high-count cells. [VERIFIED: REQUIREMENTS.md]
- [ ] Seed idempotency assertions for new `examples/accrue_host` Phase 191 records. [VERIFIED: examples/accrue_host/test/seeds_idempotency_test.exs]
- [ ] AX187 coverage audit that maps fixed defects to tests/artifact refs. [VERIFIED: CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Preserve `AuthHook`/host auth adapter boundaries; E2E auth helpers remain test-only. [VERIFIED: accrue_admin/lib/accrue_admin/auth_hook.ex] [VERIFIED: accrue_admin/test/support/e2e_auth_adapter.ex] |
| V3 Session Management | yes | Do not alter session key threading in `AccrueAdmin.Router.__session__/3` except for explicitly scoped test support. [VERIFIED: accrue_admin/lib/accrue_admin/router.ex] |
| V4 Access Control | yes | Permission-denied fixtures must not bypass production owner-scope checks or introduce public forced states. [VERIFIED: AccrueAdmin.OwnerScope/AuthHook grep] [VERIFIED: CONTEXT.md] |
| V5 Input Validation | yes | Treat LiveView event payloads and `handle_params/3` params as untrusted; official LiveView docs require validation/authorization before resource access or mutation. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| V6 Cryptography | no new crypto | No new cryptography is required; do not hand-roll tokens or secrets for fixture states. [VERIFIED: CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView Admin UI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Test-only fixture controls exposed to production | Elevation of Privilege | Keep `E2E.Server` and fixture endpoints under `MIX_ENV=test` and test endpoint only. [VERIFIED: accrue_admin/test/support/e2e_server.ex] |
| Outside click mutates billing state | Tampering | Outside click may dismiss only; confirmations require explicit action buttons and server authorization. [VERIFIED: CONTEXT.md] |
| Query-param forced states bypass owner scope | Elevation of Privilege | Restrict forced states to E2E/test support or validate params through existing owner-scope/auth checks. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [VERIFIED: CONTEXT.md] |
| Error copy leaks sensitive IDs/secrets | Information Disclosure | Copy should name resource class, owner scope, route, or recovery path without exposing secrets. [VERIFIED: 191-UI-SPEC.md] |
| Disabled stale actions are visually disabled but still clickable | Tampering | Assert both disabled/aria-disabled state and Playwright actionability after disconnect. [CITED: https://playwright.dev/docs/actionability] |

## Sources

### Primary (HIGH confidence)

- Local codebase grep/read: `accrue_admin/e2e/baseline-manifest.js`, `admin-interactions.spec.js`, `admin-group-contracts.spec.js`, `admin-a11y.spec.js`, `playwright.config.js`, `E2E.Plug`, `E2E.Fixtures`, shared components/hooks, `examples/accrue_host` seeds/tests. [VERIFIED: codebase grep]
- Phase artifacts: `191-CONTEXT.md`, `191-UI-SPEC.md`, `187-RUBRIC.md`, `187-BASELINE.md`, `187-defects.ndjson`, `190-PHASE-191-HANDOFF.md`, `190-GROUP-CONTRACTS.md`, `188-CONTEXT.md`, `189-CONTEXT.md`, `190-CONTEXT.md`. [VERIFIED: filesystem read]
- Local command probes: Elixir/Mix/Node/npm/Playwright versions, `mix hex.info`, `npm view`, package-legitimacy gate. [VERIFIED: command output]

### Secondary (MEDIUM confidence)

- Phoenix LiveView JS docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html [CITED: official docs]
- Phoenix Component `focus_wrap/1` docs: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#focus_wrap/1 [CITED: official docs]
- Phoenix LiveView lifecycle/security docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html [CITED: official docs]
- Phoenix LiveView JS interop docs: https://hexdocs.pm/phoenix_live_view/js-interop.html [CITED: official docs]
- Playwright actionability docs: https://playwright.dev/docs/actionability [CITED: official docs]
- Playwright BrowserContext offline docs: https://playwright.dev/docs/api/class-browsercontext#browser-context-set-offline [CITED: official docs]
- WAI-ARIA APG modal dialog pattern: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/ [CITED: official docs]

### Tertiary (LOW confidence)

- A1/A2 in Assumptions Log about likely lockfile churn risk and upgrade-mixing risk. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH for local locked versions and existing tools; MEDIUM for official docs because docs are current and package lock is 1.1.31 for LiveView. [VERIFIED: mix hex.info] [CITED: official docs]
- Architecture: HIGH for codebase boundaries and phase constraints; MEDIUM for implementation recommendations that still need planning decomposition. [VERIFIED: codebase grep] [VERIFIED: CONTEXT.md]
- Pitfalls: MEDIUM because most are grounded in Phase 187 defects and official docs, but exact viewport sharding and upgrade-churn risk remain assumptions. [VERIFIED: Phase 187 defects.ndjson] [ASSUMED]

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 for local architecture; re-check npm/Hex latest versions before any dependency install or upgrade. [ASSUMED]
