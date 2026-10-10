# Phase 241: Billing Operator Journeys - Pattern Map

**Mapped:** 2026-10-09  
**Files analyzed:** 22 bounded source, test and browser-owner files  
**Analogs found:** 22 / 22

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/lib/accrue_admin/scoped_path.ex` | utility | transform | same file | exact |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | controller (LiveView) | request-response | `live/invoice_live.ex` | role-match |
| `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` | controller (LiveView) | request-response | same file | exact |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | controller (LiveView) | request-response / async | same file | exact |
| `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | controller (LiveView) | request-response | same file | exact |
| `accrue_admin/lib/accrue_admin/live/charge_live.ex` | controller (LiveView) | request-response | `live/invoice_live.ex` | role-match |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | controller (LiveView) | request-response | `live/subscription_live.ex` | role-match |
| `accrue_admin/lib/accrue_admin/queries/invoices.ex` | service/query | CRUD | same file | exact |
| `accrue_admin/lib/accrue_admin/components/detail.ex` | component | transform/presentation | `components/detail_drawer.ex` | role-match |
| `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` | component | request-response | same file | exact |
| `accrue_admin/lib/accrue_admin/components/related_resources.ex` | component | transform/presentation | same file | exact |
| `accrue_admin/lib/accrue_admin/components/money_formatter.ex` | component | transform | same file | exact |
| `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` | component | request-response | same file | exact |
| `accrue_admin/lib/accrue_admin/copy.ex` | utility/copy | transform | same file | exact |
| `accrue_admin/lib/accrue_admin/copy/invoice.ex` | utility/copy | transform | same file | exact |
| `accrue_admin/lib/accrue_admin/copy/subscription.ex` | utility/copy | transform | `copy/invoice.ex` | role-match |
| `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` | utility/copy | transform | `copy/invoice.ex` | role-match |
| `accrue_admin/test/accrue_admin/scoped_path_test.exs` | test | transform | same file | exact |
| `accrue_admin/test/accrue_admin/queries/query_modules_test.exs` | test | CRUD | same file | exact |
| `accrue_admin/test/accrue_admin/live/{invoice,charge,subscription,customer}_live_test.exs` | test | request-response | same route owner tests | exact |
| `accrue_admin/test/accrue_admin/live/analytics/{recovery,campaign}_live_test.exs` | test | request-response / async | same route owner tests | exact |
| `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js`; `examples/accrue_host/e2e/phase237-admin-billing.spec.js` | test/browser | request-response | same browser specs | exact |

The bounded UI spec and research identify the route/query/component owners above; do not create a new routing, action, review-schema, or dependency layer. The existing small presentation components are the only candidates for extracting genuinely repeated invoice-review presentation.

## Pattern Assignments

### Scoped destinations and list membership

**Analog:** `accrue_admin/lib/accrue_admin/scoped_path.ex` (tracked)

`return_path/5` is the safe reconstruction seam. It validates a decoded local route, checks a customer-detail ID against the loaded customer, and rebuilds beneath the current mount and owner; its error branch uses the caller's fallback. Relevant source: lines 90-105. `validate_return_path/2` rejects scheme/host/userinfo/fragment, filters allowed keys, then rebuilds params (lines 108-134). Present limitation: it currently requires a query string (line 117), and route allowlists at lines 6-11 lag the actual invoice/payment decoders. Keep only decoder-owned filters and meaningful `view=all`, customer tab, and Recovery window values. Do not claim sort, cursor, or subscription-only invoice filtering.

Invoice membership is owned by `accrue_admin/lib/accrue_admin/queries/invoices.ex` (tracked), not by the link. Its decoder supports `q`, `status`, `customer_id`, and `collection_method`; existing query clauses must remain the source of truth. Name a customer-filtered open set “Open invoices for this customer”; label the separate scope queue according to actual scope. Distinguish any subscription-local count from either linked set.

Reusable API:

```elixir
ScopedPath.return_path(mount_path, raw_return_path, owner_scope,
  expected_customer_id, fallback_suffix)
```

Each destination's visible label and href should be derived from the same validated meaning. A query-free recognized list is a valid origin once the utility and its existing unit owner explicitly support it.

### Subscription detail, customer tabs, and invoice-origin preservation

**Analog:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex` and `customer_live.ex` (tracked)

Subscription LiveView owns detail facts, related resources and actions. Use its existing record/action structure; move identity, lifecycle, exact confirmed plan/period/collection facts and blockers ahead of related billing. Keep one secondary related-billing group, linking to the supported `customer_id` invoice query. Customer LiveView's existing peer-tab origins are the pattern for preserving a same-customer tab. Invoice/payment list origins belong to their existing detail return decode paths and `ScopedPath`; ensure filters are supported there before carrying them through. Breadcrumb hierarchy and explicit contextual return remain distinct.

### Recovery to campaign return

**Analog:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` and `campaign_live.ex` (tracked)

Recovery parses the supported `7d`, `30d`, `90d` window and defaults invalid/missing input to `30d` (`recovery_live.ex:227-228`). Campaign currently resolves `return_to` through `ScopedPath` (`campaign_live.ex:44-54`), and its breadcrumb and explicit link both target that path (`69-82`); its current generic “Back to results” copy is not destination-specific. Keep a valid Recovery origin/window and current owner, use scoped Recovery for direct, invalid, or unrelated origins, and derive both breadcrumb and explicit return label from the resolved destination. A campaign's historical timeline remains separate from the selected Recovery window.

### Semantic review, fresh checks, and exact money

**Analog:** `accrue_admin/lib/accrue_admin/live/invoice_live.ex` (semantic review exemplar); action owners `subscription_live.ex`, `charge_live.ex`, and `customer_live.ex` (tracked)

Invoice preparation stages identity, actor, scope, fingerprint, reviewed minor-unit amount and currency (`invoice_live.ex:121-143`). Confirmation rejects repeat in-flight submissions, revalidates the staged review and requires fresh step-up for destructive actions (`161-199`). This is the semantic composition exemplar, while the four existing action LiveViews remain owners of eligibility, input validation, authorization, step-up, dispatch, duplicate handling and outcome semantics.

Subscription stages the current subscription ID, actor, scope and fingerprint before review, then validates before step-up/dispatch (`subscription_live.ex:188-250`). Refund preparation retains a selected charge and computed refund action; confirmation delegates fresh step-up before execution (`charge_live.ex:104-155`). Payment-method action retains the selected method type/record and reloads and revalidates it on confirmation (`customer_live.ex:164-249`). Reviews should expose exact human identity and ID, customer/owner, current state, exact requested money/currency, consequences/timing, and evidence limitations. Reuse `Detail`, `DetailDrawer`, `MoneyFormatter`, and `StepUpAuthModal`; preserve unavailable amounts as unavailable, and confirmed vs observed state. Dismissal clears staged state; it does not dispatch or label the domain action as canceled.

### Tests, fixtures, held-busy states, and served assets

**Analog:** `accrue_admin/test/accrue_admin/scoped_path_test.exs`, existing route LiveView tests, package browser flow helpers/spec, `examples/accrue_host/e2e/phase237-admin-billing.spec.js` (tracked)

- `scoped_path_test.exs` owns route/value allowlists, safe fallback, scope rebuilding and same-customer checks. Query decoder/result membership assertions belong with `queries/query_modules_test.exs`; route link text + destinations belong with the billing list/detail LiveView tests.
- Campaign cases belong in `live/analytics/campaign_live_test.exs` and Recovery window cases in `recovery_live_test.exs`. Action content and negative safety controls belong in each action owner's LiveView test, not a generic review test.
- `admin-interaction-overlay-phase199.spec.js` and its `phase191-page-flow-helpers.js` own real keyboard focus, overlay dismissal/replacement, busy/reconnect, narrow viewport and effective theme interactions. Reuse its disposable seeded records and helpers; do not couple mutation/reset fixtures to any feedback preview.
- `phase237-admin-billing.spec.js` is the mounted host billing owner. Its existing `assertAssetBytes` flow records source/package-built/host-compiled/HTTP-served provenance. Keep asset builds explicit and bind served assertions to changed consumers. Retain existing served fixture setup, held-busy/reconnect controls, complete-baseline guard and pixel thresholds; no fixed sleeps or blanket retries.

All paths named here were confirmed git-tracked with `git ls-files`; no install/runtime mirror paths are used.

## Shared Patterns

### Scope and fallback

Use `ScopedPath` for every contextual return; owner resolution remains fresh in the route. Strip unknown keys, rebuild the current owner into local paths, reject external/cross-mount/cross-customer targets, and use the route's scoped fallback.

### Action safety

Keep mutation logic in the current four LiveViews. A reusable presentation helper may render repeated review facts, but action-specific target validation, fresh auth, step-up, stale fingerprint/state detection, duplicate/in-flight lock, and evidence-based result handling stay with each owner.

### Rendering and copy

Reuse current `Detail`/drawer/related-resource and exact-money components, established `Copy` owners, theme tokens and existing focus/busy hooks. Keep summary hierarchy and exact labels truthful to loaded evidence. Do not introduce universal wizard behavior, new dashboard structure, dependency or UI abstraction.

## No Analog Found

None for the bounded changes. Source and browser owners exist for every route family, action type and asset/fixture seam; missing coverage is an extension of those owners.

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/{scoped_path,queries,components,copy,live}`, corresponding `accrue_admin/test` owners, `accrue_admin/e2e`, and `examples/accrue_host/e2e`.  
**Pattern extraction date:** 2026-10-09
