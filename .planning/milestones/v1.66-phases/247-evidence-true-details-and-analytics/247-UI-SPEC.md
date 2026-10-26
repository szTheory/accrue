---
phase: "247"
slug: "evidence-true-details-and-analytics"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-11"
---

# Phase 247 — UI Design Contract

> Operate-mode refinement contract for existing Admin detail, webhook investigation, timestamp and recovery analytics surfaces. Preserve Accrue's established visual system and evidence boundaries. Refine shared owners; do not add a dependency, new billing capability, or broad redesign.

## Design System

| Property | Value |
|----------|-------|
| Tool | Accrue Admin in-repository design system; no shadcn |
| Preset | Not applicable |
| Component library | Custom Phoenix LiveView function components in `accrue_admin/lib/accrue_admin/components/` |
| Icon library | Existing inline Heroicons via `AccrueAdmin.Components.Icon` |
| Font | Self-hosted Geist and Geist Mono with existing system fallbacks |

Use the incumbent `PageHeader`, `Detail`, `Breadcrumbs`, `InlineId`/`IdBadge`, `StatusBadge`, `JsonViewer`, `KpiCard`, `WindowSelector`, `Tooltip`, `EmptyState`, `FlashGroup` and `AppShell` owners where applicable. Use existing `--ax-*` semantic roles and spacing/type tokens from `accrue_admin/assets/css/theme.css`; keep light/dark values and host theme behavior intact. Avoid page-local framing and token changes.

## Component Inventory

Enumerated by `rg --files accrue_admin/lib/accrue_admin/components -g '*.ex' | sort | wc -l` — 43 component source files — `accrue_admin@1.6.0` (version from `accrue_admin/mix.exs`) — 2026-10-11. This sample is non-exhaustive and not a closed allowlist; inspect the source inventory for other suitable components.

| Component | Import path | Notes |
|-----------|-------------|-------|
| PageHeader | `AccrueAdmin.Components.PageHeader` | Page identity, real breadcrumbs, concise description and page-level actions |
| Detail | `AccrueAdmin.Components.Detail` | Shared summary hierarchy, field lists and titled detail sections |
| Breadcrumbs | `AccrueAdmin.Components.Breadcrumbs` | Native links that reflect actual parent hierarchy and destination names |
| InlineId / IdBadge | `AccrueAdmin.Components.InlineId`, `AccrueAdmin.Components.IdBadge` | Exact secondary identifiers with incumbent copy behavior |
| StatusBadge | `AccrueAdmin.Components.StatusBadge` | Short evidence-backed state labels; color never carries meaning alone |
| JsonViewer | `AccrueAdmin.Components.JsonViewer` | Exact JSON inspection with accessible Tree/Raw tabs and separate Copy action |
| KpiCard | `AccrueAdmin.Components.KpiCard` | Comparable recovery metrics with definitions in ordinary body/meta text |
| WindowSelector | `AccrueAdmin.Components.WindowSelector` | Existing shared UTC analytics-window control |
| Tooltip | `AccrueAdmin.Components.Tooltip` | Supplemental help, available to keyboard and touch users |
| EmptyState / FlashGroup | `AccrueAdmin.Components.EmptyState`, `AccrueAdmin.Components.FlashGroup` | Truthful empty, error, success and action feedback states |
| AppShell | `AccrueAdmin.Components.AppShell` | One persistent Local/UTC preference shared across Admin routes |

## Spacing Scale

Use the established 4px-based scale and current `--ax-space-*` tokens. Keep section hierarchy deliberate and denser metadata aligned to the existing detail grammar.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label and inline metadata gaps |
| sm | 8px | Compact label/value and control-group spacing |
| md | 16px | Detail field groups, description spacing and card padding |
| lg | 24px | Separation between page identity and primary investigation sections |
| xl | 32px | Major section/layout gaps where the incumbent surface uses them |
| 2xl | 48px | Page-level separation |
| 3xl | 64px | Major page-level separation |

Exceptions: interactive timestamp and icon-only controls keep the established minimum 44×44px target; do not reduce that target to fit inline metadata. No new spacing tokens.

## Typography

Use current Geist roles and tabular-number behavior for amounts. Reserve monospace for exact IDs, keys, timestamps and raw payload evidence.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px | 400 | 1.4 |
| Label / metadata | 14px | 600 | 1.4 |
| Section heading | 20px | 600 | 1.2 |
| Page title / metric | 28px | 600 | 1.2 |

Weights: regular 400 and semibold 600 only. Exact values use the existing Geist Mono family at the nearest declared text size; do not introduce a new type scale or font.

## Color

Use the existing semantic theme tokens in both light and dark themes; the 60/30/10 split describes visual area, not data or state severity.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `--ax-base` (existing theme canvas) | Main page canvas and primary reading surface |
| Secondary (30%) | `--ax-elevated` and `--ax-sunken` | Navigation, detail regions, fields, controls and metric groups |
| Accent (10%) | `--ax-accent` / `--ax-accent-readable` | Primary eligible action, links, selected UTC-window choice and visible keyboard focus |
| Destructive | `--ax-danger` / readable semantic variants | Destructive actions or evidence-supported danger state only |

Accent reserved for: primary eligible action, links, selected range choice and visible keyboard focus. Use `--ax-success`, `--ax-warning`, `--ax-info` and `--ax-danger` only for their named, supported state. Ordinary populated values and explanatory metric definitions remain neutral; status text remains explicit and understandable without color.

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | `Replay webhook` — show only for an eligible webhook; its confirmation action reads `Confirm replay` |
| Secondary CTA | `Cancel replay` — dismisses the replay review only; it does not cancel an already queued or processing replay. |
| Empty state heading | `No dispatch attempts recorded yet` |
| Empty state body | `No dispatch attempts are recorded for this webhook.` Keep this as one coherent history empty state; split billing and dispatch histories only when the distinction helps investigation. |
| Error state | Clipboard failure: `Clipboard unavailable. Select and copy the UTC timestamp below.` Keep the exact ISO value visibly selectable. For an existing data-load error, state what could not load and offer only the supported retry or return path. |
| Destructive confirmation | None introduced. Preserve the existing replay confirmation: `Replay webhook {id} for {owner}: This will requeue the webhook delivery and record an admin audit event. Confirm replay.` Replay stays subject to current owner, eligibility, authorization and step-up checks. |

Use concrete destinations such as `Payments`, `Invoices`, `Webhooks` and `Payment recovery`, aligned across navigation, page headings and breadcrumbs. A breadcrumb names the real parent (the webhook parent is `Webhooks`); omit artificial roots. Status copy names observed state and nearby evidence. Missing plan, fee, snapshot or history stays unavailable/absent and never implies pending, success, failure, completion or misconfiguration. The analytics window is explicitly UTC; the separate data-coverage note does not look like a range control, and any help link describes its documentation destination.

## Interaction and Information Hierarchy

- Put record identity and a concise observed status in the shared page header. Order detail content as observed issue/state and supported next action, useful metadata, activity/history, then payload. Remove redundant inspector eyebrow/card framing and repeated IDs/status/times without investigative value. Keep exact IDs and keys available and copyable.
- Show one shared `Local` / `UTC` display preference in the Admin shell. In Local mode, every date-time includes the resolved timezone name; server-rendered fallback is explicitly UTC before client formatting. Persist the choice across Admin routes. If browser storage is unavailable, keep the current interaction usable in the session and preserve the UTC fallback. Date-only values remain date-only; analytics query boundaries stay UTC.
- A real timestamp is keyboard- and touch-activatable with a visible focus state and at least a 44×44px target. Copy the source's exact ISO 8601 UTC instant, including available precision, independently of its display. Announce success only after clipboard write resolves. When clipboard access is absent or fails, show the selectable exact UTC value and manual-copy instructions; do not show success. Missing time is plain unavailable text, never an interactive affordance.
- Replay has one coherent action section, one `Replay webhook` action when eligible, and short plain-language eligibility/effect copy. Remove DLQ implementation narration. Preserve the existing confirmation, current owner scope, action-time authorization and step-up. An accepted/queued replay is not completed processing; result feedback must state acceptance without claiming delivery success.
- In the existing replay review, label the secondary dismissal action `Cancel replay` so its effect is clear. It only dismisses the review and never cancels queued or processing work; keep confirmation, authorization, owner scope, step-up, and mutation behavior unchanged.
- Make Activity and Payload disclosures visibly recognizable and keyboard-operable, with expanded state exposed accessibly. Keep useful lazy loading. Empty history is one coherent empty state unless separate histories aid investigation. `Tree` and `Raw` are consistent tabs; `Copy` is a separate action. Preserve exact JSON and disclosure behavior.
- Shared detail metadata/copy patterns may include a small `Copy details` action containing only an allowlisted plain-text summary of visible IDs, exact UTC times and observed state. Never include secrets or raw payload by default; do not create an export flow. Keep copy content within the same owner and permission scope as the visible detail.
- Recovery analytics groups comparable metrics by currency, pairing related recovered/exhausted measures per currency. Keep supported amount, actual zero, absent value and unsupported currency visibly distinct; absent/unsupported never becomes zero or an invented amount. Keep existing formulas. Describe recurring monthly revenue separately from cash recovered and confirmed churn. Put a concise definition in body/help text, not a delta pill; remove duplicated definitions and unsupported `Money saved` / `Churned revenue` claims.
- Align the UTC window selector with shared control spacing. Keep the selected window distinct from historical data coverage; the coverage note is informational and any help control names its destination. Keep comparison groups balanced across wide and narrow layouts without combining currencies.
- Navigation and contextual links name a concrete destination and retain only record/task context supported by the route. Help supplements a visible primary label and is operable by keyboard and touch.

## UI Considerations

Engine: ui-consideration-probe.cjs; agent-confirmed element kinds, auto mode. 47 applicable items, all resolved with explicit acceptance; zero unclassified. Each row is independently owned by the named surface and must lift into plan truths/test coverage.

| Element | Category | Status | Explicit acceptance criterion |
|---|---|---|---|
| TIME | empty | resolved (explicit) | Absent instants have no copy control; missing metadata is unavailable; empty history has one explanation; empty analytics yields no invented currency group; replay missing eligibility cannot expose an eligible action. |
| TIME | loading | resolved (explicit) | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| TIME | error | resolved (explicit) | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| TIME | partial | resolved (explicit) | Missing time/fee/plan/snapshot/history is explicitly unavailable or absent, never inferred pending/misconfiguration; actual zero stays distinct; each present authorized value remains readable. |
| TIME | overflow | resolved (explicit) | Long IDs, ISO values, JSON and currency groups wrap or scroll within their container with no horizontal page overflow at320px; copy retains full values. |
| TIME | long-text | resolved (explicit) | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |
| NAV | loading | resolved (explicit) | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| NAV | error | resolved (explicit) | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| NAV | overflow | resolved (explicit) | Long IDs, ISO values, JSON and currency groups wrap or scroll within their container with no horizontal page overflow at320px; copy retains full values. |
| NAV | long-text | resolved (explicit) | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |
| DETAIL | empty | resolved (explicit) | Absent instants have no copy control; missing metadata is unavailable; empty history has one explanation; empty analytics yields no invented currency group; replay missing eligibility cannot expose an eligible action. |
| DETAIL | loading | resolved (explicit) | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| DETAIL | error | resolved (explicit) | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| DETAIL | populated | resolved (explicit) | Record identity, concise observed status, supported next action and exact secondary evidence read in that order; per-currency recovered/exhausted values retain query output. |
| DETAIL | partial | resolved (explicit) | Missing time/fee/plan/snapshot/history is explicitly unavailable or absent, never inferred pending/misconfiguration; actual zero stays distinct; each present authorized value remains readable. |
| DETAIL | overflow | resolved (explicit) | Long IDs, ISO values, JSON and currency groups wrap or scroll within their container with no horizontal page overflow at320px; copy retains full values. |
| DETAIL | zero-one-many | resolved (explicit) | Zero/one/many history and currency rows retain readable hierarchy without synthesized records or combined currencies. |
| DETAIL | long-text | resolved (explicit) | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |
| REPLAY | empty | resolved (explicit) | Absent instants have no copy control; missing metadata is unavailable; empty history has one explanation; empty analytics yields no invented currency group; replay missing eligibility cannot expose an eligible action. |
| REPLAY | loading | resolved (explicit) | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| REPLAY | error | resolved (explicit) | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| REPLAY | partial | resolved (explicit) | Missing time/fee/plan/snapshot/history is explicitly unavailable or absent, never inferred pending/misconfiguration; actual zero stays distinct; each present authorized value remains readable. |
| REPLAY | long-text | resolved (explicit) | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |
| HISTORY | empty | resolved (explicit) | Absent instants have no copy control; missing metadata is unavailable; empty history has one explanation; empty analytics yields no invented currency group; replay missing eligibility cannot expose an eligible action. |
| HISTORY | loading | resolved (explicit) | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| HISTORY | error | resolved (explicit) | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| HISTORY | populated | resolved (explicit) | Record identity, concise observed status, supported next action and exact secondary evidence read in that order; per-currency recovered/exhausted values retain query output. |
| HISTORY | partial | resolved (explicit) | Missing time/fee/plan/snapshot/history is explicitly unavailable or absent, never inferred pending/misconfiguration; actual zero stays distinct; each present authorized value remains readable. |
| HISTORY | overflow | resolved (explicit) | Long IDs, ISO values, JSON and currency groups wrap or scroll within their container with no horizontal page overflow at320px; copy retains full values. |
| HISTORY | zero-one-many | resolved (explicit) | Zero/one/many history and currency rows retain readable hierarchy without synthesized records or combined currencies. |
| HISTORY | long-text | resolved (explicit) | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |
| JSON | empty | resolved (explicit) | Absent instants have no copy control; missing metadata is unavailable; empty history has one explanation; empty analytics yields no invented currency group; replay missing eligibility cannot expose an eligible action. |
| JSON | loading | resolved (explicit) | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| JSON | error | resolved (explicit) | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| JSON | populated | resolved (explicit) | Record identity, concise observed status, supported next action and exact secondary evidence read in that order; per-currency recovered/exhausted values retain query output. |
| JSON | partial | resolved (explicit) | Missing time/fee/plan/snapshot/history is explicitly unavailable or absent, never inferred pending/misconfiguration; actual zero stays distinct; each present authorized value remains readable. |
| JSON | overflow | resolved (explicit) | Long IDs, ISO values, JSON and currency groups wrap or scroll within their container with no horizontal page overflow at320px; copy retains full values. |
| JSON | zero-one-many | resolved (explicit) | Zero/one/many history and currency rows retain readable hierarchy without synthesized records or combined currencies. |
| JSON | long-text | resolved (explicit) | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |
| METRICS | empty | resolved (explicit) | Absent instants have no copy control; missing metadata is unavailable; empty history has one explanation; empty analytics yields no invented currency group; replay missing eligibility cannot expose an eligible action. |
| METRICS | loading | resolved (explicit) | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| METRICS | error | resolved (explicit) | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| METRICS | populated | resolved (explicit) | Record identity, concise observed status, supported next action and exact secondary evidence read in that order; per-currency recovered/exhausted values retain query output. |
| METRICS | partial | resolved (explicit) | Missing time/fee/plan/snapshot/history is explicitly unavailable or absent, never inferred pending/misconfiguration; actual zero stays distinct; each present authorized value remains readable. |
| METRICS | overflow | resolved (explicit) | Long IDs, ISO values, JSON and currency groups wrap or scroll within their container with no horizontal page overflow at320px; copy retains full values. |
| METRICS | zero-one-many | resolved (explicit) | Zero/one/many history and currency rows retain readable hierarchy without synthesized records or combined currencies. |
| METRICS | long-text | resolved (explicit) | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None | None | Not applicable; no shadcn or third-party registry |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** approved 2026-10-11; independent checker 7/7
---
