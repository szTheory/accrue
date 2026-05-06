# Phase 101: Accrue Portal Foundation & Checkout — Research

**Researched:** 2026-05-01
**Domain:** Phoenix LiveView portal package + Braintree Hosted Fields integration + capability-flipped checkout adapter
**Confidence:** HIGH

## Summary

Phase 101 ships a **third sibling Hex package `accrue_portal`** containing a LiveView portal (checkout + customer self-service) wired to Braintree via Hosted Fields. The architecture is fully predetermined by `101-CONTEXT.md` and `101-UI-SPEC.md`: `Accrue.Portal.Router.accrue_portal/2` macro mirroring `accrue_admin/2` line-for-line, callback-module-not-behaviour `Accrue.Portal.AuthHook` reusing the existing `Accrue.Auth` contract, sibling-scope `live_session :accrue_portal` to avoid the Phase 88 nested-live_session bug, and capability-flipped Braintree adapter where `checkout_session_create/2` and `portal_session_create/2` return URLs pointing at the host's mounted Portal.

The Braintree adapter and webhook plumbing are **already ~90% built** in the existing codebase: `Braintree.Webhook.parse/3` is wired through `Accrue.Webhook.Signature.parse_braintree!/3`, `Accrue.Webhook.Plug` already dispatches on `:braintree`, the `Braintree` Elixir gateway library (sorentwo/braintree-elixir 0.16.0) is already in `mix.exs` (line 58), and the adapter at `accrue/lib/accrue/processor/braintree.ex` already implements customer/subscription/payment-method/refund. The five stub functions (`checkout_session_create/2`, `checkout_session_fetch/2`, `portal_session_create/2`) are the only adapter changes needed. Net-new work is the `accrue_portal` package itself.

**Primary recommendation:** Mirror `accrue_admin` ruthlessly. Every architectural question — package layout, mount macro, on_mount, CSP plug, brand plug, asset serving, test layout — has a direct precedent in `accrue_admin/lib/accrue_admin/`. The only genuinely new technical surface is the Hosted Fields LiveView Hook (browser-side iframe lifecycle) and the `accrue_checkout_sessions` Ecto-backed token table.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Pre-planning unblocker (RESOLVED 2026-05-01):**
- **U-01:** Pivoted from Braintree Drop-in to Braintree Hosted Fields. All upstream documents updated. Hosted Fields renders inside the LiveView template via Braintree's JS SDK with explicit field-by-field iframe injection.

**Area A — Package home:**
- **D-01:** `accrue` core remains headless. First-party UI ships in dedicated sibling package `accrue_portal`.
- **D-02:** Public namespace `Accrue.Portal.*`, OTP app `:accrue_portal`, internal modules `AccruePortal.*`.
- **D-03:** Joins existing `release-please-config.json` `linked-versions` group at v1.33.0 — three-package lockstep.
- **D-04:** `accrue_portal/mix.exs` deps: `{:accrue, "== <same version>"}`, `{:phoenix, "~> 1.8"}`, `{:phoenix_live_view, "~> 1.1"}`, `{:phoenix_html, "~> 4.2"}`, `{:plug, "~> 1.16"}`, `{:jason, "~> 1.4"}`. NOT a hard dep on `:braintree` or `:lattice_stripe`.
- **D-05:** `accrue/guides/braintree-local-portal.md` updated with cross-link header to `accrue_portal`. Hand-roll recipe stays as documented escape hatch.

**Area B — Checkout/portal facade integration:**
- **D-06:** Path 1 — adapter route. `Accrue.Billing.create_checkout_session/2` is unchanged at the facade. The Braintree adapter rewrites `checkout_session_create/2` from `{:error, unsupported()}` to a real implementation that builds a local-portal URL.
- **D-07:** `Accrue.Billing.create_billing_portal_session/2` flips for Braintree the same way.
- **D-08:** Capability map updates — add `"first-party local portal"` support label vocabulary; replace Braintree's checkout/billing_portal `"Stripe-only"` labels.
- **D-09:** Braintree adapter capabilities map: add `checkout: %{create: true, fetch: true, hosted: true, embedded: false}`; flip `billing_portal: %{create: true}`.
- **D-10:** `success_url` / `cancel_url` / `return_url` semantics mirror Stripe exactly. If `nil`, render in-place "Subscription created" panel.
- **D-11:** `:ui_mode :hosted` only in v1.33. URL shape: `{portal_base_url}{portal_mount_path}/checkout/{opaque_session_token}`. `:ui_mode :embedded` deferred.
- **D-12:** Idempotency — local portal persists `accrue_checkout_sessions` rows keyed by `operation_id`. Reuses existing `Accrue.Processor.Idempotency.subject_uuid(:checkout_session_create, operation_id)`.
- **D-13:** No `checkout.session.completed` from Braintree. Portal LV enqueues an Oban job that writes a synthetic `%Accrue.Webhook.Event{type: "accrue.portal.checkout.completed", source: "accrue.portal", ...}`. New telemetry event `[:accrue, :portal, :checkout, :completed]`.

**Area C — Stripe parity scope:**
- **D-14:** Braintree-only escape hatch. Portal activates whenever `Accrue.Processor.supports?([:billing_portal, :create])` returns `false`. Stripe behavior byte-identical to v1.32.
- **D-15:** Do NOT introduce `:ui_mode :local_portal` as a new value. Capability-gating is sufficient.

**Area D — Host mount + auth:**
- **D-16:** Macro `Accrue.Portal.Router.accrue_portal/2` mirroring `accrue_admin/2` line-for-line. Default `on_mount`: `[{Accrue.Portal.AuthHook, :ensure_customer}]`. Emits exactly ONE `live_session :accrue_portal` block.
- **D-17:** No new behaviour module. Reuse `Accrue.Auth`. `Accrue.Portal.AuthHook` is callback module, not behaviour. Two on_mount variants: `:ensure_customer` (lazy-create) and `:ensure_customer_no_create`.
- **D-18:** Required `socket.assigns` after on_mount: `:current_user`, `:current_customer`, `:accrue_portal_session`.
- **D-19:** **Defense-in-depth (NON-NEGOTIABLE).** Every Portal LV query MUST scope to `socket.assigns.current_customer.id`. Property tests for "wrong-tenant URL guess returns :not_found".
- **D-20:** Session-resolved customer ONLY in v1.33. Magic-link deferred.
- **D-21:** Sibling-mount discipline. `accrue_portal/2` and `accrue_admin/2` MUST be sibling top-level scopes. Distinct `live_session` ids.
- **D-22:** Pipeline plugs: `:fetch_session`, `:protect_from_forgery`, `Accrue.Portal.CSPPlug` (allowlist `js.braintreegateway.com` and `*.braintree-api.com`), `Accrue.Portal.BrandPlug`.

**Configuration:**
- **D-23:** `:portal_mount_path` (default `"/accrue/portal"`), `:portal_base_url` (required at runtime, no default).

**Example host:**
- **D-24:** `examples/accrue_host/lib/accrue_host_web/router.ex:90` — admin moves to `/admin`, `accrue_portal "/billing"` mounts alongside.

### Claude's Discretion

- File layout inside `accrue_portal/lib/accrue_portal/live/` mirrors `accrue_admin/lib/accrue_admin/live/`.
- HEEx + Tailwind classes match `accrue_admin` look-and-feel.
- Test layout mirrors `accrue_admin/test/` — LiveViewTest-driven, no JS browser harness in CI.
- ExDoc main page shape mirrors `accrue_admin`.
- CHANGELOG.md per package, release-please-driven.
- Telemetry naming `[:accrue, <area>, <verb>, <stage>]` shape — no inventions.
- Hosted Fields static asset loaded from Braintree CDN with SRI hash pinning (mirrors Stripe.js loading pattern).

### Deferred Ideas (OUT OF SCOPE)

- `:ui_mode :embedded` for the local portal — v1.34+
- Magic-link / URL-token checkout flow — v1.34+ (with documented host-side workaround in install guide)
- Opt-in unified portal for Stripe (Scope 3) — held until a real Stripe-using host asks
- `mix accrue_portal.gen.routes` Mix task — possibly v1.33 if scope is small; otherwise v1.34
- `Accrue.Portal.Token.{sign,verify}` module — designed but NOT shipped in v1.33
- Connect/Hyperwallet portal surface — gated by Phase 104
- Routes-overrideable behaviour (Pow's `Pow.Phoenix.Routes` analog) — not v1.33 scope
- Per-tenant theming beyond `BrandPlug` — defer

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BT-01 | System MUST provide a Phoenix LiveView infrastructure for `Accrue.Portal` that can be mounted by host applications. | §4 (Mount macro), §7 (admin precedent) — `Accrue.Portal.Router.accrue_portal/2` mirroring `AccrueAdmin.Router.accrue_admin/2`. |
| BT-02 | System MUST provide a local hosted checkout page generated via `Accrue.Billing.create_checkout_session/2` that implements Braintree Hosted Fields. (Drop-in deprecated.) | §1 (Hosted Fields integration), §5 (`create_checkout_session/2` API shape) — Hosted Fields client SDK 3.141.0 + LV hook + `accrue_checkout_sessions` table. |
| BT-03 | System MUST provide portal views for users to view active subscriptions, manage/vault payment methods, view transaction history, and cancel subscriptions. | §6 (Customer portal LiveView pages), UI-SPEC component inventory — 7 LVs: HomeLive, CheckoutLive, SubscriptionsLive, SubscriptionLive, PaymentMethodsLive, AddPaymentMethodLive, InvoicesLive. |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Hosted Fields iframe rendering | Browser / Client | — | Braintree-hosted JS injects iframes; LV phx-hook delegates to it. PCI-required. |
| Hosted Fields tokenization → nonce | Browser / Client | — | Card data NEVER traverses server origin. Required for SAQ-A PCI scope. |
| Client token generation | API / Backend | — | `Braintree.ClientToken.generate/0` server-side; token scoped to customer + short TTL. |
| Nonce → server (subscription create) | Frontend Server (LV) | API / Backend | LV pushEvent sends nonce; LV calls `Accrue.Billing.subscribe/3` which dispatches to Braintree adapter via `:vault_acquisition.reference`. |
| Checkout session URL generation | API / Backend | — | `Accrue.Billing.create_checkout_session/2` → Braintree adapter → DB-backed token row + URL synthesis from `:portal_base_url` + `:portal_mount_path`. |
| Checkout session token storage | Database / Storage | — | New `accrue_checkout_sessions` table; opaque token, expires_at, operation_id idempotency, Braintree-private. |
| Portal LiveView routes (subs, PMs, invoices) | Frontend Server (LV) | API / Backend | Mounted via `accrue_portal/2` macro in host's router; queries scoped to `socket.assigns.current_customer`. |
| Webhook signature verification | API / Backend | — | `Accrue.Webhook.Plug` + `Accrue.Webhook.Signature.parse_braintree!/3` — already implemented. |
| Synthetic `accrue.portal.checkout.completed` event | API / Backend (Oban worker) | Database | New `Accrue.Portal.Checkout.CompletionJob` enqueues row in `accrue_webhook_events`; reduced via existing `DefaultHandler`. |
| Portal CSS/JS asset serving | Frontend Server | CDN | Mirror `AccrueAdmin.Assets`: hashed paths served from `accrue_portal` package. Hosted Fields SDK loaded from `js.braintreegateway.com` (CDN + SRI hash). |
| Customer auth resolution | Frontend Server (LV on_mount) | API / Backend | `Accrue.Portal.AuthHook` calls `Accrue.Auth.current_user(session)` → `Accrue.Billing.customer/1` (lazy-create). |

## Project Constraints (from CLAUDE.md)

| Directive | Source | Phase 101 Implication |
|-----------|--------|----------------------|
| Tech stack: Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.13+, PG 14+ | CLAUDE.md §Constraints | `accrue_portal/mix.exs` floor versions match. |
| Required deps: `lattice_stripe`, `oban`, `swoosh`, `ecto_sql`, `postgrex`, `nimble_options`, `telemetry`, `chromic_pdf` | CLAUDE.md §Dependencies | Portal package only adds Phoenix/LiveView/HTML — no new core deps. Oban worker for completion event reuses host-owned Oban supervision. |
| Webhook signature verification mandatory and non-bypassable. Raw-body plug must run before `Plug.Parsers`. | CLAUDE.md §Security | Already in place: `Accrue.Webhook.Plug` with `:braintree` dispatch. Phase 101 does not change this. |
| Sensitive Stripe fields never logged. Payment method details stored as Stripe references, never as PII. | CLAUDE.md §Security | Apply equally to Braintree: vault tokens only, never PAN/CVV. Hosted Fields enforces this architecturally. |
| Webhook request path <100ms p99 | CLAUDE.md §Performance | Synthetic `accrue.portal.checkout.completed` event creation runs inside the LV `handle_event` already returning `{:noreply, ...}`; the Oban completion job runs async per Accrue's standard pattern. |
| All public entry points emit `:telemetry` start/stop/exception events | CLAUDE.md §Observability | `[:accrue, :billing, :checkout_session, :create]` already wraps the create call. Add `[:accrue, :portal, :checkout, :completed]` per D-13. |
| Monorepo: `accrue/` and `accrue_admin/` as siblings | CLAUDE.md §Constraints | Add `accrue_portal/` as third sibling at the repo root. |
| License: MIT for all packages | CLAUDE.md §Constraints | `accrue_portal/mix.exs` matches. |
| Ship complete, not MVP (memory) | User memory | `accrue_portal` ships at v1.33.0 with full Hosted Fields, customer portal, checkout, install guide, ExDoc, CHANGELOG. No 0.x iteration. |
| `phoenix_live_view` is a hard dep in `accrue_admin`, not in core | CLAUDE.md §Dependencies (optional) | `accrue_portal` mirrors this — LV is a hard dep in the portal package only. |
| GSD Workflow Enforcement: All file changes via GSD command | CLAUDE.md §GSD Workflow | This research run is GSD-driven (research-phase). |

## Research Questions Answered

### 1. Braintree Hosted Fields integration in Phoenix LiveView

**Confidence: HIGH** (verified against Braintree docs + braintree-web GitHub).

**SDK version (current 2026-05-01):** `braintree-web` 3.141.0 (npm) [VERIFIED: npm registry, [braintree-web npm page](https://www.npmjs.com/package/braintree-web)]. The Braintree CDN URL pattern is:

```
https://js.braintreegateway.com/web/3.141.0/js/client.min.js
https://js.braintreegateway.com/web/3.141.0/js/hosted-fields.min.js
```

[CITED: developer.paypal.com/braintree/docs/guides/hosted-fields/setup-and-integration/javascript/v3]

**Standard integration flow (4 steps):**

1. **Server generates client token** (Elixir): The `:braintree` lib exposes `Braintree.ClientToken.generate(opts)`. Token is a base64 string scoped to the merchant; passing `customer_id` scopes it to a customer (required for vault-backed flows). Returns within ~200ms.
2. **Browser loads SDK + initializes client + hostedFields**: Two `<script>` tags from `js.braintreegateway.com` (SRI hash pinned). `braintree.client.create({authorization: clientToken})` then `braintree.hostedFields.create({client, styles, fields: {...}})`. The SDK injects 3 iframes (number, expirationDate, cvv) into host `<div>` elements with matching CSS selectors.
3. **User submits form, browser tokenizes**: `hostedFieldsInstance.tokenize()` returns `{nonce, details: {bin, lastFour, cardType}, type, description}`. Card data never leaves Braintree's iframes.
4. **Browser sends nonce to server**: LiveView `pushEvent("hosted_fields_tokenized", {nonce, last4, brand})` → LV `handle_event/3` calls `Accrue.Billing.subscribe(customer, %{vault_acquisition: %{reference: nonce}, ...})`.

**LiveView ↔ Hosted Fields bridge pattern:**

```heex
<%!-- accrue_portal/lib/accrue_portal/live/checkout_live.ex template --%>
<div id="hosted-fields-form"
     phx-hook="AccrueHostedFields"
     phx-update="ignore"
     data-client-token={@client_token}
     data-styles={Jason.encode!(@hosted_fields_styles)}>
  <label>Card number</label>
  <div id="card-number" class="ap-hf-field"></div>

  <label>Expiry</label>
  <div id="expiration-date" class="ap-hf-field"></div>

  <label>CVV</label>
  <div id="cvv" class="ap-hf-field"></div>

  <button id="hf-submit" type="button" phx-click={JS.dispatch("accrue:hf:tokenize")}>
    Pay <%= Money.to_string(@amount) %>
  </button>
</div>
```

```javascript
// accrue_portal/assets/js/hooks/hosted_fields.js
export const AccrueHostedFields = {
  mounted() {
    const clientToken = this.el.dataset.clientToken;
    const styles = JSON.parse(this.el.dataset.styles);

    braintree.client.create({authorization: clientToken}, (err, client) => {
      if (err) { this.pushEvent("hosted_fields_error", {message: err.message}); return; }

      braintree.hostedFields.create({
        client, styles,
        fields: {
          number: { container: "#card-number" },
          expirationDate: { container: "#expiration-date" },
          cvv: { container: "#cvv" }
        }
      }, (err, hf) => {
        if (err) { this.pushEvent("hosted_fields_error", {message: err.message}); return; }

        this.hf = hf;
        this.pushEvent("hosted_fields_ready", {});

        // listen for the JS.dispatch from the submit button
        window.addEventListener("accrue:hf:tokenize", () => {
          hf.tokenize((err, payload) => {
            if (err) { this.pushEvent("hosted_fields_error", {message: err.message, code: err.code}); return; }
            this.pushEvent("hosted_fields_tokenized", {
              nonce: payload.nonce,
              last4: payload.details.lastFour,
              brand: payload.details.cardType,
              bin: payload.details.bin
            });
          });
        });
      });
    });
  },

  destroyed() {
    if (this.hf) { this.hf.teardown(); }
  }
};
```

**Critical LV mechanics:**
- `phx-update="ignore"` is **mandatory** on the iframe-host `<div>` so LV doesn't re-render and destroy Braintree's injected iframes on socket reconnects.
- `phx-hook="AccrueHostedFields"` registers the hook; LV emits `mounted()` once after first mount and `destroyed()` on tear-down.
- `pushEvent` is the only LV-safe channel: `pushEvent("event_name", payload)` triggers `def handle_event("event_name", payload, socket)` server-side.
- Re-mount on socket reconnect: the `mounted()` callback fires again; the `data-client-token` must still be valid (TTL ≥ 24h is Braintree default).

[CITED: Braintree Hosted Fields docs — developer.paypal.com/braintree/docs/guides/hosted-fields/setup-and-integration/javascript/v3]
[VERIFIED: Phoenix LiveView phx-hook docs — hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#module-client-hooks]

### 2. Elixir Braintree client library

**Confidence: HIGH** (verified against Hex.pm + mix.lock + adapter source).

**Library:** `:braintree` (sorentwo/braintree-elixir) — **already in `accrue/mix.exs:58` as `{:braintree, "~> 0.16"}`** [VERIFIED: codebase grep]. Resolved version in `accrue/mix.lock`: **0.16.0** (released 2025-03-27) [VERIFIED: mix.lock line 3, Hex.pm].

**API surface (used in Phase 101):**
- `Braintree.ClientToken.generate/1` — generate a token, optionally scoped via `customer_id: ...` opt
- `Braintree.Customer.{create,find,update,delete}/1,2` — already wired through `Accrue.Processor.Braintree.create_customer/2` etc.
- `Braintree.PaymentMethod.{create,find,update,delete}/1,2,3` — already wired
- `Braintree.Subscription.{create,find,cancel,update}/1,2,3` — already wired
- `Braintree.Webhook.parse/3` — already wired in `Accrue.Webhook.Signature.parse_braintree!/3`

**Maintenance status:** Last release 0.16.0 (2025-03-27), 14+ months old as of research date. The library is feature-complete for Accrue's needs (Customer, PaymentMethod, Subscription, Transaction, Webhook all covered) but not actively iterating. Its dependency on `:hackney` rather than `:finch` is a minor inconsistency with the Accrue stack but does not block Phase 101.

[CITED: hex.pm/packages/braintree, github.com/sorentwo/braintree-elixir]
[VERIFIED: codebase — `accrue/mix.exs:58`, `accrue/mix.lock:3`]

**Phase 101 use:** No new gateway calls beyond what's already adapter-mapped. The Phase 101 adapter additions (`checkout_session_create/2`, `checkout_session_fetch/2`, `portal_session_create/2`) **do not call Braintree directly** — they synthesize local URLs from `:portal_base_url` + `:portal_mount_path` + a generated session token, persisted in the new `accrue_checkout_sessions` table.

The browser-side `client_token` generation (called from `Accrue.Portal.Live.CheckoutLive.mount/3`) IS a Braintree API call: `Braintree.ClientToken.generate(customer_id: customer.processor_id)`.

### 3. Braintree webhook signature verification in Plug

**Confidence: HIGH** (verified against codebase — already implemented).

**Status:** **Already complete in core.** `accrue/lib/accrue/webhook/plug.ex:78-114` and `accrue/lib/accrue/webhook/signature.ex:40-52` together implement the full Braintree webhook verification pipeline. Phase 101 does NOT modify webhook plumbing.

**Mechanism:**
1. Host mounts `Accrue.Webhook.Plug` at a route they choose (e.g., `/webhooks/braintree`), passing `processor: :braintree`. Pipeline runs `Accrue.Webhook.CachingBodyReader` BEFORE `Plug.Parsers` to capture raw body in `conn.assigns[:raw_body]` (CLAUDE.md non-bypassable invariant).
2. Braintree POSTs `bt_signature=<sig>&bt_payload=<base64-xml>` form-encoded.
3. `Accrue.Webhook.Signature.parse_braintree!/3` calls `Braintree.Webhook.parse(bt_signature, bt_payload, opts)` which:
   - Verifies HMAC-SHA1 signature using merchant private key (configured via `Application.get_env(:braintree, :private_key)`)
   - Base64-decodes and XML-decodes the payload
   - Returns `%{"notification" => %{"kind" => ..., "subject" => ..., "timestamp" => ...}}`
4. The plug constructs a `pseudo_event = %LatticeStripe.Event{}` (codebase reuses LS event shape for both Stripe and Braintree to keep `Ingest.run/4` polymorphic) with `id: "bt_<sha256-of-payload>"` (Braintree webhooks lack unique ids — content-hash is the idempotency key).
5. `Accrue.Webhook.Ingest.run/4` performs the transactional persist + Oban enqueue + `accrue_events` ledger entry in one `Ecto.Multi`.

**Phase 101 webhook surface:**
- The synthetic `accrue.portal.checkout.completed` event (D-13) is **not** generated via this plug — it's enqueued by an Oban worker (`Accrue.Portal.Checkout.CompletionJob`) that writes a row directly into the `accrue_webhook_events` table with `source: "accrue.portal"` (distinct from `"braintree"` and `"stripe"` source values).
- The existing `Accrue.Webhook.DefaultHandler` reduces all events through the same projection path; the `source: "accrue.portal"` events flow through unchanged because the handler dispatches on `type`, not `source`.

[CITED: hexdocs.pm/braintree/Braintree.Webhook.html (v0.16.0)]
[VERIFIED: codebase — `accrue/lib/accrue/webhook/plug.ex:78-114`, `accrue/lib/accrue/webhook/signature.ex:40-52`]

### 4. `Accrue.Portal` router pipeline conventions

**Confidence: HIGH** (mirror admin precedent verbatim).

**Macro signature** (mirroring `AccrueAdmin.Router.accrue_admin/2` at `accrue_admin/lib/accrue_admin/router.ex:24-86`):

```elixir
defmacro accrue_portal(path, opts \\ []) do
  opts = Macro.expand_literals(opts, __CALLER__)
  validated = validate_opts!(path, opts)
  # ... emit pipeline + scope + live_session + asset routes
end
```

**Validated options:**
- `:on_mount` — additional LiveView on_mount hooks (default: `[{Accrue.Portal.AuthHook, :ensure_customer}]`)
- `:session_keys` — host session keys threaded into LV session (default: `[]`, hosts pass `[:user_token]` for phx.gen.auth)
- `:csp_nonce_assign_key` — reserved for CSP hardening
- `:layout` — opt-in to embed in host layout (mirror admin's `layout` option). When set: `layout: {MyAppWeb.Layouts, :app}`. UI-SPEC §Layout Strategy line 71.
- `:unauthenticated_path` — redirect target on `current_user == nil` (default: `"/"`)

**Emitted shape:**

```elixir
pipeline :accrue_portal_browser do
  plug :fetch_session
  plug :protect_from_forgery
  plug Accrue.Portal.CSPPlug    # Hosted Fields allowlist (D-22)
  plug Accrue.Portal.BrandPlug  # mirror AccrueAdmin.BrandPlug
end

scope mount_path, as: :accrue_portal do
  get "/assets/brand-#{Accrue.Portal.Assets.brand_hash()}", Accrue.Portal.Assets, :brand
  get "/assets/css-#{Accrue.Portal.Assets.css_hash()}", Accrue.Portal.Assets, :css
  get "/assets/js-#{Accrue.Portal.Assets.js_hash()}", Accrue.Portal.Assets, :js

  pipe_through :accrue_portal_browser

  live_session :accrue_portal,
    root_layout: {Accrue.Portal.Layouts, :root},
    on_mount: on_mount,
    session: {Accrue.Portal.Router, :__session__, [session_keys, mount_path]} do
    live "/", Accrue.Portal.Live.HomeLive, :index
    live "/checkout/:session_token", Accrue.Portal.Live.CheckoutLive, :show
    live "/subscriptions", Accrue.Portal.Live.SubscriptionsLive, :index
    live "/subscriptions/:id", Accrue.Portal.Live.SubscriptionLive, :show
    live "/payment-methods", Accrue.Portal.Live.PaymentMethodsLive, :index
    live "/payment-methods/new", Accrue.Portal.Live.AddPaymentMethodLive, :new
    live "/invoices", Accrue.Portal.Live.InvoicesLive, :index
  end
end
```

**Sibling-mount discipline (D-21):** `accrue_portal/2` and `accrue_admin/2` are sibling macro invocations. Distinct `live_session` ids prevent the Phase 88 nested-live_session bug. Document this explicitly in install guide:

```elixir
# examples/accrue_host/lib/accrue_host_web/router.ex (post-D-24)
scope "/" do
  pipe_through :browser
  accrue_admin "/admin"        # was "/billing"
  accrue_portal "/billing"     # new
end
```

**Asset serving:** Mirror `AccrueAdmin.Assets`. The Hosted Fields JS bundle is NOT served from the package — it's loaded from `js.braintreegateway.com` CDN with SRI pinning. Only the LV-hook bridge JS (`hosted_fields.js`) ships from the package's hashed `/assets/js-<hash>` route.

**CSP plug** must extend `AccrueAdmin.CSPPlug` shape with the Braintree allowlist (UI-SPEC §CSP Allowlist line 386-396):

```elixir
"default-src 'self'",
"base-uri 'self'",
"connect-src 'self' wss: https://*.braintreegateway.com https://*.braintree-api.com https://api.braintreegateway.com",
"font-src 'self' data:",
"img-src 'self' data: https:",
"object-src 'none'",
"script-src 'self' 'nonce-#{nonce}' https://js.braintreegateway.com https://assets.braintreegateway.com",
"style-src 'self' 'nonce-#{nonce}' 'unsafe-inline'",
"frame-src 'self' https://assets.braintreegateway.com https://*.braintreegateway.com",
"frame-ancestors 'self'"
```

`'unsafe-inline'` on `style-src` is a Hosted Fields requirement (the SDK injects style tags into iframe documents) — documented trade-off compensated by strict-nonce script-src and tight frame-src allowlist.

[VERIFIED: codebase — `accrue_admin/lib/accrue_admin/router.ex:1-190`, `accrue_admin/lib/accrue_admin/csp_plug.ex:1-32`]

### 5. `create_checkout_session/2` API shape

**Confidence: HIGH** (verified against codebase + CONTEXT.md D-06/D-11/D-12).

**Function location:** `Accrue.Billing.create_checkout_session/2` at `accrue/lib/accrue/billing.ex:520-528` — **unchanged at the facade**. Dispatches through `Accrue.Checkout.Session.create/1` which calls `Processor.__impl__().checkout_session_create/2` (`accrue/lib/accrue/checkout/session.ex:81-91`).

**Phase 101 implementation site:** `accrue/lib/accrue/processor/braintree.ex:355` — replace the stub `def checkout_session_create(_params, _opts), do: {:error, unsupported()}` with a real implementation.

**Inputs (already validated by NimbleOptions schema at `accrue/lib/accrue/checkout/session.ex:55-70`):**
- `:customer` — `%Accrue.Billing.Customer{}` or processor_id string
- `:mode` — `:subscription | :payment | :setup` (default `:subscription`)
- `:ui_mode` — `:hosted | :embedded` (default `:hosted`; Braintree only supports `:hosted` per D-09/D-11)
- `:line_items` — list of maps (Stripe-compatible shape; Braintree adapter extracts plan/price)
- `:success_url`, `:cancel_url`, `:return_url` — host-supplied (D-10)
- `:metadata`, `:client_reference_id` — pass-through
- `:operation_id` — idempotency key (D-12)

**Outputs:** `%Accrue.Checkout.Session{url: <portal-url>, id: <token>, ui_mode: "hosted", mode: "subscription", expires_at: <utc-datetime>, ...}`

**Token lifecycle (D-11, D-12):**
- URL shape: `{portal_base_url}{portal_mount_path}/checkout/{opaque_session_token}`
- `opaque_session_token` = base64url-encoded random 32 bytes (`:crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)`) — NOT a JWT, NOT a signed token. Pure DB lookup primary key.
- DB row in `accrue_checkout_sessions`:
  - `id` — UUID (from `Accrue.Processor.Idempotency.subject_uuid(:checkout_session_create, operation_id)`)
  - `token` — opaque session token (unique index)
  - `customer_processor_id` — Braintree customer id (string)
  - `mode` — `"subscription" | "payment" | "setup"`
  - `line_items` — JSONB snapshot
  - `success_url`, `cancel_url`, `return_url` — string nullable
  - `metadata` — JSONB
  - `client_reference_id` — string nullable
  - `status` — `"open" | "complete" | "expired"`
  - `expires_at` — UTC, default now() + 24h
  - `operation_id` — string, **unique index** (D-12 idempotency)
  - `inserted_at`, `updated_at`
- Idempotency: same `operation_id` → same row → same token → same URL. Implemented via `INSERT ... ON CONFLICT (operation_id) DO NOTHING RETURNING *`.
- Replay protection: token is single-binding to one customer (resolved at row-insert); LV mount checks `socket.assigns.current_customer.id == session.customer_id` (D-19 defense-in-depth).

**Suggested module layout (net-new):**
- `accrue/lib/accrue/checkout/local_session.ex` — Ecto schema + insert/fetch helpers (CONTEXT.md "Integration Points")
- `accrue/priv/repo/migrations/<ts>_create_accrue_checkout_sessions.exs` — table migration

**Adapter pseudocode** (Braintree adapter implementation):

```elixir
@impl Accrue.Processor
def checkout_session_create(params, opts) do
  operation_id = Keyword.get(opts, :operation_id)
  token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

  attrs = %{
    id: Accrue.Processor.Idempotency.subject_uuid(:checkout_session_create, operation_id),
    token: token,
    customer_processor_id: Map.get(params, "customer"),
    mode: Map.get(params, "mode"),
    line_items: Map.get(params, "line_items", []),
    success_url: Map.get(params, "success_url"),
    cancel_url: Map.get(params, "cancel_url"),
    return_url: Map.get(params, "return_url"),
    metadata: Map.get(params, "metadata"),
    client_reference_id: Map.get(params, "client_reference_id"),
    operation_id: operation_id,
    status: "open",
    expires_at: DateTime.utc_now() |> DateTime.add(24 * 3600, :second)
  }

  {:ok, row} = Accrue.Checkout.LocalSession.upsert(attrs)

  url = build_portal_url(row.token)
  {:ok, %{
    "id" => row.id,
    "object" => "checkout.session",
    "url" => url,
    "ui_mode" => "hosted",
    "mode" => row.mode,
    "status" => row.status,
    "customer" => row.customer_processor_id,
    "expires_at" => row.expires_at,
    "metadata" => row.metadata
  }}
end

defp build_portal_url(token) do
  base = Accrue.Config.fetch!(:portal_base_url)
  mount = Accrue.Config.get(:portal_mount_path, "/accrue/portal")
  "#{base}#{mount}/checkout/#{token}"
end
```

**Resolved for execution:** keep the public `line_items` contract Stripe-shaped and translate to Braintree `plan_id` inside the adapter. This matches D-06/D-15 and the existing `Accrue.Processor.Braintree.build_request/1` extraction path at `processor/braintree.ex:70-83`.

[VERIFIED: codebase — `accrue/lib/accrue/billing.ex:485-528`, `accrue/lib/accrue/checkout/session.ex:1-272`, `accrue/lib/accrue/processor/idempotency.ex:1-40`]

### 6. Customer portal LiveView pages

**Confidence: HIGH** (UI-SPEC §Component Inventory line 304-330 is exhaustive).

**Seven LiveView modules** (UI-SPEC line 308-314):

| Module | Route | Purpose | Hosted Fields? |
|--------|-------|---------|----------------|
| `Accrue.Portal.Live.HomeLive` | `/` | Dashboard: active subs + default PM + recent invoice | No |
| `Accrue.Portal.Live.CheckoutLive` | `/checkout/:session_token` | Hosted Fields checkout — single column, no nav rail | YES |
| `Accrue.Portal.Live.SubscriptionsLive` | `/subscriptions` | List active + canceled subs | No |
| `Accrue.Portal.Live.SubscriptionLive` | `/subscriptions/:id` | One-sub detail: status, next bill, payment method, manage | No |
| `Accrue.Portal.Live.PaymentMethodsLive` | `/payment-methods` | List vaulted PMs, set default, delete, add new | No (links to AddPaymentMethodLive) |
| `Accrue.Portal.Live.AddPaymentMethodLive` | `/payment-methods/new` | Hosted Fields form — vault-only flow (no charge) | YES |
| `Accrue.Portal.Live.InvoicesLive` | `/invoices` | List historical invoices | No |

**Hosted Fields hook reuse (CheckoutLive vs AddPaymentMethodLive):**

Both LVs need the same `phx-hook="AccrueHostedFields"` mechanism. Recommend a **shared HEEx component** `Accrue.Portal.Components.HostedFieldsForm` with attrs:
- `:client_token` — Braintree client token
- `:on_tokenized` — atom event name to dispatch on success (default `"hosted_fields_tokenized"`)
- `:submit_label` — string (e.g., `"Pay $29.00"` for checkout, `"Save card"` for add-PM)
- `:amount` — money for display only (nil for AddPaymentMethodLive)

UI-SPEC §Component Inventory line 322 names `Accrue.Portal.Components.HostedFieldsWrapper` for the iframe-host `<div>`; the LV-rendering wrapper above is a different component (the form composition).

The two LVs differ in `handle_event("hosted_fields_tokenized", ...)`:
- `CheckoutLive`: nonce → `Accrue.Billing.subscribe(customer, %{vault_acquisition: %{reference: nonce}, items: [%{price: plan_id}]})` → on success, enqueue `Accrue.Portal.Checkout.CompletionJob` and `push_navigate(to: success_url || home_path)`
- `AddPaymentMethodLive`: nonce → `Accrue.Billing.add_payment_method(customer, %{vault_acquisition: %{reference: nonce}})` → on success, `push_navigate(to: payment_methods_path)`

**Defense-in-depth (D-19):** Every LV's `mount/3` MUST scope by `socket.assigns.current_customer.id`:

```elixir
def mount(%{"id" => id}, _session, socket) do
  case Accrue.Billing.get_subscription_for_customer(id, socket.assigns.current_customer) do
    nil -> {:ok, socket |> put_flash(:error, "Page not found") |> redirect(to: ~p"/"), layout: false}
    subscription -> {:ok, assign(socket, subscription: subscription)}
  end
end
```

UI-SPEC §Security Visual Contract line 425-434 mandates the 404 response (not "you don't have access") to prevent side-channel leakage between "doesn't exist" and "exists but not yours."

**State of in-scope work for v1.33:** All 7 LVs ship at v1.33. Coupon entry on checkout is OUT (Phase 102 / BT-04). Apple/Google Pay buttons OUT. Plan-picker UI OUT (host-rendered).

[VERIFIED: codebase — `accrue_admin/lib/accrue_admin/live/` 18 modules; UI-SPEC line 304-330]

### 7. Existing Accrue codebase patterns

**Confidence: HIGH** (direct codebase inspection).

**`Accrue.Processor` behaviour** (`accrue/lib/accrue/processor.ex`):
- `__impl__/0` returns the configured adapter module (default `Accrue.Processor.Fake`)
- `supports?/1` walks the capability map; `[:checkout, :create]` checks `capabilities.checkout.create == true`
- `Capabilities.support_label/1` returns the human-readable label (`"all first-party"`, `"Stripe-only"`, etc. — `accrue/lib/accrue/processor/capabilities.ex:11-52`)

**Braintree adapter (`accrue/lib/accrue/processor/braintree.ex`):**
- 645 lines, fully implements: customer, subscription (create/cancel/update with restrictions), payment_method (full CRUD + set_default), refund (with status validation)
- 5 stubs to implement in Phase 101: `checkout_session_create/2:355`, `checkout_session_fetch/2:357`, `portal_session_create/2:359`. (Note: `portal_session_create/2` is NOT named in CONTEXT.md cleanly — verify the stub function naming when planning.)
- Capability map at lines 14-40: needs the D-09 changes (add `checkout: %{...}`, flip `billing_portal.create: true`).

**Modified files in working tree** (from `git status`):
- `accrue/lib/accrue/billing/subscription_projection.ex` — modified, **NOT directly related to Phase 101**. Read this to confirm before planning.
- `accrue/test/accrue/processor/stripe_test.exs` — modified, **NOT related to Phase 101**.
- `accrue/test_script.exs` — untracked scratch file.

**Existing checkout/billing_portal infrastructure to REUSE (CONTEXT.md "Reusable Assets" line 167-174):**
- `Accrue.Checkout.Session` struct + `ensure_checkout_support!/1` + `ensure_ui_mode_support!/1` work as-is once Braintree adapter flips capabilities to true.
- `Accrue.APIError{code: :unsupported_by_gateway}` stays as fallback for hosts who haven't mounted `accrue_portal`.
- `Accrue.Auth.current_user/1` reused unchanged.
- `Accrue.Processor.Idempotency.subject_uuid/2` reused for `accrue_checkout_sessions.id` derivation.
- `Accrue.Webhook.DefaultHandler` reduces synthetic events through projection unchanged.

**Mount-macro precedent to mirror (CONTEXT.md "Mount-macro precedent" line 139-144):**
- `accrue_admin/lib/accrue_admin/router.ex` — macro shape (190 lines)
- `accrue_admin/lib/accrue_admin/auth_hook.ex` — callback module pattern (35 lines)
- `accrue_admin/lib/accrue_admin/csp_plug.ex` — CSP shape (32 lines)
- `accrue_admin/lib/accrue_admin/brand_plug.ex` — brand plug pattern

**Net-new files (CONTEXT.md "Integration Points" line 187-196):**
- `accrue/lib/accrue/checkout/local_session.ex` — Ecto schema for `accrue_checkout_sessions`
- `accrue/priv/repo/migrations/<ts>_create_accrue_checkout_sessions.exs` — DB migration
- `accrue/lib/accrue/portal/checkout/completion_job.ex` — Oban worker writing synthetic event
- Full new package `accrue_portal/` — mix.exs, application.ex, router.ex, auth_hook.ex, csp_plug.ex, brand_plug.ex, layouts.ex, copy.ex, assets.ex, components/*, live/*, README, CHANGELOG, ExDoc config, test/

**Adapter changes:**
- `accrue/lib/accrue/processor/braintree.ex:14-40` — capability map (add checkout, flip billing_portal)
- `accrue/lib/accrue/processor/braintree.ex:355` — `checkout_session_create/2` real impl
- `accrue/lib/accrue/processor/braintree.ex:357` — `checkout_session_fetch/2` real impl
- `accrue/lib/accrue/processor/braintree.ex:359` — `portal_session_create/2` real impl
- `accrue/lib/accrue/processor/capabilities.ex:11-52` — `@support_labels` vocabulary additions

**ExDoc updates only (no behavior change):**
- `accrue/lib/accrue/billing.ex:485-528` — note Braintree now supported, link to `accrue_portal` install guide

[VERIFIED: codebase — direct inspection of all referenced paths]

### 8. Validation Architecture (Nyquist)

See full **§Validation Architecture** section below.

### 9. Security threat model inputs

**Confidence: HIGH** (synthesis from CONTEXT.md D-19, D-22 + UI-SPEC §Security Visual Contract + STRIDE analysis).

**Braintree-specific threats and mitigations:**

| Threat | STRIDE | Mitigation | Source |
|--------|--------|------------|--------|
| Client token leakage allowing iframe injection on attacker site | Spoofing | Server-only generation; scope to customer via `Braintree.ClientToken.generate(customer_id: id)`; short TTL (Braintree default ~24h); never log token; never embed in URLs | Braintree docs |
| Nonce replay (same nonce used to charge twice) | Tampering | Braintree-side single-use nonces; server passes nonce to `Braintree.PaymentMethod.create` exactly once; subsequent reuse returns Braintree error | Braintree single-use-nonce semantics |
| Webhook spoofing (forged Braintree webhook) | Spoofing | HMAC-SHA1 verify via `Braintree.Webhook.parse/3` using merchant private key; fail-closed (raise `Accrue.SignatureError` → 400) | Existing `Accrue.Webhook.Plug:78-114` |
| Webhook replay | Tampering | Content-hash idempotency (`event_id = "bt_" <> sha256(payload)`); `Accrue.Webhook.Ingest` rejects duplicate event_ids transactionally | Existing `Accrue.Webhook.Plug:96` |
| Hosted Fields iframe re-framed by attacker (clickjacking) | Spoofing | `frame-ancestors 'self'` CSP header; `X-Frame-Options: SAMEORIGIN` on portal pages | UI-SPEC §CSP line 386-396 |
| Session fixation in checkout flow | Tampering | Opaque session token bound to customer at row-insert; LV mount re-validates `socket.assigns.current_customer.id == session.customer_id`; Plug `:protect_from_forgery` on every form submit | D-19; UI-SPEC §Security |
| Wrong-tenant URL guess (`/subscriptions/:id` for someone else's sub) | Information disclosure | Defense-in-depth: every Portal LV query scopes to `socket.assigns.current_customer.id`; 404 (not "you don't have access") response on mismatch — identical between "doesn't exist" and "exists but not yours" | D-19; UI-SPEC line 425-434 |
| PII / PAN / CVV stored on Accrue server | Information disclosure | Hosted Fields iframes prevent PAN/CVV from ever crossing server origin; only nonce + last4 + brand + bin reach the server. No `payment_method_details` columns store full card data; references stored as Braintree vault tokens only | Architectural — Hosted Fields PCI SAQ-A |
| Checkout token reuse after expiry | Repudiation | `expires_at` enforced at LV mount; `status: "expired"` rows return 404; after subscription create, status flips to `"complete"` and reuse 404s | §5 Token lifecycle |
| Session token brute-force | Tampering | 32 bytes (256 bits) of `:crypto.strong_rand_bytes` → 2^256 keyspace; rate-limit at host's reverse proxy (host responsibility, document in install guide) | OWASP general |
| CSP bypass via `'unsafe-inline'` style-src | Tampering | `'unsafe-inline'` is **required** by Hosted Fields (SDK injects style tags into iframes); compensated by strict-nonce script-src + tight frame-src allowlist (`*.braintreegateway.com` only); document trade-off in install guide | UI-SPEC line 397-398 |
| CSRF on form submits | Tampering | `protect_from_forgery` plug emits/verifies CSRF tokens; LiveView's `phx-submit` flow auto-includes `_csrf_token` | Phoenix default |
| Logging of secret material (client_token, nonce, webhook private key) | Information disclosure | Never log: `Braintree.private_key` (config-only), `client_token` (struct masked via `Inspect`), `nonce` (single-use, but redact in logs), `Accrue.Checkout.Session.client_secret` (already masked at `accrue/lib/accrue/checkout/session.ex:274-303`) | CLAUDE.md security non-bypassable |

**Threat model handoff:** Planner uses this table to populate `<threat_model>` block in the plan-phase artifact. Each row maps directly to a verification step (positive test + negative test).

### 10. Execution-readiness resolutions

**Resolved decisions and plan bindings:**

1. **Drop-in deprecation dates** — Treat `101-CONTEXT.md` as the project record for internal planning, but keep exact dates out of user-facing portal docs in Phase 101. The execution plans already describe Hosted Fields as the supported path without depending on a disputed date string.

2. **`portal_session_create/2` callback signature** — Resolved in favor of the existing processor callback name already present in `accrue/lib/accrue/processor/braintree.ex:359`. Plan 03 owns aligning the Braintree adapter and public facade around that callback instead of inventing a new verb.

3. **`line_items` contract** — Resolved in favor of Stripe-shaped `line_items`, translated inside the adapter. This preserves the locked facade contract and avoids a Braintree-specific public payload shape.

4. **Synthetic completion-event idempotency** — Resolved by using the persisted checkout-session identity as the natural dedupe key for `accrue.portal.checkout.completed`. Plan 04 owns implementing and testing that worker/event path.

5. **Portal mount-path asset exposure** — Resolved by mirroring the existing `accrue_admin` hashed-asset/session-threading pattern rather than inventing a second asset-link strategy for LiveView templates.

6. **Wave 0 test ownership** — Resolved across the plan set: Plan 01 owns `accrue/test/support/checkout_session_fixture.ex` plus migration schema coverage, Plan 02 owns `accrue_portal/test/test_helper.exs`, `accrue_portal/test/support/conn_case.ex`, and `accrue_portal/test/support/braintree_mox.ex`, Plan 05 owns `accrue_portal/test/support/fixtures.ex` and `accrue_portal/test/support/authorize_assertions.ex`, and Plan 06 owns the remaining release/example/doc integration proof.

**Execution notes (mitigated, not blockers):**

- **JS asset bundling** — Use the same asset-build posture `accrue_admin` already ships; Plan 04 owns the Hosted Fields JS/CSS work, so this is not an unresolved architecture choice.
- **Braintree sandbox dependence** — Keep automated coverage on Mox/Fake-backed tests; any live-sandbox checks remain manual-only verification, not execution blockers.
- **LiveView `phx-update="ignore"` semantics** — The research already verified the required hook pattern against LiveView 1.1 docs; Plan 04 owns the concrete regression tests.
- **Release Please v4 naming** — Plan 06 now machine-verifies the three-package linked-versions group and package entries directly from `release-please-config.json`.
- **Example-host path collision** — Plan 06 owns the `/admin` + `/billing` sibling-mount example update explicitly.
- **Dark-mode Hosted Fields restyling** — Treat this as an implementation note under the existing UI contract; it is not a planning gap.

## Standard Stack

### Core (additions for `accrue_portal` package)
| Library | Version | Purpose | Why Standard | Source |
|---------|---------|---------|--------------|--------|
| `:phoenix` | `~> 1.8` | Router, Endpoint, Plug | Locked CLAUDE.md | [VERIFIED: project] |
| `:phoenix_live_view` | `~> 1.1` | LV runtime | Locked CLAUDE.md; current 1.1.28 (2026-03-27) | [VERIFIED: hex.pm] |
| `:phoenix_html` | `~> 4.2` | HEEx helpers | LV 1.1 requires phoenix_html 4.x | [VERIFIED: hex.pm] |
| `:plug` | `~> 1.16` | Plug runtime | Phoenix transitive; CLAUDE.md pin | [VERIFIED: project] |
| `:jason` | `~> 1.4` | JSON encoding (LV pushEvent payloads, CSP nonce) | Stack default | [VERIFIED: project] |
| `:accrue` | `== <same version>` | Core billing facade | Path-dep in dev, version-pinned in published releases | CONTEXT.md D-04 |

### Browser-side (loaded from CDN, not bundled)
| Library | Version | Purpose | CDN URL |
|---------|---------|---------|---------|
| `braintree-web/client` | `3.141.0` | Braintree client SDK | `https://js.braintreegateway.com/web/3.141.0/js/client.min.js` [VERIFIED: npm registry] |
| `braintree-web/hosted-fields` | `3.141.0` | Hosted Fields module | `https://js.braintreegateway.com/web/3.141.0/js/hosted-fields.min.js` [VERIFIED: Braintree docs] |

SRI hash pinning is required (UI-SPEC line 400). Compute hash at planning time; record in PLAN.md and `accrue_portal/lib/accrue_portal/braintree_assets.ex` (or similar). Document upgrade procedure in install guide.

### Already in `accrue/mix.exs` (no changes)
| Library | Version | Used For |
|---------|---------|----------|
| `:braintree` | `~> 0.16` (resolved 0.16.0) | `Braintree.ClientToken.generate/1`, `Braintree.Webhook.parse/3`, etc. |
| `:oban` | `~> 2.21` | `Accrue.Portal.Checkout.CompletionJob` (synthetic event worker) |
| `:ecto`, `:ecto_sql`, `:postgrex` | `~> 3.13` / `~> 0.22` | `accrue_checkout_sessions` schema + migration |
| `:nimble_options` | `~> 1.1` | `Accrue.Portal.Router.accrue_portal/2` opts validation |
| `:telemetry` | `~> 1.3` | `[:accrue, :portal, :checkout, :completed]` event |

### Dev / Test (additions to `accrue_portal/mix.exs`)
| Library | Version | `only:` | Purpose |
|---------|---------|---------|---------|
| `:lazy_html` | `>= 0.1.0` | `[:test]` | LiveView render-text assertions (mirror `accrue_admin/mix.exs:54`) |
| `:plug_cowboy` | `~> 2.7` | `[:test]` | Test endpoint (mirror admin) |
| `:mox` | `~> 1.2` | `[:test]` | Mock Braintree adapter calls |
| `:ex_doc` | `~> 0.40` | `[:dev, :test]` | Docs build |
| `:credo` | `~> 1.7` | `[:dev, :test]` | Lint |
| `:dialyxir` | `~> 1.4` | `[:dev, :test]` | Dialyzer |

**Installation (new package):**

```elixir
# accrue_portal/mix.exs
defp deps do
  [
    accrue_dep(),
    {:phoenix, "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    {:phoenix_html, "~> 4.2"},
    {:plug, "~> 1.16"},
    {:jason, "~> 1.4"},
    {:plug_cowboy, "~> 2.7", only: :test},
    {:lazy_html, ">= 0.1.0", only: :test},
    {:mox, "~> 1.2", only: :test},
    {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
  ]
end

defp accrue_dep do
  if System.get_env("ACCRUE_PORTAL_HEX_RELEASE") == "1" do
    {:accrue, "~> #{@version}"}
  else
    {:accrue, path: "../accrue"}
  end
end
```

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hosted Fields | Drop-in for Web | Drop-in deprecated (CONTEXT.md U-01); Hosted Fields is the supported path |
| `:braintree` 0.16.0 (sorentwo) | Hand-rolled HTTPoison/Finch + Braintree GraphQL | sorentwo lib already covers all calls Phase 101 needs; switching = pure overhead; lib is feature-stable |
| Macro `accrue_portal/2` | Plug + manual wiring | Macro emits ~3-line host integration vs ~30-50 lines manual; mirrors admin precedent (advisor research D.1) |
| New `Accrue.Portal.Auth` behaviour | Reuse `Accrue.Auth` + callback module | Behaviour duplicates existing contract; callback module mirrors `AccrueAdmin.AuthHook` exactly (advisor research D.2) |
| URL-token magic-link checkout | Session-resolved customer only | Token-in-URL has nontrivial security surface (referer leakage, replay); deferred to v1.34+ with documented host-side workaround (advisor research D.3) |
| Embedded Hosted Fields (`:ui_mode :embedded`) | Hosted-only `:ui_mode :hosted` | Embedded adds JS bundle distribution complexity; not in BT-02 success criteria; deferred (CONTEXT.md D-11) |
| Vendoring Braintree JS in `priv/static` | CDN load with SRI | CDN matches how Stripe.js is loaded across the Phoenix ecosystem; SRI provides integrity guarantees without bundle distribution |
| Building unified Stripe+Braintree portal | Braintree-only escape hatch (Scope 1) | Unified portal would lose Stripe's Link, Apple/Google Pay, Radar, ~35 locales — severe regression for existing Stripe adopters (advisor research C) |

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Browser                                                                     │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Phoenix LiveView page (CheckoutLive / AddPaymentMethodLive)         │   │
│  │  ┌────────────────────────────────────────────────────────────────┐  │   │
│  │  │  phx-hook="AccrueHostedFields"  (assets/js/hooks/hosted_fields)│  │   │
│  │  │     │                                                          │  │   │
│  │  │     ▼                                                          │  │   │
│  │  │  Braintree SDK (CDN, SRI-pinned)                               │  │   │
│  │  │     │                                                          │  │   │
│  │  │     ▼                                                          │  │   │
│  │  │  ┌────────┐  ┌──────────┐  ┌─────┐                            │  │   │
│  │  │  │ Number │  │ Expiry   │  │ CVV │  iframes (Braintree-hosted)│  │   │
│  │  │  └────────┘  └──────────┘  └─────┘                            │  │   │
│  │  │       │            │           │                              │  │   │
│  │  │       └────────────┴───────────┘                              │  │   │
│  │  │                    │                                          │  │   │
│  │  │                    ▼                                          │  │   │
│  │  │             tokenize() → nonce                                │  │   │
│  │  │                    │                                          │  │   │
│  │  └────────────────────┼──────────────────────────────────────────┘  │   │
│  │                       │ pushEvent("hosted_fields_tokenized", {nonce})│   │
│  └───────────────────────┼─────────────────────────────────────────────┘   │
└──────────────────────────┼─────────────────────────────────────────────────┘
                           │ WebSocket (LV channel)
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  Phoenix Server (host app, accrue_portal mounted via accrue_portal/2)       │
│                                                                              │
│  ┌──────────────────────┐         ┌────────────────────────────────────┐    │
│  │ pipeline             │         │ live_session :accrue_portal        │    │
│  │ :accrue_portal_      │  ──▶    │   on_mount: AuthHook(:ensure_      │    │
│  │  browser             │         │     customer)                      │    │
│  │  - fetch_session     │         │   ┌──────────────────────────────┐ │    │
│  │  - protect_from_     │         │   │ CheckoutLive.handle_event/3  │ │    │
│  │     forgery          │         │   │  ("hosted_fields_tokenized")  │ │    │
│  │  - CSPPlug (Hosted   │         │   └──────────┬───────────────────┘ │    │
│  │     Fields allow-    │         │              │                     │    │
│  │     list)            │         │              ▼                     │    │
│  │  - BrandPlug         │         │   Accrue.Billing.subscribe/3       │    │
│  └──────────────────────┘         │   (with vault_acquisition.ref=     │    │
│                                   │    nonce)                          │    │
│                                   │              │                     │    │
│                                   └──────────────┼─────────────────────┘    │
│                                                  │                           │
│  ┌────────────────────────────────────┐         ▼                           │
│  │ Accrue.Processor.Braintree         │  Accrue.Processor.__impl__()        │
│  │ (adapter)                          │         │                           │
│  │  - create_payment_method (vault)   │  ◄──────┘                           │
│  │  - create_subscription             │                                     │
│  │  - checkout_session_create  ◄── synthesizes URL from DB token            │
│  │  - portal_session_create   ◄── ditto                                     │
│  └─────────────────┬──────────────────┘                                     │
│                    │                                                         │
│                    ▼                                                         │
│  ┌────────────────────────────┐    ┌──────────────────────────────────┐     │
│  │ Braintree library          │    │ accrue_checkout_sessions table   │     │
│  │ (sorentwo/braintree-elixir)│    │  (new in Phase 101)              │     │
│  │  - ClientToken.generate    │    │   - token (uniq), customer_id,   │     │
│  │  - PaymentMethod.create    │    │     mode, line_items, expires_at │     │
│  │  - Subscription.create     │    │   - operation_id (uniq) for      │     │
│  │  - Webhook.parse           │    │     idempotency                  │     │
│  └────────┬───────────────────┘    └──────────────────────────────────┘     │
│           │                                                                  │
│           │ HTTPS (hackney)                                                  │
│           ▼                                                                  │
│  ┌──────────────────┐                                                        │
│  │ Braintree API    │                                                        │
│  │ (PayPal-owned)   │                                                        │
│  └──────────────────┘                                                        │
│                                                                              │
│  Webhook ingress (separate path, already built):                             │
│                                                                              │
│  POST /webhooks/braintree (host route)                                       │
│           │                                                                  │
│           ▼                                                                  │
│  ┌────────────────────────────┐                                              │
│  │ Accrue.Webhook.Plug        │                                              │
│  │  - CachingBodyReader       │                                              │
│  │    (raw body BEFORE parse) │                                              │
│  │  - Signature.parse_braintree!                                             │
│  │    (HMAC-SHA1 verify)      │                                              │
│  │  - Ingest.run (Multi)      │                                              │
│  └────────┬───────────────────┘                                              │
│           │                                                                  │
│           ▼                                                                  │
│  ┌────────────────────────────┐    ┌──────────────────────────────────┐     │
│  │ accrue_webhook_events      │ ◄──│ Accrue.Portal.Checkout.          │     │
│  │ (existing table)           │    │ CompletionJob (Oban)             │     │
│  │                            │    │  Synthesizes event:              │     │
│  │                            │    │   type:"accrue.portal.checkout.  │     │
│  │                            │    │     completed", source:          │     │
│  │                            │    │   "accrue.portal"                │     │
│  └─────────┬──────────────────┘    └──────────────────────────────────┘     │
│            │                                                                 │
│            ▼                                                                 │
│  ┌─────────────────────────────────┐                                         │
│  │ Accrue.Webhook.DefaultHandler   │                                         │
│  │  (existing, dispatches on type) │                                         │
│  │  Updates subscription_projection│                                         │
│  └─────────────────────────────────┘                                         │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

```
accrue_portal/
├── mix.exs                                # version-locked to accrue
├── README.md                              # screenshots + 5-line install
├── CHANGELOG.md                           # release-please-driven
├── lib/
│   └── accrue_portal/
│       ├── application.ex                 # supervisor (likely empty stub like AccrueAdmin)
│       ├── router.ex                      # accrue_portal/2 macro
│       ├── auth_hook.ex                   # callback module: :ensure_customer, :ensure_customer_no_create
│       ├── csp_plug.ex                    # CSP with Braintree allowlist
│       ├── brand_plug.ex                  # mirror AccrueAdmin.BrandPlug
│       ├── layouts.ex                     # root + app layouts
│       ├── copy.ex                        # all customer-facing strings (UI-SPEC §Copywriting)
│       ├── assets.ex                      # hashed asset paths (mirror AccrueAdmin.Assets)
│       ├── authorize.ex                   # Accrue.Portal.Authorize macro for D-19 enforcement
│       ├── components/
│       │   ├── card.ex
│       │   ├── button.ex
│       │   ├── status_pill.ex
│       │   ├── hosted_fields_wrapper.ex
│       │   ├── money_amount.ex
│       │   ├── confirm_panel.ex
│       │   ├── toast.ex
│       │   ├── header.ex
│       │   └── nav_rail.ex
│       └── live/
│           ├── home_live.ex
│           ├── checkout_live.ex
│           ├── subscriptions_live.ex
│           ├── subscription_live.ex
│           ├── payment_methods_live.ex
│           ├── add_payment_method_live.ex
│           └── invoices_live.ex
├── assets/
│   ├── tailwind_preset.js                 # mirror admin
│   ├── css/
│   │   └── theme.css                      # --ap-* tokens
│   └── js/
│       ├── app.js                         # imports hooks
│       └── hooks/
│           └── hosted_fields.js           # AccrueHostedFields hook
├── priv/
│   └── static/
│       └── (compiled CSS + JS bundles)
├── test/
│   ├── accrue_portal/
│   │   ├── live/
│   │   │   ├── home_live_test.exs
│   │   │   ├── checkout_live_test.exs
│   │   │   ├── subscriptions_live_test.exs
│   │   │   ├── subscription_live_test.exs
│   │   │   ├── payment_methods_live_test.exs
│   │   │   ├── add_payment_method_live_test.exs
│   │   │   └── invoices_live_test.exs
│   │   ├── router_test.exs
│   │   ├── auth_hook_test.exs
│   │   ├── csp_plug_test.exs
│   │   └── components/
│   │       └── ... (one test per component)
│   └── support/
│       ├── conn_case.ex
│       └── fixtures.ex
└── guides/
    └── install.md
```

### Pattern 1: Sibling-mount discipline (D-21)

**What:** `accrue_portal/2` and `accrue_admin/2` MUST be sibling top-level macro invocations in the host's router, NEVER nested inside one another.
**When to use:** Any host that mounts both packages.
**Example:**

```elixir
# examples/accrue_host/lib/accrue_host_web/router.ex
defmodule AccrueHostWeb.Router do
  use AccrueHostWeb, :router
  import AccrueAdmin.Router
  import Accrue.Portal.Router

  scope "/" do
    pipe_through :browser
    accrue_admin "/admin"      # operator UI
    accrue_portal "/billing"   # customer UI — SIBLING, not nested
  end
end
```

**Source:** Phase 88 Plan 02 mailglass nested-live_session bug (STATE.md line 98). Phoenix forbids nested `live_session` blocks.

### Pattern 2: Defense-in-depth tenant scoping (D-19)

**What:** Every Portal LV's `mount/3` and `handle_event/3` queries MUST scope to `socket.assigns.current_customer.id` — never trust the URL `:id` parameter alone.
**When to use:** Every Portal LV without exception.
**Example:**

```elixir
# accrue_portal/lib/accrue_portal/live/subscription_live.ex
def mount(%{"id" => id}, _session, socket) do
  case Accrue.Billing.get_subscription_for_customer(id, socket.assigns.current_customer) do
    nil ->
      {:ok,
       socket
       |> put_flash(:error, "Page not found")
       |> redirect(to: ~p"/"),
       layout: false}

    subscription ->
      {:ok, assign(socket, subscription: subscription)}
  end
end
```

**Anti-pattern (NEVER DO):**

```elixir
def mount(%{"id" => id}, _session, socket) do
  subscription = Accrue.Billing.get_subscription!(id)  # ← leaks other tenants' subs
  {:ok, assign(socket, subscription: subscription)}
end
```

### Pattern 3: Hosted Fields LV hook with `phx-update="ignore"`

**What:** Mount Braintree iframes inside a `<div phx-hook="AccrueHostedFields" phx-update="ignore">`. The `phx-update="ignore"` tells LV to leave the DOM subtree alone on re-renders, so Braintree's iframe injections survive socket events.
**When to use:** Both `CheckoutLive` and `AddPaymentMethodLive`.
**Example:** See §1 above.

### Pattern 4: Capability-explicit support label vocabulary

**What:** When adding a new processor capability that's first-party but architecturally distinct from existing labels, add a new label to the `@support_labels` vocabulary at `accrue/lib/accrue/processor/capabilities.ex`.
**When to use:** D-08 mandates `"first-party local portal"` as the new label for Phase 101.
**Example:**

```elixir
# accrue/lib/accrue/processor/capabilities.ex (post-Phase 101)
@support_labels %{
  # ... existing entries ...
  checkout: %{
    create: "first-party local portal",   # was "Stripe-only"
    fetch: "first-party local portal",    # was "Stripe-only"
    hosted: "first-party local portal",   # was "Stripe-only"
    embedded: "out of slice"
  },
  billing_portal: %{
    create: "first-party local portal"    # was "Stripe-only"
  }
}
```

### Pattern 5: Synthetic webhook event for missing processor signal (D-13)

**What:** Braintree has no `checkout.session.completed` webhook. The Portal LV, on successful subscription create, enqueues an Oban job that writes a synthetic row to `accrue_webhook_events` with `source: "accrue.portal"`. The existing `Accrue.Webhook.DefaultHandler` reduces it through the same projection path as Stripe events.
**When to use:** After every successful Hosted Fields → subscription create round-trip in `CheckoutLive`.
**Example:**

```elixir
# accrue_portal/lib/accrue_portal/live/checkout_live.ex
def handle_event("hosted_fields_tokenized", %{"nonce" => nonce}, socket) do
  customer = socket.assigns.current_customer
  session = socket.assigns.checkout_session
  attrs = %{
    vault_acquisition: %{reference: nonce},
    items: session.line_items
  }

  case Accrue.Billing.subscribe(customer, attrs) do
    {:ok, subscription} ->
      Accrue.Portal.Checkout.CompletionJob.new(%{
        session_id: session.id,
        subscription_id: subscription.id,
        customer_id: customer.id
      }) |> Oban.insert!()

      target = session.success_url || ~p"/"
      {:noreply, push_navigate(socket, to: target)}

    {:error, %Accrue.APIError{} = err} ->
      {:noreply, assign(socket, :error, err.message)}
  end
end
```

### Anti-Patterns to Avoid

- **Nesting `live_session` blocks:** Causes Phoenix to raise at compile time. Mount admin and portal as siblings (Pattern 1).
- **Passing customer id from URL into queries without re-validation:** Information disclosure side-channel (Pattern 2).
- **Removing `phx-update="ignore"` from Hosted Fields wrapper:** LV will re-render, destroying Braintree iframes on every reconnect.
- **Logging `payload.nonce` from `hostedFieldsInstance.tokenize()`:** Single-use but still card-derived; treat as secret in logs.
- **Storing `last4` / `bin` / `brand` server-side without rate-limiting:** Combined with logs, can leak partial card identity. Store only as part of `payment_method` records, never as standalone log lines.
- **Hand-rolling `Plug.Conn.put_resp_header("content-security-policy", ...)` per-LV:** Use `Accrue.Portal.CSPPlug` in the pipeline; emit one nonce per request, propagate via session assign.
- **Generating `client_token` on every LV `mount/3` without scoping to customer:** Wastes Braintree API calls and removes per-customer scoping. Always pass `customer_id:` opt and cache for the LV's lifetime.
- **Custom JS bundling without esbuild:** Mirror `accrue_admin`'s asset pipeline exactly; do not invent a new build tool.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HMAC-SHA1 webhook verification | Custom HMAC + base64 + XML decode | `Braintree.Webhook.parse/3` already wired in `Accrue.Webhook.Signature` | Timing-safe compare, replay tolerance, multi-env handling already done |
| Hosted Fields iframe lifecycle | Custom card form with PCI compliance | Braintree's `braintree-web/hosted-fields` SDK | PCI SAQ-A scope only achievable via iframe; building your own form bumps you to PCI-DSS Level 1 |
| LV ↔ JS bridge | DOM mutation observers | `phx-hook` + `pushEvent`/`handleEvent` | LV-native, survives reconnects, has documented lifecycle |
| Mount macro | Custom `live_session` setup per host | `Accrue.Portal.Router.accrue_portal/2` | Mirrors admin precedent, validates opts at compile time |
| Auth integration | Custom `Accrue.Portal.Auth` behaviour | Reuse `Accrue.Auth` + `Accrue.Portal.AuthHook` callback module | Single doctrine: "host owns auth via existing behaviour" |
| Idempotency for checkout sessions | Custom UUID + lookup | `Accrue.Processor.Idempotency.subject_uuid/2` | Already used by Stripe path; same key shape across processors |
| Theme tokens | Reinvent CSS variables | `--accrue-*` brand layer + `--ap-*` semantic layer (mirror admin's `--ax-*`) | Brand tokens are v1.0 SemVer-locked public API |
| Asset hashing for cache-busting | Manual fingerprinting | Mirror `AccrueAdmin.Assets.hashed_path/2` | Same pattern across all sibling packages; predictable cache invalidation |
| CSP nonce generation | Custom random + base64 | `:crypto.strong_rand_bytes(18) \|> Base.encode64(padding: false)` (admin pattern) | Existing pattern; no need to invent |
| Money formatting | Custom format helpers | `Accrue.Money.format/2` (already in core) | Currency-aware, locale-aware, tabular-nums-compatible |
| Synthetic event creation | Custom event row insert | Oban worker writing through existing `accrue_webhook_events` schema | Reuses existing handler reduction path |

**Key insight:** Phase 101 has almost zero genuinely novel implementation. Every architectural surface has a direct precedent in `accrue_admin/lib/accrue_admin/`, and the Braintree integration is already 90% wired. The work is **disciplined mirroring** of admin patterns into a new package, plus the Hosted Fields LV hook (the one new technical surface).

## Common Pitfalls

### Pitfall 1: Nested `live_session` blocks
**What goes wrong:** Phoenix raises `RuntimeError: live_session can not be nested` at compile time when `accrue_portal "/billing"` is placed inside a scope that already contains an `accrue_admin` macro invocation, because both expand to `live_session` blocks.
**Why it happens:** Macro expansion is opaque to host devs; the error message points at line numbers inside the macro, not at the host's misuse.
**How to avoid:** Document explicitly in install guide. The macro itself can't enforce sibling-only mounting because Phoenix expands at compile time and the error surfaces later. Mitigation: ship a `mix accrue_portal.gen.routes` task (deferred to v1.34 or possibly v1.33 if scope is small per CONTEXT.md "specifics") that detects the wrong shape and prints a clear error.
**Warning signs:** Compile error mentioning `live_session` and a stack trace through `Phoenix.LiveView.Router`.

### Pitfall 2: Forgetting `phx-update="ignore"` on Hosted Fields wrapper
**What goes wrong:** On socket reconnect (network blip, server restart, dev hot-reload), LV diffs the DOM and removes the iframes Braintree injected. The form is broken until the user refreshes.
**Why it happens:** LV's default behavior is to manage all child DOM. The iframe injection is invisible to LV's diff because it happened post-mount in JS.
**How to avoid:** Always `<div id="..." phx-hook="AccrueHostedFields" phx-update="ignore">`. Add a CSS dev-mode visual indicator (e.g., red border on missing wrapper) — verifiable via component test.
**Warning signs:** "Card number" field renders correctly on first load but disappears after any socket reconnect; iframe `<iframe>` elements are missing from devtools.

### Pitfall 3: Wrong-tenant URL guess (information disclosure)
**What goes wrong:** A LV's `mount/3` does `Accrue.Billing.get_subscription!(id)` instead of scoping to `current_customer`. Customer A guesses Customer B's subscription UUID and views their billing data.
**Why it happens:** D-19 is unenforceable at compile time; relies on dev discipline.
**How to avoid:** (1) Property tests for "wrong-tenant URL guess returns 404" on every Portal LV (UI-SPEC §Security Visual Contract). (2) Provide `Accrue.Portal.Authorize` macro that wraps `mount/3` and re-validates; fail closed. (3) Use `get_*_for_customer/2` query functions that take both id and customer; never expose `get_*!/1` to Portal code.
**Warning signs:** Code review: any `Accrue.Billing.get_*!(id)` call in `accrue_portal/lib/` is a code smell. Test: a specifically-named property test asserts the 404 path for each LV.

### Pitfall 4: Logging the Braintree client_token or nonce
**What goes wrong:** Operator with log access can re-use a not-yet-expired client_token to mount Hosted Fields scoped to another customer; or replay a nonce before it's consumed.
**Why it happens:** Default Plug log format includes assigns; LV `inspect` of socket includes the token.
**How to avoid:** Mask in `Inspect` impl. The `Accrue.Checkout.Session` struct already has an `Inspect` impl masking `client_secret` (`accrue/lib/accrue/checkout/session.ex:274-303`); extend the same pattern to `Accrue.Portal.Live.CheckoutLive`'s assigns. Log filtering via Phoenix's `:filter_parameters`.
**Warning signs:** Manual log sample of a checkout session shows raw token strings.

### Pitfall 5: CSP `'unsafe-inline'` on `style-src` mistakenly removed
**What goes wrong:** Hosted Fields' iframe-content styling injection is broken; iframes render with default browser styling (Times New Roman, blue links, etc.) — UX disaster on a payment page.
**Why it happens:** Security-minded developer sees `'unsafe-inline'` in the CSP and tries to remove it without understanding the Braintree requirement.
**How to avoid:** Inline comment in `Accrue.Portal.CSPPlug` explaining the trade-off; documentation in install guide. Test: smoke test that the CSP header includes `'unsafe-inline'` in `style-src`.
**Warning signs:** Visual diff of Hosted Fields iframes shows browser defaults.

### Pitfall 6: Generating client_token on every LV mount
**What goes wrong:** Every `mount/3` calls `Braintree.ClientToken.generate(customer_id: ...)`, hitting Braintree API per LV mount. On a slow network or sandbox flake, mount stalls.
**Why it happens:** Naive implementation puts the call in `mount/3`.
**How to avoid:** Generate token once per LV process (cache in `socket.assigns`); regenerate only on long-lived process retry. Rate-limit at host's reverse proxy. Document the call as "happens once per checkout page load."
**Warning signs:** Telemetry shows `Braintree.ClientToken.generate` p99 > 500ms in production traces.

### Pitfall 7: `phx-update="ignore"` cargo-culted everywhere
**What goes wrong:** Developer applies `phx-update="ignore"` to non-Hosted-Fields elements thinking it's a generic "preserve DOM" tool. LV stops updating subscription status pills, error messages, etc.
**Why it happens:** Not understanding the purpose of `phx-update="ignore"`.
**How to avoid:** Use ONLY on the Hosted Fields wrapper. Lint: grep for `phx-update="ignore"` in `accrue_portal/lib/` should match exactly the HostedFields wrapper component.
**Warning signs:** Status pills don't refresh after server-side update; "your subscription is now active" never appears.

### Pitfall 8: Idempotency hash collision with stripe processor's idempotency keys
**What goes wrong:** `Accrue.Processor.Idempotency.subject_uuid(:checkout_session_create, "op_abc")` produces the same UUID for Stripe and Braintree if both processors use the same op tag — but the local-portal flow generates an `accrue_checkout_sessions` row that Stripe doesn't have. Cross-pollination if a host swaps processors mid-deployment.
**Why it happens:** UUID derivation is deterministic; not processor-prefixed.
**How to avoid:** Treat processor swaps mid-deployment as unsupported and keep the local-session/idempotency behavior covered by the Plan 01 and Plan 03 tests rather than widening the key shape during Phase 101.
**Warning signs:** A test that creates a checkout session, swaps `:processor`, and tries to re-call with same `operation_id` raises a uniqueness violation.

## Code Examples

### Hosted Fields LV hook (verified pattern)

```javascript
// accrue_portal/assets/js/hooks/hosted_fields.js
// Source: Braintree Hosted Fields docs + Phoenix LiveView phx-hook docs
export const AccrueHostedFields = {
  mounted() {
    this.initBraintree();
  },

  initBraintree() {
    const clientToken = this.el.dataset.clientToken;
    const styles = JSON.parse(this.el.dataset.styles || "{}");

    if (!window.braintree) {
      this.pushEvent("hosted_fields_error", {
        code: "SDK_NOT_LOADED",
        message: "Braintree SDK failed to load. Check CSP and network."
      });
      return;
    }

    window.braintree.client.create({authorization: clientToken}, (clientErr, client) => {
      if (clientErr) {
        this.pushEvent("hosted_fields_error", {
          code: clientErr.code || "CLIENT_INIT_FAILED",
          message: clientErr.message
        });
        return;
      }

      window.braintree.hostedFields.create({
        client,
        styles,
        fields: {
          number: {container: this.el.querySelector("[data-hf-field='number']")},
          expirationDate: {container: this.el.querySelector("[data-hf-field='expiration']")},
          cvv: {container: this.el.querySelector("[data-hf-field='cvv']")}
        }
      }, (hfErr, hf) => {
        if (hfErr) {
          this.pushEvent("hosted_fields_error", {code: hfErr.code, message: hfErr.message});
          return;
        }

        this.hf = hf;
        this.pushEvent("hosted_fields_ready", {});

        // Listen for parent LV signaling tokenization
        this.handleEvent("accrue:tokenize", () => {
          hf.tokenize((tokErr, payload) => {
            if (tokErr) {
              this.pushEvent("hosted_fields_error", {code: tokErr.code, message: tokErr.message});
              return;
            }
            this.pushEvent("hosted_fields_tokenized", {
              nonce: payload.nonce,
              last4: payload.details.lastFour,
              brand: payload.details.cardType,
              bin: payload.details.bin,
              expiration_month: payload.details.expirationMonth,
              expiration_year: payload.details.expirationYear
            });
          });
        });
      });
    });
  },

  destroyed() {
    if (this.hf) {
      this.hf.teardown();
    }
  }
};
```

### LiveView server side (CheckoutLive)

```elixir
# accrue_portal/lib/accrue_portal/live/checkout_live.ex
defmodule Accrue.Portal.Live.CheckoutLive do
  use Accrue.Portal.Web, :live_view
  alias Accrue.Checkout.LocalSession
  alias Accrue.Portal.Checkout.CompletionJob

  @impl true
  def mount(%{"session_token" => token}, _session, socket) do
    customer = socket.assigns.current_customer

    with %LocalSession{} = checkout when checkout.status == "open" <-
           LocalSession.get_by_token(token),
         true <- checkout.customer_processor_id == customer.processor_id,
         false <- DateTime.compare(checkout.expires_at, DateTime.utc_now()) == :lt do

      {:ok, client_token} =
        Braintree.ClientToken.generate(customer_id: customer.processor_id)

      socket =
        socket
        |> assign(:checkout_session, checkout)
        |> assign(:client_token, client_token)
        |> assign(:hosted_fields_styles, hosted_fields_styles(socket.assigns[:theme]))
        |> assign(:error, nil)
        |> assign(:submitting?, false)

      {:ok, socket}
    else
      _ -> {:ok, redirect(socket, to: ~p"/"), layout: false}
    end
  end

  @impl true
  def handle_event("submit", _params, socket) do
    # JS hook listens for "accrue:tokenize" on the LV socket
    {:noreply, push_event(socket, "accrue:tokenize", %{}) |> assign(:submitting?, true)}
  end

  @impl true
  def handle_event("hosted_fields_tokenized", %{"nonce" => nonce} = payload, socket) do
    customer = socket.assigns.current_customer
    session = socket.assigns.checkout_session

    attrs = %{
      vault_acquisition: %{reference: nonce},
      items: session.line_items
    }

    case Accrue.Billing.subscribe(customer, attrs) do
      {:ok, subscription} ->
        # Synthetic event (D-13)
        %{
          session_id: session.id,
          subscription_id: subscription.id,
          customer_id: customer.id,
          last4: payload["last4"],
          brand: payload["brand"]
        }
        |> CompletionJob.new()
        |> Oban.insert!()

        # Mark session complete
        LocalSession.mark_complete!(session)

        target = session.success_url || ~p"/"
        {:noreply, push_navigate(socket, to: target)}

      {:error, %Accrue.APIError{} = err} ->
        {:noreply,
         socket
         |> assign(:error, err.message)
         |> assign(:submitting?, false)}
    end
  end

  def handle_event("hosted_fields_error", %{"message" => msg}, socket) do
    {:noreply,
     socket
     |> assign(:error, msg)
     |> assign(:submitting?, false)}
  end

  defp hosted_fields_styles("dark") do
    %{
      "input" => %{"color" => "#F4F7FA", "font-size" => "16px", "font-family" => "system-ui"},
      "::placeholder" => %{"color" => "#A8B2BC"},
      "input.invalid" => %{"color" => "#FDA29B"}
    }
  end

  defp hosted_fields_styles(_) do
    %{
      "input" => %{"color" => "#111418", "font-size" => "16px", "font-family" => "system-ui"},
      "::placeholder" => %{"color" => "#5D6A73"},
      "input.invalid" => %{"color" => "#B42318"}
    }
  end
end
```

### Braintree adapter `checkout_session_create/2` impl

```elixir
# accrue/lib/accrue/processor/braintree.ex (replacing line 355 stub)
@impl Accrue.Processor
def checkout_session_create(params, opts) when is_map(params) and is_list(opts) do
  operation_id = Keyword.get(opts, :operation_id)

  attrs = %{
    id: deterministic_id(operation_id),
    token: gen_token(),
    customer_processor_id: Map.get(params, "customer"),
    mode: Map.get(params, "mode", "subscription"),
    line_items: Map.get(params, "line_items", []),
    success_url: Map.get(params, "success_url"),
    cancel_url: Map.get(params, "cancel_url"),
    return_url: Map.get(params, "return_url"),
    metadata: Map.get(params, "metadata") || %{},
    client_reference_id: Map.get(params, "client_reference_id"),
    operation_id: operation_id,
    status: "open",
    expires_at: DateTime.utc_now() |> DateTime.add(24 * 3600, :second)
  }

  case Accrue.Checkout.LocalSession.upsert_by_operation_id(attrs) do
    {:ok, row} ->
      url = build_portal_url(row.token)

      {:ok, %{
        "id" => row.id,
        "object" => "checkout.session",
        "url" => url,
        "ui_mode" => "hosted",
        "mode" => row.mode,
        "status" => row.status,
        "customer" => row.customer_processor_id,
        "expires_at" => row.expires_at,
        "metadata" => row.metadata,
        "client_reference_id" => row.client_reference_id
      }}

    {:error, changeset} ->
      {:error, %Accrue.APIError{
        code: "checkout_session_create_failed",
        http_status: 422,
        message: inspect(changeset.errors)
      }}
  end
end

defp deterministic_id(nil), do: Ecto.UUID.generate()
defp deterministic_id(operation_id),
  do: Accrue.Processor.Idempotency.subject_uuid(:checkout_session_create, operation_id)

defp gen_token do
  :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
end

defp build_portal_url(token) do
  base = Accrue.Config.fetch!(:portal_base_url)
  mount = Accrue.Config.get(:portal_mount_path, "/accrue/portal")
  "#{base}#{mount}/checkout/#{token}"
end
```

### Capability map update (D-08, D-09)

```elixir
# accrue/lib/accrue/processor/braintree.ex:14-40 (replace existing map)
def capabilities do
  %{
    customer: %{create: true, retrieve: true, update: true},
    payment_method: %{
      vault_acquisition: true, create: true, list: true,
      update: true, delete: true, set_default: true
    },
    subscription: %{
      direct_create: true, cancel: true, fetch: true,
      lifecycle_webhook_projection: true, update: true,
      cancel_at_period_end: false, cancel_immediately: true,
      pause: false, resume: false
    },
    invoice: %{lifecycle_webhook_projection: true},
    checkout: %{create: true, fetch: true, hosted: true, embedded: false},  # NEW
    webhook: %{verify: true, parse: true},
    billing_portal: %{create: true}  # FLIPPED from false
  }
end
```

```elixir
# accrue/lib/accrue/processor/capabilities.ex:11-52 (extend @support_labels)
@support_labels %{
  # ... existing entries unchanged ...
  checkout: %{
    create: "first-party local portal",   # was "Stripe-only"
    fetch: "first-party local portal",    # was "Stripe-only"
    hosted: "first-party local portal",   # was "Stripe-only"
    embedded: "out of slice"
  },
  billing_portal: %{
    create: "first-party local portal"    # was "Stripe-only"
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Braintree Drop-in for Web | Hosted Fields | Drop-in deprecated (CONTEXT.md U-01; current Braintree messaging confirms deprecation timeline) | All new Braintree integrations must use Hosted Fields; Drop-in remains in maintenance for existing integrations until unsupported |
| LV without `phx-hook` for JS-managed widgets | `phx-hook` + `phx-update="ignore"` | LiveView 0.18+ stable; current 1.1.x | Standardized iframe/JS-widget integration pattern |
| Server-rendered card forms (PCI-DSS Level 1 scope) | Hosted Fields iframes (PCI SAQ-A) | Industry-wide, ongoing | Drastic reduction in PCI compliance burden for the host application |
| Inline CSP via meta tags | Plug-emitted CSP header with nonce | Phoenix 1.6+ idiom | Stronger CSP enforcement; nonce-based script allowlisting |
| Macro-based router DSL "magic" | NimbleOptions-validated macro options | Mid-2020s Elixir convention | Compile-time validation of host integration shape |
| Wrapping JS handlers in inline `onclick=` for LV pages | `JS.dispatch` + `phx-hook` | LV 1.0+ | Survives reconnects, no inline-JS CSP drift |

**Deprecated/outdated:**
- Braintree Drop-in for Web: deprecation status active; Hosted Fields is the supported path.
- `:bamboo` for email: maintenance-mode, ecosystem moved to `:swoosh` (CLAUDE.md). Not relevant to Phase 101 but called out for completeness.
- HTTPotion / HTTPoison for direct Braintree API calls: avoid; route through `:braintree` library.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `line_items` from facade should follow Stripe shape and be translated by adapter to Braintree `plan_id` | §5, §10 Open Q3 | Adapter contract mismatch; tests fail; needs adjustment in adapter translation layer |
| A2 | Synthetic completion event idempotency key = `accrue_checkout_sessions.id` (UUID) prefixed with `accrue_portal_` | §10 Open Q4 | Oban worker retries create duplicate webhook event rows; idempotency violation in projection |
| A3 | Drop-in deprecation dates in CONTEXT.md (2025-07-14 / 2026-07-14) may differ from current Braintree messaging (2026-09-01 / 2027-09-01) | §10 Open Q1 | If user-facing copy cites dates, may show wrong dates; architectural decision unaffected |
| A4 | `Accrue.Processor.Idempotency.subject_uuid/2` does NOT include processor_name in derivation, so swapping processor mid-deployment could cause UUID collision | §Pitfall 8 | Cross-processor key collision on re-call; mitigated by treating `:processor` as compile-env constant |
| A5 | Test database fixtures for `accrue_checkout_sessions` follow existing `accrue/test/support/` conventions | §10 Open Q6 | Test setup boilerplate may be inconsistent; minor cleanup later |
| A6 | Hosted Fields SDK 3.141.0 supports `instance.setAttribute({styles: ...})` for runtime style updates (theme toggle) | §1 Hosted Fields integration | Dark-mode theme toggle requires full SDK re-init instead of in-place update; UX degradation |
| A7 | `accrue_checkout_sessions.line_items` JSONB stores Stripe-shape line_items verbatim from facade | §5 | If shape diverges between Stripe and Braintree, table needs processor-specific column or polymorphic shape |
| A8 | The 5-line install snippet in the install guide can mirror admin's install pattern exactly with minimal Braintree-specific additions (env vars only) | CONTEXT.md "specifics" line 202 | Hosts get confused by missing `:portal_base_url` config; install fails on first request |
| A9 | The example host's existing `Accrue.Auth` impl at `examples/accrue_host/lib/accrue_host/auth.ex` works unchanged for the customer portal | CONTEXT.md D-24 | If admin auth is too restrictive (e.g., requires admin role), portal customer flow breaks; must add `:ensure_customer` variant logic |

## Validation Architecture

> Required because `nyquist_validation: true` in `.planning/config.json`.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) + Phoenix.LiveViewTest 1.1 + LazyHTML |
| Config file | `accrue_portal/test/test_helper.exs` (new — mirror admin's) |
| Quick run command | `cd accrue_portal && mix test` |
| Full suite command | `cd accrue_portal && mix test.all` (or per-package: `mix test.all` in each of `accrue/`, `accrue_admin/`, `accrue_portal/`) |
| Property test framework | `:stream_data` (already in `accrue/mix.exs:92`) — used for D-19 wrong-tenant property tests |
| Mock framework | `:mox` (already in `accrue/mix.exs:91`) — for Braintree adapter contract tests |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BT-01 | `accrue_portal/2` macro mounts; emits expected routes | unit (router_test) | `mix test test/accrue_portal/router_test.exs -x` | ❌ Wave 0 |
| BT-01 | `accrue_portal/2` macro validates options (rejects bad `:on_mount`) | unit | `mix test test/accrue_portal/router_test.exs:test_validate_opts -x` | ❌ Wave 0 |
| BT-01 | Sibling-mount with `accrue_admin` co-exists (distinct live_session ids) | integration | `mix test test/accrue_portal/router_test.exs:test_sibling_mount -x` | ❌ Wave 0 |
| BT-01 | `Accrue.Portal.AuthHook.on_mount(:ensure_customer, ...)` assigns `:current_user` and `:current_customer` | unit | `mix test test/accrue_portal/auth_hook_test.exs -x` | ❌ Wave 0 |
| BT-01 | `Accrue.Portal.AuthHook.on_mount(:ensure_customer, ...)` redirects to `:unauthenticated_path` on nil user | unit | `mix test test/accrue_portal/auth_hook_test.exs:test_unauth_redirect -x` | ❌ Wave 0 |
| BT-01 | `Accrue.Portal.CSPPlug` emits Braintree allowlist | unit | `mix test test/accrue_portal/csp_plug_test.exs -x` | ❌ Wave 0 |
| BT-02 | `Accrue.Billing.create_checkout_session/2` returns `%Session{url: <portal_url>}` for Braintree adapter | unit | `mix test test/accrue/billing/create_checkout_session_braintree_test.exs -x` | ❌ Wave 0 |
| BT-02 | Same `operation_id` returns the same session token (idempotency) | unit | `mix test test/accrue/billing/checkout_idempotency_test.exs -x` | ❌ Wave 0 |
| BT-02 | Capability map flips: `Accrue.Processor.supports?([:checkout, :create])` returns `true` for Braintree | unit | `mix test test/accrue/processor/braintree_capabilities_test.exs -x` | ❌ Wave 0 |
| BT-02 | Hosted Fields tokenize round-trip: nonce → server → `Accrue.Billing.subscribe/3` → subscription record (mocked Braintree) | integration | `mix test test/accrue_portal/live/checkout_live_test.exs -x` | ❌ Wave 0 |
| BT-02 | Checkout session expiry → 404 redirect | integration | `mix test test/accrue_portal/live/checkout_live_test.exs:test_expired -x` | ❌ Wave 0 |
| BT-02 | Hosted Fields tokenize failure path renders error inline | integration | `mix test test/accrue_portal/live/checkout_live_test.exs:test_tokenize_error -x` | ❌ Wave 0 |
| BT-02 | Synthetic `accrue.portal.checkout.completed` event written to `accrue_webhook_events` table | integration | `mix test test/accrue_portal/checkout_completion_job_test.exs -x` | ❌ Wave 0 |
| BT-02 | Synthetic event reduced through `DefaultHandler` updates subscription projection | integration | `mix test test/accrue/webhook/default_handler_portal_event_test.exs -x` | ❌ Wave 0 |
| BT-02 | Telemetry event `[:accrue, :portal, :checkout, :completed]` emitted with expected metadata | unit | `mix test test/accrue_portal/telemetry_test.exs -x` | ❌ Wave 0 |
| BT-03 | `HomeLive` renders dashboard for customer with active subs | integration | `mix test test/accrue_portal/live/home_live_test.exs -x` | ❌ Wave 0 |
| BT-03 | `SubscriptionsLive` renders list for authenticated customer | integration | `mix test test/accrue_portal/live/subscriptions_live_test.exs -x` | ❌ Wave 0 |
| BT-03 | `SubscriptionLive` cancel-at-period-end flow updates Braintree (mocked) | integration | `mix test test/accrue_portal/live/subscription_live_test.exs -x` | ❌ Wave 0 |
| BT-03 | `PaymentMethodsLive` lists vaulted PMs, allows set-default and delete | integration | `mix test test/accrue_portal/live/payment_methods_live_test.exs -x` | ❌ Wave 0 |
| BT-03 | `AddPaymentMethodLive` Hosted Fields → vault flow (no charge) | integration | `mix test test/accrue_portal/live/add_payment_method_live_test.exs -x` | ❌ Wave 0 |
| BT-03 | `InvoicesLive` lists customer's invoices | integration | `mix test test/accrue_portal/live/invoices_live_test.exs -x` | ❌ Wave 0 |
| BT-03 (D-19) | **Wrong-tenant property test:** any `/subscriptions/:id` for non-owned UUID returns 404 | property | `mix test test/accrue_portal/live/wrong_tenant_property_test.exs -x` | ❌ Wave 0 |
| BT-03 (D-19) | **Wrong-tenant property test:** any `/payment-methods/:id` for non-owned token returns 404 | property | `mix test test/accrue_portal/live/wrong_tenant_property_test.exs:test_pm -x` | ❌ Wave 0 |
| BT-03 (D-19) | **Wrong-tenant property test:** any `/invoices/:id` for non-owned UUID returns 404 | property | `mix test test/accrue_portal/live/wrong_tenant_property_test.exs:test_invoice -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `cd accrue_portal && mix test --stale` (if package modified) and `cd accrue && mix test --stale` (if core modified)
- **Per wave merge:** Full per-package suites: `cd accrue && mix test.all && cd ../accrue_admin && mix test && cd ../accrue_portal && mix test`
- **Phase gate:** All three suites green; release-please dry-run succeeds for 3-package linked release; `mix deps.audit` clean; Dialyzer clean before `/gsd-verify-work`.

### Wave 0 Gaps

All test infrastructure for `accrue_portal` is net-new. Required before implementation begins:

- [ ] `accrue_portal/test/test_helper.exs` — ExUnit + LazyHTML config (mirror `accrue_admin/test/test_helper.exs`)
- [ ] `accrue_portal/test/support/conn_case.ex` — Phoenix ConnCase + LiveViewTest setup
- [ ] `accrue_portal/test/support/fixtures.ex` — `customer_fixture/0`, `subscription_fixture/0`, `payment_method_fixture/0`, `checkout_session_fixture/0`
- [ ] `accrue_portal/test/support/braintree_mox.ex` — `Mox.defmock` for Braintree gateways (already configurable via `Application.put_env(:accrue, :braintree_*_gateway, MockMod)` per existing pattern at `accrue/lib/accrue/processor/braintree.ex:449-463`)
- [ ] Test factory for `accrue_checkout_sessions` rows — `accrue/test/support/checkout_session_fixture.ex`
- [ ] Migration test verifying `accrue_checkout_sessions` table schema
- [ ] `Accrue.Portal.Authorize` test helper macro for D-19 enforcement assertions

**Framework install:** None — Elixir/ExUnit is already in stack. Add `{:lazy_html, ">= 0.1.0", only: :test}` and `{:plug_cowboy, "~> 2.7", only: :test}` to `accrue_portal/mix.exs`.

## Threat Inputs

> Consumed by planner to populate the `<threat_model>` block.

See §9 above for the full table. Compact form for planner:

| # | Threat | STRIDE | Mitigation Verb |
|---|--------|--------|-----------------|
| T1 | Client token leakage allowing iframe injection on attacker site | Spoofing | Server-only generation, scope by customer_id, ≤24h TTL, never log |
| T2 | Nonce replay (charge twice) | Tampering | Braintree single-use nonce; `subscribe/3` consumes once |
| T3 | Webhook spoofing (forged Braintree webhook) | Spoofing | HMAC-SHA1 verify in existing `Accrue.Webhook.Plug` (no change) |
| T4 | Webhook replay | Tampering | Content-hash idempotency `bt_<sha256(payload)>` (existing) |
| T5 | Hosted Fields iframe re-framed (clickjacking) | Spoofing | `frame-ancestors 'self'` CSP header |
| T6 | Session fixation in checkout flow | Tampering | Token bound to customer at row-insert; LV mount re-validates |
| T7 | Wrong-tenant URL guess (info disclosure) | InfoDisclosure | D-19 defense-in-depth: every query scopes to `current_customer.id`; 404 (not "no access") |
| T8 | PII / PAN / CVV stored on Accrue server | InfoDisclosure | Architectural — Hosted Fields prevents PAN/CVV crossing origin |
| T9 | Checkout token reuse after expiry | Repudiation | `expires_at` enforced at LV mount; status flips to "complete" or "expired" |
| T10 | Session token brute-force | Tampering | 32 bytes (256 bits); rate-limit at host's edge |
| T11 | CSP bypass via `'unsafe-inline'` style-src | Tampering | Required by Hosted Fields; compensated by strict-nonce script-src + tight frame-src |
| T12 | CSRF on form submits | Tampering | `protect_from_forgery` plug + LV `phx-submit` auto-CSRF |
| T13 | Logging of secret material (token, nonce, private key) | InfoDisclosure | `Inspect` masks; `:filter_parameters` in Phoenix; never log raw |
| T14 | Idempotency UUID collision across processors | Tampering | (A4) Treat `:processor` as compile-env-constant; document in install guide |

## Recommended Plan Decomposition

> The planner will refine. This is a starting suggestion; 6 plans, 2 waves.

### Wave 0 — Test infrastructure & core extensions (must precede Wave 1)

**Plan 1: Core extensions for local checkout sessions**
- New `accrue/lib/accrue/checkout/local_session.ex` Ecto schema + helpers
- New `accrue/priv/repo/migrations/<ts>_create_accrue_checkout_sessions.exs`
- New test factory `accrue/test/support/checkout_session_fixture.ex`
- Capability map updates in `accrue/lib/accrue/processor/capabilities.ex` (D-08)
- Add `:portal_mount_path` and `:portal_base_url` to `Accrue.Config` schema (D-23)
- Tests for migration, schema, capability map shape
- **Requirements:** BT-02 (foundation)
- **Estimated tasks:** 4-6

**Plan 2: Braintree adapter checkout/portal session implementation**
- Replace stubs at `accrue/lib/accrue/processor/braintree.ex:355-359` (`checkout_session_create/2`, `checkout_session_fetch/2`, `portal_session_create/2`) with real impls
- Flip capability map at `braintree.ex:14-40` per D-09
- New tests for adapter contract (mocked Braintree gateways)
- Update Stripe behavior tests to confirm no regression (Scope 1 D-14)
- ExDoc updates in `Accrue.Billing` (D-07 implication)
- **Requirements:** BT-02
- **Estimated tasks:** 5-7

**Plan 3: `accrue_portal` package skeleton**
- Create `accrue_portal/` directory at repo root
- `accrue_portal/mix.exs`, `application.ex`, `README.md`, `CHANGELOG.md`
- `accrue_portal/lib/accrue_portal/router.ex` macro (mirror admin)
- `accrue_portal/lib/accrue_portal/auth_hook.ex` (`:ensure_customer`, `:ensure_customer_no_create`)
- `accrue_portal/lib/accrue_portal/csp_plug.ex` with Braintree allowlist (D-22)
- `accrue_portal/lib/accrue_portal/brand_plug.ex` (mirror admin)
- `accrue_portal/lib/accrue_portal/layouts.ex` + `assets.ex` + `copy.ex` shells
- Test infrastructure (`test_helper.exs`, `support/conn_case.ex`, `support/fixtures.ex`)
- Router tests, auth_hook tests, CSP plug tests
- Update `release-please-config.json` to include third package (D-03)
- **Requirements:** BT-01
- **Estimated tasks:** 8-12

### Wave 1 — Portal LiveViews (depend on Wave 0)

**Plan 4: Hosted Fields LV hook + checkout LiveView**
- `accrue_portal/assets/js/hooks/hosted_fields.js` (LV hook)
- `accrue_portal/assets/js/app.js` (registers hook)
- `accrue_portal/assets/css/theme.css` + `tailwind_preset.js`
- `accrue_portal/lib/accrue_portal/components/hosted_fields_wrapper.ex`
- `accrue_portal/lib/accrue_portal/live/checkout_live.ex`
- `accrue_portal/lib/accrue_portal/checkout/completion_job.ex` (Oban worker for synthetic event)
- Telemetry events for `[:accrue, :portal, :checkout, :completed]`
- Asset pipeline (esbuild config) mirroring admin
- SRI hash pinning for Braintree CDN scripts
- LV integration tests for checkout flow (mocked Braintree)
- Tests for synthetic event creation + projection reduction
- **Requirements:** BT-02
- **Estimated tasks:** 10-14

**Plan 5: Customer portal LiveViews (subs, PMs, invoices)**
- `accrue_portal/lib/accrue_portal/live/home_live.ex` (dashboard)
- `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex`
- `accrue_portal/lib/accrue_portal/live/subscription_live.ex` (with cancel + manage)
- `accrue_portal/lib/accrue_portal/live/payment_methods_live.ex`
- `accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex` (Hosted Fields vault-only)
- `accrue_portal/lib/accrue_portal/live/invoices_live.ex`
- `accrue_portal/lib/accrue_portal/components/{card,button,status_pill,money_amount,confirm_panel,toast,header,nav_rail}.ex`
- `accrue_portal/lib/accrue_portal/authorize.ex` macro for D-19
- Property tests for wrong-tenant URL guesses (D-19, all 3 LVs)
- Empty-state copy + accessibility validation per UI-SPEC
- Dark-mode styling tests
- **Requirements:** BT-03
- **Estimated tasks:** 14-18

**Plan 6: Example host integration + install guide + docs**
- Update `examples/accrue_host/lib/accrue_host_web/router.ex:90` per D-24 (admin to `/admin`, portal at `/billing`)
- Update `examples/accrue_host/config/runtime.exs` with `:portal_base_url`
- Create `accrue_portal/guides/install.md` (5-line snippet for `phx.gen.auth` hosts)
- Update `accrue/guides/braintree-local-portal.md` with cross-link (D-05)
- Update `accrue/lib/accrue/billing.ex` ExDoc (note Braintree now supported)
- README screenshots (UI-SPEC §Specifics line 206)
- Update `accrue_portal/CHANGELOG.md` with v1.33.0 entry
- Update `accrue/CHANGELOG.md` and `accrue_admin/CHANGELOG.md` with v1.33.0 cross-references
- Verify release-please dry-run for 3-package linked release
- **Requirements:** BT-01, BT-02, BT-03 (documentation closure)
- **Estimated tasks:** 6-8

### Plan dependency graph

```
Wave 0 (parallel where possible):
  Plan 1 (core extensions) ─┐
  Plan 2 (Braintree adapter) ── depends on Plan 1
  Plan 3 (portal skeleton) ─┘  parallel to Plan 1+2

Wave 1 (sequential):
  Plan 4 (checkout LV) ── depends on Plan 1, 2, 3
  Plan 5 (portal LVs)  ── depends on Plan 3, 4 (reuses HostedFieldsWrapper component)
  Plan 6 (host + docs) ── depends on Plans 4, 5
```

**Total estimated tasks:** 47-65 across 6 plans (range reflects how planner chooses to slice each plan).

## Execution Readiness

See §10 for the resolved execution decisions and mitigated implementation notes. No open research blockers remain for the Phase 101 plan set.

## Sources

### Primary (HIGH confidence)
- **Codebase direct inspection (verified during this session):**
  - `accrue/lib/accrue/processor/braintree.ex` (645 lines)
  - `accrue/lib/accrue/processor/capabilities.ex` (lines 11-95)
  - `accrue/lib/accrue/billing.ex` (lines 437-553)
  - `accrue/lib/accrue/checkout/session.ex` (272 lines)
  - `accrue/lib/accrue/webhook/plug.ex` (169 lines, full Braintree dispatch)
  - `accrue/lib/accrue/webhook/signature.ex` (53 lines)
  - `accrue_admin/lib/accrue_admin/router.ex` (190 lines, mount macro precedent)
  - `accrue_admin/lib/accrue_admin/auth_hook.ex` (35 lines, callback module precedent)
  - `accrue_admin/lib/accrue_admin/csp_plug.ex` (32 lines, CSP shape precedent)
  - `accrue/lib/accrue/auth.ex` (126 lines, Auth behaviour to reuse)
  - `accrue/lib/accrue/processor/idempotency.ex` (subject_uuid pattern)
  - `accrue/mix.exs` and `accrue/mix.lock` (dep versions)
- **Locked planning artifacts (HIGH confidence — they ARE the locked source of truth):**
  - `.planning/phases/101-accrue-portal-foundation-checkout/101-CONTEXT.md` (decisions D-01..D-24)
  - `.planning/phases/101-accrue-portal-foundation-checkout/101-UI-SPEC.md` (UI contract, 497 lines)
  - `.planning/phases/101-accrue-portal-foundation-checkout/101-DISCUSSION-LOG.md` (advisor synthesis rationale)
  - `.planning/milestones/v1.33-REQUIREMENTS.md` (BT-01, BT-02, BT-03)
  - `.planning/milestones/v1.33-ROADMAP.md` (success criteria)
  - `.planning/research/v1.33-PHASE-101-D-MOUNT-AUTH-SURFACE-ADVISOR.md` (Area D detailed analysis)
  - `./CLAUDE.md` (tech stack, security non-bypassables, monorepo layout)
  - `./.planning/STATE.md` (project current position)
- **Braintree official documentation:**
  - [Braintree Hosted Fields setup and integration (JS v3)](https://developer.paypal.com/braintree/docs/guides/hosted-fields/setup-and-integration/javascript/v3) — CDN URLs, JS init code, tokenize flow
  - [Braintree Hosted Fields overview](https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview) — PCI scope, iframe model
  - [braintree-web on GitHub](https://github.com/braintree/braintree-web) — SDK source, current version 3.141.0+
  - [Braintree Web Client Reference v3.140.0](https://braintree.github.io/braintree-web/current/) — full API reference

### Secondary (MEDIUM confidence)
- [`braintree-web` on npm](https://www.npmjs.com/package/braintree-web) — version 3.141.0 verified
- [`braintree` Hex.pm package](https://hex.pm/packages/braintree) — Elixir lib version 0.16.0 verified
- [Braintree.Webhook on hexdocs.pm](https://hexdocs.pm/braintree/Braintree.Webhook.html) — Webhook.parse/3 API
- [Braintree Drop-in deprecation discussion](https://developer.paypal.com/braintree/docs/start/drop-in) — confirms Hosted Fields as recommended path; date specifics under review
- [Braintree-elixir GitHub repo](https://github.com/sorentwo/braintree-elixir) — maintenance status, last release 2025-03-27
- [Braintree CHANGELOG (web SDK)](https://github.com/braintree/braintree-web/blob/main/CHANGELOG.md) — recent SDK changes

### Tertiary (LOW confidence — needs validation if used as a primary input)
- General WebSearch results for "drop-in deprecation 2025/2026" — sources contradict on exact dates; CONTEXT.md is the operative locked truth for this project
- Phoenix LiveView 1.1 phx-hook lifecycle behavior under socket reconnect with `phx-update="ignore"` — verified via training but worth a smoke test in Plan 4

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every dep version verified against `mix.lock` or hex.pm
- Architecture: HIGH — direct mirror of `accrue_admin` precedent + extensive CONTEXT.md guidance
- Pitfalls: HIGH — codebase-grounded; no extrapolation
- Hosted Fields integration mechanics: HIGH — verified against official docs + working npm/CDN URLs
- Drop-in deprecation date specifics: MEDIUM — CONTEXT.md is locked; public-facing dates may differ
- Idempotency / synthetic event patterns: MEDIUM — extrapolated from existing Stripe path; planner should verify in Plan 1/2

**Research date:** 2026-05-01
**Valid until:** 2026-06-01 (30 days; revisit if Phase 101 execution slips beyond that)

## RESEARCH COMPLETE
