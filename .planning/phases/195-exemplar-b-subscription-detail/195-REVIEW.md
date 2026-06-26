---
phase: 195-exemplar-b-subscription-detail
reviewed: 2026-06-26T10:13:38Z
depth: standard
files_reviewed: 30
files_reviewed_list:
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/js/app.js
  - accrue_admin/assets/js/hooks/overlay.js
  - accrue_admin/assets/js/hooks/scroll_lock.js
  - accrue_admin/e2e/admin-spec-detail-phase195.spec.js
  - accrue_admin/lib/accrue_admin/components/detail.ex
  - accrue_admin/lib/accrue_admin/components/detail_drawer.ex
  - accrue_admin/lib/accrue_admin/components/dropdown_menu.ex
  - accrue_admin/lib/accrue_admin/components/overlay.ex
  - accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex
  - accrue_admin/lib/accrue_admin/copy/subscription.ex
  - accrue_admin/lib/accrue_admin/layouts.ex
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex
  - accrue_admin/package.json
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/accrue_admin.js
  - accrue_admin/test/accrue_admin/components/overlay_components_test.exs
  - accrue_admin/test/accrue_admin/live/charge_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
  - accrue_admin/test/accrue_admin/live/step_up_test.exs
  - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
  - accrue_admin/test/js/dropdown_test.mjs
  - accrue_admin/test/js/scroll_lock_test.mjs
  - examples/accrue_host/e2e/generated/copy_strings.json
  - storybook/_support/registry_story.ex
  - storybook/components/action_menu.story.exs
  - storybook/components/detail.story.exs
  - storybook/components/overlay.story.exs
  - storybook/components/subscription_detail.story.exs
findings:
  critical: 1
  warning: 3
  info: 0
  total: 4
status: issues_found
---

# Phase 195: Code Review Report

**Reviewed:** 2026-06-26T10:13:38Z
**Depth:** standard
**Files Reviewed:** 30
**Status:** issues_found

## Summary

Reviewed the Phase 195 Subscription detail exemplar, overlay component and hooks, CSS/static bundles, copy export fixture, tests, and Storybook stories. The overlay substrate generally compiles and the scoped component/LiveView/JS tests pass, but the implementation still ships one security-relevant billing action gap plus several runtime/test-fixture drift risks.

Verification run during review:

```bash
cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/live/subscription_live_test.exs
cd accrue_admin && node --test test/js/dropdown_test.mjs test/js/scroll_lock_test.mjs
```

The Mix run passed but emitted a warning that `AccrueAdmin.Storybook.RegistryStory.variations_for/1` is undefined.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: [BLOCKER] Subscription item deletion bypasses step-up auth

**File:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex:33`

**Issue:** The destructive action set only includes `cancel_now` and `comp_subscription`, but the new action menu exposes `remove_item` and the executor deletes the selected subscription item through `Billing.remove_item/2` at lines 1125-1136. That means an admin can remove a subscription item after only the drawer confirmation, without the fresh-auth challenge required for destructive admin actions.

**Fix:**

```elixir
@destructive_actions ~w(cancel_now comp_subscription remove_item)
```

Add a LiveView test that opens the `Remove item` drawer, submits the form, clicks confirm, and asserts the step-up modal appears before the item is removed.

## Warnings

### WR-01: [WARNING] Summary-row actions bypass provider capability gates

**File:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex:621`

**Issue:** The summary list always renders a `Plan / price` Change action for `swap_plan`, and the quantity row only checks `single_item_subscription?/1`. Those rows do not reuse `swap_plan_available?/1` or `quantity_change_available?/1`, so Braintree subscriptions can still expose unsupported "Change" affordances even when the primary buttons and overflow menu correctly hide those actions.

**Fix:** Gate the summary row actions with the same capability predicates used by the action band.

```elixir
%{
  label: "Plan / price",
  value: current_price_id(subscription) || "-"
}
|> maybe_put_summary_action(swap_plan_available?(subscription), %{
  action_label: "Change",
  action_context: "plan for subscription #{subscription_label}",
  action_event: "open_action_drawer",
  action_value: "swap_plan"
})
```

Apply the same pattern to the quantity row with `quantity_change_available?/1`, and add a Braintree test that refutes `phx-value-action_type="swap_plan"` and `phx-value-action_type="update_quantity"` in the summary list when unsupported.

### WR-02: [WARNING] Copy export fixture omits visible Phase 195 action strings

**File:** `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex:27`

**Issue:** The export allowlist adds only some Subscription action labels. Visible Phase 195 drawer/menu strings such as `subscription_action_update_quantity`, `subscription_action_add_item`, `subscription_action_update_item_quantity`, `subscription_action_remove_item`, `subscription_action_pause_collection`, `subscription_action_resume`, `subscription_proration_none`, and `subscription_proration_always_invoice` are used by the UI but absent from the exported JSON fixture. Browser anti-drift checks can no longer catch drift in those labels.

**Fix:**

```elixir
subscription_proration_none
subscription_proration_always_invoice
subscription_action_resume
subscription_action_update_quantity
subscription_action_add_item
subscription_action_update_item_quantity
subscription_action_remove_item
subscription_action_pause_collection
```

Add those atoms to `@allowlist`, regenerate `examples/accrue_host/e2e/generated/copy_strings.json`, and extend the fixture test to assert all drawer action labels and proration labels.

### WR-03: [WARNING] RegistryStory helper is not compiled from its current path

**File:** `storybook/_support/registry_story.ex:1`

**Issue:** The helper was added at repo-root `storybook/_support/registry_story.ex`, but the `accrue_admin` Mix project compiles `storybook/_support` relative to `accrue_admin`. During the scoped test run the compiler warned that `AccrueAdmin.Storybook.RegistryStory.variations_for/1` is undefined, and stories guarded by `Code.ensure_loaded?/1` will silently return no variations.

**Fix:** Move the helper under a compiled path such as `accrue_admin/storybook/_support/registry_story.ex` or `accrue_admin/lib/accrue_admin/storybook/registry_story.ex`, or update the Mix `elixirc_paths` to include `../storybook/_support`. Then run compilation with warnings treated as failures to prove the story helper is available.

---

_Reviewed: 2026-06-26T10:13:38Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
