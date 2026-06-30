# Phase 200: Idempotent verification & sign-off - Context

**Gathered:** 2026-06-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 200 closes v1.54 by proving the already-built `accrue_admin` surface is
forward-only at the union baseline, completing PhoenixStorybook coverage and
theming, running final rendered accessibility/theme/interaction guardrails, and
recording explicit maintainer ACCEPT/REJECT sign-off.

This is a verification and sign-off phase, not another design or product phase.
Allowed implementation is limited to Storybook completeness/theming, scorecard
harness/artifact work, deterministic guardrail wiring, evidence normalization,
and narrow repairs for blocking regressions discovered by those gates.

Fixed guardrails: scope is the `accrue_admin` operator UI only; no
`accrue_portal` work; no brandbook production changes; no new billing
primitives, domain features, or breaking API/route changes; no Tailwind
migration; PhoenixStorybook stays dev/test-only; the in-app `/dev/components`
kitchen remains the second renderer and drift-test target; pixel-diff/SaaS
visual-regression stays deferred.

</domain>

<decisions>
## Implementation Decisions

### Cohesive Recommendation

- **D-01 - Use a staged-full Phase 200 closeout.** Run deterministic guardrails
  during implementation and CI, then generate the full union scorecard and
  sign-off package at closeout. Do not run expensive/full visual or human-review
  gates on every PR.
- **D-02 - Keep Phase 200 verification-only.** Fold none of the matched todos
  into scope. Verification fixes are allowed only when a Phase 200 gate exposes
  a blocking regression in already-scoped admin UI behavior.
- **D-03 - Slice planning into reproducible waves.** Recommended shape:
  Storybook completeness/theming, Storybook + route a11y/theme guardrails,
  union scorecard/artifact verifier, bounded multi-lens judge, maintainer
  sign-off + state/requirements reconciliation.

### Scope and Todo Boundary

- **D-04 - Reviewed todos are not folded.** The white-label billing portal todo
  is future `accrue_portal` scope; the PageHeader todo was resolved by Phases
  196/197 and should only be verified as part of existing PageHeader/list
  coverage; the brandbook favicon todo targets `brandbook/index.html`, not admin
  UI sign-off.
- **D-05 - No broad polish while verifying.** Subjective improvements that do
  not cite a locked requirement, rubric dimension, brandbook rule, component
  contract, page-flow contract, or Phase 199 interaction contract are advisory or
  future-roadmap material.

### PhoenixStorybook Completeness and Theming

- **D-06 - Use a hybrid Storybook strategy.** Generated registry-driven stories
  are the non-negotiable coverage floor; hand-written or curated wrappers are
  allowed only for composites, named slots, overlays/drawers, and design-lab
  examples that cannot be expressed by flat specimens.
- **D-07 - `ComponentRegistry` remains the single source of truth.** Story files
  may call `RegistryStory`, add templates, or group variations, but they must not
  duplicate variant names, tokens, required states, or specimen data.
- **D-08 - Storybook completeness is dynamic.** Current scout found
  `ComponentRegistry.entries/0` reports 30 unique families and 42 entries, and
  `group_contracts/0` reports 8 groups. Tests should derive the required family,
  variant, and group counts from the registry rather than freezing these numbers.
- **D-09 - Extend the registry story support.** `RegistryStory` should support
  state groups, `na_states` notes, stable slugified IDs, unique DOM IDs, and
  named-slot/template escape hatches. Group stories should be driven by
  `group_contracts/0`, render the proof id/slug/required states/hierarchy/
  behavior contracts, and include one representative composition with stable
  `data-component-group` markers.
- **D-10 - Keep `/dev/components` green.** Do not move Phase-189/190 drift tests
  to Storybook. Storybook is the human-facing design lab; `/dev/components` is
  the deterministic second renderer.
- **D-11 - Prove Storybook theme parity against the shipped bundle.** Enable
  PhoenixStorybook color mode explicitly, keep
  `color_mode_sandbox_dark_class: "ax-theme-dark-shim"`, load committed
  `storybook.css` / `storybook.js`, and add a parity guard so dark token changes
  in `theme.css` cannot silently miss the Storybook shim. Do not rebuild Tailwind
  or create a separate styling surface.
- **D-12 - Verify Storybook assets and adopter leak boundaries.** Storybook CSS
  and JS routes must return 200 under the mounted app path. `phoenix_storybook`
  remains `only: [:dev, :test]`; host/adopter compile must succeed without
  exposing `/dev/storybook`.

### Forward-Only Scorecard

- **D-13 - Score against the union baseline.** Canonical Phase 200 baseline is
  the union of `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.cells.json`
  (21,276 component/group cells) plus
  `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.page-flow.cells.json`
  (9,072 Phase-193 page-flow cells), for 30,348 rows unless duplicate checks
  prove otherwise.
- **D-14 - Do not mutate archived baselines.** Improvements are positive
  `score_delta` rows. Invalid historical rows require explicit
  `baseline_correction` rows with reason and evidence.
- **D-15 - Pending page-flow cells must close.** `p193` page-flow cells that
  entered as pending/null baseline coverage must finish as `covered` with score
  floor `>= 2`; missing evidence is a blocker.
- **D-16 - Phase 200 artifacts are Phase 200 artifacts.** Create or parameterize
  scorecard/sign-off scripts so outputs land under
  `.planning/phases/200-idempotent-verification-sign-off/`: `baseline.union.cells.json`,
  `final.cells.json`, `scorecard.delta.json`, `regressions.ndjson`,
  `artifacts.manifest.json`, `200-SCORECARD.md`, `200-STORYBOOK-COVERAGE.md`,
  `200-SIGN-OFF.md`, and `200-VERIFICATION.md`. Do not write into archived
  Phase 192 paths.
- **D-17 - `regressions.ndjson` is the hard close signal.** It must be empty for
  ACCEPT. Non-empty rows block sign-off until repaired and rerun.
- **D-18 - CI stays deterministic.** CI should run baseline parse, scorecard
  verifier, sign-off verifier, package docs, registry/group tests, axe,
  reduced-motion, Phase 199 E2E, Storybook structural/theming checks, and host
  leak checks. It should not run model-dependent visual scoring or maintainer
  sign-off generation on every PR.

### Accessibility, Theme, Motion, and Browser Guardrails

- **D-19 - Use a hybrid risk matrix, not exhaustive Cartesian testing.** Axe
  all primary rendered admin routes and all completed Storybook stories in
  settled light/dark. Pair that with targeted Playwright coverage for known-risk
  interactions, theme boot, reduced motion, overlay/focus behavior, copy, and
  layout stress.
- **D-20 - Theme/no-FOUC tests must use the production path.** Do not set
  `data-theme` directly when proving persistence or first paint. Use the
  production `accrue_theme` cookie/localStorage key plus Playwright system
  dark/light emulation, including malformed values and reload behavior. Direct
  `data-theme` forcing is allowed only for settled visual/axe matrix scans and
  must be labeled as bypassing production boot.
- **D-21 - Axe is required but not sufficient.** Critical/serious color-contrast
  and name/role failures block sign-off. Focus order, trap/restore,
  Escape/backdrop behavior, keyboard operation, status messages, text reflow,
  copy clarity, and brand/JTBD fit remain Playwright/judge/maintainer
  responsibilities.
- **D-22 - Keep browser gates stable.** Use deterministic reset/seed endpoints,
  package-local Playwright, `env -u NO_COLOR`, one worker for stateful admin
  matrices, web-first assertions, and traces/screenshots on failure. Avoid broad
  sleeps and broad pixel-diff approval.
- **D-23 - Reduced-motion proof must be behavioral.** Verify computed duration
  and travel collapse plus real overlay/floating behavior; token presence alone
  is insufficient.

### Multi-Lens Judge and Maintainer Sign-Off

- **D-24 - `200-SIGN-OFF.md` is the sole final maintainer decision surface.**
  The final line must be exactly one of `Final maintainer decision: ACCEPT ...`
  or `Final maintainer decision: REJECT ...`.
- **D-25 - Structured artifacts are canonical.** Markdown summaries explain
  results but never override `final.cells.json`, `scorecard.delta.json`,
  `regressions.ndjson`, `artifacts.manifest.json`, Storybook coverage output,
  and judge findings.
- **D-26 - Bound the judge to four lenses.** Correctness, accessibility, brand,
  and interaction are the only judge lenses. A finding can block only if it cites
  a locked requirement, Phase-187 rubric dimension, brandbook rule, component/
  group/page-flow contract, or Phase-199 interaction contract plus evidence.
- **D-27 - Severity semantics are fixed.** Blocking severities are `BLOCKER` and
  `REPAIR-IN-PHASE`; nonblocking severities are `ADVISORY` and `DEFERRED`.
  Subjective "could be better" observations without a locked reference cannot
  block.
- **D-28 - ACCEPT is all-or-nothing.** ACCEPT requires empty `regressions.ndjson`,
  no coverage downgrade, all comparable union-baseline cells >= baseline, all
  deterministic guardrails green, Storybook coverage/theming green, curated
  checkpoint rows accepted, and no unresolved `BLOCKER` or `REPAIR-IN-PHASE`
  judge findings.
- **D-29 - REJECT names repairs.** A REJECT decision should list blocking finding
  IDs and require narrow repair subplans plus rerun of scorecard/sign-off before
  replacing the decision.
- **D-30 - Prefer traces for interaction evidence.** Screenshot galleries are
  useful curated review aids, but focus, Escape, outside click, scroll lock,
  actionability, theme persistence, and reduced motion should cite Playwright
  trace or deterministic test evidence.
- **D-31 - No pending human state at close.** Final close must not leave
  `human_needed`, `pending`, stale requirement checkboxes, or missing Phase 200
  verification/sign-off artifacts.

### Claude's Discretion

- Exact file names and script names for Phase 200 harnesses, provided outputs use
  the Phase 200 directory and do not mutate archived Phase 192/v1.53 artifacts.
- Exact Storybook module layout, provided the registry remains SSOT and all
  families/groups are discovered and verified dynamically.
- Exact route/story batch sizes for browser scans, provided all primary admin
  routes and all completed stories receive settled light/dark axe coverage, and
  the known-risk matrix covers theme/no-FOUC, reduced motion, overlay/focus,
  disabled/hover affordances, long content, and boundary fixtures.
- Exact wording of sign-off summaries, bounded by `brandbook/voice.md`:
  measured, exact, native, durable, and proof-oriented.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements

- `.planning/ROADMAP.md` - Phase 200 goal, success criteria, v1.54 guardrails,
  and Phase 200 boundary.
- `.planning/REQUIREMENTS.md` - VER-01, VER-02, VER-03, STY-02, and STY-03
  mapping plus v1.54 exclusions.
- `.planning/STATE.md` - current milestone state and Phase 199 completion notes.
- `.planning/PROJECT.md` - stable-core posture and v1.54 strategic reopen
  decision.

### Prior Phase Decisions and Evidence

- `.planning/phases/193-research-re-baseline-pattern-lock/193-CONTEXT.md` -
  Storybook posture, page-flow baseline context, source-guard strategy, and
  archetype contracts.
- `.planning/phases/193-research-re-baseline-pattern-lock/193-VERIFICATION.md` -
  Phase 193 verification and Storybook/page-flow setup evidence.
- `.planning/phases/196-exemplar-c-subscriptions-list-pageheader/196-CONTEXT.md`
  - PageHeader and LIST exemplar boundary.
- `.planning/phases/197-propagate-list/197-CONTEXT.md` - LIST propagation,
  PageHeader adoption, and reviewed todo boundary.
- `.planning/phases/198-propagate-detail-analytics/198-CONTEXT.md` - DETAIL and
  analytics propagation, action/drawer flows, and Phase 199/200 boundary.
- `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-CONTEXT.md`
  - overlay, fixture stress, theme persistence, reduced-motion, and microcopy
  decisions handed to Phase 200 for final verification.
- `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-VERIFICATION.md`
  - Phase 199 proof that overlay/focus/scroll/theme/copy behavior is green.
- `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-VALIDATION.md`
  - Phase 199 validation state and remaining boundary context.

### Baseline, Scorecard, and Sign-Off Sources

- `.planning/milestones/v1.53-phases/187-audit-baseline/187-RUBRIC.md` -
  12-dimension rubric used by the forward-only scorecard.
- `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.cells.json` -
  archived component/group baseline, 21,276 cells.
- `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.page-flow.cells.json`
  - Phase-193 page-flow baseline, 9,072 cells.
- `.planning/milestones/v1.53-phases/187-audit-baseline/defects.ndjson` -
  prior defect ledger and owner-phase routing context.
- `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/192-CONTEXT.md`
  - prior closeout context and precedent.
- `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/192-SCORECARD.md`
  - prior final scorecard shape.
- `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/192-SIGN-OFF.md`
  - prior maintainer ACCEPT sign-off shape.
- `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/192-VERIFICATION.md`
  - prior closeout verification report.
- `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/final.cells.json`
  - prior final-cell artifact shape.
- `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/scorecard.delta.json`
  - prior scorecard delta artifact shape.
- `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/regressions.ndjson`
  - prior zero-regression artifact shape.
- `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/artifacts.manifest.json`
  - prior evidence manifest shape.
- `.planning/milestones/v1.53-MILESTONE-AUDIT.md` - lesson that closeout risk is
  documentation/traceability drift, not just implementation.
- `.planning/v1.51-MILESTONE-AUDIT.md` - prior photographic sign-off tech-debt
  pattern to avoid.
- `.planning/MILESTONES.md` - v1.53 closeout summary and accepted evidence
  posture.
- `.planning/RETROSPECTIVE.md` - local lessons on only-forward baselines,
  scorecards, screenshot limits, and structured artifacts.

### v1.54 Research and Design Contracts

- `.planning/research/SUMMARY.md` - v1.54 synthesis: structural defects, rendered
  matrix, Storybook, and forward-only expectations.
- `.planning/research/v1.54-storybook-and-forward-only-qa.md` - Storybook and
  forward-only QA design.
- `.planning/research/ARCHITECTURE.md` - overlay, motion, and interaction
  acceptance criteria.
- `.planning/research/PITFALLS.md` - known failure modes for overlays, theme,
  truncation, disabled/focus/contrast, and false affordances.
- `.planning/research/FEATURES.md` - UI/JTBD rationale for v1.54 page-level
  work.
- `.planning/research/STACK.md` - Elixir/Phoenix stack posture and package
  boundaries.
- `accrue_admin/guides/spec-overview.md` - overview page contract.
- `accrue_admin/guides/spec-list.md` - LIST contract.
- `accrue_admin/guides/spec-detail.md` - DETAIL contract.
- `accrue_admin/guides/motion.md` - motion token and reduced-motion contract.
- `accrue_admin/guides/admin_ui.md` - admin UI integration principles and
  committed bundle expectations.

### Storybook and Design-System Code

- `accrue_admin/mix.exs` - dev/test-only `phoenix_storybook`, elixirc paths, docs
  posture, and package file boundary.
- `accrue_admin/package.json` - E2E, scorecard, guardrail, and Phase 192 script
  precedents.
- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` - registry family
  entries, specimens, tokens, state metadata, and eight group contracts.
- `accrue_admin/lib/accrue_admin/dev/storybook.ex` - PhoenixStorybook setup,
  sandbox class, asset paths, and dark shim.
- `accrue_admin/storybook/_support/registry_story.ex` - current registry-to-
  variation support module that Phase 200 must extend.
- `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` - current
  registry/kitchen drift tests.
- `accrue_admin/test/accrue_admin/dev/component_group_registry_test.exs` -
  current group-contract and `/dev/components` proof tests.
- `accrue_admin/assets/css/theme.css` - `ax-*` tokens and dark theme source.
- `accrue_admin/assets/css/app.css` - component CSS and interaction source.
- `accrue_admin/priv/static/storybook.css` - committed Storybook CSS bundle.
- `accrue_admin/priv/static/storybook.js` - committed Storybook JS bundle.

### Browser, Theme, and Accessibility Verification

- `accrue_admin/e2e/baseline-manifest.js` - current manifest for dimensions,
  state taxonomy, component/group/page-flow surfaces.
- `accrue_admin/e2e/baseline-artifacts.mjs` - baseline artifact generation
  precedent.
- `accrue_admin/e2e/phase192-scorecard.mjs` - prior scorecard reducer to
  parameterize or copy narrowly for Phase 200 paths.
- `accrue_admin/e2e/score-visuals.mjs` - model/vision scoring precedent; must
  not silently satisfy visual/brand cells if skipped.
- `scripts/ci/verify_phase192_scorecard.mjs` - prior scorecard verifier shape.
- `scripts/ci/verify_phase192_signoff.mjs` - prior sign-off verifier shape.
- `scripts/ci/verify_phase192_admin_guardrails.sh` - prior deterministic
  guardrail bundle.
- `accrue_admin/e2e/admin-a11y.spec.js` - current primary-route axe scan.
- `accrue_admin/e2e/reduced-motion.spec.js` - reduced-motion browser contract.
- `accrue_admin/e2e/admin-group-contracts.spec.js` - group-contract browser
  coverage.
- `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` - Phase 199
  overlay/fixture/theme/copy stress spec.
- `accrue_admin/e2e/phase191-page-flow-helpers.js` - reusable clipping, focus,
  hit-test, scroll, theme, and route-flow helpers.
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js` - page-flow driver pattern.
- `accrue_admin/test/accrue_admin/theme_test.exs` - anti-FOUC ordering,
  production key, malformed cookie, and fixed-shell source audit.
- `accrue_admin/lib/accrue_admin/layouts.ex` - root layout, overlay root, and
  anti-FOUC script.
- `accrue_admin/assets/js/hooks/accrue_theme.js` - production theme key and
  theme control behavior.
- `accrue_admin/assets/js/hooks/overlay.js`, `focus_trap.js`, and
  `scroll_lock.js` - overlay, focus, and scroll behavior consumed by final
  interaction evidence.

### Brand, Voice, and Prompt Inputs

- `brandbook/voice.md` - current voice SSOT: measured, exact, native, durable.
- `brandbook/copy.md` - approved microcopy posture and examples.
- `brandbook/tokens/README.md` - brand token documentation; admin `--ax-*`
  tokens remain implementation SSOT.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - proof-over-polish and
  adopter-value lens.
- `prompts/accrue-brand-book.md` - older brand seed; use only where it
  reinforces `brandbook/`, and prefer `brandbook/` on conflict.

### Reviewed Todos

- `.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`
  - reviewed and not folded; future `accrue_portal` scope.
- `.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md`
  - reviewed and not folded; resolved by Phases 196/197, verify only.
- `.planning/todos/pending/2026-06-19-brandbook-use-accrue-favicon.md` -
  reviewed and not folded; brandbook scope.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`ComponentRegistry.entries/0` and `group_contracts/0`** already provide the
  Storybook source inventory: families, specimens, tokens, applicable states,
  N/A states, and eight group contracts.
- **`AccrueAdmin.Dev.Storybook`** is already wired as dev/test-only with
  committed asset paths, `sandbox_class: "accrue-admin"`, and dark shim class.
- **`AccrueAdmin.Storybook.RegistryStory`** already converts registry specimens
  into PhoenixStorybook variations; it needs expansion for groups, state notes,
  templates, and coverage verification.
- **`/billing/dev/components` kitchen** remains the mature second renderer with
  drift tests for registry classes, tokens, family state matrices, and group
  proof roots.
- **Phase 192 scorecard scripts and artifacts** provide a useful reducer,
  verifier, manifest, scorecard, and sign-off shape, but currently hardcode
  Phase 192/Phase 187 active paths. Phase 200 should parameterize or narrowly
  copy them.
- **`baseline-manifest.js`** defines dimensions, state taxonomy, page-flow
  surfaces, component groups, and an older component-family list. Phase 200
  should reconcile it with the live registry rather than assuming the older
  21-family list is complete.
- **`admin-a11y.spec.js`, `reduced-motion.spec.js`, `admin-group-contracts.spec.js`,
  and `admin-interaction-overlay-phase199.spec.js`** are the current browser
  guardrail seams to extend rather than replace.
- **`theme_test.exs`, `layouts.ex`, and `accrue_theme.js`** already encode the
  production `accrue_theme` cookie/localStorage/system path and no-FOUC ordering.

### Established Patterns

- Phoenix function components with attrs/slots own stateless shared markup;
  LiveViews/LiveComponents own stateful route/action behavior. Storybook helpers
  should stay dev/test-only and avoid runtime page DSLs.
- Source guards handle mechanical CSS/design-system invariants; rendered
  Playwright and axe tests handle composed route, story, accessibility, theme,
  and interaction behavior.
- Structured artifacts beat prose for closeout. Markdown reports explain
  `final.cells.json`, `scorecard.delta.json`, `regressions.ndjson`, manifests,
  and judge findings; they do not replace them.
- CI should prefer deterministic, bounded gates. Full visual/model/maintainer
  review belongs to closeout artifacts, not every PR.
- Custom `ax-*` CSS and committed bundles are the styling SSOT. Storybook must
  consume the same committed bundle rather than introducing another build path.

### Integration Points

- Storybook completeness connects `ComponentRegistry`, `storybook/_support`,
  `.story.exs` files under the configured content path, `priv/static/storybook.*`,
  router asset delivery, and registry/group tests.
- Scorecard generation connects archived v1.53 baseline artifacts, Phase-193
  page-flow cells, Playwright/axe/story evidence, artifact manifests, and
  Phase-200 markdown reports.
- Accessibility/theme guardrails connect route fixtures, Storybook route
  discovery, axe scans, `accrue_theme` cookie/localStorage/system emulation,
  reduced-motion media emulation, and Phase-199 overlay/focus traces.
- Final closeout connects `200-SIGN-OFF.md`, `200-VERIFICATION.md`, requirement
  checkboxes, STATE.md, and milestone closeout readiness.

</code_context>

<specifics>
## Specific Ideas

- User asked to discuss and research all relevant gray areas with subagents, then
  produce one coherent recommendation set so downstream planning can proceed
  without more user decisions.
- Five advisor agents researched: Phase 200 scope/todo boundary, Storybook
  coverage/theming, forward-only scorecard, accessibility/theme/browser
  guardrails, and multi-lens judge/sign-off.
- All advisors converged on the same closeout architecture: registry-driven
  Storybook as coverage floor; `/dev/components` retained as second renderer;
  staged-full scorecard; deterministic CI guardrails; hybrid route/story axe
  plus production theme/no-FOUC tests; bounded correctness/a11y/brand/
  interaction judge; one maintainer ACCEPT/REJECT sign-off artifact.
- Code scout found no existing `.planning/codebase` maps. Fallback scout found
  the Storybook tree currently contains only `accrue_admin/storybook/_support/registry_story.ex`,
  so STY-02/STY-03 require real Phase 200 implementation, not just verification.
- Code scout also found archived baseline paths differ from older Phase 192
  script defaults: current baseline artifacts live under
  `.planning/milestones/v1.53-phases/187-audit-baseline/`.
- External lessons considered:
  - Phoenix/PhoenixStorybook: ordinary component stories, variations, sandboxing,
    and color-mode classes fit the hybrid generated/curated approach.
  - Playwright: web-first assertions and actionability are better than sleeps;
    one-worker deterministic stateful flows reduce flake.
  - axe/WCAG/WAI: automated accessibility checks catch important failures but do
    not prove focus order, modal behavior, text reflow, status messaging, or
    JTBD/brand clarity.
  - Storybook-style design systems work best when generated inventory protects
    completeness and curated examples explain intent; real app routes still
    catch composition failures.

</specifics>

<deferred>
## Deferred Ideas

- **White-label billing portal design system** - future `accrue_portal` phase;
  not Phase 200.
- **Brandbook favicon update** - future brandbook maintenance; not Phase 200.
- **Runtime Storybook replacement for `/dev/components`** - deferred. The
  kitchen stays as second renderer and drift-test target.
- **Tailwind-style Storybook rebuild** - rejected. Storybook must use the
  committed `ax-*` bundle.
- **Pixel-diff / SaaS visual-regression gate** - still deferred by roadmap; use
  forward-only scored cells plus curated evidence instead.
- **Full Cartesian route x state x story x viewport x theme matrix in every CI
  run** - rejected as too slow/flaky. Use full closeout generation plus
  deterministic CI guardrails.
- **Broad UI polish found during sign-off** - defer unless tied to a blocking
  locked requirement/rubric/contract finding.

### Reviewed Todos (not folded)

- **White-label billing portal design system**
  (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`)
  - reviewed and not folded because Phase 200 is `accrue_admin` operator UI
  verification only; this remains future `accrue_portal` work.
- **Shared page_header component for accrue_admin list pages**
  (`.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md`)
  - reviewed and not folded because PageHeader was extracted/proven in Phase 196
  and propagated in Phase 197; Phase 200 verifies it through Storybook/list
  coverage only.
- **Use the Accrue favicon in the brandbook HTML**
  (`.planning/todos/pending/2026-06-19-brandbook-use-accrue-favicon.md`) -
  reviewed and not folded because it targets `brandbook/index.html`, not admin
  verification/sign-off.

</deferred>

---

*Phase: 200-idempotent-verification-sign-off*
*Context gathered: 2026-06-30*
