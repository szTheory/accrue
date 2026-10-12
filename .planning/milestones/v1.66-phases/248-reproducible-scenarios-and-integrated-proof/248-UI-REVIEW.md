---
phase: "248"
slug: "reproducible-scenarios-and-integrated-proof"
status: complete
audited: "2026-10-12"
baseline: "248-UI-SPEC.md evidence-only rendered proof contract"
---

# Phase 248 — UI Review

**Audited:** 2026-10-12  
**Baseline:** `248-UI-SPEC.md`, `248-CONTEXT.md`, `248-PROOF.md`, and `248-COVERAGE.md`. Phase 248 adds no production UI; this review scores only the eight supplied current images and their evidence boundaries.  
**Screenshots:** Existing Phase 248 set reviewed at original resolution (eight images, 1280×900 and 320×820, light and dark); no new captures. Their manifest attribution remains source `5548e3fd60d31f256c6bfd5322883066855cc872`, with the recorded served CSS/JS digests.  
**Interaction captures:** off (`interaction_capture=false`). No keyboard, pointer, touch, owner acceptance, or accessibility conformance is inferred from static images. A later guard/config correction has its separately recorded three-test result; it does not alter image/source attribution.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | The empty-state heading is visible, but its explanatory body falls below the wide viewport; the global open-invoice context competes with the zero-subscription message. |
| 2. Visuals | 2/4 | The invoice drawer hides the record identity/status, while the narrow boundary page repeats an oversized long name above the detail card. |
| 3. Color | 3/4 | Light/dark surfaces and semantic status/accent use read consistently; simultaneous blue outlines around the content frame and search control compete visually. |
| 4. Typography | 3/4 | Most labels and headings remain distinct and legible; the repeated long-name heading dominates the narrow boundary viewport. |
| 5. Spacing | 3/4 | The drawer and major cards fit their declared widths, but the repeated long identity consumes excessive narrow-screen height. |
| 6. Experience Design | 2/4 | The images show safe review states, but they do not cover the contract’s integrated changed surfaces or establish interaction, role, or accessibility behavior. |

**Overall: 15/24**

## Top 3 Priority Fixes

1. **WARNING — Keep record context in the ordinary action-review image** — The invoice drawer covers the underlying record, so the image does not show the contract-required identity and status alongside the staged action. Capture a review state that retains a visible invoice identifier/status, or include a paired unobscured detail image and link both to the same route/state evidence.
2. **WARNING — Make the empty-state proof image show the complete empty message** — The 1280×900 image reaches the “No subscriptions yet” heading at the bottom edge, with its body cut off; the narrow image ends before the empty state. Adjust the reviewed scroll position or use a focused crop so the heading, explanation, zero-row context, and relevant next step are visible together.
3. **WARNING — Close the changed-surface visual evidence gap** — The required integrated sample is absent for Search, Coupons, Connect, Promotion codes, Events, Recovery, Payments, invoice filters, Subscriptions detail/F03, and Connect F05. Add current revision-bound images and matching interaction evidence before treating those findings as visually reviewed.

## Detailed Findings

### Pillar 1: Copywriting (2/4)

- **WARNING — UI248-01:** The empty subscription capture visibly says “No subscriptions yet.”, but its supporting copy is cut off at the bottom of the wide viewport and absent from the narrow capture. The displayed “Action required”, “Open invoice queue”, and “1 open invoice” context competes with the zero-subscription message. The mounted test and manifest establish a genuine unfiltered zero-record scenario, but these images do not expose the complete empty-state explanation or establish how operators interpret the surrounding queue context. See [wide empty capture](captures/phase248-current-proof/heldout-empty-subscriptions-wide-light.png) and [narrow empty capture](captures/phase248-current-proof/heldout-empty-subscriptions-narrow-dark.png).
- The failure page’s visible copy qualifies the outcome: “Dead” is shown, replay queues another attempt, and queue acceptance does not confirm processing. The invoice drawer’s “Review the staged invoice action before confirming it.” also states its review boundary. These are positive observations of displayed copy, not proof of feedback after submission.
- The contract says Phase 248 adds no product copy. The image set supports that bounded review; no new CTA or product string is claimed.

### Pillar 2: Visuals (2/4)

- **WARNING — UI248-02:** In both ordinary invoice images, the open drawer occupies the right half of desktop or the lower mobile viewport and obscures the underlying invoice title/status. The staged action is the focal point, but the image alone cannot connect it to the record whose action is being reviewed. The manifest records that identity was asserted in the mounted test; that assertion does not replace the requested visible identity/status evidence. See [wide invoice review](captures/phase248-current-proof/ordinary-ordinary-invoice-review-wide-light.png) and [narrow invoice review](captures/phase248-current-proof/ordinary-ordinary-invoice-review-narrow-dark.png).
- **WARNING — UI248-03:** The narrow customer boundary view repeats the long customer name in the breadcrumb/header and the customer detail card. The large card heading wraps correctly without horizontal clipping, but the repeated heading fills much of the viewport and delays access to the detail fields. See [narrow boundary capture](captures/phase248-current-proof/heldout-long-name-boundary-narrow-light.png).
- The webhook detail has a clear event title, observed “Dead” status, and replay explanation/action hierarchy. Empty-state cards and customer-detail surfaces remain visually distinct. These observations apply to the displayed states only.

### Pillar 3: Color (3/4)

- **WARNING — UI248-04:** Blue outlines are visible around the main content region and the Search billing control in the supplied captures. Their simultaneous emphasis competes for attention; the static images do not establish whether either outline is a keyboard-focus state. Review the initial and keyboard-focused states separately before changing focus styling.
- Light and dark samples retain clear canvas/card separation. Blue is concentrated on primary actions and selected navigation, while the webhook’s amber “Dead” treatment remains paired with text. This is a qualitative impression of eight images, not a measured 60/30/10 pixel audit or a contrast/accessibility result.

### Pillar 4: Typography (3/4)

- **WARNING — UI248-05:** On the 320px customer page, the long Unicode name wraps and remains within the viewport, but it appears twice and the large detail heading consumes a substantial vertical portion of the image. Consider keeping a compact breadcrumb label while reserving the full exact identity for the detail heading.
- The supplied states preserve a useful hierarchy between route headings, section labels, supporting copy, and exact values. This review did not infer font-token compliance from screenshots; the captured long-content sample is the notable hierarchy strain.

### Pillar 5: Spacing (3/4)

- **WARNING — UI248-06:** Wide invoice review and narrow bottom-sheet contents fit within the viewport width, and the long customer name wraps without horizontal overflow. However, repeated identity content causes avoidable vertical density in the narrow boundary sample, and the empty-state body is below the captured viewport. Keep the compact breadcrumb and capture the complete empty explanation in the visible review frame.
- The set uses the specified wide/narrow dimensions. A pair of viewport screenshots does not demonstrate the full incumbent spacing-token scale or every breakpoint.

### Pillar 6: Experience Design (2/4)

- **WARNING — UI248-07:** The images show a staged invoice review with no submitted action and a webhook retry affordance with no replay submitted. They do not show focus movement, keyboard activation, touch behavior, confirmation/close transitions, or post-action feedback; no interaction quality is concluded from these states.
- **WARNING — UI248-08:** Current images do not cover Search, Coupons, Connect, Promotion codes, Events, Recovery, Payments, invoice collection filters, populated Subscriptions detail/F03, or the Connect filtered-zero/F05 state. The [coverage ledger](248-COVERAGE.md) and [proof ledger](248-PROOF.md) preserve these gaps and historical evidence separately. Phase 246/247 owning checks remain recorded results, not current visual or interaction proof.
- The mounted evidence records scenario/route assertions, zero underlying subscription rows, no action submission, and narrow page dimensions for the boundary fixture. This review does not infer owner acceptance, authorization across roles, or accessibility conformance from those assertions or the screenshots.

## Registry Safety

`components.json` is absent, and `248-UI-SPEC.md` declares no shadcn or third-party registry. Registry audit is not applicable.

## Files Audited

- `.planning/phases/248-reproducible-scenarios-and-integrated-proof/248-01-PLAN.md`, `248-01-SUMMARY.md`, `248-02-PLAN.md`, and `248-02-SUMMARY.md`
- `.planning/phases/248-reproducible-scenarios-and-integrated-proof/248-UI-SPEC.md`, `248-CONTEXT.md`, `248-PROOF.md`, `248-COVERAGE.md`, and `captures/phase248-current-proof/manifest.json`
- All eight PNGs in `captures/phase248-current-proof/`, inspected at original resolution
- `accrue_admin/lib/accrue_admin/copy/subscription.ex`, `accrue_admin/lib/accrue_admin/copy/invoice.ex`, `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`, `accrue_admin/lib/accrue_admin/live/webhook_live.ex`, `accrue_admin/assets/css/app.css`, and `accrue_admin/assets/css/theme.css` for displayed copy/token context
- `examples/accrue_host/e2e/phase248-scenarios.spec.js` for the recorded scenario assertions
