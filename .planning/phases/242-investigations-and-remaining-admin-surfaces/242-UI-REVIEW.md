# Phase 242 — UI Review

**Audited:** 2026-10-10  
**Baseline:** Approved Phase 242 UI-SPEC.md and locked D-01/D-16/D-17 decisions  
**Screenshots:** No new captures or visual inspection. The prior phase-level observation is retained only as recorded evidence: one Connect detail capture at 1280×900; the other surfaces were not visually inspected.

**Interaction captures:** off (interaction_capture=false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | The filtered Events state now renders the approved exact heading; the mounted assertion covers it. |
| 2. Visuals | 3/4 | One prior Connect detail inspection found legible facts but a broken logo in the disposable fixture; remaining surfaces lack visual inspection. |
| 3. Color | 3/4 | Table overrides now use theme roles, but the dark active theme-picker label still hard-codes a light color. |
| 4. Typography | 4/4 | The shared body role now uses the contract's 16px/400/1.4 token. |
| 5. Spacing | 4/4 | The Home coarse-pointer action targets now meet 44px and the recurring geometry assertion measures all three at 768px. |
| 6. Experience Design | 3/4 | Partial search retry now preserves successful groups and retries only failed groups; no new interaction capture was made. |

**Overall: 21/24**

---

## Top 3 Priority Fixes

1. **Replace the remaining hard-coded dark theme-picker color with a theme role** — this leaves a color exception outside the approved token system — use an appropriate `--ax-*` token and retain the dark/System contrast checks.
2. **Correct the disposable browser fixture's broken logo URL** — the only recorded visual inspection showed the shared brand mark broken because the fixture supplies `https://example.test/logo.svg` — use a valid fixture asset or the self-contained fallback, then confirm in a future authorized visual pass.
3. **Capture the uninspected investigation and search surfaces in the Phase 243 visual pass** — source and mounted tests do not establish their rendered hierarchy or visual polish — inspect Events, webhook delivery, catalog, Home, and global search at contract breakpoints and themes.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- The approved filtered-empty heading is `No ledger rows match these filters.` ([UI-SPEC.md](242-UI-SPEC.md:101)). `EventsLive.list_state_copy/1` now overrides the generic resource-state heading with `Copy.events_list_filtered_empty_title/0` and the corresponding body ([events_live.ex](../../../accrue_admin/lib/accrue_admin/live/events_live.ex:392), [billing_event.ex](../../../accrue_admin/lib/accrue_admin/copy/billing_event.ex:19)). The host mounted assertion verifies that exact rendered heading ([phase238-admin-events-webhooks.spec.js](../../../examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js:203)). The generic `Copy.resource_state_copy/2` entry still contains the older phrase ([copy.ex](../../../accrue_admin/lib/accrue_admin/copy.ex:128)), but this Events screen path deliberately replaces it; that duplicate is a maintainability note rather than a rendered contract failure.
- Existing copy continues to distinguish event from delivery, coupon from promotion code, and partial search availability from a true no-match. Search's retry label and partial-result explanation are resource-specific ([global_search.ex](../../../accrue_admin/lib/accrue_admin/components/global_search.ex:313)).

### Pillar 2: Visuals (3/4)

- The only recorded inspected view was Connect detail. Its summary, stored-snapshot note, unknown fields, and local fee policy were reported legible. The same observation records a broken brand logo ([242-EXECUTION-GATES.md](242-EXECUTION-GATES.md:59)); subsequent source diagnosis bounds this to the disposable fixture's external `logo_url`, while the nil fallback is a self-contained SVG ([242-EXECUTION-GATES.md](242-EXECUTION-GATES.md:138)). The original capture is unavailable for confirmation, so no cause or correction is visually confirmed.
- Source hierarchy follows the contract's resource identity → observed facts/uncertainty → supported action → related evidence order; for example webhook detail presents its target and eligibility before lazy Activity and Raw payload ([webhook_live.ex](../../../accrue_admin/lib/accrue_admin/live/webhook_live.ex:227), [webhook_live.ex](../../../accrue_admin/lib/accrue_admin/live/webhook_live.ex:277)). This is code-derived evidence, not a new visual finding.
- Events, delivery, catalog, Home, and global-search visual hierarchy was not inspected. Phase 243 retains the final Linux goldens and preview review.

### Pillar 3: Color (3/4)

- The package theme defines Cobalt, neutral-surface, and intent roles through `--ax-*` tokens ([theme.css](../../../accrue_admin/assets/css/theme.css:137), [theme.css](../../../accrue_admin/assets/css/theme.css:230)). The corrected dark and System-dark table selectors now use `--ax-elevated` and `--ax-primary` ([app.css](../../../accrue_admin/assets/css/app.css:4369)); the recorded corrective batch rebuilt package CSS after these changes ([242-EXECUTION-GATES.md](242-EXECUTION-GATES.md:87)).
- **WARNING:** A separate dark/System-dark theme-picker active-label selector still uses `color: #f4f7fa !important` ([app.css](../../../accrue_admin/assets/css/app.css:1024)). The literal matches the current dark `--ax-primary` value, so no current contrast defect is claimed, but it bypasses theme-role ownership. Effective contrast was not freshly inspected.
- The 60/30/10 split remains a compositional guide, not a measured pixel requirement. No broad accent overuse was established by source review.

### Pillar 4: Typography (4/4)

- The contract specifies Body as 16px/400/1.4 ([UI-SPEC.md, Typography](242-UI-SPEC.md:89)). The shared `.ax-body` now composes `--ax-type-body-font` ([app.css](../../../accrue_admin/assets/css/app.css:914)), defined as 400 at the medium size and normal 1.4 leading ([theme.css](../../../accrue_admin/assets/css/theme.css:72), [theme.css](../../../accrue_admin/assets/css/theme.css:83)). This closes the previous 1.5-leading mismatch.
- Geist and Geist Mono role declarations remain distinct for interface copy and technical identifiers ([theme.css](../../../accrue_admin/assets/css/theme.css:13), [theme.css](../../../accrue_admin/assets/css/theme.css:82)). The review credits the declared source roles and recorded text-stress assertions, not fresh rendered font inspection across every route.

### Pillar 5: Spacing (4/4)

- Home actions now receive a `min-block-size: 44px` rule for coarse pointers ([app.css](../../../accrue_admin/assets/css/app.css:4353)). The recurring Phase 199 assertion measures all three shortcut bounding boxes at 768 CSS px under emulated coarse pointer and passes (27 passed, 15 incumbent skips) ([242-EXECUTION-GATES.md](242-EXECUTION-GATES.md:105)). This closes the prior 32px target gap.
- The 4px task/layout ladder and the declared dense-data/structural exceptions remain represented by package tokens; no new spacing scale was introduced. Pointer and viewport results are emulation, not physical-device evidence.

### Pillar 6: Experience Design (3/4)

- **Resolved search retry defect:** `handle_event("retry", ...)` now starts only the failed groups and seeds the new result state with existing successful groups ([global_search.ex](../../../accrue_admin/lib/accrue_admin/components/global_search.ex:111)). Ordinary full search still starts with empty results. The recorded focused regression exercises preserved customer results alongside a retried invoice group, including success and failure, and passes 16 tests ([global_search_test.exs](../../../accrue_admin/test/accrue_admin/components/global_search_test.exs:266), [242-EXECUTION-GATES.md](242-EXECUTION-GATES.md:86)). Existing query/generation/owner guards remain in place per that evidence.
- Search exposes a partial-unavailable status and targeted retry while retaining completed results ([global_search.ex](../../../accrue_admin/lib/accrue_admin/components/global_search.ex:313)). The current host Playwright owner passed and asserts scoped pointer/Arrow/Enter selection; the focused retry reducer regression is semantic ExUnit coverage, not a claim that the partial-retry visual state was browser-captured ([242-EXECUTION-GATES.md](242-EXECUTION-GATES.md:86), [242-EXECUTION-GATES.md](242-EXECUTION-GATES.md:106)).
- Source provides distinct loading, filtered-empty, first-run, unavailable, partial-failure, and unknown-result states. Replay and fee changes retain explicit review and dismissal behavior. No new interaction capture was made; native zoom, physical-device behavior, screen-reader speech, live-provider outcomes, remote CI, and Linux goldens remain unclaimed.

---

## Files Audited

- `.planning/phases/242-investigations-and-remaining-admin-surfaces/242-01` through `242-07` PLAN and SUMMARY artifacts; `242-UI-SPEC.md`, `242-CONTEXT.md`, `242-EXECUTION-GATES.md`, `242-VALIDATION.md`.
- `accrue_admin/lib/accrue_admin/live/events_live.ex`, `event_live.ex`, `webhooks_live.ex`, `webhook_live.ex`, `coupons_live.ex`, `coupon_live.ex`, `promotion_codes_live.ex`, `promotion_code_live.ex`, `connect_accounts_live.ex`, `connect_account_live.ex`, `dashboard_live.ex`.
- `accrue_admin/lib/accrue_admin/components/global_search.ex`; `accrue_admin/lib/accrue_admin/copy.ex`; `accrue_admin/lib/accrue_admin/copy/billing_event.ex`; `accrue_admin/test/accrue_admin/components/global_search_test.exs`.
- `accrue_admin/assets/css/theme.css`, `accrue_admin/assets/css/app.css`.
- `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js`, `examples/accrue_host/e2e/phase234-search-completion.spec.js`.
