# Phase 192: Idempotent verification & sign-off - Research

**Researched:** 2026-06-19  
**Domain:** Phoenix LiveView admin UI verification, Playwright/axe guardrails, structured scorecard reduction, maintainer sign-off  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Copied from `.planning/phases/192-idempotent-verification-sign-off/192-CONTEXT.md` and binding for planning. [VERIFIED: codebase grep]

- **D-04:** Use a hybrid final scorecard package: machine-readable artifacts for CI/idempotency plus maintainer-readable markdown for sign-off. Do not choose a markdown-only or JSON-only shape.
- **D-05:** Structured artifacts are canonical. If markdown and structured data disagree, structured data wins and the markdown must be regenerated or corrected.
- **D-06:** The final package should include, or clearly alias, these artifacts: `192-SCORECARD.md`, `final.cells.json`, `scorecard.delta.json`, `regressions.ndjson`, `artifacts.manifest.json`, and `192-SIGN-OFF.md`.
- **D-07:** `192-SCORECARD.md` is a readable summary, not the source of truth. It should summarize pass/fail, coverage status, regression count, CI guardrail status, and maintainer sign-off state.
- **D-08:** Aggregate scores are summary-only. They must never hide a failing cell or dimension.
- **D-09:** Preserve the frozen Phase 187 `p187__...__dXX` cell-id grammar, 12-dimension rubric, state taxonomy, overlay tags, canonical desktop/mobile Playwright projects, and targeted-width vocabulary.
- **D-10:** The Phase 192 gate is strict per-cell comparison: every comparable final cell must have `final_score >= baseline_score`, with no coverage-status downgrade and no new regression row in `regressions.ndjson`.
- **D-11:** If a cell is newly unreachable, missing evidence, or demoted from `covered` to `gap`, that is a blocking regression unless the planner can prove the Phase 187 cell was invalid and records the correction explicitly.
- **D-12:** Baseline semantics must not be reinterpreted to make the final pass. Corrections to stale or impossible baseline rows need explicit structured notes and readable explanation.
- **D-13:** Implement the judge as a layered evidence system, not as an LLM-only visual scoring run.
- **D-14:** Keep raw lens outputs separate: correctness/browser behavior, axe/WCAG a11y, reduced motion, component-lab/group/page coverage, interaction traces, visual/brand/microcopy scoring, and maintainer screenshot review.
- **D-15:** The final synthesis step should be a pure reducer over raw evidence: it normalizes evidence to canonical cell IDs, compares against Phase 187 baseline cells, writes deltas/regressions, and emits readable summaries.
- **D-16:** Every final score, downgrade, regression, or sign-off row must cite concrete evidence references. Evidence paths belong in `artifacts.manifest.json` or generated-output locations, not as bulky committed PNG/trace artifacts.
- **D-17:** `score-visuals.mjs` may contribute advisory visual, brand, hierarchy, and microcopy findings. It must not be the sole gate for accessibility, interaction integrity, focus, scroll, overlay actionability, or CI pass/fail.
- **D-18:** Automated axe checks are necessary but not sufficient accessibility proof. Keep browser/focus/keyboard/trace evidence for the defects screenshots and static scans miss.
- **D-19:** Human or agent review tables are acceptable for subjective brand and screenshot sign-off only when each row links to deterministic evidence and has an explicit accept/block status.
- **D-20:** CI should block on deterministic, bounded checks that contributors can reproduce locally without secrets or subjective review.
- **D-21:** Existing BEAM/package CI remains required: format, compile with warnings as errors, tests, credo, dialyzer, docs, audit, and existing package contract verifiers.
- **D-22:** Keep `admin-group-contracts` merge-blocking.
- **D-23:** Add or extend an admin hardening CI job that runs: `cd accrue_admin && npm run baseline:parse`; `node scripts/ci/verify_phase191_ax187_coverage.mjs`; `cd accrue_admin && npm run e2e:group-contracts`; `cd accrue_admin && npm run e2e:phase191`; `cd accrue_admin && npm run e2e:a11y`; `cd accrue_admin && npx playwright test e2e/reduced-motion.spec.js --workers=1`; and a component-lab structural coverage check through the existing registry, ExUnit, or verifier path.
- **D-24:** Do not make `npm run e2e` as-is merge-blocking. It runs every spec under `accrue_admin/e2e`, including baseline capture, visual capture, trace, and older UAT-style suites, which is too broad and flaky for PR CI.
- **D-25:** Do not make `score-visuals` merge-blocking. It depends on generated screenshots, secrets/model availability, and subjective model output; it also skips cleanly when no API key is present, which would create false-green risk.
- **D-26:** Do not treat `baseline:artifacts` success as proof the UI passed. The artifact generator can preserve producer failures as audit evidence. It belongs in final/manual verification or a workflow-dispatch evidence run, not as a simple PR blocker.
- **D-27:** Screenshot capture, trace capture, baseline regeneration, `score-visuals`, full `npm run e2e`, and maintainer sign-off remain Phase-192 final verification or advisory/generated evidence, not required on every pull request.
- **D-28:** Upload Playwright reports, screenshots, traces, and generated evidence as CI artifacts where useful. Do not commit bulky PNG or ZIP outputs by default.
- **D-29:** The maintainer signs off on `192-SIGN-OFF.md`, not on raw `test-results/` or the full 21,276-cell corpus.
- **D-30:** `192-SIGN-OFF.md` should contain executive pass/fail, baseline comparison summary, CI guardrail status, curated gallery index, artifact manifest links, and a maintainer checklist.
- **D-31:** Use "scorecard plus curated gallery plus human checklist" as the sign-off package. Phase-boundary screenshots alone are insufficient because they are chronology-focused and can repeat v1.51's still-image weakness.
- **D-32:** The curated gallery must be JTBD-first. Each row should name `who`, `job`, `route/surface`, `state`, `theme`, `viewport`, and why the screenshot matters.
- **D-33:** Include representative screenshots for dashboard health scan, customer inspection, subscription triage/detail, invoice/payment review, webhook/event debugging, recovery campaign, component lab, modal/drawer/dropdown open states, and empty/error/permission/disconnected states.
- **D-34:** For each selected flow, include light and dark screenshots. Include mobile for layout-risk flows. Include system-theme behavior only if the harness can prove it deterministically.
- **D-35:** Include focused, hover, disabled/read-only, and open-state screenshots for historical-risk controls: command palette, dropdowns, drawers, modals, mobile nav, destructive confirmations, and disabled/read-only actions.
- **D-36:** Link traces for focus trap, focus restore, Escape, outside click, scroll reachability, LiveView patch focus, and actionability. Do not ask the maintainer to infer these behaviors from still screenshots.
- **D-37:** The maintainer checklist should approve JTBD clarity, domain vocabulary, microcopy recovery, brand fit, accessible focus/contrast, mobile usability, dark-mode role clarity, and absence of backend-guts presentation.
- **D-38:** The sign-off surface should be operator- and maintainer-friendly, not a backend implementation dump. Use domain nouns and verbs: customer, subscription, invoice, charge/payment, webhook, event, recovery, Connect account; inspect, filter, replay, refund, void, recover, clear filters.
- **D-39:** Brand review follows the ratified brandbook, not the older prompt if they conflict: measured, exact, native, durable; quiet well-made developer tooling; `ax-*` admin tokens as implementation SSOT; no fintech/startup gloss.
- **D-40:** Microcopy sign-off should check that states name what happened, the affected object/process, and the next useful action where one exists.
- **D-41:** UI sign-off should explicitly consider accessibility, performance, responsive layout, light/dark/system theme behavior where supported, interaction integrity, focus/hover/disabled affordance, information hierarchy, brand expression, and developer/operator DX.
- **D-42:** Inline fixes are allowed in Phase 192 only for harness, parser, artifact-reference, CI wiring, or evidence-normalization defects that prevent trustworthy verification.
- **D-43:** True UI, accessibility, interaction, copy, component, group, or page-flow regressions are blocking. They should become narrowly scoped Phase 192 repair plans/subplans, then the scorecard must be rerun.
- **D-44:** Deferrals are allowed only for explicitly out-of-scope items or newly discovered improvements that are not regressions against Phase 187 and do not block VER-02..04. Deferrals need an explicit maintainer-approved note.
- **D-45:** Do not encode broken Phase 187 observations as expected final behavior. Phase 191 corrected behavior is the regression target.

### the agent's Discretion

- Exact filenames, script names, and schema field names may be adjusted by the researcher/planner if the artifacts above are present or clearly aliased and the structured-data precedence rule holds.
- Exact CI job topology is planner discretion: extend `admin-group-contracts`, add a new `admin-hardening-guardrails` job, or use a workflow-dispatch final evidence run, as long as deterministic PR gates and final evidence runs remain separate.
- Exact curated gallery size is planner discretion, but it must be small enough for maintainer review and broad enough to cover the JTBD/risk categories above.

### Deferred Ideas (OUT OF SCOPE)

- The low-confidence todo `White-label billing portal design system` is future portal/design-system scope, not Phase 192 admin verification scope. [VERIFIED: 192-CONTEXT.md]
- Phase 192 does not add billing primitives, public API/route breaks, a Tailwind migration, PhoenixStorybook, a pixel-diff service, `accrue_portal` work, or a host chrome redesign. [VERIFIED: 192-CONTEXT.md]
</user_constraints>

## Summary

Phase 192 should be planned as an evidence-reduction and release-sign-off phase, not as a broad UI remediation phase. The project already has the essential evidence producers: Phase 187 canonical schemas and baseline cells, Playwright browser slices for group contracts, page-flow interaction, axe a11y, and reduced motion, plus Phase 191 AX187 closure verification. [VERIFIED: codebase grep]

The primary implementation should add a pure final-scorecard reducer that reads Phase 187 `baseline.cells.json`, reads raw final evidence outputs, preserves the frozen `p187__...__dXX` cell identity, emits `final.cells.json`, `scorecard.delta.json`, `regressions.ndjson`, `artifacts.manifest.json`, `192-SCORECARD.md`, and `192-SIGN-OFF.md`, and fails closed on score downgrades, coverage downgrades, missing evidence, or unclassified regression rows. [VERIFIED: 192-CONTEXT.md]

CI should add a bounded admin hardening guardrail job or extend `admin-group-contracts`, but it must run the listed deterministic commands serially because Phase 191 recorded browser/build lock collision when E2E commands were launched in parallel. [VERIFIED: 191-AX187-COVERAGE.md]

**Primary recommendation:** Use the existing Playwright + axe + component-registry stack and add no new dependencies by default; implement Phase 192 as schema-backed artifact generation, strict per-cell comparison, bounded CI guardrails, and maintainer sign-off markdown. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Raw browser evidence capture | Browser / Client | Frontend Server (LiveView test server) | Playwright exercises DOM, focus, overlays, motion, theme, screenshots, and traces through the existing `mix accrue_admin.e2e.server`. [VERIFIED: `accrue_admin/playwright.config.js`] |
| Axe accessibility lens | Browser / Client | CI | `@axe-core/playwright` runs in Playwright pages and emits violations that CI can fail on. [VERIFIED: `accrue_admin/e2e/admin-a11y.spec.js`] |
| Component-lab coverage | Frontend Server (LiveView) | Browser / Client | `AccrueAdmin.Dev.ComponentRegistry` and LiveView tests own the registry/proof surface; browser checks verify rendered behavior. [VERIFIED: `accrue_admin/lib/accrue_admin/dev/component_registry.ex`] |
| Final scorecard reducer | Tooling / CI | Planning artifacts | Reducer should be a Node script over JSON/NDJSON and generated evidence paths, not runtime Phoenix code. [VERIFIED: 192-CONTEXT.md] |
| CI guardrails | CI | Browser / Client | GitHub Actions already owns BEAM setup, Node setup, Chromium install, Playwright command execution, and artifact upload. [VERIFIED: `.github/workflows/ci.yml`] |
| Maintainer sign-off | Planning artifacts | Human review | `192-SIGN-OFF.md` is the explicit human decision surface over curated evidence, not an app route. [VERIFIED: 192-CONTEXT.md] |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VER-02 | Each level is scored by an adversarial multi-lens judge and final scorecard is >= baseline with zero regressions. | Use layered evidence producers plus pure reducer; preserve Phase 187 schema and compare every comparable cell. [VERIFIED: 192-CONTEXT.md] |
| VER-03 | Regression guardrails run in CI: interaction e2e, axe a11y, reduced-motion, component-lab coverage. | Existing scripts provide `e2e:group-contracts`, `e2e:phase191`, `e2e:a11y`, reduced-motion spec, and registry tests; CI already has an admin group-contracts job to extend. [VERIFIED: codebase grep] |
| VER-04 | Maintainer signs off on screenshots at phase boundaries and final sign-off closes v1.51 photographic-sign-off debt. | Generate `192-SIGN-OFF.md` with curated gallery index, evidence refs, and explicit checklist. [VERIFIED: 192-UI-SPEC.md] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Accrue uses Elixir/Phoenix with `accrue/` and `accrue_admin/` sibling packages; `accrue_admin` is a Phoenix LiveView dashboard package. [VERIFIED: `CLAUDE.md`]
- The project forbids new broad feature scope for this milestone; v1.53 is quality/design-system hardening of `accrue_admin`. [VERIFIED: `.planning/ROADMAP.md`]
- `accrue_admin/assets/css/theme.css` and custom `ax-*` tokens remain the styling source of truth; no Tailwind migration or third-party UI framework should be introduced. [VERIFIED: `192-UI-SPEC.md`]
- Before file-changing work, project workflow guidance prefers GSD entry points; this research phase is itself a GSD artifact creation step requested by the orchestrator. [VERIFIED: `CLAUDE.md`]
- No project skills were found under `.claude/skills/` or `.agents/skills/`. [VERIFIED: `find .claude .agents -path '*/SKILL.md'`]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| `@playwright/test` | installed `1.59.1`; package range `^1.57.0`; latest npm `1.61.0` | Browser automation, traces, screenshots, two Chromium projects, E2E guardrails | Existing repo standard; Playwright docs support `projects`, `webServer`, `reporter`, `outputDir`, `trace`, and `screenshot` in config. [CITED: https://playwright.dev/docs/test-configuration] [CITED: https://playwright.dev/docs/test-use-options] |
| `@axe-core/playwright` | installed `4.11.3`; latest npm `4.11.3` | Automated WCAG 2 A/AA checks inside Playwright | Existing repo standard; Deque docs expose `AxeBuilder({ page }).withTags(['wcag2a','wcag2aa']).analyze()`. [CITED: https://github.com/dequelabs/axe-core-npm/blob/develop/packages/playwright/README.md] |
| GitHub Actions | repository workflows use Actions syntax and `actions/*@v6/v7` | Merge-blocking guardrails and artifact retention | Existing CI already sets BEAM, Node, npm cache, Chromium, Playwright, and artifact upload. [VERIFIED: `.github/workflows/ci.yml`] |
| `AccrueAdmin.Dev.ComponentRegistry` | local module | Component and component-group structural coverage source | Existing registry owns component families, group contracts, proof IDs, state metadata, and LiveView proof surface. [VERIFIED: `accrue_admin/lib/accrue_admin/dev/component_registry.ex`] |
| Node.js scripts | local Node 22.14.0 available | JSON/NDJSON parsing, reducer, manifest checks, CI verification scripts | Existing `baseline:parse`, `baseline-artifacts.mjs`, and `verify_phase191_ax187_coverage.mjs` are Node scripts. [VERIFIED: codebase grep] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `mix test` | Mix 1.19.5 available | Component-registry and LiveView structural assertions | Use for component-lab coverage checks that should not require browser screenshot capture. [VERIFIED: environment probe] |
| `npx playwright install --with-deps chromium` | npm 11.1.0 available | Install CI browser runtime | Use in GitHub Actions before Playwright guardrail commands. [VERIFIED: `.github/workflows/ci.yml`] |
| `actions/upload-artifact` | workflows currently use `@v7` | Preserve reports, traces, screenshots, generated evidence | Use for Playwright reports/traces and final/manual evidence outputs; GitHub docs support named artifact uploads and retention days. [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] |
| `score-visuals.mjs` | local advisory script | Visual/brand/microcopy advisory lens | Use only in final evidence or advisory runs; never as a merge-blocking gate. [VERIFIED: 192-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Local reducer scripts | New verification service or database | Avoid; Phase 192 artifacts are static planning/CI outputs, and a service adds runtime state with no requirement support. [VERIFIED: 192-CONTEXT.md] |
| Existing `/dev/components` lab | PhoenixStorybook | Out of scope and explicitly deferred; existing registry/lab is the milestone standard. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| Structured comparison | Markdown-only sign-off | Forbidden by D-04/D-05; markdown is readable summary only. [VERIFIED: 192-CONTEXT.md] |
| Deterministic browser and schema gates | Pixel-diff SaaS / Percy / Applitools | Out of scope as TOOL-02; screenshot + adversarial judge remains the current milestone model. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| Add `ajv` for schema validation | Custom local validators | `ajv` is a likely standard JSON Schema validator, but this session did not verify it through official docs; default to custom validation or add a human checkpoint before installing. [ASSUMED] |

**Installation:**

```bash
# No new package install is recommended for Phase 192 by default.
cd accrue_admin && npm ci
cd accrue_admin && npx playwright install --with-deps chromium
```

**Version verification:**

```bash
cd accrue_admin && npm ls @playwright/test @axe-core/playwright --depth=0
npm view @playwright/test version
npm view @axe-core/playwright version
```

## Package Legitimacy Audit

No new external package install is recommended. Existing npm packages relevant to this phase were audited because the planner may touch their scripts. [VERIFIED: npm registry]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@playwright/test` | npm | latest package publish was too recent for seam threshold | 42,613,659/wk | github.com/microsoft/playwright | SUS by seam for latest `1.61.0` because `too-new`; installed lock is `1.59.1` | Do not upgrade in Phase 192; keep existing lock unless a separate dependency-upgrade phase verifies it. [VERIFIED: npm registry] |
| `@axe-core/playwright` | npm | existing current package | 5,172,514/wk | github.com/dequelabs/axe-core-npm | OK | Approved existing dependency. [VERIFIED: npm registry] |
| `ajv` | npm | existing current package | 327,724,216/wk | github.com/ajv-validator/ajv | OK by seam, but not currently installed | Not recommended by default; if added, planner should include explicit install decision because the package recommendation is [ASSUMED]. |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** `@playwright/test` latest only; installed package remains existing project dependency and should not be upgraded as part of Phase 192. [VERIFIED: npm registry]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 187 canonical baseline
  baseline.cells.json + schemas + defects.ndjson
        |
        v
Deterministic final evidence producers
  Playwright group contracts
  Playwright Phase 191 interactions
  Playwright axe a11y
  Playwright reduced motion
  Mix component-registry coverage
  Optional final screenshot/trace/model evidence
        |
        v
Raw evidence folders and command status logs
  accrue_admin/test-results/*
        |
        v
Phase 192 pure reducer
  parse -> normalize to p187 cell IDs -> validate evidence refs
  -> compare scores and coverage -> classify regressions
        |
        +--> final.cells.json
        +--> scorecard.delta.json
        +--> regressions.ndjson
        +--> artifacts.manifest.json
        |
        v
Readable generated summaries
  192-SCORECARD.md -> 192-SIGN-OFF.md
        |
        v
CI guardrail status + maintainer checklist
```

### Recommended Project Structure

```text
.planning/phases/192-idempotent-verification-sign-off/
├── 192-RESEARCH.md
├── 192-SCORECARD.md
├── 192-SIGN-OFF.md
├── final.cells.json
├── scorecard.delta.json
├── regressions.ndjson
└── artifacts.manifest.json

scripts/ci/
├── verify_phase191_ax187_coverage.mjs
└── verify_phase192_scorecard.mjs

accrue_admin/e2e/
├── phase192-scorecard.mjs
├── phase192-gallery.mjs
└── existing guardrail specs
```

### Pattern 1: Pure Reducer Over Evidence

**What:** Read baseline cells and raw evidence, normalize final evidence to canonical cell IDs, compare rows, and write structured artifacts. [VERIFIED: 192-CONTEXT.md]  
**When to use:** Always for final scorecard generation; never let markdown or screenshots decide pass/fail. [VERIFIED: 192-CONTEXT.md]

```javascript
// Source: local Phase 187 schema + Phase 192 decisions.
const baselineById = new Map(baselineCells.map((cell) => [cell.cell_id, cell]));
const regressions = [];

for (const finalCell of finalCells) {
  const baseline = baselineById.get(finalCell.cell_id);
  if (!baseline) continue;

  const scoreDowngrade =
    baseline.score !== null &&
    (finalCell.score === null || finalCell.score < baseline.score);
  const coverageDowngrade =
    baseline.coverage_status === "covered" && finalCell.coverage_status !== "covered";

  if (scoreDowngrade || coverageDowngrade || finalCell.evidence_refs.length === 0) {
    regressions.push({ cell_id: finalCell.cell_id, scoreDowngrade, coverageDowngrade });
  }
}
```

### Pattern 2: Bounded Serial CI Guardrail

**What:** Run only deterministic commands in a single admin hardening job after BEAM/Node/Chromium setup. [VERIFIED: 192-CONTEXT.md]  
**When to use:** PR/push CI. Keep final screenshot capture and model scoring out of this job. [VERIFIED: 192-CONTEXT.md]

```yaml
# Source: existing .github/workflows/ci.yml pattern.
- name: Baseline artifacts parse
  run: cd accrue_admin && npm run baseline:parse

- name: Phase 191 AX187 coverage
  run: node scripts/ci/verify_phase191_ax187_coverage.mjs

- name: Group contracts
  run: cd accrue_admin && npm run e2e:group-contracts

- name: Phase 191 interaction guardrail
  run: cd accrue_admin && npm run e2e:phase191

- name: Axe accessibility guardrail
  run: cd accrue_admin && npm run e2e:a11y

- name: Reduced-motion guardrail
  run: cd accrue_admin && npx playwright test e2e/reduced-motion.spec.js --workers=1
```

### Pattern 3: Artifact Manifest References, Not Binary Commits

**What:** Store evidence paths/checksums in `artifacts.manifest.json`; upload bulky reports/traces/screenshots as CI artifacts. [VERIFIED: `baseline-artifacts.mjs`]  
**When to use:** Always for Playwright reports, traces, screenshots, command logs, and final evidence. [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data]

### Anti-Patterns to Avoid

- **Markdown-only proof:** Violates structured-data precedence and cannot be safely re-run. [VERIFIED: 192-CONTEXT.md]
- **LLM-only judge:** Misses deterministic focus, keyboard, axe, scroll, and actionability failures. [VERIFIED: 192-CONTEXT.md]
- **Broad `npm run e2e` as PR gate:** Includes older/broad/capture suites and is explicitly rejected for merge-blocking CI. [VERIFIED: 192-CONTEXT.md]
- **Parallel browser slices against the same build/server:** Phase 191 observed a shared build-lock collision; run Phase 192 guardrails serially unless the planner creates isolated ports/build paths. [VERIFIED: 191-AX187-COVERAGE.md]
- **Treating `baseline:artifacts` success as pass:** Existing artifact generator can preserve producer failures as evidence, so it is a final evidence tool, not a pass/fail gate. [VERIFIED: 192-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser interactions, focus, traces, screenshots | Custom browser driver | Playwright existing config/specs | Already integrated with LiveView test server, projects, traces, screenshots, reports. [VERIFIED: codebase grep] |
| Accessibility rules | Custom WCAG parser | `@axe-core/playwright` | Deque package provides axe integration with Playwright and WCAG tags. [CITED: https://github.com/dequelabs/axe-core-npm/blob/develop/packages/playwright/README.md] |
| Component coverage source | New registry | `AccrueAdmin.Dev.ComponentRegistry` | Existing registry is canonical for component and group proof surfaces. [VERIFIED: codebase grep] |
| CI artifact storage | Commit PNG/ZIP reports | `actions/upload-artifact` | GitHub Actions supports artifact upload and retention; project decisions forbid bulky committed artifacts. [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] |
| Visual scoring as gate | Model-only scoring | Deterministic reducer + advisory `score-visuals` | Locked decisions state model output is advisory and cannot be sole pass/fail proof. [VERIFIED: 192-CONTEXT.md] |

**Key insight:** Phase 192 is mostly about preserving trust boundaries: deterministic evidence decides CI and regression status; subjective review decides only brand/screenshot accept/block rows with concrete evidence refs. [VERIFIED: 192-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Reinterpreting Phase 187 Baseline Rows

**What goes wrong:** Planner changes cell semantics or drops gaps to make the final pass. [VERIFIED: 192-CONTEXT.md]  
**Why it happens:** Phase 187 contains many gap rows and old observations; the temptation is to “clean up” instead of comparing strictly. [VERIFIED: codebase grep]  
**How to avoid:** Preserve cell IDs and write explicit structured correction notes for invalid baseline rows. [VERIFIED: 192-CONTEXT.md]  
**Warning signs:** `final.cells.json` has new grammar, missing `p187__` IDs, or fewer comparable rows without correction notes. [VERIFIED: 192-CONTEXT.md]

### Pitfall 2: False-Green CI From Optional Advisory Tools

**What goes wrong:** `score-visuals` skips because model credentials are absent but CI reports green. [VERIFIED: 192-CONTEXT.md]  
**Why it happens:** Advisory scripts can be useful for final review but are not deterministic PR gates. [VERIFIED: 192-CONTEXT.md]  
**How to avoid:** Keep CI gates limited to baseline parse, AX187 coverage, group contracts, Phase 191 interactions, axe, reduced motion, and component-lab coverage. [VERIFIED: 192-CONTEXT.md]

### Pitfall 3: Browser Guardrail Flake From Parallel Shared State

**What goes wrong:** Multiple Playwright jobs collide on build artifacts, E2E server, port, or database state. [VERIFIED: 191-AX187-COVERAGE.md]  
**Why it happens:** Existing config uses one default port `4017`, one test-results root, one webServer, and `workers: 1`. [VERIFIED: `accrue_admin/playwright.config.js`]  
**How to avoid:** Run guardrails serially in one job or give each job isolated `ACCRUE_ADMIN_E2E_PORT`, result root, and database lifecycle. [VERIFIED: codebase grep]

### Pitfall 4: Screenshots Used As Interaction Proof

**What goes wrong:** Maintainer approves still images while focus trap, Escape, outside-click, scroll, or actionability regressions remain. [VERIFIED: 192-CONTEXT.md]  
**Why it happens:** v1.51’s photographic sign-off debt was specifically that stills missed interaction bugs. [VERIFIED: `.planning/STATE.md`]  
**How to avoid:** Put traces/deterministic assertions beside screenshot gallery rows for behavior claims. [VERIFIED: 192-UI-SPEC.md]

## Code Examples

### Existing Axe Pattern

```javascript
// Source: accrue_admin/e2e/admin-a11y.spec.js
const AxeBuilder = require("@axe-core/playwright").default;

const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
const failures = results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
```

### Existing Reduced Motion Pattern

```javascript
// Source: accrue_admin/e2e/reduced-motion.spec.js
await page.emulateMedia({ reducedMotion: "reduce" });
await login(page, "/billing/dev/components");
await expect(page.locator("#main-content")).toBeVisible();
```

### Existing CI Artifact Pattern

```yaml
# Source: .github/workflows/ci.yml
- name: Upload Playwright traces
  if: failure()
  uses: actions/upload-artifact@v7
  with:
    name: admin-group-contracts-playwright-traces
    path: accrue_admin/test-results
    if-no-files-found: ignore
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Still-image visual QA as sign-off | Layered deterministic evidence plus curated screenshot sign-off | v1.53 Phase 192 decisions, 2026-06-19 | Planner must include structured reducer and behavior traces, not screenshot-only approval. [VERIFIED: 192-CONTEXT.md] |
| Broad Playwright suite as CI proof | Bounded deterministic guardrail slices | v1.53 Phase 192 decisions, 2026-06-19 | `npm run e2e` stays final/manual or advisory, not PR-blocking. [VERIFIED: 192-CONTEXT.md] |
| Component proof by scattered page screenshots | Registry-backed `/billing/dev/components` structural proof | Phases 189-190 | Planner should use registry/Mix tests for component-lab coverage. [VERIFIED: codebase grep] |
| Phase 187 observations as current truth | Phase 191 corrected behavior is the regression target | Phase 192 decisions | Do not encode broken old behavior as expected final behavior. [VERIFIED: 192-CONTEXT.md] |

**Deprecated/outdated:**
- PhoenixStorybook adoption for this milestone is deferred; use existing component lab. [VERIFIED: `.planning/REQUIREMENTS.md`]
- Pixel-diff SaaS tooling is deferred; do not introduce it in Phase 192. [VERIFIED: `.planning/REQUIREMENTS.md`]
- Full broad `npm run e2e` as a merge-blocker is explicitly rejected. [VERIFIED: 192-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `ajv` is the standard Node JSON Schema validator if full draft-07 validation is added. | Standard Stack | Low; planner can avoid adding `ajv` and use local validators, or add a human verification checkpoint before install. |

## Open Questions (RESOLVED)

1. **Should Phase 192 add a dedicated schema validator package?**
   - What we know: Current artifacts can be parsed and custom-validated with Node; `ajv` exists and passed registry legitimacy but was not verified from official docs in this session. [VERIFIED: npm registry]
   - RESOLVED: Do not add `ajv` by default in Phase 192. Use custom fail-closed Node validation for the known Phase 187/192 artifact shapes. If an executor later proves full draft-07 JSON Schema validation is necessary, that package addition requires an explicit maintainer checkpoint before install.
   - Planning impact: PLAN.md must not depend on a new validator package for success. Verifier tasks should parse and validate the required fields directly and fail closed on unknown or malformed artifact rows.

2. **Where should final evidence artifacts live in CI?**
   - What we know: Decisions require manifest refs and no bulky committed PNG/ZIP artifacts; GitHub Actions can upload artifacts. [VERIFIED: 192-CONTEXT.md] [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data]
   - RESOLVED: Keep PR guardrails bounded and deterministic. Run full screenshot, trace, visual/brand/microcopy advisory scoring, and maintainer review evidence as a Phase 192 final evidence workflow or manual release-closeout run. Store bulky screenshots, traces, reports, and ZIPs as CI/generated artifacts with repo-relative refs and checksums in `artifacts.manifest.json`; commit only structured scorecard/sign-off artifacts and manifest references.
   - Planning impact: PLAN.md must schedule a non-PR-gating final evidence generation step before `phase192:scorecard` and `phase192:signoff`, and must verify each required lens has current evidence refs in `artifacts.manifest.json`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Node.js | npm scripts and reducers | yes | `v22.14.0` | GitHub Actions `setup-node@v6` with Node 22. [VERIFIED: environment probe] |
| npm | package install and Playwright CLI | yes | `11.1.0` | none needed. [VERIFIED: environment probe] |
| Playwright CLI | E2E guardrails | yes | `1.59.1` installed | `npm ci` then `npx playwright install --with-deps chromium`. [VERIFIED: environment probe] |
| Mix/Elixir/OTP | LiveView server and ExUnit coverage | yes | Mix/Elixir `1.19.5`, OTP `28` | GitHub Actions `erlef/setup-beam@v1`. [VERIFIED: environment probe] |
| PostgreSQL client | local DB troubleshooting | yes | `psql 14.17` | CI provides Postgres 15 service. [VERIFIED: environment probe] |
| GitHub CLI | optional workflow inspection | yes | `gh 2.94.0` | Use web UI or Actions logs. [VERIFIED: environment probe] |

**Missing dependencies with no fallback:** none found for research/planning. [VERIFIED: environment probe]  
**Missing dependencies with fallback:** none found. [VERIFIED: environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Browser framework | Playwright `@playwright/test` installed `1.59.1`; config at `accrue_admin/playwright.config.js`. [VERIFIED: environment probe] |
| Accessibility framework | `@axe-core/playwright` installed `4.11.3`; spec at `accrue_admin/e2e/admin-a11y.spec.js`. [VERIFIED: codebase grep] |
| Elixir framework | ExUnit via `mix test`; component registry tests under `accrue_admin/test/accrue_admin/dev/`. [VERIFIED: codebase grep] |
| Quick run command | `cd accrue_admin && npm run baseline:parse && cd .. && node scripts/ci/verify_phase191_ax187_coverage.mjs` |
| Full guardrail command | Run the serial command list in D-23 plus component-lab coverage test. [VERIFIED: 192-CONTEXT.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| VER-02 | Final cells compare >= Phase 187 baseline and emit no regressions | unit/integration over artifacts | `node scripts/ci/verify_phase192_scorecard.mjs` | no - Wave 0 gap |
| VER-02 | Raw evidence normalized to canonical cell IDs with refs | unit/integration over artifacts | `node scripts/ci/verify_phase192_scorecard.mjs --manifest` | no - Wave 0 gap |
| VER-03 | Baseline artifacts parse | static parse | `cd accrue_admin && npm run baseline:parse` | yes |
| VER-03 | Phase 191 AX187 closure still covered | static/source verifier | `node scripts/ci/verify_phase191_ax187_coverage.mjs` | yes |
| VER-03 | Group contract browser guardrail | Playwright e2e | `cd accrue_admin && npm run e2e:group-contracts` | yes |
| VER-03 | Page-flow interaction guardrail | Playwright e2e | `cd accrue_admin && npm run e2e:phase191` | yes |
| VER-03 | Axe a11y guardrail | Playwright + axe | `cd accrue_admin && npm run e2e:a11y` | yes |
| VER-03 | Reduced-motion guardrail | Playwright e2e | `cd accrue_admin && npx playwright test e2e/reduced-motion.spec.js --workers=1` | yes |
| VER-03 | Component-lab structural coverage | ExUnit | `cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/component_group_registry_test.exs` | yes |
| VER-04 | Maintainer sign-off package includes curated gallery/checklist/status | static doc verifier | `node scripts/ci/verify_phase192_signoff.mjs` | no - Wave 0 gap |

### Sampling Rate

- **Per task commit:** Run the quick parse/source verifier relevant to changed files. [VERIFIED: codebase grep]
- **Per wave merge:** Run D-23 serial guardrail list plus component-lab ExUnit coverage. [VERIFIED: 192-CONTEXT.md]
- **Phase gate:** Run final evidence generation, reducer, scorecard verifier, and sign-off verifier; maintainer approves `192-SIGN-OFF.md`. [VERIFIED: 192-CONTEXT.md]

### Wave 0 Gaps

- [ ] `scripts/ci/verify_phase192_scorecard.mjs` - validates `final.cells.json`, `scorecard.delta.json`, `regressions.ndjson`, and `artifacts.manifest.json` against strict comparison rules. [VERIFIED: 192-CONTEXT.md]
- [ ] `scripts/ci/verify_phase192_signoff.mjs` - verifies `192-SIGN-OFF.md` has executive status, curated gallery rows, CI guardrail status, artifact links, and explicit checklist outcome. [VERIFIED: 192-UI-SPEC.md]
- [ ] `accrue_admin/e2e/phase192-scorecard.mjs` or equivalent - creates final cells from raw evidence without mutating Phase 187 artifacts. [VERIFIED: 192-CONTEXT.md]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not set `security_enforcement: false`. [VERIFIED: `.planning/config.json`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct change | Existing E2E login helpers and admin auth remain unchanged. [VERIFIED: codebase grep] |
| V3 Session Management | no direct change | Do not alter LiveView session/auth behavior in Phase 192. [VERIFIED: 192-CONTEXT.md] |
| V4 Access Control | yes, verification-only | Guardrails must not add production auth bypass routes; existing test-only E2E plug routes are the boundary. [VERIFIED: `.planning/STATE.md`] |
| V5 Input Validation | yes | Parse JSON/NDJSON defensively, reject malformed artifacts, reject missing evidence refs, and avoid eval/dynamic code over artifact contents. [VERIFIED: local script patterns] |
| V6 Cryptography | yes, artifact integrity only | Use SHA-256 checksums for evidence inventory, following `baseline-artifacts.mjs`; do not invent crypto. [VERIFIED: `accrue_admin/e2e/baseline-artifacts.mjs`] |

### Known Threat Patterns for Phase 192

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| False-green sign-off from skipped advisory/model tool | Tampering / Repudiation | Deterministic reducers own pass/fail; advisory rows must be explicit and non-blocking unless normalized into regressions. [VERIFIED: 192-CONTEXT.md] |
| Path traversal in artifact refs | Tampering / Information Disclosure | Only accept repo-relative refs under expected generated roots such as `accrue_admin/test-results/`, mirroring `baseline-artifacts.mjs`. [VERIFIED: codebase grep] |
| Production auth bypass introduced for evidence | Elevation of Privilege | Keep forced states and login helpers in test support only; do not modify production router/auth. [VERIFIED: `.planning/STATE.md`] |
| Committed binary evidence bloat | Denial of Service | Store paths/checksums in manifest and upload bulky artifacts to CI. [VERIFIED: 192-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/192-idempotent-verification-sign-off/192-CONTEXT.md` - locked decisions, CI boundary, sign-off contract. [VERIFIED: codebase grep]
- `.planning/phases/192-idempotent-verification-sign-off/192-UI-SPEC.md` - design/sign-off surface contract. [VERIFIED: codebase grep]
- `.planning/phases/187-audit-baseline/baseline.cells.json` - 21,276 canonical cells. [VERIFIED: codebase grep]
- `.planning/phases/187-audit-baseline/schemas/*.json` - baseline and defect schemas. [VERIFIED: codebase grep]
- `accrue_admin/package.json`, `accrue_admin/playwright.config.js`, `accrue_admin/e2e/*.js`, `.github/workflows/ci.yml` - existing test/CI implementation. [VERIFIED: codebase grep]
- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` and `accrue_admin/test/accrue_admin/dev/*` - component-lab coverage source. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- Playwright configuration docs - `projects`, `webServer`, `reporter`, `outputDir`, tracing, screenshots. [CITED: https://playwright.dev/docs/test-configuration]
- Playwright recording/tracing docs - screenshots/traces in `test-results`; CI tracing guidance. [CITED: https://playwright.dev/docs/test-use-options] [CITED: https://playwright.dev/docs/trace-viewer]
- Deque `@axe-core/playwright` README - `AxeBuilder`, `withTags`, `analyze`. [CITED: https://github.com/dequelabs/axe-core-npm/blob/develop/packages/playwright/README.md]
- GitHub Actions artifact docs - upload/download artifacts and retention. [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data]
- GitHub Actions Node.js docs - Node setup and npm caching. [CITED: https://docs.github.com/en/actions/tutorials/build-and-test-code/nodejs]

### Tertiary (LOW confidence)

- `ajv` as JSON Schema validator recommendation is [ASSUMED] unless planner verifies official Ajv docs and chooses to add the package.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - based on existing project dependencies, scripts, and official docs for Playwright/axe/GitHub Actions.
- Architecture: HIGH - locked by Phase 192 context and existing Phase 187/191 artifacts.
- Pitfalls: HIGH - grounded in locked decisions plus Phase 191 recorded collision and verification notes.
- Package additions: LOW - no new packages recommended; `ajv` remains an assumption only.

**Research date:** 2026-06-19  
**Valid until:** 2026-07-19 for local architecture; 2026-06-26 for npm/GitHub Actions version freshness.
