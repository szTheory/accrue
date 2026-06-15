---
phase: 188
slug: foundations-hardening
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-15
---

# Phase 188 Validation Strategy

## Scope

Phase 188 validates design-system foundations, not per-page visual polish. The
verification suite must prove that typography roles, measure application,
semantic layers, Tailwind source-of-truth resolution, semantic state roles, and
motion-token coverage are enforced at the root and remain hard to regress.

## Test Infrastructure

| Layer | Tooling | Purpose |
| --- | --- | --- |
| Source/docs guards | `scripts/ci/verify_package_docs.sh` | Fast static enforcement for Tailwind SSOT, raw type declarations, z-index literals, semantic token presence, and motion policy. |
| Unit/regression tests | ExUnit | Asset task arguments, verifier negative fixtures, token inventory, component registry entries. |
| Browser verification | Playwright + axe | Computed style checks for tokens and interaction states; existing light/dark accessibility sweep; reduced-motion behavior. |
| Manual review | Component kitchen | Maintainer inspection of foundation specimens in light and dark modes. |

Primary config and entry points:

- `scripts/ci/verify_package_docs.sh`
- `accrue/test/accrue/docs/package_docs_verifier_test.exs`
- `accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs`
- `accrue_admin/test/test_helper.exs`
- `accrue_admin/playwright.config.js`
- `accrue_admin/e2e/admin-a11y.spec.js`
- `accrue_admin/e2e/reduced-motion.spec.js`
- `accrue_admin/e2e/kitchen-banner.spec.js`

## Verification Commands

Quick task-scoped verification after implementation:

```bash
bash scripts/ci/verify_package_docs.sh
cd accrue_admin
mix test --warnings-as-errors test/mix/tasks/accrue_admin_assets_build_test.exs
```

Expanded phase verification after all implementation slices:

```bash
bash scripts/ci/verify_package_docs.sh
cd accrue_admin
mix test --warnings-as-errors
npm run e2e -- e2e/reduced-motion.spec.js e2e/admin-a11y.spec.js e2e/kitchen-banner.spec.js
```

If a new component-kitchen computed-style spec is added, include it in the
expanded Playwright command alongside the existing reduced-motion, a11y, and
kitchen specs.

## Per-Task Validation Map

| Planned task area | Requirements | Automated validation | Manual validation |
| --- | --- | --- | --- |
| Typography role tokens and utilities | FND-01 | Source guard confirms required `--ax-type-{role}-font`, `--ax-type-{role}-tracking`, and `.ax-type-{role}` entries; raw type declaration guard catches non-allowlisted regressions. | Component kitchen type specimen is readable and role names are understandable. |
| Semantic class migration to type roles | FND-01 | Static guard confirms raw `font-size`, `line-height`, `letter-spacing`, `font-weight`, and `font-family` are absent outside allowlisted zones. | Spot-check dense admin surfaces in the kitchen or dev pages for unchanged hierarchy. |
| Reading-measure application | FND-03 | Playwright computed-style checks confirm prose/help/error/empty/description specimens resolve `max-width` through `--ax-measure`. | Confirm copy wraps comfortably without truncating data-grid content. |
| Layer token replacement | FND-02 | Source guard confirms exact `--ax-z-*` token inventory and rejects overlay `z-index` literals except documented micro-stack `-1`, `0`, `1` cases. | Open representative dropdown/drawer/modal surfaces and confirm stacking is coherent. |
| Tailwind SSOT deletion | FND-04 | Verifier confirms config/preset files are absent, `--config` is absent from the Mix task, package CSS has no `@tailwind`/`@apply`, and docs do not invite utility authoring. | Confirm docs describe `theme.css`, `app.css`, `--ax-*`, and `ax-*` as the authoring contract. |
| Asset build task update | FND-04 | `accrue_admin_assets_build_test.exs` asserts input/output arguments remain and `--config` is absent. | None expected. |
| Semantic state role tokens | FND-05 | Source guard confirms required focus, scrollbar, disabled, readonly, interactive, and status tokens exist in light, dark, and system-dark scopes. | Component kitchen state specimens are visible and legible in light and dark modes. |
| Focus-visible standardization | FND-05 | Playwright computed-style checks confirm focusable specimens have visible outline/offset/halo values derived from tokens. Axe sweep remains clean. | Keyboard through kitchen specimens and confirm focus is obvious. |
| Disabled and readonly behavior | FND-05 | Playwright checks confirm disabled/readonly specimens resolve tokenized styles; source review or tests verify custom `aria-disabled` controls remove activation where applicable. | Verify disabled controls do not look clickable or respond like enabled controls. |
| Scrollbar role completion | FND-05 | Source guard confirms `color-scheme`, `scrollbar-color`, WebKit fallback selectors, and `--ax-scrollbar-*` token consumption. Browser check verifies computed support where available. | Inspect scrollable kitchen specimen in light and dark modes. |
| Motion gap closure | FND-06 | Existing verifier guards for raw duration/easing, `transition: all`, layout-property transitions, and reduced-motion policy remain passing. Existing Playwright reduced-motion spec remains passing. | Confirm reduced-motion behavior is still useful, not frozen. |
| Foundation kitchen specimens | FND-01..FND-06 | ExUnit registry test and Playwright computed-style spec cover new specimen availability and token resolution. | Maintainer reviews the foundation specimen page as the phase sign-off surface. |

## Static Guard Details

The package docs verifier should extend the existing negative-fixture pattern.
For every new rule, add a failing fixture in
`accrue/test/accrue/docs/package_docs_verifier_test.exs` so the guard is tested
as behavior, not only as script text.

Required guard categories:

- Tailwind config/preset files stay absent.
- Tailwind CLI invocation omits `--config`.
- Package CSS contains no `@tailwind` or `@apply`.
- Package docs do not recommend Tailwind utilities or host Tailwind config for
  AccrueAdmin styling.
- HEEx does not grow obvious Tailwind utility authoring outside intentional
  `ax-*` package classes.
- Overlay/sticky z-index values consume layer tokens instead of literals.
- Raw type properties are absent outside documented allowlist zones.
- Required semantic role tokens exist in root, dark, and system-dark scopes.
- Existing motion literal and easing guards continue to run.

## Manual Review Checklist

Manual review is required only for the component-kitchen foundation specimens:

- Type roles preserve a clear hierarchy and do not look like isolated utility
  samples.
- Prose and help text respect readable measure.
- Dropdown, drawer, modal, sticky, and toast specimens stack in the expected
  order where represented.
- Focus rings are visible with keyboard navigation in light and dark modes.
- Disabled and readonly controls read as unavailable without looking broken.
- Scrollbar and status colors remain legible in light, dark, and system-dark
  themes.
- Reduced-motion mode collapses travel/overshoot while preserving useful opacity
  feedback.

## Threat Model

| Threat | Risk | Mitigation |
| --- | --- | --- |
| Spoofing | Disabled or readonly controls may still appear active. | Tokenized disabled/readonly styles plus behavior checks for custom `aria-disabled` controls. |
| Tampering | Host or stale Tailwind config could reintroduce a second styling source. | Delete config/preset files and guard their absence plus `--config` removal. |
| Repudiation | Styling regressions may be hard to attribute. | Verifier failures should print exact file/rule context; negative fixtures lock rule behavior. |
| Information disclosure | No new user-data surfaces are expected. | Keep work to CSS/docs/tests/component kitchen. |
| Denial of service | Asset build changes could break package CSS generation. | Asset build task tests and committed bundle verification. |
| Elevation of privilege | Custom disabled controls could still trigger protected actions. | Verify `aria-disabled` controls remove activation and affordance, or use native `disabled` where possible. |

## Exit Criteria

Phase 188 execution can be accepted when:

- All FND-01 through FND-06 requirements have automated coverage.
- `scripts/ci/verify_package_docs.sh` passes with new guard categories.
- Task-scoped ExUnit tests pass.
- Playwright reduced-motion, a11y, and component-kitchen computed-style checks
  pass.
- Manual component-kitchen review is recorded with light and dark mode notes.
- No new Tailwind authoring path, motion token family, page-flow rewrite, or
  broad overlay portal architecture was introduced.
