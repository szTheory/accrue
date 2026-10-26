# Phase 237: Admin Invoices, Payments & Recovery - Pattern Map

**Mapped:** 2026-10-08  
**Files analyzed:** 19 likely existing files; one optional served-browser spec  
**Analogs found:** 19 / 19 (all targets are existing modules or have adjacent examples)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/lib/accrue_admin/queries/invoices.ex` | query | CRUD / request-response | same module | exact |
| `accrue_admin/lib/accrue_admin/queries/charges.ex` | query | CRUD / request-response | same module | exact |
| `accrue_admin/lib/accrue_admin/queries/dunning.ex` | query | batch / transform | same module | exact |
| `accrue_admin/lib/accrue_admin/live/invoices_live.ex` | LiveView | request-response | same module | exact |
| `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | LiveView | request-response | same module | exact |
| `accrue_admin/lib/accrue_admin/live/charges_live.ex` | LiveView | request-response | `invoices_live.ex` | role-match |
| `accrue_admin/lib/accrue_admin/live/charge_live.ex` | LiveView | request-response | same module | exact |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | LiveView | request-response / batch | same module | exact |
| `accrue_admin/lib/accrue_admin/components/money_formatter.ex` | component | transform | same module | exact |
| `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` | component | request-response | same module | exact |
| `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` | component | request-response | same module | exact |
| `accrue_admin/lib/accrue_admin/components/window_selector.ex` | component | request-response | same module | exact |
| `accrue_admin/lib/accrue_admin/scoped_path.ex` | utility | transform | same module | exact |
| `accrue_admin/test/accrue_admin/live/invoices_live_test.exs` | test | request-response | same suite | exact |
| `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` | test | request-response | same suite | exact |
| `accrue_admin/test/accrue_admin/live/charges_live_test.exs` | test | request-response | same suite | exact |
| `accrue_admin/test/accrue_admin/live/charge_live_test.exs` | test | request-response | same suite | exact |
| `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` | test | request-response / batch | same suite | exact |
| `examples/accrue_host/e2e/phase237-admin-billing.spec.js` (only if a new journey is needed) | test | request-response | `phase234-admin-customers-subscriptions.spec.js` | role-match |

Research recommends focused edits to existing query, LiveView, shared component/copy, and adjacent test modules; no new service layer or package. The browser spec is optional and should be added only if it closes a distinct served-navigation gap. `MoneyFormatter`, `DetailDrawer`, `AtRiskTable`, `WindowSelector`, and `ScopedPath` are reusable pattern references; research does not establish that all require edits.

## Pattern Assignments

### Invoice list and detail (`invoices_live.ex`, `invoice_live.ex`)

**Analogs:** `accrue_admin/lib/accrue_admin/live/invoices_live.ex` and `accrue_admin/lib/accrue_admin/live/invoice_live.ex` (tracked).

`invoices_live.ex` imports Ecto.Query, uses Phoenix LiveView, aliases domain/query modules and shared components (lines 1-24). It already builds stored status summary and balance presentation at lines 246-256. Current money normalization falls back to USD for unknown/missing currency (lines 261-283); replace the local fallback behavior with the shared unavailable-safe formatter. `invoice_live.ex` action dispatch is at lines 1010-1030: it dispatches the socket's assigned invoice, then branches on returned invoice, `:requires_action`, or error. This is the exact staged-action/result seam, but the assigned row must be reloaded through `Invoices.detail(id, current_owner_scope)` and revalidated before dispatch, per phase decisions.

**Scoped reload pattern:** `accrue_admin/lib/accrue_admin/queries/invoices.ex` lines 73-86 joins Customer, scopes before matching ID, maps absent/out-of-scope rows to `:not_found`, and preloads related records. The list select already includes stored status, currency, due date and amount fields (`invoices.ex` lines 35-53). Keep overdue a derived presentation fact; do not change the persisted status or status filter.

```elixir
Invoice
|> join(:inner, [invoice], customer in Customer, on: customer.id == invoice.customer_id)
|> scope_query(owner_scope)
|> where([invoice, _customer], invoice.id == ^id)
|> select([invoice, _customer], invoice)
|> Repo.one()
|> case do
  nil -> :not_found
  invoice -> {:ok, Repo.preload(invoice, [:customer, :subscription, :items])}
end
```

### Payment/refund list and detail (`charges_live.ex`, `charge_live.ex`)

**Analog:** `accrue_admin/lib/accrue_admin/live/charge_live.ex` (tracked), with the analogous list pattern in `charges_live.ex`.

The refund action currently forms operation options from the assigned charge currency and calls `Billing.create_refund(socket.assigns.charge, opts)` (`charge_live.ex` lines 586-603). Preserve staged review, step-up, and operation ID semantics; at confirmation reload `Charges.detail(id, current_owner_scope)`, verify the same charge and available refundable balance/currency, then dispatch. The existing outcome branch records local audit evidence and refreshes the charge after a returned Refund; do not present local audit logging alone as processor completion. Current local `money_text/2` and `normalize_currency/1` are at lines 856-921 and default unknown currency to USD, so migrate presentation to `MoneyFormatter`.

**Scoped reload pattern:** `accrue_admin/lib/accrue_admin/queries/charges.ex` lines 67-80 uses the same owner-before-ID lookup and `:not_found` behavior as invoice detail, preloading customer and refunds.

### Recovery (`recovery_live.ex`, `queries/dunning.ex`)

**Analogs:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` and `accrue_admin/lib/accrue_admin/queries/dunning.ex` (tracked).

`RecoveryLive.handle_params/3` parses `window`, derives UTC bounds, reads the active owner scope and asks Dunning for aggregates/funnel/at-risk rows (lines 26-34). The existing empty-data branch inserts the configured default currency (lines 38-50); avoid fabricating a currency when no measures exist. The `7d`/`30d`/`90d` allowlist and default are at lines 169-170. Dunning groups events by event type and currency at lines 172-185 and applies organization filtering to both event and subscription reads at lines 200-222; preserve those boundaries and do not merge currencies. Historical event facts and current at-risk reads remain separate.

**Navigation:** `accrue_admin/lib/accrue_admin/components/window_selector.ex` lines 24-62 updates only the `window` query parameter while preserving other query context. `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` lines 32-42 defines explicit owner scope and base path inputs; its row links should continue using `ScopedPath`. In `accrue_admin/lib/accrue_admin/scoped_path.ex` lines 25-59, paths are rebuilt from server-resolved owner scope and a validated local return path; URL owner/return values are context only, never authorization.

### Shared money and confirmation UI

**Analogs:** `accrue_admin/lib/accrue_admin/components/money_formatter.ex` and `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` (tracked).

`MoneyFormatter.money_formatter/1` resolves either a Money struct or integer minor units plus currency, delegates to `Render.format_money/3`, and displays `--` when money cannot be resolved (`money_formatter.ex` lines 18-51). Currency parsing returns `nil` for unknown codes instead of defaulting to USD (lines 53-65). Use this for known zero values as well as nonzero values; pass unavailable values through without substituting zero/default currency.

The shared drawer delegates overlay behavior, title, action slot, body and footer (`detail_drawer.ex` lines 24-55). Keep exact record/action/consequence/known amount in the review content and use the existing per-record confirmation/step-up interaction.

```elixir
with {:ok, amount_minor, currency} <- resolve_money(assigns) do
  Render.format_money(amount_minor, currency, resolved_locale(assigns.locale, assigns.customer))
else
  _ -> "--"
end
```

### Test suites and served-browser evidence

**Analogs:** existing adjacent LiveView suites and tracked `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js`.

The invoice and recovery test modules use `AccrueAdmin.LiveCase`, define an `Accrue.Auth` adapter, and seed fixtures/events in setup (`invoice_live_test.exs` lines 1-50; `analytics/recovery_live_test.exs` lines 1-55). Extend the existing suites for deterministic date/currency edge cases, owner-scope denials, refreshed eligibility, and result evidence instead of introducing new harnesses. Charge/refund assertions belong in `charge_live_test.exs`; list filters in `charges_live_test.exs`.

The Phase 234 served spec imports the shared host fixture/login/LiveView helpers and accessibility checker (lines 1-8), then defines focused DOM integrity, overflow, and accessibility helpers (lines 50-71). It is an immutable prior-phase evidence artifact; use its conventions in a new focused sibling only if browser proof is added. Do not edit its source or archived captures.

## Shared Patterns

### Owner scoping and authorization

**Sources:** `accrue_admin/lib/accrue_admin/queries/invoices.ex` lines 73-86; `queries/charges.ex` lines 67-80; `scoped_path.ex` lines 25-59.  
**Apply to:** invoice/payment detail reload, action dispatch and refresh, recovery links. Re-resolve current authorization and active owner scope on dispatch. An ID or query-string `org` is not authority.

### Money and unavailable values

**Source:** `accrue_admin/lib/accrue_admin/components/money_formatter.ex` lines 18-65.  
**Apply to:** invoice, payment, refund and recovery amounts. Preserve integer minor units and currency precision, including true zero. Missing/unsupported amount or currency renders unavailable.

### Truthful action outcomes

**Sources:** `invoice_live.ex` lines 1010-1030; `charge_live.ex` lines 586-603; authoritative contracts in `accrue/lib/accrue/billing/invoice_actions.ex` and `refund_actions.ex` (see research refs at 140-142).  
**Apply to:** invoice pay/finalize and refund. Keep accepted, provider/customer action required, definitive failure, completed from refreshed scoped evidence, and ambiguous/not-confirmed distinct. No automatic retry or new reconciliation service.

### Recovery history and current state

**Sources:** `recovery_live.ex` lines 26-59; `queries/dunning.ex` lines 172-222.  
**Apply to:** recovery KPIs, event history, at-risk table, and links. Keep window/owner/currency attached; historical failures do not overwrite current invoice/subscription observations.

## No Analog Found

None. All identified work fits existing modules and adjacent test/browser patterns; there is no evidence for a new service, provider, or migration.

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/{live,queries,components}`, `accrue_admin/test/accrue_admin/live`, `examples/accrue_host/e2e`, and canonical core billing action modules.  
**Tracked-source gate:** every named source analog was verified with `git ls-files`; all listed paths are tracked.  
**Project instructions:** no root `AGENTS.md`; supplied GSD pattern-mapper instructions were read. No `.codex/skills/` or `.agents/skills/` project skill files were present.  
**Pattern extraction date:** 2026-10-08
