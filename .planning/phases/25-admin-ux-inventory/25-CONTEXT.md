# Phase 25: Admin UX inventory - Context

**Gathered:** 2026-04-20  
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 25 delivers **maintainer-facing inventory only** (INV-01..03): a **route matrix**, **component kitchen vs production coverage** notes, and a **spec alignment** artifact that maps Phase 20/21 UI contracts to the current `accrue_admin` implementation. It does **not** implement hierarchy fixes (26), copy (27), accessibility gates (28), or mobile CI expansion (29).

Success is **checked-in artifacts** under `.planning/phases/25-admin-ux-inventory/` that downstream phases can grep, link, and extend without duplicating the UI-SPEC prose.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Artifact layout (split deliverables + index)

- **Split canonical tables** into three files with stable names: `25-INV-01-route-matrix.md`, `25-INV-02-component-coverage.md`, `25-INV-03-spec-alignment.md` (prefix matches existing phase artifact conventions such as `21-UI-SPEC.md`).
- Add a **thin `README.md`** in the phase folder: read order, links to the three INV files and to `25-CONTEXT.md`, and an explicit **“do not duplicate these tables in ROADMAP”** note (ROADMAP stays summary-level; phase folder owns matrices).
- **`25-CONTEXT.md` remains the agent/human router**: a short **Source of truth** block lists exactly those three paths for INV-01/02/03.
- **Per-file snapshot discipline:** each INV file starts with `Snapshot: <ISO date> @ <git short SHA>` plus one line describing **how** the table was produced (`manual`, `mix phx.routes` export path, etc.). Refreshes happen in the **same PR** as router/spec/test changes that alter the inventory, or in a dedicated inventory refresh PR before closing the phase.
- **Optional later:** `artifacts/` for machine-readable route dumps—only introduce when a `mix` task or CI check exists; avoid empty `artifacts/` process debt for v1.6.

**Rationale:** Matches Accrue’s existing multi-artifact phases (plans, summaries, specs), minimizes merge conflicts vs one megadoc, improves grep (`25-INV-02`), and keeps **Hex-facing `guides/`** free of maintainer-only matrices (principle of least surprise for library adopters).

### D-02 — INV-01 route matrix vs baseline audit

- **Canonical source of truth for “what routes exist”** is **`accrue_admin/lib/accrue_admin/router.ex`** as expanded for a **documented reference configuration** (not a markdown table alone).
- **`.planning/ADMIN-UX-BASELINE-AUDIT.md` §1** is **prior art / narrative context** dated 2026-04-20 — it must **not** be promoted to authoritative INV-01; INV-01 may link to it as “pre-inventory baseline.”
- **INV-01 content:** matrix derived by **re-verification** from compiled routing—idiomatic Phoenix pattern is **`mix phx.routes`** (or a future thin `mix accrue_admin.routes` wrapper) run against **`examples/accrue_host`** with the **shipping-relevant** `allow_live_reload` value documented in the matrix header (today the host pins dev routes off; the matrix must **label** dev-only `/dev/*` rows as conditional on `allow_live_reload: true`).
- **Two-class routing in the table:** separate section or column for **production session routes** vs **dev-only** routes gated by `allow_live_reload` (see router macro docs in code). Include **mount prefix** semantics: library paths are relative to host mount (e.g. `/billing`); state explicitly whether rows are **admin-relative** or **host-absolute** for the reference app.
- **Drift control:** any PR touching `AccrueAdmin.Router` (or macro options affecting route set) **updates INV-01 or the checked route snapshot** in the same PR, or adds a follow-up issue referenced from INV-01—prefer **same PR** to avoid false confidence.
- **Static assets / non-LiveView `get` routes** under the admin scope: either include in INV-01 with a clear **“non-LiveView”** label or explicitly scope INV-01 to **`live_session` LiveViews** only—pick one and state it in INV-01 header so security/review readers are not misled.

**Rationale:** Ecosystem precedent (Rails `rails routes`, Laravel `route:list`) treats **CLI / compiled output** as authoritative; markdown without mechanical linkage rots. Matches “billing state, modeled clearly”: **honest contracts** over confident prose.

### D-03 — INV-02 “blocks visual regression” policy

- **Reject** the strict rule “every `AccrueAdmin.Components.*` used in production must appear in `ComponentKitchenLive`” as the default gate—it optimizes catalog completeness over **signal per maintenance hour** and encourages toy assigns that diverge from real pages.
- **Adopt scoped blocking:** a gap **blocks** closure of Phase 25 **only** when a primitive implements a **normative visual or interaction pattern** from **20/21 UI-SPEC** on **inventory-scoped surfaces**: money indexes (`customers`, `subscriptions`, `invoices`, `charges`), **webhook** list/detail/replay-adjacent UI, **step-up** / sensitive-action flows, and **dashboard** only where a spec row explicitly applies. Other surfaces (e.g. coupons, connect, events) are **non-blocking backlog** unless INV-03 marks them normative for v1.6.
- **What satisfies “covered” for a blocking primitive:** either (a) a **ComponentKitchenLive** section with **fixture assigns aligned with** production LiveView tests / seeds, or (b) **documented** Playwright or LiveView test evidence on the **real route** with frozen fixtures—**one** of these per blocking gap is enough; the inventory names which.
- **Promotion rule:** any PR in Phases 26–29 that **touches a normative surface** must either preserve existing coverage or **promote** newly touched primitives to blocking until coverage is recorded (kitchen or route-level test)—document this rule once in INV-02.

**Rationale:** Aligns with Phase 21’s “no endless pixel polish” posture while protecting **money + webhook** truth surfaces; coherent with Phase 26 owning **pattern alignment**—INV-02 lists **pattern/component evidence**, not a flat atom inventory.

### D-04 — INV-03 spec alignment table shape

- **Two-level model (hybrid):**  
  1. **Primary rows = testable obligations**—stable pointers into `20-UI-SPEC.md` / `21-UI-SPEC.md` (heading + bullet anchor, or lightweight stable IDs **if** the specs gain them; do not duplicate spec prose). Columns: **Status** (`Aligned` | `Partial` | `N/A`), **Scope tags** (e.g. `admin`, `host-mount`, `desktop`, `@mobile` when known), **Evidence** (test path, Playwright file, or `—` with explicit reason), **Owner** (maintainer role or `TBD`), and for **Partial** a mandatory **Gap + target phase** one-liner (e.g. “Phase 28: focus trap audit”).  
  2. **Secondary rollup = surfaces** (dashboard, money indexes, detail pages, webhooks, step-up)—small table (≤10–15 rows) where each cell links to the **clause rows** it aggregates and shows **worst status** only (no duplicated per-dimension columns in the rollup).
- **Governance:** matrix updated at **phase entry/exit** boundaries; **Partial** may not survive **two consecutive milestone phases** without an ADR, explicit N/A with rationale, or a tracked todo ID in `.planning/` (prevents “partial parking lot”).
- **Operator vs maintainer views:** same file; operators read **surface rollup** first; maintainers filter **clause rows** by tag and by missing evidence.

**Rationale:** WCAG-style matrices use **obligation × evidence**; Pay/Cashier rarely ship public UI matrices—Accrue’s operator-grade posture needs **traceability without** an unmaintainable wide grid. Feeds 26 (hierarchy), 27 (copy evidence), 28 (a11y rows/tags), 29 (mobile scope tags) without rewriting the UI-SPECs.

### D-05 — Cross-cutting coherence (all four areas)

- **Single refresh story:** when refreshing inventory, touch **snapshot headers** on all three INV files in one commit so dates/SHAs stay aligned.
- **README read order:** `25-CONTEXT.md` (routing + SoT) → INV-01 → INV-02 → INV-03 → link **ADMIN-UX-BASELINE-AUDIT** as historical context.
- **No duplicate sources of truth:** Router (D-02), UI-SPECs (D-04 pointers), and tests (D-03/D-04 evidence) outrank markdown tables; markdown **indexes and interprets** them.

### Claude's Discretion

- Exact optional `mix` task name for route export (`mix accrue_admin.routes` vs documented `mix phx.routes` only)—implementer chooses the smallest shippable automation.
- Whether INV-01 includes non-LiveView `get` routes or explicitly scopes them out—implementer picks one per D-02 and documents in INV-01 header.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and requirements

- `.planning/ROADMAP.md` — Phase 25 goal, success criteria, canonical ref list.
- `.planning/REQUIREMENTS.md` — INV-01..03 definitions and traceability rows.

### UI contracts (inventory targets)

- `.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md` — Organization, tax, replay, step-up, nesting rules.
- `.planning/phases/21-admin-and-host-ux-proof/21-UI-SPEC.md` — Money indexes, hybrid list/detail, VERIFY-01-adjacent operator UX.

### Prior phase context (patterns to preserve)

- `.planning/phases/21-admin-and-host-ux-proof/21-CONTEXT.md` — Playwright split, desktop-first vs mobile subset, library vs host test pyramid, no raw JSON in operator UI.

### Baseline (non-authoritative for routes)

- `.planning/ADMIN-UX-BASELINE-AUDIT.md` — Read-only baseline snapshot 2026-04-20; INV-01 supersedes §1 for ongoing truth (D-02).

### Code (route source of truth)

- `accrue_admin/lib/accrue_admin/router.ex` — `accrue_admin/2` macro, `allow_live_reload`, `live_session`, dev-only routes.

### Host reference mount

- `examples/accrue_host/lib/accrue_host_web/router.ex` (or equivalent) — verify actual `accrue_admin` mount path and options when generating INV-01.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`AccrueAdmin.Router`** — Single macro expansion defines all shipping and dev-gated admin routes; INV-01 must reflect `allow_live_reload` branching.
- **`AccrueAdmin.Live.ComponentKitchenLive`** — Dev-only showcase for a **subset** of components; INV-02 explicitly compares kitchen vs `AccrueAdmin.Components.*` in production LiveViews under `accrue_admin/lib/accrue_admin/live/`.
- **`ADMIN-UX-BASELINE-AUDIT.md`** — Starting point tables and gap narrative; inventory phase formalizes and splits them per D-01–D-04.

### Established patterns

- Phase artifacts use **`{phase}-` prefixed filenames** and live under **`.planning/phases/{phase}-{slug}/`** — Phase 25 follows the same for least surprise.
- **Hex package admin** keeps risky surfaces **compile-gated** (`Mix.env()`, explicit opts)—inventory must document that operator-facing “full route list” depends on host opts.

### Integration points

- **Phase 26** consumes INV-02/INV-03 gaps for `ax-*` / LiveView hierarchy work.
- **Phases 27–29** attach evidence columns and new clause rows without changing D-01 file layout.

</code_context>

<specifics>
## Specific Ideas

- Research synthesis (2026-04-20) compared **single megadoc vs split INV files**, **audit promotion vs router-derived INV-01**, **strict vs scoped component kitchen policy**, and **surface-first vs rule-first spec matrices**; unified outcome is **split files + router/phx.routes truth + scoped blocking + two-level spec matrix** so all four choices reinforce one another.

</specifics>

<deferred>
## Deferred Ideas

- **Optional `artifacts/*.csv`** and CI-enforced route snapshot diff (D-01/D-02)—defer until a `mix` task exists; do not add empty `artifacts/` in Phase 25.
- **Minting formal rule IDs** inside 20/21 UI-SPECs—defer unless maintainers want machine-stable IDs; until then use **heading + bullet anchors** per D-04.

</deferred>

---

*Phase: 25-admin-ux-inventory*  
*Context gathered: 2026-04-20*
