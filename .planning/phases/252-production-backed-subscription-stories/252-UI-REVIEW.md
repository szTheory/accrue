# Phase 252 — UI Review (Re-audit)

**Audited:** 2026-10-27<br>
**Baseline:** Approved [252-UI-SPEC.md](252-UI-SPEC.md)<br>
**Current score:** 18/24<br>
**Screenshots:** captured — all 12 canonical images from owner run `25208-1793100141333-35541-feacb3440bfa`, plus 4 focused 320px variation images<br>
**Interaction captures:** off (workflow.ui_interaction_capture is false)

This re-audit inspected the actual PNGs for all three states at 320px and 1280px in both themes. `scheduled_cancellation` correctly retains the active lifecycle label while showing its scheduled cancellation date and omitting `Cancel renewal`; `incomplete_evidence` shows its unavailable facts and ordered caveats. The earlier token-scope and cramped-preview findings are resolved in these captures.

At the re-audited revision, one visual defect remained (resolved in the addendum below): the eligible `Change plan` action is present in the light-theme DOM but has no visible fill or text in the 1280px light captures, while it is visibly filled in the dark captures. Light-theme summary row actions also render black instead of the contract’s accent color. The evidence points to `--ax-accent` missing from the real light Storybook sandbox scope. The 1280px captures also show the summary header and action band much narrower than the full-width fact list.

## Current Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | All three requested states show the specified status, unavailable and action copy. |
| 2. Visuals | 2/4 | The light primary action is visually absent; the desktop summary and action cards are much narrower than the fact list. |
| 3. Color | 2/4 | Light Storybook scope lacks its accent binding, leaving row links black and the primary action visually blank. |
| 4. Typography | 4/4 | Current captures show Geist, Geist Mono IDs, 28px title, 14px values and 12px labels. |
| 5. Spacing | 3/4 | Mobile facts now stack cleanly; the centered desktop action band remains cramped relative to the full-width rows. |
| 6. Experience Design | 3/4 | Semantics and measured control targets pass; the ID copy affordance is visually subtle and no interaction captures were requested. |

**Overall: 18/24**

## Current Priority Fixes

1. **WARNING — Bind the light-theme accent in the Storybook sandbox.** Provide the host `--ax-accent` value to `.psb-sandbox.accrue-admin` in light mode. This should restore accent summary links and the eligible `Change plan` button’s fill and text. Add a rendered-style assertion for the primary button and row-link colors; geometry and existence checks do not catch the invisible light button.
2. **WARNING — Align the 1280px summary/action hierarchy with the fact list.** The screenshots show a roughly 348px summary card and 263px action card centered under a fact list spanning about 930px. Stretch or otherwise compose these blocks so the action area reads as part of the detail surface at desktop width.
3. **MINOR — Make the copyable subscription ID easier to discover.** The ID is a plain monospace line with an accessible button name but no visible copy cue. Consider a small copy icon or visible hover/focus treatment while preserving the accessible label and full clipboard value.

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- **PASS:** The active captures show `No cancellation scheduled`, `Amount (MRR) Unavailable`, `Change plan`, `Cancel renewal`, `More actions`, and `Subscription actions` where visible. The production composition owns these strings and eligibility (`accrue_admin/lib/accrue_admin/live/subscription_live.ex:260-329`); the contract specifies them at `252-UI-SPEC.md:32-40,114-123`.
- **PASS:** The scheduled variation shows `Scheduled for Nov 24, 2026, 07:00:00 AM EST`, the matching `Ends` date and a visible `Change` renewal-row link; `Cancel renewal` is omitted. Its top lifecycle label remains `Active`, which is consistent with a still-active subscription scheduled to end.
- **PASS:** Incomplete evidence shows `Renewal date unavailable`, `Price unavailable`, `Current period unavailable`, and `Charge amount unavailable`; the billing caveats appear in the required order. The three states are visible in the canonical captures listed below.

### Pillar 2: Visuals (2/4)

- **WARNING:** In all three 1280px light captures, the eligible `Change plan` button occupies the expected position but has no visible fill or text. Its dark-theme counterpart is visibly filled. This removes the expected primary focal point in the light theme even though the action exists in the rendered DOM.
- **WARNING:** The desktop summary header is approximately 348px wide and the action band approximately 263px, centered below the fact list, which spans about 930px. This splits one detail composition into disconnected visual widths and makes the action hierarchy feel undersized at the 1280px target (`252-UI-SPEC.md:32,42`).
- **RESOLVED:** The earlier 350px preview and unstyled content findings are not present in the current captures. The selected variation now receives a one-column preview with readable, full-width fact rows; at 320px, facts stack in one column and long caveats wrap without horizontal page overflow.

### Pillar 3: Color (2/4)

- **WARNING:** Light-theme summary action links appear black rather than accent-colored, and the `Change plan` primary appears visually blank in the active, scheduled and incomplete 1280px light captures. In each corresponding dark capture, links are blue and the primary button has a visible filled accent surface.
- The base token block now scopes to `html.accrue-admin, .psb-sandbox.accrue-admin` (`accrue_admin/assets/css/theme.css:13-14`), but it references `--ax-accent` for `--ax-accent-readable` and `--ax-accent-strong` without defining that host token there (`theme.css:162-168`). The dark shim supplies `--ax-accent` (`accrue_admin/priv/static/storybook.css:114-131`); the light sandbox has no corresponding binding. The production layout injects the host accent at `:root` (`accrue_admin/lib/accrue_admin/layouts.ex:100-106`), while the direct Storybook component route does not render that layout.
- The affected styles are specific: the primary button uses `--ax-accent-strong` and `--ax-accent-contrast` (`accrue_admin/assets/css/app.css:2840-2844`), and summary links use `--ax-accent-readable` (`app.css:6429-6444`). The owner result ledger records the light button’s 118×44px box and `Change plan` text, so its absence is a paint/color issue rather than ineligibility.

### Pillar 4: Typography (4/4)

- **PASS:** The 1280px and 320px captures use Geist for UI text and Geist Mono for the subscription ID. The summary title has the specified 28px/600 role, values use the 14px scale, and labels use the restored 12px scale (`252-UI-SPEC.md:24,85-95`; `accrue_admin/assets/css/app.css:5703-5710,6391-6407`).
- The previous Times-style fallback is resolved in the actual direct-route captures, not only in the E2E-adjusted DOM.

### Pillar 5: Spacing (3/4)

- **PASS:** At 320px, labels and values use a single-column rhythm and wrap long dates/caveats without horizontal overflow. The title and status badge have visible separation. The owner run measured the action targets at the required 44px height.
- **WARNING:** The narrow centered action band and summary header remain much smaller than the full-width fact area at 1280px. The buttons fit, but their tight cluster does not carry the same visual weight as the surrounding rows. Relevant production rules use the spacing tokens and set the action minimum height (`accrue_admin/assets/css/app.css:5696-5700,6371-6383,6541-6548`).
- The 320px screenshots are 1100px tall and show only the upper portion of each long story in one frame; the lower rows continue vertically. This is normal vertical scrolling, not evidence of clipping. The run measured the page geometry at its declared 900px viewport before restoring the capture height.

### Pillar 6: Experience Design (3/4)

- **PASS:** The current screenshots show all state-specific facts, named row actions, an explicit `More actions` trigger, and the active status label. Production markup keeps an `h1`, `h2`, `dl`/`dt`/`dd`, accessible copy button and button/anchor control semantics (`accrue_admin/lib/accrue_admin/live/subscription_live.ex:260-320`; `accrue_admin/lib/accrue_admin/components/detail.ex:73-112,125-137`; `id_badge.ex:35-49`). The owner run reports 16 executed browser tests with no skips or failures, including keyboard focus and full-ID copy predicates.
- **WARNING:** The ID copy button appears as a passive monospace value without a visible copy icon or label. Its accessible name and clipboard behavior are verified, but visual discovery is weak in the screenshot.
- **Evidence limit:** Interaction captures are off. The current screenshots show static presentation only; neither they nor the static story establish mounted authorization, action dispatch, provider completion or persistence. That matches the story’s declared proof lane (`storybook/components/subscription_detail.story.exs:2-6`) and does not reduce the UI score for behaviors outside this phase.

## Prior Audit History — Resolved

The initial audit on 2026-10-27 scored **10/24**: Copywriting 4, Visuals 1, Color 1, Typography 1, Spacing 1, Experience Design 2. Its primary finding was that the untouched Storybook sandbox did not resolve the production token scope, causing serif fallback typography, poor dark contrast and cramped preview content. The original report is preserved in commit `e773da57` (`docs(252): add UI review`).

The follow-up changes in `252-REVIEW-FIX.md` addressed those findings: real `.psb-sandbox.accrue-admin` token scope, theme control through Storybook’s supported event, no helper-added document/sandbox classes, a one-column preview, and restored label typography. All 12 current canonical captures confirm those original blockers are resolved. The remaining light accent defect in this re-audit is narrower: the base Storybook sandbox still lacks the host `--ax-accent` value.

## Capture and Evidence Paths

The 12 current canonical screenshots were inspected directly:

- `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/screenshots/active-1280-light.png`
- `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/screenshots/active-1280-dark.png`
- `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/screenshots/active-320-light.png`
- `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/screenshots/active-320-dark.png`
- `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/screenshots/scheduled_cancellation-1280-light.png`
- `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/screenshots/scheduled_cancellation-1280-dark.png`
- `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/screenshots/scheduled_cancellation-320-light.png`
- `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/screenshots/scheduled_cancellation-320-dark.png`
- `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/screenshots/incomplete_evidence-1280-light.png`
- `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/screenshots/incomplete_evidence-1280-dark.png`
- `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/screenshots/incomplete_evidence-320-light.png`
- `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/screenshots/incomplete_evidence-320-dark.png`

Four additional focused 320px captures were inspected for scheduled cancellation and incomplete evidence:

- `accrue_admin/tmp/phase252/ci-results/25208-focus-20261027-34785/screenshots/scheduled_cancellation-320-light.png`
- `accrue_admin/tmp/phase252/ci-results/25208-focus-20261027-34785/screenshots/scheduled_cancellation-320-dark.png`
- `accrue_admin/tmp/phase252/ci-results/25208-focus-20261027-34785/screenshots/incomplete_evidence-320-light.png`
- `accrue_admin/tmp/phase252/ci-results/25208-focus-20261027-34785/screenshots/incomplete_evidence-320-dark.png`

The owner run result bundle is `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/results.json`; its per-run render ledger is `accrue_admin/tmp/phase252/render-results-25208-1793100141333-35541-feacb3440bfa.json`. The previous fixed historical ledger and golden assets were not changed. `components.json` is absent and the UI spec declares no third-party registries, so registry safety audit was not applicable.

## Files Audited

- `.planning/phases/252-production-backed-subscription-stories/252-UI-SPEC.md`
- `.planning/phases/252-production-backed-subscription-stories/252-06-SUMMARY.md`
- `.planning/phases/252-production-backed-subscription-stories/252-REVIEW-FIX.md`
- `.planning/phases/252-production-backed-subscription-stories/252-VALIDATION.md`, `252-UAT.md`, `252-SECURITY.md`
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- `accrue_admin/lib/accrue_admin/components/detail.ex`, `status_badge.ex`, `id_badge.ex`
- `storybook/components/subscription_detail.story.exs`
- `accrue_admin/lib/accrue_admin/dev/storybook.ex`, `accrue_admin/lib/accrue_admin/layouts.ex`
- `accrue_admin/assets/css/theme.css`, `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/storybook.css`
- `accrue_admin/e2e/phase252-story-helpers.js`, `accrue_admin/e2e/phase200-storybook-helpers.js`
- The 12 canonical and 4 focused screenshots listed above

## Accent Visibility Resolution — 2026-10-27

The light accent finding was corrected in `3991d890`. The actual sandbox inherits the production host accent with the existing brandbook fallback. Focused unmodified active-light cases at 320px and 1280px passed: primary contrast 5.98:1 and row Change contrast 6.84:1; a host override propagated correctly. The parent also directly inspected the current active desktop/mobile captures and confirmed visible colored primary and row actions. Current captures: `accrue_admin/tmp/phase252/ci-results/25208-1793102721082-59067-6ba5536df2dd/screenshots/`. The current eighteen-command aggregate and sixteen executed browser tests pass. This resolves the accent/blank-primary warning; the 18/24 score above records its prior audited revision and is not silently re-scored. Desktop summary/action width and copy-affordance recommendations remain deferred, non-blocking polish.
