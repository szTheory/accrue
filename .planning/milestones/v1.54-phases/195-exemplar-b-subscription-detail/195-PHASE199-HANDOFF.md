# Phase 195 -> Phase 199 Handoff: Subscription Detail Action Menu

## D-04c Transformed-Ancestor Audit

Phase 195 intentionally leaves the Subscription detail overflow action menu as a lightweight, non-modal native disclosure menu. It is not portaled. The drawer and StepUp surfaces opened from the menu route through the canonical overlay primitive; the trigger menu itself remains in the page flow until Phase 199 has evidence to justify any exception.

## Selectors To Audit

| Surface | Selector / Class | Notes |
| --- | --- | --- |
| Subscription detail action band | `[data-ax-action-band]` and `.ax-detail-action-band` | Local section wrapping the primary actions and overflow menu. |
| Overflow action menu root / trigger | `#subscription-action-menu[data-ax-action-overflow-menu]` and `#subscription-action-menu > summary.ax-action-menu-trigger` | Emitted by `DropdownMenu.action_menu/1` from `SubscriptionLive`. |
| Action-menu panel | `#subscription-action-menu .ax-dropdown-panel.ax-action-menu-panel` | The panel is absolutely positioned by the dropdown/action-menu CSS and is not rendered through `#ax-overlay-root`. |
| Menu groups / danger divider | `.ax-action-menu-group`, `.ax-action-menu-group-separated`, `.ax-action-menu-group-danger` | Useful when checking clipping around separated groups and danger-zone styling. |
| Nearest stable observed page ancestors | `#accrue-admin-shell`, `#main-content`, `.ax-page`, `.ax-card.ax-detail-action-band[data-ax-action-band]` | Observed after Plan 195-07. These are the ancestors Phase 199 should inspect before deciding whether the menu needs a portal exception. |

## Required Phase 199 Audit

Phase 199 owns the transformed-ancestor audit for this non-portaled menu. Before changing the action menu transport, inspect the ancestor chain from `#subscription-action-menu .ax-action-menu-panel` through `.ax-detail-action-band`, `.ax-page`, `#main-content`, and `#accrue-admin-shell` for:

- `transform`, `filter`, `perspective`, `contain`, or `will-change` values that can create a containing block or stacking context.
- `overflow: hidden`, `overflow: clip`, or constrained scroll containers that can clip the absolute panel.
- z-index or isolation contexts that place the panel below sibling cards, drawers, sticky headers, or scrims.

If those ancestors are clean, keep the menu non-portaled. If Phase 199 finds an unremovable clipping or re-rooting ancestor, document the failing selector, the browser evidence, and the rejected local fixes before granting a portal exception for the menu. The default remains: menu disclosure is non-modal; drawer/modal surfaces are the overlay boundary.

