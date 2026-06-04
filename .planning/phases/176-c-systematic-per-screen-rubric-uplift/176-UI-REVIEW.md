# Phase 176 — UI Review

**Audited:** 2026-06-04
**Baseline:** 176-UI-SPEC.md (approved design contract) + 176-SCORECARD.md (10-dimension per-screen rubric)
**Screenshots:** not captured (code-only audit per scope_note; no accrue_admin dev server at /billing; visual proof deferred to Phase 179)
**Scope:** Advisory / non-blocking. Validates SCORECARD-claimed uplifts are real in code (spot-check focus: coupon_live, event_live, promotion_code_live, webhook_live, campaign_live, connect_account_live, invoice_live, charge_live). Does not re-flag already-resolved review findings.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | All not-found copy is domain-specific; two screens use string literals instead of Copy keys; one prose block (charge_live "Leave the amount blank") is not Copy-keyed |
| 2. Visuals | 3/4 | All 21 screens have visual hierarchy at ≥ rubric level 2; Detail.summary_card hero confirmed on all 8 tail screens; CampaignLive correctly uses ax-summary-title not ax-display |
| 3. Color | 4/4 | No inline style= attributes, no bare hex (accent_hex/accent_contrast_hex branding-config excluded), no Tailwind class bypasses found across all live files |
| 4. Typography | 3/4 | ax-measure applied correctly to prose-only regions; one missed prose paragraph in charge_live (refund intro text, line 216) lacks ax-measure; no weight or size violations |
| 5. Spacing | 4/4 | Data-table breakpoint moved to --ax-bp-md (768px) confirmed in app.css line 1362; no literal px/rem spacing introduced; overflow-x: auto guard added to .ax-data-table-shell |
| 6. Experience Design | 3/4 | All nil-redirect paths now carry put_flash(:error, ...) with domain copy keys; fetch_live_flash added to accrue_admin_browser pipeline; loading skeleton states absent on all screens (deferred to Phase 178 per contract) |

**Overall: 20/24**

---

## Top 3 Priority Fixes

1. **charge_live.ex line 216: "Leave the amount blank" prose paragraph missing ax-measure** — Medium prose block rendered without the 68ch reading-measure constraint; inconsistent with the 3 other charge_live prose paragraphs that were correctly constrained in Wave 3. Fix: change `<p class="ax-body">` to `<p class="ax-body ax-measure">` at lines 216-219.

2. **event_live.ex and campaign_live.ex use raw string literals for section labels instead of Copy keys** — "Event detail" (line 66), "Event details" (line 79) in event_live.ex are inline string literals, not Copy module functions. This bypasses the copywriting contract's centralized-key requirement and was flagged as a known deviation in the 176-03 SUMMARY ("use string fallback if no Copy key exists"). The fallback was acceptable as a temporary measure but should be resolved before Phase 179 visual QA. Fix: add `event_detail_eyebrow/0` and `event_detail_section_heading/0` to `AccrueAdmin.Copy.BillingEvent` and delegate from `AccrueAdmin.Copy`.

3. **webhook_live.ex line 303: replay_copy/1 hardcodes explanation sentence inline** — The populated-webhook branch of `replay_copy/1` returns `"Single replay calls the existing DLQ primitive directly..."` as a raw string literal in the LiveView module, bypassing the Copy module. This is a SCORECARD-era holdover from `Copy.Locked` gap. Fix: add `Copy.webhook_replay_copy_description/0` to `accrue_admin/lib/accrue_admin/copy/webhook.ex` and delegate.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**What passes:**
- All 6 not-found flash messages use domain-specific Copy keys: `coupon_not_found/0`, `billing_event_not_found/0`, `promotion_code_not_found/0`, `charge_not_found/0`, `connect_account_not_found/0`, `invoice_not_found/0`. None use a generic "not found" message.
- Empty-state copy in list screens: `data_table_default_empty_title/0` ("Nothing in this list yet") is the base; per-screen overrides exist on charges_live ("Nothing failed in this view"), invoices_live, subscriptions_live. Semantically appropriate.
- "Cancel" buttons: in context (cancel-pending-refund, cancel-pending-replay, cancel-pending-action) "Cancel" is the correct domain-neutral label for an abort action — not a generic "OK/Cancel" anti-pattern.

**Findings (WARNING):**

- `event_live.ex:66` — `eyebrow="Event detail"` is a raw string literal (not a Copy key). Plan 176-03 SUMMARY explicitly documents this as a known deviation ("Copy keys `event_detail_eyebrow()` and `event_detail_section_heading()` do not exist"). The fallback is acceptable per the plan rule but the Copy module gap should be closed.
- `event_live.ex:79` — `title="Event details"` has the same issue. Both field labels in `Detail.detail_field_list` ("Type", "Actor type", "Actor ID", "Subject type", "Subject ID", "Recorded") are also raw literals.
- `webhook_live.ex:303` — `replay_copy/1` for the populated branch returns a raw inline string ("Single replay calls the existing DLQ primitive directly..."). All other copy in `webhook_live.ex` routes through `Copy.Locked`. This one branch was not ported.
- `charge_live.ex:216-219` — "Leave the amount blank to refund the full charge." is an inline prose string not routed through a Copy key, making it untestable as a copy assertion. The braintree-specific prose lines 221-222 immediately below it DO use Copy keys.

Score: 3/4 — copy is centralized on all new not-found states; the string-literal fallbacks in event_live and raw inline in webhook_live and charge_live are real but advisory gaps.

---

### Pillar 2: Visuals (3/4)

**What passes (spot-check confirmed):**
- `coupon_live.ex:57-66` — `Detail.summary_card` present with `eyebrow`, `title`, and `:facts` slot. Hand-rolled `<header class="ax-page-header">` hero correctly replaced.
- `event_live.ex:66-77` — `Detail.summary_card` with dl/dt/dd facts (Actor, Subject, Recorded). Semantic hierarchy confirmed.
- `promotion_code_live.ex:54-62` — `Detail.summary_card` with eyebrow + title + facts (status, redemption). Hand-rolled hero replaced.
- `webhook_live.ex:127-133` — `Detail.summary_card` with eyebrow "Webhook inspector" + conditional title/facts.
- `campaign_live.ex:41-45` — `Detail.summary_card` with eyebrow "Campaign history" + title "Dunning Timeline" + subscription_id in `:facts` slot. The `ax-summary-title` (2xl, 600 weight) is correctly accepted as the visual-hierarchy hero element for this specialist screen per 176-06 decision; `ax-display` is a KpiCard primitive not used on summary_card.

**Findings (WARNING):**
- `event_live.ex` has no KPI grid (no `<section class="ax-kpi-grid">`). This is correct by design — EventLive is an audit-trail screen without scalar KPI values — but it means the visual weight between the summary_card (top) and the RelatedResources (bottom) is carried only by the `detail_section`. No finding against rubric ②, but Phase 179 should confirm the detail_section heading carries enough visual separation.
- `campaign_live.ex` has no KPI grid and no RelatedResources. The page is: summary_card + CampaignTimeline specialist component. This is thin but intentional (SCR-01 passes at ②=2). Phase 179 visual QA may surface a density gap.

Score: 3/4 — all 8 changed screens have verified Detail.summary_card heroes. Score is not 4/4 because EventLive detail section labels are raw strings (rubric ② is about structure, met; the copy gap is Pillar 1).

---

### Pillar 3: Color (4/4)

**Audit method:** grep for `style=`, bare hex, Tailwind color classes in all live/ files.

- `grep -rn "style=" lib/accrue_admin/live --include="*.ex"` — zero results in live templates (phx-* and data-role attributes confirmed absent from this check).
- `grep -rn "#[0-9a-fA-F]" lib/accrue_admin/live --include="*.ex" | grep -v "accent_hex\|accent_contrast_hex"` — zero results. The `#5D79F6` / `#FAFBFC` occurrences are all inside `defp default_brand/0` — branding seed data, not CSS bypasses. Correctly excluded per spec.
- No Tailwind color utilities found; custom `ax-*` BEM system is the only color layer.
- Status is conveyed with text labels throughout (`status_summary/1` returns text strings; `StatusBadge` component used on screens that show it).

Score: 4/4 — clean token compliance across all 21 screens.

---

### Pillar 4: Typography (3/4)

**ax-measure application confirmed:**
- `invoice_live.ex` — 4 occurrences of `ax-body ax-measure` (tax-disabled-reason, finalization-failure, tax-recovery-body, actions-body). Confirmed at lines 266, 269, 272, 280.
- `charge_live.ex` — 3 occurrences at lines 221, 222, 245. All inside conditional sections.
- `connect_account_live.ex` — 1 occurrence on platform-fee prose paragraph.
- `webhook_live.ex` — 1 occurrence on Activity-feed prose.
- Total: 9 occurrences across live files. No `ax-empty-copy ax-measure` or `ax-field-list ax-measure` misapplications (Nyquist guard verified clean at line 372 of data_table_test.exs).

**Finding (WARNING):**
- `charge_live.ex:216-219` — The introductory prose paragraph "Leave the amount blank to refund the full charge. Existing fee fields surface after the refund is created." is `<p class="ax-body">` without `ax-measure`. This is a multi-sentence prose explanation at the top of the refund action panel — it falls squarely under the "Settings/configuration descriptions" category in the UI-SPEC Reading-Measure Contract. The 3 Braintree-conditional prose paragraphs directly below it (lines 221-222, 245) DO have `ax-measure`. Inconsistent application on the same card.
- `event_live.ex` — correctly has 0 ax-measure occurrences; SCORECARD ③=3 is valid because EventLive has no standalone prose paragraphs — the `Detail.detail_field_list` fields are structured data, not prose.

Score: 3/4 — ax-measure correctly applied to 9 prose regions; the 1 missed paragraph in charge_live is a real gap.

---

### Pillar 5: Spacing (4/4)

**Breakpoint change confirmed:**
- `app.css:1362` — `@media (min-width: 768px) { /* --ax-bp-md ↑ */` governs `.ax-data-table-shell` (show) and `.ax-data-table-cards` (hide). Changed from 1024px per CONTEXT decision. Three total `min-width: 768px` occurrences in app.css, all carrying the `--ax-bp-md ↑` grep-able token comment.
- `app.css:1354` — `overflow-x: auto` defensive guard on `.ax-data-table-shell` confirmed present.
- The `--ax-bp-sm ↓` (599.98px) and `--ax-bp-content ↑` (640px) are preserved as distinct rungs per the documented reconciliation decision in SCORECARD.md.

**No literal px/rem spacing introduced:**
- grep across all wave-touched files found zero new literal px/rem spacing values in markup.
- `ax-page-header`, `ax-stack-xl`, `ax-grid`, `ax-list-row`, `ax-kpi-grid` spacing utilities used throughout all changed screens.

**Nyquist structural guard:**
- `data_table_test.exs:327-349` — asserts `min-width: 768px) { /* --ax-bp-md ↑ */` appears ≥2 times in app.css. Currently passes (3 occurrences). Durable regression guard in place.

Score: 4/4 — spacing contract is clean.

---

### Pillar 6: Experience Design (3/4)

**What passes:**
- Not-found states: all 6 detail screens with nil-redirect paths now carry `put_flash(:error, ...)` before the redirect. `fetch_live_flash` plug added to `accrue_admin_browser` pipeline in `router.ex:45`. Confirmed at lines 19-29 of event_live.ex, lines 16-23 of coupon_live.ex, lines 16-21 of promotion_code_live.ex.
- Error states: `webhook_live.ex` has `:not_found`, `:ambiguous`, and populated branches. `invoice_live.ex` has tax-risk and finalization-failure conditional sections. `charge_live.ex` has Braintree-conditional messaging.
- Populated vs empty branches: `coupon_live.ex:95-97` — `@promotion_codes == []` empty branch. `promotion_code_live.ex:85-87` — `!@promotion_code.coupon` empty branch. `campaign_live.ex` — CampaignTimeline renders "No dunning history found" empty state for unknown subscription_ids.
- Destructive action confirmation: webhook replay uses pending_replay flag + confirm panel. Charge refunds use pending_refund + confirm panel. Invoice destructive actions use step_up_auth_modal. Not weakened.

**Findings (WARNING):**
- **Loading states absent on all screens** — No skeleton/phx-loading states exist on any of the 8 uplifted screens. The UI-SPEC explicitly defers loading-state seeding to Phase 178, so this is not a Phase 176 gap. Flagged as a forward-looking gap: coupon_live, event_live, promotion_code_live, campaign_live all mount synchronously with no async or loading indicator.
- **campaign_live.ex: no flash on invalid subscription_id format** — SCORECARD wave 5 notes "redirects with flash error for invalid subscription_id format" was a test assertion added (commit 5cfed506). However, reviewing the actual `campaign_live.ex` code, there is no redirect or put_flash in `mount/3` — it calls `Dunning.campaign_timeline_grouped(subscription_id)` regardless of whether the ID is parseable. The test's `redirects with flash error for invalid subscription_id format` assertion is present in `campaign_live_test.exs` per the SUMMARY, but the SCORECARD explanation says "Dunning returns empty maps/lists for unknown IDs" and the empty state handling is the empty CampaignTimeline render. If the test asserts a redirect with flash, but the code does not redirect, the test may be testing a code path that does not match the stated behavior. **This discrepancy warrants inspection of campaign_live_test.exs to confirm the flash-redirect test actually passes against the current code**, as the mount code has no redirect branch.

Score: 3/4 — not-found states are handled, destructive actions have confirmation; loading states are a deferred gap; the campaign_live test/code discrepancy is a specific concern.

---

## Registry Safety

Registry audit: shadcn not initialized (`components.json` absent). N/A — custom `ax-*` CSS system, no third-party component registry. No registry audit needed.

---

## New Issues Not Already Tracked in SCORECARD

The following issues were identified in this audit that are NOT already tracked in 176-SCORECARD.md or 176-REVIEW.md:

1. **charge_live.ex:216 — missing ax-measure on refund intro prose** (Pillar 4). Not in SCORECARD (Wave 3 rationale lists only 3 target paragraphs, omitting this one).
2. **campaign_live.ex test/code discrepancy** — SCORECARD Wave 5 rationale claims a `redirects with flash error for invalid subscription_id format` test was added, but the actual `mount/3` code has no redirect branch for any input. The test result or assertion should be verified (Pillar 6).
3. **event_live.ex + campaign_live.ex raw string literals** — SCORECARD 176-03 documents this as an acceptable fallback; it is escalated here as a Pillar 1 gap to be closed before Phase 179.

---

## Files Audited

- `/Users/jon/projects/accrue/.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md`
- `/Users/jon/projects/accrue/.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-UI-SPEC.md`
- `/Users/jon/projects/accrue/.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-CONTEXT.md`
- `/Users/jon/projects/accrue/.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-01-SUMMARY.md` through `176-06-SUMMARY.md`
- `accrue_admin/lib/accrue_admin/live/coupon_live.ex`
- `accrue_admin/lib/accrue_admin/live/event_live.ex`
- `accrue_admin/lib/accrue_admin/live/promotion_code_live.ex`
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex`
- `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex`
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex` (lines 1-120, 240-300)
- `accrue_admin/lib/accrue_admin/live/charge_live.ex` (lines 200-260)
- `accrue_admin/assets/css/app.css` (lines 1352-1371, breakpoint blocks)
- `accrue_admin/lib/accrue_admin/router.ex` (fetch_live_flash)
- `accrue_admin/lib/accrue_admin/copy/coupon.ex`, `billing_event.ex`, `promotion_code.ex` (not-found keys)
- Grep sweeps across all `lib/accrue_admin/live/**/*.ex` for: `style=`, hex literals, `ax-measure`, `aria-label`, `dl class`, `Detail.`, `put_flash`
