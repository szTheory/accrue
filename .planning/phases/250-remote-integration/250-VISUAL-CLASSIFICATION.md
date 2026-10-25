# Phase 250 Visual Classification Ledger (D4)

Per-surface classification of the Phase 211 Linux pixel gate for PR #49, checked mechanically by
`node .planning/phases/250-remote-integration/250-visual-ledger-check.mjs --ledger <this file> --base <visual_base>`.

## Source evidence

- **First failure:** Browser UAT pull_request run `40229480489` at `b9c98b20081841e976586339db47554e40da7179`.
  The gate failed *before any pixel comparison*: `dashboard: rendered timestamp anchor` expected > 0, received 0.
  247-03 (`de3d2698`) had moved timeline instants into the shared `Timestamp` control, so the spec's
  `time.ax-timeline-time` anchor no longer rendered. Artifact `accrue-admin-playwright-traces` /
  `test-failed-1.png` shows the redesigned Home. The fix retargets the anchor to the new control and lets the existing
  time-of-day mask group accept the Intl output `Oct 25, 2026, 08:30:14 PM UTC`. It adds no new anchor, mask region,
  threshold change or surface change.
- **Full capture:** `workflow_dispatch` run `40232864961` (job `Mint visual baselines`, `success`) at
  `visual_base` = `133fafc2b0c4487522eaa40801985518e4d986ec` (headSha matches). Artifact `phase211-visual-baselines`,
  path `visual-desktop/<file>`. The PR gate stops at the first mismatching surface, so the dispatch capture is the only
  run that renders all 12 surfaces at the pushed head.
- **Diffs:** each minted PNG was compared to the committed baseline at `133fafc2` with Playwright's own
  `getComparator("image/png")` under the gate's options (`threshold 0.2`, `maxDiffPixelRatio 0.01`). This writes
  `<surface>-diff.png`. For every changed surface the expected, actual and diff PNG were read.
- **Baseline age:** the committed baselines are from `0197f4ba` (243-01, 2026-10-10). They predate the 2026-10-11
  phase-247 work and the 2026-10-12..19 admin owner-feedback series (`3d7d949d..b4a7eeac`), and the gate never ran
  between then and this phase.
- **After the owner-feedback range:** admin CSS and markup changed only in `1a755b2d` (249-01: `min-width: 0` on
  ellipsis cells and comment-only `ax-type-exception` notes), `8b9dc258` (249-09: topbar reflow, inside a narrow-width
  media query), `6fc488cd` (250-03: `:focus-visible` only) and non-visual 249-02/249-12 Elixir hygiene. None of them
  changes a 1280 px desktop composition apart from ellipsis truncation, and that truncation is covered by 249-01.

## D4 rule

A change traceable to an owner-feedback commit (`3d7d949d..b4a7eeac`, notes
`.planning/notes/2026-10-1*-admin-owner-feedback.md`), a v1.63-v1.66 phase commit (`233..248`), or the
249-01/249-09/250-03 CSS fixes is `intentional` and is re-minted from the CI dispatch artifact. Anything else is a
`regression` and is fixed in source. Surfaces whose minted PNG is byte-identical to the committed baseline are
`unchanged`.

## Ledger

| surface | theme | baseline file | status | diff ref | classification | receipt | fix | rationale |
|---|---|---|---|---|---|---|---|---|
| dashboard | light | dashboard.png | changed: 71847 px (0.07) | mint run 40232864961 phase211-visual-baselines/visual-desktop/dashboard.png; dashboard-diff.png; first failure PR run 40229480489 test-failed-1.png | intentional | receipt:3d7d949d | - | Owner-feedback Home redesign: "Billing operations" became "Recent activity" with a "View events" link; the CTA row is gone; Home left the nav (Recent activity is now the first Billing item, Recovery renamed Payment recovery); timeline rows have family icons, human event names ("Customer updated") and "Recorded by admin"; the topbar has Time display (247-02) and compact search (246-03). Timestamps are fully masked. No orphaned or unstyled region. |
| dashboard | dark | dashboard-dark.png | changed: 74110 px (0.07) | mint run 40232864961 phase211-visual-baselines/visual-desktop/dashboard-dark.png; dashboard-dark-diff.png | intentional | receipt:3d7d949d | - | Same Home redesign as light. Dark tokens apply throughout (surface, icons, link, active nav item); nothing is light-on-light or unthemed. |
| invoices | light | invoices.png | changed: 1280x900 to 1280x1032, 56786 px (0.05) | mint run 40232864961 phase211-visual-baselines/visual-desktop/invoices.png; invoices-diff.png | intentional | receipt:b4a7eeac | - | Owner-feedback list redesign. b4a7eeac rewrote invoices_live (78 lines) and data_table: "Clear open receivables" became "Invoices"; Needs collection/All invoices lens tabs replace the chip row; labeled Search invoices and Status controls plus a Filters disclosure; stacked identity (number, customer, id) and "paid of" balance cells; "Ownership and tax" column; a "3 invoices loaded / End of list" footer (f23f8e75). Breadcrumb "Billing" (7e77a01f). The result count now sits at the end of the compact chip bar, which has no chips after b4a7eeac. The required row assertions for E2E-191-JPY-001 passed. |
| invoices | dark | invoices-dark.png | changed: 1280x900 to 1280x1032, 223425 px (0.17) | mint run 40232864961 phase211-visual-baselines/visual-desktop/invoices-dark.png; invoices-dark-diff.png | intentional | receipt:b4a7eeac | - | Same redesign as light. The larger ratio comes from the taller page: the comparator counts the extra 132 px rows on the dark background. Dark tokens apply to the tabs, inputs, table shell and muted text. |
| invoice-detail | light | invoice-detail.png | changed: 1280x1822 to 1280x1643 | mint run 40232864961 phase211-visual-baselines/visual-desktop/invoice-detail.png; invoice-detail-diff.png | intentional | receipt:b4a7eeac | - | The Void invoice review drawer (the capture's subject) is pixel-identical: title, step-up copy, invoice/customer/owner facts, "Reviewed amount: ¥100,000 (jpy)", Confirm/Back. Only the blurred page behind the overlay moved and shortened: b4a7eeac dropped the summary-card eyebrow, and 989c75e9 (247-05) and 7e77a01f changed the detail evidence and breadcrumbs. |
| invoice-detail | dark | invoice-detail-dark.png | changed: 1280x1822 to 1280x1643, 230812 px (0.10) | mint run 40232864961 phase211-visual-baselines/visual-desktop/invoice-detail-dark.png; invoice-detail-dark-diff.png | intentional | receipt:b4a7eeac | - | Same as light. The drawer is identical in dark; the differences are the blurred backdrop content offset and the 179 px shorter page. |
| subscriptions | light | subscriptions.png | changed: 1280x1198 to 1280x913, 86944 px (0.06) | mint run 40232864961 phase211-visual-baselines/visual-desktop/subscriptions.png; subscriptions-diff.png | intentional | receipt:66d5b3ce | - | Owner-feedback list redesign ("unify list controls and billing evidence"). The "Action required" header, CTA buttons and FILTERS card are replaced by the subtitle, a "Subscriptions 6 / Past due 2 / Ending 1" strip, labeled Search subscriptions and Status controls, a Filters disclosure, Past due or ending/All subscriptions lens tabs and "Showing 3 subscriptions". The table now has Subscription/Status/Plan/Renews / ends/Ownership and tax columns with quiet identity links (a467006f). The "Renews / ends" instants stay masked. |
| subscriptions | dark | subscriptions-dark.png | changed: 1280x1198 to 1280x913, 431658 px (0.29) | mint run 40232864961 phase211-visual-baselines/visual-desktop/subscriptions-dark.png; subscriptions-dark-diff.png | intentional | receipt:66d5b3ce | - | Same redesign as light. The ratio is dominated by the 285 px shorter page (the old rows below 913 px count as differing on the dark background). Status pills, lens tab and inputs use dark tokens. |
| subscription-detail | light | subscription-detail.png | changed: 1280x1834 to 1280x1859, 177097 px (0.08) | mint run 40232864961 phase211-visual-baselines/visual-desktop/subscription-detail.png; subscription-detail-diff.png | intentional | receipt:b4a7eeac | - | b4a7eeac rewrote subscription_live (127 lines): the "SUBSCRIPTION DETAIL" fact strip and the green Lifecycle panel are replaced by an identity header card with an Active pill and the id; sentence-case evidence rows ("Billing evidence", "View events", "Unavailable" copy); the ACTIONS eyebrow is gone. Breadcrumb "Billing" (7e77a01f). The audit-summary line no longer repeats the instant, and the timeline instant moved inline with the event title (d122d53a). Related billing, Billing & items, Dunning & recovery and Raw JSON keep their baseline styling. The inline timeline instant is not masked in this composition, as before (see note). |
| subscription-detail | dark | subscription-detail-dark.png | changed: 1280x1834 to 1280x1859, 198256 px (0.09) | mint run 40232864961 phase211-visual-baselines/visual-desktop/subscription-detail-dark.png; subscription-detail-dark-diff.png | intentional | receipt:b4a7eeac | - | Same as light. The header card, evidence rows and audit card use dark tokens; nothing is unthemed. |
| component-kitchen | light | component-kitchen.png | byte-identical | mint run 40232864961 phase211-visual-baselines/visual-desktop/component-kitchen.png (byte-equal to committed) | unchanged | - | - | The minted PNG is byte-identical to the committed baseline, so there is nothing to classify or re-mint. |
| component-kitchen | dark | component-kitchen-dark.png | byte-identical | mint run 40232864961 phase211-visual-baselines/visual-desktop/component-kitchen-dark.png (byte-equal to committed) | unchanged | - | - | Byte-identical to the committed baseline. |

## Notes

- **No regressions found.** Every changed surface traces to the owner-feedback range (3d7d949d, 66d5b3ce, b4a7eeac),
  and the supporting detail traces to phase commits (246-*, 247-*). No `fix(250-04)` source fix was needed.
- **Pre-existing unmasked instant (not changed here):** subscription-detail's timeline instant was already unmasked in the
  committed `0197f4ba` baseline (`Oct 10, 2026 20:16 UTC`, twice). The plan prohibits adding masks, so the anchor set is
  unchanged. The varying glyphs are a few hundred pixels against a 1% budget of about 23.8k pixels on that full-page
  capture. This is recorded for the maintainer as a gate-precision follow-up rather than changed in this phase.
- **Observation for the maintainer:** on the invoices list (both themes), "Showing 3 invoices" now sits mid-width above
  the table, because b4a7eeac left the compact chip bar without chips. This is a consequence of the owner-feedback
  commit, so D4 classifies it as intentional; it is listed here in case the maintainer wants it right-aligned like
  subscriptions.
