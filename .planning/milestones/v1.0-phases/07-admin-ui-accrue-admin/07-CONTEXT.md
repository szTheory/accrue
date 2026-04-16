# Phase 7: Admin UI (accrue_admin) — Context

**Gathered:** 2026-04-15
**Status:** Ready for planning
**Mode:** Deep research (8 parallel advisor agents) synthesized into locked decisions

<domain>
## Phase Boundary

Ship `accrue_admin` v1.0 — a mobile-first, light/dark Phoenix LiveView admin UI mounted into the host app at an arbitrary path (`accrue_admin "/billing"`). Covers customers, subscriptions, invoices, charges, refunds, coupons/promotion codes, Connect accounts, webhook event inspector + DLQ bulk requeue, activity feed from `accrue_events`, and dev-only surfaces (test clock + email preview). Auth-protected via `Accrue.Auth` adapter with first-party Sigra auto-detection. Admin actions audit to `accrue_events` with `actor_type: :admin` and causal linkage.

**In scope:** 27 ADMIN-* requirements + AUTH-03 + EVT-09. **Out of scope:** new billing capabilities, GraphQL, tenant-user self-service (those are phases for another day / other libraries).

</domain>

<decisions>
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

---

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

### Folded Todos

None — no pending `.planning/todos/` entries matched Phase 7 scope.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents (researcher, planner, executor) MUST read these before proceeding.**

### Phase 7 direct inputs
- `.planning/PROJECT.md` — vision, non-negotiables, ship-complete philosophy, brand palette names
- `.planning/ROADMAP.md` §Phase 7 — goal, 27 ADMIN-* + AUTH-03 + EVT-09 requirements, success criteria
- `.planning/REQUIREMENTS.md` lines 154–180 — ADMIN-01..27 full text
- `CLAUDE.md` §Constraints, §Technology Stack — locked deps (`phoenix_live_view ~> 1.1`, `phoenix ~> 1.8`, `phoenix_html ~> 4.2`), monorepo layout, Mox test posture, ChromicPDF adapter pattern

### Prior-phase decisions that constrain Phase 7
- `.planning/phases/01-foundations/01-CONTEXT.md`:
  - D-24 (rich brand config read from `Accrue.Config`)
  - D-36 (core stays LiveView-free; `AccrueAdmin.PDF.render_component` flattens LiveView→PDF at admin layer)
  - D-40 (`Accrue.Auth.Default` dev-permissive, prod refuses to boot)
  - D-41 / D-45 (Sigra conditional compile, concrete callback bodies land in Phase 7)
  - D-44 (`mix accrue.install` auto-detects `accrue_admin` and generates router mounts)
- `.planning/phases/06-email-pdf/06-CONTEXT.md`:
  - D6-03 (per-customer locale + timezone — `MoneyFormatter` component must respect)
  - D6-04 (PDF lazy render on demand, no storage — invoice detail "PDF preview" is live-render)
  - D6-08 (Phase 6 ships `mix accrue.mail.preview`; Phase 7 adds the LiveView admin email preview route)

### Source files that exist and must be read before planning
- `accrue/lib/accrue/auth.ex` — behaviour signature (will be extended per D7-05)
- `accrue/lib/accrue/auth/default.ex` — dev-permissive adapter (will gain step-up stubs)
- `accrue/lib/accrue/integrations/sigra.ex` — scaffold with the `Code.ensure_loaded?(Sigra)` gate; concrete callback bodies land here in Phase 7
- `accrue/priv/static/brand.css` — existing palette CSS vars (raw palette only; semantic aliases added in Phase 7)
- `accrue/guides/branding.md` — existing branding guide (admin section added in Phase 7)
- `accrue_admin/mix.exs` — locked deps list; add `jason`, potentially `nimble_options` if not transitive
- `accrue_admin/lib/accrue_admin.ex` — current namespace anchor module (comment references Phase 7 as the landing spot for concrete LiveView dashboard)

### Ecosystem references (must be consulted by researcher + planner)
- **Phoenix.LiveDashboard source** — `lib/phoenix/live_dashboard/router.ex` (router macro shape, `live_session`, `on_mount`, `:csp_nonce_assign_key`); `lib/phoenix/live_dashboard/controllers/assets.ex` (compile-time `@external_resource` + MD5 hash pattern). This is the closest-matching precedent and should be read line-by-line before writing the `AccrueAdmin.Router` macro.
- **Oban.Web source + docs** — router macro parity, "doesn't hook into your asset pipeline at all" stance, bulk action UX for attempt history
- **Svix dashboard** — webhook event detail layout, attempt timeline with colored dots, filter chip bar (UX reference only, not code)
- **Stripe Dashboard sudo-mode / webhook event detail** — UX reference for step-up + inspector
- **GitHub sudo mode docs** — session-wide grace window pattern (`docs.github.com/en/authentication/keeping-your-account-and-data-secure/sudo-mode`)
- **Hookdeck bulk retry modal** — rate-limit quote + count + narrow-filter nudge

### Upstream Phase 2–6 artifacts that Phase 7 consumes
- `accrue_webhook_events` table schema (Phase 2)
- `accrue_events` table schema (Phase 1) — will gain `caused_by_webhook_event_id` column in a Phase 7 migration
- `Accrue.Billing.*` context facades (Phases 3–5) — admin calls into these; does not reach into schemas directly
- `Accrue.PDF.render/2` (Phase 6) — invoice PDF preview renders live
- `Accrue.Mailer` + email type modules (Phase 6) — email preview LiveView uses `Accrue.Mailer.Test` adapter to capture rendered payloads

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`Accrue.Auth` behaviour** (`accrue/lib/accrue/auth.ex`): 5 callbacks already defined. Phase 7 extends with 2 optional callbacks (`step_up_challenge/2`, `verify_step_up/3`). Additive, doesn't break hosts on upgrade.
- **`Accrue.Auth.Default`** (`accrue/lib/accrue/auth/default.ex`): Dev-permissive + prod-refuse-boot pattern is exactly what step-up needs — `step_up_challenge` returns `%{kind: :auto}` in dev, raises `StepUpUnconfigured` in prod.
- **`Accrue.Integrations.Sigra`** (`accrue/lib/accrue/integrations/sigra.ex`): Conditional-compile scaffold in place. Phase 7 fills in `require_admin_plug/0` with the real `on_mount` hook, adds `step_up_challenge`/`verify_step_up` via `Sigra.WebAuthn.*`, and adds `log_audit` delegation to `Sigra.Audit.log/2` (already stubbed).
- **`accrue/priv/static/brand.css`**: Raw palette CSS vars already defined. Phase 7 adds the semantic alias block and the dark-theme override block.
- **`Accrue.Config`**: NimbleOptions-validated. Phase 7 extends `:branding` schema with `:admin` sub-key if needed, or piggybacks on existing brand config. Already resolvable via `Accrue.Config.brand/0`.
- **`Accrue.Events.record/1`**: Already accepts `actor_type`, `actor_id`, `caused_by_event_id`. Admin actions write through this API — no new context function needed.
- **`Accrue.PDF.render/2`**: Invoice detail page "PDF preview" iframe calls this live per D6-04 (no storage).
- **`Accrue.Mailer.Test`**: Phase 7 email preview uses this adapter to capture rendered multipart emails.
- **`accrue_admin/mix.exs`**: Hard deps already locked: `phoenix ~> 1.8`, `phoenix_live_view ~> 1.1`, `phoenix_html ~> 4.2`, `ex_doc`, `credo`. Phase 7 may add: `jason ~> 1.4` (transitive today), potentially `nimble_options ~> 1.1` if router macro needs own validation.

### Established Patterns

- **Conditional compilation (D-41 4-pattern)** — Phase 7 reuses this pattern in `Accrue.Integrations.Sigra` concrete bodies AND in `accrue_admin/lib/accrue_admin/dev/*.ex` modules (wrapped in `if Mix.env() != :prod`).
- **Behaviour + adapter dispatch via `Application.get_env/3`** — used by `Accrue.Auth`, `Accrue.Processor`, `Accrue.PDF`, `Accrue.Mailer`. `Accrue.Admin.AuthHook` follows the same pattern for the `on_mount` hook.
- **NimbleOptions config validation at boot** — `Accrue.Config` validates all options. Phase 7 adds admin-specific options (`:step_up_grace_seconds`, `:admin_session_keys`) via the same mechanism.
- **Raw-body-before-parsers plug precedence** (Phase 2) — admin mount pipeline sits AFTER parsers since LiveView needs parsed params; no conflict.
- **Append-only event ledger with trigger-enforced immutability** (Phase 1) — admin inspector queries but never mutates `accrue_events`. Step-up audit writes are new rows, not updates.

### Integration Points

- **Router mount:** `accrue_admin "/billing"` — added to host router (demonstrated in `mix accrue.install` per D-44).
- **Config extension:** `config :accrue_admin, :step_up_grace_seconds` + `config :accrue, :branding` (existing, extended).
- **Database migrations:** New columns — `caused_by_webhook_event_id :uuid` on `accrue_events`; new indexes per D7-04.
- **`mix accrue.install` task** (Phase 8): detects `accrue_admin` dep, generates router mount + `on_mount` config + dev/prod config snippets.
- **Oban queue:** `accrue_webhooks` queue handles both normal webhook processing AND bulk requeue (single queue, rate-limited by `limit: 10`).
- **Phoenix PubSub topics:** `"accrue:dev:clock"` (dev-only effect feedback), `"accrue:webhook_events:#{id}"` (detail-page opt-in live retry updates — deferred to per-page planner decision).

</code_context>

<specifics>
## Specific Ideas

- User's direction: "research using subagents, pros/cons/tradeoffs... best practices idiomatic Elixir/Plug/Ecto/Phoenix... great software arch/engineering... best for our use case, great DX/dev ergonomics... cohesive/coherent decisions among themselves and drives toward goal/vision of the lib... lessons learned from other libs in ecosystem and other langs/frameworks... think deeply and one-shot perfect recommendation." Decisions above are synthesized from 8 parallel advisor research agents and cross-checked for coherence (mount → asset → theme → component → data → step-up → dev → webhook). No user follow-up questions were asked; downstream agents should treat D7-01..D7-09 as locked.

- Cohesion check passed: The LiveDashboard-style mount (D7-01) is the architectural enabler for every other decision:
  - Owns `<head>` → enables server-rendered cookie theme (D7-08)
  - Owns root layout → enables inline brand override + anti-FOUC script (D7-08, D7-02)
  - Owns pipeline → enables `on_mount` auth hook (D7-05)
  - Owns asset routes → enables precompiled bundle with no host Tailwind edits (D7-02)
  - Owns `live_session` scope → enables compile-gated dev routes (D7-07)
  - Owns component namespace → enables first-party library without host `CoreComponents` coupling (D7-03)

- Ship-complete check: No v0.x iteration. Every decision is v1.0-finishable in one phase. Additive v1.1 doors left open for: host-user theme persistence (D7-08), action-token async approvals (D7-05), payload diff viewer (D7-06), scoped PubSub per-detail-page real-time (D7-04).

- Cross-ecosystem lessons applied:
  - Phoenix.LiveDashboard router + assets pattern copied verbatim
  - Oban.Web "doesn't hook into your asset pipeline" stance adopted
  - Svix filter chips + attempt timeline adopted
  - Stripe/GitHub sudo-mode session grace adopted
  - Hookdeck bulk-retry-with-count-and-queue-quote adopted
  - Rails Mission Control deferred-to-host step-up pattern **rejected** as cautionary tale
  - Kaffy shared-`:browser`-pipeline pattern **rejected** as CSRF/layout-leak source
  - Torch generator pattern **rejected** as upgrade-burden source
  - Pow macro-into-`:browser` **rejected** as years-of-issues source

</specifics>

<deferred>
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

</deferred>

---

*Phase: 07-admin-ui-accrue-admin*
*Context gathered: 2026-04-15*
*Method: 8 parallel gsd-advisor-researcher agents, synthesized into coherent decision set*
