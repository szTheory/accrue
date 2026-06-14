# Phase 187: Audit & Baseline - Research

**Researched:** 2026-06-14  
**Domain:** Accrue Admin UI audit baseline, Playwright interaction evidence, design-system rubric scoring  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- Full per-defect regression tests for every recorded interaction defect - Phase 191, when each defect is fixed.
- CI no-regression guardrails for every baseline cell - Phase 192.
- SARIF/GitHub code-scanning export for UI defects - optional later tooling if CI annotations become valuable.
- PhoenixStorybook adoption - still deferred; v1.53 extends the in-app `/dev/components` kitchen.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VER-01 | A severity-ranked defect ledger plus a scored baseline (the refreshed rubric across viewport x theme x state, including live interaction testing) exists and is the only-forward reference point. | Use the existing Playwright visual/a11y/trace harness, extend the 10-dimension scorer to 12 dimensions, add manifest-driven cells, and emit `baseline.cells.json`, `defects.ndjson`, `187-RUBRIC.md`, `187-BASELINE.md`, and `artifacts.manifest.json`. [VERIFIED: codebase grep + CONTEXT.md] |
</phase_requirements>

## Summary

Phase 187 is a baseline and evidence phase, not a remediation phase. The repo already has the core audit substrate: Playwright desktop/mobile projects, light/dark screenshot capture across 21 production admin surfaces, axe scans over the same surface set, trace capture for selected interaction surfaces, E2E reset/login/seed endpoints, and an in-app `/dev/components` kitchen with a component registry. [VERIFIED: codebase grep] The planner should extend these assets instead of introducing a new visual-regression platform or component explorer. [VERIFIED: CONTEXT.md + codebase grep]

The primary planning gap is canonicalization. `score-visuals.mjs` currently scores screenshots against the old 10-dimension rubric and writes screenshot findings, while VER-01 needs a rerunnable cell baseline across surface x viewport x theme x state x dimension plus a severity-ranked defect ledger. [VERIFIED: codebase grep] Plan the phase around a manifest and small artifact generator that drives screenshots, axe, interaction probes, vision scoring, and structured output from one source of truth. [VERIFIED: codebase grep + CONTEXT.md]

**Primary recommendation:** Build a manifest-driven baseline harness around the existing `accrue_admin/e2e` suite, add only the minimum fixtures/probes needed to observe locked state cells, and commit structured baseline artifacts while keeping bulky screenshots/traces in generated output referenced by `artifacts.manifest.json`. [VERIFIED: codebase grep + CONTEXT.md]

## Project Constraints (from AGENTS.md)

None. `AGENTS.md` does not exist at the repository root. [VERIFIED: root `ls -la`]

## Project Skill Constraints

No project-local `.codex/skills/` or `.agents/skills/` directories exist in this repo. [VERIFIED: `find .codex/skills .agents/skills -maxdepth 2 -name SKILL.md`] Research therefore follows global GSD phase-research instructions and the phase context only. [VERIFIED: project-skills-discovery.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Baseline manifest and scored cell data | Test harness / planning artifact tier | Admin UI | The manifest orchestrates audit coverage and produces `.planning` artifacts; UI code is only the subject under test. [VERIFIED: CONTEXT.md] |
| Static viewport/theme/state screenshots | Browser / Playwright test tier | Frontend server (LiveView) | Playwright drives browser projects and theme attributes while the LiveView server provides deterministic routes and fixtures. [VERIFIED: codebase grep; CITED: https://playwright.dev/docs/test-projects] |
| Live interaction probes | Browser / Playwright test tier | Phoenix LiveView client JS | Focus, scroll, overlay, actionability, Escape, and keyboard behavior must be observed in a real browser; LiveView JS is relevant where DOM patches and JS commands affect behavior. [VERIFIED: codebase grep; CITED: https://playwright.dev/docs/actionability; CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html] |
| E2E fixture state | Backend test support / database | Browser test tier | `E2E.Fixtures` and `E2E.Plug` own reset/seed routes; Playwright only invokes them. [VERIFIED: codebase grep] |
| Rubric and defect ledger | Planning artifact tier | Browser evidence tier | `187-RUBRIC.md`, `187-BASELINE.md`, `baseline.cells.json`, and `defects.ndjson` are the canonical only-forward contract for later phases. [VERIFIED: CONTEXT.md] |
| Microcopy judgment | Planning artifact tier | Admin UI copy modules / brandbook | The scoring lens is defined by `brandbook/voice.md` and `brandbook/copy.md`; UI code provides observed strings. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| `@playwright/test` | Locked install: 1.59.1; npm latest checked: 1.60.0 modified 2026-06-14 | Browser automation, desktop/mobile project modes, traces, actionability checks | Playwright projects are the existing repo standard for desktop/mobile E2E and official docs define projects for running the same tests under different device/config profiles. [VERIFIED: npm registry + codebase grep; CITED: https://playwright.dev/docs/test-projects] |
| `@axe-core/playwright` | Locked install/latest: 4.11.3 modified 2026-06-13 | Automated accessibility scans in Playwright | Playwright's official accessibility guide uses `@axe-core/playwright` and the repo already runs it across admin surfaces. [VERIFIED: npm registry + codebase grep; CITED: https://playwright.dev/docs/accessibility-testing] |
| Phoenix LiveView JS | `phoenix_live_view ~> 1.1` in `accrue_admin/mix.exs`; docs opened at v1.2.1 | DOM-patch-aware focus/show/hide/push behavior for modal/dropdown/drawer interactions | LiveView JS commands are DOM-patch aware and include focus utilities, making them the relevant framework surface for interpreting interaction defects. [VERIFIED: codebase grep; CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html] |
| `@anthropic-ai/sdk` | Locked install: 0.100.1; npm latest checked: 0.104.1 modified 2026-06-09 | Existing optional vision-scoring client | `score-visuals.mjs` imports it only when `ANTHROPIC_API_KEY` is present and skips cleanly without the key. [VERIFIED: npm registry + codebase grep] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| JSON Lines / NDJSON | Format, not package | One defect per line in `defects.ndjson` | Use for appendable machine-readable findings; JSON Lines requires each line to be a valid JSON value and recommends line terminators. [CITED: https://jsonlines.org/] |
| JSON Schema | Format, not package | Optional `schemas/baseline-cell.schema.json` and `schemas/defect.schema.json` | Use if cheap to enforce the structured artifact contract before Phase 192 consumes it. [ASSUMED] |
| Existing Mix tasks | `mix accrue_admin.e2e.server`, `mix accrue_admin.assets.build` | Start E2E Phoenix endpoint and rebuild committed assets after CSS/JS edits | Use existing tasks; do not add a separate server bootstrap path. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `/dev/components` kitchen | PhoenixStorybook | PhoenixStorybook is explicitly deferred; adopting it would violate locked scope. [VERIFIED: CONTEXT.md] |
| Screenshot + trace + structured ledger | Percy / Applitools pixel-diff | Pixel-diff visual regression is deferred to v2; Phase 187 should not install a visual-regression SaaS/tool. [VERIFIED: REQUIREMENTS.md + CONTEXT.md] |
| `defects.ndjson` | SARIF | SARIF is optional/deferred because UI interaction defects do not map cleanly to static-analysis locations. [VERIFIED: CONTEXT.md] |

**Installation:**

No new package installation is recommended for Phase 187. Run `cd accrue_admin && npm ci` to install the already-locked E2E dependencies. [VERIFIED: package-lock + npm ls]

**Version verification:**

```bash
cd accrue_admin
npm view @playwright/test version time.modified repository.url scripts.postinstall --json
npm view @axe-core/playwright version time.modified repository.url scripts.postinstall --json
npm view @anthropic-ai/sdk version time.modified repository.url scripts.postinstall --json
npm ls @playwright/test @axe-core/playwright @anthropic-ai/sdk --depth=0 --json
```

## Package Legitimacy Audit

Phase 187 should not add external packages. Existing Node packages used by the audit harness were checked because they are part of the standard stack. [VERIFIED: codebase grep]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `@playwright/test` | npm | Existing dependency; publish history not fully audited | Not checked | `github.com/microsoft/playwright` | OK | Approved as existing dependency; use locked 1.59.1, not latest 1.60.0. [VERIFIED: npm registry + slopcheck + codebase grep; CITED: https://playwright.dev/docs/test-projects] |
| `@axe-core/playwright` | npm | Existing dependency; publish history not fully audited | Not checked | `github.com/dequelabs/axe-core-npm` | OK | Approved as existing dependency. [VERIFIED: npm registry + slopcheck + codebase grep; CITED: https://playwright.dev/docs/accessibility-testing] |
| `@anthropic-ai/sdk` | npm | Existing dependency; publish history not fully audited | Not checked | `github.com/anthropics/anthropic-sdk-typescript` | OK | Approved as existing optional scorer dependency. [VERIFIED: npm registry + slopcheck + codebase grep] |

**Packages removed due to slopcheck [SLOP] verdict:** none. [VERIFIED: slopcheck]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: slopcheck]

Note: the installed `slopcheck` CLI rejected the documented `--json` flag, so text output was used. `slopcheck install` invoked `npm install` and briefly upgraded Playwright; tracked files were restored and `npm ci` returned `node_modules` to the lockfile versions. [VERIFIED: command output + git diff]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 187 manifest
  |
  |-- surfaces: component / group / page-flow
  |-- modes: chromium-desktop / chromium-mobile
  |-- themes: light / dark
  |-- states: default-populated / empty / loading / error / permission-denied /
  |           disconnected-reconnecting / overflow / long-content /
  |           disabled-readonly / interactive-open
  v
Playwright runner (existing webServer -> mix accrue_admin.e2e.server)
  |
  |-- reset/login/seed via /__e2e__ routes
  |-- screenshot capture into test-results/admin-visuals/
  |-- axe scan after state is visible
  |-- interaction probes with trace: on for live cells
  v
Evidence files in test-results/
  |
  |-- PNGs
  |-- trace.zip files
  |-- axe JSON / findings
  |-- optional vision scorer output
  v
Artifact generator
  |
  |-- maps raw evidence -> stable cell IDs
  |-- scores 12 dimensions
  |-- creates stable defect IDs
  |-- attaches overlay tags and owner_phase
  v
Committed phase artifacts
  |
  |-- 187-RUBRIC.md
  |-- 187-BASELINE.md
  |-- baseline.cells.json
  |-- defects.ndjson
  |-- artifacts.manifest.json
  `-- optional schemas/*.schema.json
```

### Recommended Project Structure

```text
.planning/phases/187-audit-baseline/
├── 187-CONTEXT.md
├── 187-RESEARCH.md
├── 187-RUBRIC.md
├── 187-BASELINE.md
├── baseline.cells.json
├── defects.ndjson
├── artifacts.manifest.json
└── schemas/
    ├── baseline-cell.schema.json
    └── defect.schema.json

accrue_admin/e2e/
├── baseline-manifest.js          # or .json; canonical audit cells
├── admin-baseline.spec.js        # manifest-driven screenshots/state checks
├── admin-interactions.spec.js    # live interaction probes with trace evidence
└── score-visuals.mjs             # extend/wrap to 12 dimensions
```

### Pattern 1: Manifest-Driven Audit Cells

**What:** One manifest owns surface name, surface type, route, seed fixture, state taxonomy, persona job, expected evidence, and whether each cell is `covered`, `gap`, or `n/a`. [VERIFIED: CONTEXT.md]

**When to use:** Use for all baseline rows so Phase 192 can rerun the same IDs and compare no-regression output. [VERIFIED: CONTEXT.md]

**Example:**

```javascript
// Source: repo pattern from admin-visuals.spec.js + 187-CONTEXT.md
export const cells = [
  {
    id: "page:webhooks:chromium-desktop:light:interactive-open",
    surface: "webhooks",
    surface_type: "page",
    path: "/billing/webhooks",
    seed: ["operator-flows"],
    project: "chromium-desktop",
    theme: "light",
    state: "interactive-open",
    persona_job: "Operator replays a failed webhook after confirming scope",
    status: "covered",
    evidence: ["screenshot", "trace", "axe"],
    expected: ["replay confirmation visible", "trigger remains actionable"]
  }
];
```

### Pattern 2: Trace-First Interaction Evidence

**What:** For live interaction cells, turn `trace: "on"` on the specific spec or probe group and record actionability/focus/scroll assertions plus trace references in `artifacts.manifest.json`. [VERIFIED: codebase grep; CITED: https://playwright.dev/docs/trace-viewer]

**When to use:** Use for modal/drawer/dropdown/scroll/focus/live-patch/disconnected cases where screenshots cannot prove the defect. [VERIFIED: CONTEXT.md]

**Example:**

```javascript
// Source: Playwright trace docs + existing admin-motion-trace.spec.js
const { test, expect } = require("@playwright/test");

test.use({ trace: "on" });

test("AX187 probe - modal focus is trapped and restored", async ({ page, request }, testInfo) => {
  await seed(request, "operator-flows");
  await login(page, "/billing/payments/some-id");

  const trigger = page.getByRole("button", { name: /refund/i });
  await trigger.click();

  const dialog = page.getByRole("dialog");
  await expect(dialog).toBeVisible();
  await page.keyboard.press("Tab");
  await expect(dialog).toContainText(await page.evaluate(() => document.activeElement?.textContent || ""));
  await page.keyboard.press("Escape");
  await expect(dialog).toBeHidden();
  await expect(trigger).toBeFocused();

  testInfo.annotations.push({ type: "cell_id", description: "page:charge:interactive-open" });
});
```

### Pattern 3: Structured Defects with Overlay Tags

**What:** A defect is one NDJSON object with stable ID, severity, surface, reproduction, expected/actual, primary dimension, optional overlay tags, cell ID, evidence refs, owner phase, status, and notes. [VERIFIED: CONTEXT.md; CITED: https://jsonlines.org/]

**When to use:** Every static-matrix or live-interaction finding gets a row; do not bury defects only in markdown prose. [VERIFIED: CONTEXT.md]

**Example:**

```json
{"id":"AX187-001","severity":"high","surface":"webhook-detail","surface_type":"page","persona_job":"Operator replays a failed webhook","reproduction":["seed operator-flows","open /billing/webhooks/:id","click Replay"],"expected":"Confirmation remains above scrim and receives clicks","actual":"Confirmation appears behind overlay and Playwright click is intercepted","rubric_dimension":"interaction-integrity","overlay_tags":["layer-z-index","actionability"],"cell_id":"page:webhook-detail:chromium-desktop:light:interactive-open","evidence_refs":["trace:admin-interactions/webhook-replay/trace.zip"],"owner_phase":"191","status":"open","notes":"Route to IXN-01 remediation."}
```

### Anti-Patterns to Avoid

- **Literal Cartesian explosion:** Do not multiply every component, group, page, viewport, theme, and state when the locked decision requires a representative manifest. [VERIFIED: CONTEXT.md]
- **Screenshot-only interaction audit:** Screenshots and axe do not prove focus trap, focus restore, click interception, scroll reachability, or LiveView patch behavior. [VERIFIED: CONTEXT.md; CITED: https://playwright.dev/docs/actionability]
- **Markdown-only baseline:** Markdown is readable but too brittle for Phase 192 comparison; structured artifacts are canonical. [VERIFIED: CONTEXT.md]
- **Encoding current bugs as green regression tests:** Phase 187 may record evidence of broken behavior but should not create permanent tests asserting broken behavior. [VERIFIED: CONTEXT.md]
- **New component explorer dependency:** PhoenixStorybook is deferred; extend `/dev/components`. [VERIFIED: REQUIREMENTS.md + CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser interaction orchestration | Custom Puppeteer/raw CDP runner | Existing `@playwright/test` | Playwright already owns projects, traces, webServer boot, actionability checks, devices, and assertions. [VERIFIED: codebase grep; CITED: https://playwright.dev/docs/test-projects; CITED: https://playwright.dev/docs/actionability] |
| Accessibility engine | Custom DOM contrast/ARIA scanner | `@axe-core/playwright` plus manual/live probes | Official Playwright docs use axe for automated checks and explicitly warn that manual assessment is still needed. [CITED: https://playwright.dev/docs/accessibility-testing] |
| Modal keyboard model | Ad hoc focus rules | WAI-ARIA modal dialog pattern + Playwright focus assertions | APG defines focus containment, initial focus, Escape, and Tab/Shift+Tab behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] |
| Streaming defect format | Bespoke line parser | NDJSON / JSON Lines | The format already defines one JSON value per line and newline terminators for concatenation. [CITED: https://jsonlines.org/] |
| Design-token taxonomy | Parallel ad hoc token spec | Existing `brandbook/tokens` + admin `--ax-*` SSOT | Brandbook states admin `--ax-*` tokens are the implementation SSOT; DTCG exists as context for token interchange. [VERIFIED: codebase grep; CITED: https://www.designtokens.org/TR/2025.10/format/] |

**Key insight:** Phase 187's hard part is evidence normalization, not browser automation. Use existing tools for capture and spend planning effort on stable IDs, reproducible cells, severity routing, and canonical JSON/NDJSON. [VERIFIED: codebase grep + CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Baseline Drift from Unstable Cell IDs

**What goes wrong:** Phase 192 cannot compare baseline to final scorecard because cell names changed or state coverage was implicit. [VERIFIED: CONTEXT.md]  
**Why it happens:** Screenshots are named by page, while VER-01 needs surface x viewport x theme x state x dimension. [VERIFIED: codebase grep + CONTEXT.md]  
**How to avoid:** Define `cell_id` in the manifest before generating evidence; emit every `covered`, `gap`, and `n/a` cell. [VERIFIED: CONTEXT.md]  
**Warning signs:** Markdown tables have rows that do not exist in `baseline.cells.json`, or `defects.ndjson` rows lack `cell_id`. [ASSUMED]

### Pitfall 2: Axe Treated as Accessibility Completeness

**What goes wrong:** Keyboard traps, focus restore, hidden focus, and disabled affordance defects are missed. [CITED: https://playwright.dev/docs/accessibility-testing]  
**Why it happens:** Automated accessibility scans catch common machine-detectable issues but not all WCAG/usability problems. [CITED: https://playwright.dev/docs/accessibility-testing]  
**How to avoid:** Pair axe with live keyboard and trace probes for all required interaction states. [VERIFIED: CONTEXT.md]  
**Warning signs:** Passing axe output with no trace evidence for modal/dropdown/drawer flows. [ASSUMED]

### Pitfall 3: Playwright Actionability Failures Misclassified as Flakes

**What goes wrong:** An intercepted click or obscured control is retried away or ignored instead of logged as an interaction-integrity defect. [CITED: https://playwright.dev/docs/actionability]  
**Why it happens:** Playwright auto-waits until actionability checks pass; timeout messages are sometimes treated as test instability. [CITED: https://playwright.dev/docs/actionability]  
**How to avoid:** For baseline probes, capture the actionability failure, trace, overlay tag, and owner phase in the ledger. [VERIFIED: CONTEXT.md]  
**Warning signs:** Use of `{ force: true }` in probes or blanket `try/catch` that drops failures. [ASSUMED]

### Pitfall 4: Vision Scorer Remains 10-Dimension

**What goes wrong:** `interaction-integrity` and `microcopy` never get scored in structured output. [VERIFIED: codebase grep + CONTEXT.md]  
**Why it happens:** `score-visuals.mjs` currently declares `DIMENSIONS` 1-10 and prompts for exactly 10 objects per image. [VERIFIED: codebase grep]  
**How to avoid:** Extend or wrap the scorer so every screenshot/cell receives all 12 dimensions, and validate expected count. [VERIFIED: codebase grep + CONTEXT.md]  
**Warning signs:** Any generated finding has dimension range 1-10 only. [VERIFIED: codebase grep]

### Pitfall 5: Evidence Assets Accidentally Committed

**What goes wrong:** PNGs and trace zips bloat the repo. [VERIFIED: CONTEXT.md]  
**Why it happens:** Current screenshots and traces are generated under `test-results/`, which is appropriate as generated output. [VERIFIED: codebase grep]  
**How to avoid:** Commit only `artifacts.manifest.json` with paths/checksums/metadata unless human sign-off explicitly asks for representative assets. [VERIFIED: CONTEXT.md]  
**Warning signs:** `git status` shows PNG or `trace.zip` files staged. [ASSUMED]

## Code Examples

### Extend Existing Screenshot Pattern into Cells

```javascript
// Source: accrue_admin/e2e/admin-visuals.spec.js
async function captureThemes(page, name, project) {
  await expect(page.locator("#main-content")).toBeVisible();
  const dir = `test-results/admin-visuals/${project}`;
  await page.evaluate(() => document.documentElement.setAttribute("data-theme", "light"));
  await page.screenshot({ path: `${dir}/${name}.png`, fullPage: true });
  await page.evaluate(() => document.documentElement.setAttribute("data-theme", "dark"));
  await page.screenshot({ path: `${dir}/${name}-dark.png`, fullPage: true });
}
```

### Use Axe After Opening Interactive State

```javascript
// Source: Playwright accessibility docs + existing admin-a11y.spec.js
const AxeBuilder = require("@axe-core/playwright").default;

await page.getByRole("button", { name: "Navigation Menu" }).click();
await page.locator("#navigation-menu-flyout").waitFor();

const results = await new AxeBuilder({ page })
  .include("#navigation-menu-flyout")
  .withTags(["wcag2a", "wcag2aa"])
  .analyze();

expect(results.violations).toEqual([]);
```

### LiveView Focus Primitive to Recognize in Fix Planning

```elixir
# Source: Phoenix.LiveView.JS docs
JS.focus_first(to: "#modal")
```

### Defect Writer Shape

```javascript
// Source: JSON Lines format + 187-CONTEXT.md
import fs from "fs";

export function appendDefect(path, defect) {
  fs.appendFileSync(path, JSON.stringify(defect) + "\n");
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| v1.51 10-dimension screen rubric | v1.53 12-dimension rubric with `interaction-integrity` and `microcopy`, plus layer/z-index as overlay tags | Locked in Phase 187 context on 2026-06-14 | Planner must update scorer/schema/rubric and not create a 13th layer dimension. [VERIFIED: CONTEXT.md] |
| Static screenshot QA as primary sign-off | Screenshot + axe + trace-backed live interaction evidence | Locked in Phase 187 context on 2026-06-14 | Interaction defects require traces and keyboard/actionability probes. [VERIFIED: CONTEXT.md] |
| Screen-level state matrix from Phase 178 | Component + group + page/flow manifest with explicit `covered`/`gap`/`n/a` cells | Locked in Phase 187 context on 2026-06-14 | Baseline must include component lab and component groups, not only pages. [VERIFIED: CONTEXT.md] |
| Brand prompt as primary voice source | `brandbook/voice.md`, `brandbook/copy.md`, and `brandbook/tokens` supersede older prompt conflicts | Phase 185 / Phase 187 context | Microcopy findings must follow measured/exact/native/durable voice. [VERIFIED: codebase grep + CONTEXT.md] |

**Deprecated/outdated:**
- 10-dimension-only `score-visuals.mjs` prompt: keep as a starting point but update to 12 dimensions. [VERIFIED: codebase grep + CONTEXT.md]
- `/billing/charges` terminology in old state matrix: current screenshot suite uses `/billing/payments` and `charge-detail`; planner should verify route names from the current code before copying older paths. [VERIFIED: codebase grep]
- PhoenixStorybook adoption: deferred; do not plan it in Phase 187. [VERIFIED: REQUIREMENTS.md + CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | JSON Schema should be used if cheap for artifact validation. | Standard Stack | Planner may add more tooling than needed; mitigate by making schemas optional per D-18. |
| A2 | Warning signs listed for drift, axe-only coverage, force-click usage, and committed binary assets are inferred planning heuristics. | Common Pitfalls | Low; these are planner guardrails, not implementation facts. |

## Open Questions

1. **Should Phase 187 run the optional Anthropic vision scorer during execution?**
   - What we know: `score-visuals.mjs` skips cleanly when `ANTHROPIC_API_KEY` is absent. [VERIFIED: codebase grep]
   - What's unclear: Whether the execution environment for the phase will have the key and model access. [ASSUMED]
   - Recommendation: Plan the scorer update as required, but make the actual vision API run a human/CI gate that records `gap` if credentials are absent. [VERIFIED: codebase grep + CONTEXT.md]

2. **How much fixture expansion is required for permission-denied and disconnected-reconnecting?**
   - What we know: Existing fixtures cover dashboard, operator-flows, edge-states, and overflow. [VERIFIED: codebase grep]
   - What's unclear: Current E2E support does not obviously expose named permission-denied or LiveView disconnected/reconnecting fixture routes. [VERIFIED: codebase grep]
   - Recommendation: Planner should include a Wave 0 gap task to either add minimal E2E controls for these states or mark cells as `gap` defects with explicit seed/tooling ownership. [VERIFIED: CONTEXT.md]

3. **Should package versions be upgraded?**
   - What we know: npm latest for Playwright is 1.60.0, but the repo lockfile installs 1.59.1 and Phase 187 is not a dependency-upgrade phase. [VERIFIED: npm registry + npm ls + git diff]
   - What's unclear: Whether a later dependency maintenance pass wants the latest Playwright. [ASSUMED]
   - Recommendation: Do not upgrade in Phase 187 unless a locked Playwright bug blocks trustworthy evidence. [VERIFIED: CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Node.js | Playwright and artifact scripts | yes | v22.14.0 | None needed. [VERIFIED: command output] |
| npm | E2E dependency install/scripts | yes | 11.1.0 | None needed. [VERIFIED: command output] |
| Elixir | `accrue_admin` Mix tasks/tests | yes | 1.19.5 / OTP 28 | None needed. [VERIFIED: command output] |
| Mix | E2E server and test suite | yes | 1.19.5 / OTP 28 | None needed. [VERIFIED: command output] |
| PostgreSQL | E2E test database | yes | `pg_isready`: accepting connections on `/tmp:5432` | None needed. [VERIFIED: command output] |
| Playwright Chromium browser | E2E run | not probed | Package installed; browser binary not checked | Run `cd accrue_admin && npm run e2e:install` if browser launch fails. [VERIFIED: package.json] |
| `ANTHROPIC_API_KEY` | Optional vision scoring | not checked | n/a | Scorer skips cleanly without key; record as manual/CI gate. [VERIFIED: codebase grep] |
| Context7 CLI | Documentation lookup | no | n/a | Official docs were fetched directly from primary sources. [VERIFIED: command output] |
| slopcheck | Package legitimacy | yes | CLI present; no `--json` support | Text output used. [VERIFIED: command output] |

**Missing dependencies with no fallback:** none identified for planning. [VERIFIED: command output + codebase grep]  
**Missing dependencies with fallback:** Context7 CLI unavailable; official docs were fetched directly. Playwright browser binary was not probed; `npm run e2e:install` is the existing fallback/install step. [VERIFIED: command output + package.json]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit for Elixir; Playwright Test 1.59.1 for browser E2E; axe via `@axe-core/playwright` 4.11.3. [VERIFIED: mix.exs + npm ls] |
| Config file | `accrue_admin/playwright.config.js`; ExUnit standard config in `accrue_admin/test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `cd accrue_admin && npm run e2e -- e2e/admin-interactions.spec.js --project=chromium-desktop -x` after the new spec exists. [ASSUMED] |
| Full suite command | `cd accrue_admin && npm run e2e` plus `cd accrue_admin && mix test --warnings-as-errors`. [VERIFIED: package.json + GitHub workflow grep] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| VER-01 | 12-dimension rubric and artifact schemas exist | artifact/unit | `test -f .planning/phases/187-audit-baseline/187-RUBRIC.md && test -f .planning/phases/187-audit-baseline/baseline.cells.json && test -f .planning/phases/187-audit-baseline/defects.ndjson` | No; Wave 0. [VERIFIED: phase dir scan] |
| VER-01 | Static matrix captures page/component/group cells across desktop/mobile and light/dark | Playwright E2E | `cd accrue_admin && npm run e2e -- e2e/admin-baseline.spec.js --project=chromium-desktop -x` | No; Wave 0. [VERIFIED: codebase grep] |
| VER-01 | Axe support runs on opened states where relevant | Playwright E2E | `cd accrue_admin && npm run e2e:a11y` plus new interactive-state axe probes | Existing page scan yes; interactive-state expansion no. [VERIFIED: codebase grep] |
| VER-01 | Live interaction probes produce trace evidence and ledger defects | Playwright E2E | `cd accrue_admin && npm run e2e -- e2e/admin-interactions.spec.js -x` | No; Wave 0. [VERIFIED: codebase grep] |
| VER-01 | Baseline artifacts are structurally parseable | Node/script smoke | `node -e 'JSON.parse(require("fs").readFileSync(".planning/phases/187-audit-baseline/baseline.cells.json","utf8")); for (const l of require("fs").readFileSync(".planning/phases/187-audit-baseline/defects.ndjson","utf8").trim().split("\\n")) JSON.parse(l)'` | No; Wave 0. [ASSUMED] |

### Sampling Rate

- **Per task commit:** Run the narrow Playwright spec or artifact parser touched by the task. [ASSUMED]
- **Per wave merge:** Run `cd accrue_admin && npm run e2e -- e2e/admin-baseline.spec.js e2e/admin-interactions.spec.js` after those files exist. [ASSUMED]
- **Phase gate:** Run `cd accrue_admin && npm run e2e`, `cd accrue_admin && mix test --warnings-as-errors`, and parse all committed Phase 187 JSON/NDJSON artifacts. [VERIFIED: package.json + GitHub workflow grep]

### Wave 0 Gaps

- [ ] `accrue_admin/e2e/baseline-manifest.js` or `.json` - canonical cells for VER-01. [VERIFIED: codebase grep]
- [ ] `accrue_admin/e2e/admin-baseline.spec.js` - manifest-driven static matrix and evidence generation. [VERIFIED: codebase grep]
- [ ] `accrue_admin/e2e/admin-interactions.spec.js` - modal/drawer/dropdown/scroll/focus/actionability probes with traces. [VERIFIED: codebase grep]
- [ ] Artifact generator script - emits `baseline.cells.json`, `defects.ndjson`, `artifacts.manifest.json`, and optional schemas. [VERIFIED: CONTEXT.md]
- [ ] `score-visuals.mjs` extension or wrapper - 12 dimensions and stable cell IDs. [VERIFIED: codebase grep + CONTEXT.md]
- [ ] Permission-denied and disconnected/reconnecting reachability decision - add minimum fixture/probe support or mark explicit gaps. [VERIFIED: CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no new auth behavior | Existing E2E login route only for test harness; do not alter production auth. [VERIFIED: codebase grep] |
| V3 Session Management | no new session behavior | Existing `__e2e__/login` puts test session token; keep test-only. [VERIFIED: codebase grep] |
| V4 Access Control | yes, as audit subject | Permission-denied cells must be observed or logged as gaps; Phase 187 should not change production access logic. [VERIFIED: REQUIREMENTS.md + CONTEXT.md] |
| V5 Input Validation | yes, for artifact parsers | Parse JSON/NDJSON with standard JSON APIs; do not use ad hoc string parsing. [CITED: https://jsonlines.org/] |
| V6 Cryptography | yes, for artifact manifest checksums only | Use Node `crypto` hash APIs if checksums are generated; do not hand-roll hashing. [ASSUMED] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Test-only E2E routes exposed outside test environment | Elevation of privilege | Keep E2E plug/server under test-only Mix task and do not add production routes. [VERIFIED: codebase grep] |
| Artifact path traversal in manifest generator | Tampering | Resolve paths under known generated-output roots and write committed artifacts only under phase dir. [ASSUMED] |
| Untrusted model output corrupts baseline JSON | Tampering | Parse and validate vision output; enrich authoritative metadata from manifest, not model-supplied screen/theme/dimension fields. Existing scorer already overrides some metadata. [VERIFIED: codebase grep] |
| Leaking secrets in traces/screenshots | Information disclosure | Use deterministic fake/admin test fixtures; do not run against production/staging. [VERIFIED: codebase grep + CONTEXT.md] |
| Flaky live probes blocking baseline | Denial of service | Keep workers 1/serial pattern and record gaps honestly instead of forcing retries that hide defects. [VERIFIED: playwright.config.js + CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/187-audit-baseline/187-CONTEXT.md` - locked decisions D-01..D-27, artifact names, state taxonomy, and phase boundaries. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - VER-01 and v1.53 scope/deferrals. [VERIFIED: codebase grep]
- `.planning/STATE.md` - v1.53 dependency shape and current project posture. [VERIFIED: codebase grep]
- `accrue_admin/playwright.config.js` - projects, webServer, outputDir, trace/screenshot defaults. [VERIFIED: codebase grep]
- `accrue_admin/e2e/admin-visuals.spec.js`, `admin-a11y.spec.js`, `admin-motion-trace.spec.js`, `score-visuals.mjs` - existing audit harness. [VERIFIED: codebase grep]
- `accrue_admin/test/support/e2e_fixtures.ex`, `e2e_plug.ex` - deterministic reset/login/seed support. [VERIFIED: codebase grep]
- `brandbook/voice.md`, `brandbook/copy.md`, `brandbook/tokens/README.md` - binding microcopy and token lens. [VERIFIED: codebase grep]
- Playwright docs: projects, trace viewer, actionability, accessibility testing. [CITED: https://playwright.dev/docs/test-projects] [CITED: https://playwright.dev/docs/trace-viewer] [CITED: https://playwright.dev/docs/actionability] [CITED: https://playwright.dev/docs/accessibility-testing]
- Phoenix LiveView JS docs. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html]
- WAI-ARIA APG modal dialog pattern and WCAG 2.2. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] [CITED: https://www.w3.org/TR/WCAG22/]
- JSON Lines format. [CITED: https://jsonlines.org/]

### Secondary (MEDIUM confidence)

- npm registry metadata for `@playwright/test`, `@axe-core/playwright`, and `@anthropic-ai/sdk`. [VERIFIED: npm registry]
- slopcheck text-mode package legitimacy output. [VERIFIED: slopcheck]

### Tertiary (LOW confidence)

- JSON Schema recommendation and some warning-sign heuristics are planning assumptions, not verified project requirements. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Existing dependencies, lockfile installs, npm metadata, slopcheck text output, and official docs agree. [VERIFIED: npm registry + codebase grep + official docs]
- Architecture: HIGH - Phase context and current harness align closely; no new platform is needed. [VERIFIED: CONTEXT.md + codebase grep]
- Pitfalls: MEDIUM - Main pitfalls are grounded in current code and official docs; warning signs include some inferred planner heuristics. [VERIFIED: codebase grep + official docs; ASSUMED]

**Research date:** 2026-06-14  
**Valid until:** 2026-07-14 for repo architecture; 2026-06-21 for npm latest-version metadata.
