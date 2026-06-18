# Phase 190 Group Contracts

Canonical Wave 0 contract ledger for recurring `accrue_admin` component groups.

Source of truth: `AccrueAdmin.Dev.ComponentRegistry.group_contracts/0`.
Proof surface: `/billing/dev/components`.
Locator contract: each proof specimen and representative probe uses a static `data-component-group` slug derived from the frozen Phase 187 `COMPONENT_GROUPS` names.

## Contract Rows

| Group | Slug | Proof ID | Required States | Primary Components | Representative Route Category | Phase 191 Handoff Tags | Decision Coverage |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `page-header/actions/breadcrumbs` | `page-header-actions-breadcrumbs` | `grp190-page-header-actions-breadcrumbs` | long-content, overflow, mobile-wrap, dark-mode | Breadcrumbs, Button, AppShell page header | admin page header | liveview-patch-focus, microcopy | D-01, D-02, D-04, D-05, D-06, D-16, D-17, D-20, D-21, D-22, D-30 |
| `toolbar/search/filter/sort` | `toolbar-search-filter-sort` | `grp190-toolbar-search-filter-sort` | long-content, overflow, filtered-empty, selected-filter-active, mobile-wrap, dark-mode | DataTable filters, FilterChipBar, GlobalSearch, DropdownMenu | list toolbar | liveview-patch-focus, fixture-gaps, microcopy | D-01, D-02, D-04, D-05, D-06, D-07, D-12, D-13, D-17, D-23, D-24, D-27, D-30 |
| `table/empty/loading/error/pagination` | `table-empty-loading-error-pagination` | `grp190-table-empty-loading-error-pagination` | long-content, overflow, empty, filtered-empty, loading, error, no-pagination, has-pagination, selected-filter-active, mobile-card-list-degradation, dark-mode | DataTable, EmptyState, Spinner, StatusBadge, Button | list and table page | scroll-reachability, fixture-gaps, microcopy | D-01, D-02, D-04, D-05, D-06, D-08, D-10, D-11, D-12, D-13, D-14, D-29, D-30 |
| `KPI/chart/table` | `kpi-chart-table` | `grp190-kpi-chart-table` | long-content, overflow, empty, loading, error, no-pagination, has-pagination, mobile-card-list-degradation, dark-mode | KpiCard, FunnelChart, AtRiskTable, DataTable | recovery analytics | fixture-gaps, microcopy | D-01, D-02, D-04, D-05, D-06, D-09, D-15, D-17, D-18, D-19, D-21, D-30 |
| `detail-header/metadata/actions` | `detail-header-metadata-actions` | `grp190-detail-header-metadata-actions` | long-content, overflow, loading, error, mobile-wrap, dark-mode | Detail, RelatedResources, StatusBadge, InlineId, Button | detail page | fixture-gaps, microcopy | D-01, D-02, D-03, D-04, D-05, D-06, D-16, D-17, D-18, D-19, D-20, D-21, D-30 |
| `modal-confirm` | `modal-confirm` | `grp190-modal-confirm` | long-content, overflow, loading, error, mobile-stack, dark-mode | StepUpAuthModal, Button, Icon | overlay confirmation | focus-trap, focus-restore, escape, click-outside, scroll-reachability, overlay-position, microcopy | D-01, D-02, D-04, D-05, D-06, D-23, D-24, D-25, D-26, D-30 |
| `drawer/form` | `drawer-form` | `grp190-drawer-form` | long-content, overflow, loading, error, selected-filter-active, mobile-fullscreen, dark-mode | DetailDrawer, Input, Select, Textarea, Button | drawer edit flow | focus-trap, focus-restore, escape, click-outside, scroll-reachability, overlay-position, fixture-gaps, microcopy | D-01, D-02, D-04, D-05, D-06, D-20, D-23, D-24, D-25, D-26, D-30 |
| `tabs/subviews` | `tabs-subviews` | `grp190-tabs-subviews` | long-content, overflow, selected-filter-active, mobile-scroll, dark-mode | Tabs, WindowSelector, Breadcrumbs | route subnavigation | liveview-patch-focus, microcopy | D-01, D-02, D-04, D-05, D-06, D-17, D-23, D-24, D-28, D-30 |

## Rendered Lab Status

Implemented in Plan `190-02`: `/billing/dev/components` renders one proof root per contract using `id="{Proof ID}"` and `data-component-group="{Slug}"`. Each proof root is registry-driven from `ComponentRegistry.group_contracts/0` and exposes its implemented states through `data-group-state` chips plus concrete specimen markup.

| Slug | Proof ID | Rendered Lab Status | Implemented Specimen States |
| --- | --- | --- | --- |
| `page-header-actions-breadcrumbs` | `grp190-page-header-actions-breadcrumbs` | implemented | long-content, overflow, mobile-wrap, dark-mode |
| `toolbar-search-filter-sort` | `grp190-toolbar-search-filter-sort` | implemented | long-content, overflow, filtered-empty, selected-filter-active, mobile-wrap, dark-mode |
| `table-empty-loading-error-pagination` | `grp190-table-empty-loading-error-pagination` | implemented | long-content, overflow, empty, filtered-empty, loading, error, no-pagination, has-pagination, selected-filter-active, mobile-card-list-degradation, dark-mode |
| `kpi-chart-table` | `grp190-kpi-chart-table` | implemented | long-content, overflow, empty, loading, error, no-pagination, has-pagination, mobile-card-list-degradation, dark-mode |
| `detail-header-metadata-actions` | `grp190-detail-header-metadata-actions` | implemented | long-content, overflow, loading, error, mobile-wrap, dark-mode |
| `modal-confirm` | `grp190-modal-confirm` | implemented | long-content, overflow, loading, error, mobile-stack, dark-mode |
| `drawer-form` | `grp190-drawer-form` | implemented | long-content, overflow, loading, error, selected-filter-active, mobile-fullscreen, dark-mode |
| `tabs-subviews` | `grp190-tabs-subviews` | implemented | long-content, overflow, selected-filter-active, mobile-scroll, dark-mode |

## Hierarchy Rules

| Group | Required Order |
| --- | --- |
| `page-header/actions/breadcrumbs` | orientation -> task heading -> supporting copy -> primary and secondary actions |
| `toolbar/search/filter/sort` | filter label -> search/filter/sort controls -> active constraints -> apply or clear action |
| `table/empty/loading/error/pagination` | table caption or label -> column/card identity -> row facts/status -> row actions -> cursor-gated footer |
| `KPI/chart/table` | summary metrics -> trend evidence -> row evidence -> drill-down actions |
| `detail-header/metadata/actions` | eyebrow -> title or ID -> status -> primary facts -> actions |
| `modal-confirm` | title -> description -> object consequence -> cancel action -> confirm action |
| `drawer/form` | title -> description -> form body -> field errors -> footer actions |
| `tabs/subviews` | current route label -> tab labels -> counts -> active indicator |

## Phase 191 Handoff Categories

These tags are intentionally recorded as Phase 191 handoff items, not completed Wave 0 behavior:

- focus-trap
- focus-restore
- escape
- click-outside
- scroll-reachability
- overlay-position
- liveview-patch-focus
- fixture-gaps
- microcopy

## Decision Coverage Rows

| Decision | Implemented or Bounded |
| --- | --- |
| D-01 | Hybrid proof model: this ledger and `group_contracts/0` establish `/billing/dev/components` as the canonical proof surface, with live routes reserved for representative probes. |
| D-02 | Every Phase 187 group name has a stable static slug for `data-component-group`. |
| D-03 | `detail-header/metadata/actions` receives a dedicated contract row and proof ID to close the Phase 187 visibility gap. |
| D-04 | No PhoenixStorybook, per-group routes, pixel snapshots, second visual axis, or dependency additions are introduced. |
| D-05 | Phase 187 group names and cell-id grammar remain frozen; only selectors and specimens use the slugs. |
| D-06 | Operator-stress state ownership is recorded across long content, overflow, empty, filtered-empty, loading, error, pagination, selected/filter-active, mobile degradation, and dark mode. |
| D-07 | Representative live probes remain narrow: list/table, detail, recovery/KPI, overlay, and shell/nav/tabs categories only. |
| D-08 | DataTable stays the canonical renderer for entity queues. |
| D-09 | Specialized displays such as AtRiskTable and KPI/chart/table retain their shape while owning the shared data-display contract. |
| D-10 | DataTable desktop table plus mobile card mode is the default for dense operator queues. |
| D-11 | Responsive table/card modes must avoid duplicate accessible DOM and duplicate focus targets. |
| D-12 | Pagination appears only when a next cursor or equivalent exists. |
| D-13 | Filtered-empty and true-empty states have separate contract ownership. |
| D-14 | Tables degrade to cards/lists at narrow widths unless data is machine-like and requires overflow. |
| D-15 | AtRiskTable is the specialized-table exemplar for the shared data-display contract. |
| D-16 | This is a small group contract, not a broad layout framework. |
| D-17 | Group order and hierarchy are explicit in the hierarchy rules table. |
| D-18 | Nested card/box-prison risk is bounded by the KPI/detail/group contract rows. |
| D-19 | New group implementation work must consume existing `ax-*` spacing, radius, type, and layer tokens. |
| D-20 | Phoenix attrs/slots remain the intended implementation path where repeated markup creates drift. |
| D-21 | Kitchen specimens are proof specimens, not a public documentation site. |
| D-22 | Dark-mode proof follows the global theme toggle rather than side-by-side columns. |
| D-23 | Overlay and meta-component groups are explicitly named: modal-confirm, drawer/form, toolbar/search/filter/sort, tabs/subviews, and related search/dropdown roots. |
| D-24 | Phase 190 changes remain limited to spacing rhythm, hierarchy, next action, responsive degradation, stress states, layer tokens, and reusable layout. |
| D-25 | Full focus traps, scroll locking, Escape/click-outside coverage, LiveView patch focus recovery, fixture expansion, and broad microcopy cleanup remain Phase 191. |
| D-26 | Modal and drawer rows define structure, IDs, action order, sizing, body/footer rhythm, and layer ownership while handing focus behavior to Phase 191. |
| D-27 | Dropdown semantics are bounded under toolbar/search/filter/sort and must resolve to disclosure or true menu-button semantics in later implementation. |
| D-28 | Tabs and window selectors remain link-navigation with `aria-current="page"` unless same-page panels are introduced. |
| D-29 | Pagination visual/group behavior is Phase 190; cursor stress and page-flow fixture behavior remain Phase 191 when fixture-dependent. |
| D-30 | Phase 191 handoff tags are listed above and keyed to group rows. |

## Static Safety

All slugs are static lowercase strings containing only letters, numbers, and hyphens. They must not include account, customer, invoice, subscription, webhook, event, or other runtime billing identifiers.
