# AccrueAdmin Integration Guide

`accrue_admin` mounts a package-scoped LiveView billing UI inside a host Phoenix app. The package owns its own router macro, private static bundle, and non-prod inspection tools.

Start with the package quickstart in [`README.md`](../README.md), then return here for the host wiring and release checks. Published `accrue_admin` releases depend on the matching `accrue` minor (see Hex for the current `~>` range), while monorepo development keeps the local sibling dependency shape by default.

## UI stack and polish direction

- **Build:** Tailwind CSS v3 compiles [`assets/css/app.css`](../assets/css/app.css) into `priv/static/accrue_admin.css` via `mix accrue_admin.assets.build`. The package does not ship a Tailwind config or preset; Tailwind is the CSS compiler and minifier for the committed bundle.
- **Authoring:** AccrueAdmin styles are authored in [`assets/css/theme.css`](../assets/css/theme.css) and [`assets/css/app.css`](../assets/css/app.css) using `--ax-*` tokens and `ax-*` classes. Tailwind utilities are not an authoring path, and host apps never configure Tailwind for `accrue_admin`.
- **Principles:** least surprise for billing operators; clear hierarchy (context → KPIs → primary work area); visible focus states; explicit empty, loading, and error states on lists; microcopy that matches host and Stripe language (subscription, invoice, webhook) unless the screen is intentionally abstracted.
- **Motion:** light CSS transitions on shells, drawers, and modals; honor `prefers-reduced-motion`; reach for LiveView `JS` only when CSS cannot carry the interaction.
- **Responsive:** keep the mounted shell usable on small viewports first; avoid wide horizontal scroll for primary tables unless unavoidable—prefer column discipline and secondary detail surfaces.

## Feedback placement

Use `assets/js/toast.js` (`showToast`) and `.ax-toast` for short, non-actionable confirmations such as copying an ID or timestamp. All transient confirmations share one bottom-center location, token-based styling, and the toast layer above overlays. The location stays consistent across desktop and mobile, with narrow-screen gutters and a device safe-area inset. Toasts never move focus or require dismissal; a newer message replaces the previous message and restarts the 2.5-second lifetime. The shared live status announces the message politely.

Copy controls supply `data-clipboard-label` (or `IdBadge.copy_label`) to name the copied object: “Copied customer ID to clipboard”, “Copied timestamp to clipboard”, or “Copied event payload to clipboard”. Keep identifiers and payload contents out of the confirmation. The same message is visible and announced, only after the clipboard write succeeds.

Keep failures that require a decision or recovery action in the existing `FlashGroup` or beside the affected control. A copy failure may use the shared toast as brief feedback, but the exact manual-copy fallback remains at the control. Do not put required instructions or actions solely in a disappearing toast. Do not create per-page toast positions or separate notification implementations.

## Core operator surface parity (checklist)

**ADM-07:** the canonical matrix of mounted core routes vs `AccrueAdmin.Copy`, `ax-*` / token discipline, and VERIFY-01 posture lives in **[`core-admin-parity.md`](core-admin-parity.md)**. Use it when triaging Tier A copy gaps or planning VERIFY extensions—do not maintain a second matrix in planning-only docs.

## Customer payment methods tab (inventory)

The v1.24 Phase 76 **`payment_methods`** tab inventory (ADM-13) lives in [`.planning/milestones/v1.24-phases/76-customer-pm-tab-inventory-copy-burn-down/76-VERIFICATION.md`](../../.planning/milestones/v1.24-phases/76-customer-pm-tab-inventory-copy-burn-down/76-VERIFICATION.md).

This stub intentionally does not duplicate the operator string table—use that file as the SSOT (per **76-CONTEXT.md** D-02).

## Theming and exceptions

Semantic color and spacing tokens for the mounted admin UI live in [`assets/css/theme.css`](../assets/css/theme.css) and are composed in [`assets/css/app.css`](../assets/css/app.css). If you introduce a **non-token color literal** (for example a one-off hex in HEEx or a fallback brand map in Elixir) during hierarchy or polish work, add a row to the package register at [`theme-exceptions.md`](theme-exceptions.md) so reviewers can see the exception without spelunking git history.

## Host Setup

Add the package to your router and mount it where operators expect billing controls:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  import AccrueAdmin.Router

  scope "/" do
    pipe_through [:browser]

    accrue_admin "/billing",
      session_keys: [:user_token],
      on_mount: [{MyAppWeb.UserAuth, :mount_current_user}]
  end
end
```

`accrue_admin "/billing"` creates:

- hashed package asset routes under `/billing/assets/*`
- the main billing LiveView routes under `/billing/*`
- compile-gated dev routes under `/billing/dev/*` only outside `MIX_ENV=prod`

## Branding

By default, the package derives its brand chrome from `Accrue.Config.branding/0`
through the package branding plug. Configure the host app's billing identity once
and the admin shell inherits it:

```elixir
config :accrue,
  branding: [
    business_name: "Acme Corp",
    from_email: "billing@acme.test",
    support_email: "support@acme.test",
    logo_url: "https://example.test/logo.svg",
    accent_color: "#5E9E84"
  ]
```

When the customer-facing billing brand should differ from the operator surface,
configure `:admin_branding` as a small override. This preserves `:branding` for
emails, PDFs, and the customer portal while keeping the mounted admin chrome under
an Accrue/operator identity:

```elixir
config :accrue,
  branding: [
    business_name: "CohortFlow",
    from_email: "billing@cohortflow.test",
    support_email: "support@cohortflow.test",
    accent_color: "#26785F"
  ],
  admin_branding: [
    app_name: "Accrue Admin",
    accent_color: "#5D79F6"
  ]
```

## Auth Expectations

The mount macro wires the package auth hook into the LiveSession by default.
`Accrue.Auth` must be able to resolve the current operator from the forwarded
session data, and `session_keys: [:user_token]` is the supported host boundary
for the standard Phoenix auth flow.

The host app remains responsible for browser-session setup before the admin
routes mount. Keep `accrue_admin "/billing"` inside the authenticated browser
scope so `/billing` inherits the same auth boundary as the rest of the app.

## Private Asset Bundle

The package serves its own committed bundle from `priv/static/`. The JavaScript bundle must be **valid ES module output** (not a placeholder): it includes Phoenix + LiveView so admin `phx-click` interactions work in the browser. Rebuild it locally with:

```bash
cd accrue_admin
mix accrue_admin.assets.build
```

That task only touches:

- `priv/static/accrue_admin.css`
- `priv/static/accrue_admin.js`

No host Tailwind config edits or host JavaScript bootstrap changes are required.

## Release Verification

CI and local publish dry runs must force the Hex-safe sibling dependency shape:

```bash
cd accrue_admin
export ACCRUE_ADMIN_HEX_RELEASE=1
```

Use this release gate before shipping or validating publish automation:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test --warnings-as-errors
mix credo --strict
mix docs --warnings-as-errors
mix dialyzer --format github
mix hex.audit
mix hex.build
mix hex.publish --dry-run
```

## Browser UAT

Phase 7 operator verification is automated with Playwright specs under `e2e/`. The suite starts a local test Phoenix endpoint, seeds deterministic billing data, and runs the dashboard, webhook replay, bulk DLQ replay, and step-up refund flows in desktop and mobile Chromium profiles.

Run it locally with:

```bash
cd accrue_admin
npm ci
npx playwright install chromium
npm run e2e
```

CI runs the same suite in `.github/workflows/accrue_admin_browser.yml` with Postgres and uploads Playwright traces on failure.

To replay the GitHub Actions job locally with `act`:

```bash
act workflow_dispatch \
  -W .github/workflows/accrue_admin_browser.yml \
  -j browser-uat
```

## Dev-Only Surfaces

Outside prod builds, a floating dev toolbar links to:

- `/billing/dev/clock`
- `/billing/dev/email-preview`
- `/billing/dev/webhook-fixtures`
- `/billing/dev/components`
- `/billing/dev/fake-inspect`

Those pages are hidden entirely from prod builds and also refuse to expose tooling unless the configured processor is `Accrue.Processor.Fake`.

## Prod Compile Guarantee

`accrue_admin` enforces the dev surface in two layers:

- compile time: the dev LiveViews, toolbar component, and `/billing/dev/*` routes are only defined when `Mix.env() != :prod`
- runtime: even in `:dev` and `:test`, the pages render only when `Application.get_env(:accrue, :processor)` is `Accrue.Processor.Fake`

Use `MIX_ENV=prod mix compile` in `accrue_admin/` as the smoke check that the package ships without any dev-only admin tooling in production builds.

## Navigation groups and activity cues

The default Admin destination is **Recent activity**, under **Billing**, with the same name in navigation, the page heading, and browser title. Breadcrumbs begin with the corresponding sidebar group as plain text: `Billing / Recent activity`, `Billing / Customers`, `Audit / Events`, and so on. Groups have no destination. Record-detail breadcrumbs retain the actual scoped list link, such as `Billing / Customers / customer name`. Use `PageHeader.breadcrumb_group` or `Breadcrumbs.group`; do not link a peer page as though it were a parent.

`AccrueAdmin.EventPresentation` owns the shared event label, family icon, and outcome tone used by Recent activity and Events. Its catalogue covers registered lifecycle events and additional confirmed producers, but is not an exhaustive ledger enum. Customer, subscription, invoice, payment/refund, recovery, payment-method, webhook, and connected-account families reuse the existing icon set. Icons are decorative supplements to readable text, never the sole meaning. Routine events and unknown types remain neutral; selected recorded outcomes use semantic success/warning tokens. An admin result event's name alone does not establish success. Exact event keys remain available in Events and event details.

The historical `subscription.trial_ended` key is also produced for a trial-will-end webhook, so the UI uses “Subscription trial status recorded” rather than asserting an already-ended trial. Improving that producer's event contract is separate work.

Activity rows group the event heading with its copyable timestamp; narrow screens stack them in the same reading order. The heading is the real link to event details, replacing a repeated “Open event” action. ID copying remains a separate native button. When the heading explicitly names the record type (for example “Subscription created”), show the short visible label “ID”; keep the full type in the accessible copy label, and retain a visible type for ambiguous event headings. Family icons may have exact-event overrides where the family glyph misstates the action: subscription creation uses a document-plus, rather than arrows that suggest renewal or sync.

## List controls and evidence

Page orientation uses the shared shell gutter and PageHeader typography. Recent activity and record details do not remove the top gutter. At desktop widths the breadcrumb begins 32px below the topbar; smaller widths use the shell's existing responsive gutter.

Use a compact filter state row, one toolbar reset, and one resource-specific result count. “Reset filters” returns to the page's default view while preserving organization scope. Choosing an “All” view deliberately broadens the list; removing a chip removes that constraint. When a default work queue is empty, name the alternative “View all deliveries” (or the corresponding resource), rather than calling that navigation a reset. Routine summary counts stay neutral and share a baseline; reserve warning color for a non-zero actionable condition.

Named list records use the primary name with secondary evidence underneath. A record reference without a display name uses `DataTable.identity_cell layout="inline"`: type beside the exact copyable ID, with wrapping confined to the available ID space. Keep full IDs visible so browser Find and exact copying remain useful. Table links use medium-weight neutral text at rest, with an underline on hover and visible keyboard focus. Secondary links recede to the metadata role. Shared table cells use the 14px body role, headers the 14px label role, and IDs the 12px code role; timestamps use the 14px body role with tabular figures. Vertically center cells within each row. Plain ID and timestamp hover feedback is a dotted text underline, without a background fill; retain 44px copy targets and the shared focus outline.

Known Events entries show the readable label once; their stored keys remain in event details, while unknown types retain a quiet exact-key fallback. Events columns follow what changed, the affected record, when, who recorded it, and its linked webhook. “App” describes system attribution without claiming a person acted. A missing link means “No linked webhook”, not proof that an operation bypassed webhooks.

Compact display labels use `--ax-record-label-measure` (36ch, capped by the available space) and CSS ellipsis. Supply `DataTable.identity_cell label` with the full primary label for native title disclosure. Use `.ax-record-label` and a full `title` for equivalent secondary record links and recovery labels. Search-result names and breadcrumb labels follow the same clipping policy. Keep the complete value in the DOM and accessible link name; exact IDs remain complete and copyable, and detail headings/summary values wrap to show the full name. Organization scope names wrap instead of clipping. Never shorten stored data or action-confirmation identity to solve layout overflow.

`Pagination` observes the footer boundary and requests one cursor page at a time without scrolling or moving focus. Retain the native Load more button as a keyboard/manual fallback. Events explicitly retains all requested pages (`dom_limit: :infinity`); other consumers keep their configured retention limit. Errors remove the automatic boundary until recovery. Do not mount LiveView's native infinite-scroll hook on a moving footer: its row-anchoring behavior belongs on actual row containers and can otherwise move the reader to each new page.
