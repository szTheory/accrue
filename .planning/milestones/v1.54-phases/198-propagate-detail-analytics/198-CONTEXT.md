# Phase 198: Propagate DETAIL + analytics - Context

**Gathered:** 2026-06-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 198 propagates the locked v1.54 DETAIL and overview patterns across the
remaining `accrue_admin` detail and analytics pages:

- Detail pages: customer, invoice, charge/payment, coupon, promotion-code,
  connect-account, webhook, and event.
- Analytics pages: Recovery and Campaign.

The deliverable is conformance, not new product surface. Detail pages must follow
SPEC-DETAIL: summary-then-drill, a GOV.UK-style summary-list header, at most two
visible primary actions plus one overflow menu when more actions exist, action
forms hosted in side drawers, exactly one related-resources strip, and lazy
activity/raw JSON at the bottom. Recovery must follow the locked overview
direction for this analytics surface: hero metric pair, at-risk work queue, and
supporting funnel. Campaign is a drill-down detail page opened from Recovery, not
a second dashboard.

Fixed guardrails: scope is `accrue_admin` operator UI only; no `accrue_portal`
work; no new billing primitives, domain features, routes, or breaking public
APIs; no Tailwind migration; custom `ax-*` CSS and the committed admin bundle
remain the styling SSOT; copy goes through `AccrueAdmin.Copy` / copy modules;
cross-page overlay correctness, transformed-ancestor audit, fixture stress, full
microcopy sweep, Storybook completeness, axe/no-FOUC, and final zero-regression
sign-off remain Phase 199/200 ownership.

</domain>

<decisions>
## Implementation Decisions

All four gray areas were researched with advisor subagents using the local specs,
prior phase context, target LiveViews, brandbook, prompt corpus, Elixir/Phoenix
idiom, and lessons from successful admin/payment dashboards. The recommendations
converged on one coherent package: per-page tuned propagation using existing
Phoenix function components and LiveView state, not a generic DSL.

### Cohesive Recommendation

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

### Customer-360 Tab Policy

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

### Action Surfaces and Drawers

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

### Summary Rows and Drill Grouping

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

### Recovery and Campaign Analytics Grammar

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

### Verification and Planning Shape

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

### Claude's Discretion

- Exact summary row labels, row order, and short body copy, bounded by brandbook
  voice: measured, exact, native, durable.
- Exact names of pure helper functions and where page-local helpers live.
- Whether a small reusable link-subview component is extracted for Customer
  peer tabs, provided it does not become a general page DSL.
- Exact `data-ax-*` marker placement under the locked selectors.
- Which target pages get the deepest browser matrix, provided the set includes
  Customer, Invoice, Charge, Webhook, Connect Account, Recovery, and Campaign.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked Pattern Contracts

- `accrue_admin/guides/spec-detail.md` - authoritative DETAIL contract:
  summary-then-drill, summary list, action constraints, no pre-expanded action
  forms, one related strip, overlay hit-test/body-scroll invariants, tabs only
  for peer record-sets.
- `accrue_admin/guides/spec-overview.md` - authoritative OVERVIEW contract,
  including the Recovery-specific rule: hero metric pair, at-risk work queue,
  supporting visualization; no chart wall.
- `accrue_admin/guides/spec-list.md` - relevant for Customer peer-record tabs
  and the list pages those tabs link to; table-first resource collections stay
  resource-owned.

### Prior Phase Decisions

- `.planning/phases/193-research-re-baseline-pattern-lock/193-CONTEXT.md` -
  archetype contracts, overlay direction, Storybook posture, source-guard
  strategy, and forward-only page-flow baseline.
- `.planning/phases/194-exemplar-a-dashboard/194-CONTEXT.md` - overview
  decisions, Recovery re-grammar, additive `data-ax-*` marker posture, and
  "refine, not rebuild" rule for analytics.
- `.planning/phases/195-exemplar-b-subscription-detail/195-CONTEXT.md` -
  DETAIL exemplar decisions: action prioritization, summary-list rows,
  action-menu/drawer/overlay primitives, lazy Activity/Raw JSON, related strip.
- `.planning/phases/195-exemplar-b-subscription-detail/195-PATTERNS.md` -
  implementation analogs for subscription detail, overlay, drawer, action menu,
  lazy loading, Storybook, copy regeneration, and page-flow tests.
- `.planning/phases/196-exemplar-c-subscriptions-list-pageheader/196-CONTEXT.md`
  - PageHeader/list propagation context and the strict "tabs only for peer
  record-sets" boundary carried into Customer-360.
- `.planning/phases/197-propagate-list/197-CONTEXT.md` - current list page
  propagation decisions, route names, filters, and related list destinations
  the detail pages should link to.

### Project and Milestone Scope

- `.planning/ROADMAP.md` - Phase 198 goal, target pages, success criteria, and
  phase boundaries.
- `.planning/REQUIREMENTS.md` - PRP-02 mapping and v1.54 exclusions.
- `.planning/STATE.md` - current milestone state and prior execution notes.
- `.planning/PROJECT.md` - stable-core posture, admin UI scope, and v1.54
  strategic reopen decision.

### Brand, Voice, and Strategy Inputs

- `brandbook/voice.md` - current voice SSOT: measured, exact, native, durable;
  mechanism-led copy; avoid backend/fintech/posturing language.
- `brandbook/copy.md` - approved microcopy posture and examples; adapt current
  page copy to exact operator jobs.
- `brandbook/tokens/README.md` - brand token documentation; admin `--ax-*`
  tokens remain implementation SSOT.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - adopter-first product lens:
  realistic operator value, least surprise, proof over polish churn.
- `prompts/accrue-brand-book.md` - older brand seed; use only where it
  reinforces `brandbook/`, and prefer `brandbook/` on conflict.

### Existing Components and Helpers

- `accrue_admin/lib/accrue_admin/components/detail.ex` - `summary_card`,
  `summary_list`, `detail_section`, and `detail_field_list`.
- `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` -
  `action_menu/1` for detail actions; do not use it as a content bucket.
- `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` - drawer wrapper
  around the canonical overlay.
- `accrue_admin/lib/accrue_admin/components/overlay.ex` - portal-backed modal,
  drawer, popover substrate with `data-ax-overlay-*` markers.
- `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` - modal
  step-up handoff, now overlay-backed.
- `accrue_admin/lib/accrue_admin/components/related_resources.ex` - canonical
  related-resource strip; add/preserve `data-ax-related-resources` wrapper.
- `accrue_admin/lib/accrue_admin/components/timeline.ex` - Activity timeline
  primitive for lazy bottom sections.
- `accrue_admin/lib/accrue_admin/components/json_viewer.ex` - Raw data viewer
  for lazy bottom sections.
- `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` - Recovery work
  queue; update stale docs if touched.
- `accrue_admin/lib/accrue_admin/components/funnel_chart.ex` - Recovery
  supporting visualization; keep, do not replace.
- `accrue_admin/lib/accrue_admin/components/campaign_timeline.ex` - Campaign
  detail drill content.
- `accrue_admin/lib/accrue_admin/scoped_path.ex` and
  `accrue_admin/lib/accrue_admin/data_table_nav.ex` - preserve owner scope and
  query params when linking between detail pages and filtered lists.
- `accrue_admin/lib/accrue_admin/copy.ex` and
  `accrue_admin/lib/accrue_admin/copy/*.ex` - home for touched page copy.

### Target Pages

- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` - SPEC-DETAIL
  exemplar to copy structurally, not a Phase 198 target except regression
  protection.
- `accrue_admin/lib/accrue_admin/live/customer_live.ex` - Customer-360 detail;
  only peer record-set tabs survive.
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex` - high-risk action page:
  invoice lifecycle, PDF/documents, line items, tax risk.
- `accrue_admin/lib/accrue_admin/live/charge_live.ex` - payment/charge detail;
  refund action moves into drawer.
- `accrue_admin/lib/accrue_admin/live/coupon_live.ex` - compact reference
  detail; remove KPI-first shape.
- `accrue_admin/lib/accrue_admin/live/promotion_code_live.ex` - compact
  reference detail; remove KPI-first shape.
- `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` - connected
  account detail; platform fee override moves into drawer + step-up.
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` - webhook inspector;
  replay action and lifecycle/derived event drills.
- `accrue_admin/lib/accrue_admin/live/event_live.ex` - ledger event detail;
  minimal detail with lazy raw data if present.
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` - Recovery
  overview: hero pair, at-risk queue, supporting funnel.
- `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` - Campaign
  detail drill-down opened from Recovery rows.

### Verification Seams

- `accrue_admin/e2e/admin-spec-detail-phase195.spec.js` - subscription detail
  SPEC-DETAIL Playwright contract to extend/mirror.
- `accrue_admin/e2e/admin-spec-overview-phase194.spec.js` - overview and
  Recovery Playwright contract to extend without blindly applying Dashboard
  order to Recovery.
- `accrue_admin/e2e/phase191-page-flow-helpers.js` - shared assertions for
  clipping, scroll, focus, and overlay hit-testing.
- `accrue_admin/test/accrue_admin/live/*_live_test.exs` - page-level LiveView
  tests for target detail pages.
- `accrue_admin/test/accrue_admin/live/analytics/*_live_test.exs` - Recovery
  and Campaign analytics tests; keep admin boundary assertions green.
- `accrue_admin/test/accrue_admin/components/*_test.exs` - component contract
  tests for Detail, Overlay, DetailDrawer, DropdownMenu, RelatedResources,
  Timeline, JsonViewer, AtRiskTable, and FunnelChart.

### External References Considered

- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html` - Phoenix
  function component attrs/slots and portal component; supports stateless shared
  markup plus server-owned LiveView state.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` - LiveView
  mount/params/event lifecycle; supports page-owned URL and action state.
- `https://design-system.service.gov.uk/components/summary-list/` - summary
  list and row-level action semantics.
- `https://design-system.service.gov.uk/components/tabs/` - tabs are for
  related sections only and hide content; reinforces Customer peer-set limit.
- `https://docs.stripe.com/refunds` and `https://docs.stripe.com/invoicing` -
  payment/refund and invoice lifecycle actions are status-specific and staged,
  not always-visible forms.
- `https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/` and
  `https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/` - modal/dialog and
  menu-button accessibility expectations.
- `https://polaris.shopify.com/components/tables/index-table` - resource tables
  keep filtering/action state caller-owned; supports explicit composition over
  a page DSL.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **Subscription detail exemplar** already proves the target shape:
  `summary_list`, action band, `DropdownMenu.action_menu`, `DetailDrawer`,
  `StepUpAuthModal`, one related strip wrapper, lazy Activity, and lazy Raw JSON.
- **Overlay primitive is already built.** `Overlay.overlay/1` portals to
  `#ax-overlay-root`, marks panel/backdrop/shell, and backs `DetailDrawer` and
  `StepUpAuthModal`.
- **Action menu is distinct from modal/drawer.** Use `DropdownMenu.action_menu/1`
  for lightweight non-modal action selection; the actual form or confirmation
  opens in drawer/modal.
- **RelatedResources exists but lacks the exact invariant on its own.** Wrap or
  update it so each page exposes exactly one `[data-ax-related-resources]`.
- **AtRiskTable already behaves like a work queue.** It has table/card states
  and row links; the main work is marker/test/doc conformance, not rebuilding.

### Established Patterns

- **Phoenix attrs/slots for shared markup; LiveViews own state.** This supports
  helper extraction without a broad runtime DSL.
- **Source-lint where mechanical, rendered-detect where compositional.**
  Action counts, form absence, related-strip count, lazy section markers, and
  overlay hit-testing are machine assertions. Whether the page feels like a
  concise operator detail remains rubric/judge work.
- **Copy and committed assets need lockstep.** Touched copy should live in copy
  modules, and generated copy fixtures/assets should be regenerated where tests
  depend on them.
- **Custom `ax-*` CSS + committed bundle is SSOT.** Any CSS edits require the
  package asset build and committed static bundle.

### Integration Points

- Target pages import/alias `Detail`, `DropdownMenu`, `DetailDrawer`,
  `RelatedResources`, `Timeline`, `JsonViewer`, and `StepUpAuthModal` as needed.
- Each page adds summary row builders and action builders near existing
  presenter helpers.
- Invoice, charge, webhook, connect account, and customer payment-method flows
  route selected actions into drawer state and confirm through existing
  server-side execution paths.
- Customer peer tabs retain URL state but stop hiding non-peer content behind
  `More`.
- Recovery page-flow tests need a Recovery-specific zone grammar so the hero
  metric pair can precede the at-risk queue while still avoiding chart-wall
  behavior.

</code_context>

<specifics>
## Specific Ideas

- User selected all gray areas and asked for advisor-style research with
  subagents, including Elixir/Phoenix idiom, lessons from successful admin and
  billing dashboards, DX, JTBD, UI/UX, accessibility, performance, brand voice,
  and software architecture lenses.
- Four advisor subagents researched:
  - Customer-360 tab policy.
  - Action surfaces and drawers.
  - Summary rows and drill grouping.
  - Recovery and Campaign analytics grammar.
- All four reports converged on the same architecture: per-page tuned
  conformance, existing component primitives, no generic page DSL, forms only
  after intent, Customer tabs only for peer record-sets, and Recovery/Campaign
  split by actual job rather than route label.
- Design pillars considered and applied:
  - Accessibility: one `<h1>`, summary-list semantics, truthful menu/dialog
    roles, visible focus, no hidden critical actions in tabs, no disabled
    controls that look usable.
  - Performance: lazy Activity/Raw JSON, no render-helper DB work where
    assign-time loading is practical, no exact count/query expansion unless
    needed.
  - Maintainability/DX: page-owned LiveView state, pure helper functions,
    attrs/slots, no leaky DSL, reusable tests/markers.
  - Resilience: owner-scope-preserving links, server-side action allowlists,
    step-up for sensitive operations.
  - Brand/voice: measured, exact, native, durable; copy names the operator job
    and hides backend implementation details unless operationally necessary.
  - Visual/UI consistency: summary-then-drill, constrained action bands, one
    related strip, dark/light/system-safe tokens, no hover/focus weirdness.
  - Product/JTBD: Support, Billing Ops, Compliance, and Developer/Integration
    jobs get distinct surfaces instead of one mixed info dump.

</specifics>

<deferred>
## Deferred Ideas

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

### Reviewed Todos (not folded)

- **Shared page_header component for accrue_admin list pages**
  (`.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md`)
  - reviewed as a matcher but already folded into and resolved by Phases 196/197.
  Phase 198 uses DETAIL primitives, not a new PageHeader scope.
- **White-label billing portal design system**
  (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`)
  - reviewed and deferred because Phase 198 is `accrue_admin` operator UI only.

</deferred>

---

*Phase: 198-propagate-detail-analytics*
*Context gathered: 2026-06-28*
