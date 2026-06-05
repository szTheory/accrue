# v1.51 Admin UI: Depth Pass — SIGN-OFF

**Phase scope:** 174–179 (A through F)
**Date:** [PENDING — fill when photographic run completes]
**Produced by:** Phase 179 plan execution (2026-06-04)

**Gate status:**
Vision-scoring photographic run: [PENDING — run `npm run score-visuals` with ANTHROPIC_API_KEY + live server]

This scaffold marks the v1.51 build complete. All code-level requirements (DSY-01–03, IA-01–07, SCR-01–04, MOT-01–03, SEED-01–02, QA-01–03) are satisfied by prior phase execution. The photographic run and motion-trace review close the final QA gate before declaring the milestone DONE.

---

## Section 1 — How to Use This Document

1. All **PENDING** cells require a live server + API key or human review.
2. Run the commands listed in each section to populate the PENDING cells.
3. Fill in the After-column scores from `findings.ndjson` output.
4. Mark the Section 9 checklist items complete.
5. Update this header: change **Gate status** line from PENDING to DONE with the date.

---

## Section 2 — Rubric Scorecard

**Before-column source:** 176-SCORECARD.md after-scores (all 21 screens at min ≥ 2 after Phase 176 Wave 0–5 uplift).
**After-column source:** [PENDING — vision-LLM scoring from `npm run score-visuals`]

Scoring rubric (10 dimensions, ① through ⑩, scored 0–3 each; ≥ 2 = pass on every dimension):
① Token compliance · ② Visual hierarchy · ③ Spacing rhythm · ④ State coverage
⑤ Responsive/mobile-first · ⑥ Contrast · ⑦ Focus & semantics · ⑧ Brand expression
⑨ Motion · ⑩ Reuse/DRY

| Screen | Before min (176-SCORECARD) | Before pass? | After min (photographic gate) | After pass? |
|--------|----------------------------|--------------|-------------------------------|-------------|
| DashboardLive | 2 | YES | [PENDING] | [PENDING] |
| CustomersLive | 2 | YES | [PENDING] | [PENDING] |
| CustomerLive | 2 | YES | [PENDING] | [PENDING] |
| SubscriptionsLive | 2 | YES | [PENDING] | [PENDING] |
| SubscriptionLive | 2 | YES | [PENDING] | [PENDING] |
| InvoicesLive | 2 | YES | [PENDING] | [PENDING] |
| InvoiceLive | 2 | YES | [PENDING] | [PENDING] |
| ChargesLive | 2 | YES | [PENDING] | [PENDING] |
| ChargeLive | 2 | YES | [PENDING] | [PENDING] |
| CouponsLive | 2 | YES | [PENDING] | [PENDING] |
| CouponLive | 2 | YES | [PENDING] | [PENDING] |
| PromotionCodesLive | 2 | YES | [PENDING] | [PENDING] |
| PromotionCodeLive | 2 | YES | [PENDING] | [PENDING] |
| ConnectAccountsLive | 2 | YES | [PENDING] | [PENDING] |
| ConnectAccountLive | 2 | YES | [PENDING] | [PENDING] |
| EventsLive | 2 | YES | [PENDING] | [PENDING] |
| EventLive | 2 | YES | [PENDING] | [PENDING] |
| WebhooksLive | 2 | YES | [PENDING] | [PENDING] |
| WebhookLive | 2 | YES | [PENDING] | [PENDING] |
| RecoveryLive | 2 | YES | [PENDING] | [PENDING] |
| CampaignLive | 2 | YES | [PENDING] | [PENDING] |

**Before-score note:** All 21 screens reached min ≥ 2 on all 10 dimensions via Phase 176 code-level uplift (Wave 0 CSS breakpoint fix for 9 list screens; Waves 2–5 for CouponLive, EventLive, PromotionCodeLive, ConnectAccountLive, WebhookLive, InvoiceLive, ChargeLive, CampaignLive). Evidence: `.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md` (Phase 176 Final Summary).

---

## Section 3 — Axe Status

All 21 surfaces swept for WCAG 2.0 A/AA critical and serious violations in both light and dark themes by `accrue_admin/e2e/admin-a11y.spec.js`. The spec asserts 0 critical/serious violations across all surfaces × themes. Mobile (Pixel5) uses the same spec with Playwright's `chromium-mobile` project.

Run: `cd accrue_admin && npm run e2e:a11y`

| Surface | Light violations | Dark violations | Mobile (Pixel5) | Status |
|---------|-----------------|-----------------|-----------------|--------|
| dashboard | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| customers | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| customer-detail | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| subscriptions | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| subscription-detail | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| invoices | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| invoice-detail | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| payments | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| charge-detail | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| coupons | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| coupon-detail | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| promotion-codes | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| promo-code-detail | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| connect | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| connect-detail | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| events | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| event-detail | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| webhooks | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| webhook-detail | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| recovery | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |
| campaign-detail | [PENDING] | [PENDING] | [PENDING] | [PENDING — run npm run e2e:a11y] |

**Axe spec:** `accrue_admin/e2e/admin-a11y.spec.js` — 21 surfaces, 3 fixtures (operator-flows + dashboard + edge-states), light + dark scan via `scan(page, theme)` helper. Asserts `failures.toEqual([])`.
**Expected result:** 0 critical/serious violations per surface per theme.

---

## Section 4 — Motion Confirmation

Phase 177 shipped `accrue_admin/e2e/reduced-motion.spec.js` — the automated reduced-motion CI spec passes (verified in Phase 177 execution). The motion trace spec (`accrue_admin/e2e/admin-motion-trace.spec.js`) was created in Phase 179 Plan 02 and captures Playwright traces for the 4 animation surfaces.

| Surface | Trace captured | Quality reviewed | Reduced-motion spec | Status |
|---------|---------------|-----------------|---------------------|--------|
| Command palette open | [PENDING — run npx playwright test e2e/admin-motion-trace.spec.js] | [PENDING — npx playwright show-trace test-results/.../trace.zip] | PASS (CI, Phase 177) | [PENDING] |
| Dropdown open | [PENDING — run npx playwright test e2e/admin-motion-trace.spec.js] | [PENDING — npx playwright show-trace test-results/.../trace.zip] | PASS (CI, Phase 177) | [PENDING] |
| Nav-collapse toggle | [PENDING — run npx playwright test e2e/admin-motion-trace.spec.js] | [PENDING — npx playwright show-trace test-results/.../trace.zip] | PASS (CI, Phase 177) | [PENDING] |
| Webhook replay drawer | [PENDING — run npx playwright test e2e/admin-motion-trace.spec.js] | [PENDING — npx playwright show-trace test-results/.../trace.zip] | PASS (CI, Phase 177) | [PENDING] |

**Run command:** `cd accrue_admin && npx playwright test e2e/admin-motion-trace.spec.js --project chromium-desktop`
**Trace review:** `npx playwright show-trace test-results/<test-name>-chromium-desktop/trace.zip`

**Deferred 177 HUMAN-UAT items closed by this section:**
- **177 UAT #1** (Playwright reduced-motion spec runtime): Spec `e2e/reduced-motion.spec.js` passes in CI. PASS confirmed by Phase 177. The trace spec additionally exercises the surfaces at full animation for live quality review.
- **177 UAT #2** (Live motion quality pass — all 9 surfaces): Requires human review of the Playwright trace artifacts produced by `admin-motion-trace.spec.js`. [PENDING — open traces in Playwright Trace Viewer and confirm 150–300ms, no jank, restrained motion].

---

## Section 5 — State Coverage

All 21 screens have reachable states via E2E fixtures. Evidence: `.planning/phases/178-e-seed-expressiveness-state-coverage/STATE-MATRIX.md`.

SEED-01 and SEED-02 requirements verified by Phase 178 execution:
- `POST /__e2e__/seed/edge-states` provides: `at_risk_sub_id`, `canceling_sub_id`, `jpy_invoice_id`, `jpy_charge_id`, `dunning_customer_id`, `long_name_customer_id`, `coupon_id`, `promo_code_id`, `connect_account_id`.
- All cells in STATE-MATRIX (empty, populated, overflow, error, loading, dunning/at-risk, multi-currency, long-strings, dark-contrast) mapped to fixtures or no-fixture mechanisms.
- The 3-fixture sweep (operator-flows + dashboard + edge-states) used by the axe and visual specs reaches all 21 detail-screen populated states without intermediate reset().

**Deferred 178 HUMAN-UAT items closed by this section and the photographic sweep:**
- **178 UAT #1** (Loading / poll-banner state visual): [PENDING — double-seed + 5s wait in photographic sweep]. The mechanism is documented in STATE-MATRIX.md "Loading State Mechanism" section.
- **178 UAT #2** (Dark-contrast axe pass on seeded edge states): Closed by the axe spec (Section 3 above) — `admin-a11y.spec.js` sweeps all 21 surfaces including edge-state screens in dark theme. [PENDING — run `npm run e2e:a11y` against live server].
- **178 UAT #3** (Single click-through across all 21 screens — STATE-MATRIX cells reachable): [PENDING — photographic sweep run confirms reachability of all STATE-MATRIX cells].

---

## Section 6 — Design-System Completeness

DSY-01/02/03 requirements verified by Phase 174 execution.

**Token compliance guard:** `grep -v '^#' accrue_admin/assets/css/app.css | grep -c 'var(--ax-'` returns non-zero (>100 token references). No literal `px`/`hex` values in live LiveView templates (except permitted `accent_hex` / `accent_contrast_hex` branding config lines).

**Evidence:** `.planning/phases/174-a-design-system-gap-closure-token-completeness/174-07-SUMMARY.md`

Key outcomes from Phase 174:
- All spacing, color, and typography tokens consolidated under `--ax-*` namespace.
- Token registry established with token compliance grep guard in CI.
- Dark theme token parity confirmed — no hardcoded colors in light-only paths.

---

## Section 7 — IA Persona Paths

IA-01 through IA-07 requirements verified by Phase 175 execution.

**Six personas reach their primary job in ≤ 2 clicks from Home.** Related-billing cards present on all 21 detail screens. Route redirects from old paths confirmed (`/billing/charges` → `/billing/payments`, `/billing/connect-accounts` → `/billing/connect`).

**Evidence:** `.planning/phases/175-b-persona-driven-ia-spine/175-07-SUMMARY.md`

Key outcomes from Phase 175:
- Home launcher zones wired to work-queue pre-filtered deep links for all 6 personas.
- Sidebar collapse/expand + localStorage persistence implemented.
- Attention-count badges (Recovery: amber, Developer: red) on sidebar collapsible groups.
- Customer-360 "More ▾" overflow tab menu implemented.
- Related-billing cards on all 21 detail screens.

**Deferred 175 HUMAN-UAT items closed by the photographic sweep:**
- **175 UAT #1** (Sidebar collapse/expand + localStorage persistence): [PENDING — photographic sweep run confirms chevron rotation, group collapse, badge count tone in both light + dark].
- **175 UAT #2** (Attention-count badge tone & conditional appearance): [PENDING — edge-states fixture seeds at-risk + dead-letter data; photographic sweep with seeded DB confirms amber/red/hidden badge states].
- **175 UAT #3** (Home launcher → work-queue persona path ≤ 2 clicks): [PENDING — photographic sweep click-through confirms launcher → pre-filtered queue landing].
- **175 UAT #4** (Customer-360 "More ▾" overflow toggle): [PENDING — photographic sweep captures the overflow menu open/closed state on customer-detail].
- **175 UAT #5** (Webhook → Event → entity three-screen thread): [PENDING — photographic sweep with operator-flows fixture confirms the three-screen Related link chain].

**Deferred 176 HUMAN-UAT items closed by the photographic sweep:**
- **176 UAT #1** (Light-theme rendering ≥ 2 all dims — 5 most-changed screens): [PENDING — vision-LLM scoring confirms CouponLive, EventLive, CampaignLive, PromotionCodeLive, WebhookLive forensic section ≥ 2 in light theme].
- **176 UAT #2** (Dark-theme contrast verification): [PENDING — axe sweep (Section 3) + vision-LLM scoring confirms contrast ≥ 2 in dark theme for all 5 screens].
- **176 UAT #3** (Mobile @360px layout spot-check): [PENDING — chromium-mobile Pixel5 screenshots from `npm run e2e:visuals:png-only` confirm no horizontal scroll, columns stack, prose constrained].

---

## Section 8 — Screenshot Evidence Directory

Screenshots are gitignored artifacts produced by the visual capture command. They are not embedded in this document.

**Capture command:** `cd accrue_admin && npm run e2e:visuals:png-only` (requires live server at http://localhost:4000)

**Output locations:**
- `accrue_admin/test-results/admin-visuals/chromium-desktop/` — 21 light PNGs + 21 dark PNGs = 42 files
- `accrue_admin/test-results/admin-visuals/chromium-mobile/` — 21 light PNGs + 21 dark PNGs = 42 files

**Expected:** 21 screens × 2 themes × 2 projects = **84 PNGs total**

**Naming convention:**
- Light: `<screen-name>.png` (e.g., `dashboard.png`, `coupon-detail.png`)
- Dark: `<screen-name>-dark.png` (e.g., `dashboard-dark.png`, `coupon-detail-dark.png`)

**Status: [PENDING — run capture command against live server]**

**Gitignore entry:** `accrue_admin/test-results/` is already in `.gitignore` — screenshots are local/CI-only artifacts. Do not commit PNGs to the repository.

---

## Section 9 — Human/CI Gate Checklist

These items must all be completed before this SIGN-OFF is finalized and the v1.51 milestone is declared DONE.

- [ ] Full 4-cell screenshot capture (84 PNGs) — `npm run e2e:visuals:png-only`
- [ ] Vision-LLM scoring all dimensions ≥ 2 — `ANTHROPIC_API_KEY=... npm run score-visuals` → review `findings.ndjson`
- [ ] Remediation loop complete (≤ 3 rounds; Phase 176 confirmed ≥ 2 at code level, minimal expected)
- [ ] Axe 0 critical/serious in light + dark across all 21 screens — `npm run e2e:a11y`
- [ ] Motion traces reviewed in Playwright Trace Viewer for 4 surfaces (command palette, dropdown, nav-collapse, webhook replay drawer)
- [ ] SIGN-OFF scorecard After-column filled from `findings.ndjson`
- [ ] Deferred 175 HUMAN-UAT items confirmed via photographic evidence (UAT #1–#5 in Section 7)
- [ ] Deferred 176 HUMAN-UAT items confirmed via photographic evidence (UAT #1–#3 in Section 7)
- [ ] Deferred 177 HUMAN-UAT items confirmed via motion trace review (UAT #1–#2 in Section 4)
- [ ] Deferred 178 HUMAN-UAT items confirmed via axe dark-contrast pass + photographic evidence (UAT #1–#3 in Section 5)
- [ ] v1.51 milestone CLOSED: all QA-01, QA-02, QA-03 requirements satisfied

**QA requirement mapping:**
- QA-01 (full 21-screen sweep inventory): closed by `admin-a11y.spec.js` 21-surface array + `admin-visuals.spec.js` 21-shot array (both committed). Photographic capture confirms coverage.
- QA-02 (scoring + remediation loop procedure): closed by `score-visuals.mjs` + findings.ndjson schema (committed in Phase 179 Plan 01). Procedure documented in Plan 179-01 SUMMARY.
- QA-03 (final scorecard 21/21 ≥ 2 + axe + screenshot evidence): this SIGN-OFF document. Gate: vision-LLM scoring all ≥ 2 + axe 0 critical/serious + motion trace review.

---

## Consolidated HUMAN-UAT Reference

All deferred HUMAN-UAT items from Phases 175–178, organized by closing mechanism:

### Closed by photographic sweep + vision-LLM scoring

| Item | Source | Closing mechanism |
|------|--------|-------------------|
| 175 UAT #1: Sidebar collapse/expand + localStorage persistence | 175-HUMAN-UAT.md | Screenshots capture sidebar open/collapsed states in both themes |
| 175 UAT #2: Attention-count badge tone & conditional appearance | 175-HUMAN-UAT.md | Edge-states fixture seeds at-risk data; screenshots show amber/red/hidden badge states |
| 175 UAT #3: Home launcher → work-queue persona path (≤ 2 clicks) | 175-HUMAN-UAT.md | Screenshot of Home + filter-active queue landing confirms link chain |
| 175 UAT #4: Customer-360 "More ▾" overflow toggle | 175-HUMAN-UAT.md | Screenshot with overflow menu open on customer-detail |
| 175 UAT #5: Webhook→Event→entity three-screen thread | 175-HUMAN-UAT.md | operator-flows fixture seeds the chain; screenshots confirm Related links |
| 176 UAT #1: Light-theme rendering ≥ 2 all dims (5 screens) | 176-HUMAN-UAT.md | Vision-LLM scoring confirms ≥ 2 on light screenshots |
| 176 UAT #2: Dark-theme contrast verification | 176-HUMAN-UAT.md | Axe sweep + vision-LLM scoring on dark screenshots |
| 176 UAT #3: Mobile @360px layout spot-check | 176-HUMAN-UAT.md | chromium-mobile Pixel5 screenshots confirm stacking + no horizontal overflow |
| 178 UAT #1: Loading/poll-banner state visual | 178-HUMAN-UAT.md | Double-seed + 5s wait in photographic sweep; screenshot shows poll banner |
| 178 UAT #3: Single click-through — all STATE-MATRIX cells reachable | 178-HUMAN-UAT.md | Photographic sweep navigates all 21 screens via seeded fixture IDs |

### Closed by axe spec (`npm run e2e:a11y` against live server)

| Item | Source | Closing mechanism |
|------|--------|-------------------|
| 178 UAT #2: Dark-contrast axe pass on seeded edge states | 178-HUMAN-UAT.md | `admin-a11y.spec.js` sweeps all 21 surfaces in dark theme; 0 critical/serious asserted |

### Closed by motion trace review (`admin-motion-trace.spec.js` + Playwright Trace Viewer)

| Item | Source | Closing mechanism |
|------|--------|-------------------|
| 177 UAT #1: Playwright reduced-motion spec runtime | 177-HUMAN-UAT.md | `e2e/reduced-motion.spec.js` already passes in CI (Phase 177). Trace spec additionally exercises live surfaces. |
| 177 UAT #2: Live motion quality pass (all 9 surfaces) | 177-HUMAN-UAT.md | Human review of Playwright trace for 4 primary motion surfaces; Phase 177 motion CSS covers all 9 surfaces |
