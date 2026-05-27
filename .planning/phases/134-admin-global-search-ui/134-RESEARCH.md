# Phase 134: Global Search Architecture Research

**Goal:** Determine the best architectural approach for managing the state and events of a global "CMD+K" search modal in `accrue_admin` (Phoenix LiveView), aligning with the project's zero-sidecar, idiomatic Ecto/Phoenix vision.

## Architectural Approaches for Modal State

We analyzed three primary approaches for where the modal state and event handling should live:

### 1. LiveComponent in AppShell

A stateful `Phoenix.LiveComponent` mounted directly inside the root `app_shell.ex`.

*   **Pros:** 
    *   **Encapsulation:** Search logic (input, results, keyboard nav) is strictly isolated using `phx-target={@myself}`. Host LiveViews (e.g., `PageLive`, `CustomerLive`) remain pristine and unaware of the search modal.
    *   **Resource Efficiency:** Runs within the same Erlang process as the host LiveView. No overhead of a separate process per user tab.
    *   **Shared Mounting:** Trivial to mount once in `app_shell.ex` and have it available on all admin pages.
*   **Cons:** 
    *   Shares the message queue with the host process. If a search query were to take 5 seconds, it would block the host UI (mitigated by fast `pg_trgm` queries).
    *   Requires a JS hook to target global keydown events to the component, as `phx-window-keydown` on a component requires focus.
*   **Tradeoffs:** Prioritizes lower memory usage and strict component encapsulation over strict process isolation.
*   **Ecosystem Examples:** This is the pattern heavily favored by Petal Components and Phoenix core team members for reusable, stateful UI elements like modals and slide-overs.

### 2. Host LiveView State

State and events are managed directly by each host LiveView, often injected via `on_mount` lifecycle hooks and `attach_hook`.

*   **Pros:** 
    *   **Simplicity:** Zero extra components or processes.
    *   **Native Global Events:** Can easily use `phx-window-keydown` directly on the `<body>` or root layout without JS hooks.
*   **Cons:** 
    *   **Pollution:** Injects search assigns (`@search_query`, `@search_results`) and event handlers into every host LiveView's state. 
    *   **Risk of Collisions:** High risk of namespace collisions with host assigns.
    *   **Magic Behavior:** Relying heavily on `on_mount` to magically handle `handle_event("search", ...)` obscures the control flow.
*   **Tradeoffs:** Prioritizes zero-JS simplicity at the severe cost of developer ergonomics (polluted assigns) and structural clarity.
*   **Ecosystem Examples:** Often seen in early LiveView tutorials, but widely abandoned in mature apps due to the "god object" anti-pattern it creates in the host socket.

### 3. Separate LiveView Process

A completely separate LiveView process mounted via `live_render` in the root layout (`root.html.heex` or `app.html.heex`).

*   **Pros:** 
    *   **True Isolation:** The search modal is an entirely separate Erlang process. A slow query will never block the host LiveView.
    *   **Clean Boundary:** Perfect state boundary.
*   **Cons:** 
    *   **Resource Overhead:** Doubles the number of Erlang processes per connected user tab (one for the page, one for the search).
    *   **Communication Complexity:** If the search needs to navigate the user to a new page, it can't just `push_navigate` the host. It must communicate with the host process via PubSub or push an event to the client that triggers navigation.
*   **Tradeoffs:** Prioritizes absolute process isolation at the cost of higher memory overhead and complex cross-process orchestration for navigation.
*   **Ecosystem Examples:** Used for highly independent persistent widgets like a global media player (e.g., Spotify clone) where process isolation is paramount. Overkill for a transient search modal.

---

## One-Shot Recommendation

To achieve the highest standard of software architecture, developer ergonomics, and operator UX, while strictly adhering to Accrue's vision:

### 1. State & Structure: Stateful LiveComponent in AppShell
We will use a **stateful `Phoenix.LiveComponent`** mounted inside `app_shell.ex`.
*   **Why:** It offers perfect logical encapsulation without the heavyweight Erlang process duplication of `live_render`. It prevents polluting the host LiveViews, ensuring great DX for developers building custom admin pages in the future.

### 2. Data Fetching: Parallel Streams (`pg_trgm`)
When a search query is received, the LiveComponent will dispatch **parallel queries using `Task.async_stream`** against the `Accrue.Billing` search functions built in Phase 133.
*   **Why:** Postgres `pg_trgm` is fast, but serializing three network roundtrips (Customers, Invoices, Subscriptions) adds noticeable latency on every keystroke. Parallel execution guarantees the sub-100ms Stripe-like snappiness we demand.
*   **UI Formatting:** The component will map the disparate Ecto structs into a unified, dumb list of maps (e.g., `%{type: :customer, label: name, path: url}`) to keep the Heex template logic simple and focused purely on presentation.

### 3. Keyboard Navigation: Lightweight JS Hook
We will implement a single **Vanilla JS Hook (`phx-hook="CommandPalette"`)** attached to the root of the modal.
*   **Why:** We must avoid heavy sidecars like Alpine.js. LiveView's native `phx-window-keydown` introduces too much network latency for navigating a dropdown list (↑/↓ arrows). 
*   **The Hook's Job:** 
    1. Listen globally for `CMD+K` (or `CTRL+K`) to prevent the browser's default behavior and `pushEventTo` the component to open the modal.
    2. Manage local DOM focus and arrow-key navigation (adding an `.active` class to list items) instantaneously.
    3. Push a `phx-submit` or click event back to the component when `Enter` is pressed on an active item.

**Conclusion:** This architecture is cohesive, idiomatic, and highly performant. It balances Elixir's server-side rendering strengths with just enough client-side JS to ensure a premium, zero-latency command palette experience.