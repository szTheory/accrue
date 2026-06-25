# Overview Page Spec (SPEC-OVERVIEW)

The Overview archetype covers every page whose primary job is to orient the operator at a glance and
route them to their next action. In `accrue_admin` this includes `dashboard_live.ex` and the
Recovery analytics page. These pages share a fixed four-zone grammar: exceptions-first attention
rail, verb-labeled task launchers (plus visible ⌘K search), demoted-but-clickable KPI cluster, and
a recent activity strip.

The design authority is GOV.UK's "one thing per page" principle reframed for operator dashboards —
*the "thing" is a decision or task, not a metric*. An overview page that leads with KPI numbers
becomes wallpaper; one that leads with exceptions and task doors routes operators fast.

Audience: build agents for Phases 194–200, the `accrue_admin` maintainer, and adopters extending
the admin UI.

---

## SPEC-OVERVIEW — exceptions-first, tasks-as-doors

### Machine-checkable invariants

The following invariants are verified deterministically by the page-flow Playwright driver
(`phase191-page-flow-helpers.js`), source guards in `scripts/ci/verify_package_docs.sh`, or
`axe-core`. They must hold on every build.

| Invariant | How verified |
|-----------|--------------|
| **Exactly one `<h1>` per page.** The overview page may not render zero or multiple `<h1>` elements. | `assertFocusWithin` / `axe-core` landmark check; Playwright `page.locator('h1').count()` assertion in the page-flow spec. |
| **⌘K trigger is present in the DOM and focusable.** The global search entry point must appear as a visible, focusable element (not hidden behind a hotkey only), reachable by keyboard Tab and pointer click. | Playwright `locator('[data-ax-command-palette-trigger]')` is-visible + `assertFocusWithin` passes when the trigger receives focus. |
| **KPI cluster is a DOM sibling *after* the attention-rail and task-launcher zones.** The KPI elements must not be the first or second major section in document order; exceptions and tasks come first. | Playwright DOM-order assertion: `attention-rail` index < `task-launcher` index < `kpi-cluster` index in the `querySelectorAll('[data-ax-zone]')` node list. |
| **Healthy/empty attention-rail renders a non-interactive hero.** When the attention rail has no exception rows, its empty-state container must carry neither `cursor:pointer` nor `role="button"` — it is a reassurance message, not an action affordance. | Playwright `assertTopPointerTarget` confirms the empty-state element is not a pointer-events target; source guard (`require_regex`) ensures no `cursor:pointer` on `.ax-attention-rail--empty`. |

### Judge-graded criteria (12-dim rubric)

These items require human or adversarial-agent judgment. They are scored against the 12-dimension
rubric in `.planning/milestones/v1.53-phases/187-audit-baseline/187-RUBRIC.md` and are not
machine-enforceable without that rubric context.

**Exceptions read as higher-signal than KPIs.**
The visual weight and vertical position of the attention rail must communicate priority. Exception
rows should dominate the above-the-fold area. KPI cards demoted below the task launchers must
appear lighter (smaller type scale, lower contrast weight) than the exception rail heading and
its row items. A reviewer comparing a screenshot to a KPI-first alternative must judge that
exceptions are unmistakably more prominent.

**KPIs demoted, not deleted.**
The KPI cluster must remain visible on the page — removing it is a scope violation (operators
return to it for trend checks). The rubric criterion is "useful but not dominant": KPIs are
clickable shortcuts to their filtered list pages, labelled to suggest that action, and located
below the task doors.

**Recovery analytics adopts the same zone grammar, not a chart wall.**
The Recovery analytics page must follow overview zone discipline — leading with a hero metric
pair (Recovered MRR / Lost MRR), then an at-risk work queue *as a table* (the job is acting on
at-risk records, not admiring trend lines), then supporting visualization below. A reviewer must
judge that the hero pair + table are above the fold in a 1280×800 viewport and no chart appears
before the work-queue table.

**No KPI-first headline; no chart wall.**
The rubric will penalise any build where a KPI grid or chart is the first visually dominant
element on the overview page. Exceptions and verb-labeled task launchers must win the visual
hierarchy test, confirmed by an adversarial reviewer.

---

*Guide home: `accrue_admin/guides/spec-overview.md`*
*Part of the Phase 193 pattern-lock. Downstream consumers: Phases 194, 198.*
