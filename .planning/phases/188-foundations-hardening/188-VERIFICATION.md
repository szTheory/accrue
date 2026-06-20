---
phase: 188-foundations-hardening
verified: 2026-06-20T12:14:21Z
status: gaps_found
score: 6/11 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "A maintainer can run the Phase 188 full automated gate successfully."
    status: failed
    reason: "`bash scripts/ci/verify_package_docs.sh` exits nonzero on the current codebase before reaching the Phase 188 foundation checks because `accrue_admin/assets/css/app.css` contains a bare breakpoint media query."
    artifacts:
      - path: "scripts/ci/verify_package_docs.sh"
        issue: "Phase 188 Plan 07 requires this command to pass as the first full-gate command."
      - path: "accrue_admin/assets/css/app.css"
        issue: "Line 2309 has `@media (max-width: 599.98px)` without an `--ax-bp-*` annotation, tripping the shared verifier."
    missing:
      - "Annotate or refactor the bare breakpoint so `bash scripts/ci/verify_package_docs.sh` exits 0 again."
  - truth: "Phase 188 package-doc verifier negative fixtures pass and prove the foundation guards."
    status: failed
    reason: "`cd accrue && mix test --warnings-as-errors test/accrue/docs/package_docs_verifier_test.exs` fails 16/25 because the bare-breakpoint failure masks the intended negative-fixture failure messages."
    artifacts:
      - path: "accrue/test/accrue/docs/package_docs_verifier_test.exs"
        issue: "Expected failure text for Tailwind, z-index, raw type, motion, semantic role, and CMP-05 fixtures is preempted by the DSY-01 breakpoint failure."
      - path: "scripts/ci/verify_package_docs.sh"
        issue: "The verifier currently cannot reach and prove many Phase 188 guard categories in fixture runs."
    missing:
      - "Restore package-doc verifier success on the seeded fixture baseline so Phase 188 negative fixtures test their intended rules."
  - truth: "Every overlay and sticky element references the formal layer system, with no undocumented ad-hoc z-index literals."
    status: partial
    reason: "The semantic layer scale exists and primary consumers use `--ax-z-*`, but overlay internals still contain literal `z-index: 0` and `z-index: 1` without the planned `ax-z-micro-stack` documentation or local isolation pairing."
    artifacts:
      - path: "accrue_admin/assets/css/app.css"
        issue: "Lines 1168, 1176, 1242, and 1249 use local z-index literals in drawer/modal internals."
      - path: "scripts/ci/verify_package_docs.sh"
        issue: "The z-index guard allows -1/0/1 unconditionally and does not enforce the plan's micro-stack comment/isolation constraint."
    missing:
      - "Either route these local stack values through tokens or document them as isolated micro-stacks with `ax-z-micro-stack` and matching isolation."
      - "Tighten the verifier so allowed micro-stacking literals cannot silently drift."
  - truth: "Static guards enforce Tailwind SSOT and reject obvious Tailwind utility authoring in `accrue_admin/lib`."
    status: partial
    reason: "The current guard scans only literal `class=\"...\"` attributes inside `~H` templates. It misses dynamic class expressions, and the current codebase contains `class={if @loading, do: \"ax-spinner\", else: \"hidden\"}`."
    artifacts:
      - path: "scripts/ci/verify_package_docs.sh"
        issue: "Lines 344-360 inspect only literal class attributes, not `class={...}` expressions."
      - path: "accrue_admin/lib/accrue_admin/components/global_search.ex"
        issue: "Line 167 uses a dynamic non-`ax-*` utility-like class expression that the guard does not inspect."
    missing:
      - "Extend the HEEx utility guard to parse `class={...}` expressions or replace the dynamic non-`ax-*` class with a root-approved `ax-*` class/attribute pattern."
  - truth: "The full `accrue_admin` test suite passes as part of the Phase 188 final gate."
    status: failed
    reason: "`cd accrue_admin && mix test --warnings-as-errors` currently fails 6 tests. The failures observed are outside the foundation token files, but Plan 07 made the full suite a Phase 188 acceptance gate."
    artifacts:
      - path: "accrue_admin/test/accrue_admin/live/subscription_live_test.exs"
        issue: "At least two visible failures assert provider-honest confirmation copy that is absent from rendered HTML."
    missing:
      - "Restore the current full `accrue_admin` suite or update the Plan 07 gate evidence after unrelated test failures are resolved."
human_verification_notes:
  - "188-07-SUMMARY.md records `human_review: approved`, but this verifier did not independently reproduce the maintainer visual review."
---

# Phase 188: Foundations Hardening Verification Report

**Phase Goal:** Fix AccrueAdmin design-system roots for composed typography, reading measure, semantic layers, motion-token coverage, Tailwind SSOT, and light/dark semantic role correctness. Root-level fixes only.
**Verified:** 2026-06-20T12:14:21Z
**Status:** gaps_found
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | FND-01 composed typography bundles exist and are consumed | VERIFIED | `theme.css` defines all 13 `--ax-type-{role}-font` and `--ax-type-{role}-tracking` tokens; `app.css` defines `.ax-type-*` consumers. |
| 2 | FND-02 semantic layer scale exists and overlay/sticky consumers use it | PARTIAL | `theme.css` has base/sticky/dropdown/popover/drawer/modal/toast tokens and many consumers use `var(--ax-z-*)`; drawer/modal internals still use undocumented `z-index: 0/1` literals. |
| 3 | FND-03 reading measure is applied to prose/dense narrative surfaces without blanket table caps | VERIFIED | `.ax-measure` and prose/narrative selectors use `max-width: var(--ax-measure)`; grep found no measure cap on generic `table`, `td`, `th`, `.ax-data-table`, or `.ax-data-table-shell`. |
| 4 | FND-04 inert Tailwind config is resolved into one styling SSOT | VERIFIED | `tailwind.config.js` and `tailwind_preset.js` are absent; asset task keeps `tailwindcss@3.4.17` and no `--config`; docs name `theme.css`/`app.css` and reject Tailwind utility authoring. |
| 5 | FND-05 semantic roles exist and pass source contrast in light/dark/system-dark | VERIFIED | `theme.css` defines required focus, scrollbar, disabled, readonly, interactive, and status roles in repeated scopes; `node scripts/ci/verify_foundation_contrast.mjs` passed. |
| 6 | FND-06 motion coverage uses existing tokens and reduced motion collapses travel/overshoot | VERIFIED | `theme.css` retains `--ax-dur-*`, `--ax-ease-*`, `--ax-rise-*`, `--ax-press-scale`, and reduced-motion overrides; `app.css` routes key transitions through token bundles with skeleton shimmer as the explicit raw timing exception. |
| 7 | Foundation kitchen exposes maintainer specimens | VERIFIED | `component_registry.ex` has all eight foundation families; `component_kitchen_live.ex` renders required `data-ax-foundation-*` specimens. |
| 8 | Browser computed-style checks exist for foundation specimens | VERIFIED | `foundation-tokens.spec.js` visits `/billing/dev/components`, calls `getComputedStyle`, checks z-index layers, semantic contrast, focus, disabled/readonly, scrollbar, and status values; `node --check` passed. |
| 9 | Static verifier guards enforce Phase 188 invariants | FAILED | Current `verify_package_docs.sh` exits 1 on a bare breakpoint before foundation checks; its HEEx utility guard also misses dynamic `class={...}` expressions. |
| 10 | Full automated Phase 188 gate passes | FAILED | `verify_package_docs.sh` failed; package-doc verifier tests failed 16/25; full `accrue_admin` suite failed 6 tests. |
| 11 | Maintainer visual review completed | UNCERTAIN | `188-07-SUMMARY.md` records approval, but this verifier did not reproduce the human kitchen review. |

**Score:** 6/11 truths verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue_admin/assets/css/theme.css` | Type, layer, semantic role, and motion tokens | VERIFIED | 433 lines; required token families found. |
| `accrue_admin/assets/css/app.css` | Type/measure/layer/motion/semantic consumers | PARTIAL | Substantive and wired, but contains undocumented local z-index literals and a bare breakpoint that breaks the shared verifier. |
| `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` | Tailwind build without config input | VERIFIED | Keeps `tailwindcss@3.4.17`; grep found no `--config`. |
| `accrue_admin/guides/admin_ui.md` | Styling SSOT documentation | VERIFIED | Names `theme.css`, `app.css`, `--ax-*`, `ax-*`, and "Tailwind utilities are not an authoring path." |
| `scripts/ci/verify_foundation_contrast.mjs` | FND-05 source contrast verifier | VERIFIED | Runs and passes on current semantic role tokens. |
| `scripts/ci/verify_package_docs.sh` | Static guardrails | FAILED | Current command exits 1; dynamic HEEx class guard coverage is incomplete. |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | Negative fixture coverage | FAILED | Current suite fails 16 tests due shared verifier preemption. |
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | Foundation registry metadata | VERIFIED | Contains `foundation-type`, `foundation-measure`, `foundation-layer`, `foundation-focus`, `foundation-disabled-readonly`, `foundation-interactive`, `foundation-scrollbar`, and `foundation-status`. |
| `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` | Rendered foundation specimens | VERIFIED | Contains required `data-ax-foundation-*` attributes. |
| `accrue_admin/e2e/foundation-tokens.spec.js` | Browser computed-style checks | PRESENT | Syntax check passed; full Playwright was not run because earlier required static/unit gates failed. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Asset build task | `assets/css/app.css` | Tailwind CLI `--input` | VERIFIED | Build task uses package CSS input and output paths without `--config`. |
| `app.css` | `theme.css` type tokens | `font: var(--ax-type-*-font)` | VERIFIED | `.ax-type-*` classes consume composed role tokens. |
| `app.css` | `theme.css` layer tokens | `z-index: var(--ax-z-*)` | PARTIAL | Main layer consumers are wired; local 0/1 overlay internals are undocumented. |
| `app.css` | `theme.css` semantic roles | `var(--ax-disabled-*)`, `var(--ax-focus-*)`, status/interactive tokens | VERIFIED | Shared selectors consume role tokens. |
| `verify_package_docs.sh` | `verify_foundation_contrast.mjs` | Node invocation with `ROOT_DIR` | VERIFIED | Script calls helper, but overall verifier currently fails earlier. |
| `foundation-tokens.spec.js` | `/billing/dev/components` | Playwright computed styles | PRESENT | Spec is wired to kitchen route and computed styles; not executed in this verification due earlier gate failure. |

### Data-Flow Trace

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `component_kitchen_live.ex` | Foundation specimen markup | Static LiveView render plus `ComponentRegistry` metadata | Yes | FLOWING |
| `component_registry.ex` | Foundation family entries/tokens | Checked token metadata and rendered kitchen tests | Yes | FLOWING |
| `foundation-tokens.spec.js` | Computed CSS values | Browser `window.getComputedStyle` from `/billing/dev/components` | Yes when e2e runs | PRESENT, NOT EXECUTED |

### Automated Checks

| Check | Command | Result | Status |
|---|---|---|---|
| Tailwind config deleted | `test ! -e accrue_admin/assets/tailwind.config.js && test ! -e accrue_admin/assets/tailwind_preset.js` | `absent` | PASS |
| Source contrast | `node scripts/ci/verify_foundation_contrast.mjs` | `[foundation_contrast] semantic role contrast checks passed` | PASS |
| Targeted foundation/unit tests | `cd accrue_admin && mix test --warnings-as-errors test/mix/tasks/accrue_admin_assets_build_test.exs test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/dev/component_registry_test.exs` | 38 tests, 0 failures | PASS |
| Foundation spec syntax | `node --check accrue_admin/e2e/foundation-tokens.spec.js` | OK | PASS |
| Static package/docs verifier | `bash scripts/ci/verify_package_docs.sh` | Fails on bare breakpoint `@media (max-width: 599.98px)` | FAIL |
| Package-doc verifier tests | `cd accrue && mix test --warnings-as-errors test/accrue/docs/package_docs_verifier_test.exs` | 25 tests, 16 failures | FAIL |
| Full admin suite | `cd accrue_admin && mix test --warnings-as-errors` | 320 tests, 6 failures | FAIL |
| Playwright foundation/full browser gate | Not run | Skipped because required static/unit gates failed first | SKIP |

### Requirement Traceability

| Requirement | Status | Evidence |
|---|---|---|
| FND-01 | VERIFIED | Composed type role tokens and utilities exist; raw-type static guard exists, but current package verifier preemption must be fixed to keep it enforceable. |
| FND-02 | PARTIAL | Semantic layer tokens exist, but undocumented local z-index literals remain in overlay internals and the guard does not enforce the planned micro-stack constraint. |
| FND-03 | VERIFIED | Reading measure consumers exist for prose/help/error/empty/description/narrative surfaces without generic table caps. |
| FND-04 | PARTIAL | Tailwind config/preset/build/docs SSOT is implemented; static HEEx utility guard misses dynamic `class={...}` expressions. |
| FND-05 | VERIFIED | Semantic role tokens exist in light/dark/system-dark and source contrast verifier passes. Review warning remains: subtree dark-token scope is not independently checked by the helper. |
| FND-06 | VERIFIED | Motion tokens and reduced-motion collapse are present; static verifier must pass again to keep this enforceable. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `accrue_admin/assets/css/app.css` | 2309 | Bare breakpoint media query without `--ax-bp-*` annotation | BLOCKER | Breaks `verify_package_docs.sh`, Plan 07 full gate, and package-doc verifier fixture tests. |
| `accrue_admin/assets/css/app.css` | 1168, 1176, 1242, 1249 | Local `z-index: 0/1` in overlay internals | BLOCKER | Violates or at least bypasses the documented Phase 188 micro-stack exception criteria. |
| `scripts/ci/verify_package_docs.sh` | 344-360 | HEEx utility guard scans literal class attributes only | BLOCKER | FND-04 drift can bypass the guard through `class={...}` expressions. |
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | 167 | Dynamic non-`ax-*` `hidden` class | WARNING | Current source demonstrates the guard blind spot; decide whether `.hidden` is an allowed root utility or should become an `ax-*` class/attribute. |
| `scripts/ci/verify_foundation_contrast.mjs` | 9-13 | Explicit dark/system scopes checked; subtree dark scope not checked | WARNING | Current tokens appear present, but future subtree-dark contrast drift could pass source verification. |

### Probe Execution

No Phase 188 probe scripts were declared or discovered.

### Human Verification Required

No new human checkpoint is requested while blocking automated gaps exist. `188-07-SUMMARY.md` records maintainer approval, but visual approval was not independently reproduced in this verification.

## Gaps Summary

Phase 188 built most foundation artifacts: tokens, CSS consumers, component kitchen specimens, source contrast checks, and targeted browser spec source are present and substantive. The phase goal is not currently achieved in the codebase because the final automated gate no longer passes and one required enforcement surface is observably incomplete.

The blocking root cause for the automated gate is a current `app.css` bare breakpoint that makes `verify_package_docs.sh` fail before Phase 188 guard categories can be proven. Separately, the layer and Tailwind-authoring guards are weaker than the plan contract: undocumented local z-index literals remain in overlay internals, and dynamic HEEx class expressions bypass the Tailwind utility guard.

---

_Verified: 2026-06-20T12:14:21Z_
_Verifier: the agent (gsd-verifier)_
