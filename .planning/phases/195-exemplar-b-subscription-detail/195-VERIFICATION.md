---
phase: 195-exemplar-b-subscription-detail
verified: 2026-06-26T12:46:51Z
status: passed
score: "12/12 must-haves verified"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 195: exemplar-b-subscription-detail Verification Report

**Phase Goal:** Convert the worst info-dump (~25 always-visible zones -> ~6 bands) to summary-then-drill + <=2 primary actions + an overflow action-menu hosting actions in a side-drawer; build the action-menu primitive + side-drawer action hosting.
**Verified:** 2026-06-26T12:46:51Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Subscription detail is converted to the six-band DETAIL spine: summary header/list, action band, drill sections, one related strip, lazy activity, lazy raw JSON. | VERIFIED | `SubscriptionLive` renders `Detail.summary_card`, `Detail.summary_list`, `[data-ax-action-band]`, three `[data-ax-drill-section]`, one `[data-ax-related-resources]`, `[data-ax-lazy-activity]`, and `[data-ax-lazy-json]` in `accrue_admin/lib/accrue_admin/live/subscription_live.ex:210`, `:222`, `:226`, `:270`, `:322`, `:326`, `:341`. LiveView and Playwright assert those counts in `subscription_live_test.exs:80` and `admin-spec-detail-phase195.spec.js:131`. |
| 2 | Initial render exposes no visible action forms and no old always-visible action panels. | VERIFIED | Drawer state initializes closed in `subscription_live.ex:68-76`; action band contains buttons/menu only in `subscription_live.ex:226-260`; drawer content is under `DetailDrawer.detail_drawer open={drawer_open?(...)}` in `subscription_live.ex:352-386`. Tests refute action-band forms and legacy panels in `subscription_live_test.exs:100-105` and `admin-spec-detail-phase195.spec.js:134-138`. |
| 3 | Action hierarchy is <=2 primary actions plus one overflow action menu. | VERIFIED | Primary actions are only `Change plan` and `Cancel renewal`, both marked `data-ax-primary-action`; overflow is `DropdownMenu.action_menu` in `subscription_live.ex:233-259`. Tests assert exactly/tolerantly this in `subscription_live_test.exs:137-177` and `admin-spec-detail-phase195.spec.js:139-143`. |
| 4 | Provider-unavailable actions are absent, not disabled-looking, and crafted unavailable events fail closed. | VERIFIED | Braintree gating is encoded in `action_available?/2` and `reject_unavailable_action/1` in `subscription_live.ex:973-999`; Braintree UI removes unsupported actions and server-side crafted events are rejected in `subscription_live_test.exs:543-652`. |
| 5 | Operator actions selected from the overflow menu open side-drawer-hosted action content. | VERIFIED | Menu items emit `open_action_drawer` in `subscription_live.ex:858-865`; the drawer hosts either `.action_form` or pending confirmation content in `subscription_live.ex:352-386`; Playwright opens a safe menu item and verifies the drawer under `#ax-overlay-root` in `admin-spec-detail-phase195.spec.js:64-81`. |
| 6 | Destructive actions still require StepUp after the drawer confirmation path and do not execute directly from the menu. | VERIFIED | `confirm_action` routes `@destructive_actions` through `StepUp.require_fresh/4` in `subscription_live.ex:133-158`; tests prove `cancel_now` and `remove_item` reach StepUp before mutation in `subscription_live_test.exs:179-280`. |
| 7 | Duplicate related-resources card is deleted and old KPI/dunning/action/tax info-dump zones are folded into summary/drill bands. | VERIFIED | Single related strip is rendered in `subscription_live.ex:322-324`; tests refute duplicate related, standalone dunning, confirm panel, KPI grid, and old KPI copy in `subscription_live_test.exs:80-135`. |
| 8 | Canonical overlay primitive exists, portals to the body-level root, and drawer/modal wrappers use it. | VERIFIED | `Overlay.overlay/1` portals to `#ax-overlay-root` and emits shared shell/panel/backdrop/focus attributes in `overlay.ex:30-123`; root layout renders exactly one `#ax-overlay-root` after inner content in `layouts.ex:46-50`; `DetailDrawer` and `StepUpAuthModal` delegate to `Overlay.overlay` in `detail_drawer.ex:31-55` and `step_up_auth_modal.ex:26-65`. Component tests assert the portal/wrapper contract in `overlay_components_test.exs:15-125` and `:335-435`. |
| 9 | Overlay browser behavior scroll-locks, marks background inert, composes FocusTrap, and dismisses cleanly. | VERIFIED | `Overlay` composes `FocusTrap` and `ScrollLock` in `overlay.js:1-57`; `ScrollLock` uses a ref count, exact scroll restore, and inert shell restoration in `scroll_lock.js:1-162`. Node tests exercise ref-count, exact restore, inert final unlock, and dropdown Escape/outside-click dismissal in `scroll_lock_test.mjs:111-170` and `dropdown_test.mjs:69-125`; Playwright verifies portal, inert, focus, body-scroll stability, Escape, and backdrop dismissal in `admin-spec-detail-phase195.spec.js:174-206`. |
| 10 | Overlay and action-menu visual/layer contracts use the existing token scale; drawer is right-docked desktop and bottom-sheet mobile. | VERIFIED | CSS maps overlay presentations to `--ax-z-*`, keeps backdrop below panel, and defines drawer/mobile geometry in `app.css:1332-1551`; action-menu and summary-list CSS are in `app.css:2572-2620` and `:3699-3775`. Component tests assert z-token, panel/backdrop ordering, and desktop/mobile geometry in `overlay_components_test.exs:297-333`. |
| 11 | Reusable `Detail.summary_list/1` and `DropdownMenu.action_menu/1` primitives exist and are consumed by Subscription detail. | VERIFIED | `SubscriptionLive` consumes `Detail.summary_list` and `DropdownMenu.action_menu` in `subscription_live.ex:222` and `:255`; component tests assert summary-list semantics/actions and non-modal action-menu behavior in `overlay_components_test.exs:128-295`. |
| 12 | Storybook primitive/exemplar coverage and Phase 199 handoff exist. | VERIFIED | Root `storybook/components/overlay.story.exs`, `action_menu.story.exs`, `detail.story.exs`, and `subscription_detail.story.exs` call real `AccrueAdmin.Components.*` modules and cover overlay/action-menu/summary/detail states in `storybook/components/overlay.story.exs:1-145`, `action_menu.story.exs:1-155`, `detail.story.exs:1-136`, and `subscription_detail.story.exs:1-320`. The Phase 199 transformed-ancestor handoff names action-band/menu/panel selectors and stable ancestors in `195-PHASE199-HANDOFF.md:1-25`. |

**Score:** 12/12 truths verified (0 present-but-behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | Six-band Subscription detail, action hierarchy, side-drawer action flow, lazy activity/raw JSON, provider gating | VERIFIED | Substantive and wired; backed by real `Subscriptions.detail/2`, `Accrue.Events.timeline_for/3`, and `Billing` action calls. |
| `accrue_admin/lib/accrue_admin/components/overlay.ex` | Canonical overlay primitive | VERIFIED | Public component emits portal, shell, panel, backdrop, modal/drawer/popover semantics, and FocusTrap/Overlay hook attributes. |
| `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` | Side-drawer action host wrapper | VERIFIED | Delegates to `Overlay.overlay` with `presentation={:drawer}` and `component_group="drawer-form"`. |
| `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` | StepUp modal wrapper on canonical overlay | VERIFIED | Delegates to `Overlay.overlay` with `presentation={:modal}` and `component_group="modal-confirm"`. |
| `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` | Non-modal action-menu primitive | VERIFIED | Native disclosure menu with `role="menu"`/`menuitem` buttons and no overlay/scroll-lock semantics. |
| `accrue_admin/lib/accrue_admin/components/detail.ex` | `Detail.summary_list/1` primitive | VERIFIED | Semantic `dl` summary-list with row actions; component tests cover read-only, Change, and View cases. |
| `accrue_admin/assets/js/hooks/overlay.js` and `scroll_lock.js` | Overlay hook, FocusTrap composition, scroll lock/inert behavior | VERIFIED | Source and node tests verify behavior; generated JS bundle was rebuilt and compile/e2e use it. |
| `accrue_admin/assets/css/app.css` | Overlay, drawer, action-menu, summary-list CSS | VERIFIED | Tokened z layers, panel/backdrop order, desktop/mobile drawer geometry, and action-menu/summary-list styling are present and tested. |
| `storybook/components/*.story.exs` | Storybook coverage for overlay/action-menu/detail/subscription-detail | VERIFIED | Four root story files exist and call real component modules with synthetic data. |
| `accrue_admin/e2e/admin-spec-detail-phase195.spec.js` | Rendered SPEC-DETAIL and overlay behavior coverage | VERIFIED | 8-test Playwright gate passes on desktop and mobile. |
| `.planning/phases/195-exemplar-b-subscription-detail/195-PHASE199-HANDOFF.md` | D-04c transformed-ancestor handoff | VERIFIED | Names selectors and Phase 199 audit scope. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `SubscriptionLive` | `Subscriptions.detail/2` | `mount/3` calls query | WIRED | `subscription_live.ex:43-76` calls `Subscriptions.detail`; query uses `Repo.one()` and preload in `queries/subscriptions.ex:71-86`. |
| `SubscriptionLive` | `Accrue.Events.timeline_for/3` | lazy `ensure_timeline_events/1` | WIRED | Initial state is unloaded; lazy load calls `Events.timeline_for("Subscription", id, limit: 25)` in `subscription_live.ex:624-632`; event query uses `Accrue.Repo.all()` in `accrue/lib/accrue/events.ex:261-272`. |
| `SubscriptionLive` | `Detail.summary_list/1` | direct component call | WIRED | `subscription_live.ex:222`; covered by summary-list component tests. |
| `SubscriptionLive` | `DropdownMenu.action_menu/1` | direct component call | WIRED | `subscription_live.ex:255`; menu item data flows from `action_menu_groups/1` in `subscription_live.ex:819-855`. |
| `DropdownMenu.action_menu/1` | drawer event flow | `phx-click={item_event(item)}` / `phx-value-action_type` | WIRED | Primitive emits the chosen action type in `dropdown_menu.ex:90-103`; `SubscriptionLive` handles `open_action_drawer` in `subscription_live.ex:80-96`. |
| `DetailDrawer` | `Overlay.overlay/1` | wrapper delegates to canonical primitive | WIRED | `detail_drawer.ex:31-55`; component tests verify portal and drawer semantics. |
| `StepUpAuthModal` | `Overlay.overlay/1` | wrapper delegates to canonical primitive | WIRED | `step_up_auth_modal.ex:26-65`; component tests verify modal semantics. |
| `Overlay.overlay/1` | `assets/js/hooks/overlay.js` | `phx-hook="Overlay"` + hook registration | WIRED | Markup emits `phx-hook="Overlay"` in `overlay.ex:55-68`; hook imports `FocusTrap` and `ScrollLock` in `overlay.js:1-57`. |
| `Overlay.overlay/1` | body root | Phoenix portal target | WIRED | Portal target is `#ax-overlay-root` in `overlay.ex:53-55`; layout root is in `layouts.ex:46-50`. |
| Storybook stories | real components | `alias AccrueAdmin.Components.*` and component calls | WIRED | Story files call `Overlay.overlay`, `DropdownMenu.action_menu`, and `Detail.summary_list`; no copied production markup is used for the primitives. |
| Playwright spec | Phase 191/193 baseline and helpers | fixture source check + helper import | WIRED | Imports `phase191-page-flow-helpers.js` in `admin-spec-detail-phase195.spec.js:13-17` and checks `baseline.page-flow.cells.json` in `:21-25`, `:151-160`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `SubscriptionLive` detail page | `@subscription`, `@customer`, `@related_items` | `Subscriptions.detail/2` -> Ecto query -> `Repo.one()` + `Repo.preload` | Yes | FLOWING |
| `SubscriptionLive` summary rows | `summary_rows(@subscription, @customer, ...)` | Live assigns from DB-backed subscription/customer | Yes | FLOWING |
| `SubscriptionLive` action menu | `action_menu_groups(@subscription)` | Computed from real subscription processor/items/gating predicates | Yes | FLOWING |
| `SubscriptionLive` activity | `@timeline_events` | Initially `[]` by design, then lazy `Accrue.Events.timeline_for/3` on open/action flow | Yes | FLOWING |
| `SubscriptionLive` raw JSON | `subscription_payload(@subscription)` | Escaped payload from current subscription assign, only rendered after lazy open | Yes | FLOWING |
| Storybook stories | synthetic story state | Dev/test-only wrapper attributes | N/A | VERIFIED AS STORYBOOK SPECIMENS |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Server-rendered six-band page, action hierarchy, provider gating, drawer StepUp flow, overlay components | `mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/live/step_up_test.exs` | `37 tests, 0 failures` | PASS |
| Dropdown Escape/outside-click and scroll-lock ref-count/inert/exact restore | `node --test test/js/dropdown_test.mjs test/js/scroll_lock_test.mjs` | `8 pass, 0 fail` | PASS |
| Storybook modules and app compile with warnings-as-errors | `mix compile --warnings-as-errors` | exit 0 | PASS |
| Package/docs regression guard | `bash scripts/ci/verify_package_docs.sh` | package docs verified for all packages | PASS |
| Rendered browser SPEC-DETAIL and IXN-01 phase gate | `npm run e2e:phase195` | `8 passed` across desktop and mobile | PASS |

### Probe Execution

| Probe | Command | Result | Status |
| --- | --- | --- | --- |
| Conventional phase probes | `find scripts -path '*/tests/probe-*.sh' -type f` | no probes discovered | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| EXE-02 | Plans 195-01 through 195-08 | Convert Subscription detail from info-dump to summary-then-drill with <=2 primary actions, overflow action-menu, related strip, lazy activity/raw JSON. | SATISFIED | Implementation in `SubscriptionLive`; LiveView and Playwright gates verify structure, action cap, related-strip uniqueness, lazy sections, and old-panel removal. |
| IXN-01 | Cross-phase dependency instantiated here; owned by Phase 199 for full sweep | Canonical overlay primitive with portal, scroll lock, inert/focus/dismissal; side-drawer and StepUp use it for Subscription detail. | SATISFIED FOR PHASE 195 | `Overlay.overlay`, `DetailDrawer`, `StepUpAuthModal`, `Overlay` JS hook, `ScrollLock`, CSS, component tests, node tests, and Playwright all verify the Subscription detail instantiation. Phase 199 explicitly owns the all-page sweep per roadmap Phase 199 success criteria. |

No orphaned Phase 195 requirements were found in `.planning/REQUIREMENTS.md`; `IXN-01` is deliberately assigned to Phase 199 with the Phase 195 instantiation dependency.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | - | - | Debt/stub scan found no unresolved `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholder UI stubs, empty rendered data stubs, or console-log-only implementations in Phase 195 source/story/test files. Benign matches were guard returns in JS tests/source, StepUp input placeholder text, and a diagnostic log in an existing spike E2E spec. |

### Human Verification Required

None. Behavior-dependent truths have direct automated coverage: ExUnit for LiveView state transitions and StepUp, Node tests for scroll lock/dropdown cleanup, and Playwright for rendered portal/inert/focus/dismissal/geometry.

### Gaps Summary

No gaps found. The Phase 195 goal is achieved in the codebase. The broader IXN-01 all-page overlay sweep is not a Phase 195 gap because Phase 199 owns that contract and the Phase 195 handoff identifies the remaining transformed-ancestor audit.

---

_Verified: 2026-06-26T12:46:51Z_
_Verifier: the agent (gsd-verifier)_
