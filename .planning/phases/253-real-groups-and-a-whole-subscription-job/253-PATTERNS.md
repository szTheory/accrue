# Phase 253: Real Groups and a Whole Subscription Job — Pattern Map

**Mapped:** 2026-10-27
**Responsibility groups classified:** 8
**Tracked analogs found:** 8 / 8 (no exact analog for stateful DataTable Storybook rendering)

## File Classification

Proposed new symbols/paths below are planning choices, not existing code or locked names. The concrete owner files are existing and tracked.

| New/Modified File or Responsibility | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | route/controller | request-response, LiveComponent events | same file `render/1` | exact owner |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | route/controller | request-response, event-driven | same file `subscription_area/1` and `render/1` | exact owner |
| Small production collection/detail function-component seam(s), if split (path TBD) | component | transform/render | the two LiveView renderers above; `components/detail.ex` | role-match |
| New collection/group Storybook story; update `storybook/components/subscription_detail.story.exs` | story/component | transform, request-response render | current subscription detail story | partial |
| Narrow collection story adapter, or targeted extension of `accrue_admin/storybook/_support/subscription_scenarios.ex` | utility | transform | `SubscriptionScenarios.assigns!/1` | partial |
| `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` plus list-link setup from `subscriptions_live_test.exs` | test | request-response, database/provider-fake I/O | both mounted suites | partial |
| New Phase 253 responsive Playwright spec | test | browser request-response/render | `subscription-stories-phase252.spec.js` and `phase252-story-helpers.js` | role-match |
| Existing required CI/acceptance aggregate and evidence owner | config/test | batch, process/browser/DB I/O | Phase 200 guardrail owner + Phase 252 runner/generator | role-match |

## Pattern Assignments

### Production collection and stateful DataTable

**Analogs:** `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:127-217`; `accrue_admin/lib/accrue_admin/components/data_table.ex:202-234,558-584`; `accrue_admin/test/accrue_admin/components/data_table_test.exs:393-435,472-519`.

`SubscriptionsLive` owns the PageHeader, filters, scoped query inputs, production columns/cards, clear behavior, and list-status slots. Preserve that ownership when extracting a small callable visual group. Keep the actual `DataTable` LiveComponent and its query/state lifecycle. It appends cursor rows and targets its own load-more/retry events with `@myself`; use the existing component tests for page-boundary and partial-read behavior.

```elixir
<.live_component
  module={DataTable}
  id="subscriptions"
  query_module={Subscriptions}
  current_owner_scope={@current_owner_scope}
  path={@table_path}
  params={@params}
  list_state={list_state(@params, @summary)}
  empty_reason={empty_reason(@params, @summary)}
>
  <:list_status :let={status}>
    <FilterChipBar.filter_chip_bar result_count={status.visible_count} ... />
  </:list_status>
</.live_component>
```

The current stories do not mount a stateful DataTable. The new story should exercise that production LiveComponent through a narrow deterministic query adapter and assert real rendered states; a copied table or standalone markup cannot prove its state/event behavior.

### Whole detail composition and story rendering

**Analogs:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex:252-333,333-625`; `storybook/components/subscription_detail.story.exs:9-45`; `accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs:103-148`.

Existing `subscription_area/1` is a production function component with explicit attrs/slot. It already renders the summary card, status, copyable ID, ordered facts, and actions. Reuse it inside the routed page; keep `SubscriptionLive` as route/scope/action authority. New symbols such as `subscriptions_collection/1` and `subscription_page_body/1` are proposals. The existing story calls only `SubscriptionLive.subscription_area/1`, so expand the production seam only as far as the whole-page Storybook composition needs.

```elixir
attr(:subscription, :any, required: true)
attr(:customer, :any, required: true)
attr(:admin_mount_path, :string, required: true)
slot(:between_facts_and_actions)

def subscription_area(assigns) do
  ~H"""
  <Detail.summary_card title={subscription_title(@subscription, @customer)}>...</Detail.summary_card>
  <Detail.summary_list rows={summary_rows(@subscription, @customer, @admin_mount_path, @current_owner_scope)} />
  <%= render_slot(@between_facts_and_actions) %>
  ...production eligible action band...
  """
end
```

Keep the existing story discipline: `SubscriptionDetail` maps declared variations through `SubscriptionScenarios.assigns!/1` into the production renderer. The slice test proves rendered story HTML equals production output and checks that TestRepo is not started. Do not promote its legacy compatibility variation IDs into required Phase 253 states or add story-authored action/copy rules.

### Narrow scenario input

**Analog:** `accrue_admin/storybook/_support/subscription_scenarios.ex:29-93`.

The adapter validates attribution/facts, builds actual domain structs, adds the scoped mount path and assigns, and does not start Repo. Reuse this boundary and the existing launch/team facts. Those facts represent detail scenarios, not a multi-row collection; do not reinterpret them as a paginated list. Add only the small collection query/data adapter needed to feed the production DataTable, leaving the domain fact source DB-free and avoiding a general fixture/schema layer.

### Mounted list → detail → review/result → return

**Partial analogs:** `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs:369-437`; `accrue_admin/test/accrue_admin/live/subscription_live_test.exs:149-213,508-570,1084-1100`.

The list test asserts a real scoped subscription link retains filter/view context; the detail tests separately prove normalized return path, staged action + step-up + Repo/audit result, and dismissal with zero Fake cancellation calls. Combine these existing patterns in one routed mounted journey using TestRepo and Processor.Fake. Retain current owner/actor/target/fingerprint assertions, and prove dismissal causes no dispatch or persistence. No current test is an exact analog for the whole composed journey.

### Responsive browser evidence and selectors

**Analogs:** `accrue_admin/e2e/phase252-story-helpers.js:18-20,83-115,764-885`; `accrue_admin/e2e/subscription-stories-phase252.spec.js:15-44`.

Reuse the browser launcher/theme/asset/geometry patterns, but adapt the case inventory to Phase 253's collection states, detail states, review/result, 320 CSS px, a 640px constrained content container, 767/768px breakpoint edges, 1280 CSS px, and both themes where the UI contract requires them. The current helper hard-codes `CANONICAL_STATES = [active, scheduled_cancellation, incomplete_evidence]`, 320/1280, and the Phase 252 manifest/result path. Do not reuse those selectors or completeness assertions as the Phase 253 contract; they would freeze old expectations. `accrue_admin/mix.lock:70` locks PhoenixStorybook 1.2.0 (`mix.exs:46` requests `~> 1.2`); use that installed API and add no dependency.

### Required aggregate and acceptance integration

**Analogs:** `scripts/ci/verify_phase200_admin_guardrails.sh:14-23`; `scripts/ci/verify_phase252_stories.mjs:228-255,269-286,640-656`; `scripts/ci/generate_phase252_acceptance.mjs`; `.github/workflows/ci.yml:1315-1325`.

The existing required owner invokes `npm --prefix accrue_admin run phase252:check`, and that runner separates DB-free stories, disposable Repo tests, mounted route tests, browser evidence, and acceptance validation. Integrate Phase 253's required cases and generated evidence through this existing required CI/acceptance ownership, keeping its source/result inventory current. Avoid a parallel required job or new gate architecture; preserve explicit automated assertions and `human_judgment: false` per `CLAUDE.md:201-208`.

## Shared Patterns

- **Production owns meaning:** use Copy, ScopedPath, action eligibility, truthful result state, and current owner scope from the existing LiveViews; story variation data supplies facts only.
- **Story evidence is settled presentation:** Storybook may render real production components and stateful DataTable with deterministic inputs; persistence, authority, dispatch, dismissal, and result truth belong to mounted automated tests.
- **Preserve useful state owners:** keep DataTable as a LiveComponent and detail actions in the routed LiveView. New function-component symbols should be small attrs/slots seams, not a page schema.
- **Keep CI evidence in the current required aggregate:** update consumed sources, test case inventory, browser evidence, and acceptance generation together.

## No Exact Analog

| Responsibility | Why |
|---|---|
| Storybook rendering of the real stateful subscription DataTable | Existing Storybook stories use function components; state/cursor/retry behavior is covered by ExUnit, not a mounted table story. |
| One mounted list-to-detail-to-dismiss-and-confirm journey | Current list context, detail return, action/step-up, and dismissal are separate tests. |
| Phase 253 matrix and evidence under existing phase naming | Phase 252 helpers/manifests/results and runner catalogs hard-code Phase 252 states and widths; reuse their mechanics selectively and update the owner contract deliberately. |

## Metadata

**Analog search scope:** Phase 252 patterns/stories/adapters, subscription LiveViews and DataTable, their mounted/component tests, Playwright helper/spec, required guardrail/acceptance runner.
**Tracked-source gate:** every named code analog was verified with `git ls-files`; no installed/runtime mirror paths are cited.
**Project guidance:** no repository-root `AGENTS.md` or `.codex/skills` / `.agents/skills` entries were present.
