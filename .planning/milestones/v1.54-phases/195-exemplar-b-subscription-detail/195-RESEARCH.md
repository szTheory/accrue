# Phase 195: Exemplar B — Subscription Detail - Research

**Researched:** 2026-06-26
**Domain:** Phoenix LiveView admin detail-page refactor, canonical overlay primitive, action-menu/drawer hosting
**Confidence:** HIGH for codebase and locked-scope findings; MEDIUM for external documentation synthesis

<user_constraints>
## User Constraints (from CONTEXT.md)

The locked decisions, discretion areas, and deferred ideas below are copied from `.planning/phases/195-exemplar-b-subscription-detail/195-CONTEXT.md`. [VERIFIED: 195-CONTEXT.md]

### Locked Decisions

All four gray areas were researched in parallel (advisor subagents, multi-lens: Elixir/LiveView idiom, named-competitor lessons, JTBD/persona, a11y, brand voice, software architecture) and resolved into **one cohesive package**. Each decision composes with the others: the **overflow menu** (D-04) triggers the **side-drawer** (hosts action forms — D-01) routed through the **canonical overlay primitive** (D-03); the **band structure** (D-02) leaves the action band between the summary-list header and the drill sections.

#### Action prioritization — ≤2 primary + one overflow menu (EXE-02)
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

#### Band structure + summary-list + default-open (EXE-02)
- **D-02 — Six bands per SPEC-DETAIL:** (1) GOV.UK summary-list header → (2) action band → (3) collapsible drill sections (one open) → (4) exactly one related-resources strip → (5) lazy activity timeline → (6) lazy raw JSON. Net: ~25 flat zones → 6 bands.
- **D-02a — New `Detail.summary_list/1` component** (GOV.UK key/value rows + per-row "Change" with visually-hidden context). `summary_card/1` (header banner: eyebrow + H1 + status pill) stays as the **outer wrapper**; `summary_list` renders inside it. Do **not** retrofit Change-columns onto `detail_field_list/1` (leave it for borderless read-only field groups in drills). Header rows (above-the-fold @1280×800): **Status** (read-only, badge + lifecycle qualifier) · **Customer** (link, no Change) · **Plan / price** [Change → swap-plan drawer] · **Current period** (read-only) · **Renews / ends** [Change → cancel/resume] · **Amount (MRR)** (derived). Conditional rows: **Seats / quantity** [Change → update-quantity] when single-item; **Dunning** [View → recovery drill] when a campaign has ever run. `processor_id` is the H1, **not** a row; no internal IDs in rows (hide-the-backend).
- **D-02b — Default-open drill = "Billing & items", EXCEPT open "Dunning & recovery" when `Subscription.dunning_campaign_active?/1`.** Exactly one section open at a time (native `<details open={...}>`, server-rendered, AT-navigable, survives re-render). Drill sections: Billing & items / Dunning & recovery / Tax & compliance.
- **D-02c — Fate of existing zones:** KPI grid → **delete** the "Status" KPI (redundant with header) and the **"Canonical predicates" KPI outright** (library-author documentation in the UI — a hide-the-backend violation; predicate logic still drives the status string internally); fold current price into the Plan/price row, drop the raw timeline-row count. Dunning card → **delete the standalone card**; at-a-glance state folds into the header Dunning row, detail moves into the Dunning & recovery drill. Duplicate related card (`data-role=subscription-related-billing`) → **delete**; migrate its two unique links (charges-for-customer, events-index) into `related_items/3` so the canonical `RelatedResources` strip is the only one (`data-ax-related-resources` count === 1). Card-in-card → **flattened**: the outer actions `ax-card` is removed (forms move to the drawer); tax-risk content → Tax & compliance drill (spacing + heading, no inner border); confirm/preview panel → drawer content.
- **D-02d — Lazy activity + JSON:** keep Timeline + JsonViewer in collapsed `<details>`; gate the expensive work behind first-expand (move the eager `timeline_events` load out of `mount`).

#### Overlay primitive build scope — 195 vs 199 seam (IXN-01)
- **D-03 — Option A: build the full canonical `<.overlay>` primitive in 195, freeze its public API; 199 sweeps.** SPEC-DETAIL invariant 4 (`assertTopPointerTarget` on the panel primary action + body-scroll-unchanged, desktop+mobile) makes the hard mechanism — portal + `inert` + scroll-lock — a **non-deferrable ship requirement for this drawer**. Given that, the only real choice is whether 199 *extracts* a primitive (rework + forces 195's in-scope action-menu popover into a forbidden parallel path) or merely *sweeps* an already-canonical one. Sweeping is strictly less rework and the only reading coherent with 193 D-01 + with Phase 198 needing a frozen API *before* 199. Mature systems (Radix, Headless UI, shadcn, Vaul) all build portal+dismissal+focus+scroll-lock as **one shared substrate first**, then layer thin presentations — none extract it after shipping a drawer-only version.
  - **`<.overlay>` component**, one shared portal/scrim/scroll-lock/dismissal spine, three presentations via `presentation` attr: `:modal` (centered), `:drawer` (edge-dock translateX desktop / bottom-sheet translateY mobile — fixes the R-3 wrong-axis bug), `:popover` (origin-aware). `role`=`dialog` for modal/drawer, `menu` for popover; `aria-modal` for modal/drawer only.
  - **`#ax-overlay-root`** body-level portal target mounted in the **root layout** (`root/1`, rendered once, survives live-nav/`phx-update`; guaranteed-untransformed body child — escapes the transformed-ancestor re-root that causes modal-behind-scrim).
  - **`scroll_lock.js`** — standalone, **ref-counted** (module-level counter so modal-over-drawer doesn't unlock on inner close), iOS-safe (`html{position:fixed;top:-savedY}` + `scrollTo` restore), gutter-compensated (`--ax-scrollbar-comp`, no jump). Inner scroll via `overscroll-behavior:contain`.
  - **`inert`** toggled on `#accrue-admin-shell` while any overlay is open (removes background from tab order + click + hover in one attribute; honor the D-17 `inert`-floor spike outcome). Reuse the shipped **`FocusTrap`** hook for containment/Escape/restore; keep the server-driven `:if={@open}` + `phx-mounted`/`phx-remove` model (D-03 LiveView-fit rationale — do NOT move to an imperative `open` attribute).
  - **Portal mechanism:** prefer LiveView's native `phx-portal` **if confirmed available in our `phoenix_live_view ~> 1.1` line** (it is morphdom-safe and keeps the D-04 `<dialog>` swap-seam clean); otherwise a hand-rolled portal hook. **Research/planner must confirm `phx-portal` availability in the pinned LV version before relying on it.**
  - **Re-point `detail_drawer.ex` onto `<.overlay presentation={:drawer}>`** (thin wrapper preserving its call sites/slots). It hosts the action forms (form appears only on menu invocation → invariant "action forms not pre-expanded" holds).
- **D-03a — 195↔199 boundary (explicit):** **195 ships** the `<.overlay>` component + frozen public API, `#ax-overlay-root`, `scroll_lock.js` + `inert` toggle, drawer geometry/origin-aware popover for the surfaces it uses, the action-menu popover + side-drawer action-hosting for the exemplar, destructive→`:modal` step-up handoff, Storybook stories for the primitives, and **passing SPEC-DETAIL invariant 4** on the subscription drawer. **199 owns** the mechanical sweep of the remaining ~19 overlay sites, the transformed-ancestor audit, and the D-02/D-04 native-`<dialog>` per-surface fallback (flip only audited-unfixable surfaces, behind the unchanged component boundary).
- **D-03b — Budget-relief fallback (executor discretion):** if the exemplar's plan budget can't also absorb migrating `step_up_auth_modal.ex` onto the `:modal` presentation, **leave step-up on its current shell and let 199 migrate it** (Option C). The `:modal` presentation still exists for the new step-up handoff; same seam quality, briefly two overlay code paths. **Reject:** Option B (drawer-only-then-extract) — the in-scope action-menu popover makes a drawer-only scope incoherent and forces a forbidden parallel overlay path.

#### Action-menu mechanism (IXN-01 coherence)
- **D-04 — Option A (refined): a dedicated `<details>`-based `action_menu/1` component; only the drawer/modal it opens routes through the overlay primitive.** Distinct from the link-shaped `dropdown_menu/1` — actions are `<button role="menuitem" phx-click>` (push LiveView events), not `<a href>`. `summary` carries `aria-haspopup="menu"`; panel is `role="menu"`. Reuse the shipped `dropdown.js` dismissal grammar (Escape + outside-click → idempotent close + focus-restore to trigger). Add `transform-origin: top right` (origin-aware, R-4) — no new tokens.
- **D-04a — The reconciling principle (crisp):** *193 D-01's "no parallel overlay path" governs the **scrim-overlay surface** (the drawer/modal the menu opens), not every popped-up box. A trigger menu and a modal context are different ARIA roles with different contracts.* The menu **shares** the dismissal + origin-awareness grammar; it correctly does **not** share scrim / scroll-lock / `inert` / focus-trap (applying `inert` behind a *menu* would be a semantic error — a menu is not a modal context). This matches Radix (DropdownMenu is separate from Dialog: portals + dismissal but no scroll-lock, not modal).
- **D-04b — Danger handling:** destructive items last, after a divider, `ax-dropdown-item-danger`; they do **not** act from the menu — they open the step-up modal. Item API: `%{label, event, target, value, danger?, description?, confirm?}`.
- **D-04c — Clipping mitigation:** keep the menu's `position:absolute` panel; **enroll the detail action-band's ancestor in Phase 199's transformed-ancestor audit.** Portal-the-menu is a late, evidence-driven exception only if the audit finds an unremovable re-rooting/clipping ancestor (mirrors the D-02 `<dialog>` fallback posture) — never the 195 default. **Reject:** Option B (route the menu itself through the overlay primitive — over-engineers a lightweight menu, couples 195 to in-flight machinery, risks the menu-vs-dialog semantic mixup).

### the agent's Discretion
- Exact `summary_list` markup/CSS, the precise `data-ax-*` hook placement, and which drill-section copy strings are new vs reused — bounded by D-02 + the no-Tailwind/committed-bundle-rebuild + copy-regen constraints.
- The `<.overlay>` slot/attr signature details (`:actions`/`:footer` slots, `anchor_id` for popover) and whether `scroll_lock.js` carries the `inert` toggle inline vs a thin companion hook — bounded by D-03.
- Whether D-03b (defer step-up-modal migration to 199) is taken — based on the realized plan budget for the exemplar.
- Whether arrow-key roving is added to `action_menu/1` beyond Tab-through (APG-acceptable for a disclosure) — only if UAT asks; do not front-load the roving-tabindex bug surface.
- Where the two new `surface_type:"page-flow"` cells for the subscription detail page live relative to the additive `baseline.page-flow.cells.json`.

### Deferred Ideas (OUT OF SCOPE)
- **Cross-cutting overlay sweep across all ~20 pages** — Phase 199 (IXN-01 owner): migrate remaining overlay sites onto `<.overlay>`, the transformed-ancestor audit, native-`<dialog>` per-surface fallback, the full IXN battery (viewport-bounds, conditional-affordance, no-FOUC, reduced-motion), microcopy sweep, fixture stress.
- **Migrating `step_up_auth_modal.ex` onto the `:modal` presentation** — may slip to 199 if 195's plan budget is tight (D-03b); the `:modal` presentation still exists for the new handoff regardless.
- **Portaling the action-menu** — only if Phase 199's transformed-ancestor audit finds an unremovable clipping ancestor (evidence-driven exception, not the default).
- **Arrow-key roving-tabindex for the action menu** — beyond APG-acceptable Tab-through; add only if UAT asks.
- **SPEC-DETAIL propagation to the other detail/analytics pages** — Phase 198 (the spec footer names 198 as a consumer); requires the frozen `<.overlay>` + `summary_list` + `action_menu` from this phase.
- **Native time-trend / richer analytics on the subscription page** — not in scope; this is a structural-streamlining exemplar.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EXE-02 | Convert the Subscription detail page to summary-then-drill, with summary-list header, <=2 primary actions plus overflow action-menu, drawer-hosted action forms, duplicate related deletion, and flattened nesting. [VERIFIED: REQUIREMENTS.md] | Use `Detail.summary_list/1`, `ActionMenu.action_menu/1`, `DetailDrawer` backed by `<.overlay presentation={:drawer}>`, one canonical `RelatedResources` strip, lazy Timeline/JsonViewer loading, and provider-gated action data from existing predicates. [VERIFIED: 195-CONTEXT.md + codebase grep] |
| IXN-01 | Canonical overlay primitive must back modal/drawer surfaces with ref-counted iOS-safe scroll lock, body-level portal, inert background, and clean backdrop/Escape dismissal; Phase 195 instantiates this for Subscription detail while Phase 199 owns the full sweep. [VERIFIED: REQUIREMENTS.md] | Use LiveView `.portal` to `#ax-overlay-root`, reuse `FocusTrap`, add scroll lock/inert behavior, and prove the drawer with component, JS, and Playwright page-flow tests. [VERIFIED: phoenix_live_view local docs + codebase grep] |
</phase_requirements>

## Summary

Phase 195 should be planned as a structural refactor of one LiveView page plus three reusable primitives: `Detail.summary_list/1`, a button-based `ActionMenu.action_menu/1`, and a canonical `<.overlay>` substrate used by the existing `DetailDrawer` wrapper. [VERIFIED: 195-CONTEXT.md] The current `SubscriptionLive` already has the action execution path, provider predicates, step-up handoff, related-item builder, Timeline, JsonViewer, and FocusTrap/dropdown hooks; planning should preserve those paths and change where and when they render. [VERIFIED: codebase grep]

The highest-risk planning area is not billing logic; it is interaction correctness at the overlay boundary. [VERIFIED: 195-CONTEXT.md] The planner should allocate explicit tasks for body-level portal target insertion, LiveView `.portal` use, scroll-lock/inert JS, CSS z/geometry updates, Storybook stories, and browser-level assertions that the drawer is hit-testable above the scrim, scroll-locks the page, and dismisses by backdrop and Escape. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/Phoenix.Component.html#portal/1 + VERIFIED: codebase grep]

**Primary recommendation:** Implement the canonical overlay first, re-point `DetailDrawer` through it, then convert `SubscriptionLive` into six bands with all non-primary actions opening drawer forms through the existing `prepare_action`/`confirm_action` flow. [VERIFIED: 195-CONTEXT.md + codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Subscription detail page structure | Frontend Server / LiveView | Browser / CSS | The LiveView render owns bands, assigns, provider-gated action visibility, and server events; CSS/browser behavior owns responsive drill, drawer, and menu affordances. [VERIFIED: codebase grep] |
| Billing operator actions | API / Backend domain contexts | Frontend Server / LiveView | Existing handlers call billing contexts and StepUp; Phase 195 should move forms into drawers without inventing new billing execution paths. [VERIFIED: codebase grep] |
| Overlay primitive | Browser / Client | Frontend Server / LiveView | Portal target, scroll lock, inert, focus containment, Escape, and hit-testing are DOM/browser concerns triggered by LiveView-rendered overlay state. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/ + VERIFIED: codebase grep] |
| Action menu | Frontend Server / LiveView | Browser / Client | Menu items are LiveView event buttons, while native `<details>` and `dropdown.js` own open/close dismissal behavior. [VERIFIED: 195-CONTEXT.md + codebase grep] |
| Storybook primitive coverage | Dev/Test tooling | Frontend Server / LiveView | PhoenixStorybook renders component variations from LiveView components and should document the action-menu/drawer primitive states. [CITED: https://phoenix-storybook.hexdocs.pm/components.html] |
| Forward-only page-flow gate | Browser / E2E | Test fixture data | The existing Playwright page-flow helpers perform viewport, pointer, focus, and scroll assertions against rendered admin routes. [VERIFIED: codebase grep] |

## Project Constraints (from CLAUDE.md)

- Work in the `accrue_admin` operator UI only; do not add new billing primitives, domain behavior, breaking routes, or public API churn for this phase. [VERIFIED: CLAUDE.md + 195-CONTEXT.md]
- Keep the custom `ax-*` CSS/token system as the styling source of truth; do not introduce Tailwind migration work. [VERIFIED: CLAUDE.md + 195-CONTEXT.md]
- Rebuild and commit the generated admin asset bundle after source CSS/JS changes because source CSS edits alone do not ship. [VERIFIED: 195-CONTEXT.md + mix help --search accrue_admin.assets.build]
- Keep core `accrue` LiveView-runtime-free; PhoenixStorybook and LiveView runtime work belongs in `accrue_admin`. [VERIFIED: CLAUDE.md]
- Admin copy changes must go through `AccrueAdmin.Copy` and regenerate the committed copy fixture with `mix accrue_admin.export_copy_strings`. [VERIFIED: 195-CONTEXT.md + mix help --search accrue_admin.export_copy_strings]
- `AGENTS.md`, `.claude/skills/`, and `.agents/skills/` are absent in this workspace, so no additional project-skill directives apply. [VERIFIED: filesystem probe]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / OTP | Elixir 1.19.5 on Erlang/OTP 28 locally | Compile and test `accrue_admin`. | Installed local runtime meets project floor of Elixir 1.17+ and OTP 27+. [VERIFIED: local version probe + CLAUDE.md] |
| Phoenix | 1.8.7 locked | Router/layout/component runtime for admin app. | Project targets Phoenix 1.8+ and `accrue_admin` lockfile already uses 1.8.7. [VERIFIED: mix.lock + CLAUDE.md] |
| Phoenix LiveView | 1.1.31 locked, released 2026-05-29 | Subscription LiveView, function components, hooks, and native `.portal`. | The pinned LiveView 1.1 line includes `Phoenix.Component.portal/1`, which is the standard body-level teleport mechanism for this overlay. [VERIFIED: mix.lock + mix hex.info + phoenix_live_view local docs] |
| PhoenixStorybook | 1.2.0 locked, released 2026-06-11 | Dev/test-only component stories for action-menu and drawer/overlay primitive. | Existing router/backend scaffolding uses PhoenixStorybook; no new component documentation stack is needed. [VERIFIED: mix.exs + mix.lock + mix hex.info] |
| Custom `ax-*` CSS / tokens | Existing source bundle | Styling, z-index tokens, drawer/modal/menu geometry. | Phase 193/195 guardrails require custom admin CSS and no Tailwind migration. [VERIFIED: 195-CONTEXT.md + codebase grep] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Existing `FocusTrap` hook | Local admin JS hook | Focus containment, Escape dispatch, and focus restore for overlays. | Reuse for modal/drawer overlay panels instead of writing a second trap. [VERIFIED: codebase grep] |
| Existing `dropdown.js` | Local admin JS module | `<details>` outside-click/Escape close grammar. | Reuse for `action_menu/1` trigger menu dismissal; do not apply modal scroll-lock/inert to menus. [VERIFIED: codebase grep + 195-CONTEXT.md] |
| Playwright | CLI reports 1.59.1; package constraint `@playwright/test ^1.57.0` | Page-flow E2E and overlay hit-test validation. | Existing phase page-flow tests and helpers already check top pointer target, focus, scroll reachability, and clipping. [VERIFIED: package.json + local version probe + codebase grep] |
| `@axe-core/playwright` / `axe-core` | Existing npm dev dependencies, npm latest `@axe-core/playwright` 4.12.1 | Accessibility checks over rendered flows/stories. | Use only existing dependency; do not add or upgrade in Phase 195 unless explicitly planned. [VERIFIED: package.json + npm view] |
| `mix accrue_admin.assets.build` | Existing Mix task | Rebuild committed `priv/static/accrue_admin.css/js`. | Required after CSS/JS hook changes. [VERIFIED: mix help --search accrue_admin.assets.build] |
| `mix accrue_admin.export_copy_strings` | Existing Mix task | Regenerate host E2E copy fixture. | Required when relabeling action copy through `AccrueAdmin.Copy`. [VERIFIED: mix help --search accrue_admin.export_copy_strings] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| LiveView `.portal` | Hand-rolled portal hook | Only use a custom hook if `.portal` proves unusable; pinned LiveView 1.1.31 includes `.portal`, so custom teleporting adds risk. [VERIFIED: phoenix_live_view local docs] |
| Local `FocusTrap` | New focus-trap npm package | Existing hook already implements containment/Escape/restore and avoids adding package risk. [VERIFIED: codebase grep] |
| Local `dropdown.js` + `<details>` | New dropdown/menu library | Existing details-menu grammar matches the locked action-menu decision and avoids modal semantics for a lightweight trigger menu. [VERIFIED: 195-CONTEXT.md + codebase grep] |
| Refactor existing `detail_field_list/1` | Add `Detail.summary_list/1` | Locked context explicitly says to keep `detail_field_list/1` for read-only drill field groups and add a GOV.UK-style summary list component. [VERIFIED: 195-CONTEXT.md] |
| Rewrite billing action handling | Reuse `prepare_action`/`confirm_action`/`cancel_pending_action` | Existing handler triplet already handles previews, destructive step-up, execution, and refresh; rewriting risks behavior regressions. [VERIFIED: codebase grep] |

**Installation:**
```bash
# No new external packages are recommended for Phase 195.
# Use the existing Hex/npm dependencies already locked in the repository.
```

## Package Legitimacy Audit

> Phase 195 should not install new external packages. [VERIFIED: 195-CONTEXT.md + codebase grep] Existing dependencies below are already present and should be reused; any upgrade or new package addition should be gated by a human verification checkpoint. [VERIFIED: package-legitimacy check + npm view]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `:phoenix_live_view` | Hex | 1.1.31 released 2026-05-29 | Hex reported 117,833 downloads for 1.1.31 query output | Hex docs and local deps | OK for existing lock | Approved existing dependency; do not upgrade as part of this phase. [VERIFIED: mix hex.info + mix.lock] |
| `:phoenix_storybook` | Hex | 1.2.0 released 2026-06-11 | Hex reported 3,349 downloads for 1.2.0 query output | Hex docs and local deps | OK for existing lock | Approved existing dev/test dependency. [VERIFIED: mix hex.info + mix.lock] |
| `@axe-core/playwright` | npm | Existing dev dependency; npm latest checked as 4.12.1 | Registry metadata checked; seam flagged too-new if installing/upgrading | `dequelabs/axe-core-npm` | SUS if newly installed/upgraded | Existing only; planner must add `checkpoint:human-verify` before any upgrade. [VERIFIED: npm view + package-legitimacy check] |
| `axe-core` | npm | Existing transitive/dev dependency | Registry metadata checked; seam flagged too-new if installing/upgrading | `dequelabs/axe-core` family | SUS if newly installed/upgraded | Existing only; planner must add `checkpoint:human-verify` before any upgrade. [VERIFIED: npm view + package-legitimacy check] |
| `playwright` / `@playwright/test` | npm | Existing dev dependency | Registry metadata checked; seam flagged too-new if installing/upgrading | `microsoft/playwright` | SUS if newly installed/upgraded | Existing only; planner must add `checkpoint:human-verify` before any upgrade. [VERIFIED: npm view + package-legitimacy check] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package-legitimacy check]
**Packages flagged as suspicious [SUS]:** npm testing packages only if newly installed or upgraded; no Phase 195 install is recommended. [VERIFIED: package-legitimacy check]

## Architecture Patterns

### System Architecture Diagram

```text
Operator opens /subscriptions/:id
  -> SubscriptionLive.mount/params
  -> Subscriptions.detail(owner_scope, id)
  -> assign subscription + provider predicates + related_items
  -> render summary_card + Detail.summary_list
  -> render action band
       -> primary action button OR action_menu item
       -> prepare_action(type, params)
       -> pending_action assigned
       -> DetailDrawer wrapper
       -> <.overlay presentation={:drawer}> via .portal target="#ax-overlay-root"
       -> drawer form submit confirm_action
            -> non-destructive: execute_action -> refresh_subscription
            -> destructive: StepUp.require_fresh -> <.overlay presentation={:modal}> or current StepUp fallback
  -> render one open drill section
  -> render one RelatedResources strip
  -> on first expand: lazy-load Timeline / raw JSON
```

This flow keeps billing execution in the existing backend/domain path and moves only the operator interaction surface. [VERIFIED: codebase grep + 195-CONTEXT.md]

### Recommended Project Structure

```text
accrue_admin/
├── lib/accrue_admin/components/
│   ├── overlay.ex              # new canonical overlay component
│   ├── detail.ex               # add summary_list/1
│   ├── detail_drawer.ex        # thin wrapper over overlay drawer
│   └── action_menu.ex          # new button/menuitem action menu
├── lib/accrue_admin/live/
│   └── subscription_live.ex    # six-band exemplar refactor
├── assets/js/hooks/
│   ├── focus_trap.js           # reused
│   └── scroll_lock.js          # new ref-counted lock/inert behavior
├── assets/js/
│   └── dropdown.js             # reused for action menu close grammar
├── storybook/components/
│   ├── overlay.story.exs       # new primitive story
│   └── action_menu.story.exs   # new primitive story
├── test/accrue_admin/components/
│   └── overlay_components_test.exs
├── test/accrue_admin/live/
│   └── subscription_live_test.exs
├── test/js/
│   └── scroll_lock_test.mjs    # new
└── e2e/
    └── admin-spec-detail-phase195.spec.js # new
```

The Storybook directory is the repository root `storybook/`, not `accrue_admin/storybook/`; generated or manual stories should follow the existing `storybook/components/button.story.exs` pattern. [VERIFIED: codebase grep]

### Pattern 1: LiveView Portal Overlay

**What:** Render one overlay root in the LiveView tree, then teleport the DOM to a body-level `#ax-overlay-root` with `.portal`. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/Phoenix.Component.html#portal/1]

**When to use:** Use for modal/drawer surfaces that must escape transformed ancestors, stack above scrims, scroll-lock the document, and inert the app shell. [VERIFIED: 195-CONTEXT.md]

**Example:**
```elixir
# Source: Phoenix LiveView 1.1.31 portal docs + Phase 195 locked context
<.portal id={"#{@id}-portal"} target="#ax-overlay-root">
  <section
    id={@id}
    class={["ax-overlay", "ax-overlay-#{@presentation}"]}
    role={@role}
    aria-modal={@presentation in [:modal, :drawer]}
    aria-labelledby={"#{@id}-title"}
    data-ax-overlay-root
  >
    <button type="button" class="ax-overlay-backdrop" phx-click={@on_cancel} aria-label="Close" />
    <div class="ax-overlay-panel" phx-hook="FocusTrap" data-close-event={@on_cancel}>
      {render_slot(@inner_block)}
    </div>
  </section>
</.portal>
```

Planner note: put `#ax-overlay-root` in `Layouts.root/1` as a body-level sibling to the app shell, and keep the teleported root ID stable because LiveView portal cleanup depends on a single rooted element. [VERIFIED: phoenix_live_view local docs + codebase grep]

### Pattern 2: Ref-Counted Scroll Lock + Inert

**What:** Use a small browser hook/module that increments a module-level lock count on overlay mount, fixes the document at the saved scroll position, applies scrollbar compensation, sets `inert` on `#accrue-admin-shell`, and restores scroll only when the final overlay closes. [VERIFIED: 195-CONTEXT.md]

**When to use:** Use for modal/drawer overlay presentations; do not use it for the lightweight action menu. [VERIFIED: 195-CONTEXT.md]

**Implementation guidance:** Attach scroll-lock behavior to an overlay wrapper or companion hook while `FocusTrap` stays on the focus-containing panel; avoid replacing the proven FocusTrap behavior unless the executor intentionally builds one combined overlay hook. [ASSUMED]

### Pattern 3: GOV.UK-Style Summary List

**What:** A `<dl>` summary list renders rows with key, value, and optional row-level actions that include visually hidden context. [CITED: https://design-system.service.gov.uk/components/summary-list/]

**When to use:** Use inside `summary_card/1` for the above-the-fold subscription state, especially rows that answer operator questions and offer a scoped “Change” path. [VERIFIED: 195-CONTEXT.md]

**Example:**
```elixir
# Source: GOV.UK summary-list docs + Phase 195 locked context
<.summary_list
  rows={[
    %{key: "Status", value: status_badge(assigns), action: nil},
    %{key: "Plan / price", value: plan_label(@subscription), action: %{label: "Change", event: "prepare_action", value: "swap_plan"}},
    %{key: "Renews / ends", value: renewal_label(@subscription), action: %{label: "Change", event: "prepare_action", value: "cancel_at_period_end"}}
  ]}
/>
```

### Pattern 4: Button Action Menu

**What:** Use a dedicated `<details>` component with a `summary` trigger and `<button role="menuitem">` items that push LiveView events. [VERIFIED: 195-CONTEXT.md]

**When to use:** Use for non-primary subscription actions, grouped by Edit billing, Collection, and Danger zone. [VERIFIED: 195-CONTEXT.md]

**Example:**
```elixir
# Source: WAI-ARIA menu button pattern + Phase 195 locked context
<details class="ax-dropdown ax-action-menu" data-ax-action-overflow-menu>
  <summary class="ax-button ax-button-secondary" aria-haspopup="menu">
    More actions
  </summary>
  <div class="ax-dropdown-panel" role="menu">
    <button type="button" role="menuitem" phx-click="prepare_action" phx-value-type="update_quantity">
      Update quantity
    </button>
    <hr role="separator" />
    <button type="button" role="menuitem" class="ax-dropdown-item-danger" phx-click="prepare_action" phx-value-type="cancel_now">
      Cancel immediately
    </button>
  </div>
</details>
```

### Anti-Patterns to Avoid

- **Disabled-but-visible unavailable actions:** Provider-ineligible actions must be absent, not disabled, because the locked context calls disabled-looks-enabled a known pitfall. [VERIFIED: 195-CONTEXT.md]
- **Parallel scrim overlay path:** Drawer/modal surfaces must use the canonical overlay substrate; keeping old modal/drawer shells for new surfaces reintroduces the modal-behind-scrim risk. [VERIFIED: 195-CONTEXT.md + codebase grep]
- **Menu as modal:** The action menu must not scroll-lock, inert the app shell, or trap focus because it is a trigger menu, not a modal context. [VERIFIED: 195-CONTEXT.md + CITED: https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/]
- **Eager Timeline load:** `SubscriptionLive.mount` currently assigns `timeline_events` eagerly; Phase 195 should move that work behind first expand. [VERIFIED: codebase grep + 195-CONTEXT.md]
- **Card-in-card confirmation preview:** The existing confirm/preview panel belongs inside the drawer content and should not remain as a nested card on the page. [VERIFIED: 195-CONTEXT.md + codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DOM teleport / escaping stacking contexts | Custom portal hook | LiveView `.portal` | Pinned LiveView includes a portal component designed to teleport content to a target while preserving LiveView patching semantics. [VERIFIED: phoenix_live_view local docs] |
| Focus containment | New trap package or second local trap | Existing `FocusTrap` hook | The hook already covers Tab wrap, Escape dispatch, and focus restore; replacing it expands the bug surface. [VERIFIED: codebase grep] |
| Menu dismissal | New global click/Escape handler | Existing `dropdown.js` grammar | Current code already closes open `details.ax-dropdown` on outside click and Escape. [VERIFIED: codebase grep] |
| Billing action router | New action executor | Existing handler triplet and `execute_action` clauses | Existing code already distinguishes destructive actions and handles StepUp before execution. [VERIFIED: codebase grep] |
| Summary-list semantics | Custom div grid with fake labels | Semantic `<dl>` component | GOV.UK summary-list pattern uses key/value rows with optional action cells and visually hidden action context. [CITED: https://design-system.service.gov.uk/components/summary-list/] |
| Scroll locking | CSS-only `overflow:hidden` | Ref-counted JS lock with fixed document and restore | iOS body scroll-lock and nested overlays require saved scroll restoration and lock counting. [VERIFIED: 195-CONTEXT.md + CITED: https://www.jayfreestone.com/writing/locking-body-scroll-ios/] |

**Key insight:** This phase should reuse the existing domain/action machinery and spend implementation risk on the interaction substrate, because the user-visible defect is structural density and overlay correctness, not missing billing behavior. [VERIFIED: 195-CONTEXT.md + codebase grep]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None requiring migration; subscription records, events, and dunning state are read and displayed but not renamed or rekeyed. [VERIFIED: codebase grep] | No data migration. Preserve existing event names and billing context calls. [VERIFIED: codebase grep] |
| Live service config | None found for this UI-only refactor. [VERIFIED: 195-CONTEXT.md + codebase grep] | No external service patch. [VERIFIED: 195-CONTEXT.md] |
| OS-registered state | None found. [VERIFIED: filesystem/codebase probe] | No OS registration task. [VERIFIED: filesystem/codebase probe] |
| Secrets/env vars | No secret or environment variable names are part of the refactor. [VERIFIED: codebase grep] | No secret rotation or env rename. [VERIFIED: codebase grep] |
| Build artifacts | Committed admin CSS/JS bundles and generated copy fixture can become stale after source CSS/JS/copy edits. [VERIFIED: 195-CONTEXT.md + mix help --search] | Run and commit `mix accrue_admin.assets.build`; run and commit `mix accrue_admin.export_copy_strings` if copy changes. [VERIFIED: mix help --search] |

**Nothing found in category:** Stored-data migration, live-service config, OS registration, and env/secret changes are all explicitly out of scope for this UI structural refactor. [VERIFIED: 195-CONTEXT.md + codebase grep]

## Common Pitfalls

### Pitfall 1: Portal Target Missing or Wrongly Placed
**What goes wrong:** LiveView portal content cannot be teleported or still renders inside a transformed/clipped ancestor. [VERIFIED: phoenix_live_view local docs + 195-CONTEXT.md]
**Why it happens:** The root layout lacks a stable body-level `#ax-overlay-root`, or the teleported content has no single stable root ID. [VERIFIED: phoenix_live_view local docs]
**How to avoid:** Add `#ax-overlay-root` in `Layouts.root/1`, keep it a direct body-level sibling of the app shell, and test the teleported drawer in a browser. [VERIFIED: 195-CONTEXT.md + codebase grep]
**Warning signs:** `assertTopPointerTarget` fails, panel clicks hit the scrim, or LiveView logs portal-target errors. [VERIFIED: 195-CONTEXT.md + phoenix_live_view local docs]

### Pitfall 2: Tests Query the Wrong DOM for Portaled Content
**What goes wrong:** LiveView component tests fail because teleported portal children are not where the test expects. [VERIFIED: phoenix_live_view local docs]
**Why it happens:** LiveView portal docs state that tests cannot query inside teleported content the same way as ordinary rendered children. [VERIFIED: phoenix_live_view local docs]
**How to avoid:** Component tests should assert the portal source/template and browser tests should assert the real DOM target. [VERIFIED: phoenix_live_view local docs]
**Warning signs:** The component renders correctly in browser but `rendered =~ ...` assertions miss panel content. [VERIFIED: phoenix_live_view local docs]

### Pitfall 3: Non-Ref-Counted Scroll Lock
**What goes wrong:** Closing a step-up modal over a drawer unlocks the page while the drawer remains open. [VERIFIED: 195-CONTEXT.md]
**Why it happens:** Scroll lock state is represented as a boolean instead of a counter. [VERIFIED: 195-CONTEXT.md]
**How to avoid:** Implement a module-level lock counter and restore scroll only when the count returns to zero. [VERIFIED: 195-CONTEXT.md]
**Warning signs:** Body scroll position changes while any overlay remains open, especially after modal-over-drawer flows. [VERIFIED: 195-CONTEXT.md]

### Pitfall 4: Action Forms Still Render on Page Load
**What goes wrong:** The page technically has an action menu, but old forms remain visible in the page body. [VERIFIED: codebase grep + 195-CONTEXT.md]
**Why it happens:** The existing admin actions card is partially retained instead of moving form bodies into drawer content. [VERIFIED: codebase grep]
**How to avoid:** Add an assertion for zero visible action-band forms on initial load and drive form rendering from `@pending_action`. [VERIFIED: spec-detail.md + codebase grep]
**Warning signs:** `[data-role="cancel-now-form"]` or quantity/item forms are visible before an action is selected. [VERIFIED: codebase grep]

### Pitfall 5: Copy Fixture Drift
**What goes wrong:** Browser tests read stale labels after action copy changes. [VERIFIED: 195-CONTEXT.md]
**Why it happens:** `AccrueAdmin.Copy` changes are not followed by `mix accrue_admin.export_copy_strings`. [VERIFIED: 195-CONTEXT.md + mix help --search]
**How to avoid:** Pair copy module edits with fixture regeneration in the same plan wave. [VERIFIED: 195-CONTEXT.md]
**Warning signs:** Local LiveView text differs from `examples/accrue_host/e2e/generated/copy_strings.json`. [VERIFIED: codebase grep]

### Pitfall 6: CSS/JS Source Edits Without Bundle Rebuild
**What goes wrong:** Overlay CSS/JS works in source but not in the committed app bundle. [VERIFIED: 195-CONTEXT.md]
**Why it happens:** `accrue_admin` ships committed private static bundles generated by `mix accrue_admin.assets.build`. [VERIFIED: mix help --search accrue_admin.assets.build + codebase grep]
**How to avoid:** Rebuild and commit generated CSS/JS after `assets/css` or `assets/js` edits. [VERIFIED: mix help --search accrue_admin.assets.build]
**Warning signs:** Tests using built assets fail while direct source inspection looks correct. [VERIFIED: 195-CONTEXT.md]

## Code Examples

### Scroll Lock Contract Test Shape

```javascript
// Source: Phase 195 locked context + existing Node hook-test pattern
test("scroll lock is ref-counted and restores scroll", () => {
  window.scrollTo(0, 400)
  ScrollLock.lock()
  ScrollLock.lock()
  ScrollLock.unlock()
  assert.equal(document.documentElement.style.position, "fixed")
  ScrollLock.unlock()
  assert.equal(document.documentElement.style.position, "")
  assert.equal(window.scrollY, 400)
})
```

This test should live in `accrue_admin/test/js/scroll_lock_test.mjs`, which is missing today. [VERIFIED: filesystem probe]

### Page-Flow Overlay Assertion Shape

```javascript
// Source: existing Phase 191 page-flow helpers
await page.getByRole("button", { name: /More actions/i }).click()
await page.getByRole("menuitem", { name: /Change plan/i }).click()
const drawer = page.locator("[data-ax-overlay-root][data-presentation='drawer']")
await assertTopPointerTarget(page, drawer.getByRole("button", { name: /Confirm/i }))
await expect(page.locator("#accrue-admin-shell")).toHaveAttribute("inert", "")
await page.keyboard.press("Escape")
await expect(drawer).toBeHidden()
```

The exact selector names should match the final `data-ax-*` hooks, but the invariant should prove top hit-testing, inert background, and Escape dismissal on desktop and mobile projects. [VERIFIED: 195-CONTEXT.md + codebase grep]

### Related Resources Merge

```elixir
# Source: Phase 195 locked context + existing related_items/3 seam
defp related_items(subscription, customer, flash) do
  [
    customer_item(customer),
    invoices_for_subscription(subscription),
    charges_for_customer(customer),
    events_for_subject(subscription),
    events_index_item()
  ]
  |> Enum.reject(&is_nil/1)
  |> FlashVisibility.filter_visible(flash)
end
```

The current duplicate `data-role="subscription-related-billing"` card should be deleted, and its unique links should move into the canonical `related_items/3` list. [VERIFIED: 195-CONTEXT.md + codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom overlay shells without portal/scroll-lock/inert | One canonical overlay substrate with modal/drawer/popover presentations | Locked by Phase 193/195; implemented in Phase 195 for the exemplar | Planner should build the primitive first and sweep remaining sites in Phase 199. [VERIFIED: 195-CONTEXT.md] |
| Drawer fixed in local DOM | LiveView `.portal` to body-level target | LiveView 1.1.31 docs include `.portal`; project is locked on 1.1.31 | Avoid hand-rolled portal unless the pinned implementation fails in this app. [VERIFIED: mix.lock + phoenix_live_view local docs] |
| Always-visible admin action forms | Action band plus drawer-hosted forms | Phase 195 locked decision | Test initial page load for zero visible action forms. [VERIFIED: 195-CONTEXT.md] |
| `aria-hidden`-style background hiding alone | Native `inert` background plus focus trap for modal/drawer | `inert` is widely available since April 2023 per MDN | Use `inert` on `#accrue-admin-shell` while overlay is open. [CITED: https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/inert] |
| Ad hoc scrollbar compensation | CSS `scrollbar-gutter` support plus JS `--ax-scrollbar-comp` fallback/compensation | MDN marks `scrollbar-gutter` Baseline 2024 | Use compensation to avoid layout jump when locking scroll. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/scrollbar-gutter] |

**Deprecated/outdated:**
- The current `detail_drawer.ex` shell is not sufficient for Phase 195 because it does not portal, scroll-lock, or inert the background. [VERIFIED: codebase grep + 195-CONTEXT.md]
- The current `StepUpAuthModal` shell may remain only under D-03b budget relief; new drawer work should not copy its non-portaled shell. [VERIFIED: 195-CONTEXT.md + codebase grep]
- The current subscription action card is structurally obsolete for this phase because action forms must be drawer-hosted and absent on initial load. [VERIFIED: 195-CONTEXT.md + codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Scroll-lock behavior can mount as a companion hook/module while `FocusTrap` remains the focus containment hook, without needing to merge them into one hook. [ASSUMED] | Architecture Patterns | If LiveView hook placement makes this awkward, executor should create one `Overlay` hook that delegates the existing FocusTrap behavior instead of adding two hooks to one element. |

## Open Questions (RESOLVED)

1. **Exact MRR/amount formatter for the summary row — resolved**
   - Resolution: Plan 195-07 owns the code-reading and implementation work for the Amount/MRR row. It must reuse existing money/date helpers and current subscription item data; if a complete MRR cannot be derived from the current shape, it must render a truthful dash/unknown state through existing formatting rather than create new billing logic. [VERIFIED: 195-07-PLAN.md + CLAUDE.md + 195-CONTEXT.md]

2. **Step-up modal migration timing — resolved**
   - Resolution: Phase 195 plans include the StepUp wrapper migration now. Plan 195-03 routes `StepUpAuthModal.step_up_auth_modal/1` through `Overlay.overlay/1` with `presentation={:modal}` while preserving `step_up_dismiss`, `step_up_submit`, input labels, and cancel-before-submit ordering. Phase 199 still owns the broader overlay sweep, not this wrapper migration. [VERIFIED: 195-03-PLAN.md + 195-CONTEXT.md]

3. **Arrow-key roving for action menu — resolved**
   - Resolution: Phase 195 does not implement roving tabindex. Plans 195-06 and 195-08 ship the locked lightweight disclosure/menu behavior: button menu items, APG-compatible roles, Escape/outside-click dismissal, focus restore to trigger, danger grouping, and no modal overlay semantics. Roving remains deferred unless UAT explicitly rejects Tab-through behavior. [VERIFIED: 195-06-PLAN.md + 195-08-PLAN.md + 195-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Erlang | Mix compile and ExUnit | yes | Elixir 1.19.5, Erlang/OTP 28 | None needed. [VERIFIED: local version probe] |
| Mix | Mix tasks and tests | yes | 1.19.5 | None needed. [VERIFIED: local version probe] |
| Node.js | JS hook tests and asset tooling | yes | v22.14.0 | None needed. [VERIFIED: local version probe] |
| npm | npm scripts and Playwright | yes | 11.1.0 | None needed. [VERIFIED: local version probe] |
| Playwright CLI | Page-flow E2E | yes | 1.59.1 reported by `npx playwright --version` | If browser binaries are missing, run the existing install flow before E2E. [VERIFIED: local version probe] |
| `mix accrue_admin.assets.build` | CSS/JS bundle rebuild | yes | Existing Mix task | No fallback; planner must run after CSS/JS edits. [VERIFIED: mix help --search] |
| `mix accrue_admin.export_copy_strings` | Copy fixture regeneration | yes | Existing Mix task | Skip only if no copy module changes. [VERIFIED: mix help --search] |

**Missing dependencies with no fallback:**
- None identified during research. [VERIFIED: local probes]

**Missing dependencies with fallback:**
- Playwright browser binary availability was not separately smoke-tested during research; if E2E launch fails, run the existing browser install/setup path before declaring the phase blocked. [ASSUMED]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit/Mix for LiveView/component tests; Node `node --test` for JS hooks; Playwright for browser page-flow. [VERIFIED: codebase grep] |
| Config file | `accrue_admin/playwright.config.js`; ExUnit standard project config; existing Node hook tests under `accrue_admin/test/js`. [VERIFIED: codebase grep] |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/live/subscription_live_test.exs` [VERIFIED: filesystem probe] |
| JS hook command | `cd accrue_admin && node --test test/js/focus_trap_test.mjs test/js/scroll_lock_test.mjs test/js/dropdown_test.mjs` after adding the Phase 195 scroll-lock and dropdown tests. [VERIFIED: filesystem probe + 195-06/195-08 plans] |
| Full suite command | `cd accrue_admin && mix test && npm run e2e:phase195` after adding the Phase 195 script/spec; keep existing page-flow suites green. [VERIFIED: package.json/codebase grep + ASSUMED for new script name] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| EXE-02 | Summary-list header has locked rows, <=2 `[data-ax-primary-action]`, one `[data-ax-action-overflow-menu]`, one `[data-ax-related-resources]`, and no duplicate related card. [VERIFIED: 195-CONTEXT.md] | LiveView + browser | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` plus Phase 195 Playwright spec. [VERIFIED: filesystem probe] | Existing LiveView test yes; new E2E file missing. [VERIFIED: filesystem probe] |
| EXE-02 | Action forms are absent on initial load and render only in the drawer after action selection. [VERIFIED: 195-CONTEXT.md] | LiveView + browser | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` and `npm run e2e:phase195`. [VERIFIED: filesystem probe + ASSUMED for new script name] | LiveView test exists; E2E file missing. [VERIFIED: filesystem probe] |
| IXN-01 | Drawer portals to body root, sits above scrim, traps focus, scroll-locks, inerts background, and dismisses with backdrop/Escape. [VERIFIED: 195-CONTEXT.md] | Component + JS + Playwright | `cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs && node --test test/js/scroll_lock_test.mjs && npm run e2e:phase195`. [VERIFIED: filesystem probe + ASSUMED for new script name] | Component test exists; scroll-lock and E2E files missing. [VERIFIED: filesystem probe] |

### Sampling Rate
- **Per task commit:** Run the targeted ExUnit file for touched LiveView/component code and the Node hook test when scroll-lock/inert JS changes. [VERIFIED: codebase grep]
- **Per wave merge:** Run `cd accrue_admin && mix test` plus the Phase 195 Playwright spec. [VERIFIED: codebase grep + ASSUMED for new script name]
- **Phase gate:** Full suite green, rebuilt assets committed, copy fixture regenerated if copy changed, and page-flow overlay invariants passing on desktop and mobile. [VERIFIED: 195-CONTEXT.md + codebase grep]

### Wave 0 Gaps
- [ ] `accrue_admin/test/js/scroll_lock_test.mjs` — covers ref count, saved scroll restore, scrollbar compensation, and inert toggle for IXN-01. [VERIFIED: filesystem probe]
- [ ] `accrue_admin/e2e/admin-spec-detail-phase195.spec.js` — covers SPEC-DETAIL exemplar flow, overlay hit-testing, zero visible action forms, one related strip, and drawer dismissal. [VERIFIED: filesystem probe]
- [ ] `accrue_admin/test/accrue_admin/components/overlay_components_test.exs` — exists but currently targets old `DetailDrawer`/`StepUpAuthModal` shell behavior; update for canonical overlay/portal attrs. [VERIFIED: codebase grep]
- [ ] `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` — exists but currently asserts the old always-visible forms and duplicate related card; update to the six-band contract. [VERIFIED: codebase grep]
- [ ] `accrue_admin/package.json` — add a Phase 195 E2E script if the project convention requires named phase scripts. [VERIFIED: package.json/codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Preserve existing admin session authentication and use `StepUp.require_fresh/4` for `cancel_now` and `comp_subscription`. [VERIFIED: codebase grep] |
| V3 Session Management | no new session mechanism | Do not add overlay/menu state to long-lived storage; LiveView assigns and hooks are sufficient. [VERIFIED: 195-CONTEXT.md] |
| V4 Access Control | yes | Keep `Subscriptions.detail(owner_scope, id)` scoping and do not add route/API bypasses for action drawers. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Whitelist action types through existing handler clauses and provider predicates; unavailable actions should be absent from the menu. [VERIFIED: 195-CONTEXT.md + codebase grep] |
| V6 Cryptography | no new crypto | Do not add cryptographic code; preserve existing secret handling and StepUp/session mechanisms. [VERIFIED: CLAUDE.md + codebase grep] |

### Known Threat Patterns for Phoenix LiveView Admin Overlay/Action Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Destructive action bypass from crafted event | Elevation of privilege / Tampering | Keep `@destructive_actions` and `StepUp.require_fresh/4` in the `confirm_action` path; do not execute danger actions directly from menu clicks. [VERIFIED: codebase grep + 195-CONTEXT.md] |
| Unauthorized subscription access | Elevation of privilege | Preserve `owner_scope` lookup in `Subscriptions.detail/2`; drawer actions should operate on the already scoped subscription. [VERIFIED: codebase grep] |
| Background interaction while drawer is open | Tampering / UI redress | Apply `inert` to `#accrue-admin-shell`, trap focus, and hit-test drawer above scrim. [CITED: https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/inert + VERIFIED: 195-CONTEXT.md] |
| Raw JSON or event data XSS | Information disclosure / Tampering | Keep HEEx escaping and existing JsonViewer rendering; do not inject raw HTML from subscription payloads. [VERIFIED: codebase grep] |
| CSRF-like forged LiveView event | Tampering | Use LiveView event handling through existing socket/session path and server-side action allowlists; do not trust hidden form fields alone. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/195-exemplar-b-subscription-detail/195-CONTEXT.md` — locked implementation decisions, deferrals, code seams, and constraints. [VERIFIED: local file read]
- `.planning/REQUIREMENTS.md` — EXE-02 and IXN-01 requirement text and phase mapping note. [VERIFIED: local file read]
- `CLAUDE.md` — project stack and constraints. [VERIFIED: local file read]
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — existing action handlers, provider predicates, eager timeline load, duplicate related card, and form-heavy layout. [VERIFIED: codebase grep]
- `accrue_admin/lib/accrue_admin/components/*` and `accrue_admin/assets/js/*` — current drawer, step-up modal, dropdown, FocusTrap, shell, and layout integration points. [VERIFIED: codebase grep]
- `accrue_admin/mix.lock`, `accrue_admin/mix.exs`, `accrue_admin/package.json` — locked dependency/tooling state. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- Phoenix LiveView 1.1.31 local docs for `Phoenix.Component.portal/1` — portal behavior and testing caveat. [VERIFIED: local dependency docs]
- `https://phoenix-storybook.hexdocs.pm/components.html` — PhoenixStorybook story and variation patterns. [CITED: phoenix-storybook.hexdocs.pm/components.html]
- `https://design-system.service.gov.uk/components/summary-list/` — GOV.UK summary-list structure and row action pattern. [CITED: design-system.service.gov.uk/components/summary-list]
- `https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/` — modal dialog focus, inert background, Escape, and ARIA requirements. [CITED: www.w3.org/WAI/ARIA/apg/patterns/dialog-modal]
- `https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/` — menu button roles, `aria-haspopup`, `aria-expanded`, and menuitem behavior. [CITED: www.w3.org/WAI/ARIA/apg/patterns/menu-button]
- `https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/inert` — inert support and behavior. [CITED: developer.mozilla.org inert docs]
- `https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/scrollbar-gutter` — scrollbar-gutter support and purpose. [CITED: developer.mozilla.org scrollbar-gutter docs]
- `https://www.jayfreestone.com/writing/locking-body-scroll-ios/` — iOS-safe fixed-body scroll-lock considerations. [CITED: jayfreestone.com]

### Tertiary (LOW confidence)
- Assumption A1 about hook composition is implementation guidance to verify during execution. [ASSUMED]
- Playwright browser binary fallback is an environment assumption because the CLI version was checked but browser launch was not smoke-tested during research. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — dependency versions and tasks were verified from lockfiles, package manifests, local version probes, Hex/npm metadata, and existing project files. [VERIFIED: mix.lock + package.json + local probes]
- Architecture: HIGH — the target structure is locked by CONTEXT.md and the existing code seams were verified locally. [VERIFIED: 195-CONTEXT.md + codebase grep]
- Pitfalls: HIGH for local pitfalls and MEDIUM for external browser/platform details — local pitfalls come from the locked phase context and codebase; external inert/scrollbar/ARIA claims come from official docs. [VERIFIED: 195-CONTEXT.md + CITED: MDN/WAI/GOV.UK docs]

**Research date:** 2026-06-26
**Valid until:** 2026-07-26 for codebase-local findings; recheck dependency/latest-package metadata before any package upgrade. [VERIFIED: local probes + ASSUMED validity window]
