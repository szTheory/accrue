# Phase 28 — Pattern map

## PATTERN MAPPING COMPLETE

Analogs and excerpts for executors (from CONTEXT + codebase scan).

| Planned change | Role | Closest analog | Notes |
|----------------|------|----------------|-------|
| Step-up modal semantics | LiveView HEEx + `JS.*` | `StepUpAuthModal` + `charge_live.ex` `handle_event("step_up_submit", ...)` | Mirror event names; add `phx-mounted` / `phx-window-keydown` on the **same** `section` subtree that gates `@pending` |
| Stateful table chrome | LiveComponent | `accrue_admin/lib/accrue_admin/components/data_table.ex` lines ~167–194 (`<table class="ax-data-table-grid">`) | Insert `<caption>` only inside desktop `<table>` when assign present |
| Copy SSOT | Module | `accrue_admin/lib/accrue_admin/copy.ex` | Add `step_up_submit_label/0`, `customers_index_table_caption/0`, `webhooks_index_table_caption/0` (exact strings from `28-UI-SPEC.md` / CONTEXT) |
| Mounted admin journey | Playwright | `examples/accrue_host/e2e/verify01-admin-mounted.spec.js` | Reuse `login`, `waitForLiveView`, org navigation |
| Step-up browser submit | Playwright | `accrue_admin/e2e/phase7-uat.spec.js` (lines ~120–121) | Selector pattern `form[phx-submit='step_up_submit']` |

### Data table excerpt (desktop shell)

```heex
<table class="ax-data-table-grid">
  <thead>
```

Caption (when implemented) belongs **immediately after** `<table>` open, before `<thead>`, per HTML5 table model.

### Step-up excerpt (current submit label)

```heex
<button type="submit" class="ax-link">Verify</button>
```

Target state: `<%= Copy.step_up_submit_label() %>` (or equivalent function name locked in plan).
