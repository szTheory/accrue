# Phase 234 — UI Review

**Audited:** 2026-10-08

**Baseline:** Abstract 6-pillar standards, informed by Phase 234 decisions D-19–D-23; no Phase 234 UI-SPEC.md exists.

**Screenshots:** Existing served screenshots under `captures/post-layout/234-06-final/` were inspected. No new screenshots were captured during this artifact refresh; localhost:8080 responded, and this refresh reuses the phase’s saved served captures and current browser evidence. The saved images predate Plan 08’s typography/search updates and are treated as historical visual evidence, not a current pixel snapshot. The current served browser suite supplies updated DOM, theme, reflow, accessibility, and asset evidence.

**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Search and empty/error states distinguish outcomes; the staged-action footer still says only “Cancel.” |
| 2. Visuals | 2/4 | The saved subscription list and detail views are crowded, with identity competing against several secondary facts and action groups. |
| 3. Color | 3/4 | Semantic theme tokens and restrained status colors create a coherent system, while route-specific fallback palettes remain hard-coded. |
| 4. Typography | 3/4 | Plan 08 now checks 14px minimum primary detail text and 1.2 line-height; summary labels and extreme heading weights remain inconsistent. |
| 5. Spacing | 2/4 | Subscription detail overrides collapse section and field gaps to zero and retain sub-pixel/arbitrary spacing values. |
| 6. Experience Design | 3/4 | CI exercises search completion, focus/step-up, themes, accessibility and narrow reflow; historical screenshots show a prior loading state and no interaction captures were taken in this review. |

**Overall: 16/24**

---

## Top 3 Priority Fixes

1. **Reduce the subscription detail’s competing content density** — operators must find lifecycle and next action among duplicated facts, queue context, recovery links and audit data — group secondary evidence behind clear disclosure and keep the current lifecycle/action prominent. [subscription_live.ex:313](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:313) [subscription_live.ex:455](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:455)
2. **Give subscription-list identity and facts room to scan** — the saved served row wraps the customer email into the adjacent processor ID while five columns compete — move to the existing labeled-card layout at a wider breakpoint or establish stronger column priority/minimums. [subscriptions_live.ex:209](../../../accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:209) [234-06 subscription-list capture](captures/post-layout/234-06-final/subscription-list.png)
3. **Clarify the staged-action dismissal control** — “Cancel” can mean cancel the billing operation instead of dismiss the review/drawer — label the non-submitting control “Close” before staging and “Discard staged change” when it clears a pending review. [subscription_live.ex:642](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:642)

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** Global search names supported matching fields and result limits, distinguishes loading from no matches and partial lookup failure, and offers a retry for failed groups. [global_search.ex:255](../../../accrue_admin/lib/accrue_admin/components/global_search.ex:255) [global_search.ex:284](../../../accrue_admin/lib/accrue_admin/components/global_search.ex:284)
- **WARNING:** Resource-specific empty copy is used on customer and subscription lists; the dashboard scopes its no-activity message. [customers_live.ex:149](../../../accrue_admin/lib/accrue_admin/live/customers_live.ex:149) [subscriptions_live.ex:597](../../../accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:597) [dashboard_live.ex:69](../../../accrue_admin/lib/accrue_admin/live/dashboard_live.ex:69)
- **WARNING:** The staged-action footer’s standalone “Cancel” does not say whether it dismisses the drawer or cancels a billing change. Use a state-specific dismissal label. [subscription_live.ex:642](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:642)

### Pillar 2: Visuals (2/4)

- **WARNING:** In the saved 1280px subscription-list capture, the customer email wraps immediately against the subscription ID, while state, plan/amount, renewal, and signals remain in the same five-column row. Prioritize identity and use the existing labeled-card presentation sooner at constrained widths. [subscriptions_live.ex:209](../../../accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:209) [234-06 subscription-list capture](captures/post-layout/234-06-final/subscription-list.png)
- **WARNING:** The saved subscription-detail capture places the lifecycle summary, global invoice queue, related billing links, repeated fact rows, actions, dunning, and audit content in one long uninterrupted page. Group secondary evidence and give the primary task path stronger hierarchy. [subscription_live.ex:313](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:313) [subscription_live.ex:455](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:455) [234-06 subscription-detail capture](captures/post-layout/234-06-final/subscription-detail.png)
- **WARNING:** The saved action drawer leaves a large empty body between the short form and a detached footer. Keep dismissal and confirmation visually associated with the staged form. [subscription_live.ex:624](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:624) [234-06 action-drawer capture](captures/post-layout/234-06-final/subscription-drawer.png)
- **Positive evidence:** Customer detail has a clear identity header and peer tabs; the Home view provides explicit customer and subscription entry points. The existing browser suite covers keyboard focus, dialog close/restore, and the scoped customer-to-subscription journey. [customer_live.ex:289](../../../accrue_admin/lib/accrue_admin/live/customer_live.ex:289) [dashboard_live.ex:40](../../../accrue_admin/lib/accrue_admin/live/dashboard_live.ex:40)

### Pillar 3: Color (3/4)

- **Positive evidence:** The theme defines named surfaces, primary text, accent, and status colors, with a separate dark theme; the served browser test checks light/dark accessibility. [theme.css:138](../../../accrue_admin/assets/css/theme.css:138) [theme.css:193](../../../accrue_admin/assets/css/theme.css:193) [phase234-admin-customers-subscriptions.spec.js:234](../../../examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js:234)
- **WARNING:** Customer and dashboard routes retain independent literal fallback palettes (`#5D79F6`, `#FAFBFC`, `#254ee8`, `#667085`, `#12b76a`). Align these defaults with the shared semantic token/config boundary so routes do not drift when host theming changes. [customers_live.ex:445](../../../accrue_admin/lib/accrue_admin/live/customers_live.ex:445) [dashboard_live.ex:126](../../../accrue_admin/lib/accrue_admin/live/dashboard_live.ex:126)
- **Positive evidence:** On the inspected Home and list captures, cobalt is concentrated on primary navigation/actions and links, while amber marks warnings; state is also named in text rather than conveyed by color alone. [234-06 home capture](captures/post-layout/234-06-final/home.png) [234-06 subscription-list capture](captures/post-layout/234-06-final/subscription-list.png)

### Pillar 4: Typography (3/4)

- **Positive evidence:** Plan 08 added a blocking served-DOM assertion that subscription facts render at least 14px with line-height at least 1.2; the plan summary records the Phase 234 served browser checks passing. This supersedes the earlier 11–13px finding. [phase234-admin-customers-subscriptions.spec.js:81](../../../examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js:81) [234-08 summary](234-08-SUMMARY.md)
- **WARNING:** Summary-list keys still use the 12px `--ax-type-xs` role, appropriate only for secondary labels; dense rows, uppercase treatment, and the 14px values reduce scan hierarchy in the full detail view. Keep those labels secondary, but restore section separation before increasing their size globally. [app.css:6094](../../../accrue_admin/assets/css/app.css:6094) [app.css:6104](../../../accrue_admin/assets/css/app.css:6104)
- **WARNING:** Component-local section headings use weights 850, 900 and 950. Normalize to the shared heading roles so repeated audit/detail headings do not compete with the subscription identity. [app.css:6168](../../../accrue_admin/assets/css/app.css:6168) [app.css:6176](../../../accrue_admin/assets/css/app.css:6176) [app.css:6183](../../../accrue_admin/assets/css/app.css:6183)

### Pillar 5: Spacing (2/4)

- **WARNING:** Subscription detail explicitly sets section and compact-field gaps to `0`; section heads use `0.03125rem` padding, with further arbitrary sub-token gaps and button padding. The visible page consequently reads as a dense continuous block. Restore a consistent section rhythm with existing `--ax-space-*` tokens. [app.css:6143](../../../accrue_admin/assets/css/app.css:6143) [app.css:6159](../../../accrue_admin/assets/css/app.css:6159) [app.css:6362](../../../accrue_admin/assets/css/app.css:6362) [app.css:6218](../../../accrue_admin/assets/css/app.css:6218)
- **WARNING:** Compact action buttons are explicitly reduced to 1.5rem minimum height on the detail action band; keep the 44px coarse-pointer target verified by the browser test, and avoid shrinking standalone controls at other input modes. [app.css:6218](../../../accrue_admin/assets/css/app.css:6218) [phase234-admin-customers-subscriptions.spec.js:308](../../../examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js:308)
- **Positive evidence:** The shared token scale defines a 4px base with 2px compact rung; page, toolbar, and tab layouts use those roles in most shared components. [theme.css:22](../../../accrue_admin/assets/css/theme.css:22) [app.css:6840](../../../accrue_admin/assets/css/app.css:6840)

### Pillar 6: Experience Design (3/4)

- **Positive evidence:** The dedicated real-pool search browser lane proves results resolve, preserve owner scope, navigate to the matched customer, and clear stale results; the Plan 08 summary records two consecutive passing runs. This closes the former host-sandbox loading limitation for current verification. [234-08 summary](234-08-SUMMARY.md)
- **Positive evidence:** The served suite covers the search dialog keyboard path, scoped customer/subscription journey, light/dark themes, reduced motion, axe checks, and 320px reflow; Plan 08 adds expired step-up and Escape-without-dispatch coverage. [phase234-admin-customers-subscriptions.spec.js:110](../../../examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js:110) [phase234-admin-customers-subscriptions.spec.js:277](../../../examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js:277) [234-08 summary](234-08-SUMMARY.md)
- **WARNING:** The older saved search capture shows “Searching billing records…” with no results because it predates the real-pool fix. Do not use that image as current search-state evidence; the current machine-run search check is the authoritative result-resolution evidence. [234-06 search capture](captures/post-layout/234-06-final/search.png) [234-08 summary](234-08-SUMMARY.md)
- **WARNING:** Interaction capture is disabled in project configuration, so this refresh did not independently reproduce or capture interactive states. The cited Playwright checks provide automated evidence; this review makes no separate visual claim about the open/close states beyond the saved historical images.

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
- `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js`
- `.planning/phases/234-admin-customers-subscriptions/234-CONTEXT.md`
- `.planning/phases/234-admin-customers-subscriptions/234-01..08-SUMMARY.md` and selected matching plans
- Existing captures and manifests under `.planning/phases/234-admin-customers-subscriptions/captures/`
