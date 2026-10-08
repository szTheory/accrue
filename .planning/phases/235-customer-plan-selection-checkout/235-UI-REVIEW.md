# Phase 235 — UI Review

**Audited:** 2026-10-08 (refreshed after LiveView success redirect policy change)  
**Baseline:** Approved `235-UI-SPEC.md`  
**Screenshots:** Not captured — `http://localhost:8080` responded, but Playwright captures failed for desktop (1440×900), mobile (375×812), and tablet (768×1024); code-only audit  
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | The expired recovery action is now present, but unavailable-plan and hosted-handoff copy still diverge from the approved contract. |
| 2. Visuals | 3/4 | Source order separates plan facts, secure fields, and the payment action; rendered hierarchy could not be inspected after capture failures. |
| 3. Color | 2/4 | Portal surfaces/actions use semantic host tokens, while secure iframe text, error, and placeholder colors remain hard-coded. |
| 4. Typography | 2/4 | Portal CSS uses at least nine sizes and four weights; the contract allows four sizes and two weights. |
| 5. Spacing | 2/4 | Checkout CSS includes numerous non-scale values such as 6, 10, 12, 14, 18, 20, and 28px. |
| 6. Experience Design | 3/4 | LiveView completion now validates persisted success destinations and Braintree returns use scoped evidence; unavailable-plan state still lacks a fallback action when no recovery URL exists. |

**Overall: 14/24**

---

## Top 3 Priority Fixes

1. **Bring unavailable and handoff copy into contract** — customers receive less specific recovery guidance and the host handoff does not explain the secure checkout destination — render the contracted unavailable heading/body and label the provider handoff “Continue to secure checkout.” **WARNING**
2. **Theme Hosted Fields styles through the semantic bridge** — embedded payment text can clash with host themes and reduce contrast — pass computed text, danger, placeholder, and configured font values into Hosted Fields, then verify supported theme contrast. **WARNING**
3. **Normalize typography and checkout spacing to the declared tokens** — inconsistent scale weakens hierarchy and alignment across the payment summary and form — use the four declared type roles, two weights, and 4px-multiple spacing values while preserving the 40px control minimum. **WARNING**

---

## Detailed Findings

### Pillar 1: Copywriting (2/4)

- **WARNING:** The unavailable-terms state renders only “Plan details are unavailable, so payment cannot continue.” It omits the approved heading “Plan details unavailable,” the explanation that terms could not be verified, and the direction to return to the app and choose again. Its action is labeled “Return to billing” and appears only when a recovery URL exists, although the contract calls for “Return to your app” when validated and an existing safe fallback otherwise. [checkout_live.ex:328](../../../accrue_portal/lib/accrue_portal/live/checkout_live.ex:328)
- **WARNING:** The host handoff button still says “Continue with {plan}”; the approved hosted-provider action is “Continue to secure checkout.” The plan name is useful context, but the current wording does not identify the secure provider transition. [subscription_live.ex:661](../../../examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:661)
- **WARNING:** Expired checkout now correctly offers “Return to billing” (the old review's missing-action blocker is fixed), but the remaining body says to return to the account and start a new subscription instead of describing the actual billing recovery action. [checkout_live.ex:363](../../../accrue_portal/lib/accrue_portal/live/checkout_live.ex:363), [copy.ex:14](../../../accrue_portal/lib/accrue_portal/copy.ex:14)
- The mounted CTA is amount-aware (“Pay {verified amount}”), and the host return copy distinguishes canceled, pending, unavailable, and completed outcomes. The browser fixture-backed Braintree completion is not live-provider proof. [copy.ex:30](../../../accrue_portal/lib/accrue_portal/copy.ex:30), [subscription_live.ex:366](../../../examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:366)

### Pillar 2: Visuals (3/4)

- Source order establishes a sensible hierarchy: “Secure checkout” eyebrow and heading, selected plan/billed-to/charge summary, secure card fields, then one primary amount-aware payment action. Summary facts use separate definition-list rows and wrap long values. [checkout_live.ex:309](../../../accrue_portal/lib/accrue_portal/live/checkout_live.ex:309), [accrue_portal.css:227](../../../accrue_portal/priv/static/accrue_portal.css:227)
- The host return is a single status region with a distinct state message, and the plan handoff action is separate from the mounted Portal payment form. [subscription_live.ex:643](../../../examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:643)
- **WARNING:** The UI checker previously flagged that the primary visual anchor was not explicitly named in the contract. No screenshots could be inspected because all three Playwright captures failed, so focal balance, responsive composition, and actual host-theme rendering remain unverified. This score is based on markup/CSS structure only.

### Pillar 3: Color (2/4)

- Dominant page background, raised surfaces, body text, focus, and primary action map to `--accrue-*` roles and host accent tokens, consistent with the 60/30/10 hierarchy intent. [accrue_portal.css:14](../../../accrue_portal/priv/static/accrue_portal.css:14), [accrue_portal.css:345](../../../accrue_portal/priv/static/accrue_portal.css:345)
- **WARNING:** Hosted Fields iframe styles hard-code `#111418` for text, `#B42318` for invalid input, and `#5D6A73` for placeholders. These bypass active host theme values. The iframe font family is also fixed instead of using the configured host font. [accrue_portal.js:215](../../../accrue_portal/priv/static/accrue_portal.js:215)
- Accent use in Portal CSS is focused on links, focus, and primary actions rather than all controls. Because screenshots failed, actual accent contrast and 60/30/10 rendered surface balance remain unverified.

### Pillar 4: Typography (2/4)

- **WARNING:** Portal CSS contains at least nine distinct sizes: 12, 13, 14, 15, 16, 17, 19, 26, and 32px equivalents. The contract specifies only 12px metadata, 14px labels, 16px body/controls, and 26px page headings. Examples include 17px wordmark, 19px h2, 15px subtitle, 13px status, and 32px metric. [accrue_portal.css:47](../../../accrue_portal/priv/static/accrue_portal.css:47), [accrue_portal.css:271](../../../accrue_portal/priv/static/accrue_portal.css:271), [accrue_portal.css:290](../../../accrue_portal/priv/static/accrue_portal.css:290), [accrue_portal.css:410](../../../accrue_portal/priv/static/accrue_portal.css:410), [accrue_portal.css:419](../../../accrue_portal/priv/static/accrue_portal.css:419)
- **WARNING:** Portal CSS uses 400, 500, 600, and 700 weights, while the approved contract permits regular 400 and semibold 600. [accrue_portal.css:48](../../../accrue_portal/priv/static/accrue_portal.css:48), [accrue_portal.css:164](../../../accrue_portal/priv/static/accrue_portal.css:164), [accrue_portal.css:337](../../../accrue_portal/priv/static/accrue_portal.css:337)
- Hosted Fields' 16px/400 sizing matches the contract, but the fixed system font does not honor the host font mapping. [accrue_portal.js:218](../../../accrue_portal/priv/static/accrue_portal.js:218)

### Pillar 5: Spacing (2/4)

- **WARNING:** The checkout stylesheet departs from the contract's 4px-multiple scale: page/card uses 14px and 20px gutters and 28px padding; checkout groups use 18px; summary rows use 10px and 12px; and label/content gaps include 6px. At widths ≤360px summary padding is 12px and row gap 2px. Consolidate toward 4/8/16/24/32/48/64px. [accrue_portal.css:31](../../../accrue_portal/priv/static/accrue_portal.css:31), [accrue_portal.css:189](../../../accrue_portal/priv/static/accrue_portal.css:189), [accrue_portal.css:194](../../../accrue_portal/priv/static/accrue_portal.css:194), [accrue_portal.css:208](../../../accrue_portal/priv/static/accrue_portal.css:208), [accrue_portal.css:227](../../../accrue_portal/priv/static/accrue_portal.css:227), [accrue_portal.css:623](../../../accrue_portal/priv/static/accrue_portal.css:623)
- The 40px minimum button/control target is preserved. Responsive CSS stacks hosted fields and checkout actions, but screenshot failures prevented visual confirmation at the contract's 320px effective width. [accrue_portal.css:323](../../../accrue_portal/priv/static/accrue_portal.css:323), [accrue_portal.css:614](../../../accrue_portal/priv/static/accrue_portal.css:614)

### Pillar 6: Experience Design (3/4)

- **FIXED SINCE PRIOR REVIEW:** After `LocalSession.mark_completed/1` succeeds, the LiveView completion path now accepts valid local paths and HTTPS external destinations, sends unsafe values to the Portal home, and renders success in place when the URL is missing. Focused tests cover all four branches and verify persisted completion for the HTTPS, unsafe, and missing-URL cases; this aligns the LiveView redirect policy with the existing POST destination policy. [checkout_live.ex:124](../../../accrue_portal/lib/accrue_portal/live/checkout_live.ex:124), [checkout_live.ex:155](../../../accrue_portal/lib/accrue_portal/live/checkout_live.ex:155), [checkout_controller.ex:181](../../../accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex:181), [checkout_live_test.exs:246](../../../accrue_portal/test/accrue_portal/live/checkout_live_test.exs:246), [checkout_live_test.exs:316](../../../accrue_portal/test/accrue_portal/live/checkout_live_test.exs:316)
- **FIXED SINCE PRIOR REVIEW:** Expired open sessions now render a validated `@checkout_recovery_url` link labeled “Return to billing”; Plan 05 reports that unsafe cancel URLs resolve to the safe `/billing` fallback and that the expired view makes no payment request. [checkout_live.ex:363](../../../accrue_portal/lib/accrue_portal/live/checkout_live.ex:363), [235-05-SUMMARY.md](235-05-SUMMARY.md)
- **FIXED/EXPANDED SINCE PRIOR REVIEW:** Braintree successful returns now resolve the selected plan/selection locator to the current authorized organization, customer, and matching persisted `LocalSession`; only `completed` yields completion copy, while open/processing/uncertain stays pending and mismatches are unavailable. Plan 06's browser completion uses a fixture-backed session, not a live provider transaction. [subscription_live.ex:366](../../../examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:366), [235-06-SUMMARY.md](235-06-SUMMARY.md)
- The mounted checkout has distinct unavailable, denied, expired, completed, uncertain, promo, loading, card-error, and pending submission feedback. Status regions use ARIA live announcements; JS disables submission during tokenization and clears the nonce for uncertain transport failures. [checkout_live.ex:328](../../../accrue_portal/lib/accrue_portal/live/checkout_live.ex:328), [accrue_portal.js:121](../../../accrue_portal/priv/static/accrue_portal.js:121), [accrue_portal.js:255](../../../accrue_portal/priv/static/accrue_portal.js:255)
- **WARNING:** If trusted terms are unavailable and no validated recovery URL exists, the unavailable block renders no action. The design contract says to provide the existing safe fallback in that case. [checkout_live.ex:328](../../../accrue_portal/lib/accrue_portal/live/checkout_live.ex:328)
- Plan summaries report deterministic browser coverage for selection, mounted checkout, return states, keyboard focus, and narrow layouts, but no fresh browser interaction capture was made during this review. `workflow.ui_interaction_capture` was configured off.

## Files Audited

- `.planning/phases/235-customer-plan-selection-checkout/235-UI-SPEC.md`
- `.planning/phases/235-customer-plan-selection-checkout/235-CONTEXT.md`
- `.planning/phases/235-customer-plan-selection-checkout/235-01-PLAN.md` through `235-06-PLAN.md` and corresponding summaries
- `accrue_portal/lib/accrue_portal/live/checkout_live.ex`
- `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex`
- `accrue_portal/lib/accrue_portal/context.ex`
- `accrue_portal/lib/accrue_portal/copy.ex`
- `accrue_portal/priv/static/accrue_portal.css`
- `accrue_portal/priv/static/accrue_portal.js`
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`
- `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js`
- `accrue_portal/test/accrue_portal/live/checkout_live_test.exs`
- Prior `.planning/phases/235-customer-plan-selection-checkout/235-UI-REVIEW.md` (used only to identify stale claims; findings re-audited against current files)
