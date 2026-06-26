# Phase 195: Exemplar B — Subscription detail - Context

**Gathered:** 2026-06-25
**Status:** Ready for planning

<domain>
## Phase Boundary

The second **exemplar** phase of v1.54. It converts the worst info-dump page in `accrue_admin` — `subscription_live.ex` (1,234 lines, ~25 always-visible flat zones, ~13 always-expanded inline action forms) — into the **gold-standard for the object-detail archetype**, conforming to the SPEC-DETAIL contract locked in Phase 193. It also builds the **reusable action-menu + side-drawer action-hosting primitives** that detail-page propagation (Phase 198) and the cross-cutting overlay sweep (Phase 199) consume.

One surface, two deliverables:
1. **Subscription detail page** (`subscription_live.ex`) — restructured to summary-then-drill (~6 bands), ≤2 primary actions + one overflow menu, action forms hosted in a side-drawer (destructive → step-up modal), duplicate related card deleted, card-in-card nesting flattened.
2. **Canonical overlay primitive + action-menu** — the body-level-portal overlay (`<.overlay>`: modal/drawer/popover) instantiated here for the detail exemplar (the IXN-01 contract proven on this drawer), plus the `<details>`-based action-menu component. Both land in Storybook.

**Requirements:** EXE-02 (the page conversion), IXN-01 (instantiated here for the side-drawer; **owned/swept across all pages in Phase 199** — single-phase-assigned to 199 to avoid a duplicate REQ).

**Fixed guardrails (carried from 193/194, not re-litigated):** scope is `accrue_admin` operator UI only; no new billing primitives/domain features/breaking routes (component public APIs stay backward-compatible; internal moves ship with redirects); no Tailwind (custom `ax-*` CSS + tokens stay SSOT — editing source CSS ships nothing until `mix accrue_admin.assets.build` + commit); no new motion tokens (the ≤240ms band + existing `--ax-dur-*`/`--ax-ease-*` hold); core `accrue` stays LiveView-runtime-free (Storybook is `accrue_admin` dev/test-only); the forward-only scored-cell `page-flow` gate is the regression mechanism (no pixel-diff); the `/dev/components` kitchen + drift locators stay untouched.

</domain>

<decisions>
## Implementation Decisions

All four gray areas were researched in parallel (advisor subagents, multi-lens: Elixir/LiveView idiom, named-competitor lessons, JTBD/persona, a11y, brand voice, software architecture) and resolved into **one cohesive package**. Each decision composes with the others: the **overflow menu** (D-04) triggers the **side-drawer** (hosts action forms — D-01) routed through the **canonical overlay primitive** (D-03); the **band structure** (D-02) leaves the action band between the summary-list header and the drill sections.

### Action prioritization — ≤2 primary + one overflow menu (EXE-02)
- **D-01 — Primary buttons = `[Change plan]` + `[Cancel renewal]`; everything else in one overflow menu.** Grounded in operator JTBD + Stripe Dashboard precedent ("Update subscription" is the dominant action; cancel lives one rung down, never a bare top-level button).
  - **`[Change plan]`** (`swap_plan`) — filled primary (`ax-button-primary`), `data-ax-primary-action`. The single most-frequent **non-destructive** job. Available on Stripe always; on Braintree only when `@swap_plan_available` (PlanResolver configured) — gate the button.
  - **`[Cancel renewal]`** (`cancel_at_period_end`) — secondary/outline (`ax-button-secondary`), `data-ax-primary-action`, **Stripe/Fake only** (`!braintree_processor?`). This is the **reversible** cancel (status stays `active`, access preserved to period end; not in `@destructive_actions`). On Braintree this button is absent → only one primary remains (still spec-valid, ≤2).
  - The destructive, immediate `cancel_now` stays **menu-only**, danger-styled, behind step-up. This resolves the "cancel is frequent *and* destructive" tension: the frequent/safe cancel is visible; the dangerous/immediate one is buried + re-auth-gated.
- **D-01a — Single overflow `[⋯ More actions]` (`data-ax-action-overflow-menu`), grouped with dividers, frequency-then-danger:**
  - **Edit billing:** `update_quantity` (single-item only), `add_item`, `update_item_quantity`, `remove_item` (all `!braintree`, existing predicates).
  - **Collection:** `pause` ("Pause collection"), `resume` ("Resume") (`!braintree`).
  - **Danger zone** (divider + `ax-dropdown-item-danger`, placed last, never adjacent to routine items): `cancel_now` ("Cancel immediately"), `comp_subscription` ("Comp this subscription"). Both already route through `StepUp.require_fresh/4` → step-up modal; that path is untouched.
- **D-01b — Microcopy relabels (brand voice: precise, calm, literal):** `swap_plan`→**"Change plan"**; `cancel_at_period_end`→**"Cancel renewal"**; `cancel_now`→**"Cancel immediately"**; `comp_subscription`→**"Comp this subscription"**. Keep the rest. Each item carries a visually-hidden context string (`aria-label="Change plan for subscription {id}"`). The `pause_behavior` select (void/uncollectible/draft) stays **inside** the drawer form, not as separate actions. **All copy goes through `AccrueAdmin.Copy` + the `copy_strings.json` regen step** (admin copy changes silently stale the committed Playwright fixture — regen + commit in the same change).
- **D-01c — Provider gating reuses existing predicates** (`@swap_plan_available`, `!braintree_processor?/1`, `quantity_change_available?/1`, `quantity_item_changes_available?/1`) on the **menu items** — an unavailable action is *absent* from the menu, never disabled-looks-enabled (Pitfall-6). Keep the existing Braintree guidance lines **inside** the drawer/menu empty-region (provider-honesty), not as floating page text. **Reject:** Candidate D (Cancel+Pause as primary — wrong JTBD weight, two Stripe-only primaries, surfaces two dangerous-adjacent actions). The band-research strawman "Retry payment" primary is **not in scope** (no such subscription action; that's invoice-level).

### Band structure + summary-list + default-open (EXE-02)
- **D-02 — Six bands per SPEC-DETAIL:** (1) GOV.UK summary-list header → (2) action band → (3) collapsible drill sections (one open) → (4) exactly one related-resources strip → (5) lazy activity timeline → (6) lazy raw JSON. Net: ~25 flat zones → 6 bands.
- **D-02a — New `Detail.summary_list/1` component** (GOV.UK key/value rows + per-row "Change" with visually-hidden context). `summary_card/1` (header banner: eyebrow + H1 + status pill) stays as the **outer wrapper**; `summary_list` renders inside it. Do **not** retrofit Change-columns onto `detail_field_list/1` (leave it for borderless read-only field groups in drills). Header rows (above-the-fold @1280×800): **Status** (read-only, badge + lifecycle qualifier) · **Customer** (link, no Change) · **Plan / price** [Change → swap-plan drawer] · **Current period** (read-only) · **Renews / ends** [Change → cancel/resume] · **Amount (MRR)** (derived). Conditional rows: **Seats / quantity** [Change → update-quantity] when single-item; **Dunning** [View → recovery drill] when a campaign has ever run. `processor_id` is the H1, **not** a row; no internal IDs in rows (hide-the-backend).
- **D-02b — Default-open drill = "Billing & items", EXCEPT open "Dunning & recovery" when `Subscription.dunning_campaign_active?/1`.** Exactly one section open at a time (native `<details open={...}>`, server-rendered, AT-navigable, survives re-render). Drill sections: Billing & items / Dunning & recovery / Tax & compliance.
- **D-02c — Fate of existing zones:** KPI grid → **delete** the "Status" KPI (redundant with header) and the **"Canonical predicates" KPI outright** (library-author documentation in the UI — a hide-the-backend violation; predicate logic still drives the status string internally); fold current price into the Plan/price row, drop the raw timeline-row count. Dunning card → **delete the standalone card**; at-a-glance state folds into the header Dunning row, detail moves into the Dunning & recovery drill. Duplicate related card (`data-role=subscription-related-billing`) → **delete**; migrate its two unique links (charges-for-customer, events-index) into `related_items/3` so the canonical `RelatedResources` strip is the only one (`data-ax-related-resources` count === 1). Card-in-card → **flattened**: the outer actions `ax-card` is removed (forms move to the drawer); tax-risk content → Tax & compliance drill (spacing + heading, no inner border); confirm/preview panel → drawer content.
- **D-02d — Lazy activity + JSON:** keep Timeline + JsonViewer in collapsed `<details>`; gate the expensive work behind first-expand (move the eager `timeline_events` load out of `mount`).

### Overlay primitive build scope — 195 vs 199 seam (IXN-01)
- **D-03 — Option A: build the full canonical `<.overlay>` primitive in 195, freeze its public API; 199 sweeps.** SPEC-DETAIL invariant 4 (`assertTopPointerTarget` on the panel primary action + body-scroll-unchanged, desktop+mobile) makes the hard mechanism — portal + `inert` + scroll-lock — a **non-deferrable ship requirement for this drawer**. Given that, the only real choice is whether 199 *extracts* a primitive (rework + forces 195's in-scope action-menu popover into a forbidden parallel path) or merely *sweeps* an already-canonical one. Sweeping is strictly less rework and the only reading coherent with 193 D-01 + with Phase 198 needing a frozen API *before* 199. Mature systems (Radix, Headless UI, shadcn, Vaul) all build portal+dismissal+focus+scroll-lock as **one shared substrate first**, then layer thin presentations — none extract it after shipping a drawer-only version.
  - **`<.overlay>` component**, one shared portal/scrim/scroll-lock/dismissal spine, three presentations via `presentation` attr: `:modal` (centered), `:drawer` (edge-dock translateX desktop / bottom-sheet translateY mobile — fixes the R-3 wrong-axis bug), `:popover` (origin-aware). `role`=`dialog` for modal/drawer, `menu` for popover; `aria-modal` for modal/drawer only.
  - **`#ax-overlay-root`** body-level portal target mounted in the **root layout** (`root/1`, rendered once, survives live-nav/`phx-update`; guaranteed-untransformed body child — escapes the transformed-ancestor re-root that causes modal-behind-scrim).
  - **`scroll_lock.js`** — standalone, **ref-counted** (module-level counter so modal-over-drawer doesn't unlock on inner close), iOS-safe (`html{position:fixed;top:-savedY}` + `scrollTo` restore), gutter-compensated (`--ax-scrollbar-comp`, no jump). Inner scroll via `overscroll-behavior:contain`.
  - **`inert`** toggled on `#accrue-admin-shell` while any overlay is open (removes background from tab order + click + hover in one attribute; honor the D-17 `inert`-floor spike outcome). Reuse the shipped **`FocusTrap`** hook for containment/Escape/restore; keep the server-driven `:if={@open}` + `phx-mounted`/`phx-remove` model (D-03 LiveView-fit rationale — do NOT move to an imperative `open` attribute).
  - **Portal mechanism:** prefer LiveView's native `phx-portal` **if confirmed available in our `phoenix_live_view ~> 1.1` line** (it is morphdom-safe and keeps the D-04 `<dialog>` swap-seam clean); otherwise a hand-rolled portal hook. **Research/planner must confirm `phx-portal` availability in the pinned LV version before relying on it.**
  - **Re-point `detail_drawer.ex` onto `<.overlay presentation={:drawer}>`** (thin wrapper preserving its call sites/slots). It hosts the action forms (form appears only on menu invocation → invariant "action forms not pre-expanded" holds).
- **D-03a — 195↔199 boundary (explicit):** **195 ships** the `<.overlay>` component + frozen public API, `#ax-overlay-root`, `scroll_lock.js` + `inert` toggle, drawer geometry/origin-aware popover for the surfaces it uses, the action-menu popover + side-drawer action-hosting for the exemplar, destructive→`:modal` step-up handoff, Storybook stories for the primitives, and **passing SPEC-DETAIL invariant 4** on the subscription drawer. **199 owns** the mechanical sweep of the remaining ~19 overlay sites, the transformed-ancestor audit, and the D-02/D-04 native-`<dialog>` per-surface fallback (flip only audited-unfixable surfaces, behind the unchanged component boundary).
- **D-03b — Budget-relief fallback (executor discretion):** if the exemplar's plan budget can't also absorb migrating `step_up_auth_modal.ex` onto the `:modal` presentation, **leave step-up on its current shell and let 199 migrate it** (Option C). The `:modal` presentation still exists for the new step-up handoff; same seam quality, briefly two overlay code paths. **Reject:** Option B (drawer-only-then-extract) — the in-scope action-menu popover makes a drawer-only scope incoherent and forces a forbidden parallel overlay path.

### Action-menu mechanism (IXN-01 coherence)
- **D-04 — Option A (refined): a dedicated `<details>`-based `action_menu/1` component; only the drawer/modal it opens routes through the overlay primitive.** Distinct from the link-shaped `dropdown_menu/1` — actions are `<button role="menuitem" phx-click>` (push LiveView events), not `<a href>`. `summary` carries `aria-haspopup="menu"`; panel is `role="menu"`. Reuse the shipped `dropdown.js` dismissal grammar (Escape + outside-click → idempotent close + focus-restore to trigger). Add `transform-origin: top right` (origin-aware, R-4) — no new tokens.
- **D-04a — The reconciling principle (crisp):** *193 D-01's "no parallel overlay path" governs the **scrim-overlay surface** (the drawer/modal the menu opens), not every popped-up box. A trigger menu and a modal context are different ARIA roles with different contracts.* The menu **shares** the dismissal + origin-awareness grammar; it correctly does **not** share scrim / scroll-lock / `inert` / focus-trap (applying `inert` behind a *menu* would be a semantic error — a menu is not a modal context). This matches Radix (DropdownMenu is separate from Dialog: portals + dismissal but no scroll-lock, not modal).
- **D-04b — Danger handling:** destructive items last, after a divider, `ax-dropdown-item-danger`; they do **not** act from the menu — they open the step-up modal. Item API: `%{label, event, target, value, danger?, description?, confirm?}`.
- **D-04c — Clipping mitigation:** keep the menu's `position:absolute` panel; **enroll the detail action-band's ancestor in Phase 199's transformed-ancestor audit.** Portal-the-menu is a late, evidence-driven exception only if the audit finds an unremovable re-rooting/clipping ancestor (mirrors the D-02 `<dialog>` fallback posture) — never the 195 default. **Reject:** Option B (route the menu itself through the overlay primitive — over-engineers a lightweight menu, couples 195 to in-flight machinery, risks the menu-vs-dialog semantic mixup).

### Claude's Discretion (planner/executor decide)
- Exact `summary_list` markup/CSS, the precise `data-ax-*` hook placement, and which drill-section copy strings are new vs reused — bounded by D-02 + the no-Tailwind/committed-bundle-rebuild + copy-regen constraints.
- The `<.overlay>` slot/attr signature details (`:actions`/`:footer` slots, `anchor_id` for popover) and whether `scroll_lock.js` carries the `inert` toggle inline vs a thin companion hook — bounded by D-03.
- Whether D-03b (defer step-up-modal migration to 199) is taken — based on the realized plan budget for the exemplar.
- Whether arrow-key roving is added to `action_menu/1` beyond Tab-through (APG-acceptable for a disclosure) — only if UAT asks; do not front-load the roving-tabindex bug surface.
- Where the two new `surface_type:"page-flow"` cells for the subscription detail page live relative to the additive `baseline.page-flow.cells.json`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked design contract (read first)
- `accrue_admin/guides/spec-detail.md` — **the SPEC-DETAIL contract this phase IS the gold-standard for.** Machine-checkable invariants (≤2 `[data-ax-primary-action]` + ≥1 `[data-ax-action-overflow-menu]`; zero visible action-band `<form>` on load; exactly one `[data-ax-related-resources]`; overlay hit-testable above scrim + body-scroll-locked via `assertTopPointerTarget`) + judge-graded criteria (summary-list answers "what state/what's wrong"; no card-in-card double border; tabs only for peer record-sets). Footer names Phases 195/198/199 as consumers.
- `.planning/phases/193-research-re-baseline-pattern-lock/193-CONTEXT.md` — the overlay-direction lock (D-01 one-primitive/three-presentations/no-parallel-path; D-02/D-04 `<dialog>` swap-seam & fallback posture; D-03 LiveView-fit rationale; D-05 the four spike proofs; D-17 `inert`-vs-`aria-hidden` floor + Storybook `data-theme` shim).
- `.planning/phases/194-exemplar-a-dashboard/194-CONTEXT.md` — the sibling exemplar's decisions + the `data-ax-*` additive-marker convention + the committed-bundle-rebuild / copy-regen footguns.

### Design source / rationale
- `.planning/research/SUMMARY.md` — v1.54 synthesis: defects are STRUCTURAL (invisible to source-lint); the two-part backbone (canonical overlay primitive + rendered state-matrix gate).
- `.planning/research/ARCHITECTURE.md` — overlay structural fixes R-1..R-6 (R-1 iOS scroll-lock, R-2 single dismissal contract, R-3 drawer wrong-axis bug, R-4 origin-aware popover), the 12 IXN acceptance criteria, motion K1–K15, the `--ax-z-*` scale (dropdown 200 < popover 300 < drawer 400 < modal 500).
- `.planning/research/PITFALLS.md` — Pitfall-1 (modal-behind-scrim / transformed-ancestor re-root), Pitfall-2 (scroll-lock/gutter-jump), Pitfall-3 (overflow/transform clipping floating panels), Pitfall-6 (disabled-looks-enabled).
- `.planning/research/FEATURES.md` + `.planning/research/JTBD-FRONTIER.md` — detail-archetype direction (layer by frequency-of-need per persona; destructive → step-up), operator JTBD.
- `prompts/accrue-brand-book.md` (gitignored — may be absent; `accrue_admin/guides/admin_ui.md` carries the same voice) — "well-made dev tooling, quiet polish," not fintech; verb-first plain microcopy, state/lifecycle imagery.
- `lattice_stripe/prompts/payments_domain_field_guide.md` + `.../stripe-explanation-domain-language-deep-research.md` — subscription domain nouns/lifecycle so summary-list rows use correct language (`cancel_at_period_end` is reversible; status is derived; Stripe owns retry cadence).

### Forward-only gate machinery (reuse, do not rebuild)
- `.planning/milestones/v1.53-phases/187-audit-baseline/187-RUBRIC.md` — the 12-dimension rubric the new `page-flow` cells + judge-graded criteria score against.
- `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.cells.json` + the additive `baseline.page-flow.cells.json` sibling (193 D-16) — the zero-regression baseline; two new subscription-detail `page-flow` cells fold in under the unchanged `regressions.ndjson` gate.
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js` + `accrue_admin/e2e/phase191-page-flow-helpers.js` — the page-flow Playwright driver; exposes `assertTopPointerTarget` / `assertScrollReachable` / `assertNoHorizontalClip` / `assertFocusWithin` (invariant 4 uses `assertTopPointerTarget` + a body-scroll assertion).
- `.planning/research/v1.54-storybook-and-forward-only-qa.md` — the rendered state-matrix gate + Storybook story expectations (the action-menu + drawer primitives land in Storybook).

### Surfaces this phase edits / reuses
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — the conversion target (the action set, provider gating, `prepare_action`/`confirm_action`/`cancel_pending_action` handler triplet to reuse verbatim, `@destructive_actions`, the dunning card, KPI grid, duplicate related card, Timeline, JsonViewer).
- `accrue_admin/lib/accrue_admin/components/detail.ex` — existing `summary_card`/`detail_section`/`detail_field_list`; **add `summary_list/1`** (new GOV.UK row-level-Change component).
- `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` + `step_up_auth_modal.ex` — the existing shells to re-point onto `<.overlay>` (drawer/modal). Note: neither currently portals or scroll-locks; drawer enter is the R-3 wrong-axis bug.
- `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` — the existing `<details>` link-menu; **add a distinct `action_menu/1`** (button/menuitem items, not links).
- `accrue_admin/lib/accrue_admin/components/related_resources.ex` — the canonical strip (add `data-ax-related-resources` if absent); `kpi_card.ex`, `dunning_banner.ex`, `json_viewer.ex`, `timeline.ex`.
- `accrue_admin/assets/js/hooks/{focus_trap.js,dropdown.js}` — reuse; **add `scroll_lock.js`**; register hooks in `accrue_admin/assets/js/app.js`.
- `accrue_admin/lib/accrue_admin/layouts.ex` (`root/1`) — mount `#ax-overlay-root`; `accrue_admin/lib/accrue_admin/components/app_shell.ex` (`#accrue-admin-shell`) — `inert` target.
- `accrue_admin/assets/css/theme.css` (`--ax-z-*`) + `app.css` (`isolation:isolate`, `.ax-dropdown-panel`, scroll-lock CSS) — **must rebuild the committed bundle** (`mix accrue_admin.assets.build`) + commit or nothing ships.

### Source-guard + copy coupling (if touched)
- `scripts/ci/verify_package_docs.sh` ↔ `PackageDocsVerifierTest seed_tmp_dir!` — any new doc-needle must be mirrored or all 6 negative tests fail (193 D-08 coupling invariant).
- `accrue_admin` copy modules + committed `e2e/generated/copy_strings.json` — admin copy changes must be regenerated (host-integration) **and committed** or playwright-e2e shards read stale copy (CI green-up lesson).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`prepare_action`/`confirm_action`/`cancel_pending_action` handler triplet + `maybe_attach_preview/2`** (`subscription_live.ex:70-105`): reusable verbatim — only the *trigger surface* changes (inline submit → menu-item → drawer form). `confirm_action` already branches `type in @destructive_actions` → `StepUp.require_fresh/4`; untouched.
- **`FocusTrap` hook + `dropdown.js`**: shipped + solid — the overlay primitive reuses FocusTrap for containment/Escape/restore; `action_menu` reuses dropdown.js's dismissal grammar.
- **`detail_drawer.ex` / `step_up_auth_modal.ex`**: already follow the server-driven `:if={@open}` + `phx-mounted`/`phx-remove` shape the body-level-portal primitive extends — become thin `<.overlay>` wrappers.
- **`RelatedResources.related_resources` / `KpiCard` / `Timeline` / `JsonViewer` / `StatusBadge`**: existing components; the work is structural (delete the duplicate related card, fold/delete KPIs, lazy-gate timeline+JSON), not new rendering.
- **Existing provider predicates** (`@swap_plan_available`, `!braintree_processor?/1`, `quantity_change_available?/1`, `quantity_item_changes_available?/1`): drive menu-item `:if` visibility — no new gating logic.
- **Page-flow Playwright driver (Phase 191)**: reuse for the two new `surface_type:"page-flow"` cells + invariant 4.

### Established Patterns
- **One overlay substrate, thin presentations** (Radix/Headless/shadcn/Vaul precedent): portal + dismissal + focus + scroll-lock built once, modal/drawer/popover layer on top — never extracted after a drawer-only build.
- **Source-lint where mechanical, render-detect where compositional** — `data-ax-*` counts/visibility are machine assertions (page-flow driver); "summary-list answers what's wrong," "no card-in-card," "exceptions higher-signal" stay judge-graded rubric cells (193 D-10).
- **Custom `ax-*` CSS + committed bundle is SSOT** — editing `app.css` ships nothing until rebuilt + committed (Phase 189 shipped dead CSS this way).
- **`verify_package_docs.sh` ↔ `PackageDocsVerifierTest` coupling** + **admin copy ↔ committed `copy_strings.json` regen** — both must be kept in lockstep or CI fails.

### Integration Points
- New `data-ax-primary-action` / `data-ax-action-overflow-menu` / `data-ax-action-band` / `data-ax-related-resources` markers wire into the page-flow spec's count + visibility + `assertTopPointerTarget` assertions.
- `#ax-overlay-root` (root layout) + `scroll_lock.js` + `inert` toggle on `#accrue-admin-shell` wire into the LiveView app shell; hooks registered in `app.js`.
- Two new page-flow cells fold into the unchanged `regressions.ndjson` zero-regression gate; action-menu + drawer primitives land in Storybook.

</code_context>

<specifics>
## Specific Ideas

- The exemplar's job: make `subscription_live.ex` the page every other detail page is conformed against — clean locked reference, not a redesign-for-its-own-sake.
- **`cancel_at_period_end` (reversible) is the *visible* cancel; `cancel_now` (immediate, destructive) is buried + step-up-gated.** That split is the whole answer to "cancel is frequent and dangerous."
- **Delete the "canonical predicates" KPI** — it's library-author guidance leaking into the operator UI (hide-the-backend); the predicate logic still drives the status string internally.
- **One overlay path for scrim surfaces, a lightweight `<details>` for the trigger menu** — "no parallel overlay path" means the drawer/modal the menu opens must share the primitive, *not* that a menu gets scrim-wrapped.
- Build the overlay mechanism once in 195 (invariant 4 forces it here anyway), **freeze the API**, let 199 sweep — Phase 198 needs a frozen `<.overlay>` API *before* 199.
- Confirm `phx-portal` is in our pinned LiveView 1.1 before depending on it; hand-rolled portal hook is the fallback.

</specifics>

<deferred>
## Deferred Ideas

- **Cross-cutting overlay sweep across all ~20 pages** — Phase 199 (IXN-01 owner): migrate remaining overlay sites onto `<.overlay>`, the transformed-ancestor audit, native-`<dialog>` per-surface fallback, the full IXN battery (viewport-bounds, conditional-affordance, no-FOUC, reduced-motion), microcopy sweep, fixture stress.
- **Migrating `step_up_auth_modal.ex` onto the `:modal` presentation** — may slip to 199 if 195's plan budget is tight (D-03b); the `:modal` presentation still exists for the new handoff regardless.
- **Portaling the action-menu** — only if Phase 199's transformed-ancestor audit finds an unremovable clipping ancestor (evidence-driven exception, not the default).
- **Arrow-key roving-tabindex for the action menu** — beyond APG-acceptable Tab-through; add only if UAT asks.
- **SPEC-DETAIL propagation to the other detail/analytics pages** — Phase 198 (the spec footer names 198 as a consumer); requires the frozen `<.overlay>` + `summary_list` + `action_menu` from this phase.
- **Native time-trend / richer analytics on the subscription page** — not in scope; this is a structural-streamlining exemplar.

### Reviewed Todos (not folded)
None — no pending-todo matches surfaced for this phase.

</deferred>

---

*Phase: 195-exemplar-b-subscription-detail*
*Context gathered: 2026-06-25*
