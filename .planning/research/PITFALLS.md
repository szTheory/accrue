# v1.54 Usability-Footgun & Prevention Research

**Domain:** Page-level design-system anti-patterns, interaction/overlay correctness, and visual-defect prevention for a mature Phoenix LiveView admin UI (`accrue_admin`) with a token-based design system (`ax-*`).
**Researched:** 2026-06-24
**Confidence:** HIGH (canonical design-system + WCAG + named-vendor sources; cross-checked against the live `theme.css` token set and `verify_package_docs.sh` gate inventory)
**Downstream:** Feeds v1.54 REQUIREMENTS.md (IXN interaction/overlay + FIX fixture-stress categories), cross-cutting Phase 199, verification Phase 200.

> **How to read this.** Each maintainer-listed bug class is mapped to **root cause → canonical prevention pattern → acceptance criterion / CI guard → gap-vs-existing-gate → adversarial direction**. The existing `accrue_admin` token + CI system already prevents a meaningful fraction of these; the value of this milestone is closing the **page-composition** gaps that token discipline alone cannot catch. Where an existing gate covers it, it is marked **✅ COVERED**; where a new criterion/guard is needed it is marked **🆕 NEW** or **⚠️ PARTIAL**.

---

## Existing-system baseline (what is already prevented)

From `accrue_admin/assets/css/theme.css` + `scripts/ci/verify_package_docs.sh`:

- **Z-index scale is tokenized** (`--ax-z-base..toast`, 0→600) and **literals are CI-banned** in `app.css` outside documented isolated micro-stacks (FND-02 perl guard). ✅
- **Spacing scale exists** (`--ax-space-2xs..3xl`, 4px base + 2px + 64px rungs). Token *vocabulary* exists; *usage discipline* (no raw px in HEEx, container-vs-content rhythm) is **not** fully gated. ⚠️
- **Disabled / readonly / focus / scrollbar / interactive / status role tokens exist** and each must appear in ≥3 scopes (root/dark/system-dark) — semantic-token presence gate. ✅ presence; ⚠️ correct *consumption*.
- **Semantic-role contrast is CI-verified** via `verify_foundation_contrast.mjs` (FND-05). ✅ for token pairs; ⚠️ does not verify *rendered page* contrast (text over arbitrary surfaces, disabled-on-surface).
- **Tri-state theme** (light/dark/system) is implemented (`ThemePicker` + `accrue_theme` hook + `@media (prefers-color-scheme: dark)` for `data-theme="system"`), with server-rendered initial `@theme` to avoid flash. ✅ structure; ⚠️ FOUC-before-first-paint not proven by a gate.
- **Motion antipatterns banned**: no `transition: all`, no raw cubic-bezier, no raw ms/s, no layout-property transitions (MOT-01). ✅
- **No Tailwind utilities** in HEEx; **no per-page overrides** of primitive `ax-*` classes; **no inline `style=`** on primitives (CMP-05). ✅ component isolation.
- **Breakpoint annotation** gate: bare `@media (min/max-width)` must carry `--ax-bp-*` comment (DSY-01). ✅

**The structural gap this milestone targets:** every existing gate operates on **tokens and CSS source text**. None of them observe a **composed, rendered page** in a real viewport × theme × state matrix. The maintainer's entire bug list is *page-composition / runtime-interaction* failure — overlays, scroll, alignment, breathing room, disabled-looks-enabled, empty-state hover — which **CSS-source linting structurally cannot see**. Prevention here therefore needs a **rendered-state harness** (PhoenixStorybook stories + Playwright/axe over the viewport×theme×state matrix) plus a small number of new source guards. Prevention > detection, but for composition, *rendered detection in CI* is the realistic prevention.

---

## Critical Pitfalls (maintainer-enumerated bug classes)

### Pitfall 1: Modal/drawer opens but the whole screen is dark and you can't see/interact with it (modal-behind-scrim)

**What goes wrong:** The scrim/overlay paints *over* the dialog content, so the user sees a dimmed screen with an invisible (or click-blocked) modal.

**Root cause (CSS / stacking context):** The scrim and the dialog live in **different stacking contexts**, so their `z-index` values don't compare. Any ancestor with `position: fixed/sticky`, `opacity < 1`, `transform`, `filter`, `will-change`, `isolation: isolate`, or `mix-blend-mode` **creates a new stacking context** that *traps* a descendant's z-index — a child's `z-index: 9999` cannot escape a parent context that sits below the scrim. ([freecodecamp](https://www.freecodecamp.org/news/4-reasons-your-z-index-isnt-working-and-how-to-fix-it-coder-coder-6bc05f103e6c/), [playfulprogramming](https://playfulprogramming.com/posts/css-stacking-context/)). In LiveView this is acute because modals/drawers are often rendered *inside* a deeply nested component subtree, not at the document root.

**Canonical prevention pattern:**
1. **Render overlays at the document root** (portal pattern) — modal + its scrim as **siblings at `body` level**, escaping all page stacking contexts. ([weblog.west-wind](https://weblog.west-wind.com/posts/2016/sep/14/bootstrap-modal-dialog-showing-under-modal-background/)).
2. **Prefer the native `<dialog>` element with `showModal()`**, which promotes the dialog to the browser **top layer** — *above all stacking contexts by definition*, with a built-in `::backdrop` that cannot invert ordering. This is the structurally-immune fix.
3. **Scrim z-index strictly below modal z-index within one shared context** — `--ax-z-drawer (400)` / `--ax-z-modal (500)` already encode this; the scrim must use the *same* family one rung below its content, never a parallel literal.

**Acceptance criterion / CI guard:**
- 🆕 **AC:** Every overlay (modal, drawer, command palette, popover) renders such that, in a Playwright test, clicking the dialog's primary action and a focusable control inside it **succeeds** while the scrim is present (proves the dialog is *above* and *hit-testable*) — across desktop+mobile × light/dark.
- 🆕 **Source guard:** Overlay components must mount at root (or use `<dialog showModal>`); add a guard/story asserting no overlay component declares `position: fixed` *inside* a `transform`/`opacity`/`filter` ancestor in its own CSS.
- ✅ **COVERED (partial):** z-index literal ban + tokenized scale already prevents the *parallel-literal* variant. **GAP:** the *trapped-context* variant (overlay nested under a transformed ancestor) is invisible to source lint → needs the rendered Playwright hit-test + the `<dialog>`/portal structural rule.

**Adversarial direction:** Naively, "just bump the modal z-index" — **rejected**, it cannot escape a trapped context and is the exact non-fix that perpetuates the bug. **Chosen:** mandate native `<dialog>`+top-layer (or root portal) for all overlays, and *prove* it with a CI hit-test, because v1.53 already shipped a `FocusTrap` and behavioral regression coverage — extend that harness rather than trust z-index numbers.

---

### Pitfall 2: Awkward scroll / can't scroll / scroll traps / awkward scrollbars

**What goes wrong:** Background scrolls behind an open modal; or the modal body can't scroll; or opening a modal shifts the whole layout (content jumps) because the scrollbar disappears; or nested scroll containers fight (scroll-chaining).

**Root cause (layout / scroll-lock):**
- `overflow: hidden` on `body` to lock scroll **removes the scrollbar**, widening the viewport by the scrollbar width → a **layout-shift jump**. ([css-tricks](https://css-tricks.com/prevent-page-scrolling-when-a-modal-is-open/)).
- iOS Safari **ignores `overflow: hidden`** on body; touch scroll bleeds through ([jayfreestone](https://www.jayfreestone.com/writing/locking-body-scroll-ios/), [pqina](https://pqina.nl/blog/how-to-prevent-scrolling-the-page-on-ios-safari/)).
- Modal body with no `overflow-y: auto` + bounded height → **content chopped, unscrollable**.
- Missing `overscroll-behavior: contain` → scrolling the modal body "chains" to the page (scroll trap feel).

**Canonical prevention pattern:**
1. **Scroll-lock with scrollbar-gutter compensation:** lock body and add `padding-right` equal to the measured scrollbar width (the `reserveScrollBarGap` pattern), OR use modern `scrollbar-gutter: stable` so the gutter never collapses. ([body-scroll-lock](https://github.com/willmcpo/body-scroll-lock)).
2. **iOS:** `position: fixed` + restore-scroll-position pattern, or a vetted scroll-lock implementation; never rely on `overflow: hidden` alone.
3. **Modal body owns its own scroll:** `max-height` + `overflow-y: auto` on the *body* region (header/footer fixed), and `overscroll-behavior: contain` to kill chaining.
4. **Tokenized scrollbars** (already have `--ax-scrollbar-*`) applied consistently so scroll regions don't show OS-default mismatched bars across themes.

**Acceptance criterion / CI guard:**
- 🆕 **AC:** Opening any overlay (a) does not move page content horizontally (no scrollbar-gutter jump — assert layout box of a header element is unchanged before/after open), (b) locks background scroll (page scrollTop unchanged after wheel/touch on scrim), (c) a long modal body scrolls *internally* and does not chain to the page.
- 🆕 **AC (mobile):** the iOS-class trap is covered by a mobile-viewport Playwright check.
- ⚠️ **PARTIAL:** `--ax-scrollbar-*` tokens exist (presence-gated) but *consumption* on scroll regions isn't asserted → add a story + visual check that scroll containers use tokenized scrollbars in both themes.

**Adversarial direction:** "Just `overflow:hidden` on body" is the seductive one-liner — **rejected** (jump + iOS bleed). **Chosen:** scrollbar-gutter-stable lock + internal-scroll + `overscroll-behavior: contain`, verified by a before/after layout-box assertion, because the jump is *the* most common visible symptom and is cheaply machine-detectable.

---

### Pitfall 3: Elements floating/hovering in the wrong spot, covering other content (mispositioned popovers/dropdowns/tooltips)

**What goes wrong:** A dropdown, tooltip, or sticky element renders offset from its trigger, off-screen, or on top of unrelated content.

**Root cause:** Absolutely-positioned floating UI anchored relative to the **wrong containing block** (nearest positioned ancestor, not the trigger), or clipped by an ancestor `overflow: hidden`, or no collision/flip logic so it spills off-viewport. Often the same stacking-context family problem as Pitfall 1.

**Canonical prevention pattern:**
1. **Anchor floating UI to the trigger** with a positioning strategy that accounts for viewport collision (flip/shift) — either CSS Anchor Positioning where supported, or a Floating-UI-style middleware, or `<dialog>`/popover top-layer for menus.
2. **Render in top layer / root portal** to escape `overflow: hidden` clipping and stacking traps (the `popover` attribute promotes to top layer like `<dialog>`).
3. **Tokenized layer rung** `--ax-z-popover (300)` / `--ax-z-dropdown (200)` already exist — floating UI must use them and sit above page content but below modal.

**Acceptance criterion / CI guard:**
- 🆕 **AC:** For each floating element (CMD-K results, row action menus, tooltips, theme picker), a Playwright check asserts the floating box is **within viewport bounds** and **visually adjacent to its trigger** (bounding-box proximity) at desktop+mobile, light+dark, including a near-edge trigger to force collision handling.
- ✅ **COVERED:** z-index rung discipline. **GAP:** collision/clipping is rendered-only → needs the harness.

**Adversarial direction:** Pixel-pushing each menu's `top/left` per page is the trap (drifts instantly). **Chosen:** one shared anchored/top-layer popover primitive + a viewport-bounds assertion, leveraging v1.54's PhoenixStorybook to host each floating story for the check.

---

### Pitfall 4: Misalignment / awkward padding / content chopped off on one side

**What goes wrong:** Columns don't line up; a card has 16px left and 8px right; text/numbers clipped at one edge.

**Root cause:**
- **Asymmetric / ad-hoc padding** because spacing is hand-typed per element instead of drawn from inset tokens.
- **Squished flex/grid children** (see Pitfall 8) clipping content on one side.
- Mixed optical alignment (icon baseline vs text baseline) with no shared alignment primitive.

**Canonical prevention pattern (EightShapes spacing model):** Nathan Curtis's six spatial concepts — **Inset** (uniform 4-side padding), **Inset-Squish** (reduced vertical, used in table cells/list items), **Stack** (vertical rhythm between blocks), **Inline** (horizontal item spacing), **Grid** (page margins/gutters) — every spacing decision picks *one named pattern from the scale*, never a raw number. ([eightshapes](https://medium.com/eightshapes-llc/space-in-design-systems-188bcbae0d62)). Symmetry is enforced by using `--ax-space-*` tokens for *all four sides via a single inset token*, not per-side magic numbers.

**Acceptance criterion / CI guard:**
- 🆕 **Source guard:** HEEx/CSS spacing must use `--ax-space-*` tokens (or named inset/stack/inline utilities), not raw px — extend the existing perl HEEx-lint family to flag raw `padding:`/`margin:`/`gap:` px in `app.css` outside an allowlist, and discourage per-side `padding-left/right` mismatches without a token.
- 🆕 **AC:** No page renders content clipped at a container edge (visual check via Storybook story at narrow + wide).
- ⚠️ **PARTIAL:** spacing *tokens* exist; raw-px usage isn't banned the way raw type/motion already are → add a spacing-literal guard symmetric to FND-01 (type) and MOT-01 (motion).

**Adversarial direction:** A blanket raw-px ban risks false positives on legit 1px borders/hairlines — **mitigated** by allowlisting `1px`/border/hairline and `0`, banning the *spacing* properties (`padding`, `margin`, `gap`) with non-token values. Chosen because it mirrors the proven FND-01/MOT-01 guard shape the repo already trusts.

---

### Pitfall 5: Inconsistent / absent spacing; flush-in-container; card-in-card over-boxing

**What goes wrong:** Elements sit flush against container walls (no breathing room) or against each other (looks accidental); cards nested inside cards create a heavy "boxed-in" double-border look.

**Root cause:**
- **No container inset** → content touches the edge.
- **No stack rhythm** between siblings → zero or random gaps.
- **Nesting bordered/elevated surfaces** (`--ax-elevated` card inside `--ax-elevated` card) doubles borders and shadows; the inner unit reads as a redundant box. The design-system rule: *margin between cards must exceed padding inside cards or cards visually merge*; and depth should be signaled by **one** elevation step, not nested boxes. ([atlassian spacing](https://atlassian.design/foundations/spacing), [eightshapes](https://medium.com/eightshapes-llc/space-in-design-systems-188bcbae0d62)).

**Canonical prevention pattern:**
1. **Container vs content separation:** containers own **inset** (padding); collections own **stack/inline** (gap between children). Never both un-set.
2. **"Section vs card" rule:** a *card* is one elevation step (surface + border + radius). Inside a card, group with **sections/dividers/subheadings and spacing**, NOT with another card. Only nest a card when it is genuinely a separate, independently-actionable object (and then drop the inner border, using sunken `--ax-sunken` or a hairline instead of a second `--ax-elevated` box).
3. **Spacing scale discipline** (t-shirt named, geometric) so gaps are always a deliberate rung.

**Acceptance criterion / CI guard:**
- 🆕 **AC (heuristic, visual):** No card is a direct child of another card without an explicit "nested-card" exemption note; depth uses elevation/sunken tokens, not a second bordered box. Caught in the page-flow rubric cells + Storybook archetype review.
- 🆕 **AC:** Every list/collection uses a tokenized `gap`; every panel uses a tokenized inset. Spotted by the spacing-literal guard (Pitfall 4) + archetype pattern-spec conformance.
- ⚠️ **PARTIAL → 🆕:** This is primarily a *judgment* defect; the realistic guard is the **locked archetype pattern-specs (overview/list/detail) + per-page rubric scoring** in Phases 193/200, not a pure lint.

**Adversarial direction:** You cannot fully lint "tasteful breathing room." **Chosen:** encode it as (a) a token-usage guard for the mechanical half (no raw/zero spacing) and (b) an archetype pattern-spec + rubric cell for the judgment half — accepting that the rubric/Storybook review is the enforcement surface, consistent with v1.53's forward-only scorecard machinery.

---

### Pitfall 6: Disabled fields that don't look disabled; weird focus/hover; unreadable button text (same fg/bg); poor dark-mode contrast

**What goes wrong:** A disabled control looks active (users click it); OR a disabled control is *so* faded its label is unreadable; focus rings missing or wrong; hover states inconsistent; a primary button has text the same color as its fill; dark-mode text fails contrast.

**Root cause:**
- **Disabled = lower opacity only** is the classic trap: it both fails to *signal* disabled distinctly AND drops text below WCAG 4.5:1. Major systems (Atlassian, Carbon, Lightning) ship disabled buttons that *fail* contrast. ([medium/salim-ansari](https://medium.com/design-bootcamp/the-color-contrast-dilemma-of-disabled-buttons-in-accessible-design-59811fc89f62)).
- **`:focus` instead of `:focus-visible`** → focus ring shows on mouse click (noise) or is removed entirely (no keyboard affordance). Overriding default focus without a ≥3:1 replacement is a WCAG fail. ([sarasoueidan](https://www.sarasoueidan.com/blog/focus-indicators/)).
- **Button text == fill color** → a `--ax-accent` fill with `--ax-accent` text (no `--ax-accent-contrast`).
- **Dark-mode contrast** fails when colors aren't re-tuned per theme (pure white on near-black causes halation; saturated hues read poorly on dark). ([accessibilitychecker](https://www.accessibilitychecker.org/blog/dark-mode-accessibility/), [dubbot](https://dubbot.com/dubblog/2023/dark-mode-a11y.html)).

**Canonical prevention pattern:**
1. **Disabled = distinct token set, not opacity-only:** `--ax-disabled-bg/border/text/cursor` (already present) — signal via surface + cursor `not-allowed` + reduced-but-still-legible text, not opacity collapse. (Note: WCAG explicitly *exempts* disabled controls from contrast minima, but the design rule is "clearly disabled AND label still legible" — the repo's `--ax-disabled-text` at `#5d6a73`/`#c0c9d2` is the right move vs raw opacity.)
2. **`:focus-visible` with ≥3:1 ring** (`--ax-focus-ring` + `--ax-focus-shadow` already tokenized; ensure consumption is `:focus-visible`, not `:focus`).
3. **Explicit on-fill contrast token** (`--ax-accent-contrast`, `--ax-status-*-on-solid` already present) — filled controls must read text from the `-on-solid`/`-contrast` token, never the fill hue.
4. **Per-theme color re-tuning** with off-white on dark-gray (not #fff on #000), desaturated accents (theme.css already does `#0f1318` base + `#f4f7fa` primary + desaturated dark status hues — good).

**Acceptance criterion / CI guard:**
- ✅ **COVERED:** Disabled/readonly/focus/interactive/on-solid tokens are presence-gated (≥3 scopes) AND `verify_foundation_contrast.mjs` (FND-05) checks role-pair contrast; interactive `:hover`/`:active`/`:selected` *consumption* is gated (`require_css_rule_consumes`).
- ⚠️ **GAP 1:** No gate proves controls use **`:focus-visible`** specifically (vs `:focus`) → 🆕 add a guard that focus styling in `app.css` targets `:focus-visible` (allow `:focus:not(:focus-visible){outline:none}` reset).
- ⚠️ **GAP 2:** No gate proves a **disabled control is visually distinct from its enabled state in the rendered page** (token presence ≠ applied) → 🆕 Storybook state-matrix story for each form/control family rendering enabled/hover/focus/disabled/readonly × light/dark, visually reviewed in Phase 200.
- ⚠️ **GAP 3:** FND-05 checks *token pairs*; it does not check **rendered text-on-actual-surface** (e.g., muted text over `--ax-sunken` inside a card) → 🆕 extend contrast verification to the specific text/surface role pairs that actually co-occur on pages (or an axe color-contrast pass over rendered Storybook stories).

**Adversarial direction:** Relying on FND-05 token-pair contrast as "good enough" is the trap — it doesn't see *composed* pairings or `:focus` vs `:focus-visible`. **Chosen:** keep FND-05, add a `:focus-visible` source guard (cheap, deterministic) and an **axe-core color-contrast + state-matrix pass over rendered Storybook stories** for the composed cases, because axe catches the rendered pairings token-lint cannot.

---

### Pitfall 7: Tabs without selected/active state; empty/awkward pagination; hover on non-interactive empty-state heroes

**What goes wrong:** Active tab indistinguishable from inactive; pagination control shows when there's 1 page (dead affordance); an empty-state illustration has a hover/pointer cursor implying it's clickable when it isn't.

**Root cause:**
- Selected state relies on a token that isn't *consumed* on `aria-selected`/`aria-current`.
- Pagination rendered unconditionally regardless of `total_pages > 1`.
- Empty-state hero uses an interactive component (button/card) or inherits `:hover`/`cursor:pointer` though it's decorative.

**Canonical prevention pattern:**
1. **Selected state bound to ARIA state** (`--ax-interactive-selected` consumed via `[aria-selected]`/`[aria-current]`) — repo already gates `require_css_rule_consumes ... 'aria-current|aria-selected|active|selected'`. ✅
2. **Conditional affordances:** pagination renders only when `pages > 1`; "load more" only when a next page exists; no zero-state controls. (Dashboard UX: dead/empty affordances are a top complaint — [databox](https://databox.com/bad-dashboard-examples), [raw.studio](https://raw.studio/blog/dashboard-design-disasters-6-ux-mistakes-you-cant-afford-to-make/)).
3. **Non-interactive empty states:** decorative heroes have no `:hover`, no `cursor: pointer`, no `role="button"`; the *only* interactive thing in an empty state is the explicit CTA.

**Acceptance criterion / CI guard:**
- ✅ **COVERED:** selected/current state token *consumption* is gated (Phase 188 `require_css_rule_consumes`).
- 🆕 **AC:** Pagination/"load more"/filter-clear affordances are absent when not applicable (Playwright: a single-page list shows no pager; an empty list shows CTA-only, no hover-state on the hero glyph).
- 🆕 **AC:** Empty-state hero elements expose no pointer cursor / no interactive role (DOM assertion + visual).
- ⚠️ **PARTIAL:** active-tab token consumption gated, but *rendered* tab-distinctness and the empty/zero-affordance cases are rendered-only → harness.

**Adversarial direction:** Trusting that "the token exists so the tab will look selected" — **rejected** (token present ≠ visibly distinct at this contrast). **Chosen:** a Storybook story per nav/tab/pagination/empty-state family across active/empty/single-page states, reviewed in Phase 200, plus Playwright conditional-affordance assertions in Phase 199.

---

### Pitfall 8: Squished/unreadable table columns; tables overused vs cards/lists; inconsistent stat-cards; non-semantic icons

**What goes wrong:** A column's content is crushed to one character wide with mid-word wrap; a table is used where a card list would read better; stat cards look different page-to-page; icons don't communicate their meaning.

**Root cause:**
- **Squished columns:** flex/grid table cells have default `min-width: auto` (= content min-width), so a long cell forces the table wide and others collapse; the fix `min-width: 0` (and `minmax(0, 1fr)` for grid) is *by spec*, not a hack. ([css-tricks/flexbox-truncated-text](https://css-tricks.com/flexbox-truncated-text/), [bigbinary](https://www.bigbinary.com/blog/understanding-the-automatic-minimum-size-of-flex-items/), [css-tricks/grid-blowout](https://css-tricks.com/preventing-a-grid-blowout/)).
- **Tables-everywhere:** tables don't fit narrow viewports; >3 columns force horizontal scroll; if every row looks identical, scanning fails. ([uxmovement](https://uxmovement.medium.com/the-best-mobile-layout-for-complex-data-tables-e3ced21ce425), [medium/shreya-roy](https://medium.com/@royshreya538/mastering-tables-in-dashboards-avoid-these-5-ux-mistakes-boost-usability-ae4eca569ae4)).
- **Inconsistent stat-cards:** no single stat-card primitive → each page re-rolls.
- **Non-semantic icons:** icon chosen for looks, not meaning.

**Canonical prevention pattern (responsive tables):**
1. **`min-width: 0` on truncatable cells** + `text-overflow: ellipsis; overflow: hidden; white-space: nowrap`; grid tracks use `minmax(0, 1fr)`. Removes squish at the spec level.
2. **Column priority + degradation:** assign priority (lower = keep longer); below a breakpoint, **degrade table → stacked cards** (key fields + expandable detail), or **horizontal-scroll container with a frozen first/identity column**, chosen *intentionally* per table. ([datatables column-priority](https://datatables.net/extensions/responsive/priority), [uxpatterns.dev](https://uxpatterns.dev/patterns/data-display/table)). v1.53 already shipped **responsive table→card degradation** (CMP/group-contract) — this milestone makes the *choice* (table vs card vs scroll) deliberate per page.
3. **"Table only when scanning rows of homogeneous records"** rule; otherwise card/list. Status/action/number columns visually distinct.
4. **One `StatCard`/`KpiCard` primitive** reused everywhere (repo already has `KpiCard`).
5. **Semantic icon map:** each icon tied to a meaning in the registry, reviewed for legibility at `--ax-icon-sm`.

**Acceptance criterion / CI guard:**
- 🆕 **Source guard:** any flex/grid table cell intended to truncate must pair truncation with `min-width: 0`/`minmax(0,...)` — add a guard that flags `text-overflow: ellipsis` without an accompanying `min-width: 0` in the same rule (heuristic).
- 🆕 **AC:** No column renders content clipped/over-wrapped at the target min viewport (Playwright/visual at narrow width); each table page declares its degradation strategy (card vs scroll) in the list archetype pattern-spec.
- ✅ **COVERED:** table→card degradation primitive exists (v1.53). **GAP:** *per-page intentionality* + squish prevention at the cell level → new source guard + archetype conformance.
- 🆕 **AC:** Stat cards on all pages use the shared primitive (grep for ad-hoc stat markup); icons pass a semantic-legibility review row in the rubric.

**Adversarial direction:** Forcing *all* tables to cards on mobile is over-correction (operators often *want* the dense scrollable grid). **Chosen:** make degradation a **declared per-table decision** (card | horizontal-scroll-with-frozen-identity-column) validated against the list archetype spec, with `min-width:0` enforced universally because squish is never desirable.

---

### Pitfall 9: No proper full light/dark/system theme switch (system default) / flash of wrong theme

**What goes wrong:** Theme toggle is missing a state, doesn't persist, doesn't follow OS in "system," or flashes the wrong theme on load (FOUC).

**Root cause:**
- **Two-state (light/dark only)** misses "follow OS." A complete control is **tri-state**: explicit light, explicit dark, follow-system. ([tailwind dark-mode](https://tailwindcss.com/docs/dark-mode), [nerdleveltech](https://nerdleveltech.com/tailwind-v4-dark-mode)).
- **FOUC:** the theme is applied by JS *after* first paint, so the page flashes the default theme. Fix = set the theme class/attr **before first paint** via a tiny **inline `<head>` script** reading persisted choice + `prefers-color-scheme`. ([notanumber](https://www.notanumber.in/blog/fixing-react-dark-mode-flickering), [simonporter](https://www.simonporter.co.uk/posts/what-the-fouc-astro-transitions-and-tailwind/)).
- **System tracking:** "system" must react to OS changes live via `matchMedia('(prefers-color-scheme: dark)')` — repo already does this with `@media (prefers-color-scheme: dark) html.accrue-admin[data-theme="system"]`. ✅

**Canonical prevention pattern:** Tri-state control (✅ `ThemePicker` already light/dark/system, `role=radiogroup`, server-rendered initial `@theme` to avoid flash, persistence via the `accrue_theme` hook). The remaining risk is **proving** no FOUC: the `data-theme` attribute must be on `<html>` **before the first stylesheet paint** (server-rendered from persisted cookie/assign, not set by a post-mount JS hook).

**Acceptance criterion / CI guard:**
- ✅ **COVERED (structure):** tri-state picker, system media query, server-rendered initial theme, full dark token set in all three scopes (presence-gated).
- ⚠️ **GAP:** No gate proves **no-flash on first paint** and **persistence across reload** → 🆕 Playwright: set theme=dark, reload, assert `<html data-theme="dark">` is present in the *initial server HTML* (not applied post-hydration) and no light-frame is painted; assert "system" flips with emulated `prefers-color-scheme`.
- 🆕 **AC:** All ~20 pages render correct in light AND dark AND system (forced) — the milestone's per-page viewport×theme matrix in Phase 200 covers this.

**Adversarial direction:** Trusting the server-rendered `@theme` "should" prevent flash without proof — **rejected**; FOUC regressions are invisible until a user sees them. **Chosen:** a deterministic Playwright first-paint + reload + persistence + system-emulation check, since the structure is already correct and only needs a regression lock.

---

## Cross-cutting: how teams CATCH these before ship (prevention > detection)

| Layer | Technique | Catches | Status in `accrue_admin` |
|---|---|---|---|
| **Source lint (cheapest, deterministic)** | token-only guards: z-index, type, motion, Tailwind, inline-style, breakpoint, **+ new: spacing-literal, `:focus-visible`, `min-width:0`-with-ellipsis** | parallel-z-index, raw px/type/motion, utility leakage | ✅ most; 🆕 3 new guards proposed |
| **Component isolation lab** | **PhoenixStorybook** stories across the full state matrix (enabled/hover/focus/disabled/empty/selected × light/dark × viewport) | disabled-looks-enabled, tab/active, empty-state hover, stat-card drift, squished cells | 🆕 **adopted this milestone** (reverses v1.53 TOOL-01 deferral); replaces the `/dev/components` kitchen |
| **Accessibility automation** | **axe-core** over rendered stories/pages (color-contrast, name/role/value, focus order) — catches ~57% of WCAG issues automatically | composed contrast, missing names, focus | ⚠️ axe runs on host pages today; 🆕 extend to Storybook stories + composed pairings |
| **Visual regression** | snapshot diff per story in CI, required PR check | unintended visual drift, overlay/scroll layout shifts | 🆕 Storybook-backed visual snapshots are the natural v1.54 add |
| **Interaction E2E** | Playwright hit-tests: overlay-above-scrim, scroll-lock + no-jump, floating-in-bounds, conditional affordances, theme persistence/no-FOUC | every runtime/overlay/scroll/theme bug | ⚠️ Playwright exists for host; 🆕 add the interaction/overlay battery (Phase 199) |
| **Manual heuristics** | **NN/g 10 heuristics** + **GOV.UK** progressive-disclosure/IA + a per-page **rubric** (v1.53's 12-dim, extended with page-flow cells) | judgment defects no lint sees (breathing room, card-in-card, info-dump) | ✅ rubric machinery exists; extended in Phase 193/200 |

**Key principle (from the research and the repo's own posture):** *prevention via source-lint where mechanical; rendered-detection in CI where compositional.* The maintainer's bug list is dominated by **compositional** defects that **only a rendered state-matrix can catch** — hence PhoenixStorybook + axe + Playwright + the rubric are the real prevention surface, with three new cheap source guards mopping up the mechanical residue.

---

## Real user feedback on these exact frustrations (admin/dashboard tools)

- **"Tables everywhere / info-dump"** is the single most-cited dashboard sin: too many widgets/tables create clutter; users "struggle to scan relevant details"; "if every row looks the same, users scan inefficiently — status, action buttons, and important numbers should be visually distinct." ([databox bad-dashboards](https://databox.com/bad-dashboard-examples), [medium/shreya-roy](https://medium.com/@royshreya538/mastering-tables-in-dashboards-avoid-these-5-ux-mistakes-boost-usability-ae4eca569ae4)).
- **Cramped mobile / over-padding both hated:** "scaling down a full dashboard for mobile leads to cramped, unreadable content," while "too much white space and padding… forces the user to scroll too far." The fix is *deliberate density*, not max or min. ([raw.studio](https://raw.studio/blog/dashboard-design-disasters-6-ux-mistakes-you-cant-afford-to-make/), [excited.agency](https://excited.agency/blog/dashboard-ux-design)).
- **Over-design backfires:** "fancy gradients, glassmorphism, or overanimated transitions… lead to cluttered interfaces and poor UX. Poor contrast that makes content hard to read is another common issue." Validates the repo's quiet-polish brand + restrained-motion stance. ([raw.studio](https://raw.studio/blog/dashboard-design-disasters-6-ux-mistakes-you-cant-afford-to-make/)).
- **Disabled-button contrast is a known industry failure:** even Atlassian/Carbon/Lightning ship disabled buttons that fail WCAG — so "copy a big design system" is not a safe default here; the disabled treatment must be deliberately legible. ([medium/salim-ansari](https://medium.com/design-bootcamp/the-color-contrast-dilemma-of-disabled-buttons-in-accessible-design-59811fc89f62)).
- **Dark-mode pure-black/pure-white pain:** #fff-on-#000 "technically passes 21:1 but causes halation (glowing text) for users with astigmatism"; saturated colors "cause readability issues on dark backgrounds even when contrast passes." The repo's `#0f1318`/`#f4f7fa` + desaturated dark status hues already follow the off-white-on-dark-gray best practice. ([accessibilitychecker](https://www.accessibilitychecker.org/blog/dark-mode-accessibility/), [dubbot](https://dubbot.com/dubblog/2023/dark-mode-a11y.html)).
- **Modal-behind-overlay is a perennial, widely-reported bug** (Bootstrap modal-under-backdrop, Drupal stacked-dialog regression) — confirming it's a structural stacking-context failure, not a one-off. ([weblog.west-wind](https://weblog.west-wind.com/posts/2016/sep/14/bootstrap-modal-dialog-showing-under-modal-background/), [drupal #3037636](https://www.drupal.org/project/drupal/issues/3037636)).

---

## Summary: new acceptance criteria / guards for v1.54 (mapped to phases)

**New source guards (cheap, deterministic — extend the proven FND/MOT/CMP guard family):**
1. 🆕 **Spacing-literal guard** — ban raw px on `padding`/`margin`/`gap` in `app.css` outside an allowlist (mirror FND-01). *(→ Phase 193 foundation re-lock / 199.)*
2. 🆕 **`:focus-visible` guard** — focus styling must target `:focus-visible` (allow the `:focus:not(:focus-visible)` reset). *(→ 193/199.)*
3. 🆕 **Truncation-without-`min-width:0` guard** — flag `text-overflow: ellipsis` rules lacking `min-width:0`/`minmax(0,...)`. *(→ 196 list exemplar / 199.)*

**New rendered-detection (the real prevention surface for compositional bugs):**
4. 🆕 **PhoenixStorybook state-matrix stories** for every component family × (enabled/hover/focus/disabled/readonly/empty/selected) × light/dark × viewport — adopted this milestone. *(→ 193 stand-up, 194–198 per-archetype, 200 complete.)*
5. 🆕 **axe-core color-contrast + name/role pass over rendered stories** (composed pairings FND-05 can't see). *(→ 200.)*
6. 🆕 **Playwright interaction/overlay battery (Phase 199 IXN):** overlay-above-scrim hit-test; scroll-lock + no-gutter-jump + internal-scroll + overscroll-contain; floating-element-in-viewport-bounds; conditional-affordance (no zero-page pager, empty-state non-interactive); theme persistence + no-FOUC-first-paint + system-emulation. *(→ 199.)*
7. 🆕 **Fixture-stress (Phase 199 FIX):** multi-step workflows + long-content/edge fixtures to surface squish, clipping, and overflow on real data. *(→ 199.)*

**Already covered (no new work, keep green):** z-index tokenization + literal ban; type/motion/Tailwind/inline-style/breakpoint guards; semantic-token presence (≥3 scopes); FND-05 token-pair contrast; interactive `:hover`/`:active`/`:selected` consumption; tri-state theme structure + system media query + dark token sets; v1.53 FocusTrap + table→card degradation + per-page rubric/scorecard forward-only gate.

**Adversarial bottom line:** The repo's CI is strong on **token discipline** and weak — by construction — on **rendered composition**. Every remaining maintainer bug lives in composition. Do **not** try to lint taste; instead (a) add the 3 mechanical guards, and (b) invest the milestone's weight in the **rendered state-matrix (Storybook + axe + Playwright)** gated forward-only against the v1.53 baseline. That is where modal-behind-scrim, scroll traps, mispositioned floats, disabled-looks-enabled, empty-state hover, squished columns, and theme-flash actually get caught.

---

## Sources

**Stacking context / modals:** [freecodecamp — 4 reasons z-index isn't working](https://www.freecodecamp.org/news/4-reasons-your-z-index-isnt-working-and-how-to-fix-it-coder-coder-6bc05f103e6c/) · [playfulprogramming — CSS stacking contexts](https://playfulprogramming.com/posts/css-stacking-context/) · [west-wind — Bootstrap modal under backdrop](https://weblog.west-wind.com/posts/2016/sep/14/bootstrap-modal-dialog-showing-under-modal-background/) · [Drupal #3037636 — stacked dialog regression](https://www.drupal.org/project/drupal/issues/3037636)
**Scroll lock:** [jayfreestone — locking body scroll iOS](https://www.jayfreestone.com/writing/locking-body-scroll-ios/) · [css-tricks — prevent page scrolling](https://css-tricks.com/prevent-page-scrolling-when-a-modal-is-open/) · [pqina — iOS Safari 15 scroll](https://pqina.nl/blog/how-to-prevent-scrolling-the-page-on-ios-safari/) · [body-scroll-lock (reserveScrollBarGap)](https://github.com/willmcpo/body-scroll-lock)
**Flex/grid squish:** [css-tricks — flexbox truncated text](https://css-tricks.com/flexbox-truncated-text/) · [bigbinary — automatic min size of flex items](https://www.bigbinary.com/blog/understanding-the-automatic-minimum-size-of-flex-items/) · [css-tricks — preventing a grid blowout](https://css-tricks.com/preventing-a-grid-blowout/)
**Spacing systems:** [EightShapes — Space in Design Systems](https://medium.com/eightshapes-llc/space-in-design-systems-188bcbae0d62) · [Atlassian — spacing foundations](https://atlassian.design/foundations/spacing) · [Carbon — spacing](https://carbondesignsystem.com/elements/spacing/overview/) · [designsystems.com — space, grids, layouts](https://www.designsystems.com/space-grids-and-layouts/)
**Responsive tables:** [datatables — column priority](https://datatables.net/extensions/responsive/priority) · [uxpatterns.dev — data table pattern](https://uxpatterns.dev/patterns/data-display/table) · [uxmovement — best mobile layout for tables](https://uxmovement.medium.com/the-best-mobile-layout-for-complex-data-tables-e3ced21ce425) · [medium/shreya-roy — table UX mistakes](https://medium.com/@royshreya538/mastering-tables-in-dashboards-avoid-these-5-ux-mistakes-boost-usability-ae4eca569ae4)
**Theme switch / FOUC:** [Tailwind — dark mode](https://tailwindcss.com/docs/dark-mode) · [notanumber — fixing dark-mode flicker](https://www.notanumber.in/blog/fixing-react-dark-mode-flickering) · [simonporter — FOUC dark mode](https://www.simonporter.co.uk/posts/what-the-fouc-astro-transitions-and-tailwind/) · [nerdleveltech — Tailwind v4 dark mode](https://nerdleveltech.com/tailwind-v4-dark-mode)
**Dark-mode contrast:** [accessibilitychecker — dark mode accessibility](https://www.accessibilitychecker.org/blog/dark-mode-accessibility/) · [DubBot — dark mode a11y](https://dubbot.com/dubblog/2023/dark-mode-a11y.html) · [BOIA — dark mode ≠ WCAG contrast](https://www.boia.org/blog/offering-a-dark-mode-doesnt-satisfy-wcag-color-contrast-requirements)
**Disabled / focus:** [medium/salim-ansari — disabled button contrast dilemma](https://medium.com/design-bootcamp/the-color-contrast-dilemma-of-disabled-buttons-in-accessible-design-59811fc89f62) · [Sara Soueidan — accessible focus indicators](https://www.sarasoueidan.com/blog/focus-indicators/) · [WCAG 2.4.13 focus appearance](https://www.wcag.com/designers/2-4-13-focus-appearance/)
**Catch-before-ship:** [Storybook — visual testing](https://storybook.js.org/docs/writing-tests/visual-testing) · [Storybook — accessibility testing (axe-core, ~57% WCAG)](https://storybook.js.org/docs/writing-tests/accessibility-testing) · [Chromatic — visual testing for Storybook](https://www.chromatic.com/storybook)
**User-feedback / dashboard UX:** [raw.studio — dashboard design disasters](https://raw.studio/blog/dashboard-design-disasters-6-ux-mistakes-you-cant-afford-to-make/) · [databox — bad dashboard examples](https://databox.com/bad-dashboard-examples) · [excited.agency — dashboard UX](https://excited.agency/blog/dashboard-ux-design)
