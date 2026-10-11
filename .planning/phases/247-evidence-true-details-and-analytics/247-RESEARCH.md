# Phase 247: Evidence-True Details and Analytics - Research

**Researched:** 2026-10-11  
**Domain:** Existing Phoenix LiveView Admin detail pages, browser time/copy interactions, payment recovery analytics  
**Confidence:** HIGH for code ownership and existing contracts; MEDIUM for browser API behavior

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Implementation Decisions

### Time and trustworthy copying
- **D-01:** Default timestamp display to browser-local time with an explicit timezone; shared Local/UTC preference persists consistently across Admin. Before client formatting, server fallback is explicitly UTC. Use existing browser Intl APIs; add no dependency. Date-only values stay dates; analytics query windows remain UTC.
- **D-02:** Clicking or keyboard-activating an actual timestamp copies its exact ISO 8601 UTC instant, including available precision, regardless of display preference. Provide truthful accessible toast/status feedback only after clipboard success; failure offers a usable manual-copy fallback. Preserve 44px touch targets and keyboard focus. Missing timestamps are plain unavailable text, never a pretend copy control.

### Language, destinations and attention
- **D-03:** Match navigation, page names and breadcrumb destinations. Use concrete nouns such as Payments, Invoices, Webhooks and Payment recovery, qualified by actual task context. Collection names should not imply the only purpose is recovery. Breadcrumbs express real parent hierarchy; omit artificial Analytics or Dashboard roots when they are not actual parents. Webhook parent reads Webhooks, never Back to webhooks.
- **D-04:** Reserve semantic attention for demonstrated actionable conditions. Concise status labels have supporting detail nearby when needed. Missing payment method can merit attention; ordinary values need no success decoration. Absence of plan, fee, snapshot or history must not imply misconfiguration, pending work, failure or completion without evidence. Replace Signals/Billing signals with explicit field meanings. Essential explanations stay visible; help is supplemental and keyboard/touch-accessible.

### Detail hierarchy and actions
- **D-05:** Put page identity and concise status in the shared page header; remove redundant inspector eyebrow/card framing where it obscures the actual page. Prioritize observed problem/state and supported next action, then useful metadata, history and payload. Avoid repeating ID/status/timestamp in multiple blocks without investigative value. Exact keys and IDs remain accessible and copyable.
- **D-06:** Replay has one coherent action section with consistent naming and a short truthful explanation of effect and eligibility. Remove DLQ primitive and implementation narration. Preserve action-time authorization, current owner, step-up and confirmations; accepted/queued replay is not completed processing. No business logic weakening or new retry behavior.
- **D-07:** Activity and payload have obvious disclosure affordances and accessible expanded state; retain lazy behavior where it serves a purpose. Important state/actions are visible. Empty history reads as one coherent empty state, with distinct dispatch/billing subhistories only when that distinction helps. Tree/Raw are consistent tabs and Copy is a separate action; retain exact JSON, keyboard support and disclosure behavior.
- **D-08:** Extend shared detail metadata/copy patterns to other existing details and action reviews. A small Copy details action may copy an allowlisted plain-text investigation summary of visible IDs, exact UTC times and observed state. Exclude secrets and full raw payload by default; do not turn this into a new export feature. Owner and permission boundaries apply equally to summaries.

### Payment recovery analytics
- **D-09:** Group comparable metrics by currency and preserve available, actual zero, absent and unsupported currency distinctions. Never fill absent values with zero or invent an amount. Keep recurring monthly revenue definitions distinct from cash recovered and confirmed churn; retain current formulas and qualify their meaning.
- **D-10:** Definitions belong in concise body/help text, not oversized delta pills. Remove duplicated definitions and unsupported Money saved/Churned revenue claims. Align the UTC window selector with shared controls and deliberate spacing. Data coverage is informational, separate from the selected window; a coverage label must not disguise a link to cutoff-semantics documentation. Help must describe its destination.

### Shared implementation and proof
- **D-11:** Refine incumbent components/tokens first. Use Impeccable for critique, hierarchy and visual inspection; its scores or font preferences do not override owner direction. No new dependencies for formatting, clipboard or toasts. Exceptions require a concrete consumer reason. Avoid cosmetic loops after named defects are resolved.
- **D-12:** Bind each objective rule to the cheapest credible existing test owner. Cover local/UTC, exact copying, clipboard failure, missing evidence, authorization and accepted-versus-completed outcomes. Render representative detail/action/analytics pages populated at narrow/wide and light/dark; inspect actual images and served assets. Use one batched review, corrective batch and confirmation, reopen only for demonstrated defects. Do not recapture all Phase 245/246 images without a changed shared concern.

### Agent's Discretion
Exact component composition, concise final copy, placement of one time preference, restrained status tone, and test split are delegated. Choose supported behavior from source rather than inventing explanations. Research unresolved technical facts once and use existing owners.

### Deferred Ideas (OUT OF SCOPE)
- Phase 248 owns reproducible scenario selection outside production UI and integrated proof across the milestone.
- New billing actions, product scenario controls, broad data-model changes and unrelated font/redesign suggestions remain out of scope.
- Remote publishing/tagging is not authorized; keep GSD tags local. Original Phase 243 preview is protected.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TIME-01 | Operators can read timestamps in a clearly identified local timezone and copy an exact UTC value with keyboard/touch access and truthful success/failure feedback; any display preference is shared rather than repeated per row. | Existing timestamps and copy hooks are enumerated below; official Intl/Clipboard guidance and current mounted clipboard proof provide implementation and verification seams. |
| LANG-02 | Operators encounter consistent concrete destination names, headings, breadcrumb labels and task-specific help, with contextual navigation justified by the record or investigation task. | Shared Breadcrumbs, AppShell navigation and Copy modules are the presentation owners; route/scope contract tests protect destinations. |
| STATE-02 | Operators see restrained semantic attention/status presentation tied to actual evidence and useful next steps; missing history, fee fields, plan data or snapshots never imply unsupported success, failure, pending work or misconfiguration. | Existing state-aware copy, unavailable/empty tests and webhook history behavior establish truthful-state owners. |
| DETAIL-01 | Operators can understand webhook identity, observed processing state and replay availability in a deliberate hierarchy, with explicit disclosures, coherent empty histories and readable payload controls preserving exact evidence. | WebhookLive, Detail, JsonViewer and webhook LiveView/replay tests already own these contracts. |
| DETAIL-02 | Operators can investigate existing detail pages and action reviews with shared readable metadata/copy conventions while authorization, ownership, confirmation, step-up and accepted-versus-completed boundaries remain intact. | Detail components, existing clipboard controls, scoped-path tests and webhook replay tests cover the shared and protected seams. |
| METRIC-01 | Operators can compare recovery metrics by currency without prose masquerading as deltas, duplicated definitions or misleading cash/churn claims; coverage dates and UTC windows are distinct from explicitly named help. | RecoveryLive and Dunning query tests already preserve per-currency, zero/absent/unsupported, owner-scope and UTC window behavior. |
</phase_requirements>

## Summary

Phase 247 is an existing-UI refinement with no package installation or query redesign. The best implementation seam is shared Admin presentation code: AppShell and browser JS for a single time preference, a reusable timestamp display/copy pattern, existing `Detail`/`Breadcrumbs`/`JsonViewer` for investigation hierarchy, and `KpiCard`/`WindowSelector` plus recovery copy for analytics. [VERIFIED: `accrue_admin/lib/accrue_admin/components/app_shell.ex:21-27`; `accrue_admin/lib/accrue_admin/components/detail.ex:1-18`; `accrue_admin/lib/accrue_admin/components/breadcrumbs.ex:1-14`; `accrue_admin/lib/accrue_admin/components/json_viewer.ex:1-16`; `accrue_admin/lib/accrue_admin/components/kpi_card.ex:1-20`; `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:145-169`]

The current clipboard hook only sets `data-copied` after a resolved clipboard write; missing API returns silently and rejected writes are unhandled. Keep the displayed timestamp and copied value separate: browser formatting may use `Date`, which cannot retain all source precision, so the copy payload must remain the original exact UTC ISO string. Official browser documentation confirms `writeText()` resolves only after updating the system clipboard, can be unavailable outside secure contexts, and rejects when disallowed. [VERIFIED: `accrue_admin/assets/js/hooks/clipboard.js:6-18`; `accrue_admin/assets/js/hooks/clipboard.js:21-40`; Cited: MDN Clipboard `writeText()`](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText)

Recovery already queries asynchronously using owner scope and UTC bounds, and retains separate currency groups. Preserve these outputs and formulas; change only presentation and copy. Tests already distinguish an empty authorized owner scope (no default-currency totals) from a missing/unsupported currency amount, and separately test supported currency values. [VERIFIED: `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:27-48`; `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:74-82`; `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs:647-688`]

**Primary recommendation:** Put the one persistent Local/UTC display control in the shared shell, implement timestamp rendering and exact-copy behavior through one incumbent browser/LiveView seam, and improve webhook/analytics presentation at existing component and Copy owners while preserving the current action and query implementations. [VERIFIED: `accrue_admin/lib/accrue_admin/components/app_shell.ex:21-27`; `accrue_admin/assets/js/app.js:1-20`; `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:27-48`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Timestamp display preference, timezone label and formatting | Browser / Client | Frontend Server (SSR) | Browser `Intl.DateTimeFormat` can resolve the runtime timezone; server output provides the required UTC fallback before the client formats. [Cited: [MDN `resolvedOptions()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat/resolvedOptions); Verified: `accrue_admin/lib/accrue_admin/components/app_shell.ex:21-27`] |
| Exact timestamp and metadata copying | Browser / Client | Frontend Server (SSR) | Clipboard writes require browser user activation and success is known only when the promise resolves; the server supplies the exact value in the control. [Cited: [MDN `writeText()`](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText); Verified: `accrue_admin/assets/js/hooks/clipboard.js:6-18`] |
| Detail language, hierarchy and navigation | Frontend Server (SSR) | Browser / Client | LiveViews produce page labels, breadcrumbs, summaries and action eligibility; client code supplies disclosure/copy interactions. [Verified: `accrue_admin/lib/accrue_admin/live/webhook_live.ex:202-265`; `accrue_admin/lib/accrue_admin/components/detail.ex:1-18`] |
| Recovery analytics values, owner scoping and UTC window | API / Backend | Frontend Server (SSR) | Existing Dunning query owns calculations; RecoveryLive passes current owner scope and UTC bounds into that query. [Verified: `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:27-48`; `accrue_admin/lib/accrue_admin/queries/dunning.ex:45-71`] |
| Recovery metric grouping and currency-state rendering | Frontend Server (SSR) | Browser / Client | RecoveryLive pairs the query result by currency and renders cards; browser is not a calculation owner. [Verified: `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:74-113`; `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:171-188`] |

## Standard Stack

### Core

| Library / platform | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Phoenix LiveView | Existing project target: Elixir `1.19+`, Phoenix `1.8+`, LiveView `1.0+` | Existing server-rendered Admin and mounted UI behavior | Project constraints already set these targets; this phase needs only incumbent components, LiveView hooks and tests. [VERIFIED: `CLAUDE.md` lines 12-16, including “Elixir 1.19+”, “Phoenix 1.8+”, and “LiveView 1.0+”] |
| Browser `Intl.DateTimeFormat` | Native browser API | Format instants in the browser's local timezone and expose the resolved zone for labeling | MDN documents `resolvedOptions().timeZone` as the runtime timezone when no explicit zone was requested. [Cited: [MDN `resolvedOptions()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat/resolvedOptions)] |
| Browser Clipboard API | Native browser API | Copy exact ISO strings and investigation summaries | `writeText()` returns a promise that resolves after the clipboard updates; handle missing API and rejected promises as failure. [Cited: [MDN `writeText()`](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText)] |

### Supporting

| Existing owner | Purpose | When to use |
|------------|---------|-------------|
| `AccrueAdmin.Components.Detail` | Shared section, field-list, summary-list and summary-header composition | Existing detail screens and action reviews. [VERIFIED: `accrue_admin/lib/accrue_admin/components/detail.ex:1-18`] |
| `AccrueAdmin.Components.Breadcrumbs` and `AccrueAdmin.Nav` via `AppShell` | Breadcrumb and destination labels | Keep headings, links and navigation aligned. [VERIFIED: `accrue_admin/lib/accrue_admin/components/breadcrumbs.ex:1-14`; `accrue_admin/lib/accrue_admin/components/app_shell.ex:8-27`] |
| `AccrueAdmin.Components.JsonViewer` | Escaped tree/raw/copy payload display | Preserve exact JSON while clarifying tabs and disclosure controls. [VERIFIED: `accrue_admin/lib/accrue_admin/components/json_viewer.ex:1-16`; `accrue_admin/lib/accrue_admin/components/json_viewer.ex:29-69`] |
| `AccrueAdmin.Components.KpiCard` and `WindowSelector` | Recovery metric and UTC-window display | Put definitions in body/meta copy and keep selected window semantics clear. [VERIFIED: `accrue_admin/lib/accrue_admin/components/kpi_card.ex:10-20`; `accrue_admin/lib/accrue_admin/components/window_selector.ex:24-45`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing browser APIs and shared hook | New formatting or clipboard dependency | Prohibited by D-11 and adds install/runtime surface with no identified consumer need. [VERIFIED: `.planning/phases/247-evidence-true-details-and-analytics/247-CONTEXT.md` D-11] |
| Central shell preference | Repeated per-row or per-page selectors | Duplicates state and breaks the shared preference contract. [VERIFIED: `247-CONTEXT.md` D-01] |
| Existing query result grouping | Recalculate or combine money in presentation | Risks changing billing formulas, currency meaning and distinctions between absent, zero and unsupported data. [VERIFIED: `247-CONTEXT.md` D-09; `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:74-113`] |

**Installation:** None. No new packages are in scope. [VERIFIED: `247-CONTEXT.md` D-11]

## Architecture Patterns

### System Architecture Diagram

```text
Existing LiveView detail / analytics route
        │
        ├── Detail route ──> owner-scoped reads + current eligibility/action logic
        │                         │
        │                         └── shared Detail / Breadcrumbs / JsonViewer
        │                                    │
        │                                    └── timestamp display + exact-copy control
        │
        └── Recovery route ──> parse existing UTC window + current owner scope
                                  │
                                  └── existing Dunning queries (unchanged formulas)
                                             │
                                             └── currency/state pair rendering

AppShell ──> shared Local/UTC preference ──> client Intl formatting
                         │                         └── UTC server-rendered fallback
                         └── persistent preference across Admin routes
```

The diagram reflects the existing route, async query, shell and component ownership; preserve the query/action paths and insert presentation behavior at the shared boundary. [VERIFIED: `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:27-48`; `accrue_admin/lib/accrue_admin/components/app_shell.ex:21-27`; `accrue_admin/lib/accrue_admin/live/webhook_live.ex:228-265`]

### Recommended Project Structure

```text
accrue_admin/
├── lib/accrue_admin/components/       # shared time/detail/navigation/metric controls
├── lib/accrue_admin/live/             # consumer page composition; preserve actions and query calls
├── lib/accrue_admin/copy/             # evidence-backed labels, empty/unavailable/help copy
├── assets/js/hooks/                   # clipboard and browser time preference lifecycle
├── test/accrue_admin/live/            # LiveView state, scope, copy payload and action contracts
├── test/accrue_admin/components/      # shared component markup/accessibility contracts
├── test/js/                           # clipboard/local-format helper lifecycle and failures
└── e2e/                               # mounted behavior, geometry and rendered proof
```

This follows existing package ownership and the current split between Elixir LiveView tests, Node-based hook tests, and Playwright proof. [VERIFIED: `accrue_admin/package.json:1-18`; `accrue_admin/test/js/`; `examples/accrue_host/e2e/phase246-current-proof.spec.js:1-30`]

### Pattern 1: Keep exact timestamp data separate from display text

**What:** Render a UTC server fallback for the exact `%DateTime{}` and retain the original ISO string as the copy payload. Let the browser change only display text according to the shared preference. Never copy a value reconstructed from a localized string or `Date`. [VERIFIED: `accrue_admin/lib/accrue_admin/live/event_live.ex:447-448`; `247-CONTEXT.md` D-01/D-02]

**When to use:** Every existing `%DateTime{}` shown as a date-time in Admin. Keep `%Date{}`/date-only labels in date formatting paths. [VERIFIED: `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:450-464`; `247-CONTEXT.md` D-01]

**Example:**

```js
const browserTimeZone = new Intl.DateTimeFormat().resolvedOptions().timeZone;
const localFormatter = new Intl.DateTimeFormat(undefined, {
  dateStyle: "medium",
  timeStyle: "medium",
  timeZone: browserTimeZone
});
const visibleLabel = localFormatter.format(new Date(originalIsoInstant));
// Keep originalIsoInstant unchanged for the UTC copy payload.
```

The API calls are documented by MDN; retaining the raw string is required because the copied value must keep the source's available precision. [Cited: [MDN Intl `resolvedOptions()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat/resolvedOptions); [MDN `DateTimeFormat`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat); `247-CONTEXT.md` D-02]

### Pattern 2: One clipboard operation owns all feedback

**What:** Reuse the existing `Clipboard` hook and initializer but route timestamp, ID, JSON and summary copy through one operation that announces success only after `writeText` resolves. On missing API or rejection, expose a selectable manual-copy field and an accessible failure message; do not set a success marker or toast. [VERIFIED: `accrue_admin/assets/js/hooks/clipboard.js:6-40`; Cited: [MDN Clipboard `writeText()`](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText)]

**When to use:** Every visible copy button and timestamp affordance. Existing `IdBadge` and `JsonViewer` already provide the relevant button ownership. [VERIFIED: `accrue_admin/lib/accrue_admin/components/id_badge.ex:1-45`; `accrue_admin/lib/accrue_admin/components/json_viewer.ex:49-69`]

### Pattern 3: Model recovery card states from existing values

**What:** Keep one comparable recovered/exhausted pair per currency. For a currency with no row on one side, render “Amount unavailable” per the current helper rather than substituting zero; render an explicit zero only when the query provides a zero amount. Keep `currency: nil`/unsupported currency visually distinct from an empty result set. [VERIFIED: `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:74-113`; `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs:647-688`]

**When to use:** Recovery metric cards only; the Dunning queries and existing UTC window selection remain unchanged. [VERIFIED: `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:27-48`; `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:227-246`]

### Pattern 4: Preserve server-rendered copy and LiveView remounts

**What:** Use the existing AppShell/browser initializer for a preference that survives route navigation and server patches. Format timestamps at mount/update as needed, and ensure replacement nodes still receive behavior. `phx-hook` mounted/updated lifecycle and static DOM binding have different update behavior. [Cited: [Phoenix LiveView JS interoperability](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook); Verified: `accrue_admin/assets/js/app.js:1-20`; `accrue_admin/assets/js/hooks/clipboard.js:1-5`]

**When to use:** On each Admin page carrying timestamps and the single shared preference control. Avoid one listener per row if a delegated handler or mounted hook can cover re-rendered nodes. [VERIFIED: `accrue_admin/assets/js/hooks/accrue_theme.js:1-8`; `accrue_admin/assets/js/hooks/accrue_theme.js:40-80`]

### Anti-Patterns to Avoid

- **Format once on the server and claim the result is local time:** no browser zone is available there; use explicit UTC fallback until browser formatting runs. [VERIFIED: `247-CONTEXT.md` D-01]
- **Round-trip a timestamp through `Date` and copy that result:** this can discard precision available in the ISO string; copy the original UTC value. [VERIFIED: `247-CONTEXT.md` D-02; Cited: [MDN Clipboard `writeText()`](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText)]
- **Announce copy before the promise resolves or ignore rejection:** the current hook silently returns when unavailable and does not catch failures. [VERIFIED: `accrue_admin/assets/js/hooks/clipboard.js:11-16`; Cited: [MDN Clipboard `writeText()`](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText)]
- **Treat absent rows or null currency as zero:** tests explicitly require no invented default-currency totals and an unavailable amount for unsupported currency. [VERIFIED: `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs:647-688`]
- **Use empty history as a positive conclusion or replay acceptance as completed processing:** preserve the current unavailable, eligibility, ownership, step-up and replay outcome contracts. [VERIFIED: `accrue_admin/test/accrue_admin/live/webhook_live_test.exs:237-252`; `accrue_admin/test/accrue_admin/live/webhook_live_test.exs:425-470`; `.planning/phases/247-evidence-true-details-and-analytics/247-CONTEXT.md` D-06]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Timezone conversion/locale display | Custom offset/DST math | Native `Intl.DateTimeFormat` | Runtime supplies timezone rules and locale formatting. [Cited: [MDN Intl `DateTimeFormat`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat)] |
| Clipboard copy | Hidden custom clipboard transport or optimistic success indicator | Existing browser Clipboard API and shared hook, with manual fallback | API already owns asynchronous success/failure; UI must report that outcome. [Cited: [MDN Clipboard `writeText()`](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText); Verified: `accrue_admin/assets/js/hooks/clipboard.js:6-40`] |
| Detail metadata hierarchy | Page-local duplicated label/value markup | Existing `Detail` primitives | Keeps detail headers, field lists and actions coherent across consumers. [VERIFIED: `accrue_admin/lib/accrue_admin/components/detail.ex:1-18`] |
| Recovery currency aggregation | UI-side amount conversion or arithmetic | Existing `AccrueAdmin.Queries.Dunning` output and `RecoveryLive.recovery_kpi_pairs/1` | Query semantics and currency distinctions belong to current query result owner. [VERIFIED: `accrue_admin/lib/accrue_admin/queries/dunning.ex:45-71`; `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:74-113`] |

**Key insight:** The requirement is chiefly about making existing evidence easier to read and copy. Preserve each underlying instant, event status, query result and action contract; centralize only presentation behavior. [VERIFIED: `247-CONTEXT.md` D-01–D-12]

## Existing Owners and Consumers

### Timestamp display consumers

The current date-time display is repeated in `dashboard_live.ex`, `charges_live.ex`, `connect_account_live.ex`, `connect_accounts_live.ex`, `coupon_live.ex`, `coupons_live.ex`, `customer_live.ex`, `event_live.ex`, `events_live.ex`, `invoice_live.ex`, `invoices_live.ex`, `promotion_code_live.ex`, `promotion_codes_live.ex`, `subscription_live.ex`, `subscriptions_live.ex`, `webhook_live.ex`, `webhooks_live.ex`, `analytics/campaign_live.ex`, `components/at_risk_table.ex`, and `components/campaign_timeline.ex`. `subscriptions_live.ex` also has date-only formatting; `filter_chip_bar.ex` serializes date/date-time criteria. These were enumerated by opening and searching the current formatters, so the plan should distinguish date-only values and prioritize the shared timestamp component rather than indiscriminately changing date labels. [VERIFIED: `accrue_admin/lib/accrue_admin/live/dashboard_live.ex:122-125`; `accrue_admin/lib/accrue_admin/live/webhook_live.ex:924-925`; `accrue_admin/lib/accrue_admin/components/at_risk_table.ex:266-270`; `accrue_admin/lib/accrue_admin/components/campaign_timeline.ex:103-107`; `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex:137-138`; `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:450-464`]

The API preference lifecycle has a relevant in-repo model: `accrue_theme.js` reads/writes `localStorage`, cookies and synchronizes controls after LiveView replacement. Its current exact allowed values are `"light", "dark", "system"`; this is a pattern reference only, and the time preference must define its own `Local`/`UTC` choice from D-01. [VERIFIED: `accrue_admin/assets/js/hooks/accrue_theme.js:1-8` — verbatim: `export const ALLOWED_THEMES = new Set(["light", "dark", "system"]);`; `247-CONTEXT.md` D-01]

**Preference storage/fallback decision for the planner:** Reuse the shell-level lifecycle and persistence convention, with UTC server-rendered fallback and one shared client preference. The context does not lock whether time preference should use `localStorage`, cookie, or both, or the persistence lifetime; follow the existing theme pattern if its SSR/anti-FOUC behavior fits. Treat storage-disabled/private browsing behavior as a required failure case: use a safe in-memory default for the current page/session and retain explicit UTC fallback if preference reading fails. The lifetime/fallback policy is the one unresolved product detail; the plan can choose the smallest consistent behavior, with no auth or user-record mutation. [VERIFIED: `accrue_admin/assets/js/hooks/accrue_theme.js:1-8`; `accrue_admin/assets/js/hooks/accrue_theme.js:72-80`; `247-CONTEXT.md` D-01] [ASSUMED: localStorage can be unavailable or throw in some browser privacy modes; verify behavior in the target browser test or use safe try/catch]

### Clipboard and detail owners

`assets/js/hooks/clipboard.js` owns both dynamically-mounted `Clipboard` hook controls and the first-paint `[data-clipboard-text]` initializer. Current success representation is `data-copied="true"`; neither path has rejection handling or failure feedback. Timestamp copying should plug into this behavior once, rather than add another clipboard implementation. [VERIFIED: `accrue_admin/assets/js/hooks/clipboard.js:6-40` — verbatim: `if (!navigator.clipboard?.writeText) { return; }`, `await navigator.clipboard.writeText(text);`, `this.el.dataset.copied = "true"`; and initializer lines 29-37]

Detail reuse points are `components/detail.ex` (summary header/list/field list), `components/breadcrumbs.ex`, `components/json_viewer.ex`, `components/id_badge.ex`, `components/page_header.ex`, and `components/flash_group.ex`. `webhook_live.ex` currently owns page hierarchy, replay availability, history and action rendering; retain LiveView event handlers and authorization checks when moving markup. The webhook parent currently has breadcrumb labels `"Dashboard"`, `@return_destination.label`, and `breadcrumb_label(assigns)` at the rendered call site; only change labels/routes via existing navigation/copy owner contracts. [VERIFIED: `accrue_admin/lib/accrue_admin/live/webhook_live.ex:202-252`; `accrue_admin/lib/accrue_admin/components/detail.ex:1-18`; `accrue_admin/lib/accrue_admin/components/json_viewer.ex:29-69`]

### Recovery analytics owner and state inventory

`RecoveryLive.handle_params/3` parses the existing selector values and computes bounds via `Accrue.Clock.utc_now()`. The valid window values are `"7d"`, `"30d"`, `"90d"`, with invalid values defaulting to `"30d"`; the selector currently renders labels `"7 days"`, `"30 days"`, `"90 days"` and `" UTC"`. These values are quoted verbatim from the opened source. [VERIFIED: `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:227-246` — verbatim: `defp parse_window(w) when w in ["7d", "30d", "90d"], do: w`; `defp parse_window(_), do: "30d"`; `@windows [{"7d", "7 days"}, {"30d", "30 days"}, {"90d", "90 days"}]`; `aria-label="Time window (UTC)"`; `<%= label %> UTC` in `accrue_admin/lib/accrue_admin/components/window_selector.ex:19-45`]

Observed test states to preserve are:

| State | Current contract | Evidence |
|-------|-----------------|----------|
| Empty authorized owner scope | “No active dunning campaigns”; no default-currency recovered/exhausted card | `recovery_live_test.exs` lines 647-664 |
| Unsupported/missing currency on one observed row | Supported USD remains exact; unavailable-currency pair says `"Amount unavailable"`; absent currency must not be recast as USD | `recovery_live_test.exs` lines 667-688 |
| A currency present on one side only | Other-side amount is “Amount unavailable”, per current formatting helper | `recovery_live.ex` lines 96-113 |
| Actual zero | Preserve zero if returned by query; never coerce missing `nil` to zero | Query result types allow `cents: non_neg_integer() | nil`; verify with targeted metric tests when implementing. [VERIFIED: `accrue_admin/lib/accrue_admin/queries/dunning.ex:45-52`] |
| Async query failure | Render recoverable error state and avoid presenting it as a valid empty query | `recovery_live.ex` lines 63-71 and `recovery_live_test.exs` test “failed recovery read remains a recoverable error rather than an empty result” |
| Loading | Selected UTC window and owner scope remain visible until scoped reads finish | `recovery_live_test.exs` test “loading state keeps the selected owner and UTC window until scoped reads finish” |

The current recovery copy defines labels `"Recovered MRR (...)"` and `"Exhausted MRR (...)"`, but also supplies delta/meta claims `"Amount saved by successful Dunning"`, `"Money Saved"`, and `"Churned Revenue"`. Remove unsupported or duplicated presentation copy without renaming the underlying existing metrics or changing formulas. [VERIFIED: `accrue_admin/lib/accrue_admin/copy.ex:982-998` — verbatim: `def recovery_recovered_mrr_delta, do: "Amount saved by successful Dunning"`; `def recovery_recovered_mrr_meta, do: "Money Saved"`; `def recovery_exhausted_mrr_meta, do: "Churned Revenue"`]

## Common Pitfalls

### Pitfall 1: Precision loss hidden by localized display

**What goes wrong:** The operator sees a local display but copies a value with lower precision or non-UTC formatting.  
**Why it happens:** Display and payload get derived from a JavaScript `Date` or formatted label instead of the original server timestamp.  
**How to avoid:** Keep the server ISO value as an immutable copy payload; format only the visible text. Test an instant with fractional seconds/microseconds and assert copied value byte-for-byte. D-02 requires available precision. [VERIFIED: `247-CONTEXT.md` D-02]  
**Warning signs:** Copy output differs from the `data-clipboard-text` value or strips trailing fractional digits.

### Pitfall 2: SSR and browser preference disagree after navigation

**What goes wrong:** A page starts in UTC, flips unexpectedly, or one LiveView route keeps stale formatting after a patch.  
**Why it happens:** Local preference has no shared initializer or new nodes are not formatted after LiveView DOM changes. Official LiveView docs distinguish hook lifecycle callbacks for server-added/updated/removed elements. [Cited: [Phoenix LiveView JS interop](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook)]  
**How to avoid:** Keep UTC fallback; initialize one shell-level preference and cover mount, navigation, patch and remount paths; test browser reload and storage failure.  
**Warning signs:** Mixed local/UTC timestamps on one page or a preference selector whose state disagrees with rendered values.

### Pitfall 3: False clipboard success

**What goes wrong:** UI says “Copied” despite no clipboard write.  
**Why it happens:** The API is missing or its promise rejects; current code returns silently in the first case and has no catch in either path. [VERIFIED: `accrue_admin/assets/js/hooks/clipboard.js:11-16`; `accrue_admin/assets/js/hooks/clipboard.js:32-37`]  
**How to avoid:** Success follows awaited resolve only; rejection and absent API expose accessible manual-copy fallback. [Cited: [MDN Clipboard `writeText()`](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText)]  
**Warning signs:** `data-copied` is set before resolution or remains set after a failed subsequent attempt.

### Pitfall 4: Missing values become status assertions

**What goes wrong:** Empty history reads as successful/no-action-needed, or missing metric evidence reads as zero, pending work, money saved or confirmed churn.  
**Why it happens:** Empty, unavailable, unsupported and actual-zero states are collapsed into one UI string or semantic color.  
**How to avoid:** Preserve the tested distinctions and use field-specific labels; do not mutate state logic. [VERIFIED: `recovery_live_test.exs:647-688`; `webhook_live_test.exs:237-252`; `webhook_live_test.exs:425-470`; `247-CONTEXT.md` D-04/D-09]  
**Warning signs:** `nil` replaced by `0`, global reassurance generated from local empty history, or “accepted” rendered as “processed.”

### Pitfall 5: Copying detail summaries widens data exposure

**What goes wrong:** A convenience “Copy details” button includes raw payload, secrets or out-of-scope records.  
**Why it happens:** Summary builder copies the full DOM or payload instead of an explicit allowlist.  
**How to avoid:** Build a plain-text allowlist from visible IDs, UTC timestamps and observed state; keep payload copy a separate explicit action. Preserve current owner and permission scope. [VERIFIED: `247-CONTEXT.md` D-08; `accrue_admin/lib/accrue_admin/live/webhook_live.ex:63-115`]  
**Warning signs:** Summary changes when hidden payload expands or includes credential-like field names.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit through Mix; Node built-in test runner for isolated browser hook tests; Playwright for mounted browser proof. [VERIFIED: `accrue_admin/package.json:1-18`; files under `accrue_admin/test/js/`] |
| Config file | `accrue_admin/package.json`; package Mix test configuration. [VERIFIED: opened package manifest] |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs:647 test/accrue_admin/live/webhook_live_test.exs:237` (focused empty/availability states; add direct cases at owner test lines as implementation lands). |
| JS hook command | `cd accrue_admin && node --test test/js/clipboard_test.mjs` (add focused test owner for clipboard success, absent API, rejection/manual fallback, duplicate mount and exact timestamp payload). |
| Full Admin suite | `cd accrue_admin && mix test --warnings-as-errors` (project CI command; run at the phase gate, not per task). [VERIFIED: `.github/workflows/ci.yml:683`] |
| Mounted browser command | `cd examples/accrue_host && npm run e2e -- --project=chromium-desktop --workers=1` after adding a dedicated phase-247 proof spec to the Playwright config. Existing package script is `"e2e": "env -u NO_COLOR playwright test"`. [VERIFIED: `examples/accrue_host/package.json:1-18`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Existing owner / gap |
|--------|----------|-----------|-------------------|----------------------|
| TIME-01 | Local and UTC display, explicit zone, persisted shared preference across routes, UTC SSR fallback, date-only stability | Node unit + mounted browser | `cd accrue_admin && node --test test/js/time_display_test.mjs`; mounted proof spec | Add Node helper tests; cover preference reload/navigation and timezone label in Phase 247 proof. |
| TIME-01 | Timestamp click/keyboard copies exact UTC ISO, including available fractional precision; missing time has no copy affordance; resolve/reject accurately announced | Node unit + Playwright | `cd accrue_admin && node --test test/js/clipboard_test.mjs`; mounted proof | Extend hook unit owner and phase proof; existing list proof only covers ID copy and `data-copied` feedback. [VERIFIED: `examples/accrue_host/e2e/phase246-current-proof.spec.js:78-110`] |
| LANG-02 | Detail title, breadcrumb, destination and link labels match actual navigation/return path | ExUnit LiveView | `cd accrue_admin && mix test test/accrue_admin/scoped_path_test.exs test/accrue_admin/live/webhook_live_test.exs` | Existing scoped path and webhook tests; include Recovery breadcrumb/nav assertions in analytics test. |
| STATE-02 | Empty, unavailable, absent and actionable state wording remain evidence-backed | ExUnit LiveView | `cd accrue_admin && mix test test/accrue_admin/copy_test.exs test/accrue_admin/live/webhook_live_test.exs:237 test/accrue_admin/live/analytics/recovery_live_test.exs:647` | Existing copy, empty-history, unavailable-read and empty-owner tests; add fee/snapshot consumer assertions only where the phase actually changes those displays. |
| DETAIL-01 | Webhook identity/state/replay hierarchy, disclosure affordance, combined empty history, raw/tree/copy controls | ExUnit LiveView + Playwright | `cd accrue_admin && mix test test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhook_replay_test.exs`; mounted browser proof | Existing owners cover empty histories, unavailable reads and accepted-but-not-completed replay; mounted proof adds keyboard and disclosure interaction. |
| DETAIL-02 | Shared metadata and copy summaries preserve owner scope, auth, confirmation, step-up and accepted-vs-completed | ExUnit + mounted browser | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/scoped_path_test.exs` | Existing replay and path guards; add explicit summary allowlist and exact UTC copy assertions. |
| METRIC-01 | Per-currency pairs distinguish zero/absent/unsupported; definitions and coverage/help are accurate; UTC selector is unchanged | ExUnit LiveView | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | Existing recovery suite includes selected windows, scope, empty owner and unsupported currency. Add actual-zero and rendered copy assertions if not currently present. |

### Sampling Rate

- **Per task:** The focused ExUnit line targets or the Node hook/time helper tests above.
- **Per wave:** Run all affected LiveView/component tests plus one mounted browser pass across representative webhook detail, one existing detail/action review, and recovery analytics.
- **Phase gate:** `cd accrue_admin && mix test --warnings-as-errors`; run the phase-247 mounted proof validator against captures bound to the tested revision and served asset digests.

### Rendered Proof and Browser Environment

Use the ordinary mounted preview host `http://accrue-host-phase245-ordinary.localhost`. The existing held-out browser port `4101` is occupied; use `4102` for this phase's isolated held-out lane. Local Fake login is authorized only for this browser run; keep the credential out of captures, manifests, logs and research artifacts. Original Phase 243 preview is protected. [VERIFIED: Phase 247 orchestration input]

Capture representative populated webhook detail, action/confirmation state, and recovery analytics at narrow and wide viewports in light and dark themes. Bind manifest rows to exact source SHA and CSS/JS served asset digests. Record viewport dimensions separately from full-page PNG height: fullPage output height is content extent and cannot stand in for viewport. Inspect actual images and verify served assets after the corrective batch; do not recapture Phase 245/246 baselines absent a changed shared concern. Phase 246's current proof used the validator `node scripts/ci/verify_phase246_render_proof.mjs --manifest .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/manifest.json`; this remains historical completed proof and must not be rerun as Phase 247 acceptance. [VERIFIED: `.planning/phases/246-collection-controls-and-search/246-VERIFICATION.md:127-157`; `examples/accrue_host/e2e/phase246-current-proof.spec.js:17-30`]

### Wave 0 Gaps

- [ ] Add pure Node tests for one shared browser time formatter and storage failure/lifecycle behavior if no existing time helper test owner exists.
- [ ] Add clipboard hook tests for missing API and rejection/manual fallback; current automated mounted proof covers successful ID copying only, not timestamp precision or failure feedback. [VERIFIED: `examples/accrue_host/e2e/phase246-current-proof.spec.js:78-110`; `accrue_admin/assets/js/hooks/clipboard.js:6-40`]
- [ ] Add one phase-247 Playwright proof spec with exact SHA/served asset digests and representative detail/analytics captures; Phase 248 owns integrated scenario selection/proof. [VERIFIED: `247-CONTEXT.md` Deferred Ideas; `.planning/phases/246-collection-controls-and-search/246-VERIFICATION.md:96-108`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep the existing authenticated LiveView mount and action-time authorization checks; presentation changes must not create an alternate path. [VERIFIED: `accrue_admin/lib/accrue_admin/live/webhook_live.ex:63-115`] |
| V3 Session Management | yes | No session or auth-token persistence changes; local time preference is presentation state only. [VERIFIED: `247-CONTEXT.md` D-01/D-06] |
| V4 Access Control | yes | Detail summaries and links must derive from the same current owner scope and permission checks as their source details/actions. [VERIFIED: `accrue_admin/lib/accrue_admin/live/webhook_live.ex:63-115`; `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs:690-708`] |
| V5 Input Validation | yes | Allowlist summary fields; escape labels/values through HEEx and retain route/query validation. [VERIFIED: `accrue_admin/lib/accrue_admin/components/json_viewer.ex:29-69`; `accrue_admin/test/accrue_admin/scoped_path_test.exs:57-103`] |
| V6 Cryptography | no | No cryptographic operation is added; clipboard strings contain only the explicitly allowed visible metadata and exact timestamp. [VERIFIED: `247-CONTEXT.md` D-08] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| “Copy details” includes secrets or raw payload beyond operator-visible allowlist | Information disclosure | Build an explicit allowlist; keep full payload under the existing separate payload-copy action. [VERIFIED: `247-CONTEXT.md` D-08] |
| Label/link refactor weakens owner scope or replay revalidation | Elevation of privilege / tampering | Leave action handler/authorization path unchanged; retain scoped path and replay regression suites. [VERIFIED: `webhook_live.ex:135-162`; `webhook_replay_test.exs`] |
| False clipboard success gives operators incorrect evidence state | Spoofing / repudiation | Announce success only after Clipboard promise resolves; present failure/manual fallback after rejection. [Cited: [MDN Clipboard `writeText()`](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText)] |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | focused and Admin tests | ✓ | Project target Elixir 1.19+; package CI uses Mix | No fallback; if missing in execution environment use normal project CI runner. [VERIFIED: `CLAUDE.md` lines 12-16; `.github/workflows/ci.yml:683`] |
| Node / npm | hook tests and Playwright | ✓ | Node `v22.14.0`; npm `11.1.0` | No fallback for browser-level behavior. [VERIFIED: current read-only version probe] |
| Playwright CLI / Chromium | mounted route proof | ✓ | Admin package Playwright dependency `1.59.1`; Chromium at `/opt/homebrew/bin/chromium` | Existing headed/headless browser runner. [VERIFIED: `accrue_admin/package.json:52-53`; current read-only availability probe] |
| Ordinary preview host | mounted pages | ✓ (per phase execution context) | `http://accrue-host-phase245-ordinary.localhost` | Do not use protected Phase 243 host. [VERIFIED: Phase 247 orchestration input] |
| Held-out browser port | isolated held-out lane | `4101` occupied; `4102` assigned | — | Use `4102`; do not interfere with the existing listener. [VERIFIED: Phase 247 orchestration input] |

**Missing dependencies with no fallback:** None identified for code/test work. The authenticated browser-only proof requires the authorized local Fake login and the named ordinary host. [VERIFIED: Phase 247 orchestration input]

## Project Constraints (from CLAUDE.md)

- Keep the project stack at Elixir 1.19+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, and PostgreSQL 14+; this phase does not require a dependency migration. [VERIFIED: `CLAUDE.md` lines 12-16]
- Preserve the security rules: mandatory webhook signature verification, raw-body plug order, no sensitive Stripe fields in logs, and payment method references rather than PII. [VERIFIED: `CLAUDE.md` lines 19-20]
- Preserve the performance and observability contracts; UI-only work must not change billing entry points, telemetry or webhook request path. [VERIFIED: `CLAUDE.md` lines 21-22]
- Run `mix test --warnings-as-errors` for the Admin package at the phase gate, consistent with CI. [VERIFIED: `.github/workflows/ci.yml:683`]

No `AGENTS.md` was present in the project root or phase directory during discovery. [VERIFIED: project root file search]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Browser storage can be unavailable or throw in privacy modes; safest fallback is a non-persistent in-memory preference for the session and UTC server fallback. | Existing Owners and Consumers | User's preference may appear to reset in restricted browsers; preserve readable UTC timestamps and expose selected mode accurately. |
| A2 | The browser's default timezone is the appropriate “browser-local” timezone rather than a host profile preference. | Standard Stack / Pattern 1 | Display may differ from an operator's intended work timezone if browser/device zone is not their operational zone; D-01 locks browser-local as default. |
| A3 | Existing current UI component and test owners are still the desired source files when planning begins. | All | Source could move before implementation; recheck paths at planning/execution start. |

## Resolved Questions (RESOLVED)

1. **RESOLVED — Preference storage lifetime:** Use an Admin-specific `localStorage` key without an expiry, matching the shell-wide client preference lifecycle already used by the theme control. The default is Local; when storage read or write fails, retain the selected mode in memory for the current page session and render explicit UTC before client formatting. Plan 247-02 owns reload, route-change and storage-failure tests. [VERIFIED: `247-CONTEXT.md` D-01; `accrue_admin/assets/js/hooks/accrue_theme.js:1-8`; `247-02-PLAN.md`]
2. **RESOLVED — Timezone label presentation:** In Local mode, show the resolved IANA zone ID from `Intl.DateTimeFormat().resolvedOptions().timeZone` alongside the formatted date-time; UTC mode and the server fallback explicitly say UTC. Plan 247-01/02 tests the visible zone and mode change. [Cited: [MDN `resolvedOptions()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat/resolvedOptions); `247-01-PLAN.md`; `247-02-PLAN.md`]
3. **RESOLVED — Actual-zero fixture:** Add a deterministic actual-zero result through the existing Dunning/query test seam in `recovery_live_test.exs` and assert that RecoveryLive renders zero distinctly from a missing row, nil amount and unsupported currency. Preserve the production query and formulas. Plan 247-06-01 owns this assertion. [VERIFIED: `recovery_live_test.exs:647-688`; `accrue_admin/lib/accrue_admin/queries/dunning.ex:45-71`; `247-06-PLAN.md`]

## Sources

### Primary (HIGH confidence)

- Phase 247 `247-CONTEXT.md` — locked decisions, phase boundary, exact owner and proof constraints.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` — requirement descriptions, success criteria and completed prior-phase status.
- `CLAUDE.md` — project stack and safety constraints.
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`, `accrue_admin/lib/accrue_admin/queries/dunning.ex`, `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — current query inputs, rendering and state contracts.
- `accrue_admin/assets/js/hooks/clipboard.js`, `accrue_admin/assets/js/hooks/accrue_theme.js`, `accrue_admin/assets/js/app.js` — current client-side copy/preference lifecycle.
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex`, `accrue_admin/lib/accrue_admin/components/detail.ex`, `accrue_admin/lib/accrue_admin/components/json_viewer.ex` — detail and replay owners.
- `.planning/phases/246-collection-controls-and-search/246-VERIFICATION.md` — completed Phase 246 proof scope and limits; not repeated here.

### Secondary (MEDIUM confidence)

- [MDN Clipboard `writeText()`](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText) — promise resolution, secure-context restriction and `NotAllowedError` failure.
- [MDN Intl `resolvedOptions()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat/resolvedOptions) — runtime time zone reporting.
- [MDN `Intl.DateTimeFormat`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat) — native locale/timezone formatting.
- [Phoenix LiveView JavaScript interoperability](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook) — hook lifecycle and DOM patch behavior. Context7 provider was unavailable, so official HexDocs were used directly.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — confirmed from project constraints; no external dependency addition is recommended.
- Architecture: HIGH — shared component, hook, query and LiveView owners were read in source.
- Pitfalls: HIGH for current project state distinctions and clipboard implementation; MEDIUM for browser-specific storage restrictions and timezone presentation details.

**Research date:** 2026-10-11  
**Valid until:** 2026-11-10 for existing project ownership; browser behavior should be rechecked only if browser support targets change.
