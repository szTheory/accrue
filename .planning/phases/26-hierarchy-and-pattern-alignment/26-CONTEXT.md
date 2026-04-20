# Phase 26: Hierarchy and pattern alignment - Context

**Gathered:** 2026-04-20  
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 26 delivers **UX-01..UX-04** on **normative operator surfaces** (money indexes, money detail pages, webhook list/detail, token discipline): consistent list shells and signals, `ax-page` / `ax-card` / KPI patterns aligned with Phase **20/21 UI-SPEC**, webhook typographic rhythm matching other admin lists, and **semantic theme tokens** as the default with **auditable exceptions**. It does **not** own microcopy polish (27), a11y program (28), or mobile CI expansion (29).

Exit is **REQUIREMENTS checkboxes** for UX-01..04 plus **ROADMAP** structure-level tests—not open-ended visual redesign.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Scope and sequencing (inventory + requirements hybrid)

- **Completion bar:** Treat **`REQUIREMENTS.md` UX-01..UX-04** as the normative definition of “done” for Phase 26 on surfaces already scoped as **normative** in Phase 25 **INV-02 D-03** and **INV-03** (money indexes, detail pages, webhooks, step-up only where a UX row applies)—not coupons/connect/events unless INV-03 explicitly marks them in scope for this milestone.
- **Accountability mechanism (hybrid):** Each PR or plan slice **starts from the INV-03 clause row(s)** it touches (Partial → Aligned, or explicit deferral with target phase), and lists **evidence paths** already called for in INV-03. **INV-01** is used only to confirm **route ↔ LiveView module** ownership and avoid orphan paths—not as the primary sort order for work.
- **Work order (operator-coherent waves):** **UX-01** money indexes first (shared list-row mental model), then **UX-02** detail pages (KPI/grid/card nesting), then **UX-03** webhooks (density rhythm), then **UX-04** token sweep + exception registry. This order optimizes **operator consistency** and reuse of patterns learned in the first wave; it deliberately does **not** follow INV-01 table top-to-bottom (which optimizes coverage theatre over UX coherence).
- **Anti-patterns rejected:** INV-row-only scope if it would leave UX-01..04 partially satisfied; requirement-only work without INV-03 traceability (loses audit story); screenshot/pixel-diff as primary gate; silent omission of INV-03 updates after fixes.

**Ecosystem rationale:** Rails engines and Laravel admin packages that survive long-term pair **operator-visible consistency** with **traceable obligations** (what row in what artifact). Stripe Dashboard–level polish in OSS without tokens + structure tests becomes **untestable UI churn**—Accrue explicitly avoids that.

### D-02 — Refactor depth: bounded wave + surgical discipline

- **Primary approach:** **Wave B (money + webhooks)**—normalize hierarchy on the high-trust billing surfaces in one milestone so operators see one pattern per domain—while applying **Approach A discipline inside the wave:** change markup only where it **violates** documented nesting (e.g. inner `ax-page` acting as card chrome, KPI regions not using shared grid/card primitives).
- **Explicit non-goal for Phase 26:** **Library-wide “big bang”** rewrites (every LiveView + dev tools + new `<.ax_*>` API everywhere in one release). That maximizes merge pain for path-dep hosts, review fatigue, and semver ambiguity—Filament/Nova-style “publish and diff forever” is the footgun to avoid.
- **Stability contract:** Treat **`ax-*` class strings**, **`data-role` hooks**, and **documented assigns** as the **semver-relevant surface** for v1.x; internal DOM depth may move **behind small function components** only where duplication or violations cluster, **without** renaming public class contracts in a minor release.
- **Extension story (DX):** Prefer **documented extension seams** (slots, assigns, optional columns) over hosts copy-pasting full template trees—reduces upgrade churn when Accrue ships the next wave.

**Ecosystem rationale:** Pay/Cashier keep maintainer burden bounded by **scope** and delegation to Stripe where appropriate; Nova’s **vendor publish** model is a warning: raw-template-everywhere upgrades hurt. Accrue’s **library-first** posture favors **bounded waves + stable hooks**.

### D-03 — Verification: Elixir-first structure, host browser where realism demands

- **Primary gate (Phase 26):** **`Phoenix.LiveViewTest`** as the default spine for LiveViews and function components that ship in `accrue_admin`.
- **Hierarchy-heavy assertions:** Add **`Floki`** selectively to prove **wrapper depth**, **single main landmark**, **row counts under fixture assigns**, and **nav structure**—better signal than raw `html =~` alone, which only proves substring presence.
- **Cheap invariants:** Keep **`assert html =~`** for stable needles (`data-role`, unique structural markers, stable `href` shapes) where tree shape is not the risk.
- **Playwright / VERIFY-01:** **Do not** introduce a second browser matrix inside `accrue_admin` CI for every `ax-*` tweak. **Extend existing `examples/accrue_host` Playwright** only when the risk is **not expressible** in LiveViewTest: mounted assets, viewport overflow, org-switcher + real routes, timing with real LV JS. **Phase 29** owns expanded **@mobile** coverage per roadmap; **Phase 28** owns axe-style gates where REQUIREMENTS point at mounted admin.
- **Duplication guardrail:** Markup **contracts** live in **`accrue_admin` ExUnit**; **mounted realism** stays in the **host**—consistent with Phase **21-CONTEXT** library-vs-host test pyramid.

**Ecosystem rationale:** Mature Phoenix and gem ecosystems keep **libraries fast (ExUnit)** and put **Capybara/Playwright** on the **application**—double-testing the same DOM in both layers is pure contributor friction.

### D-04 — UX-04 theme tokens and exceptions (two-layer contract)

- **Contract layer:** **`theme.css` (or equivalent) remains the only place** “brand math” compiles to concrete color spaces; semantic variables are the **default** consumption path from HEEx (`var(--…)` / semantic utility classes aligned with existing admin CSS).
- **Exception layer:** Maintain a **single tracked registry** in-repo: **`.planning/phases/26-hierarchy-and-pattern-alignment/26-theme-exceptions.md`** listing each exception (**file**, **selector or region**, **one-line rationale**, optional **ADR/issue link**). Optional follow-up: a **tiny CI script** that greps for hex in `accrue_admin` templates against that registry (with allowlist for false positives like data URLs).
- **Call-site style:** Prefer **named CSS variables** defined in `theme.css` over naked `#RRGGBB` in HEEx—even when the value is “exceptional,” the **call site stays semantic** and grep stays meaningful.
- **Doc pairing:** Short pointer from **`accrue` / admin install or theming guide** (“exceptions live in phase registry + theme.css”) so adopters are not surprised; avoid **CHANGELOG-per-hex** noise.
- **Footguns rejected:** narrative-only phase notes as the sole registry; inline `<!-- temporary -->` for years; naive `#` bans that break SVG/data URLs without structure.

**Ecosystem rationale:** Tailwind/shadcn document **escape hatches** explicitly; Stripe Elements constrain customization to **declared appearance keys**; USWDS-style systems centralize tokens—Accrue aligns with **central contract + enumerated exceptions**.

### Claude's Discretion

- Exact **`mix`** task or script for optional hex CI gate (smallest shippable automation).
- Whether **`Floki`** is added as a **direct** `accrue_admin` test dependency vs test-only in host—prefer **direct** if hierarchy tests live in package tests.

### Folded Todos

_None — `todo.match-phase` returned no matches._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and requirements

- `.planning/ROADMAP.md` — Phase 26 goal, success criteria, dependencies.
- `.planning/REQUIREMENTS.md` — UX-01..UX-04 definitions and traceability table.

### Phase 25 inventory (execution queue + evidence discipline)

- `.planning/phases/25-admin-ux-inventory/25-CONTEXT.md` — routing + artifact SoT.
- `.planning/phases/25-admin-ux-inventory/25-INV-01-route-matrix.md` — route ↔ module truth (reference configuration).
- `.planning/phases/25-admin-ux-inventory/25-INV-02-component-coverage.md` — normative surfaces + blocking gap policy.
- `.planning/phases/25-admin-ux-inventory/25-INV-03-spec-alignment.md` — obligation × status × evidence; Partial rows drive PR accountability.

### UI contracts

- `.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md` — nesting, cards, step-up, org/tax/replay.
- `.planning/phases/21-admin-and-host-ux-proof/21-UI-SPEC.md` — money indexes, list/detail hybrid, operator density.
- `.planning/phases/21-admin-and-host-ux-proof/21-CONTEXT.md` — VERIFY-01 split, library vs host test pyramid, Playwright ownership.

### Phase 26 artifacts (this phase)

- `.planning/phases/26-hierarchy-and-pattern-alignment/26-theme-exceptions.md` — **create on first exception**; single registry for UX-04 (referenced from D-04).

### Code (integration points)

- `accrue_admin/lib/accrue_admin/router.ex` — route set / dev gating.
- `accrue_admin/assets/css/theme.css` (or path as in repo) — semantic token source.
- `examples/accrue_host/` — VERIFY-01 Playwright specs and mounted admin proofs.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **Established `ax-page` / `ax-page-header` / `ax-card` / `ax-kpi-grid` / `KpiCard`** patterns across `PageLive`, money LiveViews, and webhooks—Phase 26 is **normalization and spec alignment**, not inventing a new shell.
- **`Phoenix.LiveViewTest` + substring asserts** (e.g. shell tests)—extend with **Floki** for nesting where violations occurred historically (nested `ax-page` inside cards).

### Established patterns

- **Function components** (`KpiCard`, etc.) match LiveView 1.x idioms; grow components **only** where duplication or spec violations cluster (subagent consensus).
- **Phase 25** already locked **INV-03 two-level model**—Phase 26 execution should **close or re-tag** rows it touches to stay traceable.

### Integration points

- **Host Playwright** remains the place for **mounted** proofs; **`accrue_admin` ExUnit** owns **HTML structure contracts** for this phase.

</code_context>

<specifics>
## Specific Ideas

- User requested **subagent research** across all four gray areas and a **single coherent recommendation set**—synthesized into D-01..D-04. No external product screenshots; patterns cited by ecosystem name (Pay, Cashier, Nova/Filament posture, Stripe Dashboard operator density, Tailwind/shadcn token discipline).

</specifics>

<deferred>
## Deferred Ideas

- **Full design-system rewrite** with new public `<.ax_page>` API everywhere — explicitly deferred (D-02); revisit only with a semver-major story and extension-point docs.
- **Percy/visual baseline grid inside `accrue_admin` CI** — not Phase 26 primary gate; trust/demos may use host Playwright visuals per existing milestone patterns.

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 26-hierarchy-and-pattern-alignment*  
*Context gathered: 2026-04-20*
