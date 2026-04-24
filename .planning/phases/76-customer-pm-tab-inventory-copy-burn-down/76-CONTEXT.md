# Phase 76: Customer PM tab — inventory + Copy burn-down - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **ADM-13** (short inventory of customer **`payment_methods`** tab strings, **`ax-*`** usage, and VERIFY-01 / Playwright posture vs adjacent customer tabs) and **ADM-14** (burn-down operator-visible strings on that tab through **`AccrueAdmin.Copy`**, with **`ax-*`** discipline and no divergent raw literals on materially touched test paths). **Out of scope for this phase:** **ADM-15**/**ADM-16** (VERIFY-01 + axe, theme exceptions, `export_copy_strings` hygiene), **BIL-04**/**BIL-05** (billing portal facade and telemetry milestone work).

</domain>

<decisions>
## Implementation Decisions

### ADM-13 — Inventory shape and placement

- **D-01:** **Verification-first, guide as pointer-only (variant of “both”).** The authoritative inventory (strings, `ax-*` summary, Playwright / VERIFY coverage vs adjacent customer tabs) lives in **`.planning/phases/76-customer-pm-tab-inventory-copy-burn-down/76-VERIFICATION.md`** (or the same tree under `.planning/phases/` if paths shift), so it ships with the phase gate and scopes **ADM-14..16** without duplicating a second full matrix elsewhere.
- **D-02:** Add a **minimal stub** under **`accrue_admin/guides/`** (new small doc or a short subsection of **`accrue_admin/guides/admin_ui.md`**) that does **not** duplicate the table: purpose, “inventory lives in phase verification,” and a **relative link** to the verification path. Staleness risk is minimized; merge-blocking truth stays **code + VERIFY**, not prose tables parsed by CI.
- **D-03:** Treat the inventory as a **dated scope snapshot** for the phase; if drift is feared, prefer regenerating excerpts (grep / export tooling) into verification over hand-maintaining long prose.

### ADM-14 — Copy module layout

- **D-04:** Introduce **`AccrueAdmin.Copy.CustomerPaymentMethods`** (or equivalent single submodule name agreed at implementation time) for **new and migrated** payment-methods tab copy, and re-export via **`defdelegate`** from **`AccrueAdmin.Copy`**, matching the established **`Copy.Invoice`**, **`Copy.Subscription`**, **`Copy.Connect`** pattern.
- **D-05:** **Do not** grow large batches of new payment-method strings inline in the root **`copy.ex`** file — avoids merge-conflict hotspots and naming collisions with other `payment_*` surfaces.
- **D-06:** **Defer gettext / host-overridable copy (Tier B)** for this workstream — Tier A remains **`AccrueAdmin.Copy`** as host-contract English; adding host `Gettext` merge semantics is out of scope and would surprise current integrators.
- **D-07:** **Existing** `customer_detail_*` helpers already on **`AccrueAdmin.Copy`** may remain until touched; **new** PM-tab strings go in the submodule. Optional later consolidation of legacy `customer_detail_*` into **`Copy.Customer*`** is not part of Phase 76 unless a single edit already requires it.

### ADM-14 — LiveView and file scope

- **D-08:** **Strict boundary:** code and copy changes target only the **`payment_methods`** tab branch in **`AccrueAdmin.Live.CustomerLive`** plus **PM-specific** tab chrome if explicitly tied to that tab (labels/counts that read as payment-method context). Do **not** burn down unrelated literals in the same file (e.g. charges empty state, subscription KPI delta text) in Phase 76.
- **D-09:** The **ADM-13** inventory must list **cross-tab stragglers** still in `customer_live.ex` (charges KPI copy, charges empty line, etc.) with an explicit **deferred to Phase 77** note tied to **ADM-15**/**ADM-16** or a follow-up line in **`76-VERIFICATION.md`**, so “while I’m here” fixes do not re-open scope in review.
- **D-10:** Uneven polish across tabs in one LiveView until later phases is **acceptable**; PR story stays “payment methods tab copy + tokens.”

### Tests — ExUnit vs Playwright vs axe (coherence with Phase 77)

- **D-11:** **Phase 76 = ExUnit-first:** extend **`Phoenix.LiveViewTest`** (and **`render_component/2`** where appropriate) so materially changed **payment_methods** output is asserted using literals from **`AccrueAdmin.Copy.*`** (or the new submodule via **`AccrueAdmin.Copy`** delegates) — **never** duplicate the same English string as a raw third copy in tests.
- **D-12:** **Playwright in 76 = touch-only:** update existing customer-route Playwright only when **selectors, navigation, or DOM** break due to this phase’s edits; do **not** add new merge-blocking browser scenarios or **axe** in Phase 76.
- **D-13:** **Phase 77 (ADM-15)** owns **VERIFY-01** extension: **Playwright + `@axe-core/playwright`** for **≥1** materially changed **customer** mounted route group tied to **ADM-14**, reusing Copy / **`copy_strings.json`** patterns so browser assertions are not a second independent prose source.
- **D-14:** Prefer stable assertions (**roles**, accessible names, established **`ax-*`** hooks where they double as anchors) over brittle XPath / nth-child.

### Research synthesis (non-normative but rationale)

- **Cross-ecosystem:** Rails engines / Laravel packages often keep volatile enumerations next to **verification or generated artifacts**, not duplicated in user guides; **Stripe-style** products ship fixed operator copy rather than gettext-per-host for dashboard chrome. **Django** gettext fits core framework admin, not a small Hex LiveView add-on without a gettext story.
- **DX:** Submodule + facade preserves **grep-friendly** ownership, matches **Accrue’s existing Copy architecture**, and keeps CI gates on **VERIFY / code**, not dual markdown inventories.

### Claude's Discretion

- Exact submodule name (**`CustomerPaymentMethods`** vs **`Customer.PaymentMethods`**) if the first collides or reads cleaner beside future **`Copy.Customer.*`** siblings.
- Whether the guide stub is a **new file** vs a **subsection** of **`admin_ui.md`** — prefer whichever keeps the stub under ~15 lines and avoids ExDoc noise.

### Folded Todos

_None — `todo.match-phase` returned no matches._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and planning

- `.planning/REQUIREMENTS.md` — **ADM-13**, **ADM-14** (v1.24); **ADM-15**/**ADM-16** for explicit out-of-scope boundary
- `.planning/ROADMAP.md` — **### Phase 76** … **### Phase 78** sections (milestone success criteria)
- `.planning/PROJECT.md` — v1.24 goals, **PROC-08** / **FIN-03** non-goals

### Implementation anchors

- `accrue_admin/lib/accrue_admin/live/customer_live.ex` — customer LiveView; **`payment_methods`** tab branch
- `accrue_admin/lib/accrue_admin/copy.ex` — **`AccrueAdmin.Copy`** facade and **`defdelegate`** patterns
- `accrue_admin/lib/accrue_admin/copy/` — existing submodule implementations (**`invoice.ex`**, **`subscription.ex`**, etc.) as templates

### Maintainer guides

- `accrue_admin/guides/admin_ui.md` — likely home for **ADM-13** pointer stub (or link target)
- `accrue_admin/guides/theme-exceptions.md` — **Phase 77** (**ADM-16**); do not expand for PM tab unless a Phase-76 change **requires** an exception (avoid preempting 77)

### Prior art (archived phases — patterns only)

- `.planning/milestones/v1.17-phases/65-p0-admin-operator/65-CONTEXT.md` — **ADM-12** operator / Copy / VERIFY precedent (read if planner needs stop-rule context)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`AccrueAdmin.Copy`** + **`AccrueAdmin.Copy.<Surface>`** submodules with **`defdelegate`** — canonical pattern for invoice/subscription/connect/coupon copy; reuse for payment methods tab.
- **Existing customer helpers** on **`AccrueAdmin.Copy`**: e.g. **`customer_detail_no_subscriptions`**, **`customer_detail_no_invoices`** — pattern for empty states; PM tab empty line should align once migrated.

### Established Patterns

- **Tier A copy** is English **`Copy`**, not host **Gettext** — documented in **`copy.ex`** moduledoc and Phase 27 context references.
- **Customer detail** uses **`AppShell`**, **`Tabs`**, **`ax-*`** classes — inventory should note token usage on PM rows vs other tabs.

### Integration Points

- **`customer_live.ex`** `~H"""` **payment_methods** branch (~lines 176–184) — primary edit surface for **ADM-14**.
- **Tab counts / KPI** strings that mention payment methods but sit outside the PM tab — **document in inventory, defer code** per **D-09**.

</code_context>

<specifics>
## Specific Ideas

- User requested **research-backed, one-shot** recommendations; subagent synthesis converged on: **verification-first inventory + guide pointer**, **`Copy.CustomerPaymentMethods` + `defdelegate`**, **strict PM-tab scope**, **ExUnit-first / touch-only Playwright / axe in Phase 77**.

</specifics>

<deferred>
## Deferred Ideas

- **Charges tab empty state**, **subscriptions KPI delta** copy mentioning payment methods, and other **non–`payment_methods` tab** literals in **`customer_live.ex`** — explicit **Phase 77** (**VERIFY-01**, **`export_copy_strings`**, theme) or later phase; listed in **ADM-13** inventory, not silently “fixed” in **ADM-14** PRs.
- **gettext / host-overridable** operator strings — not Phase 76; would be a product-level decision outside current Tier A contract.

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 76-customer-pm-tab-inventory-copy-burn-down*  
*Context gathered: 2026-04-24*
