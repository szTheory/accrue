# Phase 175: B — Persona-Driven IA Spine - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the entity-shaped admin interior with a job/persona-shaped spine: re-tier `nav.ex`/`sidebar.ex` into one weighty primary **Billing** zone plus visually-recessed, collapsible specialist zones (Recovery · Developer · Catalog) that surface attention-count badges only when work exists, with Connect standing alone; default list screens to the persona work-queue with an "All" escape hatch one filter-chip away; tier the Customer-360 tabs (primary visible, the rest under "More"); make threading mandatory + bidirectional on all 8 detail screens via `related_resources.ex` and close the Webhook→Event→affected-entity gap; surface a visible labeled global-search field + verb-relabeled task launchers on Home; and add a Compliance actor-lens to `/events`. All route reshaping ships **with redirects** — no broken bookmarks. **No new billing primitives, no per-screen rubric uplift (that is Phase C), no motion work (Phase D).** Satisfies IA-01 through IA-07.

</domain>

<decisions>
## Implementation Decisions

All four areas were proposed as a synthesized package grounded in the locked design source (`.planning/research/v1.51-admin-ui-depth-design.md` §3) + a codebase scout, and accepted as-is by the user (calibration: `minimal_decisive`). The design source had already locked the high-level shape (cordoned-hybrid nav, work-queue defaults, Customer-360 tiering, bidirectional threading incl. Webhook→Event→entity, Compliance-as-lens, no Tailwind, mobile-first, exact Home verb labels); these decisions resolve the remaining implementation mechanics.

### Nav hierarchy & attention badges (IA-01, IA-02)
- **Recess mechanism:** specialist zones (Recovery · Developer · Catalog) render as **collapsible group headers** with muted/smaller labels + a chevron; the primary **Billing** zone is always-expanded and visually heavier (no collapse). **Connect** stands alone.
- **Default collapse state:** auto-**expand a specialist zone when its badge count > 0, collapse when empty**; persist the user's manual toggle in `localStorage`.
- **Badge data source:** reuse the existing **dashboard attention queries** (dead-letter webhooks → Developer badge; past-due / at-risk → Recovery badge) via a shared context function computed in `on_mount` / sidebar assigns — do NOT write parallel count queries.
- **Badge refresh cadence:** compute **once per navigation** (LiveView assign, no polling / no PubSub) — cheap and sufficient for v1.51.

### Work-queue defaults & route reshaping (IA-03, IA-07)
- **Per-list default queue filters:** invoices → **open + uncollectible**; subscriptions → **past_due + canceling (at-risk)**; payments → **failed**; customers → **all** (it is the Support lookup tool — no queue overwhelm).
- **Default-filter mechanism:** apply the default **in the LiveView** and `push_patch` so the URL reflects `?status=…` (shareable / bookmarkable); the **"All" filter chip** clears the queue filter. Do NOT use a hard HTTP redirect for the default filter, and do NOT leave the URL unchanged.
- **"Payments" route reshaping:** add a `/payments` route pointing at the existing `ChargesLive`/`ChargeLive`, and **redirect `/charges` → `/payments`** (and `/charges/:id` → `/payments/:id`) so existing bookmarks survive; relabel the nav leaf "Payments".
- **"All" escape hatch:** a persistent **"All" filter chip** reusing `filter_chip_bar` — one click clears the persona-queue filter.

### Threading & Customer-360 tiering (IA-04, IA-05, IA-06)
- **Customer-360 split:** primary visible tabs = **Subscriptions, Invoices, Payments** (the `charges` tab surfaces as "Payments" to match the new route/label); recessed under **"More"** = Payment methods, Entitlements, Events, Metadata.
- **"More" mechanism:** a **"More ▾" overflow dropdown** at the end of the tab strip (keeps the primary tabs prominent and is mobile-friendly).
- **Webhook→Event→entity thread:** add a Related card on Webhook detail linking to the Event(s) it produced, and **add a lightweight `/events/:id` detail (or focus drawer)** so the event → affected-entity hop has a destination (Events currently has no detail route — this closes the weakest thread, the Developer incident path).
- **Bidirectional Related card scope:** **all 8 detail screens** — customer, subscription, invoice, charge (payment), coupon, promotion_code, connect_account, webhook — each renders a Related-billing card; no detail screen dead-ends.

### Compliance lens & Home refinements (IA-01)
- **Compliance actor-lens:** a **saved actor-filter preset surfaced as a labeled quick-filter chip ("By actor")** on `/events` using the existing filter mechanism — NOT a new nav group (Compliance is rare enough to be a lens).
- **Home verb relabels:** apply the exact design strings — **"Look up a customer," "Clear the invoice queue," "Recover at-risk revenue," "Investigate an incident."**
- **Visible search:** render `GlobalSearch` as a **visible labeled input** (placeholder "Search customers, invoices… ⌘K") in the topbar + a prominent field on Home, still ⌘K-activatable.
- **Anti-churn on frozen Home zones:** touch Home **only** for the verb relabel + search-field surfacing (both are design-mandated persona-job fixes); leave the attention rail, KPIs, and recent-activity zones frozen.

### Claude's Discretion
- Exact CSS/token choices for the recessed-zone visual weight, chevron affordance, and badge styling are left to the planner/executor — must resolve from Phase 174 `ax-*` tokens (no literals).
- Exact shape of the lightweight event detail (full `/events/:id` LiveView vs. a focus drawer reusing `detail_drawer.ex`) is the planner's call, provided the Webhook→Event→entity thread is navigable and bidirectional.
- Exact `localStorage` key naming and the JS hook wiring for collapse persistence.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`nav.ex`** — already groups items into Billing / Recovery / Developer / Catalog / Connect (`{label, href, icon, group}`); has **no badge mechanism** today (add one).
- **`sidebar.ex`** — stateless functional component rendering grouped sections with active-state path matching (`ax-sidebar-link-active`); **no collapse, no badges** today (extend).
- **`filter_chip_bar.ex`** — mature chip API `{id,label,value,tone,remove_href,active}`; tones moss/cobalt/amber/slate/ink; reuse for the "All" + persona-queue chips.
- **`data_table` live component** — list pages already sync `filter_fields` to URL query params; the work-queue default rides on this existing mechanism.
- **`related_resources.ex`** — card of `{icon,label,href,:value}` links, renders nothing when empty; used today on Customer / Invoice / Charge detail (one-way query-param chains). Extend to all 8 detail screens + add the Webhook→Event→entity chain.
- **`customer_live.ex`** — `@tabs = ~w(subscriptions invoices charges payment_methods entitlements events metadata)` with per-tab counts; flat today (tier into primary + More).
- **`dashboard_live.ex`** — attention rail + 4 task launchers ("Find a customer" / "Work open invoices" / "Recover failed payments" / "Debug dead-letter webhooks") + KPIs + recent activity; attention queries here are the badge data source.
- **`global_search.ex`** — visible-in-shell LiveComponent, toggled by action; searches customers/invoices/subscriptions async. Surface as a labeled field.

### Established Patterns
- Custom `ax-*` BEM-adjacent CSS + tokens; **Tailwind is inert — do NOT migrate.** All new nav/badge/chip styling resolves from Phase 174 `ax-*` tokens (no literal hex/px).
- Phoenix function-components; list filters are URL-query-param driven via `data_table`.
- Committed asset bundle (`priv/static/accrue_admin.css`) — run `cd accrue_admin && mix accrue_admin.assets.build` after any CSS/JS edit and commit `priv/static`.

### Integration Points
- New nav-badge counts: shared context fn → `on_mount`/sidebar assigns (consumed by `sidebar.ex`).
- `/payments` route + `/charges` redirect in `router.ex`; nav leaf href update in `nav.ex`.
- Lightweight `/events/:id` (or drawer) wired from `webhooks` detail + `related_resources.ex`.

</code_context>

<specifics>
## Specific Ideas

- **Authoritative design source:** `.planning/research/v1.51-admin-ui-depth-design.md` — §2 personas, §3 locked decisions, §4 Phase B scope (lines 95–99), §6 rubric + verification commands, §7 scope guardrails, §8 critical files. Downstream agents MUST read it.
- **Anti-churn justification token** required for every change: (a) a rubric dimension below bar with a before-score, (b) a named persona-job the screen fails to serve, or (c) a concrete token bypass eliminated. "Looks nicer" is not admissible.
- **Verification:** `cd accrue_admin && mix accrue_admin.assets.build`; `npm run e2e:visuals:png-only`; axe via `admin-a11y.spec.js` (light+dark). Admin mounts at `/billing` (configurable `mount_path`). Known flaky `accrue` PdfTest — dodge with `--seed 0`.
- **No breaking changes:** route reshaping ships with redirects; component public APIs stay backward-compatible; v1.50 shared components are extended, not replaced.

</specifics>

<deferred>
## Deferred Ideas

- **Per-screen rubric uplift** (charges, coupons, promotion-codes, connect, events, webhooks, invoice detail) → Phase C (176).
- **Motion / micro-interactions** on the new collapsible nav, More dropdown, drawers → Phase D (177).
- **Seed/state coverage** so every new state (at-risk queues, dead-letter badges) is reachable from seeds → Phase E (178).
- **Screenshot QA sign-off** of the reshaped IA → Phase F (179).
- **Live badge updates via PubSub** — deferred; per-navigation compute is sufficient for v1.51.

*Discussion stayed within phase scope — no scope creep into per-screen uplift, motion, or seed work.*

</deferred>

---

*Phase: 175-b-persona-driven-ia-spine*
*Context gathered: 2026-06-04*
