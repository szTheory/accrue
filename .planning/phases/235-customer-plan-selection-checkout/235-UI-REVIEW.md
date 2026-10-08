# Phase 235 — UI Review

**Audited:** 2026-10-08  
**Baseline:** Approved `235-UI-SPEC.md`  
**Screenshots:** Not captured — `http://localhost:8080` responded, but all three Playwright captures failed (desktop, mobile, tablet); code-only audit  
**Interaction captures:** off

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | Unavailable-plan copy omits the specified heading/body, and the hosted handoff action does not use its contracted label. |
| 2. Visuals | 3/4 | Checkout markup orders selected terms before secure fields and a single primary action; pixels could not be inspected because captures failed. |
| 3. Color | 2/4 | Portal CSS uses semantic tokens, but Hosted Fields iframe styles hardcode text, error, and placeholder colors. |
| 4. Typography | 2/4 | Portal CSS uses at least eight sizes and four weights, beyond the four-size/two-weight contract. |
| 5. Spacing | 2/4 | Checkout CSS uses multiple non-4px spacing values, including 6, 10, 14, 18, and 28px. |
| 6. Experience Design | 2/4 | Expired checkout shows instructions but no recovery link/action, blocking that recovery path. |

**Overall: 13/24**

---

## Top 3 Priority Fixes

1. **Add a safe recovery action to expired checkout** — customers with expired sessions have no actionable way to resume; render the validated recovery destination beside the expiry guidance. **BLOCKER**
2. **Bring unavailable and hosted-handoff copy into the contract** — customers see generic recovery wording and a different handoff action; render the exact unavailable heading/body and “Continue to secure checkout” on the hosted branch. **WARNING**
3. **Use host theme values for Hosted Fields and align Portal typography/spacing tokens** — the embedded fields can clash with host themes, while inconsistent type and spacing weaken scanability; pass computed semantic colors into the iframe and reduce the stylesheet to the declared sizes, weights, and 4px scale. **WARNING**

---

## Detailed Findings

### Pillar 1: Copywriting (2/4)

- **WARNING:** The unavailable-terms state is a paragraph, not the contracted heading “Plan details unavailable”; its body (“Plan details are unavailable, so payment cannot continue.”) differs from the specified recovery explanation and omits the app-selection direction. Use the contract’s heading/body and its conditional “Return to your app” action. [checkout_live.ex:328](../../../accrue_portal/lib/accrue_portal/live/checkout_live.ex:328)
- **WARNING:** The hosted handoff action says “Continue with {plan}” rather than “Continue to secure checkout.” This under-specifies the provider boundary and differs from the approved copy. [subscription_live.ex:526](../../../examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:526)
- The mounted action is amount-aware (`Pay {amount}`); errors and uncertainty include next steps, and no generic “Submit” CTA was found. [copy.ex:30](../../../accrue_portal/lib/accrue_portal/copy.ex:30)

### Pillar 2: Visuals (3/4)

- The mounted checkout has a readable order in markup: heading, selected plan/billable/charge summary, provider fields, then the primary action. Summary facts are separate `<dt>/<dd>` pairs and long values can wrap. [checkout_live.ex:309](../../../accrue_portal/lib/accrue_portal/live/checkout_live.ex:309), [accrue_portal.css:227](../../../accrue_portal/priv/static/accrue_portal.css:227)
- The visual contract’s primary anchor was not explicitly named by the UI checker, and no rendered captures were available to assess the actual focal hierarchy or spacing. Treat this pillar’s score as source-structure evidence only; no aesthetic handoff is required where browser assertions cover behavior.
- The hosted return state has an explicit status region, distinct from the mounted form, preserving the different provider journeys. [subscription_live.ex:516](../../../examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:516)

### Pillar 3: Color (2/4)

- Portal page surfaces, text, focus, actions, and errors are mostly mapped to `--accrue-*` semantic tokens, matching the host-brand bridge. [accrue_portal.css:14](../../../accrue_portal/priv/static/accrue_portal.css:14), [accrue_portal.css:345](../../../accrue_portal/priv/static/accrue_portal.css:345)
- **WARNING:** Hosted Fields iframe style values are fixed to `#111418`, `#B42318`, and `#5D6A73`; host theme changes do not reach the secure field’s text, invalid state, or placeholder. Derive these from the active theme bridge and verify contrast for supported themes. [accrue_portal.js:215](../../../accrue_portal/priv/static/accrue_portal.js:215)
- Accent appears restrained in the Portal checkout CSS, but actual host-theme contrast could not be visually verified without captures.

### Pillar 4: Typography (2/4)

- **WARNING:** The Portal stylesheet defines at least eight distinct sizes (including 12, 13, 14, 15, 16, 17, 19, 26, and 32px equivalents), while the contract declares only 12/14/16/26px roles. Examples include the 19px `h2`, 15px subtitle, 13px status, and 32px metric. [accrue_portal.css:47](../../../accrue_portal/priv/static/accrue_portal.css:47), [accrue_portal.css:263](../../../accrue_portal/priv/static/accrue_portal.css:263), [accrue_portal.css:290](../../../accrue_portal/priv/static/accrue_portal.css:290), [accrue_portal.css:429](../../../accrue_portal/priv/static/accrue_portal.css:429)
- **WARNING:** CSS uses weights 400 (base), 500, 600, and 700; the contract allows regular 400 and semibold 600. [accrue_portal.css:47](../../../accrue_portal/priv/static/accrue_portal.css:47), [accrue_portal.css:307](../../../accrue_portal/priv/static/accrue_portal.css:307), [accrue_portal.css:337](../../../accrue_portal/priv/static/accrue_portal.css:337)
- Hosted Fields sets its own 16px/400 values, which fit the contract, but it also fixes a system-font stack instead of inheriting the configured host font. [accrue_portal.js:218](../../../accrue_portal/priv/static/accrue_portal.js:218)

### Pillar 5: Spacing (2/4)

- **WARNING:** Checkout styles use values outside the declared spacing tokens, including 6/10/14/18px gaps or padding, plus 20px gutters and 28px card padding. Consolidate around the declared scale (4/8/16/24/32/48/64px), preserving the existing 40px control minimum. [accrue_portal.css:31](../../../accrue_portal/priv/static/accrue_portal.css:31), [accrue_portal.css:191](../../../accrue_portal/priv/static/accrue_portal.css:191), [accrue_portal.css:207](../../../accrue_portal/priv/static/accrue_portal.css:207), [accrue_portal.css:332](../../../accrue_portal/priv/static/accrue_portal.css:332)
- The summary uses 16px internal padding and mobile rules tighten the summary/action layout at 360px; structure supports the intended grouping, but layout could not be inspected in pixels. [accrue_portal.css:207](../../../accrue_portal/priv/static/accrue_portal.css:207), [accrue_portal.css:623](../../../accrue_portal/priv/static/accrue_portal.css:623)

### Pillar 6: Experience Design (2/4)

- **BLOCKER:** Expiry renders “Return to your account and start a new subscription” but does not render `@checkout_recovery_url` or another action in that state. A customer who reaches an expired link cannot follow the instructed recovery path. Add the validated recovery action next to the expiry message. [checkout_live.ex:363](../../../accrue_portal/lib/accrue_portal/live/checkout_live.ex:363), [copy.ex:14](../../../accrue_portal/lib/accrue_portal/copy.ex:14)
- **WARNING:** The checkout has distinct terms-unavailable, denied, expired, completed, uncertain, promo, and card feedback regions. Pending/tokenization and uncertain states use status/live-region announcements; failure paths disable replay and keep recovery guidance visible. [checkout_live.ex:328](../../../accrue_portal/lib/accrue_portal/live/checkout_live.ex:328), [accrue_portal.js:121](../../../accrue_portal/priv/static/accrue_portal.js:121), [accrue_portal.js:255](../../../accrue_portal/priv/static/accrue_portal.js:255)
- Phase summaries report deterministic browser coverage for selection/sign-in, mock-SDK submission/recovery, hosted returns, served assets, focus/status, long text, and 320px layout; the test suite was not rerun for this advisory review. The interaction capture workflow was configured off, so there are no interaction screenshots to assess.

## Files Audited

- `.planning/phases/235-customer-plan-selection-checkout/235-UI-SPEC.md`
- `.planning/phases/235-customer-plan-selection-checkout/235-01-PLAN.md` through `235-04-PLAN.md` and corresponding summaries
- `.planning/phases/235-customer-plan-selection-checkout/235-CONTEXT.md`
- `accrue_portal/lib/accrue_portal/live/checkout_live.ex`
- `accrue_portal/lib/accrue_portal/copy.ex`
- `accrue_portal/priv/static/accrue_portal.css`
- `accrue_portal/priv/static/accrue_portal.js`
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`
- `examples/accrue_host/lib/accrue_host_web/controllers/page_html/pricing.html.heex`
- `examples/accrue_host/lib/accrue_host_web/components/layouts/root.html.heex`
- `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js`
