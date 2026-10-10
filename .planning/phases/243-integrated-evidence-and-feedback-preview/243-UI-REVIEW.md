# Phase 243 — UI Review

**Audited:** 2026-10-10
**Baseline:** Abstract 6-pillar standards; no Phase 243 UI-SPEC.md
**Screenshots:** Existing twelve-image Linux baseline set inspected (1280×900 desktop, light and dark)
**Interaction captures:** off (workflow.ui_interaction_capture is false); interaction findings are code- and recorded-test-derived

The Phase 211 visual comparison passed on revision `0197f4bad11d7b667a6359aba7adfae666f9dd95` (workflow run `38083267168`). This result is tied to that revision. Phase 243's later mounted CSS/JS identity proof and routing repair passed separately; neither is a new Linux pixel comparison. The mounted-host evidence showed a working wordmark. The tracked Linux package screenshots show the package visual fixture with a broken logo, so that finding is scoped to that fixture. Screenshot magenta strips are Playwright timestamp masks and are not app colors.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Action review explains the staged change and explicitly says when an estimate is unavailable. |
| 2. Visuals | 2/4 | Linux captures show a broken sidebar mark and invoice ID/customer text touching. |
| 3. Color | 3/4 | Light/dark palettes have clear neutral surfaces and restrained blue action emphasis; screenshots include magenta mask artifacts. |
| 4. Typography | 3/4 | The token system is coherent, but the rendered subscription detail is dense and uses a broad seven-step type scale. |
| 5. Spacing | 2/4 | The action band renders with a 4px gap and long detail pages compress many sections into one uninterrupted column. |
| 6. Experience Design | 3/4 | Confirmation is staged, disabled during dispatch, and step-up returns focus; responsive and live error states lack current visual captures. |

**Overall: 16/24**

## Top 3 Priority Fixes

1. **Repair the package visual fixture's sidebar logo asset** — the broken image appears in both light and dark invoice captures and weakens brand confidence — provide a fixture-local valid asset or a stable text/mark fallback.
2. **Separate invoice identifiers from customer names** — the first column renders strings such as `E2E-JPY-001E2E Dunning Customer` without visual separation — add an explicit block/stack and spacing between the linked invoice ID and customer label.
3. **Give the subscription action cluster more room** — the mounted Phase238 assertion confirms a 4px action-band gap, which reads crowded among adjacent primary actions — use the next spacing token and verify the narrow layout remains usable.

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **PASS, with minor recommendation:** The subscription action review states the target, current state, selected change, and when a charge estimate is unavailable (`subscription_live.ex:643-695`). This is useful financial-action copy rather than a generic confirmation prompt.
- **WARNING:** The visual action label is `Confirm {action}` (`subscription_live.ex:545-556`), and the secondary control is a generic “More actions” menu (`subscription_live.ex:366-370`). Keep the contextual label, and consider naming the menu “Other subscription actions” if the available actions remain unclear in the rendered context.
- Empty invoice states are differentiated for first-run, queue-empty, and filtered-empty cases (`invoices_live.ex:470-493`); no generic empty-state wording was found in the audited path.

### Pillar 2: Visuals (2/4)

- **WARNING:** The light and dark Linux invoice-list captures (`accrue_admin/e2e/__screenshots__/visual-desktop/invoices.png` and `invoices-dark.png`) show a broken sidebar image with clipped “Accru…” alternative text. The later mounted-host screenshot reported in `243-HANDOFF.md` showed a working mark, so this is isolated to the package visual fixture and should be fixed there rather than treated as a mounted-preview defect.
- **WARNING:** In the same captures, invoice links and customer names visually run together in the first column (for example, `E2E-JPY-001E2E Dunning Customer`). Add clear separation in the invoice-row markup.
- **PASS:** The open invoice review capture has a strong focal drawer, visible staged-action summary, and anchored footer action (`invoice-detail.png`, `invoice-detail-dark.png`). The selected visuals retain amount, identity, state, and action copy outside the timestamp masks per `admin-visual-regression-phase211.spec.js:26-71`.
- The captures cover desktop compositions only. They do not establish the current responsive behavior of the invoice or subscription pages.

### Pillar 3: Color (3/4)

- **PASS:** The inspected light and dark invoice compositions preserve neutral page/card surfaces and use the blue accent mainly for the selected navigation item, links, focus, and primary action. The palette changes appropriately between themes.
- **WARNING (evidence artifact):** The committed screenshots show vivid magenta bars over timestamp values. These are the Playwright `maskColor` artifacts documented in `admin-visual-regression-phase211.spec.js:19-22`, not live UI elements. They reduce the usefulness of the images for judging color harmony in those regions; avoid treating them as product color usage.
- Theme color roles are tokenized (`assets/css/theme.css:137-165`), including distinct danger, warning, and informational roles. No third-party registry audit applies: `accrue_admin/components.json` is absent.

### Pillar 4: Typography (3/4)

- **PASS:** `theme.css:13-23` declares a consistent Geist/system sans stack and a seven-step scale from 0.75rem through 2.25rem. Label/title roles use consistent weights in `theme.css:83-108`.
- **WARNING:** The subscription detail capture (`subscription-detail.png`) shows a long operational page where multiple compact labels, data rows, action controls, related-resource links, and audit details compete at nearly the same visual prominence. Strengthen section separation and reserve the smallest type for metadata so the main health and action hierarchy remains easy to scan.

### Pillar 5: Spacing (2/4)

- **WARNING:** The mounted Phase238 proof recorded a 4px action-band gap (`243-HANDOFF.md`), matching the `--ax-space-xs` token. On an action cluster with neighboring change/cancel/menu controls, this reads cramped; test the next 8px token against both full-width and narrow layouts.
- **WARNING:** The subscription-detail capture packs summary facts, billing rows, actions, related billing links, recovery, compliance, and audit history into a continuous vertical flow. Increase separation between major sections so the page is easier to scan without changing its information content.
- **PASS:** The theme defines a consistent 2–64px spacing scale (`theme.css:25-33`); arbitrary class spacing is not the dominant styling pattern in the inspected Elixir templates.

### Pillar 6: Experience Design (3/4)

- **PASS:** The confirmation control is disabled while awaiting step-up, dispatching, or submitted, and shows a contextual submitting label (`subscription_live.ex:545-556`). The review panel explicitly says that the operator is reviewing a staged action before confirming (`subscription_live.ex:643-695`).
- **PASS:** The step-up modal receives a return-focus selector for the unique visible confirmation control (`subscription_live.ex:547-548,599-604`; modal wiring in `step_up_auth_modal.ex:26-40`). The direct Phase234 owner passed 2/2 according to `243-02-SUMMARY.md`; this is deterministic behavior evidence, not a substitute for human UAT.
- **WARNING:** The current audit has no interaction captures because the workflow setting is off. Error, loading, and narrow-screen states are therefore code/test-derived or unobserved visually. Existing code has action result announcements (`subscription_live.ex:324-334`) and invoice empty-state branches (`invoices_live.ex:470-493`), but this audit cannot claim those states were visually exercised.
- **WARNING:** The action drawer has a hidden `aria-hidden` mirror used by tests (`subscription_live.ex:563-597`). Keep selectors and behavior assertions anchored to the visible drawer so future tests do not accidentally certify the hidden duplicate.

## Files Audited

- `.planning/phases/243-integrated-evidence-and-feedback-preview/243-01-PLAN.md`
- `.planning/phases/243-integrated-evidence-and-feedback-preview/243-02-PLAN.md`
- `.planning/phases/243-integrated-evidence-and-feedback-preview/243-03-PLAN.md`
- `.planning/phases/243-integrated-evidence-and-feedback-preview/243-01-SUMMARY.md`
- `.planning/phases/243-integrated-evidence-and-feedback-preview/243-02-SUMMARY.md`
- `.planning/phases/243-integrated-evidence-and-feedback-preview/243-03-SUMMARY.md`
- `.planning/phases/243-integrated-evidence-and-feedback-preview/243-CONTEXT.md`
- `.planning/phases/243-integrated-evidence-and-feedback-preview/243-HANDOFF.md`
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex`
- `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex`
- `accrue_admin/assets/css/theme.css`
- `accrue_admin/assets/css/app.css`
- `accrue_admin/e2e/admin-visual-regression-phase211.spec.js`
- All twelve PNGs in `accrue_admin/e2e/__screenshots__/visual-desktop/`
- `.planning/phases/241-billing-operator-journeys/evidence/phase237-exemplar/subscription-detail-narrow.png` (historical narrow-screen reference only)
