# Phase 101: Accrue Portal Foundation & Checkout - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning — with one upstream-document correction required first (see "Pre-planning unblockers")

<domain>
## Phase Boundary

Phase 101 delivers a **first-party LiveView portal** (checkout + customer portal) for Accrue hosts whose configured processor has no first-party hosted UI — initially **Braintree only**. Stripe behavior is unchanged: Stripe-Hosted Checkout and Stripe Billing Portal remain the path.

The portal ships as a **new sibling Hex package `accrue_portal`** (third package in the monorepo, alongside `accrue` core and `accrue_admin`). It mounts via an `accrue_portal/2` router macro that mirrors `accrue_admin/2` shape, terminates LiveView routes for checkout / subscription management / payment-method CRUD / cancel / invoice history, and is gated by `Accrue.Processor.supports?([:billing_portal, :create])` so Stripe hosts who never install it pay zero cost.

Phase 101 satisfies **BT-01, BT-02, BT-03**: mount infra, hosted checkout via local LV, customer portal views (subs, PMs, txn history, cancel).

This phase does **not**:
- Alter Stripe's checkout or billing-portal behavior in any way
- Ship a unified multi-processor UI abstraction (Stripe stays on Stripe-hosted; Braintree gets the local portal — capability-explicit named slice, not generic parity)
- Ship `:ui_mode :embedded` for the local portal (deferred to v1.34+)
- Ship magic-link / URL-token checkout (the "subscribe via emailed link, user not yet authenticated" flow — deferred to v1.34+ with documented host-side workaround)
- Bundle LiveView into `accrue` core (D-01 from Phase 100 narrowed, not reversed — see D-01 below)

</domain>

<pre_planning_unblockers>
## ✅ Pre-planning unblockers — RESOLVED 2026-05-01

### U-01 — Drop-in → Hosted Fields pivot — RESOLVED

**Braintree Drop-in for Web is deprecated 2025-07-14 and unsupported 2026-07-14** per PayPal/Braintree's deprecation notice. Phase 101 is locked to **Braintree Hosted Fields**. All upstream documents updated in lockstep with this CONTEXT.md commit:

- `.planning/milestones/v1.33-REQUIREMENTS.md` BT-02 — updated to Hosted Fields with deprecation note
- `.planning/milestones/v1.33-ROADMAP.md` Phase 101 success criterion 2 — updated
- `.planning/ROADMAP.md` Phase 101 row goal + success criterion 2 — updated
- `.planning/research/v1.33-BRAINTREE-FULL-MATURITY.md` §1, §5 — updated to reference Hosted Fields and the new sibling `accrue_portal` package
- `accrue/guides/braintree-local-portal.md` payment-method section — updated to use Hosted Fields nonce flow

Hosted Fields renders inside our LiveView template via Braintree's JS SDK with explicit field-by-field iframe injection (vs. Drop-in's prepackaged form). All other Phase 101 decisions are unaffected.

</pre_planning_unblockers>

<decisions>
## Implementation Decisions

### Package home (Area A)

- **D-01 (amends Phase 100 D-01 — narrows, does not reverse):** The `accrue` core package remains a headless backend facade — no LiveView routes, no controllers, no end-user-facing UI. First-party UI for end-user-facing billing flows (checkout, customer portal) is shipped in a **dedicated sibling package `accrue_portal`**, which hosts opt into explicitly. The "explicit error + documentation recipe" pattern from Phase 100 (D-03/D-04/D-05) remains the contract for hosts that decline `accrue_portal`. **Phase 100's deferred-rejection of "drop-in unified LiveView portal shipped as part of `accrue_admin`" is honored** — we did not put it in admin; we carved a third home.
- **D-02:** Public namespace = `Accrue.Portal.*` (under the umbrella, mirroring existing `Accrue.BillingPortal`). OTP app = `:accrue_portal`. Internal/private modules use `AccruePortal.*` (e.g., `AccruePortal.Router`, `AccruePortal.Application`). Precedent: `Phoenix.LiveDashboard` (public) in `:phoenix_live_dashboard` (OTP app).
- **D-03:** `accrue_portal` joins the existing `release-please-config.json` `linked-versions` group at v1.33.0 — all three packages release in lockstep. Add a third entry to `release-please-config.json` mirroring `accrue_admin`'s shape.
- **D-04:** `accrue_portal/mix.exs` deps: `{:accrue, "== <same version>"}`, `{:phoenix, "~> 1.8"}`, `{:phoenix_live_view, "~> 1.1"}`, `{:phoenix_html, "~> 4.2"}`, `{:plug, "~> 1.16"}`, `{:jason, "~> 1.4"}`. NOT a hard dep on `:braintree` or `:lattice_stripe` — adapter-specific UI bits (Hosted Fields script tag, future Stripe Elements config) are gated by `Accrue.Processor.capabilities/1` checks at render time.
- **D-05:** Update `accrue/guides/braintree-local-portal.md` to add a header note: "If you want a first-party batteries-included LiveView portal instead, see `accrue_portal` (added v1.33). This guide remains for hosts that prefer to hand-roll the portal in their own UI stack." Add the reverse cross-link from `accrue_portal`'s README. The hand-roll recipe stays valid as the documented escape hatch.

### Checkout/portal facade integration (Area B)

- **D-06:** **Path 1 — adapter route.** `Accrue.Billing.create_checkout_session/2` is unchanged at the facade — it dispatches through `Accrue.Processor.__impl__().checkout_session_create/2` as it always has. The Braintree adapter (`accrue/lib/accrue/processor/braintree.ex:355`) is rewritten from `{:error, unsupported()}` to a real implementation that builds a local-portal URL pointing at the host's mounted `Accrue.Portal` checkout LV. Caller code is identical between Stripe and Braintree.
- **D-07:** `Accrue.Billing.create_billing_portal_session/2` flips for Braintree the same way — currently returns `{:error, %Accrue.APIError{code: :unsupported_by_gateway}}` (Phase 100), Phase 101 returns `{:ok, %Accrue.BillingPortal.Session{url: <local-portal-mount>, ...}}`. **This explicitly cascades the Phase 100 verb to the new local-portal model alongside checkout** — both verbs flip together for Braintree to keep adapter behavior coherent. Phase 100's `:unsupported_by_gateway` error path is preserved as the fallback when `accrue_portal` is not mounted.
- **D-08:** Capability map updates (`accrue/lib/accrue/processor/capabilities.ex`):
  - Add new support-label vocabulary entry: `"first-party local portal"` (meaning: served via `Accrue.Portal` mounted in the host router; honest about the architectural difference from `"all first-party"` which means "every adapter implements the same upstream contract")
  - Replace `checkout: %{create: "Stripe-only", fetch: "Stripe-only", hosted: "Stripe-only"}` with `"first-party local portal"` for those three; keep `embedded: "out of slice"`
  - Add `billing_portal: %{create: "first-party local portal"}` (currently `"Stripe-only"`)
- **D-09:** Braintree adapter capabilities map (`accrue/lib/accrue/processor/braintree.ex:14-40`):
  - Add `checkout: %{create: true, fetch: true, hosted: true, embedded: false}` (between `invoice:` and `webhook:`)
  - Flip `billing_portal: %{create: true}` (currently `false`)
- **D-10:** `success_url` / `cancel_url` / `return_url` semantics mirror Stripe exactly. Portal LV reads them from the session record and redirects on completion / abandonment. If `nil`, portal renders an in-place "Subscription created" panel (matches Stripe's no-redirect behavior). No portal-computed defaults — host owns redirects.
- **D-11:** `:ui_mode :hosted` only in v1.33. URL shape: `{portal_base_url}{portal_mount_path}/checkout/{opaque_session_token}`. `:ui_mode :embedded` deferred to v1.34+ — capability declares `embedded: false` for Braintree.
- **D-12:** Idempotency — local portal persists `accrue_checkout_sessions` rows keyed by `operation_id` when present. Re-calls with the same `operation_id` return the same session token / URL. Uses existing `Accrue.Processor.Idempotency.subject_uuid(:checkout_session_create, operation_id)` derivation so Stripe and Braintree share the same key shape.
- **D-13:** Webhook/event surface — Braintree has no `checkout.session.completed`. Portal LV, on successful Hosted Fields nonce → subscription create, enqueues an Oban job that writes a synthetic `%Accrue.Webhook.Event{type: "accrue.portal.checkout.completed", source: "accrue.portal", ...}` row. Existing `Accrue.Webhook.DefaultHandler` reduces it through the same downstream projection path as Stripe's `checkout.session.completed`. New telemetry event `[:accrue, :portal, :checkout, :completed]` mirrors Stripe webhook receipt; existing `[:accrue, :billing, :checkout_session, :create]` span wraps the create call for both processors (no fork).

### Stripe parity scope (Area C)

- **D-14:** **Braintree-only escape hatch.** `Accrue.Portal` activates whenever `Accrue.Processor.supports?([:billing_portal, :create])` returns `false` (today: Braintree; future: any first-party processor missing hosted UI). Stripe hosts on `accrue` see byte-identical v1.32 behavior — Stripe-Hosted Checkout, Stripe Billing Portal, Link, Apple/Google Pay, Radar hosted-page signals, ~35 locales — all unchanged. **No STRATEGY.md amendment needed**: the existing line "checkout and billing portal remain Stripe-first until another first-party processor proves them honestly" literally describes this scope.
- **D-15:** **Do NOT introduce `:ui_mode :local_portal`** as a new value on `create_checkout_session/2`'s schema. Capability-gating is sufficient and keeps the public API surface from permanently widening for an opt-in path with no current customer demand. Opt-in-for-Stripe (a unified portal with Stripe migrations) is filed in Deferred Ideas as a v1.34+ candidate behind an actual host ask.

### Host mount + end-user auth surface (Area D)

- **D-16:** **Macro `Accrue.Portal.Router.accrue_portal/2`** mirroring `accrue_admin/2` shape line-for-line. Hosts mount with `accrue_portal "/billing", on_mount: [...], session_keys: [...]`. Default `on_mount`: `[{Accrue.Portal.AuthHook, :ensure_customer}]`. Validates options at macro expansion (`validate_opts!/2` mirror admin). Emits exactly ONE `live_session :accrue_portal` block.
- **D-17:** **No new behaviour module.** Reuse the existing `Accrue.Auth` behaviour for `current_user/1`. `Accrue.Portal.AuthHook` is a callback module (NOT a behaviour) mirroring `AccrueAdmin.AuthHook` exactly. Two on_mount variants:
  - `:ensure_customer` — calls `Accrue.Auth.current_user(session)`, then `Accrue.Billing.customer(user, :lazy_create_if_missing)`, assigns `:current_user` and `:current_customer`. On `nil` user → halts and redirects to configured `:unauthenticated_path`.
  - `:ensure_customer_no_create` — same but does NOT lazy-create; halts with `:not_found` if user has no Customer record. Used by routes that should never create a stub Customer (e.g., invoice list).
- **D-18:** Required `socket.assigns` after on_mount: `:current_user`, `:current_customer` (`%Accrue.Billing.Customer{}`), `:accrue_portal_session` (mirror of admin's `:accrue_admin_session`).
- **D-19:** **Defense-in-depth (NON-NEGOTIABLE).** Every Portal LV query MUST scope to `socket.assigns.current_customer.id` — never trust URL `:id` alone. Provide an `Accrue.Portal.Authorize` LV macro/helper that runs in every Portal LV's `mount` to enforce. Add property tests covering "wrong-tenant URL guess returns :not_found".
- **D-20:** **Session-resolved customer ONLY in v1.33.** Magic-link / URL-token checkout deferred to v1.34+ with documented host-side workaround in the install guide: hosts can build a `/checkout/start?token=...` controller in their own router that verifies the token and `put_session(:user_token, ...)` before redirecting into the Portal at `/billing/checkout/:price_id`.
- **D-21:** **Sibling-mount discipline.** `accrue_portal/2` and `accrue_admin/2` MUST be mounted as sibling top-level scopes — never nest one inside the other. Distinct `live_session` ids (`:accrue_portal` vs `:accrue_admin`) keep them safely co-resident. Document explicitly in install guide. Lesson source: Phase 88 plan 02 mailglass nested-live_session bug.
- **D-22:** Pipeline plugs (`pipeline :accrue_portal_browser`): `:fetch_session`, `:protect_from_forgery`, `Accrue.Portal.CSPPlug` (CSP with `frame-src` / `script-src` allowlist for `js.braintreegateway.com` and `*.braintree-api.com` — Hosted Fields requirement), `Accrue.Portal.BrandPlug` (mirror admin's brand plug for theming).

### Configuration

- **D-23:** Two new config keys (both in `config/runtime.exs`):
  - `:portal_mount_path` (string, default `"/accrue/portal"`) — must match the path the host passed to `accrue_portal/2`. Read by the Braintree adapter when synthesizing the checkout URL.
  - `:portal_base_url` (string, **required at runtime, no default**) — full URL prefix (e.g., `"https://app.example.com"`) used to build absolute URLs returned to callers. Required because `create_checkout_session/2` historically returns absolute URLs (Stripe pattern) and the local portal can't synthesize them from the request context (the call may not be in a request — could be a worker).

### Example host updates

- **D-24:** `examples/accrue_host/lib/accrue_host_web/router.ex:90` currently mounts `accrue_admin "/billing"` — that path collides with the recommended `accrue_portal "/billing"`. Move admin to `accrue_admin "/admin"` (semantically cleaner anyway: admin is operator UI, not customer billing UI). Add `accrue_portal "/billing"` mount alongside as the canonical example. Update `examples/accrue_host/lib/accrue_host/auth.ex` only if needed — the existing `Accrue.Auth` impl already returns `current_user` and works for the customer portal unchanged.

### Claude's Discretion (no user input requested — coherent defaults applied)

- File layout inside `accrue_portal/lib/accrue_portal/live/` mirrors `accrue_admin/lib/accrue_admin/live/` (one LV module per route, `*_live.ex` naming).
- HEEx + tailwind classes match `accrue_admin`'s look-and-feel for visual consistency when both packages are mounted in the same host (operators and customers see the same brand).
- Test layout mirrors `accrue_admin/test/` — LiveViewTest-driven, no JS browser harness in CI.
- ExDoc main page for `accrue_portal` follows `accrue_admin`'s ExDoc shape (overview → install → configure → mount → screenshots).
- CHANGELOG.md per package, release-please-driven; v1.33.0 entry for `accrue_portal` calls out "initial release — Braintree local portal (checkout + customer portal)".
- Telemetry event names follow the existing `[:accrue, <area>, <verb>, <stage>]` shape — no inventions.
- Drop-in's static asset (e.g., `js.braintreegateway.com/.../dropin.min.js`) bundling: load from Braintree's CDN with SRI hash pinning rather than vendoring (matches how Stripe.js is loaded across the ecosystem).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Active milestone and locked context
- `.planning/milestones/v1.33-ROADMAP.md` — Phase 101 goal, success criteria, dependencies (BT-01/02/03)
- `.planning/milestones/v1.33-REQUIREMENTS.md` — BT-01..BT-09, traceability table
- `.planning/research/v1.33-BRAINTREE-FULL-MATURITY.md` — Strategic ecosystem framing for v1.33 (note Drop-in references in lines 23/25/54 require Hosted Fields update per U-01)
- `.planning/STRATEGY.md` — `PROC-08` track, "Stripe-first" doctrine, "ActiveMerchant trap" warning, named-capability-slice principle
- `.planning/PROJECT.md` — Core constraints, "headless" identity (now narrowed via D-01), facade-first posture

### Phase 100 cascade dependency
- `.planning/milestones/v1.32-phases/100-billing-portal-semantics/100-CONTEXT.md` — D-01..D-08 from Phase 100; D-01 is narrowed by Phase 101 D-01, D-07 cascades the billing-portal verb flip
- `.planning/research/v1.32-PHASE-100-ADVISOR.md` — The architectural decision record for the headless approach Phase 101 narrows
- `accrue/guides/braintree-local-portal.md` — The Phase 100 hand-roll recipe; Phase 101 D-05 keeps it as the documented `accrue_portal`-decline escape hatch

### Phase 101 advisor research (Phase-101 originated)
- `.planning/research/v1.33-PHASE-101-A-PORTAL-PACKAGE-HOME-ADVISOR.md` — Area A: package home + Phase 100 reconciliation
- `.planning/research/v1.33-PHASE-101-B-CHECKOUT-SESSION-PATH-ADVISOR.md` — Area B: `create_checkout_session/2` adapter-route path
- `.planning/research/v1.33-PHASE-101-C-STRIPE-PARITY-SCOPE-ADVISOR.md` — Area C: Braintree-only scope; surfaced Drop-in deprecation finding
- `.planning/research/v1.33-PHASE-101-D-MOUNT-AUTH-SURFACE-ADVISOR.md` — Area D: macro + on_mount + session-resolved customer

### Public facade and processor seams
- `accrue/lib/accrue/billing.ex` — `create_checkout_session/2` (lines 485-528), `create_billing_portal_session/2` (lines 437-483); both unchanged at facade, ExDoc updates only
- `accrue/lib/accrue/checkout/session.ex` — `Accrue.Checkout.Session` struct, `ensure_checkout_support!/1`, `ensure_ui_mode_support!/1` (lines 181-211) — work as-is once Braintree adapter declares true
- `accrue/lib/accrue/billing_portal/session.ex` — `Accrue.BillingPortal.Session` struct
- `accrue/lib/accrue/processor/braintree.ex` — adapter to extend (capabilities map at lines 14-40, `checkout_session_create` stub at line 355, `checkout_session_fetch` stub at line 357)
- `accrue/lib/accrue/processor/capabilities.ex` — `@support_labels` map (lines 11-52); add `"first-party local portal"` vocabulary
- `accrue/lib/accrue/errors.ex` — `Accrue.APIError` taxonomy (existing `:unsupported_by_gateway` stays as the fallback when `accrue_portal` not mounted)
- `accrue/lib/accrue/auth.ex` — `Accrue.Auth` behaviour to REUSE (do NOT create `Accrue.Portal.Auth`)

### Mount-macro precedent (mirror exactly)
- `accrue_admin/lib/accrue_admin/router.ex` — Canonical `accrue_admin/2` macro shape: pipeline + scope + live_session + on_mount + threaded session keys
- `accrue_admin/lib/accrue_admin/auth_hook.ex` — Callback-module-not-behaviour precedent for `Accrue.Portal.AuthHook`
- `accrue_admin/lib/accrue_admin/csp_plug.ex` — CSP plug shape to mirror for Hosted Fields allowlist
- `accrue_admin/lib/accrue_admin/brand_plug.ex` — Brand plug pattern to mirror for portal theming

### Host-side example (will need updates per D-24)
- `examples/accrue_host/lib/accrue_host_web/router.ex` — `/billing` path collision; admin moves to `/admin`
- `examples/accrue_host/lib/accrue_host/auth.ex` — Existing `Accrue.Auth` impl, works unchanged for portal

### Sibling release config
- `release-please-config.json` — `linked-versions` group; add `accrue_portal` as third component (verify v4 prefix change `accrue_portal--release_created` per CLAUDE.md note)

### Cross-package precedent (informative — not required reading for planner, but cited in advisor research)
- Bling (Elixir) + Bankroll (Elixir UI sibling) — closest precedent; Bling+Bankroll = Accrue+AccruePortal
- Pay (Rails) `pay-rails/pay` — headless billing pattern, no checkout UI
- `phoenix_live_dashboard` + Phoenix — separate-package UI precedent
- Oban + Oban Web — same pattern, open-sourced 2025
- Spree → Solidus frontend coupling lessons (avoid)
- Cashier-Braintree (legacy Laravel) — direct analogue of "host needs server-rendered checkout for Braintree"

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Accrue.Processor.capabilities/1` and `supports?/1` already gate features cleanly — Phase 101 just adds new entries; no new gating mechanism needed.
- `Accrue.Checkout.Session` struct + `ensure_checkout_support!/1` + `ensure_ui_mode_support!/1` work as-is once Braintree adapter flips capabilities to true.
- `Accrue.APIError{code: :unsupported_by_gateway}` taxonomy stays the fallback for hosts who haven't mounted `accrue_portal`.
- `Accrue.Auth.current_user/1` behaviour already covers the "host owns auth" contract — Phase 101 reuses it; do NOT create a parallel `Accrue.Portal.Auth`.
- `Accrue.Processor.Idempotency.subject_uuid/2` derives idempotency keys consistently — local checkout sessions reuse this so Stripe/Braintree key shapes match.
- `Accrue.Webhook.DefaultHandler` reduces events into projections — synthetic `accrue.portal.checkout.completed` events flow through unchanged.
- `accrue_admin`'s entire mount-macro stack (`Router`, `AuthHook`, `CSPPlug`, `BrandPlug`, `Layouts`, `Assets`) is the line-for-line template for `accrue_portal`'s equivalent modules.
- `examples/accrue_host/lib/accrue_host/auth.ex` already implements `Accrue.Auth` and works for the customer portal unchanged.

### Established Patterns

- **Sibling-scope live_session mounting** (Phase 88 plan 02 mailglass lesson). Never nest. `accrue_portal/2` and `accrue_admin/2` co-exist as sibling top-level macro invocations, distinct live_session ids.
- **Capability-explicit support labels** (Phase 95-96 audit work made these labels publicly introspected). New label `"first-party local portal"` joins `"all first-party"`, `"staged first-party target"`, `"out of slice"`, `"Stripe-only"` as a permanent v1.x SemVer-locked vocabulary.
- **Ship-complete philosophy** — `accrue_portal` ships at v1.33.0 with Hosted Fields, customer portal, checkout, install guide, ExDoc, CHANGELOG. No `0.x` iteration cycle.
- **Headless core boundary** — `accrue` core never gains LiveView routes; `Phoenix.Component` HEEx for emails/PDFs is the only LV-adjacent surface in core (already there for Mailglass).
- **Adapter-backed facade dispatch** — `Accrue.Billing.create_*_session/2` always goes through `Processor.__impl__()`; the facade never branches on processor identity.
- **Telemetry naming** — `[:accrue, <area>, <verb>, <stage>]`; new `[:accrue, :portal, :checkout, :completed]` follows convention.

### Integration Points

- `accrue/lib/accrue/processor/braintree.ex` — capabilities map flip + `checkout_session_create/2` impl + `checkout_session_fetch/2` impl + billing-portal flip
- `accrue/lib/accrue/processor/capabilities.ex` — new vocabulary entry, label flips for checkout + billing_portal
- `accrue/lib/accrue/billing.ex` — ExDoc updates only (note Braintree now supported, URL points at host's portal mount when processor is Braintree, link to `accrue_portal` install guide)
- New: `accrue/lib/accrue/checkout/local_session.ex` — Ecto schema + insert/fetch helpers for `accrue_checkout_sessions` table; Braintree-private state (Stripe never touches it)
- New: `accrue/priv/repo/migrations/<ts>_create_accrue_checkout_sessions.exs` — token, customer_processor_id, mode, line_items snapshot, success_url/cancel_url, status, expires_at, operation_id (unique)
- New: `accrue/lib/accrue/portal/checkout/completion_job.ex` — Oban worker that synthesizes `accrue.portal.checkout.completed` event
- New package: `accrue_portal/` — full sibling project (mix.exs, lib/accrue_portal/{router,auth_hook,csp_plug,brand_plug,application,layouts,live/{checkout,subscriptions,subscription,payment_methods,invoices,home}_live.ex,authorize.ex}, README, CHANGELOG, ExDoc config, test/, .formatter.exs)
- `release-please-config.json` — third entry in `linked-versions`; Release Please v4 output naming verification required
- `examples/accrue_host/lib/accrue_host_web/router.ex` — admin moves to `/admin`, portal mounts at `/billing`

</code_context>

<specifics>
## Specific Ideas

- The `accrue_portal` install guide must include a copy-paste 5-line mount snippet that works for a `phx.gen.auth`-shaped host out of the box (mirror admin's install pattern).
- Update `accrue/guides/braintree-local-portal.md` header with cross-link to `accrue_portal` ("If you want batteries included, see X — this guide stays for hand-roll preference").
- `Accrue.Portal.Live.HomeLive` (`/`) shows a one-glance dashboard: active subs + default PM + most recent invoice — the customer's "is everything OK?" check.
- Hosted Fields field-by-field iframe injection requires explicit field component slots; mirror Stripe Elements' card-element-only-once pattern (don't let hosts double-mount the same field).
- The `accrue_portal` README should screenshot two states: "logged-in customer viewing their subs" + "Hosted Fields checkout in progress" so adoption decisions don't require a `mix new` to see what they're getting.
- Defensive: ship a `mix accrue_portal.gen.routes` task that adds the mount line + CSP allowlist to a host's existing router (analogous to `phx.gen.auth`'s diff-based scaffolding) — defer to v1.34 if too much for Phase 101, but flag in plan-phase whether to include.

</specifics>

<deferred>
## Deferred Ideas

- **`:ui_mode :embedded` for the local portal** — Hosted Fields can render inline in a host's own LV. Adds JS bundle distribution complexity. Capability declares `embedded: false` for v1.33; revisit in v1.34+ if a host asks.
- **Magic-link / URL-token checkout flow** — "Subscribe via emailed link, user not yet authenticated." Real common SaaS flow but security surface (referer leakage, browser history, replay, scope-binding) wants careful design. Defer to v1.34+. Document host-side workaround (`/checkout/start?token=...` controller in host's router) in the install guide.
- **Opt-in unified portal for Stripe** (Scope 3 from Area C) — A Stripe host could opt into the local portal for unified UX across processors. Requires `:ui_mode :local_portal` flag or processor config. Held until a real Stripe-using host asks; until then, Stripe-Hosted's free polish (Link, Apple/Google Pay, Radar hosted-page signals, ~35 locales) is value Accrue cannot match and should not pretend to.
- **`mix accrue_portal.gen.routes` Mix task** — Diff-based scaffolding to add mount line + CSP allowlist to host's existing router. Possibly v1.33 if planner agrees scope is small; otherwise v1.34.
- **`Accrue.Portal.Token.{sign,verify}` module** — designed but NOT shipped in v1.33. Document the placeholder shape in the portal guide so hosts know it's coming.
- **Connect/Hyperwallet portal surface** — Phase 104 will decide go/no-go on `Accrue.Connect` parity for Braintree. If go, marketplace seller payouts likely need their own `Accrue.Portal.Connect.*` sub-namespace. Out of scope until Phase 104 decides.
- **Routes-overrideable behaviour** (Pow's `Pow.Phoenix.Routes` analog) — overriding Accrue.Portal's URL paths per-host. Not v1.33 scope.
- **Per-tenant theming beyond `BrandPlug`** — Multi-tenant customer portals where the rendered UI differs per organization (logo, colors, copy). `BrandPlug` handles single-brand; multi-tenant needs more. Defer.

</deferred>

---

*Phase: 101-accrue-portal-foundation-checkout*
*Context gathered: 2026-05-01*
*Synthesis pattern: parallel advisor research (4 agents, areas A/B/C/D) → cohesive default package → one HIGH-impact factual finding flagged in U-01 above*
