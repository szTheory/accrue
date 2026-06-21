---
phase: 260621-lzc
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs
autonomous: true
requirements:
  - QUICK-260621-lzc
must_haves:
  truths:
    - "The second test (`ambiguous or out-of-scope webhook replay blocks single and bulk replay without success audits`) no longer clicks the removed `[data-role='prepare-bulk-replay']` button and compiles/runs clean against the selection-driven contract."
    - "Loading `/admin/webhooks?status=dead&type=invoice.payment_failed&org=<allowed_org>` shows NO selectable rows for the outsider/ambiguous webhooks: the empty-state renders, and the selection affordances (`[data-role='selection-bar']`/`[data-role='toggle-all']`/`[data-role='bulk-action']`) are absent."
    - "A direct selection-driven retry attempt seeded with the outsider + ambiguous webhook ids is BLOCKED server-side: confirming the retry surfaces the owner-denied/replay-blocked warning and requeues zero rows."
    - "ZERO `admin.webhook.replay.completed` audit events exist after the test (final aggregate assertion preserved and passing). No `admin.webhook.bulk_replay.completed` success event is recorded either."
    - "The FIRST test and the single-webhook denial assertions (lines ~197-207: outsider redirect → `owner_access_denied`, ambiguous inline → ownership-not-verified copy) remain UNCHANGED and green."
    - "`mix test test/accrue_host_web/admin_webhook_replay_test.exs` from examples/accrue_host → 2 tests, 0 failures; broader host suite returns to green."
  artifacts:
    - path: "examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs"
      provides: "Repaired second test exercising the selection-driven retry security boundary (list-scoping + blocked retry-handler) with the zero-success-audit assertion intact"
      contains: 'admin.webhook.replay.completed'
  key_links:
    - from: "examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs"
      to: "accrue_admin/lib/accrue_admin/live/webhooks_live.ex"
      via: "send({:data_table_bulk_action, \"retry_selected\", [outsider_id, ambiguous_id]}) to view.pid, then render_click the confirm-retry-selected button — drives handle_info/2 then confirm_retry_selected which scope_selected_ids → [] → replay_blocked warning, no record_bulk_replay"
      pattern: "data_table_bulk_action|confirm-retry-selected"
    - from: "examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs"
      to: "accrue_admin/lib/accrue_admin/components/data_table.ex"
      via: "empty-state assertion: with no in-scope rows the DataTable renders [data-role='empty-state'] and omits [data-role='selection-bar']/[data-role='bulk-action']"
      pattern: "selection-bar|empty-state"
---

<objective>
Repair the orphaned second test in `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs`. Quick task 260621-h72 replaced the webhooks admin page's FILTER-driven bulk replay (`data-role="prepare-bulk-replay"` button + "No failed or dead-lettered webhook rows match the current filters" warning) with a SELECTION-driven retry flow. The test still clicks the removed button (line 215) and asserts the removed warning copy (line 216), so it fails.

Translate the broken bulk step to the new selection-driven contract WITHOUT weakening the security property: an admin scoped to `allowed_org`, viewing dead/`invoice.payment_failed` webhooks owned by an OUTSIDER org or AMBIGUOUS (unresolvable owner), must NOT be able to bulk-replay them, and ZERO `admin.webhook.replay.completed` audit events may be recorded.

Purpose: Restore the host integration suite to green while keeping the cross-package security regression test faithful (still exercises an actual blocked replay attempt, not just an empty list).
Output: One modified test file = one atomic commit.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md

# THE test to repair (only the second test + nothing else in this file changes)
@examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs

# THE new selection-driven contract (production — DO NOT MODIFY, read for behavior)
@accrue_admin/lib/accrue_admin/live/webhooks_live.ex

# Mirror this technique: the accrue_admin "blocked bulk replay" test (lines 122-205)
# is the canonical exemplar for selection-driven retry + scoped-out list + zero-audit.
@accrue_admin/test/accrue_admin/live/webhooks_live_test.exs

# Copy strings the assertions reference
@accrue_admin/lib/accrue_admin/copy/locked.ex
</context>

<!-- planner-discipline-allow: prepare-bulk-replay -->

<tasks>

<task type="auto">
  <name>Task 1: Rewrite the bulk-replay step of the second test to the selection-driven contract, preserving the security boundary and zero-success-audit assertion</name>
  <files>examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs</files>
  <action>
Edit ONLY the second test ("ambiguous or out-of-scope webhook replay blocks single and bulk replay without success audits", lines ~141-225). Leave the first test, the `insert_webhook/1` and `insert_attempt_job/1` helpers, the module header, and aliases untouched.

Keep lines 143-207 exactly as-is: the fixtures (admin_user, allowed_org, outsider_org, outsider_subscription, outsider_webhook, ambiguous_webhook), the session setup, the outsider single-replay redirect assertion (`owner_access_denied()`), and the ambiguous inline "Ownership couldn't be verified" assertion. Those pass and prove the single-replay denial; do not weaken them.

Replace ONLY the broken bulk step (current lines 209-216 — the `live(...)` that opens the filtered bulk view, the `render_click(element(bulk_view, "[data-role='prepare-bulk-replay']"))`, and the `assert bulk_html =~ "No failed or dead-lettered webhook rows match the current filters."`). Replace it with a TWO-LAYER assertion that mirrors the accrue_admin exemplar at accrue_admin/test/accrue_admin/live/webhooks_live_test.exs lines 164-205 (the "blocked bulk replay does not emit replay-success audit events" test):

LAYER 1 — list-scoping (black-box). Open the org-scoped filtered list:
`{:ok, bulk_view, bulk_html} = live(conn, "/admin/webhooks?status=dead&type=invoice.payment_failed&org=#{allowed_org.slug}")`.
Assert the outsider/ambiguous rows are scoped OUT and there is no selectable affordance, e.g.:
  - `refute bulk_html =~ outsider_webhook.id`
  - `refute bulk_html =~ ambiguous_webhook.id`
  - `assert bulk_html =~ AccrueAdmin.Copy.webhooks_index_empty_title()` (i.e. "No webhook deliveries for this organization yet" — the DataTable renders `data-role="empty-state"` when there are no in-scope rows)
  - `refute bulk_html =~ ~s(data-role="bulk-action")` (the selection bar / Retry-selected button is rendered only when rows are present)
Use the Copy module accessor `AccrueAdmin.Copy.webhooks_index_empty_title()` rather than hardcoding the string, matching how the host test already references `AccrueAdmin.Copy.Locked.owner_access_denied()`. Add `alias AccrueAdmin.Copy` only if you reference it unqualified; prefer the fully-qualified `AccrueAdmin.Copy.webhooks_index_empty_title()` to avoid touching the alias block. The `bulk_view` from this `live/2` is the LiveView process used for layer 2.

LAYER 2 — retry-handler defense-in-depth (preferred; keep a real blocked attempt). Drive the selection-driven retry directly with the hostile ids, proving the server rejects them even if a client submits ids the list would never surface. The DataTable component notifies its parent via `send(self(), {:data_table_bulk_action, event, ids})`; in a LiveViewTest the parent LiveView process is `bulk_view.pid`, so inject the hostile ids the same way:
  - `send(bulk_view.pid, {:data_table_bulk_action, "retry_selected", [outsider_webhook.id, ambiguous_webhook.id]})`
  - `_ = render(bulk_view)` to let the LiveView process the message (this assigns `pending_bulk_replay`, surfacing the confirm card)
  - then confirm: `blocked_html = render_click(element(bulk_view, "[data-role='confirm-retry-selected']"))`
  - assert the blocked warning surfaced: `assert blocked_html =~ AccrueAdmin.Copy.Locked.replay_blocked()` (handle_event "confirm_retry_selected" runs `scope_selected_ids` → both ids fail `Webhooks.detail/2` → returns `[]` → pushes `Copy.Locked.replay_blocked()` and never calls `record_bulk_replay`)
Reference behavior is in accrue_admin/lib/accrue_admin/live/webhooks_live.ex: `handle_info({:data_table_bulk_action, "retry_selected", ids}, ...)` (lines 51-57) and `handle_event("confirm_retry_selected", ...)` (lines 73-99). If `element(bulk_view, "[data-role='confirm-retry-selected']")` cannot be found because the confirm card needs an extra render cycle, add a second `render(bulk_view)` before the `render_click`; do not fall back to clicking any removed selector.

KEEP the final zero-success-audit assertion (current lines 218-224) verbatim: the `Repo.aggregate(from(event in Event, where: event.type == "admin.webhook.replay.completed"), :count, :id) == 0`. This is the load-bearing security assertion and MUST remain. Optionally (preferred, defense-in-depth) add a parallel `== 0` aggregate for `event.type == "admin.webhook.bulk_replay.completed"` (the success event the new flow would emit) so the test also proves the new code path recorded no success audit — but the `admin.webhook.replay.completed` assertion is the one that must not be removed.

Do NOT: modify any accrue_admin or core production file; touch examples/accrue_host/mix.lock; touch the first test; introduce new helpers in this file beyond what the change needs; reference any removed selector (`prepare-bulk-replay`) or removed copy ("No failed or dead-lettered webhook rows match the current filters").
  </action>
  <verify>
    <automated>cd examples/accrue_host && mix test test/accrue_host_web/admin_webhook_replay_test.exs --seed 0</automated>
  </verify>
  <done>
`mix test test/accrue_host_web/admin_webhook_replay_test.exs` reports 2 tests, 0 failures. The second test asserts (a) outsider/ambiguous ids absent from the org-scoped list + empty-state title shown + no bulk-action affordance, (b) a direct seeded retry of the hostile ids is blocked with the `replay_blocked()` warning, and (c) zero `admin.webhook.replay.completed` events. No reference to `prepare-bulk-replay` or the old filter-warning copy remains. No production files changed; `git diff --name-only` shows only the one test file.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| admin client → webhooks LiveView | An authenticated billing admin scoped to `allowed_org` may attempt to submit webhook ids (via selection or a forged client message) that belong to an outsider org or are ambiguous. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-lzc-01 | Elevation of Privilege | webhooks_live.ex `confirm_retry_selected` | mitigate (verify-only) | This test repair re-asserts the existing server-side mitigation: `scope_selected_ids` drops ids that fail `Webhooks.detail/2` owner-scope resolution, so out-of-scope/ambiguous ids return `[]` → `replay_blocked` warning → no requeue, no audit. The repaired layer-2 step exercises this with hostile ids injected directly into the LiveView process. |
| T-lzc-02 | Repudiation | accrue_events ledger | mitigate (verify-only) | The preserved `admin.webhook.replay.completed == 0` aggregate (plus optional `admin.webhook.bulk_replay.completed == 0`) proves no success audit is fabricated for a blocked replay. |
| T-lzc-SC | Tampering | npm/pip/cargo installs | accept | No package installs in this plan; no dependency changes; mix.lock is off-limits. |
</threat_model>

<verification>
- From `examples/accrue_host`: `mix test test/accrue_host_web/admin_webhook_replay_test.exs --seed 0` → 2 tests, 0 failures.
- Broader host suite returns to green (this was the only failure): `cd examples/accrue_host && mix test --seed 0` (PdfTest may be flaky per project memory — `--seed 0` dodges it; the webhook replay test must pass under any seed).
- `git diff --name-only` shows ONLY `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs`.
- `grep -c "admin.webhook.replay.completed" examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` ≥ 1 (zero-audit assertion preserved).
- `grep -c "prepare-bulk-replay" examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` == 0 (removed selector gone).
</verification>

<success_criteria>
- Second test repaired to the selection-driven contract; first test unchanged and green.
- Security property preserved: out-of-scope/ambiguous webhooks are scoped out of the list AND a direct retry attempt is blocked server-side; zero `admin.webhook.replay.completed` audits.
- Only the one host test file changed; no production code, no mix.lock, no ROADMAP.
- 2 tests, 0 failures; host suite green.
</success_criteria>

<output>
Create `.planning/quick/260621-lzc-repair-host-admin-webhook-replay-test-to/260621-lzc-SUMMARY.md` when done.
</output>
