# Phase 199: Cross-cutting interaction/overlay correctness + fixture stress + microcopy - Context

**Gathered:** 2026-06-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 199 is the cross-cutting correctness pass after the v1.54 list/detail/overview
page patterns have been propagated across `accrue_admin`.

The deliverables are:

- Sweep every modal, drawer, popover, dropdown, command-palette, theme-picker, and
  step-up surface so the canonical overlay/floating behavior is structurally
  correct across all admin pages.
- Prove focus, scroll, dismissal, hit-testing, geometry, reduced-motion, viewport
  bounds, theme persistence, and non-interactive/disabled affordances under real
  rendered routes.
- Add deterministic fixture stress for real operator flows and edge data:
  list -> detail -> nested detail / drill-down -> back, long content, zero-decimal
  currency, past-due dunning, failed/dead webhooks, connect readiness, and overflow.
- Run the page-level brand-voice microcopy sweep through the existing
  `AccrueAdmin.Copy` modules.

Fixed guardrails: scope is the `accrue_admin` operator UI only; no
`accrue_portal` work; no new billing primitives, routes, or breaking public APIs;
no Tailwind migration; custom `ax-*` CSS and the committed admin bundle remain
the styling SSOT; final Storybook completeness, axe/no-FOUC package-wide sweep,
zero-regression re-score, and maintainer sign-off remain Phase 200 ownership.

</domain>

<decisions>
## Implementation Decisions

### Overlay Substrate, Focus, and Scroll

- **D-01 - Treat the current `Overlay.overlay/1` stack as the canonical substrate.**
  Phase 199 should extend and sweep the portal-backed `Overlay.overlay/1`,
  `DetailDrawer.detail_drawer/1`, `StepUpAuthModal.step_up_auth_modal/1`,
  `assets/js/hooks/overlay.js`, `FocusTrap`, and `ScrollLock`. Do not rewrite the
  overlay system around native `<dialog>` unless the transformed-ancestor audit
  finds an unfixable root-portal failure.
- **D-02 - Every modal and drawer must route through `Overlay` or a named wrapper.**
  Planners should inventory all modal/drawer-like surfaces and reject hand-rolled
  fixed-position shells. Existing hidden test mirrors may stay only if they remain
  hidden and do not create a second interactive overlay path.
- **D-03 - Keep `ScrollLock` standalone and ref-counted.** The existing helper
  already applies fixed-position scroll preservation, scrollbar compensation via
  `--ax-scrollbar-comp`, and `#accrue-admin-shell` `inert`. Phase 199 should prove
  nested overlay flows and rapid open/close/double-toggle restore only after the
  final unlock, with no ghost inert state or scroll-position loss.
- **D-04 - Backdrop click and Escape use one dismissal contract.** For each overlay,
  backdrop click and Escape must dispatch the same close event/target path and
  settle idempotently. Tests should cover rapid double-toggle and close-while-
  transition cases so no scrim, inert shell, or locked body survives after close.
- **D-05 - Background isolation is required, with FocusTrap as the backstop.**
  While an overlay is open, the admin shell is `inert` and not tabbable/clickable.
  If browser support gaps appear, add the narrowest fallback needed; do not build
  a parallel accessibility layer before a failing test proves the gap.
- **D-06 - Run a transformed/filtered/`contain` ancestor audit.** Because overlays
  portal to `#ax-overlay-root`, the audit should verify the root stays body-level
  and no page wrapper or CSS transform/filter/contain rule can re-root a fixed
  shell. A z-index bump is not an acceptable fix for a trapped stacking context.

### Geometry, Motion, Theme, and Affordances

- **D-07 - Correct drawer geometry by breakpoint.** Desktop drawers are right-edge
  docked panels entering with `translateX`; mobile drawers are bottom sheets
  entering with `translateY`. Keep the existing <=240ms duration band and preserve
  reduced-motion no-travel behavior.
- **D-08 - Popovers and floating panels must be origin-aware and viewport-bound.**
  Dropdown action menus, command palette, theme picker, tooltips, and any popover
  should appear adjacent to their trigger, use a trigger-appropriate
  `transform-origin`, and stay within viewport bounds near edges. Prefer the
  existing local dropdown/palette hooks; add a shared anchored helper only if it
  removes real drift. Do not add a positioning dependency unless local code cannot
  satisfy the near-edge tests.
- **D-09 - Extend reduced-motion tests to the new overlay/floating surfaces.**
  `reduced-motion.spec.js` already proves button, dropdown, command palette, and
  drawer tokens. Phase 199 should extend it to the final drawer/mobile-sheet and
  popover classes, and confirm focus rings appear instantly rather than animating.
- **D-10 - Theme persistence tests must use the production key.** The production
  theme path uses the `accrue_theme` cookie/localStorage key and the root-layout
  anti-FOUC script before CSS loads. Phase 199 should add browser coverage for
  cookie > localStorage > system/default resolution, persistence through reload,
  and system dark/light emulation. Existing helpers that directly set
  `data-theme` are useful for visual matrix checks but are not sufficient for
  no-FOUC/persistence.
- **D-11 - Remove false affordances instead of styling around them.** Non-
  interactive empty/healthy heroes must not carry hover, pointer cursor, button
  roles, or click handlers. If an action/pagination/filter is unavailable, hide it
  rather than rendering a disabled-looking-enabled control. Real disabled controls
  must be visually distinct while retaining readable labels.

### Fixture Stress and Page-Flow Coverage

- **D-12 - Use deterministic seeded flows, not synthetic-only component states.**
  Phase 199 should extend the existing seed endpoints and Playwright helpers so
  real routes exercise the states. Component kitchen/Storybook specimens can
  supplement, but the acceptance path is composed admin pages.
- **D-13 - Cover representative multi-step operator paths.** Recommended minimum
  paths: Customers list -> Customer detail -> peer record-set -> related detail
  -> back; Invoices list -> Invoice detail -> drawer/step-up action -> back;
  Webhooks list -> Webhook detail -> Event/detail drill -> replay drawer/step-up;
  Recovery -> Campaign -> Subscription detail; Connect list -> Connect account
  detail -> platform-fee drawer/step-up.
- **D-14 - Edge fixtures must target layout failure modes directly.** Include very
  long customer/business names, long emails and processor IDs, zero-decimal JPY
  invoice/charge values, past-due/dunning states, failed/dead webhooks, connect
  accounts needing attention, empty/filtered-empty/loading states, and overflow
  payloads. Assertions should check no horizontal clipping, reachable scroll
  sentinels, preserved focus, and no body focus after transitions.
- **D-15 - Keep the Phase 200 gate boundary intact.** Phase 199 should add
  focused cross-cutting specs and any required fixture data. It should not try to
  run or own the final all-cell forward-only scorecard, complete Storybook
  coverage, or final sign-off artifacts.

### Microcopy Sweep

- **D-16 - All touched page-level copy goes through `AccrueAdmin.Copy` modules.**
  Avoid new raw user-facing strings in LiveView templates. If copy exports or
  fixtures depend on generated strings, regenerate and commit them with the
  implementation.
- **D-17 - Empty and error states must name the state and next useful action.**
  Keep first-run empty, queue-empty, filtered-empty, loading, error, and
  permission-denied copy distinct. Avoid generic "No results" language when the
  surface knows the resource and state.
- **D-18 - Action and `Change` labels need object context.** Summary-list row
  actions and action-menu labels should include visible or visually-hidden context
  naming the affected object and next action. Example shape: visible "Change",
  accessible label "Change default payment method for [customer]". Exact copy is
  planner discretion, bounded by the brand voice.
- **D-19 - Use the ratified voice system without marketing drift.** Admin UI copy
  should be measured, exact, native, and durable: name billing artifacts and
  mechanisms, use present tense, avoid hype adjectives, avoid Rails/SaaS jargon,
  and keep labels short enough for mobile.

### Verification Shape

- **D-20 - Layer tests by failure mode.** Use ExUnit/component tests for markup
  contracts and selectors; JS unit tests for `ScrollLock`, `FocusTrap`, dropdown,
  theme, and any anchored helper; Playwright for composed route behavior,
  hit-testing, clipping, focus, scroll, theme persistence, and multi-step flows.
- **D-21 - Reuse existing helpers before adding new harnesses.** Extend
  `phase191-page-flow-helpers.js`, `admin-spec-detail-phase198.spec.js`,
  `admin-spec-list-phase197.spec.js`, and `reduced-motion.spec.js` where that
  keeps intent obvious. Add a new Phase 199 spec only when the flow cuts across
  multiple archetype specs.
- **D-22 - Keep implementation local and dependency-light.** New abstractions are
  allowed only when they reduce repeated overlay/floating/test logic. Avoid
  broad page DSLs, generic `InteractionPage` manifests, or runtime dependencies
  unless a local implementation cannot meet the locked behavior.

### Folded Todos

No pending todos were folded into Phase 199.

### Claude's Discretion

- Exact Playwright spec filenames and helper function names.
- Which representative routes get the deepest viewport/theme matrix, provided
  the set includes at least Customer, Invoice, Charge/Payment, Webhook, Connect,
  Recovery/Campaign, and one read-only reference detail.
- Exact copy strings and hidden-label wording, bounded by `brandbook/voice.md`
  and the existing `AccrueAdmin.Copy` module structure.
- Whether near-edge floating positioning is solved with small local helpers or
  by extending existing dropdown/command-palette hooks.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements

- `.planning/ROADMAP.md` - Phase 199 goal, IXN/FIX/CPY success criteria, and
  Phase 200 boundary.
- `.planning/REQUIREMENTS.md` - IXN-01..04, FIX-01..02, CPY-01 mapping plus
  v1.54 exclusions.
- `.planning/STATE.md` - current milestone state and Phase 198 completion notes.
- `.planning/PROJECT.md` - stable-core posture and v1.54 strategic reopen
  decision.

### Locked Pattern and Research Contracts

- `.planning/research/SUMMARY.md` - v1.54 synthesis and Phase 199 routing:
  canonical overlay primitive, rendered state matrix, fixture stress, and copy
  sweep.
- `.planning/research/ARCHITECTURE.md` - overlay/motion acceptance criteria:
  scroll lock, portal, inert, dismissal, geometry, origin-aware transforms,
  focus, and reduced motion.
- `.planning/research/PITFALLS.md` - failure-mode catalog for modal-behind-scrim,
  scroll traps, mispositioned floating UI, disabled/focus/contrast, theme FOUC,
  truncation, and false affordances.
- `.planning/research/v1.54-storybook-and-forward-only-qa.md` - rendered
  state-matrix and forward-only page-flow expectations.
- `accrue_admin/guides/spec-detail.md` - DETAIL invariants, including overlay
  hit-testing/body-scroll and summary-list action context.
- `accrue_admin/guides/spec-list.md` - LIST invariants for distinct states,
  chips/count/clear-all, truncation/min-width, and pagination absence.
- `accrue_admin/guides/spec-overview.md` - overview invariants for non-
  interactive healthy empty states and Recovery grammar.
- `accrue_admin/guides/motion.md` - current motion-token vocabulary and
  reduced-motion posture.
- `accrue_admin/guides/admin_ui.md` - admin UI integration principles and
  committed bundle expectations.

### Prior Phase Decisions

- `.planning/phases/196-exemplar-c-subscriptions-list-pageheader/196-CONTEXT.md`
  - LIST/PageHeader contracts, distinct list states, and Phase 199/200 boundary.
- `.planning/phases/197-propagate-list/197-CONTEXT.md` - propagated list
  surfaces, list contract test support, copy-state expectations, and reviewed
  todo boundaries.
- `.planning/phases/198-propagate-detail-analytics/198-CONTEXT.md` - current
  detail/analytics conformance, action/drawer flows, target pages, lazy sections,
  Recovery/Campaign grammar, and Phase 199 ownership.
- `.planning/phases/195-exemplar-b-subscription-detail/195-CONTEXT.md` -
  action-menu, drawer, step-up, overlay primitive groundwork, and subscription
  detail exemplar.
- `.planning/phases/193-research-re-baseline-pattern-lock/193-CONTEXT.md` -
  archetype contracts, overlay spike direction, Storybook posture, and page-flow
  baseline.

### Brand and Copy

- `brandbook/voice.md` - voice SSOT: measured, exact, native, durable; banned
  hype words and surface tone rules.
- `brandbook/copy.md` - approved copy examples and microcopy posture.
- `accrue_admin/lib/accrue_admin/copy.ex` and
  `accrue_admin/lib/accrue_admin/copy/*.ex` - implementation SSOT for page copy.
- `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` - export
  task for committed copy fixtures when strings change.

### Overlay, Theme, and Interaction Code

- `accrue_admin/lib/accrue_admin/components/overlay.ex` - portal-backed
  canonical overlay component.
- `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` - drawer wrapper
  around `Overlay`.
- `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` - modal
  step-up wrapper around `Overlay`.
- `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` - action-menu
  floating surface and marker owner.
- `accrue_admin/lib/accrue_admin/components/theme_picker.ex` - theme segmented
  control.
- `accrue_admin/lib/accrue_admin/layouts.ex` - root layout, `#ax-overlay-root`,
  and anti-FOUC script ordering.
- `accrue_admin/assets/js/hooks/overlay.js` - composed `FocusTrap` + `ScrollLock`
  hook.
- `accrue_admin/assets/js/hooks/focus_trap.js` - focus containment, Escape,
  initial focus, and restore behavior.
- `accrue_admin/assets/js/hooks/scroll_lock.js` - ref-counted scroll lock,
  inert shell, scrollbar compensation, and iOS-safe fixed restore.
- `accrue_admin/assets/js/hooks/accrue_theme.js` - production theme persistence
  key and segmented-control behavior.
- `accrue_admin/assets/js/hooks/dropdown.js` and
  `accrue_admin/assets/js/hooks/command_palette.js` - floating surfaces to
  include in bounds/origin/focus checks.
- `accrue_admin/assets/css/app.css` and `accrue_admin/assets/css/theme.css` -
  source CSS; rebuild `accrue_admin/priv/static/accrue_admin.css` after edits.

### Target Routes and LiveViews

- `accrue_admin/lib/accrue_admin/live/customers_live.ex` and
  `accrue_admin/lib/accrue_admin/live/customer_live.ex`
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex` and
  `accrue_admin/lib/accrue_admin/live/invoice_live.ex`
- `accrue_admin/lib/accrue_admin/live/charges_live.ex` and
  `accrue_admin/lib/accrue_admin/live/charge_live.ex`
- `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` and
  `accrue_admin/lib/accrue_admin/live/webhook_live.ex`
- `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex` and
  `accrue_admin/lib/accrue_admin/live/connect_account_live.ex`
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` and
  `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` and
  `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex`
- `accrue_admin/lib/accrue_admin/live/coupons_live.ex`,
  `coupon_live.ex`, `promotion_codes_live.ex`, `promotion_code_live.ex`,
  `events_live.ex`, and `event_live.ex`

### Verification Seams

- `accrue_admin/test/js/scroll_lock_test.mjs` - existing JS lock/inert/ref-count
  tests to extend.
- `accrue_admin/test/js/focus_trap_test.mjs` - focus trap and Escape tests.
- `accrue_admin/test/js/dropdown_test.mjs` - dropdown dismissal/focus restore.
- `accrue_admin/test/accrue_admin/components/overlay_components_test.exs` -
  overlay, drawer, and step-up component contract tests.
- `accrue_admin/test/accrue_admin/theme_test.exs` - anti-FOUC ordering and
  theme session/cookie behavior.
- `accrue_admin/test/support/list_contracts.ex` - existing list-state contract
  rows and loading fixture key.
- `accrue_admin/e2e/phase191-page-flow-helpers.js` - reusable clipping, focus,
  hit-test, scroll, theme, and page-flow helpers.
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js` - prior interaction-flow
  driver pattern.
- `accrue_admin/e2e/admin-spec-detail-phase195.spec.js` - subscription overlay
  and drawer exemplar checks.
- `accrue_admin/e2e/admin-spec-detail-phase198.spec.js` - propagated detail and
  drawer/step-up flow checks.
- `accrue_admin/e2e/admin-spec-list-phase197.spec.js` - list route matrix and
  state checks.
- `accrue_admin/e2e/reduced-motion.spec.js` - reduced-motion token and surface
  checks to extend.
- `accrue_admin/e2e/admin-a11y.spec.js` - axe light/dark route scan.
- `accrue_admin/e2e/baseline-manifest.js` - page-flow surfaces, states, themes,
  and fixture parameters.

### External Platform References Considered

- `https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/` - modal dialog focus,
  Escape, containment, and focus return expectations.
- `https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/inert`
  - `inert` background behavior.
- `https://developer.mozilla.org/en-US/docs/Web/CSS/scrollbar-gutter` - stable
  scrollbar gutter behavior.
- `https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion`
  - reduced-motion media feature.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`Overlay.overlay/1`** already portals open overlays to `#ax-overlay-root`,
  marks shell/backdrop/panel, supplies presentation names, and composes close
  event/target metadata for the JS hook.
- **`assets/js/hooks/overlay.js`** already composes `FocusTrap` and `ScrollLock`
  for modal/drawer presentations.
- **`ScrollLock`** already implements ref counting, fixed-root scroll
  preservation, scrollbar compensation, and shell `inert`.
- **`FocusTrap`** already handles initial focus, Tab wrapping, Escape dispatch,
  outside-focus recapture, and focus restore/fallback.
- **`DetailDrawer` and `StepUpAuthModal`** are overlay-backed wrappers and should
  remain the primary form/step-up hosts.
- **Phase 191/195/197/198 Playwright helpers/specs** already cover clipping,
  hit-testing, scroll reachability, detail/list markers, and representative
  drawer flows. Phase 199 should extend those rather than start from scratch.
- **`AccrueAdmin.Copy` and copy modules** are the copy SSOT; tests already assert
  many page strings through Copy functions.

### Established Patterns

- Stateless Phoenix function components own shared markup; LiveViews own route
  params, action state, provider gates, and step-up execution.
- Source guards handle mechanical CSS invariants; rendered Playwright tests
  handle composed interaction/page failures.
- Committed `ax-*` CSS bundle is the shipped admin style surface; editing source
  CSS requires rebuilding and committing the generated bundle.
- Route helpers and scoped-path helpers preserve owner scope and query params.
- Deterministic seed endpoints are the right way to stress real operator flows;
  fake production delays or client-only state are not.

### Integration Points

- Overlay sweep integrates with `DetailDrawer`, `StepUpAuthModal`, action menus,
  command palette, theme picker, dropdowns, and page-specific drawer states.
- Fixture stress integrates with existing `/__e2e__/seed/*` endpoints and the
  `baseline-manifest.js` page-flow route builders.
- Theme tests integrate with `Layouts.anti_fouc_script/0`,
  `accrue_theme.js`, cookies, localStorage, and Playwright media emulation.
- Microcopy sweep integrates with page-specific copy modules and any committed
  copy export fixtures.

</code_context>

<specifics>
## Specific Ideas

- All gray areas were auto-selected because this phase's scope is already
  tightly locked by ROADMAP/REQUIREMENTS, recent phase contexts, and repo config
  favoring all-area discussion plus low-risk auto-resolution.
- No new user free-text was added during this run; decisions come from the phase
  contract, latest three contexts, codebase scout, and current repo state.
- The important correction from the code scout is that scroll lock now exists:
  planners should sweep and prove the existing `ScrollLock`, not follow older
  research text that described body scroll-lock as absent.
- The production theme key is `accrue_theme`; tests that only set `data-theme`
  or the older helper key do not prove persistence/no-FOUC.
- Reviewed todo matcher output was not folded because both matches are false
  positives for Phase 199: `PageHeader` was resolved by 196/197, and the
  white-label billing portal todo is future `accrue_portal` scope.

</specifics>

<deferred>
## Deferred Ideas

- **Native `<dialog>` rewrite** - fallback only if the portal-backed substrate
  cannot satisfy transformed-ancestor/hit-test tests.
- **Floating UI dependency** - defer unless local anchored positioning cannot
  satisfy near-edge viewport assertions.
- **Full visual-regression SaaS / pixel diff** - still deferred; Phase 200 uses
  the forward-only scored-cell gate.
- **Storybook family/group completeness and final axe/no-FOUC scorecard** -
  Phase 200 ownership.
- **Generic page/interaction DSL** - deferred. Phase 199 should use focused
  helpers and manifests only where they clarify tests.
- **`accrue_portal` white-label billing portal design-system pass** - future
  portal milestone, explicitly out of admin UI Phase 199.

### Reviewed Todos (not folded)

- **White-label billing portal design system**
  (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`)
  - reviewed and deferred because Phase 199 is `accrue_admin` operator UI only.
- **Shared page_header component for accrue_admin list pages**
  (`.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md`)
  - reviewed as a matcher but already folded into and resolved by Phases 196/197.

</deferred>

---

*Phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress*
*Context gathered: 2026-06-29*
