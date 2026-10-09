# Phase 236 — UI Review

**Audited:** 2026-10-08
**Baseline:** Approved [236-UI-SPEC.md](236-UI-SPEC.md) and decisions in [236-CONTEXT.md](236-CONTEXT.md)
**Screenshots:** Not captured for the Portal. `localhost:8080` answered but served the Traefik dashboard; project-target desktop, mobile, and tablet captures were unavailable.
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Empty-state copy is contract-aligned, but dashboard recovery and payment-method failure copy remain vague. |
| 2. Visuals | 3/4 | Page structure encodes the specified anchors, but the 32px/700 dashboard metrics compete with the 26px/600 page heading; Portal screenshots were unavailable. |
| 3. Color | 3/4 | Semantic host colors remain in the shell and Hosted Fields now pass automated contrast assertions in default, forced-light, and forced-dark browser runs; live provider iframe appearance remains outside the mock. |
| 4. Typography | 2/4 | The stylesheet uses at least nine rendered sizes and weights 400/500/600/700 against the four-size, two-weight contract. |
| 5. Spacing | 2/4 | Repeated values such as 14px, 18px, 20px, and 28px diverge from the declared 4/8/16/24/32/48/64px scale. |
| 6. Experience Design | 3/4 | Served-browser tests cover secure-field contrast and lifecycle, but dashboard failures lack an in-page recovery action. |

**Overall: 16/24**

---

## Verification Evidence

- Fresh served-browser refresh on 2026-10-08: `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --workers=1` — **14 passed**. This covers all seven Portal routes, owner-scoped collections, theme/focus/reduced-motion/long-text behavior, Hosted Fields lifecycle, and cancellation confirmation/focus behavior. Chromium required browser process access; the successful run completed in 12.8s.
- The screenshot probe found `localhost:8080`, but its response identifies the Traefik dashboard, not the Portal. No screenshot from that endpoint was used as Portal evidence; the earlier missing-Portal-screenshot limitation remains.
- Default/system Hosted Fields browser matrix: **10 passed**.
- Host-forced light Hosted Fields matrix: **7 passed**.
- Host-forced dark Hosted Fields matrix: **7 passed**.
- These deterministic browser checks assert application-supplied Braintree styles against actual rendered field backgrounds, placeholder and invalid text, labels/help contrast, malformed-token fallbacks, theme refresh, context updates, nonce clearing, pending behavior, and teardown ordering.
- The SDK mock does not prove Braintree's live cross-origin iframe rendering. That is an explicit provider boundary in the plan and summary, not an outstanding human UAT request. The implementation does not claim that mock evidence establishes live-provider fidelity.
- Static screenshot probing against `localhost:8080` reached a Traefik 3.7.1 dashboard, so no screenshot from that service is used as Portal evidence. No valid Portal desktop/mobile/tablet captures were available.
- Human visual polish is not a roadmap acceptance gate. No subjective visual judgment is outstanding for Phase 236 acceptance; any optional brand-presentation review would be separate from the executable acceptance criteria.

---

## Top 3 Priority Fixes

1. **Make dashboard read failure actionable** — customers cannot recover from an unavailable dashboard read without reloading or navigating away — provide a safe retry or relevant route while keeping the unavailable state distinct from empty data.
2. **Align typography to the approved roles** — several type sizes and weights make metric values compete with the page anchor — map ordinary roles to 12/14/16/26px and 400/600, or amend the contract for a specifically justified display role.
3. **Normalize recurring spacing values** — off-scale values weaken the promised rhythm across shell, cards, and forms — replace recurring 14/18/20/28px gaps/padding with the approved scale or document bounded component exceptions in the contract.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **PASS evidence** — Home and collection empty-state strings match the contract: home “Welcome” / “You don't have a subscription yet.” (`accrue_portal/lib/accrue_portal/copy.ex:59-60`), subscription (`:65-69`), payment method (`:223-227`), and invoice (`:288-294`). Invoice copy avoids a retention guarantee.
- **WARNING** — Dashboard unavailable copy says “Billing data is unavailable. Try again later.” (`accrue_portal/lib/accrue_portal/copy.ex:57`); its unavailable subscription block has no retry or recovery link (`accrue_portal/lib/accrue_portal/live/home_live.ex:99-119`). Give the customer a concrete next step and an in-page retry or navigation action.
- **WARNING** — Payment-method failures use “Unable to delete payment method.” and “Unable to update default payment method.” (`accrue_portal/lib/accrue_portal/copy.ex:248-251`). The contract calls for denied changes to state that they were not submitted and provide a safe retry/navigation path. Use outcome-specific copy to distinguish denial from an uncertain provider result.
- **PASS evidence** — Secure-field tokenization errors name what to check and state that no payment was submitted on generic tokenization failure (`accrue_portal/priv/static/accrue_portal.js:270-279`).

### Pillar 2: Visuals (3/4)

- **WARNING** — The contract makes “Account overview” and billed-entity context the home anchor, with counts supporting it. Metric numerals render at 32px/700 (`accrue_portal/priv/static/accrue_portal.css:475-479`), above the 26px/600 h1 (`:299-305`), so count cards can compete with the page heading. Reduce metric emphasis or explicitly establish the intended display role in the contract.
- **WARNING** — The implementation has responsive reflow and long-value wrapping (`accrue_portal/priv/static/accrue_portal.css:652-752`), but no valid Phase 236 Portal screenshot was captured to inspect desktop/tablet/mobile hierarchy or the 320px layout visually. Existing automated browser assertions provide executable responsive/overflow coverage; the missing screenshot is an audit-evidence limitation, not a request for subjective UAT.
- **PASS evidence** — The billed identity wraps long values (`accrue_portal/lib/accrue_portal/layouts.ex:56-67`; `accrue_portal/priv/static/accrue_portal.css:41-60`), keyboard focus styles exist (`:416-425`), and the three theme controls have accessible names (`accrue_portal/lib/accrue_portal/layouts.ex:75-123`).

### Pillar 3: Color (3/4)

- **PASS evidence** — Portal surfaces, text, borders, and host actions use semantic tokens (`accrue_portal/priv/static/accrue_portal.css:14-18, 230-235, 381-408, 512-522`); the host theme bridge sanitizes configured accent/font values before emitting CSS (`accrue_portal/lib/accrue_portal/layouts.ex:182-219`). Statuses also have text labels and shape cues.
- **PASS evidence** — The prior fixed light-theme Hosted Fields palette has been replaced with computed field-background and semantic-token-derived values in `hostedFieldStyles` (`accrue_portal/priv/static/accrue_portal.js:364-412`). Current Playwright runs passed the 4.5:1 assertions for input, placeholder, invalid text, rendered labels, and help text for all three fields under default/system, forced-light, forced-dark, and malformed-token fallback cases (`examples/accrue_host/e2e/phase236-portal-self-service.spec.js:166-221`; focused matrix results above).
- **WARNING** — The deterministic SDK mock captures the style object supplied by the application; it cannot establish how the live cross-origin Braintree iframe paints those styles. This is the documented provider evidence boundary, not a failing phase acceptance claim or human UAT requirement (`236-06-SUMMARY.md`, key decision and verification notes).
- **WARNING** — Browser proof checks the secure-field and associated text contrast, but there is no reported ratio assertion for every host accent/focus boundary in every overall Portal theme. Keep semantic-role coverage and extend executable assertions only if a concrete token pairing remains unverified; do not reopen the passing Hosted Fields matrix without new evidence.

### Pillar 4: Typography (2/4)

- **WARNING** — The contract permits 12, 14, 16, and 26px with weights 400/600. The stylesheet uses 12, 13, 14, 15, 16, 17, 19, 26, and 32px equivalents: 13px billable identity (`accrue_portal/priv/static/accrue_portal.css:47-49`), 15px subtitle (`:326-329`), 19px h2 (`:307-312`), and 32px metric (`:475-479`) are examples. Consolidate to the declared roles or add approved exceptions to the contract.
- **WARNING** — Weights 400, 500, 600, and 700 are used: 500 appears on breadcrumbs and ordinary links (`accrue_portal/priv/static/accrue_portal.css:200, 215, 343-348`); 700 appears on the wordmark and metric (`:83-86, 475-479`). Restrict weights to 400/600 or define a supported exception.
- **PASS evidence** — Body line-height is 1.5 and embedded secure-field input text requests 16px (`accrue_portal/priv/static/accrue_portal.css:14-20`; `accrue_portal/priv/static/accrue_portal.js:364-392`).

### Pillar 5: Spacing (2/4)

- **WARNING** — The approved scale is 4/8/16/24/32/48/64px. Recurrent exceptions include 14px topbar padding (`accrue_portal/priv/static/accrue_portal.css:31-38`), 18px section margins and card/form gaps (`:218-247`), a 20px hero gap (`:290-295`), and 28px card padding (`:230-236`). Normalize these recurring values or document justified bounded exceptions.
- **WARNING** — Additional values include 10/12/14px control and error padding (`accrue_portal/priv/static/accrue_portal.css:598-627`) and responsive 18px checkout padding (`:702-708`). Audit package CSS as a set and map spacing to the approved scale consistently.
- **PASS evidence** — Narrow-layout and wrapping rules are present (`accrue_portal/priv/static/accrue_portal.css:652-752`). Served browser coverage recorded by Phase 05 asserts 320px overflow and long-text behavior; this review did not rerun those unchanged tests.

### Pillar 6: Experience Design (3/4)

- **WARNING** — Dashboard read failures render unavailable labels but provide no retry action (`accrue_portal/lib/accrue_portal/live/home_live.ex:99-119`). A customer cannot recover in place; add a safe retry or relevant navigation.
- **WARNING** — The phase-wide contract asks for polite status on routine outcomes and alert semantics for urgent errors. Payment-method unavailable reads use `role="status"` (`accrue_portal/lib/accrue_portal/live/payment_methods_live.ex:115-117`), while invoice read failures use `role="alert"` (`accrue_portal/lib/accrue_portal/live/invoices_live.ex:50-52`). Review urgency consistency and reserve assertive alerts for urgent failures.
- **PASS evidence** — Secure Hosted Fields interaction has fresh browser evidence: all three matrices passed; direct-route styles, contrast, malformed token fallbacks, pending/validation states, nonce clearing, retry ordering, stale-resource teardown failure, theme refresh, and page-exit teardown are asserted in `examples/accrue_host/e2e/phase236-portal-self-service.spec.js:166-432, 659-720`. The mock is deterministic and provider-independent.
- **PASS evidence** — Existing phase browser assertions cover theme, bright accents, keyboard focus, reduced motion, long text, seven served routes, and cancellation confirmation/focus behavior (`examples/accrue_host/e2e/phase236-portal-self-service.spec.js`; `236-05-SUMMARY.md`). Those unchanged checks were not rerun in this focused refresh, avoiding churn on verified coverage.

## Files Audited

- `.planning/phases/236-portal-billing-self-service/236-01-PLAN.md` through `236-06-PLAN.md`
- `.planning/phases/236-portal-billing-self-service/236-01-SUMMARY.md` through `236-06-SUMMARY.md`
- `.planning/phases/236-portal-billing-self-service/236-UI-SPEC.md`
- `.planning/phases/236-portal-billing-self-service/236-CONTEXT.md`
- `accrue_portal/lib/accrue_portal/copy.ex`
- `accrue_portal/lib/accrue_portal/layouts.ex`
- `accrue_portal/lib/accrue_portal/live/home_live.ex`
- `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex`
- `accrue_portal/lib/accrue_portal/live/subscription_live.ex`
- `accrue_portal/lib/accrue_portal/live/payment_methods_live.ex`
- `accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex`
- `accrue_portal/lib/accrue_portal/live/invoices_live.ex`
- `accrue_portal/lib/accrue_portal/live/checkout_live.ex`
- `accrue_portal/priv/static/accrue_portal.css`
- `accrue_portal/priv/static/accrue_portal.js`
- `examples/accrue_host/e2e/phase236-portal-self-service.spec.js`
- `examples/accrue_host/playwright.config.js`
- `.github/workflows/ci.yml` (Phase 236 browser matrix registration)
