# Phase 252 — UI Review

**Audited:** 2026-10-27<br>
**Baseline:** Approved [252-UI-SPEC.md](252-UI-SPEC.md)<br>
**Screenshots:** captured — active story at 1280px light/dark and 320px light in `.planning/ui-reviews/252-20261027-0815/`<br>
**Interaction captures:** off (workflow.ui_interaction_capture is false)

The untouched Storybook route was captured directly. The active story shows the expected content but loses most of its design tokens. Scheduled and incomplete route captures did not reliably show their requested variations, so they are not used as visual evidence for those states. `scheduled-verify.png` showed the Storybook header without story content. No interaction states were captured. The ignored screenshots are review evidence only.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Active story labels and unavailable-value copy match the contract. |
| 2. Visuals | 1/4 | The live story preview loses its intended hierarchy and is cramped at 1280px. |
| 3. Color | 1/4 | Dark mode shows black headings and identifiers against dark surfaces. |
| 4. Typography | 1/4 | The untouched story renders serif browser defaults instead of Geist and the specified type scale. |
| 5. Spacing | 1/4 | Missing spacing tokens leave a crowded 320px title row and tightly packed facts/actions. |
| 6. Experience Design | 2/4 | Semantic structure is present, but interaction states were not captured and the rendered action affordances are degraded. |

**Overall: 10/24**

## Top 3 Priority Fixes

1. **BLOCKER — Make the production token scope resolve in the Storybook sandbox.** Apply the `accrue-admin` class where `theme.css` expects it on the actual story document, or change the token scope to match the sandbox root. Remove the test-only root-class mutation after the real route supplies the same styling.
2. **BLOCKER — Restore readable hierarchy and contrast in both themes.** Verify the untouched dark route renders the 28px title, readable primary text, and semantic accent/status colors; the current screenshot shows black title/action text on dark surfaces and default blue links.
3. **BLOCKER — Give the story content usable width and spacing at 1280px and 320px.** The 1280px Storybook preview leaves roughly 368px for the component, forcing fact values into narrow wraps; at 320px the title and status nearly touch. Recheck the component’s actual content width, single-column mobile rows, and action spacing after token scope is fixed.

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- **PASS:** The active capture shows `Change plan`, `Cancel renewal`, `More actions`, `Subscription actions`, and `Amount (MRR) Unavailable`, matching the approved contract. The production composition supplies those labels and actions in `accrue_admin/lib/accrue_admin/live/subscription_live.ex:260-329`; the contract specifies them in `252-UI-SPEC.md:32-40,114-123`.
- The screenshot confirms active-state copy only. Scheduled-cancellation and incomplete-evidence wording was checked against the contract and source, but their captures did not reliably display the target variations, so those strings are not counted as visually verified.

### Pillar 2: Visuals (1/4)

- **BLOCKER:** In `active-1280-light.png`, the component preview occupies about 368px beside Storybook’s source pane. The three-column facts technically render, but long values and links wrap into narrow fragments, weakening scan order and the main-card hierarchy required at 1280px (`252-UI-SPEC.md:32,42`).
- **BLOCKER:** In `active-320-light.png`, the summary title and status badge nearly touch, and the summary/card/actions lose the intended title-to-detail hierarchy. Production markup has the right `h1`, `dl`, and `h2` structure (`detail.ex:125-137`, `subscription_live.ex:288-322`), but the untouched render does not make that structure visually legible.
- The real page remains the Phoenix Storybook review shell; these findings concern the subscription component as it is actually presented inside that shell, not the overall production admin page.

### Pillar 3: Color (1/4)

- **BLOCKER:** `active-1280-dark.png` shows the subscription title, copied ID and `Subscription actions` heading in black on dark surfaces; the row links remain default blue. The contract requires semantic dark tokens and reserves accent for eligible actions, links and focus (`252-UI-SPEC.md:99-110`).
- The token stylesheet declares its base variables on `html.accrue-admin` and dark variables on `html.accrue-admin[data-theme="dark"]` (`accrue_admin/assets/css/theme.css:12-14,231-240`). Storybook’s backend sets `sandbox_class: "accrue-admin"` (`accrue_admin/lib/accrue_admin/dev/storybook.ex:13-20`), while the E2E helper separately adds that class to `<html>` after navigation (`accrue_admin/e2e/phase252-story-helpers.js:627-628`). The untouched screenshot is direct evidence that the production story route does not receive the same effective token scope as the helper-adjusted scan.

### Pillar 4: Typography (1/4)

- **BLOCKER:** Desktop and mobile captures show Times-style serif text in the subscription title, IDs, values and action controls rather than Geist/Geist Mono. The title also appears near body size instead of the specified 28px heading role. The approved contract requires Geist and four defined sizes (`252-UI-SPEC.md:24,85-95`).
- Authored CSS defines the intended title and summary-value sizes, but those declarations depend on custom properties (`accrue_admin/assets/css/app.css:5703-5710,6401-6407`), while font tokens are scoped to `html.accrue-admin` (`accrue_admin/assets/css/theme.css:12-23`). The screenshot shows the values are not effective in the untouched sandbox.

### Pillar 5: Spacing (1/4)

- **BLOCKER:** The desktop preview compresses values and action links into a narrow third column, and the mobile summary title/status have almost no visible separation. This misses the declared 4px-based scale and the 320px wrap/spacing contract (`252-UI-SPEC.md:42,67-81`).
- The component styles use spacing variables for the title row, fact rows, and 44px action controls (`accrue_admin/assets/css/app.css:5696-5700,6371-6383,6541-6544`). The direct screenshots show the authored rhythm is not being realized in the served story preview. The action targets’ measured test result is not treated as proof of perceived spacing or successful focus presentation.

### Pillar 6: Experience Design (2/4)

- **WARNING:** The production renderer preserves useful semantics: a page-level heading, `dl` rows with `dt`/`dd`, a labelled copy button, and button/anchor action controls (`subscription_live.ex:260-320`, `detail.ex:73-112,125-137`, `id_badge.ex:35-49`). The visible active labels and facts follow the contract.
- **WARNING:** This audit captured no focus, copy-feedback, menu-open, or action states because interaction capture is disabled. The static story explicitly does not establish mounted authorization or action success (`storybook/components/subscription_detail.story.exs:2-6`), so those behaviors remain outside this visual evidence. The screenshots still show native-looking, crowded actions, and the test helper’s root-class/theme mutations mean its computed-style checks do not substitute for the untouched route (`phase252-story-helpers.js:622-635`, `phase200-storybook-helpers.js:78-96`).

## Files Audited

- `.planning/phases/252-production-backed-subscription-stories/252-UI-SPEC.md`
- `.planning/phases/252-production-backed-subscription-stories/252-01-PLAN.md` and `252-01-SUMMARY.md` through `252-08-PLAN.md` and `252-08-SUMMARY.md`
- `.planning/phases/252-production-backed-subscription-stories/252-VALIDATION.md`, `252-UAT.md`, `252-SECURITY.md`
- `CLAUDE.md`
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- `accrue_admin/lib/accrue_admin/components/detail.ex`, `status_badge.ex`, `id_badge.ex`
- `storybook/components/subscription_detail.story.exs`
- `accrue_admin/lib/accrue_admin/dev/storybook.ex`, `accrue_admin/lib/accrue_admin/router.ex`
- `accrue_admin/assets/css/theme.css`, `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/storybook.css`
- `accrue_admin/e2e/phase252-story-helpers.js`, `accrue_admin/e2e/phase200-storybook-helpers.js`
- `.planning/ui-reviews/252-20261027-0815/active-1280-light.png`, `active-1280-dark.png`, `active-320-light.png`, `scheduled-1280-light.png`, `incomplete-1280-light.png`, and `scheduled-verify.png`; scheduled/incomplete captures were inspected but not used to assert those states.
