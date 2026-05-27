# Phase 134: Admin Global Search UI & Keyboard Nav — Discussion & Architectural Decisions

Based on the goal of creating a keyboard-first global search modal in `accrue_admin` (SRCH-03, SRCH-04) that integrates with Phase 133's Postgres Search Foundation, here is the synthesized, idiomatic architectural strategy.

## 1. Results UI: Grouped by Entity Type
**Decision:** Group results under distinct headers (e.g., "Customers", "Invoices", "Subscriptions") within the dropdown list.
**Rationale:**
- **UX/Cognitive Load:** Provides instant cognitive orientation. Since search domains are discrete, users scan for the type first, then the specific match. A flat list with badges forces the user's eye to parse both the text and the badge for every row.
- **Idiomatic/Ecosystem:** This is the established pattern for multi-domain command palettes (e.g., macOS Spotlight, Raycast, GitHub).

## 2. Empty State: Quick Links / Keyboard Legend
**Decision:** When the modal opens with no query, show a curated list of "Quick Actions" (e.g., "Go to Customers", "Create Invoice") or recent links, alongside a subtle footer showing keyboard shortcuts (`↑↓ Navigate · ↵ Select · esc Close`).
**Rationale:**
- **Ergonomics:** Transforms the search modal from a single-purpose tool into a high-utility "Command Palette". It provides immediate value without requiring keystrokes and acts as a navigation accelerator.
- **Ecosystem:** Livebook's command palette uses this pattern effectively to remain useful even before typing begins.

## 3. Keyboard Navigation & State Sync: Smart Hybrid JS Hook (`CommandPaletteHook`)
**Decision:** Implement a lightweight Vanilla JS Hook in `app.js` to handle `CMD+K` interception, focus trapping, and `↑/↓/Enter` navigation. It will use a "Smart Hybrid" approach for executing commands: the Hook handles visual traversal locally, and on `Enter`, reads data attributes to either instantly navigate (`data-path`) or push an event to the server (`data-action`).
**Rationale:**
- **Performance/Feel:** Zero latency. Prevents the browser's default `CMD+K` search bar from opening. Prevents the page from scrolling when using arrow keys inside the input. Manages the visual "active" state of list items instantaneously via classes. Tracking `active_index` on the server introduces network-bound visual lag and breaks the "native app" illusion (like Raycast or Spotlight).
- **Extensibility & DX:** The LiveView renders dumb `<li>` tags with `data-path` or `data-action` attributes. When `Enter` is pressed, if the active item has a `data-path`, the JS Hook performs an instant client-side routing transition (`liveSocket.pushHistoryPatch`). If it has a `data-action`, the JS Hook pushes the event to the LiveComponent to execute secure server-side logic (e.g., "Clear Cache"). This provides both zero-latency navigation and infinite backend extensibility.
- **Idiomatic Phoenix:** The idiomatic pattern is to use a JS hook for complex, high-frequency DOM manipulation (navigation) while letting LiveView handle the actual search query (`phx-change`) and result rendering. The Hook's `updated()` callback resets the active index to 0 whenever LiveView patches the DOM.

## 4. Search Trigger / State: Stateful LiveComponent in AppShell
**Decision:** Embed a stateful `LiveComponent` (`AccrueAdmin.Components.GlobalSearch`) inside `app_shell.ex`.
**Rationale:**
- **Architecture:** The component is globally accessible on any admin page without duplicating code in every LiveView layout. It encapsulates its own state (query, results, open/closed) independently of the main page, preventing unnecessary re-renders of the surrounding DOM.
- **Data Flow:** The component receives the search query via `phx-change`, queries the `Accrue.Billing` context (built in Phase 133), and updates its internal assigns.

## 5. Result Limits & Overflow Handling
**Decision:** Fixed limits per category (e.g., Max 5) with a "See all results" overflow action.
**Rationale:**
- **Predictability & DX:** Fixed limits make parallel Ecto queries fast and keep the UI predictable. Grouping results strictly by domain avoids the "shifting UI" problem of global relevance scoring.
- **Keyboard UX:** Infinite scroll breaks predictable `ArrowDown` navigation. Following Raycast/Linear, if a category hits its limit of 5, a 6th actionable list item is rendered: `Search all matching [Category] ↵`, which routes the user to the dedicated index view (e.g., `/admin/customers?q=term`).

## 6. Debounce & Perceived Latency
**Decision:** Moderate debounce (`phx-debounce="150"`) paired with aggressive optimistic UI loading states via `LiveView.JS`.
**Rationale:**
- **Zero-Latency Feel:** 150ms is the sweet spot for human typing speed. To make it feel instantaneous, we use `phx-change` in tandem with `LiveView.JS` (e.g., `phx-keyup={JS.remove_class("hidden", to: "#loading-spinner")}`) to show a spinner the *millisecond* a key is pressed. The network/DB delay is masked by immediate visual feedback, protecting Postgres from 1-character spam while maintaining native SPA snappiness.

## 7. Empty State Enhancements
**Decision:** Render Static Contextual Quick Actions (Zero-DB queries) + Keyboard shortcuts.
**Rationale:**
- **Instant Value:** Requires zero Ecto queries, meaning the modal opens in 0ms. Context-aware actions (passing `@uri` to the component to offer "Edit this Customer" if on a customer page) transforms it from a search bar into a true navigation accelerator.

## Summary for GSD Planner
The implementation will require:
1. `AccrueAdmin.Components.GlobalSearch` (LiveComponent) executing parallel Ecto queries (limit 5).
2. Updates to `app_shell.ex` to mount the component.
3. `CommandPaletteHook` in `app.js` for keydown interception and active-item management.
4. Optimistic loading states using `LiveView.JS` paired with `phx-debounce="150"`.
5. CSS styling for the modal, input, group headers, empty state quick actions, and `active` state.