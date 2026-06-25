# Phase 187: Audit & Baseline - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the only-forward baseline for v1.53 Admin UI Design-System Hardening. This phase refreshes the v1.51 admin UI rubric, audits the running `accrue_admin` surface across a replayable viewport/theme/state matrix, live-tests the interactions screenshots miss, and commits a severity-ranked defect ledger plus scored baseline that Phases 188-191 remediate against and Phase 192 compares to.

This is an audit and baseline phase. It should not redesign the admin UI, migrate styling systems, add billing primitives, or fix defects beyond narrow harness changes required to observe and record the baseline honestly.

</domain>

<decisions>
## Implementation Decisions

The user selected all gray areas for advisor-style discussion and requested subagent-backed, recommendation-first decisions across software architecture, Elixir/Phoenix idioms, UI/UX, accessibility, DX, and the repo's prompt/brand corpus. Four advisor researchers returned compatible recommendations; the package below is locked for planning.

### Rubric Schema

- **D-01:** Preserve the v1.51 10 rubric dimensions unchanged for continuity: token compliance, visual hierarchy, spacing rhythm, state coverage, responsive/mobile-first, contrast, focus and semantics, brand expression, motion, reuse/DRY.
- **D-02:** Add exactly two first-class v1.53 dimensions: `11 interaction-integrity` and `12 microcopy`.
- **D-03:** Do not make `layer/z-index` a standalone 13th dimension. Model it as a mandatory overlay tag that can attach to token compliance, focus and semantics, interaction-integrity, and motion findings. This avoids double-counting modal/dropdown failures while still making layer defects impossible to miss.
- **D-04:** Every defect row must name both a primary rubric dimension and, when applicable, an overlay tag. Required initial overlay tags: `layer-z-index`, `live-focus`, `focus-restore`, `focus-trap`, `scroll-reachability`, `overlay-position`, `actionability`, `disabled-affordance`, `hover-affordance`, `copy-recovery`, `copy-vocabulary`, `copy-specificity`, `dark-mode-role`, `reduced-motion`.
- **D-05:** Update the vision scoring prompt/schema to score all 12 dimensions. The carried 10 dimensions stay semantically compatible with v1.51 so Phase 192 can compare without reinterpreting old scores.

### Audit Matrix Boundary

- **D-06:** Define "full matrix" as a manifest-driven representative matrix, not a literal Cartesian product of every component x group x page x viewport x theme x state. Literal Cartesian coverage would explode, duplicate findings, and turn Phase 187 into a tooling/remediation milestone.
- **D-07:** Baseline every production admin page and the current `/dev/components` surface in the existing Playwright project modes: `chromium-desktop` (1280x900) and `chromium-mobile` (Pixel 5), across light and dark themes.
- **D-08:** Classify state cells with this taxonomy: `default-populated`, `empty`, `loading`, `error`, `permission-denied`, `disconnected-reconnecting`, `overflow`, `long-content`, `disabled-readonly`, and `interactive-open`.
- **D-09:** Each matrix cell must be explicitly marked `covered`, `gap`, or `n/a`. `covered` cells need fixture/click-path/evidence. `gap` cells become defects or seed/tooling gaps. `n/a` cells need a short reason so Phase 192 comparison does not drift.
- **D-10:** Add targeted breakpoint probes at 320, 375, 768, 1024, and 1440 where layout risk exists, but do not multiply every state by every width. The canonical screenshot baseline remains the existing desktop/mobile project pair unless the planner finds a specific risk requiring a targeted width artifact.
- **D-11:** Include component, component-group, and page/flow rows in the manifest. Component rows can start from the current `/dev/components` kitchen and existing component registry; group rows should map recurring patterns such as page-header/actions/breadcrumbs, toolbar/search/filter/sort, table/empty/loading/error/pagination, KPI/chart/table, detail-header/metadata/actions, modal-confirm, drawer/form, and tabs/subviews.

### Live Interaction Probes

- **D-12:** Use a hybrid ledger-first approach. Phase 187 must run the full exploratory live-interaction probe set and record findings now, but should automate only stable baseline contracts needed to make the ledger repeatable. Exhaustive per-defect regression coverage belongs to Phase 191 after fixes.
- **D-13:** Required live probes: modal/drawer/scrim layering, dropdown/popover/toast position, scroll reachability, focus trap, focus restore, Escape/click-outside dismiss, keyboard-only completion of primary flows, focus after LiveView patches, disabled/read-only affordances, hover/focus weirdness on non-interactive surfaces, disconnected/reconnecting behavior, permission-denied, error, loading, and empty states.
- **D-14:** Stable contracts that should be automated in Phase 187 if feasible: dialog/drawer appears above scrim and receives clicks; Escape closes; focus returns to trigger; Tab and Shift+Tab stay inside modal; dropdown/menu trigger exposes open state; keyboard activation works for menu items; scroll-bottom content is reachable; disabled controls are not actionable; Playwright actionability does not report intercepted clicks for visible controls.
- **D-15:** Treat Playwright traces as the primary evidence for live-interaction cells, especially focus, scroll, animation, overlay, and LiveView patch behavior. Screenshots and axe are supporting evidence; they do not replace traces for interaction defects.
- **D-16:** Do not encode current broken behavior as permanent tests. Phase 187 may write probe specs or scripts that produce ledger evidence, but regression tests that assert the corrected behavior should be created in Phase 191 when each defect is fixed.

### Baseline Artifacts

- **D-17:** Use a hybrid committed baseline: human-readable markdown plus machine-readable JSON/NDJSON plus an artifact manifest. Markdown alone is too brittle for Phase 192 no-regression comparison.
- **D-18:** Phase 187 should produce these canonical artifacts in the phase directory:
  - `187-RUBRIC.md` - the 12-dimension rubric, scoring anchors, overlay tags, and examples.
  - `187-BASELINE.md` - readable summary, severity-ranked defect ledger, score summaries, and handoff notes.
  - `baseline.cells.json` - canonical scored cell data for every audited surface/mode/state/dimension.
  - `defects.ndjson` - one defect per line with stable IDs and machine-readable fields.
  - `artifacts.manifest.json` - paths/checksums/metadata for screenshots, traces, axe output, and vision findings that are generated during the run but not committed as bulky assets.
  - `schemas/baseline-cell.schema.json` and `schemas/defect.schema.json` if the planner can add them cheaply; otherwise document the schemas in `187-RUBRIC.md` and make schema extraction a Phase 192 guardrail.
- **D-19:** `defects.ndjson` should carry, at minimum: `id`, `severity`, `surface`, `surface_type`, `persona_job`, `reproduction`, `expected`, `actual`, `rubric_dimension`, `overlay_tags`, `cell_id`, `evidence_refs`, `owner_phase`, `status`, and `notes`.
- **D-20:** Use stable defect IDs with a Phase 187 prefix, e.g. `AX187-001`. `owner_phase` should route defects to `188` (foundations), `189` (primitives/forms/lab), `190` (component groups), or `191` (page/flow/interaction/microcopy/seed) so downstream planning can slice work without relitigating ownership.
- **D-21:** `187-BASELINE.md` is the maintainer-readable artifact, but `baseline.cells.json` and `defects.ndjson` are canonical for Phase 192 comparison. If markdown and structured data disagree, structured data wins and markdown must be regenerated or corrected.
- **D-22:** Do not commit generated PNGs or trace zips by default. Store them under `test-results/` or the existing generated-output convention and reference them through `artifacts.manifest.json`. Commit only small representative evidence if a later human sign-off explicitly requires it.
- **D-23:** SARIF/GitHub code-scanning export is optional and not part of Phase 187. UI/design/interaction defects do not map cleanly to static-analysis locations; add SARIF later only if CI annotations become clearly useful.

### Brand, Microcopy, and UX Lens

- **D-24:** The newer `brandbook/` artifacts supersede `prompts/accrue-brand-book.md` where they conflict. The prompt remains useful as historical vision context, not as the binding source.
- **D-25:** Microcopy scoring must follow the ratified brand voice: measured, exact, native, durable. Findings should prefer mechanism-led copy, Phoenix developer vocabulary, precise object names, and proof-checkable claims.
- **D-26:** Empty/error/permission states must be evaluated as operator UX, not decorative copy. A passing state tells the operator what happened, what object or process is affected, and the next useful action when there is one.
- **D-27:** The visual/design lens remains "quiet polish, well-made developer tooling, not fintech." Score defects against `ax-*` tokens and the brandbook palette/voice, not against generic SaaS dashboard taste.

### the agent's Discretion

- Exact file layout under `.planning/phases/187-audit-baseline/`, as long as the artifact names above are present or clearly aliased.
- Exact JSON schema details and helper script names, as long as the minimum fields and canonical structured-data rule are honored.
- Exact probe grouping and Playwright spec structure, as long as all required live probes are covered and the run is repeatable.
- Exact severity scale labels, provided they are rankable, documented, and map to owner phase and remediation urgency.
- Whether to repair known Phase 179 harness robustness issues before running the audit, if those issues would prevent trustworthy Phase 187 evidence.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current Milestone Scope

- `.planning/ROADMAP.md` - Phase 187 goal/success criteria and v1.53 phase sequence.
- `.planning/PROJECT.md` - current v1.53 milestone posture, constraints, and reopen decision.
- `.planning/REQUIREMENTS.md` - v1.53 requirements, especially VER-01, IXN, PAGE, CPY, SEED, and VER-02..04.
- `.planning/STATE.md` - current state, dependency shape, guardrails, and accumulated v1.53 decisions.

### Prior Admin UI Evidence

- `.planning/research/v1.51-admin-ui-depth-design.md` - authoritative prior admin UI design source, 10-dimension rubric, and scope guardrails.
- `.planning/ADMIN-UX-BASELINE-AUDIT.md` - older admin UX baseline and rubric precedent.
- `.planning/milestones/v1.51-phases/176-c-systematic-per-screen-rubric-uplift/176-CONTEXT.md` - prior rubric uplift decisions.
- `.planning/milestones/v1.51-phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md` - prior screen scorecard.
- `.planning/milestones/v1.51-phases/177-d-motion-micro-interaction-design/177-CONTEXT.md` - prior motion/interaction decisions.
- `.planning/milestones/v1.51-phases/178-e-seed-expressiveness-state-coverage/178-CONTEXT.md` - prior state coverage decisions.
- `.planning/milestones/v1.51-phases/178-e-seed-expressiveness-state-coverage/STATE-MATRIX.md` - prior screen x state QA contract.
- `.planning/milestones/v1.51-phases/179-f-screenshot-driven-visual-qa-loop-sign-off/179-CONTEXT.md` - prior screenshot/axe/vision scoring decisions.
- `.planning/milestones/v1.51-phases/179-f-screenshot-driven-visual-qa-loop-sign-off/SIGN-OFF.md` - prior sign-off scaffold and pending photographic gate.
- `.planning/milestones/v1.51-MILESTONE-AUDIT.md` - v1.51 closeout and photographic-sign-off tech-debt.

### Brand and Prompt Corpus

- `brandbook/README.md` - current logo/color/brand asset guidance.
- `brandbook/voice.md` - ratified voice system; binding for microcopy scoring.
- `brandbook/copy.md` - approved copy blocks and microcopy patterns.
- `brandbook/tokens/README.md` - brand token layer and admin `--ax-*` mapping.
- `brandbook/tokens/tokens.json` - brand token SSOT.
- `prompts/accrue-brand-book.md` - older brand seed; use only where it does not conflict with `brandbook/`.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - maintainer preference for subagent-backed research, adopter-facing DX, and done-enough judgment.

### Existing Harness and UI Code

- `accrue_admin/playwright.config.js` - existing desktop/mobile projects and test artifact configuration.
- `accrue_admin/package.json` - E2E scripts and vision scoring script.
- `accrue_admin/e2e/admin-visuals.spec.js` - current 21-surface screenshot sweep.
- `accrue_admin/e2e/admin-a11y.spec.js` - current axe sweep.
- `accrue_admin/e2e/admin-motion-trace.spec.js` - current motion trace suite.
- `accrue_admin/e2e/reduced-motion.spec.js` - reduced-motion assertions.
- `accrue_admin/e2e/score-visuals.mjs` - current vision scoring schema and prompt.
- `accrue_admin/test/support/e2e_fixtures.ex` - E2E seed fixtures and reachable state substrate.
- `accrue_admin/test/support/e2e_plug.ex` - E2E reset/login/seed endpoints.
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` - current `/dev/components` kitchen.
- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` - current component variant registry.
- `accrue_admin/assets/css/theme.css` - admin token SSOT.
- `accrue_admin/assets/css/app.css` - admin component/page CSS and layer/focus/scroll patterns.
- `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` - drawer interaction surface.
- `accrue_admin/lib/accrue_admin/components/global_search.ex` - command palette interaction surface.
- `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` - dropdown/menu interaction surface.
- `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` - modal/focus interaction surface.
- `accrue_admin/lib/accrue_admin/components/flash_group.ex` - toast/flash surface.

### External Primary References

- `https://playwright.dev/docs/test-projects` - Playwright project modes.
- `https://playwright.dev/docs/accessibility-testing` - axe integration and known limitation that automated scans do not catch all WCAG issues.
- `https://playwright.dev/docs/trace-viewer` - traces as interaction debugging/evidence artifacts.
- `https://playwright.dev/docs/actionability` - actionability checks for visible/enabled/receives-events contracts.
- `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html` - DOM-patch-aware JS commands and focus/show/hide primitives.
- `https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/` - modal dialog focus and keyboard behavior.
- `https://www.w3.org/TR/WCAG22/` - WCAG 2.2 conformance model and focus-related criteria.
- `https://jsonlines.org/` - JSON Lines/NDJSON format for streamable findings.
- `https://www.designtokens.org/TR/2025.10/format/` - DTCG design token format context.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `accrue_admin/e2e/admin-visuals.spec.js` already captures 21 primary admin surfaces across desktop/mobile projects and light/dark themes. Extend this into a manifest-driven baseline rather than replacing it.
- `accrue_admin/e2e/admin-a11y.spec.js` already runs axe across the same 21 surfaces in light/dark with reduced-motion emulation to avoid theme-transition contrast noise.
- `accrue_admin/e2e/score-visuals.mjs` already emits structured findings and skips cleanly without `ANTHROPIC_API_KEY`. It needs rubric expansion from 10 to 12 dimensions and possibly schema hardening.
- `accrue_admin/e2e/admin-motion-trace.spec.js` already proves the trace pattern for command palette, dropdown/menu, nav collapse, and webhook replay confirmation. Use this pattern for Phase 187 interaction evidence.
- `accrue_admin/test/support/e2e_fixtures.ex` and `e2e_plug.ex` already provide reset, login, and named fixtures (`dashboard`, `operator-flows`, `edge-states`, `overflow`). Add only the minimum seed/probe support needed to observe Phase 187 matrix gaps honestly.
- `/dev/components` and `ComponentRegistry` already provide a component-lab seed for component rows without adopting PhoenixStorybook.

### Established Patterns

- Custom `ax-*` CSS and tokens are the implementation SSOT; Tailwind is inert and must not become the design-system source.
- Generated screenshot/trace/vision outputs belong under `test-results/` or equivalent generated-output paths, not committed as bulky artifacts.
- Prior v1.51 artifacts separated buildable harness work from human/CI photographic runs and recorded pending gates honestly. Preserve that honesty.
- Phase 187 should route defects to later owner phases instead of fixing them opportunistically.
- Accrue planning artifacts should be readable by humans and structured enough for downstream GSD agents to consume without re-asking.

### Integration Points

- The planner should likely introduce or extend a baseline manifest that feeds visual screenshots, axe scans, interaction probes, and `baseline.cells.json` generation.
- `score-visuals.mjs` consumes screenshots and emits findings; Phase 187 should update it or wrap it so the 12-dimension rubric and stable cell IDs land in structured output.
- Interaction probe specs should reuse the existing Playwright webServer, reset/login/seed helpers, and trace output configuration.
- Phase 192 consumes `baseline.cells.json` and `defects.ndjson` for no-regression comparison; Phases 188-191 consume `owner_phase` and overlay tags for remediation planning.

</code_context>

<specifics>
## Specific Ideas

- The recommended package is deliberately cohesive: 12 dimensions, overlay tags, manifest-driven cells, ledger-first live probes, and hybrid artifacts all support Phase 192's no-regression comparison without turning Phase 187 into a full visual-regression platform.
- The rubric should include examples in `187-RUBRIC.md` for common ambiguous cases:
  - Modal appears behind scrim: dimension `interaction-integrity`, overlay `layer-z-index`.
  - Focus vanishes after LiveView patch: dimension `interaction-integrity`, overlay `live-focus`.
  - Error says only "failed": dimension `microcopy`, overlay `copy-recovery`.
  - Disabled button still looks clickable: dimension `interaction-integrity` or `focus and semantics`, overlay `disabled-affordance`.
  - Dark-mode status chip contrast failure: dimension `contrast`, overlay `dark-mode-role`.
- Severity should consider user impact, reachability, confidence, and downstream blast radius. A good initial scale is `critical`, `high`, `medium`, `low`, with `critical` reserved for blocked primary flows, inaccessible interactions, or evidence that Phase 192 cannot compare the baseline.
- Microcopy findings should name the exact object and recovery step when possible, matching `brandbook/voice.md` and `brandbook/copy.md`.
- If existing Phase 179 review findings still affect trust in `score-visuals.mjs` or `admin-motion-trace.spec.js`, Phase 187 may include small harness hardening before the audit run because unreliable evidence would corrupt the baseline.

</specifics>

<deferred>
## Deferred Ideas

- Full per-defect regression tests for every recorded interaction defect - Phase 191, when each defect is fixed.
- CI no-regression guardrails for every baseline cell - Phase 192.
- SARIF/GitHub code-scanning export for UI defects - optional later tooling if CI annotations become valuable.
- PhoenixStorybook adoption - still deferred; v1.53 extends the in-app `/dev/components` kitchen.

</deferred>

---

*Phase: 187-audit-baseline*
*Context gathered: 2026-06-14*
