# Phase 53: auxiliary-admin-connect-events-layout-verify - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>

## Phase boundary

Ship **AUX-03..AUX-06** for **v1.13**: **Connect** + **billing events** admin LiveViews use **`AccrueAdmin.Copy`** (delegated domain modules), **`ax-*` / theme tokens** with documented exceptions, and **VERIFY-01** (**Playwright** + **axe** serious+critical merge-blocking) on the **auxiliary** surfaces this milestone owns—without **PROC-08**, **FIN-03**, new third-party UI kits, or VERIFY **policy** renames.

**Not in this phase:** Second processor / finance exports; **live** Connect **deauthorize** wiring (host-governed destructive command + reconciliation UX is a future slice); re-scoping **AUX-06** text in REQUIREMENTS (this CONTEXT interprets it coherently with Phase 50 **D-19** flow-based gates).

</domain>

<spec_lock>

## Requirements (locked via UI-SPEC + milestone docs)

**Design and copy targets are locked** in `.planning/phases/53-auxiliary-admin-connect-events-layout-verify/53-UI-SPEC.md` (approved **2026-04-22**) and **`.planning/REQUIREMENTS.md`** (**AUX-03..AUX-06**).

Downstream agents **MUST** read **`53-UI-SPEC.md`** before planning or implementing. Requirements are not duplicated here.

**In scope (summary):** `ConnectAccountsLive`, `ConnectAccountLive`, `EventsLive`; **`ax-*`** + **`--ax-*`** on v1.13-touched auxiliary rows; **VERIFY-01** extension; **theme-exceptions** register for real deviations.

**Out of scope (summary):** **PROC-08**, **FIN-03**, new UI registries, VERIFY policy renames.

**Implementation naming (CONTEXT overrides earlier UI-SPEC label):** use module **`AccrueAdmin.Copy.BillingEvent`** (not `Copy.Event`) — see **D-03** — UI-SPEC text updated to match.

</spec_lock>

<decisions>

## Implementation decisions (research-backed, `--all` + parallel research synthesis)

### 1 — VERIFY-01 inventory (**AUX-06**) vs UI-SPEC paths

- **D-01 (hybrid — reconciles AUX-06 with Phase 50 D-19):** Define merge-blocking VERIFY as **named operator flows**, not a URL crawl or “every mounted route in the repo.”
- **D-02 (depth where UI-SPEC points):** **Connect + billing events:** blocking **Playwright + axe** on **`/connect`**, **`/connect/:id`**, **`/events`** (light + dark where the **v1.12** gate already applies—follow existing `verify01-admin-a11y.spec.js` skips for mobile projects). One **critical affordance** per path after the same **locator-driven** LiveView readiness as Phase 50 **D-20**; **no `networkidle`**.
- **D-03 (Phase 52 deferral closure):** Add **one additional blocking journey each** for **coupons** and **promotion codes** (smallest flow that touches materially risky UI from **AUX-01..AUX-02**), explicitly closing the Phase 52 handoff that deferred full browser+axe for those routes to Phase 53—**not** an exhaustive auxiliary matrix.
- **D-04 (inventory artifact):** Maintain a **short checked-in mapping** (extend existing ADM-06 / VERIFY inventory pattern from Phase 50) from **each blocking spec / `test.describe`** to **which AUX requirement** it satisfies—prevents silent scope expansion later.
- **D-05 (ExUnit vs Playwright):** Keep **fast proof** in **`accrue_admin`** (**`Phoenix.LiveViewTest`**, Copy routing) for logic; **canonical mounted + axe proof** in **`examples/accrue_host`**—idiomatic split for a **Hex library + host-mounted** admin (Rails engine “dummy app” precedent).

### 2 — Destructive Connect (deauthorize) UX

- **D-06 (defer live affordance):** **Do not** ship **button + modal + LiveView event** for Stripe **deauthorize** / hard delete in Phase 53. Presentation + VERIFY + copy SSOT do not yet include a **host-declared capability** or **domain command** with reconciliation semantics—shipping destructive controls would violate **least surprise** (“library UI implies library guarantees authz + outcomes”).
- **D-07 (copy posture):** Reserve **destructive confirmation strings** in **`AccrueAdmin.Copy`** **only** when a future phase introduces an **opt-in** affordance (e.g. assign or behaviour: `connect_deauthorize_allowed`) **and** tests cover authz—until then, prefer **operator-safe** read-only guidance; if verbatim modal copy exists in UI-SPEC for future use, keep it **behind functions not called from HEEx** or document as **reserved** in planner notes so strings do not imply a live control.
- **D-08 (ecosystem lesson):** **Pay** / **Cashier** keep dangerous platform operations **host-owned** or in **Stripe Dashboard**; OSS billing libs that imply irreversible platform actions without host policy become **support and liability footguns**.

### 3 — Copy module shape & function prefixes

- **D-09 (modules):** Add **`lib/accrue_admin/copy/connect.ex`** and **`lib/accrue_admin/copy/billing_event.ex`** (`@moduledoc false`), exposed only via **`defdelegate`** on **`AccrueAdmin.Copy`**—same pattern as **Phase 52** coupon/promo and **Phase 50 D-07**.
- **D-10 (prefix policy — grep + BEAM clarity):**  
  - **Connect (list vs show):** **`connect_accounts_*`** for **`ConnectAccountsLive`**; **`connect_account_*`** for **`ConnectAccountLive`** (mirrors **`promotion_codes_*`** vs **`promotion_code_*`**).  
  - **Billing events index (and future show):** **`billing_events_*`** for **`EventsLive`**; **`billing_event_*`** reserved for a future detail surface.  
  - **Rationale:** bare **`event_*` / `events_*`** collides with **`handle_event`**, telemetry, and generic “event” vocabulary; **`BillingEvent`** matches domain language without ambiguous module **`Copy.Event`**.
- **D-11 (`Locked`):** No routine Connect/events copy through **`AccrueAdmin.Copy.Locked`** (**Phase 50 D-06**).

### 4 — `export_copy_strings` ↔ Playwright (**D-23** hygiene)

- **D-12 (single human rule):** For any string **Playwright asserts**, follow **Copy → `@allowlist` in `mix accrue_admin.export_copy_strings` → `mix accrue_admin.export_copy_strings --out …/copy_strings.json` → Playwright using **`copyStrings`** → commit **Elixir + JSON together**—never merge hand-pasted English in specs for SSOT-owned literals.
- **D-13 (CI alignment):** Treat **`scripts/ci/accrue_host_verify_browser.sh`** as canonical: **`accrue_admin` `assets.build` → `export_copy_strings` → host `npm` e2e**—already regenerates JSON before Playwright; contributors running **`npm run e2e`** locally must run the same export path (documented from **`accrue_admin/`**).
- **D-14 (Claude’s discretion — optional hardening):** Consider a **`git diff --exit-code`** on **`copy_strings.json`** after export in CI if stale committed JSON becomes noisy; not required to ship Phase 53 if current “CI always refreshes” stays trusted.

### Claude's discretion

- Exact **critical affordance** chosen per route (table landmark vs primary CTA) as long as each test proves **one** operator-visible success path + **axe** clean serious+critical.
- Whether **`git diff`** gate on generated JSON lands in Phase 53 or a hygiene follow-up (**D-14**).

</decisions>

<canonical_refs>

## Canonical references

**Downstream agents MUST read these before planning or implementing.**

### Milestone & phase contracts

- `.planning/REQUIREMENTS.md` — **AUX-03..AUX-06**
- `.planning/ROADMAP.md` — Phase **53** goal + success criteria; Phase **52** boundary
- `.planning/PROJECT.md` — v1.13 vision; non-goals (**PROC-08**, **FIN-03**)
- `.planning/phases/53-auxiliary-admin-connect-events-layout-verify/53-UI-SPEC.md` — locked UI/copy/VERIFY design contract

### Prior phase locks

- `.planning/phases/52-integrator-proof-package-alignment-auxiliary-copy-part-1/52-CONTEXT.md` — coupon/promo Copy; **D-13–D-16** VERIFY deferral to Phase 53
- `.planning/phases/50-copy-tokens-verify-gates/50-CONTEXT.md` — **D-18..D-23** VERIFY-01 + **`export_copy_strings`**; **ADM-06** inventory; **theme-exceptions**
- `.planning/phases/51-integrator-golden-path-docs/51-CONTEXT.md` — proof layering honesty (if VERIFY docs touch)

### Implementation touchpoints

- `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex` — **AUX-03** list surface
- `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` — **AUX-03** detail surface
- `accrue_admin/lib/accrue_admin/live/events_live.ex` — **AUX-04** index surface
- `accrue_admin/lib/accrue_admin/router.ex` — `/connect`, `/connect/:id`, `/events`
- `accrue_admin/lib/accrue_admin/copy.ex` — facade + **`defdelegate`** insertion point
- `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` — allowlist (**D-12**)
- `scripts/ci/accrue_host_verify_browser.sh` — assets → export → e2e order (**D-13**)
- `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` — primary VERIFY-01 extension file (**Phase 50 D-18**)
- `examples/accrue_host/e2e/generated/copy_strings.json` — Playwright SSOT view (**D-23**)
- `accrue_admin/guides/theme-exceptions.md` — token bypass register (**AUX-05**)

</canonical_refs>

<code_context>

## Existing code insights

### Reusable assets

- **`AppShell`**, **`Breadcrumbs`**, **`DataTable`**, **`KpiCard`**, **`ax-page-header`**, **`ax-kpi-grid`** — already used on Connect lives; align remaining literals to **Copy** + tokens per UI-SPEC.
- **`mix accrue_admin.export_copy_strings`** + **`verify01-admin-a11y.spec.js`** + **`fixture.js` `waitForLiveView`** — extend, do not fork.

### Established patterns

- **Phase 50:** serious+critical axe filter; desktop theme runs; **getByRole** / labels tied to Copy.
- **Phase 52:** **`copy/<domain>.ex` + `defdelegate`**; **`coupon_*` / `promotion_code_*`** naming discipline.

### Integration points

- **Host-mounted admin** under **`examples/accrue_host`** for Playwright; **`accrue_admin`** as path dependency for export compile.

</code_context>

<specifics>

## Specific ideas

- **Ecosystem synthesis applied:** Rails engine **dummy-app** style verification; **avoid matrix** and **snapshot** gates; Stripe-class dashboard depth is **not** replicated—**honest, thin, merge-blocking flows** + **Fake-backed** state beat implied full coverage.
- **UI-SPEC** table copy for empty states, CTAs, and errors are **targets** for **`AccrueAdmin.Copy`** functions—implement to match.

</specifics>

<deferred>

## Deferred ideas

- **Connect deauthorize / irreversible platform actions** as **first-class LiveView affordance** — future phase with **host opt-in capability**, **authorization assign**, **single domain entry point**, **webhook reconciliation UX**, and VERIFY for the destructive path.
- **Optional CI `git diff --exit-code` on `copy_strings.json`** — hygiene follow-up if maintainers want PR-visible string deltas without relying on CI-only regeneration (**D-14**).

### Reviewed todos (not folded)

- None.

</deferred>

---

*Phase: 53-auxiliary-admin-connect-events-layout-verify*  
*Context gathered: 2026-04-22*
