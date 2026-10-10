---
phase: 240-shared-system-and-real-billing-exemplar
reviewed: 2026-10-10T22:43:22Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - .github/workflows/accrue_admin_browser.yml
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/js/hooks/accrue_theme.js
  - accrue_admin/assets/js/hooks/connection_state.js
  - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
  - accrue_admin/e2e/admin-page-flow-phase191.spec.js
  - accrue_admin/e2e/admin-spec-detail-phase198.spec.js
  - accrue_admin/e2e/admin-spec-list-phase196.spec.js
  - accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex
  - accrue_admin/lib/accrue_admin/copy/invoice.ex
  - accrue_admin/lib/accrue_admin/live/charge_live.ex
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/invoices_live.ex
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/accrue_admin.js
  - accrue_admin/test/accrue_admin/components/theme_picker_test.exs
  - accrue_admin/test/accrue_admin/e2e_fixtures_test.exs
  - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
  - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
  - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
  - accrue_admin/test/accrue_admin/theme_test.exs
  - accrue_admin/test/js/command_palette_test.mjs
  - accrue_admin/test/js/focus_trap_test.mjs
  - accrue_admin/test/support/e2e_fixtures.ex
  - accrue_admin/test/support/e2e_plug.ex
  - examples/accrue_host/e2e/phase237-admin-billing.spec.js
  - examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 240: Code Review Report

**Reviewed:** 2026-10-10T22:43:22Z
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

Reviewed all 27 listed files. One warning affects retrying a destructive invoice action after the operator dismisses its step-up challenge.

## Warnings

### WR-01: Dismissing invoice step-up leaves confirmation locked

**Severity:** WARNING
**File:** `accrue_admin/lib/accrue_admin/live/invoice_live.ex:211-216`
**Issue:** `confirm_action` sets `dispatch_state` to `:awaiting_step_up` before opening the challenge. Escape and the explicit step-up dismiss event clear the challenge through `StepUp.dismiss_challenge/1`, but leave `dispatch_state` unchanged. A subsequent `confirm_action` is therefore ignored by the guard at line 164, and the operator must cancel and stage the invoice action again to recover.
**Fix:** Reset the dispatch state when dismissing the challenge, for example:

```elixir
def handle_event("step_up_escape", _params, socket) do
  {:noreply,
   socket
   |> dismiss_step_up_if_pending()
   |> assign(:dispatch_state, :staged)}
end
```

Apply the same reset to `step_up_dismiss` so both dismissal paths restore a retryable confirmation state.

---

_Reviewed: 2026-10-10T22:43:22Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
