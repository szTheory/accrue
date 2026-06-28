# Phase 198: Propagate DETAIL + analytics - Research

**Researched:** 2026-06-28
**Domain:** Phoenix LiveView admin UI detail-page propagation, analytics overview conformance
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

All four gray areas were researched with advisor subagents using the local specs,
prior phase context, target LiveViews, brandbook, prompt corpus, Elixir/Phoenix
idiom, and lessons from successful admin/payment dashboards. The recommendations
converged on one coherent package: per-page tuned propagation using existing
Phoenix function components and LiveView state, not a generic DSL.

#### Cohesive Recommendation

- **D-01 - Use per-page tuned SPEC-DETAIL propagation; do not introduce a
  generic `DetailPage` DSL/schema.** Existing `Detail.summary_list/1`,
  `Detail.detail_section/1`, `DropdownMenu.action_menu/1`,
  `DetailDrawer.detail_drawer/1`, `Overlay.overlay/1`,
  `RelatedResources.related_resources/1`, `Timeline.timeline/1`, and
  `JsonViewer.json_viewer/1` are enough. Keep event flow and data loading in the
  LiveView where Phoenix developers can read it. A declarative detail-page
  schema would hide status/provider/action rules behind a leaky abstraction.
- **D-02 - Delete top-level KPI grids from detail pages.** Facts that answer
  "what state, what is wrong, what can I do next" move into summary-list rows.
  Useful metrics can survive as compact drill-local facts where they serve the
  section's job. Do not leave KPI cards as the visual headline of an object
  detail page.
- **D-03 - Preserve page-specific nouns and jobs.** The pattern is common, but
  the rows and drills are resource-specific. Use operator language in copy:
  "Payment", "Invoice", "Default payment method", "Platform fee override",
  "Replay delivery", "Access", "Activity", "Raw data". Hide backend plumbing
  unless it is operationally necessary.
- **D-04 - Use existing LiveView composition idioms.** Shared markup remains
  stateless function components with attrs/slots; resource state, URL params,
  provider gates, drawer state, and action execution remain page-owned. Use
  `handle_params/3` for URL-backed subviews/filters and pure helper functions
  such as `summary_rows/1`, `primary_actions/1`, `action_menu_groups/1`, and
  `related_items/3` for testable presentation decisions.

#### Customer-360 Tab Policy

- **D-05 - Customer is the only permitted tab exception, and tabs are limited
  to peer record-sets.** Keep `Subscriptions`, `Invoices`, and `Payments`
  tabbed because they are equal-weight Customer-360 record collections. Remove
  the current broad `More` bucket.
- **D-06 - Move non-peer customer sections out of tabs.** `Payment methods`,
  `Entitlements`, `Events`, and `Metadata` are not peer record-set tabs:
  payment methods are operational object state with actions; entitlements are
  access/diagnostic state; events and metadata are audit/debug views. Move them
  into summary rows, drill sections, lazy Activity, and lazy Raw data.
- **D-07 - Keep Customer tab navigation as link/patched subviews unless a full
  ARIA tab component is implemented.** Do not label the existing link nav as
  ARIA tabs without keyboard semantics. Prefer patch links for same-LiveView
  subview changes and preserve compatibility for existing `?tab=` URLs,
  including the UI label `Payments` over internal `charges`.
- **D-08 - Move Customer data loads out of render helpers where practical.**
  Today the customer page can compute subscriptions/invoices/charges/events from
  render helpers. Phase 198 should assign the active peer record-set and lazy
  sections through mount/params/events so re-renders stay predictable.

#### Action Surfaces and Drawers

- **D-09 - Forms appear only after operator intent.** Initial detail-page load
  must render zero visible action-band forms. Invoice action prep, draft manual
  line-item add/remove, charge refund, webhook replay confirmation, connect
  platform-fee override, and payment-method delete/set-default flows move into
  `DetailDrawer` or step-up modal paths as appropriate.
- **D-10 - At most two visible primary actions per detail page.** Primary
  buttons are status-gated and only for the highest-frequency valid jobs. Omit
  unavailable actions rather than rendering disabled-looking-enabled controls.
  Render an overflow menu only when there are more than two valid actions.
- **D-11 - Keep action state server-owned.** Use page-owned LiveView events
  following the subscription exemplar shape: open/select action, prepare/validate
  drawer form, confirm action, cancel pending action, then `StepUp.require_fresh/4`
  for sensitive operations. Do not introduce client-only action state.
- **D-12 - Sensitive and money-moving actions require step-up unless already
  proven lower-risk.** Keep invoice `void` / `mark_uncollectible` and charge
  refund behind step-up. Add step-up for webhook replay and connect platform-fee
  override unless planning records a specific reason they are non-sensitive.
- **D-13 - Page-specific action recommendations are locked.**
  - Invoice: primary actions are status-gated. Draft invoices prioritize
    `Finalize invoice` and, when useful, `Add line item`; collectible invoices
    prioritize `Pay invoice`. Overflow groups: `Collection`, `Documents`,
    `Danger zone`; `Void invoice` and `Mark uncollectible` are last and step-up
    gated.
  - Charge/payment: one visible `Refund charge` primary action opens the drawer.
    Refund amount/reason/source-event fields and confirmation stay off page load;
    confirm is step-up gated.
  - Webhook: show `Replay webhook` only when the row is failed/dead and
    unambiguous. No disabled replay button for non-replayable rows; show precise
    state copy instead.
  - Connect account: one visible `Edit platform fee override` primary action
    opens the drawer; saving the override is step-up gated.
  - Coupon, promotion-code, event: omit action bands unless a real valid action
    exists. Read-only pages should not render empty overflow menus.

#### Summary Rows and Drill Grouping

- **D-14 - Every target detail page gets a summary-list header.** Use
  `Detail.summary_card/1` as the wrapper and `Detail.summary_list/1` for the
  always-visible facts. Summary rows should answer the operator's first scan:
  state, owner/customer, amount/value, current boundary, next boundary, and the
  one risk or action signal that matters for that object.
- **D-15 - Related resources sit once, after primary object drills and before
  lazy Activity / Raw data.** Add or preserve `data-ax-related-resources` around
  the single canonical strip. Do not duplicate navigation cards.
- **D-16 - Timeline and raw payloads are lazy bottom sections.** Activity and
  raw JSON remain available, but they should not be eagerly loaded/rendered above
  the fold. Use the subscription detail lazy pattern (`data-ax-lazy-activity`,
  `data-ax-lazy-json`) where it applies.
- **D-17 - Page-by-page grouping direction is locked.**
  - Customer: summary rows for owner, processor customer ID, locale/timezone,
    default payment method, billing health, tax risk, and access headline when
    cheap. Drills: Payment methods, Access & entitlements, Tax & ownership.
    Peer tabs: Subscriptions, Invoices, Payments. Lazy bottom: Activity and Raw
    data.
  - Invoice: summary rows for status, customer, amount due/remaining/paid,
    due/finalized boundary, collection method, PDF/hosted URL state, tax/finalize
    risk, and line-item count. Drills: Collection & actions, Line items, Tax &
    documents. Lazy bottom: Activity and Raw data.
  - Charge/payment: summary rows for status, customer, amount, processor,
    inserted/created boundary, net/fee/refund signal. Drills: Fee breakdown and
    Refunds. Drawer: Refund. Lazy bottom: Activity and Raw data.
  - Coupon: summary rows for valid state, discount, duration, redeem-by, max
    redemptions, current redemptions, and promotion-code count. Drills: Promotion
    codes and Projection details. Lazy bottom: Raw data.
  - Promotion code: summary rows for active state, code, parent coupon, expiry,
    redemption count/limit, and customer restriction if present. Drills: Parent
    coupon and Redemption boundaries. Lazy bottom: Raw data.
  - Connect account: summary rows for account readiness, owner, country, charges
    enabled, payouts enabled, onboarding/details submitted, and override state.
    Drills: Capabilities/requirements and Platform fee policy. Drawer: Edit
    platform fee override.
  - Webhook: summary rows for status, processor event ID, endpoint/type,
    received/processed boundaries, verification, attempts, livemode, and derived
    event count. Drills: Replay eligibility, Dispatch/retry lifecycle, Derived
    ledger rows. Lazy bottom: Raw payload and metadata.
  - Event: summary rows for type, actor, subject, source webhook, recorded time,
    and livemode if available. Drills: Event details. Related resources link to
    subject/actor/webhook where possible. Lazy bottom: Raw data if payload exists.

#### Recovery and Campaign Analytics Grammar

- **D-18 - Treat Recovery as a Recovery-specific overview, not a dashboard clone.**
  The correct order is orientation + window selector, hero metric pair, at-risk
  work queue, then supporting funnel. Do not replace the funnel with a new chart
  or time-series component in this phase.
- **D-19 - Clarify the verifier/marker contract for Recovery.** Recovery should
  be judged by SPEC-OVERVIEW's Recovery clause ("hero metric pair -> at-risk
  work-queue -> trend/supporting visualization"), not by the Dashboard's literal
  attention-rail -> task-launcher -> KPI-cluster DOM order. Update page-flow
  assertions/markers accordingly and fix stale component docs that still describe
  `AtRiskTable` as below the funnel.
- **D-20 - Treat Campaign as a detail drill-down.** `/analytics/recovery/subscriptions/:id`
  answers "what happened to this one subscription's dunning path?" Keep
  `Detail.summary_card`, add/preserve concise campaign facts, and keep
  `CampaignTimeline` as the primary drill. Do not add overview KPIs or chart-wall
  structure to Campaign.
- **D-21 - Do not introduce an `AnalyticsPage` abstraction.** Recovery and
  Campaign have different jobs and routes. Explicit composition keeps window
  params, row links, timeline data, and copy readable.

#### Verification and Planning Shape

- **D-22 - Verify contract conformance across all target pages, with deeper
  coverage on high-risk representatives.** ExUnit should cover summary rows,
  exactly one `<h1>`, action count/overflow/form absence, related-strip count,
  lazy Activity/Raw data, and page-owned gating. Playwright should smoke all
  target detail/analytics pages across desktop/mobile and light/dark for
  SPEC-DETAIL / SPEC-OVERVIEW markers and no obvious clipping. Deeper interactive
  drawer/step-up coverage belongs on invoice, charge, webhook, connect account,
  and customer payment-method flows.
- **D-23 - Keep Phase 199/200 boundaries intact.** Phase 198 may use the frozen
  overlay/drawer primitives and add page-flow assertions, but the cross-page
  overlay sweep, transformed-ancestor audit, reduced-motion/FOUC checks, full
  copy sweep, Storybook completeness, and final zero-regression sign-off stay
  with Phase 199/200.

### the agent's Discretion

- Exact summary row labels, row order, and short body copy, bounded by brandbook
  voice: measured, exact, native, durable.
- Exact names of pure helper functions and where page-local helpers live.
- Whether a small reusable link-subview component is extracted for Customer
  peer tabs, provided it does not become a general page DSL.
- Exact `data-ax-*` marker placement under the locked selectors.
- Which target pages get the deepest browser matrix, provided the set includes
  Customer, Invoice, Charge, Webhook, Connect Account, Recovery, and Campaign.

### Deferred Ideas (OUT OF SCOPE)

- **Generic `DetailPage` DSL/schema** - deferred. Revisit only if post-198
  code leaves repeated, stable boilerplate that a narrow abstraction can remove
  without owning resource state or action flow.
- **Generic `AnalyticsPage` abstraction** - deferred. Recovery and Campaign
  have different jobs; explicit composition is clearer.
- **New Recovery trend chart / time-series replacement** - deferred. Keep the
  existing funnel as supporting visualization in Phase 198.
- **Full cross-page overlay sweep and transformed-ancestor audit** - Phase 199.
  Phase 198 uses the existing primitives but does not own the global overlay
  migration/audit.
- **Full microcopy sweep, fixture stress, no-FOUC/theme persistence, reduced
  motion, Storybook completeness, final zero-regression sign-off** - Phase 199
  and Phase 200.
- **Portal white-label billing design-system pass** - future `accrue_portal`
  milestone; explicitly out of this admin UI phase.

#### Reviewed Todos (not folded)

- **Shared page_header component for accrue_admin list pages**
  (`.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md`)
  - reviewed as a matcher but already folded into and resolved by Phases 196/197.
  Phase 198 uses DETAIL primitives, not a new PageHeader scope.
- **White-label billing portal design system**
  (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`)
  - reviewed and deferred because Phase 198 is `accrue_admin` operator UI only.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PRP-02 | All remaining detail/analytics pages (customer, invoice, charge, coupon, promotion-code, connect-account, webhook, event detail, Recovery, Campaign) conform to SPEC-DETAIL / the overview spec. | Use the Phase 195 subscription detail exemplar, the Phase 194 Recovery overview contract, and page-specific LiveView helpers/tests identified below. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: accrue_admin/guides/spec-detail.md; VERIFIED: accrue_admin/guides/spec-overview.md; VERIFIED: codebase rg] |
</phase_requirements>

## Summary

Phase 198 is an internal `accrue_admin` UI conformance phase, not a feature or dependency phase. The planner should preserve the existing Phoenix LiveView stack, reuse the Phase 195 DETAIL primitives, and migrate each target page with page-owned helpers such as `summary_rows/1`, `primary_actions/1`, `action_menu_groups/1`, `related_items/3`, and lazy-load handlers. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md; VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex]

The current codebase already has the required component vocabulary: `Detail.summary_card/1`, `Detail.summary_list/1`, `DropdownMenu.action_menu/1`, `DetailDrawer.detail_drawer/1`, `StepUpAuthModal.step_up_auth_modal/1`, `RelatedResources.related_resources/1`, `Timeline.timeline/1`, `JsonViewer.json_viewer/1`, `AtRiskTable.at_risk_table/1`, `FunnelChart.funnel_chart/1`, and `CampaignTimeline.campaign_timeline/1`. The gaps are page-level composition: KPI-first detail pages, inline action forms, broad Customer "More" tabs, eager timeline/JSON, missing exactly-one related-strip markers, and Recovery/Campaign marker grammar. [VERIFIED: codebase rg; VERIFIED: accrue_admin/lib/accrue_admin/components/detail.ex; VERIFIED: accrue_admin/lib/accrue_admin/components/dropdown_menu.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/customer_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/invoice_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex]

**Primary recommendation:** plan a page-by-page propagation with one shared test contract and no new runtime DSL, no package installs, no Tailwind migration, and no Phase 199/200 overlay/microcopy/storybook scope creep. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md; VERIFIED: CLAUDE.md]

## Project Constraints (from CLAUDE.md)

- Work inside the sibling `accrue_admin` package for LiveView operator UI changes; core `accrue` must remain LiveView-runtime-free and must not gain UI runtime work from this phase. [VERIFIED: CLAUDE.md]
- Keep the v1.54 scope to `accrue_admin`; do not build `accrue_portal`, new billing primitives, route/API breaks, Tailwind migration, or adopter-runtime Storybook leakage. [VERIFIED: CLAUDE.md; VERIFIED: .planning/REQUIREMENTS.md]
- Use existing dependencies and conventions: Phoenix 1.8, Phoenix LiveView 1.1, `phoenix_storybook` dev/test-only, custom `ax-*` CSS, committed static admin bundle, and copy modules under `AccrueAdmin.Copy`. [VERIFIED: CLAUDE.md; VERIFIED: accrue_admin/mix.exs; VERIFIED: accrue_admin/package.json]
- Before direct implementation edits, work through GSD workflow artifacts; this research file is the canonical planner input for Phase 198. [VERIFIED: CLAUDE.md; VERIFIED: gsd init.phase-op 198]
- Security posture remains strict: admin actions must preserve owner scope, audit records, step-up for sensitive operations, and no sensitive payment fields in logs. [VERIFIED: CLAUDE.md; VERIFIED: accrue_admin/lib/accrue_admin/auth_hook.ex; VERIFIED: accrue_admin/lib/accrue_admin/step_up.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Detail page composition | Frontend Server (LiveView) | Browser / Client | LiveViews own assigns, events, URL params, and HEEx render; browser hooks only enforce focus/overlay behavior. [VERIFIED: Phoenix.LiveView installed docs; VERIFIED: codebase rg] |
| Summary-list headers | Frontend Server (LiveView + function components) | Browser / Client | `Detail.summary_list/1` renders server-side data rows; browser only receives semantic markup. [VERIFIED: accrue_admin/lib/accrue_admin/components/detail.ex] |
| Action selection and drawer forms | Frontend Server (LiveView) | Browser / Client | `DropdownMenu.action_menu/1` triggers LiveView events; `DetailDrawer` presents the form via overlay/focus trap. [VERIFIED: accrue_admin/lib/accrue_admin/components/dropdown_menu.ex; VERIFIED: accrue_admin/lib/accrue_admin/components/detail_drawer.ex] |
| Sensitive action authorization | API / Backend | Frontend Server (LiveView) | `StepUp.require_fresh/4` delegates challenge/verification to `Accrue.Auth` and records audit events; LiveView orchestrates the UI state. [VERIFIED: accrue_admin/lib/accrue_admin/step_up.ex] |
| Owner-scope preservation | API / Backend | Frontend Server (LiveView) | `AuthHook` assigns `current_owner_scope`; query/detail functions and `ScopedPath` preserve scope in data access and links. [VERIFIED: accrue_admin/lib/accrue_admin/auth_hook.ex; VERIFIED: accrue_admin/lib/accrue_admin/scoped_path.ex; VERIFIED: accrue_admin/lib/accrue_admin/queries/webhooks.ex] |
| Lazy Activity / Raw JSON | Frontend Server (LiveView) | Database / Storage | Subscription exemplar assigns empty state first and loads timeline/raw data after an explicit event; target pages should mirror this. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex] |
| Recovery analytics overview | Frontend Server (LiveView) | API / Backend | Recovery assembles analytics data in `RecoveryLive` and renders hero metrics, `AtRiskTable`, then `FunnelChart`; no new analytics abstraction is needed. [VERIFIED: accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex] |
| Campaign drill-down | Frontend Server (LiveView) | API / Backend | Campaign loads dunning timeline groups and invoices, then renders `Detail.summary_card` plus `CampaignTimeline`. [VERIFIED: accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 local runtime | Compile/test `accrue_admin` LiveViews and ExUnit tests. | Available locally and compatible with the package `elixir: "~> 1.19"` setting. [VERIFIED: `elixir --version`; VERIFIED: accrue_admin/mix.exs] |
| PostgreSQL | 14.17 local `psql`; port 5432 accepting connections | `AccrueAdmin.TestRepo` SQL sandbox and migrated billing schema for tests. | Test helper creates storage and runs core migrations before ExUnit starts. [VERIFIED: `psql --version`; VERIFIED: `pg_isready`; VERIFIED: accrue_admin/test/test_helper.exs] |
| `:phoenix` | Locked 1.8.7; Hex latest 1.8.8 on 2026-06-28 | Router/Endpoint and LiveView host framework. | Existing package dependency is `~> 1.8`; do not upgrade in this phase. [VERIFIED: accrue_admin/mix.exs; VERIFIED: accrue_admin/mix.lock; VERIFIED: `mix hex.info phoenix`] |
| `:phoenix_live_view` | Locked 1.1.31; Hex latest 1.2.3 on 2026-06-28 | Server-rendered LiveView pages, function components, portals, events, and URL patches. | Existing package dependency is `~> 1.1`; Phase 198 should use current 1.1 APIs and avoid upgrade churn. [VERIFIED: accrue_admin/mix.exs; VERIFIED: accrue_admin/mix.lock; VERIFIED: `mix hex.info phoenix_live_view`] |
| `:phoenix_html` | Locked 4.3.0 | HEEx/html helper dependency. | Already part of `accrue_admin`; no Phase 198 change. [VERIFIED: accrue_admin/mix.lock] |
| `@playwright/test` | Local binary 1.59.1; npm latest 1.61.1 on 2026-06-28 | Browser conformance checks for detail/overview markers, viewport/theme smoke, drawers, focus, and clipping. | Existing e2e package scripts already gate Phases 194/195/197; add a Phase 198 script or extend the same pattern. [VERIFIED: accrue_admin/package.json; VERIFIED: `./node_modules/.bin/playwright --version`; VERIFIED: `npm view @playwright/test version time.modified`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:phoenix_storybook` | Locked 1.2.0 | Dev/test component story renderer. | Do not expand Storybook completeness in Phase 198; only avoid breaking existing stories if shared components are touched. [VERIFIED: accrue_admin/mix.exs; VERIFIED: accrue_admin/mix.lock; VERIFIED: .planning/REQUIREMENTS.md] |
| `:lazy_html` | Locked 0.1.11 | HTML assertions in tests. | Use existing test helper patterns when asserting rendered component/page HTML. [VERIFIED: accrue_admin/mix.exs; VERIFIED: accrue_admin/mix.lock] |
| `Oban` | Transitive existing dependency through core/admin stack | Webhook job history and replay/dispatch context. | Read existing `Oban.Job` rows for webhook lifecycle; do not introduce new job architecture. [VERIFIED: accrue_admin/lib/accrue_admin/live/webhook_live.ex; VERIFIED: accrue_admin/test/test_helper.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-page helper propagation | Runtime `DetailPage` DSL | Rejected by locked D-01 because resource state, status gates, URL params, and action flow would be hidden behind a leaky abstraction. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md] |
| `DetailDrawer` + page-owned events | Client-only action state | Rejected by locked D-11 because action state and validation must stay server-owned. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md; VERIFIED: Phoenix.LiveView installed docs] |
| Existing `FunnelChart` supporting Recovery | New Recovery trend/time-series chart | Deferred by locked D-18 and D-19; Phase 198 is conformance, not analytics redesign. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md] |
| Link/patched Customer subviews | ARIA tabs component | Only build full ARIA tabs if keyboard semantics are implemented; current locked path is link/patched subviews. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md; CITED: https://design-system.service.gov.uk/components/tabs/] |

**Installation:**

```bash
# No new packages. Use existing accrued_admin deps and node_modules.
```

**Version verification:**

```bash
cd accrue_admin
mix hex.info phoenix_live_view
mix hex.info phoenix
mix hex.info phoenix_storybook
./node_modules/.bin/playwright --version
npm view @playwright/test version time.modified
```

## Package Legitimacy Audit

Phase 198 should install no external packages, so the package-legitimacy gate is not required. Existing packages were verified from `accrue_admin/mix.exs`, `accrue_admin/mix.lock`, `accrue_admin/package.json`, local binaries, Hex registry metadata, and npm registry metadata. [VERIFIED: accrue_admin/mix.exs; VERIFIED: accrue_admin/mix.lock; VERIFIED: accrue_admin/package.json; VERIFIED: `mix hex.info`; VERIFIED: `npm view`]

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no new package install planned]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no new package install planned]

## Architecture Patterns

### System Architecture Diagram

```text
Admin route request
  -> AuthHook.on_mount(:ensure_admin)
      -> assigns current_admin + current_owner_scope
      -> target LiveView mount/handle_params
          -> scoped query/detail load
          -> summary_rows / primary_actions / related_items helpers
          -> HEEx render:
              breadcrumbs
              -> Detail.summary_card + Detail.summary_list
              -> action band (<=2 primary + optional DropdownMenu.action_menu)
              -> page-specific drill sections
              -> one [data-ax-related-resources] wrapper
              -> lazy Activity / Raw JSON bottom details
          -> operator event:
              open_action_drawer / prepare_* / validate_* / confirm_*
              -> DetailDrawer or StepUpAuthModal through Overlay portal
              -> StepUp.require_fresh for sensitive actions
              -> billing/webhook operation
              -> audit/event record
              -> refresh assigned record
```

Every arrow above is backed by existing project code or locked phase context, not a new runtime abstraction. [VERIFIED: accrue_admin/lib/accrue_admin/auth_hook.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/step_up.ex; VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]

### Recommended Project Structure

```text
accrue_admin/
├── lib/accrue_admin/live/                  # target LiveViews own state, URL params, action flow
├── lib/accrue_admin/live/analytics/        # Recovery overview and Campaign detail drill-down
├── lib/accrue_admin/components/            # existing stateless DETAIL/overlay/data components
├── lib/accrue_admin/copy/                  # page copy modules touched by this phase
├── test/accrue_admin/live/                 # focused LiveView contract tests per target page
├── test/accrue_admin/live/analytics/       # Recovery/Campaign tests
└── e2e/                                    # Phase 198 Playwright DETAIL/overview smoke
```

This structure matches the current repository layout. [VERIFIED: `rg --files accrue_admin/lib accrue_admin/test accrue_admin/e2e`]

### Pattern 1: Page-Owned State + Stateless Components

**What:** shared components render markup; LiveViews own resource state, URL params, drawer state, lazy-load flags, validation, and operation execution. [VERIFIED: Phoenix.LiveView installed docs; VERIFIED: Phoenix.Component installed docs; VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex]

**When to use:** every target detail and analytics page in Phase 198. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]

**Example:**

```elixir
# Source: accrue_admin/lib/accrue_admin/live/subscription_live.ex
<Detail.summary_list rows={summary_rows(@subscription, @customer, @admin_mount_path, @current_owner_scope)} />

<button
  :if={@swap_plan_available}
  type="button"
  class="ax-button ax-button-primary"
  phx-click="open_action_drawer"
  phx-value-action_type="swap_plan"
  data-ax-primary-action
>
  <%= action_label("swap_plan") %>
</button>
```

### Pattern 2: Action Menu Selects, Drawer Hosts

**What:** the action menu is not a form container; it triggers a page-owned event that opens a drawer or confirmation path. [VERIFIED: accrue_admin/lib/accrue_admin/components/dropdown_menu.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex]

**When to use:** invoice, charge, webhook, connect account, and Customer payment-method flows. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]

**Example:**

```elixir
# Source: accrue_admin/lib/accrue_admin/components/dropdown_menu.ex
<button
  :for={item <- group_items(group)}
  type="button"
  role="menuitem"
  phx-click={item_event(item)}
  phx-value-action_type={item_value(item)}
>
  <span class="ax-dropdown-item-label"><%= item_label(item) %></span>
</button>
```

### Pattern 3: Portal-Backed Drawer/Modal Requires Browser Assertions

**What:** `DetailDrawer` delegates to `Overlay.overlay/1`, which uses LiveView portals; LiveViewTest assertions need portal render mirrors or direct rendered HTML, while Playwright verifies hit-testing/focus/scroll behavior. [VERIFIED: accrue_admin/lib/accrue_admin/components/detail_drawer.ex; VERIFIED: Phoenix.Component installed docs; VERIFIED: accrue_admin/e2e/admin-spec-detail-phase195.spec.js]

**When to use:** any action form or sensitive confirmation moved off the initial page load. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]

**Example:**

```elixir
# Source: accrue_admin/lib/accrue_admin/live/subscription_live.ex
<DetailDrawer.detail_drawer
  id="subscription-action-drawer"
  open={drawer_open?(@drawer_action_type, @pending_action)}
  title={drawer_title(@drawer_action_type, @pending_action)}
  close_event="cancel_pending_action"
>
  ...
</DetailDrawer.detail_drawer>
```

### Pattern 4: Lazy Bottom Sections

**What:** Activity and Raw JSON render as bottom `<details>` sections with `data-ax-lazy-activity` / `data-ax-lazy-json`; data loads only after operator intent. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex; VERIFIED: accrue_admin/guides/spec-detail.md]

**When to use:** all target pages where activity or raw payload exists; coupon/promotion-code/event may only need Raw data. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]

**Example:**

```elixir
# Source: accrue_admin/lib/accrue_admin/live/subscription_live.ex
<details class="ax-detail-section" data-ax-lazy-activity phx-click="load_activity">
  <summary class="ax-detail-section-head">
    <span class="ax-detail-section-title">Activity</span>
  </summary>
  <%= if @timeline_events_loaded? do %>
    <Timeline.timeline label="Subscription events" items={timeline_items(@timeline_events)} />
  <% else %>
    <p class="ax-body">Open this section to load subscription activity.</p>
  <% end %>
</details>
```

### Pattern 5: Recovery Overview Is Recovery-Specific

**What:** Recovery should render orientation/window selector, hero metric pair, at-risk work queue, then supporting funnel; do not apply Dashboard's exact zone order to Recovery. [VERIFIED: accrue_admin/guides/spec-overview.md; VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]

**When to use:** `AccrueAdmin.Live.Analytics.RecoveryLive` and its Playwright marker assertions. [VERIFIED: accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex; VERIFIED: accrue_admin/e2e/admin-spec-overview-phase194.spec.js]

**Example:**

```elixir
# Source: accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
<section class="ax-kpi-grid ax-section-gap" data-ax-zone="kpi-cluster">
  ...
</section>

<section data-ax-zone="task-launcher">
  <AtRiskTable.at_risk_table rows={@at_risk} base_path={@admin_mount_path} />
</section>

<FunnelChart.funnel_chart
  entered={@funnel.entered}
  recovered={@funnel.recovered}
  exhausted={@funnel.exhausted}
  active={@funnel.active}
/>
```

### Anti-Patterns to Avoid

- **Generic detail-page DSL:** it would hide resource-specific status/action rules and contradict locked D-01. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]
- **KPI-first detail pages:** customer, invoice, charge, coupon, promotion-code, connect, and webhook currently show KPI grids or metric cards that must move into summary rows or drill-local facts. [VERIFIED: codebase rg]
- **Disabled-looking-enabled or disabled primary actions:** unavailable actions should be omitted; webhook replay currently renders a disabled button for non-replayable rows and should instead show precise state copy. [VERIFIED: accrue_admin/lib/accrue_admin/live/webhook_live.ex; VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]
- **Inline forms on initial load:** invoice, charge, and connect account currently render action forms in the page body; Phase 198 must move them into drawers or step-up flows. [VERIFIED: accrue_admin/lib/accrue_admin/live/invoice_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/connect_account_live.ex]
- **Broad Customer `More` tab bucket:** current `@more_tabs` includes payment methods, entitlements, events, and metadata; locked D-05/D-06 require removing that bucket. [VERIFIED: accrue_admin/lib/accrue_admin/live/customer_live.ex; VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detail page shell | Runtime `DetailPage` DSL/schema | Page-local helpers + existing `Detail` components | Locked D-01 rejects a leaky abstraction; page semantics differ by resource. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md] |
| Action overflow | New dropdown/menu component | `DropdownMenu.action_menu/1` | Existing component already carries `data-ax-action-overflow-menu`, menu grouping, hidden context, and LiveView event hooks. [VERIFIED: accrue_admin/lib/accrue_admin/components/dropdown_menu.ex] |
| Drawer/modal substrate | New overlay or native `<dialog>` pass | `DetailDrawer`, `StepUpAuthModal`, `Overlay.overlay/1` | Phase 199 owns global overlay audit; Phase 198 should reuse frozen primitives. [VERIFIED: accrue_admin/lib/accrue_admin/components/detail_drawer.ex; VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md] |
| Step-up workflow | Per-page authentication prompts | `StepUp.require_fresh/4` + `StepUp.verify/3` | Existing service delegates to `Accrue.Auth`, stores grace state, and records audit events. [VERIFIED: accrue_admin/lib/accrue_admin/step_up.ex] |
| Related-resource navigation | Per-page duplicate nav cards | `RelatedResources.related_resources/1` wrapped once in `[data-ax-related-resources]` | SPEC-DETAIL requires exactly one strip; subscription exemplar proves wrapper placement. [VERIFIED: accrue_admin/guides/spec-detail.md; VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex] |
| Activity/raw rendering | Eager timeline/JSON above the fold | Lazy `<details>` markers and existing `Timeline` / `JsonViewer` | Locked D-16 and subscription exemplar avoid expensive/noisy bottom content on first scan. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md; VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex] |
| Recovery charting | New chart/time-series component | Existing `AtRiskTable` + `FunnelChart` order | Locked D-18 keeps work queue first and funnel as support; no chart-wall redesign. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md; VERIFIED: accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex] |

**Key insight:** the hard part is not rendering a page shell; it is preserving resource-specific action validity, owner scope, step-up, audit linkage, and operator nouns while making the pages visually consistent. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md; VERIFIED: accrue_admin/lib/accrue_admin/live/invoice_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/webhook_live.ex]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | No schema or persisted-name migration is required; target pages read existing billing records, event rows, webhook rows, Oban jobs, and analytics data. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md; VERIFIED: codebase rg] | Code edits only; do not add data migrations for conformance. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md] |
| Live service config | No external UI/service configuration is part of Phase 198. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md] | None. [VERIFIED: phase scope] |
| OS-registered state | None found; this phase does not rename services, launchd/systemd units, or package names. [VERIFIED: phase scope; VERIFIED: codebase rg] | None. [VERIFIED: phase scope] |
| Secrets/env vars | No secret/env-var rename is required; step-up and owner-scope code use existing session/admin assigns. [VERIFIED: accrue_admin/lib/accrue_admin/auth_hook.ex; VERIFIED: accrue_admin/lib/accrue_admin/step_up.ex] | None unless implementation unexpectedly changes config keys; planner should avoid that. [VERIFIED: phase scope] |
| Build artifacts | If CSS or JS changes are made, committed `accrue_admin/priv/static/accrue_admin.css` / `.js` must be rebuilt; if copy modules change and generated fixtures depend on them, update generated copy strings. [VERIFIED: CLAUDE.md; VERIFIED: accrue_admin/package.json; VERIFIED: examples/accrue_host/e2e/generated/copy_strings.json present via codebase rg] | Add asset/copy regeneration tasks only if touched files require them. [VERIFIED: project conventions] |

**Nothing found in category:** no stored data, live service config, OS registration, or env/secrets migration remains after repo files are updated. [VERIFIED: phase scope]

## Common Pitfalls

### Pitfall 1: Applying Dashboard DOM Order to Recovery

**What goes wrong:** a test requires Dashboard's attention-rail -> task-launcher -> KPI-cluster order on Recovery and fails the locked Recovery-specific grammar. [VERIFIED: accrue_admin/guides/spec-overview.md; VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]

**Why it happens:** Recovery is an overview page but its locked order is hero metric pair -> at-risk work queue -> supporting funnel. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]

**How to avoid:** write Recovery-specific markers/assertions and do not reuse Dashboard order blindly. [VERIFIED: accrue_admin/e2e/admin-spec-overview-phase194.spec.js]

**Warning signs:** tests talk about `attention-rail` before the Recovery hero pair or place charts before `AtRiskTable`. [VERIFIED: codebase rg]

### Pitfall 2: Portal Contents Disappear from LiveViewTest Selectors

**What goes wrong:** ExUnit `has_element?/2` fails to see drawer/modal internals because LiveView portals render through `<template>` sources. [VERIFIED: Phoenix.Component installed docs]

**Why it happens:** `Phoenix.Component.portal/1` teleports content to a target and its docs warn to render the portal element itself for assertions. [VERIFIED: Phoenix.Component installed docs]

**How to avoid:** keep existing hidden test mirrors where necessary and use Playwright for actual overlay hit-test/focus/scroll behavior. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex; VERIFIED: accrue_admin/e2e/admin-spec-detail-phase195.spec.js]

**Warning signs:** a test only queries `#ax-overlay-root` through LiveViewTest and never renders the portal template or runs browser checks. [VERIFIED: Phoenix.Component installed docs]

### Pitfall 3: Moving Forms but Not Moving Validation State

**What goes wrong:** a form is hidden visually but still preloads data, stale validation state, or confirm panels on initial render. [VERIFIED: accrue_admin/lib/accrue_admin/live/invoice_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex]

**Why it happens:** invoice and charge currently combine action forms and confirm panels in the main page body. [VERIFIED: accrue_admin/lib/accrue_admin/live/invoice_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex]

**How to avoid:** model each action with page-owned drawer state: open/select, validate/prepare, confirm, cancel, then optional step-up. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex; VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]

**Warning signs:** `[data-ax-action-band] form:visible` is nonzero on first load, or `data-role="confirm-panel"` appears before operator intent. [VERIFIED: accrue_admin/guides/spec-detail.md; VERIFIED: accrue_admin/e2e/admin-spec-detail-phase195.spec.js]

### Pitfall 4: RelatedResources Without the Contract Wrapper

**What goes wrong:** pages render `RelatedResources.related_resources/1` but Playwright cannot assert exactly one strip because the canonical `[data-ax-related-resources]` wrapper is missing. [VERIFIED: accrue_admin/lib/accrue_admin/live/coupon_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex]

**Why it happens:** the component itself does not add the exact Phase 195 wrapper marker. [VERIFIED: accrue_admin/lib/accrue_admin/components/related_resources.ex]

**How to avoid:** either wrap each page's single strip or update the component contract if all tests are adjusted. Prefer page wrapper to minimize blast radius. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex]

**Warning signs:** a page has `<RelatedResources.related_resources ... />` but no `data-ax-related-resources`. [VERIFIED: codebase rg]

### Pitfall 5: Customer Tabs Continue to Hide Primary State

**What goes wrong:** payment methods, entitlements, events, and metadata stay under the broad `More` tab and hide state/action content from the first scan. [VERIFIED: accrue_admin/lib/accrue_admin/live/customer_live.ex]

**Why it happens:** current Customer code defines `@tabs`, `@primary_tabs`, and `@more_tabs`, then renders tab content by `case @tab`. [VERIFIED: accrue_admin/lib/accrue_admin/live/customer_live.ex]

**How to avoid:** keep only Subscriptions/Invoices/Payments as peer record-set subviews, move other content into summary/drill/lazy sections, and preserve `?tab=payments` compatibility by normalizing to internal `charges`. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md; VERIFIED: accrue_admin/lib/accrue_admin/live/customer_live.ex]

**Warning signs:** a visible `More` trigger, a tab named `Metadata`, or critical actions only reachable after selecting a tab. [VERIFIED: accrue_admin/lib/accrue_admin/live/customer_live.ex]

## Code Examples

Verified patterns from official/local sources:

### Summary Row With Row-Level Action

```elixir
# Source: accrue_admin/lib/accrue_admin/components/detail.ex
%{
  label: "Customer",
  value: customer_label(customer),
  action_label: "View",
  action_context: "customer for subscription #{subscription_label}",
  action_href: ScopedPath.build(mount_path, "/customers/#{customer.id}", scope)
}
```

### Lazy Timeline Loader

```elixir
# Source: accrue_admin/lib/accrue_admin/live/subscription_live.ex
def handle_event("load_activity", _params, socket) do
  {:noreply, ensure_timeline_events(socket)}
end

defp ensure_timeline_events(%{assigns: %{timeline_events_loaded?: true}} = socket), do: socket

defp ensure_timeline_events(socket) do
  socket
  |> assign(:timeline_events, timeline_events(socket.assigns.subscription.id))
  |> assign(:timeline_events_loaded?, true)
end
```

### Step-Up Around Sensitive Action

```elixir
# Source: accrue_admin/lib/accrue_admin/live/charge_live.ex
case StepUp.require_fresh(socket, step_up_action(action), &execute_refund(&1, action)) do
  {:ok, socket} -> {:noreply, socket}
  {:challenge, socket} -> {:noreply, socket}
  {:error, _reason, socket} -> {:noreply, push_flash(socket, :error, charge_refund_error_copy(socket))}
end
```

### Owner-Scope Preserving Related Link

```elixir
# Source: accrue_admin/lib/accrue_admin/scoped_path.ex
def build(mount_path, suffix, %{mode: :organization, organization_slug: slug}, params)
    when is_binary(slug) do
  mount_path <> suffix <> "?" <> URI.encode_query(Map.put(params, "org", slug))
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Detail pages lead with KPI grids and many always-visible zones. | Summary card + GOV.UK-style summary list + compact drills + lazy bottom sections. | Locked in Phase 193; exemplar completed in Phase 195. [VERIFIED: accrue_admin/guides/spec-detail.md; VERIFIED: .planning/phases/195-exemplar-b-subscription-detail/195-PATTERNS.md] | Planner should move KPI facts into summary rows or drill-local facts. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md] |
| Action forms render on initial page load. | <=2 primary actions + one overflow menu; forms open only in drawer/modal after intent. | Locked in Phase 193/195. [VERIFIED: accrue_admin/guides/spec-detail.md; VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex] | Planner must move invoice/charge/connect/webhook forms/confirmations off first load. [VERIFIED: codebase rg] |
| Tabs bucket heterogeneous Customer content. | Tabs only for peer record-set collections: Subscriptions, Invoices, Payments. | Locked in Phase 198 context. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md] | Planner must remove Customer `More` bucket while preserving compatible query params. [VERIFIED: accrue_admin/lib/accrue_admin/live/customer_live.ex] |
| Recovery reads like a dashboard/chart surface. | Recovery-specific overview: hero pair, at-risk queue, supporting funnel. | Locked in Phase 194 and reiterated in Phase 198. [VERIFIED: accrue_admin/guides/spec-overview.md; VERIFIED: .planning/phases/194-exemplar-a-dashboard/194-CONTEXT.md] | Planner must adjust assertions and stale docs rather than rebuild analytics. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md] |

**Deprecated/outdated:**
- Top-level KPI grids on detail pages: replaced by summary-list rows plus drill-local facts. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]
- Broad Customer `More` tab: replaced by peer record-set tabs plus visible drills/lazy sections. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]
- Inline action forms as page content: replaced by action menu + drawer/modal flow. [VERIFIED: accrue_admin/guides/spec-detail.md; VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Phase 198 will not install or upgrade dependencies. [ASSUMED] | Standard Stack / Package Legitimacy Audit | If implementation chooses to add packages, the planner must run package-legitimacy checks and update this research. |

## Open Questions

1. **Should webhook replay and connect platform-fee override step-up be mandatory or documented as lower-risk?**
   - What we know: locked D-12 says add step-up for both unless planning records a specific lower-risk reason. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md]
   - What's unclear: no lower-risk reason was found in current code or context. [VERIFIED: codebase rg]
   - Recommendation: plan them as step-up gated. [VERIFIED: accrue_admin/lib/accrue_admin/step_up.ex]

2. **Where should the Phase 198 Playwright contract live?**
   - What we know: Phase 194/195/197 have separate npm scripts and specs. [VERIFIED: accrue_admin/package.json]
   - What's unclear: planner can extend `admin-spec-detail-phase195.spec.js` or add `admin-spec-detail-phase198.spec.js`. [VERIFIED: current file layout]
   - Recommendation: add a Phase 198 spec and npm script to avoid mutating exemplar-only intent. [VERIFIED: existing script pattern]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix compile/test | yes | 1.19.5 | None needed. [VERIFIED: `elixir --version`] |
| Mix | ExUnit and package tasks | yes | 1.19.5 | None needed. [VERIFIED: `mix --version`] |
| PostgreSQL | `AccrueAdmin.TestRepo` SQL sandbox | yes | 14.17; port 5432 accepting connections | None needed. [VERIFIED: `psql --version`; VERIFIED: `pg_isready`] |
| Node.js | Playwright/npm scripts | yes | 22.14.0 | None needed. [VERIFIED: `node --version`] |
| npm | e2e scripts and registry metadata | yes | 11.1.0 | None needed. [VERIFIED: `npm --version`] |
| Playwright local binary | Browser smoke/contract tests | yes | 1.59.1 | Use npm script local binary. [VERIFIED: `./node_modules/.bin/playwright --version`] |
| `ctx7` CLI | Preferred Context7 fallback | no | — | Used official docs + installed dependency source instead. [VERIFIED: `command -v ctx7`] |
| ripgrep | Codebase research | yes | 15.1.0 | None needed. [VERIFIED: `rg --version`] |

**Missing dependencies with no fallback:** none. [VERIFIED: environment probes]

**Missing dependencies with fallback:** `ctx7` is missing; official HexDocs URLs and installed `deps/phoenix_live_view` source were used for Phoenix docs. [VERIFIED: `command -v ctx7`; VERIFIED: accrue_admin/deps/phoenix_live_view/lib/phoenix_component.ex]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit through Mix plus Playwright `@playwright/test`; local Playwright binary is 1.59.1. [VERIFIED: accrue_admin/test/test_helper.exs; VERIFIED: accrue_admin/package.json] |
| Config file | `accrue_admin/test/test_helper.exs`, `accrue_admin/config/test.exs`, and Playwright package scripts in `accrue_admin/package.json`. [VERIFIED: codebase rg] |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/connect_account_live_test.exs -x` [VERIFIED: target test files exist] |
| Full suite command | `cd accrue_admin && mix test && npm run e2e:phase198` after the Phase 198 e2e script exists. [VERIFIED: existing mix/Playwright pattern; Wave 0 gap for script] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PRP-02 | All detail pages render one `<h1>`, a summary list, <=2 primary actions, no visible action forms on load, one related strip, and lazy Activity/Raw JSON where applicable. | ExUnit + Playwright | `cd accrue_admin && mix test test/accrue_admin/live/*_live_test.exs -x`; `cd accrue_admin && npm run e2e:phase198` | Existing LiveView test files yes; Phase 198 Playwright file/script no. [VERIFIED: `rg --files accrue_admin/test accrue_admin/e2e`] |
| PRP-02 | Customer tabs only expose Subscriptions, Invoices, Payments and do not hide payment methods, entitlements, events, or metadata. | ExUnit + Playwright smoke | `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs -x` | Existing file yes; new assertions needed. [VERIFIED: accrue_admin/test/accrue_admin/live/customer_live_test.exs; VERIFIED: accrue_admin/lib/accrue_admin/live/customer_live.ex] |
| PRP-02 | Invoice/charge/webhook/connect sensitive actions open drawers/step-up after intent. | ExUnit + Playwright interaction | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/connect_account_live_test.exs -x` | Existing files yes; new drawer/step-up assertions needed. [VERIFIED: target test files exist] |
| PRP-02 | Recovery renders orientation/window selector, hero metric pair, at-risk work queue, supporting funnel; Campaign renders as detail drill-down. | ExUnit + Playwright | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs test/accrue_admin/live/analytics/campaign_live_test.exs -x`; `cd accrue_admin && npm run e2e:phase194` | Existing files yes; Phase 198 marker updates needed. [VERIFIED: target test files exist; VERIFIED: accrue_admin/e2e/admin-spec-overview-phase194.spec.js] |

### Sampling Rate

- **Per task commit:** targeted `mix test` for touched LiveView/component files plus any changed copy/component tests. [VERIFIED: existing test layout]
- **Per wave merge:** `cd accrue_admin && mix test` plus the relevant Phase 198 Playwright smoke. [VERIFIED: package test pattern]
- **Phase gate:** `cd accrue_admin && mix test && npm run e2e:phase198 && npm run e2e:phase194 && npm run e2e:phase195` before `$gsd-verify-work`. [VERIFIED: accrue_admin/package.json; Wave 0 gap for `e2e:phase198`]

### Wave 0 Gaps

- [ ] `accrue_admin/e2e/admin-spec-detail-phase198.spec.js` - all target detail/analytics smoke and representative drawer/step-up checks. [VERIFIED: existing e2e pattern; file absent via `rg --files`]
- [ ] `accrue_admin/package.json` script `e2e:phase198` - mirrors `e2e:phase195`/`e2e:phase197` script shape. [VERIFIED: accrue_admin/package.json]
- [ ] Extend target LiveView tests for summary rows, action counts, related-strip marker, lazy sections, and Customer tab policy. [VERIFIED: target test files exist]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Existing `StepUp.require_fresh/4` and `StepUp.verify/3` for sensitive admin actions. [VERIFIED: accrue_admin/lib/accrue_admin/step_up.ex] |
| V3 Session Management | yes | `AuthHook.on_mount(:ensure_admin)` resolves owner scope/session and assigns `current_admin`, `current_owner_scope`, and step-up state. [VERIFIED: accrue_admin/lib/accrue_admin/auth_hook.ex] |
| V4 Access Control | yes | Scoped queries/detail loads and `ScopedPath.build/4` preserve owner scope; webhook detail proves row scope before replay. [VERIFIED: accrue_admin/lib/accrue_admin/scoped_path.ex; VERIFIED: accrue_admin/lib/accrue_admin/queries/webhooks.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/webhook_live.ex] |
| V5 Input Validation | yes | Page-owned parsing/validation exists for refund amount and connect override forms; new drawer moves must preserve server-side validation. [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/connect_account_live.ex] |
| V6 Cryptography | limited | No new cryptography should be introduced; use existing auth/session/step-up mechanisms and do not hand-roll tokens or signatures. [VERIFIED: phase scope; VERIFIED: accrue_admin/lib/accrue_admin/step_up.ex] |

### Known Threat Patterns for Phoenix LiveView Admin Actions

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-organization object access through detail links or replay IDs | Elevation of privilege | Use `current_owner_scope`, scoped detail functions, and `ScopedPath.build/4`; never trust URL IDs alone. [VERIFIED: accrue_admin/lib/accrue_admin/auth_hook.ex; VERIFIED: accrue_admin/lib/accrue_admin/queries/webhooks.ex] |
| Forged LiveView event for hidden/unavailable action | Tampering | Keep server-side action allowlists and status gates in `execute_action/2`, `run_invoice_action/3`, `build_refund_action/3`, and replay checks. [VERIFIED: accrue_admin/lib/accrue_admin/live/invoice_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/webhook_live.ex] |
| Sensitive action without fresh operator proof | Elevation of privilege | Wrap void/mark-uncollectible/refund/webhook replay/connect override in `StepUp.require_fresh/4` unless a lower-risk reason is explicitly recorded. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md; VERIFIED: accrue_admin/lib/accrue_admin/step_up.ex] |
| Missing audit trail for money-moving or replay actions | Repudiation | Preserve `Events.record/1` and `Auth.log_audit/2` calls around action completion. [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/invoice_live.ex; VERIFIED: accrue_admin/lib/accrue_admin/live/webhook_live.ex] |
| Raw payload exposure above the fold | Information disclosure | Keep raw JSON lazy and bottom-positioned; do not surface raw payloads as first-scan state. [VERIFIED: accrue_admin/guides/spec-detail.md; VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/198-propagate-detail-analytics/198-CONTEXT.md` - locked Phase 198 decisions, target pages, constraints, deferred scope. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - PRP-02 mapping, v1.54 scope, security/verification boundaries. [VERIFIED: local file]
- `.planning/STATE.md` - current milestone state and phase sequencing context. [VERIFIED: local file]
- `CLAUDE.md` - project constraints, stack posture, admin UI scope, GSD workflow constraints. [VERIFIED: local file]
- `accrue_admin/guides/spec-detail.md` and `accrue_admin/guides/spec-overview.md` - locked page contracts. [VERIFIED: local file]
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` - Phase 195 DETAIL exemplar. [VERIFIED: codebase rg]
- `accrue_admin/lib/accrue_admin/components/*.ex` - existing component primitives. [VERIFIED: codebase rg]

### Secondary (MEDIUM confidence)

- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html` - Phoenix function component, slot, and portal behavior; local installed source was also checked in `deps/phoenix_live_view`. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html; VERIFIED: accrue_admin/deps/phoenix_live_view/lib/phoenix_component.ex]
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` - LiveView lifecycle, `mount/3`, `handle_params/3`, `handle_event/3`. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html; VERIFIED: accrue_admin/deps/phoenix_live_view/lib/phoenix_live_view.ex]
- `https://design-system.service.gov.uk/components/summary-list/` - summary-list row/action semantics. [CITED: https://design-system.service.gov.uk/components/summary-list/]
- `https://design-system.service.gov.uk/components/tabs/` - tab content switching and hidden content implications. [CITED: https://design-system.service.gov.uk/components/tabs/]
- `https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/` and `https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/` - dialog/menu accessibility expectations. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/; CITED: https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/]
- `https://docs.stripe.com/refunds` and Stripe invoice API docs - refunds and invoice lifecycle actions are explicit API operations. [CITED: https://docs.stripe.com/refunds; CITED: https://docs.stripe.com/api/invoices/finalize; CITED: https://docs.stripe.com/api/invoices/pay]

### Tertiary (LOW confidence)

- None used for decisions. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified from local `mix.exs`, lockfiles, local binaries, Hex registry metadata, and npm registry metadata; no new dependencies recommended. [VERIFIED: local files; VERIFIED: registry commands]
- Architecture: HIGH - locked context plus codebase examples converge on per-page LiveView state and stateless components. [VERIFIED: .planning/phases/198-propagate-detail-analytics/198-CONTEXT.md; VERIFIED: codebase rg]
- Pitfalls: HIGH - each pitfall maps to current target code or locked spec invariants. [VERIFIED: codebase rg; VERIFIED: spec docs]

**Research date:** 2026-06-28
**Valid until:** 2026-07-28 for local architecture decisions; external package currency should be rechecked if planning installs or upgrades packages. [VERIFIED: current date; ASSUMED]
