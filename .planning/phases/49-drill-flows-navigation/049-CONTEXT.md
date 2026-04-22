# Phase 49: Drill flows & navigation - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **ADM-02** and **ADM-03** for **v1.12**: make **one** scoped, high-traffic **list/detail drill** measurably smoother (fewer dead ends, clearer next actions, preserved context) on **concrete LiveView routes** named in the phase plan. If primary nav or README **inventory** would drift, keep **labels/order** aligned with the **billing-noun** operator model — without expanding scope into **ADM-04..06** (Phase **50**).

**Non-goals:** New accounting semantics, **PROC-08** / **FIN-03**, new third-party UI kits, core schema/processor work, **ADM-06**-scale Playwright/axe expansion (deferred to Phase **50** per Phase **48** precedent).

</domain>

<decisions>
## Implementation Decisions

### 1 — Primary drill slice (ADM-02) — research synthesis

- **D-01:** The **single ADM-02 vertical slice** is **customer → subscription → invoice**, using these **concrete routes** (org-scoped via existing session/`ScopedPath` helpers): **`CustomersLive` / `CustomerLive` → `SubscriptionLive` → `InvoiceLive`**. This matches the **REQUIREMENTS.md** example, **Pay/Cashier** mental models (billable/customer first), and Stripe Dashboard’s strength (**cross-linked money objects**) without attempting Stripe breadth.
- **D-02:** **Primary implementation emphasis** within that slice is **`SubscriptionLive`**: today **`InvoiceLive`** breadcrumbs encode **Dashboard → Invoices → Customer → Invoice** (strong upward context), while **`SubscriptionLive`** stops at **Dashboard → Subscriptions → id** (operator dead-end vs “who is this for?”). Phase **49** closes that **asymmetry** so the slice feels **intentional**, not accidental.
- **D-03:** **Do not** broaden ADM-02 to parallel chains (webhook/event triage, Connect, coupon drills) in Phase **49** — one slice keeps LiveView assigns, tests, and docs **coherent** for a **mounted library** admin.

### 2 — “Smoother” = observable navigation + honesty (ADM-02)

- **D-04:** **Breadcrumbs** on **`SubscriptionLive`** follow the same **principle** as **`InvoiceLive`**: include a **linked Customer** segment between the **relevant index** and the **current record** (e.g. **Dashboard → Subscriptions → {Customer} → {Subscription}**), using **`ScopedPath`** / existing scope helpers — **no** new org-scoping patterns.
- **D-05:** Add **one** curated **`ax-card` “Related billing”** (or equivalently named) region on **`SubscriptionLive`** with **≤5** links: at minimum **Customer**; **Invoices** (index or honest deep link); optional **Charges** / **Events** only if links are **provably** row-scoped and not misleading. **Forbidden:** “junk drawer” association dumps; links that **404** or cross owner scope.
- **D-06:** **List views** touched in this slice keep **GET query params** as the **source of truth** for filters/pagination (**`handle_params`** → parsed filter + query modules). **No** session-only list state. **No** new `push_patch` loops for non-bookmarkable UI.
- **D-07:** **Honest URLs (Phase 48 discipline):** any `?filter=` / `?status=` style link from the drill must match **byte-for-byte** what **`AccrueAdmin.Queries.*`** applies — if parity cannot be proven in review, ship **index-only** links plus copy that does **not** imply a pre-filtered row set.

### 3 — Primary navigation & ADM-03 (README / route inventory)

- **D-08:** Phase **49** is **drill-only** for **`AccrueAdmin.Nav`**: **no** add/remove/reorder of **top-level** sidebar items and **no** IA grouping changes. Rationale: nav changes are **cross-cutting** (shell, `nav_test`, evaluator muscle memory); mixing with drill polish **inflates** merge risk and blurs ADM-02 acceptance.
- **D-09 (allowed without violating D-08):** **Href correctness**, **a11y** fixes that **do not** change IA, **breadcrumb** / in-page link work, and **README “Admin routes”** updates that **reflect router truth** (new rows only if **router** changed — not expected in **49**) or **clarify** existing **router-order vs sidebar-order** policy to prevent contributor drift.
- **D-10:** If a future phase adds a **new** `live` index, treat **router + README + nav + tests** as one **explicit** IA task — **defer** to Phase **50+** unless roadmap is amended.

### 4 — Verification posture (Phase 49 vs Phase 50)

- **D-11:** **Primary proof** of ADM-02 is **`Phoenix.LiveViewTest`** (and direct **`AccrueAdmin.Copy`** unit tests if new strings are unavoidable before Phase **50** — prefer reusing existing keys). Cover: breadcrumb **href** targets, **Related** links, **org** query preservation, and **no-regression** on redirects/flashes.
- **D-12:** **`examples/accrue_host`**: at least **one** integration-style test that walks the **named concrete routes** through the **mounted** admin router (fixtures as existing host tests do), so wiring mistakes are caught outside `accrue_admin` isolation.
- **D-13 (Playwright — Phase 48 D-13 carry-forward):** **Do not** add **new** VERIFY-01 **Playwright** scenarios or expand **axe** breadth in Phase **49**. **Exception:** an **existing** merge-blocking spec **breaks** because of DOM/route changes — apply the **smallest** fix (**roles/labels** first; **at most one** stable `data-test-id` on the touched region if required).
- **D-14:** Full **ADM-06** Playwright + **axe** pass for **all** v1.12-touched mounted paths remains **Phase 50**.

### 5 — Ecosystem & architecture principles (non-normative but guides tradeoffs)

- **D-15:** Prefer **Stripe-style** “never lost” **object linking** with **Accrue-style** honesty: **links > clever filters** when SQL parity is uncertain.
- **D-16:** Prefer **library-idiomatic** Phoenix: **thin LiveViews**, **query modules**, **`handle_params` ownership** of URL state, **minimal assigns** — good **DX** for host adopters reading the admin as reference.

### Claude's Discretion

- Exact **Related** card title, link ordering within the **≤5** cap, and whether a **second** query (e.g. “open invoice count”) ships in **49** vs a follow-up micro-phase — bounded by **D-05** / **D-07** honesty rules.
- Whether **one** filtered invoice list link ships in **49** depends on proven **URL↔query** parity; otherwise link to **`/invoices`** only.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & requirements
- `.planning/REQUIREMENTS.md` — **ADM-02**, **ADM-03**
- `.planning/ROADMAP.md` — v1.12 Phase **49** row
- `.planning/PROJECT.md` — v1.12 goals; **PROC-08** / **FIN-03** non-goals

### Prior phase locks (carry-forward)
- `.planning/phases/48-admin-metering-billing-signals/48-CONTEXT.md` — honest **`href`**, **ScopedPath**, **Playwright deferral (D-13)**, **`data-test-id`** policy
- `.planning/phases/48-admin-metering-billing-signals/48-UI-SPEC.md` — only if **49** touches shared dashboard/layout (unlikely); **subscription drill** is the focus

### Code anchors (drill slice)
- `accrue_admin/lib/accrue_admin/router.ex` — route SSOT
- `accrue_admin/lib/accrue_admin/nav.ex` — sidebar IA (**read-only** for structural changes in **49**)
- `accrue_admin/README.md` — **Admin routes** inventory (**ADM-03**)
- `accrue_admin/lib/accrue_admin/live/customer_live.ex` — tabs + links into **`/subscriptions/:id`**
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — **primary** breadcrumb/related-link target
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex` — **reference** breadcrumb pattern
- `accrue_admin/lib/accrue_admin/scoped_path.ex` — org-safe paths

### VERIFY / CI
- `examples/accrue_host` — VERIFY-01 Playwright specs (touch only under **D-13** exception)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- **`AccrueAdmin.Components.Breadcrumbs`** — same component as **`InvoiceLive`**; extend pattern to **`SubscriptionLive`**.
- **`ScopedPath.build/3`** — org-safe customer and index links.
- **`CustomerLive`** — already links to **`/subscriptions/:id`** from the subscriptions table (**entry path** exists).

### Established patterns
- **`InvoiceLive`** — **customer in breadcrumb trail**; use as the **UX reference** for subscription detail.
- **Phase 48** — **no misleading query filters** on KPI deep links; same discipline for **Related** links.

### Integration points
- **`SubscriptionLive.mount/3`** already loads **`subscription.customer`** — enough assign surface for customer crumb + Related links **without** new N+1 patterns if links reuse loaded data.

</code_context>

<specifics>
## Specific Ideas

- **Subagent research (2026-04-22):** Pay/Cashier anchor on **billable**; Stripe sets the bar for **cross-links** — Phase **49** ships **Stripe-grade continuity** for **one** chain, not Stripe-wide IA.
- **Nav vs router:** Sidebar order is **deliberately curated** vs monotonic router order; README documents **router** order — Phase **49** may **clarify** that relationship in docs if confusion is likely (**D-09**).

</specifics>

<deferred>
## Deferred Ideas

- **Invoice-first** shortcuts (e.g. finance landing on invoice then jumping to customer) — nice follow-up; not the ADM-02 **primary** slice for **49**.
- **Webhook/event drill** polish — different operator job; not **49**.
- **Primary nav reorder** (e.g. audit cluster) — Phase **50+** with explicit IA + matrix/test budget (**D-08**).
- **ADM-04..06** bulk **Copy** migration + full Playwright/**axe** matrix — **Phase 50**.

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches.

</deferred>

---

*Phase: 49-drill-flows-navigation*  
*Context gathered: 2026-04-22*
