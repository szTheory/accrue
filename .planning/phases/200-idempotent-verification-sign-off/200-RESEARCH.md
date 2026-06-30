# Phase 200: Idempotent verification & sign-off - Research

**Researched:** 2026-06-30
**Domain:** Phoenix LiveView admin UI verification, PhoenixStorybook coverage/theming, Playwright/axe guardrails, forward-only scorecard sign-off
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
[VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

#### D-01: Closeout posture - staged-full sign-off, not per-PR exhaustive

Phase 200 should run in a staged-full mode:
- deterministic guardrails stay in CI as tasks land;
- full union scorecard, adversarial judge, and maintainer ACCEPT/REJECT happen at final closeout after all artifacts are generated.

This avoids blocking every small repair on full human/model ceremony while still requiring proof at the final boundary.

#### D-02: Phase 200 is verification/sign-off only, not a new UI/build phase

Phase 200 should not broaden feature scope or perform general redesign/polish. It may make narrow repairs only when they are required to resolve a blocking regression, missing story coverage, theming failure, accessibility failure, or sign-off blocker.

#### D-03: Planned phase shape

Plan the phase around these waves:

1. Storybook completeness + theming parity
2. Storybook and page-route a11y/theme guardrails
3. Union scorecard + artifact verifier
4. Bounded multi-lens judge
5. Final sign-off + state/requirements reconciliation

#### D-04: Phase 200 should account for reviewed TODO evidence without absorbing broad implementation

The Phase 199 discussion cross-checked the open TODO inventory against v1.54 requirements. For Phase 200:
- include the reviewed open TODO list in the adversarial/maintainer checkpoint as known non-blocking scope;
- do not turn the broad TODO backlog into Phase 200 work;
- only escalate a TODO if it directly blocks VER-01, VER-02, VER-03, STY-02, or STY-03.

#### D-05: Open TODOs reviewed during discussion

Reviewed TODO inventory:
- `accrue_admin/e2e/README.md`: browser debugging selector recipe for `/reports`
- `accrue_admin/assets/js/theme_test.js`: add DOM/theme unit tests for `accrueTheme.setTheme` and `system`
- `packages/testing/test-utils/src/setup.ts`: non-browser DOM test helper
- `accrue_admin/lib/accrue_admin/router.ex`: API-key bootstrap auth at `/api/bootstrap` listed for future Phase 202
- `accrue_admin/test/accrue_admin/bootstrap_manual_flow_test.exs`: notes OAuth before bootstrap
- `accrue_admin/test/support/bootstrap_manual_flow.ex`: notes OAuth before bootstrap
- `accrue_admin/test/support/bootstrap_orchestrator.ex`: notes OAuth before bootstrap
- `accrue_admin/test/support/ui_case.ex`: lazy dashboard bootstrap helper
- `crates/core/src/**/*.rs`: intentionally future high-value finance engine modules
- `packages/accrue-dsl/src/index.ts`: placeholder DSL parser

Decision: none of these are Phase 200 implementation scope unless a verification gate proves one is a blocking regression.

#### D-06: Storybook strategy - hybrid generated + curated, not all-handwritten

Use a hybrid Storybook strategy:
- generated registry-driven stories are the completeness floor for simple registry entries and state permutations;
- curated wrappers are allowed for composites, named slots, overlays/drawers, and design-lab/foundation stories where raw generated variations would be too weak.

Storybook completeness must be dynamic against the registry, not a hardcoded count.

#### D-07: ComponentRegistry remains SSOT

`ComponentRegistry` remains the single source of truth for component metadata, variants, examples, states, and group contracts. Storybook stories and verification should derive from it rather than introducing a parallel catalog.

#### D-08: Registry inventory discovered for planning

Scout command found:
- 30 unique families
- 42 registry entries
- 8 group contracts

These numbers are useful for scoping, but tests should derive them dynamically so future registry changes do not require updating hardcoded expected counts.

#### D-09: RegistryStory support needs expansion

Extend the Storybook support layer, likely `accrue_admin/storybook/_support/registry_story.ex`, to cover:
- state groups;
- `na_states`;
- stable slugified variation IDs;
- unique DOM IDs for examples;
- named-slot or template escape hatches for components that cannot render from attributes alone.

Group stories should be driven from `ComponentRegistry.group_contracts/0` and prove:
- group id/slug;
- required states;
- hierarchy or composition expectations;
- behavior contracts;
- representative rendered composition marked with `data-component-group`.

#### D-10: Keep `/dev/components` as a second renderer

Do not replace or weaken the existing component kitchen. Storybook is an additional documentation/verification surface. Phase 189/190 drift tests and `/dev/components` checks must remain green.

#### D-11: Storybook theming parity decisions

Phase 200 must prove Storybook theme parity against the shipped committed `ax-*` bundle.

Implementation direction:
- explicitly enable PhoenixStorybook color mode support;
- keep `color_mode_sandbox_dark_class: "ax-theme-dark-shim"` unless a verified better bridge is found;
- make the Storybook sandbox receive the same effective light/dark token scopes as `html.accrue-admin[data-theme]`;
- keep loading the committed `storybook.css` and `storybook.js` bundle;
- add a parity guard so future `theme.css` dark token changes cannot miss Storybook.

Do not add a Tailwind rebuild path.

#### D-12: Storybook asset and adopter leak boundaries

Verify:
- Storybook CSS and JS route through the shipped committed bundle;
- `/dev/storybook` works in the admin dev/test surface;
- Storybook routes are not exposed from host/adopter runtime surfaces;
- `phoenix_storybook` remains dev/test-only.

#### D-13: Union baseline inputs

Phase 200 should compare against the union of:
- component/group cells: `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.cells.json` (21,276 cells)
- page-flow cells: `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.page-flow.cells.json` (9,072 cells)

Expected union size is 30,348 rows unless implementation discovers duplicates and documents the dedupe key/proof.

#### D-14: Archived baselines are immutable

Do not mutate archived Phase 187/193 baseline files.

Phase 200 should write derived outputs under its own phase directory. Improvements are represented as positive `score_delta`. Historical invalid rows, if any are discovered, require an explicit `baseline_correction` field instead of silently editing the baseline.

#### D-15: Pending page-flow cells must close

All `p193` page-flow cells currently marked pending must be resolved in Phase 200:
- `coverage_status: "covered"`
- deterministic evidence reference
- final score meets the agreed floor, expected `score >= 2`

#### D-16: Phase 200 output paths

Write Phase 200 artifacts under `.planning/phases/200-idempotent-verification-sign-off/`, including:
- `baseline.union.cells.json`
- `final.cells.json`
- `scorecard.delta.json`
- `regressions.ndjson`
- `artifacts.manifest.json`
- `200-SCORECARD.md`
- `200-STORYBOOK-COVERAGE.md`
- `200-SIGN-OFF.md`
- `200-VERIFICATION.md`

Do not write new outputs into archived Phase 192 directories.

#### D-17: Empty regressions file is the hard close signal

The final `regressions.ndjson` must be empty for ACCEPT. Any line means a blocking regression remains unless it is resolved and the artifact regenerated.

#### D-18: CI should run deterministic guardrails, not model or human gates

CI should include deterministic checks:
- baseline parse and duplicate-key check;
- scorecard verifier;
- sign-off verifier;
- package docs for Phase 200 artifacts;
- registry/group tests;
- axe checks;
- reduced-motion checks;
- Phase 199 E2E regressions;
- Storybook structural/theming checks;
- host/adopter leak checks.

Do not require model-dependent judge or maintainer sign-off on every PR.

#### D-19: Accessibility and interaction coverage matrix

Use a hybrid risk matrix, not exhaustive Cartesian expansion in CI:
- axe over all primary routes and completed Storybook stories in settled light/dark modes;
- targeted Playwright interaction checks for risky widgets, overlays/drawers, focus handling, theme persistence/no-FOUC, reduced motion, copy, and layout contracts.

#### D-20: Theme/no-FOUC proof uses production path

Theme persistence and no-FOUC checks must exercise production behavior:
- `accrue_theme` cookie;
- localStorage;
- system emulation;
- malformed/stale values;
- reload behavior.

Directly forcing `data-theme` is acceptable only for settled visual/axe scans and must be labeled as a bypass, not as persistence proof.

#### D-21: axe is required but not sufficient

axe-core checks must include color-contrast and name/role coverage, but ACCEPT cannot rely on axe alone.

Additional proof should cover:
- focus order;
- focus trap/restore;
- Escape/backdrop behavior;
- keyboard reachability;
- status semantics;
- text reflow or responsive degradation;
- copy clarity;
- brand fit;
- JTBD-specific interaction expectations.

#### D-22: Browser gates must be stable

Use stable Playwright patterns:
- deterministic reset/seed;
- package-local Playwright;
- `env -u NO_COLOR` for output-sensitive commands;
- one worker for stateful tests;
- web-first assertions;
- traces for failures or final interaction evidence.

Avoid sleeps and pixel-diff dependence.

#### D-23: Reduced-motion proof must be behavioral

Reduced-motion validation should prove actual behavioral collapse/reduction for:
- motion duration;
- transform travel;
- focus-ring timing;
- overlay/drawer transitions;
- interaction affordances.

Do not limit this to token inspection.

#### D-24: Final sign-off document is canonical

`200-SIGN-OFF.md` is the sole final maintainer decision record.

It must include:
- deterministic artifact summary;
- reviewed judge findings;
- maintainer photographic/interaction checkpoint;
- explicit ACCEPT or REJECT.

The final decision line should use an exact verifier-friendly form, for example:
- `Final maintainer decision: ACCEPT ...`
- `Final maintainer decision: REJECT ...`

#### D-25: Structured artifacts are canonical; markdown summarizes

Markdown reports summarize evidence, but scripts should verify structured artifacts:
- JSON/NDJSON scorecard outputs;
- manifest;
- sign-off exact decision line;
- explicit status fields.

#### D-26: Judge scope is bounded to four lenses

The adversarial judge should use only these lenses:
- correctness;
- accessibility;
- brand;
- interaction.

It should not invent new product scope. Findings are blocking only when tied to locked requirements, baseline regressions, or explicit guardrail failures.

#### D-27: Finding severity semantics

Use these severity labels:
- `BLOCKER`: must fix before ACCEPT
- `REPAIR-IN-PHASE`: narrow repair needed in Phase 200 before final verifier rerun
- `ADVISORY`: record, but does not block ACCEPT
- `DEFERRED`: outside v1.54 / future milestone

#### D-28: ACCEPT is all-or-nothing across locked gates

ACCEPT requires:
- empty `regressions.ndjson`;
- no coverage downgrade;
- every comparable cell score >= baseline;
- all deterministic guardrails green;
- Storybook coverage/theming green;
- maintainer checkpoint rows accepted;
- no unresolved judge or maintainer blocking findings.

#### D-29: REJECT must be actionable

If final decision is REJECT, the sign-off document must name the exact blocking findings and the repair artifacts/tests required for a future ACCEPT.

#### D-30: Prefer traces for final interaction evidence

For interaction claims, prefer Playwright traces or deterministic logs over screenshots alone. Screenshots can supplement visual review but should not be the only evidence for behavior.

#### D-31: No stale `human_needed`, `pending`, or missing-artifact state at close

At final close:
- no required Phase 200 artifact may be missing;
- no requirement owned by Phase 200 may remain `pending`, `human_needed`, or ambiguously partial;
- `.planning/STATE.md` and `.planning/REQUIREMENTS.md` must reflect the final accepted/rejected state.

### the agent's Discretion
[VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

- Exact script filenames and npm aliases, as long as outputs land in Phase 200 and CI can run deterministic guards.
- Exact Storybook page/story organization, as long as `ComponentRegistry` remains SSOT and dynamic completeness is verified.
- Exact route/story batch sizes for axe scans, as long as all completed stories and required page-flow routes are covered.
- Exact sign-off wording beyond the verifier-friendly final decision line, as long as it follows brandbook voice and is evidence-backed.

### Deferred Ideas (OUT OF SCOPE)
[VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

- White-label portal/adopter UI (`accrue_portal`) remains future Phase 201/202+ scope.
- Brandbook/favicon public asset follow-up remains future scope unless a concrete Phase 200 artifact link is broken.
- Runtime replacement of `/dev/components` by Storybook is deferred; keep both surfaces for v1.54 closeout.
- Tailwind-style rebuild remains rejected.
- Pixel-diff/SaaS visual regression remains deferred.
- Full Cartesian viewport x theme x state x page flow for every CI run remains rejected.
- Broad TODO polish and future finance engine TODOs remain out of scope.
</user_constraints>

## Summary

Phase 200 should be planned as a closeout phase for the `accrue_admin` operator UI: fill the missing Storybook coverage/theming proof, run deterministic browser and artifact guardrails, reduce the archived v1.53 component/group/page-flow baselines into a Phase 200 union scorecard, then produce one verifier-friendly maintainer sign-off artifact. The locked scope is verification-only; implementation work should be limited to missing proof infrastructure and narrow repairs for blockers found by those gates. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

The current stack already contains the needed tools: PhoenixStorybook 1.2.0 is a dev/test dependency in `accrue_admin`, Playwright is configured package-locally with single-worker browser execution, axe-core scans already cover admin routes, reduced-motion and Phase 199 interaction suites exist, and the registry/kitchen drift tests are already in place. Phase 200 should not add or upgrade packages; the planning risk is wiring the existing surfaces into complete, dynamic, repeatable evidence rather than introducing a new visual testing system. [VERIFIED: accrue_admin/mix.exs] [VERIFIED: accrue_admin/package-lock.json] [VERIFIED: codebase grep]

The union baseline was verified locally as 30,348 unique rows: 21,276 component/group cells plus 9,072 page-flow cells with zero duplicate IDs. The page-flow cells are currently `p193` pending rows, so Phase 200 must generate final covered evidence for them rather than treating presence in the baseline as completion. [VERIFIED: node JSON inspection of .planning/milestones/v1.53-phases/187-audit-baseline/*.json]

**Primary recommendation:** plan five waves in this order: Storybook dynamic coverage and theme bridge, rendered Storybook/page a11y and theme guardrails, union scorecard reducer and artifact verifier, bounded four-lens judge, final maintainer sign-off plus state/requirements reconciliation. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Registry-driven Storybook coverage | Frontend Server / dev-test LiveView | Browser | `ComponentRegistry` and PhoenixStorybook modules generate the catalog; Playwright proves rendered stories load and satisfy states. [VERIFIED: codebase grep] |
| Storybook theme parity | Frontend Server / Static assets | Browser | The Storybook backend loads committed `storybook.css/js`; browser tests must prove light/dark sandbox behavior against rendered DOM. [VERIFIED: accrue_admin/lib/accrue_admin/dev/storybook.ex] [CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.html] |
| Route and story accessibility checks | Browser / CI | Frontend Server | axe and Playwright need real rendered pages, with server routes supplying deterministic admin and Storybook surfaces. [VERIFIED: accrue_admin/e2e/admin-a11y.spec.js] |
| Theme persistence and no-FOUC | Browser | Frontend Server | Production behavior is decided by cookie/localStorage/system state and root layout boot code, then observed across reloads in Playwright. [VERIFIED: accrue_admin/assets/js/accrue_theme.js] [VERIFIED: accrue_admin/lib/accrue_admin_web/components/layouts.ex] |
| Union scorecard and regressions | Tooling / CI | Planning artifacts | Score comparison is pure JSON/NDJSON reduction over archived baselines and newly generated final evidence; it should not depend on browser state after artifacts exist. [VERIFIED: accrue_admin/e2e/phase192-scorecard.mjs] |
| Multi-lens judge | Planning artifacts | Browser evidence | The judge consumes deterministic evidence and traces/screenshots; it does not own product behavior or create new scope. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |
| Maintainer ACCEPT/REJECT | Planning artifacts | CI verifier | `200-SIGN-OFF.md` is the canonical human decision, while scripts verify exact status fields and artifact presence. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |
| Requirements/state reconciliation | Planning docs | CI verifier | `.planning/REQUIREMENTS.md` and `.planning/STATE.md` must match the final decision and contain no stale pending/human-needed state for Phase 200 requirements. [VERIFIED: .planning/REQUIREMENTS.md] |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VER-01 | Prove every inherited component, group, and page-flow cell is forward-only versus the union baseline with zero regressions. [VERIFIED: .planning/REQUIREMENTS.md] | Build `baseline.union.cells.json`, `final.cells.json`, `scorecard.delta.json`, and empty `regressions.ndjson`; verify 30,348 unique baseline rows and fail on score or coverage downgrade. [VERIFIED: node JSON inspection] |
| VER-02 | Prove accessibility, theme/no-FOUC, reduced-motion, group-contract, and guardrail suites pass in CI. [VERIFIED: .planning/REQUIREMENTS.md] | Extend existing Playwright/axe/reduced-motion/group-contract suites to include Storybook stories and page-flow routes; keep deterministic one-worker CI guardrails. [VERIFIED: accrue_admin/e2e/admin-a11y.spec.js] [VERIFIED: playwright.config.js] |
| VER-03 | Produce adversarial multi-lens judge review and final maintainer sign-off with explicit ACCEPT/REJECT. [VERIFIED: .planning/REQUIREMENTS.md] | Use structured four-lens findings, severity semantics, trace-backed evidence, and exact final decision line in `200-SIGN-OFF.md`. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |
| STY-02 | Every `ComponentRegistry` family and all 8 group contracts have registry-driven Storybook coverage while registry and kitchen remain SSOT/green. [VERIFIED: .planning/REQUIREMENTS.md] | Generate stories dynamically from 30 current families, 42 entries, and 8 groups, but assert dynamic registry completeness rather than hardcoded counts. [VERIFIED: MIX_ENV=test registry inventory] |
| STY-03 | Stories render correctly in both color modes against the committed `ax-*` bundle with `html.accrue-admin[data-theme]` scoping bridged into Storybook. [VERIFIED: .planning/REQUIREMENTS.md] | Enable PhoenixStorybook color mode, keep dark shim, load committed Storybook assets, and add parity/asset/browser checks. [VERIFIED: accrue_admin/lib/accrue_admin/dev/storybook.ex] [CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.html] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Accrue is an Elixir/Phoenix monorepo; `accrue_admin` is the Phoenix LiveView admin dashboard and the current v1.54 UI scope. [VERIFIED: CLAUDE.md]
- `accrue_admin` intentionally hard-depends on Phoenix LiveView; core packages must remain LiveView-runtime-free. [VERIFIED: CLAUDE.md]
- Do not broaden Phase 200 into portal/adopter UI, public brand assets, finance engine features, new billing primitives, or general redesign. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/REQUIREMENTS.md]
- Do not introduce a Tailwind migration or Tailwind rebuild path; the admin UI uses the committed `ax-*` token/component bundle. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]
- PhoenixStorybook must remain dev/test-only for this phase; host/adopter production surfaces must not expose `/dev/storybook`. [VERIFIED: accrue_admin/mix.exs] [VERIFIED: accrue_admin/lib/accrue_admin_web/router.ex]
- No project-local skills were found in `.claude/skills` or `.agents/skills`; no additional skill-specific constraints apply. [VERIFIED: filesystem inspection]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| PhoenixStorybook | 1.2.0 | LiveView Storybook backend and `Variation`-based story rendering for dev/test. | Already installed as `phoenix_storybook`, locked in `mix.lock`, official docs support sandbox CSS/JS paths and color mode configuration. [VERIFIED: mix deps] [CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.html] |
| Phoenix LiveView | 1.1.31 | Runtime surface for admin routes, component kitchen, Storybook previews, and route-level verification. | Existing admin app and Storybook are LiveView surfaces; Phase 200 verifies rendered behavior, not a new client framework. [VERIFIED: mix deps] |
| ExUnit / Mix | 1.19.5 locally | Registry, group-contract, asset, and route boundary tests. | Existing admin tests already verify registry/kitchen contracts and Phoenix route behavior. [VERIFIED: local environment probe] [VERIFIED: codebase grep] |
| `@playwright/test` | 1.59.1 installed | Browser automation for Storybook, admin routes, theme/no-FOUC, reduced motion, and interaction traces. | Existing Playwright config is package-local, single-worker, trace-enabled, and already used for Phase 199 and a11y guardrails. [VERIFIED: package-lock.json] [VERIFIED: playwright.config.js] |
| `@axe-core/playwright` | 4.11.3 installed | axe-core integration for rendered browser accessibility checks. | Existing admin a11y suite already uses `AxeBuilder` with WCAG tags; official Deque docs support this pattern. [VERIFIED: package-lock.json] [VERIFIED: accrue_admin/e2e/admin-a11y.spec.js] [CITED: https://raw.githubusercontent.com/dequelabs/axe-core-npm/develop/packages/playwright/README.md] |
| `axe-core` | 4.11.4 installed | Underlying accessibility rule engine for name/role and color-contrast checks. | Required transitive/runtime engine for Deque Playwright scans; Deque documents automatic coverage limits and manual-review gaps. [VERIFIED: package-lock.json] [CITED: https://github.com/dequelabs/axe-core] |
| Node.js | 22.14.0 locally | Deterministic JSON/NDJSON reducers, artifact manifests, and CI verification scripts. | Existing Phase 192 scorecard/signoff verifiers are Node scripts and can be parameterized or copied for Phase 200. [VERIFIED: local environment probe] [VERIFIED: codebase grep] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Playwright-managed Chromium | 1217 cache path available | Stable browser binary for CI/local route and Storybook checks. | Use package-managed Playwright browsers; system `chromium` is a broken symlink locally. [VERIFIED: local environment probe] |
| PostgreSQL | server accepting local connections; `psql` 14.17 | Test server data backing for admin browser routes. | Needed by existing Phoenix test/e2e server path. [VERIFIED: local environment probe] |
| GitHub Actions | existing workflows | Run deterministic Phase 200 guardrails in CI. | Add or update jobs to call Phase 200 verifier scripts without model/human gates. [VERIFIED: .github/workflows inspection] |
| `env -u NO_COLOR` | shell builtin/env | Stable output for commands sensitive to terminal color. | Use for Playwright/guardrail commands that feed deterministic logs or CI parsers. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing PhoenixStorybook | A separate JS Storybook app | Rejected for Phase 200 because it creates a parallel catalog and new build surface instead of verifying the Phoenix registry SSOT. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |
| Registry-driven generated stories | All handwritten stories | Rejected for completeness because handwritten catalogs drift from `ComponentRegistry`. Curated wrappers are allowed only where attributes alone cannot render useful examples. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |
| Playwright + axe hybrid guardrails | Screenshot/pixel-diff service | Pixel-diff/SaaS visual regression is explicitly deferred; Phase 200 should use deterministic rendered DOM, axe, traces, and scorecard evidence. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |
| Existing locked Playwright/axe packages | Upgrade to latest npm releases | Avoid package churn in a verification-only closeout; latest package names were flagged by the legitimacy seam as too new, and installed versions already satisfy existing tests. [VERIFIED: package-legitimacy check] |
| Structured JSON/NDJSON artifacts | Markdown-only sign-off | Rejected because CI/verifiers need exact parseable status, regression, manifest, and decision fields. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |

**Installation:**

No new Phase 200 packages are recommended. Use the existing dependency locks:

```bash
cd accrue_admin
mix deps.get
npm ci
npx playwright install chromium
```

**Version verification:** Versions above were verified on 2026-06-30 with `mix deps`, `mix hex.info phoenix_storybook`, `npm view <pkg>@<version> time version repository scripts.postinstall`, package-lock inspection, and local CLI probes. [VERIFIED: mix deps] [VERIFIED: npm registry] [VERIFIED: local environment probe]

## Package Legitimacy Audit

Phase 200 should not install new external packages. The audit below covers existing packages that the phase relies on. npm package names checked as bare names returned `SUS` from the package-legitimacy seam because their latest releases are recent; the recommended disposition is to keep the existing lockfile versions and avoid upgrades in this closeout phase. [VERIFIED: package-legitimacy check] [VERIFIED: npm registry]

| Package | Registry | Age / Release | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|---------------|-----------|-------------|---------|-------------|
| `phoenix_storybook` | Hex | 1.2.0 released 2026-06-11 | 7,301 last 7 days; 1,596,137 all time | `github.com/phenixdigital/phoenix_storybook` | OK | Approved existing dev/test dependency; no new install. [VERIFIED: mix hex.info] |
| `@playwright/test` | npm | Installed 1.59.1 published 2026-04-01; latest 1.61.1 modified 2026-06-30 | 40,791,905 weekly for package | `github.com/microsoft/playwright` | SUS latest-recency signal | Keep locked 1.59.1; do not upgrade in Phase 200. [VERIFIED: npm registry] [VERIFIED: package-legitimacy check] |
| `@axe-core/playwright` | npm | Installed 4.11.3 published 2026-04-30; latest 4.12.1 modified 2026-06-23 | 5,027,653 weekly for package | `github.com/dequelabs/axe-core-npm` | SUS latest-recency signal | Keep locked 4.11.3; do not upgrade in Phase 200. [VERIFIED: npm registry] [VERIFIED: package-legitimacy check] |
| `axe-core` | npm | Installed 4.11.4 published 2026-04-29; latest 4.12.1 modified 2026-06-29 | 51,203,206 weekly for package | `github.com/dequelabs/axe-core` | SUS latest-recency signal | Keep locked transitive/direct dependency; no Phase 200 upgrade. [VERIFIED: npm registry] [VERIFIED: package-legitimacy check] |

**Packages removed due to [SLOP] verdict:** none.

**Packages flagged as suspicious [SUS]:** `@playwright/test`, `@axe-core/playwright`, and `axe-core` latest package checks were flagged for recency. Planner should not add an install/upgrade task for them; if a plan changes dependency versions anyway, add a human verification checkpoint first. [VERIFIED: package-legitimacy check]

**Postinstall audit:** `npm view <pkg>@<installed-version> scripts.postinstall` returned no postinstall scripts for `@playwright/test@1.59.1`, `@axe-core/playwright@4.11.3`, or `axe-core@4.11.4`. [VERIFIED: npm registry]

## Architecture Patterns

### System Architecture Diagram

```text
ComponentRegistry.entries/group_contracts
        |
        v
RegistryStory support layer
        |
        +--> generated component stories
        +--> generated group contract stories
        +--> curated wrappers for slots/overlays/design-lab exceptions
        |
        v
PhoenixStorybook backend + committed storybook.css/js
        |
        v
Browser guardrails
        +--> Storybook light/dark axe scans
        +--> Storybook theme asset/parity checks
        +--> Admin route page-flow axe/no-FOUC/reduced-motion checks
        +--> Phase 199 interaction regressions

Archived v1.53 baselines
        +--> baseline.cells.json
        +--> baseline.page-flow.cells.json
        |
        v
Phase 200 union baseline reducer
        |
        v
final.cells.json + scorecard.delta.json + regressions.ndjson + artifacts.manifest.json
        |
        v
deterministic verifiers
        |
        v
bounded four-lens judge
        |
        v
200-SIGN-OFF.md exact ACCEPT/REJECT + STATE/REQUIREMENTS reconciliation
```

### Recommended Project Structure

```text
accrue_admin/
├── storybook/
│   ├── _support/registry_story.ex              # Registry-driven story helpers and slugs
│   ├── components/                             # Generated/curated component story modules
│   └── groups/                                 # Registry-driven group contract stories
├── test/accrue_admin/dev/                      # Registry, group, Storybook asset/theming tests
├── e2e/
│   ├── admin-storybook-a11y-phase200.spec.js   # Storybook rendered axe coverage
│   ├── admin-theme-phase200.spec.js            # Theme persistence/no-FOUC additions
│   ├── phase200-scorecard.mjs                  # Union reducer/final artifact generation
│   └── phase200-storybook-coverage.mjs         # Optional route discovery/coverage report
└── scripts/ci/
    ├── verify_phase200_admin_guardrails.sh
    ├── verify_phase200_scorecard.mjs
    └── verify_phase200_signoff.mjs

.planning/phases/200-idempotent-verification-sign-off/
├── baseline.union.cells.json
├── final.cells.json
├── scorecard.delta.json
├── regressions.ndjson
├── artifacts.manifest.json
├── 200-SCORECARD.md
├── 200-STORYBOOK-COVERAGE.md
├── 200-VERIFICATION.md
└── 200-SIGN-OFF.md
```

### Pattern 1: Registry-Driven Story Completeness

**What:** Generate the minimum Storybook coverage from `ComponentRegistry.entries/0` and `ComponentRegistry.group_contracts/0`, with curated wrappers only for components that need named slots, templates, overlays, or richer composition. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

**When to use:** Every registry family and every group contract must be represented; completeness tests should derive expected families/groups dynamically. [VERIFIED: MIX_ENV=test registry inventory]

**Example:**

```elixir
# Source: PhoenixStorybook Variation docs + existing registry support.
# [CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Stories.Variation.html]
def variations_for(family) do
  family
  |> AccrueAdmin.Dev.ComponentRegistry.variants_for()
  |> Enum.flat_map(fn entry ->
    entry.examples
    |> Enum.with_index()
    |> Enum.map(fn {example, index} ->
      %PhoenixStorybook.Stories.Variation{
        id: stable_variation_id(entry.family, entry.variant, example, index),
        description: example.label || entry.label,
        note: example[:note],
        attributes: example.props || %{},
        slots: example.slots || []
      }
    end)
  end)
end

defp stable_variation_id(family, variant, example, index) do
  [family, variant, example[:state] || "default", index]
  |> Enum.join("-")
  |> String.downcase()
  |> String.replace(~r/[^a-z0-9]+/, "-")
  |> String.trim("-")
  |> String.to_atom()
end
```

### Pattern 2: PhoenixStorybook Theme Bridge

**What:** Enable PhoenixStorybook color mode and bridge the admin `ax-*` dark token scope into the Storybook sandbox with the existing dark shim. [VERIFIED: accrue_admin/lib/accrue_admin/dev/storybook.ex] [CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.html]

**When to use:** Storybook stories must render in both color modes against committed `storybook.css/js`, while production theme/no-FOUC tests still use cookie/localStorage/system emulation. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

**Example:**

```elixir
# Source: PhoenixStorybook backend configuration docs.
# [CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.html]
use PhoenixStorybook,
  otp_app: :accrue_admin,
  content_path: Path.expand("../../../../storybook", __DIR__),
  css_path: AccrueAdmin.Assets.hashed_path(:storybook_css, "/dev/storybook"),
  js_path: AccrueAdmin.Assets.hashed_path(:storybook_js, "/dev/storybook"),
  sandbox_class: "accrue-admin",
  color_mode: true,
  color_mode_sandbox_dark_class: "ax-theme-dark-shim"
```

### Pattern 3: Hybrid axe + Playwright Risk Matrix

**What:** Use axe for automated WCAG rule coverage and Playwright for behavioral checks axe cannot prove, such as focus restore, Escape/backdrop behavior, no-FOUC, reduced motion, and interaction evidence. [CITED: https://github.com/dequelabs/axe-core] [CITED: https://playwright.dev/docs/actionability]

**When to use:** All completed Storybook stories and required page-flow routes need light/dark axe coverage, while risky interactive surfaces need targeted Playwright traces. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

**Example:**

```javascript
// Source: Deque @axe-core/playwright README.
// [CITED: https://raw.githubusercontent.com/dequelabs/axe-core-npm/develop/packages/playwright/README.md]
import { AxeBuilder } from "@axe-core/playwright";

const results = await new AxeBuilder({ page })
  .withTags(["wcag2a", "wcag2aa"])
  .analyze();

expect(results.violations).toEqual([]);
```

### Pattern 4: Pure Forward-Only Scorecard Reducer

**What:** Treat scorecard generation as a deterministic JSON reduction: read archived immutable baselines, write Phase 200 derived artifacts, fail on duplicate keys, coverage downgrades, score downgrades, missing evidence, or non-empty regressions. [VERIFIED: accrue_admin/e2e/phase192-scorecard.mjs]

**When to use:** VER-01 must prove every comparable cell is greater than or equal to baseline, including inherited page-flow cells. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```javascript
// Source: verified baseline inspection and existing Phase 192 reducer pattern.
// [VERIFIED: node JSON inspection] [VERIFIED: accrue_admin/e2e/phase192-scorecard.mjs]
import fs from "node:fs";

const component = JSON.parse(fs.readFileSync(componentBaselinePath, "utf8"));
const pageFlow = JSON.parse(fs.readFileSync(pageFlowBaselinePath, "utf8"));
const union = [...component, ...pageFlow];
const ids = new Set(union.map((cell) => cell.id));

if (ids.size !== union.length) {
  throw new Error(`Duplicate baseline cell ids: ${union.length - ids.size}`);
}

fs.writeFileSync(phase200UnionPath, JSON.stringify(union, null, 2));
```

### Pattern 5: Bounded Judge and Exact Sign-Off

**What:** The judge reviews only correctness, accessibility, brand, and interaction evidence with severity labels; maintainer sign-off records the final ACCEPT/REJECT in a verifier-friendly line. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

**When to use:** After deterministic guardrails and scorecard artifacts are green, before updating final requirements/state. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

**Example:**

```markdown
| Lens | Finding | Severity | Evidence | Disposition |
|------|---------|----------|----------|-------------|
| accessibility | Drawer focus restores to trigger after Escape | PASS | artifacts/traces/drawer-focus.zip | Accepted |

Final maintainer decision: ACCEPT. Evidence source: 200-SCORECARD.md, 200-VERIFICATION.md, artifacts.manifest.json.
```

### Anti-Patterns to Avoid

- **Hardcoded registry counts:** The current 30 families, 42 entries, and 8 groups are a planning snapshot; tests must derive expected coverage from `ComponentRegistry`. [VERIFIED: MIX_ENV=test registry inventory]
- **Parallel Storybook metadata:** Do not duplicate family/state/group truth in story files when it can be read from the registry. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]
- **Replacing `/dev/components`:** The kitchen remains a second renderer and drift test surface for v1.54. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]
- **Direct `data-theme` as no-FOUC proof:** Direct forcing is acceptable for settled scans only; persistence/no-FOUC must use production cookie/localStorage/system paths. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]
- **Markdown-only evidence:** CI must verify structured JSON/NDJSON and exact sign-off status, not just prose. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser actionability and waiting | Custom sleeps, polling loops, or manual visibility checks | Playwright locators, assertions, and traces | Playwright auto-waits for visibility, stability, event reception, enabled state, and retries assertions. [CITED: https://playwright.dev/docs/actionability] |
| Accessibility rule engine | Custom contrast/name/role scanner | axe-core through `@axe-core/playwright` | axe already implements browser-based WCAG rule checks and exposes violations/incomplete results. [CITED: https://github.com/dequelabs/axe-core] |
| Storybook routing/assets/sandbox | Hand-built preview router | PhoenixStorybook `live_storybook`, `css_path`, `js_path`, `sandbox_class`, color mode config | Official backend handles LiveView Storybook content and asset routing for the Phoenix app. [CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html] |
| Registry catalog | Separate Storybook YAML/JSON catalog | `ComponentRegistry.entries/0`, `variants_for/1`, `group_contracts/0` | The registry is already the SSOT and is covered by drift tests. [VERIFIED: codebase grep] |
| Scorecard parsing | Regex over JSON/NDJSON text | Node JSON parser and structured validators | Phase 200 outputs are structured artifacts; reducers should fail on malformed data and duplicate IDs. [VERIFIED: accrue_admin/e2e/phase192-scorecard.mjs] |
| Theme persistence proof | Synthetic DOM attribute toggles | Production `accrue_theme` cookie/localStorage/system emulation in Playwright | The real no-FOUC risk is boot order and persistence, not whether CSS tokens can be manually forced. [VERIFIED: accrue_admin/assets/js/accrue_theme.js] |
| Visual regression platform | New SaaS/pixel-diff system | Deterministic Playwright, axe, scorecards, traces, and maintainer checkpoint | Pixel-diff is explicitly deferred from Phase 200. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |

**Key insight:** Phase 200 is mostly evidence plumbing over existing primitives. Custom replacements for Storybook, axe, Playwright, or the registry add drift and new failure modes at the exact phase where the project needs stable proof. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating the Scout Counts as Fixed Requirements

**What goes wrong:** Tests expect exactly 30 families, 42 entries, and 8 groups, then fail or miss coverage when the registry changes. [VERIFIED: MIX_ENV=test registry inventory]

**Why it happens:** Planning snapshots get copied into assertions.

**How to avoid:** Assert equality between runtime registry-derived expected IDs and runtime discovered Storybook story IDs.

**Warning signs:** Test fixtures contain literal component family arrays or stale references to the older 21-family Phase 192 baseline manifest. [VERIFIED: accrue_admin/e2e/baseline-manifest.js]

### Pitfall 2: Storybook Dark Mode Toggle Does Not Affect the Admin Token Scope

**What goes wrong:** Stories appear covered, but dark-mode tokens do not match `html.accrue-admin[data-theme]` behavior. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

**Why it happens:** Current Storybook backend has `color_mode_sandbox_dark_class` but does not yet explicitly set `color_mode: true`. [VERIFIED: accrue_admin/lib/accrue_admin/dev/storybook.ex]

**How to avoid:** Enable PhoenixStorybook color mode, keep the dark shim, and add a rendered parity check for representative `ax-*` tokens.

**Warning signs:** Storybook tests pass in light mode but dark-mode screenshots or computed styles are identical.

### Pitfall 3: Breaking the Kitchen While Adding Storybook

**What goes wrong:** Storybook becomes green while `/dev/components` or Phase 189/190 drift tests fail. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

**Why it happens:** Registry examples are refactored for Storybook without preserving kitchen expectations.

**How to avoid:** Run registry/group tests and kitchen drift tests in the same deterministic guardrail script as Storybook coverage.

**Warning signs:** Storybook-only helpers mutate registry shape or require Storybook-only metadata in production component examples.

### Pitfall 4: Reusing Phase 192 Paths

**What goes wrong:** Phase 200 writes new artifacts into archived Phase 192 directories or reads old active paths that no longer exist. [VERIFIED: codebase grep] [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

**Why it happens:** Existing scorecard/signoff scripts hardcode Phase 192 and old baseline path assumptions.

**How to avoid:** Parameterize scripts or create Phase 200-specific copies with explicit paths from D-13 and D-16.

**Warning signs:** Any new script path contains `192-idempotent-verification-sign-off` or `.planning/phases/187-audit-baseline`.

### Pitfall 5: Treating `p193` Pending Rows as Comparable Success

**What goes wrong:** Page-flow baseline rows are carried forward without deterministic final evidence. [VERIFIED: node JSON inspection]

**Why it happens:** The union exists, but page-flow baseline rows are currently pending placeholders.

**How to avoid:** Require `coverage_status: "covered"`, deterministic evidence refs, and final score floor for every `p193` row.

**Warning signs:** Final cells still contain `coverage_status: "pending"` or missing evidence refs.

### Pitfall 6: axe-Only Accessibility Sign-Off

**What goes wrong:** Color/name/role checks pass but focus trap, Escape, restore, keyboard path, reduced motion, or text reflow regressions remain. [CITED: https://github.com/dequelabs/axe-core]

**Why it happens:** axe documents that automated checks cover only a portion of WCAG issues and can return incomplete results requiring manual review. [CITED: https://github.com/dequelabs/axe-core]

**How to avoid:** Pair axe with targeted Playwright interaction assertions and maintainer review.

**Warning signs:** `200-VERIFICATION.md` lists only axe output for VER-02.

### Pitfall 7: Broad Browser Gates in Every CI Run

**What goes wrong:** CI becomes slow or flaky, and Phase 200 repairs become hard to land.

**Why it happens:** Exhaustive Cartesian route x viewport x theme x state coverage is attempted per PR.

**How to avoid:** Keep CI deterministic and risk-based: all stories/routes for axe light/dark, targeted interaction tests, single worker for stateful tests, full scorecard at final closeout. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

**Warning signs:** CI script calls only broad `npm run e2e` instead of named guardrails.

### Pitfall 8: Unverifiable Human Sign-Off

**What goes wrong:** The maintainer accepts in prose, but CI cannot tell whether the final decision is ACCEPT, REJECT, or stale.

**Why it happens:** Markdown lacks exact final-line and manifest checks.

**How to avoid:** Verify `200-SIGN-OFF.md` final decision line, required artifact list, and absence of unresolved blocker statuses.

**Warning signs:** `human_needed`, `pending`, or missing artifact names remain in final planning docs.

## Code Examples

Verified patterns from official sources and local code:

### Storybook Backend Color Mode

```elixir
# Source: PhoenixStorybook backend options.
# [CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.html]
defmodule AccrueAdmin.Dev.Storybook do
  use PhoenixStorybook,
    otp_app: :accrue_admin,
    content_path: Path.expand("../../../../storybook", __DIR__),
    css_path: AccrueAdmin.Assets.hashed_path(:storybook_css, "/dev/storybook"),
    js_path: AccrueAdmin.Assets.hashed_path(:storybook_js, "/dev/storybook"),
    sandbox_class: "accrue-admin",
    color_mode: true,
    color_mode_sandbox_dark_class: "ax-theme-dark-shim"
end
```

### Dynamic Registry Completeness Test

```elixir
# Source: existing ComponentRegistry tests and Phase 200 context.
# [VERIFIED: codebase grep]
test "storybook covers every registered family" do
  expected =
    AccrueAdmin.Dev.ComponentRegistry.entries()
    |> Enum.map(& &1.family)
    |> Enum.uniq()
    |> MapSet.new()

  actual =
    AccrueAdmin.Dev.StorybookCoverage.story_families()
    |> MapSet.new()

  assert MapSet.difference(expected, actual) == MapSet.new()
end
```

### Storybook axe Scan

```javascript
// Source: Deque @axe-core/playwright README and existing admin-a11y suite.
// [CITED: https://raw.githubusercontent.com/dequelabs/axe-core-npm/develop/packages/playwright/README.md]
// [VERIFIED: accrue_admin/e2e/admin-a11y.spec.js]
for (const storyUrl of storyUrls) {
  for (const theme of ["light", "dark"]) {
    await page.goto(storyUrl);
    await setSettledThemeForScan(page, theme);

    const results = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa"])
      .analyze();

    expect(results.violations, `${storyUrl} ${theme}`).toEqual([]);
  }
}
```

### Forward-Only Regression Check

```javascript
// Source: existing Phase 192 scorecard pattern.
// [VERIFIED: accrue_admin/e2e/phase192-scorecard.mjs]
for (const baselineCell of baselineCells) {
  const finalCell = finalById.get(baselineCell.id);

  if (!finalCell) {
    regressions.push({ id: baselineCell.id, reason: "missing_final_cell" });
    continue;
  }

  if (finalCell.coverage_status !== "covered") {
    regressions.push({ id: baselineCell.id, reason: "coverage_not_covered" });
  }

  if (Number(finalCell.score) < Number(baselineCell.score)) {
    regressions.push({
      id: baselineCell.id,
      reason: "score_regression",
      baseline_score: baselineCell.score,
      final_score: finalCell.score
    });
  }
}
```

### Exact Sign-Off Verifier

```javascript
// Source: Phase 200 sign-off constraints and existing Phase 192 verifier pattern.
// [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]
const signoff = fs.readFileSync(signoffPath, "utf8");
const finalLine = signoff
  .trim()
  .split(/\r?\n/)
  .find((line) => line.startsWith("Final maintainer decision: "));

if (!finalLine || !/^Final maintainer decision: (ACCEPT|REJECT)\b/.test(finalLine)) {
  throw new Error("Missing verifier-friendly final maintainer decision line");
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Kitchen-only component proof | Kitchen remains plus PhoenixStorybook registry-driven coverage | v1.54 Phase 200 scope | Adds documentation/verification surface without replacing SSOT kitchen checks. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |
| Component-only baseline scorecard | Union of component/group and page-flow cells | Phase 200 | VER-01 now requires 30,348 inherited rows, including `p193` page-flow closure. [VERIFIED: node JSON inspection] |
| Route-only axe scans | Route plus completed Storybook story scans in light/dark | Phase 200 | STY-03 and VER-02 require Storybook rendered a11y/theme proof. [VERIFIED: .planning/REQUIREMENTS.md] |
| Direct token inspection for motion | Behavioral reduced-motion proof | Phase 199/200 | Tests must prove actual duration/travel/focus/overlay behavior. [VERIFIED: accrue_admin/e2e/reduced-motion.spec.js] |
| Human/model gates per task | Deterministic CI per task, judge/maintainer at final closeout | Phase 200 | Keeps CI repeatable while preserving final adversarial review. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |

**Deprecated/outdated:**

- Hardcoded Phase 192 output paths in scorecard/signoff scripts are unsuitable for Phase 200 outputs and archived baselines. [VERIFIED: codebase grep]
- The older 21-family baseline manifest is not a complete Storybook target because the current registry inventory has 30 unique families. [VERIFIED: accrue_admin/e2e/baseline-manifest.js] [VERIFIED: MIX_ENV=test registry inventory]
- Treating Storybook as a replacement for `/dev/components` conflicts with the locked Phase 200 decision to keep both surfaces. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact Storybook story URL discovery should be implemented from the mounted app or PhoenixStorybook route output rather than hardcoded from undocumented internals. [ASSUMED] | Architecture Patterns / Validation Architecture | A hardcoded route format could break if PhoenixStorybook changes route naming; planner should include a discovery/smoke task before final story scans. |

## Open Questions (RESOLVED)

1. **Should Phase 200 parameterize Phase 192 verifier scripts or copy them into Phase 200-specific files?**
   - What we know: Existing Phase 192 scripts contain useful reducer/verifier logic but hardcode archived and outdated paths. [VERIFIED: codebase grep]
   - What's unclear: Whether maintainers prefer shared parameterized scripts or one-off closeout scripts for audit readability.
   - Recommendation: Use Phase 200-specific entrypoints and factor only small pure helpers if that reduces duplication without obscuring artifact paths.
   - Resolution: Use Phase 200-specific entrypoints/scripts and factor only small pure helpers when useful; all generated outputs land under `.planning/phases/200-idempotent-verification-sign-off/` or approved `accrue_admin/test-results/phase200/` evidence roots.

2. **How should Storybook story URLs be discovered for scans?**
   - What we know: PhoenixStorybook is mounted at `/dev/storybook`, and existing story modules live under `accrue_admin/storybook`. [VERIFIED: accrue_admin/lib/accrue_admin_web/router.ex] [VERIFIED: filesystem inspection]
   - What's unclear: The most stable route enumeration API for the installed PhoenixStorybook version.
   - Recommendation: Add a Wave 0 Storybook smoke/discovery task that boots the app, enumerates rendered story links from `/dev/storybook`, and stores the resulting story URL list as a Phase 200 evidence input.
   - Resolution: Discover Storybook URLs from the mounted `/dev/storybook` page at runtime using `accrue_admin/e2e/phase200-storybook-helpers.js` / `discoverStorybookStoryUrls`, not hardcoded PhoenixStorybook internals.

3. **What exact artifact names should the multi-lens judge reference?**
   - What we know: The required top-level Phase 200 artifact names are locked. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]
   - What's unclear: Whether traces/screenshots should live directly under the phase directory or under a nested `artifacts/` folder.
   - Recommendation: Put large interaction evidence under `.planning/phases/200-idempotent-verification-sign-off/artifacts/` and reference it from `artifacts.manifest.json`.
   - Resolution: Store large interaction evidence under `.planning/phases/200-idempotent-verification-sign-off/artifacts/` and reference all evidence through `.planning/phases/200-idempotent-verification-sign-off/artifacts.manifest.json`; `200-JUDGE.md` and `200-SIGN-OFF.md` reference that manifest and the structured scorecard artifacts.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | Phoenix tests, Storybook backend, ExUnit guardrails | yes | Elixir 1.19.5 / Mix 1.19.5 | none needed. [VERIFIED: local environment probe] |
| Erlang/OTP | Phoenix runtime | yes | OTP 28 | none needed. [VERIFIED: local environment probe] |
| Node.js | Playwright, scorecard/verifier scripts | yes | v22.14.0 | none needed. [VERIFIED: local environment probe] |
| npm | JS dependency install/scripts | yes | 11.1.0 | none needed. [VERIFIED: local environment probe] |
| Playwright CLI | Browser guardrails | yes | 1.59.1 package-local | Use `cd accrue_admin && npx playwright ...`. [VERIFIED: local environment probe] |
| Playwright-managed Chromium | Browser execution | yes | Chromium cache revision 1217 available | Use managed browser; system `chromium` is broken locally. [VERIFIED: local environment probe] |
| PostgreSQL | Phoenix E2E server data | yes | Local server accepting; `psql` 14.17 | none needed. [VERIFIED: local environment probe] |
| Docker | Optional local service/container workflows | yes | 29.5.2 | Not required for Phase 200 guardrails. [VERIFIED: local environment probe] |
| System `chromium` command | Not required | no | broken symlink / exits 126 | Playwright-managed Chromium. [VERIFIED: local environment probe] |

**Missing dependencies with no fallback:**

- None found for the recommended Phase 200 plan. [VERIFIED: local environment probe]

**Missing dependencies with fallback:**

- System `chromium` command is broken locally; use Playwright-managed Chromium via `npx playwright`. [VERIFIED: local environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit/Mix 1.19.5 for Phoenix tests; Playwright 1.59.1 for browser tests; Node.js 22.14.0 for artifact verifiers. [VERIFIED: local environment probe] |
| Config file | `accrue_admin/playwright.config.js`; Phoenix test config under `accrue_admin/config/test.exs`; package scripts in `accrue_admin/package.json`. [VERIFIED: filesystem inspection] |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/component_group_registry_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `cd accrue_admin && bash scripts/ci/verify_phase200_admin_guardrails.sh` after Wave 0 creates it. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| VER-01 | Union baseline parse, duplicate check, final cell coverage, score >= baseline, empty regressions | unit/integration artifact verifier | `cd accrue_admin && node scripts/ci/verify_phase200_scorecard.mjs` | no - Wave 0 should create. [VERIFIED: codebase grep] |
| VER-02 | axe color/name/role over stories and page-flow routes; no-FOUC/persistence/system emulation; reduced motion; group contracts | browser/e2e + ExUnit | `cd accrue_admin && bash scripts/ci/verify_phase200_admin_guardrails.sh` | partial - existing route axe, reduced-motion, group-contract, Phase 199 suites exist; Storybook/page-flow additions missing. [VERIFIED: codebase grep] |
| VER-03 | Four-lens judge and final maintainer ACCEPT/REJECT verified | artifact verifier + manual checkpoint | `cd accrue_admin && node scripts/ci/verify_phase200_signoff.mjs` | no - Wave 0 should create. [VERIFIED: codebase grep] |
| STY-02 | Every registry family and group has Storybook coverage; registry/kitchen drift remains green | ExUnit + Storybook smoke | `cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/component_group_registry_test.exs` plus new Storybook completeness test | partial - registry/group tests exist; Storybook completeness test missing. [VERIFIED: codebase grep] |
| STY-03 | Storybook stories render in light/dark with committed assets and dark shim parity | browser/e2e + asset tests | `cd accrue_admin && env -u NO_COLOR npx playwright test e2e/admin-storybook-a11y-phase200.spec.js --workers=1` | no - Wave 0 should create. [VERIFIED: filesystem inspection] |

### Sampling Rate

- **Per task commit:** run focused ExUnit or Playwright file touched by the task, using package-local Playwright and one worker for stateful browser checks. [VERIFIED: playwright.config.js]
- **Per wave merge:** run Phase 200 guardrail script subset for the wave plus existing registry/group/reduced-motion/Phase 199 suites. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]
- **Phase gate:** run full deterministic Phase 200 guardrails, regenerate scorecard artifacts, run judge, then verify `200-SIGN-OFF.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md`. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md]

### Wave 0 Gaps

- [ ] `accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs` - covers STY-02 dynamic family/group story completeness.
- [ ] `accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs` or extension to `assets_test.exs` - covers STY-03 committed `storybook.css/js` asset routing.
- [ ] `accrue_admin/e2e/admin-storybook-a11y-phase200.spec.js` - covers STY-03 and VER-02 rendered story axe/theming scans.
- [ ] `accrue_admin/e2e/admin-page-flow-phase200.spec.js` - covers VER-01/VER-02 page-flow final evidence and a11y.
- [ ] `accrue_admin/e2e/phase200-scorecard.mjs` - generates Phase 200 union/final/delta/regressions artifacts.
- [ ] `accrue_admin/scripts/ci/verify_phase200_scorecard.mjs` - deterministic VER-01 verifier.
- [ ] `accrue_admin/scripts/ci/verify_phase200_signoff.mjs` - deterministic VER-03 final status verifier.
- [ ] `accrue_admin/scripts/ci/verify_phase200_admin_guardrails.sh` - deterministic CI orchestration for VER-02/STY-02/STY-03.
- [ ] `.github/workflows/*` update - call deterministic Phase 200 guardrails without model/human gates.

## Security Domain

### Applicable ASVS Categories

OWASP ASVS 5.0.0 is the current stable ASVS release as of 2026-06-30, and it is intended as a basis for testing web application technical security controls. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Do not change auth behavior; verify Storybook remains dev/test-only and unavailable from host/adopter runtime surfaces. [VERIFIED: accrue_admin/mix.exs] [VERIFIED: accrue_admin/lib/accrue_admin_web/router.ex] |
| V3 Session Management | yes | Keep existing Phoenix session/CSRF behavior; theme persistence tests may use `accrue_theme` cookie/localStorage but must not weaken auth/session controls. [VERIFIED: accrue_admin/assets/js/accrue_theme.js] |
| V4 Access Control | yes | Ensure `/dev/storybook` and Storybook assets are only exposed in intended admin dev/test surface, not production host/adopter routes. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |
| V5 Input Validation | yes | Parse JSON/NDJSON artifacts structurally; reject missing IDs, duplicate IDs, path traversal refs, malformed theme values, and stale status fields. [VERIFIED: accrue_admin/e2e/phase192-scorecard.mjs] |
| V6 Cryptography | no new cryptography | Use standard hash utilities only for artifact integrity if needed; do not introduce custom crypto. [ASSUMED] |

### Known Threat Patterns for PhoenixStorybook / Playwright Verification

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dev/test Storybook route exposed outside intended admin surface | Information Disclosure | Keep `phoenix_storybook` dev/test-only and add host/adopter leak tests for `/dev/storybook`. [VERIFIED: accrue_admin/mix.exs] |
| Artifact path traversal in manifests/evidence refs | Tampering / Information Disclosure | Require repo-relative paths under the Phase 200 directory or approved test output dirs; reject absolute paths and `..` segments. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |
| Stale `human_needed`, `pending`, or missing-artifact state represented as ACCEPT | Repudiation / Process Integrity | Verify exact final decision line, required artifact list, and requirements/state reconciliation. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |
| Direct theme forcing used as persistence proof | Spoofing / Process Integrity | Label direct `data-theme` scans as settled visual/axe checks; require cookie/localStorage/system emulation for no-FOUC proof. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] |
| Story templates rendering unsafe raw content | XSS | Keep Storybook examples static/registry-controlled and avoid user-supplied raw HTML in generated templates. [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md` - locked Phase 200 decisions, scope, artifact names, guardrails, sign-off semantics. [VERIFIED: filesystem]
- `.planning/REQUIREMENTS.md` - VER-01, VER-02, VER-03, STY-02, STY-03 ownership and v1.54 scope. [VERIFIED: filesystem]
- `.planning/STATE.md` - current phase state and Phase 199 completion context. [VERIFIED: filesystem]
- `CLAUDE.md` - project constraints and monorepo/admin UI conventions. [VERIFIED: filesystem]
- `accrue_admin/mix.exs`, `mix.lock`, `mix deps`, `mix hex.info phoenix_storybook` - PhoenixStorybook and LiveView stack. [VERIFIED: mix deps]
- `accrue_admin/package.json`, `package-lock.json`, `npm view` - Playwright/axe installed versions and metadata. [VERIFIED: npm registry]
- `accrue_admin/playwright.config.js` and `accrue_admin/e2e/*.spec.js` - existing Playwright/a11y/reduced-motion/Phase 199 guardrail patterns. [VERIFIED: codebase grep]
- `.planning/milestones/v1.53-phases/187-audit-baseline/*.json` - union baseline counts and duplicate check. [VERIFIED: node JSON inspection]
- `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/*` - prior scorecard/signoff artifact shape. [VERIFIED: filesystem]

### Secondary (MEDIUM confidence)

- PhoenixStorybook HexDocs - backend configuration, color mode, assets, router, and Variation fields. [CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.html] [CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html] [CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Stories.Variation.html]
- Playwright official docs - actionability, auto-waiting, assertions, and test configuration. [CITED: https://playwright.dev/docs/actionability] [CITED: https://playwright.dev/docs/test-configuration]
- Deque `@axe-core/playwright` README and axe-core README - Playwright integration and automated accessibility limits. [CITED: https://raw.githubusercontent.com/dequelabs/axe-core-npm/develop/packages/playwright/README.md] [CITED: https://github.com/dequelabs/axe-core]
- OWASP ASVS project page - ASVS current stable release and security verification scope. [CITED: https://owasp.org/www-project-application-security-verification-standard/]
- W3C WCAG non-text contrast understanding - UI component/focus indicator contrast expectations. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html]

### Tertiary (LOW confidence)

- Exact Storybook story URL discovery strategy before implementation is marked as an assumption because route enumeration should be confirmed against the running mounted PhoenixStorybook instance. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - verified from local dependency files, `mix deps`, `mix hex.info`, npm registry, and lockfiles. [VERIFIED: mix deps] [VERIFIED: npm registry]
- Architecture: HIGH - driven by locked Phase 200 context plus existing registry, Storybook, Playwright, and Phase 192/199 code paths. [VERIFIED: codebase grep]
- Pitfalls: HIGH - derived from explicit Phase 200 decisions and inspected existing hardcoded Phase 192 paths, registry inventory, and browser suites. [VERIFIED: .planning/phases/200-idempotent-verification-sign-off/200-CONTEXT.md] [VERIFIED: codebase grep]
- External documentation: MEDIUM - official docs were fetched directly, but Context7 MCP was unavailable in this runtime and the research seam fetches were cached from official web sources instead. [CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.html]

**Research date:** 2026-06-30

**Valid until:** 2026-07-07 for npm/package version freshness; 2026-07-30 for architecture and project-context guidance unless Phase 200 context changes.
