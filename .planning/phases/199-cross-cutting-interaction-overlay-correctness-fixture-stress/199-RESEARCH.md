# Phase 199 Research: Cross-cutting interaction/overlay correctness + fixture stress + microcopy

**Researched:** 2026-06-29  
**Scope:** `accrue_admin` operator UI only.  
**Confidence:** HIGH for local paths and existing patterns; MEDIUM for exact Wave split.

## Summary

Phase 199 should extend the existing overlay substrate, not replace it. The canonical path is `Overlay.overlay/1` -> LiveView portal target `#ax-overlay-root` -> browser `Overlay` hook -> `FocusTrap` + `ScrollLock`; wrappers already include `DetailDrawer.detail_drawer/1` and `StepUpAuthModal.step_up_auth_modal/1`. [VERIFIED: `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-CONTEXT.md`; VERIFIED: `accrue_admin/lib/accrue_admin/components/overlay.ex`; VERIFIED: `accrue_admin/assets/js/hooks/overlay.js`]

The highest-risk planning issue is that not every interaction surface has the same ownership model. Drawers and step-up dialogs are modal overlay clients; dropdown/action menus stay non-modal native disclosure menus; the command palette is currently a fixed wrapper with its own hook and should either be routed through the canonical primitive or explicitly aligned/tested against the same focus/dismissal/scroll/background-isolation contract. [VERIFIED: `accrue_admin/lib/accrue_admin/components/detail_drawer.ex`; VERIFIED: `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex`; VERIFIED: `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex`; VERIFIED: `accrue_admin/lib/accrue_admin/components/global_search.ex`; VERIFIED: `accrue_admin/assets/js/hooks/command_palette.js`]

Fixture and microcopy work should reuse current deterministic seeds, route-level Playwright helpers, `AccrueAdmin.Copy`, and detail/list component affordances. Do not invent a generic page DSL, fixture DSL, or broad abstraction layer; Phase 198 explicitly avoided generic runtime abstractions, and Phase 199 is a correctness sweep over composed pages. [VERIFIED: `.planning/STATE.md`; VERIFIED: `accrue_admin/test/support/e2e_fixtures.ex`; VERIFIED: `accrue_admin/e2e/phase191-page-flow-helpers.js`; VERIFIED: `accrue_admin/lib/accrue_admin/copy.ex`]

## Source Artifacts Read

- Phase context: `199-CONTEXT.md` decisions D-01..D-22, especially overlay substrate, fixture scope, microcopy, and Phase 200 boundary. [VERIFIED: `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-CONTEXT.md`]
- Roadmap Phase 199 section: goal, dependencies, success criteria, Phase 200 boundary. [VERIFIED: `.planning/ROADMAP.md`]
- Requirements rows: IXN-01, IXN-02, IXN-03, IXN-04, FIX-01, FIX-02, CPY-01. [VERIFIED: `.planning/REQUIREMENTS.md`]
- State notes: current phase position; Phase 195 overlay decisions; Phase 198 completion notes and known offscreen/verification boundary notes. [VERIFIED: `.planning/STATE.md`]
- Project instructions: `AGENTS.md` was not present in the workspace root. [VERIFIED: shell check]
- Planning graph: `.planning/graphs/graph.json` was absent, so no graph context was injected. [VERIFIED: shell check]
- Targeted code/test paths: overlay components/hooks/CSS, Playwright specs/helpers, seed helpers, copy modules, DataTable/Detail affordance components. [VERIFIED: codebase `rg`/snippets]

## Existing Patterns and Concrete Paths

### Canonical overlay substrate

- `accrue_admin/lib/accrue_admin/components/overlay.ex` owns portal markup, backdrop, panel semantics, presentation types `:modal | :drawer | :popover`, scroll-lock flags, focus-trap data attributes, and backdrop click wiring. It portals with `<.portal target="#ax-overlay-root">`. [VERIFIED: `accrue_admin/lib/accrue_admin/components/overlay.ex`]
- `accrue_admin/lib/accrue_admin/layouts.ex` renders exactly one body-level `<div id="ax-overlay-root"></div>` after page content and before runtime style/JS. [VERIFIED: `accrue_admin/lib/accrue_admin/layouts.ex`; VERIFIED: `accrue_admin/test/accrue_admin/components/overlay_components_test.exs`]
- `accrue_admin/assets/js/hooks/overlay.js` composes `FocusTrap` and `ScrollLock`; only modal/drawer presentations should scroll-lock. [VERIFIED: `accrue_admin/assets/js/hooks/overlay.js`]
- `accrue_admin/assets/js/hooks/scroll_lock.js` is ref-counted, fixes the root to preserve iOS/body scroll, writes `--ax-scrollbar-comp`, and sets/restores `#accrue-admin-shell` `inert`. [VERIFIED: `accrue_admin/assets/js/hooks/scroll_lock.js`; VERIFIED: `accrue_admin/test/js/scroll_lock_test.mjs`]
- `accrue_admin/assets/js/hooks/focus_trap.js` stores previous focus, wraps Tab/Shift+Tab, redirects outside focus back inside, restores focus on cleanup, and dispatches the configured close event on Escape. [VERIFIED: `accrue_admin/assets/js/hooks/focus_trap.js`; VERIFIED: `accrue_admin/test/js/focus_trap_test.mjs`]
- `accrue_admin/assets/css/app.css` defines fixed overlay shells, isolated backdrop/panel z-order, drawer/mobile-sheet geometry, modal and popover shells, dropdown origin, and reduced-motion token usage. [VERIFIED: `accrue_admin/assets/css/app.css`; VERIFIED: `accrue_admin/assets/css/theme.css`]

### Current clients and exceptions

- Confirmed drawer clients: `invoice_live.ex`, `subscription_live.ex`, `charge_live.ex`, `customer_live.ex`, `connect_account_live.ex`, and `webhook_live.ex` use `DetailDrawer.detail_drawer/1`. [VERIFIED: codebase `rg`]
- Confirmed step-up clients: `invoice_live.ex`, `subscription_live.ex`, `charge_live.ex`, `connect_account_live.ex`, and `webhook_live.ex` use `StepUpAuthModal.step_up_auth_modal/1` plus hidden `data-role="step-up-test-mirror"` blocks for LiveViewTest support. Those mirrors must remain hidden and non-interactive. [VERIFIED: codebase `rg`; VERIFIED: `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-CONTEXT.md`]
- `DropdownMenu.action_menu/1` is intentionally non-modal `details`/`summary` disclosure. It renders `role="menu"`/`role="menuitem"`, hidden context, and no `aria-modal`, `data-scroll-lock`, or overlay shell. [VERIFIED: `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex`; VERIFIED: `accrue_admin/test/accrue_admin/components/overlay_components_test.exs`]
- `assets/js/hooks/dropdown.js` closes open dropdowns on outside click or Escape and restores focus to the summary trigger. [VERIFIED: `accrue_admin/assets/js/hooks/dropdown.js`; VERIFIED: `accrue_admin/test/js/dropdown_test.mjs`; VERIFIED: `accrue_admin/e2e/dropdown-dismiss.spec.js`]
- `GlobalSearch`/command palette currently uses `.ax-command-palette-wrapper`, fixed z-modal CSS, `CommandPalette` hook, manual focus restore, backdrop click, and Escape close. It is not currently routed through `Overlay.overlay/1`. [VERIFIED: `accrue_admin/lib/accrue_admin/components/global_search.ex`; VERIFIED: `accrue_admin/assets/js/hooks/command_palette.js`; VERIFIED: `accrue_admin/assets/css/app.css`]

### Existing validation helpers to reuse

- Playwright helper functions already cover top hit target, focus containment, body-focus avoidance, scroll reachability, and horizontal clipping. Reuse `assertTopPointerTarget`, `assertFocusWithin`, `assertNoBodyFocus`, `assertScrollReachable`, and `assertNoHorizontalClip`. [VERIFIED: `accrue_admin/e2e/phase191-page-flow-helpers.js`]
- Phase 195 Playwright already proves one subscription drawer portals, locks background scroll, traps focus, is hit-testable, has desktop/mobile geometry, and closes via Escape/backdrop. Extend the pattern across Phase 198 surfaces instead of cloning a new framework. [VERIFIED: `accrue_admin/e2e/admin-spec-detail-phase195.spec.js`]
- Phase 198 Playwright already defines explicit target matrices and representative drawer/step-up flows for Customer, Invoice, Charge, Coupon, Promotion Code, Connect, Webhook, Event, Recovery, and Campaign. Phase 199 should reuse and harden those explicit matrices. [VERIFIED: `accrue_admin/e2e/admin-spec-detail-phase198.spec.js`; VERIFIED: `.planning/STATE.md`]
- Existing scripts include `e2e:phase191` through `e2e:phase198`; Phase 199 should add an `e2e:phase199` script that mirrors the one-spec, one-worker pattern. [VERIFIED: `accrue_admin/package.json`]

### Fixtures and copy

- Seed endpoints exist for `dashboard`, `operator-flows`, `edge-states`, `overflow`, and `phase191-matrix` under `/__e2e__/seed/...`. [VERIFIED: `accrue_admin/test/support/e2e_plug.ex`]
- `seed_edge_states!/0` already creates past-due dunning, JPY invoice/charge, a very long customer name, coupon, promotion code, and Connect account. `seed_operator_flows!/0` creates charge, event, failed/dead webhooks. `seed_phase191_matrix!/0` adds deterministic IDs, non-ASCII names, boundary counts, failed webhook, and at-risk recovery. [VERIFIED: `accrue_admin/test/support/e2e_fixtures.ex`; VERIFIED: `accrue_admin/test/accrue_admin/e2e_fixtures_test.exs`]
- `DataTable` already derives `first-run-empty` vs `filtered-empty`, emits `data-ax-empty-reason`, shows Clear filters only when filters are active, and keeps unavailable select options truly disabled. [VERIFIED: `accrue_admin/lib/accrue_admin/components/data_table.ex`]
- `Detail.summary_list/1` and `DropdownMenu.action_menu/1` already support visible action labels plus visually hidden object/action context. [VERIFIED: `accrue_admin/lib/accrue_admin/components/detail.ex`; VERIFIED: `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex`]
- Copy SSOT is `AccrueAdmin.Copy` plus domain modules in `accrue_admin/lib/accrue_admin/copy/*.ex`; generated copy exports are handled by `mix accrue_admin.export_copy_strings --out ...` when relevant. [VERIFIED: `accrue_admin/lib/accrue_admin/copy.ex`; VERIFIED: `accrue_admin/lib/accrue_admin/copy/*.ex`; VERIFIED: `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex`]

## Planning Implications by Requirement

### IXN-01: canonical overlay primitive

- Start with RED coverage that inventories modal/drawer/step-up/command-palette/dropdown surfaces and asserts the expected route: modal/drawer through `Overlay`, dropdown as non-modal disclosure, command palette either through `Overlay` or explicitly brought to equivalent behavior. [VERIFIED: `199-CONTEXT.md`; VERIFIED: codebase `rg`]
- Add JS unit coverage for nested lock/open-close cases: nested modal/drawer lock count, rapid open/close/double-toggle, close while transition is pending, and final restore of scroll position, `--ax-scrollbar-comp`, and `inert`. [VERIFIED: `accrue_admin/test/js/scroll_lock_test.mjs`; VERIFIED: `accrue_admin/assets/js/hooks/scroll_lock.js`]
- Add Playwright route coverage for representative drawers/step-up flows across Invoice, Charge, Webhook, Connect, Customer payment methods, and Subscription; assert portal root count, panel hit testing, inert shell, no body scroll, Escape/backdrop same close result, no ghost scrim/panel, and focus restore to a meaningful trigger/fallback. [VERIFIED: `accrue_admin/e2e/admin-spec-detail-phase195.spec.js`; VERIFIED: `accrue_admin/e2e/admin-spec-detail-phase198.spec.js`]

### IXN-02: geometry, focus, and motion

- Keep desktop drawer right-docked with `translateX(100%)`; keep mobile drawer bottom-sheeted with `translateY(100%)`; assert both through Playwright viewport checks and CSS component tests. [VERIFIED: `accrue_admin/assets/css/app.css`; VERIFIED: `accrue_admin/test/accrue_admin/components/overlay_components_test.exs`]
- Extend `reduced-motion.spec.js` to cover final drawer/mobile-sheet and any Phase 199 popover/command-palette classes. The existing pattern checks both reduced and non-reduced cases to avoid false positives. [VERIFIED: `accrue_admin/e2e/reduced-motion.spec.js`]
- Add focus-ring immediacy checks around overlay open and reduced-motion mode; use `foundation-tokens.spec.js` focus-ring patterns only as reference, not as a replacement for route-level overlay focus tests. [VERIFIED: `accrue_admin/e2e/foundation-tokens.spec.js`; VERIFIED: `199-CONTEXT.md`]
- For popovers/floating panels, test trigger adjacency, `transform-origin`, and viewport containment near edges. Prefer extending dropdown/command-palette hooks locally before adding a positioning dependency. [VERIFIED: `199-CONTEXT.md`; VERIFIED: `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex`; VERIFIED: `accrue_admin/assets/css/app.css`]

### IXN-03: affordances, floating bounds, and theme persistence

- Add mechanical guards and Playwright assertions that non-interactive empty states do not have button roles, `phx-click`, pointer cursor, or hover styling. Existing `.ax-empty` and `.ax-attention-rail--empty` comments encode this guardrail. [VERIFIED: `accrue_admin/lib/accrue_admin/components/empty_state.ex`; VERIFIED: `accrue_admin/assets/css/app.css`; VERIFIED: `scripts/ci/verify_package_docs.sh`]
- Hidden/absent affordances should be omitted rather than rendered disabled-looking-enabled. Keep real disabled controls semantically disabled and visually distinct. [VERIFIED: `199-CONTEXT.md`; VERIFIED: `accrue_admin/lib/accrue_admin/components/data_table.ex`; VERIFIED: `accrue_admin/e2e/foundation-tokens.spec.js`]
- Existing `setPhase191Theme` writes `accrue_admin_theme`, which is useful for visual matrix checks but not production persistence. Add separate browser tests for production `accrue_theme` cookie/localStorage precedence, reload persistence, and system dark/light emulation. [VERIFIED: `accrue_admin/e2e/phase191-page-flow-helpers.js`; VERIFIED: `accrue_admin/lib/accrue_admin/layouts.ex`; VERIFIED: `accrue_admin/assets/js/hooks/accrue_theme.js`; VERIFIED: `accrue_admin/test/accrue_admin/theme_test.exs`]

### IXN-04: transformed ancestor audit

- Audit CSS for `transform`, `filter`, `backdrop-filter`, `contain`, `perspective`, and `position: fixed`; assert `#ax-overlay-root` remains a direct body-level root and overlay shells are not descendants of transformed page wrappers. [VERIFIED: `199-CONTEXT.md`; VERIFIED: targeted CSS `rg`; VERIFIED: `accrue_admin/lib/accrue_admin/layouts.ex`]
- Use the Phase 193 portal spike as precedent: portal root must escape transformed ancestors and primary actions must be top hit targets above scrim. Do not fix trapped stacking contexts with z-index bumps. [VERIFIED: `accrue_admin/e2e/spike-overlay-portal.spec.js`; VERIFIED: `199-CONTEXT.md`]

### FIX-01 and FIX-02: deterministic route-level fixtures

- Reuse `/__e2e__/seed/phase191-matrix`, `/operator-flows`, `/edge-states`, and `/overflow`. Extend `E2E.Fixtures` only for missing Phase 199 edge IDs; do not introduce a generic fixture DSL. [VERIFIED: `accrue_admin/test/support/e2e_fixtures.ex`; VERIFIED: `.planning/STATE.md`]
- Required route flows should be explicit and readable: Customer list -> Customer detail -> peer record set -> related detail -> back; Invoice list -> Invoice detail -> drawer/step-up -> back; Webhooks list -> Webhook detail -> Event/detail drill -> replay drawer/step-up; Recovery -> Campaign -> Subscription; Connect list -> Connect detail -> platform-fee drawer/step-up. [VERIFIED: `199-CONTEXT.md`]
- Assertions should target failure modes directly: no horizontal overflow/clipping, long names/emails/processor IDs wrap without squish, JPY zero-decimal values render, past-due/dunning states are reachable, dead/failed webhooks are replayable only when eligible, connect readiness surfaces are reachable, scroll sentinels are reachable, and focus does not fall to body after transitions. [VERIFIED: `199-CONTEXT.md`; VERIFIED: `accrue_admin/e2e/phase191-page-flow-helpers.js`; VERIFIED: `accrue_admin/test/support/e2e_fixtures.ex`]

### CPY-01: page-level microcopy

- Sweep LiveViews/components for raw page-level strings and route new/changed strings through `AccrueAdmin.Copy` or the relevant domain module. [VERIFIED: `199-CONTEXT.md`; VERIFIED: `accrue_admin/lib/accrue_admin/copy.ex`]
- Preserve distinct first-run empty, queue-empty, filtered-empty, loading, error, and permission-denied copy; use `DataTable`'s `empty_title`, `filtered_empty_title`, `empty_reason`, and `clear-filters` behavior instead of generic "No results" copy. [VERIFIED: `accrue_admin/lib/accrue_admin/components/data_table.ex`; VERIFIED: `accrue_admin/test/support/list_contracts.ex`; VERIFIED: `accrue_admin/test/accrue_admin/copy_test.exs`]
- Action labels such as "Change" and action-menu rows need object/action context, either visible or via `.ax-visually-hidden`. Use `action_context`, `hidden_context`, or `context` in existing components. [VERIFIED: `accrue_admin/lib/accrue_admin/components/detail.ex`; VERIFIED: `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex`; VERIFIED: `accrue_admin/test/accrue_admin/components/overlay_components_test.exs`]
- Voice guardrail: copy should be measured, exact, native, and durable; avoid hype adjectives and generic SaaS/Rails vocabulary. [VERIFIED: `brandbook/voice.md`]

## Suggested Plan/Wave Decomposition

1. **Wave 0: RED interaction contract.** Add `admin-interaction-overlay-phase199.spec.js` plus `e2e:phase199`; extend JS unit tests for `ScrollLock`, `FocusTrap`, `Dropdown`, and command palette behavior; add focused ExUnit assertions for overlay client structure and hidden test mirrors. [VERIFIED: existing test patterns]
2. **Wave 1: Overlay substrate and client sweep.** Patch `Overlay`, `DetailDrawer`, `StepUpAuthModal`, command palette, and client LiveViews so modal/drawer surfaces route through the canonical contract, dismissal is idempotent, and non-modal dropdowns remain lightweight disclosure menus. [VERIFIED: overlay/client paths above]
3. **Wave 2: Geometry, motion, floating, theme.** Extend CSS/tests for desktop/mobile drawer geometry, popover/dropdown near-edge bounds, reduced-motion, focus ring immediacy, production `accrue_theme` persistence, and transformed ancestor audit. [VERIFIED: CSS/test paths above]
4. **Wave 3: Fixture stress.** Extend `E2E.Fixtures` only where existing seeds do not cover Phase 199 failure modes, then add route-level Playwright flows for FIX-01/FIX-02 using explicit target arrays. [VERIFIED: fixture/helper paths above]
5. **Wave 4: Microcopy sweep.** Update `AccrueAdmin.Copy` domain modules, LiveView call sites, hidden context labels, empty/error states, and generated copy fixtures if touched. [VERIFIED: copy paths above]
6. **Final gates.** Run focused ExUnit/JS/Playwright gates, rebuild committed admin assets if CSS/JS changed, run copy export if copy fixtures depend on changed strings, then run relevant package-doc/guardrail checks. [VERIFIED: `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex`; VERIFIED: `scripts/ci/verify_package_docs.sh`; VERIFIED: `accrue_admin/package.json`]

## Validation Architecture

Nyquist validation is enabled in `.planning/config.json`. [VERIFIED: `.planning/config.json`]

Recommended focused commands:

- Component/contract tests: `cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/theme_test.exs test/accrue_admin/e2e_fixtures_test.exs test/accrue_admin/copy_test.exs -x`
- JS unit tests: `cd accrue_admin && node --test test/js/scroll_lock_test.mjs test/js/focus_trap_test.mjs test/js/dropdown_test.mjs`
- Existing browser baselines to keep green while adding Phase 199: `cd accrue_admin && npm run e2e:phase195 && npm run e2e:phase198 && npm run e2e:phase191`
- New Phase 199 browser gate: add `cd accrue_admin && npm run e2e:phase199` mapped to a focused Phase 199 spec.
- Reduced motion: `cd accrue_admin && env -u NO_COLOR playwright test e2e/reduced-motion.spec.js --timeout=60000 --workers=1`
- Accessibility smoke after overlay/copy changes: `cd accrue_admin && npm run e2e:a11y`
- Assets after CSS/JS edits: `cd accrue_admin && mix accrue_admin.assets.build`, then ensure `accrue_admin/priv/static/accrue_admin.css` and `.js` are committed. [VERIFIED: `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex`; VERIFIED: `.github/workflows/ci.yml`]
- Copy export after allow-listed copy changes: `cd accrue_admin && mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json` when changed strings feed generated fixtures. [VERIFIED: `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex`]

Phase requirements to validation map:

| Requirement | Validation focus |
| --- | --- |
| IXN-01 | ExUnit structure, JS lock/focus unit tests, Playwright portal/inert/scroll/dismiss/focus route checks |
| IXN-02 | CSS/component geometry tests, Playwright viewport geometry, reduced-motion checks |
| IXN-03 | Affordance source guards, Playwright bounds/theme/no-FOUC tests, focus/disabled visual checks |
| IXN-04 | CSS ancestor audit plus Playwright hit-test proof under transformed wrapper fixture |
| FIX-01 | Explicit multi-step Playwright route flows with focus/scroll/back assertions |
| FIX-02 | Seeded long-content/boundary route checks with clipping/squish/overflow assertions |
| CPY-01 | Copy unit tests, list/detail LiveView tests, Playwright empty/action-label accessible-name checks |

## Risks and Pitfalls

- **Closing IXN-01 too early:** Phase 195 instantiated the overlay primitive, but Phase 199 owns the cross-page sweep. Do not mark IXN-01 complete from subscription-only evidence. [VERIFIED: `.planning/STATE.md`; VERIFIED: `.planning/REQUIREMENTS.md`]
- **Treating dropdowns as modal overlays:** `DropdownMenu.action_menu/1` is deliberately non-modal. Adding scroll-lock or `aria-modal` there would contradict the existing contract. [VERIFIED: `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex`; VERIFIED: `.planning/STATE.md`]
- **Ignoring command palette drift:** The command palette is overlay-like but has a separate hook/CSS path. Leaving it untested against the canonical behavior could preserve focus/dismiss/stacking defects. [VERIFIED: `accrue_admin/lib/accrue_admin/components/global_search.ex`; VERIFIED: `accrue_admin/assets/js/hooks/command_palette.js`]
- **Theme false positives:** Helpers that set `data-theme` directly do not prove production `accrue_theme` persistence or anti-FOUC ordering. Add production-key coverage. [VERIFIED: `accrue_admin/e2e/phase191-page-flow-helpers.js`; VERIFIED: `accrue_admin/lib/accrue_admin/layouts.ex`; VERIFIED: `accrue_admin/test/accrue_admin/theme_test.exs`]
- **Z-index-only fixes:** A body-level portal avoids transformed/filtered/contained ancestors; z-index bumps do not escape trapped stacking contexts. [VERIFIED: `accrue_admin/e2e/spike-overlay-portal.spec.js`; VERIFIED: `199-CONTEXT.md`]
- **Broad DSLs and generic abstractions:** Phase 198 explicitly used explicit page target matrices and existing seeded fixtures, not generic DetailPage/AnalyticsPage abstractions. Phase 199 should continue that style. [VERIFIED: `.planning/STATE.md`; VERIFIED: `accrue_admin/e2e/admin-spec-detail-phase198.spec.js`]
- **Phase 200 boundary creep:** Do not own final all-cell re-score, complete Storybook coverage, package-wide axe/no-FOUC sweep, zero-regression sign-off, or maintainer sign-off artifacts. Phase 199 adds focused correctness specs and fixtures. [VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `199-CONTEXT.md`]
- **Copy in templates:** Raw strings in LiveViews/components create drift from `AccrueAdmin.Copy` and generated fixtures. Route changed page-level copy through domain modules. [VERIFIED: `199-CONTEXT.md`; VERIFIED: `accrue_admin/lib/accrue_admin/copy.ex`]

## Open Questions / Assumptions

1. **Command palette routing:** Should the command palette be refactored to use `Overlay.overlay/1`, or should Phase 199 explicitly document it as a named wrapper with equivalent behavior? Recommendation: start with RED coverage; refactor only if tests show the separate hook cannot satisfy IXN-01/02/03. [ASSUMED]
2. **Popover shared helper threshold:** A small anchored helper may be useful if dropdown, command palette, theme picker, and tooltips drift. Recommendation: add it only after near-edge tests show repeated code or inconsistent geometry. [ASSUMED]
3. **Fixture extension scope:** Existing seeds likely cover most required edge cases, but long processor IDs/emails and nested drill-back specifics may need one small `phase199` extension. Recommendation: extend `E2E.Fixtures` minimally and keep deterministic IDs. [ASSUMED]
4. **Exact copy wording:** The planner can choose exact strings within the brand voice, but should gate them through `AccrueAdmin.Copy` and copy tests. [ASSUMED]
