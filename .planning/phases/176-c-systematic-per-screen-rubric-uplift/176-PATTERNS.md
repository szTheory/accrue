# Phase 176: C — Systematic Per-Screen Rubric Uplift - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 15 (7 tail detail screens + 9 list screens + 3 shared CSS/component files)
**Analogs found:** 7/7 tail screens have a strong analog in the polished screens

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `assets/css/app.css` (line 1361 only) | config | — | self (registry pattern at lines 904, 2381) | exact — token swap only |
| `live/event_live.ex` | LiveView detail | request-response | `live/webhook_live.ex` | role-match (both are thin forensic detail screens) |
| `live/coupon_live.ex` | LiveView detail | request-response | `live/charge_live.ex` | role-match (catalog entity with KPI grid + detail sections) |
| `live/promotion_code_live.ex` | LiveView detail | request-response | `live/coupon_live.ex` | exact (sibling catalog entity, same structure gap) |
| `live/connect_account_live.ex` | LiveView detail + form | CRUD | `live/charge_live.ex` | role-match (detail + action panel) |
| `live/webhook_live.ex` (prose regions) | LiveView detail | request-response | `live/charge_live.ex` | role-match (same .ax-measure prose target pattern) |
| `live/invoice_live.ex` (prose regions) | LiveView detail | request-response | `live/charge_live.ex` | exact (same prose target pattern already implemented there) |
| `live/charge_live.ex` (prose regions) | LiveView detail | request-response | self (already uses detail_section/detail_field_list) | gold standard |

---

## Shared Patterns

### 1. `Detail.detail_section` + `Detail.detail_field_list` — the DRY detail primitive

**Source:** `accrue_admin/lib/accrue_admin/components/detail.ex` lines 22–56

The slot API (from the actual component — do not guess):

```elixir
# detail_section: titled card wrapper
# attr :title, :string, required: true
# attr :class, :any, default: nil
# slot :actions   (optional, renders right of header)
# slot :inner_block, required: true
# Renders: <section class="ax-card ax-detail-section"> with <header class="ax-detail-section-head">

# detail_field_list: semantic <dl> field list
# attr :fields, :list, required: true   — list of %{label: ..., value: ...} maps
# attr :class, :any, default: nil
# Renders: <dl class="ax-field-list"> with <dt class="ax-field-label"> + <dd class="ax-field-value"> per field
# CSS: .ax-field-list goes 1-col → 2-col at --ax-bp-content (640px) — already responsive

# summary_card: page-level hero header
# attr :eyebrow, :string, default: nil
# attr :title, :string, required: true
# slot :status   (optional)
# slot :facts    (optional — renders inside .ax-summary-facts as a flex row)
# slot :actions  (optional — renders right side of card)
# IMPORTANT: :facts slot renders children directly inside <div class="ax-summary-facts">
# (NOT inside a <dl>) — so the bare <span> children in event_live are the correct
# element type; the semantic gap is that they carry no label/value distinction.
# Fix: use <dl>/<dt>/<dd> INSIDE the :facts slot, not bare <span>.
```

**Gold-standard usage** (charge_live.ex lines 144–154 — this is the target all tail screens should match for rubric ⑩):

```elixir
<Detail.detail_section title="Charge details">
  <Detail.detail_field_list fields={[
    %{label: "Charge ID", value: @charge.processor_id || @charge.id},
    %{label: "Status", value: humanize(@charge.status)},
    %{label: "Amount", value: money_text(@charge.amount_cents, @charge.currency)},
    %{label: "Currency", value: String.upcase(to_string(@charge.currency))},
    %{label: "Customer", value: customer_label(@customer)},
    %{label: "Processor", value: humanize(@charge.processor)},
    %{label: "Inserted", value: format_datetime(@charge.inserted_at)}
  ]} />
</Detail.detail_section>
```

**Connect account usage** (connect_account_live.ex lines 123–141 — the `ax-grid-2` wrapper pattern for side-by-side sections):

```elixir
<section class="ax-grid ax-grid-2">
  <Detail.detail_section title={AccrueAdmin.Copy.connect_account_section_capabilities_heading()}>
    <Detail.detail_field_list fields={[
      %{label: ..., value: ...},
      ...
    ]} />
  </Detail.detail_section>

  <Detail.detail_section title={AccrueAdmin.Copy.connect_account_section_effective_fee_heading()}>
    <Detail.detail_field_list fields={[...]} />
    <p :if={@override_preview.error} class="ax-body"><%= @override_preview.error %></p>
  </Detail.detail_section>
</section>
```

---

### 2. Mobile card-collapse breakpoint fix — `app.css` line 1361

**Source:** `accrue_admin/assets/css/app.css` lines 1351–1369

Current state (MUST CHANGE):

```css
/* Data table: one layout at a time — cards below lg, grid table from lg (avoids duplicate DOM in a11y scans). */
.ax-data-table-shell {
  display: none;
}

.ax-data-table-cards {
  display: grid;
  gap: var(--ax-space-md);
}

@media (min-width: 1024px) { /* --ax-bp-lg ↑ */   /* ← LINE 1361: CHANGE THIS */
  .ax-data-table-shell {
    display: block;
  }

  .ax-data-table-cards {
    display: none;
  }
}
```

Required change (one-line value + one-line comment update):

```css
@media (min-width: 768px) { /* --ax-bp-md ↑ */   /* ← AFTER CHANGE */
  .ax-data-table-shell {
    display: block;
  }

  .ax-data-table-cards {
    display: none;
  }
}
```

After this single edit, run `cd accrue_admin && mix accrue_admin.assets.build` and commit `priv/static`. This simultaneously lifts rubric ⑤ for all 9 list screens.

**Defensive guard to add** (if widest tables overflow at 768px): add `overflow-x: auto` to `.ax-data-table-shell` — do not revert the breakpoint.

---

### 3. `.ax-measure` application pattern

**Source:** `accrue_admin/assets/css/app.css` line 406:

```css
.ax-measure { max-width: var(--ax-measure); }
```

**Source:** `accrue_admin/assets/css/theme.css` line 80:

```css
--ax-measure: 68ch;
```

**Application rule (region-level, never whole-card):**

```elixir
# CORRECT: wrap a prose <p> element
<p class="ax-body ax-measure">
  <%= AccrueAdmin.Copy.connect_account_section_platform_fee_body() %>
</p>

# CORRECT: wrap a multi-sentence prose block
<div class="ax-measure">
  <p class="ax-body">First sentence explaining this section...</p>
  <p class="ax-body">Second sentence with more context...</p>
</div>

# WRONG: wrap a whole card
<article class="ax-card ax-measure">...</article>

# WRONG: wrap a data table or field list
<dl class="ax-field-list ax-measure">...</dl>

# WRONG: wrap .ax-empty-copy (already has its own max-width: 28rem cap — do NOT double-cap)
<p class="ax-empty-copy ax-measure">...</p>
```

**Confirmed application targets by file** (from RESEARCH.md):

| File | Element to wrap | Current line |
|------|-----------------|--------------|
| `connect_account_live.ex` | `<p class="ax-body">` platform-fee-body description | line 145 |
| `webhook_live.ex` | `<p class="ax-body">` endpoint/processed/activity lines | lines 223–237 |
| `coupon_live.ex` | `<p class="ax-body">` projection key/value prose (after DRY uplift) | lines 107–109 |
| `invoice_live.ex` | `<p class="ax-body">` tax-risk recovery body, actions body | lines 263, 266, 269, 277 |
| `charge_live.ex` | `<p class="ax-body">` Braintree eligibility/warning, refund confirm | lines 218–219, 242 |
| `event_live.ex` | any description prose added in Wave 2 body sections | new |

---

### 4. Responsive column→stack — `ax-grid-2`/`ax-grid-3` already correct

**Source:** `accrue_admin/assets/css/app.css` lines 1163–1166 + 904–911

```css
/* Mobile: single column (default, before any @media) */
.ax-grid-2,
.ax-grid-3 {
  grid-template-columns: 1fr;
}

/* Promote to multi-column at --ax-bp-md (768px) */
@media (min-width: 768px) { /* --ax-bp-md ↑ */
  .ax-grid-2 {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .ax-grid-3 {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}
```

Detail screens that already use `ax-grid ax-grid-2` correctly (copy these lines verbatim for tail screens that need grid layout):

- `charge_live.ex` line 182: `<section class="ax-grid ax-grid-2">` — correct
- `webhook_live.ex` line 198: `<section :if={@webhook} class="ax-grid ax-grid-2">` — correct
- `connect_account_live.ex` line 123: `<section class="ax-grid ax-grid-2">` — correct

The field-list inside detail sections auto-promotes at `--ax-bp-content` (640px):

```css
@media (min-width: 640px) { /* --ax-bp-content ↑ */
  .ax-field-list {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
```

---

### 5. `data_table` `card_fields`/`card_title` wiring (list screens)

**Source:** `accrue_admin/lib/accrue_admin/components/data_table.ex` lines 30–31, 477–483

All 9 list screens already wire these attrs. The `card_fields` default is all columns; set an explicit list to limit mobile card fields to decision-critical columns only. Pattern from `charges_live` (representative):

```elixir
<DataTable.data_table
  id="charges-table"
  card_title={fn row -> row.processor_id || row.id end}
  card_fields={[@col_customer, @col_status, @col_amount, @col_date]}
  ...
/>
```

The CSS breakpoint change (pattern 2 above) activates this at 768px instead of 1024px. No HEEx changes needed to list screens unless `card_title` or `card_fields` audit reveals a quality miss.

---

## Pattern Assignments

### `live/event_live.ex` — THINNEST TAIL (rubric ②③④⑦⑩ misses)

**Analog:** `live/webhook_live.ex` — both are thin forensic detail screens, both use `Detail.summary_card` as the entry point, both link to related entities.

**Current state** (lines 65–73 — all rubric misses are here):

```elixir
# BEFORE: bare <span> facts, no body sections, no Copy module usage
<Detail.summary_card eyebrow="Event detail" title={@event.type}>
  <:facts>
    <span>Actor: <%= @event.actor_type %></span>
    <span>Subject: <%= @event.subject_type %> <%= @event.subject_id %></span>
    <span>Recorded: <%= format_datetime(@event.inserted_at) %></span>
  </:facts>
</Detail.summary_card>

<RelatedResources.related_resources items={@related_items} />
```

**Target pattern** — copy the webhook_live body structure (lines 156–238), adapted for event fields:

```elixir
# AFTER: semantic facts + detail_section body + .ax-measure on prose
<Detail.summary_card eyebrow="Event detail" title={@event.type}>
  <:facts>
    <dl class="ax-summary-facts-dl">
      <dt class="ax-label">Actor</dt><dd class="ax-body"><%= @event.actor_type %> <%= @event.actor_id || "" %></dd>
      <dt class="ax-label">Subject</dt><dd class="ax-body"><%= @event.subject_type %> <%= @event.subject_id %></dd>
      <dt class="ax-label">Recorded</dt><dd class="ax-body"><%= format_datetime(@event.inserted_at) %></dd>
    </dl>
  </:facts>
</Detail.summary_card>

<Detail.detail_section title="Event details">
  <Detail.detail_field_list fields={[
    %{label: "Type", value: @event.type},
    %{label: "Actor type", value: @event.actor_type || "--"},
    %{label: "Actor ID", value: @event.actor_id || "--"},
    %{label: "Subject type", value: @event.subject_type || "--"},
    %{label: "Subject ID", value: @event.subject_id || "--"},
    %{label: "Recorded", value: format_datetime(@event.inserted_at)}
  ]} />
</Detail.detail_section>

<RelatedResources.related_resources items={@related_items} />
```

NOTE: Check whether `Event` struct has `actor_id` field before using it. Inspect `Accrue.Events.Event` schema. The `:facts slot` does NOT render a `<dl>` — put the `<dl>` inside the slot yourself.

**State coverage gap** (dim ④): `event_live.ex` redirects on nil (line 22–28) but shows no error copy to the user. Add a not-found flash or a rendered "Event not found" path — copy the webhook_live `:ambiguous` pattern (lines 55–61).

**Imports to add** (copy from webhook_live.ex lines 14–25):

```elixir
alias AccrueAdmin.Components.{
  AppShell,
  Breadcrumbs,
  Detail,           # already present
  FlashGroup,       # ADD
  KpiCard,          # ADD
  RelatedResources  # already present
}
alias AccrueAdmin.Copy  # ADD (for Copy module keys)
```

---

### `live/coupon_live.ex` — DRY + hierarchy miss (rubric ②⑦⑩)

**Analog:** `live/charge_live.ex` — same structure: eyebrow+heading hero, KPI grid, detail sections, JSON viewer.

**Current state — two rubric violations:**

1. Missing `Detail.summary_card` (uses hand-rolled `<header class="ax-page-header">` at lines 46–61)
2. Hand-rolled `<div class="ax-page">` with `<p class="ax-body">` key/value pairs at lines 100–111 (rubric ⑩ miss + semantic ⑦ miss)

**Missing import** (line 11 — `Detail` is absent from the alias list):

```elixir
# BEFORE (line 11):
alias AccrueAdmin.Components.{AppShell, Breadcrumbs, JsonViewer, KpiCard, RelatedResources}

# AFTER:
alias AccrueAdmin.Components.{AppShell, Breadcrumbs, Detail, JsonViewer, KpiCard, RelatedResources}
```

**Hero section** — replace hand-rolled header with `Detail.summary_card` (copy charge_live.ex lines 123–141 pattern):

```elixir
# BEFORE (lines 46–61): hand-rolled <header class="ax-page-header">
# AFTER:
<Detail.summary_card
  eyebrow={AccrueAdmin.Copy.coupon_detail_eyebrow()}
  title={coupon_label(@coupon)}
>
  <:status>
    <%# StatusBadge for valid/invalid — copy status_summary/1 output into badge %>
  </:status>
  <:facts>
    <span><%= @coupon.processor_id || @coupon.id %></span>
    <span><%= discount_summary(@coupon) %></span>
    <span><%= status_summary(@coupon) %></span>
  </:facts>
</Detail.summary_card>
```

**Projection section** — replace hand-rolled key/value with `Detail.detail_section` + `Detail.detail_field_list` (lines 100–111):

```elixir
# BEFORE (lines 100–111):
<section class="ax-card">
  <header class="ax-page-header">
    <p class="ax-eyebrow">...</p>
    <h3 class="ax-heading">...</h3>
  </header>
  <div class="ax-page">
    <p class="ax-body"><%= Copy.coupon_detail_label_duration() %> <%= duration_summary(@coupon) %></p>
    <p class="ax-body"><%= Copy.coupon_detail_label_currency() %> <%= @coupon.currency || "--" %></p>
    <p class="ax-body"><%= Copy.coupon_detail_label_processor() %> <%= @coupon.processor || "--" %></p>
  </div>
</section>

# AFTER:
<Detail.detail_section title={AccrueAdmin.Copy.coupon_detail_section_projection_heading()}>
  <Detail.detail_field_list fields={[
    %{label: AccrueAdmin.Copy.coupon_detail_label_duration(), value: duration_summary(@coupon)},
    %{label: AccrueAdmin.Copy.coupon_detail_label_currency(), value: @coupon.currency || "--"},
    %{label: AccrueAdmin.Copy.coupon_detail_label_processor(), value: @coupon.processor || "--"}
  ]} />
</Detail.detail_section>
```

The promotion codes list section (lines 77–98) can stay as-is — it's a list of links, not key/value prose, so `detail_section` wrapper only (not `detail_field_list`):

```elixir
# Wrap existing section in Detail.detail_section (rubric ⑩ — reuse card primitive):
<Detail.detail_section title={AccrueAdmin.Copy.coupon_detail_section_codes_heading()}>
  <div :for={promotion_code <- @promotion_codes} class="ax-list-row">
    ...existing content unchanged...
  </div>
  <p :if={@promotion_codes == []} class="ax-body">...</p>
</Detail.detail_section>
```

---

### `live/promotion_code_live.ex` — same gaps as coupon_live (rubric ②⑦⑩)

**Analog:** `live/coupon_live.ex` (sibling entity after its own uplift) and `live/charge_live.ex` (gold standard).

**Missing import** (line 8 — `Detail` is absent):

```elixir
# BEFORE (line 8):
alias AccrueAdmin.Components.{AppShell, Breadcrumbs, JsonViewer, KpiCard, RelatedResources}

# AFTER:
alias AccrueAdmin.Components.{AppShell, Breadcrumbs, Detail, JsonViewer, KpiCard, RelatedResources}
```

**Hero section** — replace hand-rolled `<header class="ax-page-header">` (lines 43–56) with `Detail.summary_card` (same pattern as coupon_live after uplift):

```elixir
<Detail.summary_card
  eyebrow={AccrueAdmin.Copy.promotion_code_detail_eyebrow()}
  title={@promotion_code.code || @promotion_code.processor_id || @promotion_code.id}
>
  <:facts>
    <span><%= status_summary(@promotion_code) %></span>
    <span><%= redemption_summary(@promotion_code) %></span>
  </:facts>
</Detail.summary_card>
```

**Parent coupon section** (lines 72–87) — replace hand-rolled `<section class="ax-card">` with `Detail.detail_section`:

```elixir
# BEFORE (lines 72–87): hand-rolled <section class="ax-card">
# AFTER:
<Detail.detail_section title={AccrueAdmin.Copy.promotion_code_section_navigate_heading()}>
  <p :if={@promotion_code.coupon} class="ax-body">
    <a href={@admin_mount_path <> "/coupons/" <> @promotion_code.coupon.id} class="ax-link">
      <%= @promotion_code.coupon.name || @promotion_code.coupon.processor_id || @promotion_code.coupon.id %>
    </a>
  </p>
  <p :if={!@promotion_code.coupon} class="ax-body">
    <%= AccrueAdmin.Copy.promotion_code_detail_no_coupon_projection() %>
  </p>
</Detail.detail_section>
```

---

### `live/connect_account_live.ex` — nested grid overflow + `.ax-measure` miss (rubric ④⑤)

**Analog:** `live/charge_live.ex` — same pattern: `ax-grid ax-grid-2` outer section with action panel inside.

**Current state** (lines 123–217): already uses `Detail.detail_section` + `Detail.detail_field_list` correctly in the two-column grid section (lines 123–141). The rubric misses are:

1. The `<Detail.detail_section title=...>` for platform-fee form (line 143) wraps a `<p class="ax-body">` prose description at line 145 that needs `.ax-measure`
2. The `<div class="ax-grid ax-grid-2">` at line 149 (INSIDE a `Detail.detail_section`) creates a nested grid — at 360px this becomes two nested single-column grids (fine), but the inputs at 768px each span one of the 2 columns inside a detail_section which is itself a full-width card (not half of an outer grid). Verify no horizontal overflow.

**`.ax-measure` on prose** (line 145):

```elixir
# BEFORE (line 145):
<p class="ax-body">
  <%= AccrueAdmin.Copy.connect_account_section_platform_fee_body() %>
</p>

# AFTER:
<p class="ax-body ax-measure">
  <%= AccrueAdmin.Copy.connect_account_section_platform_fee_body() %>
</p>
```

**Form inputs pattern** — the form uses `<label class="ax-label">` wrapping `<input class="ax-input">` inline (label-wraps-input anti-pattern vs. sibling label+input). The executor should verify this does not cause a11y issues in the axe sweep. The `data-role="save-override"` button (line 212) and `phx-submit="save_override"` (line 148) MUST be preserved — do not alter these during any structural wrapping.

---

### `live/webhook_live.ex` — forensic payload prose needs `.ax-measure` (rubric ①)

**Analog:** `live/charge_live.ex` — same pattern: `Detail.detail_section` already used; prose inside hand-rolled `<section class="ax-card">` block needs `.ax-measure`.

**Forensic payload section** (lines 216–239) — the hand-rolled `<section class="ax-card">` with `<p class="ax-body">` lines is the only remaining DRY miss (rubric ⑩):

```elixir
# BEFORE (lines 216–239): hand-rolled section + bare <p class="ax-body"> key/value
<section :if={@webhook} class="ax-card">
  <header class="ax-page-header">
    <p class="ax-eyebrow">Forensic payload</p>
    <h3 class="ax-heading">Stored raw payload and metadata</h3>
  </header>
  <div class="ax-stack-xl">
    <p class="ax-body">Endpoint: <%= humanize(@webhook.endpoint) %></p>
    <p class="ax-body">Processed: <%= format_datetime(@webhook.processed_at) %></p>
    <p class="ax-body">
      Activity feed:
      <a class="ax-link" href={...}>View linked activity</a>
    </p>
  </div>
</section>

# AFTER: DRY uplift + .ax-measure on the body copy
<Detail.detail_section :if={@webhook} title="Stored raw payload and metadata">
  <Detail.detail_field_list fields={[
    %{label: "Endpoint", value: humanize(@webhook.endpoint)},
    %{label: "Processed", value: format_datetime(@webhook.processed_at)}
  ]} />
  <p class="ax-body ax-measure">
    Activity feed:
    <a class="ax-link" href={scoped_mount_path(@admin_mount_path, "/events", @current_owner_scope, %{"source_webhook_event_id" => @webhook.id})}>
      View linked activity
    </a>
  </p>
</Detail.detail_section>
```

---

### `live/invoice_live.ex` — prose regions need `.ax-measure` (rubric ① + readability)

**Analog:** `live/charge_live.ex` — already fully uses `Detail.detail_section`, `Detail.detail_field_list`, `ax-grid-2`. The only uplift needed is `.ax-measure` on prose `<p class="ax-body">` elements.

**Target lines** (from RESEARCH.md):

```elixir
# Line 263 — tax disabled reason (inside tax-risk-panel section):
<p :if={present?(@invoice.automatic_tax_disabled_reason)} class="ax-body ax-measure">
  <%= Copy.invoice_tax_disabled_reason_label() %> <%= humanize(@invoice.automatic_tax_disabled_reason) %>.
</p>

# Line 266 — tax finalization failure:
<p :if={present?(@invoice.last_finalization_error_code)} class="ax-body ax-measure">
  <%= Copy.invoice_tax_finalization_failure_label() %> <%= @invoice.last_finalization_error_code %>.
</p>

# Line 269 — tax recovery body:
<p class="ax-body ax-measure">
  <%= Copy.invoice_tax_recovery_body() %>
</p>

# Line 277 — actions body:
<p class="ax-body ax-measure">
  <%= Copy.invoice_actions_body() %>
</p>
```

The `ax-grid-3` line-item form at line 379 (`<div class="ax-grid ax-grid-3">`) stacks to 1fr at mobile — this is already handled by the existing CSS. Verify the three fields (description, amount, currency) do not overflow at 360px.

---

### `live/charge_live.ex` — GOLD STANDARD (minor prose additions only)

**Analog:** itself — `charge_live.ex` is already the best-scored financial detail screen and serves as the template for all other tail screens. The only Phase 176 touch is `.ax-measure` on Braintree prose.

**Target lines** (from RESEARCH.md):

```elixir
# Lines 218–219 — Braintree eligibility/warning (inside refund card):
<div :if={@charge.processor == "braintree"} class="ax-stack-sm">
  <p class="ax-body ax-measure"><%= Copy.charge_refund_braintree_eligibility_info() %></p>
  <p class="ax-body ax-measure"><%= Copy.charge_refund_not_final_truth_warning() %></p>
</div>

# Line 242 — refund confirm panel body:
<p class="ax-body ax-measure"><%= refund_copy(@pending_refund, @charge.currency) %></p>
```

The `ax-grid ax-grid-2` fee-breakdown section (line 182) already stacks correctly at mobile — no change needed.

---

## CSS Token Reference

For any new inline CSS class composition during uplift, the full token vocabulary from `theme.css` lines 17–80:

| Category | Tokens |
|----------|--------|
| Spacing | `--ax-space-2xs` (2px) through `--ax-space-3xl` (64px) — use these, never px literals |
| Type | `--ax-type-xs` through `--ax-type-3xl` |
| Line-height | `--ax-leading-tight/normal/relaxed` (prose = relaxed) |
| Letter-spacing | `--ax-tracking-tight/normal/wide/caps` |
| Reading measure | `--ax-measure: 68ch` → `.ax-measure` class |
| Breakpoints (CSS @media only, not in var()) | 599.98px=sm↓, 640px=content↑, 768px=md↑, 1024px=lg↑ |

**Breakpoint comment convention (grep-guard — REQUIRED on every @media):**

```css
@media (min-width: 768px) { /* --ax-bp-md ↑ */
@media (max-width: 599.98px) { /* --ax-bp-sm ↓ */
@media (min-width: 640px) { /* --ax-bp-content ↑ */
@media (min-width: 1024px) { /* --ax-bp-lg ↑ */
```

---

## No Analog Found

All tail screens have strong analogs. No files require falling back to RESEARCH.md patterns exclusively.

| File | Reason no gap |
|------|---------------|
| All 7 tail detail screens | Analogs identified above; `charge_live.ex` is the gold standard |
| All 9 list screens | No HEEx changes needed; CSS-only breakpoint fix (Wave 0) |

---

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/live/`, `accrue_admin/lib/accrue_admin/components/`, `accrue_admin/assets/css/`
**Files scanned:** 15 LiveViews + 3 component/CSS files
**Pattern extraction date:** 2026-06-04
