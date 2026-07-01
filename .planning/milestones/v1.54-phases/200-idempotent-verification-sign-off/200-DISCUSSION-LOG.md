# Phase 200: Idempotent verification & sign-off - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-30
**Phase:** 200-idempotent-verification-sign-off
**Areas discussed:** Scope/todo boundary, Storybook coverage and theming, forward-only scorecard, accessibility/theme/browser guardrails, multi-lens sign-off

---

## Scope and Todo Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Fold matched todos | Pull portal, PageHeader, or brandbook favicon todos into Phase 200. | |
| Review but do not fold | Record all matched todos as reviewed/not folded and preserve Phase 200 as admin verification/sign-off only. | yes |
| Cancel discussion | Stop before context capture. | |

**User's choice:** Discuss all relevant areas and use subagent research. The scope advisor recommended reviewing but not folding any matched todo.
**Notes:** White-label portal is `accrue_portal` scope; PageHeader was resolved by 196/197; brandbook favicon is brandbook maintenance.

---

## Storybook Coverage and Theming

| Option | Description | Selected |
|--------|-------------|----------|
| Generated-only registry stories | Maximum SSOT discipline but weak for named slots, overlays, and group compositions. | |
| Hand-written stories | Human-curated but high drift risk and duplicates registry data. | |
| Hybrid generated floor plus curated wrappers | Registry remains SSOT while wrappers handle composites, slots, overlays, and design-lab examples. | yes |
| Kitchen-primary with minimal Storybook | Keeps current `/dev/components` flow but fails STY-02/STY-03. | |

**User's choice:** Research all and produce a coherent recommendation; selected recommendation is hybrid generated floor plus curated wrappers.
**Notes:** Scout found only `storybook/_support/registry_story.ex` exists today. Current registry inventory is 30 unique families, 42 entries, and 8 group contracts; tests should derive counts dynamically.

---

## Forward-Only Scorecard

| Option | Description | Selected |
|--------|-------------|----------|
| Full union rescore in CI every PR | Maximum confidence but too slow/flaky for normal CI. | |
| Sampled representative rescore | Fast but does not satisfy VER-01 all-cell proof. | |
| Staged-full closeout | Deterministic guardrails during implementation, full union scorecard at closeout. | yes |
| Rewrite/rebaseline after improvements | Simpler final baseline but destroys forward-only audit value. | |

**User's choice:** Research all and recommend one path; selected recommendation is staged-full closeout.
**Notes:** Union baseline is archived v1.53 component/group cells plus Phase-193 page-flow cells. `regressions.ndjson` must be empty for ACCEPT.

---

## Accessibility, Theme, and Browser Guardrails

| Option | Description | Selected |
|--------|-------------|----------|
| Exhaustive Cartesian matrix | Route x state x story x viewport x theme everywhere; too slow and noisy. | |
| Representative routes only | Fast but misses Storybook and rare theme/state failures. | |
| Targeted known-risk matrix plus full route/story axe | Axe all primary routes and completed stories in light/dark, with targeted Playwright for no-FOUC/theme/motion/interaction. | yes |
| Pixel-diff visual gate | Catches visual drift but is explicitly deferred and brittle. | |
| Axe-only gate | Necessary but cannot prove focus, modal behavior, copy meaning, or JTBD fit. | |

**User's choice:** Research all and recommend a coherent verification shape; selected recommendation is the hybrid risk matrix.
**Notes:** No-FOUC/persistence tests must use production `accrue_theme` cookie/localStorage/system path. Direct `data-theme` forcing is acceptable only for settled visual/axe scans.

---

## Multi-Lens Judge and Maintainer Sign-Off

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid sign-off package | `200-SIGN-OFF.md` as final decision surface, backed by structured artifacts and judge findings. | yes |
| Verification-only narrative | Simple but weak for explicit maintainer ACCEPT/REJECT. | |
| Screenshot gallery primary | Easy to scan but cannot prove interaction or a11y semantics. | |
| Judge report primary | Useful but can become subjective and scope-opening. | |
| CI-only required gate | Deterministic but cannot satisfy maintainer checkpoint. | |

**User's choice:** Research all and recommend the closeout workflow; selected recommendation is the hybrid sign-off package.
**Notes:** `200-SIGN-OFF.md` must end in exactly one final maintainer decision line. The judge is bounded to correctness, accessibility, brand, and interaction.

---

## Claude's Discretion

- Exact Phase 200 harness/script names, as long as outputs land in the Phase 200 directory and archived v1.53/Phase 192 artifacts are not mutated.
- Exact Storybook module layout, as long as the registry remains the SSOT and all families/groups are dynamically verified.
- Exact browser scan batching, as long as all primary admin routes and completed stories receive settled light/dark axe coverage and the known-risk matrix covers production theme boot, reduced motion, overlay/focus, disabled/hover affordances, long content, and boundary fixtures.
- Exact sign-off summary wording, bounded by `brandbook/voice.md`.

## Deferred Ideas

- White-label billing portal design system - future `accrue_portal` phase.
- Brandbook favicon update - future brandbook maintenance.
- Runtime Storybook replacement for `/dev/components` - deferred.
- Tailwind-style Storybook rebuild - rejected.
- Pixel-diff / SaaS visual-regression gate - deferred.
- Exhaustive Cartesian matrix in every CI run - rejected.
- Broad UI polish found during sign-off - defer unless tied to a blocking locked contract.
