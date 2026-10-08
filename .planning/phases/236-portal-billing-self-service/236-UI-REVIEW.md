# Phase 236 — UI Review

**Audited:** 2026-10-08
**Baseline:** Approved [236-UI-SPEC.md](236-UI-SPEC.md) and decisions in [236-CONTEXT.md](236-CONTEXT.md)
**Screenshots:** Not captured (server at `http://localhost:8080` answered, but Playwright failed for desktop 1440×900, mobile 375×812, and tablet 768×1024; code-only audit)
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Main empty-state copy matches; dashboard read failures offer no retry action. |
| 2. Visuals | 3/4 | Home metric numerals are styled larger than the page heading, weakening the specified heading-first hierarchy. |
| 3. Color | 2/4 | Hosted Fields use hard-coded light-theme colors instead of host semantic/theme colors. |
| 4. Typography | 2/4 | CSS uses more than the four specified sizes and two weights, including 32px/700 metric numerals. |
| 5. Spacing | 2/4 | Multiple layout values (14, 18, 20, 28px) fall outside the declared spacing scale. |
| 6. Experience Design | 3/4 | State handling and confirmations are strong, but dashboard failures have no safe recovery action and visual interaction proof is unavailable. |

**Overall: 15/24**

---

## Top 3 Priority Fixes

1. **Theme Hosted Fields from host tokens and active color scheme** — card entry text and placeholder contrast can fail in host dark/custom themes — derive the Hosted Fields foreground, placeholder, and invalid colors from the same semantic theme roles used by the Portal.
2. **Bring typography back to the approved four sizes and two weights** — metric values and labels create hierarchy that diverges from the contract — map page heading/body/label/metadata and weights to 26/16/14/12px and 600/400; remove or explicitly contract any additional display role.
3. **Make dashboard read failures actionable** — customers cannot recover from a failed subscription read from the dashboard — add a safe retry or relevant navigation link while retaining the unavailable state and never rendering it as empty.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **PASS evidence** — The core home and collection empty-state strings match the contract: home “Welcome” / “You don't have a subscription yet.” (`accrue_portal/lib/accrue_portal/copy.ex:59-60`), subscription empty text (`:65-69`), payment method empty text (`:223-227`), and invoice empty text/next step (`:288-294`). The invoice empty state also avoids a retention promise.
- **WARNING** — Dashboard unavailable copy only says “Billing data is unavailable. Try again later.” (`accrue_portal/lib/accrue_portal/copy.ex:57`), while the subscription unavailable block renders no retry or recovery link (`accrue_portal/lib/accrue_portal/live/home_live.ex:99-103`). Replace “later” with a concrete safe next step and expose a retry/navigation action.
- **WARNING** — Payment method operation failures are generic (“Unable to delete payment method.” / “Unable to update default payment method.”; `accrue_portal/lib/accrue_portal/copy.ex:248-251`). They do not say that the change was not submitted as the contract asks for denied changes (`236-UI-SPEC.md`, Copywriting Contract). Use outcome-specific copy that distinguishes denial from uncertainty.
- **NEEDS HUMAN JUDGMENT** — “Switch account” is rendered when `switch_path` exists (`accrue_portal/lib/accrue_portal/layouts.ex:61-67`). Whether the host-provided destination makes the selected billing context clear is content/context dependent and could not be judged without the rendered host flow. Confirm its accessible name and destination context with a configured host.

### Pillar 2: Visuals (3/4)

- **WARNING** — The home contract says “Account overview” and billed-entity context lead, with counts supporting them. The metric number style is 32px and weight 700 (`accrue_portal/priv/static/accrue_portal.css:475-481`), larger/heavier than the 26px h1 (`:299-305`), so the three count cards can compete with the page anchor. Reduce metric emphasis. **NEEDS HUMAN JUDGMENT:** confirm the resulting page hierarchy in rendered captures.
- **WARNING** — Static captures did not succeed, so actual focus appearance, host-branded layout, and desktop/mobile/tablet hierarchy could not be inspected. The responsive CSS reflows navigation and hero at 700px (`accrue_portal/priv/static/accrue_portal.css:677-723`), but code alone does not establish the 320px contract for actual content and host themes.
- **PASS evidence** — Topbar retains the billed identity and wraps long values (`accrue_portal/lib/accrue_portal/layouts.ex:56-67`, `accrue_portal/priv/static/accrue_portal.css:41-60`); keyboard focus selectors are present (`accrue_portal/priv/static/accrue_portal.css:416-425`). Theme-picker controls have accessible names (`accrue_portal/lib/accrue_portal/layouts.ex:75-121`).

### Pillar 3: Color (2/4)

- **PASS evidence** — The main stylesheet uses host semantic surface, ink, border, accent, and status tokens (`accrue_portal/priv/static/accrue_portal.css:14-18, 230-235, 381-408, 512-522`), and links/primary actions use accent roles rather than spreading accent across all controls. Statuses also have text labels in the Portal markup and shape cues in CSS.
- **WARNING** — Hosted Fields override that system with fixed `#111418`, `#B42318`, and `#5D6A73` (`accrue_portal/priv/static/accrue_portal.js:267-281`). This ignores configured host palette and active light/dark/system theme; the contract explicitly requires secure-field labels/help/errors to remain legible across these themes. Use validated semantic theme values and verify contrast against bright host accents.
- **WARNING** — Color contrast against arbitrary configured host accents is not established by source inspection or captured rendering. Theme role mapping exists in the layout (`accrue_portal/lib/accrue_portal/layouts.ex:182-198`), but there is no evidence here that the effective accent text/contrast bridge meets 4.5:1 for normal text and 3:1 for focus boundaries across host themes.

### Pillar 4: Typography (2/4)

- **WARNING** — The contract permits four sizes (12, 14, 16, 26px) and weights 400/600. The stylesheet uses at least 12, 13, 14, 15, 16, 17, 19, 26, and 32px equivalents; examples include 13px billable identity (`accrue_portal/priv/static/accrue_portal.css:47-49`), 15px subtitle (`:326-329`), 19px h2 (`:307-312`), and 32px metric (`:475-479`). Consolidate to the declared roles or amend the contract with approved exceptions.
- **WARNING** — Weights 400, 500, 600, and 700 are present: inline Hosted Fields use 400 (`accrue_portal/priv/static/accrue_portal.js:270-274`), links use 500 (`accrue_portal/priv/static/accrue_portal.css:343-348`), and the wordmark/metrics use 700 (`:83-86`, `:475-479`). Restrict styles to 400/600 per the contract.
- **PASS evidence** — Body line height is 1.5 and ordinary Portal controls inherit body sizing; the embedded field input explicitly requests 16px (`accrue_portal/priv/static/accrue_portal.css:14-20`, `accrue_portal/priv/static/accrue_portal.js:267-275`).

### Pillar 5: Spacing (2/4)

- **WARNING** — The scale is xs 4, sm 8, md 16, lg 24, xl 32, 2xl 48, 3xl 64px. The stylesheet adds recurring off-scale values: 14px topbar padding (`accrue_portal/priv/static/accrue_portal.css:31-38`), 18px section margins and card gaps (`:220-236`, `:244-247`), 20px hero gap (`:290-295`), and 28px card padding (`:230-236`). Normalize these to scale values (or document bounded exceptions) to maintain consistent rhythm.
- **WARNING** — Responsive card padding adds another 18px exception (`accrue_portal/priv/static/accrue_portal.css:702-708`); checkout and inline errors use 12/14px values (`:249-256`, `:620-627`). These are not shown to be mapped to package-local authoritative tokens. Audit the complete spacing set and use the local mapping consistently.
- **PASS evidence** — The layout includes narrow-screen rules and long-content wrapping (`accrue_portal/priv/static/accrue_portal.css:652-752`), but no screenshot was captured to verify the 320 CSS px acceptance condition.

### Pillar 6: Experience Design (3/4)

- **WARNING** — Home dashboard read failures produce “Subscriptions unavailable” and unavailable metric labels (`accrue_portal/lib/accrue_portal/live/home_live.ex:99-119`) with no retry action. A customer cannot recover without leaving/reloading the page; provide an explicit, safe retry or navigation path.
- **WARNING** — Payment-method unavailable reads use `role="status"` / polite live announcements (`accrue_portal/lib/accrue_portal/live/payment_methods_live.ex:115-117`), while invoice read failures use `role="alert"` (`accrue_portal/lib/accrue_portal/live/invoices_live.ex:50-52`). Confirm routine unavailable reads are consistently announced at the intended urgency; reserve alert for urgent errors.
- **WARNING** — Screenshot/interaction proof is absent: static Playwright attempts failed at all three required viewports, and interaction capture is configured off. Thus keyboard confirmation behavior, actual focus movement, 320px overflow, reduced motion, theme patches, and announcements remain code-derived rather than observed in this audit.
- **PASS evidence** — The implementation distinguishes successful-empty and unavailable reads, provides explicit cancellation confirmations with Escape handling and focus restoration (`accrue_portal/lib/accrue_portal/live/subscriptions_live.ex:28-64, 114-123`; `subscription_live.ex:65-104`), disables secure submit until fields are available (`add_payment_method_live.ex:116-130`), and has reduced-motion CSS (`accrue_portal/priv/static/accrue_portal.css:755-762`). These patterns support a 3 rather than a lower score.

## Files Audited

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
