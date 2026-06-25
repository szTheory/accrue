# Phase 192: Idempotent verification & sign-off - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 192 is the final verification and sign-off phase for v1.53 Admin UI
Design-System Hardening. It proves the already-remediated `accrue_admin`
surface is done by re-running the Phase 187 audit machinery, scoring every
component, component-group, and page-flow cell with an adversarial multi-lens
judge, confirming the final scorecard is greater than or equal to the Phase 187
baseline on every comparable dimension/cell with zero regressions, wiring
deterministic regression guardrails into CI, and capturing maintainer screenshot
sign-off.

This phase does not reopen Phase 188 foundation decisions, Phase 189 primitive
and component-lab decisions, Phase 190 group contracts, or Phase 191 page-flow
fixes unless the rerun exposes a true regression that blocks VER-02..04. It
does not add billing primitives, public API/route breaks, a Tailwind migration,
PhoenixStorybook, a pixel-diff service, `accrue_portal` work, or a host chrome
redesign.

</domain>

<decisions>
## Implementation Decisions

### Discussion Outcome

- **D-01:** All five gray areas were selected and researched with advisor
  subagents: final scorecard shape, adversarial judge loop, CI guardrail
  boundary, screenshot sign-off package, and regression repair policy.
- **D-02:** The decisions below are locked as a coherent package. Downstream
  agents should not re-ask these questions; research and planning should focus
  on exact implementation.
- **D-03:** The low-confidence todo `White-label billing portal design system`
  was reviewed but not folded. It is future portal/design-system scope, not
  Phase 192 admin verification scope.

### Final Scorecard Shape

- **D-04:** Use a hybrid final scorecard package: machine-readable artifacts for
  CI/idempotency plus maintainer-readable markdown for sign-off. Do not choose
  a markdown-only or JSON-only shape.
- **D-05:** Structured artifacts are canonical. If markdown and structured data
  disagree, structured data wins and the markdown must be regenerated or
  corrected.
- **D-06:** The final package should include, or clearly alias, these artifacts:
  `192-SCORECARD.md`, `final.cells.json`, `scorecard.delta.json`,
  `regressions.ndjson`, `artifacts.manifest.json`, and `192-SIGN-OFF.md`.
- **D-07:** `192-SCORECARD.md` is a readable summary, not the source of truth. It
  should summarize pass/fail, coverage status, regression count, CI guardrail
  status, and maintainer sign-off state.
- **D-08:** Aggregate scores are summary-only. They must never hide a failing
  cell or dimension.

### Cell-By-Cell Comparison

- **D-09:** Preserve the frozen Phase 187 `p187__...__dXX` cell-id grammar,
  12-dimension rubric, state taxonomy, overlay tags, canonical desktop/mobile
  Playwright projects, and targeted-width vocabulary.
- **D-10:** The Phase 192 gate is strict per-cell comparison: every comparable
  final cell must have `final_score >= baseline_score`, with no coverage-status
  downgrade and no new regression row in `regressions.ndjson`.
- **D-11:** If a cell is newly unreachable, missing evidence, or demoted from
  `covered` to `gap`, that is a blocking regression unless the planner can prove
  the Phase 187 cell was invalid and records the correction explicitly.
- **D-12:** Baseline semantics must not be reinterpreted to make the final pass.
  Corrections to stale or impossible baseline rows need explicit structured
  notes and readable explanation.

### Adversarial Multi-Lens Judge

- **D-13:** Implement the judge as a layered evidence system, not as an LLM-only
  visual scoring run.
- **D-14:** Keep raw lens outputs separate: correctness/browser behavior,
  axe/WCAG a11y, reduced motion, component-lab/group/page coverage, interaction
  traces, visual/brand/microcopy scoring, and maintainer screenshot review.
- **D-15:** The final synthesis step should be a pure reducer over raw evidence:
  it normalizes evidence to canonical cell IDs, compares against Phase 187
  baseline cells, writes deltas/regressions, and emits readable summaries.
- **D-16:** Every final score, downgrade, regression, or sign-off row must cite
  concrete evidence references. Evidence paths belong in `artifacts.manifest.json`
  or generated-output locations, not as bulky committed PNG/trace artifacts.
- **D-17:** `score-visuals.mjs` may contribute advisory visual, brand, hierarchy,
  and microcopy findings. It must not be the sole gate for accessibility,
  interaction integrity, focus, scroll, overlay actionability, or CI pass/fail.
- **D-18:** Automated axe checks are necessary but not sufficient accessibility
  proof. Keep browser/focus/keyboard/trace evidence for the defects screenshots
  and static scans miss.
- **D-19:** Human or agent review tables are acceptable for subjective brand and
  screenshot sign-off only when each row links to deterministic evidence and
  has an explicit accept/block status.

### CI Guardrail Boundary

- **D-20:** CI should block on deterministic, bounded checks that contributors
  can reproduce locally without secrets or subjective review.
- **D-21:** Existing BEAM/package CI remains required: format, compile with
  warnings as errors, tests, credo, dialyzer, docs, audit, and existing package
  contract verifiers.
- **D-22:** Keep `admin-group-contracts` merge-blocking.
- **D-23:** Add or extend an admin hardening CI job that runs:
  `cd accrue_admin && npm run baseline:parse`;
  `node scripts/ci/verify_phase191_ax187_coverage.mjs`;
  `cd accrue_admin && npm run e2e:group-contracts`;
  `cd accrue_admin && npm run e2e:phase191`;
  `cd accrue_admin && npm run e2e:a11y`;
  `cd accrue_admin && npx playwright test e2e/reduced-motion.spec.js --workers=1`;
  and a component-lab structural coverage check through the existing registry,
  ExUnit, or verifier path.
- **D-24:** Do not make `npm run e2e` as-is merge-blocking. It runs every spec
  under `accrue_admin/e2e`, including baseline capture, visual capture, trace,
  and older UAT-style suites, which is too broad and flaky for PR CI.
- **D-25:** Do not make `score-visuals` merge-blocking. It depends on generated
  screenshots, secrets/model availability, and subjective model output; it also
  skips cleanly when no API key is present, which would create false-green risk.
- **D-26:** Do not treat `baseline:artifacts` success as proof the UI passed.
  The artifact generator can preserve producer failures as audit evidence. It
  belongs in final/manual verification or a workflow-dispatch evidence run, not
  as a simple PR blocker.
- **D-27:** Screenshot capture, trace capture, baseline regeneration,
  `score-visuals`, full `npm run e2e`, and maintainer sign-off remain
  Phase-192 final verification or advisory/generated evidence, not required on
  every pull request.
- **D-28:** Upload Playwright reports, screenshots, traces, and generated
  evidence as CI artifacts where useful. Do not commit bulky PNG or ZIP outputs
  by default.

### Screenshot Sign-Off Package

- **D-29:** The maintainer signs off on `192-SIGN-OFF.md`, not on raw
  `test-results/` or the full 21,276-cell corpus.
- **D-30:** `192-SIGN-OFF.md` should contain executive pass/fail, baseline
  comparison summary, CI guardrail status, curated gallery index, artifact
  manifest links, and a maintainer checklist.
- **D-31:** Use "scorecard plus curated gallery plus human checklist" as the
  sign-off package. Phase-boundary screenshots alone are insufficient because
  they are chronology-focused and can repeat v1.51's still-image weakness.
- **D-32:** The curated gallery must be JTBD-first. Each row should name `who`,
  `job`, `route/surface`, `state`, `theme`, `viewport`, and why the screenshot
  matters.
- **D-33:** Include representative screenshots for dashboard health scan,
  customer inspection, subscription triage/detail, invoice/payment review,
  webhook/event debugging, recovery campaign, component lab, modal/drawer/dropdown
  open states, and empty/error/permission/disconnected states.
- **D-34:** For each selected flow, include light and dark screenshots. Include
  mobile for layout-risk flows. Include system-theme behavior only if the
  harness can prove it deterministically.
- **D-35:** Include focused, hover, disabled/read-only, and open-state screenshots
  for historical-risk controls: command palette, dropdowns, drawers, modals,
  mobile nav, destructive confirmations, and disabled/read-only actions.
- **D-36:** Link traces for focus trap, focus restore, Escape, outside click,
  scroll reachability, LiveView patch focus, and actionability. Do not ask the
  maintainer to infer these behaviors from still screenshots.
- **D-37:** The maintainer checklist should approve JTBD clarity, domain
  vocabulary, microcopy recovery, brand fit, accessible focus/contrast, mobile
  usability, dark-mode role clarity, and absence of backend-guts presentation.

### UI/UX, Brand, And Domain Language

- **D-38:** The sign-off surface should be operator- and maintainer-friendly, not
  a backend implementation dump. Use domain nouns and verbs: customer,
  subscription, invoice, charge/payment, webhook, event, recovery, Connect
  account; inspect, filter, replay, refund, void, recover, clear filters.
- **D-39:** Brand review follows the ratified brandbook, not the older prompt if
  they conflict: measured, exact, native, durable; quiet well-made developer
  tooling; `ax-*` admin tokens as implementation SSOT; no fintech/startup gloss.
- **D-40:** Microcopy sign-off should check that states name what happened, the
  affected object/process, and the next useful action where one exists.
- **D-41:** UI sign-off should explicitly consider accessibility, performance,
  responsive layout, light/dark/system theme behavior where supported,
  interaction integrity, focus/hover/disabled affordance, information hierarchy,
  brand expression, and developer/operator DX.

### Regression Repair Policy

- **D-42:** Inline fixes are allowed in Phase 192 only for harness, parser,
  artifact-reference, CI wiring, or evidence-normalization defects that prevent
  trustworthy verification.
- **D-43:** True UI, accessibility, interaction, copy, component, group, or
  page-flow regressions are blocking. They should become narrowly scoped Phase
  192 repair plans/subplans, then the scorecard must be rerun.
- **D-44:** Deferrals are allowed only for explicitly out-of-scope items or newly
  discovered improvements that are not regressions against Phase 187 and do not
  block VER-02..04. Deferrals need an explicit maintainer-approved note.
- **D-45:** Do not encode broken Phase 187 observations as expected final
  behavior. Phase 191 corrected behavior is the regression target.

### Claude's Discretion

- Exact filenames, script names, and schema field names may be adjusted by the
  researcher/planner if the artifacts above are present or clearly aliased and
  the structured-data precedence rule holds.
- Exact CI job topology is planner discretion: extend `admin-group-contracts`,
  add a new `admin-hardening-guardrails` job, or use a workflow-dispatch final
  evidence run, as long as deterministic PR gates and final evidence runs remain
  separate.
- Exact curated gallery size is planner discretion, but it must be small enough
  for maintainer review and broad enough to cover the JTBD/risk categories above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current Phase Scope

- `.planning/ROADMAP.md` - Phase 192 goal, dependency on Phase 191, success
  criteria, and v1.53 execution model.
- `.planning/REQUIREMENTS.md` - VER-02, VER-03, VER-04 and v1.53 out-of-scope
  constraints.
- `.planning/PROJECT.md` - v1.53 milestone posture, admin UI hardening rationale,
  no-new-feature boundary, and sign-off context.
- `.planning/STATE.md` - current milestone state, accumulated v1.53 decisions,
  and Phase 192 carry-forward notes.

### Baseline And Comparison Contract

- `.planning/phases/187-audit-baseline/187-CONTEXT.md` - Phase 187 baseline
  decisions, artifact precedence, and scorecard contract.
- `.planning/phases/187-audit-baseline/187-RUBRIC.md` - 12 rubric dimensions,
  overlay tags, state taxonomy, severity, ownership, and scoring rules.
- `.planning/phases/187-audit-baseline/187-BASELINE.md` - maintainer-readable
  baseline summary and rerun commands.
- `.planning/phases/187-audit-baseline/baseline.cells.json` - canonical baseline
  cells for Phase 192 comparison.
- `.planning/phases/187-audit-baseline/defects.ndjson` - canonical Phase 187
  defect ledger and AX187 IDs.
- `.planning/phases/187-audit-baseline/artifacts.manifest.json` - Phase 187
  generated evidence reference pattern.
- `.planning/phases/187-audit-baseline/schemas/baseline-cell.schema.json` -
  baseline cell schema.
- `.planning/phases/187-audit-baseline/schemas/defect.schema.json` - defect
  ledger schema.

### Prior Phase Decisions And Verification

- `.planning/phases/188-foundations-hardening/188-CONTEXT.md` - foundation
  tokens, semantic roles, focus/disabled/read-only/status roles, motion, layer,
  and Tailwind SSOT decisions that Phase 192 must preserve.
- `.planning/phases/189-primitive-form-components-component-lab/189-CONTEXT.md`
  - primitive/form decisions, component-lab single-column global-theme reversal,
  and state-matrix verification decisions.
- `.planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md`
  - group proof model, group contracts, and Phase 191 handoff boundaries.
- `.planning/phases/190-navigation-data-display-meta-component-cohesion/190-GROUP-CONTRACTS.md`
  - recurring component-group contracts to preserve.
- `.planning/phases/191-page-flow-interaction-pass-fixture-stress-microcopy/191-CONTEXT.md`
  - locked page-flow, interaction, fixture, microcopy, and verification decisions.
- `.planning/phases/191-page-flow-interaction-pass-fixture-stress-microcopy/191-UI-SPEC.md`
  - Phase 191 corrected behavior and UI contract.
- `.planning/phases/191-page-flow-interaction-pass-fixture-stress-microcopy/191-AX187-COVERAGE.md`
  - AX187 closure evidence for Phase 191-owned defects.
- `.planning/phases/191-page-flow-interaction-pass-fixture-stress-microcopy/191-VERIFICATION.md`
  - Phase 191 verification status and evidence.
- `.planning/debug/resolved/phase-187-baseline-timeout.md` - resolved
  `probeAffordanceAndStates` timeout and bounded-hover lesson relevant to final
  reruns.

### v1.51 Sign-Off Debt And Brand

- `.planning/v1.51-MILESTONE-AUDIT.md` - photographic sign-off tech-debt Phase
  192 closes.
- `.planning/milestones/v1.51-phases/179-f-screenshot-driven-visual-qa-loop-sign-off/SIGN-OFF.md`
  - prior screenshot/axe/motion sign-off scaffold and pending-gate pitfalls.
- `brandbook/voice.md` - ratified voice: measured, exact, native, durable.
- `brandbook/copy.md` - approved microcopy patterns and mechanism-led wording.
- `brandbook/tokens/README.md` - brand/admin token relationship; admin `--ax-*`
  tokens remain implementation SSOT.
- `brandbook/tokens/tokens.json` - brand token SSOT.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - maintainer preference for
  subagent-backed research, idiomatic Elixir/Phoenix lens, DX/UX-first judgment,
  proof honesty, and done-enough restraint.
- `prompts/accrue-brand-book.md` - historical brand seed only where it does not
  conflict with ratified `brandbook/`.

### Code And CI Surfaces

- `accrue_admin/package.json` - current E2E, a11y, phase191, group-contract,
  score-visuals, and baseline artifact scripts.
- `accrue_admin/playwright.config.js` - Playwright projects, artifact behavior,
  and browser test configuration.
- `accrue_admin/e2e/baseline-manifest.js` - canonical dimensions, state
  taxonomy, projects, themes, surface definitions, component groups, and cell-id
  grammar.
- `accrue_admin/e2e/baseline-artifacts.mjs` - baseline/final artifact generation
  pattern to extend or mirror.
- `accrue_admin/e2e/admin-baseline.spec.js` - baseline/final capture entry point.
- `accrue_admin/e2e/admin-interactions.spec.js` - live interaction probes,
  trace-backed observation pattern, and actionability/focus/scroll coverage.
- `accrue_admin/e2e/admin-a11y.spec.js` - light/dark axe sweep pattern.
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js` - Phase 191 page-flow and
  interaction regression suite.
- `accrue_admin/e2e/admin-group-contracts.spec.js` - Phase 190 group-contract
  browser gate.
- `accrue_admin/e2e/admin-visuals.spec.js` - screenshot capture pattern for
  curated gallery/final evidence.
- `accrue_admin/e2e/admin-motion-trace.spec.js` - trace capture pattern for live
  motion/interaction review.
- `accrue_admin/e2e/reduced-motion.spec.js` - reduced-motion guardrail.
- `accrue_admin/e2e/score-visuals.mjs` - advisory visual/brand/microcopy scoring
  layer; not a sole gate.
- `scripts/ci/verify_phase191_ax187_coverage.mjs` - fast source/coverage
  verifier for Phase 191 AX187 closure.
- `scripts/ci/verify_phase190_automation_contract.sh` - group-contract CI pattern.
- `scripts/ci/verify_package_docs.sh` - existing package/documentation verifier
  and design-system static guard pattern.
- `scripts/ci/verify_foundation_contrast.mjs` - foundation contrast verifier.
- `.github/workflows/ci.yml` - main CI workflow and existing admin group-contract
  job.
- `.github/workflows/accrue_admin_browser.yml` - fast mounted admin browser proof
  workflow.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `baseline-manifest.js` already owns the 12 dimensions, themes, projects,
  state taxonomy, surface inventory, component groups, and `cellId` grammar.
  Phase 192 should consume it instead of inventing another matrix vocabulary.
- `baseline-artifacts.mjs` already produces `baseline.cells.json`,
  `defects.ndjson`, `artifacts.manifest.json`, and markdown from generated
  Playwright/vision evidence. Phase 192 can extend or mirror this for final
  artifacts and scorecard deltas.
- `admin-baseline.spec.js`, `admin-interactions.spec.js`, `admin-a11y.spec.js`,
  `admin-visuals.spec.js`, `admin-motion-trace.spec.js`, `reduced-motion.spec.js`,
  `admin-group-contracts.spec.js`, and `admin-page-flow-phase191.spec.js` are the
  existing evidence producers. Keep evidence producer responsibilities separate.
- `score-visuals.mjs` already handles credential absence safely. Treat that as a
  feature for manual/advisory scoring, not as a CI pass signal.
- `verify_phase191_ax187_coverage.mjs` gives Phase 192 a fast fail-closed check
  that the Phase 191 AX187 closure map remains wired.
- `ComponentRegistry`, `ComponentGroupRegistry`, and the `/billing/dev/components`
  kitchen are the component-lab structural coverage spine.

### Established Patterns

- Generated screenshots, traces, reports, and vision outputs stay under
  `accrue_admin/test-results`, `playwright-report`, CI artifacts, or another
  ignored/generated-output location. Planning docs store paths, hashes, summaries,
  and decisions.
- Admin design implementation uses custom `ax-*` CSS and `--ax-*` tokens as SSOT.
  Brandbook tokens document the brand layer but do not replace admin tokens.
- GSD phase artifacts should be both human-readable and structured enough for
  downstream agents; markdown-only verification is too weak for this phase.
- Contributor-facing PR CI should be bounded, deterministic, and reproducible
  without secrets. Expensive, subjective, or artifact-heavy evidence belongs in
  final verification/manual runs.
- Browser-level tests are required for LiveView JS, focus, scroll, overlay,
  hover/actionability, and reduced-motion behavior that server-side LiveView
  tests cannot observe.

### Integration Points

- CI integration likely lands in `.github/workflows/ci.yml` or
  `.github/workflows/accrue_admin_browser.yml`, with artifact upload on failure.
- Final scorecard generation likely connects to `accrue_admin/e2e/` artifact
  scripts plus `.planning/phases/187-audit-baseline/` structured baseline files.
- Sign-off artifacts land in `.planning/phases/192-idempotent-verification-sign-off/`
  with generated binary evidence referenced, not committed.
- Component-lab coverage should integrate through existing ExUnit registry tests,
  browser group-contract tests, or a small static verifier rather than screenshot
  comparison.

</code_context>

<specifics>
## Specific Ideas

- The final acceptance packet should read like an operator/admin UX review, not
  a backend implementation dump. Use JTBD rows and domain verbs instead of route
  or module-name soup.
- Keep the scorecard reducer boring and deterministic. The creativity belongs in
  the curated gallery and brand/microcopy review, not in the pass/fail algorithm.
- Use `192-SIGN-OFF.md` to explicitly close the v1.51 photographic-sign-off
  tech-debt, including a note that Phase 192 now covers screenshots, axe, traces,
  interaction probes, CI guardrails, and structured no-regression deltas.
- If the planner introduces a single convenience command such as
  `npm run verify:phase192`, it should orchestrate deterministic local checks and
  clearly separate optional/manual evidence commands that need screenshots,
  traces, or API keys.
- Official guidance used during discussion supports this split: Playwright/axe
  are suitable for automated a11y checks but not complete accessibility proof;
  Playwright traces/actionability are the right evidence for interaction behavior;
  GitHub Actions artifacts are short-lived generated evidence, not durable
  committed source.

</specifics>

<deferred>
## Deferred Ideas

### Reviewed Todos (not folded)

- `White-label billing portal design system` - reviewed from
  `.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`
  and not folded. It concerns future portal/UI design-system scope; Phase 192 is
  limited to `accrue_admin` v1.53 verification and sign-off.

</deferred>

---

*Phase: 192-idempotent-verification-sign-off*
*Context gathered: 2026-06-19*
