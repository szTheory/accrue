# Phase 234 — UI Review

**Audited:** 2026-10-07
**Baseline:** Abstract 6-pillar standards (no UI-SPEC.md found)
**Screenshots:** Not captured — localhost:8080 responded, but Playwright failed at desktop, mobile, and tablet. Existing Phase 234 served captures were inspected as supplemental evidence.
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Search, empty, and unavailable states use specific, helpful language; action drawers still use generic “Cancel.” |
| 2. Visuals | 2/4 | The subscription list compresses identity, plan, dates, and signals into a cramped five-column table. |
| 3. Color | 3/4 | Semantic tokens and restrained cobalt/amber status cues are used, but component paths retain several hard-coded accent values. |
| 4. Typography | 2/4 | Subscription details use 11–13px text, line-height 1.1, and weights up to 950, making dense evidence harder to scan. |
| 5. Spacing | 2/4 | Component CSS includes sub-pixel padding and several arbitrary rem values that produce cramped rows. |
| 6. Experience Design | 3/4 | Loading, empty, partial-failure, and destructive confirmation states exist; browser search results remained unverified in the host E2E sandbox. |

**Overall: 15/24**

---

## Top 3 Priority Fixes

1. **Restore readable hierarchy in subscription details** — operators must scan lifecycle evidence quickly, but secondary facts are reduced to 11px and 13px — replace component-local sizes and extreme weights with shared readable type roles; preserve compactness through layout, not smaller text. [app.css:6054](../../../accrue_admin/assets/css/app.css:6054) [app.css:6362](../../../accrue_admin/assets/css/app.css:6362)
2. **Give subscription rows enough room for identity and comparison fields** — at desktop width the five-column row wraps the customer identity and crowds plan/date/signal facts — use the existing narrow labeled-card variant at an earlier breakpoint or reprioritize column widths and secondary content. [subscriptions_live.ex:209](../../../accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:209)
3. **Remove sub-pixel and one-off spacing overrides from the detail surface** — 0.5px vertical padding and inconsistent tiny gaps visually collapse section separation — use the existing `--ax-space-*` scale and restore clear section rhythm. [app.css:6140](../../../accrue_admin/assets/css/app.css:6140) [app.css:6050](../../../accrue_admin/assets/css/app.css:6050)

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** Search accurately lists match fields, caps results per group, and has distinct loading, partial failure/retry, and no-results states. [global_search.ex:255](../../../accrue_admin/lib/accrue_admin/components/global_search.ex:255) [global_search.ex:284](../../../accrue_admin/lib/accrue_admin/components/global_search.ex:284) [global_search.ex:287](../../../accrue_admin/lib/accrue_admin/components/global_search.ex:287)
- **WARNING:** Customer and subscription tables distinguish row identity and relevant data; empty-state copy routes through resource-specific copy helpers rather than generic “No data.” [customers_live.ex:149](../../../accrue_admin/lib/accrue_admin/live/customers_live.ex:149) [customers_live.ex:392](../../../accrue_admin/lib/accrue_admin/live/customers_live.ex:392) [subscriptions_live.ex:597](../../../accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:597)
- **WARNING:** Action footer’s standalone “Cancel” is generic and repeated in the drawer. Rename it to “Close” before review begins and a specific “Discard staged change” after staging, so users know the consequence. [subscription_live.ex:642](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:642)

### Pillar 2: Visuals (2/4)

- **WARNING:** The subscription table presents five columns, including signals and multi-line plan/date facts, alongside a wrapping customer identity. In the saved served capture, the row is visually dense and identity runs close to the subscription ID. Prefer labeled cards sooner on medium screens, or give identity and plan/date columns explicit minimum space. [subscriptions_live.ex:209](../../../accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:209) [234-06-final subscription-list capture](<../../../.planning/phases/234-admin-customers-subscriptions/captures/post-layout/234-06-final/subscription-list.png>)
- **WARNING:** Subscription page heading/actions and stats compete in the first viewport: three prominent action links sit beside a two-line page description and KPI row. Put the primary invoice action first and move debug/audit destinations into a quieter secondary group. [subscriptions_live.ex:128](../../../accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:128) [subscriptions_live.ex:138](../../../accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:138)
- **WARNING:** The saved drawer capture contains a two-column feeling form with a large unused body and footer pinned at the bottom; tighten the form’s vertical layout and keep the primary and dismiss actions grouped. Current-run visual confirmation was unavailable. [subscription_live.ex:624](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:624)
- **Positive evidence:** Customer peer tabs wrap, keep a 44px minimum height, and use `aria-current`; the subscription detail has explicit named regions. [customer_live.ex:289](../../../accrue_admin/lib/accrue_admin/live/customer_live.ex:289) [app.css:6847](../../../accrue_admin/assets/css/app.css:6847)

### Pillar 3: Color (3/4)

- **WARNING:** Theme CSS centralizes surface, status, and interaction colors under `--ax-*` semantic tokens, and saved list screens use cobalt links with amber warning cues. This creates a coherent state language. [theme.css:138](../../../accrue_admin/assets/css/theme.css:138) [theme.css:193](../../../accrue_admin/assets/css/theme.css:193)
- **WARNING:** LiveViews still construct fallback branding with hard-coded accent colors (`#5D79F6`, `#FAFBFC`); dashboard also has literal primary/secondary/accent defaults. Move these to the existing token/config boundary so host theme overrides cannot drift across routes. [customers_live.ex:446](../../../accrue_admin/lib/accrue_admin/live/customers_live.ex:446) [dashboard_live.ex:130](../../../accrue_admin/lib/accrue_admin/live/dashboard_live.ex:130)
- CSS contains a few fixed literal dark-mode overrides as well as the theme variables; constrain these to compatibility cases or express them through semantic tokens. [app.css:1024](../../../accrue_admin/assets/css/app.css:1024) [app.css:4320](../../../accrue_admin/assets/css/app.css:4320)

### Pillar 4: Typography (2/4)

- No utility-class font-size or weight system is used in the audited LiveView markup; the component CSS instead creates many component-local roles. Relevant subscription details explicitly use 0.6875rem labels (11px), 0.8125rem values (13px), `--ax-type-xs`, and tight 1.1 line-height. [app.css:6054](../../../accrue_admin/assets/css/app.css:6054) [app.css:6356](../../../accrue_admin/assets/css/app.css:6356) [app.css:6362](../../../accrue_admin/assets/css/app.css:6362)
- Section-title weights reach 900 and 950, while other sections use 850. These weights create loud headings without improving the small supporting text’s legibility; cap at the shared semibold/bold roles. [app.css:6145](../../../accrue_admin/assets/css/app.css:6145) [app.css:6153](../../../accrue_admin/assets/css/app.css:6153) [app.css:6160](../../../accrue_admin/assets/css/app.css:6160)
- **WARNING:** Increase labels and secondary values to the project’s legible 14px secondary-text target and retain 16px for body/control copy; keep metadata smaller only when genuinely auxiliary.

### Pillar 5: Spacing (2/4)

- **WARNING:** Detail section headings have only `0.03125rem` vertical padding (0.5px), and compact detail field rows use similarly tiny gaps. This removes breathing room between dense evidence groups. [app.css:6140](../../../accrue_admin/assets/css/app.css:6140) [app.css:6350](../../../accrue_admin/assets/css/app.css:6350)
- Arbitrary spacing appears throughout the late subscription detail overrides (`0.3125rem`, `0.03125rem`, `0.0625rem`, and `0.125rem`) alongside token spacing. Consolidate these on `--ax-space-*` roles and preserve a consistent section rhythm. [app.css:6040](../../../accrue_admin/assets/css/app.css:6040) [app.css:6123](../../../accrue_admin/assets/css/app.css:6123) [app.css:6217](../../../accrue_admin/assets/css/app.css:6217)
- **Positive evidence:** Toolbar, page, and tab layouts mostly use shared stack/gap tokens; tabs and narrow-layout action controls target 44px. [app.css:6840](../../../accrue_admin/assets/css/app.css:6840) [app.css:6892](../../../accrue_admin/assets/css/app.css:6892)

### Pillar 6: Experience Design (3/4)

- **WARNING:** Global search handles loading, partial query failure with retry, no matches, and successful result groups. The Phase 234 host E2E explicitly could not verify resolved production search results because async workers stay in loading state under the SQL sandbox; unit tests passed per the plan summary. [global_search.ex:284](../../../accrue_admin/lib/accrue_admin/components/global_search.ex:284) [234-06 summary](../../../.planning/phases/234-admin-customers-subscriptions/234-06-SUMMARY.md:129)
- **WARNING:** Destructive/substantive subscription operations have staged confirmation and a cancel path. The cancel label is underspecified once an operation has been staged. [subscription_live.ex:632](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:632)
- **Positive evidence:** Customer and subscription lists provide scoped loading/empty states, while search has a named dialog and visible status messages. [customers_live.ex:143](../../../accrue_admin/lib/accrue_admin/live/customers_live.ex:143) [subscriptions_live.ex:203](../../../accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:203) [global_search.ex:232](../../../accrue_admin/lib/accrue_admin/components/global_search.ex:232)
- Phase summary reports served checks for search dialog Tab/Shift+Tab/Escape/focus restoration, 320 CSS px overflow, theme, reduced motion, and 44px action targets. I did not reproduce those interactions in this review because interaction capture was configured off.

---

## Files Audited

- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex`
- `accrue_admin/lib/accrue_admin/live/customers_live.ex`
- `accrue_admin/lib/accrue_admin/live/customer_live.ex`
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- `accrue_admin/lib/accrue_admin/components/global_search.ex`
- `accrue_admin/assets/css/app.css`
- `accrue_admin/assets/css/theme.css`
- `.planning/phases/234-admin-customers-subscriptions/234-01..07-SUMMARY.md` and matching plans; `234-CONTEXT.md`

