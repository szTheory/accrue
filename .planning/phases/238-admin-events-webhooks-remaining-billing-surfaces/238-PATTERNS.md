# Phase 238: Admin Events, Webhooks & Remaining Billing Surfaces - Pattern Map

**Mapped:** 2026-10-08  
**Files analyzed:** 9 likely touched or extended files  
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` | component (LiveView) | request-response / event-driven | `accrue_admin/lib/accrue_admin/live/webhook_live.ex` | role-match; single replay sibling |
| `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs` | test | event-driven / CRUD | same file; `webhooks_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/webhooks_live_test.exs` | test | request-response / event-driven | same file | exact |
| `accrue_admin/lib/accrue_admin/live/events_live.ex` | component (LiveView) | request-response | same file | exact |
| `accrue_admin/test/accrue_admin/live/events_live_test.exs` | test | request-response | same file | exact |
| `accrue_admin/test/accrue_admin/live/coupons_live_test.exs` | test | request-response | same file | exact |
| `accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs` | test | request-response | same file | exact |
| `accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs` | test | request-response / event-driven | same file | exact |
| `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` | test | request-response / event-driven | same file | exact |

Research identifies only the bulk replay behavior as a concrete implementation gap; the Events, coupon, promotion-code, and Connect code/tests are bounded existing inspection surfaces. Extend those only if the plan finds a named acceptance gap. Existing Connect override implementation is a relevant step-up analog in `connect_account_live.ex`.

## Pattern Assignments

### `accrue_admin/lib/accrue_admin/components/data_table.ex` (shared stateful LiveComponent)

**Analog:** `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` and `accrue_admin/test/accrue_admin/components/at_risk_table_test.exs` (tracked; explicit loading/error/empty/pagination state contract).

The DataTable currently derives empty/populated/list states from loaded rows and directly destructures query results in `reload/3` and `load-more`. Add a dedicated unavailable/partial-load state with safe retry behavior; do not map query errors to an empty list or expose exception text. Extend `accrue_admin/test/accrue_admin/components/data_table_test.exs` using its existing fixture query module to drive the error/recovery cases. Only expected database read failures should become user-visible unavailable states; unrelated implementation errors should still surface.

### `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` (LiveView, request-response / event-driven)

**Analog:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex` (tracked; sibling detail LiveView with the safe single-replay flow).

**Imports and aliases** (webhooks lines 1-15):

```elixir
use Phoenix.LiveView

alias Accrue.{Auth, Events}
alias Accrue.Webhook.WebhookEvent
alias Accrue.Webhooks.DLQ
alias AccrueAdmin.Copy
alias AccrueAdmin.Queries.Webhooks
```

**Single-action step-up pattern** (`webhook_live.ex` lines 82-101):

```elixir
def handle_event("confirm_replay", _params, %{assigns: %{webhook: webhook}} = socket) do
  case StepUp.require_fresh(socket, step_up_action(webhook), &execute_replay(&1, webhook.id)) do
    {:ok, socket} -> {:noreply, socket}
    {:challenge, socket} -> {:noreply, socket}
    {:error, _reason, socket} ->
      {:noreply,
       socket
       |> clear_replay_drawer()
       |> push_flash(:error, Copy.webhook_replay_step_up_unavailable())}
  end
end
```

The corresponding local Connect action uses the same `StepUp.require_fresh(socket, step_up_action(...), callback)` shape in `connect_account_live.ex` lines 74-100. For bulk replay, check freshness at confirmation time; do not infer authorization from the visible button or selection snapshot.

**Current bulk flow to refine** (`webhooks_live.ex` lines 88-153): `handle_info({:data_table_bulk_action, "retry_selected", ids}, socket)` stores selected IDs/count; `confirm_retry_selected` scopes IDs then calls `replay_scoped_rows/1`. The current reducer calls `DLQ.requeue(id)` sequentially and halts on the first error. Keep `DLQ.requeue/1`, but re-resolve each row in the active owner scope and recheck `status in [:failed, :dead]` immediately before queueing. Accumulate per-row outcomes so a single failure does not erase evidence for other selected rows.

**Audit boundary** (`webhooks_live.ex` lines 491-517): `record_bulk_replay/4` calls `Events.record/1` with `admin.webhook.bulk_replay.completed`, then `Auth.log_audit/2`. Keep the selected IDs and explicit selected/eligible/attempted/requeued/skipped/failed counts in this existing audit boundary. Avoid recording completion for an empty/inaccessible selection as successful replay.

**Success copy:** current success branch calls `Copy.webhooks_retry_success(count)` where `count` is the submitted selection size. Use outcome counts to report accepted/requeued work; queue acceptance must not be worded as completed processing.

---

### `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs` (test, event-driven / CRUD)

**Analog:** same file (tracked; focused fixture and audit assertions for single and bulk replay).

**Setup and deterministic auth:** lines 1-57 define `AuthAdapter`, save/restore the configured adapter, and seed `:dead` / `:failed` webhook rows. Keep the test repo and local records; do not call an external processor.

**Bulk acceptance test** (lines 87-122):

```elixir
{:ok, view, _html} = live(conn, "/billing/webhooks?type=invoice.payment_failed")
render_click(element(view, "[data-role='toggle-all']"))
render_click(element(view, "[data-role='bulk-action']"))
_ = render(view)
html = render_click(element(view, "[data-role='confirm-retry-selected']"))
assert html =~ "Retrying"
assert audit_count_after == audit_count_before + 1
```

Build named counterexamples beside this test: mixed eligible/ineligible statuses, a status changed after selection, foreign-owner and duplicate IDs, and a requeue failure after an earlier success. Assert no unauthorized queue mutation and that result/audit counts match actual per-row outcomes. Preserve the separate single replay assertion for audit linkage and status transition (lines 59-85).

### `accrue_admin/test/accrue_admin/live/webhooks_live_test.exs` (test, request-response / event-driven)

**Analog:** same file; tracked.

Lines 193-242 cover selection controls, visible confirmation, and filtered retry; lines 254-329 cover audit IDs/count, owner-scoped counts, and blocked replay. Reuse `LiveCase`, `AuthAdapter`, seeded `WebhookEvent` fixtures, role/data-role selectors, and `TestRepo` assertions. Extend for partial result display and do not duplicate the deeper single/bulk mutation checks in `webhook_replay_test.exs`.

### `accrue_admin/lib/accrue_admin/live/events_live.ex` (LiveView, request-response)

**Analog:** same file; tracked.

**Imports and scoped navigation** (lines 1-45):

```elixir
use Phoenix.LiveView
import Ecto.Query
alias Accrue.Repo
alias AccrueAdmin.Queries.Events
alias AccrueAdmin.ScopedPath
```

Mount uses `ScopedPath.build(..., "/events", socket.assigns.current_owner_scope)` for both current and table paths, then loads summary. The filter handler delegates to `DataTableNav.patch_with_filters/3`, dropping `"_target"` and `"_csrf_token"`. Keep event ledger evidence separate from webhook delivery status, and preserve owner-scoped links and explicit lazy loading.

### `accrue_admin/test/accrue_admin/live/events_live_test.exs` (test, request-response)

**Analog:** same file; tracked.

Lines 84-148 establish `ListContracts.fetch!(:events)`, page-header/filter contracts, and default ledger lens. Lines 269-317 are the owner-scope proof with in-scope/out-of-scope subjects. Reuse event fixtures and assert foreign-owner rows are absent; avoid interpreting an unavailable evidence query as a truly empty history.

### `accrue_admin/test/accrue_admin/live/coupons_live_test.exs` and `accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs` (tests, request-response)

**Analogs:** each same file; tracked.

Both files seed persisted records, authenticate through the local test `AuthAdapter`, and assert the two inspection surfaces remain distinct. Coupons test lines 60-70 checks coupon filtering and link to promotion codes. Promotion codes test lines 58-69 checks independent code filtering, parent coupon display, and links back to coupon detail. Their `ListContracts` tests pin the default lens and accessible list chrome. Extend with terms/usage/restriction/relationship and unavailable-state assertions only; do not add unsupported create/edit controls.

### `accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs` (test, request-response / event-driven)

**Analog:** same file; tracked. For mutation/step-up semantics, use tracked sibling `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` lines 74-100.

Lines 60-95 cover list header and needs-attention vs all-account lenses. Lines 248 onward assert a row's override state. Seed provider readiness fields (`charges_enabled`, `payouts_enabled`, `details_submitted`) independently from `data["platform_fee_override"]`; test copy and state without conflating Stripe observation with the local fee setting. Connect detail validates the override then requires fresh step-up before `execute_override_save`.

### `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` (test, request-response / event-driven)

**Analog:** same file; tracked.

This is the existing host Playwright journey (file currently names its suite `@phase15-trust`). Reuse `test`/`expect` from `./support/test.js`, fixture reseeding and login helpers, semantic role/name assertions, responsive overflow checks, and screenshot attachments as supporting evidence. The file already contains an admin replay walkthrough and an `replayAuditEventLocator` helper (lines 55-76); extend the real mounted journey for selection confirmation, step-up, partial outcomes, Events evidence, coupon/promotion-code inspection, and Connect local override. Keep reliable browser behavior assertions as the gate; screenshots supplement them.

## Shared Patterns

### Owner scope and route navigation

**Sources:** `accrue_admin/lib/accrue_admin/live/events_live.ex` lines 22-45; `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` lines 24-38.  
**Apply to:** Events/Webhooks list and detail links, and any selected-row re-resolution.

```elixir
ScopedPath.build(mount_path, "/events", socket.assigns.current_owner_scope)
AccrueAdmin.DataTableNav.patch_with_filters(socket, socket.assigns.table_path,
  Map.drop(params, ["_target", "_csrf_token"]))
```

Bulk IDs originate in the browser, so the handler must resolve every ID under the current owner scope at action time. Suppress inaccessible foreign-record details in the UI/audit.

### Step-up and action audit

**Sources:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex` lines 82-101, 456-494, 571-600; `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` lines 74-100.  
**Apply to:** consequential retry or local policy mutations.

Reuse `StepUp.require_fresh/3`, `StepUp.verify/2`, the action descriptor, and the existing `Events.record/1` plus `Auth.log_audit/2` boundary. Require freshness server-side at submission, and record only actual outcomes.

### List and fixture test conventions

**Sources:** `accrue_admin/test/accrue_admin/live/events_live_test.exs` lines 1-40, 84-109; matching `coupons_live_test.exs` and `promotion_codes_live_test.exs`.  
**Apply to:** changed inspection surfaces.

Tests use `AccrueAdmin.LiveCase`, local adapter setup/restore, `TestRepo`, seeded domain facts, `ListContracts`, and semantic `data-role` selectors. Keep owner-scope and empty/unavailable cases explicit.

## No Analog Found

None. The novel portion is the bulk replay partial-result contract; implement it by extending existing webhook handler, step-up and audit patterns rather than introducing a new queue or evidence abstraction.

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/live/`, `accrue_admin/test/accrue_admin/live/`, `examples/accrue_host/e2e/`, and `examples/accrue_host/test/accrue_host_web/`.  
**Files scanned:** 12 focused source/test/browser files.  
**Tracked-source verification:** all analog paths listed above were checked with `git ls-files`; no runtime mirror paths are referenced.  
**Pattern extraction date:** 2026-10-08
