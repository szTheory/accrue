# Phase 7: Admin UI (accrue_admin) - Research

**Researched:** 2026-04-15
**Domain:** Phoenix LiveView admin package architecture for a mountable library
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

All decisions below are locked. Downstream research/planning must not relitigate; consult DISCUSSION-LOG.md for rejected alternatives.

### D7-01 — Library-mount pattern (Phoenix.LiveDashboard-style forward)

**Decision:** `accrue_admin "/billing"` is a router macro that expands to a `scope` containing its own `pipeline` (`:fetch_session`, `:protect_from_forgery`, `AccrueAdmin.CSPPlug`, `AccrueAdmin.BrandPlug`), its own `live_session` with `root_layout: {AccrueAdmin.Layouts, :root}`, and an `on_mount: [{AccrueAdmin.AuthHook, :ensure_admin}]` hook chain that is user-extendable via an `on_mount:` keyword option. Session data crosses into admin LiveViews via a `session: {AccrueAdmin.Router, :__session__, [...]}` callback that extracts host-configured keys.

**Rationale:** Matches Phoenix.LiveDashboard + Oban.Web + Rails Engines + Laravel Horizon + Django admin — the cross-ecosystem convergent pattern for mountable admin UIs. Isolates the admin pipeline from host layout/CSRF/CSP edits. Security blast radius matters for a money-handling UI. `live_session`'s `on_mount` is the only correct place to enforce auth before mount (ADMIN-26). Dev routes gate at compile time inside the macro, not at runtime.

**Day-one install contract:** (1) `{:accrue_admin, "~> 1.0"}` in deps, (2) `import AccrueAdmin.Router` + `accrue_admin "/billing"` in router, (3) `config :accrue, :auth_adapter, MyApp.Auth` (or let Sigra autodetect). Three steps. No host tailwind.config.js edits, no layout edits, no CoreComponents coupling.

**The router macro accepts:** `:on_mount` (append hooks), `:csp_nonce_assign_key` (CSP nonce field), `:session_keys` (which host session keys to thread through), `:allow_live_reload` (test-only).

---

### D7-02 — Asset pipeline: precompiled bundle via compile-time `@external_resource` plug controller

**Decision:** `accrue_admin/assets/` contains a private Tailwind + esbuild build that runs at library-publish time (not at host install time). Output is committed to `accrue_admin/priv/static/accrue_admin.css` and `accrue_admin.js`. An `AccrueAdmin.Assets` plug controller reads these via `File.read!` + `@external_resource` at compile time, computes an MD5 hash, and exposes them at hash-suffixed routes (`/billing/assets/css-<md5>`, `/billing/assets/js-<md5>`) emitted by the router macro. **Not** served via `Plug.Static` from the host — the library owns the route.

**Rationale:** Phoenix.LiveDashboard and Oban.Web both land on this identical pattern (verified by reading their source). Eliminates every failure mode where the host's Tailwind JIT drops library classes in prod. Host never edits their tailwind.config.js. No Node/Rust toolchain required at `mix deps.get` time — the bundle is already in the Hex tarball. CSP-nonce-friendly, cache-forever-safe (MD5-suffixed URLs).

**Tailwind is a private implementation detail of `accrue_admin`.** Internal Tailwind config scans only `accrue_admin/lib/**/*.{ex,heex}`. Components use `@apply`-backed semantic classes (`ax-btn`, `ax-card`) defined in `assets/css/components/`, so the compiled CSS has a stable public-ish contract for hosts wanting to override.

**Build tooling:** `mix accrue_admin.assets.build` task runs `cd assets && npx tailwindcss -i css/app.css -o ../priv/static/accrue_admin.css --minify && npx esbuild js/app.js --bundle --minify --outfile=../priv/static/accrue_admin.js`. Hex package files list includes `priv/static` but **excludes** `assets/`, `node_modules`, `package.json`.

**JS bootstrap:** `accrue_admin.js` bootstraps its own `LiveSocket` scoped to the admin `live_session`, registering `Clipboard`, `CmdK`, `JsonTree`, `Sortable`, `AccrueTheme` hooks internally. Host `app.js` untouched — this is the only idiomatic answer for a mounted admin, matching LiveDashboard and Oban.Web.

**Fonts & icons:** System font stack, no web font. Heroicons inlined via Phoenix 1.8 `<.icon name="hero-..." />` — zero asset implication.

**CI freshness check:** A dedicated CI job compares `priv/static/accrue_admin.css` against a fresh rebuild from source. Fails the build if the committed bundle drifts. Runs only when `accrue_admin/assets/**` or `accrue_admin/lib/**/*.{ex,heex}` changes. Node touches CI only in this one job.

---

### D7-03 — First-party component library (~18 components), no SaladUI/Petal dep

**Decision:** Build all admin components in `accrue_admin/lib/accrue_admin/components/` as pure HEEx function components (and LiveComponents where state is required). No dependency on SaladUI, PetalComponents, or any external component library. No fork of the host's `CoreComponents` (host namespace, can't import).

**Rationale:** CLAUDE.md "ship complete, no v0.x iteration" is the deciding constraint. SaladUI/Petal are pre-1.0 and would couple Accrue v1.0 to their roadmap. Phoenix 1.8 `CoreComponents` ships ~10 components — missing DataTable/Drawer/Timeline/KpiCard/JsonViewer/DropdownMenu/Tabs/Breadcrumbs/CommandPalette/MoneyFormatter. Any reuse path reconstructs half of it anyway. Owning the surface gives us total theming control and zero upgrade risk. Maintenance cost (~18 components) is real but bounded.

**Component inventory (18):**

*Layout & nav:* `AppShell`, `Sidebar`, `Topbar`, `Breadcrumbs`, `CommandPalette` (cmd-K, navigates + actions)

*Data display:* `DataTable` (LiveComponent — streams, URL-synced sort/filter/page, bulk select, card mode on mobile), `DetailDrawer` (right-side sheet desktop, full-screen sheet mobile), `KpiCard` (label + value + delta + sparkline slot), `Timeline` (event ledger + webhook attempt history), `JsonViewer` (collapsible tree with Tree/Raw/Copy tri-tab), `StatusBadge` (semantic palette mapping: Moss=ok, Cobalt=info, Amber=warn/grace, Slate=neutral, Ink=error)

*Inputs & actions:* `Button`, `Input`, `Select`, `DropdownMenu`, `Tabs`, `FilterChipBar` (top chip-style filters, URL-synced)

*Feedback & flow:* `FlashGroup`, `ConfirmDialog`, `StepUpAuthModal`, `MoneyFormatter` (function component wrapping `Accrue.Money.format/2`, locale-aware per Phase 6 D6-03)

**Layout shell:** Adaptive. Desktop (≥1024px) = 240px sidebar + 56px topbar + fluid content + right-slide DetailDrawer. Mobile (<768px) = topbar with hamburger-drawer nav + stacked KPIs + DataTable card mode + full-screen sheet DetailDrawer. Wireframes in advisor research transcript (see DISCUSSION-LOG.md).

**Nav groups:** `Dashboard`, `Customers`, `Subscriptions`, `Invoices`, `Charges`, `Coupons`, `Connect`, `Webhooks`. `Events` (activity feed) lives as a per-customer tab AND a global view. `Dev` group (compile-gated, amber-accented) holds test-clock, email preview, fixtures, component kitchen sink, fake-processor inspector — see D7-07.

**Testability:** Every function component is snapshot-testable via `Phoenix.LiveViewTest.render_component/2`. No external component lib pinning in CI matrix. Every component gets ExDoc moduledoc + a kitchen-sink LiveView at `/billing/dev/components` (dev-only) that doubles as a visual regression target.

---

### D7-04 — Data loading: LiveView streams + cursor pagination + 5s poll banner ("N new rows — click to load")

**Decision:** One `DataTable` LiveComponent powers every list page (customers, subscriptions, invoices, charges, events, webhooks, Connect accounts, coupons, DLQ). All pagination is cursor-based on `(inserted_at DESC, id DESC)` (or `received_at`/`issued_at` for the table's natural time field). Filters URL-synced via `handle_params` + `push_patch`. Real-time updates via in-process `Process.send_after(self(), :poll, 5_000)` polling — **no PubSub auto-insert**. When the poll finds new rows matching the current filter, the banner shows "N new rows — click to load"; click re-enters `handle_params` which resets the cursor and re-queries.

**Rationale:** Three hard constraints collapse the decision: (1) mobile tab-left-open must not drain battery, (2) filters must be deep-linkable and multi-admin-safe, (3) `accrue_events` is append-only with millions of rows — `OFFSET` is a sequential scan. PubSub auto-insert loses on all three (battery drain, phantom rows in filtered views, thundering herd). Polling is a one-line variant of the cold-load query path (`WHERE (inserted_at, id) > ?`), so there's a single code path to maintain. The banner decouples notification from insertion — user stays in control of DOM growth. `stream(:rows, [], reset: true, limit: -500)` caps DOM at 500 rows for hours-long sessions.

**The `AccrueAdmin.Queries.Cursor` module** is the only cursor type in the codebase — opaque base64-encoded `(inserted_at, id)` tuple. Round-trips via `decode/encode`, used by every per-resource query helper.

**Per-resource query helper behaviour (`AccrueAdmin.Queries.Behaviour`):**
```
@callback list(opts :: keyword()) :: {[row], next_cursor :: binary() | nil}
@callback count_newer_than(opts :: keyword()) :: non_neg_integer()
@callback decode_filter(params :: map()) :: filter :: map()
@callback encode_filter(filter :: map()) :: params :: map()
@callback filter_form() :: Phoenix.HTML.Form.t()
```

One module per resource: `Events`, `Webhooks`, `Customers`, `Subscriptions`, `Invoices`, `Charges`, `Coupons`, `PromotionCodes`, `ConnectAccounts`. All `WHERE`/`JOIN`/cursor logic lives here — LiveViews are query-ignorant. Behaviour has no `:offset` key — offset pagination is structurally banned.

**Required indexes (migrations in this phase):**

| Table | Index |
|---|---|
| `accrue_events` | `(inserted_at DESC, id DESC)` |
| `accrue_events` | `(customer_id, inserted_at DESC, id DESC)` |
| `accrue_events` | `(subject_type, subject_id, inserted_at DESC, id DESC)` |
| `accrue_events` | `(event_type, inserted_at DESC, id DESC)` |
| `accrue_events` | `(caused_by_webhook_event_id)` (new column — see D7-06) |
| `accrue_webhook_events` | `(status, received_at DESC, id DESC)` |
| `accrue_webhook_events` | `(received_at DESC, id DESC)` |
| `accrue_webhook_events` | partial `(received_at DESC, id DESC) WHERE status = 'dlq'` |
| `accrue_customers` | `(inserted_at DESC, id DESC)`, `(email)` btree |
| `accrue_subscriptions` | `(status, inserted_at DESC, id DESC)`, `(customer_id, inserted_at DESC, id DESC)` |
| `accrue_invoices` | `(status, issued_at DESC, id DESC)`, `(customer_id, issued_at DESC, id DESC)`, `(number)` unique |
| `accrue_charges` | `(status, created_at DESC, id DESC)`, `(customer_id, created_at DESC, id DESC)` |
| `accrue_connect_accounts` | `(charges_enabled, inserted_at DESC, id DESC)` |
| `accrue_coupons`, `accrue_promotion_codes` | `(active, inserted_at DESC, id DESC)` |

Migration smoke tests assert every index exists via `pg_indexes`.

**Detail pages** (single webhook retry timeline, single subscription event stream) may *optionally* add scoped PubSub subscriptions for sub-second feel — decided per-page, not architecturally. Default is poll.

---

### D7-05 — Step-up auth: additive `Accrue.Auth` callbacks + session grace window + generic `StepUpAuthModal`

**Decision:** Extend `Accrue.Auth` with two `@optional_callbacks`:
```elixir
@callback step_up_challenge(user, action) :: challenge
@callback verify_step_up(user, params, action) :: :ok | {:error, reason}
```
where `challenge` is `%{kind: :password | :totp | :webauthn | :auto, ...}`. `Accrue.Admin.StepUp.require_fresh/3` wraps destructive event handlers, checks a session-scoped `@grace_key` timestamp (configurable `:step_up_grace_seconds`, default 300 = Stripe parity), and if stale assigns `:step_up_pending` + `:step_up_challenge` so the template renders `<.live_component module={AccrueAdmin.Components.StepUpAuthModal} />`. Modal submits a params map to a `"step_up_submit"` handler that calls `verify_step_up/3`, records an `admin.step_up.ok | .denied` audit event, and runs the stored continuation on success.

**Grace scope:** Session-wide "sudo mode" (any sensitive action for N minutes), not per-action. Matches GitHub sudo mode and Stripe Dashboard. Avoids prompt fatigue. Scope `:accrue_admin, :step_up_grace_seconds` is runtime-configurable.

**Rationale:** Stripe, GitHub, Nova, Django, AWS all converge on: sensitive-session flag + clock + generic reprompt UI + verification delegated to whatever credential the host owns. Accrue cannot own the credential (no password hash, no TOTP secret, no passkey). Option A (extend the behaviour) maps cleanly; hosts implement it however they want. Option B (session timeout, kick admin out) loses LiveView state on refund — real foot-gun. Option C (defer to host plug) is the Mission Control "nobody does it" anti-pattern. Option D (action tokens) is strictly more powerful but imposes token-lifecycle burden for the 95% synchronous case. Option E (hybrid) ships A now and keeps D additive for v1.1 Slack-approval workflows — adding `issue_action_token/2` is purely additive.

**Sigra adapter path:** WebAuthn user-verification assertion is the web-standard step-up primitive. Sigra adapter implements `step_up_challenge` as `%{kind: :webauthn, options: Sigra.WebAuthn.generate_assertion_options(user, user_verification: :required)}` and `verify_step_up` via `Sigra.WebAuthn.verify_assertion/3`. First-party DX is a Touch ID tap — matches where Stripe Dashboard passkey prompts are going.

**Default adapter:** Dev returns `%{kind: :auto}` and auto-approves. Prod raises `Accrue.Auth.StepUpUnconfigured` — same fail-closed posture as the rest of `Accrue.Auth.Default`.

**Destructive actions requiring step-up:** `refund`, `cancel_subscription`, `void_invoice`, `mark_uncollectible`, `comp_subscription`, `requeue_dlq` (bulk only — single requeue is one-click per GitHub webhook redeliver).

**Audit linkage (ADMIN-22, ADMIN-23):** Every successful destructive action writes an `accrue_events` row with `actor_type: :admin`, `actor_id: Accrue.Auth.actor_id(user)`, and `caused_by_event_id` set to the event_id the admin clicked (action handler signature enforces passing it explicitly). Step-up OK/denied audit events are a *separate* `admin.step_up.*` stream that doesn't pollute billing events.

---

### D7-06 — Webhook inspector + DLQ bulk requeue UX

**Decision (five sub-picks, each one-sentence):**

1. **Raw payload viewer:** Extend `JsonViewer` with a Tree/Raw/Copy tri-tab, pure LiveView + a `phx-hook="Clipboard"` (~15-line JS), no third-party JS, no diff tab in v1.0.
2. **Filter UX:** Top `FilterChipBar` with chips for Status · Event type · Provider · Date, URL-synced via `live_patch`, Svix-style color-coded status chips. No sidebar facets.
3. **Attempt history:** Vertical `Timeline` component inside the detail drawer, one node per attempt with Moss/Amber/Ink status dot, click-to-expand error body, footer row for "next retry at" / "moved to DLQ".
4. **DLQ bulk requeue:** Multi-select with "select page" + "select all N matching filter"; confirmation modal quoting queue name, concurrency (pulled live via `Oban.config/1`), estimated drain time, and `admin.webhook.bulk_requeue` audit warning; streamed progress via `Oban.insert_all/2` in chunks of 100 with `send_update` pushing `{:progress, N, total}` to the modal LiveComponent; hard cap at **10,000 rows** (refuse above, suggest filter narrowing). Bulk select is **desktop-only** — hidden below `md:` breakpoint.
5. **Derived events:** Add `caused_by_webhook_event_id :uuid` FK on `accrue_events` (migration in this phase); "Derived Events" tab in the webhook detail drawer links into the Events inspector.

**Rationale:** Svix is the gold standard and the template. Stripe Dashboard's webhook event detail, Hookdeck's bulk retry with count/rate-limit quote, GitHub's one-click redeliver, and Oban.Web's attempt-history timeline all converge on this shape. Chip bar over sidebar facets because webhook filter state must be URL-shareable (paste into Slack for a teammate to see the exact same filtered view) and horizontal space matters for the payload preview column. One bulk audit event per intent (not N per row). Secret masking: Signature tab shows verification *result* only, never the raw signing secret (already masked at `Accrue.Config` Inspect protocol layer, but we don't reintroduce it in the admin UI).

**Individual requeue is one-click with no modal.** Only bulk earns confirmation. Matches GitHub's per-row redeliver UX.

**Single requeue queue:** Bulk requeue uses the same `accrue_webhooks` Oban queue as normal webhook processing — no separate `accrue_webhooks_requeue` queue. Rate limiting is already handled by the queue's `limit: 10` default.

---

### D7-07 — Dev surfaces: hybrid `/billing/dev` section + floating dev toolbar, 5-layer compile gate

**Decision:**

**Packaging (Option E — Hybrid):**
- `/billing/dev/*` route scope containing `ClockLive`, `EmailPreviewLive`, `WebhookFixtureLive`, `ComponentKitchenLive`, `FakeInspectLive` — organized under an amber-accented "Dev" sidebar group with a `[NON-PROD]` pill for unmistakable visual signaling.
- A persistent floating `<.dev_toolbar>` component mounted in `AppShell`'s root layout (dev builds only), fixed bottom-right, collapsed by default, showing current clock time + `+1d / +1w / +1mo` quick buttons + a "full clock UI →" link. Lets admins advance time without leaving the page they're inspecting.

**Rationale:** Test-clock work is *bursty and interleaved* (on a customer page → advance 7 days → stay on that customer page), while email preview is a *destination task* (sit for 20 min iterating templates, needs full width). Floating toolbar handles the first, dedicated section handles the second. Option C (inline everywhere) is rejected — prod-leak surface area is unacceptable. Option D (`/_dev` bare mount) forces context-switching that doesn't match Accrue's "manipulate state" workflow (vs Telescope's "observe"). Both LiveDashboard (dedicated mount) and Django debug_toolbar (floating panel) have ecosystem precedent; combining both matches our specific task shape.

**5-layer compile gate (belt-and-suspenders):**

1. **Module-level gate.** Every dev module wrapped in `if Mix.env() != :prod do defmodule ... end`. The module literally doesn't exist in prod BEAM. Credo rule bans `Mix.env()` inside function bodies.
2. **Router gate.** `if Mix.env() != :prod do scope "/dev", Dev do ... end end` inside the router macro. Prod route table has no `/billing/dev/*` entries.
3. **Sidebar/toolbar gate.** `@dev_enabled Code.ensure_loaded?(AccrueAdmin.Dev.ClockLive)` module attribute captured at compile time; HEEx `:if={@dev_enabled}` elides the entire nav group and toolbar subtree in prod.
4. **Runtime guardrail.** Every dev LiveView `mount/3` checks `Accrue.Processor.current() == Accrue.Processor.Fake` and refuses to render otherwise. Catches the pathological "dev modules force-loaded into prod" case AND protects against pointing dev-mode Accrue at real Stripe keys.
5. **CI assertion.** Prod-compile smoke job asserts `find _build/prod/lib/accrue_admin/ebin -name 'Elixir.AccrueAdmin.Dev.*.beam'` is empty AND boots a prod release and asserts no `Elixir.AccrueAdmin.Dev.*` atoms are loadable.

**Test clock UX:** List of active clocks, quick advance buttons (`+1h / +1d / +1w / +1mo / +30d / +90d`), "advance by N [days|weeks|months]" form, "jump to date" form, "reset to wall time" danger button. Confirmation modal for advances > 90 days. **Effect-feedback panel** during advance streams `accrue_events` rows via `Phoenix.PubSub.subscribe(Accrue.PubSub, "accrue:dev:clock")` so admin sees "3 subs renewed, 2 invoices finalized, 1 trial ended" as it happens. This is one of the few places PubSub is used in admin (see D7-04).

**Email preview UX:** Sidebar list of 13+ email template types, tabs (HTML / Text / Raw / Attachments), fixture selector (which customer/invoice/subscription), light/dark preview toggle (emails render differently in dark mode email clients), "Send to me" button (dev-only, mails to logged-in admin via `Accrue.Mailer.Test`), "Copy raw" for debugging. Mailpit is the reference. Fulfills Phase 6 D6-08 deferral.

**Dev-only ExDoc:** Every `AccrueAdmin.Dev.*` module gets `@moduledoc false` so they don't appear in published Hex docs even when compiled into dev. Double protection.

---

### D7-08 — Theming: `data-theme` 3-state (light/dark/system) + cookie + inline anti-FOUC + semantic aliases

**Decision:**

1. **Toggle mechanism:** `data-theme` attribute on `<html>` with three states (`light`/`dark`/`system`). CSS vars flipped via `:root[data-theme="dark"] { ... }` blocks. Tailwind `darkMode: ['variant', '&:where([data-theme="dark"], [data-theme="dark"] *)']` so `dark:` utilities remain usable for escape cases, but 95% of components reference semantic vars directly.
2. **Persistence:** HTTP cookie `accrue_theme` (SameSite=Lax, 1 year, not HttpOnly — JS reads for anti-FOUC), mirrored into `localStorage` as a cache. Cookie wins because root layout reads it server-side before first paint. Host-user persistence is **out of scope for v1.0** (couples to `Accrue.Auth.user_schema`, breaks single-package cohesion; additive v1.1).
3. **Anti-FOUC:** Blocking inline `<script nonce={@csp_nonce}>` in `<head>` *before* any stylesheet link, reading cookie → localStorage → `prefers-color-scheme`, setting `document.documentElement.dataset.theme` synchronously. ~400 bytes minified.
4. **Runtime brand override:** Inline `<style nonce={@csp_nonce}>` block in root layout emitting `:root { --ax-accent: <%= @brand.accent_hex %>; --ax-accent-contrast: <%= @brand.accent_contrast_hex %>; }`. Rejected dynamic `/billing/brand.css` route (adds blocking request, etag complexity, doesn't compose with LV session→assigns). Inline is ~80 bytes and reuses the nonce we already need.
5. **Palette → Tailwind:** Single Tailwind preset (`accrue_admin/assets/tailwind_preset.js`) maps raw palette (`ink`, `slate`, `fog`, `paper`, `moss`, `cobalt`, `amber`) and **semantic aliases** (`base`, `elevated`, `sunken`, `primary`, `muted`, `subtle`, `border`, `accent`, `accent-contrast`, `success`, `warning`) to `var(--ax-*)`. Components **must** use semantic classes; raw palette classes are escape hatches for fixed-identity surfaces (invoice PDFs, emails) where dark mode doesn't apply.
6. **Accessibility:** WCAG AA contrast pairs precomputed and asserted in unit tests via a pure-Elixir `Accrue.Color` helper (~40 LOC, relative luminance). Runtime-override path property-tested with `stream_data` over representative accent colors. Focus ring derived from accent via `color-mix(in oklch, var(--ax-accent) 70%, white|black)` in light|dark. `@media (prefers-reduced-motion: reduce)` zeros the `--ax-theme-transition` var.

**Semantic alias CSS structure:** Raw palette never flips. Semantic aliases have a light default block in `:root` and a dark override block in `:root[data-theme="dark"]`. Dev-only `/billing/dev/brand` preview page renders every semantic token against every background with computed contrast ratios inline (designers get instant WCAG feedback without running tests).

**Root layout ordering is load-bearing:** (1) `<meta charset>`, (2) anti-FOUC script, (3) `brand.css` link, (4) `app.css` link (MD5-hashed), (5) runtime override `<style>`, (6) LV client script. Any reorder causes FOUC or override loss. Integration test asserts byte order.

**`Accrue.Config` brand schema (NimbleOptions) — deliberately minimal three keys:**
```elixir
brand: [
  type: :keyword_list,
  keys: [
    app_name:    [type: :string, default: "Billing"],
    logo_url:    [type: {:or, [:string, nil]}, default: nil],
    accent_hex:  [type: :string, default: "#2f6bff"]  # Cobalt
  ]
]
```
`accent_contrast_hex` is **derived** (not configured) via `Accrue.Color.pick_contrast/1` so hosts can't ship inaccessible pairings. `Accrue.Brand.resolve/1` raises with helpful message if an override fails AA — fail at boot, not at first paint.

---

### D7-09 — `AccrueAdmin.Components.DataTable` is the load-bearing primitive

Explicit call-out: `DataTable` is *the* component that most of the phase's complexity flows through. Customer/subscription/invoice/charge/event/webhook/Connect/coupon lists all use it. It must be built first (wave 2), and it must be built right. All list pages are thin LiveViews whose `mount`/`handle_params` delegates to a per-resource `Query` module and renders via `<.live_component module={DataTable} ... />`. Column config declares per-column `:filter` type (`:text`, `:select`, `:date_range`, `:boolean`); `DataTable` renders the filter form; `Query` module maps the form schema back to Ecto. Bulk select lives in a LiveComponent assign (not the stream). Card-mode responsive breakpoint is `md:`.

### Claude's Discretion

- **Exact breakpoint pixels** for mobile/tablet/desktop beyond the `md: 768px` and `lg: 1024px` defaults.
- **Exact component prop names** — sketched in research, planner may refine to match Phoenix 1.8 idiomatic slot/attr naming.
- **Ordering of waves** in PLAN.md — planner decides dependency tree.
- **Test-clock widget exact button row** (`+1h / +1d / +1w / +1mo / +30d / +90d` sketched; planner may add `+15min` if Fake processor timing needs it).
- **Email preview fixture selector UX** — sidebar with search vs dropdown.
- **Specific Oban queue concurrency** shown in bulk requeue modal (pull via `Oban.config/1` runtime, value not locked).
- **`Accrue.Color` helper's exact API surface** — the public contract is `contrast_ratio/2` + `meets_aa?/3` + `pick_contrast/1`, anything else is planner's discretion.
- **CmdK palette action registry shape** — likely `@callback commands() :: [%{label:, action:, group:, shortcut:}]` per-LV.
- **Which v1.0 ADMIN-* req gets which wave number** — beyond the wave-0/wave-1 split of foundation→components→pages→dev.

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

### v1.1 doors (additive, non-breaking)
- **Host-user theme persistence** via optional `Accrue.Auth.user_schema` extension — cookie falls back
- **Action token async approvals** for Slack/push workflows — `issue_action_token/2` + `verify_action_token/3` as further `@optional_callbacks`, modal learns `%{kind: :token}` challenge
- **Payload diff viewer tab** in JsonViewer (against last successful event of same type)
- **Scoped PubSub per-detail-page** real-time (single webhook retry drawer, single subscription timeline)
- **Advanced filter drawer** (beyond chip bar) when filter field count exceeds ~6
- **Saved views** (named filter presets persisted per-admin-user)
- **Bulk actions beyond requeue** — bulk cancel, bulk refund (deliberately NOT in v1.0; too dangerous without more UX work)
- **Admin action "undo" / four-eyes approval** — requires dual-admin approval for highest-risk actions

### Reviewed Todos (not folded)
None — no pending todos matched.

### Scope-creep redirects
None — discussion stayed within phase scope. User's direction ("research deeply, one-shot perfect") avoided mid-discussion ideation.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADMIN-01 | Dashboard KPIs | Dashboard should aggregate from local `accrue_*` projections and `accrue_events`, not processor calls. |
| ADMIN-02 | Mobile-first layout | `AppShell`, card-mode `DataTable`, full-screen mobile drawer, and route-level polling strategy support phone use. |
| ADMIN-03 | Light + dark mode | `data-theme`, cookie persistence, anti-FOUC ordering, and semantic CSS variables cover this. |
| ADMIN-04 | Brand palette theme | Reuse `accrue/priv/static/brand.css`, add semantic aliases and runtime accent override. |
| ADMIN-05 | Breadcrumbs + flash | First-party component inventory includes both. |
| ADMIN-06 | Branding config | Keep brand config in `Accrue.Config`; no DB-backed admin editing in v1.0. |
| ADMIN-07 | Customer list/search/filter | Add `AccrueAdmin.Queries.Customers`; use local `accrue_customers` with explicit search indexes. |
| ADMIN-08 | Customer detail tabs | Use local customer-centric queries plus `Accrue.Events.timeline_for/3`. |
| ADMIN-09 | Subscription list/detail | Use `accrue_subscriptions` plus `Accrue.Billing.Query` predicates for status-safe filtering. |
| ADMIN-10 | Subscription actions | Route through `Accrue.Billing.*` actions and wrap destructive ones with step-up and audit writes. |
| ADMIN-11 | Invoice list/detail | Use local invoice projection and live PDF render path from Phase 6. |
| ADMIN-12 | Invoice actions | Step-up gate destructive invoice actions; keep action logic in core billing context. |
| ADMIN-13 | Charge list/detail | Use local charge/refund/payment-method associations; no processor round-trips for list pages. |
| ADMIN-14 | Refund action | Step-up gate and surface fee-aware fields already present on `accrue_refunds`. |
| ADMIN-15 | Coupon + promotion code UI | Query local `accrue_coupons` and `accrue_promotion_codes`; align filters with actual `valid`/`active` fields. |
| ADMIN-16 | Webhook inspector | Use `accrue_webhook_events` + `Accrue.Webhooks.DLQ` + raw-body redaction rules. |
| ADMIN-17 | Webhook replay | Use existing `Accrue.Webhooks.DLQ.requeue/1` and `requeue_where/2`; do not invent another queue. |
| ADMIN-18 | Activity feed | Use `Accrue.Events.timeline_for/3` and cursorized event queries. |
| ADMIN-19 | Connect accounts list/detail | Query local `accrue_connect_accounts`; `Accrue.Connect.list_accounts/1` is processor pass-through and not the default list source. |
| ADMIN-20 | Platform fee config UI | Needs a follow-up planner decision on whether Phase 7 is read-only for fees or writes via existing `Accrue.Connect.PlatformFee`. |
| ADMIN-21 | Step-up auth | Extend `Accrue.Auth` with optional callbacks; default dev adapter auto-approves, prod fails closed. |
| ADMIN-22 | Admin action audit logging | Add causal event columns first, then write all admin actions through `Accrue.Events`. |
| ADMIN-23 | Causal linkage | Requires event-ledger schema support; current code does not yet expose causal FK fields. |
| ADMIN-24 | Dev-only test clock | Compile-gated dev routes and runtime `Accrue.Processor.Fake` guardrail support this. |
| ADMIN-25 | `accrue_admin` router macro | Implement like LiveDashboard/Oban.Web: own scope, assets, live_session, session callback. |
| ADMIN-26 | `on_mount` auth | Enforce in `live_session`, not only in event handlers. |
| ADMIN-27 | Shared component library | Build first-party components in `AccrueAdmin.Components.*`. |
| AUTH-03 | Sigra integration | Fill the existing conditional-compile Sigra adapter instead of adding a second integration path. |
| EVT-09 | Event causality | Add event-ledger schema support for causal linkage before admin destructive actions depend on it. |
</phase_requirements>

## Summary

`accrue_admin` is currently only a namespace package with config stubs, one `mix.exs`, and no router, assets, layouts, components, LiveViews, or admin tests. The core `accrue` package already provides the pieces the admin must stand on: a host-owned Repo facade, billing schemas, `Accrue.Billing.Query` status-safe query fragments, an append-only event ledger, webhook-event persistence, DLQ replay APIs, Connect account projection, and the `Accrue.Auth` behaviour. [VERIFIED: codebase grep]

The main planning risk is not missing Phoenix guidance; it is schema drift between the locked context and the code that exists today. The Phase 7 context prescribes indexes and causal columns that refer to fields not present in the current schemas, including `accrue_events.customer_id`, `accrue_events.event_type`, `accrue_invoices.issued_at`, `accrue_charges.created_at`, webhook status `dlq`, and coupon field `active` on `accrue_coupons`. The planner should preserve the intent of those decisions, but must translate them to actual columns or add the missing columns in Wave 0 instead of copying the context literally. [VERIFIED: codebase grep]

The second major risk is package publishing. The locked asset strategy is correct for a mountable library, but `accrue_admin/mix.exs` currently omits `priv/static` from the Hex package file list, which would ship a package with no bundled CSS or JS. The planner should treat package metadata, router/asset plumbing, and the event-ledger schema corrections as prerequisites before page work. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban_web/installation.html]

**Primary recommendation:** Build Phase 7 in four waves: `Wave 0 foundation` (router/assets/config/schema/index corrections), `Wave 1 primitives` (layouts/components/query behaviour/test harness), `Wave 2 read surfaces` (dashboard + lists + detail drawers), `Wave 3 privileged surfaces` (step-up actions, webhook replay UX, dev tools). [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Admin route mount, session handoff, CSP/CSRF, root layout | Frontend Server (SSR) | Browser / Client | Router macro, `live_session`, and asset endpoints all live in Phoenix server code. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Router.html] |
| Interactive tables, drawers, command palette, theme toggle | Browser / Client | Frontend Server (SSR) | LiveView drives the UI from the server, but the DOM state, hooks, clipboard, and theme application land in the client. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1] |
| Authz and step-up enforcement | Frontend Server (SSR) | API / Backend | LiveView `on_mount` and event handlers must gate access before render and before destructive actions. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1] [VERIFIED: codebase grep] |
| Billing/admin reads | API / Backend | Database / Storage | Query modules should compose Ecto queries over local projections and not call the processor for list pages. [VERIFIED: codebase grep] |
| Event timeline, webhook inspector, DLQ replay | API / Backend | Database / Storage | `Accrue.Events` and `Accrue.Webhooks.DLQ` already own the read/write semantics the UI should wrap. [VERIFIED: codebase grep] |
| Bundled CSS/JS delivery | Frontend Server (SSR) | CDN / Static | The library should expose hashed asset routes from its own plug/controller instead of using host `Plug.Static` or host Tailwind. [CITED: https://hexdocs.pm/oban_web/installation.html] [VERIFIED: phase context] |

## Project Constraints (from CLAUDE.md)

- Target Elixir `1.17+`, Phoenix `1.8+`, Phoenix LiveView `1.0+`, PostgreSQL `14+`; the local machine exceeds that floor at Elixir `1.19.5`, OTP `28`, and PostgreSQL `14.17`. [VERIFIED: codebase grep] [VERIFIED: local command]
- `accrue` and `accrue_admin` stay sibling Mix projects in one monorepo; `accrue_admin` is the only package that should take a hard LiveView dependency. [VERIFIED: codebase grep]
- The core library must stay LiveView-free; admin UI behavior should live in `accrue_admin` and call into `Accrue.*` facades rather than pulling web concerns into `accrue/`. [VERIFIED: codebase grep]
- Testing posture is ExUnit with sandboxed Ecto ownership, Mox/Oban helpers in core, and no external-component dependency pinning. [VERIFIED: codebase grep]
- PDF preview depends on the existing `Accrue.PDF` behaviour and ChromicPDF adapter pattern rather than a new PDF stack. [VERIFIED: codebase grep]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | `1.8.5` (published 2026-03-05) | Router macros, plug pipeline, verified routes, root layouts | Current stable Phoenix `1.8.x` is already locked in the repo and is the framework both LiveDashboard and mountable admin packages target. [VERIFIED: mix.lock] [CITED: https://hex.pm/packages/phoenix/versions] |
| `phoenix_live_view` | `1.1.28` (published 2026-03-27) | `live_session`, `on_mount`, streams, LiveComponents | Current stable LiveView exposes the exact auth/session hooks and streamed rendering pattern the locked context depends on. [VERIFIED: mix hex.info] [CITED: https://hex.pm/packages/phoenix_live_view/versions] |
| `phoenix_html` | `4.3.0` (published 2025-09-28) | Forms, HTML helpers, function-component interoperability | Current Phoenix HTML matches the repo lock and supports the admin component surface without extra UI deps. [VERIFIED: mix.lock] [CITED: https://hex.pm/packages/phoenix_html/versions] |
| `accrue` | local sibling `0.1.0` | Billing schemas, events, webhook DLQ, auth facade, PDF facade | `accrue_admin` should be a thin UI layer over existing `Accrue.*` boundaries, not a second business-logic package. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `tailwindcss` | `4.2.2` (published 2026-03-18) | Private CSS build for the packaged bundle | Use only inside `accrue_admin/assets` and CI/package build; do not require host Tailwind integration. [VERIFIED: npm registry] |
| `esbuild` | `0.28.0` (published 2026-04-02) | Private JS bundling for hooks and LiveSocket bootstrap | Use only for the library-owned asset bundle and bundle-freshness CI. [VERIFIED: npm registry] |
| `Accrue.Billing.Query` | repo module | Status-safe subscription query fragments | Use for status filtering instead of raw subscription status clauses. [VERIFIED: codebase grep] |
| `Accrue.Events` | repo module | Event timelines and bucketed analytics | Use for activity feed and subject timelines rather than ad hoc event-folding in LiveViews. [VERIFIED: codebase grep] |
| `Accrue.Webhooks.DLQ` | repo module | Single and bulk replay, counts, pruning | Use for webhook replay UX instead of direct Oban job manipulation from LiveViews. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Library-owned router macro + assets | Host `forward` + host Tailwind pipeline | Rejected because Oban.Web documents a self-contained install and the locked context requires no host asset config edits. [CITED: https://hexdocs.pm/oban_web/installation.html] |
| First-party HEEx components | PetalComponents / SaladUI | Rejected because the phase is v1.0 surface area and the repo should not inherit pre-1.0 component-library churn. [VERIFIED: phase context] |
| Cursor pagination | Offset pagination | Rejected because `accrue_events` is append-only and offset scans degrade badly for long-lived admin feeds. [VERIFIED: codebase grep] |

**Installation:**
```bash
cd accrue_admin
mix deps.get
npm view tailwindcss version
npm view esbuild version
```

## Architecture Patterns

### System Architecture Diagram

```text
Host Router
  -> accrue_admin "/billing" macro
    -> admin pipeline
      -> session callback + CSP/brand plugs
        -> live_session(on_mount auth)
          -> Layout/AppShell
            -> DataTable/DetailDrawer/CommandPalette components
              -> AccrueAdmin.Queries.* modules
                -> Accrue.Repo facade
                  -> accrue_* tables / accrue_events / accrue_webhook_events
                    -> optional action callouts to Accrue.Billing / Accrue.Webhooks.DLQ / Accrue.PDF
                      -> telemetry + audit event rows
```

### Recommended Project Structure

```text
accrue_admin/
├── lib/accrue_admin/router.ex                # `accrue_admin/2` macro, session callback, route helpers
├── lib/accrue_admin/assets.ex                # hashed asset serving from `priv/static`
├── lib/accrue_admin/layouts.ex               # root + app shell layouts
├── lib/accrue_admin/auth_hook.ex             # `on_mount` authz and current-admin assigns
├── lib/accrue_admin/brand_plug.ex            # brand + theme assigns
├── lib/accrue_admin/csp_plug.ex              # nonce extraction helpers
├── lib/accrue_admin/queries/                 # cursor, behaviour, per-resource query modules
├── lib/accrue_admin/components/              # function components + stateful LiveComponents
├── lib/accrue_admin/live/                    # dashboard, list/detail LiveViews, action modals
├── lib/accrue_admin/dev/                     # compile-gated dev LiveViews and toolbar
├── priv/static/                              # committed `accrue_admin.css` + `accrue_admin.js`
├── assets/                                   # private Tailwind/esbuild source, not shipped to hosts
├── test/support/                             # ConnCase/DataCase-like helpers for admin package
└── test/accrue_admin/                        # router, component, query, LiveView, accessibility tests
```

Recommended layout notes:
- Keep query modules under the single `AccrueAdmin.Queries.*` namespace to match the package namespace already used by `AccrueAdmin`. [VERIFIED: codebase grep]
- Keep all business mutations in `Accrue.*`; `accrue_admin` should add orchestration only for session/auth/UI state. [VERIFIED: codebase grep]

### Pattern 1: Mountable Admin Macro With Its Own `live_session`
**What:** A router macro that owns its browser scope, session callback, `live_session`, and hashed asset routes.
**When to use:** For every host installation; do not mount individual LiveViews manually.
**Example:**
```elixir
defmodule AccrueAdmin.Router do
  defmacro accrue_admin(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      scope path, AccrueAdmin do
        pipe_through [:browser, :accrue_admin]

        live_session :accrue_admin,
          root_layout: {AccrueAdmin.Layouts, :root},
          on_mount: [{AccrueAdmin.AuthHook, :ensure_admin} | Keyword.get(opts, :on_mount, [])],
          session: {AccrueAdmin.Router, :__session__, [opts]} do
          live "/", DashboardLive, :index
        end

        get "/assets/:asset", AccrueAdmin.Assets, :show
      end
    end
  end
end
```
Source: [Phoenix LiveView `on_mount` + `live_session`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1), [Oban.Web.Router](https://hexdocs.pm/oban_web/Oban.Web.Router.html)

### Pattern 2: Read-Side Query Modules Per Resource
**What:** Query modules own filter decoding, Ecto joins, cursor encoding, and "new rows" count logic.
**When to use:** For every list/detail admin surface; avoid embedding `Ecto.Query` in LiveViews.
**Example:**
```elixir
defmodule AccrueAdmin.Queries.Webhooks do
  import Ecto.Query

  alias Accrue.Repo
  alias Accrue.Webhook.WebhookEvent

  def list(filter: filter, cursor: cursor, limit: limit) do
    WebhookEvent
    |> where([w], ^status_clause(filter))
    |> order_by([w], desc: w.inserted_at, desc: w.id)
    |> apply_cursor(cursor)
    |> limit(^limit)
    |> Repo.all()
  end
end
```
Source: repo query posture in [Accrue.Events](/Users/jon/projects/accrue/accrue/lib/accrue/events.ex) and [Accrue.Webhooks.DLQ](/Users/jon/projects/accrue/accrue/lib/accrue/webhooks/dlq.ex)

### Pattern 3: Action Wrapper Around Existing Core APIs
**What:** LiveViews submit to thin admin action modules that add step-up checks, flash semantics, and audit writes around `Accrue.*` mutations.
**When to use:** Refunds, invoice voiding, subscription cancellation, bulk replay.
**Example:**
```elixir
with :ok <- AccrueAdmin.StepUp.require_fresh(socket, :refund, refund_ref),
     {:ok, refund} <- Accrue.Billing.RefundActions.refund_charge(charge, params),
     {:ok, _audit} <- Accrue.Events.record(%{
       type: "admin.refund.created",
       actor_type: "admin",
       actor_id: Accrue.Auth.actor_id(current_admin),
       subject_type: "Refund",
       subject_id: refund.id
     }) do
  {:noreply, put_flash(socket, :info, "Refund queued")}
end
```
Source: repo action boundaries in [Accrue.Auth](/Users/jon/projects/accrue/accrue/lib/accrue/auth.ex), [Accrue.Events](/Users/jon/projects/accrue/accrue/lib/accrue/events.ex)

### Anti-Patterns to Avoid

- **LiveView-embedded SQL:** Keep filtering and cursor logic in `AccrueAdmin.Queries.*`; otherwise every list page forks the same bugs. [VERIFIED: codebase grep]
- **Processor-backed list pages:** `Accrue.Connect.list_accounts/1` is processor pass-through and should not be the default admin list source. [VERIFIED: codebase grep]
- **Literal copy of D7-04 index names:** Several context indexes target columns that do not exist yet; translating intent is mandatory. [VERIFIED: codebase grep]
- **Host asset pipeline coupling:** Do not require host `tailwind.config.js`, `app.js`, or layout edits. [CITED: https://hexdocs.pm/oban_web/installation.html]
- **Runtime-only dev gating:** Compile-gate dev routes/modules first, then add runtime Fake-processor guards. [VERIFIED: phase context]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LiveView auth lifecycle | Custom websocket/session gate outside `live_session` | `live_session` + `on_mount` | Official LiveView auth hooks run before mount and support halting/redirect cleanly. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1] |
| Asset invalidation | Manual cache-busting query strings | Hashed asset routes from a plug/controller | Oban.Web and LiveDashboard use self-contained hashed assets, which remove host pipeline coupling. [CITED: https://hexdocs.pm/oban_web/installation.html] |
| Webhook replay backend | Direct Oban job inserts in UI code | `Accrue.Webhooks.DLQ.requeue/1` and `requeue_where/2` | The repo already centralizes replay rules, skip logic, telemetry, and audit events there. [VERIFIED: codebase grep] |
| Subscription status filtering | Raw `.status` strings in UI queries | `Accrue.Billing.Query` | The repo explicitly bans raw status access outside approved modules. [VERIFIED: codebase grep] |
| Currency formatting | Ad hoc integer formatting | `Accrue.Money` / `MoneyFormatter` | Locale/timezone-aware billing display is already a core requirement from Phase 6. [VERIFIED: codebase grep] |

**Key insight:** The admin package should hand-roll UI composition, not domain rules. The rule-heavy parts already exist in `accrue`, and Phase 7 risk rises sharply if the admin starts duplicating them. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Locked Index Specs Drift From Real Schema
**What goes wrong:** Planner copies D7-04 migrations literally and generates indexes on nonexistent columns or impossible statuses. [VERIFIED: codebase grep]
**Why it happens:** The locked context describes intended read models, but the current schemas still use `type`, `inserted_at`, `valid`, and `status in [:dead, :failed]`. [VERIFIED: codebase grep]
**How to avoid:** Add a Wave 0 schema/index reconciliation plan before page work and verify every column against the actual Ecto schemas and migrations. [VERIFIED: codebase grep]
**Warning signs:** Migration compilation fails, or tests reference `issued_at`, `created_at`, `dlq`, or `event_type` without prior schema changes. [VERIFIED: codebase grep]

### Pitfall 2: Shipping A Hex Package Without Bundled Assets
**What goes wrong:** The package builds locally from the monorepo but published Hex installs have no `priv/static` assets. [VERIFIED: codebase grep]
**Why it happens:** `accrue_admin/mix.exs` currently ships only `lib`, `mix.exs`, `README*`, `LICENSE*`, and `CHANGELOG*`. [VERIFIED: codebase grep]
**How to avoid:** Add `priv/static` and any runtime config/docs the package needs to `package.files`, plus a CI bundle-freshness check. [VERIFIED: codebase grep]
**Warning signs:** Asset routes 404 in a dependency install or rendered admin pages have no styles/scripts. [ASSUMED]

### Pitfall 3: Using Processor APIs For Admin Lists
**What goes wrong:** Admin pages become slow, inconsistent, and untestable because list pages hit Stripe instead of local projections. [VERIFIED: codebase grep]
**Why it happens:** Some core APIs, especially `Accrue.Connect.list_accounts/1`, still expose processor pass-throughs that look convenient. [VERIFIED: codebase grep]
**How to avoid:** Treat processor calls as refresh/fallback paths only; all list/detail pages should default to local tables. [VERIFIED: codebase grep]
**Warning signs:** Query modules need API keys, rate-limit handling, or network mocks for basic list-page tests. [ASSUMED]

### Pitfall 4: Authz Only In Event Handlers
**What goes wrong:** Sensitive pages render or connect before the admin check runs. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1]
**Why it happens:** Plug-based or `handle_event`-only auth feels familiar, but LiveView mount is the actual boundary. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1]
**How to avoid:** Enforce admin access in the router macro's `live_session on_mount` and keep action-specific step-up as a second gate. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1]
**Warning signs:** Pages briefly flash before redirect or connected mounts fetch data for unauthorized users. [ASSUMED]

## Code Examples

Verified patterns from official sources:

### Mount Hook For Auth
```elixir
live_session :admins, on_mount: {MyAppWeb.InitAssigns, :admin} do
  scope "/admin", MyAppWeb.Admin do
    pipe_through [:browser, :require_user, :require_admin]
    live "/", AdminLive.Index, :index
  end
end
```
Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1

### Self-Contained Dashboard Mount
```elixir
scope "/" do
  pipe_through :browser
  oban_dashboard "/oban", on_mount: [MyApp.UserHook]
end
```
Source: https://hexdocs.pm/oban_web/Oban.Web.Router.html

### Self-Contained Asset Stance
```text
Oban Web is delivered as a hex package named `oban_web`. The package is entirely self contained—it doesn't hook into your asset pipeline at all.
```
Source: https://hexdocs.pm/oban_web/installation.html

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Host asset pipeline integration for mounted dashboards | Self-contained bundled assets with router-owned routes | Current Oban.Web docs and LiveDashboard source | Makes Hex installs predictable and removes host Tailwind config edits. [CITED: https://hexdocs.pm/oban_web/installation.html] |
| Offset pagination for admin feeds | Cursor pagination on stable sort keys | Current best practice for append-only feeds | Keeps `accrue_events` and `accrue_webhook_events` workable at large row counts. [VERIFIED: codebase grep] |
| Plug-only auth for server-rendered pages | `live_session` + `on_mount` for LiveViews | LiveView official guidance | Prevents mount-time leaks and keeps redirect semantics correct. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1] |
| Runtime-only hiding of dev tools | Compile-gated modules and routes plus runtime guardrail | Current locked phase context | Reduces prod leakage risk for test-clock and fixture tooling. [VERIFIED: phase context] |

**Deprecated/outdated:**
- Host `tailwind.config.js` integration for packaged admin UIs: outdated for this phase because the locked goal is a mountable library package with zero host asset setup. [CITED: https://hexdocs.pm/oban_web/installation.html]
- Raw subscription status access in UI code: outdated because the repo already ships `Accrue.Billing.Query` and a Credo rule to ban raw status access. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The D7-04 index list should be treated as intent, not literal migration text, because several referenced columns/statuses do not exist yet. | Summary / Common Pitfalls | Planner could generate invalid migrations or block the phase in Wave 0. |
| A2 | `EVT-09` for admin causality requires explicit event-ledger linkage fields because current `Accrue.Events.Event` and `Accrue.Events.record/1` expose no causal columns. | Summary / Resolved Decisions | Admin actions and webhook-derived event linkage would have no schema support. |
| A3 | The package should standardize on `accrue_admin/lib/accrue_admin/queries/*.ex` and `AccrueAdmin.Queries.*`. | Architecture Patterns | Planner could produce the wrong module tree and leak inconsistent naming into the public API. |
| A4 | Adding `step_up_challenge/2` and `verify_step_up/3` as `@optional_callbacks` is the least-breaking way to extend `Accrue.Auth`. | Common Pitfalls / Open Questions | Existing adapters could break or Phase 7 could need a broader auth-contract migration. |
| A5 | Poll-driven “new rows” banners will be acceptable for admin freshness without scoped PubSub in v1.0. | Architecture Patterns | If false, planners may need extra Wave 0 work for live detail subscriptions or higher-frequency refresh. |

## Resolved Decisions

1. **Causal linkage uses both `caused_by_event_id` and `caused_by_webhook_event_id`.**
   Decision: add both nullable linkage fields in Phase 7. `caused_by_event_id` is the self-referential `accrue_events` FK for admin action chains and event-to-event causality. `caused_by_webhook_event_id` is the FK to `accrue_webhook_events` for webhook-derived billing/admin events. [VERIFIED: locked context + codebase grep]
   Reasoning: the locked context and webhook inspector need direct webhook-to-event linkage, while ADMIN-22/23 also require event-to-event causality for operator-triggered actions. A single column would force awkward overload semantics.

2. **Customer search defaults to `accrue_customers` only; no host user-schema join by default.**
   Decision: customer list/detail surfaces query local customer fields (`name`, `email`, `processor_id`, locale/timezone, payment-method linkage) and treat host-schema enrichments as optional future additions. [VERIFIED: codebase grep]
   Reasoning: this preserves package portability and avoids making Phase 7 depend on arbitrary host schemas or auth adapters.

3. **ADMIN-20 ships a writable per-account override UI, not a global settings editor.**
   Decision: Phase 7 keeps the global platform-fee policy read-only from `Accrue.Config`, and ships a writable per-account override stored in `accrue_connect_accounts.data["platform_fee_override"]`, validated and previewed through `Accrue.Connect.PlatformFee`, with a minimal `Accrue.Connect` helper to persist the override. [VERIFIED: requirements grep] [VERIFIED: codebase grep]
   Reasoning: this is conservative and executable with current repo primitives. It satisfies ADMIN-20 without inventing a new settings subsystem or fictional table.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `accrue_admin` compile/test | ✓ | `1.19.5` | — |
| Erlang/OTP | Phoenix/LiveView runtime | ✓ | `28` | — |
| Mix | deps/test/docs | ✓ | `1.19.5` | — |
| Node.js | asset bundle rebuild + CI freshness check | ✓ | `22.14.0` | — |
| npm | `npx tailwindcss` / `npx esbuild` | ✓ | `11.1.0` | — |
| PostgreSQL client | Ecto-backed tests and schema verification | ✓ | `14.17` | — |
| Chromium/Chrome | live PDF preview if `ChromicPDF` is used | ✗ | — | Use `Accrue.PDF.Test` or `Accrue.PDF.Null` in local/dev tests; production host must provide Chrome/Chromium. |

**Missing dependencies with no fallback:**
- None for planning-only work. [VERIFIED: local command]

**Missing dependencies with fallback:**
- Browser binary for ChromicPDF-backed invoice preview is missing locally; fallback is non-Chrome adapters in tests/dev, but production preview still needs a real browser. [VERIFIED: local command] [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (`accrue_admin` package has `test/test_helper.exs` only today) |
| Config file | `accrue_admin/test/test_helper.exs` |
| Quick run command | `cd accrue_admin && mix test` |
| Full suite command | `cd accrue && mix test --warnings-as-errors && cd ../accrue_admin && mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADMIN-25 | Router macro mounts isolated scope, session callback, and asset routes | integration | `cd accrue_admin && mix test test/accrue_admin/router_test.exs` | ❌ Wave 0 |
| ADMIN-26 | Non-admin users are rejected in `on_mount` before page render | integration | `cd accrue_admin && mix test test/accrue_admin/live/auth_hook_test.exs` | ❌ Wave 0 |
| ADMIN-02 | Mobile card-mode table and drawer navigation remain usable | LiveView integration | `cd accrue_admin && mix test test/accrue_admin/live/responsive_navigation_test.exs` | ❌ Wave 0 |
| ADMIN-03 | Light/dark/system theme persistence and anti-FOUC ordering | component + integration | `cd accrue_admin && mix test test/accrue_admin/theme_test.exs` | ❌ Wave 0 |
| ADMIN-07 | Customer filters/search/cursor pagination | query + LiveView integration | `cd accrue_admin && mix test test/accrue_admin/queries/customers_test.exs` | ❌ Wave 0 |
| ADMIN-16 | Webhook inspector shows payload, status, attempts, and masking | LiveView integration | `cd accrue_admin && mix test test/accrue_admin/live/webhooks_live_test.exs` | ❌ Wave 0 |
| ADMIN-17 | Replay and bulk replay call `Accrue.Webhooks.DLQ` correctly | integration | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs` | ❌ Wave 0 |
| ADMIN-21 | Step-up prompt gates destructive actions and grants grace window | integration | `cd accrue_admin && mix test test/accrue_admin/live/step_up_test.exs` | ❌ Wave 0 |
| ADMIN-24 | Dev routes compile out in prod and reject non-Fake processor runtime | compile smoke + integration | `cd accrue_admin && MIX_ENV=prod mix compile` | ❌ Wave 0 |
| EVT-09 | Admin/webhook causal event linkage writes expected event rows | integration | `cd accrue && mix test test/accrue/events/admin_causality_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `cd accrue_admin && mix test`
- **Per wave merge:** `cd accrue && mix test --warnings-as-errors && cd ../accrue_admin && mix test --warnings-as-errors`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `accrue_admin/test/support/conn_case.ex` — browser-conn + sandbox ownership helper
- [ ] `accrue_admin/test/support/data_case.ex` — query-layer helpers and errors-on convenience
- [ ] `accrue_admin/test/accrue_admin/router_test.exs` — macro mount, asset route, CSP/session wiring
- [ ] `accrue_admin/test/accrue_admin/components/*_test.exs` — component render coverage for `DataTable`, drawers, badges, flashes
- [ ] `accrue_admin/test/accrue_admin/queries/*_test.exs` — cursor/filter logic per resource
- [ ] `accrue_admin/test/accrue_admin/live/*_test.exs` — page-level auth/theme/action/dev-route coverage
- [ ] `accrue_admin/test/accrue_admin/prod_compile_test.exs` or CI smoke step — dev-surface compile gate verification

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | `live_session` `on_mount` auth with host-owned `Accrue.Auth` adapter |
| V3 Session Management | yes | session callback + step-up grace timestamp in session + CSRF-protected browser pipeline |
| V4 Access Control | yes | admin-only mount hook plus per-action step-up for destructive operations |
| V5 Input Validation | yes | `NimbleOptions` for router/config opts and changeset-backed core actions |
| V6 Cryptography | yes | reuse host auth/WebAuthn/TOTP/password verification via adapter; never hand-roll credential checks |

### Known Threat Patterns for Phoenix LiveView Admin

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized LiveView mount | Elevation of Privilege | enforce admin check in `live_session on_mount` before render |
| Destructive action without re-auth | Elevation of Privilege | step-up challenge with session grace window and audit events |
| CSRF/session bleed from host layout reuse | Tampering | mount under isolated admin scope with its own pipeline and root layout |
| Raw webhook payload exposure | Information Disclosure | use redacted schema inspect output and hide secrets in the inspector UI |
| DOM bloat or stale-row confusion in long sessions | Denial of Service | poll banner + bounded `stream/3` list limit instead of auto-insert |
| Replay abuse on large DLQ sets | Denial of Service | count quote, confirmation modal, chunked replay, and hard row cap |

## Sources

### Primary (HIGH confidence)

- Local codebase:
  - [accrue_admin/mix.exs](/Users/jon/projects/accrue/accrue_admin/mix.exs)
  - [accrue_admin/lib/accrue_admin.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin.ex)
  - [accrue/lib/accrue/auth.ex](/Users/jon/projects/accrue/accrue/lib/accrue/auth.ex)
  - [accrue/lib/accrue/events.ex](/Users/jon/projects/accrue/accrue/lib/accrue/events.ex)
  - [accrue/lib/accrue/billing/query.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/query.ex)
  - [accrue/lib/accrue/webhook/webhook_event.ex](/Users/jon/projects/accrue/accrue/lib/accrue/webhook/webhook_event.ex)
  - [accrue/lib/accrue/webhooks/dlq.ex](/Users/jon/projects/accrue/accrue/lib/accrue/webhooks/dlq.ex)
  - [accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs](/Users/jon/projects/accrue/accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs)
  - [accrue/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs](/Users/jon/projects/accrue/accrue/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs)
  - [accrue/priv/repo/migrations/20260414120000_phase3_schema_upgrades.exs](/Users/jon/projects/accrue/accrue/priv/repo/migrations/20260414120000_phase3_schema_upgrades.exs)
- Official docs:
  - https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1
  - https://hexdocs.pm/oban_web/Oban.Web.Router.html
  - https://hexdocs.pm/oban_web/installation.html
- Registry/version sources:
  - https://hex.pm/packages/phoenix/versions
  - https://hex.pm/packages/phoenix_live_view/versions
  - https://hex.pm/packages/phoenix_html/versions
  - https://hex.pm/packages/phoenix_live_dashboard/versions
  - `mix hex.info phoenix_live_view`
  - `mix hex.info phoenix_html`
  - `mix hex.info phoenix_live_dashboard`
  - `npm view tailwindcss version`
  - `npm view esbuild version`

### Secondary (MEDIUM confidence)

- https://github.com/phoenixframework/phoenix_live_dashboard
- https://github.com/oban-bg/oban_web

### Tertiary (LOW confidence)

- None. All notable factual claims were verified against the repo, official docs, or package registries.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - package versions and toolchain were verified from `mix.lock`, Hex, npm, and local commands.
- Architecture: MEDIUM - the mount/asset/auth patterns are well-supported by official docs, but several locked-context schema/index examples still need Wave 0 translation.
- Pitfalls: HIGH - the biggest pitfalls come directly from concrete repo/context mismatches visible today.

**Research date:** 2026-04-15
**Valid until:** 2026-05-15
