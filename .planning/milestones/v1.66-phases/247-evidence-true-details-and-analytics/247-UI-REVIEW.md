# Phase 247 — UI Review

**Audited:** 2026-10-11  
**Baseline:** Approved `247-UI-SPEC.md` and `247-CONTEXT.md`; Impeccable critique hierarchy applied in a single evidence-based pass as directed.  
**Screenshots:** Captured in the supplied current-revision proof set; all 16 original-resolution PNGs inspected (1280×900 and 320×820, light and dark). Product source is bound to `60cbf063`; the current code revision differs by documentation only.  
**Interaction captures:** off (workflow.ui_interaction_capture is false). Findings about unstaged interactions are code-derived; the supplied static proof includes mounted invoice and replay review states.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | Recovery subtitle repeats unexplained “dunning”; the page and nav use different destination names. |
| 2. Visuals | 3/4 | Core evidence hierarchy is clear, but Activity and Raw payload disclosures have no visible expand cue. |
| 3. Color | 3/4 | Semantic colors and accent restraint are sound; the captures show a second blue focus outline around the full content region. |
| 4. Typography | 2/4 | Detail section headings render at 16px/850 where the contract specifies 20px/600. |
| 5. Spacing | 4/4 | The supplied wide/narrow evidence shows deliberate 4px-token spacing and preserves the 44px disclosure targets. |
| 6. Experience Design | 1/4 | At 320px the Local/UTC selector is mostly clipped off-screen, blocking reliable touch use of a required control. |

**Overall: 15/24**

---

## Top 3 Priority Fixes

1. **BLOCKER — Keep the Local/UTC selector fully visible at 320px** — The preference is a required shared timestamp control, but the narrow captures show its label and most of its select clipped beyond the left edge. Reflow the topbar controls or place the preference in a clearly labeled, reachable mobile menu.
2. **WARNING — Give Activity and Raw payload visible disclosure affordances** — Their headings look like static section titles in the populated webhook capture, so operators may not discover the lazy-loaded evidence. Add a visible chevron or equivalent expanded/collapsed cue while retaining native `summary` keyboard behavior.
3. **WARNING — Use one operator-facing recovery destination name and explain “dunning”** — The sidebar says “Recovery” while the page says “Payment recovery,” and the subtitle uses “dunning” twice without explanation. Align the destination labels and replace or briefly define the unfamiliar term.

---

## Detailed Findings

### Pillar 1: Copywriting (2/4)

- **WARNING:** The recovery subtitle says “Review payment recovery activity, the dunning funnel, and subscriptions currently in dunning.” The repeated specialist term is unexplained in a page aimed at billing/support operators ([copy.ex](accrue_admin/lib/accrue_admin/copy.ex:979)). Prefer “failed-payment recovery” or define the term once in plain language.
- **WARNING:** The page heading is “Payment recovery” ([copy.ex](accrue_admin/lib/accrue_admin/copy.ex:977)), but the selected sidebar destination is “Recovery” ([nav.ex](accrue_admin/lib/accrue_admin/nav.ex:54)). This misses the contract’s destination-name consistency requirement.
- The webhook copy is notably stronger: the page distinguishes “Dead” from processing outcomes, says replay “Queues another delivery attempt. Queue acceptance does not confirm processing,” and preserves unavailable processing time ([webhook_live.ex](accrue_admin/lib/accrue_admin/live/webhook_live.ex:203)). The empty fixture does not invent dispatch or payload evidence; the full empty-state copy is in source at lines 273–301.

### Pillar 2: Visuals (3/4)

- **WARNING:** Recovery’s four currency/outcome KPIs form a readable 2×2 desktop group and stack one-up on mobile. The at-risk queue follows them, and the funnel remains a secondary section; captured values and unavailable states are legible in both themes.
- **WARNING:** In the held-out webhook screenshots, “Activity” and “Raw payload” appear as plain bold headings with no visible marker or other expand/collapse treatment. The native `<details>/<summary>` controls exist in source ([webhook_live.ex](accrue_admin/lib/accrue_admin/live/webhook_live.ex:268)), but the visible design does not communicate that they can be opened. This is especially costly because the selected fixture has empty Activity and raw payload, so users need a discoverable cue before content appears.
- The detail page establishes identity, observed status, replay action, exact metadata, then investigation sections. On narrow viewports the long event key wraps without page overflow. No claim is made about a populated payload or eligible replay state beyond the supplied fixtures.

### Pillar 3: Color (3/4)

- **WARNING:** The 60/30/10 distribution is generally respected: base canvas dominates, elevated/sunken regions separate navigation and data, and accent is limited to selected navigation/window state, links, and primary actions. Theme tokens support both captured themes; the phase CSS uses the existing theme roles for recovery metric grouping ([app.css](accrue_admin/assets/css/app.css:4242)).
- **WARNING:** Every supplied capture shows a blue outline around the entire main content region while the search control also has a focus ring. This makes the accent read as a selected page frame rather than a single active focus target. The shell CSS intends to suppress a non-keyboard outline on programmatic main focus ([app.css](accrue_admin/assets/css/app.css:1081)); reconcile that behavior with the rendered state so the initial page does not carry two simultaneous focus cues.

### Pillar 4: Typography (2/4)

- **WARNING:** The contract sets section headings at 20px/600 and permits only regular 400 and semibold 600 ([247-UI-SPEC.md](.planning/phases/247-evidence-true-details-and-analytics/247-UI-SPEC.md:68)). Shared detail section headings instead use `--ax-type-md` (16px) and `font-weight: 850` ([app.css](accrue_admin/assets/css/app.css:6353)). In the webhook capture, “Activity” and “Raw payload” therefore look unusually heavy for secondary sections, while their disclosure meaning remains unclear. Apply the declared heading role and weight.
- The recovery page title and metric values retain a clear size hierarchy; exact IDs and timestamps use the incumbent code treatment. The main deviation is the repeated over-heavy detail-section role, not the typeface choice.

### Pillar 5: Spacing (4/4)

- Wide captures show the currency pairs, work queue, and funnel separated as distinct groups; narrow captures keep each KPI and subscription card within the viewport. Recovery-specific card pairing uses the existing 16px token, with the requested 2×2 desktop and one-column mobile geometry ([app.css](accrue_admin/assets/css/app.css:4242)).
- Webhook disclosure summaries retain the required 44px minimum target ([app.css](accrue_admin/assets/css/app.css:6337)). The screenshot matrix shows no clipping of long identities, currency values, or action copy inside the content region. Topbar clipping is scored under Experience Design because it prevents access to a control; it is not evidence of inconsistent page-content spacing.

### Pillar 6: Experience Design (1/4)

- **BLOCKER:** At 320px, the time preference in the persistent topbar is cut off at the left edge: the “Time display” label is absent and only a small slice of the select is visible in the supplied captures. The preference is required for choosing Local versus UTC, so mobile users cannot reliably operate it by touch. The current markup places the select before search, menu, and theme controls ([topbar.ex](accrue_admin/lib/accrue_admin/components/topbar.ex:19)); the screenshot proves the resulting group does not fit at the contracted viewport.
- **WARNING:** The Activity and Raw payload sections are native keyboard-operable disclosures and load lazily on open, but their captured closed state lacks a visible expand affordance ([webhook_live.ex](accrue_admin/lib/accrue_admin/live/webhook_live.ex:268)). Add a visible state cue and verify that it updates with `open`.
- **WARNING:** The replay confirmation shows “Cancel replay” in both the drawer’s top close control and its lower secondary action ([webhook_live.ex](accrue_admin/lib/accrue_admin/live/webhook_live.ex:324)). Both dismiss the same review, so the duplicate dismissal choice adds noise; keep one clearly labeled dismissal control if the drawer pattern permits it.
- Phase summaries and source demonstrate substantial state handling for missing values, clipboard failure, scoped retry, empty history, authorization and queued-versus-completed replay feedback. The supplied held-out record has only two dead deliveries and no separate eligible blocked-detail record; Activity and raw payload are empty. Those are fixture limits, not inferred UI behavior. Interaction capture was off, so clipboard success/failure and keyboard activation are source-derived here.

## Files Audited

- `.planning/phases/247-evidence-true-details-and-analytics/247-UI-SPEC.md`, `247-CONTEXT.md`, `247-01` through `247-08` PLAN and SUMMARY files
- `.planning/notes/2026-10-11-admin-owner-feedback.md`
- `.planning/phases/247-evidence-true-details-and-analytics/captures/phase247-current-proof/manifest.json` and all 16 PNG captures
- `accrue_admin/lib/accrue_admin/components/{app_shell,topbar,timestamp,detail,kpi_card,sidebar}.ex`
- `accrue_admin/lib/accrue_admin/live/{webhook_live,analytics/recovery_live}.ex`
- `accrue_admin/lib/accrue_admin/{copy.ex,nav.ex}`
- `accrue_admin/assets/css/{app.css,theme.css}`
- `examples/accrue_host/e2e/phase247-current-proof.spec.js`
- `$HOME/.codex/gsd-core/workflows/ui-review.md`
- `$HOME/.agents/skills/impeccable/SKILL.md` and `reference/critique.md`
