# Phase 50: Copy, tokens & VERIFY gates - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **ADM-04**, **ADM-05**, and **ADM-06** for **v1.12**: **`AccrueAdmin.Copy`** (and **`Copy.Locked`** where appropriate) plus **token/layout discipline** for all **milestone UI churn**, and **VERIFY-01**-aligned **Playwright** + **axe** on **every materially touched mounted-admin path**—without changing **merge-blocking vs advisory** semantics, **without** **PROC-08** / **FIN-03**, and **without** new third-party UI kits.

This phase **closes** the deferred verification posture from **Phases 48–49** (full **ADM-06** breadth lands here, not in 48/49).

</domain>

<decisions>
## Implementation Decisions

### 1 — ADM-04: what “v1.12 churn” means for Copy enforcement

- **D-01 (primary gate — hybrid):** Maintain an **explicit enforcement surface** (not “every file under `accrue_admin/lib`”): default globs **`accrue_admin/lib/accrue_admin/live/**/*.ex`** and **`accrue_admin/lib/accrue_admin/components/**/*.ex`**, **plus** any additional paths **named by Phase 48/49 artifacts** (CONTEXT, plans, verification) as UI-bearing for v1.12. **Policy:** in that surface, **new or changed user-visible string literals** that belong in the operator/admin UX must be expressed via **`AccrueAdmin.Copy`** (or **`AccrueAdmin.Copy.Locked`** when D-06 applies)—not raw HEEx/LiveView string blobs. Documented **escape hatches** only for truly dynamic values, legal/verbatim text that *must* stay in `Locked`, or host-injected fragments already covered by integration contracts.
- **D-02 (git diff):** Use **`git diff` vs integration branch** as a **secondary signal** (PR checklist and/or **advisory** CI), **not** the sole merge-blocking definition of ADM-04—diff-only is too noisy for a library repo and punishes unrelated edits.
- **D-03 (Hex library / host boundary):** Phase 50 **does not** require shipping a new runtime copy backend; **do** document the **intended seam** for hosts (future **optional** `Application.get_env`/behaviour-style override or Gettext domains) so literals are not “forked” across LiveViews. Until then, **`AccrueAdmin.Copy`** remains the **package-default English SSOT** (same philosophy as Pay/Cashier locale files, adapted to Accrue’s code-first library model).
- **D-04 (ecosystem lesson):** Follow **key-stable centralization** (Rails I18n / Laravel `lang` lesson): tests and Playwright must **not** re-duplicate English literals when a **`Copy.*`** function already exists—see **§5 D-15** for the concrete bridge.

### 2 — Copy module shape & naming (growth without API churn)

- **D-05 (public surface):** **`AccrueAdmin.Copy`** stays the **only documented entry module** for routine operator strings. **No** new public “string module” surfaces for hosts without a semver note.
- **D-06 (`Locked` boundary):** **`AccrueAdmin.Copy.Locked`** remains **only** for **verbatim, cross-surface-sensitive** strings (replay/legal/adjacent, audit echo, etc.). Do **not** route normal feature copy through `Locked` to avoid diluting that contract.
- **D-07 (scale Phase 50):** Add **`lib/accrue_admin/copy/<domain>.ex`** modules (e.g. `AccrueAdmin.Copy.Dashboard`) and expose them via **`defdelegate`** from **`AccrueAdmin.Copy`** so call sites keep **`alias AccrueAdmin.Copy`** and tests stay stable.
- **D-08 (naming):** Prefer **`{domain}_{surface}_{role}`**-style function names with **consistent prefixes** (`dashboard_*`, `subscription_*`, `invoice_*`, …)—grep-friendly, review-friendly, aligned with **Phase 48** dashboard meter keys and **Phase 49** subscription drill direction.
- **D-09 (i18n later):** **Defer** a Copy **behaviour/protocol** until a real second backend exists. When i18n lands, prefer **Gettext** (or a thin wrapper) and **keep function names** as stable call sites—swap **bodies**, not module graph, per Elixir ecosystem norms.

### 3 — ADM-05: documenting intentional token / layout exceptions (UX-04 discipline)

- **D-10 (Exception Register — SSOT):** Create and maintain **`accrue_admin/guides/theme-exceptions.md`** as the **canonical register** of intentional non-token or non-`ax-*` exceptions: table columns minimally **slug/id, location (file or route), what deviates, rationale, preferred future token (or “none yet”), status, phase/PR reference**. This coexists with **v1.6 UX-04** intent (registry pattern) while keeping exceptions **discoverable outside `.planning/`** for OSS contributors.
- **D-11 (phase close-out):** **`50-VERIFICATION.md`** (or equivalent phase notes) **links** the register and asserts **every v1.12-touched intentional exception** has a row—phase notes are the **gate**, the guide is the **catalog** (no duplicate prose).
- **D-12 (inline):** At each exception site, **one short pointer** comment to the register anchor (e.g. `Accrue: see accrue_admin/guides/theme-exceptions.md#<slug>`).
- **D-13 (PR hygiene):** Add or extend a **PR checklist** item: *If this PR introduces a non-token color/layout exception, update **`accrue_admin/guides/theme-exceptions.md`***.
- **D-14 (ADRs):** Use **ADRs only for policy changes** (e.g. chart palette rules)—**not** per-row exception narratives.

### 4 — ADM-06: operational definition of “materially touched mounted paths”

- **D-15 (milestone gate — “medium” definition):** Maintain a **short, explicit, checked-in inventory** of **mounted-admin URLs / flows** that v1.12 work **intentionally touches**—the **union** of **Phase 48**, **Phase 49**, and **Phase 50** shipped surfaces (ADM-01..03 + this phase’s copy/token sweep), **not** the entire README route matrix and **not** a raw **git-diff-only** substitute for sign-off. Git-diff or narrow checks may supplement as **PR hints** or scheduled hygiene, but **ADM-06 completeness** is judged against that **stable inventory**.
- **D-16 (library vs host):** Prove **behavior + structure** heavily in **`accrue_admin`** with **`Phoenix.LiveViewTest`** and **`Copy`** unit tests; use **`examples/accrue_host` + VERIFY-01** for **mounted** integration (**real router, session, scope, static pipeline**). Do **not** duplicate full depth twice without reason—**one canonical depth per concern** (LV for logic; Playwright for mount + axe on inventory paths).
- **D-17 (VERIFY-01 policy):** **Unchanged** merge-blocking vs advisory lane semantics—no new lanes, no policy rename in Phase 50.

### 5 — Playwright + axe strategy (VERIFY-01 extension only)

- **D-18 (file structure):** **Extend** existing **`examples/accrue_host/e2e/verify01-admin-a11y.spec.js`** (and sibling VERIFY-01 specs) first. **Split** a new spec file **only** when the primary file becomes unwieldy for review (~**400–500** lines or unmaintainable `describe` fan-out)—prefer **clear `test.describe` ownership** over many tiny files with duplicated fixtures.
- **D-19 (test shape):** **Per-flow** merge-blocking tests: **setup → navigate to inventory path → wait on accessibility tree readiness → assert critical operator affordances → run `@axe-core/playwright` once**. Avoid “visit 40 URLs in a loop” in the **blocking** job; matrix sweeps belong in **advisory** or scheduled jobs if ever needed.
- **D-20 (LiveView timing):** **Never** use **`networkidle`** as the primary LiveView readiness strategy. Prefer **locator-driven** readiness (`expect(…).toBeVisible()` on **role + accessible name**, or a documented shell landmark). Run **axe after the same readiness** as functional assertions.
- **D-21 (axe scope):** Prefer **full-page** axe while **`accrue_host`** layout stays clean; if host chrome or third-party noise grows, scope axe to a **single prefixed admin root** (see Phase **48** `data-test-id` prefix discipline) **and** document any **narrow, reviewed** `disableRules` / supplemental checks—avoid silent erosion of signal.
- **D-22 (selectors):** Default **`getByRole` / `getByLabel`** tied to **`AccrueAdmin.Copy`**-sourced strings. Use **`data-test-id`** **only** as a **scalpel** when roles/names are **ambiguous or unstable**—prefix policy per **Phase 48 D-14**; do **not** sprawl parallel selector layers.
- **D-23 (Copy ↔ Playwright contract — non-negotiable):** Implement **one** automated **anti-drift** mechanism so JS specs **do not hand-duplicate** `Copy` literals—acceptable patterns include: a **`mix`** task or **test-only** exporter that emits **JSON/TS constants** from **`AccrueAdmin.Copy`**, or an **ExUnit contract test** that fails when spec literals diverge from Copy. The planner picks the **smallest** shippable approach; doing nothing here is **out of scope** for ADM-04 + ADM-06 together.

### 6 — Cross-cutting product/engineering principles (research synthesis)

- **D-24 (Stripe / Pay / Cashier lesson):** **Honest operator language** and **single vocabulary** beat clever filters; **separate transport health from domain row state** (already echoed in Phase **48** metering KPI discipline)—keep tests and copy from collapsing those stories.
- **D-25 (footgun avoidance):** Reject **annual full-admin matrix** testing and **unbounded visual snapshot** ownership for this milestone; reject **axe merge-blocking on noise** without a documented severity/exclusion policy consistent with **v1.6 / v1.7** precedent.

### Claude's Discretion

- Exact **inventory file path** for **D-15** (README subsection vs `examples/accrue_host/docs/…` vs `scripts/ci` companion)—must be **one** discoverable location linked from **`50-VERIFICATION.md`**.
- Exact **anti-drift** implementation details for **D-23** (JSON export vs ExUnit diff)—bounded by “smallest shippable” and VERIFY-01 maintainer ergonomics.
- Minor **axe** scoping choices under **D-21** once real host layout noise is measured in implementation.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & requirements
- `.planning/REQUIREMENTS.md` — **ADM-04**, **ADM-05**, **ADM-06**
- `.planning/ROADMAP.md` — v1.12 Phase **50** row + milestone success criteria
- `.planning/PROJECT.md` — v1.12 goals; **PROC-08** / **FIN-03** non-goals; VERIFY-01 posture

### Prior phase locks (carry-forward)
- `.planning/phases/48-admin-metering-billing-signals/48-CONTEXT.md` — **`Copy`**, **`data-test-id`**, Playwright **deferral** (**D-13**), href honesty
- `.planning/phases/48-admin-metering-billing-signals/48-UI-SPEC.md` — dashboard KPI presentation contracts (if token/copy touchpoints interact)
- `.planning/phases/49-drill-flows-navigation/049-CONTEXT.md` — subscription drill scope, **nav read-only**, **ADM-06** deferral to Phase **50**

### Package & host VERIFY spine
- `accrue_admin/README.md` — admin integration + **Copy** / tier notes (if present)
- `accrue_admin/lib/accrue_admin/copy.ex` — operator string SSOT entry
- `accrue_admin/lib/accrue_admin/copy/locked.ex` — locked verbatim strings
- `examples/accrue_host/README.md` — **VERIFY-01** contract, `npm run e2e` / `e2e:a11y`
- `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` — axe entrypoint to extend
- `examples/accrue_host/package.json` — Playwright / `@axe-core/playwright` scripts

### Historical discipline (v1.6)
- `.planning/milestones/v1.6-REQUIREMENTS.md` — **UX-04** source intent (archived milestone doc)

### New in Phase 50 (implementation deliverable)
- `accrue_admin/guides/theme-exceptions.md` — **Exception Register** (**D-10**; create during Phase 50 execution)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- **`AccrueAdmin.Copy`** / **`AccrueAdmin.Copy.Locked`** — SSOT for strings; extend via **`defdelegate`** + `lib/accrue_admin/copy/*.ex` as volume grows.
- **`examples/accrue_host` VERIFY-01 suite** — extend in place before splitting files.
- **Phase 48/49 LiveViews** — primary v1.12 surfaces for inventory + tests (`DashboardLive`, `SubscriptionLive`, related indexes).

### Established patterns
- **`Phoenix.LiveViewTest`** for fast proof; **Playwright + axe** for mounted paths only on the **ADM-06 inventory**.
- **Phase 48** — KPI / href honesty + minimal Playwright exception for broken blocking specs.

### Integration points
- **Host router + session + scope** — VERIFY-01 remains the **integration spine**; library tests stay deterministic.

</code_context>

<specifics>
## Specific Ideas

- **2026-04-22:** User requested **all five** gray areas with **parallel subagent research** (Pay/Cashier/Stripe patterns, Elixir/Hex library norms, VERIFY-01 / Playwright / axe practice). This CONTEXT merges those threads into **one** coherent policy set (**D-01**–**D-25**).

</specifics>

<deferred>
## Deferred Ideas

- **Full Gettext/i18n** packaging for `accrue_admin` — defer until a milestone explicitly scopes host-facing translations; groundwork only in **D-03** / **D-09**.
- **Advisory nightly matrix** of “every README route” — optional hygiene only; not part of Phase **50** merge-blocking bar (**D-15**, **D-19**).
- **ADR per theme row** — explicitly rejected for normal exceptions (**D-14**).

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches for Phase **50**.

</deferred>

---

*Phase: 50-copy-tokens-verify-gates*  
*Context gathered: 2026-04-22*
