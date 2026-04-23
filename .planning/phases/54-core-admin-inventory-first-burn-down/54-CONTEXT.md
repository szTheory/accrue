# Phase 54: Core admin inventory + first burn-down - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>

## Phase boundary

Publish **ADM-07**: a **single canonical** gap inventory of **core** `accrue_admin` mounted surfaces (dashboard, customers, subscriptions, invoices, charges, webhooks — list and detail where routed) vs **`AccrueAdmin.Copy`** (and delegated `copy/*.ex`), **`ax-*` / theme token** discipline aligned to **v1.6 UX-04**, and **VERIFY-01** posture — **excluding** the v1.13 auxiliary set (**coupons**, **promotion codes**, **Connect**, **events**).

Execute **ADM-08**: close **P0** gaps on **one** named **money-primary** list/detail route group so operator-visible strings route through **Copy**, tokens match intent, and **ExUnit** / **existing** Playwright assertions on **materially touched** paths do not diverge from Copy-backed UI.

**Explicitly later (roadmap-locked):** merge-blocking **Playwright + axe** extension for the ADM-08 group (**ADM-09**, Phase 55); **theme-exceptions** churn + **`export_copy_strings` / `copy_strings.json` / CI allowlist** expansion when Copy modules grow (**ADM-10**, **ADM-11**, Phase 55). Phase 54 may still **touch** `theme-exceptions.md` for **real** deviations discovered during burn-down, but the **register discipline** as a milestone gate stays Phase 55 unless a row is **required** to honestly describe code shipped here.

</domain>

<decisions>

## Implementation decisions

*Research synthesis: parallel subagent review (Hex/OSS docs norms, Pay/Cashier/Stripe operator patterns, Phase 50/53 locks). Recommendations below are intentionally one coherent package.*

### 1 — ADM-07 inventory artifact (location, shape, VERIFY handoff)

- **D-01 (canonical SSOT):** Add **`accrue_admin/guides/core-admin-parity.md`** as the **authoritative ADM-07 matrix** (versioned with the package, ship in Hex `files`, list in **ExDoc `extras`** next to **`guides/admin_ui.md`**). **Do not** maintain a second competing matrix under **`.planning/phases/54-*`** — phase notes **link** to stable headings in that guide.
- **D-02 (table columns — minimum):** Each **one row per mounted surface** (see §4): **Route (relative to mount)**, **LiveView module + action**, **`AccrueAdmin.Copy` posture** (clean / gaps / N/A), **`ax-*` / token posture** (clean / gaps / pointer to **`guides/theme-exceptions.md`** slug when exception), **Named VERIFY flow id** (empty until Phase 55 defines specs — use `—`), **`VERIFY-01 lane`** (`merge-blocking` \| `advisory` \| **`planned — Phase 55 (ADM-09)`** \| `n/a`), **Severity** (`P0` / `P1` / `P2` for this milestone).
- **D-03 (VERIFY column semantics):** Use **named flows**, never URL crawls (**Phase 50 D-19**, **Phase 53 D-01**). For core surfaces not yet covered by merge-blocking specs, **`VERIFY-01 lane` = `planned — Phase 55 (ADM-09)`** and **`VERIFY flow id` = `—`** until ADM-09 assigns ids — preserves honest inventory without renaming VERIFY policy.
- **D-04 (discoverability):** Add a short anchor subsection or link from **`guides/admin_ui.md`** and optionally **one line** in **`accrue_admin/README.md`** pointing to the parity guide — README stays policy-level; the matrix lives in the guide (Oban/Req-style **Hexdocs co-located guides** idiom vs Rails-engine README dumps).
- **D-05 (ecosystem lesson):** Avoid **Pay-style implicit-only** coverage (“grep the repo”) for P0 triage; avoid **out-of-git** wikis. Prefer **Laravel-doc-shaped** versioned guide sections with a **scannable appendix table** (Cashier-shaped, not laravel.com infrastructure).

### 2 — ADM-08 anchor flow (money-primary burn-down + Phase 55 VERIFY anchor)

- **D-06 (locked anchor):** **`/invoices` + `/invoices/:id`** (**`InvoicesLive` index**, **`InvoiceLive` show**) is the **ADM-08** money-primary route group for P0 close-out and the **implicit VERIFY anchor** Phase 55 extends under **ADM-09**.
- **D-07 (rationale):** Invoices are the strongest **“show me the money document”** operator loop (Stripe Dashboard–shaped), with **high literal + table/section density** where Copy and **`ax-*`** discipline pay off and where future **axe** ROI is highest. Subscriptions align with **library positioning** (Cashier/Pay lifecycle) but **Phase 49** already stressed subscription drill — net-new P0 may be thinner; **customers** blurs money vs identity; **webhooks** optimizes the wrong operator story for “money-primary.”
- **D-08 (Phase 55 discipline):** When ADM-09 adds Playwright, favor **accessible roles/structure** over brittle full amount-string snapshots; treat **PDF / download / new tab** edges explicitly so VERIFY stays stable.
- **D-09 (deferral, not competition):** If implementation discovers **invoices** scope blocked, document in **`54-VERIFICATION.md`** and **planner** may propose **subscriptions** as the anchor — **requires CONTEXT amendment**; default remains **invoices**.

### 3 — P0 / P1 / P2 and “no divergent literals” scope

- **D-10 (P0):** On the **ADM-08 anchor flow only**: (a) operator-visible English not routed through **`AccrueAdmin.Copy`** (or established **`copy/<domain>.ex` + `defdelegate`**); (b) **material** **`ax-*` / token** violations on **touched** markup (fix or register **honest** exception — prefer fix on touched rows); (c) **any** **ExUnit** or **existing** Playwright assertion on a **materially touched** path that hard-codes copy now owned by Copy. **Closure** = that flow’s operator chrome is Copy-backed and token-correct on touched files, and tests on those paths track Copy.
- **D-11 (P1):** Same categories on **adjacent** core surfaces, **shared chrome** only where not required for ADM-08 closure, **non-operator** strings, or inventory-only gaps explicitly deferred.
- **D-12 (P2):** Broad refactors, advisory-only hygiene, **URL-matrix** / crawl-style tests — **out of scope** for Phase 54 (**Phase 50 D-19** anti-pattern).
- **D-13 (literal scope — not whole-repo):** **Minimum:** every **git-touched** file in the anchor closure. **Maximum:** **route closure** (invoice list + detail + **shared components / layout slots that those actions render**), not “every module in `accrue_admin`.”
- **D-14 (VERIFY vs Phase 54):** **Do not** add **new** merge-blocking **Playwright + axe** coverage in Phase 54 (**ADM-09**). **Do** minimally edit **existing** specs if ADM-08 changes would otherwise make assertions **false** (**principle of least surprise** for CI).
- **D-15 (`export_copy_strings` / JSON):** **Phase 55 / ADM-11** owns systematic **`export_copy_strings`**, **`copy_strings.json`**, and CI allowlist expansion when introducing or extending Copy modules. Phase 54 **only** touches that pipeline if an **existing** Playwright path already consumes generated JSON and would **break** without a minimal allowlist/export sync (**Phase 53 churn lesson** — avoid drive-by broad JSON churn).

### 4 — ADM-07 core surface checklist (rows + exclusions)

- **D-16 (row source of truth):** Rows are derived **only** from **`accrue_admin/lib/accrue_admin/router.ex`** `live/3` entries inside the **`accrue_admin/2` macro** — Rails-engine **`routes.rb` mental model**: what hosts mount is what inventory lists.
- **D-17 (canonical 11 rows — paths relative to mount):**
  - `/` — `AccrueAdmin.Live.DashboardLive` — `:index`
  - `/customers` — `AccrueAdmin.Live.CustomersLive` — `:index`
  - `/customers/:id` — `AccrueAdmin.Live.CustomerLive` — `:show`
  - `/subscriptions` — `AccrueAdmin.Live.SubscriptionsLive` — `:index`
  - `/subscriptions/:id` — `AccrueAdmin.Live.SubscriptionLive` — `:show`
  - `/invoices` — `AccrueAdmin.Live.InvoicesLive` — `:index`
  - `/invoices/:id` — `AccrueAdmin.Live.InvoiceLive` — `:show`
  - `/charges` — `AccrueAdmin.Live.ChargesLive` — `:index`
  - `/charges/:id` — `AccrueAdmin.Live.ChargeLive` — `:show`
  - `/webhooks` — `AccrueAdmin.Live.WebhooksLive` — `:index`
  - `/webhooks/:id` — `AccrueAdmin.Live.WebhookLive` — `:show`
- **D-18 (explicit exclusions from core table):** `/coupons*`, `/promotion-codes*`, `/connect*`, `/events` (v1.13 auxiliary). **Static asset** `get("/assets/…")` routes: **not** LiveView rows (optional one-line appendix note). **`/dev/*`** LiveViews: **omit** from core table; prose note only — *“when `allow_live_reload: true`; not part of supported OSS operator UX.”*
- **D-19 (optional hygiene):** A **non-normative** maintenance note may suggest diffing router `live/…` vs **`lib/accrue_admin/live/**/*.ex`** for orphans — **not** part of ADM-07 row count.

### 5 — Cross-cutting principles

- **D-20 (least surprise):** Inventory **truthfully** shows VERIFY as **planned** where specs do not yet exist; ADM-08 **does not** silently expand VERIFY merge-blocking policy.
- **D-21 (DX):** One **Hex-visible** guide for evaluators cloning only the package tarball; phase artifacts **narrate execution**, they do not fork the matrix.
- **D-22 (VERIFY policy):** **Unchanged** merge-blocking vs advisory semantics (**milestone ROADMAP**).

### Claude's discretion

- Exact markdown heading names / table sorting in **`core-admin-parity.md`** as long as **D-01–D-05** columns exist.
- Minor **invoice** edge treatments (PDF, async patches) inside ADM-08 as long as **D-10** P0 closure and **D-14** VERIFY boundary hold.
- Whether **`54-VERIFICATION.md`** uses a short appendix vs only links — must **link** the parity guide as canonical.

</decisions>

<canonical_refs>

## Canonical references

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/REQUIREMENTS.md` — **ADM-07**, **ADM-08** (v1.14)
- `.planning/ROADMAP.md` — Phase **54** goal, Phase **55** dependency on ADM-08 anchor
- `.planning/PROJECT.md` — v1.14 charter; **PROC-08** / **FIN-03** non-goals

### Prior phase locks (carry-forward)

- `.planning/phases/50-copy-tokens-verify-gates/50-CONTEXT.md` — Copy/`Locked` boundary, **`theme-exceptions.md`**, VERIFY **named flows** (**D-19**), anti-drift (**D-23**)
- `.planning/phases/53-auxiliary-admin-connect-events-layout-verify/53-CONTEXT.md` — **`export_copy_strings`** hygiene, CI script order, VERIFY flow naming

### Package and host implementation touchpoints

- `accrue_admin/lib/accrue_admin/router.ex` — **authoritative route list** for ADM-07 rows (**D-16**)
- `accrue_admin/guides/admin_ui.md` — link target for parity guide (**D-04**)
- `accrue_admin/guides/theme-exceptions.md` — intentional token/layout exceptions register
- `accrue_admin/lib/accrue_admin/copy.ex` — Copy facade + `defdelegate` insertion point
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex` — ADM-08 anchor index
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex` — ADM-08 anchor detail
- `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` — existing VERIFY-01 spine (do not expand merge-blocking scope in Phase 54 per **D-14**)
- `scripts/ci/accrue_host_verify_browser.sh` — canonical CI order when browser jobs run

### New deliverable (Phase 54)

- `accrue_admin/guides/core-admin-parity.md` — **ADM-07 canonical matrix** (**D-01**); add to **`accrue_admin/mix.exs`** `docs/0` **`extras`** alongside **`guides/admin_ui.md`**

</canonical_refs>

<code_context>

## Existing code insights

### Reusable assets

- **`AccrueAdmin.Copy`** + existing **`lib/accrue_admin/copy/*.ex`** pattern — extend with e.g. **`AccrueAdmin.Copy.Invoice`** if volume warrants (**Phase 50 D-07**).
- **`guides/theme-exceptions.md`** — register real deviations rather than silent hex colors.
- **Host VERIFY-01** — extend only when Phase 55; Phase 54 touches only if assertions would otherwise lie.

### Established patterns

- **Router-first** surface inventory (engine-style mount contract).
- **Invoices list/detail** as standard Phoenix **index → show** drill within one **`live_session`**.

### Integration points

- **`mix.exs` ExDoc extras** — register new guide for Hex consumers.
- **Phase 55 planner** reads **`core-admin-parity.md`** `VERIFY` columns to fill **flow ids** and flip **`planned — Phase 55 (ADM-09)`** to merge-blocking where appropriate.

</code_context>

<specifics>

## Specific ideas

- User requested **all four** gray areas in one pass with **parallel subagent research** (Hex library docs norms, Pay/Cashier/Stripe Dashboard operator patterns, Phase 50/53 VERIFY + Copy hygiene). This CONTEXT merges those threads into **one** policy set: **Hex guide SSOT**, **invoices ADM-08 anchor**, **route-derived 11-row checklist**, **P0 scoped to anchor closure**, **no new merge-blocking Playwright in Phase 54**.

</specifics>

<deferred>

## Deferred ideas

- **Subscriptions-first anchor** — credible if invoices blocked; requires explicit CONTEXT amendment (**D-09**).
- **Subscriptions + invoices joint VERIFY group** — only if Phase 55 explicitly widens ADM-09 scope; not Phase 54 default.
- **Router-vs-filesystem orphan diff task** — optional hygiene (**D-19**); not ADM-07 row SSOT.

### Reviewed todos (not folded)

- None (`todo.match-phase` returned no matches).

</deferred>

---

*Phase: 54-core-admin-inventory-first-burn-down*  
*Context gathered: 2026-04-22*
