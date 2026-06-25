# Architecture Research — v1.54 Micro-Animation & Interaction-Motion

**Domain:** Award-winning micro-animation & interaction-motion for dense Phoenix LiveView operator tooling (`accrue_admin`)
**Researched:** 2026-06-24
**Confidence:** HIGH (Emil Kowalski principles and overlay/scroll-lock failure modes both cross-checked against multiple primary sources; LiveView-specific application reasoned from HexDocs + first-hand reading of our own components)

> This file is the v1.54 motion/interaction design contract source. It **builds forward** from the existing 9-surface spec in `accrue_admin/guides/motion.md` and the token system in `accrue_admin/assets/css/theme.css`. It does **not** contradict them: every recommendation reuses existing `--ax-*` tokens unless a new token is explicitly justified. Downstream consumer: v1.54 `REQUIREMENTS.md` (IXN motion + overlay-correctness category) and per-phase UI design contracts.

---

## Executive Summary

The existing motion system is already well-architected: split duration/easing/travel atoms, property bundles that inherit a `prefers-reduced-motion` override "for free," CI guards banning `transition: all` / raw literals / layout-property animation, and an enter/exit asymmetry encoded in tokens. It is, by the standards of Emil Kowalski's published principles, **already mostly correct** — the duration band (120–240ms), composited-properties-only rule, the single earned overshoot, and the "no entry in the table = no animation" discipline are exactly his guidance.

The gap v1.54 must close is **not the token vocabulary — it is overlay/interaction correctness**. The maintainer's reported bugs (modal behind scrim / invisible modal, awkward scroll, floating/mispositioned elements covering content, won't-dismiss, hover on non-interactive empty-state heroes) are **structural overlay defects, not animation defects**. The strongest evidence: **there is no body scroll-lock anywhere in the codebase** (`grep` for `overflow: hidden` on body/html, `scroll-lock`, `position: fixed` body returns nothing). That single omission explains "awkward scroll" and a class of "floating in the wrong spot" reports. A second structural finding: the `detail_drawer` panel is hardcoded `inset: auto 0 0 0; min-height: 100vh; max-height: 100vh` — a full-viewport bottom sheet on **every** breakpoint, with `transform: translateX(--ax-rise-md)` enter motion that doesn't match a bottom-anchored sheet (translateX on a full-width bottom sheet is imperceptible/wrong-axis).

So the chosen direction is: **keep the token system almost entirely as-is, and spend v1.54's motion budget on a hardened, single, canonical overlay primitive** (layer model + portal-equivalent + body scroll-lock + focus + dismissal + origin-aware enter) that every modal/drawer/popover routes through, plus an enumerated set of micro-interaction corrections (hover-on-non-interactive, focus-ring, press, optimistic state) and one or two narrowly-justified new tokens.

---

## Part 1 — Emil Kowalski Principles (Extracted & Cited)

Source authority order: (1) his canonical article **"Great animations"** — <https://emilkowal.ski/ui/great-animations> (already cited in our `motion.md` as the antipattern basis); (2) his **Sonner** (toasts) and **Vaul** (drawer) open-source libraries and their published rationale; (3) his **"Animations on the Web"** course at <https://animations.dev/>; (4) his published **design-engineering skill** (<https://github.com/emilkowalski/skills>). Where a number comes only from a secondary digest of the course, it is tagged MEDIUM.

| # | Principle (Kowalski) | Citable phrasing / number | Our current state |
|---|----------------------|---------------------------|-------------------|
| K1 | **Sub-300ms.** "Your animations should also usually be shorter than 300ms." | <https://emilkowal.ski/ui/great-animations> (HIGH) | ✅ Band is 120–240ms; exit 140ms. Already compliant. |
| K2 | **ease-out for enters.** "The best type of easing… is `ease-out` [because it] starts fast and slows down at the end, which gives the impression of a quick response." | great-animations (HIGH) | ✅ `--ax-ease-out` is the default enter curve. |
| K3 | **ease / ease-in-out for *moving* existing elements**, not entering ones; ease (symmetric) reads more "elegant" and is used deliberately slightly slower (Sonner toasts). | great-animations + Sonner rationale (MEDIUM) | ⚠️ We have `--ax-ease-inout` but restrict it to skeleton shimmer only. See R-7 (tabs indicator / position moves). |
| K4 | **Composite-only properties.** Animate `transform` + `opacity`; they "only trigger the third rendering step (composite)." Avoid `padding`/`margin`/layout. | great-animations (HIGH) | ✅ Encoded as antipattern A2 + CI guard. |
| K5 | **Hardware-accelerated stays smooth under main-thread load.** Prefer CSS/WAAPI; "A hardware-accelerated animation will remain smooth, no matter how busy the main thread is." | great-animations (HIGH) | ✅ All motion is CSS/`JS.show` transition classes; no JS rAF loops. |
| K6 | **Purpose over decoration.** "It's easy to start adding animations everywhere. The user then becomes overwhelmed and animations lose their impact." Decide *whether* before *how*. | great-animations + skill meta-rule (HIGH) | ✅ "no table entry = no animation" (A8). |
| K7 | **Never animate keyboard-initiated actions.** "A good tip here is to never animate keyboard initiated actions." | great-animations (HIGH) | ✅ Antipattern A7 (Cmd-K, tab nav stay fast). |
| K8 | **Interruptibility.** Animations "must allow users to change the state… at any time while maintaining a smooth transition." CSS transitions get this naturally; keyframes/JS must retarget. | great-animations (HIGH) | ⚠️ We use `JS.show/hide` with fixed `time:`. Re-opening mid-exit can double-fire. See R-2 / footgun F8. |
| K9 | **Never scale from zero.** Start from `scale(0.96)`/`0.9`, not `scale(0)` — "starting from nothing looks cheap; start nearly there." | course digest + skill ref (MEDIUM, corroborated 2 sources) | ✅ Palette uses `scale(0.98)→1`; badge uses `--ax-press-scale 0.97→1`. Already compliant. |
| K10 | **Origin-aware transforms.** Modals are viewport-centered → `transform-origin: center`, scale+opacity (no directional travel). Dropdowns/popovers belong to a trigger → `transform-origin` toward the trigger (e.g. `top center`), small directional rise. Sheets → bottom-oriented. | search synthesis of his modal/dropdown patterns (MEDIUM, 2 sources) | ⚠️ **Gap.** Our drawer enter uses `translateX` regardless of anchor; dropdowns use a generic `translateY` rise but `transform-origin` is not set toward the trigger. See R-3, R-4. |
| K11 | **Interaction-frequency framework.** Rare actions → can be delightful/morphing; occasional → subtle/fast (180–250ms); frequent → little or no animation; keyboard → none. | skill ref (MEDIUM) | ✅ Matches our A5/A7 posture; formalize as acceptance lens (R-12). |
| K12 | **Enter gentle / exit snappy asymmetry.** Enter may carry travel/scale on ease-out; exit is faster and typically fade-only ("an element leaving does not need to narrate where it goes"). Sonner/Vaul exits are quicker than enters. | great-animations + Vaul/Sonner (HIGH) | ✅ Already encoded (D-16: `--ax-dur-exit` 140ms, fade-only). |
| K13 | **Cohesion.** Easing/duration/feel must match the product's vibe; Sonner "feels satisfying… partly because the whole experience is cohesive… the easing and duration fit the vibe." | Sonner rationale (HIGH) | ✅ Our "quiet, well-made dev tooling" brand → restrained curves. Keep overshoot rationed to one surface. |
| K14 | **Toast specifics (Sonner).** Default visible duration ~4000ms; stack with slight scale/offset on background toasts; **swipe/velocity-based dismissal** (velocity threshold ~0.11, not pure distance); slightly slower + `ease` (not ease-out) to read elegant. | Sonner source/digest (MEDIUM) | ⚠️ Our toasts (`flash_group`) enter/exit are tokenized but **non-stacking, no swipe**. v1.54 scope decision in R-9. |
| K15 | **Reduced-motion is mandatory.** "Animations can make people feel sick or get distracted." Gate via `@media (prefers-reduced-motion: reduce)`. | great-animations (HIGH) | ✅ Bundle override in `theme.css:414`. Best-in-class already. |

**Adversarial note on Emil's numbers:** Vaul's drawer and Sonner's toast use **~500ms** and **ease** — *longer and softer* than our 240ms ceiling. That is a real tension. Resolution: those are **consumer-product, low-frequency, single-instance** surfaces (a phone-style bottom sheet, a celebratory toast). `accrue_admin` is **dense, high-frequency operator tooling** where K11 says "occasional/frequent → 180–250ms or none." Our 240ms ceiling is the *correct* localization of his framework for our context, not a violation of it. **Do not raise the duration ceiling to match Vaul.** (This is the chosen, adversarially-defended position.)

---

## Part 2 — Overlay Motion DONE RIGHT (the maintainer's bug class)

This is where v1.54's motion budget should go. Each reported failure mode is mapped to a root cause and a fix that reuses our tokens and z-scale.

### 2.1 The canonical layer / stacking model

We already have a tokenized z-scale (`theme.css:128`): `--ax-z-base 0 · sticky 100 · dropdown 200 · popover 300 · drawer 400 · modal 500 · toast 600`. Both overlay shells correctly use `position: fixed; inset: 0; isolation: isolate` and place backdrop at local `z-index:0`, panel at local `z-index:1` inside the isolated stacking context. **This part is right** — keep it. The `isolation: isolate` micro-stack is the correct pattern (it prevents backdrop/panel z-fighting and means raising the shell never requires touching internal z-values).

```
┌─ document body (NOT scroll-locked today — BUG) ───────────────┐
│  app chrome (sidebar --ax-z-sticky 100, topbar)               │
│                                                                │
│  ┌─ overlay shell  position:fixed inset:0  isolation:isolate ─┐│
│  │  z-index: --ax-z-modal(500) / --ax-z-drawer(400)           ││
│  │  ┌─ backdrop  position:absolute inset:0  local z:0 ───────┐ ││
│  │  │  bg color-mix(ink 40%) + backdrop-filter blur(6px)     │ ││
│  │  │  click → dismiss event                                 │ ││
│  │  └────────────────────────────────────────────────────────┘ ││
│  │  ┌─ panel  local z:1  (focus-trapped, role=dialog) ──────┐ ││
│  │  │  modal: place-items:center, scale 0.98→1 + opacity    │ ││
│  │  │  drawer: edge-anchored, translate on anchored axis     │ ││
│  │  └────────────────────────────────────────────────────────┘ ││
│  └────────────────────────────────────────────────────────────┘│
└────────────────────────────────────────────────────────────────┘
```

**Why "modal behind scrim / invisible modal" happens (root causes & fixes):**

| Symptom | Most likely root cause in our code/CSS | Fix (reuses tokens) |
|---------|----------------------------------------|---------------------|
| Whole screen dark, panel invisible/uninteractable | Panel and backdrop **siblings** with the panel painted *before* the backdrop in DOM order, OR the panel lacks a stacking context so the backdrop (later sibling or higher local z) paints over it. Also: a parent of the shell has its own `transform`/`filter`/`isolation` creating a stacking context that **traps** the `position:fixed` shell inside a clipped/lower ancestor — classic "fixed element is not actually viewport-fixed." | Our shells already order backdrop-before-panel and isolate. **The real risk is ancestor stacking contexts**: any LiveView page wrapper with `transform`, `filter`, `will-change`, `contain`, or `backdrop-filter` will re-root our `position:fixed` shell. **Acceptance criterion: overlay shells must be portalled to a body-level container** (LiveView: render the dialog as a sibling of `<main>` via a dedicated `#ax-overlay-root` slot, or assert no transformed ancestor). Add a CI/dev guard. |
| Modal floats in a weird spot / mispositioned | Same ancestor-stacking-context bug repositions a `position:fixed` element relative to the transformed ancestor, not the viewport. Or `place-items:center` shell sized by a clipped ancestor. | Portal to body-level root (above). For drawer: the current `min-height:100vh` sheet on desktop is wrong — it should be an **edge-docked panel** (`inset: 0 0 0 auto; width: min(...)`) on ≥ tablet, full-sheet only on mobile. See R-3. |
| Won't dismiss / dismiss leaves ghost | Exit transition (`JS.hide time:140`) races a re-render that re-adds the element; or backdrop click target is covered by the panel; or Escape handled but close event has no `phx-target`. | Single dismissal contract: backdrop click + Escape both dispatch the **same** close event through FocusTrap (`data-focus-trap-close-event`). Ensure exit class set is idempotent (interruptibility, K8). See R-2. |
| Background scrolls / "awkward scroll" | **No body scroll-lock exists.** Wheel/touch over the backdrop scrolls the page behind. On iOS the page also rubber-bands. | **Add body scroll-lock (R-1).** This is the single highest-value fix in the milestone. |
| Hover/focus oddities on overlay | Background interactive elements remain in tab order and hoverable behind the scrim (backdrop doesn't `pointer-events` block consistently; focus trap covers keyboard but not pointer hover tooltips on background). | Backdrop must be a real pointer-events surface across the full viewport (it is `inset:0` — good); additionally set `inert` / `aria-hidden` on the background root while an overlay is open. See R-5. |

### 2.2 Body scroll-lock — the missing primitive (R-1, highest priority)

**Finding:** no scroll-lock in the repo. This is the root cause of "awkward scroll" and contributes to mispositioned/floating reports.

**Recommended pattern (cross-checked against jayfreestone, Ben Frain, CSS-Tricks, and the iOS Safari writeup):**

- **Desktop / non-iOS:** `overflow: hidden` on `<html>` (or a `data-ax-scroll-locked` attribute) while any overlay is open. Compensate for scrollbar-gutter shift with `scrollbar-gutter: stable` on the scroll container (or pad by measured scrollbar width) so the page doesn't jump when the bar disappears.
- **iOS Safari:** `overflow:hidden` is insufficient. The robust, everywhere-working approach is **`position: fixed` on the body with `top: -<savedScrollY>px`**, restoring scroll on close. Trade-off: it resets/relayouts; mitigate by saving and restoring `scrollY`. Pair with `overscroll-behavior: none` on the scroll container and the overlay body to kill rubber-band/scroll-chaining. (Sources: <https://www.jayfreestone.com/writing/locking-body-scroll-ios/>, <https://benfrain.com/preventing-body-scroll-for-modals-in-ios/>, <https://css-tricks.com/prevent-page-scrolling-when-a-modal-is-open/>, <https://stripearmy.medium.com/i-fixed-a-decade-long-ios-safari-problem-0d85f76caec0>.)

**Implementation shape (LiveView-friendly, ref-counted):** a small `ScrollLock` JS hook (or extend `FocusTrap`) that, on activate, records `window.scrollY`, locks the body, and on deactivate restores. **Must be ref-counted** (a counter of open overlays) so a modal-over-drawer doesn't unlock prematurely. The overlay scrollable region (`.ax-detail-drawer-body`, `.ax-step-up-modal`) keeps its own `overflow:auto` with `overscroll-behavior: contain` so its inner scroll doesn't chain to the locked body.

**Token impact:** none. **New asset:** one hook + one `[data-ax-scroll-locked]` CSS rule. This is the central new mechanism of the milestone.

### 2.3 Focus, dismissal, and timing

Our `FocusTrap` hook (`assets/js/hooks/focus_trap.js`) is already strong: focus containment, Tab cycling, Escape → close event, `focusin` guard, restore-focus on deactivate, initial-focus targeting, fallback chain. **Keep it.** Refinements for v1.54:

- **R-2 (interruptibility, K8):** `scheduleInitialFocus` uses `setTimeout(…, 0)`. With `JS.show` enter transitions running 240ms, focusing at t=0 is fine for a11y but the panel is still animating in. Acceptable. The real interruptibility risk is the **enter/exit class race**: if `@open` toggles faster than `--ax-dur-3`, `JS.show`/`JS.hide` can leave stale `*-entering`/`*-leaving` classes. Acceptance: rapid open→close→open must settle to the correct end state (add an e2e "double-toggle" assertion). Prefer driving open/close purely off the `:if={@open}` mount/remove + `phx-mounted`/`phx-remove` (as drawer does) rather than imperative `JS.show` on an always-present node.
- **R-5 (background inert):** while an overlay is open, set `inert` on the main app root (`#ax-overlay-root` sibling pattern), not just focus-trap. `inert` removes background from tab order, click, and hover/tooltip — fixing "weird hover states behind the modal." Reduced-motion-independent; pure correctness.
- **Focus-restore is already correct** (restores `previouslyFocused`, falls back to a heading) — this prevents the "focus jumps to top of page after close" jank.

### 2.4 Origin-aware enter motion (R-3 drawer, R-4 dropdown)

- **R-3 — Drawer axis/anchor fix.** Current: full-viewport bottom sheet on all breakpoints, enter = `translateX(--ax-rise-md)`. translateX on a full-width sheet is the wrong axis and barely visible. **Fix:** make the drawer genuinely edge-docked on ≥ `--ax-bp-md` (`inset: 0 0 0 auto; width: min(34rem, 92vw)`) entering with `translateX` from the right edge (now meaningful), and a **bottom sheet on mobile** entering with `translateY`. Two enter-class sets, same tokens (`--ax-dur-3`, `--ax-ease-out`, `--ax-rise-md` for the small settle; the large off-screen offset is the panel's own width/height, not a token). This directly fixes "drawer covers content / floats wrong" on desktop and matches K10 (origin-aware: a side panel slides from its edge).
- **R-4 — Dropdown/popover transform-origin.** Set `transform-origin` toward the trigger (`top center` for below-trigger menus, `bottom center` for above) so the small `--ax-rise-sm` scale/translate reads as "belonging to" the trigger (K10). Keep `--ax-rise-sm` + opacity + `--ax-dur-2`. No new tokens — just add the `transform-origin` declaration to `.ax-dropdown-panel` / `.ax-command-palette` / overflow menu.
- **Command palette** already does `scale(0.98)→1` with `--ax-ease-emphasis` (the one earned overshoot) and `transform-origin` should be `center top` (it descends from the top). Confirm origin; keep the overshoot rationed to this one surface.

---

## Part 3 — List / Table / Page-Transition Motion

Context: tables and list pages are LiveView, often `phx-update="stream"`; page-to-page is link nav between LiveViews (full nav, not SPA client routing).

| Topic | Recommendation | Tokens | Confidence |
|-------|----------------|--------|------------|
| **Skeleton → content** | Already correct (surface #8): content crossfades in via `opacity --ax-dur-2 --ax-ease-out` where the skeleton was; shimmer is the only sanctioned loop. Keep. | `--ax-dur-2`, `--ax-ease-out` | HIGH |
| **Stagger** | **Reject general stagger.** Staggered row entrance on a 50-row operator table is decorative (A8), slow, and fights K11 (frequent surface). Allowed only as a *single* crossfade of the whole table body, not per-row. | — | HIGH |
| **Stream re-render without jank/focus loss** | LiveView `phx-update="stream"` patches via morphdom; JS-applied classes (`JS.show/hide`) are patch-aware and stick. **Footgun:** animating a row that gets re-keyed on patch causes flicker. Rule: animate **container** crossfade on first load only; on incremental stream inserts, use a brief `opacity`/`background` flash on the **new row** via `--ax-transition-colors` (state-change grammar, surface #9), never a height/translate that shifts the list. Focus loss: don't animate the focused row; rely on LiveView's DOM-patch focus preservation. | `--ax-transition-colors`, `--ax-dur-2` | MEDIUM |
| **View Transitions API** | **Applicable but scope-gated.** LiveView 1.1.18+ exposes the `onDocumentPatch` DOM callback; you can wrap patches in `document.startViewTransition()` (Chrome 126+, Safari 18.2+ for cross-doc). For v1.54 **defer same-document VT for streams** (high complexity, easy to introduce jank/focus issues) and consider only a **conservative cross-document fade** on full LiveView navigations, gated behind `@media (prefers-reduced-motion: no-preference)`. Default: **do not adopt VT in v1.54**; record as a candidate. Adversarial reason: our nav is already fast; VT adds a snapshot cost and a new failure surface for marginal polish on a tool. | (VT default fade; no new `--ax-*` token) | MEDIUM |

Sources: <https://hexdocs.pm/phoenix_live_view/syncing-changes.html>, <https://elixirmerge.com/p/integrating-view-transitions-api-with-phoenix-liveview>, <https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API>, <https://css-tricks.com/cross-document-view-transitions-part-1/>.

---

## Part 4 — Micro-interactions: "premium/Apple-like" vs gimmicky

**Motion HELPS when** it provides: *continuity* (an element moves from A to B so you track it), *affordance* (a panel rises from its trigger so you know they're related), or *feedback* (a press scale / state flash confirms your action registered). **Motion HURTS when** it adds *latency* to a frequent path, *distracts* from data, or triggers *vestibular* discomfort (large travel, parallax, spin).

| Interaction | Premium pattern (keep/adopt) | Gimmicky / reject | Tokens |
|-------------|------------------------------|-------------------|--------|
| **Hover** | Color/elevation change via `--ax-transition-colors` / `--ax-transition-shadow` at `--ax-dur-1`/`--ax-dur-2`. Only on genuinely interactive elements. | Hover lift/scale on cards; **hover states on non-interactive empty-state heroes (reported bug)** — see R-6. | `--ax-transition-colors`, `--ax-dur-1` |
| **Press** | `--ax-press-scale` (0.97) on `:active`, instant feel at `--ax-dur-1`. K9-compliant (never from 0). | Ripples, long bouncy press. | `--ax-press-scale`, `--ax-dur-1` |
| **Focus ring** | **Instant, non-animated** focus ring (offset outline). Animating focus rings is a keyboard-frequent action → K7 says never. Ensure ring is visible in light/dark and on the panel's initial-focus target. | Animated/growing focus glow. | none (no transition on `outline`) |
| **State change** | Surface #9 grammar: color/bg/border crossfade via `--ax-transition-colors`; first-appear single pop via `--ax-press-scale→1`. | Pulsing/looping attention badges (A4). | `--ax-transition-colors`, optional `--ax-ease-emphasis` |
| **Optimistic UI** | LiveView: apply the optimistic class via `JS` immediately on submit (button → pending/`aria-busy`, `--ax-press-scale`), reconcile on server patch. Use `phx-disable-with` + a non-looping inline spinner only during genuine in-flight fetch. | Optimistic full-row re-animation that then "corrects" on server reply (jarring). | `--ax-transition-colors`; `.ax-spinner` (sanctioned loop, active fetch only) |

**R-6 — Non-interactive hover bug.** Empty-state heroes and static cards must not carry `:hover` style or `cursor: pointer`. Acceptance: only elements with a role/handler (`a`, `button`, `[phx-click]`, `[role=button]`) may define hover/active motion. Add a dev/CI lint or a state-matrix check in the `/dev/components` (soon PhoenixStorybook) gallery asserting empty-state specimens have no hover delta.

**Reduced-motion correctness (already best-in-class — preserve, don't regress):** the `theme.css:414` block zeroes travel/overshoot/press-scale and collapses bundles to `--ax-dur-instant` while **retaining opacity crossfades** — exactly K15. Every new surface in v1.54 **must** route through `--ax-transition-*` bundles or the `--ax-dur-*`/`--ax-ease-*` atoms so it inherits this for free. **No `matchMedia` in JS** (the token override is the single source of truth). The new ScrollLock hook is non-motion and therefore reduced-motion-neutral.

---

## Part 5 — Anti-patterns & Footguns (enumerated)

Extends `motion.md`'s A1–A8 with interaction-specific footguns surfaced by this research:

| ID | Footgun | Rule |
|----|---------|------|
| F1 | **No body scroll-lock** (current state) | Overlays MUST lock body scroll (R-1), ref-counted, iOS-safe. |
| F2 | **`position:fixed` overlay inside a transformed/filtered/`contain` ancestor** | Overlays MUST be portalled to a body-level root; no transformed ancestor may wrap a dialog shell. (Root cause of invisible/mispositioned modal.) |
| F3 | **Hover/cursor on non-interactive elements** (reported) | Only interactive roles get hover/press motion (R-6). |
| F4 | **Animating focus rings / keyboard actions** | K7 — focus ring instant; Cmd-K/tab nav stay fast (A7). |
| F5 | **Wrong-axis enter** (translateX on a bottom sheet) | Enter axis must match the panel's anchored edge (R-3, K10). |
| F6 | **Stagger / per-row entrance on dense tables** | Banned; whole-body crossfade only (Part 3). |
| F7 | **Durations chasing Vaul/Sonner (500ms)** | Keep our 120–240ms band; those are low-frequency consumer surfaces, K11 localizes them down for operator tooling. |
| F8 | **Non-interruptible open/close** (stale enter/exit classes on rapid toggle) | Open/close must settle correctly under double-toggle (R-2, K8). |
| F9 | **Background remains hover/tab-reachable behind scrim** | Set `inert`/`aria-hidden` on background while overlay open (R-5). |
| F10 | **Scroll chaining from inner overlay scroll to page** | `overscroll-behavior: contain` on overlay scroll regions; `none` on locked body. |
| F11 | **Looping/pulsing attention badges** | A4 — state-change is a single transition, never a loop. |
| F12 | **Scrollbar-gutter jump on lock** | `scrollbar-gutter: stable` or width compensation so locking doesn't shift layout. |

---

## Part 6 — Chosen Direction (adversarially defended) & Token Decisions

**Direction:** *Keep the token vocabulary; invest in one hardened overlay primitive + enumerated micro-interaction corrections.* The animation system is already Kowalski-aligned; the wins are structural correctness, not new curves.

**Token reuse vs. new tokens:**

| Need | Decision | Justification |
|------|----------|---------------|
| Modal/drawer enter/exit, dropdown, toast, palette, badge, press, hover, state-change | **Reuse existing tokens** (`--ax-dur-1/2/3/exit`, `--ax-ease-out/in/inout/emphasis`, `--ax-rise-sm/md`, `--ax-press-scale`, `--ax-transition-*`) | Full coverage already; adding tokens would dilute the disciplined vocabulary. |
| Drawer off-screen start offset (right-dock & bottom-sheet) | **No new token** — use the panel's own width/height (`translateX(100%)`/`translateY(100%)`) as the off-screen origin; `--ax-rise-md` is the small final settle if any | Off-screen distance is structural (panel size), not a motion atom. |
| `transform-origin` for dropdown/popover/palette | **No new token** — plain CSS declaration per surface | Origin is positional, not a reusable scalar. |
| Body scroll-lock | **No new motion token**; one `[data-ax-scroll-locked]` rule + `ScrollLock` hook (ref-counted) + `overscroll-behavior` | Non-motion correctness primitive. |
| Background `inert` while overlay open | **No token**; attribute toggle in FocusTrap/overlay hook | Correctness. |
| **Candidate new token (only if needed):** a slightly longer drawer-on-mobile sheet duration | **Hold / do NOT add by default.** Only add `--ax-dur-sheet` if mobile-sheet UAT shows 240ms feels abrupt for the larger travel. Must be ≤ 300ms (K1) and justified in `motion.md`. | Respects K11; avoids speculative tokens. The CI guard already forces any new duration to be a token, so this stays honest. |

**`motion.md` updates required (forward-only):** add R-3 drawer axis/anchor rows (desktop right-dock vs mobile sheet) replacing the single translateX row; add the body-scroll-lock + `inert` background as non-motion correctness requirements referenced from the overlay surfaces; add `transform-origin` notes to dropdown/palette rows; keep all A1–A8 guards; extend the antipattern list with F1–F12 cross-references. **Do not weaken** any existing guard or the reduced-motion block.

---

## Acceptance Criteria (feed v1.54 REQUIREMENTS — IXN/overlay category)

1. **Scroll-lock:** opening any overlay locks body scroll (ref-counted, restores exact scroll position); verified on desktop + iOS Safari; inner overlay scroll works with `overscroll-behavior: contain`; no scrollbar-gutter layout jump. (R-1, F1, F10, F12)
2. **Portal/stacking:** every dialog/drawer renders at a body-level overlay root; no transformed/filtered ancestor wraps a shell; modal is never painted behind its scrim; panel always visible and interactive. (F2)
3. **Dismissal:** backdrop click + Escape both dismiss via the same close event; double-toggle (open→close→open faster than enter duration) settles to the correct end state with no ghost/stale classes. (R-2, K8, F8)
4. **Background isolation:** while an overlay is open the background is `inert`/`aria-hidden` — not hoverable, clickable, or tab-reachable. (R-5, F9)
5. **Drawer anchoring:** desktop = edge-docked right panel entering on translateX from its edge; mobile = bottom sheet entering on translateY; neither covers content in the wrong spot. (R-3, K10, F5)
6. **Origin-aware popovers:** dropdown/overflow/palette set `transform-origin` toward their trigger; rise/scale reads as belonging to the trigger. (R-4, K10)
7. **No hover on non-interactive:** empty-state heroes/static cards have no hover/active delta and no `cursor:pointer`. (R-6, F3)
8. **Focus correctness:** focus moves into the panel on open (initial-focus target), is trapped, and restores to the invoker on close; focus rings are instant (un-animated). (FocusTrap, K7, F4)
9. **Duration band held:** all enter ≤ 240ms, exit 140ms; no surface raised to Vaul/Sonner durations. (K1, K11, F7)
10. **Reduced-motion preserved:** every new surface routes through `--ax-transition-*`/atoms; `prefers-reduced-motion` zeroes travel/overshoot/press-scale while keeping opacity crossfades; no JS `matchMedia`. Existing Playwright `reduced-motion.spec.js` extended to cover new overlay surfaces. (K15)
11. **No new motion tokens** unless justified in `motion.md` and ≤300ms; the existing CI guards (`verify_package_docs.sh`: ban `transition: all`, raw `cubic-bezier`/`ms`/`s`, layout-property animation) stay green.
12. **List/stream motion:** table first-load crossfade only (no per-row stagger); new stream rows flash via `--ax-transition-colors`, no height/translate list shift; focused row not animated. (Part 3, F6)

---

## Confidence & Gaps

| Area | Confidence | Notes |
|------|------------|-------|
| Emil Kowalski enter/easing/duration/composite/interruptible/reduced-motion principles | HIGH | Multiple primary sources incl. his own article cited in our `motion.md`. |
| Emil's exact course numbers (velocity 0.11, 500ms Vaul, origin values) | MEDIUM | From course digests / skill refs; directionally reliable, exact constants secondary. Treat as guidance, not law. |
| Overlay failure-mode root causes (scroll-lock, transformed-ancestor, inert) | HIGH | Cross-checked across jayfreestone/Ben Frain/CSS-Tricks/Stripe-army + first-hand reading of our components (no scroll-lock confirmed by grep; drawer geometry confirmed in `app.css:1332`). |
| LiveView stream + View Transitions applicability | MEDIUM | HexDocs confirms `onDocumentPatch` (1.1.18+) and patch-aware JS; VT-on-streams deliberately deferred — needs a spike if pursued. |
| Whether to add `--ax-dur-sheet` | LOW (deliberately deferred) | Decide from mobile-sheet UAT, not up front. |

**Open questions for phase design:** (a) Is `inert` acceptable given our supported browser floor, or do we need an `aria-hidden` + focusguard fallback? (b) Should ScrollLock be a standalone hook or folded into FocusTrap (ref-counting argues standalone)? (c) Confirm no LiveView page wrapper applies `transform`/`filter`/`contain` that would re-root `position:fixed` shells (audit during Phase 199).

---

## Sources

- Emil Kowalski — "Great animations": <https://emilkowal.ski/ui/great-animations>
- Emil Kowalski — site / course hub: <https://emilkowal.ski/> · <https://animations.dev/>
- Emil Kowalski — design-engineering skill (canonical phrasings): <https://github.com/emilkowalski/skills/blob/main/skills/emil-design-eng/SKILL.md>
- Emil Kowalski principles digest (durations, easing, origin, scale-not-zero): <https://github.com/leadgenjay/claude-skills/blob/main/skills/design-motion-principles/references/emil-kowalski.md>
- Vaul (drawer) and Sonner (toast) — Emil Kowalski libraries: <https://vaul.emilkowal.ski/>
- iOS body scroll-lock: <https://www.jayfreestone.com/writing/locking-body-scroll-ios/> · <https://benfrain.com/preventing-body-scroll-for-modals-in-ios/> · <https://css-tricks.com/prevent-page-scrolling-when-a-modal-is-open/> · <https://stripearmy.medium.com/i-fixed-a-decade-long-ios-safari-problem-0d85f76caec0>
- View Transitions API: <https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API> · <https://css-tricks.com/cross-document-view-transitions-part-1/>
- LiveView + View Transitions / syncing changes: <https://elixirmerge.com/p/integrating-view-transitions-api-with-phoenix-liveview> · <https://hexdocs.pm/phoenix_live_view/syncing-changes.html>
- First-hand: `accrue_admin/guides/motion.md`, `accrue_admin/assets/css/theme.css` (lines 53–135, 414–438), `accrue_admin/assets/css/app.css` (lines 1332–1491), `accrue_admin/assets/js/hooks/focus_trap.js`, `accrue_admin/lib/accrue_admin/components/detail_drawer.ex`, `step_up_auth_modal.ex` (verified 2026-06-24, HIGH confidence — no body scroll-lock present in repo).
