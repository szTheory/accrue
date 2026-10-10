# Phase 242 — UI Review

**Audited:** 2026-10-10  
**Baseline:** Approved Phase 242 UI-SPEC.md and locked D-01/D-16/D-17 decisions  
**Screenshots:** No new captures. Reused the single phase-level visual observation recorded in 242-EXECUTION-GATES.md (Connect detail, 1280×900, system appearance); the other surfaces were not visually inspected.  
**Interaction captures:** off (interaction_capture=false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | The rendered events filtered-empty heading differs from the approved exact copy. |
| 2. Visuals | 3/4 | The inspected Connect detail facts were legible; the shared header showed a broken brand logo, and other surfaces lack visual inspection. |
| 3. Color | 3/4 | Theme roles are established, but a table override duplicates dark token colors as four `!important` literals. |
| 4. Typography | 2/4 | The shared body class uses 1.5 line height where the contract specifies 1.4. |
| 5. Spacing | 2/4 | Home’s standalone shortcut actions remain 32px high, below the approved coarse-pointer target direction. |
| 6. Experience Design | 3/4 | Mounted assertions cover the principal flows; the global search and changed detail surfaces were not visually captured. |

**Overall: 16/24**

---

## Top 3 Priority Fixes

1. **Align body line height with the contract** — body copy across these screens is looser than the specified 1.4 rhythm — set the shared `.ax-body` role to the normal 1.4 token and reserve relaxed leading for long-form prose.
2. **Enlarge Home shortcut targets for coarse pointers** — the three prominent Home actions are small standalone targets on intermediate touch layouts — add a coarse-pointer rule giving those actions at least 44px clickable height.
3. **Use the approved events empty-state title** — filtered searches show a different phrase than the design contract — route the rendered state through the approved BillingEvent copy (`No ledger rows match these filters.`).

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** The approved filtered-empty title is `No ledger rows match these filters.` ([UI-SPEC.md, copy contract](242-UI-SPEC.md:101)). `EventsLive` obtains empty-state text from `Copy.resource_state_copy/2` ([events_live.ex](../../../accrue_admin/lib/accrue_admin/live/events_live.ex:374)); the resource state currently says `No event ledger rows match these filters.` ([copy.ex](../../../accrue_admin/lib/accrue_admin/copy.ex:128)). The mounted assertion confirms that the latter is what renders ([phase238-admin-events-webhooks.spec.js](../../../examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js:203)). `Copy.BillingEvent.events_list_filtered_empty_title/0` already has the approved wording ([billing_event.ex](../../../accrue_admin/lib/accrue_admin/copy/billing_event.ex:19)); use one canonical string and assert the rendered value against it.
- The other audited copy paths name the resources distinctly (delivery vs. event, coupon vs. promotion code) and have explicit unavailable/retry and replay-review wording. The existing first-run empty copy matches the contract.

### Pillar 2: Visuals (3/4)

- The only existing inspected view was Connect detail. The execution record says its summary, stored-snapshot note, unknown fields, and local fee policy were legible. It also records a broken brand logo at the top left ([242-EXECUTION-GATES.md](242-EXECUTION-GATES.md:59)); this is a visible shared-shell defect, though it is outside Phase 242’s changed UI and was not modified.
- Source hierarchy follows the contract’s resource identity → observed facts/uncertainty → supported action → related evidence order in the audited detail and review views. For example, webhook detail leads with the replay action and its eligibility before lazy Activity and Raw payload ([webhook_live.ex](../../../accrue_admin/lib/accrue_admin/live/webhook_live.ex:227), [webhook_live.ex](../../../accrue_admin/lib/accrue_admin/live/webhook_live.ex:277)).
- Events, delivery, catalog, Home, and global-search visual hierarchy was not inspected in a screenshot. Do not treat this source-based assessment as visual confirmation; Phase 243 owns final Linux goldens and stable preview.

### Pillar 3: Color (3/4)

- The package theme defines the specified Cobalt, neutral surface, and intent roles in `--ax-*` tokens ([theme.css](../../../accrue_admin/assets/css/theme.css:137), [theme.css](../../../accrue_admin/assets/css/theme.css:230)). The composition guide is not a pixel-count requirement; no broad accent overuse was established by source review.
- **WARNING:** Table colors bypass those roles in two dark-theme selectors with `!important`: `#171d24` for the surface and `#f4f7fa` for links, repeated in the System-dark media rule ([app.css](../../../accrue_admin/assets/css/app.css:4365), [app.css](../../../accrue_admin/assets/css/app.css:4373)). These currently equal `--ax-elevated` and `--ax-primary`, so no present contrast defect is claimed. Replace them with the tokens to preserve theme ownership and avoid drift.
- Execution evidence includes emulated Light/Dark/System theme checks for the covered flows; it does not claim physical-device or host-forced-theme proof.

### Pillar 4: Typography (2/4)

- **WARNING:** The contract specifies Body as 16px/400/1.4 ([UI-SPEC.md, Typography](242-UI-SPEC.md:89)). The global `.ax-body` uses `--ax-type-body-relaxed-font` ([app.css](../../../accrue_admin/assets/css/app.css:914)), whose theme token is 16px/400/1.5 ([theme.css](../../../accrue_admin/assets/css/theme.css:87)). Because this class is used across routine page, fact, empty-state, and error copy, this is a shared role mismatch. Reserve 1.5 leading for prose roles and use the 1.4 body token here.
- The theme defines the specified Geist/Geist Mono families and 400/600 role weights; technical code roles are separated from prose ([theme.css](../../../accrue_admin/assets/css/theme.css:13), [theme.css](../../../accrue_admin/assets/css/theme.css:82)). Source confirms role assignment, but the single screenshot does not verify rendered font loading across the audited routes.

### Pillar 5: Spacing (2/4)

- **WARNING:** Home’s primary shortcuts and customer-search action use `.ax-button-sm` ([dashboard_live.ex](../../../accrue_admin/lib/accrue_admin/live/dashboard_live.ex:42), [dashboard_live.ex](../../../accrue_admin/lib/accrue_admin/live/dashboard_live.ex:45), [dashboard_live.ex](../../../accrue_admin/lib/accrue_admin/live/dashboard_live.ex:54)). The shared rule sets a 2rem (32px) minimum height ([app.css](../../../accrue_admin/assets/css/app.css:3322)). The coarse-pointer rule raises table links and drawer-form buttons only ([app.css](../../../accrue_admin/assets/css/app.css:4353)); it does not cover these Home actions. This misses the approved 44px direction for prominent standalone task controls at intermediate touch widths. The reported browser geometry checks do not claim these Home actions were measured.
- The 4px spacing ladder and approved 2px dense-data / 1px structural exceptions remain represented by package tokens. No new arbitrary spacing scale was introduced in the audited phase surfaces.

### Pillar 6: Experience Design (3/4)

- Focused browser evidence covers the current event filtered membership/source relationship and webhook replay review, plus search pointer → Arrow → Enter destination behavior ([phase238-admin-events-webhooks.spec.js](../../../examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js:196), [phase234-search-completion.spec.js](../../../examples/accrue_host/e2e/phase234-search-completion.spec.js:26)). Package browser owners also cover catalog/Connect review, dismissal/focus, responsive/theme emulation and atomic text stress as recorded in the execution gates.
- Source provides distinct loading, filtered-empty, first-run, unavailable, partial-failure and unknown-result states in the audited list/detail and search implementations; destructive replay and fee changes retain explicit review and dismissal behavior. This review credits only the named owners and the recorded executions, not every state on every route.
- No interaction screenshot was taken because capture was disabled. Phase acceptance is automated; actual browser zoom, physical-device behavior, screen-reader speech, live-provider behavior, remote CI, and Phase 243 Linux goldens remain unclaimed. These are evidence limits, not additional human approval gates.

---

## Files Audited

- `.planning/phases/242-investigations-and-remaining-admin-surfaces/242-01` through `242-07` PLAN and SUMMARY artifacts; `242-UI-SPEC.md`, `242-CONTEXT.md`, `242-EXECUTION-GATES.md`, `242-VALIDATION.md`; root `CLAUDE.md`.
- `accrue_admin/lib/accrue_admin/live/events_live.ex`, `event_live.ex`, `webhooks_live.ex`, `webhook_live.ex`, `coupons_live.ex`, `coupon_live.ex`, `promotion_codes_live.ex`, `promotion_code_live.ex`, `connect_accounts_live.ex`, `connect_account_live.ex`, `dashboard_live.ex`.
- `accrue_admin/lib/accrue_admin/components/global_search.ex`; `accrue_admin/lib/accrue_admin/copy.ex`; `accrue_admin/lib/accrue_admin/copy/billing_event.ex`.
- `accrue_admin/assets/css/theme.css`, `accrue_admin/assets/css/app.css`.
- `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js`, `examples/accrue_host/e2e/phase234-search-completion.spec.js`.
