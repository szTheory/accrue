---
phase: 260621-lzc
plan: 01
subsystem: examples/accrue_host (host integration tests)
tags: [test-repair, webhooks, admin, security-regression, selection-driven-retry]
requires:
  - accrue_admin/lib/accrue_admin/live/webhooks_live.ex (selection-driven retry contract)
  - accrue_admin/lib/accrue_admin/copy.ex (webhooks_index_empty_title/0)
  - accrue_admin/lib/accrue_admin/copy/locked.ex (replay_blocked/0, owner_access_denied/0)
provides:
  - Repaired cross-package security regression test exercising the selection-driven retry boundary
affects:
  - examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs
tech-stack:
  added: []
  patterns:
    - "Inject data_table_bulk_action message directly to LiveView pid to exercise the retry handler defense-in-depth"
    - "Assert HTML-escaped flash copy (FlashGroup escapes apostrophes via <%= %>)"
key-files:
  created: []
  modified:
    - examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs
decisions:
  - "Assert both admin.webhook.replay.completed == 0 AND admin.webhook.bulk_replay.completed == 0 — the latter is the new flow's success event and is the load-bearing proof nothing was requeued"
  - "Compare replay_blocked() against its HTML-escaped form (isn&#39;t) because FlashGroup escapes the message"
  - "Reverted incidental mix.lock churn to honor the test-file-only constraint"
metrics:
  duration: 3m
  completed: 2026-06-21
status: complete
---

# Phase 260621-lzc Plan 01: Repair host admin webhook replay test to selection-driven contract Summary

Repaired the orphaned second test in the host integration suite that still clicked the
removed `[data-role='prepare-bulk-replay']` button and asserted removed filter-warning copy,
translating its bulk step to the new selection-driven retry contract without weakening the
cross-package security regression (out-of-scope/ambiguous webhooks must not be bulk-replayable,
zero success audits).

## What was done

- **Kept unchanged:** the first test, the `insert_webhook/1` and `insert_attempt_job/1` helpers,
  the module header/aliases, the fixtures, the session setup, and the single-replay denial
  assertions (outsider redirect → `owner_access_denied()`, ambiguous inline → ownership-not-verified copy, lines ~197-207).
- **Replaced** the broken bulk step (the `prepare-bulk-replay` click + removed filter-warning assert) with a two-layer assertion:
  - **Layer 1 (list scoping, black-box):** load `/admin/webhooks?status=dead&type=invoice.payment_failed&org=<allowed_org>`, then `refute` both outsider/ambiguous ids appear, `assert` the empty-state title (`AccrueAdmin.Copy.webhooks_index_empty_title()`), and `refute` any `data-role="bulk-action"` affordance.
  - **Layer 2 (handler defense-in-depth):** `send(bulk_view.pid, {:data_table_bulk_action, "retry_selected", [outsider_id, ambiguous_id]})` → `render` → `render_click` the `[data-role='confirm-retry-selected']` button → assert the `replay_blocked()` warning surfaces (server `scope_selected_ids` drops both ids → `[]` → push warning, no requeue).
- **Preserved** the load-bearing `admin.webhook.replay.completed == 0` aggregate, and **added** a parallel `admin.webhook.bulk_replay.completed == 0` aggregate (the new flow's success event) so the test proves the new code path recorded no success audit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Flash copy assertion needed HTML-escaped form**
- **Found during:** Task 1 (first test run failed on `assert blocked_html =~ Copy.Locked.replay_blocked()`)
- **Issue:** `FlashGroup` renders the message via `<%= flash[:message] %>`, which HTML-escapes the apostrophe in "isn't" → `isn&#39;t`, so the raw `replay_blocked()` string never matched.
- **Fix:** Escape the copy accessor at runtime with `Phoenix.HTML.html_escape/1 |> Phoenix.HTML.safe_to_string/1` before asserting (mirrors the existing escaped ambiguous-copy assertion in this same file).
- **Files modified:** examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs
- **Commit:** 42b75764

### Out-of-scope (reverted, not committed)

**mix.lock churn (pre-existing stale-lock condition):** Running `mix test`/`mix deps.get` re-resolved several transitive deps to newer published versions (finch 0.22→0.23, phoenix 1.8.7→1.8.8, phoenix_live_view 1.1.31→1.1.32, req 0.5.18→0.6.2, floki, flop_phoenix, sourceror). This is an environmental stale-lock on `main` unrelated to the test change. Per the test-file-only constraint and the "do NOT touch mix.lock" rule, the lock was reverted with `git checkout -- examples/accrue_host/mix.lock`; the deps-on-disk are at the upgraded versions but the committed lock is left untouched. Flag for a future deps-bump task.

## Verification (exact results)

- `cd examples/accrue_host && mix test test/accrue_host_web/admin_webhook_replay_test.exs --seed 0` → **2 tests, 0 failures**.
- `cd examples/accrue_host && mix test test/accrue_host_web/ --seed 0` → **109 tests, 0 failures** (admin web suite green; warnings are benign operation_id / signature-test noise).
- `grep -c "prepare-bulk-replay" …admin_webhook_replay_test.exs` → **0** (removed selector gone).
- `grep -c "No failed or dead-lettered webhook rows match the current filters" …` → **0** (removed copy gone).
- `grep -c "admin.webhook.replay.completed" …` → **1** (zero-audit assertion preserved).
- `grep -c "admin.webhook.bulk_replay.completed" …` → **1** (new-flow success-event zero assertion added).
- `git diff --name-only` (pre-commit) → only `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs`; mix.lock NOT changed.

## Commit

- `42b75764` test(260621-lzc): repair host admin webhook replay test to selection-driven contract (1 file changed, 42 insertions(+), 3 deletions(-))

## Self-Check: PASSED
- FOUND: examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs
- FOUND: commit 42b75764
