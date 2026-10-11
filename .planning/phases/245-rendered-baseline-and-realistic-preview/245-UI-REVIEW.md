# Phase 245 — UI Review

**Audited:** 2026-10-11  
**Baseline:** Approved [245-UI-SPEC.md](245-UI-SPEC.md), current ordinary-preview captures, Phase 245 findings ledger, and task-oriented Impeccable assessment  
**Screenshots:** Reviewed the 24 manifest-bound captures through the coverage/findings ledger and representative PNGs; one extra unmanifested PNG is present in the folder. No new captures made.  
**Interaction captures:** Captured (focused states in the Phase 245 evidence batch); broader interaction claims remain unverified as recorded in [245-COVERAGE.md](245-COVERAGE.md)

This is a quality assessment of the rendered Admin baseline and evidence scope. Phase 245's goal—an isolated, ordinary-data preview and a revision-bound rendered inventory—was achieved. The accepted UI findings below describe defects in the existing product UI and are routed to the later owning phases; they do not mean Phase 245's preview or inventory goal is blocked. The 245 findings ledger records five accepted current-render findings, route/state limitations, and the independent Impeccable assessment (22/40). It also records that the original broad visual critique covered the 19-route cohort; five supplemental captures were opened for their specific states, not treated as a second full critique.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | Several labels expose implementation language or imply action/empty-state meaning beyond the selected view. |
| 2. Visuals | 2/4 | Shared identity cells and filter planes compete with the task's primary information. |
| 3. Color | 3/4 | The light/dark palette is coherent, but Recovery uses success/warning treatments for explanatory metric copy. |
| 4. Typography | 3/4 | Geist and the token system are consistent; record names and exact IDs often merge into one scan line. |
| 5. Spacing | 2/4 | Repeated filter surfaces and uneven content density weaken grouping on collection and analytics screens. |
| 6. Experience Design | 2/4 | The capture proves a few interactions; key filter, activation, disclosure, and recovery behaviors remain unverified. |

**Overall: 14/24**

## Top 3 Priority Fixes

1. **Separate primary record identity from exact IDs in shared collection cells** — names and identifiers run together across Customers, Subscriptions, Invoices, Events, and Promotion codes, slowing record recognition — give the human-readable name a primary line and keep the exact copyable identifier secondary; Phase 246 shared table work.
2. **Give collections one clear filter hierarchy** — multiple filter rows/cards and repeated clear controls compete with the table and obscure applied constraints — consolidate the general search, secondary criteria, selected view, removable constraints, and reset action; Phase 246 shared filter owners.
3. **Make headings, metric labels, and status copy describe operator evidence plainly** — broad labels such as “Action required,” “Setup gap,” and “Money Saved” can overstate what a record or metric establishes — name the actual state and separate explanation from semantic status color; route collection copy to Phase 246 and Recovery/detail copy to Phase 247.

## Detailed Findings

### Pillar 1: Copywriting (2/4)

- **WARNING — implementation and task copy are mixed.** The shell says “Customer billing lookup” and “Search customers now” ([topbar.ex:29](../../../accrue_admin/lib/accrue_admin/components/topbar.ex#L29)); the dialog says “Open a scoped list” ([global_search.ex:290](../../../accrue_admin/lib/accrue_admin/components/global_search.ex#L290)). These labels emphasize system structure over the operator's task. C01 and C21 show the trigger and dialog; Phase 246 owns the shared search copy.
- **WARNING — attention language lacks a specific condition.** The subscription list shows “Action required” above two different states, including past due and unpaid, without identifying a supported next step in that label (C04; `copy/subscription.ex:108`). Phase 246 should tie attention language to a particular observed condition and action.
- **WARNING — filtered zero can read as an empty inventory.** In C14, the selected Needs attention view shows “Accounts 0” alongside “No connected accounts need attention.” The All accounts view was not selected, so the capture does not establish that the account inventory itself is empty. Clarify count and filtered-empty scope in ConnectAccountsLive / Phase 246 (`copy.ex:100`).
- The Recovery capture uses “Money Saved,” “Churned Revenue,” and a long formula explanation in the same compact metric area. “Showing data since 2024-01-01” also looks like scope information while acting as a link. Phase 247 should align labels with metric evidence and distinguish coverage notes from help.

### Pillar 2: Visuals (2/4)

- **WARNING — primary identity is difficult to scan.** C02, C04, C06, C15, and C12 show linked names directly adjacent to gray processor IDs; in Invoices, for example, `DEMO-UNCOLL-0006` runs into “Tidewater Systems” (C06). This is the shared F01 finding, owned by DataTable consumers and Phase 246; see `promotion_codes_live.ex:230` and `customers_live.ex:219` for representative renderers.
- **WARNING — filter composition competes with the table.** C14 shows five categorical controls, a “Clear filters” action, a separate FILTERS card with another selected view and another clear affordance, and then the empty state. C10 and C04 show the same split-plane pattern. This is F02, owned by `DataTable.filter_toolbar/1`, `FilterChipBar`, and consumers; Phase 246.
- **WARNING — dense detail and analytics hierarchy.** C05's Subscription detail compresses lifecycle, identity, metadata, and actions. C20's Recovery view puts lengthy amber/green explanatory text beside metrics, leaves one of four metric cards alone on a second row, and leaves large unused card areas. F03 is assigned to Phase 247 detail owners; Recovery's layout and metric hierarchy also belong to Phase 247.
- **WARNING — shell search takes persistent precedence.** C01 shows a two-line trigger, nested-looking action badge, shortcut, and persistent accent outline across the topbar. This is F04 and belongs to the Phase 246 shared shell/search review.

### Pillar 3: Color (3/4)

- **WARNING — semantic color carries explanatory copy.** In C20, explanatory Recovery text is placed in green “Amount saved by successful Dunning” pills and amber formula pills. Those colors imply success or warning for descriptive metric definitions, and the text competes with the metric value. The contract reserves semantic colors for supported status meaning and says not to color ordinary metric explanations as emphasis ([245-UI-SPEC.md](245-UI-SPEC.md), Color). Rework at the Recovery/KpiCard owner in Phase 247.
- The light and dark captures otherwise preserve a coherent paper/elevated/sunken palette and cobalt selection/focus treatment. The two Impeccable critiques call the palette a positive baseline; the token assignments are in `assets/css/theme.css:17-33` and `:151-178`. No blanket accent-overuse finding is supported by the current evidence.

### Pillar 4: Typography (3/4)

- **WARNING — identity hierarchy is typographic as well as spatial.** C02/C04/C06/C12/C15 render a human-readable name and a technical identifier at nearly equal prominence on the same line. The identifier's exact value remains visible, but it competes with the record name. Separate the label and secondary ID treatment in the shared identity-cell fix (F01, Phase 246).
- The contract calls for Geist/Geist Mono, explicit body/label/heading/display roles, and mono for exact technical values. Current captures retain that family and recognizable heading/body hierarchy, so the issue is not an unsupported claim that all typography diverges. However, several pages introduce compact labels and long prose alongside large names or metric values without enough distinction; C04 and C20 show the clearest cases. See typography roles in `theme.css:83-108` and the contract's roles in [245-UI-SPEC.md](245-UI-SPEC.md#typography).

### Pillar 5: Spacing (2/4)

- **WARNING — duplicate filter planes add vertical bulk without clarifying grouping.** C14's filter controls and separate applied-filter card occupy multiple rows before the empty state; C04 and C10 repeat this pattern. Consolidate the layout at shared owners rather than adjusting each page independently (F02, Phase 246; `data_table.ex:580`, `filter_chip_bar.ex:20`).
- **WARNING — density changes abruptly within a single task.** C06's invoice table has tall rows from wrapping and large gaps between the heading, counters, filters, and table; C20 has a long gap before the Recovery table and a visibly unbalanced 3+1 metric arrangement. The declared scale is documented in `theme.css:26-33`; the contract explicitly treats captures as an inventory of incumbent spacing, so these are rendered hierarchy findings, not a request to change tokens in Phase 245.

### Pillar 6: Experience Design (2/4)

- **WARNING — interactions are only partially evidenced.** The recorded captures show Control+K opening search and focusing its input, ArrowDown selection followed by pointer hover moving the active highlight, a customer Invoices tab, and an Activity disclosure. They do not verify Enter activation, focus restoration, pointer/keyboard selection parity, filter URL/query/count agreement, clear-one/reset-all scope, clipboard feedback, loaded activity, or touch operation. The recorded C22 after-state has one active item; it neither reproduces nor disproves the reported simultaneous-highlight issue. Keep these behaviors unaccepted until the owning phases exercise them; evidence boundaries are enumerated in [245-COVERAGE.md](245-COVERAGE.md) and [245-FINDINGS.md](245-FINDINGS.md).
- **WARNING — selected filtered-zero copy and controls do not yet make state scope self-evident.** C14's selected Needs attention view reports zero accounts while the copy can be read as an inventory-wide empty state; the selected All accounts alternative was not tested. F05 is a Phase 246 copy/count issue. Do not infer query correctness from the capture.
- **WARNING — other important states remain gaps, not passes.** The route ledger covers 21 production templates and marks unavailable/not-applicable rows explicitly. It does not establish every detail route, genuinely empty/loading/error state, owner/role scope, all disclosures, or action outcomes. In particular, no destructive actions or replay outcomes were triggered, and the Recovery capture only proves the recorded ready state and visible ordinary data. The mechanical detector's `[]` result is limited to its scanned components and is not an accessibility conformance result.
- **WARNING — the capture folder has one file outside the canonical manifest.** The manifest binds 24 PNGs, while `captures/phase245-current/` contains 25; `16-rootevents-wide-light.png` is not listed in the manifest. It is excluded from the accepted evidence set. Reconcile this extra file before using folder contents as the authoritative batch; the phase summary and revision-bound manifest remain the provenance source.
- **No Phase 245 blocker identified.** The ordinary preview and revision/asset-bound baseline are usable for the next phases. The warnings above are concrete baseline defects and evidence gaps; none is shown to prevent Phase 245's seed, capture, or inventory task from completing.

## Files Audited

- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-UI-SPEC.md`
- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-CONTEXT.md`
- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-01-PLAN.md`, `245-02-PLAN.md`, `245-03-PLAN.md`
- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-01-SUMMARY.md`, `245-02-SUMMARY.md`, `245-03-SUMMARY.md`
- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md`, `245-FINDINGS.md`, `245-ORDINARY-STORIES.md`
- `.planning/notes/2026-10-11-admin-owner-feedback.md`
- `captures/manifest.json` and `captures/phase245-current/` (24 manifest-bound captures; one additional unmanifested PNG noted above)
- `accrue_admin/assets/css/theme.css`
- `accrue_admin/lib/accrue_admin/components/topbar.ex`, `global_search.ex`, `data_table.ex`, `filter_chip_bar.ex`
- `accrue_admin/lib/accrue_admin/live/customers_live.ex`, `subscriptions_live.ex`, `promotion_codes_live.ex`
- `accrue_admin/lib/accrue_admin/copy.ex`, `copy/subscription.ex`
