# Phase 7: Admin UI (accrue_admin) — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `07-CONTEXT.md` — this log preserves alternatives considered and the research methodology.

**Date:** 2026-04-15
**Phase:** 07-admin-ui-accrue-admin
**Method:** 8 parallel `gsd-advisor-researcher`-style agents, one per gray area, then synthesized into coherent decision set
**User direction:** "research using subagents, pros/cons/tradeoffs... best practices idiomatic Elixir/Plug/Phoenix... great software arch/engineering... best for our use case, great DX/dev ergonomics... cohesive/coherent decisions among themselves... lessons learned from other libs in ecosystem and other langs/frameworks... think deeply and one-shot perfect recommendation so I don't have to think"

**Areas discussed:** Mount model, Asset pipeline, Component library + layout, Data loading + real-time, Step-up auth, Webhook inspector + DLQ UX, Dev surfaces packaging, Theme + dark mode mechanics

**Presentation format:** No interactive per-question AskUserQuestion loop — user delegated all choices to research-backed synthesis.

---

## Mount + isolation model

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| A. LiveDashboard-style forward w/ own pipeline, live_session, on_mount | Matches ecosystem, clean auth integration, total isolation, low upgrade risk, CSP-friendly | +1 module to own (router macro), ~600 LOC component lib forced | ✓ **Chosen (D7-01)** |
| B. Router macro into host `:browser` pipeline | 1-line install | CSRF mismatch risk, layout leakage, Pow's historical pain | Rejected |
| C. Generator (Torch-style, copies files) | Full host customization | Every upgrade = manual merge; violates ship-complete v1.x promise | Rejected |
| D. Hybrid mount w/ host pipeline reuse | Novel, flexible | Untested pattern, no precedent | Rejected |

**Cross-ecosystem corroboration:** Phoenix.LiveDashboard, Oban.Web, Rails Engines (Mission Control, GoodJob), Laravel Horizon, Django admin — all converge on "own the pipeline, own the layout, expose hooks for auth."

**User's choice:** Delegated to synthesis — Option A.

---

## Asset pipeline strategy

| Option | Host tailwind.config edit? | Node at install? | Runtime brand vars | CSP nonce | Verdict |
|---|---|---|---|---|---|
| A. Precompiled bundle, compile-time embed, plug controller | No | No | Yes (inline style nonce) | Yes | ✓ **Chosen (D7-02)** |
| B. Runtime Tailwind scan of `deps/accrue_admin` | **Yes (force)** | Yes | Yes | Yes | Rejected — forces host edits, couples prod build |
| C. Tailwind preset + plugin | Yes (import) | Yes | Yes | Yes | Reserved as power-user escape hatch (E layer) |
| D. Zero-Tailwind hand-written CSS | No | No | Yes | Yes | Close second — rejected only because utility velocity matters for 18 components |
| E. Hybrid A + optional C preset | Optional | No (default) | Yes | Yes | **Adopted as layered story** |

**Source-reading performed:** Phoenix.LiveDashboard `lib/phoenix/live_dashboard/controllers/assets.ex` (compile-time `@external_resource` + MD5 hash pattern) and `lib/phoenix/live_dashboard/router.ex` (`get "/css-:md5"` route, not `Plug.Static`). Oban.Web installation docs: "doesn't hook into your asset pipeline at all."

**User's choice:** Delegated to synthesis — Option A (+ E as layered story).

---

## Component library + layout shell

| Option | Maintenance | Upgrade risk | Theming | Coherence | Idiomaticity | Verdict |
|---|---|---|---|---|---|---|
| A. First-party ~18 components, no external dep | Medium (own forever) | None | Total | Highest | Highest | ✓ **Chosen (D7-03)** |
| B. SaladUI dependency | Low day-1 | **High** (pre-1.0 churn) | Constrained | Depends on SaladUI | Good | Rejected |
| C. Fork Phoenix CoreComponents | Medium-low | Low | Total (after fork) | High | Highest | Rejected — half-rewrite anyway |
| D. Hybrid (own domain + SaladUI primitives) | Medium-high | High | Split-brain tokens | Seam risk | Mixed | Rejected |

**Rationale:** CLAUDE.md "ship complete, no v0.x iteration" is the deciding constraint. SaladUI/Petal are pre-1.0 shadcn ports under active churn — coupling Accrue v1.0 to them reintroduces the breaking-change pain CLAUDE.md forbids.

**Layout shell:** Adaptive sidebar+topbar chosen over topbar-only and command-palette-first because 8 top-level nav areas + mobile responsiveness demand dedicated nav surface. Desktop: 240px sidebar + 56px topbar + fluid content + right-slide DetailDrawer. Mobile: hamburger-drawer nav + stacked KPIs + DataTable card mode + full-screen DetailDrawer.

**User's choice:** Delegated to synthesis — Option A.

---

## Data loading + real-time updates

| Option | Mobile battery | Multi-admin safety | Live feel | DOM growth | Append-only fit | Verdict |
|---|---|---|---|---|---|---|
| A. Streams + cursor + PubSub auto-insert | Bad | Thundering herd; phantom rows | Instant | Unbounded | Wasteful | Rejected |
| B. Streams + cursor + 5s poll banner | **Good** | **Per-client filter** | ~5s explicit | Bounded (user opt-in) | **Ideal** (`id > last_seen_id` is one seek) | ✓ **Chosen (D7-04)** |
| C. Streams + cursor + manual refresh | Best | Safe | None | Bounded | Yes | Too cold |
| D. Offset + assign list | Good | Safe | None | N/A | **Fails** (`OFFSET` = seq scan) | Rejected |

**Decisive constraint:** `accrue_events` is append-only with millions of rows in mature installs. Cursor pagination on `(inserted_at DESC, id DESC)` is an index range scan at any depth; OFFSET is death. Polling on an append-only table is a one-line variant of the cold-load query path — single code path, single bug surface.

**User's choice:** Delegated to synthesis — Option B.

---

## Step-up auth for destructive actions

| Option | Host burden | UX | Sigra fit | Async approvals | Verdict |
|---|---|---|---|---|---|
| A. Behaviour callbacks + generic modal | Low | Good inline reprompt | Excellent (passkey UV) | No | Ship component |
| B. Session timeout only | Zero | **Worst** (loses LV state) | N/A | No | Rejected |
| C. Raise `StepUpRequired`, host plug handles | High | Inconsistent per host | Poor | Maybe | Rejected (Mission Control anti-pattern) |
| D. Action token only | Medium | Friction for simple hosts | OK | **Yes** | Reserved for v1.1 |
| **E. A now, D additive later** | **Low** | **Good** | **Excellent** | **Future** | ✓ **Chosen (D7-05)** |

**Cross-ecosystem:** Stripe Dashboard sudo state (~30min grace), GitHub sudo mode (WebAuthn or password + hours grace, session-wide), Laravel Nova `password.confirm` middleware (10800s grace), Django `sensitive_post_parameters`, AWS IAM `MultiFactorAuthAge` policy condition. All converge on: sensitive-session flag + clock + generic reprompt UI + verification delegated to whatever credential the host owns.

**Grace window default:** 300s (5 minutes) — Stripe parity.

**User's choice:** Delegated to synthesis — Option E.

---

## Webhook inspector + DLQ bulk requeue UX

### Sub-decision matrix

| Sub-decision | Options considered | Chosen |
|---|---|---|
| Raw payload viewer | Collapsible tree / syntax-highlighted `<pre>` / Tree+Raw+Diff tri-tab / JS component | **Tri-tab Tree/Raw/Copy, no diff in v1.0** (pure LiveView + 15-line Clipboard hook) |
| Filter UX | Top chip bar / Sidebar facets / Combined chips + advanced drawer | **Top chip bar** (URL-synced, mobile-scroll, Svix-style) |
| Attempt history | Reuse `Timeline` component / new `AttemptList` / inline `<ul>` | **Reuse `Timeline`** with Moss/Amber/Ink status dots + collapsible error bodies |
| DLQ bulk requeue | Send-to-new-queue / same queue + rate guard / job-per-bulk-action | **Same `accrue_webhooks` queue + `Oban.insert_all` chunks of 100 + 10k hard cap + streamed progress via `send_update`** |
| Derived events | Separate route / embedded tab / not shown | **"Derived Events" tab in detail drawer, via new `caused_by_webhook_event_id` FK** |

**Cross-ecosystem:** Svix (gold standard — chip filters + attempt timeline), Stripe Dashboard (derived objects linkage), Hookdeck (bulk retry quote), GitHub webhook delivery (one-click redeliver), Oban.Web (attempt history card pattern).

**Desktop vs mobile split:** Bulk select hidden below `md:` breakpoint — nobody selects 47 rows on a phone. Individual requeue remains available everywhere.

**Security:** Signature tab shows verification *result* only, never the raw signing secret — `Inspect` masking at config layer already exists, admin UI doesn't reintroduce it.

**User's choice:** Delegated to synthesis — all five sub-picks as above.

---

## Dev surfaces (test clock + email preview) packaging

| Option | Discoverability | Interleaving | Prod leak risk | Chrome overhead | Verdict |
|---|---|---|---|---|---|
| A. Sidebar "Dev" group only | High | Poor (navigate away) | Low | Low | Good but clock-advance is too far |
| B. Floating toolbar only | Very high | Excellent | Medium | None | Fine for clock; hostile to email preview real estate |
| C. Inline on every surface | Medium | Excellent | **High** (scattered guards) | Zero | Rejected |
| D. `/billing/_dev` bare isolated mount | Low | Poor | Low | None | Rejected |
| **E. Hybrid A + B** | **Very high** | **Excellent** | Low | Low | ✓ **Chosen (D7-07)** |

**Task-shape rationale:** Test-clock is *bursty/interleaved* (floating toolbar). Email preview is a *destination task* needing full width (dedicated section). Both, not one.

**5-layer compile gate designed:** Module gate (`if Mix.env() != :prod do defmodule ... end`) + router gate + sidebar `Code.ensure_loaded?` attribute gate + runtime `Accrue.Processor.Fake` guard + CI BEAM artifact assertion.

**User's choice:** Delegated to synthesis — Option E.

---

## Theme + dark mode + runtime brand mechanics

### Sub-decision table

| Sub-decision | Options | Chosen |
|---|---|---|
| Toggle mechanism | `prefers-color-scheme` only / `data-theme` 2-state / **`data-theme` 3-state (light/dark/system)** / Tailwind `dark:` class | **3-state with Tailwind `variant` strategy** |
| Persistence | localStorage only / **cookie + localStorage cache** / session / host user schema | **Cookie + localStorage** (server-readable before first paint) |
| Anti-FOUC | None (accept flash) / defer script / **blocking inline script** | **Blocking inline nonce'd `<script>`** in `<head>` |
| Runtime brand override | Rebuild CSS at boot / **inline nonce'd `<style>`** / dynamic `/brand.css` route / CSS custom property fetch | **Inline `<style>`** (80 bytes, reuses nonce) |
| Palette → Tailwind | Raw palette only / **semantic aliases + raw palette** / raw only with `dark:` variants everywhere | **Semantic aliases primary** (`base`, `primary`, `muted`, `accent`, etc.); raw palette available for fixed-identity surfaces (PDFs, emails) |
| Accessibility | Runtime check / none / **pure-Elixir WCAG helper + unit tests** | **`Accrue.Color` helper (~40 LOC) + property tests via `stream_data`** |

**Cross-ecosystem:** Stripe Dashboard, Linear, GitHub — all use `data-theme` attribute + cookie/server-readable + inline anti-FOUC script. Linear's inline `<script>` pattern cited as reference.

**Root layout ordering (load-bearing):** (1) meta charset → (2) anti-FOUC script → (3) brand.css → (4) app.css → (5) runtime override `<style>` → (6) LV client. Integration test asserts byte order.

**Brand schema deliberately minimal:** 3 keys (`app_name`, `logo_url`, `accent_hex`). `accent_contrast_hex` is *derived* so hosts cannot ship inaccessible pairings. `Accrue.Brand.resolve/1` raises at boot if AA fails.

**Host-user theme persistence:** Deferred to v1.1 — cookie fallback works for v1.0 single-device UX.

**User's choice:** Delegated to synthesis — all six sub-picks as above.

---

## Research methodology notes

Eight parallel agent invocations in two batches (four initially, then two-that-rate-limited + four behavior/UX areas). Each agent was briefed on:

- Project identity (Accrue, ship-complete v1.0, monorepo)
- Tech stack (Phoenix 1.8, LiveView 1.1, Ecto 3.13, PG 14+)
- The specific gray area
- Hard constraints
- Decided context from prior gray areas (to enforce coherence across agents)
- Instruction to research deeply (WebFetch, source-reading), compare options, pick ONE with strong rationale, and include downstream implications

**Coherence cross-check performed during synthesis:** D7-01 (mount) unlocks D7-02 (assets), D7-03 (components), D7-05 (auth hook), D7-07 (dev gates), D7-08 (theme) — verified no contradictions between advisor recommendations.

**Total advisor token budget:** ~225k tokens across 8 agents (estimated from returned outputs).

## Claude's Discretion

See D7-01..D7-09 "Claude's Discretion" bullets in `07-CONTEXT.md`. Summary: exact breakpoint pixels, exact component prop names, wave ordering in PLAN.md, exact test-clock button row, fixture selector UX, Oban concurrency display value, `Accrue.Color` API surface beyond the public three, CmdK command registry shape, wave-to-req assignment.

## Deferred Ideas

See `<deferred>` section in `07-CONTEXT.md`. Summary: host-user theme persistence (v1.1), action-token async approvals (v1.1), payload diff viewer (v1.1), scoped detail-page PubSub (per-page planner decision), advanced filter drawer (v1.1), saved filter views (v1.1), bulk cancel/refund (deliberately not v1.0), four-eyes approval (v1.1+).
