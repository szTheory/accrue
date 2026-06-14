# Phase 187 Audit Rubric

This file is the scoring contract for the v1.53 admin UI audit baseline. It preserves the
v1.51 continuity dimensions, adds interaction and copy dimensions for the defects screenshots
miss, and fixes the machine-readable vocabulary used by `baseline.cells.json` and
`defects.ndjson`.

`baseline.cells.json` and `defects.ndjson` are canonical for Phase 192 comparison. If this
markdown file, `187-BASELINE.md`, or any prose summary disagrees with those structured
artifacts, structured data wins and the markdown must be regenerated or corrected.

`brandbook/` supersedes `prompts/accrue-brand-book.md` wherever they conflict. The older prompt
remains historical context only.

## Rubric Dimensions

Scores are integers from 0 to 3 unless a row is explicitly outside scope and recorded as `null`
with `coverage_status: "n/a"` in `baseline.cells.json`.

Canonical dimension anchors:

- 1 token-compliance
- 2 visual-hierarchy
- 3 spacing-rhythm
- 4 state-coverage
- 5 responsive-mobile-first
- 6 contrast
- 7 focus-semantics
- 8 brand-expression
- 9 motion
- 10 reuse-dry
- 11 interaction-integrity
- 12 microcopy

| # | Dimension | Passing signal | Scoring anchors |
|---|-----------|----------------|-----------------|
| 1 | token-compliance | The surface uses `ax-*` implementation tokens and approved semantic roles; no inline style drift, bare palette values, or ad hoc spacing/layer/color values are introduced. | 3 = token-clean and role-correct; 2 = token-based with minor documented exception; 1 = visible drift or one-off value; 0 = token system bypassed. |
| 2 | visual-hierarchy | The page or component presents the operator's next useful read in a clear order using established heading, body, table, and action patterns. | 3 = clear hierarchy and focal path; 2 = usable hierarchy with minor flattening; 1 = hard to scan or competing focal points; 0 = hierarchy blocks task completion. |
| 3 | spacing-rhythm | Layout rhythm follows the `ax-*` spacing scale and uses density appropriate to developer tooling. | 3 = consistent rhythm across viewport and state; 2 = minor spacing imbalance; 1 = cramped, loose, or semantically wrong spacing; 0 = spacing causes overlap or unreadability. |
| 4 | state-coverage | The audited surface accounts for populated, empty, loading, error, permission, overflow, disabled, and open-interaction states when applicable. | 3 = all applicable states reachable and named; 2 = primary states covered with minor gaps; 1 = important state missing or ambiguous; 0 = missing state blocks audit or operator flow. |
| 5 | responsive-mobile-first | The surface works from narrow mobile through desktop and uses established responsive patterns instead of squeezed desktop layouts. | 3 = robust at canonical and targeted risk widths; 2 = usable with minor friction; 1 = layout strain, clipping, or awkward degradation; 0 = content or controls unreachable. |
| 6 | contrast | Text, controls, focus rings, status indicators, semantic roles, and dark-mode variants meet contrast expectations and do not rely on color alone. | 3 = contrast-clean in both themes; 2 = accessible with minor refinement needed; 1 = likely contrast or color-only risk; 0 = unreadable or hidden state. |
| 7 | focus-semantics | Interactive and structural elements expose correct roles, names, keyboard behavior, focus visibility, and semantic relationships. | 3 = complete keyboard and semantic contract; 2 = mostly correct with minor omission; 1 = partial roles or weak keyboard path; 0 = inaccessible or misleading semantics. |
| 8 | brand-expression | The surface feels like quiet, well-made developer tooling and uses Accrue's tokens, Geist typography, and domain vocabulary without generic SaaS or fintech taste. | 3 = distinctly Accrue and restrained; 2 = neutral and compatible; 1 = generic, decorative, or off-register; 0 = contradicts the brand system. |
| 9 | motion | Animation uses the established motion tokens, supports reduced motion, and clarifies state changes without adding friction. | 3 = tokenized, purposeful, reduced-motion-safe; 2 = acceptable inherited behavior; 1 = drift, excess, or missing reduced-motion behavior; 0 = motion blocks use or hides state. |
| 10 | reuse-dry | The surface uses existing primitives, component groups, and page patterns so fixes happen at the root instead of per-page patches. | 3 = built from established reusable pieces; 2 = mostly reused with small local pattern; 1 = hand-rolled duplicate; 0 = duplicate implementation likely to fork behavior. |
| 11 | interaction-integrity | Live interactions work under real browser conditions: overlays receive clicks, focus stays controlled, scroll remains reachable, keyboard-only paths complete, disabled controls are not actionable, and LiveView patches do not strand focus. | 3 = interaction contract holds with trace evidence; 2 = usable with minor friction; 1 = broken edge interaction or ambiguous affordance; 0 = primary interaction blocked, intercepted, or inaccessible. |
| 12 | microcopy | UI text follows Accrue's measured, exact, native, durable voice; state and action copy names the affected object/process and gives the next useful action when one exists. | 3 = precise, mechanism-led, Phoenix-native, recoverable; 2 = understandable with minor vagueness; 1 = generic, missing object, or missing recovery; 0 = misleading, wrong, or blocks recovery. |

Layer/z-index is not a thirteenth dimension. Layer defects are recorded with the relevant primary
dimension, usually `token-compliance`, `focus-semantics`, `interaction-integrity`, or `motion`,
plus the `layer-z-index` overlay tag.

## Overlay Tags

Overlay tags make recurring cross-dimensional failure modes searchable without double-counting
them as extra dimensions. A defect may have zero, one, or many overlay tags.

| Tag | Use when |
|-----|----------|
| layer-z-index | A layer order, stacking context, scrim, sticky region, modal, drawer, toast, dropdown, or popover appears behind or above the wrong thing. |
| live-focus | Focus is lost, hidden, duplicated, or moved to an unexpected element after a LiveView patch or async update. |
| focus-restore | Closing an overlay or completing a flow does not return focus to the trigger or next logical element. |
| focus-trap | A modal or drawer that should trap focus lets focus escape, or traps focus so tightly that required controls are unreachable. |
| scroll-reachability | Page, panel, drawer, table, or nested region content cannot be reached by wheel, touch, keyboard, or programmatic scroll. |
| overlay-position | A dropdown, popover, tooltip, toast, drawer, or modal is detached from its trigger, clipped, or positioned over the related control. |
| actionability | A visible control cannot receive pointer or keyboard activation, or Playwright actionability reports intercepted clicks. |
| disabled-affordance | Disabled or read-only controls look actionable, or enabled controls look disabled. |
| hover-affordance | Non-interactive content advertises hover/focus affordance, or interactive content lacks a clear hover/focus affordance. |
| copy-recovery | Error, empty, permission, disconnected, or destructive copy omits the next useful action or recovery path. |
| copy-vocabulary | Copy uses wrong, generic, Rails/SaaS/fintech, or inconsistent domain vocabulary. |
| copy-specificity | Copy fails to name the affected object, process, route, event, invoice, subscription, customer, or config key. |
| dark-mode-role | A semantic color role is wrong, invisible, low contrast, or misleading in dark mode. |
| reduced-motion | Motion does not honor reduced-motion expectations, or the reduced-motion path hides necessary state feedback. |

## State Taxonomy

Every baseline cell uses one of these states:

- `default-populated` - Normal populated state with representative deterministic data.
- `empty` - No records or no relevant records exist, distinct from unavailable data.
- `loading` - Pending fetch, async action, or loading placeholder state.
- `error` - Recoverable failure or invalid state that the operator can understand.
- `permission-denied` - Authenticated user lacks access to the surface or action.
- `disconnected-reconnecting` - LiveView or client connection is stale, disconnected, or reconnecting.
- `overflow` - Tables, lists, cards, chips, tabs, or toolbars have more content than the default viewport comfortably fits.
- `long-content` - IDs, names, URLs, descriptions, JSON, or domain values are unusually long.
- `disabled-readonly` - Controls or fields are disabled, read-only, locked, or temporarily not actionable.
- `interactive-open` - Modal, drawer, dropdown, popover, command palette, menu, toast, tab, disclosure, or other interactive state is open.

Each matrix cell must be marked `covered`, `gap`, or `n/a`. `covered` cells need evidence
references. `gap` cells become defects or explicit seed/tooling gaps. `n/a` cells need a short
reason so Phase 192 comparison does not drift.

## Severity Scale

Severity is rankable in this order: `critical` > `high` > `medium` > `low`.

| Severity | Meaning | Typical routing |
|----------|---------|-----------------|
| critical | Blocks a primary operator flow, hides or corrupts the baseline evidence, creates an inaccessible interaction, or prevents Phase 192 comparison. | Immediate owner phase; document before any lower-severity work. |
| high | Breaks a common task, makes a core state unreachable, causes serious responsive/a11y/interaction failure, or affects many surfaces through a shared root. | Route to the phase that owns the root component, group, or page flow. |
| medium | Causes meaningful friction, ambiguity, copy weakness, visual drift, or state incompleteness without blocking the main path. | Route to the most local owner phase with root-cause note. |
| low | Minor polish issue, isolated copy specificity issue, cosmetic inconsistency, or narrow edge state that does not block operation. | Route to cleanup inside the appropriate owner phase. |

Severity considers user impact, reachability, confidence, blast radius, and whether the defect
prevents repeatable evidence.

## Defect Ownership

`defects.ndjson` rows must include `owner_phase` with one of these string values:

| owner_phase | Receives |
|-------------|----------|
| 188 | Foundation defects: typography bundles, reading measure, token drift, z-index/layer system, motion tokens, inert Tailwind resolution, semantic roles, focus rings, scrollbars, and dark-mode/disabled foundation roles. |
| 189 | Primitive, form, and component-lab defects: isolated component states, accessible names/roles, button/form affordances, root component reuse, disabled/read-only component behavior, and `/dev/components` coverage. |
| 190 | Component-group defects: app shell, nav, tabs, pagination, tables, cards, detail layouts, timeline, KPI/chart/table clusters, toolbars, filters, modals/drawers as reusable groups, and group-level spacing/hierarchy. |
| 191 | Page, flow, interaction, fixture, and microcopy defects: page JTBD coverage, live interaction repair, permission/disconnected/empty/error copy, seed reachability, page-specific keyboard paths, and Phase-187 interaction ledger fixes. |

Use the earliest owner phase that can fix the root cause without per-page patching. If the same
defect is visible on many pages because of a primitive, route it to `189`; if it is a recurring
composition issue across several primitives, route it to `190`; if it is page-specific flow or
copy, route it to `191`.

## Scoring Rules

1. Score against observed behavior and committed evidence, not intent.
2. Use the carried v1.51 meanings for dimensions 1 through 10 so prior scores remain comparable.
3. Score `interaction-integrity` from live browser evidence, preferably Playwright traces.
   Screenshots and axe output are supporting evidence, not replacements for focus, scroll,
   overlay, and keyboard behavior.
4. Score `microcopy` against the ratified Accrue voice: measured, exact, native, durable.
   Prefer mechanism-led copy, Phoenix developer vocabulary, precise object names, and
   proof-checkable claims.
5. Evaluate empty, error, permission-denied, and disconnected/reconnecting states as operator UX.
   Passing copy tells the operator what happened, what object or process is affected, and the
   next useful action when one exists.
6. Score visual and design findings against quiet, well-made developer tooling and `ax-*` tokens,
   not generic SaaS dashboard taste.
7. Do not inflate coverage by marking unreachable states as covered. Use `gap` when fixtures,
   routes, or probes cannot reach a required state.
8. Do not encode current broken behavior as a permanent regression assertion in Phase 187.
   Record it as a defect with evidence and let Phase 191 add the corrected regression test.
9. Do not commit bulky screenshots or trace zips by default. Evidence paths belong in
   `artifacts.manifest.json`; generated files stay under `test-results/` or the established
   generated-output convention.
10. Do not add SARIF, PhoenixStorybook, pixel-diff services, or new package dependencies as part
    of this rubric contract.

## Examples

| Observation | Primary dimension | Overlay tags | Severity guidance | Owner guidance |
|-------------|-------------------|--------------|-------------------|----------------|
| A confirmation modal appears behind its scrim and Playwright reports the visible confirm button is intercepted. | interaction-integrity | `layer-z-index`, `actionability`, `focus-trap` if keyboard focus is also wrong | `critical` if it blocks confirmation; otherwise `high`. | `188` if layer tokens are missing; `190` if modal group composition is wrong; `191` if page-specific. |
| Focus vanishes after a LiveView patch refreshes a table row action. | interaction-integrity | `live-focus`, `focus-restore` | `high` when keyboard-only completion breaks; `medium` for narrow edge cases. | `191` unless a primitive or shared group owns the focus behavior. |
| An error state says only "Failed" after invoice finalization. | microcopy | `copy-recovery`, `copy-specificity` | `medium`; `high` if no recovery path exists for a common operator task. | `191`. |
| A disabled replay button keeps the same visual treatment as the enabled state and still advertises hover. | interaction-integrity | `disabled-affordance`, `hover-affordance` | `high` if action remains clickable; `medium` if visual affordance only. | `189` for button primitive; `190` for toolbar/action group. |
| A dark-mode status chip uses a role color that fails contrast but the label text is present. | contrast | `dark-mode-role` | `medium`, or `high` if the state is safety-critical or repeated across many surfaces. | `188` if semantic role tokens are wrong; `189` if chip primitive is wrong. |
| A table at 320px keeps all desktop columns and pushes the primary action off-screen. | responsive-mobile-first | `scroll-reachability`, `actionability` if the action cannot be reached | `high` for common lists; `critical` if the page cannot be used. | `190` if table/card group pattern is wrong; `191` if page-specific. |
| A destructive confirmation says "Are you sure?" without naming the webhook, invoice, or subscription affected. | microcopy | `copy-specificity`, `copy-recovery` | `medium`; `high` when irreversible action consequence is unclear. | `191`. |
