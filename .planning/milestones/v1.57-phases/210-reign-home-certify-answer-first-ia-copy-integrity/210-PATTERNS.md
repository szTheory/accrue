# Phase 210: Reign Home + certify answer-first IA & copy integrity - Pattern Map

**Mapped:** 2026-07-19
**Files analyzed:** 5 (1 target LiveView, 1 copy SSOT, 1 unit test, 2 e2e specs)
**Analogs found:** 5 / 5

> This is a **REIGN, not a redesign**. Every pattern below is *copy-from-a-sibling-page*, not invent-new. The primary analog is `subscriptions_live.ex` (Phase 209 — the immediately-prior reigned page). The through-line is **cross-page parity**: Home's reigned header must read as the same grammar as Subscriptions'. Zero new shared components (COMP-01 = "inline", D-01). All shared component slot/attr APIs already exist and are unchanged.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` | LiveView page (index/home) | request-response (read/navigate; server-rendered) | `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | exact (sibling reigned page, same shell + PageHeader grammar) |
| `accrue_admin/lib/accrue_admin/copy.ex` | copy SSOT (module of `def`s) | transform (string constants) | existing `dashboard_*` / `home_*` fns in same file + `copy/subscription.ex` verdict fns | exact (add/rename in place) |
| `accrue_admin/test/accrue_admin/live/dashboard_live_test.exs` | unit test (LiveView render) | test | same file's existing assertions (migrate in place) | exact |
| `accrue_admin/e2e/admin-spec-overview-phase194.spec.js` | e2e spec (Playwright) | test | same file's `.ax-attention-rail--empty` locator (L96) | exact |
| `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` | e2e spec (Playwright) | test | same file's `.ax-attention-rail` ratchet selectors (L974, L979) | exact |

Two generated artifacts are rebuilt+committed on every change (not authored by hand):
- `accrue_admin/priv/static/accrue_admin.css` — via `mix accrue_admin.assets.build` (only if `app.css` is touched; a pure stop-referencing reign may not need CSS edits at all — verify).
- `examples/accrue_host/e2e/generated/copy_strings.json` — via `mix accrue_admin.export_copy_strings` (required because Copy strings change).

---

## Pattern Assignments

### `dashboard_live.ex` (LiveView page, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`

The reign replaces the hand-rolled `<header class="ax-page-header ax-page-header-compact">` (current `dashboard_live.ex` L52–104) with `PageHeader.page_header`, mirroring Subscriptions verbatim. Everything below L106 in `dashboard_live.ex` (attention rail, customer-search strip, launchers, KpiCard band, Timeline cards) is recomposed or kept per the UI-SPEC.

#### 1. Imports / alias block (copy the shape)

Subscriptions aliases the canonical spine components (`subscriptions_live.ex` L13–23). Home currently only aliases `{AppShell, Breadcrumbs, Icon, KpiCard, Timeline}` (`dashboard_live.ex` L13). The reign must **add** `PageHeader`, `StatStrip`, `StatusBadge`, `EmptyState`, `FlashGroup` to Home's alias list and **drop** `Breadcrumbs` (PageHeader renders breadcrumbs internally). Analog:

```elixir
# subscriptions_live.ex L13-23
alias AccrueAdmin.Components.{
  AppShell,
  DataTable,
  FilterChipBar,
  FlashGroup,
  PageHeader,
  StatStrip
}

alias AccrueAdmin.Components.StatusBadge
alias AccrueAdmin.Copy
```

Home's target alias set: `AppShell, Icon, KpiCard, Timeline, PageHeader, StatStrip, StatusBadge, EmptyState, FlashGroup` (drop `Breadcrumbs`; keep `Icon`/`KpiCard`/`Timeline`; keep `Copy`, `ScopedPath`).

#### 2. PageHeader wiring — the load-bearing analog (`subscriptions_live.ex` L98–187)

This is the exact slot wiring Home must mirror. Note the slot order: `:description` (verdict badge + route line) → `:actions` (primary CTA + secondary links) → `:stat_strip` (4-stat StatStrip). Home has **no** `:filter_toolbar` (no table).

```elixir
# subscriptions_live.ex L98-176 — MIRROR THIS
<PageHeader.page_header
  breadcrumbs={[
    %{
      label: Copy.dashboard_breadcrumb_home(),
      href: scoped_path(@admin_mount_path, "", @current_owner_scope)
    },
    %{label: Copy.subscriptions_index_breadcrumb()}
  ]}
  title={Copy.subscriptions_index_breadcrumb()}
>
  <:description>
    <p>
      <StatusBadge.status_badge
        status={verdict_status(@summary)}
        label={verdict_label(verdict_status(@summary))}
        tone={verdict_tone(verdict_status(@summary))}
      />
    </p>
    <p class="ax-body"><%= Copy.subscriptions_route_line() %></p>
  </:description>
  <:actions>
    <a class="ax-button ax-button-primary ax-button-sm" href={invoice_queue_path(...)}>
      <%= Copy.subscriptions_invoice_queue_cta() %>
    </a>
    <a class="ax-button ax-button-secondary ax-button-sm" href={...}>Events audit log</a>
  </:actions>
  <:stat_strip>
    <StatStrip.stat_strip label={Copy.subscriptions_kpi_section_aria_label()}>
      <:stat label="Open invoices" value={count(...)} tone="cobalt" href={...} />
      <:stat label="Exposure" value={format_minor(...)} tone={exposure_tone(@summary)} href={...} />
      <:stat label="At-risk subscriptions" value={count(...)} tone="amber" href={...} />
      <:stat label="Failed webhooks" value={count(...)} tone={webhook_tone(@summary)} href={...} />
    </StatStrip.stat_strip>
  </:stat_strip>
</PageHeader.page_header>
```

**Home-specific deltas from this analog (per UI-SPEC + CONTEXT):**
- Breadcrumbs = **single self-referential-free crumb** `[%{label: Copy.dashboard_breadcrumb_home()}]` (no `href` — Home is root; D-04a). Do NOT add a second/parent crumb. This is the one place Home diverges from Subscriptions' two-crumb pattern.
- `title` = `Copy.dashboard_breadcrumb_home()` ("Dashboard") — plain noun, NOT a rendered verdict sentence. Retire `dashboard_health_headline/1` (`dashboard_live.ex` L467–468) and the `<h1 class="ax-display">` at L56.
- `:actions` = **primary CTA** `Open invoice queue` (`.ax-button-primary`, drop the "collect $X" suffix currently at L69) + **customer-search control** `Find a customer` (`.ax-button-secondary`, `data-command-palette-trigger="true" data-ax-command-palette-trigger="true"` — carry the `data-ax-command-palette-trigger` marker from current L84 as the stable selector) + **`Audit ledger`** secondary link. DROP `Debug dead-lettered webhooks` (L72–79) and `Dunning after invoices` (L89–95) from actions (they duplicate launcher tiles).
- `:stat_strip` = 4 stats, **same order/shape as Subscriptions** (Open invoices `cobalt` → Exposure amber-if-`>0` → At-risk subscriptions `amber` → Failed webhooks amber-if-`>0`), sourced from Home's `@stats` assigns (`open_invoice_count`, `open_invoice_balance_minor`, `past_due_subscription_count`, `blocked_webhook_count`). `failed_meter_event_count` is NOT a 5th stat — it stays as an attention-rail row (content-preservation, UI-SPEC §2/L104).

#### 3. Verdict helper functions — copy verbatim (`subscriptions_live.ex` L345–358)

Home must add `dashboard_`-prefixed twins of these. The tone/status logic is identical:

```elixir
# subscriptions_live.ex L345-358 — COPY, rename subscriptions_* -> dashboard_*
defp verdict_status(%{open_invoice_count: count}) when count > 0, do: :action_required
defp verdict_status(_summary), do: :healthy

defp verdict_label(:action_required), do: Copy.subscriptions_health_verdict_action_required()
defp verdict_label(:healthy), do: Copy.subscriptions_health_verdict_healthy()

defp verdict_tone(:action_required), do: "amber"
defp verdict_tone(:healthy), do: "moss"

defp exposure_tone(%{open_invoice_exposure_minor: minor}) when minor > 0, do: "amber"
defp exposure_tone(_summary), do: "moss"

defp webhook_tone(%{failed_webhook_count: count}) when count > 0, do: "amber"
defp webhook_tone(_summary), do: "moss"
```

**Note:** `dashboard_live.ex` already has a `webhook_tone/1` (L567–570) that maps a *status atom* to a timeline tone — that is a DIFFERENT function (arity-collision by name). Name the new StatStrip helpers to avoid clashing (e.g. `stat_webhook_tone/1` or pattern-match on the stats map key). Home's stats map uses `blocked_webhook_count`/`open_invoice_balance_minor`, not Subscriptions' `failed_webhook_count`/`open_invoice_exposure_minor` — adapt the map keys. New verdict badge language must be `Healthy`/`Action required` (reuse `Copy.subscriptions_health_verdict_*` literals or add `dashboard_health_verdict_*` twins), NOT the current bespoke "Unhealthy" (`dashboard_live.ex` L461, L468, L120).

#### 4. Attention-rail recomposition (kept, rows rebuilt from primitives)

Current bespoke markup: `dashboard_live.ex` L124–136 (`.ax-card.ax-attention` with `.ax-attention-priority-*` / `.ax-attention-dot-*` / `.ax-attention-pill-*` / `.ax-attention-action` spans). The `@attention` data pipeline (`attention_items/3`, L414–459) is **kept** — it already produces `%{tone, priority, metric, label, pill, action, href}` rows sorted P1→P4. Rebuild each row's DOM from shared primitives:
- Priority chip: `StatusBadge.status_badge` (its built-in `.ax-status-dot` replaces the bespoke `ax-attention-dot`). Map `row.tone` ("warning"/"danger"/"info") to StatusBadge tone via a small helper (StatusBadge tones: `moss`/`cobalt`/`amber`/`slate`/`ink` — see `status_badge.ex` L28–39; `warning`→`amber`, `danger`→`amber`/`danger`, `info`→`cobalt`).
- Metric+label: `.ax-stack-xs` stack (established idiom — see `subscriptions_live.ex` `identity_cell/1` L338–339 uses `<span class="ax-stack-xs">`).
- Optional pill: `.ax-chip.ax-label` (established idiom — `subscriptions_live.ex` L326 `billing_signals_cell/1`).
- Trailing action: quiet link / small `Button`.
- **DROP** the `ax-attention-summary` verdict block (`dashboard_live.ex` L119–122) — now covered by the header StatusBadge/StatStrip.

#### 5. EmptyState — replace bespoke empty block (`empty_state.ex` API)

Current bespoke empty branch: `dashboard_live.ex` L138–142 (`.ax-card.ax-empty.ax-attention-rail--empty` hand-rolled). Replace with the canonical component. API (`empty_state.ex` L19–24): `icon` (atom, required), `title` (string, required), `body` (string, required), optional `class`, optional `:actions` slot. Direct-call reference (`component_kitchen_live.ex` L1758–1763):

```elixir
<EmptyState.empty_state
  icon={:check_circle}
  title={Copy.home_attention_empty_title()}
  body={Copy.home_attention_empty_copy()}
/>
```

`Copy.home_attention_empty_title/0` ("You're all caught up") and `Copy.home_attention_empty_copy/0` already exist (`copy.ex` L1320, L1322) — text unchanged, just migrated into the component.

**Selector-migration caution:** the e2e spec `admin-spec-overview-phase194.spec.js` L96 locates `.ax-attention-rail--empty`. `EmptyState` renders `.ax-empty` (+ optional `class`). Pass `class="ax-attention-rail--empty"` to preserve that hook, OR migrate the e2e locator to `.ax-empty` in this phase (D-05). Prefer keeping a stable intentional marker.

#### 6. Three-tile launcher grid (down from 4)

Current: 4 tiles at `dashboard_live.ex` L167–220 (invoices L168, **customer L179–191 — REMOVE**, recovery L193, developer L209). Rebuild the 3 survivors from `.ax-card` + `Icon`(lg) + title + `StatusBadge`/chip meta (rendered only when count `> 0`, matching current conditional `:if`) + `Button`-styled action. Keep a stable `data-ax-launcher-primary` marker on the invoice tile (current stable-selector intent lives in class `ax-launcher-primary` at L168 — migrate the test assertion to a `data-` attribute per D-05/UI-SPEC §7). Remove the `ax-launcher-customer` tile entirely (D-02) — customer-search now lives only in the header. Do NOT widen tile padding to fill the freed 4th column (UI-SPEC Spacing "Exceptions").

#### 7. Keep-as-is zones (do not touch)

- KpiCard "At a glance" band: `dashboard_live.ex` L224–276 — **kept** (already canonical). Division of labor with new StatStrip: StatStrip = one-line exposure-first answer; KpiCard = metric drill-down (D-03a — must not restate the same number as the same sentence).
- Timeline activity cards: `dashboard_live.ex` L279–360 — **kept**.
- Add `FlashGroup.flash_group flashes={flash_messages(@flash)}` after the PageHeader (mirror `subscriptions_live.ex` L189; copy the `flash_messages/1` helper from L494–501). Confirm Home renders it (UI-SPEC Copywriting "Error state").

#### 8. Removed helpers (clean up dead code)

Delete once unreferenced: `dashboard_health_headline/1` (L467–468), `attention_health_summary/1` (L461), `attention_health_issue_summary/1` (L463–465). `attention_rail_heading/1` (L470–471) is kept but its inline "Priority exceptions" literal (L471) must move into `Copy`.

---

### `copy.ex` (copy SSOT, transform)

**Analog:** existing `dashboard_*` / `home_*` functions in the same file + `copy/subscription.ex` verdict functions.

**Verdict strings to reuse/add** (`copy/subscription.ex` L103–107 — same literals, both pages):
```elixir
def subscriptions_invoice_queue_cta, do: "Open invoice queue"
def subscriptions_health_verdict_healthy, do: "Healthy"
def subscriptions_health_verdict_action_required, do: "Action required"
```
Add `dashboard_health_verdict_healthy/0` + `dashboard_health_verdict_action_required/0` reusing these exact literals (UI-SPEC Copywriting Contract), or reference the `subscriptions_*` ones directly.

**Inline literals in `dashboard_live.ex` that MUST migrate into `copy.ex`** (COPY-01, no template literals):
- L60 `"Billing status"`, L120 `"Billing status: Unhealthy."` + L121 P1/P2/P3 sentence (block being removed — retire, don't migrate).
- L147 `"Find ONE customer"` → plain `"Find a customer"` (sentence case; distinct from existing `home_search_customers_title` = "Find one customer" at L1339).
- L156 `"Open customer search"`, L189 `"Open global customer search"` (removed with the tile/strip).
- L172 `"Open invoice queue workspace"` → drop "workspace".
- L196 `"Dunning check:"`, L199 `"Next stage: reminder pending"`, L202 `"Funnel preview: …"` — plain-language rework.
- L471 `"Priority exceptions"` → new `Copy` fn.

**Jargon audit — "workspace" removals** (COPY-01/D-04):
- `dashboard_kpi_invoices_aria_label` (`copy.ex` L1279 = "Open invoice queue workspace") → "Open invoice queue".
- `dashboard_kpi_open_invoice_balance_meta` (L1256–1257 = "…Invoices queue workspace…") → de-jargon.
- `home_launcher_recovery_meta` (L1360 = "Recovery workspace") → "N at-risk accounts" framing.
- `home_launcher_invoices_title` (L1350 = "Invoices queue: $0.00 target") → short noun "Invoice queue".

**Every new/renamed string** requires `mix accrue_admin.export_copy_strings` → commit `examples/accrue_host/e2e/generated/copy_strings.json`.

---

### `dashboard_live_test.exs` (unit test) — migrate in-phase (D-05)

**Analog:** the file's own existing assertions (rewrite in place).

Assertions that break when the DOM/copy changes (must be migrated, not left red):
- `assert html =~ "Billing status: Unhealthy"` and the P1/P2/P3 sentence → replace with the new `StatusBadge`/`StatStrip` verdict assertions (assert `Copy.dashboard_health_verdict_action_required()` / `"Healthy"`).
- `"ax-home-health-answer"` (D-05 L107 selector) → new header verdict marker.
- `"ax-launcher-primary"` (D-05 L130) → `data-ax-launcher-primary` (stable marker).
- `"ax-home-customer-search-cta"` (D-05 L184) → `data-ax-command-palette-trigger` (already present on the control).
- `"Find ONE customer"` → `"Find a customer"`; `"Open customer search"` (strip removed) → drop.
- `Copy.home_launcher_customers_title()` / `..._meta()` assertions → drop (customer tile removed).
- `"Open invoice queue workspace"` / `"Dunning check:"` / `"Next stage: reminder pending"` → update to de-jargoned strings.
- Keep `failed_meter_event_count` rail-row assertions (`Copy.home_attention_meter_label()`, `home_attention_action_investigate()`) — that row survives.

### `admin-spec-overview-phase194.spec.js` + `admin-interaction-overlay-phase199.spec.js` (e2e) — migrate in-phase (D-05)

**Analog:** the files' own existing locators.
- `admin-spec-overview-phase194.spec.js` L96: `.ax-attention-rail--empty` → keep by passing `class="ax-attention-rail--empty"` to `EmptyState`, or migrate to `.ax-empty`.
- `admin-interaction-overlay-phase199.spec.js` L974, L979: `.ax-attention-rail` ratchet `focus-ring` findings → point at the recomposed rail's real focusable rows (the `StatusBadge`-row anchors) or the new stable marker.
- `admin-a11y.spec.js` (axe): must stay green — PageHeader's single `<h1>` must remain the page's only top-level heading (retiring the bespoke `<h1>` at `dashboard_live.ex` L56 satisfies this automatically since PageHeader supplies the one h1). Preserve landmark/`aria-label`/visually-hidden semantics on the rail/launcher sections.

---

## Shared Patterns

### PageHeader single-CTA-in-`:actions` grammar
**Source:** `subscriptions_live.ex` L118–144 (and reference pages `invoices_live.ex`, `customers_live.ex`).
**Apply to:** Home header. One primary `.ax-button-primary` + secondary `.ax-button-secondary` links, all `ax-button-sm`. The customer-search control folds into this slot (D-02) as a secondary button with `data-command-palette-trigger`.

### Verdict = StatusBadge + exposure-first StatStrip in the header
**Source:** `subscriptions_live.ex` `:description` (StatusBadge, L110–114) + `:stat_strip` (StatStrip, L146–175) + helpers L345–358.
**Apply to:** Home — verbatim grammar, adapted to Home's `@stats` map keys. This is the cross-page parity contract (D-03).

### ScopedPath / scoped_path href construction
**Source:** `dashboard_live.ex` already uses `ScopedPath.build(mount_path, suffix, scope, params)` (L67 etc.); `subscriptions_live.ex` uses a local `scoped_path/3,4` (L635–646). Home should **keep its existing `ScopedPath.build/4`** calls (signature at `scoped_path.ex` L7) for all header/stat/tile hrefs — no need to import Subscriptions' local helper.
**Apply to:** all StatStrip `href`, `:actions` hrefs, launcher tile hrefs.

### `count/2` + `format_minor/2` money/quantity formatters
**Source:** identical private fns already in BOTH files (`dashboard_live.ex` L473–474 & L595–606; `subscriptions_live.ex` L455–456 & L426–437). Home already has them — reuse in the new StatStrip/verdict wiring, no new code.

### FlashGroup on the spine
**Source:** `subscriptions_live.ex` L189 + `flash_messages/1` L494–501.
**Apply to:** add to Home after PageHeader (every reference page renders it).

### Build contract (generated artifacts)
**Source:** MEMORY `accrue_admin CSS bundle rebuild` + UI-SPEC Build contract.
**Apply to:** `mix accrue_admin.assets.build` → commit `priv/static/accrue_admin.css` (only if `app.css` edited); `mix accrue_admin.export_copy_strings` → commit `copy_strings.json` (always, since Copy changes). CSS is **stop-referencing, not delete** this phase (deletion = Phase 211).

---

## No Analog Found

None. Every file has a strong in-repo analog — this phase is a straight recomposition onto an already-shipped component spine.

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/live/` (LiveView pages), `accrue_admin/lib/accrue_admin/components/` (shared spine), `accrue_admin/lib/accrue_admin/copy*` (SSOT), `accrue_admin/test/`, `accrue_admin/e2e/`.
**Files scanned:** dashboard_live.ex, subscriptions_live.ex, invoices_live.ex, customers_live.ex (grep), empty_state.ex, stat_strip.ex, status_badge.ex, page_header.ex, copy.ex, copy/subscription.ex, component_kitchen_live.ex (EmptyState direct-call ref), dashboard_live_test.exs, admin-spec-overview-phase194.spec.js, admin-interaction-overlay-phase199.spec.js.
**Pattern extraction date:** 2026-07-19
