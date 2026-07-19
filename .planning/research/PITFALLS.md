# Pitfalls Research

**Domain:** Admin/operator UI reign-in + information-architecture pivot on live pages (`accrue_admin`, v1.57 SEED-004 M1)
**Researched:** 2026-07-19
**Confidence:** HIGH (grounded in the actual `accrue_admin` source, tests, e2e specs, and committed CSS bundle; each pitfall names the concrete file/line evidence)

## Scope reminder (what M1 is / isn't)

M1 = **admin-only** IA/grammar pivot that reigns **Home** (`dashboard_live.ex`) and **Subscriptions** (`subscriptions_live.ex` + `subscription_live.ex`) onto the shared component vocabulary (PageHeader / StatStrip / DataTable / FilterChipBar / `.ax-card` / Button / StatusBadge / EmptyState), retiring the bespoke `ax-home-*` / `ax-launcher*` / `ax-attention*` / `ax-subscriptions-*` / `ax-inline-worklist*` sets (~284 rules measured; ~325 estimated in PROJECT.md). No core `accrue`, no `accrue_portal`, no M2/M3 surfaces. `ax-*` stays the styling SSOT; keep Cobalt/quiet-confidence brand + the density of an operator console. The pitfalls below are the ways this specific job goes wrong.

---

## Critical Pitfalls

### Pitfall 1: Over-airy-ing the console (breaking operator density by inheriting list-page spacing wholesale)

**What goes wrong:**
The reigned Home and Subscriptions pages adopt the shared components at their *default* (comfortable) spacing and end up looking like an airy marketing list instead of a dense operator worklist. The rest of the admin reads as "calm, exact, dense" (blueprint §1, §42); the two reigned pages drift lighter, so cohesion is *lost* even though the components are now "shared."

**Why it happens:**
The bespoke sets encode density deliberately — `subscriptions_live.ex` uses `ax-page-compact`, `ax-page-header-compact`, and packs ~60 row classes (`ax-subscription-row-meta-grid`, `ax-subscription-row-signal-*`, `ax-subscriptions-invoice-strip`) at tight `--ax-space-2xs/xs` gaps. Shared `StatStrip`/`DataTable`/`PageHeader` default to roomier `--ax-space-md/lg`. "Compose, don't fork" (the milestone rule) is right, but composing at defaults silently trades density away. Whitespace also *feels* like "design," so the drift is toward more air — exactly the tension the blueprint (§4 cons) and the ratchet's "operator-density-defender" both warn about.

**How to avoid:**
- Treat density as an explicit acceptance criterion, not an aesthetic afterthought. Before/after PNG-compare the reigned pages against the canonical Payments/Customers/Invoices reference (already the milestone's stated verification method) *and* against the *pre-reign* screenshot — row height, rows-per-viewport, and header band height must not regress.
- Reuse the compact modifiers that already exist (`ax-page-compact`, `ax-page-header-compact`, `--ax-space-2xs`) when composing shared components; if a shared component has no compact mode, add a compact variant to the *shared* component rather than a bespoke wrapper.
- Keep tabular figures / tight leading (`--ax-leading-tight`) on numeric columns — the source already sets `font-variant-numeric` globally; don't let a shared cell idiom drop it.

**Warning signs:**
Fewer subscription rows visible per screen than before; StatStrip taller than the old `ax-subscriptions-kpi-row`; a reviewer says it "looks cleaner" while an operator says "I can see less."

**Phase to address:** The Home-reign phase and the Subscriptions-reign phase each own their own density gate; the milestone SPEC/discuss phase should lock "no density regression vs pre-reign baseline" as a written requirement so both phases inherit it.

---

### Pitfall 2: IA over-reach — drifting into M2/M3 scope while pivoting the IA

**What goes wrong:**
"Improve the information architecture" is an open-ended invitation. Mid-reign, it's tempting to add the signature "Why blocked?" diagnosis card, a causality graph, a unified billing-state verdict, or stub a new Usage/checkout/fee-reconciliation room "while we're in here." All of those are explicitly **M2/M3** (blueprint §7, synthesis §9). M2 also reaches into core `accrue` (`blocking_reason_for_owner/1`, `billing_state_for_customer/1`, `causality_chain_for_event/1`) — a scope-*class* change (admin-only → admin + core) the milestone forbids.

**Why it happens:**
The 23 round-99 ratchet-confirmed findings that drive M1 are IA findings, and the north-star blueprint is exhaustive and enticing. The line between "one scannable health verdict per zone" (in scope) and "a diagnostic verdict synthesizing entitlement+webhook+payment state" (M2) is blurry unless someone holds it. A "health answer" string that starts summarizing *why* a subscription is blocked has quietly become the M2 diagnosis surface.

**How to avoid:**
- Hard-gate on: no new core `accrue` functions, no new nav rooms (Usage/Settings/checkout/fee-recon), no causality/timeline visualization, no cross-object diagnosis synthesis. If a plan touches `accrue/lib`, it is out of M1 by construction.
- M1's "health verdict" is a *re-presentation of state already rendered on the page today* (e.g. the existing `ax-detail-health-verdict` / `ax-home-health-answer` content), reigned onto shared grammar — not a new computed diagnosis.
- Keep the one-small-new-shared-component budget honored: exactly one new shared component allowed, and only if a work-queue "callout" shape clearly repeats. A "diagnosis card" is not that component.

**Warning signs:**
A plan proposes editing `accrue/lib/...`; a new route/nav entry appears; a task description contains "why blocked," "causality," "usage room," or "unified billing state"; the one-new-component budget is spent on something diagnostic; requirement count creeping past the Home+Subscriptions reign.

**Phase to address:** Owned at the SPEC/discuss/roadmap-shaping level (scope fence written once, enforced per phase). The plan-review/convergence gate should reject any plan that imports M2/M3 surfaces.

---

### Pitfall 3: Losing operator content while "trimming redundant bands"

**What goes wrong:**
The IA pivot calls for trimming "redundant/duplicate bands." Under time pressure, real operator data gets deleted as if it were redundant. `subscriptions_live.ex` carries dense, load-bearing signals — `ax-subscriptions-at-risk-strip`, `ax-subscriptions-exposure`, `ax-subscriptions-invoice-records`, `ax-webhook-row-status-warning`, `ax-subscription-row-signal-secondary`, `ax-subscription-setup-gap`. A "cleaner" reign that collapses three "bands" into one can silently drop the at-risk exposure figure, the last-webhook status, or the open-invoice record — data an operator relies on.

**Why it happens:**
"Trim redundant bands" and "one health verdict + one primary action per zone" read as *remove things*. Redundancy (the same fact shown twice) and density (many distinct facts shown compactly) look similar in a screenshot but are opposite. Retiring ~284 CSS rules feels like the goal, so content attached to those rules is treated as disposable.

**How to avoid:**
- Trim only **true duplication** (the same datum rendered in two bands) and **decoration** (empty framing), never distinct data. Rule of thumb: a band is redundant only if every datum in it appears elsewhere on the same page.
- Build a content inventory before deleting: enumerate every operator-facing datum on today's Home and Subscriptions pages (grep the `ax-subscription-row-*` / `ax-subscriptions-*` render blocks) and check each survives the reign, possibly relocated, never dropped.
- Lean on the existing copy assertions as a data tripwire — `subscription_live_test.exs` asserts strings like "Work all open invoice records", "Global invoice queue workspace", "Webhook debugger after invoice queue". If a reign deletes the datum, either the test fails (good) or the test was updated to hide the loss (bad — review copy-test edits closely).

**Warning signs:**
A PR diff deletes render blocks with no equivalent added; the at-risk/exposure number or webhook-status chip disappears from the screenshot; `subscription_live_test.exs` / `subscriptions_live_test.exs` copy assertions get deleted rather than relocated; operators can no longer answer "which subs are at risk and by how much" from the list.

**Phase to address:** The Subscriptions-reign phase (highest-density page). The content inventory should be produced in that phase's SPEC/plan and checked in verification.

---

### Pitfall 4: Test + selector breakage against retired `ax-*` classes and DOM

**What goes wrong:**
Retiring the bespoke class sets breaks unit tests and e2e specs that assert on those exact classes/DOM, and the failures look like regressions rather than expected churn. Confirmed live couplings:
- **Unit tests** — `test/accrue_admin/live/dashboard_live_test.exs` asserts `html =~ "ax-home-health-answer"` (L107), `"ax-launcher-primary"` (L130), `"ax-home-customer-search-cta"` (L184); `test/accrue_admin/live/subscriptions_live_test.exs:111` asserts `class="ax-kpi-row ax-subscriptions-kpi-row"`.
- **e2e** — `e2e/admin-spec-overview-phase194.spec.js:96` locates `.ax-attention-rail--empty`; `e2e/ratchet/region-tags.js:91` maps a region to `ax-attention-rail` (already TODO-flagged "confirm selector"); `e2e/admin-interaction-overlay-phase199.spec.js` pins `@ratchet` findings to `.ax-attention-rail`.

**Why it happens:**
The specs were written to lock the *current* bespoke design (Phases 194/199 + ratchet). A reign that renames/removes those classes is expected to churn them, but if the test suite is treated as an immovable gate the team either (a) reads red as "the reign broke something" and reverts good work, or (b) keeps a dead `ax-attention-rail` alias alive purely to satisfy a selector, defeating the retirement.

**How to avoid:**
- Before deleting a class, `grep -rn` it across `test/` and `e2e/` (the couplings above are the known set) and migrate every assertion to the shared-component selector/DOM in the *same* phase as the markup change — never leave the suite red across a phase boundary.
- Retire, don't alias: update the assertion to the new shared class rather than keeping the old class alive to satisfy a stale test.
- The `region-tags.js` ratchet selector map is parked but still in-tree; update it (or mark its regions stale) so a future ratchet re-freeze doesn't inherit dangling `.ax-attention-rail` selectors.

**Warning signs:**
`mix test` failures naming `ax-home-*` / `ax-subscriptions-kpi-row`; Playwright "locator resolved to 0 elements" for `.ax-attention-rail*`; a phase closing with a retired class still present only because a test references it.

**Phase to address:** Each reign phase owns migrating the selectors for the page it touches (Home phase → `dashboard_live_test` + phase194 overview spec; Subscriptions phase → `subscriptions_live_test`). A selector-migration checklist belongs in each phase's verification.

---

### Pitfall 5: The committed-bundle footgun — source edits ship nothing

**What goes wrong:**
The team edits `assets/css/app.css` (8,004 lines, the source), sees the reign look right in a dev build, ships, and the deployed/committed admin renders the *old* CSS. The served stylesheet is the git-tracked, minified `priv/static/accrue_admin.css` (155 KB, single line) produced by `mix accrue_admin.assets.build`. Editing source without rebuilding + committing `priv/static` ships dead CSS. This exact class of miss already burned Phase 189 (project memory: "admin serves COMMITTED priv/static/accrue_admin.css, not source app.css").

**Why it happens:**
Two-file indirection with no in-file warning banner: `app.css` looks authoritative and there's no comment there saying "not served directly." Dev tooling may live-recompile bind-mounted source, masking the gap until CI/prod serves the committed bundle. `priv/static/storybook.css` is a second committed bundle with the same trap.

**How to avoid:**
- Every phase that touches `assets/css/*` must end with `mix accrue_admin.assets.build` and `git add priv/static/accrue_admin.css` (+ `storybook.css` if the kitchen/gallery changed) in the *same* commit as the source edit — the `accrue_admin.ui.round` / `ui.fix` tasks already encode this exact order (assets.build → git add priv/static → commit).
- Verify the rendered PNGs against the *served* bundle (e.g. the Docker/CI-served admin), not a hot-reloaded dev sheet, so a forgotten rebuild is caught visually.
- Add a rebuild step to the phase verification checklist, not just the plan.

**Warning signs:**
PNG verification shows old styling despite "done" source edits; `git status` shows `assets/css/app.css` modified but `priv/static/accrue_admin.css` clean; CSS changes visible locally (hot reload) but absent in Docker/CI screenshots.

**Phase to address:** Every phase that edits CSS (both reign phases); enforce via a shared verification step defined in the milestone SPEC.

---

### Pitfall 6: Deleting CSS the Subscription DETAIL page still uses

**What goes wrong:**
The retirement list includes `ax-inline-worklist*`. But the Subscription **detail** page (`subscription_live.ex`, in M1 scope) *also* renders `ax-inline-worklist` and `ax-inline-worklist-copy`, and shares `ax-audit-summary-row` with the list. If the reign deletes the `ax-inline-worklist*` rules (20 rules) while retiring the *list's* worklist, the detail page's worklist loses its styling — an invisible break unless the detail page is re-verified. This is the classic "shared bespoke class deleted for one consumer, still referenced by another" trap, and it's real here, not hypothetical.

**Why it happens:**
The class names read as list-only ("inline-worklist" sounds like a list affordance), so a retire-the-list pass deletes them without grepping the detail template. `subscription_live.ex` is large (~90 distinct `ax-*` classes) and its worklist usage is easy to miss.

**How to avoid:**
- Before deleting *any* rule in the retirement set, `grep -rn 'ax-inline-worklist' lib/` — it returns both `subscriptions_live.ex` (list) and `subscription_live.ex` (detail). Reign the detail page's worklist onto the shared component in the same phase, or keep the shared component styling that replaces it.
- Cross-check every retired selector against all three reigned files (`dashboard_live.ex`, `subscriptions_live.ex`, `subscription_live.ex`) plus `component_kitchen_live.ex` (which also references the sets) and `storybook.css` before deletion.
- PNG-verify the subscription *detail* page after the *list* reign lands, even if the phase's headline is "list" — shared-class deletion crosses the list/detail boundary.

**Warning signs:**
Detail-page worklist renders unstyled/misaligned after a "list-only" change; `grep ax-inline-worklist lib/` still returns `subscription_live.ex` after the class's CSS was deleted; `component_kitchen_live.ex` gallery entry for the retired set 404s its styling.

**Phase to address:** The Subscriptions-reign phase must treat list + detail as one unit (they share the worklist/audit classes). Sequence CSS deletion *last*, after all three templates are reigned.

---

### Pitfall 7: Accessibility regressions when swapping bespoke markup for shared components

**What goes wrong:**
The bespoke Home/Subscriptions markup carries hand-placed a11y affordances (`dashboard_live.ex` has 11 `aria-*`/`role=` usages; `subscriptions_live.ex` has 6, plus `ax-visually-hidden` labels on the detail page). Swapping to shared components can drop landmark roles, visually-hidden labels, heading hierarchy, or focus order — and `e2e/admin-a11y.spec.js` (axe gate) will fail, or worse, pass while the *heading/landmark structure* silently degrades.

**Why it happens:**
Shared components encapsulate their own a11y, but the bespoke markup may have page-specific ARIA (e.g. a labelled attention rail, a visually-hidden queue-position announcement) that no shared component reproduces. "Use the shared component" feels like it inherits a11y for free; page-level semantics don't transfer automatically.

**How to avoid:**
- Inventory the existing `aria-*` / `role=` / `ax-visually-hidden` usages on the three files before the reign and confirm each is preserved or intentionally superseded by the shared component's own semantics.
- Run `e2e/admin-a11y.spec.js` (axe) against the reigned pages in each phase; treat it as merge-blocking. Also verify heading order and landmark structure manually (axe won't catch a demoted `h1`).
- Preserve keyboard/focus behavior for the worklist loop (prev/next, queue position) — the detail page's `ax-visually-hidden` announcements are part of that; don't drop them when the worklist markup changes.

**Warning signs:**
`admin-a11y.spec.js` axe violations on Home/Subscriptions; a removed `ax-visually-hidden` span; StatStrip rendering plain `<div>`s where an `aria-label`ed region used to be; focus jumps or lost queue-position announcement in the list→detail→next loop.

**Phase to address:** Both reign phases; axe gate + manual landmark/heading check in each phase's verification.

---

### Pitfall 8: Host `copy_strings.json` staleness (the cross-repo copy coupling)

**What goes wrong:**
Reigning the pages changes operator copy (headers, empty-state strings, primary-action labels). Admin copy is exported via `mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json`, and that committed JSON is **regenerated by host-integration but read as-committed by the Playwright e2e shards**. Changing admin copy without regenerating + committing the JSON silently stales it, and host e2e fails (or asserts on old copy). This is a known, previously-hit failure mode (project memory: CI green-up 260622).

**Why it happens:**
The copy SSOT lives in `AccrueAdmin.Copy`, but the e2e assertion reads a *generated snapshot* in a sibling project (`examples/accrue_host`). The two drift the moment admin copy changes and the snapshot isn't regenerated — a cross-repo coupling invisible from within `accrue_admin`.

**How to avoid:**
- Any phase that changes admin copy (both reign phases will, via EmptyState/PageHeader/primary-action strings) must re-run the export task and commit the regenerated `examples/accrue_host/e2e/generated/copy_strings.json` in the same change.
- Keep copy in `AccrueAdmin.Copy` (the SSOT the milestone already mandates); don't inline literals in the reigned templates, or the export won't capture them.
- Add the export+commit to the phase checklist alongside the CSS rebuild (Pitfall 5) — they're the same class of "generated artifact must be rebuilt and committed."

**Warning signs:**
Host Playwright shards fail asserting old admin copy; `git status` shows `AccrueAdmin.Copy` / templates changed but `copy_strings.json` clean; `copy_test.exs` passes locally while host e2e reds in CI.

**Phase to address:** Both reign phases; enforce via the same generated-artifact verification step as Pitfall 5.

---

## Moderate / secondary pitfalls

### Pitfall 9: Ratchet baseline drift (parked, but must be recorded)

**What goes wrong:**
A large visual/IA change invalidates the v1.56 ratchet baseline (`e2e/ratchet/ledger.baseline.json`, `findings.ledger.ndjson` = 4,724 entries, `rounds.ndjson` = 98 rounds, `region-tags.js` selector map, `exemplars/`). The ratchet is **parked**, so it won't fail CI during M1 — but if it's later un-parked without a re-freeze, it will flag the entire redesign as regressions and/or its region selectors (`.ax-attention-rail`) will resolve to nothing.

**Why it happens:**
The ratchet locks the *current* design forward-only; a redesign is exactly the "huge change" it's built to prevent (synthesis §8). Because it's parked, there's no forcing function during M1, so the required downstream re-freeze is easy to forget.

**How to avoid:**
- Do **not** try to keep the ratchet green during M1 — it's parked by design. Instead, leave a recorded breadcrumb (in the milestone RETROSPECTIVE / RESULT) that the ratchet's design-lens rubric, persona-job strings (`baseline-manifest.js`), `region-tags.js` selectors, and `exemplars/` must be refreshed and the ledger baseline re-frozen **after M1 (and M2/M3) land**, before the ratchet is resumed.
- Update `region-tags.js`'s already-TODO'd `ax-attention-rail` mapping opportunistically so the eventual re-freeze starts from a non-dangling selector map.

**Warning signs:**
Someone proposes running/gating the ratchet during M1; a resumed ratchet floods `finding-regressions.ndjson` with the whole redesign; `region-tags.js` selectors resolve to 0 elements.

**Phase to address:** Milestone close (RETROSPECTIVE/RESULT breadcrumb). Not an M1 build phase — explicitly deferred to the post-M3 ratchet re-freeze.

---

### Pitfall 10: Kitchen / Storybook drift for the retired sets

**What goes wrong:**
`component_kitchen_live.ex` and `priv/static/storybook.css` reference the bespoke sets. Retiring the classes without updating the component kitchen leaves dead gallery entries or unstyled stories, and `e2e/admin-storybook-a11y-phase200.spec.js` / `admin-page-flow-phase200.spec.js` may fail.

**Why it happens:**
The kitchen is a secondary renderer (drift-test backing); it's easy to reign the live pages and forget the gallery that also renders the retired vocabulary.

**How to avoid:**
Grep the retirement set against `lib/accrue_admin/dev/component_kitchen_live.ex` and `priv/static/storybook.css`; update or remove stale entries; rebuild `storybook.css` (same bundle footgun as Pitfall 5). Run the phase200 storybook specs.

**Warning signs:** Storybook a11y/page-flow specs fail; kitchen renders an unstyled retired component; `storybook.css` clean in `git status` after a class retirement.

**Phase to address:** Whichever reign phase retires the shared classes (fold the kitchen/storybook update into it).

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Keep a retired `ax-*` class alive as an alias so an old test/selector still passes | Green suite without touching tests | Retirement is fake; `region-tags.js` and specs keep pointing at zombie selectors; the ~284-rule cleanup never lands | Never — migrate the assertion instead |
| Compose shared components at default spacing "for now," tighten density later | Faster reign, looks fine in isolation | Density regression ships; contradicts the operator-console posture; ratchet flags it later | Never for the two reigned pages — density is the point |
| Edit `app.css` without rebuilding `priv/static` this commit | Faster local loop | Dead CSS in prod/CI (repeat of Phase 189); confusing "why didn't my change ship" | Only mid-phase WIP; must rebuild+commit before phase close |
| Change admin copy without regenerating `copy_strings.json` | Smaller diff | Host e2e stales/reds; cross-repo drift | Never at phase close |
| Add "just a small diagnosis hint" to the health verdict | Feels like better IA | Silently starts M2; pulls scope toward core `accrue` | Never in M1 — defer to M2 |
| Delete a "band" that looks duplicated without a content inventory | Cleaner screenshot | Drops real operator data (at-risk exposure, webhook status) | Only for verified true-duplicate/decoration bands |

---

## Phase-Specific Warnings (summary map)

| Concern | Likely pitfall | Owning phase | Mitigation |
|---------|----------------|--------------|------------|
| Scope fence (no M2/M3, no core) | #2 IA over-reach | SPEC / discuss / roadmap-shaping | Written scope fence; plan-review rejects core/new-room work |
| Home reign | #1 density, #4 selectors (`dashboard_live_test` L107/130/184; phase194 spec), #5 bundle, #7 a11y, #8 copy | Home-reign phase | Density gate + selector migration + rebuild + axe + copy export |
| Subscriptions list+detail reign | #1 density, #3 content loss, #4 selectors (`subscriptions_live_test` L111), #6 shared-CSS deletion (`ax-inline-worklist*` on detail), #5 bundle, #7 a11y, #8 copy | Subscriptions-reign phase (list+detail as one unit) | Content inventory; grep-before-delete across all 3 files; delete CSS last; verify detail after list |
| Component kitchen / storybook | #10 kitchen drift | The class-retirement phase | Update kitchen + rebuild `storybook.css` + phase200 specs |
| Ratchet re-lock | #9 baseline drift | Milestone close (deferred to post-M3) | Recorded breadcrumb; opportunistic `region-tags.js` fix; do NOT gate on ratchet in M1 |

---

## Sources

- `accrue_admin/lib/accrue_admin/live/{dashboard_live,subscriptions_live,subscription_live}.ex` — actual class usage; confirmed `ax-inline-worklist*` shared between list and detail (HIGH).
- `accrue_admin/test/accrue_admin/live/{dashboard_live_test,subscriptions_live_test,subscription_live_test}.exs` — retired-class + copy assertions at named lines (HIGH).
- `accrue_admin/e2e/{admin-spec-overview-phase194,admin-interaction-overlay-phase199}.spec.js`, `e2e/ratchet/region-tags.js` — `.ax-attention-rail*` selector couplings (HIGH).
- `accrue_admin/assets/css/app.css` (8,004 lines, source) vs `priv/static/accrue_admin.css` (155 KB minified, git-tracked) + `lib/mix/tasks/accrue_admin.assets.build.ex` / `accrue_admin.ui.{round,fix}.ex` — committed-bundle mechanics; measured retirement-set rule counts (ax-subscriptions 146, ax-attention 43, ax-home 38, ax-launcher 37, ax-inline-worklist 20) (HIGH).
- `lib/mix/tasks/accrue_admin.export_copy_strings.ex` + `examples/accrue_host/e2e/generated/copy_strings.json` — cross-repo copy coupling (HIGH); corroborated by project memory "CI green-up 260622" and "Phase 189 dead CSS" (MEDIUM, prior-incident recall).
- `.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md` §4–§9 — density-defender tension, M1/M2/M3 boundary, ratchet-distinct + re-freeze-after guidance (HIGH).
- `.planning/PROJECT.md` (Current Milestone v1.57) — M1 scope fence, retirement set, `ax-*` SSOT, brand/density constraints (HIGH).
- `accrue_admin/e2e/ratchet/{ledger.baseline.json,findings.ledger.ndjson,rounds.ndjson}` — parked baseline scale (4,724 findings / 98 rounds) informing the re-freeze warning (HIGH).
