# Phase 27: Microcopy and operator strings - Context

**Gathered:** 2026-04-20  
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 27 delivers **COPY-01..COPY-03** on **INV-03 normative v1.6 surfaces** only: plain-language **empty states**, coordinated **errors / flashes / destructive confirmations**, and a **single source of truth for stability-contract strings** so `accrue_admin` ExUnit and `examples/accrue_host` Playwright do not assert divergent literals.

It does **not** broaden normative scope to coupons, Connect, events, or promotion codes without a prior **INV-03** promotion (Phase 25 D-03 policy). It does **not** own hierarchy (26), a11y program (28), or mobile matrix expansion (29).

Exit is **REQUIREMENTS.md** checkboxes for COPY-01..03 plus evidence pointers consistent with **25-INV-03** rows touched.

</domain>

<decisions>
## Implementation Decisions

### D-01 — COPY-03: Hybrid copy layer (Elixir SSOT + light enforcement)

- **Primary SSOT:** Introduce a small **`AccrueAdmin.Copy`** module (split into e.g. `Copy.Tables`, `Copy.Webhooks`, `Copy.Flash` only if file size warrants—start single-module until ~300 lines).
- **API shape:** **Named functions** returning string literals (e.g. `customers_index_empty_title/0`, `customers_index_empty_body/0`) for every string that **tests, Playwright, or Phase 20/21 UI-SPEC locks** as canonical—not only `@`-style module attributes scattered per LiveView.
- **Migration rule:** Replace inline `empty_copy=` / flash / denial literals on **in-scope routes** (D-05) with `Copy.*` calls; **`DataTable` defaults** (`empty_title`, `empty_copy`) move to `Copy` or delegate to `Copy` so defaults are not a hidden second SSOT.
- **Hybrid enforcement (optional but recommended):** Add **minimal CI** (thin script or Credo custom check) that fails on **duplicate raw literals** for the same semantic role (e.g. multiple distinct “Adjust the …” variants for the same surface class), **or** a **`mix` task that emits a doc snippet** from `Copy`—do **not** treat a hand-maintained markdown manifest as authoritative unless it is **generated** from the module.
- **Playwright policy:** Prefer **`getByRole` / existing `data-role` hooks** for structure; use **exact text** from `Copy` only where UI-SPEC or VERIFY-01 explicitly locks wording.
- **Semver / changelog:** Treat **`Copy` function names and semantics** as the stable integration surface; **English wording tweaks** are **patch** unless **meaning** changes (forbidden → unavailable, denial scope changes) → **minor** + explicit **CHANGELOG** callout under `### Host-visible copy (accrue_admin)`.

**Ecosystem rationale:** Pay/Filament-style OSS survives when operator strings are **keyed and centralized**; manifest-only SSOT drifts; gettext in a library is a host-imposition footgun for v1.6—defer.

### D-02 — COPY-01: Two-tier empty-state voice (state-first + short verification)

- **Tier A — Standard operator lists** (money indexes, webhook index, other in-scope tables): **Short title** names **billing state**, not the interface (e.g. “No invoices in this view” / “No subscriptions for this organization yet” as appropriate—not “No rows found” as the only voice). **Body:** **one sentence** explaining what would populate the list in **billing terms**, plus **one** non-alarmist verification hint (filters, date range, scope)—avoid false precision (“next billing cycle”, “next projection sync”) when timing is unknown.
- **Tier B — Org / first-run / permission blocks:** Reuse **Phase 20 locked** heading + body where applicable (`20-UI-SPEC.md` org billing empty table)—do not shorten those; they are the canonical **state block** voice.
- **Retire as default headline:** The repetitive **“Adjust the X filters or wait for Y”** chorus as the **primary** message; filters may appear as **secondary** guidance, not the main headline, to align with Phase 20 rule: *copy names billing state or action, not the interface*.
- **Jargon purge (primary chrome):** Remove **DLQ**, **projection**, **processor** (and similar implementer terms) from **empty-state titles** and first-line bodies; webhook/debug pages may use operational terms **below the fold** or in **detail** contexts where INV-03 marks them as operator-relevant.

**Ecosystem rationale:** Stripe-class billing UIs separate **zero-data** vs **zero-match** mentally even when the UI uses one component—Accrue approximates that with **title = state**, **body = cause + one verify path**.

### D-03 — COPY-02: Risk waves + per-flow coordination + copy tiers

- **Work order:** **Wave 1** — money surfaces (customers, subscriptions, invoices, charges) indexes + detail + destructive confirms tied to money. **Wave 2** — webhooks list/detail/replay-adjacent flashes and errors. **Wave 3** — step-up / sensitive-action strings + dashboard only where INV-03 maps an obligation. Within each wave, complete **one operator flow at a time** (flash + modal + inline error for the same decision tree in one PR or explicitly linked PRs)—no scattered one-line flash edits across unrelated flows.
- **Locked strings (Phase 20):** **Never paraphrase** org/tax/replay denial, ambiguous ownership, cross-org denial, or replay confirmations—import from **`AccrueAdmin.Copy`** (or a `Copy.Locked` submodule) that **mirrors the UI-SPEC table verbatim**; CI or a focused test asserts **single occurrence** of each locked literal in HEEx/LiveView (excluding quoted docs).
- **Copy tiers (document in admin guide):** **Tier A — Host contract:** production `live_session` operator strings on normative routes; semver/changelog rules apply. **Tier B — Library demo:** `ComponentKitchenLive` and fixture-heavy previews—**non-contract**; banner in contributor docs. **Tier C — Dev-only:** routes gated by `allow_live_reload` / dev flags—placeholder copy allowed; still no misleading safety text.
- **CHANGELOG:** Standing subsection **`### Host-visible copy (accrue_admin)`** for Tier A changes so hosts grepping releases catch flash assertion breaks.

**Ecosystem rationale:** Pay showed integrators treat **error text as API**; Cashier pushes copy to hosts—Accrue ships UI, so **explicit tiering + changelog** reduces surprise without a big-bang unreadable diff.

### D-04 — Scope: INV-03 normative surfaces only (closed list discipline)

- **In scope:** Surfaces present in **25-INV-03-spec-alignment.md** surface rollup and clause rows for **money indexes, detail pages, webhooks, step-up**, plus **dashboard** only where INV-03 maps a copy-related obligation—mechanically cross-checked against **`25-INV-01-route-matrix.md`** LiveView modules.
- **Explicitly out of scope for Phase 27:** **Coupons, Connect, Events, Promotion codes** LiveViews remain **INV-02 non-blocking backlog** per Phase 25 D-03 until INV-03 gains rows promoting them; document this pointer in phase README or `27` notes so omission is **intentional**, not forgotten.
- **INV-03 hygiene:** Any COPY change that resolves a Partial gap must **update the same INV-03 row’s Evidence** in the **same PR** (or a immediately following PR referenced from the row)—same accountability as Phase 26.

**Ecosystem rationale:** Wave polish in mature OSS is **journey-scoped** with one accountability artifact—INV-03 is that artifact for Accrue.

### D-05 — Cohesion across decisions (single architecture story)

- **`AccrueAdmin.Copy` is the hub:** Tier B pulls **locked** strings from the same module family; Tier A empty states use **named functions** per D-02; Tier A flashes/errors from D-03 reference **`Copy`** (or thin LiveView helpers that only delegate to `Copy`)—**no parallel string literals** for the same semantic event.
- **Tests:** `accrue_admin` ExUnit asserts **`Copy.function()`** output or rendered DOM containing it; host Playwright asserts **hooks + selective text** per D-01.
- **Sequencing with Phase 26:** Land **26** hierarchy/token alignment before bulk **27** edits to the same files to reduce merge thrash; if 27 must start early, **restrict file overlap** to `Copy` scaffolding + non-conflicting routes until 26 merges.

### Claude's Discretion

- Exact module split (`Copy` vs `Copy.Locked` vs `Copy.Tables`) once line count is known.
- Whether the optional duplicate-literal CI is **script** or **Credo**—smallest shippable automation wins.
- Precise Tier A title strings per route—planner refines using D-02 templates and Phase 20 locks.

### Folded Todos

_None — `todo.match-phase` returned no matches._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and requirements

- `.planning/ROADMAP.md` — Phase 27 goal, success criteria, dependencies (26 before implementation churn).
- `.planning/REQUIREMENTS.md` — COPY-01..COPY-03 definitions.

### Phase 25 inventory (scope authority)

- `.planning/phases/25-admin-ux-inventory/25-INV-01-route-matrix.md` — route ↔ module truth for closed in-scope list.
- `.planning/phases/25-admin-ux-inventory/25-INV-02-component-coverage.md` — normative vs non-blocking surfaces.
- `.planning/phases/25-admin-ux-inventory/25-INV-03-spec-alignment.md` — obligation × evidence; Partial rows drive PR accountability.

### Phase 26 handoff

- `.planning/phases/26-hierarchy-and-pattern-alignment/26-CONTEXT.md` — what 26 owns vs 27; merge sequencing.

### UI contracts (tone + locked literals)

- `.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md` — locked copy tables, copy rules (name billing state, no raw auth jargon).
- `.planning/phases/21-admin-and-host-ux-proof/21-UI-SPEC.md` — money index / list-detail operator patterns.

### Code integration points

- `accrue_admin/lib/accrue_admin/components/data_table.ex` — default empty title/body must align with `AccrueAdmin.Copy` once introduced.
- `accrue_admin/lib/accrue_admin/live/*_live.ex` — index/detail entry points for in-scope routes.
- `examples/accrue_host/e2e/` — Playwright contracts per D-01.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`AccrueAdmin.Components.DataTable`** — central defaults for `empty_title` / `empty_copy`; natural home to call into `Copy` for defaults.
- **Module-attribute patterns** — e.g. webhook replay denial strings in `webhook_live.ex`; migrate into `Copy` for discoverability.

### Established patterns

- **Per-index `empty_copy=` assigns** — consistent rhythm today but duplicated; D-02 + D-01 replace with `Copy` + differentiated bodies.
- **Phase 20 locked tables** — authoritative for Tier B and replay/denial Tier A strings.

### Integration points

- **Host Playwright** — asserts on mounted admin; must follow D-01 hook-first policy when tightening strings.

</code_context>

<specifics>
## Specific Ideas

User requested **all four discuss areas** with **parallel subagent research** (2026-04-20); decisions above synthesize Pay/Cashier/Filament/ActiveAdmin lessons, Phoenix LiveView idioms, and Accrue phase 25/26 policy into one coherent architecture.

</specifics>

<deferred>
## Deferred Ideas

- **Promote secondary admin (coupons, connect, events, promotion codes) to COPY scope** — requires new **INV-03** clause or rollup rows + explicit milestone decision; until then backlog only per Phase 25 D-03.
- **Gettext-backed i18n for `accrue_admin`** — valid future phase; out of scope for v1.6 COPY deliverable.

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 27-microcopy-and-operator-strings*  
*Context gathered: 2026-04-20*
