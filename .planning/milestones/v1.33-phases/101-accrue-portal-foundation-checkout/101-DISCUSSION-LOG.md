# Phase 101: Accrue Portal Foundation & Checkout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-01
**Phase:** 101-accrue-portal-foundation-checkout
**Areas discussed:** A (Portal package home + Phase 100 reversal), B (`create_checkout_session/2` Braintree path), C (Stripe parity vs Braintree-only scope), D (Host mount + end-user auth surface)

**Discussion mode:** User invoked the cohesive-one-shot-synthesis pattern (per `feedback_decision_synthesis_style.md` and the standing GSD knobs `discuss_auto_all_gray_areas: true`, `discuss_high_impact_confirm: true`, `discuss_auto_resolve_low_impact: true`, `research_before_questions: true`). Four parallel `gsd-advisor-researcher` agents produced comparison tables + single recommendations + HIGH_IMPACT flags; this log records the alternatives the synthesis collapsed.

---

## Area A — Portal package home + Phase 100 reconciliation

| Option | Description | Selected |
|--------|-------------|----------|
| `accrue` core | Add `:phoenix_live_view` LV-routes surface to the core package; reverses Phase 100 D-01 outright. | |
| `accrue_admin` | Reuse existing LV-host pattern; conflates operator-UI and end-user-portal audiences in one package. (Also explicitly deferred-rejected by Phase 100's `<deferred>` block.) | |
| `accrue_portal` (new sibling) | Third package in the monorepo; preserves Phase 100 D-01 by carving an explicit UI-shipping home that's NOT admin. Direct precedent: Bling+Bankroll, Phoenix+LiveDashboard, Oban+ObanWeb. | ✓ |

**Synthesis choice:** `accrue_portal` (new sibling). Phase 100 D-01 narrowed (not reversed): "headless" applies to `accrue` core specifically; the monorepo gains a named UI-shipping sibling.

**Notes:** Advisor A flagged HIGH_IMPACT (irreversible package naming + namespace + release-please lockstep). Synthesis auto-resolved given direct precedent + clean Phase 100 narrowing. User can override at CONTEXT.md review.

---

## Area B — `create_checkout_session/2` Braintree path

| Option | Description | Selected |
|--------|-------------|----------|
| Path 1 — adapter route | Braintree's `checkout_session_create/2` returns `%Session{url: <local portal URL>}`. Caller code identical between Stripe and Braintree. New "first-party local portal" capability label. | ✓ |
| Path 2 — facade short-circuit | `Accrue.Billing.create_checkout_session/2` detects Braintree and bypasses processor callback, calling into portal package directly. Capability map says false while behavior says true. | |
| Path 3 — parallel verb | `Accrue.Portal.Checkout.create_session/2` as a new public verb; `Accrue.Billing.create_checkout_session/2` stays Stripe-only and returns `:unsupported_by_gateway`. Honest but asymmetric for callers. | |

**Synthesis choice:** Path 1. Cascades: Phase 100's `Accrue.Billing.create_billing_portal_session/2` ALSO flips for Braintree (D-07) — both verbs flip together for adapter coherence.

**Notes:** Advisor B flagged HIGH_IMPACT (new "first-party local portal" support label is a SemVer commitment + Phase 100 cascade). Synthesis auto-resolved: capability honesty wins, the cascade is the obviously right cohesive move.

---

## Area C — Stripe parity vs Braintree-only scope

| Option | Description | Selected |
|--------|-------------|----------|
| Scope 1 — Braintree-only escape hatch | Portal activates only when configured processor lacks hosted UI. Stripe behavior byte-identical to v1.32. | ✓ |
| Scope 2 — Unified Stripe+Braintree | Both processors flow through local portal. Stripe loses Link, Apple/Google Pay polish, Radar hosted signals, ~35 locales. Severe regression for every existing Stripe adopter. | |
| Scope 3 — Opt-in for Stripe | Default unchanged for Stripe; opt-in flag for hosts who want the unified portal. Permanent doc burden + new public flag. | |

**Synthesis choice:** Scope 1. Matches the existing STRATEGY.md "Stripe-first until proven by another processor honestly" line literally — no amendment needed.

**Notes:** Advisor C flagged HIGH_IMPACT: false for the scope decision (it's a continuation of an asymmetry the codebase already commits to). BUT Advisor C surfaced a separate factual finding that IS HIGH_IMPACT and was flagged to the user: **Braintree Drop-in for Web is deprecated 2025-07-14 and unsupported 2026-07-14.** Phase 101 must pivot to **Hosted Fields**, requiring updates to BT-02 wording, v1.33-ROADMAP success criterion, and `.planning/ROADMAP.md` Phase 101 row. Captured as `<pre_planning_unblockers>` U-01 in CONTEXT.md.

---

## Area D — Host mount + end-user auth surface

### D.1 — Mount API shape

| Option | Description | Selected |
|--------|-------------|----------|
| Macro `Accrue.Portal.Router.accrue_portal/2` | Mirror `accrue_admin/2` line-for-line. ~3-line host mount. | ✓ |
| Plug + manual wiring | Host writes pipeline + scope + live_session manually. ~30-50 lines per host. | |
| Endpoint plug + sub-router | `forward`-style; `live_session` doesn't compose with `forward`, non-starter. | |

### D.2 — Auth contract

| Option | Description | Selected |
|--------|-------------|----------|
| New `Accrue.Portal.AuthHook` BEHAVIOUR | Duplicates the existing `Accrue.Auth` behaviour; splits the contract. | |
| Pure `on_mount` convention + shipped default callback module | Reuse `Accrue.Auth`; `Accrue.Portal.AuthHook` is callback-module-not-behaviour mirroring `AccrueAdmin.AuthHook`. ~3-line host extension. | ✓ |
| Magic-link URL-token (hybrid) | Works alongside either; deferred to v1.34+ (see D.3). | |

### D.3 — Customer resolution scope in v1.33

| Option | Description | Selected |
|--------|-------------|----------|
| Session-resolved customer ONLY in v1.33 | Portal expects `socket.assigns.current_customer` populated by host's on_mount. Magic-link deferred to v1.34+ with documented host-side workaround. | ✓ |
| Session-resolved + URL-token (hybrid) in v1.33 | Adds 1-2 plans of work: token module, security model, additional LV, property tests for token expiry/scope-binding. | |

**Synthesis choice:** Macro + on_mount convention + session-resolved-only.

**Notes:** Advisor D flagged HIGH_IMPACT: true for D.3 only. Synthesis auto-resolved to defer magic-link per the conservative v1.33-maturity posture; documented host workaround in install guide. User can override at CONTEXT.md review if magic-link should ship in v1.33.

Defense-in-depth (D-19) is non-negotiable per Advisor D — every Portal LV query MUST scope to `socket.assigns.current_customer.id`; never trust URL `:id` alone. Property tests for "wrong-tenant URL guess returns :not_found" required.

---

## Claude's Discretion

User explicitly delegated all non-VERY-impactful forks to coherent cohesive defaults. Items where Claude picked without surfacing:

- File layout inside `accrue_portal/` mirrors `accrue_admin/`
- HEEx + Tailwind classes match `accrue_admin` look-and-feel for visual consistency
- Test layout mirrors `accrue_admin/test/` (LiveViewTest, no JS browser harness)
- ExDoc main page shape mirrors `accrue_admin`
- CHANGELOG.md per package, release-please-driven
- Telemetry naming `[:accrue, <area>, <verb>, <stage>]` conventions
- Hosted Fields static asset loaded from Braintree CDN with SRI hash pinning (mirror Stripe.js loading pattern)
- `Accrue.Portal.Live.HomeLive` content (one-glance dashboard: active subs + default PM + most recent invoice)

## Deferred Ideas

- `:ui_mode :embedded` for the local portal — v1.34+
- Magic-link / URL-token checkout flow — v1.34+ (with documented host-side workaround in v1.33 install guide)
- Opt-in unified portal for Stripe (Scope 3) — held until a real Stripe-using host asks
- `mix accrue_portal.gen.routes` Mix task — possibly v1.33 if planner agrees scope is small; otherwise v1.34
- `Accrue.Portal.Token.{sign,verify}` module — designed but not shipped in v1.33
- Connect/Hyperwallet portal surface — gated by Phase 104 go/no-go decision
- Routes-overrideable behaviour (Pow's `Pow.Phoenix.Routes` analog) — not v1.33 scope
- Per-tenant theming beyond `BrandPlug` — defer
